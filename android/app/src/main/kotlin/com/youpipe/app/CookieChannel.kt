package com.youpipe.app

import android.webkit.CookieManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the WebView cookie jar after the user signs in to YouTube.
 *
 * The auth cookies (SID, HSID, SSID, ...) are HttpOnly, so they can't be read from JavaScript;
 * CookieManager exposes them to the app.
 */
object CookieChannel {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "youpipe/cookies").setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(CookieManager.getInstance().getCookie(call.argument<String>("url")!!))
                "clear" -> {
                    CookieManager.getInstance().removeAllCookies { removed ->
                        CookieManager.getInstance().flush()
                        result.success(removed)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
