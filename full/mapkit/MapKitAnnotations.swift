import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif

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
}

public protocol MKGeoJSONObject: NSObjectProtocol {}

open class MKShape: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?

    public override init() {
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
    }
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
}

open class MKUserLocation: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    open var isUpdating: Bool { false }
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

    public init(featureType: FeatureType) {
        self.featureType = featureType
        super.init()
    }
}

open class MKMapItemAnnotation: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    public let mapItem: MKMapItem

    public init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init()
        self.title = mapItem.name
    }
}
