import Foundation
@_spi(OpenUIKitHost) import Charts

func testPlottableValueInt() {
    let integer = PlottableValue.value("count", 8)
    precondition(integer.label == "count")
    precondition(integer.value == 8)
    precondition(chartEncode(integer.value) == .number(8))
    let floating = PlottableValue.value("ratio", 2.5)
    precondition(floating.value == 2.5)
    let dated = PlottableValue.value("day", Date(timeIntervalSinceReferenceDate: 12))
    precondition(dated.value.timeIntervalSinceReferenceDate == 12)
    let categorical = PlottableValue.value("name", "A")
    precondition(categorical.value == "A")
    precondition(chartEncode(categorical.value) == .category("A"))
}

func testPlottableValueLocalizedFactories() {
    let keyed = PlottableValue.value(LocalizedStringKey("count"), 3)
    precondition(keyed.value == 3)
    let textual = PlottableValue.value(Text("count"), 4)
    precondition(textual.value == 4)
    let resource = PlottableValue.value(LocalizedStringResource("count"), 5)
    precondition(resource.value == 5)
    let ranged = PlottableValue.value("span", 1..<4)
    precondition(ranged.value == 1)
}

func testPlottableValueDateUnitFactory() {
    let dated = PlottableValue.value(
        "day",
        Date(timeIntervalSinceReferenceDate: 20),
        unit: .day
    )
    precondition(dated.value.timeIntervalSinceReferenceDate == 20)
}

func testLinearNiceTicksZeroToTen() {
    let scale = ChartScale.linear(domain: 0...10, range: 0...100)
    precondition(scale.niceTicks(desiredCount: 5) == [0, 2, 4, 6, 8, 10])
    let domain = scale.niceDomain(desiredTicks: 5)
    precondition(domain.min == 0)
    precondition(domain.max == 10)
    let hundreds = ChartScale.linear(domain: 0...100, range: 0...1)
    precondition(hundreds.niceTicks(desiredCount: 5) == [0, 20, 40, 60, 80, 100])
    precondition(ScaleType.linear.description == "linear")
}

func testLogNiceTicks() {
    let scale = ChartScale.log(domain: 1...1000, range: 0...1)
    precondition(scale.niceTicks() == [1, 10, 100, 1000])
    precondition(ScaleType.log != .linear)
}

func testDateScaleMapping() {
    let scale = ChartScale.date(domain: 0...100, range: 0...200)
    precondition(abs(scale.position(forNumeric: 50) - 100) < 0.0001)
    precondition(abs(scale.numericValue(at: 100) - 50) < 0.0001)
    precondition(ScaleType.date != .category)
}

func testCategoryScaleBands() {
    let scale = ChartScale.category(["A", "B", "C"], range: 0...90)
    precondition(scale.bandWidth == 30)
    precondition(scale.position(forCategory: "A") == 15)
    precondition(scale.position(forCategory: "B") == 45)
    precondition(scale.position(forCategory: "C") == 75)
    precondition(scale.categoryValue(at: 10) == "A")
    precondition(scale.categoryValue(at: 44) == "B")
    precondition(scale.categoryValue(at: 80) == "C")
    precondition(ScaleType.category == .categorical)
}

func testScaleTypeCatalog() {
    let types: [ScaleType] = [
        .linear, .log, .date, .category, .categorical, .squareRoot, .symmetricLog,
    ]
    precondition(Set(types).count == 6)
    precondition(ScaleType.linear != .log)
    precondition(ScaleType.date != .category)
    precondition(ScaleType.squareRoot != .linear)
    precondition(ScaleType.power(exponent: 2) != .linear)
    precondition(ScaleType.symmetricLog(slopeAtZero: 1) == .symmetricLog)
    precondition(ScaleType.linear.description == "linear")
}

