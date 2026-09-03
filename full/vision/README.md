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
  conversion helpers, shoelace area, perimeter, Douglas-Peucker approximation,
  and Welzl minimum enclosing circle (empty/singleton/duplicates/collinear/
  obtuse/acute/order-invariance tests).
- Catalog types: barcode symbologies, image options, compute stages, and the
  public enum surface used by rectangle/barcode/text/face requests.
- Request plumbing: `VNImageRequestHandler` / `VNSequenceRequestHandler`
  `perform` throws `VNErrorCode.notImplemented` unless
  `@_spi(OpenUIKitHost)` results are attached. Cancel delivers
  `requestCancelled`. No ML success path.
- Observations store bounding boxes, QR payload fields, and text candidates
  that tests inject; they do not come from a detector.

`VNErrorCode` integer layout follows independent `dotnet/macios` Native
bindings (`turiCoreErrorCode = -1`, `OK = 0`, then sequential). That is
declaration evidence, not an on-device Apple oracle.

## Fail-closed / not invented

- No Core ML models, OCR, barcode decode, face landmarks, optical flow, or
  person segmentation execute. `perform` fails closed.
- `CGImage` / `CIImage` / `CVPixelBuffer` / `CMSampleBuffer` handler inits are
  omitted until those modules exist (`canImport` is false on this host).
- `VNContour.normalizedPath` (`CGPath`) is omitted without CoreGraphics.
- `VNObservation.timeRange` is omitted without CoreMedia.
- Symbology and image-option raw strings are Linux-local tokens named after
  TBD export symbols; C-string bytes are unobserved.
- `VNCircle.contains(_:inCircumferentialRingOfWidth:)` uses `|d − r| ≤ width`.

## Still deferred

Most of the 3584 exact public IDs remain deferred: pose graphs, document
observation, Core ML requests, video processor, Swift-only iOS 26 request
structs, and dependency-gated image types. `tests/agent/VisionDependencyIdentity.swift`
is a future EC2 probe against real CoreGraphics and CoreImage.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```
