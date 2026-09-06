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
    public let content: Content
    public init(@Chart3DContentBuilder content: () -> Content) {
        self.content = content()
    }
    public var body: some View { EmptyView() }
}

@resultBuilder
public struct Chart3DContentBuilder {
    public static func buildBlock() -> _EmptyChart3DContent { _EmptyChart3DContent() }
    public static func buildBlock<Content: Chart3DContent>(_ content: Content) -> Content { content }
    public static func buildBlock<each Content: Chart3DContent>(
        _ content: repeat each Content
    ) -> AnyChart3DContent {
        var names: [String] = []
        repeat names.append(String(describing: type(of: each content)))
        return AnyChart3DContent(childCount: names.count, childTypeNames: names)
    }
    public static func buildEither<C1: Chart3DContent, C2: Chart3DContent>(
        first component: C1
    ) -> BuilderConditional<C1, C2> {
        BuilderConditional(storage: .first(component))
    }
    public static func buildEither<C1: Chart3DContent, C2: Chart3DContent>(
        second component: C2
    ) -> BuilderConditional<C1, C2> {
        BuilderConditional(storage: .second(component))
    }
    public static func buildOptional<Content: Chart3DContent>(
        _ component: Content
    ) -> Content {
        component
    }
    public static func buildExpression<Content: Chart3DContent>(
        _ expression: Content
    ) -> Content {
        expression
    }
    public static func buildLimitedAvailability<Content: Chart3DContent>(
        _ components: Content
    ) -> AnyChart3DContent {
        AnyChart3DContent(
            childCount: 1,
            childTypeNames: [String(describing: type(of: components))]
        )
    }
}

public struct _EmptyChart3DContent: Chart3DContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct AnyChart3DContent: Chart3DContent {
    public var childCount: Int
    public var childTypeNames: [String]
    public var metalness: Double?
    public var roughness: Double?
    public var symbolSize: CGFloat?
    public var foregroundStyleName: String?
    public var surfaceStyleName: String?
    public var symbolName: String?
    public init(
        childCount: Int = 0,
        childTypeNames: [String] = [],
        metalness: Double? = nil,
        roughness: Double? = nil,
        symbolSize: CGFloat? = nil,
        foregroundStyleName: String? = nil,
        surfaceStyleName: String? = nil,
        symbolName: String? = nil
    ) {
        self.childCount = childCount
        self.childTypeNames = childTypeNames
        self.metalness = metalness
        self.roughness = roughness
        self.symbolSize = symbolSize
        self.foregroundStyleName = foregroundStyleName
        self.surfaceStyleName = surfaceStyleName
        self.symbolName = symbolName
    }
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
    public static let automatic = Chart3DCameraProjection("automatic")
}

public struct BasicChart3DSymbolShape: Hashable, Sendable, Chart3DSymbolShape {
    private let name: String
    init(_ name: String) { self.name = name }
}

public struct BasicChart3DSurfaceStyle: Hashable, Sendable, Chart3DSurfaceStyle {
    public var kind: String
    public var yRangeMin: CGFloat?
    public var yRangeMax: CGFloat?
    public var gradientName: String?

    public init() {
        kind = "automatic"
        yRangeMin = nil
        yRangeMax = nil
        gradientName = nil
    }

    public init(
        kind: String,
        yRangeMin: CGFloat? = nil,
        yRangeMax: CGFloat? = nil,
        gradientName: String? = nil
    ) {
        self.kind = kind
        self.yRangeMin = yRangeMin
        self.yRangeMax = yRangeMax
        self.gradientName = gradientName
    }
}

public extension Chart3DSurfaceStyle where Self == BasicChart3DSurfaceStyle {
    /// Linux default height domain is `0...1`. Apple's implicit range is unobserved.
    static var heightBased: Self {
        .heightBased(yRange: 0...1)
    }

    static func heightBased(yRange: ClosedRange<CGFloat>) -> Self {
        BasicChart3DSurfaceStyle(
            kind: "heightBased",
            yRangeMin: yRange.lowerBound,
            yRangeMax: yRange.upperBound
        )
    }

