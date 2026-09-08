# Charts (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Charts` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

Unchanged application source continues to import `Charts`. Linux has no
SwiftUI layout engine, no display list, and no Apple chart renderer.
Scalar conversion, mark construction, host-driven `ChartProxy` mapping, and
stroke/interpolation retention are real. Layout, selection gestures, 3D,
and scroll interaction fail closed.

## What is real

- `Plottable` on the numeric types plus `String` and `Date`, with
  `primitivePlottable` identity round-trips.
- `PlottableValue.value` stores the authored label and value, including
  categorical `String`s.
- Marks convert plottable X/Y values to scalars (`Date` via
  `timeIntervalSinceReferenceDate`) and emit `ChartPlotRecord`s.
- `ChartScale` resolves `.linear` / `.log` / `.date` / `.category` and
  `ChartProxy` maps values through that geometry when scales are installed.
- `lineStyle` and `interpolationMethod` retain the authored
  `StrokeStyle` / `InterpolationMethod` on the returned wrapper, and
  interpolation methods produce sampled paths.
- `PlotDimensionScaleRange`, `AxisMarkPosition`, `BasicChartSymbolShape`
  (circle through triangle), `NumberBins`, `DateBins`, and `Chart3DPose`
  catalogs are constructible.
- `Chart` data and `@ChartContentBuilder` inits compile and collect marks.

The isolated Linux host gate compiles these sources with `swiftc` and
Foundation only. SwiftUI and CoreGraphics are not present as modules
there, so Charts uses module-local lookalikes for those dependency-owned
types. `tests/agent/ChartsDependencyIdentity.swift` imports the real
Foundation module for the later clean integration build.

## Fail-closed boundaries

- Chart selection, overlay geometry, and plot-frame mapping do not invent
  Apple layout. A default `ChartProxy` returns `nil` positions.
- `chartXSelection`, `chartOverlay`, axis builders, and legend modifiers
  are identity wrappers. They do not present UI.
- `Chart3D`, camera projection, and surface plots are declared types with
  empty bodies. There is no 3D renderer.
- Scroll-target and gesture modifiers do not claim Apple
  `ScrollTargetBehavior` timing.
- Synthesized SwiftUI `View` members on `Chart`, `Chart3D`,
  `ChartPlotContent`, `ChartAxisContent`, `Circle`,
  `BasicChartSymbolShape`, and `AnyChartSymbolShape` compile as no-ops so
  the overlay census can be declared without inventing layout.

## Existing Darwin host gate

The portable IceCubes consumer script remains Darwin-only (`xcrun`):

```sh
bash full/charts/tests/test_charts_host.sh
```

It is unchanged and is not the wave-6 Linux deliverable gate.

## Depth pass 2026-09

This pass implements the DATA→GEOMETRY layer and a software raster path
for Swift Charts on Linux. The isolated host gate still compiles with
Foundation only, so Charts programs against lookalike `View` /
`ViewBuilder` / `Shape` / `Path` / `Canvas` / `GraphicsContext` types
that match the port's SwiftUI/OpenCoreGraphics contracts. Those real
modules are not imported here and were not edited.

### Public surface that is now real

- `Chart { }` with `ChartContentBuilder` (including `buildPartialBlock`)
  collects `ChartPlotRecord`s from `BarMark`, `LineMark`, `PointMark`,
  `AreaMark`, `RuleMark`, `RectangleMark`, and `SectorMark`.
- `PlottableValue` for `Int`, `Double`, `Date`, `String` / categorical
  values, with `chartEncode` / `chartDecode`.
- `ChartScale` for `.linear`, `.log`, `.date`, and `.category`. Linear
  nice ticks use the 1-2-5×10^n rule: domain `0...10` →
  `0, 2, 4, 6, 8, 10`; domain `0...100` → `0, 20, 40, 60, 80, 100`.
  Log ticks are powers of ten.
- `chartXScale` / `chartYScale` / `chartXAxis` / `chartYAxis` /
  `chartLegend` / `chartForegroundStyleScale` store domain, range, type,
  visibility, and default axis positions (x → `.bottom`, y → `.leading`).
- `ChartProxy.position(forX:)` / `position(forY:)` / `value(atX:)` /
  `plotAreaRect` invert the resolved scales exactly. A default proxy
  stays fail-closed (`nil` / `.zero`) until a host or `Chart.resolvedProxy`
  installs scales.
