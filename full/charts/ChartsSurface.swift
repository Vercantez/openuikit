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
    private let records: [ChartPlotRecord]
    public init<Content: ChartContent>(_ content: Content) {
        records = content.chartPlotRecords
    }
    public var chartPlotRecords: [ChartPlotRecord] { records }
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

public struct BuilderConditional<TrueContent: ChartContent, FalseContent: ChartContent>: ChartContent {
    enum Storage {
        case first(TrueContent)
        case second(FalseContent)
    }
    let storage: Storage?
    public init() { storage = nil }
    init(storage: Storage) { self.storage = storage }
    public var chartPlotRecords: [ChartPlotRecord] {
        switch storage {
        case .first(let content): return content.chartPlotRecords
        case .second(let content): return content.chartPlotRecords
        case nil: return []
        }
    }
    public var body: some View { EmptyView() }
}

public struct AutomaticScaleDomain: ScaleDomain, Hashable, Sendable {
    public static let automatic = AutomaticScaleDomain()
    public init() {}
}

public struct ScaleType: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let linear = ScaleType("linear")
    public static let log = ScaleType("log")
    public static let category = ScaleType("category")
    public static let categorical = ScaleType("category")
    public static let date = ScaleType("date")
    public static let squareRoot = ScaleType("squareRoot")
    public static let symmetricLog = ScaleType("symmetricLog")
    public static let symbolLog = ScaleType("symbolLog")
    public static func symmetricLog(slopeAtZero: Double) -> ScaleType {
        _ = slopeAtZero
        return .symmetricLog
    }
    public static func power(exponent: Double) -> ScaleType {
        _ = exponent
        return ScaleType("power")
    }
    public var description: String { name }
}

public struct MarkDimension: Hashable, Sendable {
    public static let automatic = MarkDimension()
    public init() {}
}

public struct MarkDimensions<DataElement>: Hashable {
    public static var automatic: MarkDimensions<DataElement> { MarkDimensions() }
    public init() {}
}

public struct MarkStackingMethod: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let standard = MarkStackingMethod("standard")
    public static let center = MarkStackingMethod("center")
    public static let normalized = MarkStackingMethod("normalized")
    public static let unstacked = MarkStackingMethod("unstacked")
    public init() { self = .standard }
    public var description: String { name }
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
    public var description: String
    public var strideStep: Double?
    public var explicitValues: [Double]
    public var desiredCount: Int?
    public var calendarComponent: Calendar.Component?

    public static let automatic = AxisMarkValues(
        description: "automatic",
        strideStep: nil,
        explicitValues: [],
        desiredCount: 5
    )

    public init() {
        description = "automatic"
        strideStep = nil
        explicitValues = []
        desiredCount = 5
        calendarComponent = nil
    }

    init(
        description: String,
        strideStep: Double?,
        explicitValues: [Double],
        desiredCount: Int? = nil,
        calendarComponent: Calendar.Component? = nil
    ) {
        self.description = description
        self.strideStep = strideStep
        self.explicitValues = explicitValues
        self.desiredCount = desiredCount
        self.calendarComponent = calendarComponent
    }

    public static func stride<P: Plottable>(
        by stepSize: P,
        roundLowerBound: Bool? = nil,
        roundUpperBound: Bool? = nil
    ) -> AxisMarkValues {
        _ = roundLowerBound
        _ = roundUpperBound
        return AxisMarkValues(
            description: "stride",
            strideStep: chartNumericScalar(stepSize),
            explicitValues: []
        )
    }

    public static func stride(
        by component: Calendar.Component,
        count: Int = 1,
        roundLowerBound: Bool? = nil,
        roundUpperBound: Bool? = nil,
        calendar: Calendar? = nil
    ) -> AxisMarkValues {
        _ = roundLowerBound
        _ = roundUpperBound
        _ = calendar
        return AxisMarkValues(
            description: "stride-calendar",
            strideStep: Double(count),
            explicitValues: [],
            calendarComponent: component
        )
    }

    public static func automatic(
        desiredCount: Int? = nil,
        roundLowerBound: Bool? = nil,
        roundUpperBound: Bool? = nil
    ) -> AxisMarkValues {
        _ = roundLowerBound
        _ = roundUpperBound
        return AxisMarkValues(
            description: "automatic",
            strideStep: nil,
            explicitValues: [],
            desiredCount: desiredCount
        )
    }

    public static func automatic<P: Plottable>(
        minimumStride: P,
        desiredCount: Int? = nil,
        roundLowerBound: Bool? = nil,
        roundUpperBound: Bool? = nil
    ) -> AxisMarkValues {
        _ = roundLowerBound
        _ = roundUpperBound
        return AxisMarkValues(
            description: "automatic",
            strideStep: chartNumericScalar(minimumStride),
            explicitValues: [],
            desiredCount: desiredCount
        )
    }

    public static func values(_ values: [Double]) -> AxisMarkValues {
        AxisMarkValues(
            description: "values",
            strideStep: nil,
            explicitValues: values
        )
    }

    public func resolvedTicks(domainMin: Double, domainMax: Double) -> [Double] {
        if !explicitValues.isEmpty {
            return explicitValues
        }
        if let step = strideStep, step > 0 {
            var ticks: [Double] = []
            var value = domainMin
            while value <= domainMax + step * 0.0001 {
                ticks.append(value)
                value += step
            }
            return ticks
        }
        return ChartNiceNumbers.ticks(
            min: domainMin,
            max: domainMax,
            desired: desiredCount ?? 5
        )
    }
}

