package com.youpipe.app

import java.io.InputStream
import java.io.OutputStream

/** The bits of HTTP/1.1 the on-device servers need: [CastProxy] (LAN) and [PlaybackProxy] (loopback). */
internal object MiniHttp {
    class Request(
        val method: String?,
        val path: String?,
        /** Lower-cased names. */
        val headers: Map<String, String>,
    )

    /** The request line and headers; null when the client sent nothing. */
    fun readRequest(input: InputStream): Request? {
        val requestLine = readLine(input) ?: return null
        val headers = HashMap<String, String>()
        while (true) {
            val line = readLine(input) ?: break
            if (line.isEmpty()) break
            val colon = line.indexOf(':')
            if (colon > 0) headers[line.substring(0, colon).trim().lowercase()] = line.substring(colon + 1).trim()
        }
        val parts = requestLine.split(' ')
        return Request(parts.getOrNull(0), parts.getOrNull(1), headers)
    }

    /** A single `bytes=a-b` / `bytes=a-` range, clamped to the file; the whole file without one. */
    fun parseRange(
        header: String?,
        size: Long,
    ): Pair<Long, Long> {
        val spec = header?.removePrefix("bytes=")?.substringBefore(',') ?: return 0L to size - 1
        val start = spec.substringBefore('-').toLongOrNull()
        val end = spec.substringAfter('-').toLongOrNull()
        return when {
            start == null && end != null -> maxOf(0, size - end) to size - 1
            else -> (start ?: 0L).coerceIn(0, size - 1) to minOf(end ?: (size - 1), size - 1)
        }
    }

    fun writeHead(
        out: OutputStream,
        code: Int,
        reason: String,
        headers: Map<String, String>,
    ) {
        val text =
            buildString {
                append("HTTP/1.1 $code $reason\r\n")
                headers.forEach { (k, v) -> append("$k: $v\r\n") }
                append("Access-Control-Allow-Origin: *\r\n")
                append("Connection: close\r\n\r\n")
            }
        out.write(text.toByteArray(Charsets.ISO_8859_1))
    }

    fun copy(
        input: InputStream,
        out: OutputStream,
    ): Long {
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val n = input.read(buffer)
            if (n < 0) break
            out.write(buffer, 0, n)
            total += n
        }
        return total
    }

    private fun readLine(input: InputStream): String? {
        val line = StringBuilder()
        while (true) {
            val c = input.read()
            if (c < 0) return if (line.isEmpty()) null else line.toString()
            if (c == '\n'.code) return line.toString().trimEnd('\r')
            line.append(c.toChar())
            if (line.length > 8192) return null
        }
    }
}
