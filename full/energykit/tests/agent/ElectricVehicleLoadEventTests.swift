import Foundation
import EnergyKit

func testVehicleLoadEventType() {
    energyKitExpectEqual(energyKitVehicleEvent().deviceID, "ev-1")
}

func testVehicleLoadEventIDTypealias() {
    let identifier: ElectricVehicleLoadEvent.ID = energyKitVehicleEvent().id
    energyKitExpect(identifier.uuidString.count == 36)
}

func testVehicleLoadEventIDProperty() {
    energyKitExpect(energyKitVehicleEvent().id != energyKitVehicleEvent().id)
}

func testVehicleLoadEventTimestamp() {
    energyKitExpectEqual(
        energyKitVehicleEvent().timestamp,
        Date(timeIntervalSince1970: 1_700_000_100)
    )
}

func testVehicleLoadEventMeasurementProperty() {
    energyKitExpectEqual(energyKitVehicleEvent().measurement.stateOfCharge, 64)
}

func testVehicleLoadEventSessionProperty() {
    energyKitExpectEqual(energyKitVehicleEvent().session.state, .begin)
}

func testVehicleLoadEventDeviceID() {
    energyKitExpectEqual(energyKitVehicleEvent(deviceID: "car-9").deviceID, "car-9")
}

func testVehicleLoadEventInit() {
    let event = energyKitVehicleEvent()
    energyKitExpectEqual(event.measurement.direction, .imported)
}

func testVehicleLoadEventCodable() {
    do {
        let decoded = try energyKitRoundTrip(energyKitVehicleEvent())
        energyKitExpectEqual(decoded.deviceID, "ev-1")
        energyKitExpectEqual(decoded.measurement.stateOfCharge, 64)
    } catch {
        preconditionFailure("vehicle Codable failed: \(error)")
    }
}

func testVehicleMeasurementInit() {
    let measurement = ElectricVehicleLoadEvent.ElectricalMeasurement(
        stateOfCharge: 10,
        direction: .exported,
        power: Measurement(value: 0, unit: UnitPower.watts),
        energy: Measurement(value: 0, unit: UnitEnergy.kilowattHours)
    )
    energyKitExpectEqual(measurement.direction, .exported)
}

func testVehicleMeasurementStateOfCharge() {
    energyKitExpectEqual(energyKitVehicleEvent().measurement.stateOfCharge, 64)
}

func testVehicleMeasurementDirection() {
    energyKitExpectEqual(energyKitVehicleEvent().measurement.direction, .imported)
}

func testVehicleMeasurementPower() {
    energyKitExpectEqual(energyKitVehicleEvent().measurement.power.value, 7200)
}

func testVehicleMeasurementEnergy() {
    energyKitExpectEqual(energyKitVehicleEvent().measurement.energy.value, 12)
}

func testVehicleMeasurementCodable() {
    do {
        let decoded = try energyKitRoundTrip(energyKitVehicleEvent().measurement)
        energyKitExpectEqual(decoded.stateOfCharge, 64)
        energyKitExpectEqual(decoded.direction, .imported)
    } catch {
        preconditionFailure("vehicle measurement Codable failed: \(error)")
    }
}

func testVehicleSessionInit() {
    let session = ElectricVehicleLoadEvent.Session(
        id: UUID(),
        state: .active,
        guidanceState: ElectricVehicleLoadEvent.Session.GuidanceState(
            wasFollowingGuidance: true,
            guidanceToken: UUID()
        )
    )
    energyKitExpectEqual(session.state, .active)
}

func testVehicleSessionID() {
    let identifier = UUID(uuidString: "14141414-1414-1414-1414-141414141414")!
    let session = ElectricVehicleLoadEvent.Session(
        id: identifier,
        state: .end,
        guidanceState: ElectricVehicleLoadEvent.Session.GuidanceState(
            wasFollowingGuidance: false,
            guidanceToken: UUID()
        )
    )
    energyKitExpectEqual(session.id, identifier)
}

func testVehicleSessionStateProperty() {
    energyKitExpectEqual(energyKitVehicleEvent().session.state, .begin)
}

func testVehicleSessionGuidanceStateProperty() {
    energyKitExpect(!energyKitVehicleEvent().session.guidanceState.wasFollowingGuidance)
}

func testVehicleSessionCodable() {
    do {
        let decoded = try energyKitRoundTrip(energyKitVehicleEvent().session)
        energyKitExpectEqual(decoded.state, .begin)
    } catch {
        preconditionFailure("vehicle session Codable failed: \(error)")
    }
}

func testVehicleSessionStateCases() {
    let cases: [ElectricVehicleLoadEvent.Session.State] = [.begin, .end, .active]
    energyKitExpectEqual(Set(cases).count, 3)
}

func testVehicleSessionStateEquality() {
    energyKitExpectEqual(ElectricVehicleLoadEvent.Session.State.end, .end)
    energyKitExpect(ElectricVehicleLoadEvent.Session.State.begin != .active)
}

func testVehicleSessionStateInequality() {
    energyKitExpect(ElectricVehicleLoadEvent.Session.State.active != .begin)
}

func testVehicleSessionStateHash() {
    var hasher = Hasher()
    ElectricVehicleLoadEvent.Session.State.active.hash(into: &hasher)
    energyKitExpectEqual(Set([ElectricVehicleLoadEvent.Session.State.end, .end]).count, 1)
}

func testVehicleSessionStateCodable() {
    do {
        energyKitExpectEqual(try energyKitRoundTrip(ElectricVehicleLoadEvent.Session.State.begin), .begin)
    } catch {
        preconditionFailure("vehicle session state Codable failed: \(error)")
    }
}

func testVehicleGuidanceStateInit() {
    let token = UUID()
    let state = ElectricVehicleLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: true,
        guidanceToken: token
    )
    energyKitExpect(state.wasFollowingGuidance)
    energyKitExpectEqual(state.guidanceToken, token)
}

func testVehicleGuidanceStateWasFollowing() {
    energyKitExpect(!energyKitVehicleEvent().session.guidanceState.wasFollowingGuidance)
}

func testVehicleGuidanceStateTokenMutation() {
    var state = ElectricVehicleLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: false,
        guidanceToken: UUID()
    )
    let updated = UUID(uuidString: "15151515-1515-1515-1515-151515151515")!
    state.guidanceToken = updated
    energyKitExpectEqual(state.guidanceToken, updated)
}

func testVehicleGuidanceStateCodable() {
    do {
        let original = ElectricVehicleLoadEvent.Session.GuidanceState(
            wasFollowingGuidance: true,
            guidanceToken: UUID(uuidString: "16161616-1616-1616-1616-161616161616")!
        )
        let decoded = try energyKitRoundTrip(original)
        energyKitExpect(decoded.wasFollowingGuidance)
    } catch {
        preconditionFailure("vehicle guidance state Codable failed: \(error)")
    }
}

func testEnergyVenueSubmitVehicleEmptyDeviceInvalid() {
    energyKitExpectError(
        energyKitAwait { try await energyKitSampleVenue().submitEvents([energyKitVehicleEvent(deviceID: "")]) },
        .invalidLoadEvent
    )
}
