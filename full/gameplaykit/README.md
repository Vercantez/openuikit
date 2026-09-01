# GameplayKit for Linux

This directory is a clean-room starting implementation of Apple's public
`GameplayKit` module for the OpenUIKit Linux campaign. It compiles to
`libGameplayKit.dylib` and is exercised by `tests/agent/GameplayKitRuntime.swift`.

## What is real

The Linux module implements the algorithmic core that does not require
SpriteKit, SceneKit, or UIKit:

- Random sources (`GKARC4RandomSource`, `GKLinearCongruentialRandomSource`,
  `GKMersenneTwisterRandomSource`), distributions, and `NSArray` shuffling
- Entity/component (`GKEntity`, `GKComponent`, `GKComponentSystem`)
- State machines (`GKState`, `GKStateMachine`) — the surface used by the
  Mastodon onboarding/report state types in the roadmap corpus
- Steering agents, goals, behaviors, paths, and obstacles
- Graphs, A* pathfinding, grid graphs, obstacle visibility graphs, and a
  Bowyer–Watson mesh triangulation
- Noise sources, `GKNoise` combinators, and `GKNoiseMap` sampling
- Quadtree / octree / R-tree spatial queries
- Rule systems, decision trees, minimax and Monte Carlo strategists
- `GKScene` entity/graph bookkeeping constructed in code

Seeded random sources, Perlin-style coherent noise, and graph search are
deterministic on this implementation and covered by the agent runtime.

## Fail-closed boundaries

- `GKScene(fileNamed:)` returns `nil`. Apple `.gkscene` archives are not in
  the pinned corpus, so they are not invented.
- `GKDecisionTree` URL import/export does not read or write an Apple archive
  format; `export(to:error:)` returns `false`.
- `NSCoder` paths compile but do not restore Apple-encoded objects.
- `NSPredicate(format:)` is unavailable in swift-corelibs-foundation.
  Predicate rules evaluate block/value predicates against `GKRuleSystem.state`.
- SpriteKit / SceneKit overlays (`GKSKNodeComponent`, `GKSCNNodeComponent`,
  `SKNode` obstacle helpers, `SKTexture(noiseMap:)`, `SCNNode.entity`,
  `SKTileMapNode` noise construction) are deferred until those modules exist
  in this isolated compile.
- `GKNoise` gradient-color APIs that require `UIColor` are deferred.

Steering, noise, triangulation, and PRNG constants are useful Linux
equivalents, not claimed Apple-bit-identical.

## Deferred / unavailable

See `coverage.tsv`. SceneKit, SpriteKit, and UIColor-dependent identifiers are
`deferred`. Everything else in `reference/public-surface.tsv` is `implemented`
or `declared` with evidence.
