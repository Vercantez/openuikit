# SpriteKit for Linux

This directory is a clean-room starting implementation of Apple's public
`SpriteKit` module for the OpenUIKit Linux host. Isolated compilation produces
`libSpriteKit.dylib` with Foundation only; CoreGraphics, QuartzCore, UIKit,
Metal, SceneKit, AVFoundation, and SwiftUI are not imported on this gate.

**Reference dossier:** `full/spritekit/reference/` from Xcode 26.1 / iPhoneOS 26.1
(1883 exact public identifiers, large-partitioned lane). External macios enums
are a secondary cross-check for raw values; their implementations are not copied.

## What is real (this isolated compile)

- Version macros `SK_VERSION` (Linux reports `0`), `SKVIEW_AVAILABLE`,
  `PHYSICSKIT_MINUS_GL_IMPORTS`
- Every public enum / `SKTileAdjacencyMask` option-set member with the macios
  raw values, including overlay name `hexPointyAdjacencyAdd` (raw 63)
- Scene graph: `SKNode` add/insert/remove, self-insertion rejected, `//name`
  search, 2D affine `convert`, hit-test / frame / intersects, user state,
  keyed actions, NSSecureCoding of name/position/scale/alpha
- `SKAction` move/fade/scale/rotate/resize/sequence/group/repeat/hide/wait/run/
  custom/texture/physics/audio/follow/reach/warp factories on a CPU clock
  (`SKScene.update`); named `.sks` actions return `nil`
- `SKScene` / `SKView` present, view↔scene convert, CPU texture snapshot,
  `SKTransition` factories, `SKCameraNode` contained set
- Physics: Euler integration, AABB contacts/bitmasks, joints, field sampling
  (Linux PhysicsKit stand-in, not bit-identical to Apple)
- Sprites, labels, shapes, textures (data / noise / `CGImage` lookalike), atlases
- Emitters + keyframe sequences (linear/step; spline uses linear mix)
- Tile definitions / groups / sets / maps; named and URL tile sets return `nil`
- Constraints, ranges, regions, warp grids, attributes, uniforms, shaders
- Crop / effect / light / audio / video / reference / transform / 3D bookkeeping
  nodes (no SceneKit scene, no AVPlayer)

Linux `SKColor` is a class with RGBA storage. When UIKit is imported it is a
`UIColor` typealias. `CGVector` / `CGPath` / `CGImage` lookalikes exist only
when CoreGraphics is absent; they are not a substitute in the EC2 integration
build (`SpriteKitDependencyIdentity.swift`).

## Fail-closed / deferred

- No `.sks` / named-action / named-tile-set archives (`nil` or `SKArchiveError`)
- No Metal `SKRenderer`, GPU frame loop, or shader compilation
- No SwiftUI `SpriteView` overlay (843 identifiers)
- No AVPlayer / AVAudioEngine success, no CIFilter, no UIImage texture loader
- No GLKit vector/matrix uniform overloads
- No SceneKit `SK3DNode` scene / hit-test types
- No `Selector` `perform(onTarget:)`
- `SKAction.follow` stores the path token and completes in duration; tangent
  orientation is unmeasured
- Physics contacts are AABB, not PhysicsKit manifolds

## Depth pass 2026-09

Coverage of the 1883 exact IDs: **981 implemented / 0 declared / 902 deferred**.

**Top-5 implemented evidence (of 981):**

| citations | evidence |
| ---: | --- |
| 200 | `test:full/spritekit/tests/agent/SpriteKitEnumTests.swift#testEnumAndOptionSetValues` |
| 100 | `test:full/spritekit/tests/agent/SpriteKitParticleTests.swift#testConstraintsRangeRegionWarp` |
| 73 | `test:full/spritekit/tests/agent/SpriteKitSpriteTests.swift#testSceneViewCameraTransition` |
| 71 | `test:full/spritekit/tests/agent/SpriteKitParticleTests.swift#testTileMapAndSet` |
| 70 | `test:full/spritekit/tests/agent/SpriteKitParticleTests.swift#testEmitterAndKeyframe` |