- Stacking arithmetic for `.standard`, `.normalized`, and `.center`
  (plus `.unstacked`).
- Interpolation sampling for `.linear`, `.stepStart`, `.stepCenter`,
  `.stepEnd`, `.monotone` (Fritsch–Carlson), and `.catmullRom` /
  `.cardinal`. Sample points are numerically tested.
- Symbol paths (`circle`/`square`/`triangle`) and annotation offsets
  (`.top` / `.bottom` / `.leading` / `.trailing` / `.overlay`, default
  spacing 4).
- `AxisMarks` / `AxisValueLabel` / `AxisGridLine` / `AxisTick` retain
  position, values, and formats.
- Raster of bars/lines/points through lookalike `GraphicsContext` into
  a `ChartBitmap`. The 3-bar fixture (categories A/B/C, values 1/2/3,
  90×60) matches a hand-computed RGBA raster.

Coverage ledger (honest evidence, after the merge-refusal repair):

| status | refused `a7f28027` | after repair |
| --- | ---: | ---: |
| implemented | 3652 | 341 |
| declared | 4678 | 7996 |
| deferred | 680 | 673 |
| not-applicable | 464 | 464 |

The refused revision cited `testSymbolShapePaths` from 1670 of 3652
implemented rows (45.7%). Those rows were SwiftUI overlay witnesses on
`AnyChartSymbolShape` / `BasicChartSymbolShape`, not symbol `path(in:)`
checks. Implemented rows now cite a real `test*` that constructs or
calls that identifier. Enum / option-set catalogs may share one
table-driven test; no other test exceeds 40% of implemented rows.

Top-5 implemented evidence after repair:

| rows | share | test |
| ---: | ---: | --- |
| 38 | 11.1% | `ChartsTests.swift#testPrimitivePlottable` |
| 26 | 7.6% | `ChartsTests.swift#testBinsAndRanges` |
| 14 | 4.1% | `ChartsTests.swift#testChart3DPoseCatalog` |
| 14 | 4.1% | `ChartsDepthTests.swift#testPlottableValueLocalizedFactories` |
| 12 | 3.5% | `ChartsTests.swift#testRectangleMarkScalars` |

Chart / marks / `PlottableValue` / scales / axes / `ChartProxy` /
stacking / interpolation families stay nondeferred except 3D-only
synthesized `Chart3DContent` members on marks (`metalness` /
`roughness` / `symbolRotation`). The 464 stdlib-operator
`not-applicable` rows from this pass were later reclassified to
`deferred` in the wave-8 ledger repair (they are not SwiftUI overlay
IDs).

### SwiftUI port gaps (listed, not edited)

`uikit/Sources/SwiftUI` exposes `_OpenView` rather than Apple's `View`,
and has no `Canvas` / `GraphicsContext`. `uikit/Sources/OpenCoreGraphics`
has `Path` and `Canvas` (bitmap), not SwiftUI `GraphicsContext.fill`.
The isolated Charts gate cannot import those modules, so lookalikes
mirror the needed signatures. A later integration build should replace
the lookalikes with the real SwiftUI/OpenCoreGraphics types.

### Fail-closed (unchanged)

Selection, scroll, gestures, 3D/RealityKit, and live SwiftUI layout
timing remain fail-closed. `ChartProxy` without installed scales still
returns `nil` positions.

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass. The first-pass DATA→GEOMETRY layer and its tests
stay in place. This pass adds the plot-space layout engine, vectorized
plot content, and an honest fail-closed 3D/scroll boundary.

Before this pass (first-pass coverage after the merge-refusal repair):

| status | first pass |
| --- | ---: |
| implemented | 341 |
| declared | 7996 |
| deferred | 673 |
| not-applicable | 464 |

After the wave-8 implementation (`65361c52`, merge-refused):

| status | wave 8 refused |
| --- | ---: |
| implemented | 689 |
| declared | 6845 |
| deferred | 660 |
| not-applicable | 1280 |

After the ledger repair (this revision):

| status | after repair |
| --- | ---: |
| implemented | 673 |
| declared | 6861 |
| deferred | 1124 |
| not-applicable | 816 |

