import Foundation

/// Public `MKGeometry` world size from Apple's Map Kit projection: 2^28 map
/// points. The numeric payload is the long-published `MKMapSizeWorld` value;
/// a central Apple-oracle probe should still confirm the live SDK constant.
private let mkWorldDimension: Double = 268_435_456.0

/// WGS-84 equatorial radius in meters, the conventional Map Kit scale used
/// with `MKMetersPerMapPointAtLatitude`. Exact live equality is an oracle
/// question.
private let mkEquatorialRadiusMeters: Double = 6_378_137.0

/// Mercator latitude limit implied by the Web Mercator projection.
private let mkMercatorMaxLatitude: Double = 85.0511287798066

public struct MKMapPoint: Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct MKMapSize: Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let world = MKMapSize(width: mkWorldDimension, height: mkWorldDimension)
}

public struct MKMapRect: Sendable {
    public var origin: MKMapPoint
    public var size: MKMapSize

    public init(origin: MKMapPoint, size: MKMapSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = MKMapPoint(x: x, y: y)
        self.size = MKMapSize(width: width, height: height)
    }

    public static let null = MKMapRect(
        origin: MKMapPoint(x: Double.infinity, y: Double.infinity),
        size: MKMapSize(width: 0, height: 0)
    )

    public static let world = MKMapRect(
        origin: MKMapPoint(x: 0, y: 0),
        size: MKMapSize.world
    )

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var width: Double { size.width }
    public var height: Double { size.height }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var midX: Double { origin.x + size.width * 0.5 }
    public var midY: Double { origin.y + size.height * 0.5 }

    public var isNull: Bool {
        !origin.x.isFinite || !origin.y.isFinite
    }

    public var isEmpty: Bool {
        isNull || size.width == 0 || size.height == 0
    }

    public var spans180thMeridian: Bool {
        guard !isNull else { return false }
        return maxX > MKMapSize.world.width
    }

    public var remainder: MKMapRect {
        guard spans180thMeridian else { return .null }
        let overflow = maxX - MKMapSize.world.width
        guard overflow > 0 else { return .null }
        return MKMapRect(x: 0, y: origin.y, width: overflow, height: size.height)
    }

    public func contains(_ point: MKMapPoint) -> Bool {
        guard !isNull, point.x.isFinite, point.y.isFinite else { return false }
        let (left, right) = mkOrdered(minX, maxX)
        let (top, bottom) = mkOrdered(minY, maxY)
        return point.x >= left && point.x <= right && point.y >= top && point.y <= bottom
    }

    public func contains(_ rect2: MKMapRect) -> Bool {
        guard !isNull, !rect2.isNull else { return false }
        if rect2.isEmpty {
            return contains(rect2.origin)
        }
        let (left, right) = mkOrdered(minX, maxX)
        let (top, bottom) = mkOrdered(minY, maxY)
        let (left2, right2) = mkOrdered(rect2.minX, rect2.maxX)
        let (top2, bottom2) = mkOrdered(rect2.minY, rect2.maxY)
        return left <= left2 && right >= right2 && top <= top2 && bottom >= bottom2
    }

    public func intersects(_ rect2: MKMapRect) -> Bool {
        mkNonEmptyOverlap(self, rect2)
    }

    public func intersection(_ rect2: MKMapRect) -> MKMapRect {
        if isNull || rect2.isNull { return .null }
        let (left1, right1) = mkOrdered(minX, maxX)
        let (left2, right2) = mkOrdered(rect2.minX, rect2.maxX)
        let (top1, bottom1) = mkOrdered(minY, maxY)
        let (top2, bottom2) = mkOrdered(rect2.minY, rect2.maxY)
        let left = max(left1, left2)
        let right = min(right1, right2)
        let top = max(top1, top2)
        let bottom = min(bottom1, bottom2)
        if left > right || top > bottom { return .null }
        return MKMapRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    public func union(_ rect2: MKMapRect) -> MKMapRect {
        if isNull { return rect2 }
        if rect2.isNull { return self }
        let (left1, right1) = mkOrdered(minX, maxX)
        let (left2, right2) = mkOrdered(rect2.minX, rect2.maxX)
        let (top1, bottom1) = mkOrdered(minY, maxY)
        let (top2, bottom2) = mkOrdered(rect2.minY, rect2.maxY)
        let left = min(left1, left2)
        let right = max(right1, right2)
        let top = min(top1, top2)
        let bottom = max(bottom1, bottom2)
        return MKMapRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    public func insetBy(dx: Double, dy: Double) -> MKMapRect {
        if isNull { return .null }
        guard dx.isFinite, dy.isFinite else { return .null }
        return MKMapRect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: size.width - dx * 2,
            height: size.height - dy * 2
        )
    }

    public func offsetBy(dx: Double, dy: Double) -> MKMapRect {
        if isNull { return .null }
        guard dx.isFinite, dy.isFinite else { return .null }
        return MKMapRect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: size.width,
            height: size.height
        )
    }
}

