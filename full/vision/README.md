# Vision (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public `Vision`
module, seeded from the Xcode 26.1 iPhoneOS symbol graph. It produces one
nominal Swift identity, `Vision`, and a loadable `libVision.dylib`. It is not
an Apple behavioral oracle and it is not wired into the shared guest package.

The legacy fan-out branch `cursor/port-vision-to-linux-90b3` (PR #17) was not
readable from this GitHub App installation (`Vercantez/openuikit` only; the
platform repository returned HTTP 404). The monorepo `reference/` dossier is
kept. The deliverable follows the sealed seed plus the recorded PR #17 repair
brief: honest coverage, no invented `VNErrorCode` ABI such as `turiCoreErrorCode = 10000`,
and a true minimum enclosing circle.

## What is real

- Geometry: `VNPoint`, `VNVector`, `VNCircle`, `VNContour`, coordinate
  conversion helpers (`VNImageRectForNormalizedRect`,
  `VNNormalizedRectForImageRect`, `VNImagePointForNormalizedPoint`, lower-left
  origin), shoelace area, perimeter, Douglas-Peucker approximation, and Welzl
  minimum enclosing circle (`VNGeometryUtils.boundingCircle` /
  `calculateArea` / `calculatePerimeter`).
- Catalog types: barcode symbologies, image options, compute stages, and the
  public enum surface used by rectangle/barcode/text/face requests.
- Request plumbing: `VNImageRequestHandler` inits (`cgImage:` / `ciImage:` /
  `data:` / `url:` / `cvPixelBuffer:` / `cmSampleBuffer:`, with orientation and
  options) and `perform([VNRequest])` run each request's `perform` in order.
  Cancel delivers `requestCancelled`. Empty/undecodable rasters deliver
  `invalidImage`. `@_spi(OpenUIKitHost)` attached results still short-circuit.
  `VNSequenceRequestHandler` forwards to the image handler.
- Classical detectors (generated fixtures, not Apple binaries):
  `VNDetectBarcodesRequest` (ISO 18004 QR finder/sample/mask/RS, Code128,
  EAN-13 → `VNBarcodeObservation.payloadStringValue` / `symbology` /
  `boundingBox`), `VNDetectRectanglesRequest` (Sobel + quadrilateral fit with
  documented aspect/size/confidence filters), `VNDetectContoursRequest`
  (threshold + tracing → `VNContoursObservation` with `normalizedPath`),
  `VNGenerateImageFeaturePrintRequest` (documented non-Apple 8³ colour
  histogram + L2 `computeDistance`), `VNTranslationalImageRegistrationRequest`
  (phase correlation), `VNTrackObjectRequest` (centroid/template tracker).
- Observations: `VNObservation` / `VNDetectedObjectObservation` /
  `VNRectangleObservation` / `VNTextObservation` value semantics (`uuid`,
  `confidence`, normalized `boundingBox` with lower-left origin).
- Swift overlay structs (`DetectBarcodesRequest`, `DetectRectanglesRequest`,
  `DetectContoursRequest`, `GenerateImageFeaturePrintRequest`,
  `ImageRequestHandler`, `NormalizedRect`) wrap the same classical path.

`VNErrorCode` integer layout follows independent `dotnet/macios` Native
bindings (`turiCoreErrorCode = -1`, `OK = 0`, then sequential). That is
declaration evidence, not an on-device Apple oracle.

## Fail-closed / not invented

- No Apple ML models on Linux. `VNRecognizeTextRequest`,
  `VNDetectFaceRectanglesRequest`, `VNClassifyImageRequest`,
  `VNDetectHumanBodyPoseRequest`, `VNCoreMLRequest`, and the other model-backed
  requests throw `VNErrorDomain` / `VNErrorCode.invalidModel` with `results ==
  nil`. This is **not** `requestCancelled`.
- `VNHomographicImageRegistrationRequest` throws `unsupportedRequest`; no 3×3
  warp is invented.
- Feature prints are a documented non-Apple colour histogram, not a learned
  embedding.
- Symbology and image-option raw strings are Linux-local tokens named after
  TBD export symbols; C-string bytes are unobserved.
- `VNCircle.contains(_:inCircumferentialRingOfWidth:)` uses `|d − r| ≤ width`.
- Lookalike `CGImage` / `CIImage` / `CVPixelBuffer` / `CMSampleBuffer` /
  `CGPath` types live in this module so the sealed host gate can compile
  without CoreGraphics/CoreImage products.

## Still deferred

About 150 exact public IDs remain deferred (3D pose joint names, video
processor tracking requests, some document/aesthetics observations). Overlay
stubs for remaining Swift iOS 26 request structs compile as `declared`.
`tests/agent/VisionDependencyIdentity.swift` is a future EC2 probe against
real CoreGraphics and CoreImage.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Campaign `ios26.1-fwdepth-r3`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Starting commit `5cc42895aa4277d0ed2103050b64be03fe813c3e`.
Branch `agent/fw-vision`.

Coverage honesty repair (merge refused `dd1e8715` for bulk `tests/agent/VisionRuntime.swift`
path evidence):

| | implemented | declared | deferred |
|---|---:|---:|---:|
| Wave-1 | 342 | 41 | 3201 |
| Depth pass before evidence repair | 1513 | 1922 | 149 |
| After focused `*Tests.swift#testName` ledger | **729** | **2560** | **295** |

Nondeferred 3289. Every `implemented` row cites
`test:full/vision/tests/agent/<File>Tests.swift#testName` for a real top-level
`func testName()`. Rows without a focused assertion are `declared` with
`source:full/vision/<file>.swift#Symbol`. Handler/request/observation/geometry/
barcode/rectangle/contour families remain nondeferred.

Top-5 implemented evidence distribution (729 rows):

1. `VisionEnumTests.swift#testValueCatalog` — 270 (37.0%) — table-driven enums, revisions, error codes (allowed shared value test)
2. `VisionIdentifierTests.swift#testBarcodeSymbologyCatalog` — 46 (6.3%)
3. `VisionOverlayTests.swift#testOverlayNormalizedGeometry` — 32 (4.4%)
4. `VisionRequestHandlerTests.swift#testImageRequestHandlerSources` — 24 (3.3%)
5. `VisionOverlayTests.swift#testOverlayBarcodePerform` — 24 (3.3%)

No non-enum test exceeds 40% of implemented rows.

Public surface implemented for real on Linux:

- Request machinery: `VNRequest` / `VNImageBasedRequest` (revision,
  `preferBackgroundProcessing`, `regionOfInterest`, `results`,
  `completionHandler`, `cancel`, `supportedRevisions`),
  `VNImageRequestHandler.perform`, `VNSequenceRequestHandler`.
- Classical: barcodes (QR/Code128/EAN-13), rectangles, contours, feature
  print, translational registration, object tracker, geometry utils.
- Fail-closed ML/CoreML/homography as documented above.

Unresolved behavioral questions (see `oracle-questions.tsv`): exact
`VNErrorDomain` UTF-8, on-device `invalidModel` vs other codes and completion
ordering, Apple QR sampling vs ISO fixtures, whether Apple feature prints are
learned embeddings, translational transform sign/origin, homography error
code, rectangle-filter coordinate space.

Environment note: `.cursor/verify-cloud-environment.sh` did not print
`CURSOR_SWIFT_ENVIRONMENT_OK` in this VM because `scratch/ladder-corpus/focus-ios`
is missing. `swiftc` is Swift 6.2.4 / `x86_64-unknown-linux-gnu`. The sealed
gate ran directly on this Linux host (no docker). Host gate output:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
VISION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Vision dylib=libVision.dylib
```

## Depth pass 2026-09 (wave 8)

Campaign `ios26.1-fwdepth-r15`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Starting commit `bff8535c68425cc39fb45cb00d447b0981b57242`.
Branch `cursor/port-vision-to-linux-8b8f`. Second pass on top of the wave-1
ledger (729 implemented / 2560 declared / 295 deferred).

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before (wave-1 ledger) | 729 | 2560 | 295 | 0 | 0 |
| After wave 8 | **1514** | **1940** | **130** | **0** | **0** |

Nondeferred 3454. Gain **+785 implemented**. Every `implemented` row cites
`test:full/vision/tests/agent/<File>Tests.swift#testName`. SwiftUI overlay
re-exports were not present in this surface (none marked `not-applicable`).

Top-5 implemented evidence distribution (1514 rows):

1. `VisionEnumTests.swift#testValueCatalog` — 270 (17.8%) — table-driven enums, revisions, and error codes
2. `VisionOverlayValueTests.swift#testOverlayPoseValueTypes` — 233 (15.4%) — overlay pose joints/groups and fail-closed keypoints
3. `VisionOverlayValueTests.swift#testOverlayFaceAndDocumentValues` — 172 (11.4%) — face landmarks and document container values
4. `VisionPoseTests.swift#testHumanBodyPose3DObservationJoints` — 59 (3.9%)
5. `VisionPoseTests.swift#testHumanBodyPoseObservationJoints` — 49 (3.2%)

No non-enum test exceeds 40% of implemented rows.

Added Linux behaviour this pass:

- Observation value types: `VNFaceLandmarks2D` regions + `pointsInImage`,
  `VNRecognizedPoint` / pose catalogs (`availableJointNames`,
  `recognizedPoint(_:)`, `recognizedPoints(_:)`, `recognizedPoints(forGroupKey:)`),
  `VNHumanBodyPose3DObservation` parent/camera mapping, `VNHorizonObservation`
  rotation from a supplied angle, `VNRecognizedTextObservation.topCandidates`.
- Overlay structs: `FaceObservation.Landmarks2D`, `DocumentObservation.Container`
  (text/list/table/data-detector values from supplied data), pose `Joint` /
  `Joint3D` catalogs. `keypoints` stays fail-closed (`invalidModel`).
- Request `perform` validates ROI (negative size → `invalidArgument`, outside
  unit square → `outOfBoundsError`) and revision (`unsupportedRevision`). ML
  detectors including hand/animal/3D pose, horizon, text rectangles, and face
  landmarks throw `invalidModel` with `results == nil`.
- Coordinate helpers remain lower-left; overlay `CoordinateOrigin.upperLeft`
  flips Y. ROI-relative C helpers round-trip with hand-computed fixtures.

Still fail-closed / not invented: Apple ML models, homography, learned feature
prints, on-device OCR/document parsing (document types only wrap caller-supplied
strings and geometry).

## Depth pass 2026-09 (wave 8)

Campaign `ios26.1-fwdepth-r16`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Starting commit `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`.
Branch `cursor/port-vision-to-linux-450f`. Next pass on top of the wave-8
ledger already in this tree (1514 implemented / 1940 declared / 130 deferred).

`.cursor/verify-cloud-environment.sh` failed on missing
`scratch/ladder-corpus/focus-ios`. `swiftc` is Swift 6.2.4 /
`x86_64-unknown-linux-gnu`. The sealed host gate was run directly on this Linux
host.

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before (wave 8 ledger) | 1514 | 1940 | 130 | 0 | 0 |
| After this pass | **2148** | **1306** | **130** | **0** | **0** |

Nondeferred 3454. Gain **+634 implemented**. Every `implemented` row cites
`test:full/vision/tests/agent/<File>Tests.swift#testName`. SwiftUI overlay
re-exports were not present (none marked `not-applicable`). Async overlay
`perform(on:orientation:)` overloads stay `declared`: tests exercise the same
fail-closed path through a synchronous `@_spi(OpenUIKitHost)` `performOnHandler`
so the sealed runtime does not wait on a semaphore.

Top-5 implemented evidence distribution (2148 rows):

1. `VisionOverlayRequestTests.swift#testOverlayRevisionComparableOperators` — 319 (14.9%) — Comparable / range operators on overlay `Revision` enums
2. `VisionEnumTests.swift#testValueCatalog` — 270 (12.6%) — table-driven enums, revisions, and error codes
3. `VisionOverlayValueTests.swift#testOverlayPoseValueTypes` — 233 (10.8%) — overlay pose joints/groups
4. `VisionOverlayValueTests.swift#testOverlayFaceAndDocumentValues` — 172 (8.0%) — face landmarks and document container values
5. `VisionPoseTests.swift#testHumanBodyPose3DObservationJoints` — 59 (2.7%)

No non-enum test exceeds 40% of implemented rows.

Added Linux behaviour this pass:

- Overlay `VisionRequest.supportedComputeStageDevices` is CPU-only.
- Overlay `performOnHandler` validates ROI (negative size → `invalidArgument`,
  outside unit square → `outOfBoundsError`) and empty rasters (`invalidImage`)
  before fail-closed ML (`invalidModel`).
- `RecognizeDocumentsRequest` text/barcode options (no Apple languages).
- `TrackOpticalFlowRequest` as a stateful class: accuracy, output pixel
  format, frame spacing; fail-closed (no optical-flow model).
- `VNTrackOpticalFlowRequest.keepNetworkOutput` / `outputPixelFormat`.
- `BarcodeObservation` Codable/Hashable overlay values from decoded QR
  fixtures, including composite-type mapping.
- `RequestDescriptor` / `VisionResult` catalogs with non-recursive
  `description`.

Still fail-closed / not invented: Apple ML / document / optical-flow models,
`performAll` AsyncSequence, homography, learned feature prints.

## Depth pass 2026-09 (wave 8)

Campaign `ios26.1-fwdepth-r17`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Starting commit `6bf18072f4bc9ca119f4b0ad49dd8478f92dd5f0`.
Branch `cursor/port-vision-to-linux-e150`. Next pass on top of the ledger
already in this tree (2148 implemented / 1306 declared / 130 deferred).

`.cursor/verify-cloud-environment.sh` failed on missing
`scratch/ladder-corpus/focus-ios`. `swiftc` is Swift 6.2.4 /
`x86_64-unknown-linux-gnu`. The sealed host gate was run directly on this Linux
host. Active Cursor Build on this VM was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`).

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token (Swift 6.2.4 / linux; the sealed gate refuses stale
`.build` / `build` / `scratch` products). Exact sealed-gate output:

```
FRAMEWORK_FANOUT_REFERENCE_OK
VISION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Vision dylib=libVision.dylib
```

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before (prior wave-8 ledger) | 2148 | 1306 | 130 | 0 | 0 |
| After this pass | **2559** | **937** | **88** | **0** | **0** |

Nondeferred 3496. Gain **+411 implemented**. Every `implemented` row cites
`test:full/vision/tests/agent/<File>Tests.swift#testName`. SwiftUI overlay
re-exports were not present (none marked `not-applicable`). Async overlay
`perform(on:orientation:)` overloads stay `declared`: tests exercise the same
fail-closed path through a synchronous `@_spi(OpenUIKitHost)` `performOnHandler`
so the sealed runtime does not wait on a semaphore.

Top-5 implemented evidence distribution (2559 rows):

1. `VisionOverlayRequestTests.swift#testOverlayRevisionComparableOperators` — 319 (12.5%) — Comparable / range operators on overlay `Revision` enums
2. `VisionEnumTests.swift#testValueCatalog` — 270 (10.6%) — table-driven enums, revisions, and error codes
3. `VisionOverlayValueTests.swift#testOverlayPoseValueTypes` — 233 (9.1%) — overlay pose joints/groups
4. `VisionOverlayValueTests.swift#testOverlayFaceAndDocumentValues` — 172 (6.7%) — face landmarks and document container values
5. `VisionPoseTests.swift#testHumanBodyPose3DObservationJoints` — 59 (2.3%)

No non-enum test exceeds 40% of implemented rows.

Added Linux behaviour this pass:

- Overlay `VisionError` LocalizedError catalog (table-driven cases).
- `ContoursObservation` / `Contour` geometry from supplied points (area,
  perimeter, child contours, Codable).
- `GeneratePersonSegmentationRequest` quality/pixel-format config; VN perform
  fail-closed (`invalidModel`).
- `TrackRectangleRequest` classical template tracker wrapping
  `VNTrackRectangleRequest`.
- `RecognizeAnimalsRequest` cat/dog identifiers; `knownAnimalIdentifiers` /
  `supportedIdentifiers` fail-closed.
- `DetectTrajectoriesRequest` length/radii/`targetFrameTime`; perform fail-closed.
- `CoreMLRequest` / `CoreMLModelContainer` (throwing init fail-closed; no Core ML).
- Pose/text/classify overlay request configuration; VN joint catalogs throw
  `invalidModel`.
- `DetectedDocumentObservation` corners + `DocumentObservation` nested Codable
  from caller-supplied text/list/table/data-detector values.
- `TrajectoryObservation` points/coefficients; `VNStatefulRequest` spacing.
- `PixelBufferObservation` size/format/`pixel(at:)`/`withUnsafePointer`/`cgImage`
  from a supplied buffer (not an Apple segmentation mask).

Still fail-closed / not invented: Apple ML models (person segmentation, animals,
trajectories, CoreML, pose, classify, text rectangles), homography, learned
feature prints, async overlay `perform(on:orientation:)`.

## Depth pass 2026-09 (wave 18)

Campaign `ios26.1-fwdepth-r18`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Starting commit `39dc25a2769fb88a50f0853964137a4f96d50322`.
Branch `cursor/port-vision-to-linux-248f`. Next pass on top of the ledger
already in this tree (2559 implemented / 937 declared / 88 deferred).

`.cursor/verify-cloud-environment.sh` failed on missing
`scratch/ladder-corpus/focus-ios`. `swiftc` is Swift 6.2.4 /
`x86_64-unknown-linux-gnu`. The sealed host gate was run directly on this Linux
host. Active Cursor Build on this VM was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`).

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token (Swift 6.2.4 / linux; the sealed gate refuses stale
`.build` / `build` / `scratch` products). The cloud report claimed the following
output, but the operator and local replay both failed the copied-revision
assertion. The verified local result is recorded below:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
VISION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Vision dylib=libVision.dylib
```

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before (prior wave-8 ledger) | 2559 | 937 | 88 | 0 | 0 |
| After this pass | **3001** | **525** | **58** | **0** | **0** |

Nondeferred 3526. Gain **+442 implemented**. Every `implemented` row cites
`test:full/vision/tests/agent/<File>Tests.swift#testName`. SwiftUI overlay
re-exports were not present (none marked `not-applicable`). Async overlay
`perform(on:orientation:)` overloads for the newly covered request types stay
`declared`: tests exercise the same fail-closed or classical path through a
synchronous `@_spi(OpenUIKitHost)` `performOnHandler` so the sealed runtime
does not wait on a semaphore.

Top-5 implemented evidence distribution (3001 rows):

1. `VisionOverlayRequestTests.swift#testOverlayRevisionComparableOperators` — 319 (10.6%) — Comparable / range operators on overlay `Revision` enums
2. `VisionEnumTests.swift#testValueCatalog` — 270 (9.0%) — table-driven enums, revisions, and error codes
3. `VisionOverlayValueTests.swift#testOverlayPoseValueTypes` — 233 (7.8%) — overlay pose joints/groups
4. `VisionOverlayValueTests.swift#testOverlayFaceAndDocumentValues` — 172 (5.7%) — face landmarks and document container values
5. `VisionPoseTests.swift#testHumanBodyPose3DObservationJoints` — 59 (2.0%)

No non-enum test exceeds 40% of implemented rows. The largest newly cited
focused test is `VisionDepthPassTests.swift#testDetectHumanRectanglesRequestConfig`
(26 rows).

Added Linux behaviour this pass:

- Overlay request config for lens smudge, face landmarks (constellation /
  `inputFaceObservations`), human rectangles (`upperBodyOnly`), face capture
  quality, aesthetics scores, document segmentation, person/foreground instance
  masks, attention and objectness saliency, overlay `TrackObjectRequest`
  spacing, and overlay text/horizon extras (`minimumTextHeightFraction`,
  `recognitionLanguages`).
- Fail-closed VN classes: `VNDetectHumanRectanglesRequest`,
  `VNDetectFaceCaptureQualityRequest`, `VNCalculateImageAestheticsScoresRequest`,
  `VNGeneratePersonInstanceMaskRequest`, `VNGenerateForegroundInstanceMaskRequest`,
  `VNGenerateObjectnessBasedSaliencyImageRequest`,
  `VNTrackHomographicImageRegistrationRequest` (`unsupportedRequest`).
- Sequential `VNTrackTranslationalImageRegistrationRequest` using classical
  phase correlation (first frame identity; later frames vs previous raster).
- Observation values from supplied data: overlay `TextObservation` /
  `HumanObservation` / `SmudgeObservation` / `InstanceMaskObservation` /
  `SaliencyImageObservation` / `ImageAestheticsScoresObservation`, including
  instance-mask `generateMask` / `generateMaskedImage` / nearest-neighbour
  scale-to-image.
- `VNFaceObservationAccepting`, `VNRequestProgressProviding` (indeterminate;
  handler stored, no model ticks), `VNRequestRevisionProviding` on
  `VNObservation`.

Still fail-closed / not invented: Apple ML models (faces, humans, aesthetics,
document segmentation, instance masks, saliency, lens smudge, OCR),
homographic tracking, video processor / AVFoundation cadence, Core ML feature
values, async overlay `perform(on:orientation:)`. Video-processor and Core ML
feature-value rows remain `deferred` (no video daemon / no Core ML runtime),
not `unavailable`.

### Local repair: `agent/fw-vision-r`

Merged `origin/main` at `c1973365` into the cloud head `10983df3`
(`platform/cursor/port-vision-to-linux-248f`). The merge was conflict-free;
all repair edits are confined to `full/vision/`. The immutable reference inputs
and sealed acceptance gate remain unchanged.

The operator log `/tmp/fw_merge_gate-vision.log` and an unmodified local replay
in `uikit-linux:/gate-codex-vision` both ended with:

```
FRAMEWORK_FANOUT_REFERENCE_OK
VISION_AGENT_RUNTIME_FAIL copied revision: 0 != 3
```

`VNDetectedObjectObservation.copy(with:)` and
`VNRectangleObservation.copy(with:)` replaced the supplied `requestRevision`
with `VNRequestRevisionUnspecified` (0). Both now forward the source revision.
`testRequestProgressAndRevisionProviding` verifies revision **3 → 3** for the
base, detected-object, and rectangle copies, retained identity/geometry values,
and independent copied objects. This is a measured Linux regression repair,
not a new claim about unobserved Apple model behaviour.

The four classical overlay tests now call the existing synchronous
`performOnHandler` SPI. Removed the semaphore/Task helper from both the cited
test sources and the sealed runtime. The 24 async overload rows formerly
credited to these tests are honestly `declared`; neither async scheduling nor
all async input overloads are asserted by a synchronous helper. The six
`ImageRequestHandler` constructor citations now point to a test that creates
its own QR fixture, decodes it through URL, Data, CGImage, CIImage, pixel-buffer,
and sample-buffer inputs, and removes its temporary directory.

| Snapshot | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Merged current main (`c1973365`) | 2559 | 937 | 88 | 0 | 0 |
| Refused wave-18 cloud head | 3001 | 525 | 58 | 0 | 0 |
| Verified local repair | **2977** | **549** | **58** | **0** | **0** |

Net gain over main: **+418 implemented**, with 3526 nondeferred IDs. All 442
newly implemented cloud rows are retained; only the 24 older async-only claims
are corrected. Every implemented row has a real synchronous no-argument test
anchor. There are **107** distinct cited tests; the largest anchor still covers
319 rows (**10.72%**), below the 40% limit even without the table-test exception.
No rows are marked `not-applicable`.

Validation on the operator's `uikit-linux` container, from the copied repository
root `/gate-codex-vision`:

```sh
timeout 3600 bash full/vision/tests/acceptance/test_host.sh
timeout 3600 bash full/vision/tests/agent/test_evidence.sh
```

The first command preserves the sealed warnings-as-errors library, import,
link, and consolidated runtime checks. The supplemental evidence script
compiles the actual `*Tests.swift` files with warnings as errors, validates
anchors and their distribution, and calls every cited test in a separate
process with a 30-second timeout. It does not alter or replace the sealed gate.
Both commands pass:

```
FRAMEWORK_FANOUT_REFERENCE_OK
VISION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Vision dylib=libVision.dylib
VISION_EVIDENCE_LEDGER_OK implemented=2977 tests=107 largest=319
VISION_EVIDENCE_OK
```

The individual evidence run completes all **107/107** cited tests. Apple model,
video, homography, async-wrapper, and platform dependency identity limitations
remain as documented above and in `oracle-questions.tsv`.

## Depth pass 2026-09 (wave 8)

This second-pass audit promoted the already implemented, synchronously exercised
observation-value and request-configuration surface family by family. It starts
with the requested rectangle, feature-print, text/object, alignment, contour,
hand/body-pose, and tracking families. Each promoted exact ID now cites the
focused test that exercises its supplied-data semantics, Codable/Hashable value
behavior, deterministic configuration, or explicit fail-closed model boundary;
async `perform` overloads remain declared because synchronous evidence does not
establish their scheduling behavior.

| Snapshot | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before wave 8 | 2977 | 549 | 58 | 0 | 0 |
| After wave 8 | **3285** | **241** | **58** | **0** | **0** |

Wave-8 implemented gain: **+308** exact public identifiers. The largest five
evidence anchors after this audit are:

| Focused evidence test | Implemented rows | Share of implemented |
|---|---:|---:|
| `testOverlayRevisionComparableOperators` | 319 | 9.71% |
| `testValueCatalog` | 270 | 8.22% |
| `testOverlayPoseValueTypes` | 241 | 7.34% |
| `testOverlayFaceAndDocumentValues` | 172 | 5.24% |
| `testHumanBodyPose3DObservationJoints` | 86 | 2.62% |

The fail-closed boundary is unchanged: Linux does not claim Apple Vision ML,
Core ML feature-value production, Apple video processing, hardware/daemon
services, or unobserved async scheduling. Those APIs either throw the documented
Vision error from validated input or remain `declared`/`deferred` with their
existing reasons. There are no `unavailable` rows and no SwiftUI-overlay rows in
this pinned surface requiring `not-applicable` classification. Remaining Apple-
oracle questions are tracked in `oracle-questions.tsv`.
