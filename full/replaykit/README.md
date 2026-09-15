# ReplayKit

Linux starting point for Apple's public `ReplayKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

The legacy fan-out branch `cursor/port-replaykit-to-linux-7961` (platform PR
#13) was not readable from this GitHub App token (scoped to
`Vercantez/openuikit` only). This tree is a seed-based deliverable that follows
the in-repo repair brief for PR #13: do not ship module-local `UIView`,
`UIViewController`, `UIImage`, `CMSampleBuffer`, or `NSExtensionContext`
lookalikes; compile dependency-bearing APIs only against real UIKit / CoreMedia
/ Foundation types; omit those APIs on the isolated Linux toolchain and keep
capture, broadcast, entitlement, and Apple-service behavior fail-closed.

The monorepo `full/replaykit/reference/` dossier is the current seed (generator
SHA `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`); it was
kept as-is. The platform `reference/` could not be compared (`unavailable`).

## Coverage (wave 4 depth pass)

Before: 108 implemented / 4 declared / 0 deferred / 23 unavailable (135 total).
After: 112 implemented / 0 declared / 0 deferred / 23 unavailable (135 total).
Implemented gain: +4 (the four string constants below are now exercised by
`testReplayKitStringConstants`). All 112 implemented rows cite contract-form
`test:full/replaykit/tests/agent/<File>Tests.swift#testName` evidence: eleven
top-level synchronous no-argument `func test*()` probes in
`ReplayKitEnumTests.swift` (table-driven raw-value coverage of
`RPCameraPosition`, `RPSampleBufferType`, and all 38 `RPRecordingErrorCode`
cases), `ReplayKitConstantTests.swift`, `ReplayKitScreenRecorderTests.swift`,
`ReplayKitBroadcastTests.swift`, and `ReplayKitHandlerTests.swift`. The largest
single-test share is the error-code table test at 43/112 rows (38.4%, the
contract's explicitly allowed enum table test); every other cited test backs at
most 13 rows. No cited test uses `DispatchQueue.main`, `RunLoop`, semaphore
waits, or `await`.

## What is real

The public Swift surface that does not require UIKit or CoreMedia compiles to
`libReplayKit.dylib`.

Implemented and exercised:

- `RPCameraPosition`, `RPSampleBufferType`, and `RPRecordingErrorCode` (including
  inequality, hashing, and `rawValue` round-trip using numeric values from
  pinned-independent-bindings `dotnet-macios` `ReplayKit/RPEnums.cs`)
- `RPScreenRecorder.shared()` identity, stored camera/microphone/position flags,
  `isAvailable == false`, `isRecording == false`
- Fail-closed `startRecording`, clip buffering, `stopCapture`, `exportClip`
  (both the async `exportClip(to:duration:)` projection and the
  `exportClip(to:duration:completionHandler:)` entry point), and
  `discardRecording`, with completion handlers hopped once onto serial queue
  `ReplayKit.completion` (never inline)
- `stopRecording(withOutput:)` throwing `attemptToStopNonRecording` when idle,
  plus a completion-handler overload `stopRecording(withOutput:completionHandler:)`
  that delivers the same fail-closed error on serial queue
  `ReplayKit.completion` (never inline); the async form is the projected shape of
  ObjC `stopRecordingWithOutputURL:completionHandler:`, the overload is the
  synchronously callable entry point
- `RPBroadcastController` fail-closed `startBroadcast` (`entitlements`) and
  `finishBroadcast` (`broadcastInvalidSession`); pause/resume remain inert
- `RPBroadcastConfiguration` get/set plus `NSSecureCoding` round-trip of
  `clipDuration`
- `RPBroadcastHandler` / `RPBroadcastMP4ClipHandler` / `RPBroadcastSampleHandler`
  subclass overrides through the class hierarchy
- Delegate assignment and existential dispatch for
  `RPScreenRecorderDelegate.screenRecorderDidChangeAvailability` and
  `RPBroadcastControllerDelegate`

## Fail-closed / omitted

- No screen capture, microphone/camera capture, clip export, or Apple broadcast
  session ever becomes active.
- Isolated Linux has no UIKit or CoreMedia. `RPPreviewViewController`,
  `RPBroadcastActivityViewController`, `RPSystemBroadcastPickerView`,
  `cameraPreviewView`, `NSExtensionContext` broadcast helpers, `startCapture`,
  `processSampleBuffer`, and `stopRecording(handler:)` (preview controller) are
  compiled only when those modules exist. Coverage records those rows
  `unavailable`.
- String constant payloads (`RPRecordingErrorDomain`, key names,
  `SCStreamErrorDomain`) are Linux-local identifier spellings (`implemented` via
  `testReplayKitStringConstants`, which pins each spelling and cross-checks
  inequality; Darwin NSString bytes remain unobserved, see
  `oracle-questions.tsv`).

`tests/agent/ReplayKitDependencyIdentity.swift` is prepared for a future EC2
guest Foundation+UIKit+AVFoundation+CoreMedia identity run
(`REPLAYKIT_DEPENDENCY_IDENTITY_OK`); it is not compiled by the isolated host
gate.
