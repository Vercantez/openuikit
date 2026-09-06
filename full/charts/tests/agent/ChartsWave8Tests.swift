import Foundation
@_spi(OpenUIKitHost) import Charts

func testSymbolLogScalePixels() {
    let scale = ChartScale.symbolLog(domain: 1...1000, range: 0...90)
    precondition(abs(scale.position(forNumeric: 1) - 0) < 0.0001)
    precondition(abs(scale.position(forNumeric: 10) - 30) < 0.0001)
    precondition(abs(scale.position(forNumeric: 100) - 60) < 0.0001)
    precondition(abs(scale.position(forNumeric: 1000) - 90) < 0.0001)
    precondition(ScaleType.symbolLog != .log)
    precondition(ScaleType.symbolLog.description == "symbolLog")
}

func testLogScalePixelsFixedPlot() {
    let scale = ChartScale.log(domain: 1...1000, range: 0...90)
    precondition(abs(scale.position(forNumeric: 10) - 30) < 0.0001)
    precondition(abs(scale.numericValue(at: 30) - 10) < 0.0001)
}

func testDateScalePixelsFixedPlot() {
    let scale = ChartScale.date(domain: 0...100, range: 0...200)
    precondition(abs(scale.position(forNumeric: 50) - 100) < 0.0001)
    let proxy = ChartProxy(
        xScale: scale,
        yScale: ChartScale.linear(domain: 0...1, range: 0...40, inverted: true),
        plotArea: ChartFixedPlotFixture.plotArea
    )
    let date = Date(timeIntervalSinceReferenceDate: 50)
    precondition(abs((proxy.position(forX: date) ?? -1) - 100) < 0.0001)
    precondition(proxy.plotAreaSize.width == 100)
    precondition(proxy.plotAreaSize.height == 40)
    precondition(proxy.plotFrame != nil)
}

func testLinearScalePixelsFixedPlot() {
    let xScale = ChartScale.linear(domain: 0...10, range: 0...100)
    let yScale = ChartScale.linear(domain: 0...4, range: 0...40, inverted: true)
    let proxy = ChartProxy(xScale: xScale, yScale: yScale, plotArea: ChartFixedPlotFixture.plotArea)
    precondition(proxy.position(forX: 5) == 50)
    precondition(proxy.position(forY: 0) == 40)
    precondition(proxy.position(forY: 4) == 0)
    precondition(proxy.position(forY: 2) == 20)
    precondition(proxy.value(atX: 50, as: Int.self) == 5)
    precondition(proxy.plotAreaSize == CGSize(width: 100, height: 40))
}

func testAutomaticDomainInference() {
    let chart = Chart {
        LineMark(x: .value("x", 2), y: .value("y", 4))
        LineMark(x: .value("x", 8), y: .value("y", 12))
    }
    let plot = CGRect(x: 0, y: 0, width: 100, height: 40)
    let xScale = chart.resolvedXScale(plotArea: plot)
    let yScale = chart.resolvedYScale(plotArea: plot)
    precondition(xScale.domainMin == 2)
    precondition(xScale.domainMax == 8)
    precondition(yScale.domainMin == 4)
    precondition(yScale.domainMax == 12)
    let proxy = chart.resolvedProxy(plotArea: plot)
    precondition(abs((proxy.position(forX: 2) ?? -1) - 0) < 0.0001)
    precondition(abs((proxy.position(forX: 8) ?? -1) - 100) < 0.0001)
}

func testChartXScaleDomainRangeType() {
    let chart = Chart {
        LineMark(x: .value("x", 1), y: .value("y", 2))
    }
    .chartXScale(domain: 0...10, type: .linear)
    .chartYScale(domain: 0...4, type: .linear)
    precondition(chart.xScaleStorage?.domainMin == 0)
    precondition(chart.xScaleStorage?.domainMax == 10)
    precondition(chart.yScaleStorage?.type == .linear)
}

func testChartLogScaleResolvedPixels() {
    let chart = Chart {
        PointMark(x: .value("x", 10), y: .value("y", 100))
    }
    .chartXScale(domain: 1...1000, type: .log)
    .chartYScale(domain: 1...1000, type: .log)
    let proxy = chart.resolvedProxy(
        plotArea: CGRect(x: 0, y: 0, width: 90, height: 90)
    )
    precondition(abs((proxy.position(forX: 10) ?? -1) - 30) < 0.0001)
    precondition(abs((proxy.position(forY: 10) ?? -1) - 60) < 0.0001)
}

func testChartSymbolLogScaleResolvedPixels() {
    let chart = Chart {
        PointMark(x: .value("x", 10), y: .value("y", 10))
    }
    .chartXScale(domain: 1...1000, type: .symbolLog)
    let proxy = chart.resolvedProxy(
        plotArea: CGRect(x: 0, y: 0, width: 90, height: 40)
    )
    precondition(abs((proxy.position(forX: 10) ?? -1) - 30) < 0.0001)
}

func testAxisMarksStridePixels() {
    let values = AxisMarkValues.stride(by: 2)
    precondition(values.strideStep == 2)
    let ticks = values.resolvedTicks(domainMin: 0, domainMax: 10)
    precondition(ticks == [0, 2, 4, 6, 8, 10])
    let scale = ChartScale.linear(domain: 0...10, range: 0...100)
    let pixels = ChartAxisLayout.tickPositions(values: values, scale: scale)
    precondition(pixels == [0, 20, 40, 60, 80, 100])
    let marks = AxisMarks(preset: .aligned, position: .bottom, values: values)
    precondition(marks.preset == .aligned)
    precondition(marks.markValues.strideStep == 2)
}

