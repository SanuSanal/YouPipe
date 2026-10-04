package com.youpipe.app

import android.Manifest
import android.app.Activity
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `youpipe/system`: small platform needs: the Android 13+ notification permission for playback and downloads, what
 * kind of device this is (TV, picture-in-picture support; docs/ui.md), and staying awake while a video plays
 * (docs/playback.md).
 */
object SystemChannel {
    private var wifiLock: WifiManager.WifiLock? = null

    /**
     * While a video plays: the screen stays on (only matters while the app is visible) and Wi-Fi stays out of power
     * save, so a video playing with the screen off keeps fetching. audio_service already holds the CPU wakelock.
     */
    @Suppress("DEPRECATION")
    private fun setPlaying(
        activity: Activity,
        playing: Boolean,
    ) {
        if (playing) {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        val lock =
            wifiLock ?: run {
                val wifi = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
                // What ExoPlayer's WAKE_MODE_NETWORK uses (the low-latency mode only works with the screen on).
                wifi
                    .createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "YouPipe:playback")
                    .apply { setReferenceCounted(false) }
                    .also { wifiLock = it }
            }
        if (playing && !lock.isHeld) lock.acquire() else if (!playing && lock.isHeld) lock.release()
    }

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

                "playing" -> {
                    setPlaying(activity, call.argument<Boolean>("playing") == true)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
