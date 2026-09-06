#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Stored scroll-axis model. Linux has no UIScrollView; the modifier
/// retains the requested axes and does not pan a plot.
public struct ChartScrollableAxes: Equatable, Sendable {
    public var axes: Axis.Set
    public init(_ axes: Axis.Set) { self.axes = axes }
    public static let horizontal = ChartScrollableAxes(.horizontal)
    public static let vertical = ChartScrollableAxes(.vertical)
}

/// Host-retained scroll position. Gesture delivery stays fail-closed.
public struct ChartScrollPositionModel: Equatable, Sendable {
    public var xEncoded: ChartEncodedValue?
    public var yEncoded: ChartEncodedValue?
    public init(xEncoded: ChartEncodedValue? = nil, yEncoded: ChartEncodedValue? = nil) {
        self.xEncoded = xEncoded
        self.yEncoded = yEncoded
    }
}

/// Host-retained X selection. Binding writes are stored; hit-testing is not.
public struct ChartXSelectionModel: Equatable, Sendable {
    public var value: ChartEncodedValue?
    public var range: ClosedRange<Double>?
    public init(value: ChartEncodedValue? = nil, range: ClosedRange<Double>? = nil) {
        self.value = value
        self.range = range
    }
}

public struct ChartMarkAttributes: Equatable, Sendable {
    public var interpolation: InterpolationMethod?
    public var lineStyle: StrokeStyle?
    public var symbol: BasicChartSymbolShape?
    public var foregroundStyleName: String?
    public var opacity: Double?
    public var accessibilityLabel: String?
    public var accessibilityValue: String?
    public var accessibilityHidden: Bool?
    public var accessibilityIdentifier: String?
    public var symbolSize: CGFloat?
    public var symbolSizeBy: String?
    public var lineStyleBy: String?
    public var foregroundStyleBy: String?
    public var positionAxis: String?

    public init(
        interpolation: InterpolationMethod? = nil,
        lineStyle: StrokeStyle? = nil,
        symbol: BasicChartSymbolShape? = nil,
        foregroundStyleName: String? = nil,
        opacity: Double? = nil,
        accessibilityLabel: String? = nil,
        accessibilityValue: String? = nil,
        accessibilityHidden: Bool? = nil,
        accessibilityIdentifier: String? = nil,
        symbolSize: CGFloat? = nil,
        symbolSizeBy: String? = nil,
        lineStyleBy: String? = nil,
        foregroundStyleBy: String? = nil,
        positionAxis: String? = nil
    ) {
        self.interpolation = interpolation
        self.lineStyle = lineStyle
        self.symbol = symbol
        self.foregroundStyleName = foregroundStyleName
        self.opacity = opacity
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.accessibilityHidden = accessibilityHidden
        self.accessibilityIdentifier = accessibilityIdentifier
        self.symbolSize = symbolSize
        self.symbolSizeBy = symbolSizeBy
        self.lineStyleBy = lineStyleBy
        self.foregroundStyleBy = foregroundStyleBy
        self.positionAxis = positionAxis
    }
}

public func chartApplyMarkAttributes(
    _ attributes: ChartMarkAttributes,
    to records: [ChartPlotRecord]
) -> [ChartPlotRecord] {
    records.map { record in
        var copy = record
        if let interpolation = attributes.interpolation {
            copy.interpolation = interpolation
        }
        if let style = attributes.lineStyle {
            copy.lineWidth = style.lineWidth
            copy.lineDash = style.dash
        }
        if let symbol = attributes.symbol {
            copy.symbolName = symbol.description
        }
        if let name = attributes.foregroundStyleName {
            copy.foregroundStyleName = name
        }
        if let opacity = attributes.opacity {
            copy.opacity = opacity
        }
        return copy
    }
}

public struct VectorizedAttributedContent<Base: VectorizedChartContent>: VectorizedChartContent {
    public typealias DataElement = Base.DataElement
    public var chartPlotRecords: [ChartPlotRecord]
    public init(base: Base, attributes: ChartMarkAttributes) {
        chartPlotRecords = chartApplyMarkAttributes(attributes, to: base.chartPlotRecords)
    }
    public init(records: [ChartPlotRecord]) {
        chartPlotRecords = records
    }
    public var body: some View { EmptyView() }
}