func testAxisMarkValuesAutomaticAndValues() {
    let automatic = AxisMarkValues.automatic(desiredCount: 5)
    precondition(automatic.desiredCount == 5)
    let explicit = AxisMarkValues.values([0, 5, 10])
    precondition(explicit.explicitValues == [0, 5, 10])
    let calendar = AxisMarkValues.stride(by: .day, count: 1)
    precondition(calendar.calendarComponent == .day)
    _ = AxisMarkValues.automatic(minimumStride: 2, desiredCount: 4)
    _ = AxisMarkValues.stride(by: 1, roundLowerBound: true, roundUpperBound: true)
}

func testAxisMarksExplicitValuesPixels() {
    let marks = AxisMarks(position: .leading, values: [0, 2, 4])
    precondition(marks.numericValues == [0, 2, 4])
    let scale = ChartScale.linear(domain: 0...4, range: 0...40, inverted: true)
    let pixels = ChartAxisLayout.tickPositions(values: marks.markValues, scale: scale)
    precondition(pixels == [40, 20, 0])
}

func testBarMarkSeriesAndIntervalInits() {
    let series = BarMark(
        x: .value("x", "A"),
        y: .value("y", 3),
        series: .value("s", "one"),
        stacking: .center
    )
    precondition(series.series == "one")
    precondition(series.stacking == .center)
    let interval = BarMark(
        x: .value("x", "B"),
        yStart: 1,
        yEnd: 4
    )
    precondition(interval.yStart == 1)
    precondition(interval.yEnd == 4)
    let horizontal = BarMark(
        xStart: 0,
        xEnd: 10,
        yStart: .value("lo", 1),
        yEnd: .value("hi", 2)
    )
    precondition(horizontal.xStart == 0)
    precondition(horizontal.xEnd == 10)
    let plottableX = BarMark(
        xStart: .value("a", 1),
        xEnd: .value("b", 3),
        yStart: 0,
        yEnd: 5
    )
    precondition(plottableX.xStart == 1)
    precondition(plottableX.xEnd == 3)
    let stackedX = BarMark(
        xStart: .value("a", 0),
        xEnd: .value("b", 2),
        y: .value("y", 7)
    )
    precondition(stackedX.y == 7)
}

