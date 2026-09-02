#if canImport(UIKit)
import UIKit
#if canImport(CoreLocation)
@preconcurrency import CoreLocation
#endif

@MainActor
open class MKMapView: UIView {
    open weak var delegate: (any MKMapViewDelegate)?
    open var mapType: MKMapType = .standard
    open var isZoomEnabled = true
    open var isScrollEnabled = true
    open var isRotateEnabled = true
    open var isPitchEnabled = true
    open var showsCompass = true
    open var showsScale = false
    open var showsTraffic = false
    open var showsBuildings = true
    open var showsUserLocation = false
    open var isUserLocationVisible: Bool { false }
    open var visibleMapRect: MKMapRect = .world
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    open var preferredConfiguration: MKMapConfiguration = MKStandardMapConfiguration()
    open var camera: MKMapCamera = MKMapCamera()
    private var storedAnnotations: [any MKAnnotation] = []
    private var storedOverlays: [any MKOverlay] = []

#if canImport(CoreLocation)
    open var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    )

    open func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
        _ = animated
        self.region = region
    }
#endif

    open func setVisibleMapRect(_ mapRect: MKMapRect, animated animate: Bool) {
        _ = animate
        visibleMapRect = mapRect
    }

    open func setVisibleMapRect(
        _ mapRect: MKMapRect,
        edgePadding insets: UIEdgeInsets,
        animated animate: Bool
    ) {
        _ = (insets, animate)
        visibleMapRect = mapRect
    }

    open var annotations: [any MKAnnotation] { storedAnnotations }

    open func addAnnotation(_ annotation: any MKAnnotation) {
        storedAnnotations.append(annotation)
    }

    open func addAnnotations(_ annotations: [any MKAnnotation]) {
        storedAnnotations.append(contentsOf: annotations)
    }

    open func removeAnnotation(_ annotation: any MKAnnotation) {
        storedAnnotations.removeAll { ($0 as AnyObject) === (annotation as AnyObject) }
    }

    open func addOverlay(_ overlay: any MKOverlay) {
        storedOverlays.append(overlay)
    }

    open func addOverlays(_ overlays: [any MKOverlay]) {
        storedOverlays.append(contentsOf: overlays)
    }

    open var overlays: [any MKOverlay] { storedOverlays }

    open class CameraZoomRange: NSObject {
        open var minCenterCoordinateDistance: Double
        open var maxCenterCoordinateDistance: Double

        public override init() {
            self.minCenterCoordinateDistance = 0
            self.maxCenterCoordinateDistance = Double.infinity
            super.init()
        }

        public init(minCenterCoordinateDistance: Double, maxCenterCoordinateDistance: Double) {
            self.minCenterCoordinateDistance = minCenterCoordinateDistance
            self.maxCenterCoordinateDistance = maxCenterCoordinateDistance
            super.init()
        }
    }

    open class CameraBoundary: NSObject {
        public let mapRect: MKMapRect

        public init?(mapRect: MKMapRect) {
            guard !mapRect.isNull else { return nil }
            self.mapRect = mapRect
            super.init()
        }

#if canImport(CoreLocation)
        public init?(coordinateRegion region: MKCoordinateRegion) {
            self.mapRect = MKMapRect.world
            super.init()
            _ = region
        }

        public var region: MKCoordinateRegion {
            MKCoordinateRegion(mapRect)
        }
#endif
    }
}

@MainActor
public protocol MKMapViewDelegate: NSObjectProtocol {}

@MainActor
open class MKAnnotationView: UIView {
    public enum CollisionMode: Int, Hashable, Sendable {
        case rectangle = 0
        case circle = 1
        case none = 2
    }

    public enum DragState: UInt, Hashable, Sendable {
        case none = 0
        case starting = 1
        case dragging = 2
        case canceling = 3
        case ending = 4
    }

