package com.youpipe.app

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** `youpipe/system`: small platform needs (the Android 13+ notification permission for playback and downloads). */
object SystemChannel {
    fun register(
        activity: Activity,
        messenger: BinaryMessenger,
    ) {
        MethodChannel(messenger, "youpipe/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
