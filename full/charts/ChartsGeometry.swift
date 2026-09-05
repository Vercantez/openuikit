#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Encoded plottable payload used by scale resolution and ChartProxy mapping.
public enum ChartEncodedValue: Equatable, Sendable {
    case number(Double)
    case date(Double)
    case category(String)

    public var numeric: Double? {
        switch self {
        case .number(let value), .date(let value):
            return value
        case .category:
            return nil
        }
    }

    public var categoryName: String? {
        if case .category(let name) = self { return name }
        return nil
    }
}

public func chartEncode<Value: Plottable>(_ value: Value) -> ChartEncodedValue? {
    if let text = value as? String {
        return .category(text)
    }
    if let date = value as? Date {
        return .date(date.timeIntervalSinceReferenceDate)
    }
    if let scalar = chartNumericScalar(value) {
        return .number(scalar)
    }
    return nil
}

public func chartNumericScalar<Value: Plottable>(_ value: Value) -> Double? {
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

public func chartDecode<Value: Plottable>(
    _ encoded: ChartEncodedValue,
    as type: Value.Type
) -> Value? {
    switch encoded {
    case .category(let name):
        return name as? Value
    case .date(let scalar):
        if type == Date.self {
            return Date(timeIntervalSinceReferenceDate: scalar) as? Value
        }
        return chartDecodeNumeric(scalar, as: type)
    case .number(let scalar):
        return chartDecodeNumeric(scalar, as: type)
    }
}

private func chartDecodeNumeric<Value: Plottable>(_ scalar: Double, as type: Value.Type) -> Value? {
    if type == Double.self { return scalar as? Value }
    if type == Float.self { return Float(scalar) as? Value }
    if type == Int.self { return Int(scalar.rounded()) as? Value }
    if type == Int8.self { return Int8(scalar.rounded()) as? Value }
    if type == Int16.self { return Int16(scalar.rounded()) as? Value }
    if type == Int32.self { return Int32(scalar.rounded()) as? Value }
    if type == Int64.self { return Int64(scalar.rounded()) as? Value }
    if type == UInt.self { return UInt(max(0, scalar).rounded()) as? Value }
    if type == UInt8.self { return UInt8(max(0, scalar).rounded()) as? Value }
    if type == UInt16.self { return UInt16(max(0, scalar).rounded()) as? Value }
    if type == UInt32.self { return UInt32(max(0, scalar).rounded()) as? Value }
    if type == UInt64.self { return UInt64(max(0, scalar).rounded()) as? Value }
    if type == Date.self {
        return Date(timeIntervalSinceReferenceDate: scalar) as? Value
    }
    return nil
}

public struct ChartPlotRecord: Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case bar
        case line
        case point
        case area
        case rule
        case rectangle
        case sector
    }

    public var kind: Kind
    public var x: Double?
    public var y: Double?
    public var xStart: Double?
    public var xEnd: Double?
    public var yStart: Double?
    public var yEnd: Double?
    public var category: String?
    public var series: String?
    public var stacking: MarkStackingMethod
    public var angle: Double?
    public var interpolation: InterpolationMethod?
    public var lineWidth: CGFloat?
    public var lineDash: [CGFloat]
    public var symbolName: String?
    public var foregroundStyleName: String?
    public var annotationPosition: String?
    public var annotationAlignment: String?
    public var opacity: Double?

    public init(
        kind: Kind,
        x: Double? = nil,
        y: Double? = nil,
        xStart: Double? = nil,
        xEnd: Double? = nil,
        yStart: Double? = nil,
        yEnd: Double? = nil,
        category: String? = nil,
        series: String? = nil,
        stacking: MarkStackingMethod = .standard,
        angle: Double? = nil,
        interpolation: InterpolationMethod? = nil,
        lineWidth: CGFloat? = nil,
        lineDash: [CGFloat] = [],
        symbolName: String? = nil,
        foregroundStyleName: String? = nil,
        annotationPosition: String? = nil,
        annotationAlignment: String? = nil,
        opacity: Double? = nil
    ) {
        self.kind = kind
        self.x = x
        self.y = y
        self.xStart = xStart
        self.xEnd = xEnd
        self.yStart = yStart
        self.yEnd = yEnd
        self.category = category
        self.series = series
        self.stacking = stacking
        self.angle = angle
        self.interpolation = interpolation
        self.lineWidth = lineWidth
        self.lineDash = lineDash
        self.symbolName = symbolName
        self.foregroundStyleName = foregroundStyleName
        self.annotationPosition = annotationPosition
        self.annotationAlignment = annotationAlignment
        self.opacity = opacity
    }
}

