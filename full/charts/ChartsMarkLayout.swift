#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Sectors start at 12 o'clock and sweep with increasing angle in the
/// y-down plot (visually clockwise). Apple's start angle is unobserved.
public let chartSectorStartAngle = -Double.pi / 2

/// Resolve a `MarkDimension` inside a pixel span.
///
/// - `automatic`: inset `defaultInset` on each side.
/// - `inset(v)`: inset `v` on each side.
/// - `fixed(v)`: length `v`, centered.
/// - `ratio(r)`: length `span * r`, centered.
public func chartResolveMarkDimension(
    _ dimension: MarkDimension,
    span: Double,
    defaultInset: Double
) -> (origin: Double, length: Double) {
    switch dimension.kind {
    case "inset":
        let inset = Double(dimension.value ?? 0)
        return (inset, max(0, span - 2 * inset))
    case "fixed":
        let length = min(span, max(0, Double(dimension.value ?? 0)))
        return ((span - length) / 2, length)
    case "ratio":
        let length = max(0, min(span, span * Double(dimension.value ?? 1)))
        return ((span - length) / 2, length)
    default:
        let inset = defaultInset
        return (inset, max(0, span - 2 * inset))
    }
}

/// Resolve a radial `MarkDimension`. `automatic` uses `automaticValue`
/// (`maxRadius` for outer, `0` for inner).
public func chartResolveRadius(
    _ dimension: MarkDimension,
    maxRadius: Double,
    automaticValue: Double
) -> Double {
    switch dimension.kind {
    case "inset":
        return max(0, maxRadius - Double(dimension.value ?? 0))
    case "fixed":
        return max(0, Double(dimension.value ?? 0))
    case "ratio":
        return max(0, maxRadius * Double(dimension.value ?? 1))
    default:
        return automaticValue
    }
}

/// Snap a numeric domain value using `MajorValueAlignment`.
/// `page` → domain lower bound. `unit` → nearest multiple of the unit
/// measured from the domain origin. Other kinds leave the value unchanged.
public func chartSnapMajorValue(
    _ value: Double,
    alignmentKind: String,
    unitValue: Double?,
    domain: ClosedRange<Double>
) -> Double {
    switch alignmentKind {
    case "page":
        return domain.lowerBound
    case "unit":
        guard let unit = unitValue, unit != 0 else { return value }
        let origin = domain.lowerBound
        let steps = ((value - origin) / unit).rounded()
        return origin + steps * unit
    default:
        return value
    }
}

/// Apply `DateComponents` onto `date` using a Gregorian calendar.
/// Unset component fields keep the original date's values.
public func chartSnapMatchingDate(
    _ date: Date,
    components: DateComponents,
    calendar: Calendar = Calendar(identifier: .gregorian)
) -> Date {
    var parts = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: date
    )
    if let year = components.year { parts.year = year }
    if let month = components.month { parts.month = month }
    if let day = components.day { parts.day = day }
    if let hour = components.hour { parts.hour = hour }
    if let minute = components.minute { parts.minute = minute }
    if let second = components.second { parts.second = second }
    return calendar.date(from: parts) ?? date
}

/// Place sector records as polar wedges inside the plot area implied by
/// the resolved X/Y ranges. Angles are fractions of the sum of authored
/// `angle` values (nil angles are skipped).
public func chartPlaceSectors(
    records: [ChartPlotRecord],
    xScale: ChartScale,
    yScale: ChartScale
) -> [ChartPlacedMark] {
    let sectors = records.filter { $0.kind == .sector && $0.angle != nil }
    let total = sectors.reduce(0.0) { $0 + ($1.angle ?? 0) }
    guard total > 0 else { return [] }
    let x0 = min(xScale.rangeStart, xScale.rangeEnd)
    let x1 = max(xScale.rangeStart, xScale.rangeEnd)
    let y0 = min(yScale.rangeStart, yScale.rangeEnd)
    let y1 = max(yScale.rangeStart, yScale.rangeEnd)
    let center = CGPoint(x: (x0 + x1) / 2, y: (y0 + y1) / 2)
    let maxRadius = min(x1 - x0, y1 - y0) / 2
    var cursor = chartSectorStartAngle
    var placed: [ChartPlacedMark] = []
    for record in sectors {
        let sweep = 2 * Double.pi * ((record.angle ?? 0) / total)
        let outer = chartResolveRadius(record.outerRadius, maxRadius: maxRadius, automaticValue: maxRadius)
        let inner = chartResolveRadius(record.innerRadius, maxRadius: maxRadius, automaticValue: 0)
        var start = cursor
        var end = cursor + sweep
        if let inset = record.angularInset, outer > 0 {
            let delta = Double(inset) / outer
            if delta * 2 < sweep {
                start += delta
                end -= delta
            } else {
                let mid = (start + end) / 2
                start = mid
                end = mid
            }
        }
        let startPoint = CGPoint(
            x: center.x + outer * cos(start),
            y: center.y + outer * sin(start)
        )
        let endPoint = CGPoint(
            x: center.x + outer * cos(end),
            y: center.y + outer * sin(end)
        )
        var xs = [center.x, startPoint.x, endPoint.x]
        var ys = [center.y, startPoint.y, endPoint.y]
        let cardinals = [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2, -Double.pi / 2]
        for angle in cardinals where angle >= start - 1e-12 && angle <= end + 1e-12 {
            xs.append(center.x + outer * cos(angle))
            ys.append(center.y + outer * sin(angle))
        }
        let minX = xs.min() ?? center.x
        let minY = ys.min() ?? center.y
        let frame = CGRect(
            x: minX,
            y: minY,
            width: (xs.max() ?? minX) - minX,
            height: (ys.max() ?? minY) - minY
        )
        placed.append(
            ChartPlacedMark(
                kind: .sector,
                frame: frame,
                points: [center, startPoint, endPoint],
                series: record.series,
                startAngle: start,
                endAngle: end,
                innerRadius: inner,
                outerRadius: outer,
                center: center
            )
        )
        cursor += sweep
    }
    return placed
}