func testLineMarkPixelsFixedPlot() {
    let chart = Chart {
        LineMark(x: .value("x", 0), y: .value("y", 0), series: .value("s", "one"))
        LineMark(x: .value("x", 10), y: .value("y", 4), series: .value("s", "one"))
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let line = placed.first { $0.kind == .line }
    precondition(line != nil)
    precondition(abs((line?.points.first?.x ?? -1) - 0) < 0.0001)
    precondition(abs((line?.points.first?.y ?? -1) - 40) < 0.0001)
    precondition(abs((line?.points.last?.x ?? -1) - 100) < 0.0001)
    precondition(abs((line?.points.last?.y ?? -1) - 0) < 0.0001)
}

func testPointMarkPixelsFixedPlot() {
    let chart = Chart {
        PointMark(x: .value("x", 5), y: .value("y", 2))
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let point = placed.first { $0.kind == .point }
    precondition(abs((point?.points.first?.x ?? -1) - 50) < 0.0001)
    precondition(abs((point?.points.first?.y ?? -1) - 20) < 0.0001)
}

func testAreaMarkPixelsFixedPlot() {
    let chart = Chart {
        AreaMark(x: .value("x", 0), y: .value("y", 0), stacking: .unstacked)
        AreaMark(x: .value("x", 10), y: .value("y", 4), stacking: .unstacked)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let area = placed.first { $0.kind == .area }
    precondition(area != nil)
    precondition(abs((area?.points.first?.x ?? -1) - 0) < 0.0001)
}

func testRuleMarkPixelsFixedPlot() {
    let chart = Chart {
        RuleMark(x: .value("x", 5))
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let rule = placed.first { $0.kind == .rule }
    precondition(abs((rule?.points.first?.x ?? -1) - 50) < 0.0001)
}

func testRectangleMarkPixelsFixedPlot() {
    let chart = Chart {
        RectangleMark(
            xStart: .value("a", 0),
            xEnd: .value("b", 10),
            yStart: .value("c", 0),
            yEnd: .value("d", 4)
        )
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let placed = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea)
    let rect = placed.first { $0.kind == .rectangle }
    precondition(abs((rect?.frame.width ?? -1) - 100) < 0.0001)
    precondition(abs((rect?.frame.height ?? -1) - 40) < 0.0001)
}

func testForEachChartContentRecords() {
    struct Row: Hashable {
        var name: String
        var value: Int
    }
    let rows = [Row(name: "A", value: 1), Row(name: "B", value: 2)]
    let chart = Chart {
        ForEach(rows, id: \.self) { row in
            BarMark(x: .value("x", row.name), y: .value("y", row.value), stacking: .unstacked)
        }
    }
    precondition(chart.chartPlotRecords.count == 2)
    precondition(chart.chartPlotRecords[0].category == "A")
    precondition(chart.chartPlotRecords[1].y == 2)
}

func testChartDataForEachInit() {
    let chart = Chart([("A", 1), ("B", 3)], id: \.0) { row in
        BarMark(x: .value("x", row.0), y: .value("y", row.1), stacking: .unstacked)
    }
    precondition(chart.chartPlotRecords.count == 2)
    let proxy = chart.resolvedProxy(plotArea: CGRect(x: 0, y: 0, width: 90, height: 60))
    precondition(proxy.position(forX: "A") == 22.5)
    precondition(proxy.position(forX: "B") == 67.5)
}

func testAnnotationStoresPosition() {
    let marked = BarMark(x: .value("x", "A"), y: .value("y", 1))
        .annotation(position: .top, alignment: .center) { Text("A") }
    precondition(marked.chartPlotRecords.first?.annotationPosition == "top")
    let overlay = PointMark(x: .value("x", 1), y: .value("y", 2))
        .annotation(position: .overlay, alignment: .center, spacing: 2) { Text("p") }
    precondition(overlay.chartPlotRecords.first?.annotationPosition == "overlay")
}

func testForegroundStyleResolvedAttribute() {
    let marked = LineMark(x: .value("x", 1), y: .value("y", 2))
        .foregroundStyle(Color.blue)
    precondition(marked.chartPlotRecords.first?.foregroundStyleName != nil)
    let bySeries = BarMark(x: .value("x", "A"), y: .value("y", 1))
        .foregroundStyle(by: .value("s", "one"))
    precondition(bySeries.chartPlotRecords.first?.foregroundStyleName == "s")
}

func testSymbolAndLineStyleResolvedAttributes() {
    let interpolated = LineMark(x: .value("x", 1), y: .value("y", 2))
        .interpolationMethod(.monotone)
    precondition(interpolated.chartPlotRecords.first?.interpolation == .monotone)
    let lined = RuleMark(x: .value("x", 1))
        .lineStyle(StrokeStyle(lineWidth: 3, dash: [4, 4]))
    precondition(lined.chartPlotRecords.first?.lineWidth == 3)
    precondition(lined.chartPlotRecords.first?.lineDash == [4, 4])
    let marked = LineMark(x: .value("x", 1), y: .value("y", 2))
        .symbol(.square)
    _ = marked
}

func testChartScrollableAxesModel() {
    let chart = Chart {
        LineMark(x: .value("x", 1), y: .value("y", 2))
    }
    .chartScrollableAxes(.horizontal)
    precondition(chart.scrollableAxes?.axes == .horizontal)
    precondition(ChartScrollableAxes.horizontal.axes == .horizontal)
    precondition(ChartScrollableAxes.vertical.axes == .vertical)
}

func testChartScrollPositionModel() {
    var x = 5
    let chart = Chart {
        LineMark(x: .value("x", 1), y: .value("y", 2))
    }
    .chartScrollPosition(x: Binding(get: { x }, set: { x = $0 }))
    precondition(chart.scrollPosition?.xEncoded == .number(5))
    let initial = Chart {
        LineMark(x: .value("x", 1), y: .value("y", 2))
    }
    .chartScrollPosition(initialX: 8)
    precondition(initial.scrollPosition?.xEncoded == .number(8))
}

func testChartXSelectionModel() {
    var selected: Int? = 3
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartXSelection(value: Binding(get: { selected }, set: { selected = $0 }))
    precondition(chart.xSelection?.value == .number(3))
    var range: ClosedRange<Double>? = 1...4
    let ranged = Chart {
        LineMark(x: .value("x", 1), y: .value("y", 2))
    }
    .chartXSelection(range: Binding(get: { range }, set: { range = $0 }))
    precondition(ranged.xSelection?.range == 1...4)
}

func testSurfaceMarkFailClosed() {
    let mark = SurfaceMark()
    _ = mark.body
    let plot = SurfacePlot()
    _ = plot.body
    let chart3D = Chart3D {
        SurfaceMark()
    }
    _ = chart3D.body
}

func testVectorizedBarPlotRecords() {
    struct Row { var name: String; var value: Int }
    let plot = BarPlot(
        [Row(name: "A", value: 1), Row(name: "B", value: 3)],
        x: .value("x", \.name),
        y: .value("y", \.value)
    )
    precondition(plot.chartPlotRecords.count == 2)
    precondition(plot.chartPlotRecords[0].kind == .bar)
    precondition(plot.chartPlotRecords[0].category == "A")
    precondition(plot.chartPlotRecords[1].y == 3)
}

func testVectorizedBarPlotIntervalInit() {
    struct Row { var name: String; var lo: Int; var hi: Int }
    let plot = BarPlot(
        [Row(name: "A", lo: 1, hi: 4)],
        x: .value("x", \.name),
        yStart: .value("lo", \.lo),
        yEnd: .value("hi", \.hi)
    )
    precondition(plot.chartPlotRecords.first?.yStart == 1)
    precondition(plot.chartPlotRecords.first?.yEnd == 4)
}

func testVectorizedLinePlotRecords() {
    struct Row { var x: Double; var y: Double }
    let plot = LinePlot(
        [Row(x: 0, y: 0), Row(x: 10, y: 4)],
        x: .value("x", \.x),
        y: .value("y", \.y)
    )
    precondition(plot.chartPlotRecords.count == 2)
    precondition(plot.chartPlotRecords[0].kind == .line)
    precondition(plot.chartPlotRecords[1].x == 10)
}

func testVectorizedPointPlotRecords() {
    struct Row { var x: Double; var y: Double }
    let plot = PointPlot(
        [Row(x: 3, y: 4)],
        x: .value("x", \.x),
        y: .value("y", \.y)
    )
    precondition(plot.chartPlotRecords.first?.kind == .point)
    precondition(plot.chartPlotRecords.first?.y == 4)
}

func testVectorizedAreaPlotRecords() {
    struct Row { var x: Double; var y: Double }
    let plot = AreaPlot(
        [Row(x: 1, y: 2)],
        x: .value("x", \.x),
        y: .value("y", \.y),
        stacking: .standard
    )
    precondition(plot.chartPlotRecords.first?.kind == .area)
    precondition(plot.chartPlotRecords.first?.stacking == .standard)
}

func testVectorizedRulePlotRecords() {
    struct Row { var x: Double }
    let plot = RulePlot(
        [Row(x: 5)],
        x: .value("x", \.x)
    )
    precondition(plot.chartPlotRecords.first?.kind == .rule)
    precondition(plot.chartPlotRecords.first?.x == 5)
}

func testVectorizedRectanglePlotRecords() {
    struct Row { var x0: Double; var x1: Double; var y0: Double; var y1: Double }
    let plot = RectanglePlot(
        [Row(x0: 0, x1: 2, y0: 0, y1: 3)],
        xStart: .value("a", \.x0),
        xEnd: .value("b", \.x1),
        yStart: .value("c", \.y0),
        yEnd: .value("d", \.y1)
    )
    precondition(plot.chartPlotRecords.first?.kind == .rectangle)
    precondition(plot.chartPlotRecords.first?.xEnd == 2)
}

func testVectorizedSectorPlotRecords() {
    struct Row { var share: Double }
    let plot = SectorPlot(
        [Row(share: 0.25)],
        angle: .value("share", \.share)
    )
    precondition(plot.chartPlotRecords.first?.kind == .sector)
    precondition(plot.chartPlotRecords.first?.angle == 0.25)
}

func testVectorizedBarPlotContentEmpty() {
    let empty = VectorizedBarPlotContent<[Int]>()
    precondition(empty.chartPlotRecords.isEmpty)
    _ = VectorizedAreaPlotContent<[Int]>()
    _ = VectorizedLinePlotContent<[Int]>()
    _ = VectorizedRulePlotContent<[Int]>()
    _ = VectorizedPointPlotContent<[Int]>()
    _ = VectorizedSectorPlotContent<[Int]>()
    _ = VectorizedRectanglePlotContent<[Int]>()
}

private struct ChartVectorizedRow {
    var name: String
    var value: Int
    var lo: Int
    var hi: Int
    var series: String
    var labelKey: LocalizedStringKey
    var labelText: Text
    var hidden: Bool
    var identifier: String
    var fade: CGFloat
    var stroke: StrokeStyle
    var color: Color
    var area: CGFloat
    var size: CGSize
    var day: Date
}

private func chartVectorizedFixture() -> [ChartVectorizedRow] {
    [
        ChartVectorizedRow(
            name: "A",
            value: 1,
            lo: 1,
            hi: 4,
            series: "s",
            labelKey: LocalizedStringKey("count"),
            labelText: Text("count"),
            hidden: true,
            identifier: "row",
            fade: 0.5,
            stroke: StrokeStyle(lineWidth: 1.5),
            color: .blue,
            area: 4,
            size: CGSize(width: 2, height: 2),
            day: Date(timeIntervalSinceReferenceDate: 10)
        )
    ]
}

private func chartVectorizedContents(_ rows: [ChartVectorizedRow]) -> (
    BarPlot<VectorizedBarPlotContent<[ChartVectorizedRow]>>,
    LinePlot<VectorizedLinePlotContent<[ChartVectorizedRow]>>,
    AreaPlot<VectorizedAreaPlotContent<[ChartVectorizedRow]>>,
    PointPlot<VectorizedPointPlotContent<[ChartVectorizedRow]>>,
    RulePlot<VectorizedRulePlotContent<[ChartVectorizedRow]>>,
    SectorPlot<VectorizedSectorPlotContent<[ChartVectorizedRow]>>,
    RectanglePlot<VectorizedRectanglePlotContent<[ChartVectorizedRow]>>,
    VectorizedBarPlotContent<[ChartVectorizedRow]>,
    VectorizedLinePlotContent<[ChartVectorizedRow]>,
    VectorizedAreaPlotContent<[ChartVectorizedRow]>,
    VectorizedPointPlotContent<[ChartVectorizedRow]>,
    VectorizedRulePlotContent<[ChartVectorizedRow]>,
    VectorizedSectorPlotContent<[ChartVectorizedRow]>,
    VectorizedRectanglePlotContent<[ChartVectorizedRow]>
) {
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    return (
        BarPlot(rows, x: x, y: y),
        LinePlot(rows, x: x, y: y),
        AreaPlot(rows, x: x, y: y),
        PointPlot(rows, x: x, y: y),
        RulePlot(rows, x: x),
        SectorPlot(rows, angle: y),
        RectanglePlot(rows, xStart: y, xEnd: y, yStart: y, yEnd: y),
        VectorizedBarPlotContent(records: []),
        VectorizedLinePlotContent(records: []),
        VectorizedAreaPlotContent(records: []),
        VectorizedPointPlotContent(records: []),
        VectorizedRulePlotContent(records: []),
        VectorizedSectorPlotContent(records: []),
        VectorizedRectanglePlotContent(records: [])
    )
}

func testVectorizedSymbolSizeBy() {
    let rows = chartVectorizedFixture()
    let size = PlottableProjection<ChartVectorizedRow, Int>.value("size", \.value)
    let contents = chartVectorizedContents(rows)
    _ = contents.0.symbolSize(by: size)
    _ = contents.1.symbolSize(by: size)
    _ = contents.2.symbolSize(by: size)
    _ = contents.3.symbolSize(by: size)
    _ = contents.4.symbolSize(by: size)
    _ = contents.5.symbolSize(by: size)
    _ = contents.6.symbolSize(by: size)
    _ = contents.7.symbolSize(by: size)
    _ = contents.8.symbolSize(by: size)
    _ = contents.9.symbolSize(by: size)
    _ = contents.10.symbolSize(by: size)
    _ = contents.11.symbolSize(by: size)
    _ = contents.12.symbolSize(by: size)
    _ = contents.13.symbolSize(by: size)
}

func testVectorizedSymbolSizeAreaKeyPath() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.symbolSize(\.area)
    _ = contents.1.symbolSize(\.area)
    _ = contents.2.symbolSize(\.area)
    _ = contents.3.symbolSize(\.area)
    _ = contents.4.symbolSize(\.area)
    _ = contents.5.symbolSize(\.area)
    _ = contents.6.symbolSize(\.area)
    _ = contents.7.symbolSize(\.area)
    _ = contents.8.symbolSize(\.area)
    _ = contents.9.symbolSize(\.area)
    _ = contents.10.symbolSize(\.area)
    _ = contents.11.symbolSize(\.area)
    _ = contents.12.symbolSize(\.area)
    _ = contents.13.symbolSize(\.area)
}

func testVectorizedSymbolSizeCGSizeKeyPath() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.symbolSize(\.size)
    _ = contents.1.symbolSize(\.size)
    _ = contents.2.symbolSize(\.size)
    _ = contents.3.symbolSize(\.size)
    _ = contents.4.symbolSize(\.size)
    _ = contents.5.symbolSize(\.size)
    _ = contents.6.symbolSize(\.size)
    _ = contents.7.symbolSize(\.size)
    _ = contents.8.symbolSize(\.size)
    _ = contents.9.symbolSize(\.size)
    _ = contents.10.symbolSize(\.size)
    _ = contents.11.symbolSize(\.size)
    _ = contents.12.symbolSize(\.size)
    _ = contents.13.symbolSize(\.size)
}

func testVectorizedForegroundStyleBy() {
    let rows = chartVectorizedFixture()
    let series = PlottableProjection<ChartVectorizedRow, String>.value("s", \.series)
    let contents = chartVectorizedContents(rows)
    _ = contents.0.foregroundStyle(by: series)
    _ = contents.1.foregroundStyle(by: series)
    _ = contents.2.foregroundStyle(by: series)
    _ = contents.3.foregroundStyle(by: series)
    _ = contents.4.foregroundStyle(by: series)
    _ = contents.5.foregroundStyle(by: series)
    _ = contents.6.foregroundStyle(by: series)
    _ = contents.7.foregroundStyle(by: series)
    _ = contents.8.foregroundStyle(by: series)
    _ = contents.9.foregroundStyle(by: series)
    _ = contents.10.foregroundStyle(by: series)
    _ = contents.11.foregroundStyle(by: series)
    _ = contents.12.foregroundStyle(by: series)
    _ = contents.13.foregroundStyle(by: series)
}

func testVectorizedForegroundStyleKeyPath() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.foregroundStyle(\.color)
    _ = contents.1.foregroundStyle(\.color)
    _ = contents.2.foregroundStyle(\.color)
    _ = contents.3.foregroundStyle(\.color)
    _ = contents.4.foregroundStyle(\.color)
    _ = contents.5.foregroundStyle(\.color)
    _ = contents.6.foregroundStyle(\.color)
    _ = contents.7.foregroundStyle(\.color)
    _ = contents.8.foregroundStyle(\.color)
    _ = contents.9.foregroundStyle(\.color)
    _ = contents.10.foregroundStyle(\.color)
    _ = contents.11.foregroundStyle(\.color)
    _ = contents.12.foregroundStyle(\.color)
    _ = contents.13.foregroundStyle(\.color)
}

func testVectorizedAccessibilityLabelKey() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityLabel(\.labelKey)
    _ = contents.1.accessibilityLabel(\.labelKey)
    _ = contents.2.accessibilityLabel(\.labelKey)
    _ = contents.3.accessibilityLabel(\.labelKey)
    _ = contents.4.accessibilityLabel(\.labelKey)
    _ = contents.5.accessibilityLabel(\.labelKey)
    _ = contents.6.accessibilityLabel(\.labelKey)
    _ = contents.7.accessibilityLabel(\.labelKey)
    _ = contents.8.accessibilityLabel(\.labelKey)
    _ = contents.9.accessibilityLabel(\.labelKey)
    _ = contents.10.accessibilityLabel(\.labelKey)
    _ = contents.11.accessibilityLabel(\.labelKey)
    _ = contents.12.accessibilityLabel(\.labelKey)
    _ = contents.13.accessibilityLabel(\.labelKey)
}