/// Resolved scale used by ChartProxy mapping and axis tick generation.
///
/// Nice-number ticks follow the 1-2-5×10^n rule used by D3/Wilkinson-style
/// labeling. For linear domain `0...10` with five desired ticks that produces
/// `0, 2, 4, 6, 8, 10`. Log scales tick at powers of ten. Category scales
/// place one band per discrete value.
public struct ChartScale: Hashable, Sendable {
    public var type: ScaleType
    public var domainMin: Double
    public var domainMax: Double
    public var categories: [String]
    public var rangeStart: Double
    public var rangeEnd: Double
    public var inverted: Bool

    public init(
        type: ScaleType,
        domainMin: Double,
        domainMax: Double,
        categories: [String] = [],
        rangeStart: Double,
        rangeEnd: Double,
        inverted: Bool = false
    ) {
        self.type = type
        self.domainMin = domainMin
        self.domainMax = domainMax
        self.categories = categories
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.inverted = inverted
    }

    public static func linear(
        domain: ClosedRange<Double>,
        range: ClosedRange<Double>,
        inverted: Bool = false
    ) -> ChartScale {
        ChartScale(
            type: .linear,
            domainMin: domain.lowerBound,
            domainMax: domain.upperBound,
            rangeStart: range.lowerBound,
            rangeEnd: range.upperBound,
            inverted: inverted
        )
    }

    public static func log(
        domain: ClosedRange<Double>,
        range: ClosedRange<Double>,
        inverted: Bool = false
    ) -> ChartScale {
        ChartScale(
            type: .log,
            domainMin: domain.lowerBound,
            domainMax: domain.upperBound,
            rangeStart: range.lowerBound,
            rangeEnd: range.upperBound,
            inverted: inverted
        )
    }

    public static func date(
        domain: ClosedRange<Double>,
        range: ClosedRange<Double>,
        inverted: Bool = false
    ) -> ChartScale {
        ChartScale(
            type: .date,
            domainMin: domain.lowerBound,
            domainMax: domain.upperBound,
            rangeStart: range.lowerBound,
            rangeEnd: range.upperBound,
            inverted: inverted
        )
    }

    public static func category(
        _ names: [String],
        range: ClosedRange<Double>
    ) -> ChartScale {
        ChartScale(
            type: .category,
            domainMin: 0,
            domainMax: Double(max(names.count, 1)),
            categories: names,
            rangeStart: range.lowerBound,
            rangeEnd: range.upperBound
        )
    }

    /// Log mapping used for symbol-size scales. Domain must be positive.
    /// For domain `1...1000` and range `0...90`, value `10` maps to `30`
    /// (log10 ticks at 1, 10, 100, 1000 → 0, 30, 60, 90).
    public static func symbolLog(
        domain: ClosedRange<Double>,
        range: ClosedRange<Double>,
        inverted: Bool = false
    ) -> ChartScale {
        ChartScale(
            type: .symbolLog,
            domainMin: domain.lowerBound,
            domainMax: domain.upperBound,
            rangeStart: range.lowerBound,
            rangeEnd: range.upperBound,
            inverted: inverted
        )
    }

    public var rangeLength: Double { rangeEnd - rangeStart }

    public var bandWidth: Double {
        guard type == .category, !categories.isEmpty else { return 0 }
        return rangeLength / Double(categories.count)
    }

    public func position(forNumeric value: Double) -> Double {
        let unit: Double
        if type == .log || type == .symbolLog {
            let lo = log10(max(domainMin, .leastNonzeroMagnitude))
            let hi = log10(max(domainMax, domainMin * 10))
            let span = hi - lo
            guard span != 0 else { return rangeStart }
            unit = (log10(max(value, .leastNonzeroMagnitude)) - lo) / span
        } else {
            let span = domainMax - domainMin
            guard span != 0 else { return rangeStart }
            unit = (value - domainMin) / span
        }
        let clamped = min(max(unit, 0), 1)
        let mapped = inverted ? (1 - clamped) : clamped
        return rangeStart + mapped * rangeLength
    }

    public func position(forCategory name: String) -> Double? {
        guard let index = categories.firstIndex(of: name) else { return nil }
        return rangeStart + (Double(index) + 0.5) * bandWidth
    }

    public func position(for encoded: ChartEncodedValue) -> Double? {
        switch encoded {
        case .category(let name):
            return position(forCategory: name)
        case .number(let value), .date(let value):
            return position(forNumeric: value)
        }
    }

    public func bandStart(forCategory name: String) -> Double? {
        guard let index = categories.firstIndex(of: name) else { return nil }
        return rangeStart + Double(index) * bandWidth
    }

    public func numericValue(at position: Double) -> Double {
        let span = rangeLength
        guard span != 0 else { return domainMin }
        var unit = (position - rangeStart) / span
        if inverted { unit = 1 - unit }
        if type == .log || type == .symbolLog {
            let lo = log10(max(domainMin, .leastNonzeroMagnitude))
            let hi = log10(max(domainMax, domainMin * 10))
            return pow(10, lo + unit * (hi - lo))
        }
        return domainMin + unit * (domainMax - domainMin)
    }

