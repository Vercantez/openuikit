import Foundation
@_spi(OpenUIKitHost) import Charts

private func chartModifierChart() -> Chart<BarMark> {
    Chart { BarMark(x: .value("Day", 1), y: .value("Val", 2)) }
}

private func chartModifierChart3D() -> Chart3D<SurfacePlot> {
    Chart3D { SurfacePlot() }
}

func testChartViewXAxisContent() {
    precondition(Visibility.hidden != .visible)
    _ = EmptyView().chartXAxis { AxisMarks() }
    _ = chartModifierChart3D().chartXAxis { AxisMarks() }
    _ = ChartPlotContent().chartXAxis { AxisMarks() }
    _ = ChartAxisContent().chartXAxis { AxisMarks() }
    _ = AnyChartSymbolShape().chartXAxis { AxisMarks() }
    _ = BasicChartSymbolShape.circle.chartXAxis { AxisMarks() }
    _ = Circle().chartXAxis { AxisMarks() }
    _ = EmptyView().chartXAxis(.hidden)
    _ = chartModifierChart().chartXAxis(.hidden)
    _ = chartModifierChart3D().chartXAxis(.hidden)
    _ = ChartPlotContent().chartXAxis(.hidden)
    _ = ChartAxisContent().chartXAxis(.hidden)
    _ = AnyChartSymbolShape().chartXAxis(.hidden)
    _ = BasicChartSymbolShape.circle.chartXAxis(.hidden)
    _ = Circle().chartXAxis(.hidden)
    let stored = chartModifierChart().chartXAxis(.hidden)
    precondition(stored.xAxisStorage?.visibility == .hidden)
}

func testChartViewYAxisContent() {
    precondition(Visibility.hidden != .visible)
    _ = EmptyView().chartYAxis { AxisMarks() }
    _ = chartModifierChart3D().chartYAxis { AxisMarks() }
    _ = ChartPlotContent().chartYAxis { AxisMarks() }
    _ = ChartAxisContent().chartYAxis { AxisMarks() }
    _ = AnyChartSymbolShape().chartYAxis { AxisMarks() }
    _ = BasicChartSymbolShape.circle.chartYAxis { AxisMarks() }
    _ = Circle().chartYAxis { AxisMarks() }
    _ = EmptyView().chartYAxis(.hidden)
    _ = chartModifierChart().chartYAxis(.hidden)
    _ = chartModifierChart3D().chartYAxis(.hidden)
    _ = ChartPlotContent().chartYAxis(.hidden)
    _ = ChartAxisContent().chartYAxis(.hidden)
    _ = AnyChartSymbolShape().chartYAxis(.hidden)
    _ = BasicChartSymbolShape.circle.chartYAxis(.hidden)
    _ = Circle().chartYAxis(.hidden)
    let stored = chartModifierChart().chartYAxis(.hidden)
    precondition(stored.yAxisStorage?.visibility == .hidden)
}

func testChartViewZAxis() {
    precondition(Visibility.hidden != .visible)
    _ = EmptyView().chartZAxis(content: AxisMarks())
    _ = chartModifierChart().chartZAxis(content: AxisMarks())
    _ = chartModifierChart3D().chartZAxis(content: AxisMarks())
    _ = ChartPlotContent().chartZAxis(content: AxisMarks())
    _ = ChartAxisContent().chartZAxis(content: AxisMarks())
    _ = AnyChartSymbolShape().chartZAxis(content: AxisMarks())
    _ = BasicChartSymbolShape.circle.chartZAxis(content: AxisMarks())
    _ = Circle().chartZAxis(content: AxisMarks())
    _ = EmptyView().chartZAxis(Visibility.hidden)
    _ = chartModifierChart().chartZAxis(Visibility.hidden)
    _ = chartModifierChart3D().chartZAxis(Visibility.hidden)
    _ = ChartPlotContent().chartZAxis(Visibility.hidden)
    _ = ChartAxisContent().chartZAxis(Visibility.hidden)
    _ = AnyChartSymbolShape().chartZAxis(Visibility.hidden)
    _ = BasicChartSymbolShape.circle.chartZAxis(Visibility.hidden)
    _ = Circle().chartZAxis(Visibility.hidden)
    _ = EmptyView().chartZAxis(AxisMarks())
    _ = Circle().chartZAxis(AxisMarks())
}

