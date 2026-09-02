#if canImport(CoreLocation)
#if os(Linux)
@_spi(OpenUIKitHost) @preconcurrency import CoreLocation
#else
@preconcurrency import CoreLocation
#endif
#endif
import Foundation

public protocol MKAnnotation: NSObjectProtocol {
    var title: String? { get }
    var subtitle: String? { get }
#if canImport(CoreLocation)
    var coordinate: CLLocationCoordinate2D { get }
#endif
}

extension MKAnnotation {
    public var title: String? { nil }
    public var subtitle: String? { nil }
}

public protocol MKOverlay: MKAnnotation {
    var boundingMapRect: MKMapRect { get }
}

extension MKOverlay {
    public func intersects(_ mapRect: MKMapRect) -> Bool {
        boundingMapRect.intersects(mapRect)
    }

    public func canReplaceMapContent() -> Bool {
        false
    }

#if canImport(CoreLocation)
    public var coordinate: CLLocationCoordinate2D {
        let mid = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
        return mid.coordinate
    }
#endif
}

public protocol MKGeoJSONObject: NSObjectProtocol {}

open class MKShape: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
#if canImport(CoreLocation)
    open var coordinate: CLLocationCoordinate2D
#endif

    public override init() {
#if canImport(CoreLocation)
        self.coordinate = kCLLocationCoordinate2DInvalid
#endif
        super.init()
    }
}

open class MKPointAnnotation: MKShape, MKGeoJSONObject {
    public var mapPoint: MKMapPoint

    public override init() {
        self.mapPoint = MKMapPoint(x: 0, y: 0)
        super.init()
    }

    public init(mapPoint: MKMapPoint) {
        self.mapPoint = mapPoint
        super.init()
#if canImport(CoreLocation)
        super.coordinate = mapPoint.coordinate
#endif
    }

#if canImport(CoreLocation)
    open override var coordinate: CLLocationCoordinate2D {
        get { mapPoint.coordinate }
        set { mapPoint = MKMapPoint(newValue) }
    }
#endif
}

open class MKClusterAnnotation: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    private let _members: [any MKAnnotation]

    public init(memberAnnotations: [any MKAnnotation]) {
        self._members = memberAnnotations
        super.init()
    }

    open var memberAnnotations: [any MKAnnotation] { _members }

#if canImport(CoreLocation)
    open var coordinate: CLLocationCoordinate2D {
        let coords = _members.map(\.coordinate).filter { CLLocationCoordinate2DIsValid($0) }
        guard !coords.isEmpty else { return kCLLocationCoordinate2DInvalid }
        let latitude = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let longitude = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
#endif
}

open class MKUserLocation: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    open var isUpdating: Bool { false }
#if canImport(CoreLocation)
    open var location: CLLocation? { nil }
    open var heading: CLHeading? { nil }
    open var coordinate: CLLocationCoordinate2D {
        location?.coordinate ?? kCLLocationCoordinate2DInvalid
    }
#endif
}

open class MKMapFeatureAnnotation: NSObject, MKAnnotation {
    public enum FeatureType: Int, Hashable, Sendable {
        case pointOfInterest = 0
        case territory = 1
        case physicalFeature = 2
    }

    open var title: String?
    open var subtitle: String?
    public let featureType: FeatureType
    public var pointOfInterestCategory: MKPointOfInterestCategory?
    public var iconStyle: MKIconStyle?
#if canImport(CoreLocation)
    open var coordinate: CLLocationCoordinate2D
#endif

    /// Apple does not publish a general public initializer; this SPI exists so
    /// host tests can construct a feature annotation without inventing map data.
    @_spi(MapKitHostTests)
    public init(featureType: FeatureType) {
        self.featureType = featureType
#if canImport(CoreLocation)
        self.coordinate = kCLLocationCoordinate2DInvalid
#endif
        super.init()
    }
}

open class MKMapItemAnnotation: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    public let mapItem: MKMapItem

    public init?(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init()
        self.title = mapItem.name
    }

#if canImport(CoreLocation)
    open var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }
#endif
}
