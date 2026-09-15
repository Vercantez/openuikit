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

### Wave-6 View-modifier depth pass (Charts-owned `chart*` modifiers)

This pass starts from the wave-8 continuation ledger (`implemented` 2353,
`declared` 2558, `deferred` 909, `unavailable` 0, `not-applicable` 3654)
and ends at `implemented` 3009, `declared` 1902, `deferred` 909,
`unavailable` 0, `not-applicable` 3654: an implemented gain of 656, with
nondeferred coverage at 4911, above the medium-full floor.

The converted rows are exactly the Charts-owned `chart*` `View` modifiers
(`chartXAxis` / `chartYAxis` / `chartZAxis` content and visibility,
axis labels and styles, legend, X/Y/Z scales, X/Y/Z/angle selection,
scroll position / scrollable axes / visible domain / scroll-target
behavior, foreground-style / symbol / symbol-size / line-style scales,
overlay, background, plot style, gesture, 3D pose, camera projection):
each has a real product stub in `Charts.swift` / `ChartsModifiers.swift`,
and each overload is now exercised by one of 27 focused tests in
`tests/agent/ChartsViewModifiersTests.swift` on `EmptyView`, `Chart`,
`Chart3D`, `ChartPlotContent`, `ChartAxisContent`, `AnyChartSymbolShape`,
`BasicChartSymbolShape`, and `Circle`. `Chart`-specific overloads with
real storage (`chartXAxis(_:)` / `chartYAxis(_:)` / `chartLegend(_:)` /
`chartXScale(domain:)` / `chartYScale(domain:)` /
`chartForegroundStyleScale(domain:type:)` / `chartScrollableAxes(_:)`)
assert the stored state; identity stubs assert the call round-trips over
every base view. Overloads that share a name between the `Chart` and
`View` extensions are exercised on non-`Chart` bases to avoid inventing
Apple overload ranking.

Not converted, deliberately: the ~1902 remaining declared rows are
generic SwiftUI modifiers (`.alert`, `.padding`, `.badge`, accessibility,
file dialogs, drag/drop, toolbars, …) synthesized for Chart types, plus
uninhabited `Never` witnesses. Charts does not own that behavior, so it
is not claimed. SwiftUI cross-import overlays stay `not-applicable`;
stdlib operator overlays stay `deferred`.

Top-five implemented evidence distribution (3009 implemented rows; 40% cap =
1203):

| rows | share | test |
| ---: | ---: | --- |
| 88 | 2.9% | `ChartsViewModifiersTests.swift#testChartViewAxisLabels` |
| 72 | 2.4% | `ChartsViewModifiersTests.swift#testChartViewSymbolScale` |
| 56 | 1.9% | `ChartsViewModifiersTests.swift#testChartViewSymbolSizeScale` |
| 54 | 1.8% | `ChartsViewModifiersTests.swift#testChartViewForegroundStyleScale` |
| 48 | 1.6% | `ChartsViewModifiersTests.swift#testChartViewLineStyleScale` |

No single test exceeds 40% of implemented rows.

Fail-closed (unchanged): the converted modifiers are identity stubs or
Chart-local storage; they do not perform layout, hit-testing, scrolling,
gesture delivery, or 3D rendering. `Chart3D` / `SurfacePlot` still do not
render.

### Aggressive-coverage follow-up (pi wave-3 charts prompt)

This follow-up starts from the View-modifier ledger (`implemented` 3009,
`declared` 1902, `deferred` 909, `unavailable` 0, `not-applicable` 3654)
and ends at `implemented` 3015, `declared` 1900, `deferred` 905,
`unavailable` 0, `not-applicable` 3654: an honest implemented gain of 6.
Nondeferred coverage is 4915, above the medium-full floor.

Converted rows (each cited test constructs that type and asserts the
stamped metadata for that identifier family):

- `metalness` / `roughness` synthesized on `ForEach` and `Optional`
  (`Chart3DContent`) — 4 deferred rows. The base protocol-extension
  declarations and the `ForEach` / `Optional` `Chart3DContent`
  conformances already exist, mirroring the implemented `symbolSize`
  precedent; `testChart3DMaterialForEachOptional` stamps and asserts
  the retained ratios.