    static func heightBased(_ gradient: Gradient, yRange: ClosedRange<CGFloat>? = nil) -> Self {
        BasicChart3DSurfaceStyle(
            kind: "heightBased",
            yRangeMin: yRange?.lowerBound,
            yRangeMax: yRange?.upperBound,
            gradientName: "gradient-\(gradient.colorCount)"
        )
    }

    static var normalBased: Self {
        BasicChart3DSurfaceStyle(kind: "normalBased")
    }
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
    public init<Content: AxisMark>(erasing content: Content) { _ = content }
    public init(_ content: any AxisMark) { _ = content }
    public var body: some View { EmptyView() }
}

public struct AnyAxisContent: View, AxisContent {
    public init<Content: AxisContent>(erasing content: Content) { _ = content }
    public init(_ content: any AxisContent) { _ = content }
    public var body: some View { EmptyView() }
}

public struct BuilderConditional<TrueContent, FalseContent>: View {
    public typealias Body = EmptyView
    public enum Storage {
        case first(TrueContent)
        case second(FalseContent)
    }
    public let storage: Storage?
    public init() { storage = nil }
    public init(storage: Storage) { self.storage = storage }
    public var body: EmptyView { EmptyView() }
}

extension BuilderConditional: ChartContent where TrueContent: ChartContent, FalseContent: ChartContent {
    public var chartPlotRecords: [ChartPlotRecord] {
        switch storage {
        case .first(let content): return content.chartPlotRecords
        case .second(let content): return content.chartPlotRecords
        case nil: return []
        }
    }
}

extension BuilderConditional: AxisMark where TrueContent: AxisMark, FalseContent: AxisMark {}
extension BuilderConditional: AxisContent where TrueContent: AxisContent, FalseContent: AxisContent {}

public struct AutomaticScaleDomain: ScaleDomain, Hashable, Sendable {
    public var includesZero: Bool?
    public var reversed: Bool?
    public var modifiedDomain: [Double]
    public init(
        includesZero: Bool? = nil,
        reversed: Bool? = nil,
        modifiedDomain: [Double] = []
    ) {
        self.includesZero = includesZero
        self.reversed = reversed
        self.modifiedDomain = modifiedDomain
    }
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

public struct MarkDimension: Hashable, Sendable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public typealias FloatLiteralType = Double
    public typealias IntegerLiteralType = Int
    public let kind: String
    public let value: CGFloat?
    public static let automatic = MarkDimension(kind: "automatic", value: nil)
    public static func fixed(_ value: CGFloat) -> MarkDimension {
        MarkDimension(kind: "fixed", value: value)
    }
    public static func ratio(_ value: CGFloat) -> MarkDimension {
        MarkDimension(kind: "ratio", value: value)
    }
    public static func inset(_ value: CGFloat) -> MarkDimension {
        MarkDimension(kind: "inset", value: value)
    }
    public var description: String { kind }
    public init() {
        kind = "automatic"
        value = nil
    }
    init(kind: String, value: CGFloat?) {
        self.kind = kind
        self.value = value
    }
    public init(floatLiteral value: Double) {
        self = .fixed(CGFloat(value))
    }
    public init(integerLiteral value: Int) {
        self = .fixed(CGFloat(value))
    }
}

