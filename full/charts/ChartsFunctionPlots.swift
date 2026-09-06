#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Inclusive sample count for 2D function plots. Domain `0...10` yields
/// `0, 1, 2, …, 10`.
public let chartFunctionPlotSampleCount = 11

/// Surface plots sample a 3×3 grid on `[0, 1] × [0, 1]`. There is no 3D
/// renderer; hosts inspect `SurfacePlot.samples`.
public let chartSurfacePlotGridCount = 3

/// Padding applied when `AnnotationOverflowResolution.Strategy.padScale`
/// clamps a point into the plot rect.
public let chartPadScaleInset: CGFloat = 4

public func chartSampleFunctionDomain(_ domain: ClosedRange<Double>?) -> [Double] {
    let span = domain ?? 0...1
    let count = chartFunctionPlotSampleCount
    guard count > 1 else { return [span.lowerBound] }
    let last = Double(count - 1)
    return (0..<count).map { index in
        span.lowerBound + (span.upperBound - span.lowerBound) * Double(index) / last
    }
}

public func chartSampleLineFunction(
    domain: ClosedRange<Double>?,
    function: (Double) -> Double,
    kind: ChartPlotRecord.Kind
) -> [ChartPlotRecord] {
    chartSampleFunctionDomain(domain).map { x in
        let y = function(x)
        return ChartPlotRecord(
            kind: kind,
            x: x,
            y: y,
            yStart: kind == .area ? 0 : nil,
            yEnd: y
        )
    }
}

public func chartSampleIntervalFunction(
    domain: ClosedRange<Double>?,
    function: (Double) -> (yStart: Double, yEnd: Double)
) -> [ChartPlotRecord] {
    chartSampleFunctionDomain(domain).map { x in
        let pair = function(x)
        return ChartPlotRecord(
            kind: .area,
            x: x,
            y: pair.yEnd,
            yStart: pair.yStart,
            yEnd: pair.yEnd
        )
    }
}

public func chartSampleParametricFunction(
    domain: ClosedRange<Double>,
    function: (Double) -> (x: Double, y: Double)
) -> [ChartPlotRecord] {
    chartSampleFunctionDomain(domain).map { t in
        let point = function(t)
        return ChartPlotRecord(kind: .line, x: point.x, y: point.y)
    }
}

public func chartSampleSurfaceFunction(
    _ function: (Double, Double) -> Double
) -> [(x: Double, y: Double, z: Double)] {
    let last = Double(chartSurfacePlotGridCount - 1)
    var samples: [(x: Double, y: Double, z: Double)] = []
    for yi in 0..<chartSurfacePlotGridCount {
        for xi in 0..<chartSurfacePlotGridCount {
            let x = Double(xi) / last
            let y = Double(yi) / last
            samples.append((x, y, function(x, y)))
        }
    }
    return samples
}

/// Linux overflow clamp. `disabled` leaves the coordinate unchanged.
/// `fit` / `automatic` clamp into `plotArea`. `padScale` clamps into the
/// plot area inset by `chartPadScaleInset`. `fit(to:)` uses the same plot
/// rect for `.plot` and `.chart` (no separate chart chrome on Linux).
public func chartClampAnnotation(
    point: CGPoint,
    plotArea: CGRect,
    resolution: AnnotationOverflowResolution
) -> CGPoint {
    CGPoint(
        x: chartClampAxis(value: point.x, min: plotArea.minX, max: plotArea.maxX, strategy: resolution.x),
        y: chartClampAxis(value: point.y, min: plotArea.minY, max: plotArea.maxY, strategy: resolution.y)
    )
}

private func chartClampAxis(
    value: CGFloat,
    min: CGFloat,
    max: CGFloat,
    strategy: AnnotationOverflowResolution.Strategy
) -> CGFloat {
    if strategy.name == "disabled" {
        return value
    }
    var lo = min
    var hi = max
    if strategy.name == "padScale" {
        lo += chartPadScaleInset
        hi -= chartPadScaleInset
    }
    if hi < lo {
        return (min + max) / 2
    }
    return Swift.min(Swift.max(value, lo), hi)
}

public extension AreaPlot where Content == FunctionAreaPlotContent {
    init(
        x: LocalizedStringResource,
        y: LocalizedStringResource,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        self.init(x: x.key, y: y.key, domain: domain, function: function)
    }

    init(
        x: LocalizedStringKey,
        y: LocalizedStringKey,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        self.init(x: x.key, y: y.key, domain: domain, function: function)
    }

    init(
        x: Text,
        y: Text,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        self.init(x: x.content, y: y.content, domain: domain, function: function)
    }