func testVectorizedAccessibilityLabelText() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityLabel(\.labelText)
    _ = contents.1.accessibilityLabel(\.labelText)
    _ = contents.2.accessibilityLabel(\.labelText)
    _ = contents.3.accessibilityLabel(\.labelText)
    _ = contents.4.accessibilityLabel(\.labelText)
    _ = contents.5.accessibilityLabel(\.labelText)
    _ = contents.6.accessibilityLabel(\.labelText)
    _ = contents.7.accessibilityLabel(\.labelText)
    _ = contents.8.accessibilityLabel(\.labelText)
    _ = contents.9.accessibilityLabel(\.labelText)
    _ = contents.10.accessibilityLabel(\.labelText)
    _ = contents.11.accessibilityLabel(\.labelText)
    _ = contents.12.accessibilityLabel(\.labelText)
    _ = contents.13.accessibilityLabel(\.labelText)
}

func testVectorizedAccessibilityLabelString() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityLabel(\.name)
    _ = contents.1.accessibilityLabel(\.name)
    _ = contents.2.accessibilityLabel(\.name)
    _ = contents.3.accessibilityLabel(\.name)
    _ = contents.4.accessibilityLabel(\.name)
    _ = contents.5.accessibilityLabel(\.name)
    _ = contents.6.accessibilityLabel(\.name)
    _ = contents.7.accessibilityLabel(\.name)
    _ = contents.8.accessibilityLabel(\.name)
    _ = contents.9.accessibilityLabel(\.name)
    _ = contents.10.accessibilityLabel(\.name)
    _ = contents.11.accessibilityLabel(\.name)
    _ = contents.12.accessibilityLabel(\.name)
    _ = contents.13.accessibilityLabel(\.name)
}

