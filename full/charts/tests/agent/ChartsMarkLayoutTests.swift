import Charts
import Foundation

private struct ChartLayoutRow: Identifiable {
    var id: String
    var name: String
    var value: Int
    var lo: Int
    var hi: Int
    var yStartPx: CGFloat
    var yEndPx: CGFloat
    var xStartPx: CGFloat
    var xEndPx: CGFloat
    var angle: Double
    var inset: CGFloat
}

private func chartLayoutRows() -> [ChartLayoutRow] {
    [
        ChartLayoutRow(
            id: "a", name: "A", value: 3, lo: 1, hi: 4,
            yStartPx: 0, yEndPx: 30, xStartPx: 0, xEndPx: 40,
            angle: 1, inset: 2
        ),
        ChartLayoutRow(
            id: "b", name: "B", value: 1, lo: 0, hi: 2,
            yStartPx: 5, yEndPx: 25, xStartPx: 10, xEndPx: 50,
            angle: 1, inset: 2
        ),
    ]
}

func testMarkDimensionAutomaticDescription() {
    let automatic = MarkDimension.automatic
    precondition(automatic.kind == "automatic")
    precondition(automatic.description == "automatic")
    precondition(MarkDimension().description == "automatic")
    let resolved = chartResolveMarkDimension(automatic, span: 50, defaultInset: 4)
    precondition(abs(resolved.origin - 4) < 0.0001)
    precondition(abs(resolved.length - 42) < 0.0001)
}

func testMarkDimensionInsetPixels() {
    let inset = MarkDimension.inset(8)
    precondition(inset.kind == "inset")
    precondition(inset.value == 8)
    precondition(inset.description == "inset")
    let resolved = chartResolveMarkDimension(inset, span: 50, defaultInset: 4)
    precondition(abs(resolved.origin - 8) < 0.0001)
    precondition(abs(resolved.length - 34) < 0.0001)
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 3), width: .inset(8), stacking: .unstacked)
        BarMark(x: .value("x", "B"), y: .value("y", 1), width: .inset(8), stacking: .unstacked)
    }
    .chartYScale(domain: 0...4)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    precondition(bars.count == 2)
    // 100-wide, two bands of 50. inset 8 → x=8 width=34; second band x=58 width=34.
    precondition(abs(bars[0].frame.minX - 8) < 0.0001)
    precondition(abs(bars[0].frame.width - 34) < 0.0001)
    precondition(abs(bars[1].frame.minX - 58) < 0.0001)
    precondition(abs(bars[1].frame.width - 34) < 0.0001)
}

func testMarkDimensionFixedPixels() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 3), width: .fixed(20), stacking: .unstacked)
        BarMark(x: .value("x", "B"), y: .value("y", 1), width: .fixed(20), stacking: .unstacked)
    }
    .chartYScale(domain: 0...4)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    // Band 50, fixed 20 centered: origin 15. A at 15, B at 65.
    precondition(abs(bars[0].frame.minX - 15) < 0.0001)
    precondition(abs(bars[0].frame.width - 20) < 0.0001)
    precondition(abs(bars[1].frame.minX - 65) < 0.0001)
    precondition(abs(bars[1].frame.width - 20) < 0.0001)
    precondition(abs(bars[0].frame.minY - 10) < 0.0001)
    precondition(abs(bars[0].frame.height - 30) < 0.0001)
}

func testMarkDimensionRatioPixels() {
    let ratio = MarkDimension.ratio(0.5)
    precondition(ratio.kind == "ratio")
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 3), width: .ratio(0.5), stacking: .unstacked)
        BarMark(x: .value("x", "B"), y: .value("y", 1), width: .ratio(0.5), stacking: .unstacked)
    }
    .chartYScale(domain: 0...4)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    // Band 50 * 0.5 = 25, origin 12.5.
    precondition(abs(bars[0].frame.minX - 12.5) < 0.0001)
    precondition(abs(bars[0].frame.width - 25) < 0.0001)
    precondition(abs(bars[1].frame.minX - 62.5) < 0.0001)
    precondition(abs(bars[1].frame.width - 25) < 0.0001)
}

func testMarkDimensionsAutomaticInsetAndKeyPath() {
    let auto = MarkDimensions<ChartLayoutRow>.automatic
    precondition(auto.kind == "automatic")
    let inset = MarkDimensions<ChartLayoutRow>.inset(3)
    precondition(inset.kind == "inset")
    precondition(inset.value == 3)
    let keyed = MarkDimensions<ChartLayoutRow>.inset(\.inset)
    let row = chartLayoutRows()[0]
    let resolved = keyed.resolved(for: row)
    precondition(resolved.kind == "inset")
    precondition(resolved.value == 2)
}

