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

- Random sources and distributions: construction, seed storage, `nextInt(upperBound:)`
  range, Linux-deterministic replay, copy independence. Apple stream identity is
  unobserved (`declared` for unbounded `nextInt`/`nextUniform`/`nextBool`).
- Entity/component ownership: attach, two-entity transfer, same-class
  replacement, removal, deallocation of the host entity
- State machines, including nested `enter` from `didEnter`
- Graph connectivity and A* on explicit connections (cycle, start=goal empty,
  disconnected empty)
- Grid graph lookup and 4-neighbor paths
- Spatial queries, rule-system facts, option-set/enum values, `GKScene`
  in-memory bookkeeping
- `init?(coder:)` round-trips Linux-keyed `NSSecureCoding` archives for
  entities, graphs, scenes, polygon obstacles, decision trees, and random
  sources. Malformed and Apple-layout buffers are rejected. Apple keyed
  archive identity is unobserved (`declared`).

## Fail-closed / deferred

- No `.gkscene` loader (`sceneWithFileNamed:` returns `nil`)
- Decision-tree URL import/export does not invent an Apple archive
- `NSPredicate(format:)` is unavailable in swift-corelibs-foundation
- SpriteKit / SceneKit overlays compile only with those modules
- `UIColor` gradient APIs remain deferred
- Steering, noise samples, mesh triangulation, and strategist search are Linux
  algorithms (`declared` where Apple-exact behavior is unobserved)

Do not treat this isolated host run as an integrated Linux product proof.
`tests/agent/GameplayKitDependencyIdentity.swift` is the future EC2 probe: it
prints `GAMEPLAYKIT_DEPENDENCY_IDENTITY_OK` only after real Foundation, simd,
SceneKit, SpriteKit, and GameplayKit modules pass identity, coding, ownership,
overlay, and dylib assertions.
