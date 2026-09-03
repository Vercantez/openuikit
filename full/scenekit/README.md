# SceneKit for Linux

This directory is a clean-room starting implementation of Apple's public
`SceneKit` module. Isolated host compilation produces `libSceneKit.dylib`
without CoreGraphics, QuartzCore, Metal, or the Darwin `simd` module.

The platform branch `cursor/port-scenekit-to-linux-c917` (legacy PR #28) could
not be fetched (private repository, 404). This lane is reconstructed from the
monorepo seed, `FANOUT_TASK.md`, and the in-repo PR #28 repair brief: keep the
CPU scene graph, math, primitives, and action scaffold; fail-close renderer and
physics; do not claim unoracle'd color-mask bits or projection conventions.

**Reference dossier:** kept the monorepo `full/scenekit/reference/` (generator
SHA `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`). The
platform branch `reference/` could not be compared (`unavailable`).

## What is real (this isolated compile)

- `SCNVector3` / `SCNVector4` / `SCNMatrix4` and the C-shaped helpers that do
  not require GLKit (`Make`, `Equal`, `Identity`, translate/scale/rotate,
  multiply, invert)
- Scene graph: add/insert/replace/remove, self/ancestor insertion rejected,
  enumeration snapshots so world transforms cannot recurse forever, convert
  position/vector/transform, clone
- CPU action clock: leftover delta across sequence/repeat, `speed == 0` pauses,
  `SCNTransaction.disableActions` does not complete explicit `SCNAction`s
  immediately, keyed cancel, large deltas
- Primitive parameter objects (`SCNBox`, `SCNSphere`, `SCNPlane`, …) with CPU
  bounding boxes
- Camera/light/material property storage (no shading)
- Physics types as fail-closed bookkeeping: `SCNPhysicsWorld.step()` does not
  invent motion

`linux_advanceTime` on `SCNNode` / `SCNScene` is a Linux CPU clock, not an
Apple API.

## Fail-closed / deferred

- No GPU renderer, `SCNView`, SwiftUI `SceneView`, Metal programs, or snapshots
- No scene-file / USD / DAE loader (`SCNScene(named:)` is nil; URL init throws)
- Physics contacts, vehicles, and fields do not simulate
- Particle emission does not run
- Audio does not play
- `simd_*` / GLKit conversion APIs are compiled only when those modules exist
- `SCNColorMask` bits are Linux placeholders pending an Apple-oracle probe
- Projection-matrix convention is Linux-local, not claimed Apple-identical

Do not treat this isolated host run as an integrated Linux product proof.
`tests/agent/SceneKitDependencyIdentity.swift` and `tests/agent/SceneKitCABI.c`
are prepared for a future EC2 run with real guest Foundation, CoreGraphics,
QuartzCore, Metal, shared simd, and unmangled `SCN*` exports.
