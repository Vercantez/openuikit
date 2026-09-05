# MetalKit for Linux

This directory is a clean-room starting implementation of Apple's public
`MetalKit` module. Isolated host compilation produces `libMetalKit.dylib`
from toolchain Foundation plus module-local lookalikes. That is not an
integrated Linux GPU product and it is not Apple behavioral parity.

## Source of the starting point

The **newer** dossier kept here is the monorepo `full/metalkit/reference/`
seed (schema v1, generator `scripts/framework-fanout/generate_seed.py`,
Xcode 26.1 / iPhoneOS 26.1, 124 precise IDs, floor 62).

Product sources do **not** `import` Metal, UIKit, CoreGraphics, QuartzCore,
or ModelIO. Those modules are absent from the isolated `swiftc` host gate.
Dependency-owned names used in MetalKit signatures (`MTLDevice`, `UIView`,
`CGImage`, `MDLMesh`, `CAMetalDrawable`, …) are lookalikes in
`MetalKitLinuxSupport.swift` and `MetalKitModelIOTypes.swift`. The later
integration build wires the real module graph.

## What is real (this isolated compile)

- `MTKModelError` and `MTKTextureLoader.{Error,Option,Origin,CubeLayout}`
  string newtypes, including domain/key/option raw values matching the ObjC
  export names. Apple string payloads remain unobserved beyond those names.
- `MTKView` as a lookalike-`UIView` subclass with a software drawable path:
  stored view state, `draw()` / delegate callbacks, `drawableSize` change
  notification, CPU `CAMetalDrawable` / `MTLRenderPassDescriptor`,
  fail-closed `currentMTL4RenderPassDescriptor` (`nil`).
- `MTKTextureLoader` construction, option plumbing, and fail-closed decode:
  data/URL/CGImage/name/MDLTexture loaders throw `NSError` in
  `MTKTextureLoaderErrorDomain`. Async overloads hop once onto
  `MetalKit.MTKTextureLoader.completion`. The NSErrorPointer-style URL array
  API returns `[]` and writes the same error.
- Vertex-format conversion using the public ModelIO bit layout and Metal
  `MTLVertexFormat` raw values (`MTKMetalVertexFormatFromModelIO` and the
  reverse). Unknown raw values and `uchar4Normalized_bgra` (no ModelIO
  counterpart) map to `.invalid`. Descriptor conversion copies
  attribute format/offset/bufferIndex and layout stride.
- `MTKMeshBufferAllocator` allocates software `MTLBuffer`s.
  `MTKMesh.init(mesh:device:)` copies MDL vertex/index bytes, maps
  `MDLGeometryType` points/lines/triangles/triangleStrips onto
  `MTLPrimitiveType`, and maps `UInt16`/`UInt32` index depths. Quads,
  variable topology, and `UInt8` indices throw `NSError` in
  `MTKModelErrorDomain`. `MTKMesh.newMeshes(asset:device:)` converts each
  mesh in the asset.

## Fail-closed / deferred

- Lookalike `MTL*` / `UIView` / `CGImage` / `MDL*` types are not the Metal,
  UIKit, CoreGraphics, or ModelIO modules. They exist so the isolated host
  gate can compile.
- No ImageIO module in this isolated configuration, so no PNG/JPEG/KTX GPU
  upload. Texture APIs exist and fail closed, including `MDLTexture`.
- No Apple GPU, CAMetalLayer display present, or Metal 4 encoder.
- MSAA resolve textures stay `nil` even when `sampleCount > 1`.
- `MTKModelError` / `MTKTextureLoaderError` numeric codes are `0` until an
  Apple oracle records Darwin payloads.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Implemented before: **91**. Implemented after: **124**. Declared: 0.
Deferred: **0** (was 33 ModelIO mesh/conversion/MDLTexture rows).

The 20-app corpus (`reference/corpus-summary.json`) exercises MetalKit in
Signal (video / spoiler particle views) and Telegram (sticker, camera,
drawing, call-screen layers). That surface is `MTKView` /
`MTKViewDelegate` / `MTKTextureLoader`. This pass kept those families
implemented with focused tests and raised the remaining ModelIO mesh and
vertex-descriptor identifiers to implemented software behavior rather than
leaving them deferred.

Top-5 evidence distribution (implemented rows citing each test):

| test | rows |
| --- | --- |
| `testTextureLoaderOptionConstants` | 9 |
| `testSubmeshPropertiesFromConvertedMesh` | 8 |
| `testMeshBufferFromAllocator` | 7 |
| `testMeshInitCopiesVertexAndIndexBuffers` | 6 |
| `testViewDefaultFlags` | 6 |

No non-constant test exceeds 40% of implemented rows. Option/origin/error
C constants share table-driven value tests as allowed.
