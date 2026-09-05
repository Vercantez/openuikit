#if canImport(SwiftUI)
@_exported import SwiftUI
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation

public enum ChartsPortable {
    public enum RenderingCapability: String, Sendable {
        case basicMarks
    }

    public enum InteractionCapability: String, Sendable {
        case unavailable
        case hostDriven
    }

    public static let renderingCapability = RenderingCapability.basicMarks
    public static let interactionCapability = InteractionCapability.unavailable
}

public protocol Plottable {}
extension Int: Plottable {}
extension Int8: Plottable {}
extension Int16: Plottable {}
extension Int32: Plottable {}
extension Int64: Plottable {}
extension UInt: Plottable {}
extension UInt8: Plottable {}
extension UInt16: Plottable {}
extension UInt32: Plottable {}
extension UInt64: Plottable {}
extension Float: Plottable {}
extension Double: Plottable {}
extension String: Plottable {}
extension Date: Plottable {}

public extension Plottable {
    typealias PrimitivePlottable = Self
    var primitivePlottable: Self { self }
    init?(primitivePlottable: Self) { self = primitivePlottable }
}

public struct PlottableValue<Value: Plottable>: Sendable
    where Value: Sendable
{
    public let label: String
    public let value: Value

    private init(label: String, value: Value) {
        self.label = label
        self.value = value
    }

    public static func value(_ label: String, _ value: Value) -> Self {
        Self(label: label, value: value)
    }
}

public protocol ChartContent: View {
    var chartPlotRecords: [ChartPlotRecord] { get }
}

public extension ChartContent {
    var chartPlotRecords: [ChartPlotRecord] { [] }
}

public struct _ChartViewContent<Content: View>: ChartContent {
    let content: Content

    public var body: some View { content }
}

public struct _ChartPairContent<First: ChartContent, Second: ChartContent>:
    ChartContent
{
    let first: First
    let second: Second

    public var chartPlotRecords: [ChartPlotRecord] {
        first.chartPlotRecords + second.chartPlotRecords
    }

    public var body: some View {
        ZStack {
            first
            second
        }
    }
}

public struct _ChartOptionalContent<Content: ChartContent>: ChartContent {
    let content: Content?

    public var chartPlotRecords: [ChartPlotRecord] {
        content?.chartPlotRecords ?? []
    }

    @ViewBuilder
    public var body: some View {
        if let content { content }
    }
}

public struct _ChartEitherContent<First: ChartContent, Second: ChartContent>:
    ChartContent
{
    enum Storage {
        case first(First)
        case second(Second)
    }

    let storage: Storage

    public var chartPlotRecords: [ChartPlotRecord] {
        switch storage {
        case .first(let content): return content.chartPlotRecords
        case .second(let content): return content.chartPlotRecords
        }
    }

    @ViewBuilder
    public var body: some View {
        switch storage {
        case .first(let content): content
        case .second(let content): content
        }
    }
}

@resultBuilder
public enum ChartContentBuilder {
    public static func buildBlock() -> _ChartViewContent<EmptyView> {
        _ChartViewContent(content: EmptyView())
    }

    public static func buildBlock<Content: ChartContent>(
        _ content: Content
    ) -> Content {
        content
    }

    public static func buildBlock<First: ChartContent, Second: ChartContent>(
        _ first: First,
        _ second: Second
    ) -> _ChartPairContent<First, Second> {
        _ChartPairContent(first: first, second: second)
    }

    public static func buildExpression<Content: ChartContent>(
        _ expression: Content
    ) -> Content {
        expression
    }

    public static func buildExpression<Content: View>(
        _ expression: Content
    ) -> _ChartViewContent<Content> {
        _ChartViewContent(content: expression)
    }

    public static func buildOptional<Content: ChartContent>(
        _ content: Content?
    ) -> _ChartOptionalContent<Content> {
        _ChartOptionalContent(content: content)
    }

    public static func buildEither<First: ChartContent, Second: ChartContent>(
        first: First
    ) -> _ChartEitherContent<First, Second> {
        _ChartEitherContent(storage: .first(first))
    }

    public static func buildEither<First: ChartContent, Second: ChartContent>(
        second: Second
    ) -> _ChartEitherContent<First, Second> {
        _ChartEitherContent(storage: .second(second))
    }

    public static func buildIf<Content: ChartContent>(
        _ content: Content?
    ) -> Content? {
        content
    }

    public static func buildLimitedAvailability(
        _ content: some ChartContent
    ) -> AnyChartContent {
        AnyChartContent(content)
    }