func testVectorizedAccessibilityValueKey() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityValue(\.labelKey)
    _ = contents.1.accessibilityValue(\.labelKey)
    _ = contents.2.accessibilityValue(\.labelKey)
    _ = contents.3.accessibilityValue(\.labelKey)
    _ = contents.4.accessibilityValue(\.labelKey)
    _ = contents.5.accessibilityValue(\.labelKey)
    _ = contents.6.accessibilityValue(\.labelKey)
    _ = contents.7.accessibilityValue(\.labelKey)
    _ = contents.8.accessibilityValue(\.labelKey)
    _ = contents.9.accessibilityValue(\.labelKey)
    _ = contents.10.accessibilityValue(\.labelKey)
    _ = contents.11.accessibilityValue(\.labelKey)
    _ = contents.12.accessibilityValue(\.labelKey)
    _ = contents.13.accessibilityValue(\.labelKey)
}

func testVectorizedAccessibilityValueText() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityValue(\.labelText)
    _ = contents.1.accessibilityValue(\.labelText)
    _ = contents.2.accessibilityValue(\.labelText)
    _ = contents.3.accessibilityValue(\.labelText)
    _ = contents.4.accessibilityValue(\.labelText)
    _ = contents.5.accessibilityValue(\.labelText)
    _ = contents.6.accessibilityValue(\.labelText)
    _ = contents.7.accessibilityValue(\.labelText)
    _ = contents.8.accessibilityValue(\.labelText)
    _ = contents.9.accessibilityValue(\.labelText)
    _ = contents.10.accessibilityValue(\.labelText)
    _ = contents.11.accessibilityValue(\.labelText)
    _ = contents.12.accessibilityValue(\.labelText)
    _ = contents.13.accessibilityValue(\.labelText)
}

