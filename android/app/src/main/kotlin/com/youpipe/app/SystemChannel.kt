package com.youpipe.app

import android.Manifest
import android.app.Activity
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `youpipe/system`: small platform needs: the Android 13+ notification permission for playback and downloads, and
 * what kind of device this is (TV, picture-in-picture support; docs/ui.md).
 */
object SystemChannel {
    /** Most TVs (and Fire TV) have no picture-in-picture. */
    fun supportsPip(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

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

                "device" -> {
                    val pm = activity.packageManager
                    val uiMode = activity.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                    result.success(
                        mapOf(
                            // Android TV, Google TV and Fire TV (which reports leanback too).
                            "tv" to (
                                uiMode.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION ||
                                    pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
                            ),
                            "pip" to supportsPip(activity),
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
    }
}