func testBarPlotKeyPathYStartYEndWidthPixels() {
    let rows = chartLayoutRows()
    let x = PlottableProjection<ChartLayoutRow, String>.value("x", \.name)
    let plot = BarPlot(
        rows,
        x: x,
        yStart: \.yStartPx,
        yEnd: \.yEndPx,
        width: .fixed(20),
        stacking: .unstacked
    )
    precondition(plot.chartPlotRecords.count == 2)
    precondition(plot.chartPlotRecords[0].yStart == 0)
    precondition(plot.chartPlotRecords[0].yEnd == 30)
    precondition(plot.chartPlotRecords[0].markWidth.kind == "fixed")
    let chart = Chart { plot }
        .chartYScale(domain: 0...40)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    // Category A/B, band 50, fixed 20 centered at 15 / 65.
    // Y 0...40 inverted over 0...40: yStart 0 → 40, yEnd 30 → 10, height 30.
    precondition(abs(bars[0].frame.minX - 15) < 0.0001)
    precondition(abs(bars[0].frame.width - 20) < 0.0001)
    precondition(abs(bars[0].frame.minY - 10) < 0.0001)
    precondition(abs(bars[0].frame.height - 30) < 0.0001)
}

func testBarPlotKeyPathXStartXEndPixels() {
    let rows = chartLayoutRows()
    let xStart = PlottableProjection<ChartLayoutRow, Int>.value("xs", \.lo)
    let xEnd = PlottableProjection<ChartLayoutRow, Int>.value("xe", \.hi)
    let plot = BarPlot(rows, xStart: xStart, xEnd: xEnd, yStart: \.yStartPx, yEnd: \.yEndPx)
    precondition(plot.chartPlotRecords[0].xStart == 1)
    precondition(plot.chartPlotRecords[0].xEnd == 4)
    let yStart = PlottableProjection<ChartLayoutRow, Int>.value("ys", \.lo)
    let yEnd = PlottableProjection<ChartLayoutRow, Int>.value("ye", \.hi)
    let plotB = BarPlot(rows, xStart: \.xStartPx, xEnd: \.xEndPx, yStart: yStart, yEnd: yEnd)
    precondition(plotB.chartPlotRecords[0].xStart == 0)
    precondition(plotB.chartPlotRecords[0].xEnd == 40)
    let chart = Chart { plotB }
        .chartXScale(domain: 0...100)
        .chartYScale(domain: 0...4)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    // x 0...40 on domain 0...100 → pixels 0...40.
    // Unstacked interval uses authored yStart/yEnd: lo=1 → 30, hi=4 → 0, height 30.
    precondition(!bars.isEmpty)
    precondition(abs(bars[0].frame.minX - 0) < 0.0001)
    precondition(abs(bars[0].frame.width - 40) < 0.0001)
    precondition(abs(bars[0].frame.minY - 0) < 0.0001)
    precondition(abs(bars[0].frame.height - 30) < 0.0001)
}

func testBarPlotKeyPathHeightStackingPixels() {
    let rows = chartLayoutRows()
    let y = PlottableProjection<ChartLayoutRow, Int>.value("y", \.value)
    let plot = BarPlot(
        [rows[0]],
        xStart: \.xStartPx,
        xEnd: \.xEndPx,
        y: y,
        height: .automatic,
        stacking: .unstacked
    )
    precondition(plot.chartPlotRecords[0].y == 3)
    precondition(plot.chartPlotRecords[0].stacking == .unstacked)
    let chart = Chart { plot }
        .chartXScale(domain: 0...100)
        .chartYScale(domain: 0...4)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    // First row x 0...40 → pixels 0...40. y=3 of 0...4 inverted → y=10, height 30.
    precondition(abs(bars[0].frame.minX - 0) < 0.0001)
    precondition(abs(bars[0].frame.width - 40) < 0.0001)
    precondition(abs(bars[0].frame.minY - 10) < 0.0001)
    precondition(abs(bars[0].frame.height - 30) < 0.0001)
}