public struct MarkDimensions<DataElement>: Hashable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public typealias FloatLiteralType = Double
    public typealias IntegerLiteralType = Int
    public let kind: String
    public let value: CGFloat?
    public let keyPath: KeyPath<DataElement, CGFloat>?
    public static var automatic: MarkDimensions<DataElement> {
        MarkDimensions(kind: "automatic", value: nil)
    }
    public static func fixed(_ value: CGFloat) -> MarkDimensions<DataElement> {
        MarkDimensions(kind: "fixed", value: value)
    }
    public static func ratio(_ value: CGFloat) -> MarkDimensions<DataElement> {
        MarkDimensions(kind: "ratio", value: value)
    }
    public static func inset(_ value: CGFloat) -> MarkDimensions<DataElement> {
        MarkDimensions(kind: "inset", value: value)
    }
    public static func inset(_ keyPath: KeyPath<DataElement, CGFloat>) -> MarkDimensions<DataElement> {
        MarkDimensions(kind: "inset", value: nil, keyPath: keyPath)
    }
    public init() {
        kind = "automatic"
        value = nil
        keyPath = nil
    }
    init(kind: String, value: CGFloat?, keyPath: KeyPath<DataElement, CGFloat>? = nil) {
        self.kind = kind
        self.value = value
        self.keyPath = keyPath
    }
    public init(floatLiteral value: Double) {
        self = .fixed(CGFloat(value))
    }
    public init(integerLiteral value: Int) {
        self = .fixed(CGFloat(value))
    }

    public func resolved(for element: DataElement) -> MarkDimension {
        if kind == "inset", let keyPath {
            return .inset(element[keyPath: keyPath])
        }
        return MarkDimension(kind: kind, value: value)
    }
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
    public static let topLeading = AnnotationPosition("topLeading")
    public static let topTrailing = AnnotationPosition("topTrailing")
    public static let bottomLeading = AnnotationPosition("bottomLeading")
    public static let bottomTrailing = AnnotationPosition("bottomTrailing")
    public init() { self = .automatic }
    public var description: String { name }
}

public struct AnnotationOverflowResolution: Hashable, Sendable {
    public struct Boundary: Hashable, Sendable {
        public let name: String
        private init(_ name: String) { self.name = name }
        public static let automatic = Boundary("automatic")
        public static let plot = Boundary("plot")
        public static let chart = Boundary("chart")
        public init() { self = .automatic }
    }
    public struct Strategy: Hashable, Sendable {
        public let name: String
        public let boundary: Boundary?
        private init(name: String, boundary: Boundary? = nil) {
            self.name = name
            self.boundary = boundary
        }
        public static let automatic = Strategy(name: "automatic")
        public static let fit = Strategy(name: "fit", boundary: .automatic)
        public static let padScale = Strategy(name: "padScale")
        public static let disabled = Strategy(name: "disabled")
        public static func fit(to boundary: Boundary) -> Strategy {
            Strategy(name: "fit", boundary: boundary)
        }
        public init() { self = .automatic }
    }
    public var x: Strategy
    public var y: Strategy
    public init(x: Strategy = .automatic, y: Strategy = .automatic) {
        self.x = x
        self.y = y
    }
    public static let automatic = AnnotationOverflowResolution()
}

public struct ChartBinRange<Bound: Comparable & Hashable>: Hashable, RangeExpression {
    public let lowerBound: Bound
    public let upperBound: Bound
    public init(uncheckedBounds: (lower: Bound, upper: Bound)) {
        lowerBound = uncheckedBounds.lower
        upperBound = uncheckedBounds.upper
    }

    /// Half-open `[lowerBound, upperBound)`. The last histogram bin still
    /// receives the final threshold through `NumberBins.index(for:)` /
    /// `DateBins.index(for:)`, which clamp onto the last index.
    public func contains(_ element: Bound) -> Bool {
        element >= lowerBound && element < upperBound
    }

    public func relative<C: Collection>(to collection: C) -> Range<Bound>
        where Bound == C.Index
    {
        let start: Bound
        if lowerBound < collection.startIndex {
            start = collection.startIndex
        } else if lowerBound > collection.endIndex {
            start = collection.endIndex
        } else {
            start = lowerBound
        }
        let end: Bound
        if upperBound < collection.startIndex {
            end = collection.startIndex
        } else if upperBound > collection.endIndex {
            end = collection.endIndex
        } else {
            end = upperBound
        }
        return start < end ? start..<end : end..<end
    }

    public static func ~= (pattern: ChartBinRange<Bound>, value: Bound) -> Bool {
        pattern.contains(value)
    }
}

