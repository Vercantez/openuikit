import Foundation
@_spi(OpenUIKitHost) import Charts

func testLinePlotFunctionStringPixels() {
    let plot = LinePlot(x: "x", y: "y", domain: 0...10, function: { $0 * 2 })
    precondition(plot.chartPlotRecords.count == 11)
    precondition(plot.chartPlotRecords[0].x == 0)
    precondition(plot.chartPlotRecords[0].y == 0)
    precondition(plot.chartPlotRecords[5].x == 5)
    precondition(plot.chartPlotRecords[5].y == 10)
    precondition(plot.chartPlotRecords[10].x == 10)
    precondition(plot.chartPlotRecords[10].y == 20)
    let chart = Chart { plot }
        .chartXScale(domain: 0...10)
        .chartYScale(domain: 0...20)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let line = placed.first { $0.kind == .line }
    precondition(abs((line?.points.first?.x ?? -1) - 0) < 0.0001)
    precondition(abs((line?.points.first?.y ?? -1) - 40) < 0.0001)
    let mid = line?.points.first { abs($0.x - 50) < 0.0001 }
    precondition(abs((mid?.y ?? -1) - 20) < 0.0001)
    let last = line?.points.last
    precondition(abs((last?.x ?? -1) - 100) < 0.0001)
    precondition(abs((last?.y ?? -1) - 0) < 0.0001)
}

func testLinePlotFunctionText() {
    let plot = LinePlot(x: Text("x"), y: Text("y"), domain: 0...10, function: { $0 })
    precondition(plot.chartPlotRecords.count == 11)
    precondition(plot.chartPlotRecords[10].y == 10)
}

func testLinePlotFunctionLocalizedStringKey() {
    let plot = LinePlot(
        x: LocalizedStringKey("x"),
        y: LocalizedStringKey("y"),
        domain: 0...10,
        function: { $0 + 1 }
    )
    precondition(plot.chartPlotRecords[0].y == 1)
    precondition(plot.chartPlotRecords[10].y == 11)
}

func testLinePlotFunctionLocalizedStringResource() {
    let plot = LinePlot(
        x: LocalizedStringResource("x"),
        y: LocalizedStringResource("y"),
        domain: 0...10,
        function: { $0 * 0.5 }
    )
    precondition(plot.chartPlotRecords[10].y == 5)
}

func testLinePlotParametricStringPixels() {
    let plot = LinePlot(
        x: "x",
        y: "y",
        t: "t",
        domain: 0...10,
        function: { t in (x: t, y: t * 2) }
    )
    precondition(plot.chartPlotRecords.count == 11)
    precondition(plot.chartPlotRecords[5].x == 5)
    precondition(plot.chartPlotRecords[5].y == 10)
    let chart = Chart { plot }
        .chartXScale(domain: 0...10)
        .chartYScale(domain: 0...20)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let line = placed.first { $0.kind == .line }
    precondition(abs((line?.points.last?.x ?? -1) - 100) < 0.0001)
    precondition(abs((line?.points.last?.y ?? -1) - 0) < 0.0001)
}

func testLinePlotParametricText() {
    let plot = LinePlot(
        x: Text("x"),
        y: Text("y"),
        t: Text("t"),
        domain: 0...1,
        function: { t in (x: t, y: 1 - t) }
    )
    precondition(plot.chartPlotRecords[0].y == 1)
    precondition(plot.chartPlotRecords[10].y == 0)
}

func testLinePlotParametricLocalizedStringKey() {
    let plot = LinePlot(
        x: LocalizedStringKey("x"),
        y: LocalizedStringKey("y"),
        t: LocalizedStringKey("t"),
        domain: 0...2,
        function: { t in (x: t, y: t) }
    )
    precondition(plot.chartPlotRecords[10].x == 2)
}