    init(
        x: some StringProtocol,
        y: some StringProtocol,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        _ = x
        _ = y
        self.init(records: chartSampleLineFunction(domain: domain, function: function, kind: .area))
    }

    init(
        x: LocalizedStringResource,
        yStart: LocalizedStringResource,
        yEnd: LocalizedStringResource,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> (yStart: Double, yEnd: Double)
    ) {
        self.init(x: x.key, yStart: yStart.key, yEnd: yEnd.key, domain: domain, function: function)
    }

    init(
        x: LocalizedStringKey,
        yStart: LocalizedStringKey,
        yEnd: LocalizedStringKey,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> (yStart: Double, yEnd: Double)
    ) {
        self.init(x: x.key, yStart: yStart.key, yEnd: yEnd.key, domain: domain, function: function)
    }

    init(
        x: Text,
        yStart: Text,
        yEnd: Text,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> (yStart: Double, yEnd: Double)
    ) {
        self.init(x: x.content, yStart: yStart.content, yEnd: yEnd.content, domain: domain, function: function)
    }

    init(
        x: some StringProtocol,
        yStart: some StringProtocol,
        yEnd: some StringProtocol,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> (yStart: Double, yEnd: Double)
    ) {
        _ = x
        _ = yStart
        _ = yEnd
        self.init(records: chartSampleIntervalFunction(domain: domain, function: function))
    }
}

public extension LinePlot where Content == FunctionLinePlotContent {
    init(
        x: LocalizedStringResource,
        y: LocalizedStringResource,
        t: LocalizedStringResource,
        domain: ClosedRange<Double>,
        function: @escaping (Double) -> (x: Double, y: Double)
    ) {
        self.init(x: x.key, y: y.key, t: t.key, domain: domain, function: function)
    }

    init(
        x: LocalizedStringKey,
        y: LocalizedStringKey,
        t: LocalizedStringKey,
        domain: ClosedRange<Double>,
        function: @escaping (Double) -> (x: Double, y: Double)
    ) {
        self.init(x: x.key, y: y.key, t: t.key, domain: domain, function: function)
    }

    init(
        x: Text,
        y: Text,
        t: Text,
        domain: ClosedRange<Double>,
        function: @escaping (Double) -> (x: Double, y: Double)
    ) {
        self.init(x: x.content, y: y.content, t: t.content, domain: domain, function: function)
    }

    init(
        x: some StringProtocol,
        y: some StringProtocol,
        t: some StringProtocol,
        domain: ClosedRange<Double>,
        function: @escaping (Double) -> (x: Double, y: Double)
    ) {
        _ = x
        _ = y
        _ = t
        self.init(records: chartSampleParametricFunction(domain: domain, function: function))
    }

    init(
        x: LocalizedStringResource,
        y: LocalizedStringResource,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        self.init(x: x.key, y: y.key, domain: domain, function: function)
    }

    init(
        x: LocalizedStringKey,
        y: LocalizedStringKey,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        self.init(x: x.key, y: y.key, domain: domain, function: function)
    }

    init(
        x: Text,
        y: Text,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        self.init(x: x.content, y: y.content, domain: domain, function: function)
    }

    init(
        x: some StringProtocol,
        y: some StringProtocol,
        domain: ClosedRange<Double>? = nil,
        function: @escaping (Double) -> Double
    ) {
        _ = x
        _ = y
        self.init(records: chartSampleLineFunction(domain: domain, function: function, kind: .line))
    }
}

public extension ScaleDomain where Self == AutomaticScaleDomain {
    static var automatic: AutomaticScaleDomain { AutomaticScaleDomain() }

    static func automatic(
        includesZero: Bool? = nil,
        reversed: Bool? = nil
    ) -> AutomaticScaleDomain {
        AutomaticScaleDomain(includesZero: includesZero, reversed: reversed)
    }

    static func automatic<DataValue: Plottable>(
        includesZero: Bool? = nil,
        reversed: Bool? = nil,
        dataType: DataValue.Type,
        modifyInferredDomain: @escaping (inout [DataValue]) -> Void
    ) -> AutomaticScaleDomain {
        _ = dataType
        var values: [DataValue] = []
        modifyInferredDomain(&values)
        let scalars = values.compactMap(chartNumericScalar)
        return AutomaticScaleDomain(
            includesZero: includesZero,
            reversed: reversed,
            modifiedDomain: scalars
        )
    }
}

public extension PositionScaleRange where Self == PlotDimensionScaleRange {
    static var plotDimension: PlotDimensionScaleRange {
        PlotDimensionScaleRange(startPadding: 0, endPadding: 0)
    }