func testRectanglePlotKeyPathYStartYEndWidth() {
    let rows = chartLayoutRows()
    let x = PlottableProjection<ChartLayoutRow, String>.value("x", \.name)
    let plot = RectanglePlot(rows, x: x, yStart: \.yStartPx, yEnd: \.yEndPx, width: .inset(2))
    precondition(plot.chartPlotRecords[0].yStart == 0)
    precondition(plot.chartPlotRecords[0].markWidth.kind == "inset")
    let chart = Chart { plot }
        .chartYScale(domain: 0...40)
    let marks = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .rectangle }
    precondition(abs(marks[0].frame.minX - 2) < 0.0001)
    precondition(abs(marks[0].frame.width - 46) < 0.0001)
}

func testRectanglePlotKeyPathIntervalInits() {
    let rows = chartLayoutRows()
    let xStart = PlottableProjection<ChartLayoutRow, Int>.value("xs", \.lo)
    let xEnd = PlottableProjection<ChartLayoutRow, Int>.value("xe", \.hi)
    let plotA = RectanglePlot(rows, xStart: xStart, xEnd: xEnd, yStart: \.yStartPx, yEnd: \.yEndPx)
    precondition(plotA.chartPlotRecords[0].xStart == 1)
    precondition(plotA.chartPlotRecords[0].yEnd == 30)
    let plotB = RectanglePlot(rows, xStart: \.xStartPx, xEnd: \.xEndPx, yStart: \.yStartPx, yEnd: \.yEndPx)
    precondition(plotB.chartPlotRecords[0].xEnd == 40)
    let yStart = PlottableProjection<ChartLayoutRow, Int>.value("ys", \.lo)
    let yEnd = PlottableProjection<ChartLayoutRow, Int>.value("ye", \.hi)
    let plotC = RectanglePlot(rows, xStart: \.xStartPx, xEnd: \.xEndPx, yStart: yStart, yEnd: yEnd)
    precondition(plotC.chartPlotRecords[0].yStart == 1)
    let y = PlottableProjection<ChartLayoutRow, Int>.value("y", \.value)
    let plotD = RectanglePlot(rows, xStart: \.xStartPx, xEnd: \.xEndPx, y: y, height: .ratio(1))
    precondition(plotD.chartPlotRecords[0].y == 3)
    precondition(plotD.chartPlotRecords[0].markHeight.kind == "ratio")
    let chart = Chart { plotB }
        .chartXScale(domain: 0...100)
        .chartYScale(domain: 0...40)
    let marks = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .rectangle }
    // x 0...40 → 0...40px. y 0...30 inverted over 0...40 → minY=10 height=30.
    precondition(abs(marks[0].frame.minX - 0) < 0.0001)
    precondition(abs(marks[0].frame.width - 40) < 0.0001)
    precondition(abs(marks[0].frame.minY - 10) < 0.0001)
    precondition(abs(marks[0].frame.height - 30) < 0.0001)
}

func testRulePlotKeyPathInitsPixels() {
    let rows = chartLayoutRows()
    let x = PlottableProjection<ChartLayoutRow, String>.value("x", \.name)
    let plotA = RulePlot(rows, x: x, yStart: \.yStartPx, yEnd: \.yEndPx)
    precondition(plotA.chartPlotRecords[0].kind == .rule)
    precondition(plotA.chartPlotRecords[0].yStart == 0)
    let yStart = PlottableProjection<ChartLayoutRow, Int>.value("ys", \.lo)
    let yEnd = PlottableProjection<ChartLayoutRow, Int>.value("ye", \.hi)
    let plotB = RulePlot(rows, x: \.xStartPx, yStart: yStart, yEnd: yEnd)
    precondition(plotB.chartPlotRecords[0].x == 0)
    let xStart = PlottableProjection<ChartLayoutRow, Int>.value("xs", \.lo)
    let xEnd = PlottableProjection<ChartLayoutRow, Int>.value("xe", \.hi)
    let plotC = RulePlot(rows, xStart: xStart, xEnd: xEnd, y: \.yStartPx)
    precondition(plotC.chartPlotRecords[0].y == 0)
    let y = PlottableProjection<ChartLayoutRow, Int>.value("y", \.value)
    let plotD = RulePlot(rows, xStart: \.xStartPx, xEnd: \.xEndPx, y: y)
    precondition(plotD.chartPlotRecords[0].y == 3)
    let chart = Chart { plotD }
        .chartXScale(domain: 0...100)
        .chartYScale(domain: 0...4)
    let rules = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .rule }
    // Horizontal rule at y=3 → pixel 10. x 0...40 → 0...40.
    precondition(abs(rules[0].frame.minY - 10) < 0.0001)
    precondition(abs(rules[0].frame.minX - 0) < 0.0001)
    precondition(abs(rules[0].frame.width - 40) < 0.0001)
}