func testVectorizedAccessibilityValueString() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityValue(\.identifier)
    _ = contents.1.accessibilityValue(\.identifier)
    _ = contents.2.accessibilityValue(\.identifier)
    _ = contents.3.accessibilityValue(\.identifier)
    _ = contents.4.accessibilityValue(\.identifier)
    _ = contents.5.accessibilityValue(\.identifier)
    _ = contents.6.accessibilityValue(\.identifier)
    _ = contents.7.accessibilityValue(\.identifier)
    _ = contents.8.accessibilityValue(\.identifier)
    _ = contents.9.accessibilityValue(\.identifier)
    _ = contents.10.accessibilityValue(\.identifier)
    _ = contents.11.accessibilityValue(\.identifier)
    _ = contents.12.accessibilityValue(\.identifier)
    _ = contents.13.accessibilityValue(\.identifier)
}

func testVectorizedAccessibilityHidden() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityHidden(\.hidden)
    _ = contents.1.accessibilityHidden(\.hidden)
    _ = contents.2.accessibilityHidden(\.hidden)
    _ = contents.3.accessibilityHidden(\.hidden)
    _ = contents.4.accessibilityHidden(\.hidden)
    _ = contents.5.accessibilityHidden(\.hidden)
    _ = contents.6.accessibilityHidden(\.hidden)
    _ = contents.7.accessibilityHidden(\.hidden)
    _ = contents.8.accessibilityHidden(\.hidden)
    _ = contents.9.accessibilityHidden(\.hidden)
    _ = contents.10.accessibilityHidden(\.hidden)
    _ = contents.11.accessibilityHidden(\.hidden)
    _ = contents.12.accessibilityHidden(\.hidden)
    _ = contents.13.accessibilityHidden(\.hidden)
}

func testVectorizedAccessibilityIdentifier() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.accessibilityIdentifier(\.identifier)
    _ = contents.1.accessibilityIdentifier(\.identifier)
    _ = contents.2.accessibilityIdentifier(\.identifier)
    _ = contents.3.accessibilityIdentifier(\.identifier)
    _ = contents.4.accessibilityIdentifier(\.identifier)
    _ = contents.5.accessibilityIdentifier(\.identifier)
    _ = contents.6.accessibilityIdentifier(\.identifier)
    _ = contents.7.accessibilityIdentifier(\.identifier)
    _ = contents.8.accessibilityIdentifier(\.identifier)
    _ = contents.9.accessibilityIdentifier(\.identifier)
    _ = contents.10.accessibilityIdentifier(\.identifier)
    _ = contents.11.accessibilityIdentifier(\.identifier)
    _ = contents.12.accessibilityIdentifier(\.identifier)
    _ = contents.13.accessibilityIdentifier(\.identifier)
}

func testVectorizedSymbolBy() {
    let rows = chartVectorizedFixture()
    let kind = PlottableProjection<ChartVectorizedRow, String>.value("s", \.series)
    let contents = chartVectorizedContents(rows)
    _ = contents.0.symbol(by: kind)
    _ = contents.1.symbol(by: kind)
    _ = contents.2.symbol(by: kind)
    _ = contents.3.symbol(by: kind)
    _ = contents.4.symbol(by: kind)
    _ = contents.5.symbol(by: kind)
    _ = contents.6.symbol(by: kind)
    _ = contents.7.symbol(by: kind)
    _ = contents.8.symbol(by: kind)
    _ = contents.9.symbol(by: kind)
    _ = contents.10.symbol(by: kind)
    _ = contents.11.symbol(by: kind)
    _ = contents.12.symbol(by: kind)
    _ = contents.13.symbol(by: kind)
}

func testVectorizedOpacity() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    precondition(contents.4.opacity(\.fade).chartPlotRecords.first?.opacity == 1)
    _ = contents.0.opacity(\.fade)
    _ = contents.1.opacity(\.fade)
    _ = contents.2.opacity(\.fade)
    _ = contents.3.opacity(\.fade)
    _ = contents.5.opacity(\.fade)
    _ = contents.6.opacity(\.fade)
    _ = contents.7.opacity(\.fade)
    _ = contents.8.opacity(\.fade)
    _ = contents.9.opacity(\.fade)
    _ = contents.10.opacity(\.fade)
    _ = contents.11.opacity(\.fade)
    _ = contents.12.opacity(\.fade)
    _ = contents.13.opacity(\.fade)
}

func testVectorizedPositionBy() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let contents = chartVectorizedContents(rows)
    _ = contents.0.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.1.position(by: x, axis: .vertical, span: .automatic)
    _ = contents.2.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.3.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.4.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.5.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.6.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.7.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.8.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.9.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.10.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.11.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.12.position(by: x, axis: .horizontal, span: .automatic)
    _ = contents.13.position(by: x, axis: .horizontal, span: .automatic)
}

