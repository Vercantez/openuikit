# VideoToolbox (Linux starting point)

This directory is a clean-room Linux Swift overlay for Apple's public
`VideoToolbox` module, seeded from the iPhoneOS 26.1 symbol graph.

## What is real

- Public `OSStatus` constants from `VTErrors.h`, integer knobs such as
  `kVTUnlimitedFrameDelayCount`, and identity `CFString` keys for compression,
  decompression, pixel-transfer, and encoder-specification properties.
- Option-set flags (`VTDecodeInfoFlags`, `VTEncodeInfoFlags`,
  `VTCompressionSessionOptionFlags`, `VTDecodeFrameFlags`, motion-estimation
  frame flags) with the documented bit layout.
- CF session types (`VTCompressionSession`, `VTDecompressionSession`,
  `VTFrameSilo`, `VTMultiPassStorage`, `VTPixelRotationSession`,
  `VTPixelTransferSession`) plus the C create/encode/decode/query overlay.
- Frame-processor overlay types (`VTFrameProcessor`, configurations,
  parameters, `VTFrameProcessorError`) and motion-estimation / HDR metadata
  session types.

`VTCopyVideoEncoderList` returns an empty list. Hardware-decode and MV-HEVC
capability queries return `false`. `VT_SUPPORT_COLORSYNC_PIXEL_TRANSFER` is
`false`.

## Fail-closed boundaries

Linux has no Apple video encoder, decoder, ColorSync pixel-transfer path,
frame-processor model service, or Dolby Vision metadata generator.

- Session `Create` APIs return `kVTCouldNotFindVideoEncoderErr`,
  `kVTCouldNotFindVideoDecoderErr`, `kVTPixelTransferNotSupportedErr`,
  `kVTPixelRotationNotSupportedErr`, or `kVTCouldNotCreateInstanceErr` and
  write `nil` to the out-parameter.
- Encode, decode, rotate, transfer, and CGImage conversion APIs return the
  same family of errors and never emit a sample or image.
- `VTFrameProcessorConfiguration.isSupported` is `false`. Failable
  configuration inits return `nil`. `startSession` throws
  `VTFrameProcessorError.initializationFailed`. Super-resolution model
  download reports `assetDownloadFailed`.
- `VTMotionEstimationSession` and `VTHDRPerFrameMetadataGenerationSession`
  inits throw rather than producing motion vectors or HDR metadata.

Do not treat a zero `OSStatus` from `VTCopyVideoEncoderList` as evidence that
a hardware encoder exists; the list is empty.

## Deferred / unavailable

Exact Apple `CFSTR` payloads for property keys, numeric `CMVideoCodecType`
fourccs, and pixel-buffer layout for a software transfer path remain
oracle questions. Successful codec, hardware, host-service, and Metal
command-buffer processing is unavailable on this seed.
