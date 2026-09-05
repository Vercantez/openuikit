import Foundation

open class VNContour: NSObject {
    public let indexPath: IndexPath
    public let normalizedPoints: [SIMD2<Float>]
    public let childContours: [VNContour]

    public var pointCount: Int { normalizedPoints.count }
    public var childContourCount: Int { childContours.count }

    public var normalizedPath: CGPath {
        visionPath(from: normalizedPoints)
    }

    public var aspectRatio: Float {
        guard let box = axisAlignedBounds(), box.height > 0 else { return 0 }
        return Float(box.width / box.height)
    }

    public init(
        normalizedPoints: [SIMD2<Float>],
        indexPath: IndexPath = IndexPath(index: 0),
        childContours: [VNContour] = []
    ) {
        self.normalizedPoints = normalizedPoints
        self.indexPath = indexPath
        self.childContours = childContours
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostPoints points: [VNPoint],
        indexPath: IndexPath = IndexPath(index: 0),
        childContours: [VNContour] = []
    ) {
        self.init(
            normalizedPoints: points.map { SIMD2<Float>(Float($0.x), Float($0.y)) },
            indexPath: indexPath,
            childContours: childContours
        )
    }

    public func childContour(at childContourIndex: Int) throws -> VNContour {
        guard childContours.indices.contains(childContourIndex) else {
            throw vnMakeError(.outOfBoundsError, description: "childContourIndex")
        }
        return childContours[childContourIndex]
    }

    public func polygonApproximation(epsilon: Float) throws -> VNContour {
        guard normalizedPoints.count >= 2 else {
            throw vnMakeError(.invalidArgument, description: "polygonApproximation needs two points")
        }
        let simplified = contourDouglasPeucker(normalizedPoints, epsilon: max(0, Double(epsilon)))
        return VNContour(
            normalizedPoints: simplified,
            indexPath: indexPath,
            childContours: []
        )
    }

    func vnPoints() -> [VNPoint] {
        normalizedPoints.map { VNPoint(x: Double($0.x), y: Double($0.y)) }
    }

    private func axisAlignedBounds() -> (width: Double, height: Double)? {
        guard let first = normalizedPoints.first else { return nil }
        var minX = Double(first.x)
        var maxX = Double(first.x)
        var minY = Double(first.y)
        var maxY = Double(first.y)
        for point in normalizedPoints.dropFirst() {
            minX = min(minX, Double(point.x))
            maxX = max(maxX, Double(point.x))
            minY = min(minY, Double(point.y))
            maxY = max(maxY, Double(point.y))
        }
        return (maxX - minX, maxY - minY)
    }
}

open class VNGeometryUtils: NSObject {
    public class func boundingCircle(for points: [VNPoint]) throws -> VNCircle {
        try minimumEnclosingCircle(points)
    }

    public class func boundingCircle(for contour: VNContour) throws -> VNCircle {
        try boundingCircle(for: contour.vnPoints())
    }

    public class func boundingCircle(
        forSIMDPoints points: UnsafePointer<SIMD2<Float>>,
        pointCount: Int
    ) throws -> VNCircle {
        guard pointCount >= 0 else {
            throw vnMakeError(.invalidArgument, description: "pointCount")
        }
        var converted: [VNPoint] = []
        converted.reserveCapacity(pointCount)
        for index in 0..<pointCount {
            let value = points.advanced(by: index).pointee
            converted.append(VNPoint(x: Double(value.x), y: Double(value.y)))
        }
        return try boundingCircle(for: converted)
    }

    public class func calculateArea(
        _ area: UnsafeMutablePointer<Double>,
        for contour: VNContour,
        orientedArea: Bool
    ) throws {
        let points = contour.vnPoints()
        guard points.count >= 3 else {
            throw vnMakeError(.invalidArgument, description: "area needs three points")
        }
        var sum: Double = 0
        for index in 0..<points.count {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            sum += current.x * next.y - next.x * current.y
        }
        let signed = sum / 2
        area.pointee = orientedArea ? signed : abs(signed)
    }

    public class func calculatePerimeter(
        _ perimeter: UnsafeMutablePointer<Double>,
        for contour: VNContour
    ) throws {
        let points = contour.vnPoints()
        guard points.count >= 2 else {
            throw vnMakeError(.invalidArgument, description: "perimeter needs two points")
        }
        var length: Double = 0
        for index in 0..<points.count {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            length += current.distance(next)
        }
        perimeter.pointee = length
    }
}

