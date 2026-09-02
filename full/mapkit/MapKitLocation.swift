#if canImport(CoreLocation)
import CoreLocation
import Foundation

public struct MKCoordinateRegion: Sendable {
    public var center: CLLocationCoordinate2D
    public var span: MKCoordinateSpan

    public init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.center = center
        self.span = span
    }

    public init(_ rect: MKMapRect) {
        let mid = MKMapPoint(x: rect.midX, y: rect.midY)
        let coord = mkCoordinate(for: mid)
        let maxPoint = MKMapPoint(x: rect.maxX, y: rect.maxY)
        let minPoint = MKMapPoint(x: rect.minX, y: rect.minY)
        let maxCoord = mkCoordinate(for: maxPoint)
        let minCoord = mkCoordinate(for: minPoint)
        self.center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        self.span = MKCoordinateSpan(
            latitudeDelta: abs(maxCoord.latitude - minCoord.latitude),
            longitudeDelta: abs(maxCoord.longitude - minCoord.longitude)
        )
    }

    public init(
        center centerCoordinate: CLLocationCoordinate2D,
        latitudinalMeters: CLLocationDistance,
        longitudinalMeters: CLLocationDistance
    ) {
        self.center = centerCoordinate
        let pointsPerMeter = MKMapPointsPerMeterAtLatitude(centerCoordinate.latitude)
        let latDelta = (latitudinalMeters * pointsPerMeter) / MKMapSize.world.height * 360.0
        let lonDelta = (longitudinalMeters * pointsPerMeter) / MKMapSize.world.width * 360.0
        self.span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    }
}

extension MKMapPoint {
    public init(_ coordinate: CLLocationCoordinate2D) {
        let point = mkMapPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.init(x: point.x, y: point.y)
    }

    public var coordinate: CLLocationCoordinate2D {
        let pair = mkCoordinate(for: self)
        return CLLocationCoordinate2D(latitude: pair.latitude, longitude: pair.longitude)
    }
}

open class MKPlacemark: CLPlacemark, MKAnnotation {
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(coordinate: coordinate, addressDictionary: nil)
    }

    public convenience init(
        coordinate: CLLocationCoordinate2D,
        addressDictionary: [String: Any]?
    ) {
        _ = addressDictionary
        self.init()
        _ = coordinate
    }
}

extension MKCircle {
    public convenience init(center coord: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.init(centerMapPoint: MKMapPoint(coord), radius: radius)
    }

    public convenience init(
        centerCoordinate coord: CLLocationCoordinate2D,
        radius: CLLocationDistance
    ) {
        self.init(centerMapPoint: MKMapPoint(coord), radius: radius)
    }

    public var coordinate: CLLocationCoordinate2D {
        MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY).coordinate
    }
}

extension MKPointAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        get { mapPoint.coordinate }
        set { mapPoint = MKMapPoint(newValue) }
    }

    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(mapPoint: MKMapPoint(coordinate))
    }
}

extension MKMapItem {
    public convenience init(placemark: MKPlacemark) {
        self.init()
        self.name = placemark.name
    }

    public convenience init(location: CLLocation, address: MKAddress?) {
        self.init(address: address)
        _ = location
    }
}

extension MKMapCamera {
    public var centerCoordinate: CLLocationCoordinate2D {
        get { centerMapPoint.coordinate }
        set { centerMapPoint = MKMapPoint(newValue) }
    }

    public convenience init(
        lookingAtCenter centerCoordinate: CLLocationCoordinate2D,
        fromDistance distance: CLLocationDistance,
        pitch: CGFloat,
        heading: CLLocationDirection
    ) {
        self.init(
            lookingAtCenterMapPoint: MKMapPoint(centerCoordinate),
            fromDistance: distance,
            pitch: pitch,
            heading: heading
        )
    }

    public convenience init(
        lookingAtCenterCoordinate centerCoordinate: CLLocationCoordinate2D,
        fromDistance distance: CLLocationDistance,
        pitch: CGFloat,
        heading: CLLocationDirection
    ) {
        self.init(
            lookingAtCenter: centerCoordinate,
            fromDistance: distance,
            pitch: pitch,
            heading: heading
        )
    }
}

extension MKLocalSearch.Request {
    public var region: MKCoordinateRegion {
        get { storedRegion }
        set { storedRegion = newValue }
    }

    public convenience init(naturalLanguageQuery: String, region: MKCoordinateRegion) {
        self.init(naturalLanguageQuery: naturalLanguageQuery)
        self.region = region
    }
}

private var storedRegionKey: UInt8 = 0

extension MKLocalSearch.Request {
    fileprivate var storedRegion: MKCoordinateRegion {
        get {
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
            )
        }
        set { _ = newValue }
    }
}

extension MKLocalSearchCompleter {
    public var region: MKCoordinateRegion {
        get {
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
            )
        }
        set { _ = newValue }
    }
}

extension MKLocalSearch.Response {
    public var boundingRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
        )
    }
}

extension MKLocalPointsOfInterestRequest {
    public convenience init(coordinateRegion region: MKCoordinateRegion) {
        self.init(
            centerMapPoint: MKMapPoint(region.center),
            radius: MKLocalPointsOfInterestRequest.maxRadius
        )
        _ = region
    }

    public var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
        )
    }
}

extension MKGeocodingRequest {
    public var region: MKCoordinateRegion {
        get {
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
            )
        }
        set { _ = newValue }
    }
}

extension MKReverseGeocodingRequest {
    public convenience init?(location: CLLocation) {
        self.init()
        _ = location
    }

    public var location: CLLocation {
        CLLocation(latitude: 0, longitude: 0)
    }
}

extension MKLookAroundSceneRequest {
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init()
        _ = coordinate
    }

    public convenience init(mapItem: MKMapItem) {
        self.init()
        _ = mapItem
    }
}
#endif
