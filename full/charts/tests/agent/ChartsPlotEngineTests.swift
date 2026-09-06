import Foundation
@_spi(OpenUIKitHost) import Charts

private func chartApplyModifierCatalog<C: ChartContent>(_ content: C) -> some ChartContent {
    let offsetXY: _ChartAttributedPlotContent = content.offset(x: 10.0, y: 4.0)
    let offsetSize: _ChartAttributedPlotContent = offsetXY.offset(CGSize(width: 1.0, height: 0.0))
    return offsetSize
        .offset(x: 0.0, yStart: 2.0, yEnd: 3.0)
        .offset(xStart: 1.0, xEnd: 2.0, y: 0.0)
        .offset(xStart: 0.0, xEnd: 0.0, yStart: 0.0, yEnd: 1.0)
        .symbolSize(by: .value("size", 4))
        .symbolSize(12.0)
        .symbolSize(CGSize(width: 3.0, height: 3.0))
        .cornerRadius(3.0, style: .continuous)
        .foregroundStyle(Color.blue)
        .foregroundStyle(by: .value("series", "one"))
        .compositingLayer()
        .compositingLayer { _ in Color.blue }
        .accessibilityLabel(LocalizedStringResource("label"))
        .accessibilityLabel(LocalizedStringKey("key"))
        .accessibilityLabel(Text("text"))
        .accessibilityLabel("string")
        .accessibilityValue(LocalizedStringResource("value"))
        .accessibilityValue(LocalizedStringKey("vkey"))
        .accessibilityValue(Text("vtext"))
        .accessibilityValue("vstring")
        .accessibilityHidden(true)
        .accessibilityIdentifier("id")
        .interpolationMethod(.monotone)
        .alignsMarkStylesWithPlotArea(true)
        .blur(radius: 1.0)
        .mask { RectangleMark(xStart: .value("a", 0), xEnd: .value("b", 1), yStart: .value("c", 0), yEnd: .value("d", 1)) }
        .shadow(radius: 2.0)
        .symbol(by: .value("sym", "circle"))
        .symbol { Circle() }
        .symbol(BasicChartSymbolShape.square)
        .zIndex(3.0)
        .opacity(0.5)
        .position(by: .value("pos", 1), axis: .horizontal, span: .automatic)
        .clipShape(Circle(), style: FillStyle())
        .lineStyle(by: .value("stroke", "dash"))
        .lineStyle(StrokeStyle(lineWidth: 2.0, dash: [2.0, 2.0]))
        .annotation(position: .top, alignment: .center, spacing: 4.0) { Text("ann") }
        .annotation(position: .overlay, alignment: .center, spacing: 1.0, overflowResolution: AnnotationOverflowResolution()) { Text("ann2") }
}

func testInferredLinearNiceDomainPixels() {
    let chart = Chart {
        LineMark(x: .value("x", 0.2), y: .value("y", 0.2))
        LineMark(x: .value("x", 9.7), y: .value("y", 9.7))
    }
    let plot = CGRect(x: 0, y: 0, width: 100, height: 40)
    let xScale = chart.resolvedXScale(plotArea: plot)
    precondition(xScale.domainMin == 0)
    precondition(xScale.domainMax == 10)
    let proxy = chart.resolvedProxy(plotArea: plot)
    precondition(abs((proxy.position(forX: 0) ?? -1) - 0) < 0.0001)
    precondition(abs((proxy.position(forX: 10) ?? -1) - 100) < 0.0001)
    precondition(abs((proxy.position(forX: 5) ?? -1) - 50) < 0.0001)
}

