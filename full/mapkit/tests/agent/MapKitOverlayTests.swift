import Foundation
import MapKit

func testPolylinePolygonCircle() {
    var coords = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 0, longitude: 1)
    ]
    let line = MKPolyline(coordinates: &coords, count: 3)
    precondition(line.pointCount == 3)
    precondition(line.intersects(MKMapRect.world))
    precondition(!line.canReplaceMapContent())
    var buffer = Array(repeating: CLLocationCoordinate2D(), count: 3)
    line.getCoordinates(&buffer, range: NSRange(location: 0, length: 3))
    precondition(abs(buffer[0].latitude) < 1e-9)
    _ = line.location(atPointIndex: 1)
    _ = line.locations(at: IndexSet(integersIn: 0..<3))
    _ = line.points()
    _ = line.boundingMapRect
    let poly = MKPolygon(coordinates: &coords, count: 3)
    precondition(poly.pointCount == 3)
    _ = poly.interiorPolygons
    let inner = MKPolygon(coordinates: &coords, count: 3, interiorPolygons: [poly])
    _ = inner.interiorPolygons?.count
    var points = coords.map { MKMapPoint($0) }
    _ = MKPolyline(points: &points, count: 3)
    _ = MKPolygon(points: &points, count: 3)
    _ = MKPolygon(points: &points, count: 3, interiorPolygons: nil)
    let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 50)
    precondition(circle.radius == 50)
    _ = MKCircle(center: CLLocationCoordinate2D(latitude: 1, longitude: 1), radius: 10)
    _ = MKCircle(mapRect: MKMapRect(x: 0, y: 0, width: 1000, height: 1000))
    let multiLine = MKMultiPolyline([line])
    precondition(multiLine.polylines.count == 1)
    _ = MKMultiPolyline(polylines: [line])
    let multiPoly = MKMultiPolygon([poly])
    precondition(multiPoly.polygons.count == 1)
    _ = MKMultiPolygon(polygons: [poly])
    var geoPts = [MKMapPoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))]
    _ = MKGeodesicPolyline(points: &geoPts, count: 1)
}

func testOverlayRenderers() {
    var coords = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1)
    ]
    let line = MKPolyline(coordinates: &coords, count: 2)
    let lineRenderer = MKPolylineRenderer(polyline: line)
    lineRenderer.strokeStart = 0
    lineRenderer.strokeEnd = 1
    lineRenderer.lineWidth = 2
    lineRenderer.lineCap = .round
    lineRenderer.lineJoin = .bevel
    lineRenderer.miterLimit = 4
    lineRenderer.lineDashPhase = 1
    lineRenderer.lineDashPattern = [2, 4]
    lineRenderer.shouldRasterize = true
    lineRenderer.fillColor = .clear
    lineRenderer.strokeColor = .red
    lineRenderer.createPath()
    precondition(lineRenderer.path != nil)
    lineRenderer.invalidatePath()
    _ = lineRenderer.canDraw(MKMapRect.world, zoomScale: 1)
    _ = lineRenderer.point(for: MKMapPoint(x: 1, y: 2))
    _ = lineRenderer.mapPoint(for: CGPoint(x: 1, y: 2))
    _ = lineRenderer.rect(for: MKMapRect.world)
    _ = lineRenderer.mapRect(for: CGRect(x: 0, y: 0, width: 1, height: 1))
    lineRenderer.setNeedsDisplay()
    lineRenderer.setNeedsDisplay(MKMapRect.world)
    lineRenderer.setNeedsDisplay(MKMapRect.world, zoomScale: 1)
    lineRenderer.alpha = 0.5
    lineRenderer.blendMode = .normal
    _ = lineRenderer.contentScaleFactor
    let poly = MKPolygon(coordinates: &coords, count: 2)
    let polyRenderer = MKPolygonRenderer(polygon: poly)
    polyRenderer.strokeStart = 0
    polyRenderer.strokeEnd = 1
    polyRenderer.createPath()
    let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 10)
    let circleRenderer = MKCircleRenderer(circle: circle)
    circleRenderer.strokeStart = 0
    circleRenderer.strokeEnd = 1
    circleRenderer.createPath()
    let multiLine = MKMultiPolylineRenderer(multiPolyline: MKMultiPolyline([line]))
    multiLine.createPath()
    _ = multiLine.multiPolyline
    let multiPoly = MKMultiPolygonRenderer(multiPolygon: MKMultiPolygon([poly]))
    multiPoly.createPath()
    _ = multiPoly.multiPolygon
    let gradient = MKGradientPolylineRenderer(polyline: line)
    gradient.setColors([.red, .blue], locations: [0, 1])
    precondition(gradient.colors.count == 2)
    precondition(gradient.locations.count == 2)
    let tile = MKTileOverlay(urlTemplate: "https://example.com/{z}/{x}/{y}.png")
    precondition(mk_testContains(tile.url(forTilePath: MKTileOverlayPath(x: 1, y: 2, z: 3, contentScaleFactor: 1)).absoluteString, "3"))
    _ = MKTileOverlay(URLTemplate: nil)
    tile.canReplaceMapContent = true
    tile.isGeometryFlipped = true
    tile.maximumZ = 18
    tile.minimumZ = 1
    tile.tileSize = CGSize(width: 256, height: 256)
    _ = tile.urlTemplate
    _ = tile.boundingMapRect
    _ = tile.coordinate
    let tileRenderer = MKTileOverlayRenderer(tileOverlay: tile)
    tileRenderer.reloadData()
    _ = MKOverlayRenderer(overlay: line)
    _ = MKOverlayView(frame: .zero)
    _ = MKOverlayPathView(frame: .zero)
    _ = MKPolylineView(frame: .zero)
    _ = MKPolygonView(frame: .zero)
    _ = MKCircleView(frame: .zero)
