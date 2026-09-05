# Metal (Linux starting point)

This directory is an isolated clean-room port of Apple's public `Metal`
module for OpenUIKit on Linux. It reconstructs Swift names from the pinned
iPhoneOS 26.1 symbol graph. It is not wired into the shared guest package.

## What is real

- Geometry value types (`MTLSize`, `MTLOrigin`, `MTLRegion`, `MTLViewport`,
  `MTLScissorRect`, `MTLClearColor`, `MTLSamplePosition`) and their `Make`
  helpers, plus pixel-format / resource-option / pipeline enumerations with
  public-header raw values.
- Descriptor objects with value semantics: texture, sampler, heap, render
  pass, render pipeline, vertex, depth-stencil, compile options, blit/compute
  pass, argument, capture, and related arrays.
- `MTLCreateSystemDefaultDevice()` returns a CPU reference adapter named
  **OpenUIKit CPU Reference**. The adapter allocates real shared `MTLBuffer`
  and `MTLTexture` storage, executes blit and documented CPU compute kernels,
  and applies render-pass load/store without rasterizing.
- Command buffers transition
  `.notEnqueued → .enqueued → .committed → .scheduled → .completed` in order
  on `commit()`, with `error == nil` and GPU/kernel timestamps from
  `ProcessInfo.processInfo.systemUptime`.
- Sampler, heap, fence, and event objects store configuration / CPU signaling.
  They do not execute GPU work.

## Fail-closed boundaries

- `supportsFamily` / `supportsFeatureSet` are `false` for every Apple GPU
  family. This is not an Apple GPU.
- Shader compilation (`makeLibrary(source:)`) throws
  `MTLLibraryError.compileFailure` whose description lists **no shader compiler**.
- `makeLibrary(URL:)` / `makeLibrary(filepath:)` throw
  `MTLLibraryError.fileNotFound`. Apple metallib binaries are not loaded.
- `makeDefaultLibrary()` returns `nil`.
- Compute dispatch runs only the documented CPU builtin kernels
  (`openuikit.cpu.fillUInt32`, `openuikit.cpu.addUInt32`,
  `openuikit.cpu.copyUInt8`). MSL functions cannot be compiled.
- Render encoders record state. `endEncoding` applies load/store
  (`.clear` writes `clearColor` / `clearDepth`). There is **no rasterization**.
- GPU capture (`MTLCaptureManager`) reports no supported destinations and
  `startCapture(with:)` throws `MTLCaptureError.notSupported`.
- `makeArgumentEncoder` returns an inert encoder (`encodedLength == 0`).
- `makeIndirectCommandBuffer` returns `nil`.
- Ray tracing, Metal 4 command queues, tensors, IO command queues,
  acceleration structures, and IOSurface-backed textures are not implemented.
  `MTL4RenderPassDescriptor` exists as a nominal type so MetalKit can compile
  `currentMTL4RenderPassDescriptor`; it does not encode GPU work.
- Compressed / unknown pixel formats cannot be CPU-copied; `replace`/`getBytes`
  no-op when bytes-per-pixel is unknown. `MTLPixelFormat.unspecialized` is
  omitted rather than guessing an ABI value.

## Still deferred

Most remaining identifiers are Metal 4 compiler/queue/encoder APIs, ray
tracing, sparse textures, counters, tessellation/mesh draws, residency sets,
and IO command queues. See `coverage.tsv`.

IOSurface is a declared seed dependency but is not imported; this module
compiles standalone against Foundation.

## Depth pass 2026-09

Campaign `ios26.1-fwdepth-r3`, framework `Metal`, lane `large-partitioned`.
This pass implements the object model plus a CPU reference executor for the
compute/blit subset apps use. There is no GPU.

### Public surface implemented

- Device factory: `MTLCreateSystemDefaultDevice()` /
  `MTLCopyAllDevices()` → one CPU device, name `"OpenUIKit CPU Reference"`,
  `architecture.name == "cpu"`, `hasUnifiedMemory == true`.
- Buffers: `makeBuffer(length:options:)` / `makeBuffer(bytes:length:options:)`
  / `bytesNoCopy`, real storage, `contents()`, `didModifyRange`, `length`.
- Textures: `makeTexture(descriptor:)` with descriptor validation;
  `replace`/`getBytes` for `rgba8Unorm`, `bgra8Unorm`, `r8Unorm`,
  `rgba16Float`, `rgba32Float`, `depth32Float` with exact byte layouts and
  mipmap level sizes.
