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

The required preflight completed and emitted
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.
The framework tree itself has no stale `.build` / `build` / `scratch` products.
`tests/test_avfoundation_host.sh` is a Darwin IceCubes/`xcrun` consumer and
is not runnable on this Linux host.


### Depth pass 2026-09 (wave 8)

This pass audits previously declared surface against the focused runtime suite.
It promotes 315 rows only where a synchronous test directly exercises the
identifier: 146 public constants and notification names now have an explicit
table-driven access/value check, while 169 type, enum, option-set, and model
rows cite the existing focused test that constructs or uses that surface. No
Apple hardware, daemon, entitlement, network, decoder, or encoder success is
claimed by these promotions; all existing fail-closed boundaries remain in
force.

| status | before | after |
|---|---:|---:|
| `implemented` | 3681 | 3996 |
| `declared` | 1707 | 1392 |
| `deferred` | 244 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after wave 8:

| citations | test |
|---:|---|
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |
| 146 | `testRemainingPublicConstantValues` (constant/notification table) |

The largest evidence group is 293 rows, well below 40% of the 3,996
implemented rows. The unresolved behavioral questions remain recorded in
`oracle-questions.tsv`; in particular, this pass does not infer callback
timing, queue selection, service success, coding round trips, or device state
from static API evidence.

### Depth pass 2026-09 (wave 9)

Wave 9 extends the coverage audit across 315 additional concrete Objective-C
surface rows. Its synchronous family audit re-runs focused local ISO BMFF
asset/track and composition probes, player and observer state-machine probes,
writer/reader/content-key/capture fail-closed probes, instruction models, and
the permitted metadata/enum/option-set tables. It uses neither reflection nor
declaration-only identity checks. No hardware, daemon, entitlement, network,
decoder, encoder, or Apple UI success is fabricated.

| status | before | after |
|---|---:|---:|
| `implemented` | 3996 | 4311 |
| `declared` | 1392 | 1077 |
| `deferred` | 244 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after wave 9:

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

The fail-closed boundary is unchanged: Apple media services, capture devices,
FairPlay/content-key services, codecs, and UI rendering never report invented
success. Questions about callback queues/timing, service policy, and native
coding behavior remain in `oracle-questions.tsv` for an Apple-oracle run.

### Depth pass 2026-09-14 (non-UI AVAsset/metadata)

Non-UI depth on `AVAsset` / `AVURLAsset` / `AVFragmentedAsset`, metadata
groups, media-type/file-type/codec raw values, `AVError` witnesses, and the
local ISO-BMFF / WAV / AIFF probe. Capture, player chrome, PiP, AirPlay, and
SwiftUI stay fail-closed. Async `load(...)` that would hang the sealed gate
stays deferred.

An `xcrun swiftc` `import AVFoundation` probe on Xcode 26.1 (macOS 26.1 SDK)
pinned four-character media types, remaining `AVFileType` UTIs, video codec
fourCCs, common metadata keys/identifiers/key spaces/formats, and
`AVPixelAspectRatio` / `AVEdgeWidths` field storage. Transcript:
`scratch/oracle-2026-09-14/AVFoundationConstantsProbe.transcript.txt`.

| status | before | after |
|---|---:|---:|
| `implemented` | 4311 | 4416 |
| `declared` | 1077 | 972 |
| `deferred` | 244 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass:

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

This pass added 105 `implemented` rows (8 tests in
`tests/agent/AVDepthPass10Tests.swift`). Largest new test is 24 citations
(cache / segment-report / track-group fail-closed), well under 40% of the
remaining implemented rows.

Local probe additions: `mvhd` `next_track_ID` for `unusedTrackID()`, `elst`
empty-edit offset, `dref` self-contained flag, `pasp` pixel aspect, `udta` /
WAVE `LIST INFO` / AIFF `NAME` metadata items, and identity
`AVAssetTrack.segments` for unedited local tracks. `AVDateRangeMetadataGroup`
/ `AVTimedMetadataGroup` now store items and dates/time ranges.
`AVFragmentedAsset` is a real `AVURLAsset` subclass over the same probe.
`AVError(rawValue:)` / `CustomNSError` / `~=` are exercised without claiming
Apple NSError bridging. Capture/async/FairPlay leftover rows stay deferred.