func minimumEnclosingCircle(_ points: [VNPoint]) throws -> VNCircle {
    if points.isEmpty {
        throw vnMakeError(.invalidArgument, description: "empty point set")
    }
    var unique: [VNPoint] = []
    unique.reserveCapacity(points.count)
    for point in points {
        if !unique.contains(where: { $0.x == point.x && $0.y == point.y }) {
            unique.append(point)
        }
    }
    if unique.count == 1 {
        return VNCircle(center: unique[0], radius: 0)
    }
    var shuffled = unique
    for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
        let swapIndex = Int.random(in: 0...index)
        shuffled.swapAt(index, swapIndex)
    }
    return welzl(points: shuffled, boundary: [])
}

private func welzl(points: [VNPoint], boundary: [VNPoint]) -> VNCircle {
    if boundary.count == 3 || points.isEmpty {
        return trivialCircle(boundary)
    }
    var remaining = points
    let point = remaining.removeLast()
    let circle = welzl(points: remaining, boundary: boundary)
    if circle.contains(point) {
        return circle
    }
    return welzl(points: remaining, boundary: boundary + [point])
}

private func trivialCircle(_ points: [VNPoint]) -> VNCircle {
    switch points.count {
    case 0:
        return .zero
    case 1:
        return VNCircle(center: points[0], radius: 0)
    case 2:
        return diameterCircle(points[0], points[1])
    default:
        return circleFromThree(points[0], points[1], points[2])
    }
}

private func diameterCircle(_ a: VNPoint, _ b: VNPoint) -> VNCircle {
    let center = VNPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    return VNCircle(center: center, radius: a.distance(b) / 2)
}

private func circleFromThree(_ a: VNPoint, _ b: VNPoint, _ c: VNPoint) -> VNCircle {
    let ab = a.distance(b)
    let bc = b.distance(c)
    let ca = c.distance(a)
    let longest = max(ab, max(bc, ca))
    if ab == longest && ab * ab >= bc * bc + ca * ca - 1e-15 {
        return diameterCircle(a, b)
    }
    if bc == longest && bc * bc >= ab * ab + ca * ca - 1e-15 {
        return diameterCircle(b, c)
    }
    if ca == longest && ca * ca >= ab * ab + bc * bc - 1e-15 {
        return diameterCircle(c, a)
    }
    let d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
    if abs(d) < 1e-18 {
        if ab >= bc && ab >= ca { return diameterCircle(a, b) }
        if bc >= ab && bc >= ca { return diameterCircle(b, c) }
        return diameterCircle(c, a)
    }
    let a2 = a.x * a.x + a.y * a.y
    let b2 = b.x * b.x + b.y * b.y
    let c2 = c.x * c.x + c.y * c.y
    let ux = (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / d
    let uy = (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / d
    let center = VNPoint(x: ux, y: uy)
    let radius = max(center.distance(a), max(center.distance(b), center.distance(c)))
    return VNCircle(center: center, radius: radius)
}

func contourDouglasPeucker(_ points: [SIMD2<Float>], epsilon: Double) -> [SIMD2<Float>] {
    if points.count <= 2 {
        return points
    }
    let start = points.first!
    let end = points.last!
    var maxDistance: Double = 0
    var maxIndex = 0
    for index in 1..<(points.count - 1) {
        let distance = perpendicularDistance(points[index], start, end)
        if distance > maxDistance {
            maxDistance = distance
            maxIndex = index
        }
    }
    if maxDistance > epsilon {
        let left = douglasPeucker(Array(points[0...maxIndex]), epsilon: epsilon)
        let right = douglasPeucker(Array(points[maxIndex...]), epsilon: epsilon)
        return left.dropLast() + right
    }
    return [start, end]
}

private func perpendicularDistance(
    _ point: SIMD2<Float>,
    _ start: SIMD2<Float>,
    _ end: SIMD2<Float>
) -> Double {
    let dx = Double(end.x - start.x)
    let dy = Double(end.y - start.y)
    if dx == 0 && dy == 0 {
        let px = Double(point.x - start.x)
        let py = Double(point.y - start.y)
        return (px * px + py * py).squareRoot()
    }
    let numerator = abs(dy * Double(point.x) - dx * Double(point.y) + Double(end.x) * Double(start.y) - Double(end.y) * Double(start.x))
    return numerator / (dx * dx + dy * dy).squareRoot()
}
