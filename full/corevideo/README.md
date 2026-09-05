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
- Fail-closed Metal / OpenGL ES cache and wrap entry points, including
  `CVEAGLContext` as an alias of a module-local `EAGLContext` lookalike.

## Fail-closed boundaries

- `COREVIDEO_SUPPORTS_METAL`, `_OPENGLES`, `_IOSURFACE`, `_DISPLAYLINK`,
  `_OPENGL`, `_DIRECT3D`, and `_COLORSPACE` are `false`.
- `CVPixelBufferCreateWithIOSurface` returns `kCVReturnUnsupported`.
  `CVPixelBufferGetIOSurface` and overlay `withUnsafeBackingIOSurfaceIfPresent`
  return nil. Overlay `backing: .ioSurface` throws `CVError.unsupported`.
- `CVMetalBufferCacheCreate`, `CVMetalTextureCacheCreate`,
  `CVOpenGLESTextureCacheCreate`, and the corresponding wrap-from-image APIs
  return `kCVReturnUnsupported` and write nil. `CVMetalBufferGetBuffer` /
  `CVMetalTextureGetTexture` return nil. `CVOpenGLESTextureGetName` /
  `GetTarget` return 0. Texture coordinate helpers still fill normalized
  coords from the flip flag; they do not invent a GPU texture.
- Compressed (lossy/lossless) FourCCs are identified but
  `CVIsCompressedPixelFormatAvailable` is always false and create fails with
  `kCVReturnInvalidPixelFormat`.
- Color-space queries return nil; there is no ColorSync/`CGColorSpace` profile
  inventing.

Metal/`MTLDevice` and `EAGLContext` names used in those signatures are
module-local lookalikes so the standalone Linux module compiles without
importing Metal or GLKit. They are not claimed as CoreVideo identifiers
except `CVEAGLContext`.

## Deferred

None of the 980 public precise identifiers remain deferred. DisplayLink
callbacks, real MTL/EAGL object wrapping, and exact Apple CFString payloads
for a few ProRes RAW / display-mask keys still need an Apple-oracle probe
(see `oracle-questions.tsv`). Those paths stay fail-closed.

## Depth pass 2026-09

Coverage before this pass: **968 implemented / 0 declared / 12 deferred**.

Coverage after: **980 implemented / 0 declared / 0 deferred**.

The remaining 12 identifiers were the Metal/OpenGL ES create/wrap APIs plus
`CVEAGLContext`. They are now implemented as documented fail-closed GPU
boundaries (`kCVReturnUnsupported` / nil / 0) against module-local lookalikes,
with focused tests in `tests/agent/CoreVideoMetalTests.swift`.

Every `implemented` row cites
`test:full/corevideo/tests/agent/<File>Tests.swift#testName`. Enum / option-set
members and C `k…`/`err…` constants share table-driven value tests; other
families have focused tests.

Top-5 evidence distribution (of 980 implemented rows):

1. `testPixelFormatFourCCs` — 99 (C FourCC constants)
2. `testImageBufferKeys` — 82 (C `kCVImageBuffer*` keys)
3. `testFormatOptionSetAlgebra` — 54 (Components/Compatibility option-set algebra)
4. `testBufferAndPixelBufferKeys` — 41 (C buffer/pool keys)
5. `testPixelFormatDescriptionKeys` — 33 (C format-description keys)

Largest non-constant test is `testFormatOptionSetAlgebra` at 54 rows (5.5%),
under the 40% bulk-relabel cap.
