# SceneKit Linux starting point

This directory is a clean-room Linux port of Apple's public `SceneKit` surface.
It is a **large-partitioned** seed: the useful CPU scene graph is real, and GPU,
physics simulation, and Apple asset pipelines stay fail-closed.

## What is real

- Math: `SCNVector3`, `SCNVector4`, `SCNMatrix4`, identity/translate/scale/rotate,
  multiply, invert, quaternion/euler conversion, and world-space composition.
- Scene graph: `SCNScene`, `SCNNode` hierarchy, named lookup, clone, convert
  position/vector/transform, look-at, local translate/rotate.
- Primitive geometry (`SCNBox`, `SCNSphere`, `SCNPlane`, `SCNCylinder`, `SCNCone`,
  `SCNCapsule`, `SCNTorus`, `SCNPyramid`, `SCNTube`, `SCNFloor`, `SCNText` string
  storage) with CPU bounding boxes.
- Geometry sources/elements, materials, cameras (perspective/orthographic
  projection matrices), and lights as data.
- CPU actions (`move`, `rotate`, `scale`, `fade`, `hide`, `sequence`, `group`)
  plus `_openUIKitAdvanceScene` for hosts without a display link.
- Instant actions and `SCNTransaction.disableActions`.
- AABB segment hit testing on node bounding boxes.
- Physics *descriptors* (`SCNPhysicsBody` mass/velocity/forces, gravity, shapes,
  joints) without a solver.
- Constraint objects as data (`SCNLookAtConstraint`, billboard, distance, IK, …).

## Fail-closed boundaries

- No Metal, OpenGL, or pixel output. `SCN_ENABLE_METAL` and `SCN_ENABLE_OPENGL`
  are `0`. `SCNView`, `SCNRenderer`, and SwiftUI `SceneView` are not shipped.
- `SCNScene(named:)` returns `nil`. URL load and `write(to:)` fail with
  `SCNErrorDomain` rather than pretending to decode `.scn` / `.dae` / `.usdz`.
- Physics ray/contact/sweep tests return empty arrays. Forces are stored; they
  do not integrate a world step.
- Particle systems, audio, CA/Metal animations, JavaScript actions, and shader
  programs do not run. Named particle/audio assets return `nil`.
- GLKit vector/matrix bridges are unavailable (no GLKit on Linux).

## Tests

`tests/agent/SceneKitRuntime.swift` exercises math, hierarchy, primitives,
materials, camera projection, actions, fail-closed I/O, and empty physics queries.
It prints `SCENEKIT_AGENT_RUNTIME_OK`.

Run `bash tests/acceptance/test_host.sh` from this directory (or
`bash full/scenekit/tests/acceptance/test_host.sh` from the repo root).
