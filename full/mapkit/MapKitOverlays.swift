import Foundation

open class MKMultiPoint: MKShape, MKGeoJSONObject {
    private var storedPoints: [MKMapPoint]
    private var exportedPoints: UnsafeMutablePointer<MKMapPoint>?
    private var exportedCapacity = 0

    public override init() {
        self.storedPoints = []
        super.init()
    }

    init(points: [MKMapPoint]) {
        self.storedPoints = points
        super.init()
    }

    deinit {
        if let exportedPoints {
            exportedPoints.deinitialize(count: exportedCapacity)
            exportedPoints.deallocate()
        }
    }

    open func points() -> UnsafeMutablePointer<MKMapPoint> {
        if let exportedPoints {
            exportedPoints.deinitialize(count: exportedCapacity)
            exportedPoints.deallocate()
        }
        let count = max(storedPoints.count, 1)
        let pointer = UnsafeMutablePointer<MKMapPoint>.allocate(capacity: count)
        if storedPoints.isEmpty {
            pointer.initialize(to: MKMapPoint(x: 0, y: 0))
        } else {
            pointer.initialize(from: storedPoints, count: storedPoints.count)
        }
        exportedPoints = pointer
        exportedCapacity = count
        return pointer
    }

    open var pointCount: Int { storedPoints.count }

    func mapPoints() -> [MKMapPoint] { storedPoints }

    public var boundingMapRect: MKMapRect {
        mkBoundingRect(storedPoints)
    }
}

open class MKPolyline: MKMultiPoint, MKOverlay {
    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int) {
        let buffer = UnsafeBufferPointer(start: points, count: max(count, 0))
        self.init(points: Array(buffer))
    }
}

open class MKGeodesicPolyline: MKPolyline {}

open class MKPolygon: MKMultiPoint, MKOverlay {
    public private(set) var interiorPolygons: [MKPolygon]?

    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int) {
        let buffer = UnsafeBufferPointer(start: points, count: max(count, 0))
        self.init(points: Array(buffer))
        self.interiorPolygons = nil
    }

    public convenience init(
        points: UnsafePointer<MKMapPoint>,
        count: Int,
        interiorPolygons: [MKPolygon]?
    ) {
        let buffer = UnsafeBufferPointer(start: points, count: max(count, 0))
        self.init(points: Array(buffer))
        self.interiorPolygons = interiorPolygons
    }
}

open class MKCircle: MKShape, MKOverlay {
    public private(set) var boundingMapRect: MKMapRect
    public private(set) var radius: Double

    public convenience init(mapRect: MKMapRect) {
        self.init(boundingMapRect: mapRect)
    }

    public init(boundingMapRect: MKMapRect) {
        self.boundingMapRect = boundingMapRect
        let mid = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
        let latitude = mkCoordinate(for: mid).latitude
        let metersPerPoint = MKMetersPerMapPointAtLatitude(latitude)
        let mapRadius = min(abs(boundingMapRect.width), abs(boundingMapRect.height)) * 0.5
        self.radius = mapRadius * metersPerPoint
        super.init()
    }

    public init(centerMapPoint: MKMapPoint, radius: Double) {
        self.radius = radius
        let metersPerPoint = MKMetersPerMapPointAtLatitude(mkCoordinate(for: centerMapPoint).latitude)
        let mapRadius = metersPerPoint == 0 || !metersPerPoint.isFinite
            ? 0
            : radius / metersPerPoint
        self.boundingMapRect = MKMapRect(
            x: centerMapPoint.x - mapRadius,
            y: centerMapPoint.y - mapRadius,
            width: mapRadius * 2,
            height: mapRadius * 2
        )
        super.init()
    }
}

open class MKMultiPolyline: MKShape, MKOverlay, MKGeoJSONObject {
    public let polylines: [MKPolyline]

    public init(_ polylines: [MKPolyline]) {
        self.polylines = polylines
        super.init()
    }

    public convenience init(polylines: [MKPolyline]) {
        self.init(polylines)
    }

    public var boundingMapRect: MKMapRect {
        polylines.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
    }
}

open class MKMultiPolygon: MKShape, MKOverlay, MKGeoJSONObject {
    public let polygons: [MKPolygon]

    public init(_ polygons: [MKPolygon]) {
        self.polygons = polygons
        super.init()
    }

    public convenience init(polygons: [MKPolygon]) {
        self.init(polygons)
    }

    public var boundingMapRect: MKMapRect {
        polygons.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
    }
}

open class MKTileOverlay: NSObject, MKOverlay {
    open var title: String?
    open var subtitle: String?
    open var urlTemplate: String?
    open var canReplaceMapContent: Bool = false
    open var maximumZ: Int = 21
    open var minimumZ: Int = 0
    open var tileSize: CGSize = CGSize(width: 256, height: 256)
    open var isGeometryFlipped: Bool = false
    public var boundingMapRect: MKMapRect = .world

    public override init() {
        super.init()
    }

    public init(urlTemplate: String?) {
        self.urlTemplate = urlTemplate
        super.init()
    }

    open func url(forTilePath path: MKTileOverlayPath) -> URL {
        var template = urlTemplate ?? ""
        template = template.replacingOccurrences(of: "{x}", with: String(path.x))
        template = template.replacingOccurrences(of: "{y}", with: String(path.y))
        template = template.replacingOccurrences(of: "{z}", with: String(path.z))
        if let url = URL(string: template) {
            return url
        }
        return URL(string: "about:blank")!
    }

    open func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, (any Error)?) -> Void) {
        _ = path
        let gate = MKFailClosedGate(generation: 0)
        mk_finishOffQueue(gate: gate) {
            result(nil, mk_unsupportedServiceError(.unknown))
        }
    }
}

private func mkBoundingRect(_ points: [MKMapPoint]) -> MKMapRect {
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
