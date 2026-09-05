# VisionKit

Linux starting point for Apple's public `VisionKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph, the in-repo PR #27 repair brief,
and Apple's published availability contract. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

The private platform branch `cursor/port-visionkit-to-linux-83e2` could not be
fetched with this GitHub App token (404). This is a content reconstruction, not
a byte-copy of the 1414 Swift lines on that branch.

**Reference dossier:** kept the monorepo `full/visionkit/reference/` (generator
`scripts/framework-fanout/generate_seed.py`, SHA256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`).

## What is real

The public Swift surface that does not require UIKit, Vision, CoreImage,
CoreVideo, or ImageIO compiles to `libVisionKit.dylib`.

Fail-closed availability (Apple documents A12+/camera authorization; Linux has
neither):

- `DataScannerViewController.isSupported == false`
- `DataScannerViewController.isAvailable == false`
- `DataScannerViewController.supportedTextRecognitionLanguages == []`
- `ImageAnalyzer.isSupported == false`
- `ImageAnalyzer.supportedTextRecognitionLanguages == []`
- `VNDocumentCameraViewController.isSupported == false`

Also implemented:

- `ImageAnalyzer.AnalysisTypes` and `ImageAnalysisInteraction.InteractionTypes`
  as `OptionSet` (Linux-local bits; Darwin numeric ABI is unobserved)
- `ImageAnalyzer.Configuration` stored `analysisTypes` / `locales`
- `DataScannerViewController` initializer defaults from the symbol graph
  (`.balanced`, `recognizesMultipleItems == false`, high-frame-rate / pinch /
  guidance true, highlighting false)
- `startScanning()` throws `ScanningUnavailable.unsupported` and never sets
  `isScanning`
- Interaction hit-tests return `false`; subjects and recognized items stay empty
- `RecognizedItem.Bounds` using Foundation `CGPoint`

`@_spi(OpenUIKitHost)` fixtures exist for `ImageAnalysis`, `RecognizedItem.Text`
/ `Barcode`, `ImageAnalysisInteraction.Subject`, and `VNDocumentCameraScan`.
They are not Apple public constructors.

## Fail-closed boundaries

Linux has no camera, Live Text service, Visual Look Up, or document scanner.

- `analyze` overloads that take `UIImage` / `CGImage` / `CIImage` /
  `CVPixelBuffer` / `CGImagePropertyOrientation` are compiled only when those
  modules import; they throw and never return an analysis.
- `capturePhoto()`, `overlayContainerView`, `image(for:)`,
  `ImageAnalysisInteraction.view`, fonts/insets, and Vision observation
  properties are omitted on the isolated host (no same-named substitutes).
- Document-camera appear does **not** invent `didFail` / `didFinish` / cancel.
- `startScanning` does **not** also call `becameUnavailableWithError` (Darwin
  throw-versus-delegate precedence is unobserved).

## Still open

See `oracle-questions.tsv` for OptionSet bits, contents-rect mapping, zoom
hardware range, start-error precedence, and out-of-range `imageOfPage`.

`tests/agent/VisionKitRuntime.swift` is the isolated host probe
(`VISIONKIT_AGENT_RUNTIME_OK`). Focused `tests/agent/*Tests.swift` functions
are the coverage evidence. `tests/agent/VisionKitDependencyIdentity.swift`
is prepared for a future clean EC2 run that builds guest Foundation, UIKit, and
Vision first. Compiling that file against toolchain Foundation is not
guest-module success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Coverage before this pass: **214 implemented / 19 declared / 23 deferred /
0 unavailable / 0 not-applicable**.

Coverage after: **233 implemented / 0 declared / 23 deferred / 0 unavailable /
0 not-applicable**.

Raised to `implemented` (documented Linux semantics, fail-closed where
hardware or Apple services are required):

- `ImageAnalyzer.AnalysisTypes` named flags, `rawValue`, and `init(rawValue:)`
  (Linux-local bits `1<<0` / `1<<1` / `1<<2`; Darwin ABI still unobserved)
- `ImageAnalysisInteraction.InteractionTypes` named flags, `rawValue`, and
  `init(rawValue:)` (sequential Linux-local bits; Darwin ABI unobserved)
- `preferredInteractionTypes` (Linux default empty; `activeInteractionTypes`
  mirrors it only when `analysis` is set)
- `contentsRect` / `setContentsRectNeedsUpdate` (delegate rect or `.zero`)
- `minZoomFactor` / `maxZoomFactor` (Linux `[1, 1]` clamp; no zoom hardware)
- Foundation `localizedDescription` on `ScanningUnavailable` and
  `SubjectUnavailable`

Left **deferred** (23): every identifier whose signature requires UIKit,
Vision, CoreImage, CoreVideo, or ImageIO on the isolated host
(`UIView` / `UIImage` / `UIFont` / `UIEdgeInsets` / `CGImage` /
`CIImage` / `CVPixelBuffer` / `VNBarcodeSymbology` / Vision observations).
No same-named substitutes.

Corpus ranking (`reference/corpus-summary.json`): Telegram and Nextcloud
exercise `VNDocumentCameraViewController` and Nextcloud also uses image
analysis overlay paths. Those families are implemented and fail-closed;
page images and Live Text analyze overloads stay deferred.

Top-5 evidence distribution (233 implemented rows):

1. `AnalysisTypesTests.swift#testAnalysisTypesAlgebra` — 22 (9.4%)
2. `InteractionTypesTests.swift#testInteractionTypesAlgebra` — 22 (9.4%)
3. `DataScannerTests.swift#testDataScannerDelegate` — 14 (6.0%)
4. `DataScannerTests.swift#testDataScannerTextContentType` — 13 (5.6%)
5. `InteractionTypesTests.swift#testInteractionTypesBits` — 12 (5.2%)

No single non-enum/OptionSet test exceeds 40% of implemented rows. OptionSet
members share table-driven bit tests as allowed.