The enum/option-set table is the allowed shared value test (200). Of the remaining
781 implemented rows, the largest non-enum citation is
`testConstraintsRangeRegionWarp` at 100 (12.8%, under the 40% bulk-relabel ceiling).

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass. The first-pass CPU scene graph and its tests stay in
place. This pass implements search-path syntax, viewport math, deterministic
actions, PNG/atlas I/O, mass-density physics, circle contacts, and a CPU
`SKRenderer` ticker. Rendering stays fail-closed: no Metal device, no GPU
frame loop. A software raster of sprites/shapes is tested via
`SKView.texture(from:)`.

| status | before (pass 1) | after (wave 8) |
| --- | ---: | ---: |
| implemented | 981 | 991 |
| declared | 0 | 0 |
| deferred | 902 | 0 |
| unavailable | 0 | 49 |
| not-applicable | 0 | 843 |

Implemented gain: **+10** (`SKRenderer` CPU surface). 843 `_SpriteKit_SwiftUI`
`SpriteView` overlay identifiers are `not-applicable` with
`SwiftUI cross-import overlay; owned by the SwiftUI lane`. 49 Apple-only
Metal/SceneKit/AVFoundation/GLKit/CIFilter/UIKit-touch/Playground rows are
`unavailable`.

**Top-5 implemented evidence (of 991):**

| citations | evidence |
| ---: | --- |
| 200 | `test:full/spritekit/tests/agent/SpriteKitEnumTests.swift#testEnumAndOptionSetValues` |
| 95 | `test:full/spritekit/tests/agent/SpriteKitParticleTests.swift#testConstraintsRangeRegionWarp` |
| 71 | `test:full/spritekit/tests/agent/SpriteKitParticleTests.swift#testTileMapAndSet` |
| 70 | `test:full/spritekit/tests/agent/SpriteKitParticleTests.swift#testEmitterAndKeyframe` |
| 66 | `test:full/spritekit/tests/agent/SpriteKitSpriteTests.swift#testCropEffectLightAudioVideo` |

The enum/option-set table is the allowed shared value test (200). Of the remaining
791 implemented rows, the largest non-enum citation is
`testConstraintsRangeRegionWarp` at 95 (12.0%, under the 40% bulk-relabel ceiling).

Environment: `git rev-parse HEAD` matched
`bff8535c68425cc39fb45cb00d447b0981b57242`.
`.cursor/verify-cloud-environment.sh` failed with
`missing corpus checkout: scratch/ladder-corpus/focus-ios` (this pod booted
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21`, not campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Host `swiftc` is
Swift 6.2.4 / `x86_64-unknown-linux-gnu`. The isolated host gate compiles a
clean product tree (`products=clean`).

### Behaviour added in this pass

- `enumerateChildNodes(withName:)` / `childNode(withName:)` honor `//`, `*`,
  `..`, and `/`-separated paths.
- Parent `isPaused` stops descendant actions; `isHidden` skips hit-testing
  and raster but still evaluates actions.
- `calculateAccumulatedFrame` unions descendant frames in parent space.
- `SKScene.scaleMode` viewport math (fill / aspectFill / aspectFit /
  resizeFill) drives `convertPoint(fromView:)` / `toView`.
- Tick order is `update` → `didEvaluateActions` → `didSimulatePhysics` →
  `didApplyConstraints` → `didFinishUpdate`.
- `SKAction` timingMode (linear vs easeIn), `reversed()`, `speed`, and
  follow-path arc-length are evaluated on the CPU clock.
- Label frame uses the documented half-em rule: width = glyphCount ×
  fontSize × 0.5, height = fontSize.
- `SKTexture(data:size:)` parses PNG IHDR size; atlases load a folder of
  PNGs or a plist `frames` dictionary.
- Physics `mass`/`density` stay coupled through `area`; circle-circle
  contacts separate along the center line and dispatch begin/end.
- `SKRenderer.update(atTime:)` ticks the scene on CPU. Metal
  `init(device:)` / encode remain unavailable.
