# MediaPlayer (Linux starting point)

This directory is a portable `MediaPlayer` tranche reconstructed from the
Xcode 26.1 iPhoneOS public symbol graph. It is **not** wired into the shared
guest package; that integration is a later central-review step. It is not an
Apple-behavioral-parity claim.

## What is real

- **Enums and option sets** (`MPError.Code`, `MPMediaType`,
  `MPNowPlayingPlaybackState`, `MPRemoteCommandHandlerStatus`, movie/music
  playback enums, and the rest of the overlay) compile with public-header raw
  values.
- **String constants** for media-item properties, now-playing keys, language
  option characteristics, and `NSNotification.Name` values.
- **`MPError` / `MPErrorDomain`**: a typed `CustomNSError` overlay. Equality
  uses Foundation dictionary value equality; hashing uses only the code.
- **`MPNowPlayingInfoCenter`**: process-local `nowPlayingInfo` and
  `playbackState`. `supportedAnimatedArtworkKeys` is empty. Nothing is
  published to Control Center, the lock screen, CarPlay, or an Apple daemon.
- **`MPRemoteCommandCenter`**: in-process command objects. Closures registered
  with `addTarget(handler:)` run only when a host calls the
  `@_spi(OpenUIKitHost)` `_openUIKit_deliver` entry point. There is no headset,
  Control Center, or CarPlay transport.
- **Media entities, queries, collections, and predicates**: local objects.
  `MPMediaQuery.items` / `collections` are `nil` because there is no iPod/Music
  library. `MPMediaLibrary.authorizationStatus()` is `.denied`;
  `addItem(withProductID:)` and playlist mutation throw `MPError.notSupported`.
- **`MPMusicPlayerController`**: distinct application vs system players, local
  queue-descriptor storage, inert `play()` / `pause()` / `stop()` that leave
  `playbackState == .stopped`. `prepareToPlay(completionHandler:)` completes
  with `MPError.notSupported`. `iPodMusicPlayer` is the same instance as
  `systemMusicPlayer`. `openToPlay` cannot launch Music.app.
- **`MPContentItem`** and **`MPPlayableContentManager`**: local metadata.
  `context.endpointAvailable` is `false`. `MPPlayableContentDataSource` and
  `MPPlayableContentDelegate` declare Apple's optional Objective-C callbacks as
  protocol requirements with extension defaults, so calls through `any`
  existentials use witness-table dispatch. Default queue/identifier/playback
  entry points fail closed with `MPError.notSupported`.
- **Volume-settings alert functions**: inert; `MPVolumeSettingsAlertIsVisible()`
  is always `false`.

## Fail-closed / unavailable

Linux `swiftc` in this gate has **Foundation only** (no UIKit, AVFoundation,
or CoreMedia). The following Apple types are omitted rather than stubbed with
fake UIKit/AV types:

- `MPVolumeView` (UIView / wireless routes)
- `MPMoviePlayerController` / `MPMoviePlayerViewController` and access/error logs
- `MPMediaPickerController`
- `MPMediaItemArtwork` image request APIs (`UIImage`, `CGSize`, `CGRect`)
- `MPMediaItemAnimatedArtwork`
- `MPNowPlayingSession` (`AVPlayer`)
- `AVPlayerItem.nowPlayingInfo` and `AVMediaSelection*` helpers
- `MPAdTimeRange` (`CMTimeRange`)
- `NSUserActivity.externalMediaContentIdentifier` (no `NSUserActivity` on Linux Foundation)
- Objective-C `Selector` target/action on `MPRemoteCommand`

`NSCoding` initializers return `nil`; archives are not claimed compatible.

## Still deferred / oracle-owned

Exact constant strings, default remote-command `isEnabled` flags, now-playing
publication rules, media-library authorization on a real device, Music.app
`prepareToPlay` error codes, and `MPMusicPlayerPlayParameters` rejection
rules are listed in `oracle-questions.tsv`. Until those are observed on an
Apple runtime, this tranche keeps the conservative Linux behavior above.

The isolated runtime probe is `tests/agent/MediaPlayerRuntime.swift` and prints
`MEDIAPLAYER_AGENT_RUNTIME_OK`. Run `bash tests/acceptance/test_host.sh`
from this directory to compile the module, link `libMediaPlayer.dylib`, and
execute that probe. That isolated gate does **not** prove an integrated guest
Foundation + CoreGraphics link.

`tests/agent/MediaPlayerDependencyIdentity.swift` is the future EC2 client: it
imports `Foundation`, `CoreGraphics`, and `MediaPlayer`, re-checks existential
witness dispatch, and asserts `libMediaPlayer.dylib` is loaded. Artwork APIs
remain unavailable until UIKit exists; this module does not define `UIImage`,
`CGSize`, or `CGRect` lookalikes.