func testVectorizedLineStyleBy() {
    let rows = chartVectorizedFixture()
    let style = PlottableProjection<ChartVectorizedRow, String>.value("s", \.series)
    let contents = chartVectorizedContents(rows)
    _ = contents.0.lineStyle(by: style)
    _ = contents.1.lineStyle(by: style)
    _ = contents.2.lineStyle(by: style)
    _ = contents.3.lineStyle(by: style)
    _ = contents.4.lineStyle(by: style)
    _ = contents.5.lineStyle(by: style)
    _ = contents.6.lineStyle(by: style)
    _ = contents.7.lineStyle(by: style)
    _ = contents.8.lineStyle(by: style)
    _ = contents.9.lineStyle(by: style)
    _ = contents.10.lineStyle(by: style)
    _ = contents.11.lineStyle(by: style)
    _ = contents.12.lineStyle(by: style)
    _ = contents.13.lineStyle(by: style)
}

func testVectorizedLineStyleKeyPath() {
    let rows = chartVectorizedFixture()
    let contents = chartVectorizedContents(rows)
    _ = contents.0.lineStyle(\.stroke)
    _ = contents.1.lineStyle(\.stroke)
    _ = contents.2.lineStyle(\.stroke)
    _ = contents.3.lineStyle(\.stroke)
    _ = contents.4.lineStyle(\.stroke)
    _ = contents.5.lineStyle(\.stroke)
    _ = contents.6.lineStyle(\.stroke)
    _ = contents.7.lineStyle(\.stroke)
    _ = contents.8.lineStyle(\.stroke)
    _ = contents.9.lineStyle(\.stroke)
    _ = contents.10.lineStyle(\.stroke)
    _ = contents.11.lineStyle(\.stroke)
    _ = contents.12.lineStyle(\.stroke)
    _ = contents.13.lineStyle(\.stroke)
}

func testVectorizedChartContentProtocol() {
    let content: any VectorizedChartContent = VectorizedBarPlotContent<[Int]>()
    _ = content.chartPlotRecords
    precondition(VectorizedBarPlotContent<[Int]>().chartPlotRecords.isEmpty)
    let _: VectorizedBarPlotContent<[Int]>.DataElement.Type = Int.self
    let _: BarPlot<VectorizedBarPlotContent<[Int]>>.DataElement.Type = Int.self
    let _: LinePlot<VectorizedLinePlotContent<[Int]>>.DataElement.Type = Int.self
    let _: AreaPlot<VectorizedAreaPlotContent<[Int]>>.DataElement.Type = Int.self
    let _: PointPlot<VectorizedPointPlotContent<[Int]>>.DataElement.Type = Int.self
    let _: RulePlot<VectorizedRulePlotContent<[Int]>>.DataElement.Type = Int.self
    let _: SectorPlot<VectorizedSectorPlotContent<[Int]>>.DataElement.Type = Int.self
    let _: RectanglePlot<VectorizedRectanglePlotContent<[Int]>>.DataElement.Type = Int.self
}

func testPlottableProjectionType() {
    struct Row { var name: String; var value: Int }
    let row = Row(name: "A", value: 2)
    let projection = PlottableProjection<Row, String>.value("x", \.name)
    precondition(projection.value(from: row) == "A")
    let numeric = PlottableProjection<Row, Int>.value("y", \.value)
    precondition(numeric.value(from: row) == 2)
}

func testPlottableProjectionConstantValue() {
    struct Row { var name: String; var value: Int }
    precondition(PlottableProjection<Row, Int>.value("y", 3).value(from: Row(name: "A", value: 0)) == 3)
    precondition(PlottableProjection<Row, Int>.value(Text("y"), 1).value(from: Row(name: "A", value: 0)) == 1)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringKey("y"), 1).value(from: Row(name: "A", value: 0)) == 1)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringResource("y"), 1).value(from: Row(name: "A", value: 0)) == 1)
}

func testPlottableProjectionKeyPathValue() {
    struct Row { var name: String; var value: Int }
    let row = Row(name: "A", value: 2)
    precondition(PlottableProjection<Row, Int>.value("y", \.value).value(from: row) == 2)
    precondition(PlottableProjection<Row, Int>.value(Text("y"), \.value).value(from: row) == 2)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringKey("y"), \.value).value(from: row) == 2)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringResource("y"), \.value).value(from: row) == 2)
}

func testPlottableProjectionRangeConstant() {
    struct Row { var name: String; var value: Int }
    let row = Row(name: "A", value: 2)
    precondition(PlottableProjection<Row, Int>.value("y", 1, 4).value(from: row) == 1)
    precondition(PlottableProjection<Row, Int>.value(Text("y"), 1, 4).value(from: row) == 1)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringKey("y"), 1, 4).value(from: row) == 1)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringResource("y"), 1, 4).value(from: row) == 1)
}

func testPlottableProjectionRangeKeyPath() {
    struct Row { var name: String; var value: Int }
    let row = Row(name: "A", value: 2)
    precondition(PlottableProjection<Row, Int>.value("y", \.value, \.value).value(from: row) == 2)
    precondition(PlottableProjection<Row, Int>.value(Text("y"), \.value, \.value).value(from: row) == 2)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringKey("y"), \.value, \.value).value(from: row) == 2)
    precondition(PlottableProjection<Row, Int>.value(LocalizedStringResource("y"), \.value, \.value).value(from: row) == 2)
}

func testPlottableProjectionDateUnitKeyPath() {
    struct Row { var day: Date }
    let row = Row(day: Date(timeIntervalSinceReferenceDate: 8))
    precondition(PlottableProjection<Row, Date>.value("day", \.day, unit: .day).value(from: row) == row.day)
    precondition(PlottableProjection<Row, Date>.value(Text("day"), \.day, unit: .day).value(from: row) == row.day)
    precondition(PlottableProjection<Row, Date>.value(LocalizedStringKey("day"), \.day, unit: .day).value(from: row) == row.day)
    precondition(PlottableProjection<Row, Date>.value(LocalizedStringResource("day"), \.day, unit: .day).value(from: row) == row.day)
}

