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

public protocol MKOverlay: MKAnnotation {
    var boundingMapRect: MKMapRect { get }
    func intersects(_ mapRect: MKMapRect) -> Bool
    func canReplaceMapContent() -> Bool
}

extension MKOverlay {
    public func intersects(_ mapRect: MKMapRect) -> Bool {
        boundingMapRect.intersects(mapRect)
    }

    public func canReplaceMapContent() -> Bool { false }
}

open class MKMultiPoint: MKShape {
    var storedPoints: [MKMapPoint] = []
    var storedLocations: [CGFloat] = []
    private var exportedPoints: UnsafeMutablePointer<MKMapPoint>?
    private var exportedCapacity = 0

    deinit {
        exportedPoints?.deallocate()
    }

    public var pointCount: Int { storedPoints.count }

    public func points() -> UnsafeMutablePointer<MKMapPoint> {
        if exportedCapacity != storedPoints.count || exportedPoints == nil {
            exportedPoints?.deallocate()
            exportedPoints = UnsafeMutablePointer<MKMapPoint>.allocate(capacity: max(storedPoints.count, 1))
            exportedCapacity = storedPoints.count
        }
        let pointer = exportedPoints!
        for (index, point) in storedPoints.enumerated() {
            pointer[index] = point
        }
        return pointer
    }

    public func getCoordinates(_ coords: UnsafeMutablePointer<CLLocationCoordinate2D>, range: NSRange) {
        let start = range.location
        let end = min(start + range.length, storedPoints.count)
        var output = 0
        var index = start
        while index < end {
            coords[output] = storedPoints[index].coordinate
            output += 1
            index += 1
        }
    }

    public func location(atPointIndex index: Int) -> CGFloat {
        if index >= 0 && index < storedLocations.count {
            return storedLocations[index]
        }
        if storedPoints.isEmpty { return 0 }
        return CGFloat(index) / CGFloat(max(storedPoints.count - 1, 1))
    }

    public func locations(at indexes: IndexSet) -> [CGFloat] {
        indexes.map { location(atPointIndex: $0) }
    }

    func install(points: [MKMapPoint]) {
        storedPoints = points
        if let first = points.first {
            coordinate = first.coordinate
        }
        storedLocations = points.enumerated().map { index, _ in
            CGFloat(index) / CGFloat(max(points.count - 1, 1))
        }
    }
}

open class MKPolyline: MKMultiPoint, MKOverlay {
    public var boundingMapRect: MKMapRect {
        boundingRect(of: storedPoints)
    }

    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int) {
        self.init()
        install(points: Array(UnsafeBufferPointer(start: points, count: count)))
    }

    public convenience init(coordinates coords: UnsafePointer<CLLocationCoordinate2D>, count: Int) {
        self.init()
        let coordinates = Array(UnsafeBufferPointer(start: coords, count: count))
        install(points: coordinates.map { MKMapPoint($0) })
    }
}

open class MKGeodesicPolyline: MKPolyline {
    public override init() {
        super.init()
    }

    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int) {
        let mapped = Array(UnsafeBufferPointer(start: points, count: count)).map { $0.coordinate }
        self.init()
        install(points: mk_densifyGeodesic(mapped).map { MKMapPoint($0) })
    }

    public convenience init(coordinates coords: UnsafePointer<CLLocationCoordinate2D>, count: Int) {
        let mapped = Array(UnsafeBufferPointer(start: coords, count: count))
        self.init()
        install(points: mk_densifyGeodesic(mapped).map { MKMapPoint($0) })
    }
}

open class MKPolygon: MKMultiPoint, MKOverlay {
    public private(set) var interiorPolygons: [MKPolygon]?
    public var boundingMapRect: MKMapRect { boundingRect(of: storedPoints) }

    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int) {
        self.init(points: points, count: count, interiorPolygons: nil)
    }

    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int, interiorPolygons: [MKPolygon]?) {
        self.init()
        install(points: Array(UnsafeBufferPointer(start: points, count: count)))
        self.interiorPolygons = interiorPolygons
    }

    public convenience init(coordinates coords: UnsafePointer<CLLocationCoordinate2D>, count: Int) {
        self.init(coordinates: coords, count: count, interiorPolygons: nil)
    }

    public convenience init(
        coordinates coords: UnsafePointer<CLLocationCoordinate2D>,
        count: Int,
        interiorPolygons: [MKPolygon]?
    ) {
        self.init()
        let coordinates = Array(UnsafeBufferPointer(start: coords, count: count))
        install(points: coordinates.map { MKMapPoint($0) })
        self.interiorPolygons = interiorPolygons
    }
}

open class MKCircle: MKShape, MKOverlay {
    public private(set) var radius: CLLocationDistance
    public private(set) var boundingMapRect: MKMapRect

    public override init() {
        radius = 0
        boundingMapRect = .null
        super.init()
    }

    public convenience init(center coord: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.init(centerCoordinate: coord, radius: radius)
    }

    public convenience init(centerCoordinate coord: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.init()
        coordinate = coord
        self.radius = radius
        let metersPerPoint = MKMetersPerMapPointAtLatitude(coord.latitude)
        let points = metersPerPoint > 0 ? radius / metersPerPoint : 0
        let center = MKMapPoint(coord)
        boundingMapRect = MKMapRect(
            x: center.x - points,
            y: center.y - points,
            width: points * 2,
            height: points * 2
        )
    }

