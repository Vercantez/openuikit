# VisionKit (Linux starting point)

This directory is a clean-room Linux port of Apple's public `VisionKit` surface
from the iPhoneOS 26.1 SDK seed (256 exact public identifiers). It builds
`libVisionKit.dylib` from the sources listed in `visionkit_guest_sources.txt`.

Isolated `tests/acceptance/test_host.sh` only compiles VisionKit guest sources
plus `tests/agent/VisionKitRuntime.swift`. That gate is **not** an integrated
Linux success. Cross-module identity is prepared in
`tests/agent/VisionKitDependencyIdentity.swift` for a future EC2 run that first
builds real guest Foundation, UIKit, CoreGraphics, ImageIO, CoreImage,
CoreVideo, and Vision.

## What is real

- Foundation-only types and fail-closed flags: `ImageAnalyzer` support/languages,
  `AnalysisTypes` / `InteractionTypes` set algebra (not Apple bit layout),
  `Configuration`, scanner quality/text-content/unavailable enums, constructible
  controllers, zoom clamping with no camera, empty `recognizedItems`, inert Live
  Text hit-testing, and document-camera `isSupported == false`.
- `@_spi(OpenUIKitHost)` fixtures for empty `ImageAnalysis`, recognized items,
  subjects, and document scans. Those fixtures are test-only.
- When guest UIKit/Vision/CoreGraphics/ImageIO/CoreImage/CoreVideo are imported
  independently (not `#elseif`), analyze/capture/view/observation routes compile
  against **those modules' types**. This module does not define `UIImage`,
  `CGImage`, `CGImagePropertyOrientation`, `CVPixelBuffer`, `CIImage`, or Vision
  observation identities.

`VisionKitHostError`, `failClosed()`, and `cancel()` are SPI, not Apple graph
surface.

## Fail-closed boundaries

| API | Linux behavior |
| --- | --- |
| `ImageAnalyzer.isSupported` | `false` (no A12 / Neural Engine) |
| `ImageAnalyzer.analyze(...)` | throws `VisionKitHostError.imageAnalysisUnsupported` (when dependency types exist) |
| `ImageAnalyzer.supportedTextRecognitionLanguages` | `[]` |
| `DataScannerViewController.isSupported` / `isAvailable` | `false` |
| `DataScannerViewController.startScanning()` | throws `ScanningUnavailable` (Apple case precedence unattested) |
| `DataScannerViewController.capturePhoto()` | throws `VisionKitHostError.cameraUnavailable` |
| `DataScannerViewController.recognizedItems` | immediately finished empty stream |
| `VNDocumentCameraViewController.isSupported` | `false` |
| `ImageAnalysisInteraction` hit-testing / subjects / Live Text UI | empty / `false` / `.imageUnavailable` |

Do not treat constructing a controller as a successful camera, document scan,
Visual Look Up, or Live Text session.

## Deferred / unattested

See `oracle-questions.tsv` and `coverage.tsv`. OptionSet raw bits, default
`preferredInteractionTypes`, `startScanning` error precedence, out-of-range
`imageOfPage(at:)`, and default `contentsRect` stay deferred until an Apple
oracle attests them. UIKit/Vision/image-buffer routes stay deferred on the
isolated host until the EC2 dependency-identity run.
