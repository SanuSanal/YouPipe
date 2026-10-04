# Casting

Ported from YouPipe Music (see its `docs/cast.md` for the protocol details) and adapted for video.

- **Devices:**
  - **Chromecast** through the Google Cast SDK with the Default Media Receiver (`CastChannel.kt`, `CastOptionsProvider.kt`). Discovery is active while the app is in the foreground.
  - **DLNA/UPnP TVs** through SSDP discovery and SOAP AVTransport (`lib/player/dlna.dart`). The DIDL class is `object.item.videoItem.movie`.
- **The relay (`CastProxy.kt`):**
  - **Why:** receivers can't fetch googlevideo URLs, which are bound to the phone, so the phone serves the video on the LAN: `http://<phone-ip>:<port>/a/<token>`.
  - **What it serves:**
    - a downloaded file, at its own quality;
    - otherwise YouTube's **muxed MP4 (360p)**, fetched in 1 MB ranges with the matching User-Agent.

    A muxed file is used because every receiver can play a single progressive file, while a DASH pair would need the receiver to fetch both streams.
  - A Wi-Fi lock and wake lock are held while casting.
- **The bridge (`castBridgeProvider`, `lib/features/cast/cast_feature.dart`):**
  - **On connect:** the current video loads on the receiver at the phone's position, and the phone pauses.
  - **New videos** (a tap, the queue, autoplay) go to the receiver.
  - **When the receiver finishes**, the queue or autoplay continues.
  - **On disconnect,** the phone seeks to where the TV was.
- **UI:**
  - The Cast button (top bar, player) only shows when devices are found.
  - The sheet lists Chromecasts and DLNA TVs, with volume and Disconnect.
  - While casting, the player shows "Playing on …" with play/pause and seek, and the mini player's button drives the receiver.
- **Status:** DLNA checked on 2026-10-04 with the user's smart TV: discovery, playback (the position advances), pause from the phone, and Disconnect handing playback back to the phone. Chromecast not tried (none on the network). The TV opens the relayed stream several times while starting ("connection reset" in the `YouPipeCastProxy` log), which is normal.
- **Better quality later:** 360p comes from the muxed stream. Higher quality would need the relay to serve a DASH manifest (Chromecast supports DASH) or to mux on the fly.
