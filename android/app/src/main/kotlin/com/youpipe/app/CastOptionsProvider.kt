package com.youpipe.app

import android.content.Context
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions

/**
 * Cast setup (docs/cast.md): Google's Default Media Receiver, so there's no receiver app to
 * register. The Cast SDK's own media session and notification are off: audio_service's
 * notification and the lock screen player keep controlling playback while casting.
 */
class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions =
        CastOptions
            .Builder()
            .setReceiverApplicationId(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID)
            .setCastMediaOptions(
                CastMediaOptions
                    .Builder()
                    .setNotificationOptions(null)
                    .setMediaSessionEnabled(false)
                    .build(),
            ).build()

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? = null
}
