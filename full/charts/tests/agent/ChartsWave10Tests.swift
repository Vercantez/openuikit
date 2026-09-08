import Foundation
@_spi(OpenUIKitHost) import Charts

private struct Wave10ChartScrollBehavior: ChartScrollTargetBehavior {
    func updateTarget(
        _ target: inout ScrollTarget,
        context: ChartScrollTargetBehaviorContext
    ) {
        target.rect.origin.x = context.contentSize.width - context.containerSize.width
    }
}

private struct Wave10AxisMark: AxisMark {
    var body: some View { EmptyView() }
}

private struct Wave10AxisContent: AxisContent {
    var body: some View { EmptyView() }
}

private struct Wave10Symbol: ChartSymbolShape {
    var body: some View { EmptyView() }
    func path(in rect: CGRect) -> Path { Path(rect) }
}

func testChartScrollTargetContextForwardsBaseProperties() {
    let proxy = ChartProxy(
        xScale: ChartScale.linear(domain: 0...1, range: 0...120),
        yScale: ChartScale.linear(domain: 0...1, range: 0...40, inverted: true),
        plotArea: CGRect(x: 0, y: 0, width: 120, height: 40)
    )
    let base = ScrollTargetBehaviorContext(
        originalTarget: ScrollTarget(rect: CGRect(x: 3, y: 4, width: 20, height: 10)),
        velocity: CGPoint(x: 2, y: -1),
        contentSize: CGSize(width: 300, height: 200),
        containerSize: CGSize(width: 100, height: 80)
    )
    let context = ChartScrollTargetBehaviorContext(
        chartProxy: proxy,
        scrollTargetBehaviorContext: base
    )
    precondition(context.chartProxy.plotAreaSize == CGSize(width: 120, height: 40))
    precondition(context.velocity == CGPoint(x: 2, y: -1))
    precondition(context.contentSize == CGSize(width: 300, height: 200))
    precondition(context.containerSize == CGSize(width: 100, height: 80))
}

func testChartScrollTargetBehaviorBridgeUsesChartContext() {
    let behavior = Wave10ChartScrollBehavior()
    let base = ScrollTargetBehaviorContext(
        contentSize: CGSize(width: 260, height: 100),
        containerSize: CGSize(width: 80, height: 40)
    )
    var target = ScrollTarget(rect: CGRect(x: 7, y: 9, width: 80, height: 40))
    behavior.updateTarget(&target, context: base)
    precondition(target.rect.origin == CGPoint(x: 180, y: 9))
}

func testValueAlignedScrollTargetSnapsBothAxes() {
    let behavior = ValueAlignedChartScrollTargetBehavior(
        xUnit: 10,
        yUnit: 4,
        limitBehavior: .never
    )
    let context = ChartScrollTargetBehaviorContext()
    var target = ScrollTarget(rect: CGRect(x: 26, y: 11, width: 50, height: 20))
    behavior.updateTarget(&target, context: context)
    precondition(target.rect.origin == CGPoint(x: 30, y: 12))
    precondition(behavior.limitBehavior.name == "never")
}

func testRemainingProtocolWitnesses() {
    _ = Wave10AxisMark().body
    _ = Wave10AxisContent().body
    let symbol = Wave10Symbol()
    precondition(symbol.perceptualUnitRect == CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(symbol.path(in: CGRect(x: 2, y: 3, width: 4, height: 5)).cgRects == [CGRect(x: 2, y: 3, width: 4, height: 5)])
}

func testFunctionContentRetainsSampledRecords() {
    let areaRecord = ChartPlotRecord(kind: .area, x: 2, y: 8, yStart: 3, yEnd: 8)
    let area = FunctionAreaPlotContent(records: [areaRecord])
    precondition(area.chartPlotRecords == [areaRecord])
    _ = area.body

    let lineRecord = ChartPlotRecord(kind: .line, x: 4, y: 16)
    let line = FunctionLinePlotContent(records: [lineRecord])
    precondition(line.chartPlotRecords == [lineRecord])
    _ = line.body
}

func testBasicChart3DSymbolShapeIdentity() {
    let shapes: Set<BasicChart3DSymbolShape> = [.sphere, .cube, .cone, .cylinder]
    precondition(shapes.count == 4)
}
