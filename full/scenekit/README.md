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

- `SCNVector3` / `SCNVector4` / `SCNMatrix4` / `SCNQuaternion` and the C-shaped
  helpers that do not require GLKit (`Make`, `Equal`, `Identity`,
  translate/scale/rotate, multiply, invert), plus `SIMD3`/`SIMD4` bridging
- Scene graph: add/insert/replace/remove, self/ancestor insertion rejected,
  enumeration snapshots so world transforms cannot recurse forever, convert
  position/vector/transform, clone and flattenedClone
- Node TRS coupling: `position` is parent-space translation independent of
  `rotation`/`orientation`/`eulerAngles` (Linux XYZ Tait-Bryan) and `scale`/`pivot`
- CPU constraints applied after actions each `linux_advanceTime` tick:
  LookAt, Distance, Billboard, Transform
- CPU action clock: leftover delta across sequence/repeat, `speed == 0` pauses,
  timing modes linear/easeIn/easeOut/easeInEaseOut, group, fade, hide, run,
  `SCNTransaction.disableActions` does not complete explicit `SCNAction`s
  immediately, keyed cancel, large deltas
- Primitive meshes (`SCNBox`, `SCNSphere`, `SCNPlane`, cylinder/cone/capsule/
  torus/tube/pyramid/floor) with vertices/normals/UVs and documented default
  segment counts; `SCNGeometrySource`/`SCNGeometryElement` from raw data
- Materials: contents, lighting models, blend/transparency/doubleSided
- Camera projection math: `projectionTransform(withViewportSize:)` for
  perspective and orthographic (Linux OpenGL-style)
- `SCNRenderer`/`SCNView`: CPU rasterizer (constant/lambert/blinn/phong,
  depth test) into `SCNCPUImage`; `SCNView` is an `NSObject` port that stores
  `scene` / `pointOfView` / `allowsCameraControl` (not a UIKit `UIView`)
- Physics types as fail-closed bookkeeping: `SCNPhysicsWorld.step()` does not
  invent motion

`linux_advanceTime` on `SCNNode` / `SCNScene` is a Linux CPU clock, not an
Apple API.

## Fail-closed / deferred

- No GPU/Metal/EAGL renderer, SwiftUI `SceneView`, or `UIImage` snapshots
- No scene-file / USD / DAE loader (`SCNScene(named:)` is nil; URL init throws;
  `.scn` NSSecureCoding archive is not decoded)
- Physics contacts, vehicles, and fields do not simulate
- Particle emission does not run
- Audio does not play (`SCNAudioSource` stores properties only)
- Darwin `simd_float4x4` / `simd_quatf` / GLKit conversion APIs compile only
  when those modules exist
- Implicit CoreAnimation of animatable properties is not wired to QuartzCore
  (`SCNTransaction.animationDuration` is stored; `CAAnimation` bridging is
  deferred)
- `SCNColorMask` bits are Linux placeholders pending an Apple-oracle probe
- Projection-matrix convention is Linux-local, not claimed Apple-identical
- `SCNText` / `SCNShape` tessellation is declared (string/path stored, no glyphs)

Do not treat this isolated host run as an integrated Linux product proof.
`tests/agent/SceneKitDependencyIdentity.swift` and `tests/agent/SceneKitCABI.c`
are prepared for a future EC2 run with real guest Foundation, CoreGraphics,
QuartzCore, Metal, shared simd, and unmangled `SCN*` exports.

## Depth pass 2026-09

SDK depth for `SceneKit` in `full/scenekit/` (2611 IDs). Wave-1 starting point
was 329 implemented / 1329 declared / 953 deferred. This pass implements the
scene graph and math exactly on the CPU and a software rasterizer for basic
materials. Coverage after the pass: **1687 implemented / 32 declared / 892
deferred**.

**Public surface implemented (Linux CPU):**

- Math: `SCNVector3`/`SCNVector4`/`SCNMatrix4`/`SCNQuaternion`, every
  `SCNMatrix4*`/`SCNVector3*` helper, `SIMD3`/`SIMD4` bridging. `SCNMatrix4Mult(A,B)`
  is `A*B`; row-vector `p' = p * M` so Mult applies A then B. Node compose is
  pivot⁻¹ · S · R · T.
- `SCNNode` hierarchy, name lookup, TRS coupling, worldTransform/convert*,
  CPU `hitTestWithSegment` with documented options, boundingBox/boundingSphere,
  clone/flattenedClone, constraints in stored order per frame.
- `SCNGeometry` primitives with vertex layouts and default segment counts;
  raw `SCNGeometrySource`/`Element`; materials array; `subdivisionLevel` stored.
- `SCNMaterial` properties/contents/lighting models/blend/transparency/doubleSided.
- `SCNLight`/`SCNCamera` value semantics; camera projection exact for the Linux
  OpenGL-style helper (perspective and orthographic).
- `SCNScene` rootNode/background; load of `.scn`/`.dae`/`.usdz` fail-closed.
- `SCNAction` move/rotate/scale/fade/sequence/group/repeat/wait/run with timing
  modes and quadratic easing on the injectable `linux_advanceTime` clock.
- `SCNTransaction` begin/commit/animationDuration/completionBlock.
- `SCNAnimation`/`SCNAnimatable` players and keys (no implicit CA property
  animation).
- `SCNRenderer`/`SCNView` CPU rasterizer into `SCNCPUImage`; view stores
  pointOfView/allowsCameraControl.
- `SCNPhysicsBody`/`SCNPhysicsWorld` declared/bookkeeping only (no gravity
  integration — Apple solver unobserved).
- `SCNHitTestResult` CPU; `SCNAudioSource` fail-closed playback.

**Fail-closed boundaries:** scene archives, Metal/EAGL/GPU, SwiftUI SceneView
(~809 IDs), `UIImage` snapshot, `simd_float4x4`/`simd_quatf`, GLKit, CAAnimation
implicit animation, physics contacts, audio playback, text/shape tessellation.

**Tests:** `bash full/scenekit/tests/acceptance/test_host.sh` (this Linux host,
no docker). Runtime pixel-tests a constant-red lit cube against the CPU
rasterizer and exercises math, node coupling, geometry layouts, camera
projection, easing, SCNView stores, and hit tests.

**Environment:** Swift 6.2.4, `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` failed in this snapshot (missing
`scratch/ladder-corpus/focus-ios`); the sealed host gate only requires `swiftc`.

**Unresolved for central review:** see `oracle-questions.tsv` (color-mask bits,
projection NDC, Mult associativity vs Darwin, euler convention vs Apple,
implicit CA animation, sceneNamed search, physics solver, C ABI exports,
constraint order vs Apple, `.scn` NSSecureCoding layout).
