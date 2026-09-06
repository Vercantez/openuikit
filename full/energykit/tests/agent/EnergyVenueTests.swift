import Foundation
import EnergyKit

func testEnergyVenueType() {
    let venue = energyKitSampleVenue()
    energyKitExpectEqual(venue.name, "Home")
    energyKitExpectEqual(String(describing: type(of: venue)), "EnergyVenue")
}

func testEnergyVenueIDTypealias() {
    let identifier: EnergyVenue.ID = energyKitSampleVenue().id
    energyKitExpectEqual(identifier, energyKitSampleVenue().id)
}

func testEnergyVenueIDProperty() {
    let venue = EnergyVenue(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!, name: "Cabin")
    energyKitExpectEqual(venue.id.uuidString.lowercased(), "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
}

func testEnergyVenueNameProperty() {
    energyKitExpectEqual(EnergyVenue(id: UUID(), name: "Garage").name, "Garage")
}

func testEnergyVenueCodable() {
    do {
        let venue = energyKitSampleVenue()
        let decoded = try energyKitRoundTrip(venue)
        energyKitExpectEqual(decoded.id, venue.id)
        energyKitExpectEqual(decoded.name, venue.name)
    } catch {
        preconditionFailure("venue Codable failed: \(error)")
    }
}

func testEnergyVenueEncode() {
    do {
        let data = try JSONEncoder().encode(energyKitSampleVenue())
        energyKitExpect(data.count > 0)
    } catch {
        preconditionFailure("venue encode failed: \(error)")
    }
}

func testEnergyVenueDecode() {
    do {
        let payload = Data(#"{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","name":"Shed"}"#.utf8)
        let venue = try JSONDecoder().decode(EnergyVenue.self, from: payload)
        energyKitExpectEqual(venue.name, "Shed")
    } catch {
        preconditionFailure("venue decode failed: \(error)")
    }
}

func testEnergyVenueVenuesFailClosed() {
    energyKitExpectError(
        energyKitAwait { try await EnergyVenue.venues() },
        .serviceUnavailable
    )
}

func testEnergyVenueForIDFailClosed() {
    let identifier = UUID()
    energyKitExpectError(
        energyKitAwait { try await EnergyVenue.venue(for: identifier) },
        .venueUnavailable
    )
}

func testEnergyVenueMatchingHomeFailClosed() {
    let home = UUID()
    energyKitExpectError(
        energyKitAwait { try await EnergyVenue.venue(matchingHomeUniqueIdentifier: home) },
        .locationServicesDenied
    )
}

func testEnergyVenueSubmitEventsServiceUnavailable() {
    let venue = energyKitSampleVenue()
    let event = energyKitHVACEvent()
    energyKitExpectError(
        energyKitAwait { try await venue.submitEvents([event]) },
        .serviceUnavailable
    )
}

func testEnergyVenueSubmitEventsEmptyInvalid() {
    let venue = energyKitSampleVenue()
    energyKitExpectError(
        energyKitAwait { () async throws in
            let events: [ElectricHVACLoadEvent] = []
            try await venue.submitEvents(events)
        },
        .invalidLoadEvent
    )
}

func testEnergyVenueSubmitEventsEmptyDeviceInvalid() {
    let venue = energyKitSampleVenue()
    energyKitExpectError(
        energyKitAwait { try await venue.submitEvents([energyKitHVACEvent(deviceID: "")]) },
        .invalidLoadEvent
    )
}
