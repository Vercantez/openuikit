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

open class MKMapCamera: NSObject, NSCopying {
    open var centerCoordinate: CLLocationCoordinate2D
    open var heading: CLLocationDirection
    open var pitch: CGFloat
    open var altitude: CLLocationDistance
    open var centerCoordinateDistance: CLLocationDistance

    public override init() {
        centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        heading = 0
        pitch = 0
        altitude = 0
        centerCoordinateDistance = 0
        super.init()
    }

    public convenience init(
        lookingAtCenter centerCoordinate: CLLocationCoordinate2D,
        fromDistance distance: CLLocationDistance,
        pitch: CGFloat,
        heading: CLLocationDirection
    ) {
        self.init()
        self.centerCoordinate = centerCoordinate
        self.centerCoordinateDistance = distance
        self.pitch = pitch
        self.heading = heading
        self.altitude = distance * cos(Double(pitch) * .pi / 180)
    }

    public convenience init(
        lookingAtCenterCoordinate centerCoordinate: CLLocationCoordinate2D,
        fromDistance distance: CLLocationDistance,
        pitch: CGFloat,
        heading: CLLocationDirection
    ) {
        self.init(lookingAtCenter: centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
    }

    public convenience init(
        lookingAtCenter centerCoordinate: CLLocationCoordinate2D,
        fromEyeCoordinate eyeCoordinate: CLLocationCoordinate2D,
        eyeAltitude: CLLocationDistance
    ) {
        self.init()
        self.centerCoordinate = centerCoordinate
        self.altitude = eyeAltitude
        let eye = MKMapPoint(eyeCoordinate)
        let center = MKMapPoint(centerCoordinate)
        let meters = eye.distance(to: center)
        self.centerCoordinateDistance = (meters * meters + eyeAltitude * eyeAltitude).squareRoot()
        let dLat = centerCoordinate.latitude - eyeCoordinate.latitude
        let dLon = centerCoordinate.longitude - eyeCoordinate.longitude
        self.heading = atan2(dLon, dLat) * 180 / .pi
        if self.centerCoordinateDistance > 0 {
            self.pitch = CGFloat(atan2(meters, eyeAltitude) * 180 / .pi)
        }
    }

    public convenience init(
        lookingAtCenterCoordinate centerCoordinate: CLLocationCoordinate2D,
        fromEyeCoordinate eyeCoordinate: CLLocationCoordinate2D,
        eyeAltitude: CLLocationDistance
    ) {
        self.init(
            lookingAtCenter: centerCoordinate,
            fromEyeCoordinate: eyeCoordinate,
            eyeAltitude: eyeAltitude
        )
    }

    public convenience init(lookingAt mapItem: MKMapItem, forViewSize viewSize: CGSize, allowPitch: Bool) {
        self.init(
            lookingAtCenter: mapItem.placemark.coordinate,
            fromDistance: 1000,
            pitch: allowPitch ? 30 : 0,
            heading: 0
        )
        _ = viewSize
    }

    public convenience init(lookingAtMapItem mapItem: MKMapItem, forViewSize viewSize: CGSize, allowPitch: Bool) {
        self.init(lookingAt: mapItem, forViewSize: viewSize, allowPitch: allowPitch)
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = MKMapCamera()
        copy.centerCoordinate = centerCoordinate
        copy.heading = heading
        copy.pitch = pitch
        copy.altitude = altitude
        copy.centerCoordinateDistance = centerCoordinateDistance
        return copy
    }
}

open class MKMapConfiguration: NSObject, NSCopying {
    public enum ElevationStyle: Int, Sendable, Equatable, Hashable {
        case flat = 0
        case realistic = 1
    }

    open var elevationStyle: ElevationStyle = .flat

    public override init() {
        super.init()
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = MKMapConfiguration()
        copy.elevationStyle = elevationStyle
        return copy
    }
}

open class MKStandardMapConfiguration: MKMapConfiguration {
    public enum EmphasisStyle: Int, Sendable, Equatable, Hashable {
        case `default` = 0
        case muted = 1
    }

    open var emphasisStyle: EmphasisStyle = .default
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    open var showsTraffic: Bool = false

    public override init() {
        super.init()
    }

    public convenience init(elevationStyle: MKMapConfiguration.ElevationStyle) {
        self.init()
        self.elevationStyle = elevationStyle
    }

    public convenience init(emphasisStyle: EmphasisStyle) {
        self.init()
        self.emphasisStyle = emphasisStyle
    }

    public convenience init(
        elevationStyle: MKMapConfiguration.ElevationStyle,
        emphasisStyle: EmphasisStyle
    ) {
        self.init()
        self.elevationStyle = elevationStyle
        self.emphasisStyle = emphasisStyle
    }
}

open class MKHybridMapConfiguration: MKMapConfiguration {
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    open var showsTraffic: Bool = false

    public override init() { super.init() }

    public convenience init(elevationStyle: MKMapConfiguration.ElevationStyle) {
        self.init()
        self.elevationStyle = elevationStyle
    }
}

open class MKImageryMapConfiguration: MKMapConfiguration {
    public override init() { super.init() }

    public convenience init(elevationStyle: MKMapConfiguration.ElevationStyle) {
        self.init()
        self.elevationStyle = elevationStyle
    }
}