func testPointPlotKeyPathInitsPixels() {
    let rows = chartLayoutRows()
    let x = PlottableProjection<ChartLayoutRow, String>.value("x", \.name)
    let plotA = PointPlot(rows, x: x, y: \.yEndPx)
    precondition(plotA.chartPlotRecords[0].y == 30)
    let y = PlottableProjection<ChartLayoutRow, Int>.value("y", \.value)
    let plotB = PointPlot(rows, x: \.xStartPx, y: y)
    precondition(plotB.chartPlotRecords[0].x == 0)
    precondition(plotB.chartPlotRecords[0].y == 3)
    let chart = Chart { plotB }
        .chartXScale(domain: 0...100)
        .chartYScale(domain: 0...4)
    let points = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .point }
    // x=0 → 0, y=3 of 0...4 inverted → 10. Default point size 6, so frame origin (-3, 7).
    precondition(abs((points[0].points.first?.x ?? -1) - 0) < 0.0001)
    precondition(abs((points[0].points.first?.y ?? -1) - 10) < 0.0001)
}

func testSectorPlotAngleInnerOuterKeyPathPixels() {
    let rows = chartLayoutRows()
    let angle = PlottableProjection<ChartLayoutRow, Double>.value("a", \.angle)
    let plot = SectorPlot(
        rows,
        angle: angle,
        innerRadius: .ratio(0.25),
        outerRadius: .automatic,
        angularInset: \.inset
    )
    precondition(plot.chartPlotRecords.count == 2)
    precondition(plot.chartPlotRecords[0].angle == 1)
    precondition(plot.chartPlotRecords[0].innerRadius.kind == "ratio")
    precondition(plot.chartPlotRecords[0].angularInset == 2)
    let chart = Chart { plot }
    let sectors = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .sector }
    precondition(sectors.count == 2)
    precondition(abs((sectors[0].center?.x ?? -1) - 50) < 0.0001)
    precondition(abs((sectors[0].center?.y ?? -1) - 20) < 0.0001)
    precondition(abs((sectors[0].outerRadius ?? -1) - 20) < 0.0001)
    precondition(abs((sectors[0].innerRadius ?? -1) - 5) < 0.0001)
}

func testSectorMarkAutomaticFullCirclePixels() {
    let chart = Chart {
        SectorMark(angle: .value("share", 1.0))
    }
    let sectors = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .sector }
    precondition(sectors.count == 1)
    // 100×40 plot, center (50, 20), max radius 20, full circle.
    precondition(abs((sectors[0].center?.x ?? -1) - 50) < 0.0001)
    precondition(abs((sectors[0].center?.y ?? -1) - 20) < 0.0001)
    precondition(abs((sectors[0].outerRadius ?? -1) - 20) < 0.0001)
    precondition(abs((sectors[0].innerRadius ?? -1) - 0) < 0.0001)
    precondition(abs((sectors[0].startAngle ?? 0) - chartSectorStartAngle) < 0.0001)
    precondition(abs((sectors[0].endAngle ?? 0) - (chartSectorStartAngle + 2 * Double.pi)) < 0.0001)
    precondition(abs(sectors[0].frame.minX - 30) < 0.0001)
    precondition(abs(sectors[0].frame.minY - 0) < 0.0001)
    precondition(abs(sectors[0].frame.width - 40) < 0.0001)
    precondition(abs(sectors[0].frame.height - 40) < 0.0001)
}

func testSectorMarkSplitPixels() {
    let chart = Chart {
        SectorMark(angle: .value("a", 1.0))
        SectorMark(angle: .value("b", 1.0))
    }
    let sectors = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .sector }
    precondition(sectors.count == 2)
    // Equal halves from -π/2. First sweep π, end at π/2. Right semicircle x=50...70.
    precondition(abs((sectors[0].startAngle ?? 0) - (-Double.pi / 2)) < 0.0001)
    precondition(abs((sectors[0].endAngle ?? 0) - (Double.pi / 2)) < 0.0001)
    precondition(abs(sectors[0].frame.minX - 50) < 0.0001)
    precondition(abs(sectors[0].frame.width - 20) < 0.0001)
    precondition(abs(sectors[1].frame.minX - 30) < 0.0001)
    precondition(abs(sectors[1].frame.width - 20) < 0.0001)
}

