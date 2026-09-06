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
  on `commit()`, with `error == nil` when only CPU blit / builtin compute /
  render load-store ran. GPU/kernel timestamps come from
  `ProcessInfo.processInfo.systemUptime`. Dispatch without a CPU-builtin
  pipeline completes with `status == .error` and `MTLCommandBufferError.notPermitted`.
- Sampler, heap, fence, event, and **shared-event** objects store configuration
  and host-clock signaling. Listeners fire on the signaling thread.
- Argument encoders write 16-byte slots into a bound `MTLBuffer`.
  Indirect command buffers store compute/render commands as CPU data;
  compute `executeCommandsInBuffer` runs CPU-builtin kernels.
- Parallel render encoders create child render encoders that apply the same
  CPU load/store path. Resource-state encoders signal CPU fences and
  fail closed for sparse mapping.
- Buffer-backed textures honor `bytesPerRow` on `replace`/`getBytes`.

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
- Compute dispatch without a CPU-builtin pipeline, and render pipelines
  that name MSL vertex/fragment functions, fail closed (`MTLCommandBufferError.notPermitted`
  at commit, or `MTLLibraryError.compileFailure` at pipeline creation).
- Sparse texture mapping on a resource-state encoder fails closed with
  `MTLCommandBufferError.notPermitted` (this CPU device is not sparse).
- Shared-event listeners fire on the signaling thread, not the listener
  dispatch queue (no run loop).
- Ray tracing, tensors, and IOSurface-backed textures are not implemented.
  Metal 4 command queues exist as a CPU command stream: copies and mipgen run
  on commit; draws/dispatches fail closed. IO command queues exist but `load*`
  fails closed. Acceleration structures are zero-size resources (no BLAS/TLAS).
- Compressed / unknown pixel formats cannot be CPU-copied; `replace`/`getBytes`
  no-op when bytes-per-pixel is unknown. `MTLPixelFormat.unspecialized` is
  omitted rather than guessing an ABI value.

## Still deferred

Most remaining identifiers are Metal 4 machine-learning encoders, GPU
tessellation/mesh rasterization, sparse page mapping, residency sets, tensors,
and Apple IO command processors. See `coverage.tsv`.

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
- `supportsFamily` always `false`; ray tracing / Metal 4 / IO / tensors /
  acceleration structures remain unimplemented.
- Compute dispatch without a CPU-builtin pipeline: `MTLCommandBufferError.notPermitted`.
- Render pipeline with MSL functions: `MTLLibraryError.compileFailure`.

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
library compileFailure, capture fail-closed, argument-encoder buffer writes,
shared events, texture views (2D/array/cube/3D), ICB data + CPU-builtin
execute, compute dispatch fail-closed, parallel render encoders, resource-state
fences, and fail-closed sparse mapping.

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
attached debugger; `MTLStages` bit layout including `MTLStageAll`;
argument-buffer slot stride; ICB execute semantics; shared-event listener
queues; texture-view format compatibility; parallel-encoder load ordering;
and the Apple error for sparse mapping on a non-sparse device.
This port does not fabricate those Apple-only outcomes.

## Depth pass 2026-09 (wave 8)

Campaign `ios26.1-fwdepth-r15`, framework `Metal`, lane `large-partitioned`.
Second pass on the existing CPU reference: keep the first-pass tests green,
then add host-clock shared events, ICB/argument-encoder data, texture views
with compatible formats, 2DArray/cube/3D byte-exact layouts, pipeline
validation, fail-closed shader dispatch at commit, a parallel render encoder
with CPU load/store, resource-state fences, fail-closed sparse mapping, and
buffer-backed textures that honor `bytesPerRow`.

| Status | Before (first pass in tree) | After |
| --- | ---: | ---: |
| implemented | 1991 | 2128 |
| declared | 389 | 312 |
| deferred | 2164 | 2104 |
| unavailable | 3 | 3 |

Implemented gain: **+137**. Evidence is `test:full/metal/tests/agent/<File>Tests.swift#testName`
naming a real synchronous `test*` function.

Top-5 implemented evidence distribution (of 2128):

1. `MetalEnumTests.swift#testMetalEnumOptionSetAndConstantValues` — 1319 (enum / option-set / C constant table)
2. `MetalDescriptorTests.swift#testDescriptorValueSemantics` — 224
3. `MetalGeometryTests.swift#testGeometryHelpers` — 106
4. `MetalRenderTests.swift#testRenderPassClearAndLoad` — 60
5. `MetalComputeTests.swift#testCPUBuiltinCompute` — 60

No non-table test exceeds 40% of the remaining 809 implemented rows
(cap 323; largest family test is 224). New focused tests:
`testSharedEventHostClock`, `testIndirectCommandBufferAsData`,
`testTextureViewsAndDimensionalLayouts`, `testPipelineDescriptorValidation`,
`testComputeDispatchFailClosed`, `testParallelRenderEncoderAndSamplerState`,
`testResourceStateEncoder`.

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 /
linux and the sealed gate compiles with a clean product tree (`products=clean`).

