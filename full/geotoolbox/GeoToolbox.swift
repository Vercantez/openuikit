@_exported import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif

/// Linux starting point for Apple's public `GeoToolbox` module.
///
/// Isolated host compilation has Foundation only. `CLLocationCoordinate2D`
/// and `CLLocation` come from `_LocationEssentials` on Darwin (re-exported by
/// GeoToolbox). Those types are not a declared GeoToolbox dependency, so this
/// file supplies lookalikes when `CoreLocation` is absent. They compile out
/// once a real `CoreLocation` module is on the link line.
///
/// `PlaceDescriptor` is a value type: it stores place representations. Linux does
/// not talk to MapKit, Apple Maps, Core Location hardware, or App Intents.

#if !canImport(CoreLocation)

public typealias CLLocationDegrees = Double
public typealias CLLocationDistance = Double
public typealias CLLocationAccuracy = Double
public typealias CLLocationSpeed = Double
public typealias CLLocationDirection = Double

/// Isolated-host stand-in for `_LocationEssentials.CLLocationCoordinate2D`.
public struct CLLocationCoordinate2D: Equatable, Hashable, Sendable {
    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Isolated-host stand-in for `_LocationEssentials.CLLocation`.
///
/// This type stores a coordinate snapshot. Constructing it does not query
/// GPS, a location daemon, or any Apple service.
open class CLLocation: NSObject, @unchecked Sendable {
    public let coordinate: CLLocationCoordinate2D
    public let altitude: CLLocationDistance
    public let horizontalAccuracy: CLLocationAccuracy
    public let verticalAccuracy: CLLocationAccuracy
    public let timestamp: Date

    public convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }

    public init(
        coordinate: CLLocationCoordinate2D,
        altitude: CLLocationDistance,
        horizontalAccuracy: CLLocationAccuracy,
        verticalAccuracy: CLLocationAccuracy,
        timestamp: Date
    ) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        super.init()
    }
}

#endif