func testSectorMarkInsetAndRatioRadiusPixels() {
    let inset = Chart {
        SectorMark(
            angle: .value("share", 1.0),
            innerRadius: .inset(4),
            outerRadius: .inset(4)
        )
    }
    let insetSectors = inset.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .sector }
    // maxR=20, inset 4 → outer 16, inner 16. Wait inner automaticValue is 0, inset means maxR-4=16.
    // Both inner and outer inset(4) → both 16. Degenerate ring.
    precondition(abs((insetSectors[0].outerRadius ?? -1) - 16) < 0.0001)
    precondition(abs((insetSectors[0].innerRadius ?? -1) - 16) < 0.0001)
    let ratio = Chart {
        SectorMark(
            angle: .value("share", 1.0),
            innerRadius: .ratio(0.25),
            outerRadius: .ratio(0.5)
        )
    }
    let ratioSectors = ratio.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .sector }
    precondition(abs((ratioSectors[0].innerRadius ?? -1) - 5) < 0.0001)
    precondition(abs((ratioSectors[0].outerRadius ?? -1) - 10) < 0.0001)
    let fixed = Chart {
        SectorMark(
            angle: .value("share", 1.0),
            innerRadius: .fixed(6),
            outerRadius: .fixed(12)
        )
    }
    let fixedSectors = fixed.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .sector }
    precondition(abs((fixedSectors[0].innerRadius ?? -1) - 6) < 0.0001)
    precondition(abs((fixedSectors[0].outerRadius ?? -1) - 12) < 0.0001)
}

func testMajorValueAlignmentPage() {
    let alignment = MajorValueAlignment<Double>.page
    precondition(alignment.kind == "page")
    let snapped = chartSnapMajorValue(7, alignmentKind: alignment.kind, unitValue: alignment.unitValue, domain: 0...10)
    precondition(snapped == 0)
}

func testMajorValueAlignmentUnitSnapPixels() {
    let alignment = MajorValueAlignment<Double>.unit(5)
    precondition(alignment.kind == "unit")
    precondition(alignment.unitValue == 5)
    // Domain 0...10, value 3 snaps to 5 (nearer than 0). Pixel on 100-wide: 50.
    let snapped = chartSnapMajorValue(3, alignmentKind: alignment.kind, unitValue: alignment.unitValue, domain: 0...10)
    precondition(snapped == 5)
    let xScale = ChartScale.linear(domain: 0...10, range: 0...100)
    precondition(abs(xScale.position(forNumeric: snapped) - 50) < 0.0001)
    let nearZero = chartSnapMajorValue(1, alignmentKind: alignment.kind, unitValue: alignment.unitValue, domain: 0...10)
    precondition(nearZero == 0)
}

func testMajorValueAlignmentMatching() {
    let components = DateComponents(hour: 0, minute: 0, second: 0)
    let alignment = MajorValueAlignment<Date>.matching(components)
    precondition(alignment.kind == "matching")
    precondition(alignment.matching?.hour == 0)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let date = Date(timeIntervalSinceReferenceDate: 15 * 3600 + 30 * 60)
    let snapped = chartSnapMatchingDate(date, components: components, calendar: calendar)
    let parts = calendar.dateComponents([.hour, .minute, .second], from: snapped)
    precondition(parts.hour == 0)
    precondition(parts.minute == 0)
    precondition(parts.second == 0)
}

func testVectorizedBarPlotContentBodyDataElement() {
    typealias Element = VectorizedBarPlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    typealias Body = VectorizedBarPlotContent<[Int]>.Body
    precondition(Body.self == EmptyView.self)
    let content = VectorizedBarPlotContent<[Int]>(records: [
        ChartPlotRecord(kind: .bar, x: 1, y: 2),
    ])
    _ = content.body
    precondition(content.chartPlotRecords[0].y == 2)
}

func testVectorizedAreaPlotContentBodyDataElement() {
    typealias Element = VectorizedAreaPlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    precondition(VectorizedAreaPlotContent<[Int]>.Body.self == EmptyView.self)
    precondition(VectorizedAreaPlotContent<[Int]>().chartPlotRecords.isEmpty)
}

func testVectorizedLinePlotContentBodyDataElement() {
    typealias Element = VectorizedLinePlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    precondition(VectorizedLinePlotContent<[Int]>.Body.self == EmptyView.self)
    precondition(VectorizedLinePlotContent<[Int]>().chartPlotRecords.isEmpty)
}

func testVectorizedSectorPlotContentBodyDataElement() {
    typealias Element = VectorizedSectorPlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    precondition(VectorizedSectorPlotContent<[Int]>.Body.self == EmptyView.self)
    precondition(VectorizedSectorPlotContent<[Int]>().chartPlotRecords.isEmpty)
}

