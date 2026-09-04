#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

// Additional Charts-owned types from the Xcode 26.1 public surface.
// 3D, scroll, and vectorized plot rendering stay fail-closed.

public protocol ChartSymbolShape: Shape {}
public protocol Chart3DContent: View {}
public protocol Chart3DSymbolShape {}
public protocol Chart3DSurfaceStyle: Hashable {}
public protocol ScaleRange { associatedtype VisualValue }
public protocol ScaleDomain {}
public protocol PositionScaleRange: ScaleRange where VisualValue == CGFloat {}
public protocol VectorizedChartContent: ChartContent { associatedtype DataElement }
public protocol ChartScrollTargetBehavior: ScrollTargetBehavior {}
public protocol PrimitivePlottableProtocol: Plottable {}

public struct AnyChartSymbolShape: Hashable, Sendable, View, ChartSymbolShape {
    private let shape: BasicChartSymbolShape
    public init(_ shape: BasicChartSymbolShape = .circle) { self.shape = shape }
    public var body: some View { shape }
    public func path(in rect: CGRect) -> Path { shape.path(in: rect) }
}

extension BasicChartSymbolShape: ChartSymbolShape {}

public struct ChartPlotContent: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct ChartAxisContent: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Chart3D<Content: Chart3DContent>: View {
    public init(@Chart3DContentBuilder content: () -> Content) { _ = content }
    public var body: some View { EmptyView() }
}

@resultBuilder
public struct Chart3DContentBuilder {
    public static func buildBlock() -> _EmptyChart3DContent { _EmptyChart3DContent() }
    public static func buildBlock<Content: Chart3DContent>(_ content: Content) -> Content { content }
}

public struct _EmptyChart3DContent: Chart3DContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Chart3DPose: Hashable, Sendable {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let top = Chart3DPose("top")
    public static let back = Chart3DPose("back")
    public static let left = Chart3DPose("left")
    public static let front = Chart3DPose("front")
    public static let right = Chart3DPose("right")
    public static let bottom = Chart3DPose("bottom")
    public static let `default` = Chart3DPose("default")
}

public struct Chart3DCameraProjection: Hashable, Sendable {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let perspective = Chart3DCameraProjection("perspective")
    public static let orthographic = Chart3DCameraProjection("orthographic")
}

public struct BasicChart3DSymbolShape: Hashable, Sendable, Chart3DSymbolShape {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let sphere = BasicChart3DSymbolShape("sphere")
    public static let cube = BasicChart3DSymbolShape("cube")
    public static let cone = BasicChart3DSymbolShape("cone")
    public static let cylinder = BasicChart3DSymbolShape("cylinder")
}

public struct BasicChart3DSurfaceStyle: Hashable, Sendable, Chart3DSurfaceStyle {
    public init() {}
}

public struct AnyChartContent: View, ChartContent {
    public init<Content: ChartContent>(_ content: Content) { _ = content }
    public var body: some View { EmptyView() }
}

public struct AnyAxisMark: View, AxisMark {
    public init<Content: AxisMark>(_ content: Content) { _ = content }
    public var body: some View { EmptyView() }
}

public struct AnyAxisContent: View, AxisContent {
    public init<Content: AxisContent>(_ content: Content) { _ = content }
    public var body: some View { EmptyView() }
}

public struct BuilderConditional<TrueContent, FalseContent> {
    public init() {}
}

public struct AutomaticScaleDomain: ScaleDomain, Hashable, Sendable {
    public static let automatic = AutomaticScaleDomain()
    public init() {}
}

public struct ScaleType: Hashable, Sendable {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let linear = ScaleType("linear")
    public static let log = ScaleType("log")
    public static let categorical = ScaleType("categorical")
    public static let date = ScaleType("date")
}

public struct MarkDimension: Hashable, Sendable {
    public static let automatic = MarkDimension()
    public init() {}
}

public struct MarkDimensions<DataElement>: Hashable {
    public static var automatic: MarkDimensions<DataElement> { MarkDimensions() }
    public init() {}
}

public struct MarkStackingMethod: Hashable, Sendable {
    public static let standard = MarkStackingMethod()
    public static let center = MarkStackingMethod()
    public static let normalized = MarkStackingMethod()
    public static let unstacked = MarkStackingMethod()
    public init() {}
}