func testPointMarkOffsetPixelsFixedPlot() {
    let chart = Chart {
        PointMark(x: .value("x", 5), y: .value("y", 2))
            .offset(x: 10.0, y: 5.0)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let point = placed.first { $0.kind == .point }
    precondition(abs((point?.points.first?.x ?? -1) - 60) < 0.0001)
    precondition(abs((point?.points.first?.y ?? -1) - 25) < 0.0001)
}

func testBarMarkOffsetPixelsFixedPlot() {
    let chart = Chart {
        BarMark(x: .value("x", 5), y: .value("y", 2), stacking: .unstacked)
            .offset(x: 8.0, y: 0.0)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let bar = placed.first { $0.kind == .bar }
    let unoffset = Chart {
        BarMark(x: .value("x", 5), y: .value("y", 2), stacking: .unstacked)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    .placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let base = unoffset.first { $0.kind == .bar }
    precondition(abs((bar?.frame.minX ?? -1) - ((base?.frame.minX ?? 0) + 8)) < 0.0001)
}

func testLineMarkOffsetPixelsFixedPlot() {
    let chart = Chart {
        LineMark(x: .value("x", 0), y: .value("y", 0))
            .offset(x: 5.0, y: 3.0)
        LineMark(x: .value("x", 10), y: .value("y", 4))
            .offset(x: 5.0, y: 3.0)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let line = placed.first { $0.kind == .line }
    precondition(abs((line?.points.first?.x ?? -1) - 5) < 0.0001)
    precondition(abs((line?.points.first?.y ?? -1) - 43) < 0.0001)
    precondition(abs((line?.points.last?.x ?? -1) - 105) < 0.0001)
    precondition(abs((line?.points.last?.y ?? -1) - 3) < 0.0001)
}

func testAreaMarkOffsetPixelsFixedPlot() {
    let chart = Chart {
        AreaMark(x: .value("x", 0), y: .value("y", 0), stacking: .unstacked)
            .offset(x: 2.0, y: 1.0)
        AreaMark(x: .value("x", 10), y: .value("y", 4), stacking: .unstacked)
            .offset(x: 2.0, y: 1.0)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let area = placed.first { $0.kind == .area }
    precondition(abs((area?.points.first?.x ?? -1) - 2) < 0.0001)
}

func testRuleMarkOffsetPixelsFixedPlot() {
    let chart = Chart {
        RuleMark(x: .value("x", 5))
            .offset(x: 4.0, y: 0.0)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let rule = placed.first { $0.kind == .rule }
    precondition(abs((rule?.points.first?.x ?? -1) - 54) < 0.0001)
}

func testRectangleMarkOffsetPixelsFixedPlot() {
    let chart = Chart {
        RectangleMark(
            xStart: .value("a", 0),
            xEnd: .value("b", 10),
            yStart: .value("lo", 0),
            yEnd: .value("hi", 4)
        )
        .offset(xStart: 5.0, xEnd: -5.0, yStart: 0.0, yEnd: 0.0)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let rect = placed.first { $0.kind == .rectangle }
    precondition(abs((rect?.frame.minX ?? -1) - 5) < 0.0001)
    precondition(abs((rect?.frame.width ?? -1) - 90) < 0.0001)
}

func testChartContentProtocolModifiers() {
    let marked = chartApplyModifierCatalog(
        LineMark(x: .value("x", 1), y: .value("y", 2))
    )
    let record = marked.chartPlotRecords[0]
    precondition(record.layout.offsetX == 11)
    precondition(record.layout.offsetY == 4)
    precondition(record.layout.symbolSize == 9)
    precondition(record.layout.cornerRadius == 3)
    precondition(record.foregroundStyleName != nil)
    precondition(record.layout.accessibilityLabel == "string")
    precondition(record.layout.accessibilityValue == "vstring")
    precondition(record.layout.accessibilityHidden == true)
    precondition(record.layout.accessibilityIdentifier == "id")
    precondition(record.layout.blurRadius == 1)
    precondition(record.layout.shadowRadius == 2)
    precondition(record.layout.zIndex == 3)
    precondition(record.opacity == 0.5)
    precondition(record.layout.clipShapeName != nil)
    precondition(record.annotationPosition == "overlay")
}

func testBarMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        BarMark(x: .value("x", "A"), y: .value("y", 3), stacking: .unstacked)
    )
    precondition(marked.chartPlotRecords[0].layout.offsetX == 11)
    precondition(marked.chartPlotRecords[0].opacity == 0.5)
}

func testLineMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        LineMark(x: .value("x", 1), y: .value("y", 2), series: .value("s", "one"))
    )
    precondition(marked.chartPlotRecords[0].layout.cornerRadius == 3)
    precondition(marked.chartPlotRecords[0].interpolation == .monotone)
}

func testPointMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        PointMark(x: .value("x", 1), y: .value("y", 2))
    )
    precondition(marked.chartPlotRecords[0].layout.symbolSize == 9)
}

func testAreaMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        AreaMark(x: .value("x", 1), y: .value("y", 2), stacking: .unstacked)
    )
    precondition(marked.chartPlotRecords[0].layout.zIndex == 3)
}

func testRuleMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(RuleMark(x: .value("x", 1)))
    precondition(marked.chartPlotRecords[0].lineWidth == 2)
}

func testRectangleMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        RectangleMark(
            xStart: .value("a", 0),
            xEnd: .value("b", 1),
            yStart: .value("c", 0),
            yEnd: .value("d", 2)
        )
    )
    precondition(marked.chartPlotRecords[0].layout.offsetXStart == 1)
}

func testSectorMarkChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        SectorMark(angle: .value("share", 0.5))
    )
    precondition(marked.chartPlotRecords[0].layout.accessibilityIdentifier == "id")
}

func testBarPlotChartContentModifiers() {
    struct Row { var name: String; var value: Int }
    let plot = BarPlot(
        [Row(name: "A", value: 2)],
        x: .value("x", \.name),
        y: .value("y", \.value)
    )
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.offsetX == 11)
}

func testLinePlotChartContentModifiers() {
    struct Row { var x: Double; var y: Double }
    let plot = LinePlot([Row(x: 1, y: 2)], x: .value("x", \.x), y: .value("y", \.y))
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].opacity == 0.5)
}

func testPointPlotChartContentModifiers() {
    struct Row { var x: Double; var y: Double }
    let plot = PointPlot([Row(x: 1, y: 2)], x: .value("x", \.x), y: .value("y", \.y))
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.symbolBy == "size" || marked.chartPlotRecords[0].layout.symbolBy == "sym")
}

func testAreaPlotChartContentModifiers() {
    struct Row { var x: Double; var y: Double }
    let plot = AreaPlot([Row(x: 1, y: 2)], x: .value("x", \.x), y: .value("y", \.y))
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.blurRadius == 1)
}

func testRulePlotChartContentModifiers() {
    struct Row { var x: Double }
    let plot = RulePlot([Row(x: 1)], x: .value("x", \.x))
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.lineStyleBy == "stroke")
}

func testRectanglePlotChartContentModifiers() {
    struct Row { var a: Double; var b: Double; var c: Double; var d: Double }
    let plot = RectanglePlot(
        [Row(a: 0, b: 1, c: 0, d: 2)],
        xStart: .value("a", \.a),
        xEnd: .value("b", \.b),
        yStart: .value("lo", \.c),
        yEnd: .value("hi", \.d)
    )
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.cornerRadius == 3)
}

func testSectorPlotChartContentModifiers() {
    struct Row { var share: Double }
    let plot = SectorPlot([Row(share: 1)], angle: .value("a", \.share))
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.zIndex == 3)
}

func testAnyChartContentModifiers() {
    let marked = chartApplyModifierCatalog(
        AnyChartContent(LineMark(x: .value("x", 1), y: .value("y", 2)))
    )
    precondition(marked.chartPlotRecords[0].layout.offsetX == 11)
}