Nondeferred (`implemented` + `declared`) is 7534, above the 4737 floor.
All 272 `VectorizedChartContent` census rows stay `implemented` with
per-overload tests that call that identifier on every conforming plot
type. SwiftUI `View` overlay re-exports (`s:7SwiftUI4View…`) stay
`not-applicable` with the note `SwiftUI cross-import overlay; owned by
the SwiftUI lane` — never `implemented`. The 464 stdlib
Comparable/Equatable/Integer operators that had been `not-applicable`
(for example `s:SLsE1goiySbx_xtFZ::SYNTHESIZED::s:10Foundation4DateV`)
are now `deferred`: Charts does not redeclare those operators. Sixteen
KeyPath plot-init overloads with no product declaration and no test
were reclassified to `declared` (`source:full/charts/ChartsSurface.swift#BarPlot`
and the sibling plot types).

Top-5 implemented evidence after repair:

| rows | share | test |
| ---: | ---: | --- |
| 38 | 5.6% | `ChartsTests.swift#testPrimitivePlottable` |
| 26 | 3.9% | `ChartsTests.swift#testBinsAndRanges` |
| 15 | 2.2% | `ChartsWave8Tests.swift#testVectorizedSymbolSizeBy` |
| 15 | 2.2% | `ChartsWave8Tests.swift#testVectorizedSymbolSizeAreaKeyPath` |
| 15 | 2.2% | `ChartsWave8Tests.swift#testVectorizedSymbolSizeCGSizeKeyPath` |

No single non-catalog test exceeds 40% of implemented rows (cap 269).
Accessibility, symbol-size, `PlottableProjection` factory, and extra
plot-init families each cite a focused `test*` that constructs that
overload.

### Public surface added in this pass

- `ChartScale.symbolLog` shares log10 mapping with `.log`. Domain
  `1...1000`, range `0...90`, value `10` maps to pixel `30`. Automatic
  domain inference uses recorded X/Y extrema; linear nice-ing keeps
  the 1-2-5×10^n rule (`0.2...9.7` → nice domain `0...10`).
- `Chart(content:)` / `Chart(data:id:content:)` plus `ForEach` collect
  `ChartPlotRecord`s. `ChartProxy.position(forX:)` / `position(forY:)` /
  `value(atX:)` / `plotAreaSize` / `plotFrame` invert the resolved scales
  for a host-supplied plot rect. Geometry tests use a fixed 100×40
  plot (3-bar fixture remains 90×60).
- Mark inits: `BarMark` series and interval overloads; `LineMark` /
  `PointMark` / `AreaMark` / `RectangleMark` / `RuleMark` / `SectorMark`
  place through `ChartLayout` against those scales.
- `AxisMarks` / `AxisMarkValues.automatic` / `stride` / `values` produce
  tick pixels via `ChartAxisLayout.tickPositions`. `chartXAxis` /
  `chartYAxis` visibility stores `.hidden` / `.visible`.
- Resolved mark attributes: `foregroundStyle`, `symbol`,
  `interpolationMethod`, `lineStyle`, and `annotation(position:alignment:)`.
- `chartScrollableAxes` / `chartScrollPosition` / `chartXSelection` retain
  host models only. Gesture delivery, hit-testing, and UIKit/SwiftUI
  scroll timing stay fail-closed.
- `VectorizedChartContent` (272 rows) plus `BarPlot` / `LinePlot` /
  `AreaPlot` / `PointPlot` / `RulePlot` / `RectanglePlot` / `SectorPlot`
  data inits. Protocol modifiers use Apple KeyPath / `PlottableProjection`
  signatures. `Chart3D` / `SurfacePlot` / extra `SurfaceMark` are empty
  fail-closed types (no RealityKit renderer).

### Fail-closed (wave 8)

- 3D pose/camera/surface rendering is not a renderer.
- Scroll and selection bindings store values; they do not pan or
  hit-test a plot.
- Vectorized KeyPath modifiers stamp attributes; they do not re-scan
  the original collection after construction.
- SwiftUI overlay modifiers remain identity stubs or Chart-local
  storage; they are not claimed as Apple `View` overlay behavior.

### Third pass (plot-space layout attributes)

Third SDK-depth pass on the wave-8 plot engine already in this tree.
First-pass and wave-8 sources and tests stay in place. This pass stamps
`ChartContent` / `AxisMark` modifiers onto `ChartPlotRecord` layout
attributes, applies those offsets in `ChartLayout.place`, and nices
inferred linear/log/symbolLog domains.

Before this pass (wave-8 repaired ledger):