    static func plotDimension(padding: CGFloat) -> PlotDimensionScaleRange {
        PlotDimensionScaleRange(startPadding: padding, endPadding: padding)
    }

    static func plotDimension(
        startPadding: CGFloat = 0,
        endPadding: CGFloat = 0
    ) -> PlotDimensionScaleRange {
        PlotDimensionScaleRange(startPadding: startPadding, endPadding: endPadding)
    }
}

public extension ChartSymbolShape where Self == BasicChartSymbolShape {
    static var plus: BasicChartSymbolShape { BasicChartSymbolShape("plus") }
    static var cross: BasicChartSymbolShape { BasicChartSymbolShape("cross") }
    static var circle: BasicChartSymbolShape { BasicChartSymbolShape("circle") }
    static var square: BasicChartSymbolShape { BasicChartSymbolShape("square") }
    static var diamond: BasicChartSymbolShape { BasicChartSymbolShape("diamond") }
    static var asterisk: BasicChartSymbolShape { BasicChartSymbolShape("asterisk") }
    static var pentagon: BasicChartSymbolShape { BasicChartSymbolShape("pentagon") }
    static var triangle: BasicChartSymbolShape { BasicChartSymbolShape("triangle") }
}

public struct _StrokedChartSymbolShape<Base: ChartSymbolShape>: ChartSymbolShape, InsettableShape {
    public var base: Base
    public var lineWidth: CGFloat
    init(base: Base, lineWidth: CGFloat) {
        self.base = base
        self.lineWidth = lineWidth
    }
    public func path(in rect: CGRect) -> Path {
        let inset = lineWidth / 2
        let inner = CGRect(
            x: rect.minX + inset,
            y: rect.minY + inset,
            width: max(0, rect.width - inset * 2),
            height: max(0, rect.height - inset * 2)
        )
        return base.path(in: inner)
    }
    public func inset(by amount: CGFloat) -> _StrokedChartSymbolShape<Base> {
        _StrokedChartSymbolShape(base: base, lineWidth: lineWidth + amount * 2)
    }
    public var body: some View { EmptyView() }
}

public extension ChartSymbolShape where Self: InsettableShape {
    func strokeBorder(style: StrokeStyle) -> _StrokedChartSymbolShape<Self> {
        _StrokedChartSymbolShape(base: self, lineWidth: style.lineWidth)
    }

    func strokeBorder(lineWidth: CGFloat = 1) -> _StrokedChartSymbolShape<Self> {
        _StrokedChartSymbolShape(base: self, lineWidth: lineWidth)
    }
}

extension BasicChartSymbolShape: InsettableShape {
    public func inset(by amount: CGFloat) -> BasicChartSymbolShape {
        _ = amount
        return self
    }
}

extension Circle: ChartSymbolShape {}

public extension Chart3DSymbolShape where Self == BasicChart3DSymbolShape {
    static var sphere: BasicChart3DSymbolShape { BasicChart3DSymbolShape("sphere") }
    static var cube: BasicChart3DSymbolShape { BasicChart3DSymbolShape("cube") }
    static var cone: BasicChart3DSymbolShape { BasicChart3DSymbolShape("cone") }
    static var cylinder: BasicChart3DSymbolShape { BasicChart3DSymbolShape("cylinder") }
}

public extension ChartScrollTargetBehavior where Self == ValueAlignedChartScrollTargetBehavior {
    static func valueAligned<P: Plottable & Numeric>(
        unit: P,
        majorAlignment: MajorValueAlignment<P>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) -> ValueAlignedChartScrollTargetBehavior {
        ValueAlignedChartScrollTargetBehavior(
            unit: unit,
            majorAlignment: majorAlignment,
            limitBehavior: limitBehavior
        )
    }

    static func valueAligned<X: Plottable & Numeric, Y: Plottable & Numeric>(
        xUnit: X,
        yUnit: Y,
        xMajorAlignment: MajorValueAlignment<X>? = nil,
        yMajorAlignment: MajorValueAlignment<Y>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) -> ValueAlignedChartScrollTargetBehavior {
        ValueAlignedChartScrollTargetBehavior(
            xUnit: xUnit,
            yUnit: yUnit,
            xMajorAlignment: xMajorAlignment,
            yMajorAlignment: yMajorAlignment,
            limitBehavior: limitBehavior
        )
    }

    static func valueAligned<X: Plottable & Numeric>(
        xUnit: X,
        yMatching yComponents: DateComponents,
        xMajorAlignment: MajorValueAlignment<X>? = nil,
        yMajorAlignment: MajorValueAlignment<Date>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) -> ValueAlignedChartScrollTargetBehavior {
        ValueAlignedChartScrollTargetBehavior(
            xUnit: xUnit,
            yMatching: yComponents,
            xMajorAlignment: xMajorAlignment,
            yMajorAlignment: yMajorAlignment,
            limitBehavior: limitBehavior
        )
    }

