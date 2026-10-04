package com.youpipe.app

import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.IOException
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Serves a googlevideo progressive stream (the muxed 360p fallback) to the phone's own player from 127.0.0.1
 * (docs/streaming.md). Adapted from YouPipe Music's relay of the same name.
 *
 * ExoPlayer reads a progressive stream with one open-ended request, which googlevideo throttles to about twice
 * real time, so its buffer barely gets ahead. This proxy fetches the same URL in 1 MB ranges with its client's
 * User-Agent ([Googlevideo]), like the downloader and the cast relay, and those arrive at full speed. It also
 * keeps playback on the address family extraction used ([Googlevideo.preferIpv4]).
 *
 * It listens on the loopback address only, and serves only URLs registered through the channel.
 */
object PlaybackProxy {
    private const val CHANNEL = "youpipe/playback_proxy"
    private const val TAG = "YouPipeProxy"

    /** Tokens kept: the current video, plus a few a retry or a quality change may still use. */
    private const val KEEP_TOKENS = 16

    private class Stream(
        val url: String,
        val mime: String,
        @Volatile var size: Long?,
    )

    private val pool = Executors.newCachedThreadPool()
    private val streams = LinkedHashMap<String, Stream>()
    private var server: ServerSocket? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "url" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("BAD_ARGS", "url is required", null)
                        return@setMethodCallHandler
                    }
                    val mime = call.argument<String>("mimeType") ?: "video/mp4"
                    val size = call.argument<Number>("contentLength")?.toLong()?.takeIf { it > 0 }
                    try {
                        result.success(urlFor(url, mime, size))
                    } catch (e: IOException) {
                        result.error("PROXY_FAILED", e.message ?: "Proxy unavailable", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /** A loopback URL that serves [url]. */
    @Synchronized
    private fun urlFor(
        url: String,
        mime: String,
        size: Long?,
    ): String {
        val socket =
            server?.takeIf { !it.isClosed }
                // 127.0.0.1 itself: getLoopbackAddress() is ::1 on Android, which the URL wouldn't reach.
                ?: ServerSocket(0, 50, InetAddress.getByName("127.0.0.1")).also {
                    server = it
                    pool.execute { accept(it) }
                }
        val token = UUID.randomUUID().toString().replace("-", "")
        streams[token] = Stream(url, mime, size)
        while (streams.size > KEEP_TOKENS) streams.remove(streams.keys.first())
        return "http://127.0.0.1:${socket.localPort}/s/$token"
    }

    private fun accept(socket: ServerSocket) {
        while (!socket.isClosed) {
            val client = runCatching { socket.accept() }.getOrNull() ?: break
            pool.execute { runCatching { serve(client) }.onFailure { Log.d(TAG, "request ended: $it") } }
        }
    }

    private fun serve(client: Socket) =
        client.use { socket ->
            socket.soTimeout = 30_000
            val request = MiniHttp.readRequest(BufferedInputStream(socket.getInputStream())) ?: return
            val out = BufferedOutputStream(socket.getOutputStream(), 64 * 1024)
            val token = request.path?.takeIf { it.startsWith("/s/") }?.removePrefix("/s/")?.substringBefore('?')
            val stream = synchronized(this) { token?.let { streams[it] } }
            if (stream == null || (request.method != "GET" && request.method != "HEAD")) {
                fail(out, 404)
                return
            }
            val size =
                try {
                    stream.size ?: sizeOf(stream.url).also { stream.size = it }
                } catch (e: IOException) {
                    fail(out, e)
                    return
                }
            val rangeHeader = request.headers["range"]
            val (start, end) = MiniHttp.parseRange(rangeHeader, size)
            // The first chunk comes before the response head, so an upstream refusal (an expired URL, a changed
            // address) reaches the player as an HTTP error, which starts its recovery.
            var chunk =
                try {
                    fetch(stream.url, start, end)
                } catch (e: IOException) {
                    fail(out, e)
                    return
                }
            val headers =
                buildMap {
                    put("Content-Type", stream.mime)
                    put("Content-Length", (end - start + 1).toString())
                    put("Accept-Ranges", "bytes")
                    if (rangeHeader != null) put("Content-Range", "bytes $start-$end/$size")
                }
            if (rangeHeader != null) {
                MiniHttp.writeHead(out, 206, "Partial Content", headers)
            } else {
                MiniHttp.writeHead(out, 200, "OK", headers)
            }
            if (request.method == "HEAD") {
                out.flush()
                return
            }
            var offset = start
            while (true) {
                out.write(chunk)
                offset += chunk.size
                if (offset > end || chunk.isEmpty()) break
                // A failure mid-body closes the connection; ExoPlayer then asks again from where it is.
                chunk = fetch(stream.url, offset, end)
            }
            out.flush()
        }

    /** An HTTP error from googlevideo. */
    private class UpstreamException(
        val code: Int,
    ) : IOException("HTTP $code")

    private fun sizeOf(url: String): Long =
        Googlevideo.range(url, 0, 0).use { response ->
            if (!response.isSuccessful) throw UpstreamException(response.code)
            Googlevideo.totalSize(response) ?: throw IOException("Unknown size")
        }

    /**
     * One chunk of at most [Googlevideo.CHUNK] bytes from [start], read in full before it's passed on: the
     * upstream connection never sits idle while the player isn't reading (its buffer is full), which googlevideo
     * would close.
     */
    private fun fetch(
        url: String,
        start: Long,
        end: Long,
    ): ByteArray =
        Googlevideo.range(url, start, minOf(end, start + Googlevideo.CHUNK - 1)).use { response ->
            if (!response.isSuccessful) {
                Log.d(TAG, "HTTP ${response.code} at byte $start (c=${Uri.parse(url).getQueryParameter("c")})")
                throw UpstreamException(response.code)
            }
            response.body?.bytes() ?: ByteArray(0)
        }

    /** Passes googlevideo's refusal on (403 for an expired URL, say); anything else is a 502. */
    private fun fail(
        out: OutputStream,
        e: IOException,
    ) = fail(out, (e as? UpstreamException)?.code?.takeIf { it in 400..599 } ?: 502)

    private fun fail(
        out: OutputStream,
        code: Int,
    ) {
        MiniHttp.writeHead(out, code, "Error", emptyMap())
        out.flush()
    }
}
