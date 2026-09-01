# ReplayKit (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`ReplayKit` module for OpenUIKit. It is not Apple behavioral parity, and it is
not wired into the shared guest package.

The isolated host gate compiles only these sources against the Swift 6.2.4
Linux toolchain (Foundation). It does **not** prove integrated Linux success
against UIKit, AVFoundation, or CoreMedia.

UIKit, CoreMedia, and Foundation.NSExtensionContext APIs are compiled only
when those real modules are importable. This module does not declare
lookalike `UIView`, `UIViewController`, `UIImage`, `CMSampleBuffer`, or
`NSExtensionContext` types.

## What is real in the isolated gate

- Enums and constants: `RPCameraPosition`, `RPSampleBufferType`,
  `RPRecordingErrorCode`, `RPRecordingErrorDomain`,
  `RPApplicationInfoBundleIdentifierKey`, `RPVideoSampleOrientationKey`,
  `SCStreamErrorDomain`.
- `RPScreenRecorder.shared()`, availability/recording flags, camera/mic
  position state, fail-closed start/stop/clip/export paths that do not
  mention UIKit or CoreMedia types.
- `RPBroadcastController`, `RPBroadcastConfiguration` (NSSecureCoding),
  `RPBroadcastHandler`, `RPBroadcastSampleHandler` lifecycle methods, and
  `RPBroadcastMP4ClipHandler`.
- Typed fail-closed errors using `RPRecordingErrorCode`.

## What is fail-closed

Linux has no ReplayKit daemon, screen-capture stack, privacy prompt, camera
preview, Control Center picker, or broadcast-upload extension host.

- `isAvailable` and `isRecording` are always `false`.
- `startRecording` and `startClipBuffering` complete/throw
  `failedToStartCaptureStack`.
- `stopRecording(withOutput:)`, `stopCapture`, and `stopClipBuffering`
  complete/throw `attemptToStopNonRecording`.
- `exportClip` completes/throws `failedToObtainURL` and does not write a
  movie.
- `discardRecording` still runs the handler (there is nothing to discard).
- `RPBroadcastController.startBroadcast` / `finishBroadcast` fail with
  `broadcastSetupFailed` / `broadcastInvalidSession`.

When UIKit/CoreMedia are present (EC2 integration), additional APIs also
fail closed: `cameraPreviewView` is `nil`, `startCapture` does not invoke
the sample handler with fabricated buffers, `RPBroadcastActivityViewController.load`
returns `nil` plus `broadcastSetupFailed`, and `NSExtensionContext`
broadcast-setup methods do not invent a broadcasting app identity.

## Deferred until real dependencies

These identifiers are omitted from the isolated module and classified
`deferred` until compiled against real UIKit / CoreMedia / Foundation:

- `RPPreviewViewController`, `RPBroadcastActivityViewController`,
  `RPSystemBroadcastPickerView`, and their delegates
- `RPScreenRecorder.cameraPreviewView`, `stopRecording(handler:)` that
  yields a preview controller, and preview-taking recorder delegate methods
- `startCapture` / `processSampleBuffer` (`CoreMedia.CMSampleBuffer`)
- `NSExtensionContext` broadcast-setup methods

`tests/agent/ReplayKitDependencyIdentity.swift` is the EC2 client for those
proofs. It is not run by `tests/acceptance/test_host.sh`.

## Tests

- Isolated: `tests/agent/ReplayKitRuntime.swift` prints
  `REPLAYKIT_AGENT_RUNTIME_OK`.
- Future EC2: build guest UIKit, AVFoundation, and CoreMedia first, build
  ReplayKit with their `-I`/`-L` paths, link the identity client against
  `libReplayKit.dylib`, run with `LD_LIBRARY_PATH`, and expect
  `REPLAYKIT_DEPENDENCY_IDENTITY_OK`.

```sh
bash tests/acceptance/test_host.sh
```