    public func categoryValue(at position: Double) -> String? {
        guard !categories.isEmpty, bandWidth != 0 else { return nil }
        let index = Int(floor((position - rangeStart) / bandWidth))
        let clamped = min(max(index, 0), categories.count - 1)
        return categories[clamped]
    }

    public func niceDomain(desiredTicks: Int = 5) -> (min: Double, max: Double) {
        if type == .category {
            return (0, Double(max(categories.count, 1)))
        }
        if type == .log || type == .symbolLog {
            let lo = pow(10, floor(log10(max(domainMin, .leastNonzeroMagnitude))))
            let hi = pow(10, ceil(log10(max(domainMax, domainMin * 10))))
            return (lo, hi)
        }
        let ticks = ChartNiceNumbers.ticks(
            min: domainMin,
            max: domainMax,
            desired: desiredTicks
        )
        guard let first = ticks.first, let last = ticks.last else {
            return (domainMin, domainMax)
        }
        return (first, last)
    }

    public func niceTicks(desiredCount: Int = 5) -> [Double] {
        if type == .category {
            return categories.indices.map { Double($0) + 0.5 }
        }
        if type == .log || type == .symbolLog {
            var ticks: [Double] = []
            let (lo, hi) = niceDomain()
            var value = lo
            while value <= hi * 1.0000001 {
                ticks.append(value)
                value *= 10
            }
            return ticks
        }
        return ChartNiceNumbers.ticks(
            min: domainMin,
            max: domainMax,
            desired: desiredCount
        )
    }

    public func formattedTicks<Format: FormatStyle>(
        _ format: Format,
        desiredCount: Int = 5
    ) -> [String] where Format.FormatInput == Double, Format.FormatOutput == String {
        niceTicks(desiredCount: desiredCount).map { format.format($0) }
    }
}

public enum ChartNiceNumbers {
    public static func step(span: Double, desired: Int) -> Double {
        guard span > 0, desired > 0 else { return 1 }
        let raw = span / Double(desired)
        let exponent = floor(log10(raw))
        let magnitude = pow(10, exponent)
        let residual = raw / magnitude
        let nice: Double
        if residual <= 1 {
            nice = 1
        } else if residual <= 2 {
            nice = 2
        } else if residual <= 5 {
            nice = 5
        } else {
            nice = 10
        }
        return nice * magnitude
    }

    public static func ticks(min: Double, max: Double, desired: Int = 5) -> [Double] {
        let span = max - min
        guard span > 0 else { return [min] }
        let increment = step(span: span, desired: desired)
        let niceMin = floor(min / increment) * increment
        let niceMax = ceil(max / increment) * increment
        var values: [Double] = []
        var value = niceMin
        let limit = niceMax + increment * 0.5
        while value <= limit {
            let snapped = (value / increment).rounded() * increment
            values.append(snapped)
            value += increment
        }
        return values
    }
}

public struct ChartStackedBar: Equatable, Sendable {
    public var category: String
    public var series: String
    public var yStart: Double
    public var yEnd: Double
}

public enum ChartStacking {
    public static func stack(
        rows: [(category: String, series: String, value: Double)],
        method: MarkStackingMethod
    ) -> [ChartStackedBar] {
        var order: [String] = []
        var seriesOrder: [String] = []
        var grouped: [String: [(series: String, value: Double)]] = [:]
        for row in rows {
            if grouped[row.category] == nil { order.append(row.category) }
            if !seriesOrder.contains(row.series) { seriesOrder.append(row.series) }
            grouped[row.category, default: []].append((row.series, row.value))
        }
        var result: [ChartStackedBar] = []
        for category in order {
            let entries = grouped[category] ?? []
            let total = entries.reduce(0) { $0 + $1.value }
            switch method.description {
            case "unstacked":
                for entry in entries {
                    result.append(
                        ChartStackedBar(
                            category: category,
                            series: entry.series,
                            yStart: min(0, entry.value),
                            yEnd: max(0, entry.value)
                        )
                    )
                }
            case "normalized":
                var cursor = 0.0
                let denom = total == 0 ? 1.0 : total
                for entry in entries {
                    let next = cursor + entry.value / denom
                    result.append(
                        ChartStackedBar(
                            category: category,
                            series: entry.series,
                            yStart: cursor,
                            yEnd: next
                        )
                    )
                    cursor = next
                }
            case "center":
                var cursor = -total / 2
                for entry in entries {
                    let next = cursor + entry.value
                    result.append(
                        ChartStackedBar(
                            category: category,
                            series: entry.series,
                            yStart: cursor,
                            yEnd: next
                        )
                    )
                    cursor = next
                }
            default:
                var cursor = 0.0
                for entry in entries {
                    let next = cursor + entry.value
                    result.append(
                        ChartStackedBar(
                            category: category,
                            series: entry.series,
                            yStart: cursor,
                            yEnd: next
                        )
                    )
                    cursor = next
                }
            }
        }
        return result
    }
}

