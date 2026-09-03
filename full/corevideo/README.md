# CoreVideo (Linux starting point)

This directory is a clean-room Linux implementation of the public `CoreVideo`
surface seeded from Xcode 26.1 / iPhoneOS 26.1. It is not wired into a shared
guest package; that integration is a later central-review step.

## What is real

- Software `CVPixelBuffer` allocation for packed 32/24/16/8-bit formats and
  common 4:2:0 / 4:2:2 / 4:4:4 biplanar YCbCr layouts, including lock/unlock,
  plane pointers, row bytes, extended-pixel queries, and `CreateWithBytes`.
- `CVBuffer` attachments with propagate / non-propagate modes.
- `CVPixelBufferPool` allocation, an allocation-threshold fail path, and flush.
- Public `OSType` pixel-format constants, `CVReturn` codes, `CVTime` /
  `CVTimeStamp` / `CVSMPTETime`, and well-known CFString keys.
- The iOS 26 Swift overlay around those buffers: `CVError`, `CVImageSize`,
  `CVPixelFormatType`, `CVMutablePixelBuffer`, `CVReadOnlyPixelBuffer`,
  creation attributes, and a pixel-format description registry.

## Fail-closed boundaries

- `COREVIDEO_SUPPORTS_METAL`, `_OPENGLES`, `_IOSURFACE`, `_DISPLAYLINK`,
  `_OPENGL`, `_DIRECT3D`, and `_COLORSPACE` are `false`.
- `CVPixelBufferCreateWithIOSurface` returns `kCVReturnUnsupported`.
  `CVPixelBufferGetIOSurface` and overlay `withUnsafeBackingIOSurfaceIfPresent`
  return nil. Overlay `backing: .ioSurface` throws `CVError.unsupported`.
- Compressed (lossy/lossless) FourCCs are identified but
  `CVIsCompressedPixelFormatAvailable` is always false and create fails with
  `kCVReturnInvalidPixelFormat`.
- Color-space queries return nil; there is no ColorSync/`CGColorSpace` profile
  inventing.

Metal/OpenGL ES cache *create* APIs that require `MTLDevice` / `EAGLContext`
are deferred rather than stubbed with fake GPU types.

## Deferred

DisplayLink, Metal texture/buffer wrapping of GPU objects, OpenGL ES texture
caches, and exact Apple CFString values for a few ProRes RAW / display-mask
keys remain for a later pass or an Apple-oracle probe (see
`oracle-questions.tsv`).
