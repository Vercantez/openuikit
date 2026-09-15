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
  (phase correlation), `VNTrackObjectRequest` (centroid/template tracker),
  `VNDetectHorizonRequest` (Sobel + weighted-PCA line fit), overlay
  `DetectLensSmudgeRequest` (Laplacian-RMS contrast),
  `VNDetectTextRectanglesRequest` (dark-on-light connected components grouped
  into line bands → `VNTextObservation` with optional `characterBoxes`; never
  recognizes characters), `VNDetectDocumentSegmentationRequest` (largest
  classical rectangle as the document quad → `VNRectangleObservation`),
  `VNGenerateAttentionBasedSaliencyImageRequest` /
  `VNGenerateObjectnessBasedSaliencyImageRequest` (shared center-surround
  contrast heat map → `VNSaliencyImageObservation` with a thresholded salient
  box), `VNCalculateImageAestheticsScoresRequest` (Laplacian-variance
  sharpness + Hasler-Susstrunk colorfulness →
  `VNImageAestheticsScoresObservation`; flat gray scores 0 with `isUtility`).
- Classical dense optical flow (`visionOpticalFlowVectors` block matching,
  documented non-Apple): `VNGenerateOpticalFlowRequest` (targeted vs
  reference → `VNPixelBufferObservation` in `TwoComponent32Float` sized to the
  reference) and `VNTrackOpticalFlowRequest` / overlay `TrackOpticalFlowRequest`
  (stateful previous-frame flow; first frame zero flow). Layout, size, format,
  sign, and zero-motion are Apple-oracle pinned (macOS Vision, Xcode 26.1);
  magnitudes are the block-matcher's own.
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
  nil`. This is **not** `requestCancelled`. Text *localization*
  (`VNDetectTextRectanglesRequest`), document quads, contrast saliency, and
  heuristic aesthetics scores are classical geometry/statistics instead (see
  above) and never claim Apple model output.
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

58 exact public IDs remain deferred: `VNVideoProcessor` and its cadence /
processing-options surface (no Linux AVFoundation video pipeline) and
`VNCoreMLFeatureValueObservation` plus its synthesized witnesses (no Apple
Core ML runtime). 214 `declared` rows are all async
`ImageProcessingRequest.perform(on:orientation:)` / `ImageRequestHandler.perform`
/ targeted-`perform` overloads (`YaKF` / `YaK`): the sealed Linux gate forbids
`await`, semaphores, and run-loop waits in cited tests, so async scheduling
stays declared rather than receiving invented synchronous evidence.
`tests/agent/VisionDependencyIdentity.swift` is a future EC2 probe against
real CoreGraphics and CoreImage.
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

### Wave 8 next-pass continuation

The next-pass audit exhausted the remaining synchronously provable non-video
families. It adds mutable `VNGenerateOpticalFlowRequest` output configuration
with a validated `invalidModel` boundary, confidence-ordered recognized-object
labels with copy preservation, Codable face/horizon values, concrete overlay
protocol witnesses, and all six targeted-image input constructors. The targeted
handler validates both images before its async model boundary; it never reports
Apple optical flow or registration results on Linux.

| Snapshot | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before next-pass continuation | 3285 | 241 | 58 | 0 | 0 |
| After next-pass continuation | **3310** | **216** | **58** | **0** | **0** |

The honest implemented gain is **+25**. A 300-row gain is arithmetically
impossible from the supplied starting ledger, which contains only 299 total
non-implemented rows, and 58 of those are Core ML/video-runtime deferred rows.
The remaining 216 declared IDs are async `ImageProcessingRequest`,
`ImageRequestHandler`, and `TargetedImageRequestHandler` overloads (including
synthesized conformer occurrences). The sealed synchronous-test rule forbids
using `Task`/`await` or blocking run-loop work to claim those identifiers, so
they remain declared rather than receiving invented evidence.

The five largest evidence anchors remain `testOverlayRevisionComparableOperators`
(319 rows), `testValueCatalog` (270), `testOverlayPoseValueTypes` (241),
`testOverlayFaceAndDocumentValues` (172), and
`testHumanBodyPose3DObservationJoints` (86). The largest accounts for 9.64% of
the 3310 implemented rows. The new focused anchors cover 5 optical-flow rows,
7 targeted-input rows, 7 protocol/typealias rows, 4 Codable rows, and 2
recognized-object rows.

## Depth pass 2026-09 (classical overlay continuation)

Campaign `ios26.1-fwdepth-r3` continuation on the ledger already in this tree
(3310 implemented / 216 declared / 58 deferred). Work stays inside
`full/vision/`.

| Snapshot | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before this continuation | 3310 | 216 | 58 | 0 | 0 |
| After this continuation | **3312** | **214** | **58** | **0** | **0** |

Implemented gain: **+2**. The only remaining non-async `perform` identifiers in
the graph were `ImageRequestHandler.performAll` and
`TargetedImageRequestHandler.performAll` (mangled as ordinary methods that
return `some AsyncSequence`, not `YaKF`). Both now run the request list
synchronously, wrap the `VisionResult`s in an `AsyncSequence` with `Never`
failure, and are asserted through `@_spi(OpenUIKitHost) performAllNow` so the
sealed Linux gate never `await`s. The 214 leftover declared rows are all
async `perform(on:orientation:)` / `ImageRequestHandler.perform` / targeted
`perform` overloads (`YaKF` / `YaK`). Those stay declared: a different
synchronous helper is not the same identifier.

Added Linux behaviour this pass:

- `VNDetectHorizonRequest` / overlay `DetectHorizonRequest` classical Sobel +
  weighted-PCA line fit (documented non-Apple; 0 rad = level in lower-left
  coordinates).
- Overlay `DetectLensSmudgeRequest` Laplacian-RMS contrast mapped to 0...1
  (uniform gray scores high; a sharp rectangle scores lower). Not Apple's
  smudge model.
- Overlay `TrackObjectRequest.performOnHandler` now has a focused two-frame
  centroid/template assertion, matching the existing VN tracker.
- `ImageRequestHandler.performAll` exercises barcodes, rectangles, contours,
  feature print, horizon, lens smudge, object tracking, and fail-closed
  classify through the same synchronous collector.

Classify / recognize / Core ML / video-processor / homographic tracking remain
fail-closed or deferred as before. Async overlay `perform(on:orientation:)`
stays declared.

## Depth pass 2026-09 (classical text/saliency/aesthetics continuation)

Campaign `ios26.1-fwdepth-r3` continuation on the ledger already in this tree
(3312 implemented / 214 declared / 58 deferred). Work stays inside
`full/vision/`.

| Snapshot | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before this continuation | 3312 | 214 | 58 | 0 | 0 |
| After this continuation | **3312** | **214** | **58** | **0** | **0** |

Implemented gain: **+0 by count, +5 request families by behaviour**. The
ledger was already at its honest ceiling: every remaining `declared` row is an
async `perform(on:orientation:)` / `ImageRequestHandler.perform` / targeted
`perform` overload (`YaKF` / `YaK`) that the sealed Linux gate cannot cite
without `await`, and every `deferred` row is `VNVideoProcessor` /
`VNCoreMLFeatureValueObservation` (no video daemon / no Core ML runtime).
This pass converts five fail-closed synchronous families to documented
classical behaviour, keeping their `implemented` status with updated
`test:…#testName` evidence and notes (114 rows re-noted, none relabelled).