func testChartViewAxisLabels() {
    precondition(AnnotationPosition.top != .bottom)
    _ = EmptyView().chartXAxisLabel(position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 4) {
        Text("x")
    }
    _ = chartModifierChart().chartXAxisLabel(position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 4) {
        Text("x")
    }
    _ = ChartPlotContent().chartXAxisLabel(position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 4) {
        Text("x")
    }
    _ = Circle().chartXAxisLabel(position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 4) {
        Text("x")
    }
    _ = EmptyView().chartXAxisLabel("X", position: AxisMarkPosition.bottom, alignment: Alignment.center, spacing: 2)
    _ = Circle().chartXAxisLabel("X", position: AxisMarkPosition.bottom, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartXAxisLabel(LocalizedStringKey("x"), position: AxisMarkPosition.bottom, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartXAxisLabel(LocalizedStringResource("x"), position: AxisMarkPosition.bottom, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartYAxisLabel(position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 4) {
        Text("y")
    }
    _ = chartModifierChart().chartYAxisLabel(position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 4) {
        Text("y")
    }
    _ = ChartPlotContent().chartYAxisLabel(position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 4) {
        Text("y")
    }
    _ = Circle().chartYAxisLabel(position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 4) {
        Text("y")
    }
    _ = EmptyView().chartYAxisLabel("Y", position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 2)
    _ = Circle().chartYAxisLabel("Y", position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartYAxisLabel(LocalizedStringKey("y"), position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartYAxisLabel(LocalizedStringResource("y"), position: AxisMarkPosition.leading, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartZAxisLabel("Z", position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 2)
    _ = chartModifierChart3D().chartZAxisLabel("Z", position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 2)
    _ = Circle().chartZAxisLabel("Z", position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartZAxisLabel(LocalizedStringKey("z"), position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 2)
    _ = EmptyView().chartZAxisLabel(LocalizedStringResource("z"), position: AxisMarkPosition.top, alignment: Alignment.center, spacing: 2)
}

func testChartViewAxisStyle() {
    _ = EmptyView().chartXAxisStyle { AxisMarks() }
    _ = chartModifierChart().chartXAxisStyle { AxisMarks() }
    _ = ChartPlotContent().chartXAxisStyle { AxisMarks() }
    _ = ChartAxisContent().chartXAxisStyle { AxisMarks() }
    _ = AnyChartSymbolShape().chartXAxisStyle { AxisMarks() }
    _ = BasicChartSymbolShape.circle.chartXAxisStyle { AxisMarks() }
    _ = Circle().chartXAxisStyle { AxisMarks() }
    _ = EmptyView().chartYAxisStyle { AxisMarks() }
    _ = chartModifierChart().chartYAxisStyle { AxisMarks() }
    _ = ChartPlotContent().chartYAxisStyle { AxisMarks() }
    _ = ChartAxisContent().chartYAxisStyle { AxisMarks() }
    _ = AnyChartSymbolShape().chartYAxisStyle { AxisMarks() }
    _ = BasicChartSymbolShape.circle.chartYAxisStyle { AxisMarks() }
    _ = Circle().chartYAxisStyle { AxisMarks() }
}

func testChartViewLegend() {
    precondition(AnnotationPosition.automatic != .overlay)
    _ = EmptyView().chartLegend(position: AnnotationPosition.automatic, alignment: Alignment.center, spacing: 4) {
        Text("legend")
    }
    _ = chartModifierChart().chartLegend(position: AnnotationPosition.automatic, alignment: Alignment.center, spacing: 4) {
        Text("legend")
    }
    _ = ChartPlotContent().chartLegend(position: AnnotationPosition.automatic, alignment: Alignment.center, spacing: 4) {
        Text("legend")
    }
    _ = Circle().chartLegend(position: AnnotationPosition.automatic, alignment: Alignment.center, spacing: 4) {
        Text("legend")
    }
    _ = EmptyView().chartLegend(position: AnnotationPosition.top, alignment: Alignment.center, spacing: 8)
    _ = ChartPlotContent().chartLegend(position: AnnotationPosition.top, alignment: Alignment.center, spacing: 8)
    _ = Circle().chartLegend(position: AnnotationPosition.top, alignment: Alignment.center, spacing: 8)
    _ = EmptyView().chartLegend(Visibility.visible)
    _ = chartModifierChart().chartLegend(Visibility.visible)
    _ = Circle().chartLegend(Visibility.hidden)
    let stored = chartModifierChart().chartLegend(Visibility.hidden)
    precondition(stored.legendStorage?.visibility == .hidden)
}

func testChartViewXScale() {
    precondition(ScaleType.linear != .log)
    _ = EmptyView().chartXScale(type: ScaleType.linear)
    _ = ChartPlotContent().chartXScale(type: ScaleType.linear)
    _ = Circle().chartXScale(type: ScaleType.linear)
    _ = EmptyView().chartXScale(range: 0.0...10.0, type: ScaleType.linear)
    _ = Circle().chartXScale(range: 0.0...10.0, type: ScaleType.linear)
    _ = EmptyView().chartXScale(domain: 0...10, type: ScaleType.linear)
    _ = Circle().chartXScale(domain: 0...10, type: ScaleType.linear)
    _ = EmptyView().chartXScale(domain: 0...10, range: 0.0...100.0, type: ScaleType.linear)
    _ = Circle().chartXScale(domain: 0...10, range: 0.0...100.0, type: ScaleType.linear)
    let stored = chartModifierChart().chartXScale(domain: 0...10)
    precondition(stored.xScaleStorage?.domainMin == 0)
    precondition(stored.xScaleStorage?.domainMax == 10)
}

func testChartViewYScale() {
    precondition(ScaleType.linear != .log)
    _ = EmptyView().chartYScale(type: ScaleType.linear)
    _ = ChartPlotContent().chartYScale(type: ScaleType.linear)
    _ = Circle().chartYScale(type: ScaleType.linear)
    _ = EmptyView().chartYScale(range: 0.0...40.0, type: ScaleType.linear)
    _ = Circle().chartYScale(range: 0.0...40.0, type: ScaleType.linear)
    _ = EmptyView().chartYScale(domain: 0...4, type: ScaleType.linear)
    _ = Circle().chartYScale(domain: 0...4, type: ScaleType.linear)
    _ = EmptyView().chartYScale(domain: 0...4, range: 0.0...40.0, type: ScaleType.linear)
    _ = Circle().chartYScale(domain: 0...4, range: 0.0...40.0, type: ScaleType.linear)
    let stored = chartModifierChart().chartYScale(domain: 0...4)
    precondition(stored.yScaleStorage?.domainMin == 0)
    precondition(stored.yScaleStorage?.domainMax == 4)
}

func testChartViewZScale() {
    precondition(ScaleType.linear != .category)
    _ = EmptyView().chartZScale(range: 0.0...10.0, type: ScaleType.linear)
    _ = chartModifierChart3D().chartZScale(range: 0.0...10.0, type: ScaleType.linear)
    _ = Circle().chartZScale(range: 0.0...10.0, type: ScaleType.linear)
    _ = EmptyView().chartZScale(domain: 0...4, type: ScaleType.linear)
    _ = Circle().chartZScale(domain: 0...4, type: ScaleType.linear)
    _ = EmptyView().chartZScale(domain: 0...4, range: 0.0...10.0, type: ScaleType.linear)
    _ = Circle().chartZScale(domain: 0...4, range: 0.0...10.0, type: ScaleType.linear)
}

func testChartViewXSelection() {
    let valueBinding = Binding<Double?>(wrappedValue: nil)
    let rangeBinding = Binding<ClosedRange<Double>?>(wrappedValue: nil)
    _ = EmptyView().chartXSelection(value: valueBinding)
    _ = Circle().chartXSelection(value: valueBinding)
    _ = ChartPlotContent().chartXSelection(value: valueBinding)
    _ = EmptyView().chartXSelection(range: rangeBinding)
    _ = Circle().chartXSelection(range: rangeBinding)
    _ = ChartPlotContent().chartXSelection(range: rangeBinding)
    precondition(valueBinding.wrappedValue == nil)
    precondition(rangeBinding.wrappedValue == nil)
}

func testChartViewYSelection() {
    let valueBinding = Binding<Double?>(wrappedValue: nil)
    let rangeBinding = Binding<ClosedRange<Double>?>(wrappedValue: nil)
    _ = EmptyView().chartYSelection(value: valueBinding)
    _ = chartModifierChart().chartYSelection(value: valueBinding)
    _ = Circle().chartYSelection(value: valueBinding)
    _ = ChartPlotContent().chartYSelection(value: valueBinding)
    _ = EmptyView().chartYSelection(range: rangeBinding)
    _ = chartModifierChart().chartYSelection(range: rangeBinding)
    _ = Circle().chartYSelection(range: rangeBinding)
    _ = ChartPlotContent().chartYSelection(range: rangeBinding)
    precondition(valueBinding.wrappedValue == nil)
    precondition(rangeBinding.wrappedValue == nil)
}

func testChartViewZSelection() {
    let valueBinding = Binding<Double?>(wrappedValue: nil)
    let rangeBinding = Binding<ClosedRange<Double>?>(wrappedValue: nil)
    _ = EmptyView().chartZSelection(value: valueBinding)
    _ = chartModifierChart3D().chartZSelection(value: valueBinding)
    _ = Circle().chartZSelection(value: valueBinding)
    _ = ChartPlotContent().chartZSelection(value: valueBinding)
    _ = EmptyView().chartZSelection(range: rangeBinding)
    _ = chartModifierChart3D().chartZSelection(range: rangeBinding)
    _ = Circle().chartZSelection(range: rangeBinding)
    _ = ChartPlotContent().chartZSelection(range: rangeBinding)
    precondition(valueBinding.wrappedValue == nil)
    precondition(rangeBinding.wrappedValue == nil)
}

func testChartViewAngleSelection() {
    let angleBinding = Binding<Double?>(wrappedValue: nil)
    _ = EmptyView().chartAngleSelection(value: angleBinding)
    _ = chartModifierChart().chartAngleSelection(value: angleBinding)
    _ = Circle().chartAngleSelection(value: angleBinding)
    _ = ChartPlotContent().chartAngleSelection(value: angleBinding)
    precondition(angleBinding.wrappedValue == nil)
}

func testChartViewScrollPosition() {
    let xBinding = Binding<Double>(wrappedValue: 1)
    let yBinding = Binding<Double>(wrappedValue: 2)
    _ = EmptyView().chartScrollPosition(x: xBinding)
    _ = Circle().chartScrollPosition(x: xBinding)
    _ = ChartPlotContent().chartScrollPosition(x: xBinding)
    _ = EmptyView().chartScrollPosition(y: yBinding)
    _ = Circle().chartScrollPosition(y: yBinding)
    _ = ChartPlotContent().chartScrollPosition(y: yBinding)
    _ = EmptyView().chartScrollPosition(initialX: 3.0)
    _ = Circle().chartScrollPosition(initialX: 3.0)
    _ = ChartPlotContent().chartScrollPosition(initialX: 3.0)
    _ = EmptyView().chartScrollPosition(initialY: 4.0)
    _ = Circle().chartScrollPosition(initialY: 4.0)
    precondition(xBinding.wrappedValue == 1)
    precondition(yBinding.wrappedValue == 2)
}

func testChartViewScrollableAxes() {
    precondition(Axis.Set.horizontal != .vertical)
    _ = EmptyView().chartScrollableAxes(Axis.Set.horizontal)
    _ = chartModifierChart().chartScrollableAxes(Axis.Set.horizontal)
    _ = Circle().chartScrollableAxes(Axis.Set.horizontal)
    _ = ChartPlotContent().chartScrollableAxes(Axis.Set.horizontal)
    _ = EmptyView().chartScrollableAxes([.horizontal, .vertical] as Axis.Set)
    let stored = chartModifierChart().chartScrollableAxes(.vertical)
    precondition(stored.scrollableAxes?.axes == .vertical)
}

func testChartViewVisibleDomain() {
    _ = EmptyView().chartXVisibleDomain(length: 5.0)
    _ = chartModifierChart().chartXVisibleDomain(length: 5.0)
    _ = Circle().chartXVisibleDomain(length: 5.0)
    _ = ChartPlotContent().chartXVisibleDomain(length: 5.0)
    _ = ChartAxisContent().chartXVisibleDomain(length: 5.0)
    _ = AnyChartSymbolShape().chartXVisibleDomain(length: 5.0)
    _ = BasicChartSymbolShape.circle.chartXVisibleDomain(length: 5.0)
    _ = EmptyView().chartYVisibleDomain(length: 2.0)
    _ = chartModifierChart().chartYVisibleDomain(length: 2.0)
    _ = Circle().chartYVisibleDomain(length: 2.0)
    _ = ChartPlotContent().chartYVisibleDomain(length: 2.0)
    _ = ChartAxisContent().chartYVisibleDomain(length: 2.0)
    _ = AnyChartSymbolShape().chartYVisibleDomain(length: 2.0)
    _ = BasicChartSymbolShape.circle.chartYVisibleDomain(length: 2.0)
}

func testChartViewScrollTargetBehavior() {
    let behavior = ValueAlignedChartScrollTargetBehavior(unit: 5)
    _ = EmptyView().chartScrollTargetBehavior(behavior)
    _ = chartModifierChart().chartScrollTargetBehavior(behavior)
    _ = Circle().chartScrollTargetBehavior(behavior)
    _ = ChartPlotContent().chartScrollTargetBehavior(behavior)
    _ = ChartAxisContent().chartScrollTargetBehavior(behavior)
    _ = AnyChartSymbolShape().chartScrollTargetBehavior(behavior)
    _ = BasicChartSymbolShape.circle.chartScrollTargetBehavior(behavior)
    precondition(behavior.unitValue == 5)
}

func testChartViewForegroundStyleScale() {
    precondition(ScaleType.linear != .category)
    let pairs: KeyValuePairs<String, Color> = ["a": Color.blue]
    _ = EmptyView().chartForegroundStyleScale(type: ScaleType.linear)
    _ = Circle().chartForegroundStyleScale(type: ScaleType.linear)
    _ = EmptyView().chartForegroundStyleScale(range: [Color.blue], type: ScaleType.linear)
    _ = Circle().chartForegroundStyleScale(range: [Color.blue], type: ScaleType.linear)
    _ = EmptyView().chartForegroundStyleScale(domain: ["a"], type: ScaleType.linear)
    _ = Circle().chartForegroundStyleScale(domain: ["a"], type: ScaleType.linear)
    _ = EmptyView().chartForegroundStyleScale(domain: ["a"], range: [Color.blue], type: ScaleType.linear)
    _ = Circle().chartForegroundStyleScale(domain: ["a"], range: [Color.blue], type: ScaleType.linear)
    _ = EmptyView().chartForegroundStyleScale(domain: ["a"], mapping: { (_: String) in Color.blue })
    _ = Circle().chartForegroundStyleScale(domain: ["a"], mapping: { (_: String) in Color.blue })
    _ = EmptyView().chartForegroundStyleScale(mapping: { (_: String) in Color.blue })
    _ = Circle().chartForegroundStyleScale(mapping: { (_: String) in Color.blue })
    _ = EmptyView().chartForegroundStyleScale(pairs)
    _ = Circle().chartForegroundStyleScale(pairs)
    let stored = chartModifierChart().chartForegroundStyleScale(domain: ["a", "b"], type: .category)
    precondition(stored.foregroundStyleScaleStorage?.domain == ["a", "b"])
}

func testChartViewSymbolScale() {
    let pairs: KeyValuePairs<String, BasicChartSymbolShape> = ["a": BasicChartSymbolShape.circle]
    _ = EmptyView().chartSymbolScale(range: [BasicChartSymbolShape.circle])
    _ = Circle().chartSymbolScale(range: [BasicChartSymbolShape.circle])
    _ = ChartPlotContent().chartSymbolScale(range: [BasicChartSymbolShape.circle])
    _ = EmptyView().chartSymbolScale(domain: ["a"], range: [BasicChartSymbolShape.circle])
    _ = Circle().chartSymbolScale(domain: ["a"], range: [BasicChartSymbolShape.circle])
    _ = EmptyView().chartSymbolScale(domain: ["a"], mapping: { (_: String) in BasicChartSymbolShape.circle })
    _ = Circle().chartSymbolScale(domain: ["a"], mapping: { (_: String) in BasicChartSymbolShape.circle })
    _ = EmptyView().chartSymbolScale(domain: ["a"])
    _ = Circle().chartSymbolScale(domain: ["a"])
    _ = EmptyView().chartSymbolScale(mapping: { (_: String) in BasicChartSymbolShape.circle })
    _ = Circle().chartSymbolScale(mapping: { (_: String) in BasicChartSymbolShape.circle })
    _ = EmptyView().chartSymbolScale(pairs)
    _ = Circle().chartSymbolScale(pairs)
    precondition(BasicChartSymbolShape.circle == BasicChartSymbolShape.circle)
}

func testChartViewSymbolSizeScale() {
    precondition(ScaleType.linear != .log)
    let pairs: KeyValuePairs<String, CGFloat> = ["a": 8]
    _ = EmptyView().chartSymbolSizeScale(type: ScaleType.linear)
    _ = Circle().chartSymbolSizeScale(type: ScaleType.linear)
    _ = EmptyView().chartSymbolSizeScale(range: 4.0...12.0, type: ScaleType.linear)
    _ = Circle().chartSymbolSizeScale(range: 4.0...12.0, type: ScaleType.linear)
    _ = EmptyView().chartSymbolSizeScale(domain: ["a"], type: ScaleType.linear)
    _ = Circle().chartSymbolSizeScale(domain: ["a"], type: ScaleType.linear)
    _ = EmptyView().chartSymbolSizeScale(domain: ["a"], range: 4.0...12.0, type: ScaleType.linear)
    _ = Circle().chartSymbolSizeScale(domain: ["a"], range: 4.0...12.0, type: ScaleType.linear)
    _ = EmptyView().chartSymbolSizeScale(domain: ["a"], mapping: { (_: String) in 8.0 })
    _ = Circle().chartSymbolSizeScale(domain: ["a"], mapping: { (_: String) in 8.0 })
    _ = EmptyView().chartSymbolSizeScale(mapping: { (_: String) in 8.0 })
    _ = Circle().chartSymbolSizeScale(mapping: { (_: String) in 8.0 })
    _ = EmptyView().chartSymbolSizeScale(pairs)
    _ = Circle().chartSymbolSizeScale(pairs)
}

func testChartViewLineStyleScale() {
    let style = StrokeStyle(lineWidth: 2)
    let pairs: KeyValuePairs<String, StrokeStyle> = ["a": style]
    _ = EmptyView().chartLineStyleScale(range: [style])
    _ = Circle().chartLineStyleScale(range: [style])
    _ = ChartPlotContent().chartLineStyleScale(range: [style])
    _ = EmptyView().chartLineStyleScale(domain: ["a"], range: [style])
    _ = Circle().chartLineStyleScale(domain: ["a"], range: [style])
    _ = EmptyView().chartLineStyleScale(domain: ["a"], mapping: { (_: String) in style })
    _ = Circle().chartLineStyleScale(domain: ["a"], mapping: { (_: String) in style })
    _ = EmptyView().chartLineStyleScale(domain: ["a"])
    _ = Circle().chartLineStyleScale(domain: ["a"])
    _ = EmptyView().chartLineStyleScale(mapping: { (_: String) in style })
    _ = Circle().chartLineStyleScale(mapping: { (_: String) in style })
    _ = EmptyView().chartLineStyleScale(pairs)
    _ = Circle().chartLineStyleScale(pairs)
    precondition(style.lineWidth == 2)
}

func testChartViewOverlay() {
    _ = EmptyView().chartOverlay { (_: ChartProxy) in Text("overlay") }
    _ = chartModifierChart().chartOverlay { (_: ChartProxy) in Text("overlay") }
    _ = Circle().chartOverlay { (_: ChartProxy) in Text("overlay") }
    _ = EmptyView().chartOverlay(alignment: Alignment.center) { (_: ChartProxy) in Text("overlay") }
    _ = chartModifierChart().chartOverlay(alignment: Alignment.center) { (_: ChartProxy) in Text("overlay") }
    _ = Circle().chartOverlay(alignment: Alignment.center) { (_: ChartProxy) in Text("overlay") }
    _ = ChartPlotContent().chartOverlay(alignment: Alignment.center) { (_: ChartProxy) in Text("overlay") }
}

func testChartViewBackground() {
    _ = EmptyView().chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
    _ = chartModifierChart().chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
    _ = Circle().chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
    _ = ChartPlotContent().chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
    _ = ChartAxisContent().chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
    _ = AnyChartSymbolShape().chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
    _ = BasicChartSymbolShape.circle.chartBackground(alignment: Alignment.center) { (_: ChartProxy) in Text("bg") }
}

func testChartViewPlotStyle() {
    _ = EmptyView().chartPlotStyle { Text("plot") }
    _ = chartModifierChart().chartPlotStyle { Text("plot") }
    _ = Circle().chartPlotStyle { Text("plot") }
    _ = ChartPlotContent().chartPlotStyle { Text("plot") }
    _ = ChartAxisContent().chartPlotStyle { Text("plot") }
    _ = AnyChartSymbolShape().chartPlotStyle { Text("plot") }
    _ = BasicChartSymbolShape.circle.chartPlotStyle { Text("plot") }
}

func testChartViewGesture() {
    _ = EmptyView().chartGesture(42)
    _ = chartModifierChart().chartGesture(42)
    _ = Circle().chartGesture(42)
    _ = ChartPlotContent().chartGesture(42)
    _ = ChartAxisContent().chartGesture(42)
    _ = AnyChartSymbolShape().chartGesture(42)
    _ = BasicChartSymbolShape.circle.chartGesture(42)
}

func testChartView3DPose() {
    let pose = Chart3DPose.default
    let binding = Binding<Chart3DPose>(wrappedValue: pose)
    _ = EmptyView().chart3DPose(pose)
    _ = chartModifierChart().chart3DPose(pose)
    _ = chartModifierChart3D().chart3DPose(pose)
    _ = Circle().chart3DPose(pose)
    _ = ChartPlotContent().chart3DPose(pose)
    _ = EmptyView().chart3DPose(binding)
    _ = chartModifierChart().chart3DPose(binding)
    _ = Circle().chart3DPose(binding)
    precondition(pose == .default)
}

func testChartView3DCameraProjection() {
    precondition(Chart3DCameraProjection.perspective != .orthographic)
    _ = EmptyView().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = chartModifierChart().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = chartModifierChart3D().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = Circle().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = ChartPlotContent().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = ChartAxisContent().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = AnyChartSymbolShape().chart3DCameraProjection(Chart3DCameraProjection.perspective)
    _ = BasicChartSymbolShape.circle.chart3DCameraProjection(Chart3DCameraProjection.perspective)
}