public enum ChartInterpolation {
    public static func sample(
        points: [CGPoint],
        method: InterpolationMethod,
        countPerSegment: Int = 8
    ) -> [CGPoint] {
        guard points.count >= 2 else { return points }
        switch method.description {
        case "linear":
            return sampleLinear(points, countPerSegment: countPerSegment)
        case "stepStart":
            return sampleStep(points, mode: .start)
        case "stepEnd":
            return sampleStep(points, mode: .end)
        case "stepCenter":
            return sampleStep(points, mode: .center)
        case "monotone":
            return sampleMonotone(points, countPerSegment: countPerSegment)
        case "catmullRom", "cardinal":
            return sampleCatmullRom(
                points,
                alpha: method.parameter ?? 0.5,
                countPerSegment: countPerSegment
            )
        default:
            return sampleLinear(points, countPerSegment: countPerSegment)
        }
    }

    private enum StepMode { case start, end, center }

    private static func sampleLinear(
        _ points: [CGPoint],
        countPerSegment: Int
    ) -> [CGPoint] {
        var sampled: [CGPoint] = []
        for index in 0..<(points.count - 1) {
            let a = points[index]
            let b = points[index + 1]
            for step in 0..<countPerSegment {
                let t = CGFloat(step) / CGFloat(countPerSegment)
                sampled.append(
                    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                )
            }
        }
        sampled.append(points[points.count - 1])
        return sampled
    }

    private static func sampleStep(_ points: [CGPoint], mode: StepMode) -> [CGPoint] {
        var sampled: [CGPoint] = [points[0]]
        for index in 0..<(points.count - 1) {
            let a = points[index]
            let b = points[index + 1]
            switch mode {
            case .start:
                sampled.append(CGPoint(x: b.x, y: a.y))
                sampled.append(b)
            case .end:
                sampled.append(CGPoint(x: a.x, y: b.y))
                sampled.append(b)
            case .center:
                let mid = (a.x + b.x) / 2
                sampled.append(CGPoint(x: mid, y: a.y))
                sampled.append(CGPoint(x: mid, y: b.y))
                sampled.append(b)
            }
        }
        return sampled
    }

    private static func sampleMonotone(
        _ points: [CGPoint],
        countPerSegment: Int
    ) -> [CGPoint] {
        let count = points.count
        var dx = [Double](repeating: 0, count: count - 1)
        var delta = [Double](repeating: 0, count: count - 1)
        for index in 0..<(count - 1) {
            dx[index] = Double(points[index + 1].x - points[index].x)
            let dy = Double(points[index + 1].y - points[index].y)
            delta[index] = dx[index] == 0 ? 0 : dy / dx[index]
        }
        var slope = [Double](repeating: 0, count: count)
        slope[0] = delta[0]
        slope[count - 1] = delta[count - 2]
        if count > 2 {
            for index in 1..<(count - 1) {
                slope[index] = (delta[index - 1] + delta[index]) / 2
            }
        }
        for index in 0..<(count - 1) {
            if delta[index] == 0 {
                slope[index] = 0
                slope[index + 1] = 0
            } else {
                let alpha = slope[index] / delta[index]
                let beta = slope[index + 1] / delta[index]
                let sum = alpha * alpha + beta * beta
                if sum > 9 {
                    let tau = 3 / sqrt(sum)
                    slope[index] = tau * alpha * delta[index]
                    slope[index + 1] = tau * beta * delta[index]
                }
            }
        }
        var sampled: [CGPoint] = []
        for index in 0..<(count - 1) {
            let a = points[index]
            let b = points[index + 1]
            for step in 0..<countPerSegment {
                let t = Double(step) / Double(countPerSegment)
                let t2 = t * t
                let t3 = t2 * t
                let h00 = 2 * t3 - 3 * t2 + 1
                let h10 = t3 - 2 * t2 + t
                let h01 = -2 * t3 + 3 * t2
                let h11 = t3 - t2
                let y =
                    h00 * Double(a.y)
                    + h10 * dx[index] * slope[index]
                    + h01 * Double(b.y)
                    + h11 * dx[index] * slope[index + 1]
                let x = Double(a.x) + t * dx[index]
                sampled.append(CGPoint(x: x, y: y))
            }
        }
        sampled.append(points[count - 1])
        return sampled
    }