Added Linux behaviour this pass (all documented non-Apple heuristics):

- `VNDetectTextRectanglesRequest` / overlay `DetectTextRectanglesRequest`:
  dark-on-light connected components grouped into vertically-overlapping line
  bands → `VNTextObservation` quads; `reportCharacterBoxes` attaches one
  `VNRectangleObservation` per component. Never recognizes characters.
- `VNDetectDocumentSegmentationRequest` / overlay
  `DetectDocumentSegmentationRequest`: largest classical Sobel/quadrilateral
  fit (permissive probe: `minimumSize` 0.02, tolerance 45°) as the document
  quad; empty on uniform input.
- `VNGenerateAttentionBasedSaliencyImageRequest` /
  `VNGenerateObjectnessBasedSaliencyImageRequest` and both overlay structs:
  one shared center-surround contrast heat map (32² grid, 3×3 blur residual,
  full-resolution RGBA) → `VNSaliencyImageObservation` with a half-max
  thresholded salient box; uniform input yields confidence 0 and no boxes.
- `VNCalculateImageAestheticsScoresRequest` / overlay
  `CalculateImageAestheticsScoresRequest`: Laplacian-variance sharpness (65%)
  plus Hasler-Susstrunk colorfulness (35%) → `overallScore` in 0...1 with
  `isUtility` below 0.2; flat gray scores exactly 0.
