import EnergyKit
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build EnergyKit with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s EnergyKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation UUID / Date / DateInterval / Measurement values round-trip
//    through public EnergyKit APIs without framework-local stand-ins.

private func assertNotEnergyKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("EnergyKit."))
}

func energyKitDependencyIdentityMain() {
    let identifier = UUID()
    assertNotEnergyKitType(identifier)
    precondition(type(of: identifier) == UUID.self)

    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotEnergyKitType(timestamp)

    let interval = DateInterval(start: timestamp, duration: 3600)
    assertNotEnergyKitType(interval)

    let power = Measurement(value: 1000, unit: UnitPower.watts)
    assertNotEnergyKitType(power)

    let energy = Measurement(value: 2, unit: UnitEnergy.kilowattHours)
    assertNotEnergyKitType(energy)

    let venue = EnergyVenue(id: identifier, name: "Home")
    precondition(venue.id == identifier)
    assertNotEnergyKitType(venue.id)

    let measurement = ElectricVehicleLoadEvent.ElectricalMeasurement(
        stateOfCharge: 50,
        direction: .imported,
        power: power,
        energy: energy
    )
    precondition(measurement.power.value == power.value)
    assertNotEnergyKitType(measurement.power)

    let query = ElectricityInsightQuery(
        options: .cleanliness,
        range: interval,
        granularity: .hourly,
        flowDirection: .imported
    )
    precondition(query.range == interval)
    assertNotEnergyKitType(query.range)
}