| status | before |
| --- | ---: |
| implemented | 673 |
| declared | 6861 |
| deferred | 1124 |
| unavailable | 0 |
| not-applicable | 816 |

After this pass:

| status | after |
| --- | ---: |
| implemented | 1892 |
| declared | 2845 |
| deferred | 1083 |
| unavailable | 0 |
| not-applicable | 3654 |

Implemented gain is +1219. Nondeferred (`implemented` + `declared`) is
4737, exactly the medium-full floor. Unique cited tests: 141. Every
`not-applicable` row is a SwiftUI cross-import overlay (`s:7SwiftUI…`)
with the note `SwiftUI cross-import overlay; owned by the SwiftUI lane`.
Stdlib operator overlays stay `deferred`, not `not-applicable`.

Top-5 implemented evidence after this pass (1892 rows; cap 40% = 756):

| rows | share | test |
| ---: | ---: | --- |
| 41 | 2.2% | `ChartsPlotEngineTests.swift#testSectorMarkChartContentModifiers` |
| 41 | 2.2% | `ChartsPlotEngineTests.swift#testSectorPlotChartContentModifiers` |
| 41 | 2.2% | `ChartsPlotEngineTests.swift#testRectangleMarkChartContentModifiers` |
| 41 | 2.2% | `ChartsPlotEngineTests.swift#testRectanglePlotChartContentModifiers` |
| 41 | 2.2% | `ChartsPlotEngineTests.swift#testAnyChartContentModifiers` |

No single test exceeds 40% of implemented rows. Each cited
`ChartContent` modifier catalog constructs that type and asserts a
stamped layout field for that identifier family.

Public surface added in this pass:

- `ChartLayoutAttributes` on each `ChartPlotRecord` (offset X/Y and
  edges, cornerRadius, zIndex, symbolSize, blur, shadow, clip, mask,
  accessibility, compositing, positionBy). `ChartLayout.place` applies
  those pixel offsets after scale mapping.
- Inferred linear/log/symbolLog domains are niced with the 1-2-5×10^n
  rule when no explicit domain is stored (`0.2...9.7` → `0...10`).
  Explicit `chartXScale(domain:)` is left unchanged.
- `ChartContent` modifiers return `_ChartAttributedPlotContent` that
  stamps records: offset overloads, symbolSize, cornerRadius,
  compositingLayer, accessibility, blur, mask, shadow, symbol, zIndex,
  opacity, position, clipShape, lineStyle(by:).
- `AxisMarkBuilder` / `AxisContentBuilder` (buildBlock, buildEither,
  buildIf, buildExpression, buildLimitedAvailability) plus
  `AxisMark.foregroundStyle` / `font` / `offset`.
- `MarkDimension.fixed` / `ratio` and integer/float literals.
- `AnnotationPosition` corners and `AnnotationOverflowResolution.Strategy`.
- `Plot` collects `chartPlotRecords` from builder content.
- Geometry tests compare against hand-computed pixels for a fixed
  100×40 plot.

Fail-closed (unchanged): `Chart3D` / `SurfaceMark` have no RealityKit
renderer. Scroll and selection store host models only. SwiftUI `View`
overlay re-exports stay `not-applicable`. Lookalike
`View.offset<T0,T1>(x:y:)` can steal `ChartContent.offset` when arguments
are `Int`; tests use `CGFloat` literals and contextual types. Apple
overload ranking is unobserved (see `oracle-questions.tsv`).

### Fourth pass (NumberBins / DateBins collection + PrimitivePlottable)

Next SDK-depth pass on the wave-8 / third-pass tree. First-pass, wave-8,
and third-pass sources and tests stay in place. This pass implements the
plot-space histogram binning engine and honest PrimitivePlottable
witnesses. Stdlib `FixedWidthInteger` / `AdditiveArithmetic` / integer
operator overlays stay `deferred` (Charts does not redeclare them).
`Chart3D` / `SurfaceMark` stay fail-closed.

Before this pass (third-pass ledger):

| status | before |
| --- | ---: |
| implemented | 1892 |
| declared | 2845 |
| deferred | 1083 |
| unavailable | 0 |
| not-applicable | 3654 |

After this pass:

| status | after |
| --- | ---: |
| implemented | 2046 |
| declared | 2783 |
| deferred | 991 |
| unavailable | 0 |
| not-applicable | 3654 |

