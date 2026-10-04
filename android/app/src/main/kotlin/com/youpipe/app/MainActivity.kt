package com.youpipe.app

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var pipChannel: MethodChannel? = null

    /** Set by Dart while a video plays on the watch page: leaving the app then shrinks it to picture-in-picture. */
    private var pipArmed = false
    private var pipAspect = Rational(16, 9)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        Googlevideo.attach(this)
        StreamExtractorChannel.register(messenger)
        PlaybackProxy.register(messenger)
        DownloadChannel.register(this, messenger)
        SystemChannel.register(this, messenger)
        CookieChannel.register(messenger)
        CastChannel.register(this, messenger)
        UpdateChannel(this).register(messenger)
        pipChannel =
            MethodChannel(messenger, "youpipe/pip").apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "arm" -> {
                            pipArmed = (call.argument<Boolean>("enabled") ?: false) && SystemChannel.supportsPip(this@MainActivity)
                            val w = call.argument<Int>("width") ?: 16
                            val h = call.argument<Int>("height") ?: 9
                            // Android rejects ratios outside 1:2.39..2.39:1.
                            pipAspect = Rational(w.coerceAtLeast(1), h.coerceAtLeast(1)).clamp()
                            applyParams()
                            result.success(null)
                        }

                        "enter" -> result.success(enterPip())
                        else -> result.notImplemented()
                    }
                }
            }
    }

    private fun Rational.clamp(): Rational {
        val v = toFloat()
        return when {
            v > 2.39f -> Rational(239, 100)
            v < 1 / 2.39f -> Rational(100, 239)
            else -> this
        }
    }

    private fun params(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val builder = PictureInPictureParams.Builder().setAspectRatio(pipAspect)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(pipArmed).setSeamlessResizeEnabled(true)
        }
        return builder.build()
    }

    private fun applyParams() {
        if (!SystemChannel.supportsPip(this)) return
        params()?.let { setPictureInPictureParams(it) }
    }

    private fun enterPip(): Boolean {
        val p = params() ?: return false
        return runCatching { enterPictureInPictureMode(p) }.getOrDefault(false)
    }

    override fun onResume() {
        super.onResume()
        CastChannel.setForeground(true)
    }

    override fun onPause() {
        CastChannel.setForeground(false)
        super.onPause()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Android 12+ enters on its own (setAutoEnterEnabled); older versions need the explicit call.
        if (pipArmed && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) enterPip()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("changed", isInPictureInPictureMode)
    }
}