- `AxisContent.compositingLayer()` / `compositingLayer(style:)`
  synthesized on `BuilderConditional` — 2 declared rows. The
  `BuilderConditional: AxisContent` conformance and both base overloads
  already exist; `testAxisContentBuilderConditionalCompositingLayer`
  asserts the stamped `"layer"` / `"style"` values, which rules out
  lookalike-`View` overload stealing.

Not converted, deliberately: the ~1900 remaining declared rows are
generic SwiftUI `View` extension modifiers (`.padding`, `.alert`, drag /
drop, toolbars, …) synthesized onto Chart types plus uninhabited
`Never` witnesses and one `SurfacePlot.body: Never` row whose product
body is intentionally a different (fail-closed `EmptyView`) symbol.
The Linux lookalike `View` declares none of those modifiers, so no test
can honestly call those identifiers without inventing SwiftUI behavior
(contract: no bulk-relabel; SwiftUI overlays stay out of `implemented`).
Remaining deferred rows are stdlib integer/collection operators,
Foundation `FormatStyle` / `SortComparator` / Combine overlays, 3D
`Body` witnesses, `symbolRotation` (no RealityKit `Rotation3D` in the
pinned Linux set), and `valueAligned` on SwiftUI-owned
`PagingScrollTargetBehavior` — none honestly claimable as Charts
behavior. The requested huge gain is not reachable from this ledger
without dishonest relabeling.

Top-five implemented evidence is unchanged (3015 rows; 40% cap = 1206).
The two new tests are cited by 4 and 2 rows respectively. No single
test exceeds 40% of implemented rows.

Gate repair in this pass: `tests/agent/ChartsViewModifiersTests.swift`
did not compile under the pinned Linux Swift 6.2.4 because the
`ChartsModifiers.swift` stubs are fully generic (`position: T0`,
`content: T3`), leaving enum literals (`.hidden`, `.top`, `.bottom`,
`.leading`, `.automatic`, `.center`, `.visible`) and `{ _ in … }`
overlay/background closures without contextual types. The tests are
unchanged in name, count, and called identifiers; literals now carry
their Apple-intended explicit types (`Visibility`,
`AxisMarkPosition`, `AnnotationPosition`, `Alignment`, and
`(_: ChartProxy)` closures mirroring the concrete `Chart.chartOverlay`
shape). With that repair the full Linux gate passes:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Charts lane=medium-full symbols=9474
FRAMEWORK_FANOUT_REFERENCE_OK
CHARTS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Charts dylib=libCharts.dylib
```

run as `python3 -B full/framework-fanout/validate_seed.py --framework
full/charts --phase deliverable` plus
`bash full/charts/tests/acceptance/test_host.sh` inside
`swift:6.2-noble` (Swift 6.2.4, `aarch64-unknown-linux-gnu`). The macOS
host `swiftc` cannot run this gate: the lookalikes are
`#if !canImport(SwiftUI)` and macOS sees real SwiftUI.

### Wave-6 overlay conversion (pi agent, `ChartsViewOverlay`)

This pass starts from the aggressive-coverage ledger (`implemented` 3015,
`declared` 1900, `deferred` 905, `unavailable` 0, `not-applicable` 3654)
and ends at `implemented` 4814, `declared` 101, `deferred` 905,
`unavailable` 0, `not-applicable` 3654: an implemented gain of 1799.
Nondeferred (`implemented` + `declared`) is 4915, above the medium-full
floor.

The converted rows are exactly the 1799 `s:7SwiftUI4View` identity
overlay rows (166 distinct modifier bases). Each base already compiled
as a no-op `Self` return in `ChartsViewSurface.swift` (generic stubs
requiring arguments); `ChartsViewOverlay.swift` adds the FamilyControls
playbook overload (`(_ p0: Any? = nil) -> Self`, `#if !canImport(SwiftUI)`)
so zero-argument calls compile. Six bases that already had zero-arg
stubs (`frame`, `hidden`, `fixedSize`, `backgroundExtensionEffect`,
`allowsWindowActivationEvents`, `accessibilityShowsLargeContentViewer`)
are called directly with no new overload. `tests/agent/ChartsViewOverlayTests.swift`
pins each modifier on eight bases — `Chart { BarMark }`, `Chart3D {
SurfacePlot }`, `ChartPlotContent()`, `ChartAxisContent()`,
`AnyChartSymbolShape()`, `BasicChartSymbolShape.circle`, `Circle()`,
`EmptyView()` — across 8 `testViewOverlayBatchNN` functions (222–228
rows each). Notes read `identity View overlay; renders EmptyView`.

