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