    private static func sampleCatmullRom(
        _ points: [CGPoint],
        alpha: CGFloat,
        countPerSegment: Int
    ) -> [CGPoint] {
        func knot(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = b.x - a.x
            let dy = b.y - a.y
            return pow(dx * dx + dy * dy, alpha / 2)
        }
        var sampled: [CGPoint] = []
        for index in 0..<(points.count - 1) {
            let p0 = points[max(index - 1, 0)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(index + 2, points.count - 1)]
            let t0: CGFloat = 0
            let t1 = t0 + knot(p0, p1)
            let t2 = t1 + knot(p1, p2)
            let t3 = t2 + knot(p2, p3)
            for step in 0..<countPerSegment {
                let t = t1 + (t2 - t1) * CGFloat(step) / CGFloat(countPerSegment)
                func lerp(_ a: CGPoint, _ b: CGPoint, _ ta: CGFloat, _ tb: CGFloat) -> CGPoint {
                    if tb == ta { return a }
                    let u = (t - ta) / (tb - ta)
                    return CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u)
                }
                let a1 = lerp(p0, p1, t0, t1)
                let a2 = lerp(p1, p2, t1, t2)
                let a3 = lerp(p2, p3, t2, t3)
                let b1 = lerp(a1, a2, t0, t2)
                let b2 = lerp(a2, a3, t1, t3)
                sampled.append(lerp(b1, b2, t1, t2))
            }
        }
        sampled.append(points[points.count - 1])
        return sampled
    }
}

public enum ChartAnnotationPlacement {
    public static let defaultSpacing: CGFloat = 4

    public static func offset(
        position: AnnotationPosition,
        spacing: CGFloat? = nil
    ) -> CGSize {
        let gap = spacing ?? defaultSpacing
        switch position.description {
        case "bottom":
            return CGSize(width: 0, height: gap)
        case "leading":
            return CGSize(width: -gap, height: 0)
        case "trailing":
            return CGSize(width: gap, height: 0)
        case "overlay":
            return .zero
        default:
            return CGSize(width: 0, height: -gap)
        }
    }
}

public struct ChartPlacedMark: Equatable, Sendable {
    public var kind: ChartPlotRecord.Kind
    public var frame: CGRect
    public var points: [CGPoint]
    public var series: String?

    public init(
        kind: ChartPlotRecord.Kind,
        frame: CGRect = .zero,
        points: [CGPoint] = [],
        series: String? = nil
    ) {
        self.kind = kind
        self.frame = frame
        self.points = points
        self.series = series
    }
}

public enum ChartLayout {
    public static let defaultBarInset: Double = 4
    public static let defaultPointSize: Double = 6

    public static func place(
        records: [ChartPlotRecord],
        xScale: ChartScale,
        yScale: ChartScale,
        interpolation: InterpolationMethod = .linear
    ) -> [ChartPlacedMark] {
        let stackedKinds: Set<ChartPlotRecord.Kind> = [.bar, .area]
        var placed: [ChartPlacedMark] = []
        let stackRows = records.compactMap { record -> (ChartPlotRecord, String, String, Double)? in
            guard stackedKinds.contains(record.kind) else { return nil }
            let category = record.category ?? record.x.map { String($0) } ?? ""
            let series = record.series ?? "_"
            let value = record.y ?? record.yEnd ?? 0
            return (record, category, series, value)
        }
        var stackedByIdentity: [String: ChartStackedBar] = [:]
        if let method = stackRows.first?.0.stacking {
            let stacked = ChartStacking.stack(
                rows: stackRows.map { ($0.1, $0.2, $0.3) },
                method: method
            )
            for item in stacked {
                stackedByIdentity["\(item.category)\u{1f}\(item.series)"] = item
            }
        }

        var linePoints: [String: [CGPoint]] = [:]
        var lineKind: [String: ChartPlotRecord.Kind] = [:]

        for record in records {
            switch record.kind {
            case .bar, .rectangle:
                let frame = barFrame(record, xScale: xScale, yScale: yScale, stacked: stackedByIdentity)
                placed.append(ChartPlacedMark(kind: record.kind, frame: frame, series: record.series))
            case .point:
                guard let x = xPosition(record, scale: xScale),
                      let y = yPosition(record, scale: yScale)
                else { continue }
                let size = defaultPointSize
                placed.append(
                    ChartPlacedMark(
                        kind: .point,
                        frame: CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size),
                        points: [CGPoint(x: x, y: y)],
                        series: record.series
                    )
                )
            case .rule:
                if let x = xPosition(record, scale: xScale) {
                    let y0 = min(yScale.rangeStart, yScale.rangeEnd)
                    let y1 = max(yScale.rangeStart, yScale.rangeEnd)
                    placed.append(
                        ChartPlacedMark(
                            kind: .rule,
                            frame: CGRect(x: x, y: y0, width: 1, height: y1 - y0),
                            points: [
                                CGPoint(x: x, y: y0),
                                CGPoint(x: x, y: y1),
                            ],
                            series: record.series
                        )
                    )
                } else if let y = yPosition(record, scale: yScale) {
                    let x0 = min(xScale.rangeStart, xScale.rangeEnd)
                    let x1 = max(xScale.rangeStart, xScale.rangeEnd)
                    placed.append(
                        ChartPlacedMark(
                            kind: .rule,
                            frame: CGRect(x: x0, y: y, width: x1 - x0, height: 1),
                            points: [
                                CGPoint(x: x0, y: y),
                                CGPoint(x: x1, y: y),
                            ],
                            series: record.series
                        )
                    )
                }
            case .line, .area:
                guard let x = xPosition(record, scale: xScale),
                      let y = yPosition(record, scale: yScale)
                else { continue }
                let key = record.series ?? "_"
                linePoints[key, default: []].append(CGPoint(x: x, y: y))
                lineKind[key] = record.kind
            case .sector:
                continue
            }
        }

