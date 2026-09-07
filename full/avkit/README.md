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

## Depth pass 2026-09 (wave 8)

SDK depth, second pass, continued from the checked-in first-pass module. The
capture interaction host-injection state machine now honors `isEnabled`: an
enabled interaction delivers its retained handler synchronously, a disabled
interaction suppresses delivery, and re-enabling resumes delivery. This is a
deterministic host injection only; Linux still never synthesizes a hardware
capture-button event.

Coverage before this wave: **215 implemented / 646 declared / 0 deferred / 0
unavailable / 150 not-applicable** (861 nondeferred, floor 506).

Coverage after this wave: **215 implemented / 646 declared / 0 deferred / 0
unavailable / 150 not-applicable** (861 nondeferred, floor 506). The implemented
count has no census gain because all 215 non-overlay identifiers were already
implemented with focused evidence at the starting commit. Every one of the 646
remaining declared identifiers is a `s:7SwiftUI4View…` cross-import overlay
member; there is therefore no remaining non-overlay family to promote. The
binding yield alternative (exhaust every remaining non-overlay family) applies.

The 150 rows already marked `not-applicable` use the required note `SwiftUI
cross-import overlay; owned by the SwiftUI lane`. Reclassifying all other
SwiftUI overlay rows would leave only 215 nondeferred identifiers and conflict
with the immutable sealed gate's 506 minimum. This input-policy conflict remains
for central review; no overlay identity no-op was relabeled as implemented.

Top-5 implemented evidence distribution (215 rows; 40% cap = 86; enum and
option-set members may share a table-driven value test):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 6 | 2.8% | `AVKitTests.swift#testVideoFrameAnalysisOptionSet` (option-set members) |
| 5 | 2.3% | `AVKitTests.swift#testDisplayDynamicRangeRawValues` (enum cases) |
| 4 | 1.9% | `AVKitTests.swift#testRouteSelectionRawValues` (enum cases) |
| 4 | 1.9% | `AVKitTests.swift#testCaptureEventPhaseRawValues` (enum cases) |
| 3 | 1.4% | `AVKitTests.swift#testAVKitErrorCodes` (error-code cases) |

The verified campaign environment emitted
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.
The starting commit was `5a351db2038abca71a1b943af3a86963f403f724`.
The sealed gate emitted all deliverable, reference, runtime, and host markers.

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
- Display state follows the current `AVPlayerItem`: Linux `isReadyForDisplay`
  is true only when `status == .readyToPlay` and `presentationSize` is
  non-zero; `videoBounds` is origin-zero with that size. Default URL items
  match the AVFoundation lane (`readyToPlay`, `presentationSize == .zero`).
  Mutating size requires `openUIKitHostRefreshDisplayState`. This is a model,
  not a decoded frame. Isolated-host Foundation has no ObjC KVO
  (`willChangeValue` is out of scope); the properties update synchronously.
- Full-screen and PiP PVC delegate order is delivered by host test hooks
  `openUIKitHostDeliverFullScreenDelegatePair` (willBegin then willEnd) and
  `openUIKitHostDeliverPictureInPictureDelegateSequence` (willStart → didStart
  → willStop → didStop, or `failedToStart` alone)
  (https://developer.apple.com/documentation/avkit/avplayerviewcontrollerdelegate).
  Interstitial willPresent/didPresent and restore completions (`false`) have
  the same host-hook shape. Linux never presents full screen or a PiP window.
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
  didStop. Host hooks can still deliver the documented start/stop order,
  invoke synchronous sample-buffer playback-delegate methods, call the
  ObjC `skipByInterval` completion-handler selector, and fail-close restore
  UI with `false`.
- `AVCaptureEvent.play(_:)` returns `false`. Custom
  `AVCaptureEventSound(url:)` throws `AVKitError.unknown`. Hardware never
  delivers capture-button events. Host hook `openUIKitHostDeliver` invokes
  stored primary / secondary handlers so tests can observe retention.
- `AVInputPickerInteraction.present()` / `dismiss()` keep `isPresented`
  false. No input-picker UI is shown.
- `AVAudioSession.prepareRouteSelectionForPlayback` invokes the completion
  synchronously, exactly once, with `(false, .none)`. The sealed runner has
  no run loop.
- `AVRoutePickerView` stores `prioritizesVideoDevices` / `activeTintColor` /
  `delegate` and does not present routes (no willBegin / didEnd).
  `AVRouteDetector` is not in this seed.
- Default `AVPlayerViewController.isReadyForDisplay` stays false until a host
  injects a non-zero `presentationSize`. Isolated-host `AVPlayerItem` is not
  KVO-compliant; there is no decoded-frame pipeline.

## Deferred

Remaining work is behavioral, not missing declarations of the iPhoneOS graph:

- 150 SwiftUI `View` overlay re-exports are `not-applicable` (SwiftUI lane).
  Remaining synthesized `View` members, including AVKit-owned
  `onCameraCaptureEvent`, typecheck as identity no-ops and stay `declared`.
  They are not behavioral evidence.
- The Swift async overlay of sample-buffer `skipByInterval` is still not
  awaited by the sealed runner. The matching ObjC completion-handler
  selector is implemented and invoked synchronously.
- Synthesized Swift operators (`!=`, `~=`) cite their owning type when they
  have no identifier spelling of their own.
- AVFoundation / SwiftUI / UIKit lookalikes give way to the real modules on a
  later EC2 integration build. Frame decoding and system PiP still cannot
  succeed without those services; the identity probe must not report a false
  Apple runtime success.
