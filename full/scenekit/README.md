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
was 329 implemented / 1329 declared / 953 deferred. The CPU scene-graph pass
then marked **1687 implemented / 32 declared / 892 deferred**, but every
implemented row cited the file path `full/scenekit/tests/agent/SceneKitRuntime.swift`
(not `test:full/scenekit/tests/agent/<File>Tests.swift#testName`). Central
`FW_MERGE` refused that ledger.

This repair splits the runtime into focused `*Tests.swift` functions and
rewrites the ledger. Coverage after the evidence pass: **1369 implemented /
350 declared / 892 deferred**. Rows without a real focused test were
reclassified to `declared` with `source:full/scenekit/<file>.swift#Symbol`.
Deferred stays 892.

**Top-5 implemented evidence (of 1369):**

| citations | evidence |
| ---: | --- |
| 565 | `test:full/scenekit/tests/agent/SceneKitEnumTests.swift#testEnumOptionSetAndConstantValues` |
| 101 | `test:full/scenekit/tests/agent/SceneKitMathTests.swift#testVectorMath` |
| 67 | `test:full/scenekit/tests/agent/SceneKitPhysicsTests.swift#testPhysicsBookkeeping` |
| 62 | `test:full/scenekit/tests/agent/SceneKitGeometryTests.swift#testPrimitiveLayouts` |
| 56 | `test:full/scenekit/tests/agent/SceneKitNodeTests.swift#testNodeTransforms` |

The enum/option-set/C-constant table is the allowed shared value test (565).
Of the remaining 804 implemented rows, the largest non-enum citation is
`testVectorMath` at 101 (12.6%, under the 40% bulk-relabel ceiling).

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
no docker). Focused `func test*()` checks live in `tests/agent/*Tests.swift`;
`SceneKitRuntime.swift` concatenates them so the v1 gate still compiles one
file, pixel-tests a constant-red cube, and prints `SCENEKIT_AGENT_RUNTIME_OK`.

**Environment:** Swift 6.2.4, `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` failed in this snapshot (missing
`scratch/ladder-corpus/focus-ios`); the sealed host gate only requires `swiftc`.

**Unresolved for central review:** see `oracle-questions.tsv` (color-mask bits,
projection NDC, Mult associativity vs Darwin, euler convention vs Apple,
implicit CA animation, sceneNamed search, physics solver, C ABI exports,
constraint order vs Apple, `.scn` NSSecureCoding layout).

## Depth pass 2026-09 (wave 8)

SDK depth for `SceneKit` in `full/scenekit/` (2611 IDs). This is a second
behaviour pass on the first-pass tree (1369 implemented / 350 declared /
892 deferred / 0 unavailable / 0 not-applicable). It keeps the existing
focused tests green and adds real graph/physics/action evaluation.

**Coverage after wave 8:** **1455 implemented / 274 declared / 73 deferred /
0 unavailable / 809 not-applicable**.

Implemented gain vs the previous ledger: **+86**. SwiftUI `SceneView` /
`s:7SwiftUI4View…` / `_SceneKit_SwiftUI` overlay re-exports (809) moved from
`deferred` to `not-applicable` with note `SwiftUI cross-import overlay;
owned by the SwiftUI lane`. Remaining deferred are Metal, GLKit, Darwin
`simd_float4x4`/`simd_quatf`, UIKit/CoreImage, AVAudio, and UIImage snapshot.

**Top-5 implemented evidence (of 1455):**

| citations | evidence |
| ---: | --- |
| 581 | `test:full/scenekit/tests/agent/SceneKitEnumTests.swift#testEnumOptionSetAndConstantValues` |
| 94 | `test:full/scenekit/tests/agent/SceneKitMathTests.swift#testVectorMath` |
| 62 | `test:full/scenekit/tests/agent/SceneKitGeometryTests.swift#testPrimitiveLayouts` |
| 61 | `test:full/scenekit/tests/agent/SceneKitPhysicsTests.swift#testPhysicsBookkeeping` |
| 56 | `test:full/scenekit/tests/agent/SceneKitNodeTests.swift#testNodeTransforms` |

The enum/option-set/C-constant table is the allowed shared value test (581).
Of the remaining 874 implemented rows, the largest non-enum citation is
`testVectorMath` at 94 (10.8%, under the 40% bulk-relabel ceiling).

**Behaviour added in this pass:**

- `SCNPhysicsWorld` fixed-`timeStep` semi-implicit Euler; gravity; linear
  damping; `applyForce`/`applyTorque` (force and impulse); sphere/sphere,
  box AABB, and sphere-AABB contacts with positional correction and restitution
  impulse; `SCNPhysicsContactDelegate` begin/update/end; `contactTest` /
  `contactTestBetween`; `rayTestWithSegment` via the CPU segment tester.
  `convexSweepTest` stays fail-closed (no GJK).
- `SCNReplicatorConstraint` position/orientation/scale math.
- `isHidden` / `opacity` / `categoryBitMask` ancestor propagation
  (`linux_worldHidden`, `linux_worldOpacity`, `linux_worldCategoryBitMask`)
  used by hit-test and the CPU rasterizer.
- `SCNTransaction.flush` zeros `animationDuration` and runs the completion
  block.
- `SCNSceneSource.property(forKey:)` returns filesystem dates when a URL
  exists; `.scn` decode remains fail-closed.
- `SCNAnimation`/`CAAnimation` data bridging (Linux stand-in, not
  CoreAnimation playback).