public struct AxisGridLine: View, AxisMark {
    public let centered: Bool?
    public let stroke: StrokeStyle?
    public init(centered: Bool? = nil, stroke: StrokeStyle? = nil) {
        self.centered = centered
        self.stroke = stroke
    }
    public var body: some View { EmptyView() }
}

public struct AxisTick: View, AxisMark {
    public struct Length: Hashable, Sendable, CustomStringConvertible {
        private let name: String
        private let extra: CGFloat
        private init(_ name: String, extra: CGFloat = 0) {
            self.name = name
            self.extra = extra
        }
        public static let automatic = Length("automatic")
        public static let label = Length("label")
        public static let longestLabel = Length("longestLabel")
        public static func label(extendPastBy: CGFloat = 0) -> Length {
            Length("label", extra: extendPastBy)
        }
        public static func longestLabel(extendPastBy: CGFloat = 0) -> Length {
            Length("longestLabel", extra: extendPastBy)
        }
        public init() { self = .automatic }
        public var description: String { name }
    }
    public let centered: Bool?
    public let length: Length
    public let stroke: StrokeStyle?
    public init(
        centered: Bool? = nil,
        length: Length = .automatic,
        stroke: StrokeStyle? = nil
    ) {
        self.centered = centered
        self.length = length
        self.stroke = stroke
    }
    public init(
        centered: Bool? = nil,
        length: CGFloat,
        stroke: StrokeStyle? = nil
    ) {
        self.centered = centered
        self.length = .label(extendPastBy: length)
        self.stroke = stroke
    }
    public var body: some View { EmptyView() }
}

public struct AxisValueLabelOrientation: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let automatic = AxisValueLabelOrientation("automatic")
    public static let vertical = AxisValueLabelOrientation("vertical")
    public static let verticalReversed = AxisValueLabelOrientation("verticalReversed")
    public static let horizontal = AxisValueLabelOrientation("horizontal")
    public init() { self = .automatic }
    public var description: String { name }
}

public struct AxisValueLabelCollisionResolution: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let automatic = AxisValueLabelCollisionResolution("automatic")
    public static let greedy = AxisValueLabelCollisionResolution("greedy")
    public static let disabled = AxisValueLabelCollisionResolution("disabled")
    public static let truncate = AxisValueLabelCollisionResolution("truncate")
    public static func greedy(priority: Double = 0, minimumSpacing: CGFloat? = nil) -> AxisValueLabelCollisionResolution {
        _ = priority
        _ = minimumSpacing
        return .greedy
    }
    public init() { self = .automatic }
    public var description: String { name }
}

public struct AnnotationContext: Hashable, Sendable {
    public init() {}
}

public struct AnnotationPosition: Hashable, Sendable, CustomStringConvertible {
    private let name: String
    private init(_ name: String) { self.name = name }
    public static let automatic = AnnotationPosition("automatic")
    public static let overlay = AnnotationPosition("overlay")
    public static let leading = AnnotationPosition("leading")
    public static let trailing = AnnotationPosition("trailing")
    public static let top = AnnotationPosition("top")
    public static let bottom = AnnotationPosition("bottom")
    public init() { self = .automatic }
    public var description: String { name }
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
    let extract: (DataElement) -> DataValue?

    public init(label: String = "") {
        self.label = label
        extract = { _ in nil }
    }