    public static func buildPartialBlock<Content: ChartContent>(
        first: Content
    ) -> Content {
        first
    }

    public static func buildPartialBlock<
        Accumulated: ChartContent,
        Next: ChartContent
    >(
        accumulated: Accumulated,
        next: Next
    ) -> _ChartPairContent<Accumulated, Next> {
        _ChartPairContent(first: accumulated, second: next)
    }
}

public struct Chart<Content: ChartContent>: View {
    let content: Content
    public var xScaleStorage: ChartScaleStorage?
    public var yScaleStorage: ChartScaleStorage?
    public var xAxisStorage: ChartAxisStorage?
    public var yAxisStorage: ChartAxisStorage?
    public var legendStorage: ChartLegendStorage?
    public var foregroundStyleScaleStorage: ChartForegroundStyleScaleStorage?

    public init(@ChartContentBuilder content: () -> Content) {
        self.content = content()
    }

    public init<Data: RandomAccessCollection, Mark: ChartContent>(
        _ data: Data,
        @ChartContentBuilder content: @escaping (Data.Element) -> Mark
    ) where Content == _ChartForEachContent<Mark> {
        _ = data.enumerated()
        let marks = data.map { content($0) }
        self.content = _ChartForEachContent(
            records: marks.flatMap(\.chartPlotRecords)
        )
    }

    public init<
        Data: RandomAccessCollection,
        ID: Hashable,
        Mark: ChartContent
    >(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ChartContentBuilder content: @escaping (Data.Element) -> Mark
    ) where Content == _ChartForEachContent<Mark> {
        _ = id
        let marks = data.map { content($0) }
        self.content = _ChartForEachContent(
            records: marks.flatMap(\.chartPlotRecords)
        )
    }

    public var chartPlotRecords: [ChartPlotRecord] { content.chartPlotRecords }

    public func resolvedProxy(plotArea: CGRect) -> ChartProxy {
        let xScale = resolvedXScale(plotArea: plotArea)
        let yScale = resolvedYScale(plotArea: plotArea)
        return ChartProxy(xScale: xScale, yScale: yScale, plotArea: plotArea)
    }

    public func resolvedXScale(plotArea: CGRect) -> ChartScale {
        resolveScale(
            storage: xScaleStorage,
            records: chartPlotRecords,
            horizontal: true,
            plotArea: plotArea
        )
    }

    public func resolvedYScale(plotArea: CGRect) -> ChartScale {
        resolveScale(
            storage: yScaleStorage,
            records: chartPlotRecords,
            horizontal: false,
            plotArea: plotArea
        )
    }

    public func placedMarks(plotArea: CGRect) -> [ChartPlacedMark] {
        ChartLayout.place(
            records: chartPlotRecords,
            xScale: resolvedXScale(plotArea: plotArea),
            yScale: resolvedYScale(plotArea: plotArea)
        )
    }

    public var body: some View {
        let records = chartPlotRecords
        return Canvas { context, size in
            let area = CGRect(origin: .zero, size: size)
            let xScale = resolveScale(
                storage: xScaleStorage,
                records: records,
                horizontal: true,
                plotArea: area
            )
            let yScale = resolveScale(
                storage: yScaleStorage,
                records: records,
                horizontal: false,
                plotArea: area
            )
            let marks = ChartLayout.place(
                records: records,
                xScale: xScale,
                yScale: yScale
            )
            #if !canImport(SwiftUI)
            ChartCanvasDrawing.draw(marks, into: &context)
            #else
            _ = marks
            _ = context
            #endif
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chart")
    }
}

public struct _ChartForEachContent<Mark: ChartContent>: ChartContent {
    let records: [ChartPlotRecord]
    public var chartPlotRecords: [ChartPlotRecord] { records }
    public var body: some View { EmptyView() }
}

private func resolveScale(
    storage: ChartScaleStorage?,
    records: [ChartPlotRecord],
    horizontal: Bool,
    plotArea: CGRect
) -> ChartScale {
    let range: ClosedRange<Double> = horizontal
        ? plotArea.minX...plotArea.maxX
        : plotArea.minY...plotArea.maxY
    let type = storage?.type ?? (horizontal ? inferXType(records) : .linear)
    if type == .category {
        let names = storage?.categories.isEmpty == false
            ? storage!.categories
            : uniqueCategories(records)
        return .category(names, range: range)
    }
    let values = numericValues(records, horizontal: horizontal)
    let minValue = storage?.domainMin ?? values.min() ?? 0
    let maxValue = storage?.domainMax ?? values.max() ?? 1
    let domain = min(minValue, maxValue)...max(minValue, maxValue == minValue ? minValue + 1 : maxValue)
    if type == .log {
        return .log(domain: domain, range: range, inverted: !horizontal)
    }
    if type == .date {
        return .date(domain: domain, range: range, inverted: !horizontal)
    }
    return .linear(domain: domain, range: range, inverted: !horizontal)
}

private func inferXType(_ records: [ChartPlotRecord]) -> ScaleType {
    if records.contains(where: { $0.category != nil }) {
        return .category
    }
    return .linear
}

private func uniqueCategories(_ records: [ChartPlotRecord]) -> [String] {
    var names: [String] = []
    for record in records {
        if let name = record.category, !names.contains(name) {
            names.append(name)
        }
    }
    return names
}

private func numericValues(_ records: [ChartPlotRecord], horizontal: Bool) -> [Double] {
    records.compactMap { record in
        if horizontal {
            return record.x ?? record.xEnd ?? record.xStart
        }
        return record.y ?? record.yEnd ?? record.yStart
    }
}

public struct RectangleMark: ChartContent {
    public let xStart: Double?
    public let xEnd: Double?
    public let yStart: Double?
    public let yEnd: Double?
    public let x: Double?
    public let y: Double?
    public let category: String?
    public let series: String?

