import Foundation

public struct PKStrokePoint: Equatable, Sendable {
    public var location: CGPoint
    public var timeOffset: TimeInterval
    public var size: CGSize
    public var opacity: CGFloat
    public var force: CGFloat
    public var azimuth: CGFloat
    public var altitude: CGFloat
    public var secondaryScale: CGFloat
    public var threshold: CGFloat

    public init(
        location: CGPoint,
        timeOffset: TimeInterval,
        size: CGSize,
        opacity: CGFloat,
        force: CGFloat,
        azimuth: CGFloat,
        altitude: CGFloat
    ) {
        self.init(
            location: location,
            timeOffset: timeOffset,
            size: size,
            opacity: opacity,
            force: force,
            azimuth: azimuth,
            altitude: altitude,
            secondaryScale: 1,
            threshold: 0
        )
    }

    public init(
        location: CGPoint,
        timeOffset: TimeInterval,
        size: CGSize,
        opacity: CGFloat,
        force: CGFloat,
        azimuth: CGFloat,
        altitude: CGFloat,
        secondaryScale: CGFloat
    ) {
        self.init(
            location: location,
            timeOffset: timeOffset,
            size: size,
            opacity: opacity,
            force: force,
            azimuth: azimuth,
            altitude: altitude,
            secondaryScale: secondaryScale,
            threshold: 0
        )
    }

    public init(
        location: CGPoint,
        timeOffset: TimeInterval,
        size: CGSize,
        opacity: CGFloat,
        force: CGFloat,
        azimuth: CGFloat,
        altitude: CGFloat,
        secondaryScale: CGFloat,
        threshold: CGFloat
    ) {
        self.location = location
        self.timeOffset = timeOffset
        self.size = size
        self.opacity = opacity
        self.force = force
        self.azimuth = azimuth
        self.altitude = altitude
        self.secondaryScale = secondaryScale
        self.threshold = threshold
    }

    static func lerp(_ a: PKStrokePoint, _ b: PKStrokePoint, t: CGFloat) -> PKStrokePoint {
        let u = min(max(t, 0), 1)
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * u }
        return PKStrokePoint(
            location: CGPoint(
                x: mix(a.location.x, b.location.x),
                y: mix(a.location.y, b.location.y)
            ),
            timeOffset: TimeInterval(mix(CGFloat(a.timeOffset), CGFloat(b.timeOffset))),
            size: CGSize(
                width: mix(a.size.width, b.size.width),
                height: mix(a.size.height, b.size.height)
            ),
            opacity: mix(a.opacity, b.opacity),
            force: mix(a.force, b.force),
            azimuth: mix(a.azimuth, b.azimuth),
            altitude: mix(a.altitude, b.altitude),
            secondaryScale: mix(a.secondaryScale, b.secondaryScale),
            threshold: mix(a.threshold, b.threshold)
        )
    }
}

open class PKStrokePointReference: NSObject {
    public var point: PKStrokePoint

    public init(
        location: CGPoint,
        timeOffset: TimeInterval,
        size: CGSize,
        opacity: CGFloat,
        force: CGFloat,
        azimuth: CGFloat,
        altitude: CGFloat
    ) {
        self.point = PKStrokePoint(
            location: location,
            timeOffset: timeOffset,
            size: size,
            opacity: opacity,
            force: force,
            azimuth: azimuth,
            altitude: altitude
        )
        super.init()
    }

    public init(
        location: CGPoint,
        timeOffset: TimeInterval,
        size: CGSize,
        opacity: CGFloat,
        force: CGFloat,
        azimuth: CGFloat,
        altitude: CGFloat,
        secondaryScale: CGFloat
    ) {
        self.point = PKStrokePoint(
            location: location,
            timeOffset: timeOffset,
            size: size,
            opacity: opacity,
            force: force,
            azimuth: azimuth,
            altitude: altitude,
            secondaryScale: secondaryScale
        )
        super.init()
    }

    public init(
        location: CGPoint,
        timeOffset: TimeInterval,
        size: CGSize,
        opacity: CGFloat,
        force: CGFloat,
        azimuth: CGFloat,
        altitude: CGFloat,
        secondaryScale: CGFloat,
        threshold: CGFloat
    ) {
        self.point = PKStrokePoint(
            location: location,
            timeOffset: timeOffset,
            size: size,
            opacity: opacity,
            force: force,
            azimuth: azimuth,
            altitude: altitude,
            secondaryScale: secondaryScale,
            threshold: threshold
        )
        super.init()
    }

