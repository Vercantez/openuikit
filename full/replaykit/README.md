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

## What is real

The public Swift surface that does not require UIKit or CoreMedia compiles to
`libReplayKit.dylib`.

Implemented and exercised:

- `RPCameraPosition`, `RPSampleBufferType`, and `RPRecordingErrorCode` (including
  inequality, hashing, and `rawValue` round-trip using numeric values from
  pinned-independent-bindings `dotnet-macios` `ReplayKit/RPEnums.cs`)
- `RPScreenRecorder.shared()` identity, stored camera/microphone/position flags,
  `isAvailable == false`, `isRecording == false`
- Fail-closed `startRecording`, clip buffering, `stopCapture`, `exportClip`, and
  `discardRecording`, with completion handlers hopped once onto serial queue
  `ReplayKit.completion` (never inline)
- `stopRecording(withOutput:)` throwing `attemptToStopNonRecording` when idle
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
  `SCStreamErrorDomain`) are Linux-local identifier spellings (`declared`).

`tests/agent/ReplayKitDependencyIdentity.swift` is prepared for a future EC2
guest Foundation+UIKit+AVFoundation+CoreMedia identity run
(`REPLAYKIT_DEPENDENCY_IDENTITY_OK`); it is not compiled by the isolated host
gate.
