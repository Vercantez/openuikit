# ReplayKit (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`ReplayKit` module for OpenUIKit. It is not Apple behavioral parity, and it is
not wired into the shared guest package.

The isolated host gate compiles only these sources against the Swift 6.2.4
Linux toolchain. UIKit, AVFoundation, and CoreMedia are listed dependencies
but are not importable in that gate, so `ReplayKitLinuxSupport.swift` provides
stand-in `UIView`, `UIViewController`, `UIImage`, `CMSampleBuffer`, and
`NSExtensionContext` types. Those names exist so ReplayKit signatures
type-check; they are not a UIKit or CoreMedia port. When this module is later
compiled against real OpenUIKit, the `#if canImport` branches should take the
imported types instead.

## What is real

- The public Swift surface from the pinned Xcode 26.1 iPhoneOS graphs:
  enums, error domain, recorder, preview controller, system broadcast picker,
  broadcast controller/handlers, activity view controller, and the
  `NSExtensionContext` broadcast-setup methods.
- `RPRecordingErrorCode` numeric values reconstructed from public `RPError.h`
  (`unknown = -5800` … `exportClipToURLInProgress = -5836`,
  `codeSuccessful = 0`).
- `RPCameraPosition.front = 1` / `.back = 2` and
  `RPSampleBufferType.video = 1` / `.audioApp = 2` / `.audioMic = 3`.
- In-process state that applications actually read and write:
  singleton `RPScreenRecorder.shared()`, camera/microphone flags, camera
  position, picker `preferredExtension` / `showsMicrophoneButton`,
  `RPBroadcastConfiguration` NSSecureCoding, and subclassable
  `RPBroadcastSampleHandler` lifecycle methods used by Telegram and
  element-ios broadcast-upload extensions.
- Typed fail-closed errors using `RPRecordingErrorCode` / `RPRecordingErrorDomain`.

## What is fail-closed

Linux has no ReplayKit daemon, screen-capture stack, privacy prompt, camera
preview, Control Center picker, or broadcast-upload extension host.

- `RPScreenRecorder.isAvailable` and `isRecording` are always `false`.
- `cameraPreviewView` is always `nil`. Capture handlers are never invoked
  with sample buffers.
- `startRecording`, `startCapture`, and `startClipBuffering` complete/throw
  `failedToStartCaptureStack`.
- `stopRecording` / `stopCapture` / `stopClipBuffering` complete/throw
  `attemptToStopNonRecording` and never return a preview controller.
- `exportClip` completes/throws `failedToObtainURL` and does not write a
  movie.
- `discardRecording` still runs the handler (there is nothing to discard).
- `RPBroadcastActivityViewController.load` returns `nil` plus
  `broadcastSetupFailed`.
- `RPBroadcastController.startBroadcast` / `finishBroadcast` fail with
  `broadcastSetupFailed` / `broadcastInvalidSession`. Pause/resume do not
  invent a live session.
- `RPSystemBroadcastPickerView` stores flags and does not present a system
  picker.
- `NSExtensionContext.loadBroadcastingApplicationInfo` invokes the handler
  with empty identity values rather than inventing an app name or icon.
- `completeRequest(withBroadcast:…)` records the URL in-process only.

## Still deferred / oracle-queued

See `oracle-questions.tsv`. In particular, Darwin string payloads for
`RPRecordingErrorDomain`, `RPApplicationInfoBundleIdentifierKey`,
`RPVideoSampleOrientationKey`, and `SCStreamErrorDomain`; the exact error
code Apple uses when recording is unavailable; `broadcastURL` before a
session exists; `clipDuration` default; and whether
`finishBroadcastWithError` notifies the host.

Private TBD classes (`RPDaemonProxy`, `RPStoreManager`, overlay buttons, and
so on) are excluded.

## Tests

`tests/agent/ReplayKitRuntime.swift` exercises singleton identity, enum raw
values, fail-closed recorder/broadcast APIs, sample-handler subclassing, and
configuration coding, then prints `REPLAYKIT_AGENT_RUNTIME_OK`.

Run the gate with no `.build` / `build` / `scratch` products:

```sh
bash full/replaykit/tests/acceptance/test_host.sh
```
