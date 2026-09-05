import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#endif

/// World size in map points. Darwin MapKit macOS 26.1:
/// `MKMapSize.world.width == 268435456` (`0x10000000`).
private let mapWorldExtent: Double = 0x10000000

/// Web Mercator maximum latitude, in degrees. Darwin
/// `MKMapPoint(CLLocationCoordinate2D(latitude: 85.05112878, longitude: 0)).y`
/// is 439674.40 (not zero); this is the spherical-mercator pole.
private let mercatorMaxLatitude: Double = 85.05112878

/// WGS-84 semi-major axis and first eccentricity squared. Darwin
/// `MKCoordinateRegion(center:latitudinalMeters:longitudinalMeters:)` at
/// `(0°,0°)` / 1000 m / 2000 m is span
/// `(0.009043695025814083, 0.017966310975031877)` (macOS 26.1): longitude
/// uses `(π/180)·a·cosφ`, latitude uses `(π/180)·a(1−e²)/(1−e²sin²φ)^{3/2}`.
private let wgs84A: Double = 6_378_137
private let wgs84E2: Double = 6.6943799901413165e-3
private let darwinMetersPerMapPointEquator: Double = 0.14828977333772544
/// First eccentricity squared implied by Darwin macOS 26.1 samples
/// `MKMetersPerMapPointAtLatitude(0) == 0.14828977333772544` and
/// `MKMetersPerMapPointAtLatitude(60) == 0.07470109070817468` under
/// `m(φ) = m(0) · |cos φ| / (1 − e² sin²φ)^{3/2}` (meridional radius shape).
private let darwinMetersPerMapPointE2: Double = 0.006626665788433665

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
    /// Darwin `MKMapPoint.distance(to:)` uses the same equator scale
    /// (`MKMetersPerMapPointAtLatitude(0)`, macOS 26.1).
    public func distance(to b: MKMapPoint) -> Double {
        let dx = x - b.x
        let dy = y - b.y
        return (dx * dx + dy * dy).squareRoot() * MKMetersPerMapPointAtLatitude(0)
    }

    /// Spherical Web Mercator. Darwin `MKMapPoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))`
    /// is `(134217728, 134217728)` (macOS 26.1).
    public init(_ coordinate: CLLocationCoordinate2D) {
        let projected = MKMapPointForCoordinate(coordinate)
        x = projected.x
        y = projected.y
    }

    public var coordinate: CLLocationCoordinate2D {
        MKCoordinateForMapPoint(self)
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
    public var latitudeDelta: CLLocationDegrees
    public var longitudeDelta: CLLocationDegrees

    public init() {
        latitudeDelta = 0
        longitudeDelta = 0
    }

    public init(latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct MKCoordinateRegion: Equatable, Hashable, Sendable {
    public var center: CLLocationCoordinate2D
    public var span: MKCoordinateSpan

    public init() {
        center = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        span = MKCoordinateSpan()
    }

    public init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.center = center
        self.span = span
    }

    /// Darwin `MKCoordinateRegion(MKMapRect.world)` is center `(0, 0)` and
    /// span `(170.10225755961318, 360)` (macOS 26.1).
    public init(_ rect: MKMapRect) {
        self = MKCoordinateRegionForMapRect(rect)
    }

    /// Darwin `MKCoordinateRegion(center:latitudinalMeters:longitudinalMeters:)`
    /// at `(0,0)` / 1000 m / 2000 m yields span
    /// `(0.009043695025814083, 0.017966310975031877)` (macOS 26.1).
    public init(
        center centerCoordinate: CLLocationCoordinate2D,
        latitudinalMeters: CLLocationDistance,
        longitudinalMeters: CLLocationDistance
    ) {
        self = MKCoordinateRegionMakeWithDistance(
            centerCoordinate, latitudinalMeters, longitudinalMeters
        )
    }

    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude
            && lhs.center.longitude == rhs.center.longitude
            && lhs.span == rhs.span
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(center.latitude)
        hasher.combine(center.longitude)
        hasher.combine(span)
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
    // WGS-84 meridional radius of curvature M(φ) times cos(φ), divided by
    // the mercator world size. Darwin macOS 26.1:
    // MKMetersPerMapPointAtLatitude(0) == 0.14828977333772544
    // MKMetersPerMapPointAtLatitude(60) == 0.07470109070817468
    let phi = latitude * .pi / 180
    let sinPhi = sin(phi)
    let denom = (1 - darwinMetersPerMapPointE2 * sinPhi * sinPhi)
    return darwinMetersPerMapPointEquator * cos(phi).magnitude / (denom * denom.squareRoot())
}

public func MKMapPointsPerMeterAtLatitude(_ latitude: Double) -> Double {
    let meters = MKMetersPerMapPointAtLatitude(latitude)
    return meters > 0 ? 1 / meters : 0
}

public func MKMapPointForCoordinate(_ coordinate: CLLocationCoordinate2D) -> MKMapPoint {
    let lon = coordinate.longitude
    let lat = max(-mercatorMaxLatitude, min(mercatorMaxLatitude, coordinate.latitude))
    let x = (lon + 180) / 360 * mapWorldExtent
    let sinLat = sin(lat * .pi / 180)
    let y = (0.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * .pi)) * mapWorldExtent
    return MKMapPoint(x: x, y: y)
}

