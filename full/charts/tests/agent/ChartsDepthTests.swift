import Foundation
@_spi(OpenUIKitHost) import Charts

func testPlottableValueIntDoubleDateString() {
    let integer = PlottableValue.value("count", 8)
    precondition(integer.label == "count")
    precondition(integer.value == 8)
    let floating = PlottableValue.value("ratio", 2.5)
    precondition(floating.value == 2.5)
    let dated = PlottableValue.value("day", Date(timeIntervalSinceReferenceDate: 12))
    precondition(dated.value.timeIntervalSinceReferenceDate == 12)
    let categorical = PlottableValue.value("name", "A")
    precondition(categorical.value == "A")
    precondition(chartEncode(categorical.value) == .category("A"))
    precondition(chartEncode(8) == .number(8))
    precondition(chartEncode(2.5) == .number(2.5))
}

func testLinearNiceTicksZeroToTen() {
    let scale = ChartScale.linear(domain: 0...10, range: 0...100)
    precondition(scale.niceTicks(desiredCount: 5) == [0, 2, 4, 6, 8, 10])
    let domain = scale.niceDomain(desiredTicks: 5)
    precondition(domain.min == 0)
    precondition(domain.max == 10)
}

func testLinearNiceTicksZeroToOneHundred() {
    let scale = ChartScale.linear(domain: 0...100, range: 0...1)
    precondition(scale.niceTicks(desiredCount: 5) == [0, 20, 40, 60, 80, 100])
}

func testLogNiceTicks() {
    let scale = ChartScale.log(domain: 1...1000, range: 0...1)
    precondition(scale.niceTicks() == [1, 10, 100, 1000])
}

func testDateScaleMapping() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    let end = Date(timeIntervalSinceReferenceDate: 100)
    let scale = ChartScale.date(domain: 0...100, range: 0...200)
    precondition(abs(scale.position(forNumeric: 50) - 100) < 0.0001)
    precondition(abs(scale.numericValue(at: 100) - 50) < 0.0001)
    _ = start
    _ = end
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
    precondition(proxy.value(atX: 50, as: Int.self) == 5)
    precondition(proxy.value(atY: 0, as: Double.self) == 5)
    precondition(proxy.plotAreaRect.width == 100)
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
}

func testAnnotationOffsets() {
    precondition(ChartAnnotationPlacement.offset(position: .top) == CGSize(width: 0, height: -4))
    precondition(ChartAnnotationPlacement.offset(position: .bottom) == CGSize(width: 0, height: 4))
    precondition(ChartAnnotationPlacement.offset(position: .leading) == CGSize(width: -4, height: 0))
    precondition(ChartAnnotationPlacement.offset(position: .trailing) == CGSize(width: 4, height: 0))
    precondition(ChartAnnotationPlacement.offset(position: .overlay) == .zero)
    precondition(
        ChartAnnotationPlacement.offset(position: .top, spacing: 8)
            == CGSize(width: 0, height: -8)
    )
}

func testSymbolShapePaths() {
    let square = BasicChartSymbolShape.square.path(in: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(square.cgRects.count == 1)
    let triangle = BasicChartSymbolShape.triangle.path(
        in: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    precondition(!triangle.polylines.isEmpty)
}

func testAxisMarksStoreValuesAndPosition() {
    let marks = AxisMarks(position: .bottom, values: [0, 2, 4, 6, 8, 10])
    precondition(marks.position == .bottom)
    precondition(marks.numericValues == [0, 2, 4, 6, 8, 10])
    let yMarks = AxisMarks(position: .leading, values: [0.0, 1.0, 2.0])
    precondition(yMarks.position == .leading)
    let label = AxisValueLabel("A", centered: true)
    precondition(label.text == "A")
    precondition(label.centered == true)
    let grid = AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
    precondition(grid.centered == true)
    let tick = AxisTick(centered: false, length: .label, stroke: nil)
    precondition(tick.length == .label)
}

func testChartModifierValueStores() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
        BarMark(x: .value("x", "B"), y: .value("y", 2))
        BarMark(x: .value("x", "C"), y: .value("y", 3))
    }
    .chartXScale(type: .category)
    .chartYScale(domain: 0...3, type: .linear)
    .chartXAxis(.visible)
    .chartYAxis(.visible)
    .chartLegend(.hidden)
    .chartForegroundStyleScale(domain: ["A", "B", "C"], type: .category)
    precondition(chart.xScaleStorage?.type == .category)
    precondition(chart.yScaleStorage?.domainMin == 0)
    precondition(chart.yScaleStorage?.domainMax == 3)
    precondition(chart.xAxisStorage?.position == .bottom)
    precondition(chart.yAxisStorage?.position == .leading)
    precondition(chart.legendStorage?.visibility == .hidden)
    precondition(chart.foregroundStyleScaleStorage?.domain == ["A", "B", "C"])
}

func testChartCollectsMarkRecords() {
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

func testThreeBarPixelRaster() {
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
    let expected = ChartThreeBarFixture.expectedBitmap()
    precondition(rendered.pixels == expected.pixels)
}

func testGraphicsContextBarFill() {
    var context = GraphicsContext(
        width: ChartThreeBarFixture.width,
        height: ChartThreeBarFixture.height
    )
    let placed = ChartLayout.place(
        records: ChartThreeBarFixture.records(),
        xScale: ChartThreeBarFixture.xScale(),
        yScale: ChartThreeBarFixture.yScale()
    )
    ChartCanvasDrawing.draw(placed, into: &context)
    let expected = ChartThreeBarFixture.expectedBitmap()
    precondition(context.bitmap.pixels == expected.pixels)
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
}

func testScaleTypeCatalog() {
    precondition(ScaleType.linear != .log)
    precondition(ScaleType.date != .category)
    precondition(ScaleType.squareRoot != .linear)
    _ = ScaleType.power(exponent: 2)
    _ = ScaleType.symmetricLog(slopeAtZero: 1)
}

func testMarkStackingMethodIdentities() {
    precondition(MarkStackingMethod.standard != .normalized)
    precondition(MarkStackingMethod.center != .unstacked)
    precondition(MarkStackingMethod.standard.description == "standard")
}
