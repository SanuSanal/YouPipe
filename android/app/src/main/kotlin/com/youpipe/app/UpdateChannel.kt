package com.youpipe.app

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Platform side of the in-app updater (lib/data/updater.dart): app version and ABIs, installing a
 * downloaded APK through a PackageInstaller session, and opening links.
 *
 * The session hands Android's own "Update this app?" screen to the user; if installs from this app
 * aren't allowed yet, that screen sends them to the "Allow from this source" setting first.
 */
class UpdateChannel(
    private val activity: Activity,
) {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "appInfo" -> result.success(appInfo())
                "install" -> install(call.argument<String>("path")!!, result)
                "openUrl" -> {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url")!!))
                    activity.startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun appInfo(): Map<String, Any?> {
        val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
        val versionCode =
            if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else @Suppress("DEPRECATION") info.versionCode.toLong()
        return mapOf(
            "versionName" to info.versionName,
            "versionCode" to versionCode,
            "abis" to Build.SUPPORTED_ABIS.toList(),
            // For bug reports from the Error log page.
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})",
        )
    }

    private fun install(
        path: String,
        result: MethodChannel.Result,
    ) {
        val installer = activity.packageManager.packageInstaller
        val sessionId: Int
        try {
            val params =
                PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL).apply {
                    setAppPackageName(activity.packageName)
                }
            sessionId = installer.createSession(params)
        } catch (e: Throwable) {
            result.error("INSTALL_FAILED", e.message ?: e.javaClass.simpleName, null)
            return
        }
        // Listen before committing so the status broadcast can't be missed.
        val action = "${activity.packageName}.INSTALL_STATUS.$sessionId"
        val receiver = listenForStatus(action, result)
        executor.execute {
            try {
                installer.openSession(sessionId).use { session ->
                    val file = File(path)
                    session.openWrite("base.apk", 0, file.length()).use { out ->
                        file.inputStream().use { it.copyTo(out) }
                        session.fsync(out)
                    }
                    val flags =
                        PendingIntent.FLAG_UPDATE_CURRENT or
                            (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
                    val intent = Intent(action).setPackage(activity.packageName)
                    session.commit(PendingIntent.getBroadcast(activity, sessionId, intent, flags).intentSender)
                }
            } catch (e: Throwable) {
                installer.abandonSessionQuietly(sessionId)
                mainHandler.post {
                    activity.unregisterReceiver(receiver)
                    result.error("INSTALL_FAILED", e.message ?: e.javaClass.simpleName, null)
                }
            }
        }
    }

    private fun PackageInstaller.abandonSessionQuietly(sessionId: Int) {
        try {
            abandonSession(sessionId)
        } catch (_: Throwable) {
        }
    }

    /** Relays the session's status: shows the confirmation screen, then answers [result] once. */
    private fun listenForStatus(
        action: String,
        result: MethodChannel.Result,
    ): BroadcastReceiver {
        val receiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    context: Context,
                    intent: Intent,
                ) {
                    val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
                    if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
                        val confirm =
                            if (Build.VERSION.SDK_INT >= 33) {
                                intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                intent.getParcelableExtra(Intent.EXTRA_INTENT)
                            }
                        confirm?.let { activity.startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                        return
                    }
                    activity.unregisterReceiver(this)
                    val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE) ?: "status $status"
                    when (status) {
                        PackageInstaller.STATUS_SUCCESS -> result.success(null)
                        PackageInstaller.STATUS_FAILURE_ABORTED -> result.error("CANCELLED", message, null)
                        PackageInstaller.STATUS_FAILURE_CONFLICT, PackageInstaller.STATUS_FAILURE_INCOMPATIBLE ->
                            if (message.contains("DOWNGRADE", ignoreCase = true)) {
                                result.error("DOWNGRADE", message, null)
                            } else {
                                result.error("SIGNATURE_MISMATCH", message, null)
                            }
                        else -> result.error("INSTALL_FAILED", message, null)
                    }
                }
            }
        val filter = IntentFilter(action)
        if (Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            activity.registerReceiver(receiver, filter)
        }
        return receiver
    }

    companion object {
        private const val CHANNEL = "youpipe/updater"
    }
}