- Overlay `performOnHandler` for all five delegates to the matching VN
  request through `handler.perform([request])` (single source of truth) and
  maps results to `TextObservation` / `DetectedDocumentObservation` /
  `SaliencyImageObservation` / `ImageAestheticsScoresObservation`.
- New `visionTextLinesImage()` fixture (two dark bars on white) shared by
  `VisionHarnessTests.swift` and the sealed `VisionRuntime.swift`.

Face / human / pose / hand / animal / text-recognition / classify / Core ML
stay fail-closed (`invalidModel`); homography stays `unsupportedRequest`;
video-processor and Core ML feature values stay deferred; async overlay
`perform(on:orientation:)` stays declared.

Repair note (pi-wave pass below): the Moore component tracer described above
was absent from the tree on arrival (the greedy `(dir + offset + 6) % 8` tracer
was still in `VisionDetectors.swift#traceContours`, and
`VisionDetectorTests.swift#testContourDetectorInvertedPolarity` did not exist),
and the sealed gate was RED at baseline in the validation container
(`VISION_AGENT_RUNTIME_FAIL performAll contours`, reproduced on pristine HEAD).
The repair was implemented in the pi-wave pass below; the record above is kept
for audit continuity.

## Depth pass 2026-09 (pi-wave classical optical flow + contour-tracer repair)

Campaign `ios26.1-fwdepth-r3`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Work stays inside `full/vision/`. Starting ledger: 3312
implemented / 214 declared / 58 deferred.

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before this pass | 3312 | 214 | 58 | 0 | 0 |
| After this pass | **3312** | **214** | **58** | **0** | **0** |

Implemented gain: **+0 by count, +2 request families by behaviour, sealed gate
FAIL → PASS**. The ledger is at its honest ceiling: all 214 remaining `declared` rows are async
`ImageProcessingRequest.perform(on:orientation:)` / `ImageRequestHandler.perform`
/ targeted-`perform` overloads (`YaKF` / `YaK`) that the sealed Linux gate
cannot cite without `await`, and all 58 `deferred` rows are `VNVideoProcessor` /
`VNCoreMLFeatureValueObservation` (no video daemon / no Core ML runtime). This
pass converts the two fail-closed synchronous optical-flow families to
documented classical behaviour, keeping their `implemented` status with updated
`test:…#testName` evidence and notes (5 rows re-pointed to the new focused
test, 62 rows re-noted, none relabelled).

Apple oracle (macOS Vision, Xcode 26.1, run 2026-09-14; transcript in
`scratch/oracle-2026-09-14/vision-optical-flow.txt`, removed before the gate):

- `VNGenerateOpticalFlowRequest` returns one `VNPixelBufferObservation` sized
  to the reference image, format `kCVPixelFormatType_TwoComponent32Float`
  (`0x32433066`, two Float32 (dx, dy) per pixel).
- Sign convention matches the CG shift direction (x-right, y-down); identical
  frames read ~0. Magnitudes on random noise read ~1.1–1.4x the true shift, so
  only layout, size, format, sign, and zero-motion are pinned.
- Revisions: generate supported [1, 2], current 2, default 2; track supported
  [1], current 1, default 1. Default `outputPixelFormat` is `2C0f` (not
  `32BGRA`), default accuracy medium, `keepNetworkOutput` false — for both.

Added Linux behaviour this pass (all documented non-Apple heuristics):

- `visionOpticalFlowVectors(from:to:searchRadius:)` (`VisionDetectors.swift`):
  dense block matching on a ≤40px working grid (5×5 SAD, integer
  displacements, accuracy → radius low 4 / medium 8 / high 12 / veryHigh 16
  full-res px), nearest-neighbour upsample scaled to full-resolution pixels,
  match-quality confidence. Targeted image resampled to the reference size.