#if canImport(CoreGraphics)
    if let space = CGColorSpace(name: CGColorSpace.sRGB),
       let ctx = CGContext(
        data: nil,
        width: 8,
        height: 8,
        bitsPerComponent: 8,
        bytesPerRow: 32,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
       )
    {
        lineRenderer.draw(MKMapRect.world, zoomScale: 1, in: ctx)
        lineRenderer.applyFillProperties(to: ctx, atZoomScale: 1)
        lineRenderer.applyStrokeProperties(to: ctx, atZoomScale: 1)
        if let path = lineRenderer.path {
            lineRenderer.strokePath(path, in: ctx)
            lineRenderer.fillPath(path, in: ctx)
        }
        tileRenderer.draw(MKMapRect.world, zoomScale: 1, in: ctx)
    }
#else
    let ctx = CGContext()
    lineRenderer.draw(MKMapRect.world, zoomScale: 1, in: ctx)
    lineRenderer.applyFillProperties(to: ctx, atZoomScale: 1)
    lineRenderer.applyStrokeProperties(to: ctx, atZoomScale: 1)
    if let path = lineRenderer.path {
        lineRenderer.strokePath(path, in: ctx)
        lineRenderer.fillPath(path, in: ctx)
    }
    tileRenderer.draw(MKMapRect.world, zoomScale: 1, in: ctx)
#endif
}

func testMapConfigurations() {
    let standard = MKStandardMapConfiguration(elevationStyle: .realistic, emphasisStyle: .muted)
    standard.showsTraffic = true
    standard.pointOfInterestFilter = .excludingAll
    precondition(standard.elevationStyle == .realistic)
    _ = MKStandardMapConfiguration()
    _ = MKStandardMapConfiguration(elevationStyle: .flat)
    _ = MKStandardMapConfiguration(emphasisStyle: .default)
    let hybrid = MKHybridMapConfiguration(elevationStyle: .flat)
    hybrid.showsTraffic = true
    hybrid.pointOfInterestFilter = .includingAll
    _ = MKHybridMapConfiguration()
    _ = MKImageryMapConfiguration()
    _ = MKImageryMapConfiguration(elevationStyle: .realistic)
    _ = MKMapConfiguration()
    let configCoder = try! NSKeyedUnarchiver(
        forReadingFrom: try! NSKeyedArchiver.archivedData(withRootObject: "x", requiringSecureCoding: false)
    )
    _ = MKMapConfiguration(coder: configCoder)
    let copied = standard.copy() as! MKMapConfiguration
    _ = copied.elevationStyle
}

func testControlsAndGeoJSON() {
    let map = MKMapView(frame: .zero)
    let compass = MKCompassButton(mapView: map)
    compass.compassVisibility = .visible
    compass.mapView = map
    let scale = MKScaleView(mapView: map)
    scale.legendAlignment = .center
    scale.scaleVisibility = .adaptive
    scale.mapView = map
    let tracking = MKUserTrackingButton(mapView: map)
    tracking.mapView = map
    let item = MKUserTrackingBarButtonItem(mapView: map)
    item.mapView = map
    do {
        _ = try MKGeoJSONDecoder().decode(Data())
        preconditionFailure("expected fail-closed decode")
    } catch let error as MKError {
        precondition(error.code == .decodingFailed)
    } catch {
        preconditionFailure("expected MKError")
    }
    let feature = MKGeoJSONFeature()
    feature.identifier = "id"
    feature.properties = Data()
    _ = feature.geometry
}