public extension Chart3D {
    init<Data: RandomAccessCollection, ID: Hashable, C: Chart3DContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @Chart3DContentBuilder content: @escaping (Data.Element) -> C
    ) where Content == ForEach<Data, ID, C> {
        self.content = ForEach(data, id: id) { element in
            content(element)
        }
    }

    init<Data: RandomAccessCollection, C: Chart3DContent>(
        _ data: Data,
        @Chart3DContentBuilder content: @escaping (Data.Element) -> C
    ) where Content == ForEach<Data, Data.Element.ID, C>, Data.Element: Identifiable {
        self.content = ForEach(data) { element in
            content(element)
        }
    }
}

public extension BarPlot {
    init<Data: RandomAccessCollection>(
        _ data: Data,
        x: PlottableProjection<BarPlot<Content>.DataElement, some Plottable>,
        yStart: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        yEnd: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        width: MarkDimensions<BarPlot<Content>.DataElement> = .automatic,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: Double(element[keyPath: yStart]),
                yEnd: Double(element[keyPath: yEnd]),
                category: x.value(from: element) as? String,
                stacking: stacking,
                markWidth: width.resolved(for: element)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<BarPlot<Content>.DataElement, X>,
        xEnd: PlottableProjection<BarPlot<Content>.DataElement, X>,
        yStart: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        yEnd: KeyPath<BarPlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
                yStart: Double(element[keyPath: yStart]),
                yEnd: Double(element[keyPath: yEnd]),
                stacking: .unstacked
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        xStart: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        xEnd: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        yStart: PlottableProjection<BarPlot<Content>.DataElement, Y>,
        yEnd: PlottableProjection<BarPlot<Content>.DataElement, Y>
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                xStart: Double(element[keyPath: xStart]),
                xEnd: Double(element[keyPath: xEnd]),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar),
                stacking: .unstacked
            )
        }
    }

    init<Data: RandomAccessCollection>(
        _ data: Data,
        xStart: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        xEnd: KeyPath<BarPlot<Content>.DataElement, CGFloat>,
        y: PlottableProjection<BarPlot<Content>.DataElement, some Plottable>,
        height: MarkDimensions<BarPlot<Content>.DataElement> = .automatic,
        stacking: MarkStackingMethod = .standard
    ) where Content == VectorizedBarPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .bar,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: Double(element[keyPath: xStart]),
                xEnd: Double(element[keyPath: xEnd]),
                stacking: stacking,
                markHeight: height.resolved(for: element)
            )
        }
    }
}

public extension RectanglePlot {
    init<Data: RandomAccessCollection>(
        _ data: Data,
        x: PlottableProjection<RectanglePlot<Content>.DataElement, some Plottable>,
        yStart: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        yEnd: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        width: MarkDimensions<RectanglePlot<Content>.DataElement> = .automatic
    ) where Content == VectorizedRectanglePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: Double(element[keyPath: yStart]),
                yEnd: Double(element[keyPath: yEnd]),
                category: x.value(from: element) as? String,
                markWidth: width.resolved(for: element)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<RectanglePlot<Content>.DataElement, X>,
        xEnd: PlottableProjection<RectanglePlot<Content>.DataElement, X>,
        yStart: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        yEnd: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedRectanglePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar),
                yStart: Double(element[keyPath: yStart]),
                yEnd: Double(element[keyPath: yEnd])
            )
        }
    }

    init<Data: RandomAccessCollection>(
        _ data: Data,
        xStart: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        xEnd: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        yStart: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        yEnd: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedRectanglePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                xStart: Double(element[keyPath: xStart]),
                xEnd: Double(element[keyPath: xEnd]),
                yStart: Double(element[keyPath: yStart]),
                yEnd: Double(element[keyPath: yEnd])
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        xStart: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        xEnd: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        yStart: PlottableProjection<RectanglePlot<Content>.DataElement, Y>,
        yEnd: PlottableProjection<RectanglePlot<Content>.DataElement, Y>
    ) where Content == VectorizedRectanglePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                xStart: Double(element[keyPath: xStart]),
                xEnd: Double(element[keyPath: xEnd]),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection>(
        _ data: Data,
        xStart: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        xEnd: KeyPath<RectanglePlot<Content>.DataElement, CGFloat>,
        y: PlottableProjection<RectanglePlot<Content>.DataElement, some Plottable>,
        height: MarkDimensions<RectanglePlot<Content>.DataElement> = .automatic
    ) where Content == VectorizedRectanglePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rectangle,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: Double(element[keyPath: xStart]),
                xEnd: Double(element[keyPath: xEnd]),
                markHeight: height.resolved(for: element)
            )
        }
    }
}