    init(label: String, extract: @escaping (DataElement) -> DataValue?) {
        self.label = label
        self.extract = extract
    }

    public func value(from element: DataElement) -> DataValue? {
        extract(element)
    }

    public static func value(_ labelResource: LocalizedStringResource, _ value: DataValue) -> Self {
        Self(label: labelResource.key, extract: { _ in value })
    }

    public static func value(_ labelResource: LocalizedStringResource, _ value: KeyPath<DataElement, DataValue>) -> Self {
        Self(label: labelResource.key, extract: { $0[keyPath: value] })
    }

    public static func value(
        _ labelResource: LocalizedStringResource,
        _ start: DataValue,
        _ end: DataValue
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: labelResource.key, extract: { _ in start })
    }

    public static func value(
        _ labelResource: LocalizedStringResource,
        _ start: KeyPath<DataElement, DataValue>,
        _ end: KeyPath<DataElement, DataValue>
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: labelResource.key, extract: { $0[keyPath: start] })
    }

    public static func value(_ labelKey: LocalizedStringKey, _ value: DataValue) -> Self {
        Self(label: labelKey.key, extract: { _ in value })
    }

    public static func value(_ labelKey: LocalizedStringKey, _ value: KeyPath<DataElement, DataValue>) -> Self {
        Self(label: labelKey.key, extract: { $0[keyPath: value] })
    }

    public static func value(
        _ labelKey: LocalizedStringKey,
        _ start: DataValue,
        _ end: DataValue
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: labelKey.key, extract: { _ in start })
    }

    public static func value(
        _ labelKey: LocalizedStringKey,
        _ start: KeyPath<DataElement, DataValue>,
        _ end: KeyPath<DataElement, DataValue>
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: labelKey.key, extract: { $0[keyPath: start] })
    }

    public static func value(_ label: Text, _ value: DataValue) -> Self {
        Self(label: label.content, extract: { _ in value })
    }

    public static func value(_ label: Text, _ value: KeyPath<DataElement, DataValue>) -> Self {
        Self(label: label.content, extract: { $0[keyPath: value] })
    }

    public static func value(
        _ label: Text,
        _ start: DataValue,
        _ end: DataValue
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: label.content, extract: { _ in start })
    }

    public static func value(
        _ label: Text,
        _ start: KeyPath<DataElement, DataValue>,
        _ end: KeyPath<DataElement, DataValue>
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: label.content, extract: { $0[keyPath: start] })
    }

    public static func value(_ label: some StringProtocol, _ value: DataValue) -> Self {
        Self(label: String(label), extract: { _ in value })
    }

    public static func value(_ label: some StringProtocol, _ value: KeyPath<DataElement, DataValue>) -> Self {
        Self(label: String(label), extract: { $0[keyPath: value] })
    }

    public static func value(
        _ label: some StringProtocol,
        _ start: DataValue,
        _ end: DataValue
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: String(label), extract: { _ in start })
    }

    public static func value(
        _ label: some StringProtocol,
        _ start: KeyPath<DataElement, DataValue>,
        _ end: KeyPath<DataElement, DataValue>
    ) -> Self where DataValue: Comparable {
        _ = end
        return Self(label: String(label), extract: { $0[keyPath: start] })
    }

    public static func value(
        _ labelKey: LocalizedStringKey,
        _ date: KeyPath<DataElement, DataValue>,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: labelKey.key, extract: { $0[keyPath: date] })
    }

    public static func value(
        _ label: Text,
        _ date: KeyPath<DataElement, DataValue>,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: label.content, extract: { $0[keyPath: date] })
    }

    public static func value(
        _ labelResource: LocalizedStringResource,
        _ date: KeyPath<DataElement, DataValue>,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: labelResource.key, extract: { $0[keyPath: date] })
    }

    public static func value(
        _ label: some StringProtocol,
        _ date: KeyPath<DataElement, DataValue>,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: String(label), extract: { $0[keyPath: date] })
    }

    public static func value(
        _ labelKey: LocalizedStringKey,
        _ date: DataValue,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: labelKey.key, extract: { _ in date })
    }

    public static func value(
        _ label: Text,
        _ date: DataValue,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: label.content, extract: { _ in date })
    }

    public static func value(
        _ labelResource: LocalizedStringResource,
        _ date: DataValue,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: labelResource.key, extract: { _ in date })
    }

    public static func value(
        _ label: some StringProtocol,
        _ date: DataValue,
        unit: Calendar.Component,
        calendar: Calendar? = nil
    ) -> Self {
        _ = unit
        _ = calendar
        return Self(label: String(label), extract: { _ in date })
    }
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
    public let x: Double?
    public let y: Double?
    public let xStart: Double?
    public let xEnd: Double?
    public let yStart: Double?
    public let yEnd: Double?
    public let category: String?
    public let series: String?
    public let stacking: MarkStackingMethod
    public let width: MarkDimension
    public let height: MarkDimension

    public init() {
        x = nil
        y = nil
        xStart = nil
        xEnd = nil
        yStart = nil
        yEnd = nil
        category = nil
        series = nil
        stacking = .standard
        width = .automatic
        height = .automatic
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>,
        width: MarkDimension = .automatic,
        height: MarkDimension = .automatic,
        stacking: MarkStackingMethod = .standard
    ) {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.xStart = nil
        self.xEnd = nil
        self.yStart = nil
        self.yEnd = self.y
        self.category = x.value as? String
        self.series = nil
        self.stacking = stacking
        self.width = width
        self.height = height
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>,
        width: MarkDimension = .automatic
    ) {
        self.x = chartNumericScalar(x.value)
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.y = self.yEnd
        self.xStart = nil
        self.xEnd = nil
        self.category = x.value as? String
        self.series = nil
        self.stacking = .unstacked
        self.width = width
        self.height = .automatic
    }

    public init<X: Plottable & Sendable>(
        x: PlottableValue<X>,
        yStart: CGFloat? = nil,
        yEnd: CGFloat? = nil,
        width: MarkDimension = .automatic,
        stacking: MarkStackingMethod = .unstacked
    ) {
        self.x = chartNumericScalar(x.value)
        self.yStart = yStart.map(Double.init)
        self.yEnd = yEnd.map(Double.init)
        self.y = self.yEnd
        self.xStart = nil
        self.xEnd = nil
        self.category = x.value as? String
        self.series = nil
        self.stacking = stacking
        self.width = width
        self.height = .automatic
    }

    public init<Y: Plottable & Sendable>(
        xStart: CGFloat? = nil,
        xEnd: CGFloat? = nil,
        yStart: PlottableValue<Y>,
        yEnd: PlottableValue<Y>
    ) {
        self.xStart = xStart.map(Double.init)
        self.xEnd = xEnd.map(Double.init)
        self.x = nil
        self.yStart = chartNumericScalar(yStart.value)
        self.yEnd = chartNumericScalar(yEnd.value)
        self.y = self.yEnd
        self.category = nil
        self.series = nil
        self.stacking = .unstacked
        self.width = .automatic
        self.height = .automatic
    }

    public init<X: Plottable & Sendable>(
        xStart: PlottableValue<X>,
        xEnd: PlottableValue<X>,
        yStart: CGFloat? = nil,
        yEnd: CGFloat? = nil
    ) {
        self.xStart = chartNumericScalar(xStart.value)
        self.xEnd = chartNumericScalar(xEnd.value)
        self.x = self.xStart
        self.yStart = yStart.map(Double.init)
        self.yEnd = yEnd.map(Double.init)
        self.y = self.yEnd
        self.category = xStart.value as? String
        self.series = nil
        self.stacking = .unstacked
        self.width = .automatic
        self.height = .automatic
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        xStart: PlottableValue<X>,
        xEnd: PlottableValue<X>,
        y: PlottableValue<Y>,
        height: MarkDimension = .automatic,
        stacking: MarkStackingMethod = .standard
    ) {
        self.xStart = chartNumericScalar(xStart.value)
        self.xEnd = chartNumericScalar(xEnd.value)
        self.x = self.xStart
        self.y = chartNumericScalar(y.value)
        self.yStart = nil
        self.yEnd = self.y
        self.category = xStart.value as? String
        self.series = nil
        self.stacking = stacking
        self.width = .automatic
        self.height = height
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable, S: Plottable & Sendable>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>,
        series: PlottableValue<S>,
        stacking: MarkStackingMethod = .standard
    ) {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.xStart = nil
        self.xEnd = nil
        self.yStart = nil
        self.yEnd = self.y
        self.category = x.value as? String
        if let name = series.value as? String {
            self.series = name
        } else {
            self.series = series.label
        }
        self.stacking = stacking
        self.width = .automatic
        self.height = .automatic
    }

    public init<Y: Plottable & Sendable>(
        xStart: CGFloat? = nil,
        xEnd: CGFloat? = nil,
        y: PlottableValue<Y>,
        height: MarkDimension = .automatic,
        stacking: MarkStackingMethod = .standard
    ) {
        self.xStart = xStart.map(Double.init)
        self.xEnd = xEnd.map(Double.init)
        self.x = nil
        self.y = chartNumericScalar(y.value)
        self.yStart = nil
        self.yEnd = self.y
        self.category = nil
        self.series = nil
        self.stacking = stacking
        self.width = .automatic
        self.height = height
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [
            ChartPlotRecord(
                kind: .bar,
                x: x,
                y: y,
                xStart: xStart,
                xEnd: xEnd,
                yStart: yStart,
                yEnd: yEnd,
                category: category,
                series: series,
                stacking: stacking
            ),
        ]
    }

    public var body: some View { EmptyView() }
}