func testBuilderConditionalChartContentModifiers() {
    let conditional = BuilderConditional<LineMark, BarMark>(
        storage: .first(LineMark(x: .value("x", 1), y: .value("y", 2)))
    )
    let marked = chartApplyModifierCatalog(conditional)
    precondition(marked.chartPlotRecords[0].opacity == 0.5)
}

func testPlotChartContentModifiers() {
    let plot = Plot {
        PointMark(x: .value("x", 1), y: .value("y", 2))
    }
    precondition(plot.chartPlotRecords.count == 1)
    let marked = chartApplyModifierCatalog(plot)
    precondition(marked.chartPlotRecords[0].layout.offsetY == 4)
}

func testForEachChartContentModifiers() {
    struct Row: Hashable { var name: String; var value: Int }
    let marked = chartApplyModifierCatalog(
        ForEach([Row(name: "A", value: 1)], id: \.self) { row in
            BarMark(x: .value("x", row.name), y: .value("y", row.value), stacking: .unstacked)
        }
    )
    precondition(marked.chartPlotRecords[0].layout.offsetX == 11)
}

func testOptionalChartContentModifiers() {
    let mark: LineMark? = LineMark(x: .value("x", 1), y: .value("y", 2))
    let marked = chartApplyModifierCatalog(mark)
    precondition(marked.chartPlotRecords[0].layout.offsetX == 11)
}

func testVectorizedBarPlotContentModifiers() {
    let content = VectorizedBarPlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .bar, x: 1, y: 2)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].layout.shadowRadius == 2)
}

func testVectorizedLinePlotContentModifiers() {
    let content = VectorizedLinePlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .line, x: 1, y: 2)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].interpolation == .monotone)
}

func testVectorizedAreaPlotContentModifiers() {
    let content = VectorizedAreaPlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .area, x: 1, y: 2)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].layout.maskName == "mask")
}

func testVectorizedRulePlotContentModifiers() {
    let content = VectorizedRulePlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .rule, x: 1)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].layout.compositing == "style")
}

func testVectorizedPointPlotContentModifiers() {
    let content = VectorizedPointPlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .point, x: 1, y: 2)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].layout.symbolSize == 9)
}

func testVectorizedSectorPlotContentModifiers() {
    let content = VectorizedSectorPlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .sector, angle: 1)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].layout.positionBy != nil)
}

func testVectorizedRectanglePlotContentModifiers() {
    let content = VectorizedRectanglePlotContent<[Int]>(
        records: [ChartPlotRecord(kind: .rectangle, xStart: 0, xEnd: 1, yStart: 0, yEnd: 1)]
    )
    let marked = chartApplyModifierCatalog(content)
    precondition(marked.chartPlotRecords[0].layout.alignsMarkStyles == true)
}

func testFunctionAreaPlotContentModifiers() {
    let marked = chartApplyModifierCatalog(FunctionAreaPlotContent())
    precondition(marked.chartPlotRecords.isEmpty)
}

func testFunctionLinePlotContentModifiers() {
    let marked = chartApplyModifierCatalog(FunctionLinePlotContent())
    precondition(marked.chartPlotRecords.isEmpty)
}