    static func valueAligned(
        matching components: DateComponents,
        majorAlignment: MajorValueAlignment<Date>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) -> ValueAlignedChartScrollTargetBehavior {
        ValueAlignedChartScrollTargetBehavior(
            matching: components,
            majorAlignment: majorAlignment,
            limitBehavior: limitBehavior
        )
    }

    static func valueAligned(
        xMatching xComponents: DateComponents,
        yMatching yComponents: DateComponents,
        xMajorAlignment: MajorValueAlignment<Date>? = nil,
        yMajorAlignment: MajorValueAlignment<Date>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) -> ValueAlignedChartScrollTargetBehavior {
        ValueAlignedChartScrollTargetBehavior(
            xMatching: xComponents,
            yMatching: yComponents,
            xMajorAlignment: xMajorAlignment,
            yMajorAlignment: yMajorAlignment,
            limitBehavior: limitBehavior
        )
    }

    static func valueAligned<Y: Plottable & Numeric>(
        xMatching xComponents: DateComponents,
        yUnit: Y,
        xMajorAlignment: MajorValueAlignment<Date>? = nil,
        yMajorAlignment: MajorValueAlignment<Y>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) -> ValueAlignedChartScrollTargetBehavior {
        ValueAlignedChartScrollTargetBehavior(
            xMatching: xComponents,
            yUnit: yUnit,
            xMajorAlignment: xMajorAlignment,
            yMajorAlignment: yMajorAlignment,
            limitBehavior: limitBehavior
        )
    }
}

extension BuilderConditional: Chart3DContent
    where TrueContent: Chart3DContent, FalseContent: Chart3DContent {}

public struct _Chart3DAttributedContent: Chart3DContent {
    public var metalness: Double?
    public var roughness: Double?
    public var symbolSize: CGFloat?
    public var foregroundStyleName: String?
    public var surfaceStyleName: String?
    public var symbolName: String?
    public var childTypeName: String
    init(
        metalness: Double? = nil,
        roughness: Double? = nil,
        symbolSize: CGFloat? = nil,
        foregroundStyleName: String? = nil,
        surfaceStyleName: String? = nil,
        symbolName: String? = nil,
        childTypeName: String = ""
    ) {
        self.metalness = metalness
        self.roughness = roughness
        self.symbolSize = symbolSize
        self.foregroundStyleName = foregroundStyleName
        self.surfaceStyleName = surfaceStyleName
        self.symbolName = symbolName
        self.childTypeName = childTypeName
    }
    public var body: some View { EmptyView() }
}

public extension Chart3DContent {
    func symbolSize(_ size: CGFloat) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            symbolSize: size,
            childTypeName: String(describing: type(of: self))
        )
    }

    func foregroundStyle<D: Plottable>(by value: PlottableValue<D>) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            foregroundStyleName: value.label,
            childTypeName: String(describing: type(of: self))
        )
    }

    func foregroundStyle(_ style: some ShapeStyle) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            foregroundStyleName: String(describing: style),
            childTypeName: String(describing: type(of: self))
        )
    }

    func foregroundStyle(_ surfaceStyle: some Chart3DSurfaceStyle) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            surfaceStyleName: String(describing: surfaceStyle),
            childTypeName: String(describing: type(of: self))
        )
    }

    func symbol<S: Chart3DSymbolShape>(_ symbol: S) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            symbolName: String(describing: symbol),
            childTypeName: String(describing: type(of: self))
        )
    }

    func metalness(_ ratio: Double) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            metalness: ratio,
            childTypeName: String(describing: type(of: self))
        )
    }

    func roughness(_ ratio: Double) -> _Chart3DAttributedContent {
        _Chart3DAttributedContent(
            roughness: ratio,
            childTypeName: String(describing: type(of: self))
        )
    }
}

public struct _AxisContentAttributed<Content: AxisContent>: AxisContent {
    public var content: Content
    public var compositing: String?
    init(content: Content, compositing: String? = nil) {
        self.content = content
        self.compositing = compositing
    }
    public var body: some View { content }
}

public extension AxisContent {
    func compositingLayer<V: View>(
        style: (PlaceholderContentView<Self>) -> V
    ) -> _AxisContentAttributed<Self> {
        _ = style(PlaceholderContentView<Self>())
        return _AxisContentAttributed(content: self, compositing: "style")
    }

    func compositingLayer() -> _AxisContentAttributed<Self> {
        _AxisContentAttributed(content: self, compositing: "layer")
    }
}
