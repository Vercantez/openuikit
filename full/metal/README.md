# Metal (Linux starting point)

This directory is an isolated clean-room port of Apple's public `Metal`
module for OpenUIKit on Linux. It reconstructs Swift names from the pinned
iPhoneOS 26.1 symbol graph. It is not wired into the shared guest package.

## What is real

- Geometry value types (`MTLSize`, `MTLOrigin`, `MTLRegion`, `MTLViewport`,
  `MTLScissorRect`, `MTLClearColor`, `MTLSamplePosition`) and their `Make`
  helpers.
- Pixel formats, resource options, texture usage, GPU-family / feature-set
  enumerations, and common pipeline/sampler/blend enums with public header
  raw values.
- Descriptor objects (`MTLTextureDescriptor`, render-pass / render-pipeline
  descriptors, sampler and depth-stencil descriptors, compile options).
- `MTLCreateSystemDefaultDevice()` returns a CPU software adapter named
  `OpenUIKit Software Metal`. The adapter allocates shared `MTLBuffer` and
  `MTLTexture` storage, records blit fills/copies, and reports
  `hasUnifiedMemory == true`.
- Sampler and depth-stencil *state objects* store descriptor configuration.
  They do not execute GPU work.

## Fail-closed boundaries

- `supportsFamily` / `supportsFeatureSet` are `false` for every Apple GPU
  family. This is not an Apple GPU.
- Shader compilation (`makeLibrary(source:)`) throws
  `MTLLibraryError.unsupported`. There is no AIR/Metal compiler here.
- `makeLibrary(URL:)` throws `MTLLibraryError.fileNotFound`. Apple metallib
  binaries are not loaded.
- `makeDefaultLibrary()` returns `nil`.
- GPU capture (`MTLCaptureManager`) reports no supported destinations and
  `startCapture(with:)` throws `MTLCaptureError.notSupported`.
- Ray tracing, Metal 4 command queues, tensors, IO command queues,
  acceleration structures, and IOSurface-backed textures are not implemented.
- Compressed pixel formats cannot be CPU-copied; `replace`/`getBytes` no-op
  when bytes-per-pixel is unknown.

## Still deferred

Most of the 4547 public identifiers remain deferred: encoder draw/dispatch
APIs, argument encoders, heaps, residency sets, binary archives, counters,
function stitching, and the Metal 4 compiler surface. See `coverage.tsv`.

IOSurface is a declared seed dependency but is not imported; this module
compiles standalone against Foundation.
