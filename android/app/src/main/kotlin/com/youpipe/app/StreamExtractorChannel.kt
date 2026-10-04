package com.youpipe.app

import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import okhttp3.RequestBody.Companion.toRequestBody
import org.schabi.newpipe.extractor.Image
import org.schabi.newpipe.extractor.MediaFormat
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.AgeRestrictedContentException
import org.schabi.newpipe.extractor.exceptions.ContentNotAvailableException
import org.schabi.newpipe.extractor.exceptions.GeographicRestrictionException
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import org.schabi.newpipe.extractor.localization.ContentCountry
import org.schabi.newpipe.extractor.localization.Localization
import org.schabi.newpipe.extractor.stream.AudioStream
import org.schabi.newpipe.extractor.stream.AudioTrackType
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import org.schabi.newpipe.extractor.stream.Stream
import org.schabi.newpipe.extractor.stream.StreamExtractor
import org.schabi.newpipe.extractor.stream.StreamType
import org.schabi.newpipe.extractor.stream.VideoStream
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Everything YouPipe needs from a single video that the Dart InnerTube client doesn't do: playable stream URLs
 * (deciphered, past the PO-token cap), captions, storyboards and chapters, through NewPipeExtractor
 * (docs/streaming.md).
 */
object StreamExtractorChannel {
    private const val CHANNEL = "youpipe/stream_extractor"

    private val executor = Executors.newFixedThreadPool(3)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var initialized = false