        for (series, points) in linePoints {
            let sorted = points.sorted { $0.x < $1.x }
            let sampled = ChartInterpolation.sample(points: sorted, method: interpolation)
            let kind = lineKind[series] ?? .line
            placed.append(ChartPlacedMark(kind: kind, points: sampled, series: series))
        }
        return placed
    }

    private static func xPosition(_ record: ChartPlotRecord, scale: ChartScale) -> Double? {
        if let name = record.category {
            return scale.position(forCategory: name)
        }
        if let x = record.x {
            return scale.position(forNumeric: x)
        }
        return nil
    }

    private static func yPosition(_ record: ChartPlotRecord, scale: ChartScale) -> Double? {
        if let y = record.y {
            return scale.position(forNumeric: y)
        }
        if let yEnd = record.yEnd {
            return scale.position(forNumeric: yEnd)
        }
        return nil
    }

    private static func barFrame(
        _ record: ChartPlotRecord,
        xScale: ChartScale,
        yScale: ChartScale,
        stacked: [String: ChartStackedBar]
    ) -> CGRect {
        let category = record.category ?? record.x.map { String($0) } ?? ""
        let series = record.series ?? "_"
        let stackedBar = stacked["\(category)\u{1f}\(series)"]
        let yStartValue = stackedBar?.yStart ?? record.yStart ?? 0
        let yEndValue = stackedBar?.yEnd ?? record.yEnd ?? record.y ?? 0
        let y0 = yScale.position(forNumeric: yStartValue)
        let y1 = yScale.position(forNumeric: yEndValue)
        let y = min(y0, y1)
        let height = abs(y1 - y0)
        if xScale.type == .category, let name = record.category ?? (record.x.map { String($0) }) {
            let start = xScale.bandStart(forCategory: name) ?? xScale.rangeStart
            let width = max(1, xScale.bandWidth - 2 * defaultBarInset)
            return CGRect(x: start + defaultBarInset, y: y, width: width, height: height)
        }
        let xStart = record.xStart.map { xScale.position(forNumeric: $0) }
            ?? xPosition(record, scale: xScale).map { $0 - 8 }
            ?? xScale.rangeStart
        let xEnd = record.xEnd.map { xScale.position(forNumeric: $0) }
            ?? xPosition(record, scale: xScale).map { $0 + 8 }
            ?? xStart + 16
        return CGRect(x: min(xStart, xEnd), y: y, width: abs(xEnd - xStart), height: height)
    }
}

