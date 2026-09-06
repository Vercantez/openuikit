#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Contains representations of a physical place, suitable for searching or
/// retrieving rich data.
///
/// Linux implements the documented value-type surface. Mapping-service lookup,
/// MapKit `MKMapItem` conversion, and App Intents display/resolver types are
/// absent and are not invented.
public struct PlaceDescriptor: Equatable, Sendable {
    /// A string that uniquely identifies this type.
    ///
    /// Apple's App Intents `PersistentlyIdentifiable` default is unobserved.
    /// Linux returns the type name. See `oracle-questions.tsv`.
    public static var persistentIdentifier: String { "PlaceDescriptor" }

    /// App Intents `UnwrappedType` on Darwin. Linux aliases the value type.
    public typealias UnwrappedType = PlaceDescriptor

    /// App Intents `ValueType` on Darwin. Linux aliases the value type.
    public typealias ValueType = PlaceDescriptor

    /// An array of representations of the place using common mapping concepts.
    ///
    /// When searching or fetching a place from a mapping service provider,
    /// the order of the list can be used as a hint. Representations that most
    /// closely match the original data source come first.
    public let representations: [PlaceRepresentation]

    /// Publicly known name of the area or place of interest.
    /// Locations that do not have a public name (like a private residence)
    /// should be nil. e.g. "Starbucks" or "Yosemite National Park"
    public let commonName: String?

    /// An array of proprietary or non-uniform representations of the place.
    public let supportingRepresentations: [SupportingPlaceRepresentation]

    /// Creates a PlaceDescriptor, suitable for searching or retrieving rich
    /// data about a place.
    ///
    /// Representations must have at least one member on Darwin. Linux stores
    /// the arrays as given and does not trap on empty input; Apple's empty
    /// policy is an oracle question.
    public init(
        representations: [PlaceRepresentation],
        commonName: String?,
        supportingRepresentations: [SupportingPlaceRepresentation] = []
    ) {
        self.representations = representations
        self.commonName = commonName
        self.supportingRepresentations = supportingRepresentations
    }

    /// Full address, as would be used in postal or administrative scenarios.
    ///
    /// Linux returns the first `.address` payload in `representations` order.
    public var address: String? {
        for representation in representations {
            if case .address(let value) = representation {
                return value
            }
        }
        return nil
    }

    /// The latitude and longitude for a place.
    ///
    /// Linux returns the first coordinate-bearing representation in array
    /// order: `.coordinate` or `.deviceLocation`. Whether Darwin also reads
    /// device-location snapshots is an oracle question.
    public var coordinate: CLLocationCoordinate2D? {
        for representation in representations {
            switch representation {
            case .coordinate(let value):
                return value
            case .deviceLocation(let location):
                return location.coordinate
            case .address:
                continue
            }
        }
        return nil
    }

    /// Retrieve the identifier for a given service provider, if available.
    ///
    /// `serviceProvider` is a bundle identifier key such as `com.apple.maps`.
    /// Linux returns the first matching dictionary entry in
    /// `supportingRepresentations` order.
    public func serviceIdentifier(for serviceProvider: String) -> String? {
        for supporting in supportingRepresentations {
            if case .serviceIdentifiers(let identifiers) = supporting {
                if let identifier = identifiers[serviceProvider] {
                    return identifier
                }
            }
        }
        return nil
    }

    /// Representation of a physical place using well known attributes.
    public enum PlaceRepresentation: Sendable {
        /// Full address, as would be used in postal or administrative scenarios.
        case address(String)
        /// Physical location provided in a coordinate system.
        case coordinate(CLLocationCoordinate2D)
        /// Physical location in a coordinate system as collected by a device.
        ///
        /// Storing a `CLLocation` here does not query hardware. Linux will not
        /// invent a live device fix.
        case deviceLocation(CLLocation)
    }

    /// Representation of a physical place using proprietary or non-uniform
    /// attributes.
    public enum SupportingPlaceRepresentation: Sendable {
        /// Identifiers that represent a place for mapping service providers.
        ///
        /// Dictionary of [`bundleId`: `uniqueIdentifier`], e.g.
        /// `[com.apple.maps: IFC1B13F6FA980C8A]`.
        case serviceIdentifiers([String: String])
    }
}