    public init<XStart, XEnd, YStart, YEnd>(
        xStart: PlottableValue<XStart>,
        xEnd: PlottableValue<XEnd>,
        yStart: PlottableValue<YStart>,
        yEnd: PlottableValue<YEnd>
    ) where XStart: Plottable & Sendable,
        XEnd: Plottable & Sendable,
        YStart: Plottable & Sendable,
        YEnd: Plottable & Sendable
    {
        self.xStart = chartNumericScalar(xStart.value)
        self.xEnd = chartNumericScalar(xEnd.value)
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.x = nil
        self.y = nil
        self.category = xStart.value as? String
        self.series = nil
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>,
        width: MarkDimension = .automatic,
        height: MarkDimension = .automatic
    ) {
        _ = width
        _ = height
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.xStart = nil
        self.xEnd = nil
        self.yStart = nil
        self.yEnd = nil
        self.category = x.value as? String
        self.series = nil
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>,
        width: MarkDimension = .automatic
    ) {
        _ = width
        self.x = chartNumericScalar(x.value)
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.xStart = nil
        self.xEnd = nil
        self.y = self.yEnd
        self.category = x.value as? String
        self.series = nil
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [
            ChartPlotRecord(
                kind: .rectangle,
                x: x,
                y: y,
                xStart: xStart,
                xEnd: xEnd,
                yStart: yStart,
                yEnd: yEnd,
                category: category,
                series: series
            ),
        ]
    }

    public var body: some View {
        let magnitude = max(2, min(200, abs((yEnd ?? y ?? 0) - (yStart ?? 0))))
        Rectangle()
            .frame(
                minWidth: 2,
                idealWidth: 8,
                maxWidth: 18,
                minHeight: CGFloat(magnitude)
            )
            .accessibilityLabel("Bar \(yEnd ?? y ?? 0)")
    }
}

public struct LineMark: ChartContent {
    public let x: Double?
    public let y: Double?
    public let category: String?
    public let series: String?

    public init<X, Y>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.category = x.value as? String
        self.series = nil
    }

    public init<X, Y, S>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>,
        series: PlottableValue<S>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable, S: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.category = x.value as? String
        if let name = series.value as? String {
            self.series = name
        } else if let scalar = chartNumericScalar(series.value) {
            self.series = String(scalar)
        } else {
            self.series = series.label
        }
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [
            ChartPlotRecord(
                kind: .line,
                x: x,
                y: y,
                category: category,
                series: series
            ),
        ]
    }

    public var body: some View {
        Circle()
            .frame(width: 7, height: 7)
            .accessibilityLabel("Point \(y ?? 0)")
    }
}

public struct AreaMark: ChartContent {
    public let x: Double?
    public let y: Double?
    public let yStart: Double?
    public let yEnd: Double?
    public let category: String?
    public let series: String?
    public let stacking: MarkStackingMethod

