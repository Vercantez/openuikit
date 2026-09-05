import Foundation
@_spi(OpenUIKitHost) import Charts

func testPortableCapabilities() {
    precondition(ChartsPortable.renderingCapability == .basicMarks)
    precondition(ChartsPortable.interactionCapability == .unavailable)
}

func testRectangleMarkScalars() {
    let bar = RectangleMark(
        xStart: .value("start", Date(timeIntervalSinceReferenceDate: 100)),
        xEnd: .value("end", Date(timeIntervalSinceReferenceDate: 200)),
        yStart: .value("base", 0),
        yEnd: .value("count", 42)
    )
    precondition(bar.xStart == 100)
    precondition(bar.xEnd == 200)
    precondition(bar.yStart == 0)
    precondition(bar.yEnd == 42)
}

func testLineMarkScalars() {
    let line = LineMark(
        x: .value("day", Date(timeIntervalSinceReferenceDate: 250)),
        y: .value("count", 17)
    )
    precondition(line.x == 250)
    precondition(line.y == 17)
}

func testAreaMarkScalars() {
    let area = AreaMark(
        x: .value("day", 3),
        y: .value("uses", 9)
    )
    precondition(area.x == 3)
    precondition(area.y == 9)
}

func testRuleMarkScalar() {
    let rule = RuleMark(x: .value("selection", 5))
    precondition(rule.x == 5)
}

func testPlottableValueLabels() {
    let numeric = PlottableValue.value("count", 8)
    precondition(numeric.label == "count")
    precondition(numeric.value == 8)
    let dated = PlottableValue.value("day", Date(timeIntervalSinceReferenceDate: 12))
    precondition(dated.label == "day")
    precondition(dated.value.timeIntervalSinceReferenceDate == 12)
}

func testChartProxyFailClosed() {
    let unavailable = ChartProxy()
    precondition(unavailable.plotFrame != nil)
    precondition(unavailable.position(forX: 5) == nil)
    precondition(unavailable.position(forY: 5) == nil)
    precondition(unavailable.plotAreaSize == .zero)
    precondition(unavailable.plotSize == .zero)
    unavailable.selectXValue(at: 1)
    unavailable.selectYValue(at: 2)
    unavailable.selectXRange(from: 0, to: 1)
    unavailable.selectYRange(from: 0, to: 1)
    let hostDriven = ChartProxy(xPosition: { CGFloat($0 * 2 + 1) })
    precondition(hostDriven.position(forX: 5) == 11)
    precondition(
        hostDriven.position(forX: Date(timeIntervalSinceReferenceDate: 9)) == 19
    )
}

func testChartProxyHostDriven() {
    let hostDriven = ChartProxy(xPosition: { CGFloat($0 * 2 + 1) })
    precondition(hostDriven.position(forX: 5) == 11)
    precondition(
        hostDriven.position(forX: Date(timeIntervalSinceReferenceDate: 9)) == 19
    )
}

func testStrokeStyleRetention() {
    let authoredStyle = StrokeStyle(
        lineWidth: 1,
        dash: [4, 4],
        dashPhase: 2
    )
    let styled = RuleMark(x: .value("selection", 5))
        .lineStyle(authoredStyle)
    let retained = Mirror(reflecting: styled).children
        .compactMap { $0.value as? StrokeStyle }
        .first
    precondition(retained == authoredStyle)
}

func testInterpolationMethods() {
    precondition(InterpolationMethod.linear != .catmullRom)
    precondition(InterpolationMethod.catmullRom(alpha: 0.5) == .catmullRom)
    precondition(InterpolationMethod.cardinal(tension: 0) == .cardinal)
    precondition(InterpolationMethod.monotone.description == "monotone")
    let marked = LineMark(x: .value("x", 1), y: .value("y", 2))
        .interpolationMethod(.catmullRom)
    let retained = Mirror(reflecting: marked).children
        .compactMap { $0.value as? InterpolationMethod }
        .first
    precondition(retained == .catmullRom)
}

func testSymbolShapes() {
    let shapes: [BasicChartSymbolShape] = [
        .circle, .square, .plus, .cross, .diamond, .asterisk, .pentagon, .triangle,
    ]
    precondition(Set(shapes).count == 8)
    precondition(BasicChartSymbolShape.circle != .square)
    _ = BasicChartSymbolShape.role
    let wrapped = AnyChartSymbolShape(.diamond)
    precondition(wrapped.path(in: .zero) == Path())
}