/// Sequential numeric bins. Thresholds are the inclusive-left edges; `count`
/// bins from `n` thresholds (`n >= 2`) yield `endIndex == n - 1`.
///
/// Equal-width `init(range:count:)` splits the closed range into `count`
/// bins, snapping the last threshold onto `range.upperBound`.
/// `init(size:range:)` walks `size` from `lowerBound` until the last edge
/// is at or past `upperBound`.
/// `init(range:desiredCount:minimumStride:)` and the data-inference init
/// use the same 1-2-5×10^n nice ticks as `ChartNiceNumbers` (`0.2...9.7`,
/// desired 5 → thresholds `0, 2, 4, 6, 8, 10`).
public struct NumberBins<Value: Comparable & Numeric & Hashable>: Hashable, RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ChartBinRange<Value>
    public typealias SubSequence = Slice<NumberBins<Value>>
    public typealias Indices = DefaultIndices<NumberBins<Value>>
    public typealias Iterator = IndexingIterator<NumberBins<Value>>

    public let thresholds: [Value]

    public init(thresholds: [Value] = []) {
        self.thresholds = thresholds
    }

    public init(range: ClosedRange<Value>, count: Int) where Value: BinaryFloatingPoint {
        self.thresholds = ChartBinning.equalWidth(range: range, count: count)
    }

    public init(range: ClosedRange<Value>, count: Int) where Value: BinaryInteger {
        self.thresholds = ChartBinning.equalWidth(range: range, count: count)
    }

    public init(size: Value, range: ClosedRange<Value>) where Value: BinaryFloatingPoint {
        self.thresholds = ChartBinning.strideSize(size: size, range: range)
    }

    public init(size: Value, range: ClosedRange<Value>) where Value: BinaryInteger {
        self.thresholds = ChartBinning.strideSize(size: size, range: range)
    }

    public init(
        range: ClosedRange<Value>,
        desiredCount: Int = 10,
        minimumStride: Value = 0
    ) where Value: BinaryFloatingPoint {
        self.thresholds = ChartBinning.nice(
            range: range,
            desiredCount: desiredCount,
            minimumStride: minimumStride
        )
    }

    public init(
        range: ClosedRange<Value>,
        desiredCount: Int = 10,
        minimumStride: Value = 0
    ) where Value: BinaryInteger {
        self.thresholds = ChartBinning.nice(
            range: range,
            desiredCount: desiredCount,
            minimumStride: minimumStride
        )
    }

    public init(
        data: [Value],
        desiredCount: Int? = nil,
        minimumStride: Value = 0
    ) where Value: BinaryFloatingPoint {
        guard let lo = data.min(), let hi = data.max() else {
            self.thresholds = []
            return
        }
        self.thresholds = ChartBinning.nice(
            range: lo...Swift.max(hi, lo),
            desiredCount: desiredCount ?? 10,
            minimumStride: minimumStride
        )
    }

    public init(
        data: [Value],
        desiredCount: Int? = nil,
        minimumStride: Value = 0
    ) where Value: BinaryInteger {
        guard let lo = data.min(), let hi = data.max() else {
            self.thresholds = []
            return
        }
        self.thresholds = ChartBinning.nice(
            range: lo...Swift.max(hi, lo),
            desiredCount: desiredCount ?? 10,
            minimumStride: minimumStride
        )
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { Swift.max(thresholds.count - 1, 0) }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }

    public subscript(position: Int) -> ChartBinRange<Value> {
        ChartBinRange(uncheckedBounds: (lower: thresholds[position], upper: thresholds[position + 1]))
    }

    /// Returns the bin index containing `value`. Values below the first
    /// threshold clamp to `0`; values at or above the last threshold clamp
    /// to `endIndex - 1`.
    public func index(for value: Value) -> Int {
        ChartBinning.index(for: value, thresholds: thresholds)
    }
}