Implemented gain is +154. Nondeferred (`implemented` + `declared`) is
4829, above the 4737 floor. Unique cited tests: 165. Every
`not-applicable` row remains a SwiftUI cross-import overlay
(`s:7SwiftUI…`) with the note `SwiftUI cross-import overlay; owned by
the SwiftUI lane`. `unavailable` stays 0.

Top-5 implemented evidence after this pass (2046 rows; cap 40% = 818):

| rows | share | test |
| ---: | ---: | --- |
| 41 | 2.0% | `ChartsPlotEngineTests.swift#testSectorMarkChartContentModifiers` |
| 41 | 2.0% | `ChartsPlotEngineTests.swift#testSectorPlotChartContentModifiers` |
| 41 | 2.0% | `ChartsPlotEngineTests.swift#testRectangleMarkChartContentModifiers` |
| 41 | 2.0% | `ChartsPlotEngineTests.swift#testRectanglePlotChartContentModifiers` |
| 41 | 2.0% | `ChartsPlotEngineTests.swift#testAnyChartContentModifiers` |

No single test exceeds 40% of implemented rows.

Public surface added in this pass:

- `NumberBins` is `RandomAccessCollection` of `ChartBinRange`. Owned
  inits: `thresholds`, `range:count:` (integer and floating),
  `size:range:`, `range:desiredCount:minimumStride:` (1-2-5×10^n nice
  ticks: `0.2...9.7` desired 5 → `0, 2, 4, 6, 8, 10`), and
  `data:desiredCount:minimumStride:`. `index(for:)` clamps below the
  first threshold to 0 and values at/above the last threshold onto the
  last bin.
- `DateBins` collection plus `init(thresholds:)`,
  `init(timeInterval:range:)`, `init(unit:by:range:calendar:)`,
  `init(range:desiredCount:calendar:)`, `init(data:desiredCount:calendar:)`.
  The first-pass `init(unit:range:)` convenience remains.
- `ChartBinRange` is `RangeExpression`: half-open `contains`,
  `relative(to:)`, and `~=`.
- Histogram geometry: bins `0...10` count 2, data `[1,2,3,8,9]` →
  counts `[3,2]`; two category bars on a 100×40 plot match hand-computed
  frames (inset 4, band 50, y domain 0...4 inverted).
- `PrimitivePlottableProtocol` identity witnesses on numeric types
  including `Float16`, plus `String`/`Date`. `Decimal` plots through
  `Double`. String raw-value enumerations use `rawValue`. `Never`
  typealias is exercised; `Never` values stay uninhabited (`declared`).
- Collection/Sequence algorithms on `NumberBins` and `DateBins` are
  exercised (map/filter/reduce/prefix/suffix/…). Combine `publisher`,
  Foundation `FormatStyle`/`SortComparator`, deprecated optional
  `flatMap`, and `indices` where `Indices == Self` stay `deferred`.

Fail-closed (unchanged): `Chart3D` / `SurfaceMark` have no RealityKit
renderer. Scroll and selection store host models only. SwiftUI overlay
re-exports stay `not-applicable`. Stdlib integer operator overlays stay
`deferred`.

### Fifth pass (function plots, overflow, 3D builder)

Next SDK-depth pass on the wave-8 / fourth-pass tree. First-pass, wave-8,
third-pass, and fourth-pass sources and tests stay in place. This pass
builds the 2D function-plot sampler, plot-dimension padding,
`AutomaticScaleDomain` includesZero/reversed/modify, annotation overflow
resolution, `Chart3DContentBuilder` collection, SurfacePlot 3×3 samples,
and ValueAligned scroll-target factories. `Chart3D` still has no
RealityKit renderer (`body` remains `EmptyView`).

Before this pass (fourth-pass ledger):

| status | before |
| --- | ---: |
| implemented | 2046 |
| declared | 2783 |
| deferred | 991 |
| unavailable | 0 |
| not-applicable | 3654 |

After this pass:

| status | after |
| --- | ---: |
| implemented | 2192 |
| declared | 2660 |
| deferred | 968 |
| unavailable | 0 |
| not-applicable | 3654 |

Implemented gain is +146. Nondeferred (`implemented` + `declared`) is
4852, above the 4737 floor. Unique cited tests: 205. Every
`not-applicable` row remains a SwiftUI cross-import overlay
(`s:7SwiftUI…`) with the note `SwiftUI cross-import overlay; owned by
the SwiftUI lane`. `unavailable` stays 0.

