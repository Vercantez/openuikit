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
Branch `agent/fw-vision`. Coverage after this pass: **implemented ≥ 900**
(classical handler/request/observation/geometry/barcode/rectangle/contour
families are nondeferred). Wave-1 was 342 implemented / 41 declared / 3201
deferred.

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
gate is run directly on this Linux host (no docker). Expected gate markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
VISION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Vision dylib=libVision.dylib
```