public struct PointMark: ChartContent {
    public let x: Double?
    public let y: Double?
    public let category: String?

    public init() {
        x = nil
        y = nil
        category = nil
    }

    public init<X: Plottable & Sendable, Y: Plottable & Sendable>(
        x: PlottableValue<X>,
        y: PlottableValue<Y>
    ) {
        self.x = chartNumericScalar(x.value)
        self.y = chartNumericScalar(y.value)
        self.category = x.value as? String
    }

    public init<Y: Plottable & Sendable>(x: CGFloat? = nil, y: PlottableValue<Y>) {
        self.x = x.map(Double.init)
        self.y = chartNumericScalar(y.value)
        self.category = nil
    }

    public init<X: Plottable & Sendable>(x: PlottableValue<X>, y: CGFloat? = nil) {
        self.x = chartNumericScalar(x.value)
        self.y = y.map(Double.init)
        self.category = x.value as? String
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [ChartPlotRecord(kind: .point, x: x, y: y, category: category)]
    }

    public var body: some View { EmptyView() }
}

public struct SectorMark: ChartContent {
    public let angle: Double?
    public let innerRadius: MarkDimension
    public let outerRadius: MarkDimension
    public let angularInset: CGFloat?

    public init() {
        angle = nil
        innerRadius = .automatic
        outerRadius = .automatic
        angularInset = nil
    }

