# AVFoundation (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AVFoundation` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, and TBD exports. It is not wired into the shared guest package;
a passing isolated host gate is not integrated Linux success and is not Apple
media-pipeline behavior.

The isolated host compile is Foundation-only. CoreMedia, CoreVideo,
CoreGraphics, and CoreImage types used in signatures are host lookalikes behind
`canImport`, not public substitute modules.

## What is real

- `AVPlayer` / `AVQueuePlayer` / `AVPlayerItem` keep item, rate, defaultRate,
  volume, mute, and background-playback policy. `play()` applies `defaultRate`
  (Apple iOS 16+). A monotonic `DispatchTime` clock (20 ms pulse) drives
  `currentTime()`, periodic and boundary observers, and item-end notifications.
  Seek with a completion handler finishes synchronously with the caller's
  `CMTime` identity while paused. No frames are decoded or displayed.
- `AVURLAsset` / `AVAsset.load(.duration/.tracks/.isPlayable/.metadata)`: a
  local file URL is probed for ISO BMFF (`ftyp`/`moov`/`mvhd`/`trak`/`tkhd`/
  `mdia`/`hdlr`/`stsd`/`stts`) plus WAV and AIFF/AIFC headers. That supplies
  duration, tracks, media type, `naturalSize`, `preferredTransform`, and
  `nominalFrameRate`. Missing files stay fail-closed (`duration` `.invalid`,
  empty tracks). `isPlayable` remains false. An injected host SPI duration
  still wins over the probe.
- `AVPlayerLayer` subclasses `CALayer` (QuartzCore on Mac; host lookalike on
  Linux). Default `videoGravity` is `AVLayerVideoGravityResizeAspect`.
  `isReadyForDisplay` is false.
- `AVFileType.mp4` / `.mov` / `.m4a` use the well-known UTIs already present
  in this lane.
- `AVAssetExportSession.init(asset:presetName:)` is nil for an empty preset.
  `export(to:as:)` throws `AVFoundationPortableError.exportUnavailable` and
  sets `status` to `.failed` without a host SPI handler. `cancelExport()` sets
  `.cancelled`. Status raw values are 0...5.
- `AVAssetImageGenerator.generateCGImageAsynchronously` calls the completion
  handler with `frameGenerationUnavailable` when no host frame handler is
  installed. Delivery is synchronous on this host. `copyCGImage(at:actualTime:)`
  and `generateCGImagesAsynchronously(forTimes:)` fail closed with
  `AVError.noImageAtTime`.
- `AVMakeRect(aspectRatio:insideRect:)` is an aspect-fit rectangle centered in
  the bounds; non-positive geometry returns `.zero`.
- `AVError.Code` raw values match the pinned `dotnet/macios` `AVError` enum.
  `AVFoundationErrorDomain` is the string `AVFoundationErrorDomain`.
- `AVCaptureDevice.authorizationStatus(for:)` is `.denied`. `requestAccess`
  returns false. `devices()` is empty. `lockForConfiguration()` throws
  `mediaServiceUnavailable`. `AVCaptureDeviceInput(device:)` throws
  `AVError.applicationIsNotAuthorizedToUseDevice`. `AVCaptureSession.startRunning()`
  leaves `isRunning` false.
- Portable `AVAudioSession` category/mode/options/active state is
  process-local. Linux has no audio hardware: `currentRoute` is empty and
  `outputVolume` is 0. Changing `category` posts
  `AVAudioSession.routeChangeNotification` with documented userInfo keys
  `AVAudioSessionRouteChangeReasonKey` (`.categoryChange` = 3) and
  `AVAudioSessionRouteChangePreviousRouteKey`. Interruptions are not
  synthesized; a host SPI posts the documented
  `AVAudioSessionInterruptionTypeKey` / `AVAudioSessionInterruptionOptionKey`
  payload. `AVAudioPlayer` uses a silent clock; `AVSpeechSynthesizer.speak`
  returns false.