## Depth pass 2026-09 (wave 8)

Campaign `ios26.1-fwdepth-r16`, framework `Metal`, lane `large-partitioned`.
Third pass on the existing CPU reference: keep prior tests green, then add a
software mesh/tile pipeline descriptor surface, acceleration-structure
instance value types (no BLAS/TLAS), render-encoder mesh/object/tile
bindings and Swift array overlays, host-clock `sampleTimestamps`, sparse
tile size 0, and fail-closed mesh/tile pipeline creation.

| Status | Before (wave-8 r15 in tree) | After |
| --- | ---: | ---: |
| implemented | 2128 | 2658 |
| declared | 312 | 275 |
| deferred | 2104 | 1611 |
| unavailable | 3 | 3 |
| not-applicable | 0 | 0 |

Implemented gain: **+530**. Evidence is `test:full/metal/tests/agent/<File>Tests.swift#testName`
naming a real synchronous `test*` function. MetalRuntime.swift now *calls*
every `test*` function before printing `METAL_AGENT_RUNTIME_OK`.

Top-5 implemented evidence distribution (of 2658):

1. `MetalEnumTests.swift#testMetalEnumOptionSetAndConstantValues` — 1633 (enum / option-set / C constant table)
2. `MetalDescriptorTests.swift#testDescriptorValueSemantics` — 224
3. `MetalGeometryTests.swift#testGeometryHelpers` — 106
4. `MetalGeometryTests.swift#testAccelerationStructureDescriptors` — 66
5. `MetalRenderTests.swift#testRenderEncoderStageBindings` — 65

No non-table test exceeds 40% of the remaining 1025 implemented rows
(cap 410; largest family test is 224). New focused tests:
`testMeshAndTilePipelineDescriptors`, `testAccelerationStructureDescriptors`,
`testRenderEncoderStageBindings`, `testDeviceFactoryAndFailClosed`.

Fail-closed this pass: mesh/tile `makeRenderPipelineState` throws
`MTLLibraryError.compileFailure` + `"no shader compiler"`; `makeLibrary(data:)`
throws `.fileNotFound`; `accelerationStructureSizes` and `sparseTileSize`
return zeros (no RT/sparse GPU). Metal 4 command encoders remain deferred.

## Depth pass 2026-09 (wave 8)

Campaign `ios26.1-fwdepth-r17`, framework `Metal`, lane `large-partitioned`.
Fourth pass on the existing CPU reference: keep prior tests green, then add a
software Metal 4 command stream (CPU buffer/texture copies and box-filter
mipgen, fail-closed shader dispatch), Metal 4 pipeline/function descriptors,
IO command buffers that fail closed at load, a host-clock timestamp counter
heap, curve/motion-curve/indirect-instance acceleration descriptors, and
`MTLArgument` reflection value objects.

| Status | Before (wave-8 r16 in tree) | After |
| --- | ---: | ---: |
| implemented | 2658 | 3448 |
| declared | 275 | 249 |
| deferred | 1611 | 847 |
| unavailable | 3 | 3 |
| not-applicable | 0 | 0 |

Implemented gain: **+790**. Evidence is `test:full/metal/tests/agent/<File>Tests.swift#testName`
naming a real synchronous `test*` function.

Top-5 implemented evidence distribution (of 3448):

1. `MetalEnumTests.swift#testMetalEnumOptionSetAndConstantValues` — 1908 (enum / option-set / C constant table)
2. `MetalDescriptorTests.swift#testDescriptorValueSemantics` — 222
3. `MetalCommandTests.swift#testMetal4CommandEncoders` — 202
4. `MetalDescriptorTests.swift#testMetal4PipelineDescriptors` — 190
5. `MetalGeometryTests.swift#testGeometryHelpers` — 106

No non-table test exceeds 40% of the remaining 1540 implemented rows
(cap 616; largest family test is 222). New focused tests:
`testMetal4CommandEncoders`, `testMetal4PipelineDescriptors`,
`testAccelerationStructureGeometryDescriptors`, `testDeviceFailClosedFactories`,
`testIOCommandBufferFailClosed`, `testRenderPipelineStateMeshProperties`.

Fail-closed this pass: Metal 4 compiler/dynamic-library/binary-function APIs
throw `MTLLibraryError.compileFailure` + `"no shader compiler"`; Metal 4
draws/dispatches complete with `MTL4CommandQueueError.notPermitted`; IO
`load*` commits with `MTLIOError.internal`; `makeIOFileHandle` / `makeArchive`
throw; pipeline-data-set serialize throws `"no GPU pipeline cache"`.
GPU families, AIR execution, and Apple IO command processors remain absent.

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 /
linux and the sealed gate compiles with a clean product tree (`products=clean`).