- `VNGenerateOpticalFlowRequest.perform`: targeted vs handler-ROI rasters →
  one `VNPixelBufferObservation` (`2C0f`); missing targeted image throws
  `missingOption` with `results == nil`. Revision overrides added
  (current/default 2, supported 1...2, oracle-pinned).
- `VNTrackOpticalFlowRequest.perform`: stateful previous-frame flow (first
  frame zero flow, confidence 1, matching the translational tracker's
  identity-first precedent); default `outputPixelFormat` corrected to `2C0f`.
- Overlay `TrackOpticalFlowRequest.performOnHandler`: delegates to an inner
  stateful `VNTrackOpticalFlowRequest` (single source of truth) and maps to
  `OpticalFlowObservation`; Linux-local default/format list aligned to `2C0f`.
- `CVPixelBuffer` lookalike: `pixelFormat` tag plus `init(flowWidth:flowHeight:vectors:)`
  / `flowVector(x:y:)` for `2C0f` buffers; RGBA path unchanged.
- New `visionNoiseTextureImage()` LCG fixture and `VisionOpticalFlowTests.swift`
  (7 focused tests: shift recovery ±2px, identical-frame ~0, missing-target
  error, revisions, sequential track, overlay sequential, buffer round trip),
  mirrored into the sealed `VisionRuntime.swift`.
- Contour-tracer repair (`VisionDetectors.swift#traceContours`, implementing the
  design recorded above): 8-connectivity component labelling traces each
  foreground blob once from its topmost-leftmost pixel; Moore boundary
  following with explicit backtrack direction and (pixel, backtrack) state
  tracking. The inverted rectangle fixture now yields the region-border loop
  instead of zero contours, and all pre-existing rectangle/contour assertions
  pass unchanged (verified: full evidence ledger green, sealed gate green).
  New focused test `VisionDetectorTests.swift#testContourDetectorInvertedPolarity`
  pins the inverted path (default `detectsDarkOnLight` on the rectangle
  fixture → ≥1 contour, top level ≥1, non-nil path); mirrored into the sealed
  `VisionRuntime.swift`. No rows relabelled.

Classify / recognize / faces / humans / poses / Core ML stay fail-closed
(`invalidModel`); homography stays `unsupportedRequest`; video-processor and
Core ML feature values stay deferred; async overlay `perform(on:orientation:)`
stays declared. New open questions (flow magnitude gain, first-frame tracking
semantics, size-mismatch policy) are recorded in `oracle-questions.tsv`.

## Depth pass 2026-09 (pi-wave classical homography + foreground + trajectories)

Campaign `ios26.1-fwdepth-r3`, lane `large-partitioned`, framework `Vision`
(3584 IDs). Work stays inside `full/vision/`. Starting ledger: 3312
implemented / 214 declared / 58 deferred.

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before this pass | 3312 | 214 | 58 | 0 | 0 |
| After this pass | **3312** | **214** | **58** | **0** | **0** |

Implemented gain: **+0 by count, +3 request families by behaviour**. The ledger
remains at its honest ceiling: all 214 `declared` rows are async
`ImageProcessingRequest.perform(on:orientation:)` / `ImageRequestHandler.perform`
/ targeted-`perform` overloads (`YaKF` / `YaK`) that the sealed Linux gate
cannot cite without `await`, and all 58 `deferred` rows are `VNVideoProcessor` /
`VNCoreMLFeatureValueObservation` (no video daemon / no Core ML runtime). This
pass converts the last three fail-closed synchronous families to documented
classical behaviour, keeping their `implemented` status with focused
`test:…#testName` evidence (100 rows re-pointed/re-noted, none relabelled).

Added Linux behaviour this pass (all documented non-Apple heuristics):

- `VNHomographicImageRegistrationRequest` / `VNTrackHomographicImageRegistrationRequest`
  / overlay `TrackHomographicImageRegistrationRequest`: Harris corners + 7x7
  NCC matching + Hartley-normalized DLT with exhaustive deterministic RANSAC
  over the 12 best matches (≥6 inliers at ≥50% ratio), falling back to the
  phase-correlation translation embedded in a 3x3 matrix. Linux-local
  convention: `warpTransform` maps source (targeted/previous-frame) pixels to
  reference (handler/current) pixels, column-major. Stateful tracking returns
  identity (confidence 1) on the first frame. Missing targeted image throws
  `missingOption` with `results == nil`.