    public init<X, Y>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.yStart = nil
        self.yEnd = self.y
        self.category = x.value as? String
        self.series = nil
        self.stacking = .standard
    }

    public init<X, Y>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>,
        stacking: MarkStackingMethod
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.yStart = nil
        self.yEnd = self.y
        self.category = x.value as? String
        self.series = nil
        self.stacking = stacking
    }

    public init<X, Y, S>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>,
        series: PlottableValue<S>,
        stacking: MarkStackingMethod = .standard
    ) where X: Plottable & Sendable, Y: Plottable & Sendable, S: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.yStart = nil
        self.yEnd = self.y
        self.category = x.value as? String
        if let name = series.value as? String {
            self.series = name
        } else {
            self.series = series.label
        }
        self.stacking = stacking
    }

    public init<X, Y>(
        x: PlottableValue<X>,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.y = self.yEnd
        self.category = x.value as? String
        self.series = nil
        self.stacking = .unstacked
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [
            ChartPlotRecord(
                kind: .area,
                x: x,
                y: y,
                yStart: yStart,
                yEnd: yEnd,
                category: category,
                series: series,
                stacking: stacking
            ),
        ]
    }

    public var body: some View {
        let magnitude = max(2, min(200, abs(y ?? 0)))
        Rectangle()
            .frame(
                minWidth: 2,
                idealWidth: 6,
                maxWidth: 14,
                minHeight: CGFloat(magnitude)
            )
            .accessibilityLabel("Area \(y ?? 0)")
    }
}

public struct RuleMark: ChartContent {
    public let x: Double?
    public let y: Double?
    public let yStart: Double?
    public let yEnd: Double?
    public let category: String?

    public init<X>(x: PlottableValue<X>) where X: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.y = nil
        self.yStart = nil
        self.yEnd = nil
        self.category = x.value as? String
    }

    public init<X, Y>(
        x: PlottableValue<X>,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = chartNumericScalar(x.value)
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.y = self.yEnd
        self.category = x.value as? String
    }

    public init<Y>(
        x: CGFloat? = nil,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>
    ) where Y: Plottable & Sendable {
        self.x = x.map(Double.init)
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.y = self.yEnd
        self.category = nil
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [
            ChartPlotRecord(
                kind: .rule,
                x: x,
                y: y,
                yStart: yStart,
                yEnd: yEnd,
                category: category
            ),
        ]
    }

    public var body: some View {
        Rectangle()
            .frame(minWidth: 1, idealWidth: 1, maxWidth: 1, maxHeight: .infinity)
            .accessibilityLabel("Selection rule")
    }
}

public struct InterpolationMethod: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    public let parameter: CGFloat?

    private init(_ name: String, parameter: CGFloat? = nil) {
        self.name = name
        self.parameter = parameter
    }

    public static let linear = InterpolationMethod("linear")
    public static let catmullRom = InterpolationMethod("catmullRom", parameter: 0.5)
    public static let cardinal = InterpolationMethod("cardinal", parameter: 0)
    public static let monotone = InterpolationMethod("monotone")
    public static let stepStart = InterpolationMethod("stepStart")
    public static let stepCenter = InterpolationMethod("stepCenter")
    public static let stepEnd = InterpolationMethod("stepEnd")

    public var description: String { name }

    public static func catmullRom(alpha: CGFloat) -> InterpolationMethod {
        InterpolationMethod("catmullRom", parameter: alpha)
    }

    public static func cardinal(tension: CGFloat) -> InterpolationMethod {
        InterpolationMethod("cardinal", parameter: tension)
    }
}

public struct BasicChartSymbolShape: Hashable, Sendable, View {
    private let name: String
    private init(_ name: String) { self.name = name }

    public static let circle = BasicChartSymbolShape("circle")
    public static let square = BasicChartSymbolShape("square")
    public static let plus = BasicChartSymbolShape("plus")
    public static let cross = BasicChartSymbolShape("cross")
    public static let diamond = BasicChartSymbolShape("diamond")
    public static let asterisk = BasicChartSymbolShape("asterisk")
    public static let pentagon = BasicChartSymbolShape("pentagon")
    public static let triangle = BasicChartSymbolShape("triangle")
    public static let role = ShapeRole.fill

    public var body: some View { EmptyView() }

    public func path(in rect: CGRect) -> Path {
        if rect.width <= 0 || rect.height <= 0 {
            return Path()
        }
        var path = Path()
        switch name {
        case "square":
            path.addRect(rect)
        case "triangle":
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        default:
            path.addEllipse(in: rect)
        }
        return path
    }
}

public struct _ChartInterpolationContent<Content: View>: View, ChartContent {
    public let content: Content
    public let method: InterpolationMethod

    public var chartPlotRecords: [ChartPlotRecord] {
        (content as? any ChartContent)?.chartPlotRecords ?? []
    }