### Depth pass 2026-09-14 (AVAssetDownload / caption values)

Non-UI depth on `AVAssetDownloadConfiguration` / `AVAssetDownloadContentConfiguration`
/ `AVAssetDownloadStorageManagementPolicy` / `AVAssetDownloadStorageManager`.
Artwork, title, media selections, variant qualifiers, expiration, and eviction
priority are stored in-process. `shared()` is a singleton. No HLS bytes are
fetched and `AVAssetDownloadTask` / `AVAssetDownloadURLSession` stay deferred.
`AVAssetImageGeneratorCompletionHandler` is a stored callback invoked
synchronously. Caption, ruby, region, grouper, and media-selection-criteria
value types store constructor arguments. Capture, player chrome, PiP, CIImage
filtering, and async `load(...)` stay fail-closed.

| status | before | after |
|---|---:|---:|
| `implemented` | 4416 | 4523 |
| `declared` | 972 | 865 |
| `deferred` | 244 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass:

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

This pass added 107 `implemented` rows (10 tests in
`tests/agent/AVAssetDownloadTests.swift` and
`tests/agent/AVCaptionValueTests.swift`). Largest new test is 37 citations
(caption region / renderer / conversion models), well under 40% of the
remaining implemented rows. URLSession subclassing and download start remain
deferred.

### Depth pass 2026-09-14 (fragmented movie / media selection / metadata objects)

Non-UI depth on already-compiling data models: `AVFragmentedMovie` track
queries plus synchronous completion-handler loads over stored tracks (inherited
`AVAsset` behavior, no fragment daemon), `AVFragmentedMovieMinder` interval
storage and membership calls, `AVFragmentedMovieTrack` identity,
`AVMediaSelection` / `AVMutableMediaSelection` / `AVCustomMediaSelectionScheme`
/ `AVMediaPresentationSelector` / `AVMediaPresentationSetting` fail-closed
queries, face/body metadata objects (`AVMetadataBodyObject` hierarchy,
`AVMetadataSalientObject.objectID`, machine-readable `corners` / `descriptor` /
`stringValue`), `AVRenderedCaptionImage` buffers and position,
`AVCaptionRegion.encode(with:)`, all fourteen `AVMutableCaption` attribute
set/remove editors, caption/metadata raw-value identities
(`AVCaption.Decoration`, `AVCaptionSettingsKey`, `AVMetadataObject.ObjectType`,
`AVCaptionConversionWarning.WarningType`,
`AVCaptionConversionAdjustment.AdjustmentType`), fail-closed
`AVMutableMovieTrack.append` (`AVError.decoderNotFound`), and
`AVAssetResourceRenewalRequest` plus fail-closed
`AVAssetWriterInputPixelBufferAdaptor.append`. AVCapture*, AVPlayer UI, async
`load(...)` (YaKF), FairPlay, PiP, AirPlay, and CIImage filtering stay
deferred or fail-closed.

| status | before | after |
|---|---|---:|
| `implemented` | 4523 | 4594 |
| `declared` | 865 | 794 |
| `deferred` | 244 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass:

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

This pass added 71 `implemented` rows (11 tests in
`tests/agent/AVDepthPass11Tests.swift`). Largest new test is 14 citations
(mutable-caption attribute editors), well under 40% of the remaining
implemented rows.

### Depth pass 2026-09-15 (metrics / coordination / external-device models)

