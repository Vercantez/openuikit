import Foundation
import Glibc
import EnergyKit

func energyKitExpect(_ condition: Bool, _ message: String = "") {
    precondition(condition, message)
}

func energyKitExpectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "") {
    precondition(lhs == rhs, "\(message): \(String(describing: lhs)) != \(String(describing: rhs))")
}

final class EnergyKitBox<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        value
    }

    func store(_ newValue: Value) {
        value = newValue
    }
}

func energyKitAwait<T: Sendable>(
    _ body: @escaping @Sendable () async throws -> T
) -> Result<T, Error> {
    let box = EnergyKitBox<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
    }
    var spins = 0
    while true {
        if let result = box.load() {
            return result
        }
        spins += 1
        if spins > 5_000_000 {
            preconditionFailure("async probe did not complete")
        }
        sched_yield()
    }
}

func energyKitExpectError(_ result: Result<some Any, Error>, _ expected: EnergyKitError) {
    switch result {
    case .success:
        preconditionFailure("expected \(expected), got success")
    case .failure(let error):
        guard let typed = error as? EnergyKitError else {
            preconditionFailure("expected \(expected), got \(error)")
        }
        energyKitExpectEqual(typed, expected)
    }
}

func energyKitRoundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}

func energyKitSampleInterval() -> DateInterval {
    DateInterval(start: Date(timeIntervalSince1970: 1_700_000_000), duration: 3600)
}

func energyKitSampleVenue() -> EnergyVenue {
    EnergyVenue(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "Home")
}

func energyKitHVACEvent(deviceID: String = "hvac-1") -> ElectricHVACLoadEvent {
    let guidance = ElectricHVACLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: true,
        guidanceToken: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    )
    let session = ElectricHVACLoadEvent.Session(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        state: .active,
        guidanceState: guidance
    )
    return ElectricHVACLoadEvent(
        timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        measurement: ElectricHVACLoadEvent.ElectricalMeasurement(stage: 2),
        session: session,
        deviceID: deviceID
    )
}

func energyKitVehicleEvent(deviceID: String = "ev-1") -> ElectricVehicleLoadEvent {
    let guidance = ElectricVehicleLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: false,
        guidanceToken: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    )
    let session = ElectricVehicleLoadEvent.Session(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        state: .begin,
        guidanceState: guidance
    )
    return ElectricVehicleLoadEvent(
        timestamp: Date(timeIntervalSince1970: 1_700_000_100),
        measurement: ElectricVehicleLoadEvent.ElectricalMeasurement(
            stateOfCharge: 64,
            direction: .imported,
            power: Measurement(value: 7200, unit: UnitPower.watts),
            energy: Measurement(value: 12, unit: UnitEnergy.kilowattHours)
        ),
        session: session,
        deviceID: deviceID
    )
}

func energyKitSampleQuery() -> ElectricityInsightQuery {
    ElectricityInsightQuery(
        options: [.cleanliness, .tariff],
        range: energyKitSampleInterval(),
        granularity: .hourly,
        flowDirection: .imported
    )
}