    public var altitude: CGFloat { point.altitude }
    public var azimuth: CGFloat { point.azimuth }
    public var force: CGFloat { point.force }
    public var location: CGPoint { point.location }
    public var opacity: CGFloat { point.opacity }
    public var secondaryScale: CGFloat { point.secondaryScale }
    public var size: CGSize { point.size }
    public var threshold: CGFloat { point.threshold }
    public var timeOffset: TimeInterval { point.timeOffset }
}

public struct PKStrokePath: RandomAccessCollection, Equatable, Sendable {
    public typealias Index = Int
    public typealias Element = PKStrokePoint
    public typealias SubSequence = Slice<PKStrokePath>
    public typealias Indices = Range<PKStrokePath.Index>
    public typealias Iterator = IndexingIterator<PKStrokePath>

    var points: [PKStrokePoint]
    public var creationDate: Date

    public init() {
        self.points = []
        self.creationDate = Date(timeIntervalSince1970: 0)
    }

    public init<T>(controlPoints: T, creationDate: Date) where T: Sequence, T.Element == PKStrokePoint {
        self.points = Array(controlPoints)
        self.creationDate = creationDate
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { points.count }

    public subscript(index: PKStrokePath.Index) -> PKStrokePoint {
        points[index]
    }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }

    public func point(at i: Int) -> PKStrokePoint { self[i] }

    /// Linear interpolation along control-point indices. Parametric 0 is the
    /// first point; `count - 1` is the last. This is not Apple's ink spline.
    public func interpolatedPoint(at parametricValue: CGFloat) -> PKStrokePoint {
        guard !points.isEmpty else {
            return PKStrokePoint(
                location: .zero,
                timeOffset: 0,
                size: .zero,
                opacity: 1,
                force: 0,
                azimuth: 0,
                altitude: 0
            )
        }
        if points.count == 1 { return points[0] }
        let maxParam = CGFloat(points.count - 1)
        let clamped = Swift.min(Swift.max(parametricValue, 0), maxParam)
        let lower = Int(clamped.rounded(.down))
        let upper = Swift.min(lower + 1, points.count - 1)
        if lower == upper { return points[lower] }
        let t = clamped - CGFloat(lower)
        return PKStrokePoint.lerp(points[lower], points[upper], t: t)
    }

    public func interpolatedLocation(at parametricValue: CGFloat) -> CGPoint {
        interpolatedPoint(at: parametricValue).location
    }

    public func parametricValue(_ parametricValue: CGFloat, offsetBy step: PKStrokePath.InterpolatedSlice.Stride) -> CGFloat {
        switch step {
        case .parametricStep(let delta):
            return parametricValue + delta
        case .distance(let distanceStep):
            return offsetParametric(parametricValue, remaining: distanceStep) { a, b in
                hypot(b.location.x - a.location.x, b.location.y - a.location.y)
            }
        case .time(let timeStep):
            return offsetParametric(parametricValue, remaining: CGFloat(timeStep)) { a, b in
                CGFloat(b.timeOffset - a.timeOffset)
            }
        }
    }

    public func parametricValue(_ parametricValue: CGFloat, offsetByDistance distanceStep: CGFloat) -> CGFloat {
        self.parametricValue(parametricValue, offsetBy: .distance(distanceStep))
    }

    public func parametricValue(_ parametricValue: CGFloat, offsetByTime timeStep: TimeInterval) -> CGFloat {
        self.parametricValue(parametricValue, offsetBy: .time(timeStep))
    }

    public func interpolatedPoints(
        in range: ClosedRange<CGFloat>? = nil,
        by stride: PKStrokePath.InterpolatedSlice.Stride
    ) -> PKStrokePath.InterpolatedSlice {
        let maxParam = points.isEmpty ? 0 : CGFloat(points.count - 1)
        let resolved = range ?? (0...maxParam)
        return PKStrokePath.InterpolatedSlice(path: self, range: resolved, stride: stride)
    }