/// Sequential date bins. Extra `unit` / `range` fields are portable metadata
/// for the existing `init(unit:range:)` convenience used by first-pass tests;
/// they are not Apple TBD exports.
public struct DateBins: Hashable, Sendable, RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ChartBinRange<Date>
    public typealias SubSequence = Slice<DateBins>
    public typealias Indices = DefaultIndices<DateBins>
    public typealias Iterator = IndexingIterator<DateBins>

    public let thresholds: [Date]
    public let unit: Calendar.Component
    public let range: ClosedRange<Date>?

    public init(thresholds: [Date]) {
        self.thresholds = thresholds
        self.unit = .second
        self.range = nil
    }

    public init(unit: Calendar.Component, range: ClosedRange<Date>? = nil) {
        self.unit = unit
        self.range = range
        if let range {
            self.thresholds = ChartBinning.calendarStride(
                unit: unit,
                by: 1,
                range: range,
                calendar: .autoupdatingCurrent
            )
        } else {
            self.thresholds = []
        }
    }

    public init(timeInterval: TimeInterval, range: ClosedRange<Date>) {
        self.unit = .second
        self.range = range
        self.thresholds = ChartBinning.timeIntervalStride(timeInterval, range: range)
    }

    public init(
        data: [Date],
        desiredCount: Int? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        _ = calendar
        self.unit = .second
        guard let lo = data.min(), let hi = data.max() else {
            self.range = nil
            self.thresholds = []
            return
        }
        let span = lo...hi
        self.range = span
        self.thresholds = ChartBinning.equalTime(range: span, count: Swift.max(desiredCount ?? 10, 1))
    }

    public init(
        unit: Calendar.Component,
        by stride: Int = 1,
        range: ClosedRange<Date>,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.unit = unit
        self.range = range
        self.thresholds = ChartBinning.calendarStride(
            unit: unit,
            by: stride,
            range: range,
            calendar: calendar
        )
    }

    public init(
        range: ClosedRange<Date>,
        desiredCount: Int = 10,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        _ = calendar
        self.unit = .second
        self.range = range
        self.thresholds = ChartBinning.equalTime(range: range, count: Swift.max(desiredCount, 1))
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { Swift.max(thresholds.count - 1, 0) }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }

    public subscript(position: Int) -> ChartBinRange<Date> {
        ChartBinRange(uncheckedBounds: (lower: thresholds[position], upper: thresholds[position + 1]))
    }

    public func index(for value: Date) -> Int {
        ChartBinning.index(for: value, thresholds: thresholds)
    }
}

enum ChartBinning {
    static func equalWidth<Value: BinaryFloatingPoint>(
        range: ClosedRange<Value>,
        count: Int
    ) -> [Value] {
        let n = max(count, 1)
        let lower = range.lowerBound
        let upper = range.upperBound
        let width = (upper - lower) / Value(n)
        var result: [Value] = []
        result.reserveCapacity(n + 1)
        for i in 0...n {
            result.append(lower + width * Value(i))
        }
        if !result.isEmpty {
            result[result.count - 1] = upper
        }
        return result
    }

    static func equalWidth<Value: BinaryInteger>(
        range: ClosedRange<Value>,
        count: Int
    ) -> [Value] {
        let n = Value(max(count, 1))
        let lower = range.lowerBound
        let upper = range.upperBound
        let span = upper - lower
        var result: [Value] = []
        result.reserveCapacity(Int(n) + 1)
        for i in 0...Int(n) {
            result.append(lower + span * Value(i) / n)
        }
        return result
    }

    static func strideSize<Value: Numeric & Comparable>(
        size: Value,
        range: ClosedRange<Value>
    ) -> [Value] {
        if size <= .zero {
            return [range.lowerBound, range.upperBound]
        }
        var values: [Value] = [range.lowerBound]
        var current = range.lowerBound
        var guardCount = 0
        while current < range.upperBound && guardCount < 10_000 {
            current = current + size
            values.append(current)
            guardCount += 1
        }
        return values
    }

    static func nice<Value: BinaryFloatingPoint>(
        range: ClosedRange<Value>,
        desiredCount: Int,
        minimumStride: Value
    ) -> [Value] {
        var ticks = ChartNiceNumbers.ticks(
            min: Double(range.lowerBound),
            max: Double(range.upperBound),
            desired: max(desiredCount, 1)
        )
        if ticks.count < 2 {
            ticks = [Double(range.lowerBound), Double(range.upperBound)]
        }
        if minimumStride > 0, ticks.count >= 2 {
            let step = ticks[1] - ticks[0]
            if step + 1e-12 < Double(minimumStride) {
                return strideSize(size: minimumStride, range: range)
            }
        }
        return ticks.map { Value($0) }
    }

