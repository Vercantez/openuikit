# VisionKit (Linux starting point)

This directory is a clean-room Linux port of Apple's public `VisionKit` surface
from the iPhoneOS 26.1 SDK seed (256 exact public identifiers). It builds
`libVisionKit.dylib` from the sources listed in `visionkit_guest_sources.txt`.

## What is real

- Type-complete Swift APIs for `ImageAnalyzer`, `ImageAnalysis`,
  `ImageAnalysisInteraction`, `DataScannerViewController`, `RecognizedItem`,
  `VNDocumentCameraViewController`, and `VNDocumentCameraScan`.
- `OptionSet` algebra for `ImageAnalyzer.AnalysisTypes` and
  `ImageAnalysisInteraction.InteractionTypes`.
- Constructible scanner and document-camera view controllers, configuration
  storage, overlay container, zoom clamping, and delegate default methods.
- Host-only `@_spi(OpenUIKitHost)` fixtures for empty analyses, recognized
  items, subjects, and document scans so storage can be tested without a camera.

On this isolated Linux compile, UIKit / Vision / CoreImage / CoreVideo types
used in Apple signatures are provided as same-module stand-ins in
`VisionKitCompatibility.swift`. When those modules exist they are imported
instead.

## Fail-closed boundaries

These never report Apple-device success:

| API | Linux behavior |
| --- | --- |
| `ImageAnalyzer.isSupported` | `false` (no A12 / Neural Engine) |
| `ImageAnalyzer.analyze(...)` | throws `VisionKitAvailabilityError.imageAnalysisUnsupported` |
| `ImageAnalyzer.supportedTextRecognitionLanguages` | `[]` |
| `DataScannerViewController.isSupported` / `isAvailable` | `false` |
| `DataScannerViewController.startScanning()` | throws `.unsupported` |
| `DataScannerViewController.capturePhoto()` | throws `.cameraUnavailable` |
| `DataScannerViewController.recognizedItems` | immediately finished empty stream |
| `VNDocumentCameraViewController.isSupported` | `false` |
| `ImageAnalysisInteraction` hit-testing / subjects / Live Text UI | empty / `false` / throws `.imageUnavailable` |

Do not treat constructing a controller as evidence that a camera, document
scan, Visual Look Up, or Live Text session succeeded.

## Deferred / unresolved

Exact Apple `OptionSet` raw values, default `preferredInteractionTypes`,
out-of-range `imageOfPage(at:)`, and `contentsRect` when `view` is nil are
recorded in `oracle-questions.tsv`.