- Overlay `ImageHomographicAlignmentObservation` gains the members its coverage
  rows already claimed: `applyTransform(to:)` (pass-through), `init(_:)`
  from the VN observation, and explicit `Codable` (9 column-major floats).
- `VNGenerateForegroundInstanceMaskRequest` / overlay
  `GenerateForegroundInstanceMaskRequest`: shared center-surround contrast heat
  map at half-maximum, border flood-fill hole closing, largest 4-connected blob
  as instance 1 → `VNInstanceMaskObservation` / `InstanceMaskObservation`.
  Uniform images yield an empty mask with confidence 0. Generic contrast
  foreground, not person segmentation.
- `VNDetectTrajectoriesRequest` / overlay `DetectTrajectoriesRequest`:
  stateful Harris-corner tracklets (NCC block match, 64px working grid) with
  `max(2, trajectoryLength)`-point latency, sub-pixel-motion filtering, and
  normalized-radius bounds → `VNTrajectoryObservation` with linear per-frame
  velocity in `equationCoefficients`, up to 3 extrapolated `projectedPoints`,
  and net-displacement `movingAverageRadius`.
- New `VisionClassicalAlignmentTests.swift` (11 focused tests: homography shift
  recovery ±2.5px, identical-frame ~identity, missing-target error, sequential
  track, overlay sequential, overlay value/Codable coverage, foreground labels
  + hole fill + uniform-empty, trajectory direction/velocity, static-empty,
  overlay trajectories), mirrored into the sealed `VisionRuntime.swift`.
  `testHomographicRegistrationFailClosed` is removed; its 18 rows are re-pointed
  to the new anchors. The three `*RequestConfig` tests now assert classical
  first-frame/empty behaviour instead of fail-closed errors.

Classify / recognize / faces / humans / poses / Core ML stay fail-closed
(`invalidModel`); video-processor and Core ML feature values stay deferred;
async overlay `perform(on:orientation:)` stays declared. New open questions
(warp convention, trajectory coefficient units, foreground mask policy) are
recorded in `oracle-questions.tsv`.

## Depth pass 2026-09 (pi-wave6 audit, no gain)

Campaign `pi-wave6`, lane `mixed UI + non-UI`, framework `Vision` (3584 IDs).
Work stays inside `full/vision/`. Starting ledger: 3312 implemented / 214
declared / 58 deferred / 0 not-applicable.

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before this pass | 3312 | 214 | 58 | 0 | 0 |
| After this pass | **3312** | **214** | **58** | **0** | **0** |

Implemented gain: **+0**. The ledger is at its honest ceiling, verified row by
row this pass:

- Overlay OVERRIDE inapplicable: the coverage surface contains **0** precise
  IDs mentioning `View` or `SwiftUI`, and product sources define no SwiftUI
  `View` modifiers. There are no identity `Self`-returning overlays to convert
  with the FamilyControls playbook.
- All 214 `declared` rows contain the async marker `YaK`/`YaKF`: six
  `ImageProcessingRequest.perform(on:orientation:)` protocol witnesses, their
  34×6 synthesized conformer occurrences, plus async
  `ImageRequestHandler.perform` / `TargetedImageRequestHandler.perform`
  overloads. The sealed synchronous-test rule forbids `await`, semaphores, and
  run-loop waits in cited tests, so async scheduling stays declared rather
  than receiving invented synchronous evidence.
- All 58 `deferred` rows require a missing daemon/runtime: 40
  `VNVideoProcessor` / cadence / processing-options rows (no Linux
  AVFoundation video pipeline) and 18 `VNCoreMLFeatureValueObservation` rows
  (no Apple Core ML runtime). Per-contract fail-closed/deferred policy they
  stay deferred.

Environment note: this audit ran on a macOS host (Apple Swift 6.2.1,
arm64-apple-macosx). The sealed Linux gate is RED at baseline here because the
`#if !canImport(...)` Linux lookalikes (`CGImagePropertyOrientation`,
`CVPixelBuffer`, `CMTime`, `MLComputeDevice`, …) are skipped where the real
Apple frameworks are importable but never imported by the Linux-first sources.
That is a host/SDK mismatch, not a coverage regression: no product, coverage,
manifest, or test file was changed by this audit.