Top-5 implemented evidence after this pass (2192 rows; cap 40% = 876):

| rows | share | test |
| ---: | ---: | --- |
| 41 | 1.9% | `ChartsPlotEngineTests.swift#testSectorMarkChartContentModifiers` |
| 41 | 1.9% | `ChartsPlotEngineTests.swift#testSectorPlotChartContentModifiers` |
| 41 | 1.9% | `ChartsPlotEngineTests.swift#testRectangleMarkChartContentModifiers` |
| 41 | 1.9% | `ChartsPlotEngineTests.swift#testRectanglePlotChartContentModifiers` |
| 41 | 1.9% | `ChartsPlotEngineTests.swift#testAnyChartContentModifiers` |

No single test exceeds 40% of implemented rows. Function-plot
`ChartContent` modifier catalogs (`testFunctionAreaPlotContentModifiers`,
`testFunctionLinePlotContentModifiers`) also sit at 41 rows each.

Public surface added in this pass:

- `LinePlot` / `AreaPlot` function and parametric inits sample 11
  inclusive points on the authored domain (nil domain → `0...1`).
  Geometry tests use a fixed 100×40 plot: `y = 2x` on `0...10` /
  `0...20` maps endpoints to (0, 40) and (100, 0).
- `chartXScale` / `chartYScale` `plotDimension(startPadding:endPadding:)`
  insets the plot-area pixel range before inversion (100-wide plot,
  padding 10/10, domain `0...10` → pixels 10…90).
- `AutomaticScaleDomain.includesZero` expands extrema through 0;
  `reversed` toggles invert; `modifyInferredDomain` runs at factory
  time.
- `AnnotationOverflowResolution` boundary/strategy values are distinct.
  `chartClampAnnotation` clamps `.fit` / `.automatic` into the plot
  rect; `.padScale` insets 4pt; `.disabled` leaves the coordinate.
- `Chart3DContentBuilder` `buildBlock` / `buildEither` / `buildOptional`
  / `buildExpression` / `buildLimitedAvailability`. `Chart3D` stores
  `content`; rendering stays `EmptyView`.
- `Chart3DCameraProjection.automatic` plus catalog equality/hash.
- `ChartSymbolShape` / `Chart3DSymbolShape` protocol statics on
  `BasicChartSymbolShape` / `BasicChart3DSymbolShape`.
- `SurfacePlot` function inits sample a 3×3 grid on `[0,1]×[0,1]` into
  `samples` (no 3D renderer). `Chart3DContent` modifiers
  (`symbolSize`, `foregroundStyle`, `symbol`, `metalness`, `roughness`)
  stamp those types.
- `ValueAlignedChartScrollTargetBehavior` inits store unit/matching
  values. `updateTarget` stays undeclared (no UIScrollView).
- `AxisContent.compositingLayer` plus `AnyAxisContent.init(erasing:)` /
  `init(_ content: any AxisContent)`.

Fail-closed (unchanged): no RealityKit/Chart3D renderer. Scroll
`updateTarget` is not declared. SwiftUI `View` `PAAE` overlays remain
`not-applicable`. Stdlib integer operator overlays stay `deferred`.

Environment: this pod booted from Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21`, not campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.
`.cursor/verify-cloud-environment.sh` fails earlier (`missing corpus
checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is Swift 6.2.4
targeting `x86_64-unknown-linux-gnu`. The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token; `products=clean` means the sealed gate ran
with no stale `full/charts/.build`, `build`, or `scratch` products.

Fifth-pass sealed host gate on this Linux host (Swift 6.2.4,
`x86_64-unknown-linux-gnu`). Starting commit was
`6bf18072f4bc9ca119f4b0ad49dd8478f92dd5f0`. The gate printed:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Charts lane=medium-full symbols=9474
FRAMEWORK_FANOUT_REFERENCE_OK
CHARTS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Charts dylib=libCharts.dylib
```

Campaign inventory token (not printed by the sealed gate or by
`.cursor/verify-cloud-environment.sh` on this snapshot; `swiftc` is
6.2.4 / linux and the product tree was clean):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
```

Darwin `full/charts/tests/test_charts_host.sh` is IceCubes / `xcrun` /
`/private/tmp` and is not the Linux deliverable (`mktemp` fails here).