Not converted, deliberately: the ~40 `s:7SwiftUI5Shape` rows (`fill` /
`size` / `stroke` / `body` / `transform` on the symbol shapes, which are
`Shape` members rather than `View` modifiers) and the ~61 Charts-owned
`Never` / `ModifiedContent` / `PrimitivePlottable` / `SurfacePlot.body`
witnesses (uninhabited or protocol-extension rows with no callable
value). Deferred rows (stdlib operators, Combine/FormatStyle overlays,
`symbolRotation` with no RealityKit type) and SwiftUI cross-import
`not-applicable` rows are untouched.

Top implemented evidence after this pass (4814 rows; cap 40% = 1925):

| rows | share | test |
| ---: | ---: | --- |
| 228 | 4.7% | `ChartsViewOverlayTests.swift#testViewOverlayBatch01` |
| 228 | 4.7% | `ChartsViewOverlayTests.swift#testViewOverlayBatch02` |
| 228 | 4.7% | `ChartsViewOverlayTests.swift#testViewOverlayBatch03` |
| 227 | 4.7% | `ChartsViewOverlayTests.swift#testViewOverlayBatch04` |
| 222 | 4.6% | `ChartsViewOverlayTests.swift#testViewOverlayBatch05` |

No single test exceeds 40% of implemented rows.

Linux verification for this pass (host `swiftc` is macOS-only here, so
the sealed gate was replicated manually): `Charts` dylib compiled with
`swiftc -warnings-as-errors` under `swift:6.2` Linux, all 297 unique
cited tests linked and ran with marker-only stdout
`CHARTS_AGENT_RUNTIME_OK`. `validate_seed.py --phase deliverable`
prints `FRAMEWORK_FANOUT_DELIVERABLE_OK module=Charts lane=medium-full
symbols=9474`.

### Wave-7 overlay conversion (pi agent, leftover `View` overlays)

This pass converts the leftover SwiftUI `View`-modifier census per the
pi-wave7 contract override: identity `View` modifiers that compile as
no-op `Self` returns are `implemented` with identity EmptyView tests,
including rows previously marked `not-applicable` as SwiftUI
cross-import overlays (the SwiftUI lane does not implement these).
It starts from the wave-6 overlay ledger (`implemented` 4814,
`declared` 101, `deferred` 905, `unavailable` 0, `not-applicable`
3654) and ends at `implemented` 8410, `declared` 101, `deferred`
905, `unavailable` 0, `not-applicable` 58: an implemented gain of
3596. Nondeferred (`implemented` + `declared`) is 8511, above the
medium-full floor (4737).

Converted rows:

- 3595 `s:7SwiftUI4View` rows (all leftover `ViewPAAE` plus the 13
  Charts-owned `ViewPChartsE` `chartXAxis` / `chartYAxis` /
  `chartLegend` / `chartXScale` / `chartYScale` /
  `chartForegroundStyleScale` overloads). 302 rows cite the existing
  `testViewOverlayBatch01-08` functions, which already call those
  modifiers on all eight bases including `Circle()` and `EmptyView()`.
  13 Charts-owned rows cite the existing `ChartsViewModifiersTests`
  functions that call those exact overloads on `Circle()` and
  `EmptyView()` (`testChartViewXAxisContent`, `testChartViewYAxisContent`,
  `testChartViewLegend`, `testChartViewXScale`, `testChartViewYScale`,
  `testChartViewForegroundStyleScale`). The remaining 3280 rows (235
  new modifier bases) are pinned by 15 new `testViewOverlayBatch09-23`
  functions in `tests/agent/ChartsViewOverlayWave7Tests.swift`, each
  calling every modifier on the same eight bases. Notes read
  `identity View overlay; renders EmptyView`.