    public var body: some View { content }
}

public struct _ChartSymbolContent<Content: View>: View {
    public let content: Content
    public let symbol: BasicChartSymbolShape

    public var body: some View { content }
}

public struct _ChartLineStyleContent<Content: View>: View {
    public let content: Content
    public let style: StrokeStyle

    public var body: some View { content }
}

public extension View {
    func interpolationMethod(_ method: InterpolationMethod) -> some View {
        _ChartInterpolationContent(content: self, method: method)
    }

    func symbol(_ symbol: BasicChartSymbolShape) -> some View {
        _ChartSymbolContent(content: self, symbol: symbol)
    }

    func lineStyle(_ style: StrokeStyle) -> some View {
        _ChartLineStyleContent(content: self, style: style)
    }
}

public struct PlotDimensionScaleRange: Hashable, Sendable {
    public typealias VisualValue = CGFloat
    public let startPadding: CGFloat
    public let endPadding: CGFloat

    private init(startPadding: CGFloat, endPadding: CGFloat) {
        self.startPadding = startPadding
        self.endPadding = endPadding
    }

    public static var plotDimension: PlotDimensionScaleRange {
        PlotDimensionScaleRange(startPadding: 0, endPadding: 0)
    }

    public static func plotDimension(
        padding: CGFloat
    ) -> PlotDimensionScaleRange {
        PlotDimensionScaleRange(startPadding: padding, endPadding: padding)
    }

    public static func plotDimension(
        startPadding: CGFloat = 0,
        endPadding: CGFloat = 0
    ) -> PlotDimensionScaleRange {
        PlotDimensionScaleRange(
            startPadding: startPadding,
            endPadding: endPadding
        )
    }
}

public struct ChartPlotFrame: Hashable, Sendable {
    public init() {}
}

public struct ChartProxy: Sendable {
    private let xPosition: (@Sendable (Double) -> CGFloat?)?
    let xScale: ChartScale?
    let yScale: ChartScale?
    let plotArea: CGRect
    public let plotFrame: ChartPlotFrame?

    public init() {
        xPosition = nil
        xScale = nil
        yScale = nil
        plotArea = .zero
        plotFrame = ChartPlotFrame()
    }

    @_spi(OpenUIKitHost)
    public init(
        xPosition: @escaping @Sendable (Double) -> CGFloat?,
        hasPlotFrame: Bool = true
    ) {
        self.xPosition = xPosition
        xScale = nil
        yScale = nil
        plotArea = .zero
        plotFrame = hasPlotFrame ? ChartPlotFrame() : nil
    }

    @_spi(OpenUIKitHost)
    public init(xScale: ChartScale, yScale: ChartScale, plotArea: CGRect) {
        xPosition = nil
        self.xScale = xScale
        self.yScale = yScale
        self.plotArea = plotArea
        plotFrame = ChartPlotFrame()
    }

    public func position<P: Plottable>(forX value: P) -> CGFloat? {
        if let encoded = chartEncode(value), let mapped = xScale?.position(for: encoded) {
            return CGFloat(mapped)
        }
        guard let scalar = chartNumericScalar(value) else { return nil }
        return xPosition?(scalar)
    }

    public func position<P: Plottable>(forY value: P) -> CGFloat? {
        if let encoded = chartEncode(value), let mapped = yScale?.position(for: encoded) {
            return CGFloat(mapped)
        }
        _ = value
        return nil
    }

    public func position<X: Plottable, Y: Plottable>(
        for point: (x: X, y: Y)
    ) -> CGPoint? {
        guard let x = position(forX: point.x), let y = position(forY: point.y) else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    public var plotAreaSize: CGSize { plotArea.size }
    public var plotSize: CGSize { plotArea.size }
    public var plotAreaRect: CGRect { plotArea }

    public func selectXRange(from: CGFloat, to: CGFloat) {
        _ = from
        _ = to
    }

    public func selectYRange(from: CGFloat, to: CGFloat) {
        _ = from
        _ = to
    }

    public func selectXValue(at xPosition: CGFloat) { _ = xPosition }
    public func selectYValue(at yPosition: CGFloat) { _ = yPosition }
}

public extension GeometryProxy {
    subscript(_ frame: ChartPlotFrame) -> CGRect {
        _ = frame
        return CGRect(origin: .zero, size: size)
    }
}

public struct AxisValue: Sendable {
    public var index: Int
    public var count: Int
    var encoded: ChartEncodedValue?