    public init<X: Plottable & Sendable>(angle: PlottableValue<X>) {
        self.angle = chartNumericScalar(angle.value)
        self.innerRadius = .automatic
        self.outerRadius = .automatic
        self.angularInset = nil
    }

    public init(
        angle: PlottableValue<some Plottable>,
        innerRadius: MarkDimension = .automatic,
        outerRadius: MarkDimension = .automatic,
        angularInset: CGFloat? = nil
    ) {
        self.angle = chartNumericScalar(angle.value)
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.angularInset = angularInset
    }

    public var chartPlotRecords: [ChartPlotRecord] {
        [ChartPlotRecord(kind: .sector, angle: angle)]
    }

    public var body: some View { EmptyView() }
}

public struct SurfacePlot: Chart3DContent {
    public init() {}
    public var body: some View { EmptyView() }
}

/// Fail-closed 3D surface mark. Linux has no RealityKit/Chart3D renderer.
public struct SurfaceMark: Chart3DContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Plot<Content: ChartContent>: ChartContent {
    public init(@ChartContentBuilder content: () -> Content) { _ = content }
    public var body: some View { EmptyView() }
}

public struct VectorizedBarPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct VectorizedAreaPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct VectorizedLinePlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct VectorizedRulePlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct VectorizedPointPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct VectorizedSectorPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct VectorizedRectanglePlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct BarPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedBarPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(_ content: Content) { chartPlotRecords = content.chartPlotRecords }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct AreaPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedAreaPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct LinePlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedLinePlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct PointPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedPointPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct RectanglePlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedRectanglePlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct RulePlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedRulePlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct SectorPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedSectorPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
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
        guard let xScale else { return nil }
        if xScale.type == .category, let name = xScale.categoryValue(at: Double(position)) {
            return name as? P
        }
        let scalar = xScale.numericValue(at: Double(position))
        if xScale.type == .date {
            return chartDecode(.date(scalar), as: P.self)
        }
        return chartDecode(.number(scalar), as: P.self)
    }
    func value<P: Plottable>(atY position: CGFloat, as _: P.Type = P.self) -> P? {
        guard let yScale else { return nil }
        let scalar = yScale.numericValue(at: Double(position))
        return chartDecode(.number(scalar), as: P.self)
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