func testLinePlotParametricLocalizedStringResource() {
    let plot = LinePlot(
        x: LocalizedStringResource("x"),
        y: LocalizedStringResource("y"),
        t: LocalizedStringResource("t"),
        domain: 0...4,
        function: { t in (x: t, y: t * t) }
    )
    precondition(plot.chartPlotRecords[10].y == 16)
}

func testAreaPlotFunctionStringPixels() {
    let plot = AreaPlot(x: "x", y: "y", domain: 0...10, function: { $0 * 2 })
    precondition(plot.chartPlotRecords.count == 11)
    precondition(plot.chartPlotRecords[0].kind == .area)
    precondition(plot.chartPlotRecords[5].yStart == 0)
    precondition(plot.chartPlotRecords[5].yEnd == 10)
    let chart = Chart { plot }
        .chartXScale(domain: 0...10)
        .chartYScale(domain: 0...20)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let area = placed.first { $0.kind == .area }
    precondition(abs((area?.points.first?.x ?? -1) - 0) < 0.0001)
    precondition(abs((area?.points.last?.x ?? -1) - 100) < 0.0001)
}

func testAreaPlotFunctionText() {
    let plot = AreaPlot(x: Text("x"), y: Text("y"), domain: 0...10, function: { $0 })
    precondition(plot.chartPlotRecords[10].y == 10)
}

func testAreaPlotFunctionLocalizedStringKey() {
    let plot = AreaPlot(
        x: LocalizedStringKey("x"),
        y: LocalizedStringKey("y"),
        domain: 0...4,
        function: { $0 + 2 }
    )
    precondition(plot.chartPlotRecords[0].y == 2)
}

func testAreaPlotFunctionLocalizedStringResource() {
    let plot = AreaPlot(
        x: LocalizedStringResource("x"),
        y: LocalizedStringResource("y"),
        domain: 0...4,
        function: { $0 }
    )
    precondition(plot.chartPlotRecords.count == 11)
}

func testAreaPlotIntervalFunctionStringPixels() {
    let plot = AreaPlot(
        x: "x",
        yStart: "lo",
        yEnd: "hi",
        domain: 0...10,
        function: { x in (yStart: x, yEnd: x + 4) }
    )
    precondition(plot.chartPlotRecords[0].yStart == 0)
    precondition(plot.chartPlotRecords[0].yEnd == 4)
    precondition(plot.chartPlotRecords[10].yStart == 10)
    precondition(plot.chartPlotRecords[10].yEnd == 14)
    let chart = Chart { plot }
        .chartXScale(domain: 0...10)
        .chartYScale(domain: 0...20)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let area = placed.first { $0.kind == .area }
    // yEnd 4 at x=0 → pixel y = 40 * (1 - 4/20) = 32
    precondition(abs((area?.points.first?.y ?? -1) - 32) < 0.0001)
}

func testAreaPlotIntervalFunctionText() {
    let plot = AreaPlot(
        x: Text("x"),
        yStart: Text("lo"),
        yEnd: Text("hi"),
        domain: 0...1,
        function: { x in (yStart: 0, yEnd: x) }
    )
    precondition(plot.chartPlotRecords[10].yEnd == 1)
}

func testAreaPlotIntervalFunctionLocalizedStringKey() {
    let plot = AreaPlot(
        x: LocalizedStringKey("x"),
        yStart: LocalizedStringKey("lo"),
        yEnd: LocalizedStringKey("hi"),
        domain: 0...2,
        function: { x in (yStart: 1, yEnd: 1 + x) }
    )
    precondition(plot.chartPlotRecords[0].yStart == 1)
}

func testAreaPlotIntervalFunctionLocalizedStringResource() {
    let plot = AreaPlot(
        x: LocalizedStringResource("x"),
        yStart: LocalizedStringResource("lo"),
        yEnd: LocalizedStringResource("hi"),
        domain: 0...2,
        function: { x in (yStart: 0, yEnd: 3) }
    )
    precondition(plot.chartPlotRecords[5].yEnd == 3)
}