- Queues / command buffers: `makeCommandQueue`, `commit`,
  `waitUntilCompleted`, `addCompletedHandler` / `addScheduledHandler`,
  status chain and timestamps as above.
- Blit (CPU-exact): buffer↔buffer, buffer↔texture, texture↔texture,
  `fill(buffer:range:value:)`, `generateMipmaps` with a box filter.
- Compute: `MTLMakeCPUBuiltinLibrary` + the three documented kernels;
  MSL compile/dispatch fail closed.
- Render: descriptor validation; encoder methods record state; load
  `.clear` fills the attachment, `.load`/`.dontCare` leave existing bytes;
  store writes through because the texture *is* the attachment storage.
- Value objects: samplers, heaps (bump allocator), fences, events,
  geometry helpers, pixel-format / resource-option semantics.

Coverage ledger repair (merge evidence form): the refused revision at
`49dd3e06` had **implemented 1636** / declared 573 / deferred 2335 /
unavailable 3, but every implemented row cited `full/metal/*.swift` rather
than a focused `test*` function.

After splitting `tests/agent/*Tests.swift` and reciting the ledger:

| Status | Before (`49dd3e06`) | After |
| --- | ---: | ---: |
| implemented | 1636 | 1991 |
| declared | 573 | 389 |
| deferred | 2335 | 2164 |
| unavailable | 3 | 3 |

Implemented rows now use `test:full/metal/tests/agent/<File>Tests.swift#testName`.
Rows without a real test are `declared` with
`source:full/metal/<file>.swift#Symbol` when the type exists in guest
sources, otherwise deferred.

Top-5 implemented evidence distribution (of 1991):

1. `MetalEnumTests.swift#testMetalEnumOptionSetAndConstantValues` — 1313 (enum / option-set / C constant table)
2. `MetalDescriptorTests.swift#testDescriptorValueSemantics` — 222
3. `MetalGeometryTests.swift#testGeometryHelpers` — 95
4. `MetalRenderTests.swift#testRenderPassClearAndLoad` — 61
5. `MetalComputeTests.swift#testCPUBuiltinCompute` — 60

No non-table test exceeds 40% of the remaining 678 implemented rows
(cap 271; largest family test is 222). Device, buffer, texture, queue,
command-buffer, blit, render-pass-clear, and descriptor families used by
the CPU executor stay nondeferred where a focused test exercises them.

### Fail-closed boundaries (depth)

- No shader compiler: `MTLLibraryError.compileFailure` + `"no shader compiler"`.
- No default / metallib libraries.
- No GPU capture destinations.
- Argument encoder inert (`encodedLength == 0`); ICB factory returns `nil`.
- `supportsFamily` always `false`; ray tracing / Metal 4 / IO / tensors /
  acceleration structures remain unimplemented.

### Tests and markers

Gate (Linux host, no docker): `bash full/metal/tests/acceptance/test_host.sh`

Expected markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
METAL_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Metal dylib=libMetal.dylib
```

Agent runtime (`tests/agent/MetalRuntime.swift`) is the sealed v1 runner: it
inlines the `test*` functions from `*Tests.swift` and prints
`METAL_AGENT_RUNTIME_OK`. Focused files cover geometry, enum/option-set
raw values, the six documented texture formats, box-filter mipgen, blit
fill/copy, builtin compute kernels, render-pass clear/load, heap/event/fence,
library compileFailure, capture fail-closed, argument encoder, and ICB `nil`.

The sealed gate does not print the Swift environment marker; that line is
produced by `.cursor/verify-cloud-environment.sh` / the Swift 6.2.4 linux
toolchain check. The host gate prints the three `FRAMEWORK_FANOUT_*` /
`METAL_AGENT_RUNTIME_OK` lines.

### Unresolved behavioral questions

See `oracle-questions.tsv`. Central review still needs Apple-oracle answers
for: default-device nil vs software adapter on devices without Metal;
`MTLGPUFamily.metal4` / `apple10` raw values; `MTLPixelFormat.unspecialized`
raw value; whether a missing AIR compiler is `.compileFailure` vs
`.unsupported` on iPhoneOS 26.1; capture `supportsDestination` with an
attached debugger; and `MTLStages` bit layout including `MTLStageAll`.
This port does not fabricate those Apple-only outcomes.