func testPlotDimensionScale() {
    let padded = PlotDimensionScaleRange.plotDimension(startPadding: 12, endPadding: 12)
    precondition(padded.startPadding == 12)
    precondition(padded.endPadding == 12)
    let uniform = PlotDimensionScaleRange.plotDimension(padding: 4)
    precondition(uniform.startPadding == 4)
    precondition(uniform.endPadding == 4)
    let bare = PlotDimensionScaleRange.plotDimension
    precondition(bare.startPadding == 0)
}

func testAxisMarkPosition() {
    precondition(AxisMarkPosition.leading != .trailing)
    precondition(AxisMarkPosition.top != .bottom)
    precondition(AxisMarkPosition.automatic.description == "automatic")
}

func testChartConstructs() {
    let chart = Chart {
        LineMark(x: .value("x", 1), y: .value("y", 2))
        AreaMark(x: .value("x", 1), y: .value("y", 2))
    }
    _ = chart
    let fromData = Chart([1, 2, 3], id: \.self) { value in
        RuleMark(x: .value("v", value))
    }
    _ = fromData
}

func testAdditionalMarks() {
    let bar = BarMark(x: .value("x", 1), y: .value("y", 2))
    let point = PointMark(x: .value("x", 1), y: .value("y", 2))
    let sector = SectorMark(angle: .value("share", 0.25))
    _ = bar
    _ = point
    _ = sector
}

func testBinsAndRanges() {
    let numbers = NumberBins(thresholds: [0, 5, 10])
    precondition(numbers.thresholds == [0, 5, 10])
    let dates = DateBins(unit: .day)
    precondition(dates.range == nil)
    let range = ChartBinRange(uncheckedBounds: (lower: 0, upper: 10))
    precondition(range.lowerBound == 0)
    precondition(range.upperBound == 10)
}

func testChartProxyLookupsFailClosed() {
    let proxy = ChartProxy()
    precondition(proxy.symbolSize(for: 1) == nil)
    precondition(proxy.xDomain(dataType: Int.self).isEmpty)
    precondition(proxy.yDomain(dataType: Int.self).isEmpty)
    precondition(proxy.foregroundStyle(for: 1) == nil)
    precondition(proxy.lineStyle(for: 1) == nil)
    precondition(proxy.symbol(for: 1) == nil)
    precondition(proxy.value(atX: 0, as: Int.self) == nil)
    _ = proxy.angle(at: .zero)
    _ = proxy.plotAreaFrame
}

func testChart3DPoseCatalog() {
    let poses: [Chart3DPose] = [
        .top, .back, .left, .front, .right, .bottom, .default,
    ]
    precondition(Set(poses).count == 7)
}

func testViewChartModifiersCompile() {
    let view = RuleMark(x: .value("x", 1))
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(range: .plotDimension)
        .chartYScale(domain: 0...10)
        .symbol(.circle)
    _ = view
}

func testPrimitivePlottable() {
    precondition((7 as Int).primitivePlottable == 7)
    precondition(Int(primitivePlottable: 7) == 7)
    precondition((Int8(3)).primitivePlottable == 3)
    precondition((Int16(3)).primitivePlottable == 3)
    precondition((Int32(3)).primitivePlottable == 3)
    precondition((Int64(3)).primitivePlottable == 3)
    precondition((UInt(3)).primitivePlottable == 3)
    precondition((UInt8(3)).primitivePlottable == 3)
    precondition((UInt16(3)).primitivePlottable == 3)
    precondition((UInt32(3)).primitivePlottable == 3)
    precondition((UInt64(3)).primitivePlottable == 3)
    precondition((Float(1.5)).primitivePlottable == Float(1.5))
    precondition((2.5 as Double).primitivePlottable == 2.5)
    precondition(("A" as String).primitivePlottable == "A")
    let day = Date(timeIntervalSinceReferenceDate: 3)
    precondition(day.primitivePlottable == day)
}

func testMarkChartContentModifiers() {
    let marked = LineMark(x: .value("x", 1), y: .value("y", 2))
        .symbolSize(12)
        .symbolSize(CGSize(width: 3, height: 3))
        .alignsMarkStylesWithPlotArea(true)
        .compositingLayer()
        .annotation { Text("label") }
    _ = marked
}
