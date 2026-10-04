package com.youpipe.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.workDataOf
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * `youpipe/downloader`: queues [DownloadWorker] jobs and reports their state. Dart keeps the Downloads table in
 * sync by polling `status` (docs/downloads.md); jobs keep running while the app is closed.
 */
object DownloadChannel {
    private const val CHANNEL = "youpipe/downloader"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(
        context: Context,
        messenger: BinaryMessenger,
    ) {
        val app = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            val work = WorkManager.getInstance(app)
            when (call.method) {
                "enqueue" -> {
                    val videoId = call.argument<String>("videoId")!!
                    val request =
                        OneTimeWorkRequestBuilder<DownloadWorker>()
                            .addTag(DownloadWorker.TAG)
                            .addTag("vid:$videoId")
                            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                            .setInputData(
                                workDataOf(
                                    DownloadWorker.KEY_VIDEO_ID to videoId,
                                    DownloadWorker.KEY_TITLE to call.argument<String>("title"),
                                    DownloadWorker.KEY_DIR to call.argument<String>("dir"),
                                    DownloadWorker.KEY_HEIGHT to (call.argument<Int>("height") ?: 720),
                                    DownloadWorker.KEY_HL to call.argument<String>("hl"),
                                    DownloadWorker.KEY_GL to call.argument<String>("gl"),
                                ),
                            ).build()
                    work.enqueueUniqueWork("download-$videoId", ExistingWorkPolicy.REPLACE, request)
                    result.success(null)
                }

                "cancel" -> {
                    work.cancelUniqueWork("download-${call.argument<String>("videoId")}")
                    result.success(null)
                }

                "status" ->
                    executor.execute {
                        try {
                            val list = work.getWorkInfosByTag(DownloadWorker.TAG).get().map(::describe)
                            mainHandler.post { result.success(list) }
                        } catch (e: Throwable) {
                            mainHandler.post { result.error("STATUS_FAILED", e.message, null) }
                        }
                    }

                // Finished jobs have been recorded in the Downloads table; drop them from WorkManager.
                "prune" -> {
                    work.pruneWork()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun describe(info: WorkInfo): Map<String, Any?> {
        val videoId = info.tags.firstOrNull { it.startsWith("vid:") }?.removePrefix("vid:")
        val state =
            when (info.state) {
                WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED -> "queued"
                WorkInfo.State.RUNNING -> "downloading"
                WorkInfo.State.SUCCEEDED -> "done"
                WorkInfo.State.FAILED -> "failed"
                WorkInfo.State.CANCELLED -> "cancelled"
            }
        return mapOf(
            "videoId" to videoId,
            "state" to state,
            "downloaded" to info.progress.getLong(DownloadWorker.KEY_DOWNLOADED, 0),
            "total" to info.progress.getLong(DownloadWorker.KEY_TOTAL, 0),
            "path" to info.outputData.getString(DownloadWorker.KEY_PATH),
            "size" to info.outputData.getLong(DownloadWorker.KEY_SIZE, 0),
            "height" to info.outputData.getInt(DownloadWorker.KEY_HEIGHT, 0),
            "error" to info.outputData.getString(DownloadWorker.KEY_ERROR),
        )
    }
}