    public init() {
        index = 0
        count = 0
        encoded = nil
    }

    public init(index: Int, count: Int, encoded: ChartEncodedValue?) {
        self.index = index
        self.count = count
        self.encoded = encoded
    }

    public func `as`<P: Plottable>(_ type: P.Type) -> P? {
        guard let encoded else { return nil }
        return chartDecode(encoded, as: type)
    }
}

public protocol AxisMark: View {}
public protocol AxisContent: View {}

public struct AxisValueLabel<Content: View>: AxisMark {
    public let centered: Bool?
    public let text: String?
    public let orientation: AxisValueLabelOrientation
    let content: Content?

    public init() where Content == Never {
        centered = nil
        text = nil
        orientation = .automatic
        content = nil
    }

    public init(format: Date.FormatStyle, centered: Bool = false) where Content == Never {
        _ = format
        self.centered = centered
        self.text = nil
        self.orientation = .automatic
        self.content = nil
    }

    public init<Format>(format: Format, centered: Bool = false) where Content == Never {
        _ = format
        self.centered = centered
        self.text = nil
        self.orientation = .automatic
        self.content = nil
    }

    public init(
        _ title: some StringProtocol,
        centered: Bool? = nil,
        orientation: AxisValueLabelOrientation = .automatic
    ) where Content == Text {
        self.centered = centered
        self.text = String(title)
        self.orientation = orientation
        self.content = Text(String(title))
    }

    public init(
        centered: Bool? = nil,
        orientation: AxisValueLabelOrientation = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.centered = centered
        self.text = nil
        self.orientation = orientation
        self.content = content()
    }

    public var body: some View { content.map { AnyView($0) } ?? AnyView(EmptyView()) }
}

public struct AxisMarkPosition: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    private init(_ name: String) { self.name = name }

    public static let automatic = AxisMarkPosition("automatic")
    public static let leading = AxisMarkPosition("leading")
    public static let trailing = AxisMarkPosition("trailing")
    public static let top = AxisMarkPosition("top")
    public static let bottom = AxisMarkPosition("bottom")

    public var description: String { name }
}

public struct _EmptyAxisMark: AxisMark {
    public var body: some View { EmptyView() }
}

@resultBuilder
public enum AxisMarkBuilder {
    public static func buildBlock<Content: AxisMark>(
        _ content: Content
    ) -> Content {
        content
    }
}

@resultBuilder
public enum AxisContentBuilder {
    public static func buildBlock<Content: AxisContent>(
        _ content: Content
    ) -> Content {
        content
    }
}

public struct AxisMarks<Content: AxisMark>: AxisContent {
    public let position: AxisMarkPosition
    public let preset: AxisMarkPreset
    public let numericValues: [Double]
    public let labels: [String]
    let mark: Content?

    public init(position: AxisMarkPosition = .automatic)
        where Content == _EmptyAxisMark
    {
        self.position = position
        self.preset = .automatic
        self.numericValues = []
        self.labels = []
        self.mark = _EmptyAxisMark()
    }

    public init(
        preset: AxisMarkPreset = .automatic,
        position: AxisMarkPosition = .automatic,
        values: AxisMarkValues = .automatic,
        stroke: StrokeStyle? = nil
    ) where Content == _EmptyAxisMark {
        _ = values
        _ = stroke
        self.position = position
        self.preset = preset
        self.numericValues = []
        self.labels = []
        self.mark = _EmptyAxisMark()
    }

    public init<Value: Plottable>(
        preset: AxisMarkPreset = .automatic,
        position: AxisMarkPosition = .automatic,
        values: [Value],
        stroke: StrokeStyle? = nil
    ) where Content == _EmptyAxisMark {
        _ = stroke
        self.position = position
        self.preset = preset
        self.numericValues = values.compactMap(chartNumericScalar)
        self.labels = values.map { String(describing: $0) }
        self.mark = _EmptyAxisMark()
    }

    public init<Values: RandomAccessCollection>(
        values: Values,
        @AxisMarkBuilder content: (AxisValue) -> Content
    ) {
        position = .automatic
        preset = .automatic
        numericValues = []
        labels = []
        let axisValue = AxisValue(index: 0, count: values.count, encoded: nil)
        mark = content(axisValue)
    }

    public init(
        preset: AxisMarkPreset = .automatic,
        position: AxisMarkPosition = .automatic,
        values: AxisMarkValues = .automatic,
        @AxisMarkBuilder content: @escaping (AxisValue) -> Content
    ) {
        _ = values
        self.position = position
        self.preset = preset
        self.numericValues = []
        self.labels = []
        self.mark = content(AxisValue())
    }

