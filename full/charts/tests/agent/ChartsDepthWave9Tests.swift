import Foundation
@_spi(OpenUIKitHost) import Charts

private struct Wave9ScaleRange: ScaleRange {
    typealias VisualValue = CGFloat
}

private struct Wave9ChartContent: ChartContent {
    var chartPlotRecords: [ChartPlotRecord] {
        [ChartPlotRecord(kind: .point, x: 2, y: 3)]
    }
    var body: some View { EmptyView() }
}

private struct Wave9Chart3DContent: Chart3DContent {
    var body: some View { EmptyView() }
}

func testScaleRangeVisualValueWitness() {
    let value: Wave9ScaleRange.VisualValue = 12
    precondition(value == 12)
}

func testChartContentBodyWitness() {
    let content = Wave9ChartContent()
    _ = content.body
    precondition(content.chartPlotRecords.single?.x == 2)
}

func testChart3DContentBodyWitness() {
    _ = Wave9Chart3DContent().body
    let chart = Chart3D { Wave9Chart3DContent() }
    _ = chart.content
}

func testChartPlotAndAxisContentBodies() {
    _ = ChartPlotContent().body
    _ = ChartAxisContent().body
}

func testSymbolPerceptualUnitRects() {
    let expected = CGRect(x: 0, y: 0, width: 1, height: 1)
    precondition(BasicChartSymbolShape.circle.perceptualUnitRect == expected)
    precondition(AnyChartSymbolShape(.triangle).perceptualUnitRect == expected)
}

func testAnnotationContextTargetSize() {
    let context = AnnotationContext(targetSize: CGSize(width: 24, height: 10))
    precondition(context.targetSize == CGSize(width: 24, height: 10))
}

func testChart3DMaterialAttributes() {
    let rectangle = RectangleMark(x: .value("x", 1), y: .value("y", 2)).metalness(0.25)
    precondition(rectangle.metalness == 0.25)
    let rule = RuleMark(x: .value("x", 1)).roughness(0.75)
    precondition(rule.roughness == 0.75)
    let pointMetal = PointMark().metalness(0.5)
    precondition(pointMetal.metalness == 0.5)
    let pointRough = PointMark().roughness(0.4)
    precondition(pointRough.roughness == 0.4)
    let conditional: BuilderConditional<RectangleMark, RuleMark> =
        BuilderConditional(storage: .first(
            RectangleMark(x: .value("x", 1), y: .value("y", 2))
        ))
    precondition(conditional.metalness(0.6).metalness == 0.6)
    precondition(conditional.roughness(0.3).roughness == 0.3)
    precondition(SurfacePlot().metalness(0.8).metalness == 0.8)
    precondition(SurfacePlot().roughness(0.2).roughness == 0.2)
}

func testSynthesizedInequalityWitnesses() {
    precondition(Chart3DPose.front != .back)
    precondition(AnnotationPosition.top != .bottom)
    precondition(MarkStackingMethod.standard != .center)
    precondition(Chart3DCameraProjection.automatic != .orthographic)
}

private extension Array {
    var single: Element? { count == 1 ? self[0] : nil }
}
