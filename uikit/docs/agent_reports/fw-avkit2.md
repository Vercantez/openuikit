# AVKit SDK depth, second pass (agent/fw-avkit2)

Base: `origin/agent/fw-avkit` (first pass, refused for coverage honesty).
Scope: `full/avkit/` plus this report. No uikit sources, no `reference/`
or `tests/acceptance/` edits, no pin files.

## What was refused

`coverage.tsv` marked **990** identifiers `implemented`, but **782** of
942 non-table implemented rows cited one test
(`tests/agent/AVKitViewTests.swift#testVideoPlayerViewSurfaceNoops`) — a
bulk relabel of the SwiftUI `View`/modifier surface as "no-op
implemented". Invented success is worse than a marked gap.
`implemented` evidence must be a focused test of that identifier's
behaviour. Only enum/option-set members and C `k…` constants may share
one table-driven value test.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| first pass (refused) | 990 | 21 | 0 | 1011 |
| this pass | **174** | **837** | 0 | 1011 |

Public surface is still 1011 precise IDs. The medium-full floor is 506
nondeferred; 1011 remains well above it.

Every row whose only evidence was `testVideoPlayerViewSurfaceNoops` is
`declared` again with `source:full/avkit/AVKitViewModifiers.swift#<func>`
(the identity no-op in that file), except
`AVVideoFrameAnalysisType.update(with:)` which is an OptionSet operation
and stays `implemented` under `testVideoFrameAnalysisOptionSet`.
`AVKitViewTests.swift` is deleted. Identity View modifiers that the first
pass cited from `testVideoPlayerOnCameraCaptureEvent` /
`testVideoPlayerViewModifiers` are `declared` too.

No implemented test is cited by more than 40% of the non-table implemented
rows (max is 15 / 151 = 9.9%, `testAVKitErrorBridging`).

## Evidence distribution (top 5 tests by row count)

1. `testAVKitErrorBridging` — 15 (bridged `AVKitError` / `NSError` witnesses)
2. `testVideoFrameAnalysisOptionSet` — 13 (OptionSet members + `update`/`union`/`contains`)
3. `testCaptureEventPhaseAndSounds` — 10
4. `testPlayerViewControllerMeasuredDefaults` — 10 (stored flags MEASURED iPhone 16 / iOS 26.1)
5. `testPlayerViewControllerDelegateOrder` — 9 (host-hook lifecycle)

32 distinct cited tests. 174 implemented rows.

## Behaviour this pass actually tests

Cited Apple documentation, not a comparison-score search.