func testNilDomainFunctionSamplesUnitInterval() {
    let samples = chartSampleFunctionDomain(nil)
    precondition(samples.count == 11)
    precondition(samples.first == 0)
    precondition(abs((samples.last ?? -1) - 1) < 0.0000001)
}

func testPlotDimensionPaddingPixels() {
    let range = PlotDimensionScaleRange.plotDimension(startPadding: 10, endPadding: 10)
    precondition(range.startPadding == 10)
    precondition(range.endPadding == 10)
    let padded = PlotDimensionScaleRange.plotDimension(padding: 4)
    precondition(padded.startPadding == 4)
    precondition(padded.endPadding == 4)
    let viaProtocol: PlotDimensionScaleRange = .plotDimension(
        startPadding: 10,
        endPadding: 10
    )
    precondition(viaProtocol.startPadding == 10)
    let chart = Chart {
        LineMark(x: .value("x", 0), y: .value("y", 0))
        LineMark(x: .value("x", 10), y: .value("y", 4))
    }
    .chartXScale(domain: 0...10, range: range)
    .chartYScale(domain: 0...4)
    let proxy = chart.resolvedProxy(plotArea: ChartFixedPlotFixture.plotArea)
    precondition(abs((proxy.position(forX: 0) ?? -1) - 10) < 0.0001)
    precondition(abs((proxy.position(forX: 10) ?? -1) - 90) < 0.0001)
    precondition(abs((proxy.position(forX: 5) ?? -1) - 50) < 0.0001)
}

func testPlotDimensionRangeOnlyPixels() {
    let chart = Chart {
        PointMark(x: .value("x", 0), y: .value("y", 0))
        PointMark(x: .value("x", 10), y: .value("y", 4))
    }
    .chartXScale(range: PlotDimensionScaleRange.plotDimension(startPadding: 20, endPadding: 0))
    .chartYScale(domain: 0...4)
    let xScale = chart.resolvedXScale(plotArea: ChartFixedPlotFixture.plotArea)
    // inferred x domain nices 0...10 → 0...10, range 20...100
    precondition(abs(xScale.position(forNumeric: 0) - 20) < 0.0001)
    precondition(abs(xScale.position(forNumeric: 10) - 100) < 0.0001)
}

func testYScalePlotDimensionPaddingPixels() {
    let chart = Chart {
        PointMark(x: .value("x", 5), y: .value("y", 0))
        PointMark(x: .value("x", 5), y: .value("y", 4))
    }
    .chartXScale(domain: 0...10)
    .chartYScale(
        domain: 0...4,
        range: PlotDimensionScaleRange.plotDimension(startPadding: 4, endPadding: 4)
    )
    let proxy = chart.resolvedProxy(plotArea: ChartFixedPlotFixture.plotArea)
    // Y inverted over inset 4...36: y=0 → 36, y=4 → 4, y=2 → 20
    precondition(abs((proxy.position(forY: 0) ?? -1) - 36) < 0.0001)
    precondition(abs((proxy.position(forY: 4) ?? -1) - 4) < 0.0001)
    precondition(abs((proxy.position(forY: 2) ?? -1) - 20) < 0.0001)
}

func testAutomaticScaleDomainIncludesZero() {
    let domain = AutomaticScaleDomain.automatic(includesZero: true, reversed: false)
    precondition(domain.includesZero == true)
    precondition(domain.reversed == false)
    let chart = Chart {
        LineMark(x: .value("x", 2), y: .value("y", 4))
        LineMark(x: .value("x", 8), y: .value("y", 12))
    }
    .chartXScale(domain: domain)
    .chartYScale(domain: 0...12)
    let xScale = chart.resolvedXScale(plotArea: ChartFixedPlotFixture.plotArea)
    precondition(xScale.domainMin == 0)
    precondition(xScale.domainMax == 8 || xScale.domainMax == 10)
    precondition(abs(xScale.position(forNumeric: 0) - 0) < 0.0001)
}