    public var body: some View { mark.map { AnyView($0) } ?? AnyView(EmptyView()) }
}

public extension View {
    func chartLegend(_ visibility: Visibility) -> some View {
        _ = visibility
        return self
    }

    func chartXAxis(_ visibility: Visibility) -> some View {
        _ = visibility
        return self
    }

    func chartYAxis(_ visibility: Visibility) -> some View {
        _ = visibility
        return self
    }

    func chartXAxis<Content: AxisContent>(
        @AxisContentBuilder content: () -> Content
    ) -> some View {
        _ = content()
        return self
    }

    func chartYAxis<Content: AxisContent>(
        @AxisContentBuilder content: () -> Content
    ) -> some View {
        _ = content()
        return self
    }

    func chartXSelection<P: Plottable & Hashable>(
        value: Binding<P?>
    ) -> some View {
        _ = value
        return self
    }

    func chartXScale(range: PlotDimensionScaleRange) -> some View {
        _ = range
        return self
    }

    func chartYScale<P: Plottable & Comparable>(
        domain: ClosedRange<P>
    ) -> some View {
        _ = domain
        return self
    }

    func chartOverlay<Overlay: View>(
        @ViewBuilder content: (ChartProxy) -> Overlay
    ) -> some View {
        overlay {
            content(ChartProxy())
        }
    }
}

public extension ChartContent {
    func annotation<C: View>(
        position: AnnotationPosition = .automatic,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        overflowResolution: AnnotationOverflowResolution = AnnotationOverflowResolution(),
        @ViewBuilder content: () -> C
    ) -> some ChartContent {
        _ = position
        _ = alignment
        _ = spacing
        _ = overflowResolution
        _ = content
        return self
    }

    func annotation<C: View>(
        position: AnnotationPosition = .automatic,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> C
    ) -> some ChartContent {
        _ = position
        _ = alignment
        _ = spacing
        _ = content
        return self
    }

    func symbolSize<D: Plottable>(by value: PlottableValue<D>) -> some ChartContent {
        _ = value
        return self
    }

    func symbolSize(_ area: CGFloat) -> some ChartContent {
        _ = area
        return self
    }

    func symbolSize(_ size: CGSize) -> some ChartContent {
        _ = size
        return self
    }

    func compositingLayer() -> some ChartContent { self }

    func alignsMarkStylesWithPlotArea(_ aligns: Bool = true) -> some ChartContent {
        _ = aligns
        return self
    }

    func interpolationMethod(_ method: InterpolationMethod) -> _ChartInterpolationContent<Self> {
        _ChartInterpolationContent(content: self, method: method)
    }

    func lineStyle(_ style: StrokeStyle) -> _ChartLineStyleContent<Self> {
        _ChartLineStyleContent(content: self, style: style)
    }

    func offset(x: CGFloat = 0, y: CGFloat = 0) -> Self {
        _ = x
        _ = y
        return self
    }

    func offset(_ value: CGSize) -> Self {
        _ = value
        return self
    }

    func offset(x: CGFloat = 0, yStart: CGFloat = 0, yEnd: CGFloat = 0) -> Self {
        _ = x
        _ = yStart
        _ = yEnd
        return self
    }

    func offset(xStart: CGFloat = 0, xEnd: CGFloat = 0, y: CGFloat = 0) -> Self {
        _ = xStart
        _ = xEnd
        _ = y
        return self
    }

    func offset(xStart: CGFloat = 0, xEnd: CGFloat = 0, yStart: CGFloat = 0, yEnd: CGFloat = 0) -> Self {
        _ = xStart
        _ = xEnd
        _ = yStart
        _ = yEnd
        return self
    }

    func foregroundStyle<S: ShapeStyle>(_ style: S) -> Self {
        _ = style
        return self
    }

    func foregroundStyle<D: Plottable>(by value: PlottableValue<D>) -> Self {
        _ = value
        return self
    }
}

extension Never: ChartContent {}
extension Never: AxisMark {}

#if !canImport(SwiftUI)
extension Optional: View where Wrapped: View {
    public var body: some View { EmptyView() }
}
#endif

extension Optional: ChartContent where Wrapped: ChartContent {
    public var chartPlotRecords: [ChartPlotRecord] {
        self?.chartPlotRecords ?? []
    }
}

extension ClosedRange: ScaleDomain where Bound: Plottable {}
extension Array: ScaleDomain where Element: Plottable {}
extension PlotDimensionScaleRange: PositionScaleRange {}

