import Foundation

#if canImport(CoreLocation)
import CoreLocation
#else
/// Isolated-host stand-in for `CoreLocation.CLLocation`. SafetyKit's seed lists
/// only Foundation; the sealed gate cannot import CoreLocation. Crash Detection
/// never produces a live GPS fix on Linux — this type exists so
/// `SACrashDetectionEvent.location` can type-check. It is not a CoreLocation port.
open class CLLocation: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let horizontalAccuracy: Double
    public let timestamp: Date

    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        horizontalAccuracy: Double = -1,
        timestamp: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
        super.init()
    }

    public required init?(coder: NSCoder) {
        latitude = coder.decodeDouble(forKey: "latitude")
        longitude = coder.decodeDouble(forKey: "longitude")
        altitude = coder.decodeDouble(forKey: "altitude")
        horizontalAccuracy = coder.decodeDouble(forKey: "horizontalAccuracy")
        timestamp = (coder.decodeObject(of: NSDate.self, forKey: "timestamp") as Date?) ?? Date()
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(latitude, forKey: "latitude")
        coder.encode(longitude, forKey: "longitude")
        coder.encode(altitude, forKey: "altitude")
        coder.encode(horizontalAccuracy, forKey: "horizontalAccuracy")
        coder.encode(timestamp as NSDate, forKey: "timestamp")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return CLLocation(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            timestamp: timestamp
        )
    }
}
#endif