func testAutomaticScaleDomainReversedPixels() {
    let domain = AutomaticScaleDomain.automatic(includesZero: false, reversed: true)
    let chart = Chart {
        LineMark(x: .value("x", 0), y: .value("y", 0))
        LineMark(x: .value("x", 10), y: .value("y", 4))
    }
    .chartXScale(domain: 0...10)
    let forward = chart.resolvedXScale(plotArea: ChartFixedPlotFixture.plotArea)
    precondition(abs(forward.position(forNumeric: 0) - 0) < 0.0001)
    let reversed = Chart {
        LineMark(x: .value("x", 0), y: .value("y", 0))
        LineMark(x: .value("x", 10), y: .value("y", 4))
    }
    .chartXScale(domain: domain)
    let xScale = reversed.resolvedXScale(plotArea: ChartFixedPlotFixture.plotArea)
    precondition(abs(xScale.position(forNumeric: 0) - 100) < 0.0001)
    precondition(abs(xScale.position(forNumeric: 10) - 0) < 0.0001)
}

func testAutomaticScaleDomainModifyInferred() {
    let domain = AutomaticScaleDomain.automatic(
        includesZero: false,
        reversed: false,
        dataType: Double.self
    ) { values in
        values.append(2)
        values.append(8)
    }
    precondition(domain.modifiedDomain == [2, 8])
    let viaProtocol = AutomaticScaleDomain.automatic
    precondition(viaProtocol.modifiedDomain.isEmpty)
    let chart = Chart {
        LineMark(x: .value("x", 0), y: .value("y", 0))
        LineMark(x: .value("x", 10), y: .value("y", 1))
    }
    .chartXScale(domain: domain)
    let xScale = chart.resolvedXScale(plotArea: ChartFixedPlotFixture.plotArea)
    precondition(xScale.domainMin == 2)
    precondition(xScale.domainMax == 8)
    precondition(abs(xScale.position(forNumeric: 2) - 0) < 0.0001)
    precondition(abs(xScale.position(forNumeric: 8) - 100) < 0.0001)
}

func testAnnotationOverflowResolutionCatalog() {
    precondition(AnnotationOverflowResolution.Boundary.automatic != .plot)
    precondition(AnnotationOverflowResolution.Boundary.plot != .chart)
    precondition(AnnotationOverflowResolution.Boundary.chart != .automatic)
    precondition(AnnotationOverflowResolution.Strategy.automatic != .fit)
    precondition(AnnotationOverflowResolution.Strategy.fit != .padScale)
    precondition(AnnotationOverflowResolution.Strategy.padScale != .disabled)
    precondition(AnnotationOverflowResolution.Strategy.disabled != .automatic)
    precondition(AnnotationOverflowResolution.Strategy.fit != .fit(to: .plot))
    precondition(AnnotationOverflowResolution.Strategy.fit(to: .plot) != .fit(to: .chart))
    let mixed = AnnotationOverflowResolution(x: .fit, y: .disabled)
    precondition(mixed.x == .fit)
    precondition(mixed.y == .disabled)
    precondition(AnnotationOverflowResolution.automatic.x == .automatic)
    let _: AnnotationOverflowResolution.Boundary = .plot
    let _: AnnotationOverflowResolution.Strategy = .padScale
}