func testChartProxyResolvedMapping() {
    let xScale = ChartScale.linear(domain: 0...10, range: 0...100)
    let yScale = ChartScale.linear(domain: 0...5, range: 0...50, inverted: true)
    let proxy = ChartProxy(
        xScale: xScale,
        yScale: yScale,
        plotArea: CGRect(x: 0, y: 0, width: 100, height: 50)
    )
    precondition(proxy.position(forX: 5) == 50)
    precondition(proxy.position(forY: 0) == 50)
    precondition(proxy.position(forY: 5) == 0)
    precondition(proxy.plotAreaRect.width == 100)
}

func testChartProxyValueAtXAndY() {
    let proxy = ChartProxy(
        xScale: ChartScale.linear(domain: 0...10, range: 0...100),
        yScale: ChartScale.linear(domain: 0...5, range: 0...50, inverted: true),
        plotArea: CGRect(x: 0, y: 0, width: 100, height: 50)
    )
    precondition(proxy.value(atX: 50, as: Int.self) == 5)
    precondition(proxy.value(atY: 0, as: Double.self) == 5)
}

func testChartProxyPointAndAngleLookups() {
    let proxy = ChartProxy()
    precondition(proxy.position(for: (x: 1, y: 2)) == nil)
    precondition(proxy.value(at: .zero, as: (Int, Int).self) == nil)
    precondition(proxy.value(atAngle: Angle(), as: Int.self) == nil)
    _ = proxy.angle(at: .zero)
    proxy.selectAngleValue(at: Angle())
}

func testChartProxyDomainAndStyleLookups() {
    let proxy = ChartProxy()
    precondition(proxy.symbolDomain(dataType: Int.self).isEmpty)
    precondition(proxy.lineStyleDomain(dataType: Int.self).isEmpty)
    precondition(proxy.symbolSizeDomain(dataType: Int.self).isEmpty)
    precondition(proxy.foregroundStyleDomain(dataType: Int.self).isEmpty)
    precondition(proxy.positionRange(forX: 1) == nil)
    precondition(proxy.positionRange(forY: 1) == nil)
    precondition(proxy.positionRange(for: (x: 1, y: 2)) == nil)
    precondition(proxy.symbol(for: 1) == nil)
    _ = proxy.plotContainerFrame
}

func testStackingStandardNormalizedCenter() {
    let rows = [
        (category: "A", series: "s1", value: 1.0),
        (category: "A", series: "s2", value: 3.0),
        (category: "B", series: "s1", value: 2.0),
        (category: "B", series: "s2", value: 2.0),
    ]
    let standard = ChartStacking.stack(rows: rows, method: .standard)
    precondition(standard[0].yStart == 0 && standard[0].yEnd == 1)
    precondition(standard[1].yStart == 1 && standard[1].yEnd == 4)
    let normalized = ChartStacking.stack(rows: rows, method: .normalized)
    precondition(abs(normalized[0].yEnd - 0.25) < 0.0001)
    precondition(abs(normalized[1].yEnd - 1) < 0.0001)
    let centered = ChartStacking.stack(rows: rows, method: .center)
    precondition(centered[0].yStart == -2 && centered[0].yEnd == -1)
    precondition(centered[1].yStart == -1 && centered[1].yEnd == 2)
    let unstacked = ChartStacking.stack(rows: rows, method: .unstacked)
    precondition(unstacked[0].yStart == 0 && unstacked[0].yEnd == 1)
}

func testMarkStackingMethodCatalog() {
    precondition(MarkStackingMethod.standard != .normalized)
    precondition(MarkStackingMethod.center != .unstacked)
    precondition(MarkStackingMethod.standard.description == "standard")
    precondition(MarkStackingMethod().description == "standard")
}

