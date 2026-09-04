# CoreImage (Linux starting point)

This directory is a clean-room Linux implementation of the public `CoreImage`
surface seeded from Xcode 26.1 / iPhoneOS 26.1. It is not wired into a shared
guest package; that integration is a later central-review step.

## What is real

- `CIColor` named colors, string round-trip, and RGBA components.
- `CIVector` scalar / `CGPoint` / `CGRect` / affine storage and parsing.
- Constant-color and linear-gradient `CIImage` graphs, crop/transform/composite
  tagging, and a deterministic CPU `CIContext.createCGImage` / `render(toBitmap:)`
  path that preserves the original lane's linear-gradient rasterizer.
- `CIFilter.linearGradient()` / `smoothLinearGradient()` and a small name
  registry (`CILinearGradient`, `CISmoothLinearGradient`,
  `CIConstantColorGenerator`).
- Typed `CIFormat` / option newtypes, public string keys, barcode descriptors,
  rect-based `CIFilterShape`, `CIImageAccumulator`, and fail-closed detectors.

## Fail-closed boundaries

- `COREIMAGE_SUPPORTS_IOSURFACE` and `COREIMAGE_SUPPORTS_OPENGLES` are `0`.
- JPEG / PNG / TIFF / HEIF / OpenEXR representation APIs return nil or throw
  `CIRenderError.unsupported`. There is no Apple codec on this host.
- `CIDetector.features(in:)` always returns `[]`. Face / QR / text / rectangle
  detection is not invented.
- `CIRAWFilter` URL/data initializers return nil; `supportedCameraModels` is
  empty. RAW decode is not invented.
- `CIKernel(source:)` and Metal-library kernel loaders return nil / throw.
  CIKL and `.metallib` compilation are absent.
- `CIBlendKernel.apply` implements `sourceOver` only; other blend names exist
  as distinct kernels and return nil.

Metal, EAGL, IOSurface, `CVPixelBuffer`, and AVFoundation depth/matte types are
not given public lookalikes. Those APIs are deferred.

## Deferred

GPU context/image initializers, pixel-buffer wrapping, IOSurface, image-codec
byte identity, ColorSync matching, and Apple's exact `CIFormat` ABI versus the
pinned `dotnet/macios` integer table remain for a later pass or an Apple-oracle
probe (see `oracle-questions.tsv`).
