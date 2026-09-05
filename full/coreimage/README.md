# CoreImage (Linux starting point)

This directory is a clean-room Linux implementation of the public `CoreImage`
surface seeded from Xcode 26.1 / iPhoneOS 26.1. It is not wired into a shared
guest package; that integration is a later central-review step.

The OpenUIKit silent-frameworks module (`uikit/Sources/CoreImage`) is a sibling
with a smaller surface (constant color + Gaussian blur + fail-closed QR). This
package keeps the same blur-extent rule (pad = 3 × radius) and does not edit
that module.

## What is real

- `CIColor` / `CIVector` value semantics (`isEqual` / `hash`), named colors,
  string round-trip, RGBA / affine / rect storage.
- Constant-color and linear-gradient `CIImage` graphs; crop, affine transform
  (including rotations), source-over composite, clamp, and CPU
  `CIContext.createCGImage` / `render(toBitmap:)`.
- Named filters with Apple's published working-space formulas and pixel tests
  against a hand-computed raster: `CIGaussianBlur` (3σ extent pad),
  `CIColorControls` (Rec.709 luma), `CISepiaTone` (published 3×3 matrix),
  `CIColorMatrix`, `CIExposureAdjust` (`s' = s · 2^EV`), `CIVibrance`,
  `CIHueAdjust`, `CICrop`, `CIAffineTransform`, `CISourceOverCompositing`,
  `CIPhotoEffect*`, `CIQRCodeGenerator` (ISO 18004 data codewords),
  `CICode128BarcodeGenerator` (ISO 15417 set B).
- `CIFilter(name:)` KVC, exact `kCIInput*` keys, nested `attributes`
  dictionaries (`kCIAttributeClass` / `Type` / `Default`), and
  `CIFilterBuiltins`-style factories.
- PNG encode/decode and baseline JPEG representation of the working-space
  raster. Default working space is sRGB / RGBA8; ColorSync matching is not
  performed.

## Fail-closed boundaries

- `COREIMAGE_SUPPORTS_IOSURFACE` and `COREIMAGE_SUPPORTS_OPENGLES` are `0`.
- HEIF / TIFF / OpenEXR representation APIs return nil or throw
  `CIRenderError.unsupported`.
- `CIAztecCodeGenerator` / `CIPDF417BarcodeGenerator` `outputImage` is nil.
- `CIDetector.features(in:)` always returns `[]` (no Vision / ML models).
- `CIRAWFilter` URL/data initializers return nil; `supportedCameraModels` is
  empty.
- `CIKernel(source:)` and Metal-library kernel loaders return nil / throw.
- `CIBlendKernel.apply` implements `sourceOver` only.
- Depth-blur filters, render tasks, and `CIImageProcessorKernel.apply` throw
  or return nil.

Metal, EAGL, IOSurface, `CVPixelBuffer`, AVFoundation depth/matte, and
`CIImageProcessorInput`/`Output` are **unavailable**: those types are not
declared dependencies, and a module-local lookalike is forbidden.

## Working-space rules

The CPU pipeline samples in `CIContext.workingColorSpace` (default sRGB) at
pixel centers and writes unpremultiplied RGBA8. `pngRepresentation` /
`jpegRepresentation` encode that raster. A linear working-space option is
recorded on the context but does not decode/encode through the sRGB transfer
function (see `oracle-questions.tsv`).

## Depth pass 2026-09

Second SDK-depth pass on `origin/agent/fw-coreimage`. The first pass labelled
213 of 510 non-table `implemented` rows with a single
`testCIDeclaredSurface` identity test; that bulk evidence was refused.

| | before (pass 1) | after (pass 2) |
|---|---|---|
| `implemented` | 765 | 621 |
| `declared` | 0 | 144 |
| `unavailable` | 90 | 90 |
| nondeferred | 765 | 765 |

Top-5 `implemented` evidence distribution after reclassification (table-driven
C-constant / option-set / enum tests may share a value test; no other single
test exceeds 40% of the remaining implemented rows):

| citations | test |
|---|---|
| 172 | `testCIAllOptionStatics` (option-set / format members) |
| 133 | `testCIAllStringConstants` (C `kCI*` / detector keys) |
| 37 | `testCIFormatConstants` |
| 28 | `testCIEnums` |
| 28 | `testCIVectorComponents` |

Behavioural tests added or split out of the bulk row: CIImage init/extent/
crop/transform/composite/`applyingFilter`, CIContext working-space
`createCGImage` / PNG / JPEG, named-filter keys and attributes, per-filter
pixel formulas, ISO 18004 QR data codewords, Code 128, and
CIKernel / CIDetector fail-closed paths.