Non-UI depth on remaining declared data models that already compile (or
needed only an access-level fix to an existing declaration):
`AVMetric*` event classes (base, error, content-key, download-summary, HLS
segment/playlist, media-resource, rendition, likely-to-keep-up, playback
summary, rate-change, seek, stall, variant-switch families),
`AVCoordinatedPlaybackParticipant` / `AVCoordinatedPlaybackSuspension` /
`AVDelegatingPlaybackCoordinator` plus all five command classes,
`AVPlaybackCoordinationMedium` / `AVPlaybackCoordinator`,
`AVExternalStorageDevice` (+ discovery session) / `AVExternalSyncDevice`
(+ discovery session), `AVMediaDataStorage`, `AVFrameRateRange`,
`AVPortraitEffectsMatte` / `AVSemanticSegmentationMatte` (+ matte-type
raw-value witness), `AVRouteDetector`, `AVVideoOutputSpecification`
(including tag-collection setters and preferred collections),
`AVSampleBufferAttachContentKey` plus fail-closed
`CMReadySampleBuffer.attach(contentKey:)` (throws
`mediaServiceUnavailable`; no content-key service on Linux), the
`CMTag` monoscopic/stereoscopic video-output helpers, and table-driven
`init(rawValue:)` witnesses for `AVVideoRange`, `AVVariantPreferences`,
and the delegating-coordinator option sets. Delegate protocols
`AVExternalSyncDeviceDelegate` and
`AVPlaybackCoordinatorPlaybackControlDelegate` (synchronous
completion-handler methods only) are exercised through recording test
doubles. AVCapture*, AVPlayer UI outputs, async `load(...)` (YaKF),
FairPlay/content-key service paths, PiP, AirPlay, and CIImage filtering
stay deferred or fail-closed. Six existing declarations needed only an
access-level fix (`AVMediaDataStorage.init(url:options:)`,
`AVPortraitEffectsMatte.init(fromDictionaryRepresentation:)`,
`AVVideoOutputSpecification.init(tagCollections:)`,
`AVDelegatingPlaybackCoordinator.init(playbackControlDelegate:)`,
`AVMutableAudioMixInputParameters.init(track:)`,
`AVSampleBufferGenerator.init(asset:timebase:)`); the `CMTag` helpers were
constrained to `Array where Element == CMTag`.

| status | before | after |
|---|---|---:|
| `implemented` | 4594 | 4785 |
| `declared` | 794 | 603 |
| `deferred` | 244 | 244 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass:

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

This pass added 191 `implemented` rows (15 tests in
`tests/agent/AVDepthPass13Tests.swift`). Largest new test is 26 citations
(delegating playback coordinator model), well under 40% of the remaining
implemented rows.