func testInterpolationLinearAndSteps() {
    let points = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)]
    let linear = ChartInterpolation.sample(points: points, method: .linear, countPerSegment: 4)
    precondition(abs(linear[2].x - 5) < 0.0001)
    precondition(abs(linear[2].y - 5) < 0.0001)
    let start = ChartInterpolation.sample(points: points, method: .stepStart)
    precondition(start[1] == CGPoint(x: 10, y: 0))
    precondition(start[2] == CGPoint(x: 10, y: 10))
    let end = ChartInterpolation.sample(points: points, method: .stepEnd)
    precondition(end[1] == CGPoint(x: 0, y: 10))
    let center = ChartInterpolation.sample(points: points, method: .stepCenter)
    precondition(center[1] == CGPoint(x: 5, y: 0))
    precondition(center[2] == CGPoint(x: 5, y: 10))
}

func testInterpolationMonotoneAndCatmullRom() {
    let points = [
        CGPoint(x: 0, y: 0),
        CGPoint(x: 1, y: 1),
        CGPoint(x: 2, y: 0),
    ]
    let monotone = ChartInterpolation.sample(points: points, method: .monotone, countPerSegment: 4)
    precondition(monotone.count > 2)
    precondition(abs(Double(monotone[0].y)) < 0.0001)
    let mid = monotone[4]
    precondition(abs(Double(mid.x) - 1) < 0.0001)
    precondition(abs(Double(mid.y) - 1) < 0.0001)
    for sample in monotone {
        precondition(sample.y >= -0.0001)
        precondition(sample.y <= 1.0001)
    }
    let spline = ChartInterpolation.sample(points: points, method: .catmullRom, countPerSegment: 4)
    precondition(spline.count > 2)
    precondition(abs(Double(spline[0].x)) < 0.0001)
    let cardinal = ChartInterpolation.sample(
        points: points,
        method: .cardinal(tension: 0),
        countPerSegment: 2
    )
    precondition(cardinal.count > 2)
    _ = InterpolationMethod.catmullRom(alpha: 0.5)
}

func testInterpolationMethodCatalog() {
    precondition(InterpolationMethod.linear != .catmullRom)
    precondition(InterpolationMethod.catmullRom(alpha: 0.5) == .catmullRom)
    precondition(InterpolationMethod.cardinal(tension: 0) == .cardinal)
    precondition(InterpolationMethod.monotone.description == "monotone")
    precondition(InterpolationMethod.stepStart != .stepEnd)
    precondition(InterpolationMethod.stepCenter != .linear)
}

func testAnnotationPositionCatalog() {
    let positions: [AnnotationPosition] = [
        .automatic, .overlay, .leading, .trailing, .top, .bottom,
    ]
    precondition(Set(positions).count == 6)
    precondition(AnnotationPosition().description == "automatic")
    precondition(AnnotationPosition.top != .bottom)
}

func testAnnotationOffsetTop() {
    precondition(ChartAnnotationPlacement.offset(position: .top) == CGSize(width: 0, height: -4))
    precondition(
        ChartAnnotationPlacement.offset(position: .top, spacing: 8)
            == CGSize(width: 0, height: -8)
    )
}

func testAnnotationOffsetBottom() {
    precondition(ChartAnnotationPlacement.offset(position: .bottom) == CGSize(width: 0, height: 4))
}

func testAnnotationOffsetLeading() {
    precondition(ChartAnnotationPlacement.offset(position: .leading) == CGSize(width: -4, height: 0))
}

func testAnnotationOffsetTrailing() {
    precondition(ChartAnnotationPlacement.offset(position: .trailing) == CGSize(width: 4, height: 0))
}

func testAnnotationOffsetOverlay() {
    precondition(ChartAnnotationPlacement.offset(position: .overlay) == .zero)
}

func testBasicChartSymbolShapeCatalog() {
    let shapes: [BasicChartSymbolShape] = [
        .circle, .square, .plus, .cross, .diamond, .asterisk, .pentagon, .triangle,
    ]
    precondition(Set(shapes).count == 8)
    precondition(BasicChartSymbolShape.circle != .square)
    _ = BasicChartSymbolShape.role
}

