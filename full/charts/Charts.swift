@_exported import SwiftUI
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

private func _chartScalar<Value: Plottable>(_ value: Value) -> Double? {
    switch value {
    case let value as Int: return Double(value)
    case let value as Int8: return Double(value)
    case let value as Int16: return Double(value)
    case let value as Int32: return Double(value)
    case let value as Int64: return Double(value)
    case let value as UInt: return Double(value)
    case let value as UInt8: return Double(value)
    case let value as UInt16: return Double(value)
    case let value as UInt32: return Double(value)
    case let value as UInt64: return Double(value)
    case let value as Float: return Double(value)
    case let value as Double: return value
    case let value as Date: return value.timeIntervalSinceReferenceDate
    default: return nil
    }
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

public protocol ChartContent: View {}

public struct _ChartViewContent<Content: View>: ChartContent {
    let content: Content

    public var body: some View { content }
}

public struct _ChartPairContent<First: ChartContent, Second: ChartContent>:
    ChartContent
{
    let first: First
    let second: Second

    public var body: some View {
        ZStack {
            first
            second
        }
    }
}

public struct _ChartOptionalContent<Content: ChartContent>: ChartContent {
    let content: Content?

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

    @ViewBuilder
    public var body: some View {
        switch storage {
        case .first(let content): content
        case .second(let content): content
        }
    }
}

@MainActor
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
}

public struct Chart: View {
    private let content: AnyView

    public init<Content: ChartContent>(
        @ChartContentBuilder content: () -> Content
    ) {
        self.content = AnyView(content())
    }

    public init<Data: RandomAccessCollection, Content: ChartContent>(
        _ data: Data,
        @ChartContentBuilder content: @escaping (Data.Element) -> Content
    ) {
        let indexed = Array(data.enumerated())
        self.content = AnyView(
            ForEach(indexed, id: \.offset) { element in
                content(element.element)
            }
        )
    }

    public init<
        Data: RandomAccessCollection,
        ID: Hashable,
        Content: ChartContent
    >(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ChartContentBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.content = AnyView(
            ForEach(data, id: id) { element in
                content(element)
            }
        )
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            content
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chart")
    }
}

public struct RectangleMark: ChartContent {
    public let xStart: Double?
    public let xEnd: Double?
    public let yStart: Double?
    public let yEnd: Double?

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
        self.xStart = _chartScalar(xStart.value)
        self.xEnd = _chartScalar(xEnd.value)
        self.yStart = _chartScalar(yStart.value)
        self.yEnd = _chartScalar(yEnd.value)
    }

    public var body: some View {
        let magnitude = max(2, min(200, abs((yEnd ?? 0) - (yStart ?? 0))))
        Rectangle()
            .frame(
                minWidth: 2,
                idealWidth: 8,
                maxWidth: 18,
                minHeight: CGFloat(magnitude)
            )
            .accessibilityLabel("Bar \(yEnd ?? 0)")
    }
}

public struct LineMark: ChartContent {
    public let x: Double?
    public let y: Double?

    public init<X, Y>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = _chartScalar(x.value)
        self.y = _chartScalar(y.value)
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

    public init<X, Y>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) where X: Plottable & Sendable, Y: Plottable & Sendable {
        self.x = _chartScalar(x.value)
        self.y = _chartScalar(y.value)
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

    public init<X>(x: PlottableValue<X>) where X: Plottable & Sendable {
        self.x = _chartScalar(x.value)
    }

    public var body: some View {
        Rectangle()
            .frame(minWidth: 1, idealWidth: 1, maxWidth: 1, maxHeight: .infinity)
            .accessibilityLabel("Selection rule")
    }
}

public enum InterpolationMethod: String, Hashable, Sendable {
    case linear
    case catmullRom
    case cardinal
    case monotone
    case stepStart
    case stepCenter
    case stepEnd
}

public struct BasicChartSymbolShape: Hashable, Sendable {
    private let name: String
    private init(_ name: String) { self.name = name }

    public static let circle = BasicChartSymbolShape("circle")
    public static let square = BasicChartSymbolShape("square")
}

public struct _ChartInterpolationContent<Content: View>: View {
    public let content: Content
    public let method: InterpolationMethod

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
    public let plotFrame: ChartPlotFrame?

    public init() {
        xPosition = nil
        plotFrame = ChartPlotFrame()
    }

    @_spi(OpenUIKitHost)
    public init(
        xPosition: @escaping @Sendable (Double) -> CGFloat?,
        hasPlotFrame: Bool = true
    ) {
        self.xPosition = xPosition
        plotFrame = hasPlotFrame ? ChartPlotFrame() : nil
    }

    public func position<P: Plottable>(forX value: P) -> CGFloat? {
        guard let scalar = _chartScalar(value) else { return nil }
        return xPosition?(scalar)
    }
}

public extension GeometryProxy {
    subscript(_ frame: ChartPlotFrame) -> CGRect {
        _ = frame
        return CGRect(origin: .zero, size: size)
    }
}

public struct AxisValue: Sendable {
    public init() {}
}

public protocol AxisMark: View {}
public protocol AxisContent: View {}

public struct AxisValueLabel: AxisMark {
    public init() {}

    public init(format: Date.FormatStyle, centered: Bool = false) {
        _ = format
        _ = centered
    }

    public init<Format>(format: Format, centered: Bool = false) {
        _ = format
        _ = centered
    }

    public var body: some View { EmptyView() }
}

public struct AxisMarkPosition: Hashable, Sendable {
    private let name: String
    private init(_ name: String) { self.name = name }

    public static let automatic = AxisMarkPosition("automatic")
    public static let leading = AxisMarkPosition("leading")
    public static let trailing = AxisMarkPosition("trailing")
    public static let top = AxisMarkPosition("top")
    public static let bottom = AxisMarkPosition("bottom")
}

public struct _EmptyAxisMark: AxisMark {
    public var body: some View { EmptyView() }
}

@MainActor
@resultBuilder
public enum AxisMarkBuilder {
    public static func buildBlock<Content: AxisMark>(
        _ content: Content
    ) -> Content {
        content
    }
}

@MainActor
@resultBuilder
public enum AxisContentBuilder {
    public static func buildBlock<Content: AxisContent>(
        _ content: Content
    ) -> Content {
        content
    }
}

public struct AxisMarks<Content: AxisMark>: AxisContent {
    public init(position: AxisMarkPosition = .automatic)
        where Content == _EmptyAxisMark
    {
        _ = position
    }

    public init<Values: RandomAccessCollection>(
        values: Values,
        @AxisMarkBuilder content: (AxisValue) -> Content
    ) {
        _ = values
        _ = content(AxisValue())
    }

    public var body: some View { EmptyView() }
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
