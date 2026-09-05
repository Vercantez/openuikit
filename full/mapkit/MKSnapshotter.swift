import Dispatch
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

open class MKMapSnapshotter: NSObject {
    public typealias CompletionHandler = (Snapshot?, (any Error)?) -> Void

    open class Snapshot: NSObject {
        open var image: UIImage = UIImage()
        open var traitCollection: UITraitCollection = UITraitCollection()

        open func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
            let mapPoint = MKMapPoint(coordinate)
            return CGPoint(x: CGFloat(mapPoint.x), y: CGFloat(mapPoint.y))
        }
    }

    open class Options: NSObject {
        open var camera: MKMapCamera = MKMapCamera()
        open var mapRect: MKMapRect = .world
        open var region: MKCoordinateRegion = MKCoordinateRegion()
        open var mapType: MKMapType = .standard
        open var size: CGSize = CGSize(width: 256, height: 256)
        open var scale: CGFloat = 1
        open var showsBuildings: Bool = true
        open var showsPointsOfInterest: Bool = true
        open var pointOfInterestFilter: MKPointOfInterestFilter?
        open var preferredConfiguration: MKMapConfiguration = MKStandardMapConfiguration()
        open var traitCollection: UITraitCollection = UITraitCollection()
    }

    public private(set) var isLoading: Bool = false
    private let options: Options

    public init(options: Options) {
        self.options = options
        super.init()
    }

    open func start(completionHandler: @escaping CompletionHandler) {
        isLoading = false
        completionHandler(nil, MKError(.serverFailure))
    }

    open func start(with queue: DispatchQueue) async throws -> Snapshot {
        _ = queue
        throw MKError(.serverFailure)
    }

    open func cancel() {
        isLoading = false
    }
}

open class MKLookAroundScene: NSObject, NSCopying {
    public override init() { super.init() }
    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MKLookAroundScene()
    }
}

open class MKLookAroundSceneRequest: NSObject {
    public private(set) var coordinate: CLLocationCoordinate2D?
    public private(set) var mapItem: MKMapItem?
    public private(set) var isCancelled: Bool = false
    public private(set) var isLoading: Bool = false

    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }

    public init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init()
    }

    open func cancel() {
        isCancelled = true
        isLoading = false
    }

    open func getSceneWithCompletionHandler(
        _ completionHandler: @escaping (MKLookAroundScene?, (any Error)?) -> Void
    ) {
        isLoading = false
        completionHandler(nil, MKError(.serverFailure))
    }
}

open class MKLookAroundSnapshotter: NSObject {
    open class Snapshot: NSObject {
        open var image: UIImage = UIImage()
    }

    open class Options: NSObject {
        open var size: CGSize = CGSize(width: 256, height: 256)
        open var traitCollection: UITraitCollection = UITraitCollection()
        open var pointOfInterestFilter: MKPointOfInterestFilter?
    }

    public private(set) var isLoading: Bool = false

    public init(scene: MKLookAroundScene, options: Options) {
        _ = (scene, options)
        super.init()
    }

    open func cancel() {
        isLoading = false
    }

    open func getSnapshotWithCompletionHandler(
        _ completionHandler: @escaping (Snapshot?, (any Error)?) -> Void
    ) {
        isLoading = false
        completionHandler(nil, MKError(.serverFailure))
    }
}

open class MKLookAroundViewController: UIViewController {
    open weak var delegate: (any MKLookAroundViewControllerDelegate)?
    open var scene: MKLookAroundScene?
    open var badgePosition: MKLookAroundBadgePosition = .topLeading
    open var isNavigationEnabled: Bool = true
    open var showsRoadLabels: Bool = true
    open var pointOfInterestFilter: MKPointOfInterestFilter?

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public init(scene: MKLookAroundScene) {
        self.scene = scene
        super.init(nibName: nil, bundle: nil)
    }
}

public protocol MKLookAroundViewControllerDelegate: AnyObject {
    func lookAroundViewControllerWillUpdateScene(_ viewController: MKLookAroundViewController)
    func lookAroundViewControllerDidUpdateScene(_ viewController: MKLookAroundViewController)
    func lookAroundViewControllerWillPresentFullScreen(_ viewController: MKLookAroundViewController)
    func lookAroundViewControllerDidPresentFullScreen(_ viewController: MKLookAroundViewController)
    func lookAroundViewControllerWillDismissFullScreen(_ viewController: MKLookAroundViewController)
    func lookAroundViewControllerDidDismissFullScreen(_ viewController: MKLookAroundViewController)
}

extension MKLookAroundViewControllerDelegate {
    public func lookAroundViewControllerWillUpdateScene(_ viewController: MKLookAroundViewController) { _ = viewController }
    public func lookAroundViewControllerDidUpdateScene(_ viewController: MKLookAroundViewController) { _ = viewController }
    public func lookAroundViewControllerWillPresentFullScreen(_ viewController: MKLookAroundViewController) { _ = viewController }
    public func lookAroundViewControllerDidPresentFullScreen(_ viewController: MKLookAroundViewController) { _ = viewController }
    public func lookAroundViewControllerWillDismissFullScreen(_ viewController: MKLookAroundViewController) { _ = viewController }
    public func lookAroundViewControllerDidDismissFullScreen(_ viewController: MKLookAroundViewController) { _ = viewController }
}