func testAnnotationOverflowClampPixels() {
    let plot = CGRect(x: 0, y: 0, width: 100, height: 40)
    let fit = AnnotationOverflowResolution(x: .fit, y: .fit)
    let clamped = chartClampAnnotation(point: CGPoint(x: -10, y: 80), plotArea: plot, resolution: fit)
    precondition(clamped.x == 0)
    precondition(clamped.y == 40)
    let disabled = AnnotationOverflowResolution(x: .disabled, y: .disabled)
    let raw = chartClampAnnotation(point: CGPoint(x: -10, y: 80), plotArea: plot, resolution: disabled)
    precondition(raw.x == -10)
    precondition(raw.y == 80)
    let mixed = AnnotationOverflowResolution(x: .fit, y: .disabled)
    let mixedPoint = chartClampAnnotation(
        point: CGPoint(x: 150, y: -5),
        plotArea: plot,
        resolution: mixed
    )
    precondition(mixedPoint.x == 100)
    precondition(mixedPoint.y == -5)
    let padded = chartClampAnnotation(
        point: CGPoint(x: 0, y: 0),
        plotArea: plot,
        resolution: AnnotationOverflowResolution(x: .padScale, y: .padScale)
    )
    precondition(padded.x == 4)
    precondition(padded.y == 4)
    let mark = PointMark(x: .value("x", 0), y: .value("y", 0))
        .annotation(position: .top, overflowResolution: AnnotationOverflowResolution(x: .fit, y: .fit)) {
            Text("a")
        }
    precondition(mark.chartPlotRecords[0].layout.overflowX == "fit")
    precondition(mark.chartPlotRecords[0].layout.overflowY == "fit")
}

func testAnnotationContextOverflowOverload() {
    let mark = PointMark(x: .value("x", 1), y: .value("y", 2))
        .annotation(
            position: .overlay,
            alignment: .center,
            spacing: 2.0,
            overflowResolution: .automatic
        ) { (_: AnnotationContext) in
            Text("ctx")
        }
    precondition(mark.chartPlotRecords[0].annotationPosition == "overlay")
    precondition(mark.chartPlotRecords[0].layout.overflowX == "automatic")
}

func testAnnotationContextOverload() {
    let mark = PointMark(x: .value("x", 1), y: .value("y", 2))
        .annotation(position: .bottom, spacing: 1.0) { (_: AnnotationContext) in
            Text("ctx")
        }
    precondition(mark.chartPlotRecords[0].annotationPosition == "bottom")
}

func testChart3DContentBuilderCollects() {
    let empty = Chart3DContentBuilder.buildBlock()
    _ = empty
    let single = Chart3DContentBuilder.buildBlock(SurfacePlot())
    precondition(type(of: single) == SurfacePlot.self)
    let pair = Chart3DContentBuilder.buildBlock(SurfacePlot(), SurfaceMark())
    precondition(pair.childCount == 2)
    let first = Chart3DContentBuilder.buildEither(first: SurfacePlot()) as BuilderConditional<
        SurfacePlot, SurfaceMark
    >
    switch first.storage {
    case .first: break
    default: preconditionFailure("expected first")
    }
    let second = Chart3DContentBuilder.buildEither(second: SurfaceMark()) as BuilderConditional<
        SurfacePlot, SurfaceMark
    >
    switch second.storage {
    case .second: break
    default: preconditionFailure("expected second")
    }
    let optional = Chart3DContentBuilder.buildOptional(SurfacePlot())
    precondition(type(of: optional) == SurfacePlot.self)
    let expressed = Chart3DContentBuilder.buildExpression(SurfaceMark())
    precondition(type(of: expressed) == SurfaceMark.self)
    let limited = Chart3DContentBuilder.buildLimitedAvailability(SurfacePlot())
    precondition(limited.childCount == 1)
    let chart = Chart3D { SurfacePlot() }
    _ = chart.content
}

func testChart3DCameraProjectionCatalog() {
    precondition(Chart3DCameraProjection.perspective != .orthographic)
    precondition(Chart3DCameraProjection.orthographic != .automatic)
    precondition(Chart3DCameraProjection.automatic != .perspective)
    precondition(Chart3DCameraProjection.perspective == Chart3DCameraProjection.perspective)
    var hasher = Hasher()
    Chart3DCameraProjection.perspective.hash(into: &hasher)
    _ = Chart3DCameraProjection.orthographic.hashValue
    _ = Chart3DCameraProjection.automatic.hashValue
}

