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

`tests/agent/MediaPlayerRuntime.swift` is the schema-v1 sealed-gate entry
point. It concatenates the focused `tests/agent/*Tests.swift` families,
prints `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`,
runs every `test*` function, and prints `MEDIAPLAYER_AGENT_RUNTIME_OK`.

## Depth pass 2026-09

Second pass on `origin/agent/fw-mediaplayer`. The implementation is unchanged
in spirit: in-process Now Playing, remote commands, fixture library,
music-player state machine, and fail-closed chrome. The refused ledger cited a
source-file list on all 869 `implemented` rows. This pass:

- Keeps the Linux module and fail-closed boundaries.
- Splits runtime checks into focused families under `tests/agent/*Tests.swift`.
- Cites every `implemented` row as `test:full/mediaplayer/tests/agent/<File>Tests.swift#testName`.
- Uses one table test each for `MPMediaItemProperty*` / playlist keys and
  `MPNowPlayingInfoProperty*` keys.
- Dispatches each `MPRemoteCommandCenter` command through enable / handler /
  `openuikit_invoke` / disable.
- Queries a three-item fixture library with `equalTo` / `contains` predicates
  and album grouping.
- Exercises the music-player state machine and playback notifications.
- Asserts every `MPError.Code` raw value, `~=` matching, and `MPErrorDomain`.

Deferred AVFoundation overlays and unavailable CoreMedia/UIKit view types are
unchanged. Isolated-host `UIImage` / `UIView` / `UIViewController` in
`MPHostTypes.swift` are still not UIKit identity.

Sealed gate: `bash full/mediaplayer/tests/acceptance/test_host.sh` (Linux host,
no docker). Expected markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
MEDIAPLAYER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=MediaPlayer dylib=libMediaPlayer.dylib
```