func testVectorizedRulePlotContentBodyDataElement() {
    typealias Element = VectorizedRulePlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    precondition(VectorizedRulePlotContent<[Int]>.Body.self == EmptyView.self)
}

func testVectorizedPointPlotContentBodyDataElement() {
    typealias Element = VectorizedPointPlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    precondition(VectorizedPointPlotContent<[Int]>.Body.self == EmptyView.self)
}

func testVectorizedRectanglePlotContentBodyDataElement() {
    typealias Element = VectorizedRectanglePlotContent<[Int]>.DataElement
    precondition(Element.self == Int.self)
    precondition(VectorizedRectanglePlotContent<[Int]>.Body.self == EmptyView.self)
}

func testBarPlotBodyDataElement() {
    typealias Plot = BarPlot<VectorizedBarPlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
    let plot = BarPlot<VectorizedBarPlotContent<[ChartLayoutRow]>>(records: [])
    _ = plot.body
}

func testRectanglePlotBodyDataElement() {
    typealias Plot = RectanglePlot<VectorizedRectanglePlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
}

func testSectorPlotBodyDataElement() {
    typealias Plot = SectorPlot<VectorizedSectorPlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
}

func testLinePlotBodyDataElement() {
    typealias Plot = LinePlot<VectorizedLinePlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
}

func testAreaPlotBodyDataElement() {
    typealias Plot = AreaPlot<VectorizedAreaPlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
}

func testRulePlotBodyDataElement() {
    typealias Plot = RulePlot<VectorizedRulePlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
}

func testPointPlotBodyDataElement() {
    typealias Plot = PointPlot<VectorizedPointPlotContent<[ChartLayoutRow]>>
    precondition(Plot.DataElement.self == ChartLayoutRow.self)
    precondition(Plot.Body.self == EmptyView.self)
}

func testBuilderConditionalBody() {
    typealias Conditional = BuilderConditional<LineMark, BarMark>
    precondition(Conditional.Body.self == EmptyView.self)
    let conditional = BuilderConditional<LineMark, BarMark>(
        storage: .first(LineMark(x: .value("x", 1), y: .value("y", 2)))
    )
    _ = conditional.body
    precondition(conditional.chartPlotRecords[0].kind == .line)
}

func testBasicChart3DSurfaceStyleHeightBased() {
    let height = BasicChart3DSurfaceStyle.heightBased
    precondition(height.kind == "heightBased")
    precondition(height.yRangeMin == 0)
    precondition(height.yRangeMax == 1)
    let ranged = BasicChart3DSurfaceStyle.heightBased(yRange: 2...8)
    precondition(ranged.yRangeMin == 2)
    precondition(ranged.yRangeMax == 8)
    let gradient = BasicChart3DSurfaceStyle.heightBased(Gradient(colors: [.blue, .black]), yRange: 0...10)
    precondition(gradient.gradientName == "gradient-2")
    precondition(gradient.yRangeMax == 10)
    let normal = BasicChart3DSurfaceStyle.normalBased
    precondition(normal.kind == "normalBased")
    precondition(height != ranged)
    precondition(height == BasicChart3DSurfaceStyle.heightBased(yRange: 0...1))
    var hasher = Hasher()
    height.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(height.hashValue == BasicChart3DSurfaceStyle.heightBased.hashValue)
}

func testChart3DDataInitsFailClosed() {
    struct Item: Identifiable {
        var id: String
        var z: Double
    }
    let items = [Item(id: "a", z: 1), Item(id: "b", z: 2)]
    let chartA = Chart3D(items, id: \.id) { item in
        SurfacePlot()
    }
    _ = chartA.body
    _ = chartA.content
    let chartB = Chart3D(items) { _ in
        SurfaceMark()
    }
    _ = chartB.body
}

func testAnyAxisMarkErasingInit() {
    let erased = AnyAxisMark(erasing: AxisGridLine())
    _ = erased.body
    let existential = AnyAxisMark(AxisTick() as any AxisMark)
    _ = existential.body
}

func testPlotInitCollectsKeyPathBars() {
    let rows = chartLayoutRows()
    let x = PlottableProjection<ChartLayoutRow, String>.value("x", \.name)
    let plot = Plot {
        BarPlot(rows, x: x, yStart: \.yStartPx, yEnd: \.yEndPx, width: .automatic, stacking: .unstacked)
    }
    precondition(plot.chartPlotRecords.count == 2)
    _ = plot.body
}