public extension VectorizedChartContent {
    func symbolSize(by value: PlottableProjection<DataElement, some Plottable>) -> VectorizedAttributedContent<Self> {
        VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(symbolSizeBy: value.label)
        )
    }

    func symbolSize(_ area: KeyPath<DataElement, CGFloat>) -> VectorizedAttributedContent<Self> {
        _ = area
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(symbolSize: 1)
        )
    }

    func symbolSize(_ size: KeyPath<DataElement, CGSize>) -> VectorizedAttributedContent<Self> {
        _ = size
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(symbolSize: 1)
        )
    }

    func foregroundStyle(by value: PlottableProjection<DataElement, some Plottable>) -> VectorizedAttributedContent<Self> {
        VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(foregroundStyleBy: value.label)
        )
    }

    func foregroundStyle<S: ShapeStyle>(_ keyPath: KeyPath<DataElement, S>) -> VectorizedAttributedContent<Self> {
        _ = keyPath
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(foregroundStyleName: "keyPath")
        )
    }

    func accessibilityLabel(_ labelKey: KeyPath<DataElement, LocalizedStringKey>) -> VectorizedAttributedContent<Self> {
        _ = labelKey
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityLabel: "key")
        )
    }

    func accessibilityLabel(_ label: KeyPath<DataElement, Text>) -> VectorizedAttributedContent<Self> {
        _ = label
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityLabel: "text")
        )
    }

    func accessibilityLabel<S: StringProtocol>(_ label: KeyPath<DataElement, S>) -> VectorizedAttributedContent<Self> {
        _ = label
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityLabel: "string")
        )
    }

    func accessibilityValue(_ valueKey: KeyPath<DataElement, LocalizedStringKey>) -> VectorizedAttributedContent<Self> {
        _ = valueKey
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityValue: "key")
        )
    }

    func accessibilityValue(_ valueDescription: KeyPath<DataElement, Text>) -> VectorizedAttributedContent<Self> {
        _ = valueDescription
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityValue: "text")
        )
    }

    func accessibilityValue<S: StringProtocol>(_ value: KeyPath<DataElement, S>) -> VectorizedAttributedContent<Self> {
        _ = value
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityValue: "string")
        )
    }

    func accessibilityHidden(_ hidden: KeyPath<DataElement, Bool>) -> VectorizedAttributedContent<Self> {
        _ = hidden
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityHidden: true)
        )
    }

    func accessibilityIdentifier(_ identifier: KeyPath<DataElement, String>) -> VectorizedAttributedContent<Self> {
        _ = identifier
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(accessibilityIdentifier: "id")
        )
    }

    func symbol(by value: PlottableProjection<DataElement, some Plottable>) -> VectorizedAttributedContent<Self> {
        VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(symbolSizeBy: value.label)
        )
    }

    func opacity(_ keyPath: KeyPath<DataElement, CGFloat>) -> VectorizedAttributedContent<Self> {
        _ = keyPath
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(opacity: 1)
        )
    }

    func position(
        by value: PlottableProjection<DataElement, some Plottable>,
        axis: Axis? = nil,
        span: MarkDimension = .automatic
    ) -> VectorizedAttributedContent<Self> {
        _ = span
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(positionAxis: axis.map { "\($0)" } ?? value.label)
        )
    }

    func lineStyle(by value: PlottableProjection<DataElement, some Plottable>) -> VectorizedAttributedContent<Self> {
        VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(lineStyleBy: value.label)
        )
    }

    func lineStyle(_ style: KeyPath<DataElement, StrokeStyle>) -> VectorizedAttributedContent<Self> {
        _ = style
        return VectorizedAttributedContent(
            base: self,
            attributes: ChartMarkAttributes(lineStyle: StrokeStyle(lineWidth: 1))
        )
    }
}

