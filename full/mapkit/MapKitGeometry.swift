import Foundation
#if canImport(CoreLocation)
#if os(Linux)
@_spi(OpenUIKitHost) @preconcurrency import CoreLocation
#else
@preconcurrency import CoreLocation
#endif
#endif

/// Public `MKGeometry` world size from Apple's Map Kit projection: 2^28 map
/// points. This payload and the edge-case algebra below are pinned by an iOS
/// 26.1 simulator oracle.
private let mkWorldDimension: Double = 268_435_456.0

/// WGS-84 equatorial radius used for map-point distance.
private let mkEquatorialRadiusMeters: Double = 6_378_137.0

/// Map Kit clamps valid coordinate input to 85 degrees before projection.
private let mkProjectionMaxLatitude: Double = 85.0

/// iOS 26.1 has stable, asymmetric results at the two exact geographic poles.
/// Preserve those observed public-function results instead of extending the
/// ordinary WGS-84 formula through a singularity.
private let mkNorthPoleMetersPerPoint: Double = 0.254_037_220_797_636_08
private let mkSouthPoleMetersPerPoint: Double = 0.000_416_774_906_744_502_91

/// Five-degree iOS/macOS 26.1 oracle samples over Map Kit's projected latitude
/// range. Linear interpolation avoids replacing the observed ellipsoidal curve
/// with the demonstrably-wrong spherical cosine shortcut. The final 85-degree
/// sample intentionally preserves Map Kit's near-pole discontinuity.
private let mkMetersPerPointSamples: [Double] = [
    0.148_289_773_337_725_44,
    0.147_736_725_459_890_89,
    0.146_081_030_604_107_4,
    0.143_333_059_012_292_76,
    0.139_510_170_788_160_61,
    0.134_636_818_982_238_7,
    0.128_744_671_638_204_97,
    0.121_872_732_046_303_99,
    0.114_067_432_628_807_27,
    0.105_382_675_513_326_13,
    0.095_879_792_040_637_485,
    0.085_627_394_029_882_689,
    0.074_701_090_708_174_683,
    0.063_183_043_789_721_671,
    0.051_161_318_089_686_623,
    0.038_728_904_874_921_345,
    0.025_981_817_044_788_295,
    0.027_389_836_522_547_215,
]

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
        origin.x == Double.infinity && origin.y == Double.infinity
    }

    public var isEmpty: Bool {
        isNull || size.width == 0 || size.height == 0
    }

    public var spans180thMeridian: Bool {
        guard !isNull else { return false }
        return minX < 0 || maxX > MKMapSize.world.width
    }

    public var remainder: MKMapRect {
        guard spans180thMeridian else { return .null }
        if minX < 0 {
            return MKMapRect(
                x: MKMapSize.world.width + minX,
                y: origin.y,
                width: -minX,
                height: size.height
            )
        }
        let overflow = maxX - MKMapSize.world.width
        return MKMapRect(x: 0, y: origin.y, width: overflow, height: size.height)
    }

    public func contains(_ point: MKMapPoint) -> Bool {
        guard !isNull else { return false }
        return point.x >= minX && point.x <= maxX
            && point.y >= minY && point.y <= maxY
    }

    public func contains(_ rect2: MKMapRect) -> Bool {
        guard !isNull, !rect2.isNull else { return false }
        return rect2.minX >= minX && rect2.maxX <= maxX
            && rect2.minY >= minY && rect2.maxY <= maxY
    }

    public func intersects(_ rect2: MKMapRect) -> Bool {
        mkNonEmptyOverlap(self, rect2)
    }

    public func intersection(_ rect2: MKMapRect) -> MKMapRect {
        if isNull || rect2.isNull { return .null }
        let left = max(minX, rect2.minX)
        let right = min(maxX, rect2.maxX)
        let top = max(minY, rect2.minY)
        let bottom = min(maxY, rect2.maxY)
        if left > right || top > bottom { return .null }
        return MKMapRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    public func union(_ rect2: MKMapRect) -> MKMapRect {
        if isNull { return rect2 }
        if rect2.isNull { return self }
        let left = min(minX, rect2.minX)
        let right = max(maxX, rect2.maxX)
        let top = min(minY, rect2.minY)
        let bottom = max(maxY, rect2.maxY)
        return MKMapRect(x: left, y: top, width: right - left, height: bottom - top)
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
    if rect.isNull {
        slice.pointee = .null
        remainder.pointee = .null
        return
    }
    switch edge {
    case .minXEdge:
        let width = mkDivideAmount(amount, dimension: rect.size.width)
        slice.pointee = MKMapRect(x: rect.minX, y: rect.minY, width: width, height: rect.size.height)
        remainder.pointee = MKMapRect(
            x: rect.minX + width, y: rect.minY,
            width: rect.size.width - width, height: rect.size.height
        )
    case .maxXEdge:
        let width = mkDivideAmount(amount, dimension: rect.size.width)
        slice.pointee = MKMapRect(
            x: rect.maxX - width, y: rect.minY,
            width: width, height: rect.size.height
        )
        remainder.pointee = MKMapRect(
            x: rect.minX, y: rect.minY,
            width: rect.size.width - width, height: rect.size.height
        )
    case .minYEdge:
        let height = mkDivideAmount(amount, dimension: rect.size.height)
        slice.pointee = MKMapRect(x: rect.minX, y: rect.minY, width: rect.size.width, height: height)
        remainder.pointee = MKMapRect(
            x: rect.minX, y: rect.minY + height,
            width: rect.size.width, height: rect.size.height - height
        )
    case .maxYEdge:
        let height = mkDivideAmount(amount, dimension: rect.size.height)
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
    if latitude == 90 { return mkNorthPoleMetersPerPoint }
    if latitude == -90 { return mkSouthPoleMetersPerPoint }
    let magnitude = abs(latitude)
    if magnitude > 90 { return Double.infinity }
    if magnitude >= 89.75 {
        return latitude.sign == .minus ? mkSouthPoleMetersPerPoint : mkNorthPoleMetersPerPoint
    }
    if magnitude >= 85.5 { return Double.infinity }
    if magnitude > 85 {
        if magnitude <= 85.25 {
            let fraction = (magnitude - 85) / 0.25
            return mkMetersPerPointSamples[17]
                + (0.053_509_138_661_681_242 - mkMetersPerPointSamples[17]) * fraction
        }
        let fraction = (magnitude - 85.25) / 0.24
        return 0.053_509_138_661_681_242
            + (1.306_754_000_470_966_8 - 0.053_509_138_661_681_242) * fraction
    }
    let position = magnitude / 5.0
    let lower = Int(position.rounded(.down))
    if lower >= mkMetersPerPointSamples.count - 1 {
        return mkMetersPerPointSamples[mkMetersPerPointSamples.count - 1]
    }
    let fraction = position - Double(lower)
    let low = mkMetersPerPointSamples[lower]
    let high = mkMetersPerPointSamples[lower + 1]
    return low + (high - low) * fraction
}

public func MKMapPointsPerMeterAtLatitude(_ latitude: Double) -> Double {
    let meters = MKMetersPerMapPointAtLatitude(latitude)
    if meters == Double.infinity { return 0 }
    guard meters.isFinite, meters != 0 else { return Double.nan }
    return 1.0 / meters
}

extension MKMapPoint {
    public func distance(to b: MKMapPoint) -> Double {
        guard x.isFinite, y.isFinite, b.x.isFinite, b.y.isFinite else {
            return Double.nan
        }
        let aCoordinate = mkCoordinate(for: self)
        let bCoordinate = mkCoordinate(for: b)
        guard aCoordinate.latitude.isFinite, aCoordinate.longitude.isFinite,
              bCoordinate.latitude.isFinite, bCoordinate.longitude.isFinite
        else {
            return Double.nan
        }
#if canImport(CoreLocation)
        let source = CLLocation(
            latitude: aCoordinate.latitude,
            longitude: aCoordinate.longitude
        )
        let destination = CLLocation(
            latitude: bCoordinate.latitude,
            longitude: bCoordinate.longitude
        )
        return source.distance(from: destination)
#else
        let latitude1 = aCoordinate.latitude * Double.pi / 180.0
        let latitude2 = bCoordinate.latitude * Double.pi / 180.0
        let deltaLatitude = latitude2 - latitude1
        var deltaLongitude = (bCoordinate.longitude - aCoordinate.longitude) * Double.pi / 180.0
        deltaLongitude = deltaLongitude.truncatingRemainder(dividingBy: 2.0 * Double.pi)
        if deltaLongitude > Double.pi { deltaLongitude -= 2.0 * Double.pi }
        if deltaLongitude < -Double.pi { deltaLongitude += 2.0 * Double.pi }
        let sinHalfLatitude = sin(deltaLatitude * 0.5)
        let sinHalfLongitude = sin(deltaLongitude * 0.5)
        let haversine = sinHalfLatitude * sinHalfLatitude
            + cos(latitude1) * cos(latitude2) * sinHalfLongitude * sinHalfLongitude
        return 2.0 * mkEquatorialRadiusMeters * asin(min(1.0, sqrt(max(0.0, haversine))))
#endif
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
    guard latitude.isFinite, longitude.isFinite,
          latitude >= -90, latitude <= 90,
          longitude >= -180, longitude <= 180
    else {
        return MKMapPoint(x: -1, y: -1)
    }
    let lat = mkClampLatitude(latitude)
    let x = (longitude + 180.0) / 360.0 * MKMapSize.world.width
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
    min(max(latitude, -mkProjectionMaxLatitude), mkProjectionMaxLatitude)
}

private func mkDivideAmount(_ amount: Double, dimension: Double) -> Double {
    if amount.isNaN { return Double.nan }
    if amount < 0 { return 0 }
    if amount > dimension { return dimension }
    return amount
}

private func mkNonEmptyOverlap(_ a: MKMapRect, _ b: MKMapRect) -> Bool {
    if a.isNull || b.isNull || a.isEmpty || b.isEmpty { return false }
    return a.minX < b.maxX && b.minX < a.maxX
        && a.minY < b.maxY && b.minY < a.maxY
}

private func mkFormat(_ value: Double) -> String {
    if value.isNaN { return "nan" }
    if value == Double.infinity { return "inf" }
    if value == -Double.infinity { return "-inf" }
    return String(value)
}