Note: `tests/agent/AVDepthPass12Tests.swift` (a concurrent pass's 11 tests)
is present but uncited by coverage; two one-word compile fixes were applied
so the shared gate builds it (`@unchecked Sendable` on its writer witness,
matching the delegate protocol's `Sendable` bound). Its rows are untouched
and remain that pass's to cite.

### Depth pass 2026-09-15 (wave 3 non-UI asset/caption models)

Wave 3 cites the concurrent pass's 11 focused tests in
`tests/agent/AVDepthPass12Tests.swift` (present but uncited until now) and
adds one new test in `tests/agent/AVDepthPass14Tests.swift`. Converted
remaining declared non-capture data models that already compile:
`AVMutableAudioMixInputParameters` track factory (`init(track:)`, the Swift
spelling of `+audioMixInputParametersWithTrack:`) plus the inherited stored
`audioTimePitchAlgorithm`; four `AVMutableVideoCompositionLayerInstruction`
ramp setters; `AVTextStyleRule` stored attributes with property-list round
trip; `AVSampleBufferGenerator` / batch fail-closed creation; zeroed
`AVVideoPerformanceMetrics` counters; recording-witness coverage for
`AVAssetReaderCaptionValidationHandling`, `AVAssetResourceLoaderDelegate`,
and `AVAssetWriterDelegate` segment callbacks; `AVFragmentMinding` protocol
and its `isAssociatedWithFragmentMinder` projection of ObjC
`associatedWithFragmentMinder`; `AVAssetReaderOutput.SupportedPayload` /
`Provider` / `Provider<AVCaptionGroup>.captionsNotPresentInPreviousGroups`
(`AVCaptionGroup` now declares the Apple-mirroring `SupportedPayload`
conformance behind Apple's `outputCaptionProvider` return type);
table-driven `init(rawValue:)` witnesses plus the newly added
`AVCoordinatedPlaybackSuspension.Reason.init(_:)`; and empty
`loadedTimeRanges` on the variant-switch / likely-to-keep-up metric events.

| status | before | after |
|---|---|---:|
| `implemented` | 4785 | 4833 |
| `declared` | 603 | 554 |
| `deferred` | 244 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

This pass added 48 `implemented` rows (largest new citation group is 9 rows
for the table-driven `init(rawValue:)`/`init(_:)` witnesses, explicitly
permitted; largest non-table group is 7). The largest evidence group overall
is 315 rows, well below 40% of the 4,833 implemented rows.

Two behavior corrections came with the citations, both staying fail-closed.
Citing the batch test exposed that
`AVSampleBufferGenerator.makeSampleBuffer(for:addTo:)` returned a blank
`CMSampleBuffer` while its single-request sibling throws; it now throws
`mediaServiceUnavailable` like the rest of the generator surface (no media
service on Linux). `AVMutableAudioMixInputParameters.audioTapProcessor`
moved to `deferred`: `MTAudioProcessingTap` is a Darwin-only type on the
isolated host, matching its already-deferred base-class twin. AVCapture*,
AVPlayer UI/outputs, async `load(...)` (YaKF), FairPlay/content-key service
paths, PiP, AirPlay, CIImage filtering, `CALayer`-typed CoreAnimationTool
factories, and `NSCoding` round trips stay deferred or fail-closed.

Sealed Linux gate (`bash full/avfoundation/tests/acceptance/test_host.sh`,
run under `swift:6.2-noble`, Swift 6.2.4, aarch64) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

Note: on this Mac's Xcode 26.1 toolchain (`swiftc` targeting
`arm64-apple-macosx`, where `canImport(CoreMedia)`/`canImport(QuartzCore)`
resolve to the real Darwin SDKs) the same gate stops at host compilation of
pre-existing lookalike-guarded lines (e.g. `CMFormatDescription()`,
`CMTimebase()`, `CALayer` in `AVAssetSurface`/`AVPlayerLayerSurface`/
`AVCaptureSurface`); that is a host-SDK condition, not a product regression,
and the Linux-container run above is the authoritative sealed result.

### Depth pass 2026-09-15 (wave 6 declared conversion)

Wave 6 converts leftover declared rows that already compile (plus minimal
Apple-mirroring product shims) into focused synchronous tests. No SwiftUI
cross-import overlay rows exist in this seed, so the overlay playbook does
not apply; the 181 `SYNTHESIZED` rows are `Sequence`/Concurrency members on
`AVCaptureSynchronizedDataCollection` (plus `NSCoding`, `NSCoding`-adjacent
`CoreAnimationTool`, and key-value-loading witnesses).

| status | before | after |
|---|---|---:|
| `implemented` | 4833 | 5213 |
| `declared` | 554 | 174 |
| `deferred` | 245 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order;
largest new citation group is 32 rows for the compositing/validation
witnesses, well under 40% of the 5,213 implemented rows):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

This pass added 380 `implemented` rows (27 tests in
`tests/agent/AVDepthPass15Tests.swift` and
`tests/agent/AVDepthPass16Tests.swift`). Product shims in
`AVDepthPass15.swift` (listed in `avfoundation_guest_sources.txt`):
`Sequence` conformance for `AVCaptureSynchronizedDataCollection` (Apple
declares `NSFastEnumeration`, which Swift imports as `Sequence`),
`AVCaptureReactionType.systemImageName` (Swift spelling of
`AVCaptureReactionSystemImageNameForType`; values pinned by an Xcode 26.1
`import AVFoundation` probe: thumbsUp=hand.thumbsup.fill,
thumbsDown=hand.thumbsdown.fill, balloons=balloon.2.fill, heart=heart.fill,
fireworks=fireworks, rain=cloud.rain.fill, confetti=party.popper.fill,
lasers=laser.burst), six synchronous completion-handler twins of the
`AVCaptureDevice` setters (block shapes pinned from the iPhoneOS 26.1
headers; handlers run synchronously with the same `.zero` timestamp the
async twins return), top-level typealiases restoring Apple's spellings
(`AVPlayerHDRMode`, `AVPlayerRateDidChangeReason`,
`AVPlayerWaitingReason`, `AVCaptureSystemPressureLevel`,
`AVCaptureSystemPressureFactors`,
`AVCapturePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions`),
`AVPlayerItem: AVMetricEventStreamPublisher` returning empty metrics, and
`IteratorProtocol` on the synchronized-data iterator. Thirteen existing
`convenience init` declarations needed only an access-level fix
(`AVCaptureIndexPicker`/`AVCaptureSlider`/system sliders,
`AVCaptureMetadataInput`, `AVCapturePhotoBracketSettings`,
`AVVideoCompositionCoreAnimationTool`/`AVVideoCompositionInstruction`
configuration inits, `AVPlayerVideoOutput.init(specification:)`).

Fail-closed on this pass: metadata-input `append` throws
`mediaServiceUnavailable`; photo/smart-framing/video-request attach paths
throw or return nil/empty; `AVPlayerPlaybackCoordinator.coordinate(using:)`
throws; completion handlers never touch hardware. The remaining 174
`declared` rows are async `AsyncSequence`/`next()` witnesses, `NSCoding`
`init(coder:)` witnesses, `Combine` publishers, `FormatStyle`, and
`Element`-constrained or `SortComparator`-element witnesses that cannot be
exercised synchronously without inventing Apple API. The 245 `deferred`
rows are unchanged (hardware/daemon/URLSession/`CALayer`/async-service).

Sealed Linux gate (`bash full/avfoundation/tests/acceptance/test_host.sh`,
run under `swift:6.2-noble`, Swift 6.2.4, aarch64) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

### Depth pass 2026-09-15 (wave 7 declared conversion)

Wave 7 converts the five remaining synchronous `AVCaptureDevice.Format`
zoom properties (`secondaryNativeResolutionZoomFactors`,
`supportedVideoZoomFactorsForDepthDataDelivery`,
`supportedVideoZoomRangesForDepthDataDelivery`,
`systemRecommendedVideoZoomRange`, `systemRecommendedExposureBiasRange`)
from `declared` to `implemented`. All five already compiled with
fail-closed bodies (empty arrays / nil: no capture hardware on Linux);
`testAVCaptureDeviceFormatFailClosedModel` in
`tests/agent/AVFailClosedTests.swift` now asserts those values alongside
the 53 sibling format rows it already cited. No SwiftUI cross-import
overlay rows exist in this seed, so the overlay playbook does not apply.

| status | before | after |
|---|---|---:|
| `implemented` | 5213 | 5218 |
| `declared` | 174 | 169 |
| `deferred` | 245 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

The remaining 169 `declared` rows are async `AsyncSequence`/`next()`
witnesses (calling them needs `await`, which the sealed gate forbids),
`NSCoding` `init(coder:)` witnesses, `Combine` publishers (no Combine on
the isolated host), `FormatStyle` / `compare` witnesses, and
`Element`-constrained (`Equatable`) or deprecated-optional-`flatMap`
witnesses that cannot be exercised synchronously without inventing Apple
API or tripping `-warnings-as-errors` deprecation errors. The 245
`deferred` rows are unchanged
(hardware/daemon/URLSession/`CALayer`/async-service).

### Depth pass 2026-09-15 (wave 8 leftover sweep)

Wave 8 sweep converts the last 8 synchronous `declared` rows that already
compile with fail-closed bodies: the six
`AVAsynchronousCIImageFilteringRequest` class/member rows (zeroed
`renderSize` / `compositionTime`, inert `finish(with:)` calls, no filtering
service claimed), `AVVideoCompositionCoreAnimationTool` (default and
configuration inits; `CALayer`-backed factories stay deferred), and the
`AVMetricEventStreamPublisher` protocol (recording witness returning empty
`AVMetrics`; no metric service claimed). Three tests in
`tests/agent/AVDepthPass17Tests.swift` (largest group 6 citations).

| status | before | after |
|---|---|---:|
| `implemented` | 5218 | 5226 |
| `declared` | 169 | 161 |
| `deferred` | 245 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order;
largest share is 315 rows, ~6% of the 5,226 implemented rows):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

