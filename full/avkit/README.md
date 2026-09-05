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

SDK depth, second pass. The first-pass module, fail-closed PiP / route /
capture paths, and existing `tests/agent/AVKitTests.swift` checks stay in
place. This pass extends `AVPlayerViewController` display state from the
AVFoundation-lane player item, adds PiP and sample-buffer delegate dispatch
hooks, and relabels 150 SwiftUI overlay re-exports.

Coverage before this pass: **174 implemented / 837 declared / 0 deferred /
0 unavailable / 0 not-applicable** (1011 nondeferred, floor 506).

Coverage after this pass: **192 implemented / 669 declared / 0 deferred /
0 unavailable / 150 not-applicable** (861 nondeferred, floor 506).

150 `s:7SwiftUI4View…` members synthesized onto `VideoPlayer` (excluding
AVKit-owned `onCameraCaptureEvent`) are `not-applicable` with the note
`SwiftUI cross-import overlay; owned by the SwiftUI lane`. The remaining
synthesized SwiftUI `View` members stay `declared` identity no-ops so the
sealed 506 nondeferred floor still holds; marking all 784 as not-applicable
would drop nondeferred coverage to 227. They are never `implemented`.

`AVRouteDetector`, `AVNavigationMarkersGroup`, macOS `AVPlayerView`,
`canStopPictureInPicture`, and `transportBarCustomMenuItems` are absent from
this iPhoneOS 26.1 public graph and are not invented.

Top-5 implemented evidence (192 rows; no non-enum test exceeds 40%):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 15 | 7.8% | `AVKitTests.swift#testAVKitErrorBridging` (bridged `AVKitError` / Foundation witnesses) |
| 13 | 6.8% | `AVKitTests.swift#testVideoFrameAnalysisOptionSet` (table-driven option-set members) |
| 10 | 5.2% | `AVKitTests.swift#testCaptureEventPhaseAndSounds` |
| 10 | 5.2% | `AVKitTests.swift#testPlayerViewControllerMeasuredDefaults` |
| 9 | 4.7% | `AVKitTests.swift#testPlayerViewControllerDelegateOrder` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`dd4c8bca7e8735289928bbd1abd44f4b35815308` matched.

`bash full/avkit/tests/acceptance/test_host.sh` is the sealed gate. Expected
markers:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVKit lane=medium-full symbols=1011
FRAMEWORK_FANOUT_REFERENCE_OK
AVKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVKit dylib=libAVKit.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate.

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
  not a decoded frame. The controller emits KVO for `readyForDisplay` and
  `videoBounds`.
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
  didStop. Host hooks can still deliver the documented start/stop order or
  invoke synchronous sample-buffer playback-delegate methods.
- `AVCaptureEvent.play(_:)` returns `false`. Custom
  `AVCaptureEventSound(url:)` throws `AVKitError.unknown`. Interaction
  handlers are stored and never invoked.
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
- The async sample-buffer `skipByInterval` member stays `declared`; the sealed
  runner cannot await it.
- Synthesized Swift operators (`!=`, `~=`) cite their owning type when they
  have no identifier spelling of their own.
- AVFoundation / SwiftUI / UIKit lookalikes give way to the real modules on a
  later EC2 integration build. Frame decoding and system PiP still cannot
  succeed without those services; the identity probe must not report a false
  Apple runtime success.