func testSymbolShapePathSquare() {
    let square = BasicChartSymbolShape.square.path(in: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(square.cgRects.count == 1)
}

func testSymbolShapePathTriangle() {
    let triangle = BasicChartSymbolShape.triangle.path(
        in: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    precondition(!triangle.polylines.isEmpty)
}

func testAnyChartSymbolShapeWraps() {
    let wrapped = AnyChartSymbolShape(.diamond)
    precondition(wrapped.path(in: .zero) == Path())
    let defaulted = AnyChartSymbolShape()
    _ = defaulted.path(in: CGRect(x: 0, y: 0, width: 4, height: 4))
}

func testAxisMarksPositionAndValues() {
    let marks = AxisMarks(position: .bottom, values: [0, 2, 4, 6, 8, 10])
    precondition(marks.position == .bottom)
    precondition(marks.numericValues == [0, 2, 4, 6, 8, 10])
    let yMarks = AxisMarks(position: .leading, values: [0.0, 1.0, 2.0])
    precondition(yMarks.position == .leading)
}

func testAxisMarksPresetAndAutomaticValues() {
    let marks = AxisMarks(preset: .automatic, position: .top, values: .automatic)
    precondition(marks.position == .top)
    precondition(marks.preset == .automatic)
    _ = AxisMarks(position: .trailing)
}

func testAxisValueLabelText() {
    let label = AxisValueLabel("A", centered: true)
    precondition(label.text == "A")
    precondition(label.centered == true)
}

func testAxisGridLineCentered() {
    let grid = AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
    precondition(grid.centered == true)
}

func testAxisTickLengthCatalog() {
    precondition(AxisTick.Length.automatic != .label)
    precondition(AxisTick.Length.longestLabel != .label)
    precondition(AxisTick.Length.label(extendPastBy: 2) != .automatic)
    precondition(AxisTick.Length.longestLabel(extendPastBy: 1).description == "longestLabel")
    let tick = AxisTick(centered: false, length: .label, stroke: nil)
    precondition(tick.length == .label)
    let sized = AxisTick(centered: true, length: 3, stroke: nil)
    precondition(sized.centered == true)
}

func testAxisMarkPresetCatalog() {
    precondition(AxisMarkPreset.inset != .aligned)
    precondition(AxisMarkPreset.extended != .automatic)
}

func testAxisValueLabelOrientationCatalog() {
    precondition(AxisValueLabelOrientation.automatic != .vertical)
    precondition(AxisValueLabelOrientation.horizontal != .verticalReversed)
    precondition(AxisValueLabelOrientation().description == "automatic")
}

func testAxisValueLabelCollisionCatalog() {
    precondition(AxisValueLabelCollisionResolution.automatic != .greedy)
    precondition(AxisValueLabelCollisionResolution.disabled != .truncate)
    precondition(AxisValueLabelCollisionResolution.greedy(priority: 1, minimumSpacing: 2) == .greedy)
    precondition(AxisValueLabelCollisionResolution().description == "automatic")
}

func testAxisValueIndexAndCast() {
    let value = AxisValue(index: 2, count: 5, encoded: .number(4))
    precondition(value.index == 2)
    precondition(value.count == 5)
    precondition(value.as(Int.self) == 4)
    _ = AxisValue()
}

func testAxisMarkValuesCatalog() {
    _ = AxisMarkValues.automatic
    _ = AxisMarkValues.stride(by: 2)
    _ = AxisMarkValues()
}

func testChartXScaleTypeStore() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartXScale(type: .category)
    precondition(chart.xScaleStorage?.type == .category)
}

func testChartYScaleDomainStore() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartYScale(domain: 0...3, type: .linear)
    precondition(chart.yScaleStorage?.domainMin == 0)
    precondition(chart.yScaleStorage?.domainMax == 3)
}

func testChartXAxisVisibilityStore() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartXAxis(.visible)
    precondition(chart.xAxisStorage?.position == .bottom)
}

func testChartYAxisVisibilityStore() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartYAxis(.visible)
    precondition(chart.yAxisStorage?.position == .leading)
}

