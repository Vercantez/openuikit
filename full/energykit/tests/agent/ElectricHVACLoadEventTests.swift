import Foundation
import EnergyKit

func testHVACLoadEventType() {
    let event = energyKitHVACEvent()
    energyKitExpectEqual(event.deviceID, "hvac-1")
}

func testHVACLoadEventIDTypealias() {
    let identifier: ElectricHVACLoadEvent.ID = energyKitHVACEvent().id
    energyKitExpect(identifier != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
}

func testHVACLoadEventIDProperty() {
    energyKitExpect(energyKitHVACEvent().id != energyKitHVACEvent().id)
}

func testHVACLoadEventTimestamp() {
    energyKitExpectEqual(
        energyKitHVACEvent().timestamp,
        Date(timeIntervalSince1970: 1_700_000_000)
    )
}

func testHVACLoadEventMeasurementProperty() {
    energyKitExpectEqual(energyKitHVACEvent().measurement.stage, 2)
}

func testHVACLoadEventSessionProperty() {
    energyKitExpectEqual(energyKitHVACEvent().session.state, .active)
}

func testHVACLoadEventDeviceID() {
    energyKitExpectEqual(energyKitHVACEvent(deviceID: "furnace").deviceID, "furnace")
}

func testHVACLoadEventInit() {
    let event = energyKitHVACEvent(deviceID: "packaged")
    energyKitExpectEqual(event.session.state, .active)
    energyKitExpectEqual(event.measurement.stage, 2)
}

func testHVACLoadEventCodable() {
    do {
        let decoded = try energyKitRoundTrip(energyKitHVACEvent())
        energyKitExpectEqual(decoded.deviceID, "hvac-1")
        energyKitExpectEqual(decoded.measurement.stage, 2)
    } catch {
        preconditionFailure("HVAC Codable failed: \(error)")
    }
}

func testHVACMeasurementInit() {
    energyKitExpectEqual(ElectricHVACLoadEvent.ElectricalMeasurement(stage: 0).stage, 0)
}

func testHVACMeasurementStage() {
    energyKitExpectEqual(ElectricHVACLoadEvent.ElectricalMeasurement(stage: 3).stage, 3)
}

func testHVACMeasurementCodable() {
    do {
        let decoded = try energyKitRoundTrip(ElectricHVACLoadEvent.ElectricalMeasurement(stage: 1))
        energyKitExpectEqual(decoded.stage, 1)
    } catch {
        preconditionFailure("HVAC measurement Codable failed: \(error)")
    }
}

func testHVACSessionInit() {
    let session = ElectricHVACLoadEvent.Session(
        id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!,
        state: .end,
        guidanceState: ElectricHVACLoadEvent.Session.GuidanceState(
            wasFollowingGuidance: false,
            guidanceToken: UUID()
        )
    )
    energyKitExpectEqual(session.state, .end)
}

func testHVACSessionID() {
    let identifier = UUID(uuidString: "01010101-0101-0101-0101-010101010101")!
    let session = ElectricHVACLoadEvent.Session(
        id: identifier,
        state: .begin,
        guidanceState: ElectricHVACLoadEvent.Session.GuidanceState(
            wasFollowingGuidance: false,
            guidanceToken: UUID()
        )
    )
    energyKitExpectEqual(session.id, identifier)
}

func testHVACSessionStateProperty() {
    energyKitExpectEqual(energyKitHVACEvent().session.state, .active)
}

func testHVACSessionGuidanceStateProperty() {
    energyKitExpect(energyKitHVACEvent().session.guidanceState.wasFollowingGuidance)
}

func testHVACSessionCodable() {
    do {
        let decoded = try energyKitRoundTrip(energyKitHVACEvent().session)
        energyKitExpectEqual(decoded.state, .active)
    } catch {
        preconditionFailure("HVAC session Codable failed: \(error)")
    }
}

func testHVACSessionStateCases() {
    let cases: [ElectricHVACLoadEvent.Session.State] = [.begin, .end, .active]
    energyKitExpectEqual(Set(cases).count, 3)
}

func testHVACSessionStateEquality() {
    energyKitExpectEqual(ElectricHVACLoadEvent.Session.State.begin, .begin)
    energyKitExpect(ElectricHVACLoadEvent.Session.State.begin != .end)
}

func testHVACSessionStateInequality() {
    energyKitExpect(ElectricHVACLoadEvent.Session.State.active != .end)
}

func testHVACSessionStateHash() {
    var hasher = Hasher()
    ElectricHVACLoadEvent.Session.State.begin.hash(into: &hasher)
    energyKitExpectEqual(Set([ElectricHVACLoadEvent.Session.State.begin, .begin]).count, 1)
}

func testHVACSessionStateCodable() {
    do {
        energyKitExpectEqual(try energyKitRoundTrip(ElectricHVACLoadEvent.Session.State.end), .end)
        energyKitExpectEqual(try energyKitRoundTrip(ElectricHVACLoadEvent.Session.State.active), .active)
        energyKitExpectEqual(try energyKitRoundTrip(ElectricHVACLoadEvent.Session.State.begin), .begin)
    } catch {
        preconditionFailure("HVAC session state Codable failed: \(error)")
    }
}

func testHVACGuidanceStateInit() {
    let token = UUID()
    let state = ElectricHVACLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: true,
        guidanceToken: token
    )
    energyKitExpectEqual(state.guidanceToken, token)
}

func testHVACGuidanceStateWasFollowing() {
    let state = ElectricHVACLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: false,
        guidanceToken: UUID()
    )
    energyKitExpect(!state.wasFollowingGuidance)
}

func testHVACGuidanceStateTokenMutation() {
    var state = ElectricHVACLoadEvent.Session.GuidanceState(
        wasFollowingGuidance: true,
        guidanceToken: UUID()
    )
    let updated = UUID(uuidString: "12121212-1212-1212-1212-121212121212")!
    state.guidanceToken = updated
    energyKitExpectEqual(state.guidanceToken, updated)
}

func testHVACGuidanceStateCodable() {
    do {
        let original = ElectricHVACLoadEvent.Session.GuidanceState(
            wasFollowingGuidance: true,
            guidanceToken: UUID(uuidString: "13131313-1313-1313-1313-131313131313")!
        )
        let decoded = try energyKitRoundTrip(original)
        energyKitExpect(decoded.wasFollowingGuidance)
        energyKitExpectEqual(decoded.guidanceToken, original.guidanceToken)
    } catch {
        preconditionFailure("HVAC guidance state Codable failed: \(error)")
    }
}