func testChartSymbolShapeProtocolCatalog() {
    let shapes: [BasicChartSymbolShape] = [
        .circle, .square, .plus, .cross, .diamond, .asterisk, .pentagon, .triangle,
    ]
    precondition(Set(shapes.map(\.description)).count == 8)
    let viaProtocol: BasicChartSymbolShape = .square
    precondition(viaProtocol == BasicChartSymbolShape.square)
    let stroked = BasicChartSymbolShape.square.strokeBorder(lineWidth: 2)
    let path = stroked.path(in: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(!path.elements.isEmpty)
    let styled = Circle().strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [1, 1]))
    let circlePath = styled.path(in: CGRect(x: 0, y: 0, width: 12, height: 12))
    precondition(!circlePath.elements.isEmpty)
    _ = BasicChartSymbolShape.circle.inset(by: 1)
}

func testChart3DSymbolShapeProtocolCatalog() {
    let shapes: [BasicChart3DSymbolShape] = [.sphere, .cube, .cone, .cylinder]
    precondition(shapes.count == 4)
    let viaProtocol: BasicChart3DSymbolShape = .cone
    precondition(viaProtocol == BasicChart3DSymbolShape.cone)
}

func testSurfacePlotFunctionSamples() {
    let plot = SurfacePlot(x: "x", y: "y", z: "z", function: { x, y in x + y })
    precondition(plot.samples.count == 9)
    precondition(plot.xLabel == "x")
    precondition(plot.samples[0].x == 0)
    precondition(plot.samples[0].y == 0)
    precondition(plot.samples[0].z == 0)
    precondition(plot.samples[8].x == 1)
    precondition(plot.samples[8].y == 1)
    precondition(plot.samples[8].z == 2)
    // 3×3 grid: index 1 is (0.5, 0) → z 0.5
    precondition(abs(plot.samples[1].z - 0.5) < 0.0000001)
}

func testSurfacePlotFunctionText() {
    let plot = SurfacePlot(x: Text("x"), y: Text("y"), z: Text("z"), function: { x, y in x * y })
    precondition(plot.samples[8].z == 1)
}

func testSurfacePlotFunctionLocalizedStringKey() {
    let plot = SurfacePlot(
        x: LocalizedStringKey("x"),
        y: LocalizedStringKey("y"),
        z: LocalizedStringKey("z"),
        function: { x, y in x - y }
    )
    precondition(plot.samples[2].z == 1)
}

func testSurfacePlotFunctionLocalizedStringResource() {
    let plot = SurfacePlot(
        x: LocalizedStringResource("x"),
        y: LocalizedStringResource("y"),
        z: LocalizedStringResource("z"),
        function: { _, _ in 4 }
    )
    precondition(plot.samples.allSatisfy { $0.z == 4 })
}

func testSurfacePlotChart3DContentModifiers() {
    let sized = SurfacePlot().symbolSize(8)
    precondition(sized.symbolSize == 8)
    let byStyle = SurfacePlot().foregroundStyle(by: .value("series", "a"))
    precondition(byStyle.foregroundStyleName == "series")
    let colored = SurfacePlot().foregroundStyle(Color.blue)
    precondition(colored.foregroundStyleName != nil)
    let surface = SurfacePlot().foregroundStyle(BasicChart3DSurfaceStyle())
    precondition(surface.surfaceStyleName != nil)
    let symbol = SurfacePlot().symbol(BasicChart3DSymbolShape.sphere)
    precondition(symbol.symbolName != nil)
    let metal = SurfacePlot().metalness(0.25)
    precondition(metal.metalness == 0.25)
    let rough = SurfacePlot().roughness(0.75)
    precondition(rough.roughness == 0.75)
}

func testSurfaceMarkChart3DContentModifiers() {
    let sized = SurfaceMark().symbolSize(3)
    precondition(sized.symbolSize == 3)
    let metal = SurfaceMark().metalness(1)
    precondition(metal.metalness == 1)
    _ = SurfaceMark().foregroundStyle(Color.blue)
    _ = SurfaceMark().foregroundStyle(by: .value("k", 1))
    _ = SurfaceMark().foregroundStyle(BasicChart3DSurfaceStyle())
    _ = SurfaceMark().symbol(BasicChart3DSymbolShape.cube)
    _ = SurfaceMark().roughness(0)
}