func testChartLegendVisibilityStore() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartLegend(.hidden)
    precondition(chart.legendStorage?.visibility == .hidden)
}

func testChartForegroundStyleScaleStore() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartForegroundStyleScale(domain: ["A", "B", "C"], type: .category)
    precondition(chart.foregroundStyleScaleStorage?.domain == ["A", "B", "C"])
}

func testBarMarkXYPlotRecord() {
    let mark = BarMark(x: .value("x", "A"), y: .value("y", 1), stacking: .unstacked)
    precondition(mark.x != nil)
    precondition(mark.y == 1)
    precondition(mark.stacking == .unstacked)
    precondition(mark.chartPlotRecords.first?.kind == .bar)
}

func testBarMarkIntervalPlotRecord() {
    let mark = BarMark(
        x: .value("x", "A"),
        yStart: .value("low", 1),
        yEnd: .value("high", 4)
    )
    precondition(mark.yStart == 1)
    precondition(mark.yEnd == 4)
    _ = BarMark()
}

func testLineMarkSeriesPlotRecord() {
    let mark = LineMark(
        x: .value("x", 1),
        y: .value("y", 2),
        series: .value("s", "one")
    )
    precondition(mark.x == 1)
    precondition(mark.y == 2)
    precondition(mark.series == "one")
    precondition(mark.chartPlotRecords.first?.kind == .line)
}

func testPointMarkPlotRecord() {
    let mark = PointMark(x: .value("x", 3), y: .value("y", 4))
    precondition(mark.x == 3)
    precondition(mark.y == 4)
    precondition(mark.chartPlotRecords.first?.kind == .point)
    _ = PointMark()
}

func testAreaMarkStackingPlotRecord() {
    let mark = AreaMark(x: .value("x", 1), y: .value("y", 2), stacking: .standard)
    precondition(mark.stacking == .standard)
    precondition(mark.chartPlotRecords.first?.kind == .area)
}

func testRuleMarkPlotRecord() {
    let mark = RuleMark(x: .value("x", 5))
    precondition(mark.x == 5)
    precondition(mark.chartPlotRecords.first?.kind == .rule)
}

func testRectangleMarkPlotRecord() {
    let mark = RectangleMark(
        xStart: .value("a", 0),
        xEnd: .value("b", 1),
        yStart: .value("c", 0),
        yEnd: .value("d", 2)
    )
    precondition(mark.xStart == 0)
    precondition(mark.xEnd == 1)
    precondition(mark.yStart == 0)
    precondition(mark.yEnd == 2)
    precondition(mark.chartPlotRecords.first?.kind == .rectangle)
}

func testSectorMarkAnglePlotRecord() {
    let mark = SectorMark(angle: .value("share", 0.25))
    precondition(mark.angle == 0.25)
    precondition(mark.chartPlotRecords.first?.kind == .sector)
    _ = SectorMark()
}

func testChartCollectsSevenMarkKinds() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1), stacking: .unstacked)
        LineMark(x: .value("x", 1), y: .value("y", 2), series: .value("s", "one"))
        PointMark(x: .value("x", 3), y: .value("y", 4))
        AreaMark(x: .value("x", 1), y: .value("y", 2), stacking: .standard)
        RuleMark(x: .value("x", 5))
        RectangleMark(
            xStart: .value("a", 0),
            xEnd: .value("b", 1),
            yStart: .value("c", 0),
            yEnd: .value("d", 2)
        )
        SectorMark(angle: .value("share", 0.25))
    }
    let kinds = chart.chartPlotRecords.map(\.kind)
    precondition(kinds.contains(.bar))
    precondition(kinds.contains(.line))
    precondition(kinds.contains(.point))
    precondition(kinds.contains(.area))
    precondition(kinds.contains(.rule))
    precondition(kinds.contains(.rectangle))
    precondition(kinds.contains(.sector))
}

