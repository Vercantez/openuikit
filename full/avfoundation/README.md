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
  `mdia`/`hdlr`/`stsd`/`stts`/`stsz`) plus WAV and AIFF/AIFC headers. That supplies
  duration, tracks, media type, `naturalSize`, `preferredTransform`,
  `nominalFrameRate`, `languageCode`, `totalSampleDataLength`, `estimatedDataRate`,
  `preferredRate`, and `preferredVolume`. Missing files stay fail-closed (`duration` `.invalid`,
  empty tracks). `isPlayable` remains false. An injected host SPI duration
  still wins over the probe. `AVMutableComposition.insertEmptyTimeRange` /
  `removeTimeRange` / `scaleTimeRange` adjust stored track durations.
- `AVPlayerLayer` subclasses `CALayer` (QuartzCore on Mac; host lookalike on
  Linux). Default `videoGravity` is `AVLayerVideoGravityResizeAspect`.
  `isReadyForDisplay` is false.
- `AVFileType.mp4` / `.mov` / `.m4a` use the well-known UTIs already present
  in this lane.
- `AVAssetExportSession.init(asset:presetName:)` is nil for an empty preset.
  `export(to:as:)` throws `AVFoundationPortableError.exportUnavailable` and
  sets `status` to `.failed` without a host SPI handler. `exportAsynchronously`
  fail-closes with `AVError.exportFailed` and invokes the handler on the caller.
  `allExportPresets()` / `exportPresets(compatibleWith:)` / `determineCompatibleFileTypes`
  return empty. `cancelExport()` sets `.cancelled`. Status raw values are 0...5.
  `AVAssetWriter.startWriting` / `finishWriting(completionHandler:)` record
  `AVError.encoderNotFound`. `AVAssetReader.startReading` records
  `AVError.decoderNotFound`. Writer inputs of `.video`/`.audio` can be added
  while status is `.unknown`.
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
  `AVError.applicationIsNotAuthorizedToUseDevice`. `AVCaptureDeviceInput(device:)` throws
  `AVError.applicationIsNotAuthorizedToUseDevice`. `AVCaptureSession.startRunning()`
  leaves `isRunning` false. Session notification names use the documented
  `AVCaptureSessionDidStartRunningNotification` C strings. `sessionPreset`
  defaults to `.high` and is stored, but `canSetSessionPreset` stays false.
  Capture-device zoom defaults to the documented `1.0`; torch-on throws
  `AVError.torchLevelUnavailable`.
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

- `AVCaptureVideoPreviewLayer`, `AVSynchronizedLayer` (must subclass
  `CALayer` and present buffers). `AVSampleBufferDisplayLayer` is a `CALayer`
  subclass on this host; enqueue fail-closes with `AVError.decoderNotFound`
  and never displays frames.
- `AVAssetDownloadTask`, `AVAggregateAssetDownloadTask`,
  `AVAssetDownloadURLSession` (must subclass `URLSession` types)
- `UTType`-typed members (no UniformTypeIdentifiers on the isolated host)
- Metal / simd / UIKit / Core Image filter graphs that the host cannot name
- NSCoder / NSValue CoreMedia overlay helpers
- Opaque `some AsyncSequence` returns
- FairPlay / content-key and AirPlay paths whose Apple queue and
  status ordering are unobserved. Export/writer completion handlers exist as
  synchronous fail-closed entries; Apple queue identity remains unobserved.

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

Third SDK-depth pass on `cursor/port-avfoundation-to-linux-0d4e`. Pass 1 (277)
and pass 2 (1188) are kept and stay green. This pass extends local-container
probing (`stsz`, `preferredRate`/`preferredVolume`, dual-track ISO BMFF),
composition empty/scale/remove, export/writer/reader completion-handler
fail-closed paths, and the AVCaptureDevice/Session/Input/Output discovery
model with documented `AVError` codes.

| | before (pass 2) | after (pass 3) |
|---|---|---|
| `implemented` | 1188 | 1784 |
| `declared` | 4175 | 3582 |
| `deferred` | 269 | 266 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 `implemented` evidence distribution (table-driven enum / option-set /
metadata-constant tests may share a value test; no other single test exceeds
40% of the remaining implemented rows):

| citations | test |
|---|---|
| 292 | `testAVMetadataIdentifierRawValues` (identifier constants) |
| 279 | `testAVMetadataKeyRawValues` (key constants) |
| 132 | `testAVCaptureDeviceFailClosedDiscoveryModel` (capture device fail-closed) |
| 98 | `testAVCaptureEnumRawValues` (capture enum cases) |
| 89 | `testAVErrorCodeMaciosRawValues` (AVError.Code raw values) |