func testValueAlignedScrollTargetStoresUnit() {
    let unit = ValueAlignedChartScrollTargetBehavior(unit: 5, limitBehavior: .never)
    precondition(unit.unitValue == 5)
    precondition(unit.limitBehavior == .never)
    let viaProtocol = ValueAlignedChartScrollTargetBehavior.valueAligned(unit: 2.5)
    precondition(viaProtocol.unitValue == 2.5)
    precondition(ValueAlignedLimitBehavior.automatic != .never)
    precondition(ValueAlignedLimitBehavior.never != .always)
}

func testValueAlignedScrollTargetStoresXYUnits() {
    let both = ValueAlignedChartScrollTargetBehavior(xUnit: 1, yUnit: 2, limitBehavior: .always)
    precondition(both.unitValue == 1)
    precondition(both.yUnitValue == 2)
    let viaProtocol = ValueAlignedChartScrollTargetBehavior.valueAligned(xUnit: 3, yUnit: 4)
    precondition(viaProtocol.unitValue == 3)
    precondition(viaProtocol.yUnitValue == 4)
}

func testValueAlignedScrollTargetStoresXUnitYMatching() {
    var components = DateComponents()
    components.day = 1
    let stored = ValueAlignedChartScrollTargetBehavior(xUnit: 10, yMatching: components)
    precondition(stored.unitValue == 10)
    precondition(stored.yMatching?.day == 1)
    let viaProtocol = ValueAlignedChartScrollTargetBehavior.valueAligned(
        xUnit: 8,
        yMatching: components
    )
    precondition(viaProtocol.yMatching?.day == 1)
}

func testValueAlignedScrollTargetStoresMatching() {
    var components = DateComponents()
    components.month = 6
    let stored = ValueAlignedChartScrollTargetBehavior(matching: components)
    precondition(stored.matching?.month == 6)
    let viaProtocol = ValueAlignedChartScrollTargetBehavior.valueAligned(matching: components)
    precondition(viaProtocol.matching?.month == 6)
}

func testValueAlignedScrollTargetStoresXYMatching() {
    var xComponents = DateComponents()
    xComponents.hour = 3
    var yComponents = DateComponents()
    yComponents.minute = 15
    let stored = ValueAlignedChartScrollTargetBehavior(
        xMatching: xComponents,
        yMatching: yComponents
    )
    precondition(stored.matching?.hour == 3)
    precondition(stored.yMatching?.minute == 15)
    let viaProtocol = ValueAlignedChartScrollTargetBehavior.valueAligned(
        xMatching: xComponents,
        yMatching: yComponents
    )
    precondition(viaProtocol.matching?.hour == 3)
}

func testValueAlignedScrollTargetStoresXMatchingYUnit() {
    var components = DateComponents()
    components.year = 2020
    let stored = ValueAlignedChartScrollTargetBehavior(xMatching: components, yUnit: 7)
    precondition(stored.matching?.year == 2020)
    precondition(stored.yUnitValue == 7)
    let viaProtocol = ValueAlignedChartScrollTargetBehavior.valueAligned(
        xMatching: components,
        yUnit: 9
    )
    precondition(viaProtocol.yUnitValue == 9)
}

func testAxisContentCompositingLayer() {
    let marks = AxisMarks()
    let layered = marks.compositingLayer()
    precondition(layered.compositing == "layer")
    let styled = marks.compositingLayer { _ in Color.blue }
    precondition(styled.compositing == "style")
    let any = AnyAxisContent(marks)
    _ = any.compositingLayer()
    let optional: AxisMarks<_EmptyAxisMark>? = AxisMarks()
    _ = optional.compositingLayer()
}

func testAnyAxisContentErase() {
    let any = AnyAxisContent(AxisMarks())
    _ = any
    let erased = AnyAxisContent(erasing: AxisMarks())
    _ = erased
}
