# VideoToolbox Linux lane

This directory is a Linux starting implementation of Apple's public
`VideoToolbox` C API, reconstructed from pinned `dotnet/macios` bindings
after the original Xcode 26.1 extractor seed was absent from `origin/main`.

The sealed host gate compiles this module with toolchain Foundation only.
CoreMedia and CoreVideo identities are therefore declared as VideoToolbox-owned
stand-ins (`VTVideoFormatDescription`, `VTMediaTime`, host pixel buffers)
rather than imported `CMVideoFormatDescription` / `CVPixelBuffer` types.
Runtime gaps versus those ports are listed below.

## What is real

- Named `OSStatus` constants from the pinned macios `VTDefs.cs` mapping of
  `VTErrors.h`, with exact integer values.
- Decode/encode info and frame option-set flags with the documented bit
  positions.
- `VTDecompressionSessionCreate` with a format description: a software
  passthrough decoder for uncompressed `kCVPixelFormatType_32BGRA` (and the
  other packed/biplanar formats this module allocates). The output callback
  runs synchronously, or asynchronously when
  `kVTDecodeFrame_EnableAsynchronousDecompression` is set; presentation
  timestamp and duration are forwarded. `DoNotOutputFrame` sets
  `kVTDecodeInfo_FrameDropped`. `FinishDelayedFrames`,
  `WaitForAsynchronousFrames`, `CanAcceptFormatDescription`, and
  `CopyBlackPixelBuffer` are live session machinery.
- `VTPixelTransferSessionTransferImage` performs CPU conversion between
  32BGRA/RGBA/ARGB/ABGR, 24RGB/BGR, and 4:2:0 biplanar YCbCr, with
  `kVTScalingMode_Normal` / `Letterbox` / `Trim` /
  `CropSourceToCleanAperture`. Pixel rotation implements 0/90/180/CCW90.
- `VTCreateCGImageFromCVPixelBuffer` copies host pixel buffers into a
  software RGBA image object (not a Darwin `CGImage`).
- `VTSessionSetProperty` / `CopyProperty` / `CopySupportedPropertyDictionary`
  validate documented `kVTCompressionPropertyKey_*` /
  `kVTDecompressionPropertyKey_*` / pixel-transfer keys for type and range.
  Read-only keys return `kVTPropertyReadOnlyErr`.
- `VTFrameSilo` and `VTMultiPassStorage` create in-memory objects with value
  semantics (ordered sample buffers, close).
- `VTIsHardwareDecodeSupported` is always `false`.

## Fail-closed boundaries

- H.264 (`avc1`) and HEVC (`hvc1`) create return
  `kVTCouldNotFindVideoDecoderErr` / `kVTCouldNotFindVideoEncoderErr`.
- Motion-JPEG / `kCMVideoCodecType_JPEG` encode and decode fail closed with the
  same codes: ImageIO is not importable on the isolated gate
  (`#if canImport(ImageIO)` is false), so the port's JPEG codec is not
  reachable.
- RAW processing, motion estimation, HDR per-frame metadata, and Media
  Extension queries fail closed (`kVTCouldNotFindExtensionErr`,
  `kVTCouldNotFindTemporalFilterErr`, `kVTAllocationFailedErr`).
- `GetTypeID` helpers return `0`. Darwin `CFTypeID` values are unobserved.
- Property-key `String` payloads are the public C identifiers. Darwin `CFSTR`
  bytes were not observed.

## CoreMedia / CoreVideo runtime gaps

- `CMVideoFormatDescription` is represented by
  `VTVideoFormatDescription` (codec type, width, height, extensions).
- `CMSampleBuffer` / `CMTime` are `VTHostCreateSampleBuffer` /
  `VTMediaTime` (`value` / `timescale` / `flags` / `epoch`).
- Pixel buffers are `VTHostCreatePixelBuffer` with CoreVideo FourCCs
  (`kVTPixelFormat_32BGRA == kCVPixelFormatType_32BGRA`). They are not the
  CoreVideo `CVPixelBuffer` class and will not interchange until a later
  integration links both modules.
- `CGImage` is a host RGBA wrapper, not CoreGraphics.

Sources listed in `videotoolbox_guest_sources.txt` compile to
`libVideoToolbox.dylib`.

## Depth pass 2026-09

SDK depth for `VideoToolbox` (482 IDs). Session, property, pixel-transfer,
and error families are nondeferred. Implemented count: 482/482.

Gate (Linux host, no docker):

```
bash full/videotoolbox/tests/acceptance/test_host.sh
```

Expected markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
VIDEOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=VideoToolbox dylib=libVideoToolbox.dylib
```

`swiftc --version` on this host is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did not
emit the campaign `products=clean` line because the scratch corpus checkout
`scratch/ladder-corpus/focus-ios` is absent from this snapshot; the sealed
framework gate does not require that checkout.
