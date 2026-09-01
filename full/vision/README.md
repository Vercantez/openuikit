# Vision (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `Vision`
module, seeded from the Xcode 26.1 iPhoneOS symbol graph. It is not Apple
behavioral parity and it is not wired into the shared guest package.

## What is real

- Geometry: `VNPoint`, `VNVector`, `VNCircle`, enclosing-circle for point
  sets, and the `VNImage*` / `VNNormalized*` coordinate mapping helpers,
  including region-of-interest variants and face-landmark projection through
  `SIMD2<Float>` (`vector_float2`).
- Configuration surface used by the 20-app corpus: `VNImageRequestHandler` /
  `VNSequenceRequestHandler` (`Data` / `URL`), `VNDetectBarcodesRequest`,
  `VNDetectFaceRectanglesRequest`, `VNDetectRectanglesRequest`,
  `VNRecognizeTextRequest`, `VNGenerateAttentionBasedSaliencyImageRequest`,
  plus the surrounding `VN*` request/observation types those apps compile
  against (faces, landmarks, human rectangles, document segmentation,
  animals, classification, tracking, optical-flow request objects).
- Observation constructors that exist on Apple (`boundingBox`, rectangle
  corners, face pose angles). `topCandidates` returns whatever candidates a
  caller constructed; handlers never invent OCR/barcode/face hits.
- `VNErrorDomain` + `VNErrorCode` + typed `VNError`. Empty image data yields
  `invalidImage`; a missing file URL yields `ioError`; `cancel()` yields
  `requestCancelled`; model-backed `perform` yields `notImplemented`.
- Identifier newtypes: `VNBarcodeSymbology` (including PascalCase overlays),
  `VNAnimalIdentifier`, `VNImageOption`, `VNComputeStage`.

## Fail-closed boundaries

Linux has no Apple Vision models, FaceCore, person segmentation GPU path,
Core ML, or camera/depth buffers. `VNImageRequestHandler.perform` and
`VNSequenceRequestHandler.perform` never return fabricated detections.
Completion handlers are invoked with the typed error, then `perform` throws
the same error.

`CGImage` / `CIImage` / `CVPixelBuffer` / `CMSampleBuffer` handler entry
points are omitted from this isolated compile (Foundation only). They remain
`unavailable` until CoreGraphics, CoreImage, and CoreVideo are linked by
central review.

Core ML (`VNCoreMLModel` / `VNCoreMLRequest`), video processing
(`VNVideoProcessor`), 3D pose, instance masks, and pixel-buffer observations
are unavailable. NSCoder inits return `nil`.

## Deferred

The iOS 18+ Swift-native overlay (`RecognizeTextRequest`, `DetectBarcodesRequest`
structs, `ImageRequestHandler` actors, `VisionObservation` protocol) is a later
partition. Covariant Objective-C `results` overlays (`[VNBarcodeObservation]?`
on the subclass) are expressed as `[VNObservation]?` on `VNRequest`; callers
cast.

## Tests

`tests/agent/VisionRuntime.swift` exercises geometry, request configuration,
fail-closed `perform`, cancel, and error identity, then prints
`VISION_AGENT_RUNTIME_OK`.
