package com.youpipe.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import kotlinx.coroutines.CancellationException
import org.schabi.newpipe.extractor.stream.AudioTrackType
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer

/**
 * Downloads one video for offline viewing (docs/downloads.md), as a WorkManager job so it carries on when the app
 * is closed:
 * 1. resolves fresh stream URLs with NewPipeExtractor (they're bound to this phone and expire);
 * 2. fetches the H.264 video-only stream and the AAC audio stream in 1 MB ranges ([Googlevideo]);
 * 3. muxes them into one MP4 with [MediaMuxer].
 * At 360p or below, YouTube's muxed stream is downloaded directly instead.
 */
class DownloadWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    private val videoId = inputData.getString(KEY_VIDEO_ID)!!
    private val title = inputData.getString(KEY_TITLE) ?: videoId
    private val notificationId = videoId.hashCode()

    override suspend fun doWork(): Result {
        val dir = File(inputData.getString(KEY_DIR)!!)
        val maxHeight = inputData.getInt(KEY_HEIGHT, 720)
        val out = File(dir, "$videoId.mp4")
        val videoTmp = File(dir, "$videoId.video.part")
        val audioTmp = File(dir, "$videoId.audio.part")
        return try {
            setForeground(foregroundInfo(0, 0))
            StreamExtractorChannel.ensureInit(
                inputData.getString(KEY_HL) ?: "en",
                inputData.getString(KEY_GL) ?: "US",
            )
            Googlevideo.attach(applicationContext)
            val extractor = StreamExtractorChannel.fetchExtractor(videoId)
            dir.mkdirs()
            val avc =
                extractor.videoOnlyStreams
                    .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl }
                    .filter { it.codec.orEmpty().startsWith("avc1") && it.height in 1..maxHeight }
                    .maxWithOrNull(compareBy({ it.height }, { it.bitrate }))
            val aac =
                extractor.audioStreams
                    .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl }
                    .filter { it.audioTrackType == null || it.audioTrackType == AudioTrackType.ORIGINAL }
                    .filter { it.codec.orEmpty().startsWith("mp4a") }
                    .sortedBy { if (it.itagItem?.isDrc() == true) 1 else 0 }
                    .maxByOrNull { it.bitrate }
            val muxed =
                extractor.videoStreams
                    .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl && !it.isVideoOnly }
                    .maxByOrNull { it.height }
            val height: Int
            if (avc != null && aac != null && avc.height > (muxed?.height ?: 0)) {
                height = avc.height
                val videoSize = avc.itagItem?.contentLength?.takeIf { it > 0 } ?: 0L
                val audioSize = aac.itagItem?.contentLength?.takeIf { it > 0 } ?: 0L
                val total = videoSize + audioSize
                fetch(avc.content, videoTmp) { done -> progress(done, total) }
                fetch(aac.content, audioTmp) { done -> progress(videoSize + done, total) }
                mux(videoTmp, audioTmp, out)
            } else if (muxed != null) {
                height = muxed.height
                val total = muxed.itagItem?.contentLength ?: 0L
                fetch(muxed.content, out) { done -> progress(done, total) }
            } else {
                throw IllegalStateException("No downloadable stream")
            }
            Result.success(workDataOf(KEY_PATH to out.path, KEY_SIZE to out.length(), KEY_HEIGHT to height))
        } catch (e: CancellationException) {
            out.delete()
            throw e
        } catch (e: Throwable) {
            Log.w("YouPipe", "download $videoId failed", e)
            out.delete()
            Result.failure(workDataOf(KEY_ERROR to (e.message ?: e.javaClass.simpleName)))
        } finally {
            videoTmp.delete()
            audioTmp.delete()
        }
    }

    private var lastProgress = 0L

    private suspend fun progress(
        done: Long,
        total: Long,
    ) {
        val now = System.currentTimeMillis()
        if (now - lastProgress < 500 && done < total) return
        lastProgress = now
        setProgress(workDataOf(KEY_DOWNLOADED to done, KEY_TOTAL to total))
        setForeground(foregroundInfo(done, total))
    }

    /** One stream, in 1 MB ranges with the User-Agent of the client that produced the URL. */
    private suspend fun fetch(
        url: String,
        file: File,
        onProgress: suspend (Long) -> Unit,
    ) {
        var offset = 0L
        var total = -1L
        RandomAccessFile(file, "rw").use { out ->
            out.setLength(0)
            while (total < 0 || offset < total) {
                if (isStopped) throw CancellationException("stopped")
                Googlevideo.range(url, offset, offset + Googlevideo.CHUNK - 1).use { response ->
                    if (!response.isSuccessful) throw IllegalStateException("HTTP ${response.code}")
                    if (total < 0) total = Googlevideo.totalSize(response) ?: throw IllegalStateException("Unknown size")
                    val bytes = response.body?.bytes() ?: ByteArray(0)
                    if (bytes.isEmpty()) throw IllegalStateException("Empty chunk at $offset")
                    out.write(bytes)
                    offset += bytes.size
                }
                onProgress(offset)
            }
        }
    }

    private fun foregroundInfo(
        done: Long,
        total: Long,
    ): ForegroundInfo {
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Downloads", NotificationManager.IMPORTANCE_LOW),
            )
        }
        val percent = if (total > 0) (done * 100 / total).toInt() else 0
        val notification =
            NotificationCompat
                .Builder(applicationContext, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_youpipe)
                .setContentTitle(title)
                .setContentText(if (total > 0) "Downloading · $percent%" else "Preparing download…")
                .setProgress(100, percent, total <= 0)
                .setOngoing(true)
                .setSilent(true)
                .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(notificationId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(notificationId, notification)
        }
    }

    companion object {
        const val CHANNEL_ID = "downloads"
        const val TAG = "youpipe-download"
        const val KEY_VIDEO_ID = "videoId"
        const val KEY_TITLE = "title"
        const val KEY_DIR = "dir"
        const val KEY_HEIGHT = "height"
        const val KEY_HL = "hl"
        const val KEY_GL = "gl"
        const val KEY_PATH = "path"
        const val KEY_SIZE = "size"
        const val KEY_ERROR = "error"
        const val KEY_DOWNLOADED = "downloaded"
        const val KEY_TOTAL = "total"

        /** Joins a video-only MP4 and an audio-only M4A into one MP4. */
        fun mux(
            video: File,
            audio: File,
            out: File,
        ) {
            val muxer = MediaMuxer(out.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val sources = listOf(video, audio).map { f -> MediaExtractor().apply { setDataSource(f.path) } }
            try {
                val tracks =
                    sources.map { ex ->
                        ex.selectTrack(0)
                        val format = ex.getTrackFormat(0)
                        muxer.addTrack(format) to format
                    }
                muxer.start()
                sources.forEachIndexed { i, ex ->
                    val (track, format) = tracks[i]
                    val size =
                        if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                            format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
                        } else {
                            4 * 1024 * 1024
                        }
                    val buffer = ByteBuffer.allocate(maxOf(size, 1024 * 1024))
                    val info = MediaCodec.BufferInfo()
                    while (true) {
                        info.size = ex.readSampleData(buffer, 0)
                        if (info.size < 0) break
                        info.offset = 0
                        info.presentationTimeUs = ex.sampleTime
                        info.flags =
                            if (ex.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) MediaCodec.BUFFER_FLAG_KEY_FRAME else 0
                        muxer.writeSampleData(track, buffer, info)
                        ex.advance()
                    }
                }
                muxer.stop()
            } finally {
                sources.forEach { it.release() }
                muxer.release()
            }
        }
    }
}
