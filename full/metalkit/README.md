# MetalKit for Linux

This directory is a clean-room starting implementation of Apple's public
`MetalKit` module. Isolated host compilation produces `libMetalKit.dylib`.
That is not an integrated Linux GPU product and it is not Apple behavioral
parity.

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

Metal's promotion (`full/metal`, platform PR #55) had not merged when this
lane was built. Metal was **not** vendored into `full/metalkit/`. The isolated
host compile on this VM uses a local fail-closed software Metal module plus
minimal UIKit `UIView` / CoreGraphics `CGImage` modules installed only on the
VM module path.

## What is real (this isolated compile)

- `MTKModelError` and `MTKTextureLoader.{Error,Option,Origin,CubeLayout}`
  string newtypes, including domain/key/option raw values matching the ObjC
  export names. Apple string payloads remain unobserved beyond those names.
- `MTKView` as a `UIView` subclass with a software drawable path: stored
  view state, `draw()` / delegate callbacks, `drawableSize` change
  notification, CPU `CAMetalDrawable` / `MTLRenderPassDescriptor` from the
  software Metal device, fail-closed `currentMTL4RenderPassDescriptor` (`nil`).
- `MTKTextureLoader` construction, option plumbing, and fail-closed decode:
  data/URL/CGImage/name loaders throw `NSError` in
  `MTKTextureLoaderErrorDomain`. Async overloads hop once onto
  `MetalKit.MTKTextureLoader.completion`. The NSErrorPointer-style URL array
  API returns `[]` and writes the same error.

## Fail-closed / deferred

- No ImageIO import in this isolated configuration, so no PNG/JPEG/KTX GPU
  upload. Texture APIs exist and fail closed.
- ModelIO is not on main. Vertex-descriptor conversions, `MTKMesh`,
  `MTKMeshBuffer`, `MTKSubmesh`, `MTKMeshBufferAllocator`, and MDLTexture
  loaders are omitted and marked `deferred`.
- No Apple GPU, CAMetalLayer display present, or Metal 4 encoder.
- MSAA resolve textures stay `nil` even when `sampleCount > 1`.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