public enum ChartVectorizedRecords {
    public static func bars<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        stacking: MarkStackingMethod = .standard
    ) -> [ChartPlotRecord] {
        data.map { element in
            let xValue = x.value(from: element)
            let yValue = y.value(from: element)
            return ChartPlotRecord(
                kind: .bar,
                x: xValue.flatMap(chartNumericScalar),
                y: yValue.flatMap(chartNumericScalar),
                category: xValue as? String,
                stacking: stacking
            )
        }
    }

    public static func lines<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>
    ) -> [ChartPlotRecord] {
        data.map { element in
            let xValue = x.value(from: element)
            let yValue = y.value(from: element)
            return ChartPlotRecord(
                kind: .line,
                x: xValue.flatMap(chartNumericScalar),
                y: yValue.flatMap(chartNumericScalar),
                category: xValue as? String
            )
        }
    }

    public static func points<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>
    ) -> [ChartPlotRecord] {
        data.map { element in
            let xValue = x.value(from: element)
            let yValue = y.value(from: element)
            return ChartPlotRecord(
                kind: .point,
                x: xValue.flatMap(chartNumericScalar),
                y: yValue.flatMap(chartNumericScalar),
                category: xValue as? String
            )
        }
    }

    public static func areas<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        stacking: MarkStackingMethod = .standard
    ) -> [ChartPlotRecord] {
        data.map { element in
            let xValue = x.value(from: element)
            let yValue = y.value(from: element)
            return ChartPlotRecord(
                kind: .area,
                x: xValue.flatMap(chartNumericScalar),
                y: yValue.flatMap(chartNumericScalar),
                category: xValue as? String,
                stacking: stacking
            )
        }
    }

    public static func rules<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>
    ) -> [ChartPlotRecord] {
        data.map { element in
            let xValue = x.value(from: element)
            return ChartPlotRecord(
                kind: .rule,
                x: xValue.flatMap(chartNumericScalar),
                category: xValue as? String
            )
        }
    }

    public static func rectangles<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>
    ) -> [ChartPlotRecord] {
        data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    public static func sectors<Data: RandomAccessCollection, A: Plottable>(
        _ data: Data,
        angle: PlottableProjection<Data.Element, A>
    ) -> [ChartPlotRecord] {
        data.map { element in
            ChartPlotRecord(
                kind: .sector,
                angle: angle.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }
}

public extension BarPlot {
    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = ChartVectorizedRecords.bars(data, x: x, y: y, stacking: stacking)
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar),
                category: x.value(from: element) as? String,
                stacking: .unstacked
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        yStart: CGFloat? = nil,
        yEnd: CGFloat? = nil,
        width: MarkDimension = .automatic,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedBarPlotContent<Data> {
        _ = width
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.map(Double.init),
                yEnd: yEnd.map(Double.init),
                category: x.value(from: element) as? String,
                stacking: stacking
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        xStart: CGFloat? = nil,
        xEnd: CGFloat? = nil,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                xStart: xStart.map(Double.init),
                xEnd: xEnd.map(Double.init),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar),
                stacking: .unstacked
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        yStart: CGFloat? = nil,
        yEnd: CGFloat? = nil
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.map(Double.init),
                yEnd: yEnd.map(Double.init),
                stacking: .unstacked
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        xStart: CGFloat? = nil,
        xEnd: CGFloat? = nil,
        y: PlottableProjection<Data.Element, Y>,
        height: MarkDimension = .automatic,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedBarPlotContent<Data> {
        _ = height
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: xStart.map(Double.init),
                xEnd: xEnd.map(Double.init),
                stacking: stacking
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        height: MarkDimension = .automatic
    ) where Content == VectorizedBarPlotContent<Data> {
        _ = height
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
                stacking: .standard
            )
        }
    }
}

public extension LinePlot {
    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedLinePlotContent<Data> {
        chartPlotRecords = ChartVectorizedRecords.lines(data, x: x, y: y)
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable, S: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        series: PlottableProjection<Data.Element, S>
    ) where Content == VectorizedLinePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .line,
                x: x.value(from: element).flatMap(chartNumericScalar),
                y: y.value(from: element).flatMap(chartNumericScalar),
                category: x.value(from: element) as? String,
                series: series.value(from: element) as? String
            )
        }
    }
}

public extension PointPlot {
    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedPointPlotContent<Data> {
        chartPlotRecords = ChartVectorizedRecords.points(data, x: x, y: y)
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        x: CGFloat? = nil,
        y: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedPointPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .point,
                x: x.map(Double.init),
                y: y.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: CGFloat? = nil
    ) where Content == VectorizedPointPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .point,
                x: x.value(from: element).flatMap(chartNumericScalar),
                y: y.map(Double.init),
                category: x.value(from: element) as? String
            )
        }
    }
}

public extension AreaPlot {
    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedAreaPlotContent<Data> {
        chartPlotRecords = ChartVectorizedRecords.areas(data, x: x, y: y, stacking: stacking)
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable, S: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        series: PlottableProjection<Data.Element, S>,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedAreaPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .area,
                x: x.value(from: element).flatMap(chartNumericScalar),
                y: y.value(from: element).flatMap(chartNumericScalar),
                category: x.value(from: element) as? String,
                series: series.value(from: element) as? String,
                stacking: stacking
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedAreaPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .area,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar),
                stacking: .unstacked
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedAreaPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .area,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
            )
        }
    }
}

