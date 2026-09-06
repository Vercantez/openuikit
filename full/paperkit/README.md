# PaperKit (Linux starting point)

Medium-full starting implementation of Apple's public `PaperKit` surface for
Linux. The module is `PaperKit`; the host gate produces `libPaperKit.dylib`.

This directory is a clean-room Linux starting point seeded from the Xcode 26.1
iPhoneOS 26.1 symbol graph, API digester, TBD exports, and pinned
`dotnet/macios` bindings (which have no PaperKit sources). It is not wired
into the shared guest package; that integration is a later central-review
step.

## Depth pass 2026-09

SDK depth for `PaperKit` in `full/paperkit/` (180 exact IDs). This is a fresh
seed: `FeatureSet` factories and set algebra, `LineMarkerPositions` OptionSet
bits, `PaperMarkup` insert/transform/remove and the Linux `OPKM` archive,
`MarkupError` cases, `ShapeConfiguration` / `RenderingOptions` defaults, and
view-controller documented property defaults are implemented with focused
tests. Three async APIs stay `declared` because the sealed runner has no run
loop.

Coverage this round: **177 implemented / 3 declared / 180 total**
(177 nondeferred, floor 90). Enum and OptionSet members share table-driven
value tests; synthesized `LineMarkerPositions` algebra shares one OptionSet
test (24 rows). No non-member test exceeds 40% of the remaining implemented
rows (algebra is 24 / 110 ≈ 21.8% after member tables).

Top-5 implemented evidence (of 177 rows; 40% cap of remaining non-member
rows ≈ 44):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 24 | 13.6% | `LineMarkerPositionsTests.swift#testLineMarkerPositionsAlgebra` (OptionSet algebra) |
| 16 | 9.0% | `FeatureSetTests.swift#testFeatureSetFeatureCases` (table-driven enum cases) |
| 15 | 8.5% | `ShapeRenderingErrorTests.swift#testShapeConfigurationShapeCases` (table-driven enum cases) |
| 10 | 5.6% | `FeatureSetTests.swift#testFeatureSetContentVersionRawValues` |
| 10 | 5.6% | `LineMarkerPositionsTests.swift#testLineMarkerPositionsMembers` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

## What is real

- `FeatureSet.empty` / `.version1` / `.latest` follow the public comments:
  empty has no features, shapes, inks, or marker positions; version1 and
  latest currently match (only `ContentVersion.version1` exists) with all
  features, all shapes, all eight documented inks, `.all` marker positions,
  and SDR `colorMaximumLinearExposure` of `1.0`.
- `FeatureSet.contains` / `insert` / `remove` / `isSubset(of:)` compare
  features, shapes, inks, marker positions, exposure, and content-version
  raw value.
- `LineMarkerPositions` is an `Int` OptionSet. Linux bits: `plain = 1<<0`,
  `single = 1<<1`, `double = 1<<2`, `all = union`.
- `PaperMarkup` is a value type. Inserts, appends, transforms, equality, and
  `removeContentUnsupported(by:)` (after which the markup `featureSet` is a
  subset of the argument) are implemented in memory.
- Linux archives use magic `OPKM` plus a big-endian version and JSON payload.
  Unknown magic → `MarkupError.incorrectFormat`; version > 1 →
  `incompatibleFormatTooNew`; truncated or invalid JSON → `malformedData`.
- `PaperMarkupViewController` and `MarkupEditViewController` keep documented
  defaults (`isEditable = true`, `drawingTool = PKInkingTool(.pen)`,
  `directTouchMode = .selection`, `zoomRange = 1...1`, nil `contentView`,
  scroll indicators on). Tool-picker callbacks copy ruler/tool state.
  Delegate methods fire for in-memory selection / markup / viewport changes.

## Fail-closed

- No Apple Pencil hardware, no markup toolbar chrome, no scroll-view
  animation (`setContentVisibleFrame(_:animated:)` assigns immediately).
- `draw(in:frame:options:)` does not rasterize into `CGContext`.
- `insertNewImage` records width/height/frame only; pixel buffers are not
  stored or replayed as Apple bitmaps.
- Isolated-host `UIView` / `PKTool` / `CGColor` names exist only when those
  modules are absent from the link line. They compile out under
  `canImport(UIKit)` / `canImport(PencilKit)` / `canImport(CoreGraphics)`.
  They are not a Linux UIKit or PencilKit port.

## Still deferred / declared

- `PaperMarkup.dataRepresentation()` (async throws), `indexableContent`
  (async getter), and `draw(in:frame:options:)` (async) are `declared`. The
  throwing `init(dataRepresentation:)` path is tested with hand-built OPKM
  bytes.
- Apple PaperKit archive bytes, UTI identifier, OptionSet bits, and
  `ContentVersion` raw values remain oracle questions.