func testPlottableProjectionDateUnitConstant() {
    struct Row { var day: Date }
    let day = Date(timeIntervalSinceReferenceDate: 8)
    let row = Row(day: Date(timeIntervalSinceReferenceDate: 0))
    precondition(PlottableProjection<Row, Date>.value("day", day, unit: .day).value(from: row) == day)
    precondition(PlottableProjection<Row, Date>.value(Text("day"), day, unit: .day).value(from: row) == day)
    precondition(PlottableProjection<Row, Date>.value(LocalizedStringKey("day"), day, unit: .day).value(from: row) == day)
    precondition(PlottableProjection<Row, Date>.value(LocalizedStringResource("day"), day, unit: .day).value(from: row) == day)
}

func testVectorizedBarPlotExtraInits() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    let lo = PlottableProjection<ChartVectorizedRow, Int>.value("lo", \.lo)
    let hi = PlottableProjection<ChartVectorizedRow, Int>.value("hi", \.hi)
    precondition(BarPlot(rows, x: x, yStart: 1, yEnd: 4).chartPlotRecords.first?.yEnd == 4)
    precondition(BarPlot(rows, xStart: 0, xEnd: 10, yStart: lo, yEnd: hi).chartPlotRecords.first?.xEnd == 10)
    precondition(BarPlot(rows, xStart: y, xEnd: y, yStart: 0, yEnd: 5).chartPlotRecords.first?.xStart == 1)
    precondition(BarPlot(rows, xStart: 0, xEnd: 10, y: y).chartPlotRecords.first?.y == 1)
    precondition(BarPlot(rows, xStart: y, xEnd: y, y: y).chartPlotRecords.first?.y == 1)
}

func testVectorizedLinePlotExtraInits() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    let series = PlottableProjection<ChartVectorizedRow, String>.value("s", \.series)
    precondition(LinePlot(rows, x: x, y: y, series: series).chartPlotRecords.first?.series == "s")
}

func testVectorizedAreaPlotExtraInits() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    let series = PlottableProjection<ChartVectorizedRow, String>.value("s", \.series)
    let lo = PlottableProjection<ChartVectorizedRow, Int>.value("lo", \.lo)
    let hi = PlottableProjection<ChartVectorizedRow, Int>.value("hi", \.hi)
    precondition(AreaPlot(rows, x: x, y: y, series: series, stacking: .center).chartPlotRecords.first?.stacking == .center)
    precondition(AreaPlot(rows, x: x, yStart: lo, yEnd: hi).chartPlotRecords.first?.yEnd == 4)
    precondition(AreaPlot(rows, xStart: y, xEnd: y, y: y).chartPlotRecords.first?.y == 1)
}

func testVectorizedPointPlotExtraInits() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    precondition(PointPlot(rows, x: 3, y: y).chartPlotRecords.first?.x == 3)
    precondition(PointPlot(rows, x: x, y: 8).chartPlotRecords.first?.y == 8)
}

func testVectorizedRulePlotExtraInits() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    let lo = PlottableProjection<ChartVectorizedRow, Int>.value("lo", \.lo)
    let hi = PlottableProjection<ChartVectorizedRow, Int>.value("hi", \.hi)
    precondition(RulePlot(rows, x: x, yStart: 0, yEnd: 4).chartPlotRecords.first?.yEnd == 4)
    precondition(RulePlot(rows, x: 5, yStart: lo, yEnd: hi).chartPlotRecords.first?.x == 5)
    precondition(RulePlot(rows, xStart: y, xEnd: y, y: 2).chartPlotRecords.first?.y == 2)
    precondition(RulePlot(rows, xStart: 0, xEnd: 10, y: y).chartPlotRecords.first?.xEnd == 10)
}

func testVectorizedRectanglePlotExtraInits() {
    let rows = chartVectorizedFixture()
    let x = PlottableProjection<ChartVectorizedRow, String>.value("x", \.name)
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    let lo = PlottableProjection<ChartVectorizedRow, Int>.value("lo", \.lo)
    let hi = PlottableProjection<ChartVectorizedRow, Int>.value("hi", \.hi)
    precondition(RectanglePlot(rows, x: x, y: y).chartPlotRecords.first?.kind == .rectangle)
    precondition(RectanglePlot(rows, x: x, yStart: lo, yEnd: hi).chartPlotRecords.first?.yEnd == 4)
    precondition(RectanglePlot(rows, xStart: y, xEnd: y, y: y).chartPlotRecords.first?.y == 1)
}

func testVectorizedSectorPlotExtraInits() {
    let rows = chartVectorizedFixture()
    let y = PlottableProjection<ChartVectorizedRow, Int>.value("y", \.value)
    precondition(
        SectorPlot(rows, angle: y, innerRadius: .automatic, outerRadius: .automatic, angularInset: 1)
            .chartPlotRecords.first?.kind == .sector
    )
}

func testChart3DFailClosed() {
    let pose = Chart3DPose.default
    _ = pose
    _ = Chart3DCameraProjection.perspective
    _ = Chart3DCameraProjection.orthographic
    _ = BasicChart3DSymbolShape.sphere
    _ = BasicChart3DSurfaceStyle()
}

func testChartXAxisHiddenStores() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 1))
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    precondition(chart.xAxisStorage?.visibility == .hidden)
    precondition(chart.yAxisStorage?.visibility == .hidden)
}

func testNiceDomainInference() {
    let scale = ChartScale.linear(domain: 0.2...9.7, range: 0...100)
    let nice = scale.niceDomain(desiredTicks: 5)
    precondition(nice.min == 0)
    precondition(nice.max == 10)
}

func testSectorMarkInnerRadius() {
    let mark = SectorMark(
        angle: .value("share", 0.5),
        innerRadius: .automatic,
        outerRadius: .automatic,
        angularInset: 2
    )
    precondition(mark.angle == 0.25 || mark.angle == 0.5)
    precondition(mark.angularInset == 2)
}
