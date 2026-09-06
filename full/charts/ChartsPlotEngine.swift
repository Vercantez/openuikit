#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Placeholder view passed to `compositingLayer(style:)` builders.
public struct PlaceholderContentView<Value>: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct _AxisMarkAttributed<Mark: AxisMark>: AxisMark {
    public var mark: Mark
    public var foregroundStyleName: String?
    public var fontName: String?
    public var offsetX: CGFloat
    public var offsetY: CGFloat

    public init(
        mark: Mark,
        foregroundStyleName: String? = nil,
        fontName: String? = nil,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0
    ) {
        self.mark = mark
        self.foregroundStyleName = foregroundStyleName
        self.fontName = fontName
        self.offsetX = offsetX
        self.offsetY = offsetY
    }

    public var body: some View { mark }
}

public extension AxisMark {
    func foregroundStyle<S: ShapeStyle>(_ style: S) -> _AxisMarkAttributed<Self> {
        _AxisMarkAttributed(mark: self, foregroundStyleName: String(describing: style))
    }

    func font(_ font: Font?) -> _AxisMarkAttributed<Self> {
        _AxisMarkAttributed(mark: self, fontName: font.map { String(describing: $0) })
    }

    func offset(x: CGFloat = 0, y: CGFloat = 0) -> _AxisMarkAttributed<Self> {
        _AxisMarkAttributed(mark: self, offsetX: x, offsetY: y)
    }

    func offset(_ offset: CGSize) -> _AxisMarkAttributed<Self> {
        self.offset(x: offset.width, y: offset.height)
    }
}

public extension ChartContent {
    func cornerRadius(
        _ radius: CGFloat,
        style: RoundedCornerStyle = .continuous
    ) -> _ChartAttributedPlotContent {
        _ = style
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.cornerRadius = Double(radius)
            }
        )
    }

    func compositingLayer<V: View>(
        style: (PlaceholderContentView<Self>) -> V
    ) -> _ChartAttributedPlotContent {
        _ = style(PlaceholderContentView<Self>())
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.compositing = "style"
            }
        )
    }

    func accessibilityLabel(_ labelResource: LocalizedStringResource) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityLabel = labelResource.key
            }
        )
    }

    func accessibilityLabel(_ labelKey: LocalizedStringKey) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityLabel = labelKey.key
            }
        )
    }

    func accessibilityLabel(_ label: Text) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityLabel = label.content
            }
        )
    }

    func accessibilityLabel<S: StringProtocol>(_ label: S) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityLabel = String(label)
            }
        )
    }

    func accessibilityValue(_ valueResource: LocalizedStringResource) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityValue = valueResource.key
            }
        )
    }

    func accessibilityValue(_ valueKey: LocalizedStringKey) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityValue = valueKey.key
            }
        )
    }

    func accessibilityValue(_ valueDescription: Text) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityValue = valueDescription.content
            }
        )
    }

    func accessibilityValue<S: StringProtocol>(_ value: S) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityValue = String(value)
            }
        )
    }

    func accessibilityHidden(_ hidden: Bool) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityHidden = hidden
            }
        )
    }

    func accessibilityIdentifier(_ identifier: String) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.accessibilityIdentifier = identifier
            }
        )
    }

    func blur(radius: CGFloat) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.blurRadius = Double(radius)
            }
        )
    }

    func mask<C: ChartContent>(
        @ChartContentBuilder content: () -> C
    ) -> _ChartAttributedPlotContent {
        _ = content()
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.maskName = "mask"
            }
        )
    }

    func shadow(
        color: Color = .black,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> _ChartAttributedPlotContent {
        _ = color
        _ = x
        _ = y
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.shadowRadius = Double(radius)
            }
        )
    }

    func symbol<D: Plottable>(by value: PlottableValue<D>) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.symbolBy = value.label
            }
        )
    }

    func symbol<V: View>(@ViewBuilder symbol: () -> V) -> _ChartAttributedPlotContent {
        _ = symbol()
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.symbolName = "view"
            }
        )
    }

    func zIndex(_ value: Double) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.zIndex = value
            }
        )
    }

    func opacity(_ value: Double) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.opacity = value
            }
        )
    }

    func position<P: Plottable>(
        by value: PlottableValue<P>,
        axis: Axis? = nil,
        span: MarkDimension = .automatic
    ) -> _ChartAttributedPlotContent {
        _ = span
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.positionBy = axis.map { String(describing: $0) } ?? value.label
            }
        )
    }

    func clipShape(_ shape: some Shape, style: FillStyle = FillStyle()) -> _ChartAttributedPlotContent {
        _ = style
        return _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.clipShapeName = String(describing: type(of: shape))
            }
        )
    }

    func lineStyle<D: Plottable>(by value: PlottableValue<D>) -> _ChartAttributedPlotContent {
        _ChartAttributedPlotContent(
            records: chartStampRecords(chartPlotRecords) { record in
                record.layout.lineStyleBy = value.label
            }
        )
    }
}
