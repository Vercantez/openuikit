import Foundation

open class VNPoint: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let x: Double
    public let y: Double

    public var location: CGPoint {
        CGPoint(x: x, y: y)
    }

    public class var zero: VNPoint {
        VNPoint(x: 0, y: 0)
    }

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
        super.init()
    }

    public convenience init(location: CGPoint) {
        self.init(x: Double(location.x), y: Double(location.y))
    }

    public required init?(coder: NSCoder) {
        x = coder.decodeDouble(forKey: "x")
        y = coder.decodeDouble(forKey: "y")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(x, forKey: "x")
        coder.encode(y, forKey: "y")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        VNPoint(x: x, y: y)
    }

    public class func distance(_ point1: VNPoint, _ point2: VNPoint) -> Double {
        point1.distance(point2)
    }

    public func distance(_ point: VNPoint) -> Double {
        let dx = x - point.x
        let dy = y - point.y
        return (dx * dx + dy * dy).squareRoot()
    }

    public class func apply(_ vector: VNVector, to point: VNPoint) -> VNPoint {
        VNPoint(x: point.x + vector.x, y: point.y + vector.y)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VNPoint else { return false }
        return x == other.x && y == other.y
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(x)
        hasher.combine(y)
        return hasher.finalize()
    }
}

open class VNDetectedPoint: VNPoint {
    public let confidence: VNConfidence

    public init(x: Double, y: Double, confidence: VNConfidence) {
        self.confidence = confidence
        super.init(x: x, y: y)
    }

    public required init?(coder: NSCoder) {
        confidence = Float(coder.decodeDouble(forKey: "confidence"))
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(confidence), forKey: "confidence")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        VNDetectedPoint(x: x, y: y, confidence: confidence)
    }
}

open class VNVector: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let x: Double
    public let y: Double

    public class var zero: VNVector {
        VNVector(xComponent: 0, yComponent: 0)
    }

    public var length: Double {
        (x * x + y * y).squareRoot()
    }

    public var squaredLength: Double {
        x * x + y * y
    }

    public var r: Double { length }

    public var theta: Double {
        atan2(y, x)
    }

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
        x = v1.x + v2.x
        y = v1.y + v2.y
        super.init()
    }

    public convenience init(byAddingVector v1: VNVector, toVector v2: VNVector) {
        self.init(byAdding: v1, to: v2)
    }

    public init(bySubtracting v1: VNVector, from v2: VNVector) {
        x = v2.x - v1.x
        y = v2.y - v1.y
        super.init()
    }

    public convenience init(bySubtractingVector v1: VNVector, fromVector v2: VNVector) {
        self.init(bySubtracting: v1, from: v2)
    }

    public init(byMultiplying vector: VNVector, byScalar scalar: Double) {
        x = vector.x * scalar
        y = vector.y * scalar
        super.init()
    }

    public convenience init(byMultiplyingVector vector: VNVector, byScalar scalar: Double) {
        self.init(byMultiplying: vector, byScalar: scalar)
    }

    public class func dotProduct(of v1: VNVector, vector v2: VNVector) -> Double {
        v1.x * v2.x + v1.y * v2.y
    }

    public class func unitVector(for vector: VNVector) -> VNVector {
        let length = vector.length
        if length == 0 {
            return .zero
        }
        return VNVector(xComponent: vector.x / length, yComponent: vector.y / length)
    }

    public required init?(coder: NSCoder) {
        x = coder.decodeDouble(forKey: "x")
        y = coder.decodeDouble(forKey: "y")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(x, forKey: "x")
        coder.encode(y, forKey: "y")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNVector(xComponent: x, yComponent: y)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VNVector else { return false }
        return x == other.x && y == other.y
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(x)
        hasher.combine(y)
        return hasher.finalize()
    }
}

open class VNCircle: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

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

    public func contains(_ point: VNPoint) -> Bool {
        center.distance(point) <= radius
    }

    /// Linux annulus: a point lies in the ring when `|d − r| ≤ ringWidth`.
    /// Apple's circumferential placement is unobserved here.
    public func contains(_ point: VNPoint, inCircumferentialRingOfWidth ringWidth: Double) -> Bool {
        let width = max(0, ringWidth)
        let distance = center.distance(point)
        return abs(distance - radius) <= width
    }

    public required init?(coder: NSCoder) {
        let x = coder.decodeDouble(forKey: "cx")
        let y = coder.decodeDouble(forKey: "cy")
        center = VNPoint(x: x, y: y)
        radius = coder.decodeDouble(forKey: "radius")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(center.x, forKey: "cx")
        coder.encode(center.y, forKey: "cy")
        coder.encode(radius, forKey: "radius")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNCircle(center: center, radius: radius)
    }
}