public struct AxisMarkPreset: Hashable, Sendable {
    public static let inset = AxisMarkPreset("inset")
    public static let aligned = AxisMarkPreset("aligned")
    public static let extended = AxisMarkPreset("extended")
    public static let automatic = AxisMarkPreset("automatic")
    private let name: String
    private init(_ name: String) { self.name = name }
}

public struct AxisMarkValues: Hashable, Sendable {
    public static let automatic = AxisMarkValues()
    public init() {}
    public static func stride<T>(by value: T) -> AxisMarkValues {
        _ = value
        return AxisMarkValues()
    }
}

public struct AxisGridLine: View, AxisMark {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct AxisTick: View, AxisMark {
    public struct Length: Hashable, Sendable {
        public static let automatic = Length()
        public init() {}
    }
    public init() {}
    public var body: some View { EmptyView() }
}

public struct AxisValueLabelOrientation: Hashable, Sendable {
    public static let automatic = AxisValueLabelOrientation()
    public static let vertical = AxisValueLabelOrientation()
    public static let horizontal = AxisValueLabelOrientation()
    public init() {}
}

public struct AxisValueLabelCollisionResolution: Hashable, Sendable {
    public static let automatic = AxisValueLabelCollisionResolution()
    public init() {}
}

public struct AnnotationContext: Hashable, Sendable {
    public init() {}
}

public struct AnnotationPosition: Hashable, Sendable {
    public static let automatic = AnnotationPosition()
    public static let overlay = AnnotationPosition()
    public static let leading = AnnotationPosition()
    public static let trailing = AnnotationPosition()
    public static let top = AnnotationPosition()
    public static let bottom = AnnotationPosition()
    public init() {}
}

public struct AnnotationOverflowResolution: Hashable, Sendable {
    public struct Boundary: Hashable, Sendable {
        public static let automatic = Boundary()
        public static let plot = Boundary()
        public static let chart = Boundary()
        public init() {}
    }
    public struct Strategy: Hashable, Sendable {
        public static let automatic = Strategy()
        public init() {}
    }
    public init() {}
}

public struct ChartBinRange<Bound: Comparable & Hashable>: Hashable {
    public let lowerBound: Bound
    public let upperBound: Bound
    public init(uncheckedBounds: (lower: Bound, upper: Bound)) {
        lowerBound = uncheckedBounds.lower
        upperBound = uncheckedBounds.upper
    }
}

public struct NumberBins<Value: Comparable & Numeric & Hashable>: Hashable {
    public let thresholds: [Value]
    public init(thresholds: [Value] = []) { self.thresholds = thresholds }
    public init(range: ClosedRange<Value>, count: Int) {
        _ = range
        _ = count
        self.thresholds = []
    }
}

public struct DateBins: Hashable, Sendable {
    public let unit: Calendar.Component
    public let range: ClosedRange<Date>?
    public init(unit: Calendar.Component, range: ClosedRange<Date>? = nil) {
        self.unit = unit
        self.range = range
    }
}

public struct PlottableProjection<DataElement, DataValue: Plottable> {
    public let label: String
    public init(label: String = "") { self.label = label }
    public static func value(_ label: some StringProtocol, _ value: DataValue) -> Self {
        Self(label: String(label))
    }
    public static func value(_ label: some StringProtocol, _ value: KeyPath<DataElement, DataValue>) -> Self {
        _ = value
        return Self(label: String(label))
    }
    public static func value(_ label: some StringProtocol, _ start: DataValue, _ end: DataValue) -> Self {
        _ = start
        _ = end
        return Self(label: String(label))
    }
    public static func value(_ label: Text, _ value: DataValue) -> Self { Self(label: "\(label)") }
    public static func value(_ labelKey: LocalizedStringKey, _ value: DataValue) -> Self { Self(label: "\(labelKey)") }
    public static func value(_ labelResource: LocalizedStringResource, _ value: DataValue) -> Self { Self(label: "\(labelResource)") }
}

public struct MajorValueAlignment<Value: Plottable>: Hashable {
    public init() {}
}

public struct ValueAlignedLimitBehavior: Hashable, Sendable {
    public static let automatic = ValueAlignedLimitBehavior()
    public static let never = ValueAlignedLimitBehavior()
    public static let always = ValueAlignedLimitBehavior()
    public init() {}
}

public struct ValueAlignedChartScrollTargetBehavior: ChartScrollTargetBehavior {
    public init() {}
}

@dynamicMemberLookup
public struct ChartScrollTargetBehaviorContext {
    public init() {}
    public subscript<T>(dynamicMember member: String) -> T? {
        _ = member
        return nil
    }
}

public struct BarMark: ChartContent {
    public init() {}
    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) {
        _ = x
        _ = y
    }
    public var body: some View { EmptyView() }
}

