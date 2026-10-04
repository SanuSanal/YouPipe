package com.youpipe.app

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import okhttp3.Dns
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.schabi.newpipe.extractor.services.youtube.YoutubeParsingHelper
import java.net.Inet4Address
import java.net.InetAddress
import java.util.concurrent.TimeUnit

/**
 * Fetching from googlevideo stream URLs, shared by the downloader and the cast proxy.
 *
 * Stream URLs are bound to this phone's IP and to the InnerTube client that produced them: requests
 * must leave through this device, with that client's User-Agent, in ranges of at most about 1 MB
 * (docs/streaming.md).
 */
object Googlevideo {
    const val CHUNK = 1024L * 1024L

    private const val WEB_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"

    /**
     * Which address family YouTube is reached over. YouTube flags IPv4 and IPv6 ranges separately, so when one
     * gets the bot check the other often still works (docs/streaming.md). Stream URLs are bound to the address that
     * resolved them, so extraction, playback and downloads must all use the same family.
     */
    @Volatile
    var preferIpv4 = false
        private set

    private const val PREFS = "youpipe_network"
    private const val KEY_IPV4 = "preferIpv4"
    private var prefs: SharedPreferences? = null

    /** Loads the remembered address family; called by the activity and the download worker. */
    fun attach(context: Context) {
        if (prefs != null) return
        prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).also {
            preferIpv4 = it.getBoolean(KEY_IPV4, false)
        }
    }

    /** YouTube's "Sign in to confirm that you're not a bot", which it gives a flagged address. */
    fun isBotCheck(e: Throwable): Boolean = e.message.orEmpty().contains("not a bot")

    /** Moves to the other address family after a bot check, and remembers it for the next launches. */
    fun switchFamily() {
        preferIpv4 = !preferIpv4
        prefs?.edit()?.putBoolean(KEY_IPV4, preferIpv4)?.apply()
        // Pooled connections still use the old family.
        client.connectionPool.evictAll()
        Log.w("YouPipe", "bot check: now preferring ${if (preferIpv4) "IPv4" else "the system's order (IPv6 first)"}")
    }

    private val familyDns =
        object : Dns {
            override fun lookup(hostname: String): List<InetAddress> {
                val all = Dns.SYSTEM.lookup(hostname)
                return if (preferIpv4) all.sortedBy { if (it is Inet4Address) 0 else 1 } else all
            }
        }

    val client: OkHttpClient =
        OkHttpClient
            .Builder()
            .dns(familyDns)
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()

    fun userAgentFor(url: String): String =
        when {
            YoutubeParsingHelper.isVisionOsStreamingUrl(url) -> YoutubeParsingHelper.getVisionOsUserAgent(null)
            YoutubeParsingHelper.isAndroidStreamingUrl(url) -> YoutubeParsingHelper.getAndroidUserAgent(null)
            YoutubeParsingHelper.isIosStreamingUrl(url) -> YoutubeParsingHelper.getIosUserAgent(null)
            else -> WEB_USER_AGENT
        }

    /** One range request (`start`..`endInclusive`); the caller closes the response. */
    fun range(
        url: String,
        start: Long,
        endInclusive: Long,
    ): Response =
        client
            .newCall(
                Request
                    .Builder()
                    .url(url)
                    .header("User-Agent", userAgentFor(url))
                    .header("Range", "bytes=$start-$endInclusive")
                    .build(),
            ).execute()

    /** The full size from a range response (`Content-Range: bytes a-b/total`). */
    fun totalSize(response: Response): Long? =
        response.header("Content-Range")?.substringAfterLast('/')?.toLongOrNull()
            ?: response.body?.contentLength()?.takeIf { it > 0 }
}