public struct ChartBitmap: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, fill: (UInt8, UInt8, UInt8, UInt8) = (255, 255, 255, 255)) {
        self.width = max(0, width)
        self.height = max(0, height)
        var pixels = [UInt8](repeating: 0, count: self.width * self.height * 4)
        if self.width > 0, self.height > 0 {
            for index in 0..<(self.width * self.height) {
                let offset = index * 4
                pixels[offset] = fill.0
                pixels[offset + 1] = fill.1
                pixels[offset + 2] = fill.2
                pixels[offset + 3] = fill.3
            }
        }
        self.pixels = pixels
    }

    public static func pack(
        red: Double,
        green: Double,
        blue: Double,
        opacity: Double
    ) -> (UInt8, UInt8, UInt8, UInt8) {
        (
            UInt8(max(0, min(255, red * 255))),
            UInt8(max(0, min(255, green * 255))),
            UInt8(max(0, min(255, blue * 255))),
            UInt8(max(0, min(255, opacity * 255)))
        )
    }

    public mutating func setPixel(x: Int, y: Int, color: (UInt8, UInt8, UInt8, UInt8)) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        let offset = (y * width + x) * 4
        pixels[offset] = color.0
        pixels[offset + 1] = color.1
        pixels[offset + 2] = color.2
        pixels[offset + 3] = color.3
    }

    public func pixel(x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
        guard x >= 0, y >= 0, x < width, y < height else { return (0, 0, 0, 0) }
        let offset = (y * width + x) * 4
        return (pixels[offset], pixels[offset + 1], pixels[offset + 2], pixels[offset + 3])
    }

    public mutating func fillRect(_ rect: CGRect, color: (UInt8, UInt8, UInt8, UInt8)) {
        let x0 = Int(floor(rect.minX))
        let y0 = Int(floor(rect.minY))
        let x1 = Int(ceil(rect.maxX))
        let y1 = Int(ceil(rect.maxY))
        if x1 <= x0 || y1 <= y0 { return }
        for y in y0..<y1 {
            for x in x0..<x1 {
                setPixel(x: x, y: y, color: color)
            }
        }
    }

    public mutating func strokeRect(
        _ rect: CGRect,
        color: (UInt8, UInt8, UInt8, UInt8),
        width: Int
    ) {
        fillRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: CGFloat(width)), color: color)
        fillRect(CGRect(x: rect.minX, y: rect.maxY - CGFloat(width), width: rect.width, height: CGFloat(width)), color: color)
        fillRect(CGRect(x: rect.minX, y: rect.minY, width: CGFloat(width), height: rect.height), color: color)
        fillRect(CGRect(x: rect.maxX - CGFloat(width), y: rect.minY, width: CGFloat(width), height: rect.height), color: color)
    }

    public mutating func fillEllipse(_ rect: CGRect, color: (UInt8, UInt8, UInt8, UInt8)) {
        let cx = rect.midX
        let cy = rect.midY
        let rx = max(rect.width / 2, 0.5)
        let ry = max(rect.height / 2, 0.5)
        let x0 = Int(floor(rect.minX))
        let y0 = Int(floor(rect.minY))
        let x1 = Int(ceil(rect.maxX))
        let y1 = Int(ceil(rect.maxY))
        for y in y0..<y1 {
            for x in x0..<x1 {
                let nx = (Double(x) + 0.5 - Double(cx)) / Double(rx)
                let ny = (Double(y) + 0.5 - Double(cy)) / Double(ry)
                if nx * nx + ny * ny <= 1 {
                    setPixel(x: x, y: y, color: color)
                }
            }
        }
    }

    public mutating func fillPolygon(_ points: [CGPoint], color: (UInt8, UInt8, UInt8, UInt8)) {
        guard points.count >= 3 else { return }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let x0 = Int(floor(xs.min() ?? 0))
        let y0 = Int(floor(ys.min() ?? 0))
        let x1 = Int(ceil(xs.max() ?? 0))
        let y1 = Int(ceil(ys.max() ?? 0))
        for y in y0..<y1 {
            for x in x0..<x1 {
                if contains(points, CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5)) {
                    setPixel(x: x, y: y, color: color)
                }
            }
        }
    }

    public mutating func strokePolyline(
        _ points: [CGPoint],
        color: (UInt8, UInt8, UInt8, UInt8),
        width: Int
    ) {
        guard points.count >= 2 else { return }
        for index in 0..<(points.count - 1) {
            strokeLine(from: points[index], to: points[index + 1], color: color, width: width)
        }
    }

    private mutating func strokeLine(
        from start: CGPoint,
        to end: CGPoint,
        color: (UInt8, UInt8, UInt8, UInt8),
        width: Int
    ) {
        var x0 = Int(start.x.rounded())
        var y0 = Int(start.y.rounded())
        let x1 = Int(end.x.rounded())
        let y1 = Int(end.y.rounded())
        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        let radius = max(0, (width - 1) / 2)
        while true {
            for oy in -radius...radius {
                for ox in -radius...radius {
                    setPixel(x: x0 + ox, y: y0 + oy, color: color)
                }
            }
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x0 += sx
            }
            if e2 < dx {
                err += dx
                y0 += sy
            }
        }
    }

    private func contains(_ polygon: [CGPoint], _ point: CGPoint) -> Bool {
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let pi = polygon[i]
            let pj = polygon[j]
            let intersect =
                ((pi.y > point.y) != (pj.y > point.y))
                && (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y + 0.0000001) + pi.x)
            if intersect { inside.toggle() }
            j = i
        }
        return inside
    }
}

public enum ChartRaster {
    public static func render(
        marks: [ChartPlacedMark],
        width: Int,
        height: Int,
        fill: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 255, 255),
        background: (UInt8, UInt8, UInt8, UInt8) = (255, 255, 255, 255)
    ) -> ChartBitmap {
        var bitmap = ChartBitmap(width: width, height: height, fill: background)
        for mark in marks {
            switch mark.kind {
            case .bar, .rectangle:
                bitmap.fillRect(mark.frame, color: fill)
            case .point:
                bitmap.fillEllipse(mark.frame, color: fill)
            case .line, .rule:
                bitmap.strokePolyline(mark.points, color: fill, width: 1)
            case .area:
                if mark.points.count >= 2 {
                    var polygon = mark.points
                    if let last = polygon.last, let first = polygon.first {
                        polygon.append(CGPoint(x: last.x, y: CGFloat(height)))
                        polygon.append(CGPoint(x: first.x, y: CGFloat(height)))
                    }
                    bitmap.fillPolygon(polygon, color: fill)
                }
            case .sector:
                bitmap.fillEllipse(mark.frame, color: fill)
            }
        }
        return bitmap
    }
}

