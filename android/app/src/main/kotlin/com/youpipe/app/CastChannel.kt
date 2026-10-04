package com.youpipe.app

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.Cast
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.MediaStatus
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.CastState
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.images.WebImage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Casting, native side (docs/cast.md).
 *
 * - Chromecast through the Google Cast SDK: device list (`routes` events), `selectRoute`, and one
 *   song at a time with `load`; the receiver's state comes back as `state`/`player` events. Without
 *   Google Play services there are simply no Chromecast devices.
 * - The video relay ([CastProxy]) for both Chromecast and DLNA: `relayStart`, `relayUrl`,
 *   `relayStop`. DLNA itself is done in Dart (lib/player/dlna.dart).
 *
 * The queue stays in Dart (PlaybackController).
 */
@SuppressLint("StaticFieldLeak")
object CastChannel {
    private val main = Handler(Looper.getMainLooper())
    private val loader = Executors.newSingleThreadExecutor()

    private var app: Context? = null
    private var castContext: CastContext? = null
    private var router: MediaRouter? = null
    private var sink: EventChannel.EventSink? = null
    private var session: CastSession? = null
    private var relaying = false
    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null

    fun register(
        activity: Activity,
        messenger: BinaryMessenger,
    ) {
        app = activity.applicationContext
        if (castContext == null) {
            castContext = createContext(activity.applicationContext)
            if (castContext != null) router = MediaRouter.getInstance(activity.applicationContext)
        }

        EventChannel(messenger, "youpipe/cast/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    sink = events
                    emitState()
                    emitRoutes()
                    session?.remoteMediaClient?.let(::emitPlayer)
                }

                override fun onCancel(arguments: Any?) {
                    sink = null
                }
            },
        )

        MethodChannel(messenger, "youpipe/cast").setMethodCallHandler { call, result ->
            val client = session?.remoteMediaClient
            when (call.method) {
                "selectRoute" -> {
                    val id = call.argument<String>("id")
                    router?.routes?.firstOrNull { it.id == id }?.select()
                    result.success(null)
                }

                "load" -> load(call.arguments as Map<*, *>, result)
                "play" -> {
                    client?.play()
                    result.success(null)
                }

                "pause" -> {
                    client?.pause()
                    result.success(null)
                }

                "seek" -> {
                    val ms = (call.argument<Number>("positionMs") ?: 0).toLong()
                    client?.seek(MediaSeekOptions.Builder().setPosition(ms).build())
                    result.success(null)
                }

                "setVolume" -> {
                    runCatching { session?.volume = call.argument<Double>("volume") ?: 0.0 }
                    result.success(null)
                }

                "disconnect" -> {
                    castContext?.sessionManager?.endCurrentSession(true)
                    result.success(null)
                }

                "relayStart" -> {
                    relaying = true
                    holdLocks()
                    CastProxy.start()
                    result.success(null)
                }

                "relayUrl" -> {
                    val videoId = call.argument<String>("videoId")!!
                    val localPath = call.argument<String>("localPath")
                    loader.execute {
                        val registered = runCatching { CastProxy.register(videoId, localPath) }
                        main.post {
                            val song = registered.getOrNull()
                            if (song == null) {
                                val message = registered.exceptionOrNull()?.message ?: "Not on a local network"
                                result.error("NO_STREAM", message, null)
                            } else {
                                result.success(mapOf("url" to song.url, "contentType" to song.contentType))
                            }
                        }
                    }
                }

                "relayStop" -> {
                    relaying = false
                    releaseIfIdle()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun createContext(app: Context): CastContext? {
        if (GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(app) != ConnectionResult.SUCCESS) {
            return null
        }
        @Suppress("DEPRECATION")
        val context = runCatching { CastContext.getSharedInstance(app) }.getOrNull() ?: return null
        context.addCastStateListener(stateListener)
        context.sessionManager.addSessionManagerListener(sessionListener, CastSession::class.java)
        context.sessionManager.currentCastSession?.let(::attach)
        return context
    }

    private fun selector(): MediaRouteSelector =
        castContext?.mergedSelector
            ?: MediaRouteSelector
                .Builder()
                .addControlCategory(
                    CastMediaControlIntent.categoryForCast(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID),
                ).build()

    private val routerCallback =
        object : MediaRouter.Callback() {
            override fun onRouteAdded(
                router: MediaRouter,
                route: MediaRouter.RouteInfo,
            ) = emitRoutes()

            override fun onRouteRemoved(
                router: MediaRouter,
                route: MediaRouter.RouteInfo,
            ) = emitRoutes()

            override fun onRouteChanged(
                router: MediaRouter,
                route: MediaRouter.RouteInfo,
            ) = emitRoutes()
        }

    /**
     * Actively looks for Chromecasts while the app is on screen, as a Cast button does; the Cast SDK
     * on its own only scans passively. Called from MainActivity.
     */
    fun setForeground(visible: Boolean) {
        val router = router ?: return
        if (visible) {
            router.addCallback(
                selector(),
                routerCallback,
                MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY or MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN,
            )
        } else {
            router.removeCallback(routerCallback)
        }
    }

    /** Registers the song with the relay (network work, off the main thread), then loads it on the receiver. */
    private fun load(
        args: Map<*, *>,
        result: MethodChannel.Result,
    ) {
        val videoId = args["videoId"] as String
        val localPath = args["localPath"] as String?
        loader.execute {
            val registered = runCatching { CastProxy.register(videoId, localPath) }
            main.post {
                val client = session?.remoteMediaClient
                val song = registered.getOrNull()
                when {
                    client == null -> result.error("NO_SESSION", "Not casting", null)
                    song == null ->
                        result.error(
                            "NO_STREAM",
                            registered.exceptionOrNull()?.message ?: "The phone isn't on a local network",
                            null,
                        )

                    else -> {
                        val metadata =
                            MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE).apply {
                                putString(MediaMetadata.KEY_TITLE, args["title"] as String? ?: "")
                                (args["artist"] as String?)?.let { putString(MediaMetadata.KEY_SUBTITLE, it) }
                                (args["artUrl"] as String?)?.let { addImage(WebImage(Uri.parse(it))) }
                            }
                        val info =
                            MediaInfo
                                .Builder(song.url)
                                .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
                                .setContentType(song.contentType)
                                .setMetadata(metadata)
                                .apply { (args["durationMs"] as Number?)?.let { setStreamDuration(it.toLong()) } }
                                .build()
                        val request =
                            MediaLoadRequestData
                                .Builder()
                                .setMediaInfo(info)
                                .setAutoplay(args["autoplay"] as Boolean? ?: true)
                                .setCurrentTime((args["positionMs"] as Number?)?.toLong() ?: 0L)
                                .build()
                        client.load(request)
                        // Receiver events carry this URL, so Dart can tell which song they're about.
                        result.success(song.url)
                    }
                }
            }
        }
    }

    // Session and receiver state -------------------------------------------------------------------

    private val stateListener = CastStateListener { emitState() }

    private val castListener =
        object : Cast.Listener() {
            override fun onVolumeChanged() = emitState()
        }

    private val mediaCallback =
        object : RemoteMediaClient.Callback() {
            override fun onStatusUpdated() {
                session?.remoteMediaClient?.let(::emitPlayer)
            }
        }

    private val progressListener =
        RemoteMediaClient.ProgressListener { _, _ -> session?.remoteMediaClient?.let(::emitPlayer) }

    private val sessionListener =
        object : SessionManagerListener<CastSession> {
            override fun onSessionStarted(
                session: CastSession,
                sessionId: String,
            ) = attach(session)

            override fun onSessionResumed(
                session: CastSession,
                wasSuspended: Boolean,
            ) = attach(session)

            override fun onSessionEnded(
                session: CastSession,
                error: Int,
            ) = detach()

            override fun onSessionSuspended(
                session: CastSession,
                reason: Int,
            ) = emitState()

            override fun onSessionStarting(session: CastSession) = emitState()

            override fun onSessionStartFailed(
                session: CastSession,
                error: Int,
            ) = emitState()

            override fun onSessionEnding(session: CastSession) = Unit

            override fun onSessionResuming(
                session: CastSession,
                sessionId: String,
            ) = Unit

            override fun onSessionResumeFailed(
                session: CastSession,
                error: Int,
            ) = detach()
        }

    private fun attach(session: CastSession) {
        this.session = session
        session.addCastListener(castListener)
        session.remoteMediaClient?.registerCallback(mediaCallback)
        session.remoteMediaClient?.addProgressListener(progressListener, 1000)
        holdLocks()
        CastProxy.start()
        emitState()
    }

    private fun detach() {
        session?.removeCastListener(castListener)
        session?.remoteMediaClient?.unregisterCallback(mediaCallback)
        session?.remoteMediaClient?.removeProgressListener(progressListener)
        session = null
        releaseIfIdle()
        emitState()
    }

    /** Keeps Wi-Fi and the CPU awake while casting, so the relay keeps serving with the screen off. */
    private fun holdLocks() {
        val app = app ?: return
        if (wifiLock == null) {
            @Suppress("DEPRECATION")
            wifiLock =
                app
                    .getSystemService(WifiManager::class.java)
                    .createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "YouPipe:cast")
                    .apply { setReferenceCounted(false) }
        }
        if (wakeLock == null) {
            wakeLock =
                app
                    .getSystemService(PowerManager::class.java)
                    .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "YouPipe:cast")
                    .apply { setReferenceCounted(false) }
        }
        wifiLock?.acquire()
        @SuppressLint("WakelockTimeout")
        wakeLock?.acquire()
    }

    /** Stops the relay and lets the phone sleep once neither Chromecast nor DLNA is casting. */
    private fun releaseIfIdle() {
        if (session != null || relaying) return
        CastProxy.stop()
        wifiLock?.takeIf { it.isHeld }?.release()
        wakeLock?.takeIf { it.isHeld }?.release()
    }

    private fun emitRoutes() {
        val router = router ?: return
        val selector = selector()
        val routes =
            router.routes
                .filter { !it.isDefault && !it.isBluetooth && it.isEnabled && it.matchesSelector(selector) }
                .map { mapOf("id" to it.id, "name" to it.name, "description" to it.description) }
        send(mapOf("type" to "routes", "routes" to routes))
    }

    private fun emitState() {
        val state =
            when (castContext?.castState) {
                CastState.CONNECTED -> "connected"
                CastState.CONNECTING -> "connecting"
                CastState.NOT_CONNECTED -> "available"
                else -> "none"
            }
        val s = session
        send(
            mapOf(
                "type" to "state",
                "state" to state,
                "device" to s?.castDevice?.friendlyName,
                "volume" to (runCatching { s?.volume }.getOrNull() ?: 0.0),
            ),
        )
    }

    private fun emitPlayer(client: RemoteMediaClient) {
        val status = client.mediaStatus ?: return
        val state =
            when (status.playerState) {
                MediaStatus.PLAYER_STATE_PLAYING -> "playing"
                MediaStatus.PLAYER_STATE_PAUSED -> "paused"
                MediaStatus.PLAYER_STATE_BUFFERING, MediaStatus.PLAYER_STATE_LOADING -> "buffering"
                else -> "idle"
            }
        val idleReason =
            when (status.idleReason) {
                MediaStatus.IDLE_REASON_FINISHED -> "finished"
                MediaStatus.IDLE_REASON_ERROR -> "error"
                MediaStatus.IDLE_REASON_CANCELED -> "canceled"
                MediaStatus.IDLE_REASON_INTERRUPTED -> "interrupted"
                else -> null
            }
        send(
            mapOf(
                "type" to "player",
                "state" to state,
                "idleReason" to idleReason,
                "positionMs" to client.approximateStreamPosition,
                "durationMs" to client.streamDuration,
                "url" to client.mediaInfo?.contentId,
            ),
        )
    }

    private fun send(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }
}