- `AVPlayerAudiovisualBackgroundPlaybackPolicy` raw values are automatic=1,
  pauses=2, continuesIfPossible=3.

IceCubes-facing `AVAudioSession` / `AVAudioPlayer` are extra portable surface;
iOS 26.1 places `AVAudioSession` in AVFAudio, not this module's public census.

## Fail-closed / deferred

No camera, encoder, FairPlay, AirPlay, or export backend exists on this host.
Stubs compile so the graph can be reviewed; they do not invent hardware or
service success.

Deferred on this host:

- `AVCaptureVideoPreviewLayer`, `AVSynchronizedLayer`,
  `AVSampleBufferDisplayLayer` (must subclass `CALayer` and present buffers)
- `AVAssetDownloadTask`, `AVAggregateAssetDownloadTask`,
  `AVAssetDownloadURLSession` (must subclass `URLSession` types)
- `UTType`-typed members (no UniformTypeIdentifiers on the isolated host)
- Metal / simd / UIKit / Core Image filter graphs that the host cannot name
- NSCoder / NSValue CoreMedia overlay helpers
- Opaque `some AsyncSequence` returns
- Completion-handler export / writer / FairPlay paths whose Apple queue and
  status ordering are unobserved

String constants generated from the graph use the public identifier as a Linux
payload unless a focused test records a corroborated value. That is a
declaration, not Apple C-string ABI.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

Coverage is a review index, not a percentage slogan. `implemented` rows cite a
focused test of that identifier. Enum/option-set members may share one
table-driven raw-value test. Touching a property without asserting it is
`declared`.

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass on `cursor/port-avfoundation-to-linux-9929`. The first
pass (277 implemented identity/behavior rows) is kept and stays green. This
pass adds a local-container probe, fail-closed writer/reader/image/capture
errors with documented `AVError` codes, mix/composition instruction models,
and table-driven metadata/capture constant tests.

| | before (pass 1) | after (pass 2) |
|---|---|---|
| `implemented` | 277 | 1188 |
| `declared` | 5086 | 4175 |
| `deferred` | 269 | 269 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 `implemented` evidence distribution (table-driven enum / option-set /
metadata-constant tests may share a value test; no other single test exceeds
40% of the remaining implemented rows):

| citations | test |
|---|---|
| 292 | `testAVMetadataIdentifierRawValues` (identifier constants) |
| 279 | `testAVMetadataKeyRawValues` (key constants) |
| 98 | `testAVCaptureEnumRawValues` (capture enum cases) |
| 89 | `testAVErrorCodeMaciosRawValues` (AVError.Code raw values) |
| 47 | `testAVCaptureDeviceTypeAndPresetRawValues` (DeviceType/Preset/AspectRatio) |

Local ISO BMFF / WAV / AIFF probing, `AVMutableComposition.insertTimeRange`,
`AVAssetWriter.startWriting` / `AVAssetReader.startReading` (`encoderNotFound` /
`decoderNotFound`), `copyCGImage` (`noImageAtTime`), capture device-input
unauthorized, `AVPlayerLooper`, and audio-mix / video-composition instruction
models are covered by focused tests in `tests/agent/AVMediaProbeTests.swift`
and `tests/agent/AVFailClosedTests.swift`. `AVSpeechSynthesizer` remains extra
portable AVFAudio surface from pass 1; it is not in this module's public
census. No SwiftUI cross-import overlay rows exist in this seed.

Sealed Linux gate (`bash full/avfoundation/tests/acceptance/test_host.sh`)
ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

`swiftc --version` on this host is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a
host-inventory token, not printed by the sealed framework gate.
`.cursor/verify-cloud-environment.sh` currently stops on a missing
`scratch/.cursor-built-products.json` in this snapshot; the framework tree
itself has no stale `.build` / `build` / `scratch` products.
`tests/test_avfoundation_host.sh` is a Darwin IceCubes/`xcrun` consumer and
is not runnable on this Linux host.
