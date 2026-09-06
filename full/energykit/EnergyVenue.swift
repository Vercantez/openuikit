import Foundation

/// A home or other energy venue. Lookups and event submission talk to an
/// Apple energy service that is absent on Linux and fail closed.
public struct EnergyVenue: Codable, Identifiable, Sendable {
    public typealias ID = UUID

    public let name: String
    public let id: UUID

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    /// Lists energy venues. Fails closed: no Home/energy daemon on Linux.
    public static func venues() async throws -> [EnergyVenue] {
        throw EnergyKitError.serviceUnavailable
    }

    /// Looks up a venue by EnergyKit venue identifier.
    public static func venue(for id: UUID) async throws -> EnergyVenue {
        _ = id
        throw EnergyKitError.venueUnavailable
    }

    /// Looks up a venue by a HomeKit home unique identifier. This host has no
    /// CoreLocation/Home identity path.
    public static func venue(matchingHomeUniqueIdentifier: UUID) async throws -> EnergyVenue {
        _ = matchingHomeUniqueIdentifier
        throw EnergyKitError.locationServicesDenied
    }

    /// Submits electrical load events for this venue. Empty batches are
    /// invalid; otherwise the Apple ingest service is unavailable.
    public func submitEvents<Event>(_ events: [Event]) async throws
    where Event: ElectricalLoadEventProtocol {
        if events.isEmpty {
            throw EnergyKitError.invalidLoadEvent
        }
        for event in events {
            if let hvac = event as? ElectricHVACLoadEvent, hvac.deviceID.isEmpty {
                throw EnergyKitError.invalidLoadEvent
            }
            if let vehicle = event as? ElectricVehicleLoadEvent, vehicle.deviceID.isEmpty {
                throw EnergyKitError.invalidLoadEvent
            }
        }
        throw EnergyKitError.serviceUnavailable
    }
}