public extension RulePlot {
    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = ChartVectorizedRecords.rules(data, x: x)
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        yStart: CGFloat? = nil,
        yEnd: CGFloat? = nil
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.map(Double.init),
                yEnd: yEnd.map(Double.init)
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        x: CGFloat? = nil,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                x: x.map(Double.init),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        y: CGFloat? = nil
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                y: y.map(Double.init),
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        xStart: CGFloat? = nil,
        xEnd: CGFloat? = nil,
        y: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: xStart.map(Double.init),
                xEnd: xEnd.map(Double.init),
            )
        }
    }
}

public extension RectanglePlot {
    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>
    ) where Content == VectorizedRectanglePlotContent<Data> {
        chartPlotRecords = ChartVectorizedRecords.rectangles(
            data,
            xStart: xStart,
            xEnd: xEnd,
            yStart: yStart,
            yEnd: yEnd
        )
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        width: MarkDimension = .automatic,
        height: MarkDimension = .automatic
    ) where Content == VectorizedRectanglePlotContent<Data> {
        _ = width
        _ = height
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                x: x.value(from: element).flatMap(chartNumericScalar),
                y: y.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        x: PlottableProjection<Data.Element, X>,
        yStart: PlottableProjection<Data.Element, Y>,
        yEnd: PlottableProjection<Data.Element, Y>,
        width: MarkDimension = .automatic
    ) where Content == VectorizedRectanglePlotContent<Data> {
        _ = width
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable, Y: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<Data.Element, X>,
        xEnd: PlottableProjection<Data.Element, X>,
        y: PlottableProjection<Data.Element, Y>,
        height: MarkDimension = .automatic
    ) where Content == VectorizedRectanglePlotContent<Data> {
        _ = height
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
            )
        }
    }
}

public extension SectorPlot {
    init<Data: RandomAccessCollection, A: Plottable>(
        _ data: Data,
        angle: PlottableProjection<Data.Element, A>,
        innerRadius: MarkDimensions<Data.Element> = .automatic,
        outerRadius: MarkDimensions<Data.Element> = .automatic,
        angularInset: CGFloat? = nil
    ) where Content == VectorizedSectorPlotContent<Data> {
        _ = innerRadius
        _ = outerRadius
        _ = angularInset
        chartPlotRecords = ChartVectorizedRecords.sectors(data, angle: angle)
    }
}

/// Pixel positions for axis ticks against a resolved scale.
public enum ChartAxisLayout {
    public static func tickPositions(
        values: AxisMarkValues,
        scale: ChartScale
    ) -> [CGFloat] {
        let ticks = values.resolvedTicks(domainMin: scale.domainMin, domainMax: scale.domainMax)
        if scale.type == .category {
            return scale.categories.compactMap { name in
                scale.position(forCategory: name).map { CGFloat($0) }
            }
        }
        return ticks.map { CGFloat(scale.position(forNumeric: $0)) }
    }
}

public struct _ChartForegroundStyleContent<Content: ChartContent>: ChartContent {
    let content: Content
    let name: String
    public var chartPlotRecords: [ChartPlotRecord] {
        var records = content.chartPlotRecords
        for index in records.indices {
            records[index].foregroundStyleName = name
        }
        return records
    }
    public var body: some View { content }
}

public extension ChartContent {
    func foregroundStyle<S: ShapeStyle>(_ style: S) -> _ChartForegroundStyleContent<Self> {
        _ChartForegroundStyleContent(content: self, name: String(describing: style))
    }

    func foregroundStyle<D: Plottable>(by value: PlottableValue<D>) -> _ChartForegroundStyleContent<Self> {
        _ChartForegroundStyleContent(content: self, name: value.label)
    }

    func symbol<S: ChartSymbolShape>(_ symbol: S) -> some ChartContent {
        var records = chartPlotRecords
        for index in records.indices {
            records[index].symbolName = String(describing: type(of: symbol))
        }
        return _ChartAttributedPlotContent(records: records)
    }
}

public struct _ChartAttributedPlotContent: ChartContent {
    public var chartPlotRecords: [ChartPlotRecord]
    public init(records: [ChartPlotRecord]) { self.chartPlotRecords = records }
    public var body: some View { EmptyView() }
}

/// Hand-computed plot geometry for a 100×40 plot used by wave-8 tests.
public enum ChartFixedPlotFixture {
    public static let width = 100.0
    public static let height = 40.0
    public static var plotArea: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }
}