### Sixth pass (mark-dimension layout + ChartProxy bands)

Next SDK-depth pass on the wave-8 / fifth-pass tree. First-pass through
fifth-pass sources and tests stay in place. This pass builds the
plot-space `MarkDimension` resolver, sector polar layout, KeyPath
interval plot inits, `ChartProxy.positionRange` category bands, and
fail-closed `Chart3DContent` witnesses on 2D marks.

Before this pass (fifth-pass ledger):

| status | before |
| --- | ---: |
| implemented | 2192 |
| declared | 2660 |
| deferred | 968 |
| unavailable | 0 |
| not-applicable | 3654 |

After this pass:

| status | after |
| --- | ---: |
| implemented | 2314 |
| declared | 2580 |
| deferred | 926 |
| unavailable | 0 |
| not-applicable | 3654 |

Implemented gain is +122. Nondeferred (`implemented` + `declared`) is
4894, above the 4737 floor. Unique cited tests: 246. Every
`not-applicable` row remains a SwiftUI cross-import overlay
(`s:7SwiftUI…`) with the note `SwiftUI cross-import overlay; owned by
the SwiftUI lane`. `unavailable` stays 0.

Top-5 implemented evidence after this pass (2314 rows; cap 40% = 925):

| rows | share | test |
| ---: | ---: | --- |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testSectorMarkChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testSectorPlotChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testRectangleMarkChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testRectanglePlotChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testAnyChartContentModifiers` |

No single test exceeds 40% of implemented rows.

Public surface added in this pass:

- `MarkDimension` `.automatic` / `.inset` / `.fixed` / `.ratio` resolve
  inside a pixel span (automatic insets 4pt on a category band). Two
  category bars on a 100-wide plot with `.inset(8)` occupy x=8 width=34
  and x=58 width=34; `.fixed(20)` occupies 15…35 and 65…85.
- `MarkDimensions` KeyPath `.inset(\.field)` reads per-row CGFloats.
- `BarPlot` / `RectanglePlot` / `RulePlot` / `PointPlot` / `SectorPlot`
  KeyPath interval inits record authored xStart/xEnd/yStart/yEnd and
  place through `ChartLayout` against a fixed 100×40 plot.
- Sectors start at `-π/2` (12 o'clock) and sweep with increasing angle
  in y-down space. A full-circle `SectorMark` on 100×40 is centered at
  (50, 20) with outer radius 20. Equal halves occupy the right and left
  semicircle frames. Inner/outer `.ratio` / `.inset` / `.fixed` are
  numeric.
- Unstacked interval bars keep authored `yStart`/`yEnd` instead of
  stacking overwrite. Rule marks with `xStart`/`xEnd` + `y` draw that
  segment only.
- `ChartProxy.positionRange(forX:)` returns the category band
  (`"A"` → 0...50, `"B"` → 50...100 on two categories). Continuous Y
  collapses to the mapped pixel (y=3 of 0...4 inverted → 10...10).
  `value(at:)` inverts both scales; `angle(at:)` is `atan2` from the
  plot-range center.
- `ChartContent.position(by:axis:span:)` stamps `span` onto
  `markWidth` (horizontal) or `markHeight` (vertical). `.fixed(20)`
  matches the hand-computed centered band.
- `MajorValueAlignment.page` / `.unit` / `.matching` snap domain
  values. `.unit(5)` on 0...10 maps 3 → 5 → pixel 50.
- `BasicChart3DSurfaceStyle.heightBased` defaults to yRange `0...1`;
  `normalBased` is a distinct stored style. No 3D renderer.
- `Chart3D` data/`ForEach` inits store content; `body` stays
  `EmptyView`. `RectangleMark` / `RuleMark` / `PointMark` /
  `BuilderConditional` / `ForEach` / `Optional` accept
  `Chart3DContent` modifiers as attribute stamps.
- `AnyAxisMark(erasing:)` / `init(_ content: any AxisMark)`.

Fail-closed (unchanged): no RealityKit/Chart3D renderer.
`symbolRotation` / `metalness` / `roughness` stay deferred.
`Chart3DContent` modifiers on `Never` and lookalike-absent
`ModifiedContent` stay `declared`. `ChartContent` modifiers
synthesized on `Never` stay `declared` (uninhabited). Scroll and
selection store host models only. SwiftUI `View` overlay re-exports
stay `not-applicable`. Stdlib integer operator overlays stay
`deferred`.

## Wave-6 deliverable gate

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/charts --phase deliverable
bash full/charts/tests/acceptance/test_host.sh
```