func testRectangleMarkWidthPixels() {
    let chart = Chart {
        RectangleMark(
            x: .value("x", "A"),
            yStart: .value("lo", 0.0),
            yEnd: .value("hi", 3.0),
            width: .fixed(10)
        )
        RectangleMark(
            x: .value("x", "B"),
            yStart: .value("lo", 0.0),
            yEnd: .value("hi", 1.0),
            width: .fixed(10)
        )
    }
    .chartYScale(domain: 0...4)
    let marks = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .rectangle }
    precondition(abs(marks[0].frame.width - 10) < 0.0001)
    precondition(abs(marks[0].frame.minX - 20) < 0.0001)
}

func testChartProxyPositionRangeCategoryPixels() {
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 3), stacking: .unstacked)
        BarMark(x: .value("x", "B"), y: .value("y", 1), stacking: .unstacked)
    }
    .chartYScale(domain: 0...4)
    let proxy = chart.resolvedProxy(plotArea: ChartFixedPlotFixture.plotArea)
    let aRange = proxy.positionRange(forX: "A")
    let bRange = proxy.positionRange(forX: "B")
    precondition(aRange != nil)
    precondition(abs((aRange?.lowerBound ?? -1) - 0) < 0.0001)
    precondition(abs((aRange?.upperBound ?? -1) - 50) < 0.0001)
    precondition(abs((bRange?.lowerBound ?? -1) - 50) < 0.0001)
    precondition(abs((bRange?.upperBound ?? -1) - 100) < 0.0001)
    let yRange = proxy.positionRange(forY: 3)
    // Domain 0...4 inverted over 0...40 → y=3 maps to 10...10.
    precondition(abs((yRange?.lowerBound ?? -1) - 10) < 0.0001)
    precondition(abs((yRange?.upperBound ?? -1) - 10) < 0.0001)
    let rect = proxy.positionRange(for: (x: "A", y: 3))
    precondition(abs((rect?.minX ?? -1) - 0) < 0.0001)
    precondition(abs((rect?.width ?? -1) - 50) < 0.0001)
    precondition(abs((rect?.minY ?? -1) - 10) < 0.0001)
    precondition(abs((rect?.height ?? -1) - 0) < 0.0001)
}

func testChartProxyValueAtPointAndAnglePixels() {
    let chart = Chart {
        BarMark(x: .value("x", 0), y: .value("y", 0), stacking: .unstacked)
        BarMark(x: .value("x", 10), y: .value("y", 4), stacking: .unstacked)
    }
    .chartXScale(domain: 0...10)
    .chartYScale(domain: 0...4)
    let proxy = chart.resolvedProxy(plotArea: ChartFixedPlotFixture.plotArea)
    let decoded = proxy.value(at: CGPoint(x: 50, y: 20), as: (Double, Double).self)
    precondition(decoded != nil)
    precondition(abs((decoded?.0 ?? -1) - 5) < 0.0001)
    precondition(abs((decoded?.1 ?? -1) - 2) < 0.0001)
    // Plot center (50, 20). Point (70, 20) is due east → atan2(0, 20) = 0.
    let east = proxy.angle(at: CGPoint(x: 70, y: 20))
    precondition(abs(east.radians - 0) < 0.0001)
    // Point (50, 0) is due north in y-down space → atan2(-20, 0) = -π/2.
    let north = proxy.angle(at: CGPoint(x: 50, y: 0))
    precondition(abs(north.radians - (-Double.pi / 2)) < 0.0001)
}

func testChartContentPositionSpanPixels() {
    let attributed = BarMark(x: .value("x", "A"), y: .value("y", 3), stacking: .unstacked)
        .position(by: .value("series", "s"), axis: .horizontal, span: .fixed(20))
    precondition(attributed.chartPlotRecords[0].layout.positionBy != nil)
    precondition(attributed.chartPlotRecords[0].markWidth.kind == "fixed")
    precondition(attributed.chartPlotRecords[0].markWidth.value == 20)
    let chart = Chart {
        BarMark(x: .value("x", "A"), y: .value("y", 3), stacking: .unstacked)
            .position(by: .value("series", "s"), axis: .horizontal, span: .fixed(20))
        BarMark(x: .value("x", "B"), y: .value("y", 1), stacking: .unstacked)
            .position(by: .value("series", "s"), axis: .horizontal, span: .fixed(20))
    }
    .chartYScale(domain: 0...4)
    let bars = chart.placedMarks(plotArea: ChartFixedPlotFixture.plotArea).filter { $0.kind == .bar }
    precondition(abs(bars[0].frame.width - 20) < 0.0001)
    precondition(abs(bars[0].frame.minX - 15) < 0.0001)
    precondition(abs(bars[1].frame.minX - 65) < 0.0001)
}

