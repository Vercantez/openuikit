# AVKit (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public `AVKit`
module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester,
and TBD exports. It is not wired into the shared guest package; that
integration is a later central-review step.

The isolated host compiler has Foundation only. Product sources may
`import Foundation` and, when present, the real Apple modules. Types owned by
AVFoundation, AVFAudio, UIKit, CoreMedia, and SwiftUI are module-local
lookalikes so the AVKit overlay can compile. They are not substitutes for a
listed dependency: this seed lists Foundation only.

Second pass (`agent/fw-avkit2`): SwiftUI `View` members synthesized onto
`VideoPlayer` are identity no-ops and are `declared`, not `implemented`.
Invented success is worse than a marked gap.

## What is real

- `AVKitErrorDomain` is the string `AVKitErrorDomain`, matching the pinned
  `dotnet/macios` `[ErrorDomain ("AVKitErrorDomain")]` annotation.
- `AVKitError` is a `@frozen` `Foundation._BridgedStoredNSError` wrapper.
  `AVKitError.Code` uses `unknown = -1000` and
  `pictureInPictureStartFailed = -1001` from pinned macios. Extra macios cases
  that are absent from this seed's public graph are not declared.
- `PLATFORM_SUPPORTS_AVKITCORE` is `false` on this host.
- `AVCaptureEventPhase` raw values are `began = 0`, `ended = 1`,
  `cancelled = 2`.
- `AVDisplayDynamicRange` raw values are `automatic = 0`, `standard = 1`,
  `constrainedHigh = 2`, `high = 3`.
- `AVVideoFrameAnalysisType` is an `OptionSet` with flags `1 << 0` through
  `1 << 4` for `default`, `text`, `subject`, `visualSearch`, and
  `machineReadableCode`.
- `AVAudioSession.RouteSelection` is `none = 0`, `local = 1`, `external = 2`.
- `VideoPlayer` stores an `AVPlayer?`, composes an overlay with `ZStack`, and
  exposes Linux-host caption text (`openUIKitHostCaption`) derived from the
  selected item URL and `rate`. It does not decode frames.
- `AVPlaybackSpeed` stores `rate` and `localizedName`. `localizedNumericName`
  formats the rate with U+00D7 and drops a trailing `.0` on whole numbers
  (MEASURED iPhone 16 / iOS 26.1). `systemDefaultSpeeds` is one stable array
  of five entries (en_US): 2.0 Double / 1.5 Faster / 1.25 Fast / 1.0 Normal /
  0.5 Half
  (https://developer.apple.com/documentation/avkit/avplaybackspeed/systemdefaultspeeds).
  `AVPlayerView` is macOS-only and is not in this iPhoneOS seed.
- `AVPlayerViewController` stores the measured iPhone 16 / iOS 26.1 defaults
  (`showsPlaybackControls` true, `showsTimecodes` false, `videoGravity`
  `.resizeAspect`, `isReadyForDisplay` false, `videoBounds` zero,
  `contentOverlayView` non-nil, `allowsPictureInPicturePlayback` true,
  `allowsVideoFrameAnalysis` true, `videoFrameAnalysisTypes` `.default`,
  `canStartPictureInPictureAutomaticallyFromInline` false,
  `updatesNowPlayingInfoCenter` true, `entersFullScreenWhenPlaybackBegins`
  false, `exitsFullScreenWhenPlaybackEnds` false, `requiresLinearPlayback`
  false, `preferredDisplayDynamicRange` `.automatic`)
  (https://developer.apple.com/documentation/avkit/avplayerviewcontroller).
  `speeds` is `=== AVPlaybackSpeed.systemDefaultSpeeds`; a fresh controller's
  `selectedSpeed` is `=== systemDefaultSpeeds[3]`. `selectSpeed` is object
  identity: outsiders are ignored, a list member writes `player.defaultRate`.
  Assigning a player with a matching `defaultRate` selects that list entry.
  Isolated-host `AVPlayer` lookalike exposes `defaultRate` (Apple default 1.0)
  as a stored property: it is not KVO-compliant.
- Full-screen and PiP PVC delegate order is delivered by host test hooks
  `openUIKitHostDeliverFullScreenDelegatePair` (willBegin then willEnd) and
  `openUIKitHostDeliverPictureInPictureDelegateSequence` (willStart → didStart
  → willStop → didStop, or `failedToStart` alone)
  (https://developer.apple.com/documentation/avkit/avplayerviewcontrollerdelegate).
  Linux never presents full screen or a PiP window.
- `AVInterstitialTimeRange` is `NSCopying` + `NSSecureCoding`, copies by
  value, and round-trips a keyed overlay archive. Apple's archive keys are
  unobserved. Playback gap insertion is not performed. `init(timeRange:)`
  is tvOS-designated / `API_UNAVAILABLE(ios)` on Apple; Linux keeps it.

`CGSize` / `CGRect` / `CGFloat` values are Foundation's Linux geometry types.

## Fail-closed boundaries

Linux has no AirPlay picker, Picture in Picture session, capture hardware,
or AVKitCore runtime. The implementation never fabricates playback, PiP
windows, route sheets, or capture-button events.

- `AVPictureInPictureController.isPictureInPictureSupported()` is `false`.
  `init?(playerLayer:)` returns nil (header: when unsupported, initializers
  return nil). `init(contentSource:)` still constructs (MEASURED iPhone 16 /
  iOS 26.1). `isPictureInPicturePossible` stays false.
  `startPictureInPicture()` leaves the session inactive and calls
  `pictureInPictureController(_:failedToStartPictureInPictureWithError:)`
  with `AVKitError.pictureInPictureStartFailed` (-1001)
  (https://developer.apple.com/documentation/avkit/avpictureinpicturecontrollerdelegate/pictureinpicturecontroller(_:failedtostartpictureinpicturewitherror:)).
  `stopPictureInPicture()` on an inactive session does not fire willStop /
  didStop.
- `AVCaptureEvent.play(_:)` returns `false`. Custom
  `AVCaptureEventSound(url:)` throws `AVKitError.unknown`. Interaction
  handlers are stored and never invoked.
- `AVInputPickerInteraction.present()` / `dismiss()` keep `isPresented`
  false. No input-picker UI is shown.
- `AVAudioSession.prepareRouteSelectionForPlayback` invokes the completion
  asynchronously, exactly once, on serial queue
  `com.apple.avkit.AVKit.callback`, with `(false, .none)`.
- `AVRoutePickerView` stores `prioritizesVideoDevices` / `activeTintColor` /
  `delegate` and does not present routes (no willBegin / didEnd).
- `AVPlayerViewController` never becomes ready for display. Isolated-host
  `AVPlayer` has no `status` / `timeControlStatus` / item-ready pipeline.

## Deferred

Every public precise identifier in this seed is either `implemented` (focused
host tests) or `declared` (compiled product sources). Remaining work is
behavioral, not missing declarations:

- SwiftUI `View` members on `VideoPlayer` typecheck as identity no-ops and
  are `declared`. They are not behavioral evidence.
- Synthesized Swift operators (`!=`, `~=`) cite their owning type when they
  have no identifier spelling of their own.
- AVFoundation / SwiftUI / UIKit lookalikes give way to the real modules on a
  later EC2 integration build. Frame decoding and system PiP still cannot
  succeed without those services; the identity probe must not report a false
  Apple runtime success.
