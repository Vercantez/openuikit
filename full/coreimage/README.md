# CoreImage (Linux starting point)

This directory is a clean-room Linux implementation of the public `CoreImage`
surface seeded from Xcode 26.1 / iPhoneOS 26.1. It is not wired into a shared
guest package; that integration is a later central-review step.

The OpenUIKit silent-frameworks module (`uikit/Sources/CoreImage`) is a sibling
with a smaller surface (constant color + Gaussian blur + fail-closed QR). This
package keeps the same blur-extent rule (pad = 3 × radius) and does not edit
that module. Divergences are listed in `oracle-questions.tsv` and the agent
report.

## What is real

- `CIColor` named colors, string round-trip, RGBA components, `CIVector`.
- Constant-color and linear-gradient `CIImage` graphs, crop / affine transform
  (including rotations), composite, clamp, intermediates, and a CPU
  `CIContext.createCGImage` / `render(toBitmap:)` rasterizer.
- Named filters measured on iPhone SE 2x / iOS 26.1 software renderer:
  `CIGaussianBlur`, `CIColorControls`, `CISepiaTone`, `CIColorMatrix`,
  `CIExposureAdjust`, `CIVibrance`, `CIHueAdjust`, `CICrop`,
  `CIAffineTransform`, `CISourceOverCompositing`, `CIPhotoEffect*`,
  `CIQRCodeGenerator` (ISO 18004, quiet 1 module), `CICode128BarcodeGenerator`
  (ISO 15417 set B, quiet 10, height 32).
- `CIFilter(name:)` KVC (`setValue` / `value(forKey:)`), `inputKeys` /
  `outputKeys` / `attributes`, and `CIFilterBuiltins`-style factories.
- PNG encode/decode (stored deflate) and baseline JPEG representation.
- Typed `CIFormat` / option newtypes, public string keys, barcode descriptors,
  rect-based `CIFilterShape`, `CIImageAccumulator`.

## Fail-closed boundaries

- `COREIMAGE_SUPPORTS_IOSURFACE` and `COREIMAGE_SUPPORTS_OPENGLES` are `0`.
- HEIF / TIFF / OpenEXR representation APIs return nil or throw
  `CIRenderError.unsupported`.
- `CIAztecCodeGenerator` / `CIPDF417BarcodeGenerator` `outputImage` is nil.
- `CIDetector.features(in:)` always returns `[]` (no Vision models).
- `CIRAWFilter` URL/data initializers return nil; `supportedCameraModels` is
  empty.
- `CIKernel(source:)` and Metal-library kernel loaders return nil / throw.
- `CIBlendKernel.apply` implements `sourceOver` only.

Metal, EAGL, IOSurface, `CVPixelBuffer`, AVFoundation depth/matte, and
`CIImageProcessorInput`/`Output` are **unavailable**: those types are not
declared dependencies, and a module-local lookalike is forbidden.

## Pixel oracle

iPhone SE 2x / iOS 26.1 (`SIM_DEVICE_SUFFIX=-fw-coreimage`, software renderer,
sRGB working space unless noted):

| measurement | number |
|---|---|
| Gaussian blur 32×32 radius 2 extent | (−6, −6, 44, 44) = pad 3×radius |
| Rotate 4×2 +π/2 | (−2, 0, 2, 4) |
| ColorControls sat 0 Rec.709 | red 54, green 182, blue 18 |
| Sepia intensity 1 | red (76, 47, 12); 0.5 mix (165, 23, 6) |
| Exposure EV+1 sRGB gray 0.5 | (255, 255, 255) |
| QR "HELLO WORLD" M | 23×23 (version 1 + 1-module quiet), mask 0 |
| Code 128 "ABC-123" | 132×52, quiet 10, height 32 |
| PhotoEffect | 5³ RGB cubes (affine 3×4 did not fit) |