Pass 2 snapshot (kept): implemented 1188, declared 4175, deferred 269.
Pass 2 top-5: metadata identifiers 292, metadata keys 279, capture enums 98,
AVError.Code 89, DeviceType/Preset 47.

Local ISO BMFF / WAV / AIFF probing, `AVMutableComposition` duration edits,
`AVAssetWriter.startWriting` / `finishWriting` (`encoderNotFound`),
`AVAssetReader.startReading` (`decoderNotFound`), `exportAsynchronously`
(`exportFailed`), `copyCGImage` (`noImageAtTime`), capture lock/torch
unauthorized, `AVPlayerLooper`, and audio-mix / video-composition instruction
models are covered by focused tests in `tests/agent/AVMediaProbeTests.swift`,
`tests/agent/AVFailClosedTests.swift`, and `tests/agent/AVPlaybackTests.swift`.
`AVSpeechSynthesizer` remains extra portable AVFAudio surface from pass 1; it
is not in this module's public census. No SwiftUI cross-import overlay rows
exist in this seed.

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
`scratch/ladder-corpus/focus-ios` corpus checkout in this snapshot (active
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21`, not the
seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The framework tree
itself has no stale `.build` / `build` / `scratch` products. Swift 6.2.4
typechecks Foundation. `tests/test_avfoundation_host.sh` is a Darwin
IceCubes/`xcrun` consumer and is not runnable on this Linux host.

### Pass 4 (wave 8 next)

Fourth SDK-depth pass on `cursor/port-avfoundation-to-linux-6e1e`. Passes 1–3
(277 / 1188 / 1784) are kept and stay green. This pass adds local `AVMovie` /
`AVMutableMovie` header probing and duration-only edits, an
`AVCapturePhotoOutput` / `AVCapturePhotoSettings` fail-closed discovery model,
`AVComposition.naturalSize` / initialization options, and table-driven
Hashable / Equatable / OptionSet / SetAlgebra witnesses for the remaining
enum and option-set families.

| | before (pass 3) | after (pass 4) |
|---|---|---|
| `implemented` | 1784 | 2727 |
| `declared` | 3582 | 2639 |
| `deferred` | 266 | 266 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 `implemented` evidence distribution after pass 4 (table-driven enum /
option-set / metadata-constant tests may share a value test; no other single
test exceeds 40% of the remaining implemented rows):

| citations | test |
|---|---|
| 292 | `testAVMetadataIdentifierRawValues` (identifier constants) |
| 279 | `testAVMetadataKeyRawValues` (key constants) |
| 267 | `testOptionSetAlgebraSynthesis` (OptionSet / SetAlgebra) |
| 253 | `testRawRepresentableEnumHashableSynthesis` (enum Hashable / `!=`) |
| 132 | `testAVCaptureDeviceFailClosedDiscoveryModel` (capture device fail-closed) |

`AVSpeechSynthesizer` remains extra portable AVFAudio surface; it is not in
this module's public census. No SwiftUI cross-import overlay rows exist in
this seed. Concurrency `AsyncSequence` witnesses stay `declared` because a
blocking wait would hang the sealed gate. `AVMovie.writeHeader` /
`makeMovieHeader` throw `AVError.encoderNotFound`. Photo capture invokes the
delegate synchronously with `AVError.applicationIsNotAuthorizedToUseDevice`.
`AVMutableMovie.insertTimeRange(..., copySampleData: true)` throws
`AVError.decoderNotFound`.

Sealed Linux gate (`bash full/avfoundation/tests/acceptance/test_host.sh`)
ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

### Pass 5 (wave 8 next)

Fifth SDK-depth pass on `cursor/port-avfoundation-to-linux-b064`. Passes 1–4
(277 / 1188 / 1784 / 2727) are kept and stay green. This pass stores real
`AVMetadataItem` / `AVMutableMetadataItem` values and portable identifier
mapping, `AVCompositionTrack` / `AVMutableCompositionTrack` segments and
`validateSegments` fail-closed `AVError` codes, `AVAssetWriterInput` stored
configuration with fail-closed `append`, `AVPlayerInterstitialEvent` models
and monitor notification names, empty `AVPlayerItem` access/error logs,
capture session controls/connections plus photo representations, sample-cursor
pinning without media, and video-composition layer-instruction ramps.

| | before (pass 4) | after (pass 5) |
|---|---|---|
| `implemented` | 2727 | 3281 |
| `declared` | 2639 | 2085 |
| `deferred` | 266 | 266 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 `implemented` evidence distribution after pass 5 (table-driven enum /
option-set / metadata-constant tests may share a value test; no other single
test exceeds 40% of the remaining implemented rows):

| citations | test |
|---|---|
| 292 | `testAVMetadataIdentifierRawValues` (identifier constants) |
| 279 | `testAVMetadataKeyRawValues` (key constants) |
| 267 | `testOptionSetAlgebraSynthesis` (OptionSet / SetAlgebra) |
| 253 | `testRawRepresentableEnumHashableSynthesis` (enum Hashable / `!=`) |
| 132 | `testAVCaptureDeviceFailClosedDiscoveryModel` (capture device fail-closed) |

Pass 5 added 554 `implemented` rows (14 tests in
`tests/agent/AVDepthPass5Tests.swift`; largest new test is 77 citations for
video-composition ramps). Largest non-table test remains 132 citations
(capture-device fail-closed), under 40% of the 2003 remaining implemented
rows after table-driven metadata/enum/option-set evidence.

Fail-closed on this pass: writer `append` / caption and metadata adaptors
return false; capture `canAdd*` stays false and device lists stay empty;
photo file/CGImage representations are nil; sample-cursor steps pin and
return 0 / invalid; `AVVideoComposition.isValid` stays false; player-item
date seeks return false; `accessLog()` / `errorLog()` are empty UTF-8 logs,
not fabricated network sessions. Local ISO BMFF / WAV / AIFF probing from
earlier passes is unchanged. `AVSpeechSynthesizer` remains extra portable
AVFAudio surface; it is not in this module's public census. No SwiftUI
cross-import overlay rows exist in this seed.

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
`scratch/swift-foundation` corpus checkout in this snapshot (active Cursor
Build is not the seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`).
The framework tree itself has no stale `.build` / `build` / `scratch`
products. `tests/test_avfoundation_host.sh` is a Darwin IceCubes/`xcrun`
consumer and is not runnable on this Linux host.

