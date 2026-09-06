import Foundation

public final class PHASENumericPair: NSObject {
    public var first: Double
    public var second: Double

    public init(firstValue first: Double, secondValue second: Double) {
        self.first = first
        self.second = second
        super.init()
    }
}

public final class PHASEEnvelopeSegment: NSObject {
    public var endPoint: simd_double2
    public var curveType: PHASECurveType

    public init(endPoint: simd_double2, curveType: PHASECurveType) {
        self.endPoint = endPoint
        self.curveType = curveType
        super.init()
    }
}

public final class PHASEEnvelope: NSObject {
    public let startPoint: simd_double2
    public let segments: [PHASEEnvelopeSegment]
    public let domain: PHASENumericPair
    public let range: PHASENumericPair

    public init?(startPoint: simd_double2, segments: [PHASEEnvelopeSegment]) {
        self.startPoint = startPoint
        self.segments = segments
        var xs = [startPoint.x]
        var ys = [startPoint.y]
        for segment in segments {
            xs.append(segment.endPoint.x)
            ys.append(segment.endPoint.y)
        }
        self.domain = PHASENumericPair(
            firstValue: xs.min() ?? startPoint.x,
            secondValue: xs.max() ?? startPoint.x
        )
        self.range = PHASENumericPair(
            firstValue: ys.min() ?? startPoint.y,
            secondValue: ys.max() ?? startPoint.y
        )
        super.init()
    }

    public func evaluate(x: Double) -> Double {
        var previous = startPoint
        if x <= previous.x {
            return previous.y
        }
        for segment in segments {
            let end = segment.endPoint
            if x <= end.x {
                let span = end.x - previous.x
                let t = span == 0 ? 1.0 : (x - previous.x) / span
                return previous.y + (end.y - previous.y) * phaseEase(t, segment.curveType)
            }
            previous = end
        }
        return previous.y
    }
}