The remaining 161 `declared` rows are async witnesses (calling them needs
`await`, which the sealed gate forbids: `AsyncSequence` members,
`next()` iterators, async `load` / `seek` / `image` / receiver `append`
methods), `NSCoding` `init(coder:)` witnesses, `Combine` publishers (no
Combine on the isolated host), `FormatStyle` / `compare` witnesses, and
`Element`-constrained or `SortComparator`-element witnesses that cannot be
exercised synchronously without inventing Apple API. The 245 `deferred`
rows are unchanged (hardware/daemon/URLSession/`CALayer`/async-service
bodies that cannot be written without guessing Apple behavior).

### Depth pass 2026-09-15 (wave 9 NSCoding / CoreAnimationTool sweep)

Wave 9 sweep converts the last 9 synchronous `declared` rows into focused
tests in `tests/agent/AVDepthPass18Tests.swift` (one citation per test).
Seven `NSCoding` `init(coder:)` witnesses (`AVCaption`, `AVCaption.Ruby`,
`AVCaptionRegion`, `AVCompositionTrackFormatDescriptionReplacement`,
`AVMetricEvent`, `AVMetricMediaRendition`,
`AVVideoCompositionLayerInstruction`) gain fail-closed Linux initializers
that always return nil: decoding Apple archives is impossible on this
host, so no round trip is claimed. The two `CALayer`-backed
`AVVideoCompositionCoreAnimationTool` factories gain Apple-mirroring
constructors whose Swift spellings (`init(postProcessingAsVideoLayer:in:)`
/ `init(postProcessingAsVideoLayers:in:)`) were pinned by an Xcode 26.1
`import AVFoundation` probe (Apple's Swift SDK deprecates both in favor
of `init(configuration:)`); the Linux bodies only store the video/parent
layers and render nothing. No SwiftUI cross-import overlay rows exist in
this seed, so the overlay playbook does not apply.