    open var annotation: (any MKAnnotation)?
    public let reuseIdentifier: String?
    open var canShowCallout = false
    open var isEnabled = true
    open var isHighlighted = false
    open var isSelected = false
    open var isDraggable = false
    open var dragState: DragState = .none
    open var collisionMode: CollisionMode = .rectangle
    open var clusteringIdentifier: String?
    open weak var cluster: MKAnnotationView?
    open var displayPriority: MKFeatureDisplayPriority = .required
    open var zPriority: MKAnnotationViewZPriority = .defaultUnselected
    open var selectedZPriority: MKAnnotationViewZPriority = .defaultSelected
    open var centerOffset: CGPoint = .zero
    open var calloutOffset: CGPoint = .zero
    open var accessoryOffset: CGPoint = .zero
    open var image: UIImage?
    open var leftCalloutAccessoryView: UIView?
    open var rightCalloutAccessoryView: UIView?
    open var detailCalloutAccessoryView: UIView?

    public init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        self.annotation = annotation
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: .zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.annotation = nil
        self.reuseIdentifier = nil
        super.init(coder: aDecoder)
    }

    open func prepareForReuse() {}
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

@MainActor
open class MKMarkerAnnotationView: MKAnnotationView {
    open var glyphText: String?
    open var glyphImage: UIImage?
    open var selectedGlyphImage: UIImage?
    open var glyphTintColor: UIColor?
    open var markerTintColor: UIColor?
    open var titleVisibility: MKFeatureVisibility = .adaptive
    open var subtitleVisibility: MKFeatureVisibility = .adaptive
    open var animatesWhenAdded = false
}

@MainActor
open class MKPinAnnotationView: MKAnnotationView {
    open var pinTintColor: UIColor?
    open var animatesDrop = false
    open class var redPinColor: UIColor { .red }
    open class var greenPinColor: UIColor { .green }
    open class var purplePinColor: UIColor { .purple }
}

@MainActor
open class MKUserLocationView: MKAnnotationView {}

@MainActor
open class MKOverlayView: UIView {
    public var overlay: (any MKOverlay)?
}

@MainActor
open class MKOverlayPathView: MKOverlayView {}

@MainActor
open class MKPolygonView: MKOverlayPathView {}

@MainActor
open class MKPolylineView: MKOverlayPathView {}

@MainActor
open class MKCircleView: MKOverlayPathView {}

@MainActor
open class MKCompassButton: UIView {
    open weak var mapView: MKMapView?
    open var compassVisibility: MKFeatureVisibility = .adaptive

    public convenience init(mapView: MKMapView?) {
        self.init(frame: .zero)
        self.mapView = mapView
    }
}

@MainActor
open class MKScaleView: UIView {
    public enum Alignment: Int, Hashable, Sendable {
        case leading = 0
        case trailing = 1
        case center = 2
    }

    open weak var mapView: MKMapView?
    open var scaleVisibility: MKFeatureVisibility = .adaptive
    open var legendAlignment: Alignment = .leading
}

@MainActor
open class MKUserTrackingButton: UIView {
    open weak var mapView: MKMapView?
}

@MainActor
open class MKUserTrackingBarButtonItem: UIBarButtonItem {
    public convenience init(mapView: MKMapView?) {
        self.init()
        _ = mapView
    }
}

@MainActor
open class MKLookAroundViewController: UIViewController {
    open weak var delegate: (any MKLookAroundViewControllerDelegate)?
    open var scene: MKLookAroundScene?
    open var isNavigationEnabled = true
    open var showsRoadLabels = true
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    open var badgePosition: MKLookAroundBadgePosition = .topLeading
}

@MainActor
public protocol MKLookAroundViewControllerDelegate: NSObjectProtocol {}

@MainActor
open class MKMapItemDetailViewController: UIViewController {
    open var mapItem: MKMapItem?
    open weak var delegate: (any MKMapItemDetailViewControllerDelegate)?

    public init(mapItem: MKMapItem?) {
        self.mapItem = mapItem
        super.init(nibName: nil, bundle: nil)
    }

    public init(mapItem: MKMapItem?, displaysMap: Bool) {
        self.mapItem = mapItem
        super.init(nibName: nil, bundle: nil)
        _ = displaysMap
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@MainActor
public protocol MKMapItemDetailViewControllerDelegate: NSObjectProtocol {
    func mapItemDetailViewControllerDidFinish(_ detailViewController: MKMapItemDetailViewController)
}
#endif
