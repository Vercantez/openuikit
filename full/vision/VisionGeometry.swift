//===----------------------------------------------------------------------===//
// Deterministic 2D geometry: VNPoint, VNVector, VNCircle, enclosing circle.
//===----------------------------------------------------------------------===//

open class VNPoint: NSObject, NSCopying, @unchecked Sendable {
    public let x: Double
    public let y: Double

    public var location: CGPoint {
        CGPoint(x: x, y: y)
    }

    public class var zero: VNPoint { VNPoint(x: 0, y: 0) }

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
        super.init()
    }

    public convenience init(location: CGPoint) {
        self.init(x: Double(location.x), y: Double(location.y))
    }

    public init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNPoint(x: x, y: y)
    }

    public func distance(_ point: VNPoint) -> Double {
        Self.distance(self, point)
    }

    public class func distance(_ point1: VNPoint, _ point2: VNPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return (dx * dx + dy * dy).squareRoot()
    }

    public class func apply(_ vector: VNVector, to point: VNPoint) -> VNPoint {
        VNPoint(x: point.x + vector.x, y: point.y + vector.y)
    }
}

open class VNVector: NSObject, NSCopying, @unchecked Sendable {
    public let x: Double
    public let y: Double

    public var length: Double { (x * x + y * y).squareRoot() }
    public var squaredLength: Double { x * x + y * y }
    public var r: Double { length }
    public var theta: Double { atan2(y, x) }

    public class var zero: VNVector { VNVector(xComponent: 0, yComponent: 0) }

    public init(xComponent x: Double, yComponent y: Double) {
        self.x = x
        self.y = y
        super.init()
    }

    public convenience init(XComponent x: Double, yComponent y: Double) {
        self.init(xComponent: x, yComponent: y)
    }

    public convenience init(r: Double, theta: Double) {
        self.init(xComponent: r * cos(theta), yComponent: r * sin(theta))
    }

    public convenience init(vectorHead head: VNPoint, tail: VNPoint) {
        self.init(xComponent: head.x - tail.x, yComponent: head.y - tail.y)
    }

    public init(byAdding v1: VNVector, to v2: VNVector) {
        self.x = v1.x + v2.x
        self.y = v1.y + v2.y
        super.init()
    }

    public convenience init(byAddingVector v1: VNVector, toVector v2: VNVector) {
        self.init(byAdding: v1, to: v2)
    }

    public init(bySubtracting v1: VNVector, from v2: VNVector) {
        self.x = v2.x - v1.x
        self.y = v2.y - v1.y
        super.init()
    }

    public convenience init(bySubtractingVector v1: VNVector, fromVector v2: VNVector) {
        self.init(bySubtracting: v1, from: v2)
    }

    public init(byMultiplying vector: VNVector, byScalar scalar: Double) {
        self.x = vector.x * scalar
        self.y = vector.y * scalar
        super.init()
    }

    public convenience init(byMultiplyingVector vector: VNVector, byScalar scalar: Double) {
        self.init(byMultiplying: vector, byScalar: scalar)
    }

    public init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNVector(xComponent: x, yComponent: y)
    }

    public class func dotProduct(of v1: VNVector, vector v2: VNVector) -> Double {
        v1.x * v2.x + v1.y * v2.y
    }

    public class func unitVector(for vector: VNVector) -> VNVector {
        let len = vector.length
        if len == 0 {
            return .zero
        }
        return VNVector(xComponent: vector.x / len, yComponent: vector.y / len)
    }
}

open class VNCircle: NSObject, NSCopying, @unchecked Sendable {
    public let center: VNPoint
    public let radius: Double

    public var diameter: Double { radius * 2 }

    public class var zero: VNCircle {
        VNCircle(center: .zero, radius: 0)
    }

    public init(center: VNPoint, radius: Double) {
        self.center = center
        self.radius = max(0, radius)
        super.init()
    }

    public convenience init(center: VNPoint, diameter: Double) {
        self.init(center: center, radius: diameter / 2)
    }

    public init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNCircle(center: center, radius: radius)
    }

    public func contains(_ point: VNPoint) -> Bool {
        VNPoint.distance(center, point) <= radius
    }

    public func contains(
        _ point: VNPoint,
        inCircumferentialRingOfWidth ringWidth: Double
    ) -> Bool {
        let distance = VNPoint.distance(center, point)
        let inner = max(0, radius - ringWidth)
        return distance >= inner && distance <= radius
    }
}

open class VNDetectedPoint: VNPoint, @unchecked Sendable {
    public let confidence: VNConfidence

    public init(x: Double, y: Double, confidence: VNConfidence) {
        self.confidence = confidence
        super.init(x: x, y: y)
    }

    public override init?(coder: NSCoder) {
        return nil
    }
}

open class VNRecognizedPoint: VNDetectedPoint, @unchecked Sendable {
    public let identifier: VNRecognizedPointKey

    public init(
        x: Double,
        y: Double,
        confidence: VNConfidence,
        identifier: VNRecognizedPointKey
    ) {
        self.identifier = identifier
        super.init(x: x, y: y, confidence: confidence)
    }

    public override init?(coder: NSCoder) {
        return nil
    }
}

open class VNGeometryUtils: NSObject, @unchecked Sendable {
    public class func boundingCircle(for points: [VNPoint]) throws -> VNCircle {
        guard !points.isEmpty else {
            throw visionError(.invalidArgument, "boundingCircle requires at least one point")
        }
        if points.count == 1 {
            return VNCircle(center: points[0], radius: 0)
        }
        var minX = points[0].x
        var maxX = points[0].x
        var minY = points[0].y
        var maxY = points[0].y
        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
        let center = VNPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        var radius: Double = 0
        for point in points {
            radius = max(radius, VNPoint.distance(center, point))
        }
        return VNCircle(center: center, radius: radius)
    }
}
