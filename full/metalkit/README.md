# MetalKit for Linux

This directory is a clean-room starting implementation of Apple's public
`MetalKit` module. Isolated host compilation produces `libMetalKit.dylib`
from toolchain Foundation plus module-local lookalikes. That is not an
integrated Linux GPU product and it is not Apple behavioral parity.

## Source of the starting point

The legacy platform fan-out PR #40 (`cursor/port-metalkit-to-linux-3115` on
`openuikit-linux-platform`) was the intended content source (about 1,281 Swift
lines, 43 nondeferred coverage rows — the TBD-export count). This environment
cannot fetch that private repository, so this lane was rewritten against the
pinned `reference/` dossier already on monorepo main.

The **newer** dossier kept here is the monorepo `full/metalkit/reference/`
seed (schema v1, generator `scripts/framework-fanout/generate_seed.py`,
Xcode 26.1 / iPhoneOS 26.1, 124 precise IDs, floor 62). Platform PR #40's
older `reference/` was not copied.

Product sources do **not** `import` Metal, UIKit, CoreGraphics, QuartzCore,
or ModelIO. Those modules are absent from the isolated `swiftc` host gate.
Dependency-owned names used in MetalKit signatures (`MTLDevice`, `UIView`,
`CGImage`, `CAMetalDrawable`, …) are lookalikes in
`MetalKitLinuxSupport.swift`. The later integration build wires the real
module graph.

## What is real (this isolated compile)

- `MTKModelError` and `MTKTextureLoader.{Error,Option,Origin,CubeLayout}`
  string newtypes, including domain/key/option raw values matching the ObjC
  export names. Apple string payloads remain unobserved beyond those names.
- `MTKView` as a lookalike-`UIView` subclass with a software drawable path:
  stored view state, `draw()` / delegate callbacks, `drawableSize` change
  notification, CPU `CAMetalDrawable` / `MTLRenderPassDescriptor`,
  fail-closed `currentMTL4RenderPassDescriptor` (`nil`).
- `MTKTextureLoader` construction, option plumbing, and fail-closed decode:
  data/URL/CGImage/name loaders throw `NSError` in
  `MTKTextureLoaderErrorDomain`. Async overloads hop once onto
  `MetalKit.MTKTextureLoader.completion`. The NSErrorPointer-style URL array
  API returns `[]` and writes the same error.

## Fail-closed / deferred

- Lookalike `MTL*` / `UIView` / `CGImage` types are not the Metal, UIKit, or
  CoreGraphics modules. They exist so the isolated host gate can compile.
- No ImageIO module in this isolated configuration, so no PNG/JPEG/KTX GPU
  upload. Texture APIs exist and fail closed.
- ModelIO is not on main. Vertex-descriptor conversions, `MTKMesh`,
  `MTKMeshBuffer`, `MTKSubmesh`, `MTKMeshBufferAllocator`, and MDLTexture
  loaders are omitted and marked `deferred`.
- No Apple GPU, CAMetalLayer display present, or Metal 4 encoder.
- MSAA resolve textures stay `nil` even when `sampleCount > 1`.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