public struct MKCoordinateSpan: Sendable {
    public var latitudeDelta: Double
    public var longitudeDelta: Double

    public init(latitudeDelta: Double, longitudeDelta: Double) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct MKTileOverlayPath: Sendable {
    public var x: Int
    public var y: Int
    public var z: Int
    public var contentScaleFactor: CGFloat

    public init(x: Int, y: Int, z: Int, contentScaleFactor: CGFloat) {
        self.x = x
        self.y = y
        self.z = z
        self.contentScaleFactor = contentScaleFactor
    }
}

public func MKMapPointEqualToPoint(_ point1: MKMapPoint, _ point2: MKMapPoint) -> Bool {
    point1.x == point2.x && point1.y == point2.y
}

public func MKMapSizeEqualToSize(_ size1: MKMapSize, _ size2: MKMapSize) -> Bool {
    size1.width == size2.width && size1.height == size2.height
}

public func MKMapRectEqualToRect(_ rect1: MKMapRect, _ rect2: MKMapRect) -> Bool {
    if rect1.isNull && rect2.isNull { return true }
    return MKMapPointEqualToPoint(rect1.origin, rect2.origin)
        && MKMapSizeEqualToSize(rect1.size, rect2.size)
}

public func MKMapRectDivide(
    _ rect: MKMapRect,
    _ slice: UnsafeMutablePointer<MKMapRect>,
    _ remainder: UnsafeMutablePointer<MKMapRect>,
    _ amount: Double,
    _ edge: CGRectEdge
) {
    if rect.isNull || !amount.isFinite {
        slice.pointee = .null
        remainder.pointee = .null
        return
    }
    let amt = max(0, amount)
    switch edge {
    case .minXEdge:
        let width = min(amt, rect.size.width)
        slice.pointee = MKMapRect(x: rect.minX, y: rect.minY, width: width, height: rect.size.height)
        remainder.pointee = MKMapRect(
            x: rect.minX + width, y: rect.minY,
            width: rect.size.width - width, height: rect.size.height
        )
    case .maxXEdge:
        let width = min(amt, rect.size.width)
        slice.pointee = MKMapRect(
            x: rect.maxX - width, y: rect.minY,
            width: width, height: rect.size.height
        )
        remainder.pointee = MKMapRect(
            x: rect.minX, y: rect.minY,
            width: rect.size.width - width, height: rect.size.height
        )
    case .minYEdge:
        let height = min(amt, rect.size.height)
        slice.pointee = MKMapRect(x: rect.minX, y: rect.minY, width: rect.size.width, height: height)
        remainder.pointee = MKMapRect(
            x: rect.minX, y: rect.minY + height,
            width: rect.size.width, height: rect.size.height - height
        )
    case .maxYEdge:
        let height = min(amt, rect.size.height)
        slice.pointee = MKMapRect(
            x: rect.minX, y: rect.maxY - height,
            width: rect.size.width, height: height
        )
        remainder.pointee = MKMapRect(
            x: rect.minX, y: rect.minY,
            width: rect.size.width, height: rect.size.height - height
        )
    @unknown default:
        slice.pointee = .null
        remainder.pointee = .null
    }
}

public func MKStringFromMapPoint(_ point: MKMapPoint) -> String {
    "{\(mkFormat(point.x)), \(mkFormat(point.y))}"
}

public func MKStringFromMapSize(_ size: MKMapSize) -> String {
    "{\(mkFormat(size.width)), \(mkFormat(size.height))}"
}

public func MKStringFromMapRect(_ rect: MKMapRect) -> String {
    "{\(MKStringFromMapPoint(rect.origin)), \(MKStringFromMapSize(rect.size))}"
}

public func MKMetersPerMapPointAtLatitude(_ latitude: Double) -> Double {
    guard latitude.isFinite else { return Double.nan }
    let lat = mkClampLatitude(latitude)
    let metersPerPoint = (Double.pi * mkEquatorialRadiusMeters * cos(lat * Double.pi / 180.0))
        / MKMapSize.world.width
    return metersPerPoint
}

public func MKMapPointsPerMeterAtLatitude(_ latitude: Double) -> Double {
    let meters = MKMetersPerMapPointAtLatitude(latitude)
    guard meters.isFinite, meters != 0 else { return Double.nan }
    return 1.0 / meters
}

extension MKMapPoint {
    public func distance(to b: MKMapPoint) -> Double {
        guard x.isFinite, y.isFinite, b.x.isFinite, b.y.isFinite else {
            return Double.nan
        }
        let midY = (y + b.y) * 0.5
        let latitude = mkCoordinate(for: MKMapPoint(x: 0, y: midY)).latitude
        let metersPerPoint = MKMetersPerMapPointAtLatitude(latitude)
        let dx = b.x - x
        let dy = b.y - y
        return hypot(dx, dy) * metersPerPoint
    }
}

/// Test-only SPI for the Web Mercator projection used by this starting point.
/// Public `CLLocationCoordinate2D` wrappers live behind `canImport(CoreLocation)`.
@_spi(MapKitHostTests)
public enum MKMapProjection {
    public static func point(latitude: Double, longitude: Double) -> MKMapPoint {
        mkMapPoint(latitude: latitude, longitude: longitude)
    }