    /** The `hl-gl` NewPipe is set up for; Settings can change them while the app runs. */
    @Volatile
    private var localeKey: String? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            val hl = call.argument<String>("hl") ?: "en"
            val gl = call.argument<String>("gl") ?: "US"
            when (call.method) {
                "getVideoInfo" -> {
                    val videoId = call.argument<String>("videoId")
                    if (videoId.isNullOrBlank()) {
                        result.error("BAD_ARGS", "videoId is required", null)
                        return@setMethodCallHandler
                    }
                    val maxHeight = call.argument<Int>("maxHeight") ?: 1080
                    run(result) { getVideoInfo(videoId, hl, gl, maxHeight) }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun run(
        result: MethodChannel.Result,
        work: () -> Any?,
    ) {
        executor.execute {
            try {
                val data = work()
                mainHandler.post { result.success(data) }
            } catch (e: Throwable) {
                val code =
                    when {
                        // "Sign in to confirm that you're not a bot": YouTube is blocking anonymous access from this IP.
                        Googlevideo.isBotCheck(e) -> "BOT_CHECK"
                        e is AgeRestrictedContentException -> "AGE_RESTRICTED"
                        e is GeographicRestrictionException -> "GEO_RESTRICTED"
                        e is ContentNotAvailableException -> "UNAVAILABLE"
                        e is ReCaptchaException -> "RECAPTCHA"
                        e is NoStreamsException -> "NO_STREAMS"
                        else -> "EXTRACTION_FAILED"
                    }
                mainHandler.post { result.error(code, e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    private class NoStreamsException(
        videoId: String,
    ) : Exception("No playable stream for $videoId")

    /**
     * Fetches a video's player responses. YouTube flags IPv4 and IPv6 addresses separately, so after a bot check
     * this retries once over the other address family and keeps using it ([Googlevideo.switchFamily]).
     */
    fun fetchExtractor(videoId: String): StreamExtractor {
        fun fetch() = ServiceList.YouTube.getStreamExtractor(watchUrl(videoId)).apply { fetchPage() }
        return try {
            fetch()
        } catch (e: Exception) {
            if (!Googlevideo.isBotCheck(e)) throw e
            Googlevideo.switchFamily()
            fetch()
        }
    }

    fun ensureInit(
        hl: String,
        gl: String,
    ) {
        val key = "$hl-$gl"
        if (localeKey == key) return
        synchronized(this) {
            if (!initialized) {
                NewPipe.init(OkHttpDownloader, Localization(hl, gl), ContentCountry(gl))
                initialized = true
            } else if (localeKey != key) {
                NewPipe.setupLocalization(Localization(hl, gl), ContentCountry(gl))
            }
            localeKey = key
        }
    }

    private fun watchUrl(videoId: String) = "https://www.youtube.com/watch?v=$videoId"

    // Video info ---------------------------------------------------------------------------------------------------

    /**
     * One extraction for the watch page: metadata, every way to play the video, captions, storyboards and chapters.
     *
     * Playback options, best first (docs/playback.md):
     * - `hlsUrl` for live streams;
     * - `mpd`: a static DASH manifest from the video-only streams up to [maxHeight] plus the best audio stream;
     * - `muxed`: YouTube's progressive stream with video and audio in one file (360p).
     */
    private fun getVideoInfo(
        videoId: String,
        hl: String,
        gl: String,
        maxHeight: Int,
    ): Map<String, Any?> {
        ensureInit(hl, gl)
        val started = System.currentTimeMillis()
        fun stage(name: String) = Log.d("YouPipe", "getVideoInfo $videoId $name +${System.currentTimeMillis() - started}ms")
        val extractor = fetchExtractor(videoId)
        stage("fetched")
        val duration = extractor.length
        val live = extractor.streamType == StreamType.LIVE_STREAM || extractor.streamType == StreamType.AUDIO_LIVE_STREAM

        val hls = extractor.hlsUrl.takeIf { it.isNotBlank() }
        val muxed =
            extractor.videoStreams
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl && !it.isVideoOnly }
                .filter { it.height in 1..720 }
                .maxByOrNull { it.height }
        val dash = if (live || duration <= 0) null else buildDash(extractor, maxHeight, duration)
        stage("streams")
        // NewPipe mixes clients: the muxed stream and the DASH streams can come from different ones (docs/streaming.md).
        fun client(url: String?) = url?.let { Regex("[?&]c=([A-Z_]+)").find(it)?.groupValues?.get(1) }
        Log.d("YouPipe", "getVideoInfo $videoId clients: muxed=${client(muxed?.content)} dash=${client(dash?.get("url") as String?)}")
        if (hls == null && muxed == null && dash == null) throw NoStreamsException(videoId)

        // Metadata is best-effort: one getter tripping over a changed response must not stop playback.
        fun <T> safe(get: () -> T): T? = runCatching(get).onFailure { Log.w("YouPipe", "getVideoInfo $videoId: $it") }.getOrNull()
        val uploaderUrl = safe { extractor.uploaderUrl }.orEmpty()
        return linkedMapOf<String, Any?>(
            "videoId" to videoId,
            "title" to safe { extractor.name },
            "channelId" to uploaderUrl.substringAfterLast('/').takeIf { it.startsWith("UC") },
            "channelName" to safe { extractor.uploaderName },
            "channelAvatar" to safe { bestImage(extractor.uploaderAvatars, 176) },
            "channelVerified" to safe { extractor.isUploaderVerified },
            "subscriberCount" to safe { extractor.uploaderSubscriberCount },
            "viewCount" to safe { extractor.viewCount },
            "likeCount" to safe { extractor.likeCount },
            "uploadDate" to safe { extractor.textualUploadDate },
            "description" to safe { extractor.description.content },
            "durationSeconds" to duration,
            "isLive" to live,
            "isShort" to (safe { extractor.isShortFormContent } ?: false),
            "ageLimit" to safe { extractor.ageLimit },
            "hlsUrl" to hls,
            "dashMpd" to dash?.get("mpd"),
            "dashHeights" to dash?.get("heights"),
            "dashCodec" to dash?.get("codec"),
            "muxedUrl" to muxed?.content,
            "muxedHeight" to muxed?.height,
            // Each source's URLs only play with the User-Agent of the client that produced them.
            "dashUserAgent" to (dash?.get("url") as String?)?.let(Googlevideo::userAgentFor),
            "muxedUserAgent" to muxed?.content?.let(Googlevideo::userAgentFor),
            "hlsUserAgent" to hls?.let(Googlevideo::userAgentFor),
            "captions" to captions(extractor),
            "storyboards" to storyboards(extractor),
            "chapters" to
                (safe { extractor.streamSegments } ?: emptyList()).map {
                    mapOf("title" to it.title, "startSeconds" to it.startTimeSeconds, "thumbnail" to it.previewUrl)
                },
            "downloadOptions" to downloadOptions(extractor, muxed),
            "audio" to
                originalAudio(extractor.audioStreams).map {
                    mapOf(
                        "url" to it.content,
                        "itag" to it.itag,
                        "mimeType" to it.format?.mimeType,
                        "codec" to it.codec,
                        "bitrate" to (it.averageBitrate.takeIf { b -> b > 0 } ?: (it.bitrate / 1000)),
                    )
                },
        ).also { stage("done") }
    }

    /** What [DownloadWorker] can make, by height, with the total size: H.264 + AAC, or the muxed stream. */
    private fun downloadOptions(
        extractor: StreamExtractor,
        muxed: VideoStream?,
    ): List<Map<String, Any?>> {
        val aac =
            originalAudio(extractor.audioStreams)
                .filter { it.codec.orEmpty().startsWith("mp4a") }
                .maxByOrNull { it.bitrate }
        val audioSize = aac?.itagItem?.contentLength ?: 0L
        val options = mutableMapOf<Int, Long>()
        if (aac != null) {
            extractor.videoOnlyStreams
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP }
                .filter { it.codec.orEmpty().startsWith("avc1") }
                .forEach { v ->
                    val size = (v.itagItem?.contentLength ?: 0L) + audioSize
                    if (v.height > (muxed?.height ?: 0) && (options[v.height] ?: 0L) < size) options[v.height] = size
                }
        }
        if (muxed != null) options[muxed.height] = muxed.itagItem?.contentLength ?: 0L
        return options.entries.sortedBy { it.key }.map { mapOf("height" to it.key, "size" to it.value) }
    }

    /** The muxed progressive stream for casting ([CastProxy]); network work. */
    fun castStream(videoId: String): VideoStream? {
        ensureInit("en", "US")
        val extractor = fetchExtractor(videoId)
        return extractor.videoStreams
            .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl && !it.isVideoOnly }
            .maxByOrNull { it.height }
    }

    private fun bestImage(
        images: List<Image>,
        target: Int,
    ): String? = images.minByOrNull { kotlin.math.abs(it.height - target) }?.url ?: images.firstOrNull()?.url

    private fun captions(extractor: StreamExtractor): List<Map<String, Any?>> =
        runCatching { extractor.getSubtitles(MediaFormat.VTT) }.getOrDefault(emptyList()).map {
            mapOf(
                "url" to it.content,
                "languageCode" to it.languageTag,
                "name" to it.displayLanguageName,
                "autoGenerated" to it.isAutoGenerated,
            )
        }

    private fun storyboards(extractor: StreamExtractor): List<Map<String, Any?>> =
        runCatching { extractor.frames }.getOrDefault(emptyList()).map {
            mapOf(
                "urls" to it.urls,
                "frameWidth" to it.frameWidth,
                "frameHeight" to it.frameHeight,
                "totalCount" to it.totalCount,
                "durationPerFrameMs" to it.durationPerFrame,
                "framesPerPageX" to it.framesPerPageX,
                "framesPerPageY" to it.framesPerPageY,
            )
        }

    /**
     * Progressive audio on the original track. DRC ("stable volume") copies have their dynamic range compressed,
     * so they're only kept when nothing else is offered.
     */
    private fun originalAudio(all: List<AudioStream>): List<AudioStream> {
        val original =
            all
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl }
                .filter { it.audioTrackType == null || it.audioTrackType == AudioTrackType.ORIGINAL }
        return original.filter { it.itagItem?.isDrc() != true }.ifEmpty { original }
    }

    private fun Stream.hasRanges(): Boolean {
        val i = itagItem ?: return false
        return i.initEnd > 0 && i.indexStart > 0 && i.indexEnd > i.indexStart
    }

    private fun isVp9(s: VideoStream) = s.codec.orEmpty().let { it.startsWith("vp9") || it.startsWith("vp09") }

    /** Whether the phone has a hardware VP9 decoder; software VP9 above 1080p stutters on most phones. */
    private val hardwareVp9: Boolean by lazy {
        MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info ->
            !info.isEncoder &&
                info.supportedTypes.any { it.equals("video/x-vnd.on2.vp9", ignoreCase = true) } &&
                (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || isHardware(info))
        }
    }

    private fun isHardware(info: MediaCodecInfo): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && info.isHardwareAccelerated

    /**
     * A static DASH manifest (one codec family per manifest, so ExoPlayer can switch heights): H.264 up to 1080p,
     * or VP9 when more than 1080p is wanted, available, and decodable in hardware.
     */
    private fun buildDash(
        extractor: StreamExtractor,
        maxHeight: Int,
        duration: Long,
    ): Map<String, Any?>? {
        val usable =
            extractor.videoOnlyStreams
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl && it.hasRanges() }
                .filter { it.height in 144..maxHeight }
        val avc = usable.filter { it.codec.orEmpty().startsWith("avc1") }
        val vp9 = usable.filter(::isVp9)
        val wantsVp9 = vp9.isNotEmpty() && hardwareVp9 && (vp9.maxOf { it.height } > (avc.maxOfOrNull { it.height } ?: 0))
        val chosen = if (wantsVp9 || avc.isEmpty()) vp9 else avc
        val video =
            chosen
                .groupBy { it.height }
                .map { (_, same) -> same.maxBy { it.bitrate } }
                .sortedBy { it.height }
        if (video.isEmpty()) return null
        val audio =
            originalAudio(extractor.audioStreams)
                .filter { it.hasRanges() }
                .let { list -> list.filter { it.codec.orEmpty().contains("opus") }.ifEmpty { list } }
                .maxByOrNull { it.bitrate } ?: return null
        return mapOf(
            "mpd" to buildMpd(video, audio, duration),
            "heights" to video.map { it.height },
            "codec" to video.last().codec,
            "url" to video.last().content,
        )
    }

    private fun xml(s: String) =
        s
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")

    private fun segmentBase(s: Stream): String {
        val i = s.itagItem!!
        return "<BaseURL>${xml(s.content)}</BaseURL>" +
            "<SegmentBase indexRange=\"${i.indexStart}-${i.indexEnd}\">" +
            "<Initialization range=\"${i.initStart}-${i.initEnd}\"/></SegmentBase>"
    }

    private fun buildMpd(
        video: List<VideoStream>,
        audio: AudioStream,
        durationSeconds: Long,
    ): String =
        buildString {
            append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
            append("<MPD xmlns=\"urn:mpeg:dash:schema:mpd:2011\" profiles=\"urn:mpeg:dash:profile:isoff-on-demand:2011\"")
            append(" type=\"static\" minBufferTime=\"PT1.5S\" mediaPresentationDuration=\"PT${durationSeconds}S\">")
            append("<Period>")
            val videoMime = video.first().format?.mimeType ?: "video/mp4"
            append("<AdaptationSet id=\"0\" contentType=\"video\" mimeType=\"$videoMime\">")
            video.forEachIndexed { n, v ->
                append("<Representation id=\"v$n\" codecs=\"${xml(v.codec.orEmpty())}\" bandwidth=\"${v.bitrate}\"")
                append(" width=\"${v.width}\" height=\"${v.height}\"")
                if (v.fps > 0) append(" frameRate=\"${v.fps}\"")
                append(">${segmentBase(v)}</Representation>")
            }
            append("</AdaptationSet>")
            val audioMime = audio.format?.mimeType ?: "audio/mp4"
            append("<AdaptationSet id=\"1\" contentType=\"audio\" mimeType=\"$audioMime\">")
            append("<Representation id=\"a0\" codecs=\"${xml(audio.codec.orEmpty())}\" bandwidth=\"${audio.bitrate}\"")
            audio.itagItem?.sampleRate?.takeIf { it > 0 }?.let { append(" audioSamplingRate=\"$it\"") }
            append(">${segmentBase(audio)}</Representation>")
            append("</AdaptationSet></Period></MPD>")
        }

    private object OkHttpDownloader : Downloader() {
        private const val USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"

        private val client =
            Googlevideo.client
                .newBuilder()
                .readTimeout(30, TimeUnit.SECONDS)
                .build()

        override fun execute(request: Request): Response {
            val body = request.dataToSend()?.toRequestBody()
            val builder =
                okhttp3.Request
                    .Builder()
                    .method(request.httpMethod(), body)
                    .url(request.url())
                    .addHeader("User-Agent", USER_AGENT)

            request.headers().forEach { (name, values) ->
                builder.removeHeader(name)
                values.forEach { builder.addHeader(name, it) }
            }

            client.newCall(builder.build()).execute().use { response ->
                if (response.code == 429) {
                    throw ReCaptchaException("reCaptcha challenge requested", request.url())
                }
                return Response(
                    response.code,
                    response.message,
                    response.headers.toMultimap(),
                    response.body?.string(),
                    response.request.url.toString(),
                )
            }
        }
    }
}
