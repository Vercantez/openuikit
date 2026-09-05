# MediaPlayer (Linux corpus surface)

Fail-closed portable `MediaPlayer` for the OpenUIKit Linux guest. Public
Xcode 26.1 iPhoneOS Swift surface, 895 precise IDs.

**Oracle:** `/tmp/mp_oracle.json` from `com.openuikit.mporacle` on
`OpenUIKit-2x-fw-mediaplayer` (iPhone SE 3rd gen, 375×667 @2x, iOS 26.1).

## What is real

- Enum and option-set **raw values** match the oracle (not declaration
  order). `MPRemoteCommandHandlerStatus.success` is 0;
  `commandFailed` is 200. `MPNowPlayingPlaybackState.stopped` is 3.
- `MPErrorDomain` is `MPErrorDomain`; `MPError.Code.notSupported` is 5.
- `MPMediaItemProperty*` / playlist keys are the short Darwin payloads
  (`title`, `albumPID`, `playlistPersistentID`, …). Now Playing keys keep
  the `MPNowPlayingInfoProperty*` spelling except
  `MPNowPlayingInfoPropertyCurrentLanguageOptions` →
  `MPNowPlayingInfoPropertyCurrentLanguageOption` (singular).
- Language-option characteristics are the `public.*` AVMediaCharacteristic
  strings.
- Notification `rawValue`s end in `Notification`.
- `MPNowPlayingInfoCenter.default()` stores a process-local dictionary and
  `playbackState`. `supportedAnimatedArtworkKeys` is
  `[MPNowPlayingInfoProperty3x4AnimatedArtwork]`.
- `MPRemoteCommandCenter.shared()` exposes every command. Handlers run
  in-process through `@_spi(OpenUIKitHost) openuikit_invoke`.
  `addTarget(_:action:)` / `removeTarget(_:action:)` are implemented.
  Skip-interval default is `[10]`; rating min/max at rest are 0.
- `MPMediaLibrary.authorizationStatus` is `.denied` until
  `openuikit_loadFixtureLibrary` (then `.authorized`). Unauthorized
  `MPMediaQuery.items` is `nil`. Queries filter (`equalTo` / `contains`)
  and group over the fixture. `canFilter(byProperty:)` follows the
  measured item vs entity tables.
- `MPMusicPlayerController` play/pause/stop/skip is an in-process state
  machine when `setQueue` has items. Empty-queue `play()` stays `.stopped`
  (measured). Defaults: `repeatMode == .none`, `shuffleMode == .off`,
  `currentPlaybackRate == 0`. Notifications fire only between
  `beginGeneratingPlaybackNotifications` / `endGeneratingPlaybackNotifications`.
- `MPMediaItemArtwork.image(at:)` calls the request handler.
  `init(image:)` bounds equal `image.size`.
- `MPVolumeView()` frame is `.zero`, `showsRouteButton == false`,
  `showsVolumeSlider == true`. Slider/route rects fail closed to `.zero`
  (one 200×44 route-button sample is in the report; no general rule).
- `MPMediaPickerController` is a fail-closed `UIViewController`. Defaults:
  `allowsPickingMultipleItems == false`, `showsCloudItems == true`,
  `showsItemsWithProtectedAssets == true`.

## Fail-closed / omitted

- No Apple Music / iPod library / CarPlay endpoint.
- `MPAdTimeRange` (`CMTimeRange`), `AVPlayer` now-playing session members,
  `MPMediaItemAnimatedArtwork`, movie-player `view` / thumbnail /
  `MPMoviePlayerViewController` remain unavailable.
- Volume-settings alerts never become visible.
- Isolated-host `UIImage`/`UIView`/`UIViewController` in `MPHostTypes.swift`
  are not UIKit identity; the guest imports OpenUIKit.

## Tests

`tests/agent/MediaPlayerRuntime.swift` prints `MEDIAPLAYER_AGENT_RUNTIME_OK`.
