# SceneKit Linux starting point

This directory is a clean-room Linux port of Apple's public `SceneKit` surface.
It is a **large-partitioned** seed: the useful CPU scene graph is real, and GPU,
physics simulation, and Apple asset pipelines stay fail-closed.

Isolated `tests/acceptance/test_host.sh` success is **not** integrated Linux
success. Guest CoreGraphics, QuartzCore, Metal, shared simd, and C ABI linking
are prepared for a future clean EC2 run (no local Docker).

## What is real

- C ABI math: `SCNVector3`, `SCNVector4`, `SCNMatrix4`, the `SCNVector3Zero` /
  `SCNVector4Zero` / `SCNMatrix4Identity` globals, and TBD-exported helpers live
  in `include/SceneKit/SceneKit.h` plus `SceneKitMath.c`. Swift gets
  Clang-imported identities when `CSceneKit` is on the search path; the isolated
  gate uses a layout-compatible overlay and `@_cdecl` unmangled exports.
- Scene graph: `SCNScene`, `SCNNode` hierarchy, named lookup, clone, convert
  position/vector/transform, look-at, local translate/rotate. Self and ancestor
  insertion are rejected so world transforms and enumeration cannot cycle.
- Primitive geometry (`SCNBox`, `SCNSphere`, `SCNPlane`, `SCNCylinder`, `SCNCone`,
  `SCNCapsule`, `SCNTorus`, `SCNPyramid`, `SCNTube`, `SCNFloor`, `SCNText` string
  storage) with CPU bounding boxes.
- Geometry sources/elements, materials, cameras, and lights as data. Camera
  projection-matrix clip-space convention is **not** claimed until oracle-attested.
- CPU actions (`move`, `rotate`, `scale`, `fade`, `hide`, `wait`, `sequence`,
  `group`, `repeat`). Leftover delta carries across sequence/repeat boundaries,
  `speed == 0` pauses, and `SCNTransaction.disableActions` does not complete
  explicit `SCNAction` runs. Async `runAction` waits for completion or cancel.
- `_openUIKitAdvanceScene` for hosts without a display link.
- AABB segment hit testing on node bounding boxes.
- Physics *descriptors* (`SCNPhysicsBody` mass/velocity/forces, gravity, shapes,
  joints) without a solver.
- Constraint objects as data (`SCNLookAtConstraint`, billboard, distance, IK, …).

## Fail-closed boundaries

- No Metal, OpenGL, or pixel output. `SCN_ENABLE_METAL` and `SCN_ENABLE_OPENGL`
  are `0`. `SCNView`, `SCNRenderer`, and SwiftUI `SceneView` are not shipped.
- SceneKit does **not** define `simd_quatf` / `simd_float4x4` lookalikes. Those
  APIs compile only when the shared staged `simd` module is imported.
- `SCNColorMask` cases compile; raw bit values are unattested.
- `SCNScene(named:)` returns `nil`. URL load and `write(to:)` fail with
  `SCNErrorDomain` rather than pretending to decode `.scn` / `.dae` / `.usdz`.
- Physics ray/contact/sweep tests return empty arrays. Forces are stored; they
  do not integrate a world step.
- Particle systems, audio, CA/Metal animations, JavaScript actions, and shader
  programs do not run. Named particle/audio assets return `nil`.
- GLKit vector/matrix bridges are unavailable (no GLKit on Linux).

## Coverage layers

`coverage.tsv` distinguishes:

- **Swift source implementation**: CPU scene graph, actions, primitives.
- **C ABI**: canonical header / unmangled `SCN*` exports (isolated overlay +
  EC2 `libSceneKit.dylib` that links `SceneKitMath.c`).
- **Objective-C ABI**: NSObject subclasses compile in Swift; the ObjC runtime
  and message ABI are not claimed.

`implemented` rows have focused runtime evidence in
`tests/agent/SceneKitRuntime.swift`. Compile-only surface is `declared`.
Unobserved renderer, physics-solver, and hardware behavior is `deferred` or
`unavailable`.

## Tests

- `tests/agent/SceneKitRuntime.swift` — isolated guest runtime; prints
  `SCENEKIT_AGENT_RUNTIME_OK`.
- `tests/agent/SceneKitDependencyIdentity.swift` — EC2 identity probe; prints
  `SCENEKIT_AGENT_DEPENDENCY_IDENTITY_OK`.
- `tests/agent/SceneKitCABI.c` — EC2 C client; prints `SCENEKIT_AGENT_CABI_OK`.
- `tests/agent/ec2_guest_gates.sh` — CoreGraphics / QuartzCore / Metal / simd
  identity, C-link, and symbol-inventory recipe for a future clean EC2 run.

Run `bash tests/acceptance/test_host.sh` from this directory (or
`bash full/scenekit/tests/acceptance/test_host.sh` from the repo root).