public extension Chart {
    func chartXScale(type: ScaleType? = nil) -> Chart {
        var copy = self
        copy.xScaleStorage = ChartScaleStorage(axis: "x", type: type)
        return copy
    }

    func chartXScale<Range: PositionScaleRange>(
        range: Range,
        type: ScaleType? = nil
    ) -> Chart {
        var copy = self
        copy.xScaleStorage = ChartScaleStorage(
            axis: "x",
            type: type,
            range: range as? PlotDimensionScaleRange
        )
        return copy
    }

    func chartXScale<Domain: ScaleDomain>(
        domain: Domain,
        type: ScaleType? = nil
    ) -> Chart {
        var copy = self
        copy.xScaleStorage = storage(axis: "x", domain: domain, type: type)
        return copy
    }

    func chartYScale(type: ScaleType? = nil) -> Chart {
        var copy = self
        copy.yScaleStorage = ChartScaleStorage(axis: "y", type: type)
        return copy
    }

    func chartYScale<Domain: ScaleDomain>(
        domain: Domain,
        type: ScaleType? = nil
    ) -> Chart {
        var copy = self
        copy.yScaleStorage = storage(axis: "y", domain: domain, type: type)
        return copy
    }

    func chartXAxis(_ visibility: Visibility) -> Chart {
        var copy = self
        copy.xAxisStorage = ChartAxisStorage(
            axis: "x",
            visibility: visibility,
            position: .bottom
        )
        return copy
    }

    func chartYAxis(_ visibility: Visibility) -> Chart {
        var copy = self
        copy.yAxisStorage = ChartAxisStorage(
            axis: "y",
            visibility: visibility,
            position: .leading
        )
        return copy
    }

    func chartXAxis<Axis: AxisContent>(
        @AxisContentBuilder content: () -> Axis
    ) -> Chart {
        var copy = self
        let built = content()
        if let marks = built as? AxisMarks<_EmptyAxisMark> {
            copy.xAxisStorage = ChartAxisStorage(
                axis: "x",
                position: marks.position == .automatic ? .bottom : marks.position,
                values: marks.numericValues,
                labels: marks.labels
            )
        } else {
            copy.xAxisStorage = ChartAxisStorage(axis: "x", position: .bottom)
        }
        return copy
    }

    func chartYAxis<Axis: AxisContent>(
        @AxisContentBuilder content: () -> Axis
    ) -> Chart {
        var copy = self
        let built = content()
        if let marks = built as? AxisMarks<_EmptyAxisMark> {
            copy.yAxisStorage = ChartAxisStorage(
                axis: "y",
                position: marks.position == .automatic ? .leading : marks.position,
                values: marks.numericValues,
                labels: marks.labels
            )
        } else {
            copy.yAxisStorage = ChartAxisStorage(axis: "y", position: .leading)
        }
        return copy
    }

    func chartLegend(_ visibility: Visibility) -> Chart {
        var copy = self
        copy.legendStorage = ChartLegendStorage(visibility: visibility)
        return copy
    }

    func chartLegend(
        position: AnnotationPosition = .automatic,
        alignment: Alignment? = nil,
        spacing: CGFloat? = nil
    ) -> Chart {
        _ = alignment
        var copy = self
        copy.legendStorage = ChartLegendStorage(position: position, spacing: spacing)
        return copy
    }

    func chartForegroundStyleScale<S: Sequence>(
        domain: S,
        type: ScaleType? = nil
    ) -> Chart where S.Element: Plottable {
        var copy = self
        copy.foregroundStyleScaleStorage = ChartForegroundStyleScaleStorage(
            domain: domain.map { String(describing: $0) },
            type: type
        )
        return copy
    }
}

private func storage<Domain: ScaleDomain>(
    axis: String,
    domain: Domain,
    type: ScaleType?
) -> ChartScaleStorage {
    if let range = domain as? ClosedRange<Int> {
        return ChartScaleStorage(
            axis: axis,
            type: type,
            domainMin: Double(range.lowerBound),
            domainMax: Double(range.upperBound)
        )
    }
    if let range = domain as? ClosedRange<Double> {
        return ChartScaleStorage(
            axis: axis,
            type: type,
            domainMin: range.lowerBound,
            domainMax: range.upperBound
        )
    }
    if let names = domain as? [String] {
        return ChartScaleStorage(axis: axis, type: type ?? .category, categories: names)
    }
    return ChartScaleStorage(axis: axis, type: type)
}
