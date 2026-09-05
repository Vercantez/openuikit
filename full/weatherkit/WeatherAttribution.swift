import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif

public struct WeatherMetadata: Hashable, Codable, Sendable {
    public var date: Date
    public var expirationDate: Date
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double

    public init(
        date: Date,
        expirationDate: Date,
        latitude: Double = 0,
        longitude: Double = 0,
        altitude: Double = 0
    ) {
        self.date = date
        self.expirationDate = expirationDate
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }

    #if canImport(CoreLocation)
    public var location: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: date
        )
    }
    #endif
}

public struct WeatherAttribution: Equatable, Codable, Sendable {
    public var legalAttributionText: String
    public var serviceName: String
    public var legalPageURL: URL
    public var squareMarkURL: URL
    public var combinedMarkDarkURL: URL
    public var combinedMarkLightURL: URL

    public init(
        legalAttributionText: String,
        serviceName: String,
        legalPageURL: URL,
        squareMarkURL: URL,
        combinedMarkDarkURL: URL,
        combinedMarkLightURL: URL
    ) {
        self.legalAttributionText = legalAttributionText
        self.serviceName = serviceName
        self.legalPageURL = legalPageURL
        self.squareMarkURL = squareMarkURL
        self.combinedMarkDarkURL = combinedMarkDarkURL
        self.combinedMarkLightURL = combinedMarkLightURL
    }
}

public struct WeatherAvailability: Equatable, Codable, Sendable {
    public enum AvailabilityKind: String, Codable, Hashable, Sendable {
        case available
        case temporarilyUnavailable
        case unsupported
        case unknown
    }

    public var alertAvailability: AvailabilityKind
    public var minuteAvailability: AvailabilityKind

    public init(
        alertAvailability: AvailabilityKind,
        minuteAvailability: AvailabilityKind
    ) {
        self.alertAvailability = alertAvailability
        self.minuteAvailability = minuteAvailability
    }
}

public struct WeatherAlert: Equatable, Codable, Sendable {
    public var detailsURL: URL
    public var region: String?
    public var source: String
    public var summary: String
    public var metadata: WeatherMetadata
    public var severity: WeatherSeverity

    public init(
        detailsURL: URL,
        region: String?,
        source: String,
        summary: String,
        metadata: WeatherMetadata,
        severity: WeatherSeverity
    ) {
        self.detailsURL = detailsURL
        self.region = region
        self.source = source
        self.summary = summary
        self.metadata = metadata
        self.severity = severity
    }
}