    static func nice<Value: BinaryInteger>(
        range: ClosedRange<Value>,
        desiredCount: Int,
        minimumStride: Value
    ) -> [Value] {
        let ticks = nice(
            range: Double(range.lowerBound)...Double(range.upperBound),
            desiredCount: desiredCount,
            minimumStride: Double(minimumStride)
        )
        return ticks.map { Value($0.rounded()) }
    }

    static func equalTime(range: ClosedRange<Date>, count: Int) -> [Date] {
        let n = max(count, 1)
        let lower = range.lowerBound.timeIntervalSinceReferenceDate
        let upper = range.upperBound.timeIntervalSinceReferenceDate
        let width = (upper - lower) / Double(n)
        var result: [Date] = []
        result.reserveCapacity(n + 1)
        for i in 0...n {
            result.append(Date(timeIntervalSinceReferenceDate: lower + width * Double(i)))
        }
        result[n] = range.upperBound
        return result
    }

    static func timeIntervalStride(_ interval: TimeInterval, range: ClosedRange<Date>) -> [Date] {
        let step = interval > 0 ? interval : 1
        var values: [Date] = [range.lowerBound]
        var current = range.lowerBound
        var guardCount = 0
        while current < range.upperBound && guardCount < 10_000 {
            current = current.addingTimeInterval(step)
            values.append(current)
            guardCount += 1
        }
        return values
    }

    static func calendarStride(
        unit: Calendar.Component,
        by stride: Int,
        range: ClosedRange<Date>,
        calendar: Calendar
    ) -> [Date] {
        let step = stride == 0 ? 1 : stride
        var values: [Date] = [range.lowerBound]
        var current = range.lowerBound
        var guardCount = 0
        while current < range.upperBound && guardCount < 10_000 {
            guard let next = calendar.date(byAdding: unit, value: step, to: current) else {
                break
            }
            values.append(next)
            current = next
            guardCount += 1
        }
        return values
    }