private func chart3DStampSize<C: Chart3DContent>(_ content: C, _ size: CGFloat) -> _Chart3DAttributedContent {
    content.symbolSize(size)
}

private func chart3DStampForeground<C: Chart3DContent>(_ content: C) -> _Chart3DAttributedContent {
    content.foregroundStyle(Color.blue)
}

private func chart3DStampForegroundBy<C: Chart3DContent>(_ content: C) -> _Chart3DAttributedContent {
    content.foregroundStyle(by: .value("series", "a"))
}

private func chart3DStampSurface<C: Chart3DContent>(_ content: C) -> _Chart3DAttributedContent {
    content.foregroundStyle(BasicChart3DSurfaceStyle.heightBased)
}

private func chart3DStampSymbol<C: Chart3DContent>(_ content: C) -> _Chart3DAttributedContent {
    content.symbol(BasicChart3DSymbolShape.sphere)
}

func testRectangleMarkChart3DContentModifiersFailClosed() {
    let mark = RectangleMark(x: .value("x", 1.0), y: .value("y", 2.0))
    let sized = chart3DStampSize(mark, 9)
    precondition(sized.symbolSize == 9)
    precondition(chart3DStampForeground(mark).foregroundStyleName != nil)
    precondition(chart3DStampForegroundBy(mark).foregroundStyleName == "series")
    precondition(chart3DStampSurface(mark).surfaceStyleName != nil)
    precondition(chart3DStampSymbol(mark).symbolName != nil)
    _ = mark.body
}

func testRuleMarkChart3DContentModifiersFailClosed() {
    let mark = RuleMark(x: .value("x", 1.0))
    let sized = chart3DStampSize(mark, 4)
    precondition(sized.symbolSize == 4)
    precondition(chart3DStampForeground(mark).foregroundStyleName != nil)
    precondition(chart3DStampForegroundBy(mark).foregroundStyleName == "series")
    precondition(chart3DStampSurface(mark).surfaceStyleName != nil)
    _ = mark.body
}

func testPointMarkChart3DContentModifiersFailClosed() {
    let mark = PointMark(x: .value("x", 1.0), y: .value("y", 2.0))
    let sized = chart3DStampSize(mark, 6)
    precondition(sized.symbolSize == 6)
    precondition(chart3DStampForeground(mark).foregroundStyleName != nil)
    precondition(chart3DStampForegroundBy(mark).foregroundStyleName == "series")
    precondition(chart3DStampSurface(mark).surfaceStyleName != nil)
    precondition(chart3DStampSymbol(mark).symbolName != nil)
    _ = mark.body
}

func testBuilderConditionalChart3DContentModifiersFailClosed() {
    let conditional = Chart3DContentBuilder.buildEither(first: SurfacePlot()) as BuilderConditional<
        SurfacePlot, SurfaceMark
    >
    let sized = chart3DStampSize(conditional, 5)
    precondition(sized.symbolSize == 5)
    precondition(chart3DStampForeground(conditional).foregroundStyleName != nil)
    precondition(chart3DStampForegroundBy(conditional).foregroundStyleName == "series")
    precondition(chart3DStampSurface(conditional).surfaceStyleName != nil)
    precondition(chart3DStampSymbol(conditional).symbolName != nil)
    _ = conditional.body
}

func testForEachChart3DContentModifiersFailClosed() {
    struct Item: Identifiable {
        var id: String
    }
    let items = [Item(id: "a")]
    let each = ForEach(items, id: \.id) { _ in SurfacePlot() }
    let sized = chart3DStampSize(each, 2)
    precondition(sized.symbolSize == 2)
    precondition(chart3DStampForeground(each).foregroundStyleName != nil)
    precondition(chart3DStampForegroundBy(each).foregroundStyleName == "series")
    precondition(chart3DStampSurface(each).surfaceStyleName != nil)
    precondition(chart3DStampSymbol(each).symbolName != nil)
}

func testOptionalChart3DContentModifiersFailClosed() {
    let present: SurfacePlot? = SurfacePlot()
    let sized = chart3DStampSize(present, 1)
    precondition(sized.symbolSize == 1)
    precondition(chart3DStampForeground(present).foregroundStyleName != nil)
    precondition(chart3DStampForegroundBy(present).foregroundStyleName == "series")
    precondition(chart3DStampSurface(present).surfaceStyleName != nil)
    precondition(chart3DStampSymbol(present).symbolName != nil)
    _ = present.body
}