public struct PointMark: ChartContent {
    public init() {}
    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) {
        _ = x
        _ = y
    }
    public var body: some View { EmptyView() }
}

public struct SectorMark: ChartContent {
    public init() {}
    public init<X: Plottable & Sendable>(angle: PlottableValue<X>) { _ = angle }
    public var body: some View { EmptyView() }
}

public struct SurfacePlot: Chart3DContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Plot<Content: ChartContent>: ChartContent {
    public init(@ChartContentBuilder content: () -> Content) { _ = content }
    public var body: some View { EmptyView() }
}

public struct AreaPlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct BarPlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct LinePlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct PointPlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct RectanglePlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct RulePlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct SectorPlot<Content>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedBarPlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedAreaPlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedLinePlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedRulePlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedPointPlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedSectorPlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct VectorizedRectanglePlotContent<Data: RandomAccessCollection>: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct FunctionAreaPlotContent: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct FunctionLinePlotContent: ChartContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public extension ChartProxy {
    func symbolSize<P: Plottable>(for value: P) -> CGFloat? { _ = value; return nil }
    func symbolDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    var plotAreaFrame: Anchor<CGRect> { Anchor<CGRect>() }
    func positionRange<X: Plottable, Y: Plottable>(for point: (x: X, y: Y)) -> CGRect? { _ = point; return nil }
    func positionRange<P: Plottable>(forX value: P) -> ClosedRange<CGFloat>? { _ = value; return nil }
    func positionRange<P: Plottable>(forY value: P) -> ClosedRange<CGFloat>? { _ = value; return nil }
    func foregroundStyle<P: Plottable>(for value: P) -> AnyShapeStyle? { _ = value; return nil }
    func lineStyleDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    func selectAngleValue(at angle: Angle) { _ = angle }
    func symbolSizeDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    var plotContainerFrame: Anchor<CGRect>? { nil }
    func foregroundStyleDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    func angle(at position: CGPoint) -> Angle { _ = position; return Angle() }
    func value<X: Plottable, Y: Plottable>(at position: CGPoint, as _: (X, Y).Type = (X, Y).self) -> (X, Y)? {
        _ = position
        return nil
    }
    func value<P: Plottable>(atX position: CGFloat, as _: P.Type = P.self) -> P? {
        _ = position
        return nil
    }
    func value<P: Plottable>(atY position: CGFloat, as _: P.Type = P.self) -> P? {
        _ = position
        return nil
    }
    func value<P: Plottable>(atAngle angle: Angle, as _: P.Type = P.self) -> P? {
        _ = angle
        return nil
    }
    func symbol<P: Plottable>(for value: P) -> AnyChartSymbolShape? { _ = value; return nil }
    func xDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    func yDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    func lineStyle<P: Plottable>(for value: P) -> StrokeStyle? { _ = value; return nil }
}

public extension PlottableValue {
    static func value(_ labelKey: LocalizedStringKey, _ value: Value) -> Self {
        .value("\(labelKey)", value)
    }
    static func value(_ label: Text, _ value: Value) -> Self {
        .value("\(label)", value)
    }
    static func value(_ labelResource: LocalizedStringResource, _ value: Value) -> Self {
        .value("\(labelResource)", value)
    }
    static func value<S: StringProtocol>(_ label: S, _ range: Range<Value>) -> Self where Value: Comparable {
        .value(String(label), range.lowerBound)
    }
}

public extension PlottableValue where Value == Date {
    static func value(
        _ label: String,
        _ date: Date,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return .value(label, date)
    }
}