public func VNNormalizedRectIsIdentityRect(_ normalizedRect: CGRect) -> Bool {
    normalizedRect.origin.x == 0
        && normalizedRect.origin.y == 0
        && normalizedRect.size.width == 1
        && normalizedRect.size.height == 1
}

public func VNImagePointForNormalizedPoint(
    _ normalizedPoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    CGPoint(
        x: normalizedPoint.x * CGFloat(imageWidth),
        y: normalizedPoint.y * CGFloat(imageHeight)
    )
}

public func VNNormalizedPointForImagePoint(
    _ imagePoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    let width = max(imageWidth, 1)
    let height = max(imageHeight, 1)
    return CGPoint(
        x: imagePoint.x / CGFloat(width),
        y: imagePoint.y / CGFloat(height)
    )
}

public func VNImageRectForNormalizedRect(
    _ normalizedRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGRect {
    let origin = VNImagePointForNormalizedPoint(normalizedRect.origin, imageWidth, imageHeight)
    return CGRect(
        x: origin.x,
        y: origin.y,
        width: normalizedRect.width * CGFloat(imageWidth),
        height: normalizedRect.height * CGFloat(imageHeight)
    )
}

public func VNNormalizedRectForImageRect(
    _ imageRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGRect {
    let origin = VNNormalizedPointForImagePoint(imageRect.origin, imageWidth, imageHeight)
    let width = max(imageWidth, 1)
    let height = max(imageHeight, 1)
    return CGRect(
        x: origin.x,
        y: origin.y,
        width: imageRect.width / CGFloat(width),
        height: imageRect.height / CGFloat(height)
    )
}

public func VNImagePointForNormalizedPointUsingRegionOfInterest(
    _ normalizedPoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGPoint {
    let mapped = CGPoint(
        x: roi.origin.x + normalizedPoint.x * roi.size.width,
        y: roi.origin.y + normalizedPoint.y * roi.size.height
    )
    return VNImagePointForNormalizedPoint(mapped, imageWidth, imageHeight)
}

public func VNNormalizedPointForImagePointUsingRegionOfInterest(
    _ imagePoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGPoint {
    let normalized = VNNormalizedPointForImagePoint(imagePoint, imageWidth, imageHeight)
    let width = roi.size.width == 0 ? 1 : roi.size.width
    let height = roi.size.height == 0 ? 1 : roi.size.height
    return CGPoint(
        x: (normalized.x - roi.origin.x) / width,
        y: (normalized.y - roi.origin.y) / height
    )
}

public func VNImageRectForNormalizedRectUsingRegionOfInterest(
    _ normalizedRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGRect {
    let origin = VNImagePointForNormalizedPointUsingRegionOfInterest(
        normalizedRect.origin,
        imageWidth,
        imageHeight,
        roi
    )
    return CGRect(
        x: origin.x,
        y: origin.y,
        width: normalizedRect.width * roi.size.width * CGFloat(imageWidth),
        height: normalizedRect.height * roi.size.height * CGFloat(imageHeight)
    )
}

public func VNNormalizedRectForImageRectUsingRegionOfInterest(
    _ imageRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGRect {
    let origin = VNNormalizedPointForImagePointUsingRegionOfInterest(
        imageRect.origin,
        imageWidth,
        imageHeight,
        roi
    )
    let width = roi.size.width == 0 ? 1 : roi.size.width
    let height = roi.size.height == 0 ? 1 : roi.size.height
    return CGRect(
        x: origin.x,
        y: origin.y,
        width: (imageRect.width / CGFloat(max(imageWidth, 1))) / width,
        height: (imageRect.height / CGFloat(max(imageHeight, 1))) / height
    )
}

public func VNImagePointForFaceLandmarkPoint(
    _ faceLandmarkPoint: SIMD2<Float>,
    _ faceBoundingBox: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    let normalized = CGPoint(
        x: faceBoundingBox.origin.x + CGFloat(faceLandmarkPoint.x) * faceBoundingBox.size.width,
        y: faceBoundingBox.origin.y + CGFloat(faceLandmarkPoint.y) * faceBoundingBox.size.height
    )
    return VNImagePointForNormalizedPoint(normalized, imageWidth, imageHeight)
}

public func VNNormalizedFaceBoundingBoxPointForLandmarkPoint(
    _ faceLandmarkPoint: SIMD2<Float>,
    _ faceBoundingBox: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    _ = imageWidth
    _ = imageHeight
    return CGPoint(
        x: faceBoundingBox.origin.x + CGFloat(faceLandmarkPoint.x) * faceBoundingBox.size.width,
        y: faceBoundingBox.origin.y + CGFloat(faceLandmarkPoint.y) * faceBoundingBox.size.height
    )
}