extension PlaceDescriptor.PlaceRepresentation: Equatable {
    public static func == (
        lhs: PlaceDescriptor.PlaceRepresentation,
        rhs: PlaceDescriptor.PlaceRepresentation
    ) -> Bool {
        switch (lhs, rhs) {
        case (.address(let left), .address(let right)):
            return left == right
        case (.coordinate(let left), .coordinate(let right)):
            return left.latitude == right.latitude && left.longitude == right.longitude
        case (.deviceLocation(let left), .deviceLocation(let right)):
            return left.coordinate.latitude == right.coordinate.latitude
                && left.coordinate.longitude == right.coordinate.longitude
                && left.altitude == right.altitude
                && left.horizontalAccuracy == right.horizontalAccuracy
                && left.verticalAccuracy == right.verticalAccuracy
                && left.timestamp == right.timestamp
        default:
            return false
        }
    }
}

extension PlaceDescriptor.SupportingPlaceRepresentation: Equatable {
    public static func == (
        lhs: PlaceDescriptor.SupportingPlaceRepresentation,
        rhs: PlaceDescriptor.SupportingPlaceRepresentation
    ) -> Bool {
        switch (lhs, rhs) {
        case (.serviceIdentifiers(let left), .serviceIdentifiers(let right)):
            return left == right
        }
    }
}

extension PlaceDescriptor.PlaceRepresentation: Codable {
    /// Linux-local coding keys. Apple's on-wire keys are unobserved.
    public enum CodingKeys: String, CodingKey {
        case address
        case coordinate
        case deviceLocation
    }

    private struct CoordinatePayload: Codable {
        var latitude: Double
        var longitude: Double
    }

    private struct DeviceLocationPayload: Codable {
        var latitude: Double
        var longitude: Double
        var altitude: Double
        var horizontalAccuracy: Double
        var verticalAccuracy: Double
        var timestamp: TimeInterval
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hasAddress = container.contains(.address)
        let hasCoordinate = container.contains(.coordinate)
        let hasDevice = container.contains(.deviceLocation)
        let present = [hasAddress, hasCoordinate, hasDevice].filter { $0 }.count
        guard present == 1 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "PlaceRepresentation requires exactly one of address, coordinate, deviceLocation"
                )
            )
        }
        if hasAddress {
            self = .address(try container.decode(String.self, forKey: .address))
            return
        }
        if hasCoordinate {
            let payload = try container.decode(CoordinatePayload.self, forKey: .coordinate)
            self = .coordinate(
                CLLocationCoordinate2D(latitude: payload.latitude, longitude: payload.longitude)
            )
            return
        }
        let payload = try container.decode(DeviceLocationPayload.self, forKey: .deviceLocation)
        self = .deviceLocation(
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: payload.latitude,
                    longitude: payload.longitude
                ),
                altitude: payload.altitude,
                horizontalAccuracy: payload.horizontalAccuracy,
                verticalAccuracy: payload.verticalAccuracy,
                timestamp: Date(timeIntervalSince1970: payload.timestamp)
            )
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .address(let value):
            try container.encode(value, forKey: .address)
        case .coordinate(let value):
            try container.encode(
                CoordinatePayload(latitude: value.latitude, longitude: value.longitude),
                forKey: .coordinate
            )
        case .deviceLocation(let location):
            try container.encode(
                DeviceLocationPayload(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitude: location.altitude,
                    horizontalAccuracy: location.horizontalAccuracy,
                    verticalAccuracy: location.verticalAccuracy,
                    timestamp: location.timestamp.timeIntervalSince1970
                ),
                forKey: .deviceLocation
            )
        }
    }
}

extension PlaceDescriptor.SupportingPlaceRepresentation: Codable {
    /// Linux-local coding keys. Apple's on-wire keys are unobserved.
    public enum CodingKeys: String, CodingKey {
        case serviceIdentifiers
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifiers = try container.decode([String: String].self, forKey: .serviceIdentifiers)
        self = .serviceIdentifiers(identifiers)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .serviceIdentifiers(let identifiers):
            try container.encode(identifiers, forKey: .serviceIdentifiers)
        }
    }
}

extension PlaceDescriptor: Codable {
    /// Linux-local coding keys named after the public stored properties.
    /// Apple's on-wire keys (`wellKnownName` appears in TBD but not the public
    /// census) are unobserved.
    public enum CodingKeys: String, CodingKey {
        case representations
        case commonName
        case supportingRepresentations
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let representations = try container.decode(
            [PlaceRepresentation].self,
            forKey: .representations
        )
        let commonName = try container.decodeIfPresent(String.self, forKey: .commonName)
        let supporting = try container.decodeIfPresent(
            [SupportingPlaceRepresentation].self,
            forKey: .supportingRepresentations
        ) ?? []
        self.init(
            representations: representations,
            commonName: commonName,
            supportingRepresentations: supporting
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(representations, forKey: .representations)
        try container.encodeIfPresent(commonName, forKey: .commonName)
        try container.encode(supportingRepresentations, forKey: .supportingRepresentations)
    }
}