    public func enumerateInterpolatedPoints(
        in range: __PKFloatRange,
        strideByDistance distanceStep: CGFloat,
        using block: (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        enumerate(slice: interpolatedPoints(in: range.closedRange, by: .distance(distanceStep)), using: block)
    }

    public func enumerateInterpolatedPoints(
        in range: __PKFloatRange,
        strideByParametricStep parametricStep: CGFloat,
        using block: (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        enumerate(slice: interpolatedPoints(in: range.closedRange, by: .parametricStep(parametricStep)), using: block)
    }

    public func enumerateInterpolatedPoints(
        in range: __PKFloatRange,
        strideByTime timeStep: TimeInterval,
        using block: (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        enumerate(slice: interpolatedPoints(in: range.closedRange, by: .time(timeStep)), using: block)
    }

    private func enumerate(
        slice: PKStrokePath.InterpolatedSlice,
        using block: (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var cursor = slice
        var stop = ObjCBool(false)
        while let point = cursor.next() {
            withUnsafeMutablePointer(to: &stop) { pointer in
                block(point, pointer)
            }
            if stop.boolValue { break }
        }
    }

    private func offsetParametric(
        _ start: CGFloat,
        remaining: CGFloat,
        metric: (PKStrokePoint, PKStrokePoint) -> CGFloat
    ) -> CGFloat {
        guard remaining > 0, points.count >= 2 else { return start }
        let maxParam = CGFloat(points.count - 1)
        var param = Swift.min(Swift.max(start, 0), maxParam)
        var left = remaining
        while param < maxParam && left > 0 {
            let lower = Int(param.rounded(.down))
            let upper = Swift.min(lower + 1, points.count - 1)
            if lower == upper { break }
            let t0 = param - CGFloat(lower)
            let a = interpolatedPoint(at: param)
            let b = points[upper]
            let span = metric(a, b)
            let remainingInSegment = Swift.max(CGFloat(1) - t0, 0)
            let segmentMetric = metric(points[lower], points[upper]) * remainingInSegment
            let usable = span > 0 ? span : segmentMetric
            if usable <= 0 {
                param = CGFloat(upper)
                continue
            }
            if left < usable {
                let fraction = left / usable
                param += remainingInSegment * fraction
                left = 0
            } else {
                left -= usable
                param = CGFloat(upper)
            }
        }
        return Swift.min(param, maxParam)
    }

    public struct InterpolatedSlice: Sequence, IteratorProtocol, Sendable {
        public typealias Element = PKStrokePoint
        public typealias Iterator = PKStrokePath.InterpolatedSlice

        public enum Stride: Sendable, Equatable {
            case parametricStep(CGFloat)
            case distance(CGFloat)
            case time(TimeInterval)
        }

        var path: PKStrokePath
        var range: ClosedRange<CGFloat>
        var stride: Stride
        var current: CGFloat
        var finished: Bool

        init(path: PKStrokePath, range: ClosedRange<CGFloat>, stride: Stride) {
            self.path = path
            self.range = range
            self.stride = stride
            self.current = range.lowerBound
            self.finished = path.points.isEmpty
        }

        public mutating func next() -> PKStrokePoint? {
            if finished { return nil }
            if current > range.upperBound {
                finished = true
                return nil
            }
            let point = path.interpolatedPoint(at: current)
            let nextParam: CGFloat
            switch stride {
            case .parametricStep(let step):
                if step <= 0 {
                    finished = true
                    return point
                }
                nextParam = current + step
            case .distance(let step):
                if step <= 0 {
                    finished = true
                    return point
                }
                nextParam = path.parametricValue(current, offsetBy: .distance(step))
            case .time(let step):
                if step <= 0 {
                    finished = true
                    return point
                }
                nextParam = path.parametricValue(current, offsetBy: .time(step))
            }
            if nextParam <= current {
                finished = true
            } else {
                current = nextParam
                if current > range.upperBound {
                    finished = true
                }
            }
            return point
        }

        public func makeIterator() -> PKStrokePath.InterpolatedSlice { self }
    }
}

open class PKStrokePathReference: NSObject {
    public var path: PKStrokePath

    public init(controlPoints: [PKStrokePoint], creationDate: Date) {
        self.path = PKStrokePath(controlPoints: controlPoints, creationDate: creationDate)
        super.init()
    }

    public var count: Int { path.count }
    public var creationDate: Date { path.creationDate }

    public subscript(i: Int) -> PKStrokePoint { path[i] }

    public func point(at i: Int) -> PKStrokePoint { path.point(at: i) }

    public func interpolatedPoint(at parametricValue: CGFloat) -> PKStrokePoint {
        path.interpolatedPoint(at: parametricValue)
    }

    public func interpolatedLocation(at parametricValue: CGFloat) -> CGPoint {
        path.interpolatedLocation(at: parametricValue)
    }

    public func parametricValue(_ parametricValue: CGFloat, offsetByDistance distanceStep: CGFloat) -> CGFloat {
        path.parametricValue(parametricValue, offsetByDistance: distanceStep)
    }

    public func parametricValue(_ parametricValue: CGFloat, offsetByTime timeStep: TimeInterval) -> CGFloat {
        path.parametricValue(parametricValue, offsetByTime: timeStep)
    }

    public func enumerateInterpolatedPoints(
        in range: __PKFloatRange,
        strideByDistance distanceStep: CGFloat,
        using block: @escaping (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        path.enumerateInterpolatedPoints(in: range, strideByDistance: distanceStep, using: block)
    }

    public func enumerateInterpolatedPoints(
        in range: __PKFloatRange,
        strideByParametricStep parametricStep: CGFloat,
        using block: @escaping (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        path.enumerateInterpolatedPoints(in: range, strideByParametricStep: parametricStep, using: block)
    }

    public func enumerateInterpolatedPoints(
        in range: __PKFloatRange,
        strideByTime timeStep: TimeInterval,
        using block: @escaping (PKStrokePoint, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        path.enumerateInterpolatedPoints(in: range, strideByTime: timeStep, using: block)
    }
}

public struct PKStroke: Equatable {
    public var ink: PKInk
    public var path: PKStrokePath
    public var transform: PencilKitTransform
    public var mask: PencilKitBezierPath?
    public var randomSeed: UInt32

    public init(
        ink: PKInk,
        path: PKStrokePath,
        transform: PencilKitTransform = .identity,
        mask: PencilKitBezierPath? = nil,
        randomSeed: UInt32
    ) {
        self.ink = ink
        self.path = path
        self.transform = transform
        self.mask = mask
        self.randomSeed = randomSeed
    }

    public init(
        ink: PKInk,
        path: PKStrokePath,
        transform: PencilKitTransform = .identity,
        mask: PencilKitBezierPath? = nil
    ) {
        self.init(ink: ink, path: path, transform: transform, mask: mask, randomSeed: 0)
    }

    public var requiredContentVersion: PKContentVersion {
        ink.requiredContentVersion
    }

    public var maskedPathRanges: [ClosedRange<CGFloat>] {
        []
    }

    public var renderBounds: CGRect {
        guard !path.isEmpty else { return .zero }
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for point in path {
            let mapped = pk_applyTransform(transform, to: point.location)
            let hx = max(point.size.width, 1) / 2
            let hy = max(point.size.height, 1) / 2
            minX = min(minX, mapped.x - hx)
            minY = min(minY, mapped.y - hy)
            maxX = max(maxX, mapped.x + hx)
            maxY = max(maxY, mapped.y + hy)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public static func == (lhs: PKStroke, rhs: PKStroke) -> Bool {
        lhs.ink == rhs.ink
            && lhs.path == rhs.path
            && pk_transformsEqual(lhs.transform, rhs.transform)
            && lhs.randomSeed == rhs.randomSeed
    }
}

open class PKStrokeReference: NSObject {
    public var stroke: PKStroke

    public init(
        ink: PKInk,
        strokePath: PKStrokePath,
        transform: PencilKitTransform,
        mask: PencilKitBezierPath?
    ) {
        self.stroke = PKStroke(ink: ink, path: strokePath, transform: transform, mask: mask)
        super.init()
    }

    public init(
        ink: PKInk,
        strokePath: PKStrokePath,
        transform: PencilKitTransform,
        mask: PencilKitBezierPath?,
        randomSeed: UInt32
    ) {
        self.stroke = PKStroke(
            ink: ink,
            path: strokePath,
            transform: transform,
            mask: mask,
            randomSeed: randomSeed
        )
        super.init()
    }

    public var ink: PKInk { stroke.ink }
    public var mask: PencilKitBezierPath? { stroke.mask }
    public var maskedPathRanges: [__PKFloatRange] {
        stroke.maskedPathRanges.map { pk_closedRangeToFloatRange($0) }
    }
    public var path: PKStrokePath { stroke.path }
    public var randomSeed: UInt32 { stroke.randomSeed }
    public var renderBounds: CGRect { stroke.renderBounds }
    public var requiredContentVersion: PKContentVersion { stroke.requiredContentVersion }
    public var transform: PencilKitTransform { stroke.transform }
}
