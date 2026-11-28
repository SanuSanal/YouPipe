package com.youpipe.app

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.view.View
import android.util.Rational
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var pipChannel: MethodChannel? = null

    /** Set by Dart while a video plays on the watch page: leaving the app then shrinks it to picture-in-picture. */
    private var pipArmed = false
    private var pipAspect = Rational(16, 9)

    /** Whether the video plays, for the PiP window's play/pause button. */
    private var pipPlaying = false

    /** The PiP window's buttons (see [actions]): sent on to Dart, which runs them like the notification's. */
    private val pipActionReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                intent.getStringExtra(PIP_ACTION_NAME)?.let { pipChannel?.invokeMethod("action", it) }
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ContextCompat.registerReceiver(
            this,
            pipActionReceiver,
            IntentFilter(PIP_ACTION),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        // Android's own focus highlight (from the legacy window theme: a lime frame round the whole app) shows once a
        // key is pressed, e.g. a TV remote or a keyboard. Flutter draws its own focus, so turn Android's off.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            findViewById<View>(FLUTTER_VIEW_ID)?.defaultFocusHighlightEnabled = false
        }
    }

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
                            pipPlaying = call.argument<Boolean>("playing") ?: false
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

    /**
     * Previous, play/pause and next in the PiP window, like YouTube's. Stock Android makes them from the media session
     * when an app gives none, but other system UIs (vivo's OriginOS) then show no playback buttons at all.
     */
    private fun actions(): List<RemoteAction> {
        fun action(name: String, icon: Int, title: String, request: Int): RemoteAction {
            val intent = Intent(PIP_ACTION).setPackage(packageName).putExtra(PIP_ACTION_NAME, name)
            val pending =
                PendingIntent.getBroadcast(
                    this,
                    request,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
            return RemoteAction(Icon.createWithResource(this, icon), title, title, pending)
        }
        return listOf(
            action("previous", R.drawable.ic_pip_previous, "Previous", 1),
            if (pipPlaying) {
                action("toggle", R.drawable.ic_pip_pause, "Pause", 2)
            } else {
                action("toggle", R.drawable.ic_pip_play, "Play", 2)
            },
            action("next", R.drawable.ic_pip_next, "Next", 3),
        )
    }

    private fun params(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val builder = PictureInPictureParams.Builder().setAspectRatio(pipAspect).setActions(actions())
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

    override fun onDestroy() {
        unregisterReceiver(pipActionReceiver)
        super.onDestroy()
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
        // Closing the PiP window only stops the activity (expanding it starts it again), and the task stays, so
        // audio_service's onTaskRemoved doesn't fire: tell Dart, which stops the video like YouTube.
        if (!isInPictureInPictureMode && lifecycle.currentState == Lifecycle.State.CREATED) {
            pipChannel?.invokeMethod("closed", null)
        }
    }

    private companion object {
        const val PIP_ACTION = "com.youpipe.app.PIP_ACTION"
        const val PIP_ACTION_NAME = "name"
    }
}