### Pass 6 (wave 8 next)

Sixth SDK-depth pass on `cursor/port-avfoundation-to-linux-747d`. Passes 1–5
(277 / 1188 / 1784 / 2727 / 3281) are kept and stay green. This pass stores
`AVAssetWriter` / input-group configuration and cancel, `AVAssetReader`
output settings, a FairPlay-free `AVContentKeySession` fail-closed model,
`AVCaptureMovieFileOutput` / `AVCaptureStillImageOutput` recording and still
capture that complete synchronously with
`AVError.applicationIsNotAuthorizedToUseDevice`,
`AVCaptureResolvedPhotoSettings` zero dimensions, `AVOutputSettingsPreset`
identifier strings, `AVPlayerItem` output delegates, and
`AVSampleBufferDisplayLayer` as a `CALayer` that fail-closes on enqueue.

| | before (pass 5) | after (pass 6) |
|---|---|---|
| `implemented` | 3281 | 3681 |
| `declared` | 2085 | 1707 |
| `deferred` | 266 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 `implemented` evidence distribution after pass 6 (table-driven enum /
option-set / metadata-constant tests may share a value test; no other single
test exceeds 40% of the remaining implemented rows):

| citations | test |
|---|---|
| 292 | `testAVMetadataIdentifierRawValues` (identifier constants) |
| 279 | `testAVMetadataKeyRawValues` (key constants) |
| 267 | `testOptionSetAlgebraSynthesis` (OptionSet / SetAlgebra) |
| 253 | `testRawRepresentableEnumHashableSynthesis` (enum Hashable / `!=`) |
| 132 | `testAVCaptureDeviceFailClosedDiscoveryModel` (capture device fail-closed) |

Pass 6 added 400 `implemented` rows (11 tests in
`tests/agent/AVDepthPass6Tests.swift`). Largest non-table test remains 132
citations (capture-device fail-closed), under 40% of the remaining
implemented rows after table-driven metadata/enum/option-set evidence.
Deferred dropped 22 rows because still-image capture methods and
`AVSampleBufferDisplayLayer` now have fail-closed Linux behavior instead of
being left as unimplemented CALayer/hardware stubs.

Fail-closed on this pass: writer `canApply` stays false; tagged/pixel
receivers `appendImmediately` return false; content-key requests complete
with `AVError.contentKeyRequestCancelled` (no FairPlay daemon); movie
`startRecording` and still `captureStillImageAsynchronously` invoke the
caller synchronously with `AVError.applicationIsNotAuthorizedToUseDevice`;
sample-buffer display enqueue records `AVError.decoderNotFound` and
`requiresFlushToResumeDecoding`. Local ISO BMFF / WAV / AIFF probing from
earlier passes is unchanged. `AVSpeechSynthesizer` remains extra portable
AVFAudio surface; it is not in this module's public census. No SwiftUI
cross-import overlay rows exist in this seed.

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
`scratch/ladder-corpus/focus-ios` corpus checkout in this snapshot (active
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21`, not the
seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The framework
tree itself has no stale `.build` / `build` / `scratch` products.
`tests/test_avfoundation_host.sh` is a Darwin IceCubes/`xcrun` consumer and
is not runnable on this Linux host.