    public static func coordinate(for point: MKMapPoint) -> (latitude: Double, longitude: Double) {
        mkCoordinate(for: point)
    }
}

func mkMapPoint(latitude: Double, longitude: Double) -> MKMapPoint {
    guard latitude.isFinite, longitude.isFinite else {
        return MKMapPoint(x: Double.nan, y: Double.nan)
    }
    let lat = mkClampLatitude(latitude)
    var lon = longitude
    lon = fmod(lon + 180.0, 360.0)
    if lon < 0 { lon += 360.0 }
    lon -= 180.0
    let x = (lon + 180.0) / 360.0 * MKMapSize.world.width
    let latRad = lat * Double.pi / 180.0
    let sinLat = sin(latRad)
    let y = (0.5 - log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * Double.pi))
        * MKMapSize.world.height
    return MKMapPoint(x: x, y: y)
}

func mkCoordinate(for point: MKMapPoint) -> (latitude: Double, longitude: Double) {
    guard point.x.isFinite, point.y.isFinite else {
        return (Double.nan, Double.nan)
    }
    let world = MKMapSize.world.width
    var x = point.x
    x = x.truncatingRemainder(dividingBy: world)
    if x < 0 { x += world }
    let longitude = x / world * 360.0 - 180.0
    let n = Double.pi - 2.0 * Double.pi * point.y / world
    let latitude = 180.0 / Double.pi * atan(0.5 * (exp(n) - exp(-n)))
    return (latitude, longitude)
}

func mkClampLatitude(_ latitude: Double) -> Double {
    min(max(latitude, -mkMercatorMaxLatitude), mkMercatorMaxLatitude)
}

private func mkOrdered(_ a: Double, _ b: Double) -> (Double, Double) {
    a <= b ? (a, b) : (b, a)
}

private func mkNonEmptyOverlap(_ a: MKMapRect, _ b: MKMapRect) -> Bool {
    if a.isNull || b.isNull || a.isEmpty || b.isEmpty { return false }
    let (left1, right1) = mkOrdered(a.minX, a.maxX)
    let (left2, right2) = mkOrdered(b.minX, b.maxX)
    let (top1, bottom1) = mkOrdered(a.minY, a.maxY)
    let (top2, bottom2) = mkOrdered(b.minY, b.maxY)
    return left1 <= right2 && left2 <= right1 && top1 <= bottom2 && top2 <= bottom1
}

private func mkFormat(_ value: Double) -> String {
    if value.isNaN { return "nan" }
    if value == Double.infinity { return "inf" }
    if value == -Double.infinity { return "-inf" }
    return String(value)
}