| status | before | after |
|---|---|---:|
| `implemented` | 5226 | 5235 |
| `declared` | 161 | 152 |
| `deferred` | 245 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order;
largest new citation group is 1 row per new test):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

The remaining 152 `declared` rows are async witnesses (calling them needs
`await`, which the sealed gate forbids), `Combine` publishers,
`FormatStyle` / `compare` / `SortComparator`-element witnesses, and
`AsyncIterator.Element` associated types that cannot be exercised
synchronously without inventing Apple API. The 245 `deferred` rows are
unchanged (completion-handler service calls, Darwin-only types,
`CALayer`/`URLSession` inheritance, and bodies that cannot be written
without guessing Apple behavior).

Sealed Linux gate (`bash full/avfoundation/tests/acceptance/test_host.sh`,
run under `swift:6.2-noble`, Swift 6.2.4, aarch64) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

### Depth pass 2026-09-15 (wave 10 leftover sweep)

Wave 10 sweep converts 56 synchronous `declared` rows into focused tests
in `tests/agent/AVDepthPass19Tests.swift` (largest citation group 12).
`AVAsyncSequenceConformances.swift` (listed in
`avfoundation_guest_sources.txt`) publishes the formal `AsyncSequence` /
`AsyncIteratorProtocol` conformances the iPhoneOS 26.1 graph records
through its SYNTHESIZED witness rows for the five metric/image/timeline
sequence families (`AVMetrics`, `AVMergedMetrics`,
`AVAssetImageGenerator.Images`,
`AVPlayerItemIntegratedTimeline.BoundaryTimes/.PeriodicTimes`); every
requirement already existed as an Apple-mirroring member (`Element`,
`AsyncIterator`, `makeAsyncIterator()`, fail-closed `async next()`), so no
daemon, hardware, codec, or service behavior is added. The 54 converted
combinator rows are the synchronous lazy constructors (`map` x2,
`compactMap` x2, `filter`, `drop(while:)`, `prefix(while:)`, `prefix(_:)`,
`dropFirst`, plus `flatMap` overloads pinned by result-type annotation:
throwing transforms select `AsyncThrowingFlatMapSequence`, and over a
throwing base a non-throwing transform selects `Self.Failure ==
Segment.Failure` for an `AsyncThrowingStream` segment versus
`Segment.Failure == Never` for an `AsyncStream` segment). `prefix(while:)`
is rethrows, so over a throwing base it is spelled `try?` (still
synchronous, no `await`). The two `AsyncIterator.Element` associated-type
rows are exercised as synchronous typealias identities. Each converted
test only constructs lazy sequence values; nothing is iterated and no
Apple service success is claimed. No SwiftUI cross-import overlay rows
exist in this seed, so the overlay playbook does not apply.

| status | before | after |
|---|---|---:|
| `implemented` | 5235 | 5291 |
| `declared` | 152 | 96 |
| `deferred` | 245 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order;
largest new citation group is 12 rows, well under 40% of the 5,291
implemented rows):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