func testAxisMarkBuilderAndModifiers() {
    let empty = AxisMarkBuilder.buildBlock()
    _ = empty
    let tick = AxisTick()
    let built = AxisMarkBuilder.buildBlock(tick)
    precondition(type(of: built) == AxisTick.self)
    let either = AxisMarkBuilder.buildEither(first: AxisGridLine()) as BuilderConditional<AxisGridLine, AxisValueLabel<Text>>
    _ = AxisMarkBuilder.buildEither(second: AxisValueLabel("A")) as BuilderConditional<AxisGridLine, AxisValueLabel<Text>>
    _ = either
    let optional = AxisMarkBuilder.buildIf(AxisTick() as AxisTick?)
    precondition(optional != nil)
    _ = AxisMarkBuilder.buildExpression(AxisGridLine())
    let styled = AxisGridLine().foregroundStyle(Color.blue)
    precondition(styled.foregroundStyleName != nil)
    let offsetGrid: _AxisMarkAttributed<AxisGridLine> = AxisGridLine().offset(x: 1.0, y: 2.0)
    precondition(offsetGrid.offsetX == 1)
    precondition(offsetGrid.offsetY == 2)
    let sized: _AxisMarkAttributed<AxisTick> = AxisTick().offset(CGSize(width: 3.0, height: 4.0))
    precondition(sized.offsetX == 3)
    let label = AxisValueLabel("A").foregroundStyle(Color.blue)
    precondition(label.foregroundStyleName != nil)
    let anyMark = AxisMarkBuilder.buildLimitedAvailability(AxisTick())
    _ = anyMark
    let content = AxisContentBuilder.buildBlock(AxisMarks())
    _ = AxisContentBuilder.buildExpression(content)
    _ = AxisContentBuilder.buildIf(AxisMarks() as AxisMarks<_EmptyAxisMark>?)
    _ = AxisContentBuilder.buildLimitedAvailability(AxisMarks())
}

func testOptionalAxisMarkModifiers() {
    let tick: AxisTick? = AxisTick()
    let marked: _AxisMarkAttributed<AxisTick?> = tick.foregroundStyle(Color.blue)
    precondition(marked.foregroundStyleName != nil)
    let offset: _AxisMarkAttributed<AxisTick?> = tick.offset(x: 2.0, y: 1.0)
    precondition(offset.offsetX == 2)
    let missing: AxisGridLine? = nil
    _ = missing.font(.body)
}

func testAxisValueLabelFontAndOffset() {
    let marked = AxisValueLabel("tick").font(.caption)
    precondition(marked.fontName != nil)
    let offset: _AxisMarkAttributed<AxisValueLabel<Text>> = AxisValueLabel("tick").offset(x: 2.0, y: -1.0)
    precondition(offset.offsetX == 2)
    _ = AnyAxisMark(AxisTick()).foregroundStyle(Color.blue)
    _ = AnyAxisMark(AxisTick()).font(.body)
}

func testMarkDimensionFixedAndRatio() {
    let fixed = MarkDimension.fixed(8)
    precondition(fixed.kind == "fixed")
    precondition(fixed.value == 8)
    let ratio = MarkDimension.ratio(0.5)
    precondition(ratio.kind == "ratio")
    let fromInt: MarkDimension = 4
    precondition(fromInt.kind == "fixed")
    let fromFloat: MarkDimension = 1.5
    precondition(fromFloat.kind == "fixed")
    let dims = MarkDimensions<Int>.fixed(10)
    precondition(dims.value == 10)
    let ratioDims = MarkDimensions<Int>.ratio(0.25)
    precondition(ratioDims.kind == "ratio")
    let auto = MarkDimensions<Int>.automatic
    precondition(auto.kind == "automatic")
}

func testAnnotationCornerPositions() {
    precondition(AnnotationPosition.topTrailing.description == "topTrailing")
    precondition(AnnotationPosition.bottomLeading.description == "bottomLeading")
    precondition(AnnotationPosition.topLeading.description == "topLeading")
    precondition(AnnotationPosition.bottomTrailing.description == "bottomTrailing")
    _ = AnnotationOverflowResolution.Strategy.fit
    _ = AnnotationOverflowResolution.Strategy.padScale
    _ = AnnotationOverflowResolution.Strategy.fit(to: .plot)
}

func testPlotCollectsMarks() {
    let plot = Plot {
        BarMark(x: .value("x", "A"), y: .value("y", 2), stacking: .unstacked)
        LineMark(x: .value("x", 1), y: .value("y", 3))
    }
    precondition(plot.chartPlotRecords.count == 2)
    precondition(plot.chartPlotRecords[0].kind == .bar)
    precondition(plot.chartPlotRecords[1].kind == .line)
}
