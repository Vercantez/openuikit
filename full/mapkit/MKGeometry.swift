import Foundation

/// World size in map points, matching the public `MKGeometry` constant
/// `0x10000000` recorded by the pinned macios bindings.
private let mapWorldExtent: Double = 0x10000000

/// Equatorial circumference used for Linux Mercator meter conversion.
/// Not an Apple-oracle ellipsoid.
private let equatorialCircumferenceMeters: Double = 40_075_016.68557849

public struct MKMapPoint: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init() {
        x = 0
        y = 0
    }

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// Euclidean map-point distance scaled by meters-per-point at the equator.
    /// Linux Mercator stand-in; not an Apple-oracle geodesic.
    public func distance(to b: MKMapPoint) -> Double {
        let dx = x - b.x
        let dy = y - b.y
        return (dx * dx + dy * dy).squareRoot() * MKMetersPerMapPointAtLatitude(0)
    }
}

public struct MKMapSize: Equatable, Hashable, Sendable {
    public var width: Double
    public var height: Double

    public init() {
        width = 0
        height = 0
    }

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let world = MKMapSize(width: mapWorldExtent, height: mapWorldExtent)
}

public struct MKMapRect: Equatable, Hashable, Sendable {
    public var origin: MKMapPoint
    public var size: MKMapSize

    public init() {
        origin = MKMapPoint()
        size = MKMapSize()
    }

    public init(origin: MKMapPoint, size: MKMapSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        origin = MKMapPoint(x: x, y: y)
        size = MKMapSize(width: width, height: height)
    }

    public static let null = MKMapRect(
        x: Double.infinity,
        y: Double.infinity,
        width: 0,
        height: 0
    )

    public static let world = MKMapRect(
        x: 0,
        y: 0,
        width: mapWorldExtent,
        height: mapWorldExtent
    )

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var midX: Double { origin.x + size.width / 2 }
    public var midY: Double { origin.y + size.height / 2 }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var width: Double { size.width }
    public var height: Double { size.height }

    public var isNull: Bool {
        origin.x.isInfinite || origin.y.isInfinite
    }

    public var isEmpty: Bool {
        isNull || size.width == 0 || size.height == 0
    }

    public var spans180thMeridian: Bool {
        !isNull && maxX > mapWorldExtent
    }

    public var remainder: MKMapRect {
        guard spans180thMeridian else { return .null }
        return MKMapRect(
            x: origin.x - mapWorldExtent,
            y: origin.y,
            width: size.width,
            height: size.height
        )
    }

    public func contains(_ point: MKMapPoint) -> Bool {
        let rect = standardized
        return point.x >= rect.minX
            && point.x < rect.maxX
            && point.y >= rect.minY
            && point.y < rect.maxY
    }

    public func contains(_ rect2: MKMapRect) -> Bool {
        if isNull || rect2.isNull { return false }
        let a = standardized
        let b = rect2.standardized
        return b.minX >= a.minX
            && b.maxX <= a.maxX
            && b.minY >= a.minY
            && b.maxY <= a.maxY
    }

    public func intersects(_ rect2: MKMapRect) -> Bool {
        if isNull || rect2.isNull { return false }
        let a = standardized
        let b = rect2.standardized
        return a.minX < b.maxX
            && b.minX < a.maxX
            && a.minY < b.maxY
            && b.minY < a.maxY
    }

    public func intersection(_ rect2: MKMapRect) -> MKMapRect {
        guard intersects(rect2) else { return .null }
        let a = standardized
        let b = rect2.standardized
        let minX = max(a.minX, b.minX)
        let minY = max(a.minY, b.minY)
        let maxX = min(a.maxX, b.maxX)
        let maxY = min(a.maxY, b.maxY)
        return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public func union(_ rect2: MKMapRect) -> MKMapRect {
        if isNull { return rect2 }
        if rect2.isNull { return self }
        let a = standardized
        let b = rect2.standardized
        let minX = min(a.minX, b.minX)
        let minY = min(a.minY, b.minY)
        let maxX = max(a.maxX, b.maxX)
        let maxY = max(a.maxY, b.maxY)
        return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public func insetBy(dx: Double, dy: Double) -> MKMapRect {
        if isNull { return .null }
        return MKMapRect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: size.width - dx * 2,
            height: size.height - dy * 2
        )
    }

    public func offsetBy(dx: Double, dy: Double) -> MKMapRect {
        if isNull { return .null }
        return MKMapRect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: size.width,
            height: size.height
        )
    }

    private var standardized: MKMapRect {
        var rect = self
        if rect.size.width < 0 {
            rect.origin.x += rect.size.width
            rect.size.width = -rect.size.width
        }
        if rect.size.height < 0 {
            rect.origin.y += rect.size.height
            rect.size.height = -rect.size.height
        }
        return rect
    }
}

public struct MKCoordinateSpan: Equatable, Hashable, Sendable {
    public var latitudeDelta: Double
    public var longitudeDelta: Double

    public init() {
        latitudeDelta = 0
        longitudeDelta = 0
    }

    public init(latitudeDelta: Double, longitudeDelta: Double) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct MKTileOverlayPath: Equatable, Hashable, Sendable {
    public var x: Int
    public var y: Int
    public var z: Int
    public var contentScaleFactor: CGFloat

    public init() {
        x = 0
        y = 0
        z = 0
        contentScaleFactor = 1
    }

    public init(x: Int, y: Int, z: Int, contentScaleFactor: CGFloat) {
        self.x = x
        self.y = y
        self.z = z
        self.contentScaleFactor = contentScaleFactor
    }
}

public func MKMapPointEqualToPoint(_ point1: MKMapPoint, _ point2: MKMapPoint) -> Bool {
    point1 == point2
}

public func MKMapSizeEqualToSize(_ size1: MKMapSize, _ size2: MKMapSize) -> Bool {
    size1 == size2
}

public func MKMapRectEqualToRect(_ rect1: MKMapRect, _ rect2: MKMapRect) -> Bool {
    if rect1.isNull && rect2.isNull { return true }
    return rect1 == rect2
}

public func MKStringFromMapPoint(_ point: MKMapPoint) -> String {
    "{\(point.x), \(point.y)}"
}

public func MKStringFromMapSize(_ size: MKMapSize) -> String {
    "{\(size.width), \(size.height)}"
}

public func MKStringFromMapRect(_ rect: MKMapRect) -> String {
    "{\(MKStringFromMapPoint(rect.origin)), \(MKStringFromMapSize(rect.size))}"
}

public func MKMetersPerMapPointAtLatitude(_ latitude: Double) -> Double {
    let lat = max(-85.05112878, min(85.05112878, latitude))
    let metersAtEquator = equatorialCircumferenceMeters / mapWorldExtent
    return metersAtEquator * cos(lat * .pi / 180)
}

public func MKMapPointsPerMeterAtLatitude(_ latitude: Double) -> Double {
    let meters = MKMetersPerMapPointAtLatitude(latitude)
    return meters > 0 ? 1 / meters : 0
}
