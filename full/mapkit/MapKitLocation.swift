#if canImport(CoreLocation)
#if os(Linux)
@_spi(OpenUIKitHost) @preconcurrency import CoreLocation
#else
@preconcurrency import CoreLocation
#endif
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

open class MKPlacemark: CLPlacemark, MKAnnotation, @unchecked Sendable {
    private let annotationCoordinate: CLLocationCoordinate2D

    public init(coordinate: CLLocationCoordinate2D) {
        self.annotationCoordinate = coordinate
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
#if os(Linux)
        super.init(location: location)
#else
        super.init()
        _ = location
#endif
    }

    public convenience init(
        coordinate: CLLocationCoordinate2D,
        addressDictionary: [String: Any]?
    ) {
        self.init(coordinate: coordinate)
        _ = addressDictionary
    }

    open var coordinate: CLLocationCoordinate2D { annotationCoordinate }

    open var countryCode: String? { isoCountryCode }
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
}

extension MKPointAnnotation {
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(mapPoint: MKMapPoint(coordinate))
    }

    public convenience init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.init(mapPoint: MKMapPoint(coordinate))
        self.title = title
        self.subtitle = subtitle
    }
}

extension MKMapItem {
    public convenience init(placemark: MKPlacemark) {
        self.init()
        self.name = placemark.name
        self.storedPlacemark = placemark
    }

    public convenience init(location: CLLocation, address: MKAddress?) {
        self.init(address: address)
        self.storedPlacemark = MKPlacemark(coordinate: location.coordinate)
    }

    public var placemark: MKPlacemark { storedPlacemark }
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

extension MKLocalSearchCompleter {
    public var region: MKCoordinateRegion {
        get { storedCompleterRegion }
        set { storedCompleterRegion = newValue }
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
    }

    public convenience init(center coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.init(centerMapPoint: MKMapPoint(coordinate), radius: radius)
    }

    public var coordinate: CLLocationCoordinate2D {
        storedCenterMapPoint.coordinate
    }

    public var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
        )
    }
}

extension MKGeocodingRequest {
    public var region: MKCoordinateRegion {
        get { storedGeocodeRegion }
        set { storedGeocodeRegion = newValue }
    }
}

extension MKReverseGeocodingRequest {
    public convenience init?(location: CLLocation) {
        self.init()
        storedLocation = location
    }

    public var location: CLLocation? { storedLocation }
}

extension MKLookAroundSceneRequest {
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init()
        storedCoordinate = coordinate
    }

    public convenience init(mapItem: MKMapItem) {
        self.init()
        storedMapItem = mapItem
    }

    public var coordinate: CLLocationCoordinate2D? { storedCoordinate }
}
#endif