    public convenience init(mapRect: MKMapRect) {
        let center = MKCoordinateForMapPoint(MKMapPoint(x: mapRect.midX, y: mapRect.midY))
        let meters = min(mapRect.width, mapRect.height) / 2 * MKMetersPerMapPointAtLatitude(center.latitude)
        self.init(centerCoordinate: center, radius: meters)
    }
}

open class MKMultiPolyline: MKShape, MKOverlay {
    public private(set) var polylines: [MKPolyline]

    public convenience init(_ polylines: [MKPolyline]) {
        self.init(polylines: polylines)
    }

    public init(polylines: [MKPolyline]) {
        self.polylines = polylines
        super.init()
        if let first = polylines.first {
            coordinate = first.coordinate
        }
    }

    public var boundingMapRect: MKMapRect {
        polylines.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
    }
}

open class MKMultiPolygon: MKShape, MKOverlay {
    public private(set) var polygons: [MKPolygon]

    public convenience init(_ polygons: [MKPolygon]) {
        self.init(polygons: polygons)
    }

    public init(polygons: [MKPolygon]) {
        self.polygons = polygons
        super.init()
        if let first = polygons.first {
            coordinate = first.coordinate
        }
    }

    public var boundingMapRect: MKMapRect {
        polygons.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
    }
}

open class MKTileOverlay: NSObject, MKOverlay {
    public private(set) var urlTemplate: String?
    open var canReplaceMapContent: Bool = false
    open var isGeometryFlipped: Bool = false
    open var maximumZ: Int = 21
    open var minimumZ: Int = 0
    open var tileSize: CGSize = CGSize(width: 256, height: 256)

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    public var boundingMapRect: MKMapRect { .world }

    public init(urlTemplate URLTemplate: String?) {
        urlTemplate = URLTemplate
        super.init()
    }

    public convenience init(URLTemplate: String?) {
        self.init(urlTemplate: URLTemplate)
    }

    open func url(forTilePath path: MKTileOverlayPath) -> URL {
        var template = urlTemplate ?? "about:blank"
        template = mk_replaceTemplate(template, key: "{z}", value: String(path.z))
        template = mk_replaceTemplate(template, key: "{x}", value: String(path.x))
        template = mk_replaceTemplate(template, key: "{y}", value: String(path.y))
        return URL(string: template) ?? URL(string: "about:blank")!
    }

    /// Tile bytes. Linux has no Apple tile server: fail closed.
    open func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        _ = path
        throw MKError(.serverFailure)
    }
}

private func boundingRect(of points: [MKMapPoint]) -> MKMapRect {
    guard let first = points.first else { return .null }
    var minX = first.x
    var minY = first.y
    var maxX = first.x
    var maxY = first.y
    for point in points.dropFirst() {
        minX = min(minX, point.x)
        minY = min(minY, point.y)
        maxX = max(maxX, point.x)
        maxY = max(maxY, point.y)
    }
    return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

func mk_densifyGeodesic(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
    guard !coordinates.isEmpty else { return [] }
    var densified: [CLLocationCoordinate2D] = [coordinates[0]]
    var index = 1
    while index < coordinates.count {
        densified.append(contentsOf: mk_geodesicSamples(from: coordinates[index - 1], to: coordinates[index]))
        densified.append(coordinates[index])
        index += 1
    }
    return densified
}

/// Darwin macOS 26.1 geodesic: 1° of equator is 113 points, 90° is 10020
/// points — `ceil(spherical metres / 1000) + 1` on a sphere of radius
/// `6378137` (WGS-84 semi-major), excluding the already-emitted start.
func mk_geodesicSamples(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
    let radius = 6_378_137.0
    let dist = mk_sphericalDistance(start, end, radius: radius)
    let count = max(2, Int(ceil(dist / 1000)) + 1)
    if count <= 2 { return [] }
    var samples: [CLLocationCoordinate2D] = []
    var index = 1
    while index < count - 1 {
        let t = Double(index) / Double(count - 1)
        samples.append(mk_sphericalInterpolate(start, end, t: t))
        index += 1
    }
    return samples
}

private func mk_sphericalDistance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, radius: Double) -> Double {
    let lat1 = a.latitude * .pi / 180
    let lat2 = b.latitude * .pi / 180
    let dLat = lat2 - lat1
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let s = sin(dLat / 2) * sin(dLat / 2)
        + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
    return 2 * radius * atan2(s.squareRoot(), (1 - s).squareRoot())
}

private func mk_sphericalInterpolate(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, t: Double) -> CLLocationCoordinate2D {
    let lat1 = a.latitude * .pi / 180
    let lon1 = a.longitude * .pi / 180
    let lat2 = b.latitude * .pi / 180
    let lon2 = b.longitude * .pi / 180
    let x1 = cos(lat1) * cos(lon1)
    let y1 = cos(lat1) * sin(lon1)
    let z1 = sin(lat1)
    let x2 = cos(lat2) * cos(lon2)
    let y2 = cos(lat2) * sin(lon2)
    let z2 = sin(lat2)
    let x = x1 + (x2 - x1) * t
    let y = y1 + (y2 - y1) * t
    let z = z1 + (z2 - z1) * t
    let hyp = (x * x + y * y).squareRoot()
    return CLLocationCoordinate2D(
        latitude: atan2(z, hyp) * 180 / .pi,
        longitude: atan2(y, x) * 180 / .pi
    )
}