public func MKCoordinateForMapPoint(_ mapPoint: MKMapPoint) -> CLLocationCoordinate2D {
    let lon = mapPoint.x / mapWorldExtent * 360 - 180
    let n = .pi - 2 * .pi * mapPoint.y / mapWorldExtent
    let lat = 180 / .pi * atan(0.5 * (exp(n) - exp(-n)))
    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
}

public func MKCoordinateRegionForMapRect(_ rect: MKMapRect) -> MKCoordinateRegion {
    if rect.isNull || rect.isEmpty {
        return MKCoordinateRegion()
    }
    let centerPoint = MKMapPoint(x: rect.midX, y: rect.midY)
    let nw = MKCoordinateForMapPoint(rect.origin)
    let se = MKCoordinateForMapPoint(MKMapPoint(x: rect.maxX, y: rect.maxY))
    var latDelta = (nw.latitude - se.latitude).magnitude
    var lonDelta = (se.longitude - nw.longitude)
    if lonDelta < 0 { lonDelta += 360 }
    if latDelta > 180 { latDelta = 180 }
    if lonDelta > 360 { lonDelta = 360 }
    return MKCoordinateRegion(
        center: MKCoordinateForMapPoint(centerPoint),
        span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
}

public func MKMapRectForCoordinateRegion(_ region: MKCoordinateRegion) -> MKMapRect {
    let halfLat = region.span.latitudeDelta / 2
    let halfLon = region.span.longitudeDelta / 2
    let nw = MKMapPointForCoordinate(
        CLLocationCoordinate2D(
            latitude: region.center.latitude + halfLat,
            longitude: region.center.longitude - halfLon
        )
    )
    let se = MKMapPointForCoordinate(
        CLLocationCoordinate2D(
            latitude: region.center.latitude - halfLat,
            longitude: region.center.longitude + halfLon
        )
    )
    return MKMapRect(
        x: min(nw.x, se.x),
        y: min(nw.y, se.y),
        width: abs(se.x - nw.x),
        height: abs(se.y - nw.y)
    )
}

public func MKCoordinateRegionMakeWithDistance(
    _ centerCoordinate: CLLocationCoordinate2D,
    _ latitudinalMeters: CLLocationDistance,
    _ longitudinalMeters: CLLocationDistance
) -> MKCoordinateRegion {
    // Darwin macOS 26.1: (0°,0°) / 1000 m / 2000 m →
    // latitudeDelta 0.009043695025814083, longitudeDelta 0.017966310975031877.
    let phi = centerCoordinate.latitude * .pi / 180
    let sinPhi = sin(phi)
    let denom = (1 - wgs84E2 * sinPhi * sinPhi).squareRoot()
    let primeVertical = wgs84A / denom
    let meridional = wgs84A * (1 - wgs84E2) / (denom * denom * denom)
    let metersPerDegreeLat = meridional * .pi / 180
    let metersPerDegreeLon = primeVertical * cos(phi).magnitude * .pi / 180
    let latDelta = metersPerDegreeLat > 0 ? latitudinalMeters / metersPerDegreeLat : 0
    let lonDelta = metersPerDegreeLon > 0 ? longitudinalMeters / metersPerDegreeLon : 0
    return MKCoordinateRegion(
        center: centerCoordinate,
        span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
}

public func MKMapRectDivide(
    _ rect: MKMapRect,
    _ slice: UnsafeMutablePointer<MKMapRect>,
    _ remainder: UnsafeMutablePointer<MKMapRect>,
    _ amount: Double,
    _ edge: CGRectEdge
) {
    // Darwin macOS 26.1: dividing (10,20,30,40) by 10 on minXEdge yields
    // slice (10,20,10,40) remainder (20,20,20,40).
    var sliceRect = MKMapRect()
    var remainderRect = rect
    switch edge {
    case .minXEdge:
        sliceRect = MKMapRect(x: rect.minX, y: rect.minY, width: amount, height: rect.height)
        remainderRect = MKMapRect(x: rect.minX + amount, y: rect.minY, width: rect.width - amount, height: rect.height)
    case .maxXEdge:
        sliceRect = MKMapRect(x: rect.maxX - amount, y: rect.minY, width: amount, height: rect.height)
        remainderRect = MKMapRect(x: rect.minX, y: rect.minY, width: rect.width - amount, height: rect.height)
    case .minYEdge:
        sliceRect = MKMapRect(x: rect.minX, y: rect.minY, width: rect.width, height: amount)
        remainderRect = MKMapRect(x: rect.minX, y: rect.minY + amount, width: rect.width, height: rect.height - amount)
    case .maxYEdge:
        sliceRect = MKMapRect(x: rect.minX, y: rect.maxY - amount, width: rect.width, height: amount)
        remainderRect = MKMapRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - amount)
    @unknown default:
        break
    }
    slice.pointee = sliceRect
    remainder.pointee = remainderRect
}

/// Darwin macOS 26.1 `MKRoadWidthAtZoomScale`:
/// `z >= 0.75` is `21/z`; `z == 0` is `inf`; power-of-two samples below
/// 0.75 are the table in this function (1 → 21, 0.5 → 32, 0.25 → 60,
/// 0.125 → 96, 0.0625 → 176, 0.03125 → 288, 0.015625 → 448).
public func MKRoadWidthAtZoomScale(_ zoomScale: MKZoomScale) -> CGFloat {
    if zoomScale <= 0 { return .infinity }
    if zoomScale >= 0.75 { return 21 / zoomScale }
    let table: [(CGFloat, CGFloat)] = [
        (0.015625, 448),
        (0.03125, 288),
        (0.0625, 176),
        (0.125, 96),
        (0.25, 60),
        (0.5, 32),
        (0.75, 28)
    ]
    if zoomScale <= table[0].0 { return table[0].1 }
    for index in 1..<table.count {
        let lo = table[index - 1]
        let hi = table[index]
        if zoomScale <= hi.0 {
            let t = (zoomScale - lo.0) / (hi.0 - lo.0)
            return lo.1 + (hi.1 - lo.1) * t
        }
    }
    return 21 / zoomScale
}

func mk_clampedRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
    var center = region.center
    if center.latitude > 90 { center.latitude = 90 }
    if center.latitude < -90 { center.latitude = -90 }
    var lon = center.longitude
    while lon > 180 { lon -= 360 }
    while lon < -180 { lon += 360 }
    center.longitude = lon
    var latDelta = region.span.latitudeDelta
    var lonDelta = region.span.longitudeDelta
    if latDelta < 0 { latDelta = 0 }
    if lonDelta < 0 { lonDelta = 0 }
    if latDelta > 170.10225755961318 { latDelta = 170.10225755961318 }
    if lonDelta > 360 { lonDelta = 360 }
    return MKCoordinateRegion(
        center: center,
        span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
}
