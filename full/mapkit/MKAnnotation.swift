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

public protocol MKAnnotation: AnyObject {
    var coordinate: CLLocationCoordinate2D { get }
    var title: String? { get }
    var subtitle: String? { get }
}

extension MKAnnotation {
    public var title: String? { nil }
    public var subtitle: String? { nil }
}

open class MKShape: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    open var coordinate: CLLocationCoordinate2D

    public override init() {
        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        super.init()
    }
}

open class MKPointAnnotation: MKShape {
    public override init() {
        super.init()
    }

    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init()
        self.coordinate = coordinate
    }

    public convenience init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.init(coordinate: coordinate)
        self.title = title
        self.subtitle = subtitle
    }
}

open class MKUserLocation: NSObject, MKAnnotation {
    open var location: CLLocation?
    open var heading: CLHeading?
    open var title: String?
    open var subtitle: String?
    open var isUpdating: Bool = false

    public var coordinate: CLLocationCoordinate2D {
        location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}

open class MKClusterAnnotation: NSObject, MKAnnotation {
    open var title: String?
    open var subtitle: String?
    public private(set) var memberAnnotations: [any MKAnnotation]

    public init(memberAnnotations: [any MKAnnotation]) {
        self.memberAnnotations = memberAnnotations
        super.init()
    }

    public var coordinate: CLLocationCoordinate2D {
        guard !memberAnnotations.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        var lat = 0.0
        var lon = 0.0
        for annotation in memberAnnotations {
            lat += annotation.coordinate.latitude
            lon += annotation.coordinate.longitude
        }
        let count = Double(memberAnnotations.count)
        return CLLocationCoordinate2D(latitude: lat / count, longitude: lon / count)
    }
}

open class MKMapItemAnnotation: NSObject, MKAnnotation {
    public let mapItem: MKMapItem

    public init?(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init()
    }

    public var coordinate: CLLocationCoordinate2D {
        mapItem.placemark.coordinate
    }

    public var title: String? { mapItem.name }
    public var subtitle: String? { mapItem.placemark.title }
}

open class MKMapFeatureAnnotation: NSObject, MKAnnotation {
    public enum FeatureType: Int, Sendable, Equatable, Hashable {
        case pointOfInterest = 0
        case territory = 1
        case physicalFeature = 2
    }

    open var coordinate: CLLocationCoordinate2D
    open var title: String?
    open var subtitle: String?
    open var featureType: FeatureType
    open var iconStyle: MKIconStyle?
    open var pointOfInterestCategory: MKPointOfInterestCategory?

    public override init() {
        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        featureType = .pointOfInterest
        super.init()
    }
}

open class MKIconStyle: NSObject {
    public var backgroundColor: UIColor
    public var image: UIImage

    public override init() {
        backgroundColor = .clear
        image = UIImage()
        super.init()
    }
}

open class MKAnnotationView: UIView {
    public enum CollisionMode: Int, Sendable, Equatable, Hashable {
        case rectangle = 0
        case circle = 1
        case none = 2
    }

    public enum DragState: UInt, Sendable, Equatable, Hashable {
        case none = 0
        case starting = 1
        case dragging = 2
        case canceling = 3
        case ending = 4
    }

    public private(set) var reuseIdentifier: String?
    open var annotation: (any MKAnnotation)?
    open var image: UIImage?
    open var centerOffset: CGPoint = .zero
    open var calloutOffset: CGPoint = .zero
    open var accessoryOffset: CGPoint = .zero
    open var canShowCallout: Bool = false
    open var leftCalloutAccessoryView: UIView?
    open var rightCalloutAccessoryView: UIView?
    open var detailCalloutAccessoryView: UIView?
    open var isEnabled: Bool = true
    open var isHighlighted: Bool = false
    open var isSelected: Bool = false
    open var isDraggable: Bool = false
    open var dragState: DragState = .none
    open var clusteringIdentifier: String?
    public private(set) weak var cluster: MKAnnotationView?
    open var displayPriority: MKFeatureDisplayPriority = .required
    open var collisionMode: CollisionMode = .rectangle
    open var zPriority: MKAnnotationViewZPriority = .defaultUnselected
    open var selectedZPriority: MKAnnotationViewZPriority = .defaultSelected

    public required init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        self.annotation = annotation
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func prepareForReuse() {
        isSelected = false
        isHighlighted = false
        dragState = .none
        cluster = nil
    }

    open func prepareForDisplay() {}

    open func setSelected(_ selected: Bool, animated: Bool) {
        _ = animated
        isSelected = selected
    }

    open func setDragState(_ newDragState: DragState, animated: Bool) {
        _ = animated
        dragState = newDragState
    }
}

open class MKMarkerAnnotationView: MKAnnotationView {
    open var markerTintColor: UIColor?
    open var glyphTintColor: UIColor?
    open var glyphText: String?
    open var glyphImage: UIImage?
    open var selectedGlyphImage: UIImage?
    open var titleVisibility: MKFeatureVisibility = .adaptive
    open var subtitleVisibility: MKFeatureVisibility = .adaptive
    open var animatesWhenAdded: Bool = false
}

open class MKPinAnnotationView: MKAnnotationView {
    open var pinColor: MKPinAnnotationColor = .red
    open var pinTintColor: UIColor! = .red
    open var animatesDrop: Bool = false

    open class func redPinColor() -> UIColor { .red }
    open class func greenPinColor() -> UIColor { .green }
    open class func purplePinColor() -> UIColor { .purple }
}

open class MKUserLocationView: MKAnnotationView {}