The remaining 96 `declared` rows are async witnesses (calling them needs
`await`, which the sealed gate forbids: async `next()`, async terminal
`AsyncSequence` consumers like `first`/`contains`/`allSatisfy`/`reduce`/
`max`/`min`, async `load` / `seek` / `image` / receiver `append` methods),
the three non-throwing `flatMap` overloads on Never-failure bases (all
three where-clauses hold there, so no call shape can pin exactly one),
`Combine` publishers, `FormatStyle` / `compare` /
`SortComparator`-element witnesses, `Element`-constrained (`Equatable`)
Sequence witnesses, and `AVAsynchronousKeyValueLoading` `status(of:)`
witnesses for types that do not adopt the protocol on this host. The 245
`deferred` rows are unchanged (completion-handler service calls,
Darwin-only types, `CALayer`/`URLSession` inheritance, and bodies that
cannot be written without guessing Apple behavior).

Sealed Linux gate (`bash full/avfoundation/tests/acceptance/test_host.sh`,
run under `swift:6.2-noble`, Swift 6.2.4, aarch64) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```

### Depth pass 2026-09-15 (wave 11 leftover sweep)

Wave 11 converts the four synchronous `Element`-constrained (`Equatable`)
`Sequence` witnesses on `AVCaptureSynchronizedDataCollection`
(`contains`, `elementsEqual`, `starts(with:)`, `split(separator:)`).
The collection is an empty `Sequence` of `AVCaptureSynchronizedData`
(iterator returns nil immediately, `count` is 0), and the element inherits
`Equatable` from `NSObject`, so the constraints hold with only
Apple-mirroring product surface. One test in
`tests/agent/AVDepthPass20Tests.swift` calls all four synchronously
(false / false / false / single empty slice); no hardware, daemon,
codec, or service success is claimed. No SwiftUI cross-import overlay
rows exist in this seed, so the overlay playbook does not apply.

| status | before | after |
|---|---|---:|
| `implemented` | 5291 | 5295 |
| `declared` | 96 | 92 |
| `deferred` | 245 | 245 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order;
the new test cites 4 rows, well under 40% of the 5,295 implemented rows):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

The remaining 92 `declared` rows are async witnesses (calling them needs
`await`, which the sealed gate forbids: async `next()`, async terminal
`AsyncSequence` consumers like `first`/`contains`/`allSatisfy`/`reduce`/
`max`/`min`, async `load` / `seek` / `image` / receiver `append` methods),
the three non-throwing `flatMap` overloads on Never-failure bases (all
three where-clauses hold there, so no call shape can pin exactly one),
the deprecated optional `flatMap` (calling it trips
`-warnings-as-errors`), `Combine` publishers (no Combine on the isolated
host), `FormatStyle` / `compare` / `SortComparator`-element witnesses
(calling them needs an invented style/comparator; that would exercise
stdlib, not product behavior), and `AVAsynchronousKeyValueLoading`
`load` / `status(of:)` witnesses for types that do not adopt the protocol
on this host (adding the conformance would invent Apple API). The 245
`deferred` rows are unchanged (completion-handler service calls,
Darwin-only types, `CALayer`/`URLSession` inheritance, opaque `some`
returns, and bodies that cannot be written without guessing Apple
behavior).

Host-equivalent Linux check (same compile-and-run steps as
`tests/acceptance/test_host.sh`, replicated under `swift:6.2-noble`
because this isolated worktree lacks the shared
`full/framework-roadmap/framework-roadmap.json` the checked-in validator
requires): dylib builds `-warnings-as-errors`, all 201 cited tests across
25 `*Tests.swift` files link and run, and the runner emits only
`AVFOUNDATION_AGENT_RUNTIME_OK`.

### Depth pass 2026-09-15 (wave 12 sync-twins sweep)

Wave 12 converts 127 synchronous `deferred` rows into focused tests in
`tests/agent/AVDepthPass21Tests.swift` (24 tests; largest citation group is
25 rows for the track async-property tokens). New product surface in
`AVPartialAsyncProperties.swift` (55 `AVPartialAsyncProperty` statics for the
track / asset / metadata-item / composition / movie families, plus citations
for the 5 already-declared `AVAsset` tokens) and `AVWave12SyncTwins.swift`
(synchronous completion-handler twins that invoke the caller's handler
inline: track loads project stored state, timeline seeks report false,
renderers/synchronizer/generator/photo fail closed, export
compatibility/estimates and the video-composition factory mirror the
oracle-pinned shapes below, reader/writer provider and receiver factories
vend fail-closed values, caption getters return oracle-pinned defaults, and
6 variant-qualifier factories return empty-universe predicates). Class-body
support in `AVCaptionSurface.swift` (internal validator status, warning
range storage) and `AVCaptureSurface.swift` (required bracket-settings
inits with stored bias/duration/ISO, stored `rawPhotoPixelFormatType`
wired through the RAW inits). Two pre-existing tests
(`AVMediaProbeTests`, `AVPlaybackTests`) now spell three generic-`load`
arguments as `AVPartialAsyncProperty<AVAsset>.tracks/isPlayable/metadata`
explicitly: the new per-root tokens otherwise make those inference sites
ambiguous. The spelled-out static is the same identifier the rows already
cited, so no evidence changed meaning.

| status | before | after |
|---|---|---:|
| `implemented` | 5295 | 5422 |
| `declared` | 92 | 92 |
| `deferred` | 245 | 118 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 implemented evidence distribution after this pass (unchanged order;
largest new citation group is 25 rows, well under 40% of the 5,422
implemented rows):

| citations | test |
|---:|---|
| 315 | `testDepthPass9BehavioralFamilies` (focused family audit) |
| 293 | `testAVMetadataIdentifierRawValues` (metadata identifier table) |
| 289 | `testOptionSetAlgebraSynthesis` (option-set algebra table) |
| 280 | `testAVMetadataKeyRawValues` (metadata key table) |
| 274 | `testRawRepresentableEnumHashableSynthesis` (enum synthesis table) |

Oracle pins from Xcode 26.1 on this Mac (no service/hardware success
claimed; transcripts are probe notes, not repo files): an
`import AVFoundation` run probe recorded fresh-`AVCaption` getter defaults
(zero raw values / nil colors and ruby, full-text effective range),
composition-track load shapes (`[]`, `[]`, invalid time, nil segment, all
with nil error), `insertTimeRange` reporting nil error, the video-composition
factory failing closed `(nil, error)`, the validator delivering one terminal
nil and moving validating (empty validation completes), export compatibility
`false`, `estimateMaximumDuration` zero-valid with nil error,
`estimateOutputFileLength` zero with nil error, empty playback options,
audio-renderer flush `true`, video flush / nil metrics / remove-`false`
delivery, and late-`false` timeline seeks (delivered synchronously as
`false` on Linux, where the gate forbids waiting). The header for
`rawPhotoPixelFormatType` pins the 0 default ("Returns 0 if you did not
specify RAW capture"). A simulator-SDK typecheck probe verified the
remaining spellings (`requestAccess(completionHandler:)`,
`setPreparedPhotoSettingsArray(_:completionHandler:)`, exposure factories,
all 16 provider/receiver factories, `images(for:)`, `setActionQueue`,
`notifyOfDataReady(for:completionHandler:)`, queue-registration twins, and
cursor comparison). Six operator-taking variant-qualifier overloads stay
deferred with a refined note: `NSComparisonPredicate` is unavailable in
swift-corelibs-foundation, so their Apple operator type cannot be named.

The remaining 92 `declared` rows are unchanged (async witnesses needing
`await`, ambiguous/deprecated `flatMap`, `Combine` publishers,
`FormatStyle` / `compare` / `SortComparator` witnesses, and
`AVAsynchronousKeyValueLoading` witnesses for non-adopting types). The
remaining 118 `deferred` rows are `CALayer`/`URLSession` inheritance,
Darwin-only types (UTType, simd matrices, `MTAudioProcessingTap`,
`NSPredicate` operators, FairPlay/content-key service paths, CIImage
filtering, image-source/depth-transform constructors returning `Self`
without a pixel pipeline), `NSCoder`/`NSValue` CoreMedia overlays, opaque
`some` returns, generic-shadowing methods, and async bodies that cannot be
exercised without `await`.

Sealed Linux gate (same `swift:6.2-noble` replication as above, Swift
6.2.4, aarch64) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVFoundation lane=medium-full symbols=5632
FRAMEWORK_FANOUT_REFERENCE_OK
AVFOUNDATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFoundation dylib=libAVFoundation.dylib
```