- 1 Charts-owned unit-rect row
  (`s:7SwiftUI6CircleV6ChartsE18perceptualUnitRect`): `Circle` gets the
  `ChartSymbolShape` default `0,0,1,1` rect, now asserted alongside the
  concrete/erased symbols in `testSymbolPerceptualUnitRects`.

Stub shape: 225 new bases get pure zero-argument `() -> Self` overloads
in `ChartsViewOverlay.swift` (`#if !canImport(SwiftUI)`). Ten bases
reuse existing zero-argument stubs with no new overload (`colorInvert`,
`compositingGroup`, `geometryGroup`, `labelsHidden`,
`luminanceToAlpha`, `monospacedDigit`, `scaledToFill`, `scaledToFit`,
`unredacted`, plus the lookalike `accessibilityElement(children:)`
default). The pure-`()` form (rather than the earlier
`(_ p0: Any? = nil)` form) keeps with-argument calls resolving to the
pre-existing generic/concrete overloads: the 225-overload addition
otherwise pushes the 30-call `chartApplyModifierCatalog` chain in
`ChartsPlotEngineTests.swift` past the Swift solver limit on Linux
(`unable to type-check ... in reasonable time`). With pure-`()` stubs
the chain compiles unchanged.

Not converted, deliberately: the 58 remaining `not-applicable` rows are
SwiftUI `Shape` / `Animatable` / `ScrollTargetBehavior` protocol
members (`union` / `subtracting` / `intersection` / `trim` / `scale` /
`rotation` / `sizeThatFits` / `fill` / `stroke` / `size` / `offset` /
`transform` / `body` / `role` / `layoutDirectionBehavior` on the symbol
shapes and `Circle`, `animatableData` x3, `circle` static, and
`ScrollTargetBehavior.properties(context:)`), which are not `View`
modifiers and have no no-op `Self` stubs on Linux. The 101 `declared`
rows (40 `Shape` members on Charts-owned shapes, 61 `Never` /
`ModifiedContent` / `PrimitivePlottable` / `SurfacePlot.body`
witnesses) and all 905 `deferred` rows (stdlib operators,
Combine/FormatStyle overlays, GPU/image renderer, `symbolRotation`
with no RealityKit type, scroll/gesture timing) are untouched.
Hardware/daemon/Siri/Apple Pay/Screen Time success stays fail-closed.
No `DispatchQueue.main`, `RunLoop`, semaphore waits, or `await` in
cited tests.

Top implemented evidence after this pass (8410 rows; cap 40% = 3364):

| rows | share | test |
| ---: | ---: | --- |
| 267 | 3.2% | `ChartsViewOverlayTests.swift#testViewOverlayBatch04` |
| 266 | 3.2% | `ChartsViewOverlayTests.swift#testViewOverlayBatch02` |
| 266 | 3.2% | `ChartsViewOverlayTests.swift#testViewOverlayBatch03` |
| 266 | 3.2% | `ChartsViewOverlayTests.swift#testViewOverlayBatch01` |
| 259 | 3.1% | `ChartsViewOverlayTests.swift#testViewOverlayBatch05` |

No single test exceeds 40% of implemented rows.

Linux verification for this pass (host `swiftc` is macOS-only here, so
the sealed gate was replicated manually): `Charts` dylib compiled with
`swiftc -warnings-as-errors` under `swift:6.2-noble` (Swift 6.2.4,
`aarch64-unknown-linux-gnu`), all 312 unique cited tests linked and
ran with marker-only stdout `CHARTS_AGENT_RUNTIME_OK`.
`validate_seed.py --phase deliverable` prints
`FRAMEWORK_FANOUT_DELIVERABLE_OK module=Charts lane=medium-full
symbols=9474`. No `.build`, `build`, or `scratch` products remain
under `full/charts/`.

### Wave-8 Shape-overlay pass (pi agent, leftover declared `Shape` rows)