1. **AVPlayerViewController value semantics.** Apple
   (https://developer.apple.com/documentation/avkit/avplayerviewcontroller):
   `showsPlaybackControls` default true, `videoGravity` `.resizeAspect`,
   `allowsPictureInPicturePlayback` true,
   `entersFullScreenWhenPlaybackBegins` / `exitsFullScreenWhenPlaybackEnds`
   / `requiresLinearPlayback` false (MEASURED OpenUIKit-Chrome-fw-avkit,
   iPhone 16 / iOS 26.1). Those six round-trip. `contentOverlayView` is
   non-nil, `videoBounds` is zero, `isReadyForDisplay` stays false with or
   without an assigned player (no decoded first frame).
2. **Player assignment and KVO gap.** Assigning `player` stores identity
   and selects `selectedSpeed` from `player.defaultRate` (MEASURED 1.5).
   Isolated-host `AVPlayer` is a stored-property lookalike, not
   AVFoundation's KVO-compliant player
   (https://developer.apple.com/documentation/avfoundation/avplayer/rate).
   Runtime gaps: no `status` / `timeControlStatus` / `currentItem.status`
   pipeline, so `isReadyForDisplay` never becomes true. Listed in
   `oracle-questions.tsv`.
3. **Speeds.** Apple `AVPlaybackSpeed.systemDefaultSpeeds`
   (https://developer.apple.com/documentation/avkit/avplaybackspeed/systemdefaultspeeds).
   MEASURED en_US: 2.0 Double / 1.5 Faster / 1.25 Fast / 1.0 Normal /
   0.5 Half. `selectSpeed` is object identity; a list member writes
   `player.defaultRate`.
4. **Delegate order via a test hook.** Linux never presents full screen or
   PiP. `openUIKitHostDeliverFullScreenDelegatePair` delivers willBegin then
   willEnd
   (https://developer.apple.com/documentation/avkit/avplayerviewcontrollerdelegate).
   `openUIKitHostDeliverPictureInPictureDelegateSequence` delivers
   willStart → didStart → willStop → didStop, or `failedToStart` alone.
   Coordinator `animate(alongside:)` timing is unobserved.
5. **AVPictureInPictureController fail-closed.** `isPictureInPictureSupported()`
   is false; `init(playerLayer:)` returns nil (header); `init(contentSource:)`
   still constructs (MEASURED). `isPictureInPicturePossible` stays false.
   `startPictureInPicture()` calls
   `failedToStartPictureInPictureWithError` with
   `AVKitError.pictureInPictureStartFailed` (-1001)
   (https://developer.apple.com/documentation/avkit/avpictureinpicturecontrollerdelegate/pictureinpicturecontroller(_:failedtostartpictureinpicturewitherror:)).
   First-pass simulator probe observed no callback on the contentSource
   path; Linux fail-closed still delivers the documented error (see
   oracle-questions.tsv). `stopPictureInPicture()` on an inactive session
   does not fire willStop / didStop.
6. **AVRoutePickerView.** Stores `prioritizesVideoDevices` / `activeTintColor`
   / `delegate`. No route sheet, so willBegin / didEnd are not invoked.
7. **AVInterstitialTimeRange.** `NSCopying` + `NSSecureCoding` value
   identity. Archive keys are a host overlay (unobserved on Apple).
8. **AVCaptureEventInteraction.** Handlers are stored and never invoked.
   `isEnabled` / `defaultCaptureSoundDisabled` round-trip.

`avkit_guest_sources.txt` is unchanged (five sorted product sources).

## Verification

- Shared deliverable validator is green on the Mac host when main's
  lineage-aware `validate_seed.py` is used (this seed is `e44f6bde…`,
  checked-in generator is `e56ee6e7…`). This branch does not rewrite
  `scripts/framework-fanout/generate_seed_v2.py` or pin files.
- Isolated Mac `swiftc -warnings-as-errors` of `libAVKit.dylib` (5 guest
  sources). The sealed runner still `import Glibc` (immutable
  `tests/acceptance/test_host.sh`), so the load-smoke binary is Linux-only.
- Isolated Linux `swiftc -warnings-as-errors` of `libAVKit.dylib` plus 32
  cited tests in `docker exec uikit-linux` (Swift 6.2.4): stdout is exactly
  `AVKIT_AGENT_RUNTIME_OK`.
- macOS lookalikes (`os(macOS)` alongside `!canImport`) keep the isolated
  overlay compiling with Foundation only. Real AVFoundation / SwiftUI /
  UIKit are still imported when those modules exist and the OS is not
  macOS (later EC2 iOS integration).

## Open (oracle-questions.tsv)

- Route-selection completion queue and `(Bool, RouteSelection)` pair.
- Capture-sound URL failure code.
- Input-picker `isPresented` sequencing.
- Interstitial archive keys.
- `systemDefaultSpeeds` names off `en_US`.
- Apple's unsupported PiP `startPictureInPicture` delegate payload vs the
  first-pass simulator (no callback).
- Whether `AVPlayerViewController.player` assignment subscribes to
  AVPlayer KVO on iOS 26.1.
- `selectSpeed` then replace player.
- Full-screen coordinator `animate(alongside:)` order.
- `VideoPlayer.body` update / z-order.
- Bridged `AVKitError` hash payload.