- Primitive vertex-count rules (box 36, plane 6, sphere 24×48×6, cylinder
  288, cone 144, torus 24×24×6, pyramid 18) and `SCNText` box fallback
  sized by character count (not glyph tessellation).
- `SCNAction.customAction` samples elapsed `t`; `rotateBy` applies Euler
  deltas; `reversed()` inverts `moveBy`.
- Camera projection `m33`/`m43` checked against the hand-computed OpenGL
  formula for `zNear=1`, `zFar=100`.
- Screen `hitTest` with no scene returns `[]` (GPU/UIImage snapshot still
  deferred).

**Fail-closed:** Metal/EAGL/GPU render and snapshot, `.scn`/USD/DAE decode,
convex sweep, particle emission, audio playback, SwiftUI `SceneView`,
Darwin `simd_float4x4`/`simd_quatf`, GLKit.

**Tests:** `bash full/scenekit/tests/acceptance/test_host.sh`. Every cited
`func test*()` is synchronous and lives in `tests/agent/*Tests.swift`;
`SceneKitRuntime.swift` concatenates them for the sealed one-file guest
runtime.

**Environment:** Swift 6.2.4, `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` still fails in this snapshot
(missing `scratch/ladder-corpus/focus-ios`). The sealed host gate only
requires `swiftc`. Active Cursor Build on this VM was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign listed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). HEAD at start was
`bff8535c68425cc39fb45cb00d447b0981b57242`.

## Depth pass 2026-09 (wave 9)

SDK depth for `SceneKit` in `full/scenekit/` (2611 IDs). This is a next
behaviour pass on the wave-8 tree. It keeps the first-pass and wave-8 tests
green and adds CPU particle emission, camera-controller math, physics fields,
and vehicle/slider motors.

**Coverage before this pass:** **1455 implemented / 274 declared / 73 deferred /
0 unavailable / 809 not-applicable**.

**Coverage after this pass:** **1728 implemented / 0 declared / 74 deferred /
0 unavailable / 809 not-applicable**.

Implemented gain vs wave 8: **+273**. `present(_:with:incomingPointOfView:)`
moved from `declared` to `deferred` (SpriteKit `SKTransition` + async present
cannot be exercised on the sealed synchronous gate). No `unavailable` rows.

**Top-5 implemented evidence (of 1728):**

| citations | evidence |
| ---: | --- |
| 582 | `test:full/scenekit/tests/agent/SceneKitEnumTests.swift#testEnumOptionSetAndConstantValues` |
| 101 | `test:full/scenekit/tests/agent/SceneKitMathTests.swift#testVectorMath` |
| 62 | `test:full/scenekit/tests/agent/SceneKitGeometryTests.swift#testPrimitiveLayouts` |
| 61 | `test:full/scenekit/tests/agent/SceneKitPhysicsTests.swift#testPhysicsBookkeeping` |
| 56 | `test:full/scenekit/tests/agent/SceneKitNodeTests.swift#testNodeTransforms` |

The enum/option-set/C-constant table is the allowed shared value test (582).
Of the remaining 1146 implemented rows, the largest non-enum citation is
`testVectorMath` at 101 (8.8%, under the 40% bulk-relabel ceiling).

**Behaviour added in this pass:**

- `SCNParticleSystem` CPU emitter: `birthRate` spawn, life, acceleration,
  damping, `reset()`, SoA `addModifier` / `removeModifiers` /
  `removeAllModifiers`, `handle` birth/death/collision events, remaining
  emission/idle/image-sequence/mass/bounce/charge properties as live data.
- `SCNCameraController` orbit `rotateBy`, `dollyToTarget`/`dolly(by:onScreenPoint:viewport:)`,
  `rollAroundTarget`, `frameNodes` bounding-sphere framing, `clearRoll`,
  inertia flags/`stopInertia`.
- `SCNPhysicsField` kinds (linear/radial/drag/vortex/spring/electric/magnetic/
  noise/turbulence/custom) evaluated during the fixed-dt integrator, with
  exclusive/scope/halfExtent.
- `SCNPhysicsVehicle` engine/brake/steer applying chassis force; wheel
  suspension/axle properties; `speedInKilometersPerHour` from velocity.
  `SCNPhysicsSliderJoint` motor force and linear limits.
- Geometry `insert`/`remove`/`replace` materials, `element(at:)`, tessellator
  and LOD stores, geometry-element point-size/range.
- Camera post-process stores, light shadow/area/IES stores, morpher/physicsField/
  rendererDelegate, fail-closed `SCNScene(named:)`/`init(url:)`, NSCoding
  `init(coder:)` returns nil.

**Fail-closed:** Metal/EAGL/GPU render and snapshot, `.scn`/USD/DAE decode,
async SpriteKit `present`, JavaScript actions (no JS runtime), audio playback,
SwiftUI `SceneView`, Darwin `simd_float4x4`/`simd_quatf`, GLKit,
precomputed lighting environments.

**Tests:** `bash full/scenekit/tests/acceptance/test_host.sh`. Every cited
`func test*()` is synchronous and lives in `tests/agent/*Tests.swift`;
`SceneKitRuntime.swift` concatenates them for the sealed one-file guest
runtime.

**Environment:** Swift 6.2.4, `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` still fails in this snapshot
(missing `scratch/ladder-corpus/focus-ios`). The sealed host gate only
requires `swiftc`. Active Cursor Build on this VM was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign listed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). HEAD at start was
`39dc25a2769fb88a50f0853964137a4f96d50322`.
