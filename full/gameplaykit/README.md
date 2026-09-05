# GameplayKit for Linux

This directory is a clean-room starting implementation of Apple's public
`GameplayKit` module. Isolated host compilation produces `libGameplayKit.dylib`
without SceneKit, SpriteKit, or the Darwin `simd` module.

Vector public APIs use Swift standard-library `SIMD2`/`SIMD3` types, which are
the nominal identity behind Darwin `vector_floatN` once `simd` is imported.
This module does not declare public `vector_*` or `matrix_float3x3` shadows.
`GKAgent3D.rotation` is compiled only when `simd` provides `matrix_float3x3`.

`GK_VERSION` is not published: the macro has no numeric payload in the pinned
graphs.

## What is real (this isolated compile)

- Random sources and distributions: construction, seed storage, `nextInt` /
  `nextInt(upperBound:)` / `nextUniform` / `nextBool` range, Linux-deterministic
  replay, copy independence. Apple stream identity remains an oracle item.
- Entity/component ownership: attach, two-entity transfer, same-class
  replacement, removal, deallocation of the host entity
- State machines, including nested `enter` from `didEnter` (Mastodon-shaped
  `GKState` / `GKStateMachine` surface from the 20-app corpus)
- Graph connectivity and A* on explicit connections (cycle, start=goal empty,
  disconnected empty)
- Grid graph lookup and 4-neighbor paths
- Mesh triangulation, obstacle-graph connect/lock, and agent steering as
  Linux algorithms (not claimed Apple-bit-identical)
- Spatial queries, rule-system facts, option-set/enum values, `GKScene`
  in-memory bookkeeping
- `init?(coder:)` round-trips Linux-keyed `NSSecureCoding` archives for
  entities, graphs, scenes, polygon obstacles, decision trees, and random
  sources. Malformed and Apple-layout buffers are rejected.

## Fail-closed / deferred

- No `.gkscene` loader (`sceneWithFileNamed:` returns `nil`)
- Decision-tree URL import/export does not invent an Apple archive (`export`
  returns `false`)
- `NSPredicate(format:)` is unavailable in swift-corelibs-foundation;
  `NSPredicate(value:)` rules are exercised
- SpriteKit / SceneKit overlays compile only with those modules
- `UIColor` gradient APIs remain deferred
- `GKAgent3D.rotation` stays deferred until `simd.matrix_float3x3` is imported

Do not treat this isolated host run as an integrated Linux product proof.
`tests/agent/GameplayKitDependencyIdentity.swift` is the future EC2 probe: it
prints `GAMEPLAYKIT_DEPENDENCY_IDENTITY_OK` only after real Foundation, simd,
SceneKit, SpriteKit, and GameplayKit modules pass identity, coding, ownership,
overlay, and dylib assertions.

## Depth pass 2026-09

Coverage of 491 exact public identifiers:

| | before | after |
|---|---:|---:|
| implemented | 436 | **473** |
| declared | 37 | **0** |
| deferred | 18 | 18 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

The 37 previously `declared` rows (Linux algorithms, fail-closed URL/archive
paths, and `nextInt`/`nextUniform`/`nextBool` range behaviour) now cite focused
`test*` functions. SpriteKit/SceneKit/`UIColor`/`simd` overlays and
`GK_VERSION` stay deferred.

Every `implemented` row's evidence is
`test:full/gameplaykit/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous `func testName()`. Enum and option-set members share
`testEnumAndOptionSetValues`. No other test is cited by more than 40% of
implemented rows (largest non-enum: 43 / 473 ≈ 9%).

Top-5 evidence distribution (implemented rows):

1. `GameplayKitNoiseTests.swift#testNoiseSourcesDeterminism` — 43
2. `GameplayKitAgentTests.swift#testGoalsPathAndObstacles` — 39
3. `GameplayKitEnumTests.swift#testEnumAndOptionSetValues` — 38
4. `GameplayKitNoiseTests.swift#testNoiseOperationsAndMaps` — 30
5. `GameplayKitRulesTests.swift#testMinmaxAndMonteCarloStrategists` — 25

The 20-app corpus (from `reference/corpus-summary.json`) exercises GameplayKit
primarily through Mastodon `GKState` / `GKStateMachine` files; those identifiers
are covered by `GameplayKitStateMachineTests.swift`. Wikipedia contributes one
games-controller file. The scratch ladder-corpus checkout was not present in this
environment; ranking used the pinned corpus-summary plus the public surface.