public extension RulePlot {
    init<Data: RandomAccessCollection>(
        _ data: Data,
        x: PlottableProjection<RulePlot<Content>.DataElement, some Plottable>,
        yStart: KeyPath<RulePlot<Content>.DataElement, CGFloat>,
        yEnd: KeyPath<RulePlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                x: x.value(from: element).flatMap(chartNumericScalar),
                yStart: Double(element[keyPath: yStart]),
                yEnd: Double(element[keyPath: yEnd]),
                category: x.value(from: element) as? String
            )
        }
    }

    init<Data: RandomAccessCollection, Y: Plottable>(
        _ data: Data,
        x: KeyPath<RulePlot<Content>.DataElement, CGFloat>,
        yStart: PlottableProjection<RulePlot<Content>.DataElement, Y>,
        yEnd: PlottableProjection<RulePlot<Content>.DataElement, Y>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                x: Double(element[keyPath: x]),
                yStart: yStart.value(from: element).flatMap(chartNumericScalar),
                yEnd: yEnd.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection, X: Plottable>(
        _ data: Data,
        xStart: PlottableProjection<RulePlot<Content>.DataElement, X>,
        xEnd: PlottableProjection<RulePlot<Content>.DataElement, X>,
        y: KeyPath<RulePlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                y: Double(element[keyPath: y]),
                xStart: xStart.value(from: element).flatMap(chartNumericScalar),
                xEnd: xEnd.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }

    init<Data: RandomAccessCollection>(
        _ data: Data,
        xStart: KeyPath<RulePlot<Content>.DataElement, CGFloat>,
        xEnd: KeyPath<RulePlot<Content>.DataElement, CGFloat>,
        y: PlottableProjection<RulePlot<Content>.DataElement, some Plottable>
    ) where Content == VectorizedRulePlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .rule,
                y: y.value(from: element).flatMap(chartNumericScalar),
                xStart: Double(element[keyPath: xStart]),
                xEnd: Double(element[keyPath: xEnd])
            )
        }
    }
}

public extension PointPlot {
    init<Data: RandomAccessCollection>(
        _ data: Data,
        x: PlottableProjection<PointPlot<Content>.DataElement, some Plottable>,
        y: KeyPath<PointPlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedPointPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .point,
                x: x.value(from: element).flatMap(chartNumericScalar),
                y: Double(element[keyPath: y]),
                category: x.value(from: element) as? String
            )
        }
    }

    init<Data: RandomAccessCollection>(
        _ data: Data,
        x: KeyPath<Data.Element, CGFloat>,
        y: PlottableProjection<PointPlot<Content>.DataElement, some Plottable>
    ) where Content == VectorizedPointPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .point,
                x: Double(element[keyPath: x]),
                y: y.value(from: element).flatMap(chartNumericScalar)
            )
        }
    }
}

public extension SectorPlot {
    init<Data: RandomAccessCollection>(
        _ data: Data,
        angle: PlottableProjection<SectorPlot<Content>.DataElement, some Plottable>,
        innerRadius: MarkDimensions<SectorPlot<Content>.DataElement> = .automatic,
        outerRadius: MarkDimensions<SectorPlot<Content>.DataElement> = .automatic,
        angularInset: KeyPath<SectorPlot<Content>.DataElement, CGFloat>
    ) where Content == VectorizedSectorPlotContent<Data> {
        chartPlotRecords = data.map { element in
            ChartPlotRecord(
                kind: .sector,
                angle: angle.value(from: element).flatMap(chartNumericScalar),
                innerRadius: innerRadius.resolved(for: element),
                outerRadius: outerRadius.resolved(for: element),
                angularInset: element[keyPath: angularInset]
            )
        }
    }
}

extension RectangleMark: Chart3DContent {}
extension RuleMark: Chart3DContent {}
extension PointMark: Chart3DContent {}
extension Optional: Chart3DContent where Wrapped: Chart3DContent {}