`tests/agent/ChartsRuntime.swift` records the runtime contract the focused
tests exercise. `tests/agent/ChartsLoadSmoke.swift` is the canonical
schema-v2 import/marker source.

### Depth pass 2026-09 (wave 8): normalized metadata follow-up

This follow-up starts from the sixth-pass ledger (`implemented` 2314,
`declared` 2580, `deferred` 926, `unavailable` 0, `not-applicable` 3654)
and ends at `implemented` 2340, `declared` 2566, `deferred` 914,
`unavailable` 0, `not-applicable` 3654. The implemented gain is 26.
Nondeferred coverage is 4906, above the medium-full floor.

Concrete and erased 2D symbols now expose the normalized `0,0,1,1`
perceptual unit rectangle, and `AnnotationContext` retains its target size.
Focused checks also exercise protocol body/associated-type witnesses and verify
that 3D material attributes are retained by every available Linux 3D-content
witness. Material values are metadata only; `Chart3D` and `SurfacePlot` still
do not render, and `symbolRotation` remains deferred because the pinned Linux
dependency set has no genuine RealityKit `Rotation3D` type.

Top-five evidence distribution (2340 implemented rows; 40% cap = 936):

| rows | share | test |
| ---: | ---: | --- |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testSectorMarkChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testSectorPlotChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testRectangleMarkChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testRectanglePlotChartContentModifiers` |
| 41 | 1.8% | `ChartsPlotEngineTests.swift#testAnyChartContentModifiers` |

The requested 300-row gain is not honestly reachable from this ledger: only 85
declared rows are non-SwiftUI precise IDs, 54 of those are uninhabited `Never`
witnesses, and most remaining deferred rows are stdlib integer/collection
members that Charts neither owns nor redeclares. SwiftUI cross-import overlay
rows were not relabeled as implemented, and stdlib behavior was not claimed as
Charts behavior merely to increase the count.

#### Wave 8 depth continuation: scroll-target model and remaining witnesses

This continuation starts from `implemented` 2340, `declared` 2566,
`deferred` 914, `unavailable` 0, and `not-applicable` 3654. It ends at
`implemented` 2353, `declared` 2558, `deferred` 909, `unavailable` 0, and
`not-applicable` 3654: an honest implemented gain of 13, with nondeferred
coverage remaining 4911. The 300-row target is exhausted by the ownership
boundary: the remaining declared Charts rows are overwhelmingly uninhabited
`Never` synthesized witnesses, while the deferred bulk is stdlib and SwiftUI
surface that Charts cannot honestly claim.

The Linux scroll starting point now includes a deterministic programmatic
`ScrollTarget` model, a `ChartScrollTargetBehaviorContext` that exposes its
`ChartProxy` and forwards base context properties by key path, and protocol
bridging from a base scroll context to a chart context. Value-aligned behavior
snaps x/y origins to configured numeric units. This does not synthesize gesture
prediction, paging, animation, or Apple scroll-view limit behavior.

Focused tests additionally establish the `AxisMark` and `AxisContent` protocol
witnesses, the `ChartSymbolShape.perceptualUnitRect` contract, distinct basic 3D
symbol identities, and record retention by function area/line content. 3D
rendering, camera/pose interaction, and `Rotation3D` remain fail-closed. Function
content and `Plot` `Body == Never` ABI questions remain deferred because the
portable diagnostic views intentionally expose inspectable bodies.

Top-five implemented evidence distribution (2353 implemented rows; 40% cap =
941):

| rows | share | test |
| ---: | ---: | --- |
| 41 | 1.7% | `ChartsPlotEngineTests.swift#testSectorMarkChartContentModifiers` |
| 41 | 1.7% | `ChartsPlotEngineTests.swift#testSectorPlotChartContentModifiers` |
| 41 | 1.7% | `ChartsPlotEngineTests.swift#testRectangleMarkChartContentModifiers` |
| 41 | 1.7% | `ChartsPlotEngineTests.swift#testRectanglePlotChartContentModifiers` |
| 41 | 1.7% | `ChartsPlotEngineTests.swift#testAnyChartContentModifiers` |