func testChartContentBuilderBuildBlock() {
    let empty = ChartContentBuilder.buildBlock()
    _ = empty
    let single = ChartContentBuilder.buildBlock(RuleMark(x: .value("x", 1)))
    precondition(single.chartPlotRecords.first?.kind == .rule)
    let pair = ChartContentBuilder.buildBlock(
        LineMark(x: .value("x", 1), y: .value("y", 2)),
        AreaMark(x: .value("x", 1), y: .value("y", 2))
    )
    precondition(pair.chartPlotRecords.count == 2)
}

func testChartContentBuilderBuildExpression() {
    let mark = ChartContentBuilder.buildExpression(PointMark(x: .value("x", 1), y: .value("y", 2)))
    precondition(mark.chartPlotRecords.first?.kind == .point)
    let wrapped = ChartContentBuilder.buildExpression(EmptyView())
    _ = wrapped
}

func testChartContentBuilderBuildOptionalAndIf() {
    let some = ChartContentBuilder.buildOptional(
        Optional(RuleMark(x: .value("x", 1)))
    )
    precondition(!some.chartPlotRecords.isEmpty)
    let none = ChartContentBuilder.buildIf(Optional<RuleMark>.none)
    precondition(none == nil)
}

func testChartContentBuilderBuildEither() {
    let first: _ChartEitherContent<LineMark, AreaMark> = ChartContentBuilder.buildEither(
        first: LineMark(x: .value("x", 1), y: .value("y", 2))
    )
    precondition(first.chartPlotRecords.first?.kind == .line)
    let second: _ChartEitherContent<LineMark, AreaMark> = ChartContentBuilder.buildEither(
        second: AreaMark(x: .value("x", 1), y: .value("y", 2))
    )
    precondition(second.chartPlotRecords.first?.kind == .area)
}

func testChartContentBuilderLimitedAvailability() {
    let boxed = ChartContentBuilder.buildLimitedAvailability(
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    )
    precondition(boxed.chartPlotRecords.first?.kind == .bar)
}

func testChartResolvedProxyFromContent() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1), stacking: .unstacked)
        BarMark(x: .value("x", "B"), y: .value("y", 2), stacking: .unstacked)
        BarMark(x: .value("x", "C"), y: .value("y", 3), stacking: .unstacked)
    }
    .chartYScale(domain: 0...3)
    let proxy = chart.resolvedProxy(plotArea: ChartThreeBarFixture.plotArea)
    precondition(proxy.position(forX: "A") == 15)
    precondition(abs((proxy.position(forY: 0) ?? -1) - 60) < 0.0001)
    precondition(abs((proxy.position(forY: 3) ?? -1) - 0) < 0.0001)
    precondition(proxy.plotAreaRect.width == 90)
    let records = ChartThreeBarFixture.records()
    let placed = ChartLayout.place(
        records: records,
        xScale: ChartThreeBarFixture.xScale(),
        yScale: ChartThreeBarFixture.yScale()
    )
    let frames = placed.map(\.frame)
    let expectedFrames = ChartThreeBarFixture.expectedFrames()
    precondition(frames.count == expectedFrames.count)
    for (actual, expected) in zip(frames, expectedFrames) {
        precondition(abs(actual.minX - expected.minX) < 0.0001)
        precondition(abs(actual.minY - expected.minY) < 0.0001)
        precondition(abs(actual.width - expected.width) < 0.0001)
        precondition(abs(actual.height - expected.height) < 0.0001)
    }
    let rendered = ChartRaster.render(
        marks: placed,
        width: ChartThreeBarFixture.width,
        height: ChartThreeBarFixture.height
    )
    precondition(rendered.pixels == ChartThreeBarFixture.expectedBitmap().pixels)
    var context = GraphicsContext(
        width: ChartThreeBarFixture.width,
        height: ChartThreeBarFixture.height
    )
    ChartCanvasDrawing.draw(placed, into: &context)
    precondition(context.bitmap.pixels == ChartThreeBarFixture.expectedBitmap().pixels)
}