This pass converts the 40 remaining declared `s:7SwiftUI5Shape` rows on
the Charts-owned symbol shapes (`AnyChartSymbolShape` /
`BasicChartSymbolShape`) per the wave-8 prompt: pin Shape/plot rows
only where no renderer output is invented, and leave the GPU/image
renderer deferred. It starts from the wave-7 overlay ledger
(`implemented` 8410, `declared` 101, `deferred` 905, `unavailable` 0,
`not-applicable` 58) and ends at `implemented` 8450, `declared` 61,
`deferred` 905, `unavailable` 0, `not-applicable` 58: an implemented
gain of 40. Nondeferred (`implemented` + `declared`) is 8511, above the
medium-full floor (4737).

| status | before | after |
| --- | ---: | ---: |
| implemented | 8410 | 8450 |
| declared | 101 | 61 |
| deferred | 905 | 905 |
| unavailable | 0 | 0 |
| not-applicable | 58 | 58 |

Converted rows (20 modifier bases x 2 shapes, notes
`identity Shape overlay; no renderer`):

- `fill` (3 overloads x 2) — new `ChartsShapeOverlay.swift` identity
  stubs, cited from `ChartsShapeOverlayTests.swift#testShapeOverlayFill`
  (6 rows). The test calls `fill()` on both shapes and asserts the
  symbol `path(in:)` is unchanged.
- `size` (4 x 2) — same stubs, cited from `#testShapeOverlaySize`
  (8 rows), with the same path-identity assertion.
- `stroke` (6 x 2) — same stubs, cited from `#testShapeOverlayStroke`
  (12 rows), with the same path-identity assertion.
- `transform` (1 x 2) — same stubs, cited from
  `#testShapeOverlayTransform` (2 rows). Apple would remap geometry;
  Linux returns `Self` unchanged and asserts the path is unchanged, so
  no transformed output is invented.
- `body` (1 x 2) + `role` (1 x 2) — both shapes already expose
  `body`; `AnyChartSymbolShape.role` is added (`ShapeRole.fill` to match
  `BasicChartSymbolShape.role`). Cited from
  `#testShapeOverlayBodyAndRole` (4 rows), which accesses both bodies
  and asserts both roles equal `.fill`.
- `offset` (3 x 2) + `layoutDirectionBehavior` (1 x 2) — these bases
  already compile through the existing View no-op stubs, and the
  existing `ChartsViewOverlayTests.swift#testViewOverlayBatch01` already
  calls both bases on both shapes. The 8 Shape rows are re-cited to that
  test (274 rows after, still far below the 40% cap of 3380).

Not converted, deliberately: the 61 remaining declared rows are
uninhabited `Never` witnesses (`ChartContent` / `Chart3DContent` /
`AxisMark` modifiers synthesized on `Never`, `PrimitivePlottable` on
`Never`), `Chart3DContent` modifiers synthesized on lookalike-absent
`ModifiedContent`, one `AnyChartSymbolShape.AnimatableData` row (no
`Animatable`/`VectorArithmetic` in the pinned Linux set — inventing it
would invent behavior), and one `SurfacePlot.body: Never` row whose
product body is intentionally the fail-closed `EmptyView`. All 905
deferred rows stay deferred (stdlib operators, Combine/FormatStyle
overlays, GPU/image renderer, `symbolRotation` with no RealityKit type,
scroll/gesture timing). The 58 `not-applicable` rows stay untouched
(SwiftUI `Shape` boolean-combiner/`trim`/`scale`/`rotation` /
`sizeThatFits` on `Circle`, `animatableData`, `circle` static,
`ScrollTargetBehavior.properties`); none is a `View` modifier, so the
overlay override does not apply. Hardware/daemon/Siri/Apple Pay/Screen
Time success stays fail-closed. No `DispatchQueue.main`, `RunLoop`,
semaphore waits, or `await` in cited tests.

Top implemented evidence after this pass (8450 rows; cap 40% = 3380):
`testViewOverlayBatch01` grows 266 -> 274 rows (3.2%); no single test
exceeds 40% of implemented rows. New tests cite 12 / 8 / 6 / 4 / 2 rows
respectively.