    static func index<Value: Comparable>(for value: Value, thresholds: [Value]) -> Int {
        let binCount = max(thresholds.count - 1, 0)
        guard binCount > 0 else { return 0 }
        if value < thresholds[0] { return 0 }
        if value >= thresholds[binCount] { return binCount - 1 }
        var lo = 0
        var hi = binCount - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if thresholds[mid] <= value {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
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
    public var kind: String
    public var unitValue: Double?
    public var matching: DateComponents?

    public init() {
        kind = "automatic"
        unitValue = nil
        matching = nil
    }

    init(kind: String, unitValue: Double? = nil, matching: DateComponents? = nil) {
        self.kind = kind
        self.unitValue = unitValue
        self.matching = matching
    }

    public static var page: MajorValueAlignment<Value> {
        MajorValueAlignment(kind: "page")
    }

    public static func unit(_ unit: Value) -> MajorValueAlignment<Value> where Value: Numeric {
        MajorValueAlignment(kind: "unit", unitValue: chartNumericScalar(unit))
    }

    public static func matching(_ components: DateComponents) -> MajorValueAlignment<Value> where Value == Date {
        MajorValueAlignment(kind: "matching", matching: components)
    }
}

public struct ValueAlignedLimitBehavior: Hashable, Sendable {
    public let name: String
    private init(_ name: String) { self.name = name }
    public static let automatic = ValueAlignedLimitBehavior("automatic")
    public static let never = ValueAlignedLimitBehavior("never")
    public static let always = ValueAlignedLimitBehavior("always")
    public init() { self = .automatic }
}

public struct ValueAlignedChartScrollTargetBehavior: ChartScrollTargetBehavior {
    public var unitValue: Double?
    public var yUnitValue: Double?
    public var matching: DateComponents?
    public var yMatching: DateComponents?
    public var limitBehavior: ValueAlignedLimitBehavior
    public init() {
        unitValue = nil
        yUnitValue = nil
        matching = nil
        yMatching = nil
        limitBehavior = .automatic
    }
    public init<T: Plottable & Numeric>(
        unit: T,
        majorAlignment: MajorValueAlignment<T>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) {
        _ = majorAlignment
        unitValue = chartNumericScalar(unit)
        yUnitValue = nil
        matching = nil
        yMatching = nil
        self.limitBehavior = limitBehavior
    }
    public init<X: Plottable & Numeric, Y: Plottable & Numeric>(
        xUnit: X,
        yUnit: Y,
        xMajorAlignment: MajorValueAlignment<X>? = nil,
        yMajorAlignment: MajorValueAlignment<Y>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) {
        _ = xMajorAlignment
        _ = yMajorAlignment
        unitValue = chartNumericScalar(xUnit)
        yUnitValue = chartNumericScalar(yUnit)
        matching = nil
        yMatching = nil
        self.limitBehavior = limitBehavior
    }
    public init<X: Plottable & Numeric>(
        xUnit: X,
        yMatching yComponents: DateComponents,
        xMajorAlignment: MajorValueAlignment<X>? = nil,
        yMajorAlignment: MajorValueAlignment<Date>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) {
        _ = xMajorAlignment
        _ = yMajorAlignment
        unitValue = chartNumericScalar(xUnit)
        yUnitValue = nil
        matching = nil
        yMatching = yComponents
        self.limitBehavior = limitBehavior
    }
    public init(
        matching components: DateComponents,
        majorAlignment: MajorValueAlignment<Date>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) {
        _ = majorAlignment
        unitValue = nil
        yUnitValue = nil
        matching = components
        yMatching = nil
        self.limitBehavior = limitBehavior
    }
    public init(
        xMatching xComponents: DateComponents,
        yMatching yComponents: DateComponents,
        xMajorAlignment: MajorValueAlignment<Date>? = nil,
        yMajorAlignment: MajorValueAlignment<Date>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) {
        _ = xMajorAlignment
        _ = yMajorAlignment
        unitValue = nil
        yUnitValue = nil
        matching = xComponents
        yMatching = yComponents
        self.limitBehavior = limitBehavior
    }
    public init<Y: Plottable & Numeric>(
        xMatching xComponents: DateComponents,
        yUnit: Y,
        xMajorAlignment: MajorValueAlignment<Date>? = nil,
        yMajorAlignment: MajorValueAlignment<Y>? = nil,
        limitBehavior: ValueAlignedLimitBehavior = .automatic
    ) {
        _ = xMajorAlignment
        _ = yMajorAlignment
        unitValue = nil
        yUnitValue = chartNumericScalar(yUnit)
        matching = xComponents
        yMatching = nil
        self.limitBehavior = limitBehavior
    }
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
                stacking: stacking,
                markWidth: width,
                markHeight: height
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
        [
            ChartPlotRecord(
                kind: .sector,
                angle: angle,
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                angularInset: angularInset
            ),
        ]
    }

    public var body: some View { EmptyView() }
}

public struct SurfacePlot: Chart3DContent {
    public var xLabel: String
    public var yLabel: String
    public var zLabel: String
    public var samples: [(x: Double, y: Double, z: Double)]
    public init() {
        xLabel = ""
        yLabel = ""
        zLabel = ""
        samples = []
    }
    public init(
        x: LocalizedStringResource,
        y: LocalizedStringResource,
        z: LocalizedStringResource,
        function: @escaping (Double, Double) -> Double
    ) {
        self.init(x: x.key, y: y.key, z: z.key, function: function)
    }
    public init(
        x: LocalizedStringKey,
        y: LocalizedStringKey,
        z: LocalizedStringKey,
        function: @escaping (Double, Double) -> Double
    ) {
        self.init(x: x.key, y: y.key, z: z.key, function: function)
    }
    public init(
        x: Text,
        y: Text,
        z: Text,
        function: @escaping (Double, Double) -> Double
    ) {
        self.init(x: x.content, y: y.content, z: z.content, function: function)
    }
    public init(
        x: some StringProtocol,
        y: some StringProtocol,
        z: some StringProtocol,
        function: @escaping (Double, Double) -> Double
    ) {
        xLabel = String(x)
        yLabel = String(y)
        zLabel = String(z)
        samples = chartSampleSurfaceFunction(function)
    }
    public var body: some View { EmptyView() }
}

/// Fail-closed 3D surface mark. Linux has no RealityKit/Chart3D renderer.
public struct SurfaceMark: Chart3DContent {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Plot<Content: ChartContent>: ChartContent {
    let content: Content
    public init(@ChartContentBuilder content: () -> Content) {
        self.content = content()
    }
    public var chartPlotRecords: [ChartPlotRecord] { content.chartPlotRecords }
    public var body: some View { content }
}

public struct VectorizedBarPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct VectorizedAreaPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct VectorizedLinePlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct VectorizedRulePlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct VectorizedPointPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct VectorizedSectorPlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct VectorizedRectanglePlotContent<Data: RandomAccessCollection>: VectorizedChartContent {
    public typealias DataElement = Data.Element
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct BarPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedBarPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(_ content: Content) { chartPlotRecords = content.chartPlotRecords }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct AreaPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedAreaPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct LinePlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedLinePlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct PointPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedPointPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct RectanglePlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedRectanglePlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct RulePlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedRulePlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct SectorPlot<Content: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Content.DataElement
    public typealias Body = EmptyView
    public var chartPlotRecords: [ChartPlotRecord]
    public init() where Content == VectorizedSectorPlotContent<[Int]> {
        chartPlotRecords = []
    }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: EmptyView { EmptyView() }
}

public struct FunctionAreaPlotContent: VectorizedChartContent {
    public typealias DataElement = Double
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public struct FunctionLinePlotContent: VectorizedChartContent {
    public typealias DataElement = Double
    public var chartPlotRecords: [ChartPlotRecord]
    public init() { chartPlotRecords = [] }
    public init(records: [ChartPlotRecord]) { chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

public extension ChartProxy {
    func symbolSize<P: Plottable>(for value: P) -> CGFloat? { _ = value; return nil }
    func symbolDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    var plotAreaFrame: Anchor<CGRect> { Anchor<CGRect>() }
    func positionRange<X: Plottable, Y: Plottable>(for point: (x: X, y: Y)) -> CGRect? {
        guard let xs = positionRange(forX: point.x), let ys = positionRange(forY: point.y) else {
            return nil
        }
        let minX = min(xs.lowerBound, xs.upperBound)
        let maxX = max(xs.lowerBound, xs.upperBound)
        let minY = min(ys.lowerBound, ys.upperBound)
        let maxY = max(ys.lowerBound, ys.upperBound)
        return CGRect(
            x: minX,
            y: minY,
            width: max(0, maxX - minX),
            height: max(0, maxY - minY)
        )
    }
    func positionRange<P: Plottable>(forX value: P) -> ClosedRange<CGFloat>? {
        guard let encoded = chartEncode(value), let xScale, let range = xScale.pixelRange(for: encoded) else {
            return nil
        }
        return CGFloat(range.lowerBound)...CGFloat(range.upperBound)
    }
    func positionRange<P: Plottable>(forY value: P) -> ClosedRange<CGFloat>? {
        guard let encoded = chartEncode(value), let yScale, let range = yScale.pixelRange(for: encoded) else {
            return nil
        }
        return CGFloat(range.lowerBound)...CGFloat(range.upperBound)
    }
    func foregroundStyle<P: Plottable>(for value: P) -> AnyShapeStyle? { _ = value; return nil }
    func lineStyleDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    func selectAngleValue(at angle: Angle) { _ = angle }
    func symbolSizeDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    var plotContainerFrame: Anchor<CGRect>? { nil }
    func foregroundStyleDomain<P: Plottable>(dataType: P.Type) -> [P] { _ = dataType; return [] }
    func angle(at position: CGPoint) -> Angle {
        guard let xScale, let yScale else { return Angle() }
        let centerX = (xScale.rangeStart + xScale.rangeEnd) / 2
        let centerY = (yScale.rangeStart + yScale.rangeEnd) / 2
        return Angle(radians: atan2(Double(position.y) - centerY, Double(position.x) - centerX))
    }
    func value<X: Plottable, Y: Plottable>(at position: CGPoint, as _: (X, Y).Type = (X, Y).self) -> (X, Y)? {
        guard let x: X = value(atX: position.x, as: X.self),
              let y: Y = value(atY: position.y, as: Y.self)
        else {
            return nil
        }
        return (x, y)
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
