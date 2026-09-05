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
`roughness` / `symbolRotation`). The 464 `not-applicable` rows are
unchanged.

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

After this pass:

| status | wave 8 |
| --- | ---: |
| implemented | 689 |
| declared | 6845 |
| deferred | 660 |
| not-applicable | 1280 |

Nondeferred (`implemented` + `declared`) is 7534, above the 4737 floor.
All 272 `VectorizedChartContent` census rows are `implemented` with
per-method tests that call the identifier on every conforming plot
type. SwiftUI `View` overlay re-exports (`s:7SwiftUI4View…`) are
`not-applicable` with the note `SwiftUI cross-import overlay; owned by
the SwiftUI lane` — never `implemented`.

Top-5 implemented evidence after this pass:

| rows | share | test |
| ---: | ---: | --- |
| 45 | 6.5% | `ChartsWave8Tests.swift#testVectorizedAccessibilityLabel` |
| 45 | 6.5% | `ChartsWave8Tests.swift#testVectorizedAccessibilityValue` |
| 38 | 5.5% | `ChartsTests.swift#testPrimitivePlottable` |
| 30 | 4.4% | `ChartsWave8Tests.swift#testVectorizedSymbolSizeKeyPath` |
| 30 | 4.4% | `ChartsWave8Tests.swift#testVectorizedAccessibilityHiddenAndIdentifier` |

No single non-catalog test exceeds 40% of implemented rows.

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

## Wave-6 deliverable gate

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/charts --phase deliverable
bash full/charts/tests/acceptance/test_host.sh
```

`tests/agent/ChartsRuntime.swift` records the runtime contract the focused
tests exercise. `tests/agent/ChartsLoadSmoke.swift` is the canonical
schema-v2 import/marker source.