#if !canImport(SwiftUI)
public enum ChartCanvasDrawing {
    public static func draw(
        _ marks: [ChartPlacedMark],
        into context: inout GraphicsContext,
        color: Color = .blue
    ) {
        for mark in marks {
            switch mark.kind {
            case .bar, .rectangle:
                context.fill(Path(mark.frame), with: .color(color))
            case .point:
                context.fill(ellipse: mark.frame, color: color)
            case .line, .rule:
                var path = Path()
                path.addLines(mark.points)
                context.stroke(path, with: .color(color), lineWidth: 1)
            case .area:
                var path = Path()
                path.addLines(mark.points)
                context.fill(path, with: .color(color))
            case .sector:
                context.fill(ellipse: mark.frame, color: color)
            }
        }
    }
}

private extension GraphicsContext {
    mutating func fill(ellipse rect: CGRect, color: Color) {
        var path = Path()
        path.addEllipse(in: rect)
        fill(path, with: .color(color))
    }
}
#endif

/// Hand-computed 3-bar fixture used by the pixel test.
public enum ChartThreeBarFixture {
    public static let width = 90
    public static let height = 60
    public static let categories = ["A", "B", "C"]
    public static let values = [1.0, 2.0, 3.0]

    public static var plotArea: CGRect {
        CGRect(x: 0, y: 0, width: Double(width), height: Double(height))
    }

    public static func records() -> [ChartPlotRecord] {
        zip(categories, values).map { name, value in
            ChartPlotRecord(
                kind: .bar,
                y: value,
                category: name,
                stacking: .unstacked
            )
        }
    }

    public static func xScale() -> ChartScale {
        .category(categories, range: 0...Double(width))
    }

    public static func yScale() -> ChartScale {
        .linear(domain: 0...3, range: 0...Double(height), inverted: true)
    }

    public static func expectedFrames() -> [CGRect] {
        let band = Double(width) / 3
        let inset = ChartLayout.defaultBarInset
        let barWidth = band - 2 * inset
        return values.enumerated().map { index, value in
            let heightPx = value / 3.0 * Double(height)
            return CGRect(
                x: Double(index) * band + inset,
                y: Double(height) - heightPx,
                width: barWidth,
                height: heightPx
            )
        }
    }

    public static func expectedBitmap() -> ChartBitmap {
        var bitmap = ChartBitmap(width: width, height: height)
        for frame in expectedFrames() {
            bitmap.fillRect(frame, color: (0, 0, 255, 255))
        }
        return bitmap
    }
}

public struct ChartScaleStorage: Equatable, Sendable {
    public var axis: String
    public var type: ScaleType?
    public var domainMin: Double?
    public var domainMax: Double?
    public var categories: [String]
    public var range: PlotDimensionScaleRange?

    public init(
        axis: String,
        type: ScaleType? = nil,
        domainMin: Double? = nil,
        domainMax: Double? = nil,
        categories: [String] = [],
        range: PlotDimensionScaleRange? = nil
    ) {
        self.axis = axis
        self.type = type
        self.domainMin = domainMin
        self.domainMax = domainMax
        self.categories = categories
        self.range = range
    }
}

public struct ChartAxisStorage: Equatable, Sendable {
    public var axis: String
    public var visibility: Visibility
    public var position: AxisMarkPosition
    public var values: [Double]
    public var labels: [String]

    public init(
        axis: String,
        visibility: Visibility = .automatic,
        position: AxisMarkPosition = .automatic,
        values: [Double] = [],
        labels: [String] = []
    ) {
        self.axis = axis
        self.visibility = visibility
        self.position = position
        self.values = values
        self.labels = labels
    }
}

public struct ChartLegendStorage: Equatable, Sendable {
    public var visibility: Visibility
    public var position: AnnotationPosition
    public var spacing: CGFloat?

    public init(
        visibility: Visibility = .automatic,
        position: AnnotationPosition = .automatic,
        spacing: CGFloat? = nil
    ) {
        self.visibility = visibility
        self.position = position
        self.spacing = spacing
    }
}

public struct ChartForegroundStyleScaleStorage: Equatable, Sendable {
    public var domain: [String]
    public var type: ScaleType?

    public init(domain: [String] = [], type: ScaleType? = nil) {
        self.domain = domain
        self.type = type
    }
}
