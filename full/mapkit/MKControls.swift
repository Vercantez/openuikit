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

open class MKCompassButton: UIView {
    open weak var mapView: MKMapView?
    open var compassVisibility: MKFeatureVisibility = .adaptive

    public convenience init(mapView: MKMapView?) {
        self.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.mapView = mapView
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

open class MKScaleView: UIView {
    public enum Alignment: Int, Sendable, Equatable, Hashable {
        case leading = 0
        case trailing = 1
        case center = 2
    }

    open weak var mapView: MKMapView?
    open var legendAlignment: Alignment = .leading
    open var scaleVisibility: MKFeatureVisibility = .adaptive

    public convenience init(mapView: MKMapView?) {
        self.init(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
        self.mapView = mapView
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

open class MKUserTrackingButton: UIView {
    open weak var mapView: MKMapView?

    public convenience init(mapView: MKMapView?) {
        self.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.mapView = mapView
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

open class MKUserTrackingBarButtonItem: UIBarButtonItem {
    open var mapView: MKMapView?

    public init(mapView: MKMapView?) {
        self.mapView = mapView
        super.init()
    }
}

public protocol MKGeoJSONObject: AnyObject {}

open class MKGeoJSONFeature: NSObject, MKGeoJSONObject {
    open var identifier: String?
    open var properties: Data?
    open var geometry: [any MKShape & MKGeoJSONObject] = []
}

open class MKGeoJSONDecoder: NSObject {
    open func decode(_ data: Data) throws -> [any MKGeoJSONObject] {
        _ = data
        throw MKError(.decodingFailed)
    }
}
