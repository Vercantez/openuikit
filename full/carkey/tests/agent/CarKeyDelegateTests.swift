import CarKey
import Foundation

private final class RequiredOnlyDelegate: CarKeyRemoteControlSessionDelegate {
    var invalidations: [CarKeyErrorCode] = []
    var reports: [VehicleReport] = []
    var passthrough: [(Data, String)] = []

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didInvalidateWithError: CarKeyErrorCode
    ) {
        _ = session
        invalidations.append(didInvalidateWithError)
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        vehicleDidUpdateReport: VehicleReport
    ) {
        _ = session
        reports.append(vehicleDidUpdateReport)
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didReceivePassthroughData: Data,
        fromVehicle vehicleID: String
    ) {
        _ = session
        passthrough.append((didReceivePassthroughData, vehicleID))
    }
}

private final class FullDelegate: CarKeyRemoteControlSessionDelegate {
    var created: [(String, String)] = []

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didInvalidateWithError: CarKeyErrorCode
    ) {
        _ = session
        _ = didInvalidateWithError
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didCreateKey keyID: String,
        forVehicle vehicleID: String
    ) {
        created.append((keyID, vehicleID))
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        vehicleDidUpdateReport: VehicleReport
    ) {
        _ = session
        _ = vehicleDidUpdateReport
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didReceivePassthroughData: Data,
        fromVehicle vehicleID: String
    ) {
        _ = session
        _ = didReceivePassthroughData
        _ = vehicleID
    }
}

func testDelegateRequirements() {
    let session = CarKeyRemoteControlSession()
    let delegate = RequiredOnlyDelegate()
    let report = VehicleReport(identifier: "veh-1", isConnected: false)
    delegate.remoteControlSession(session, didInvalidateWithError: .SessionNotActive)
    delegate.remoteControlSession(session, vehicleDidUpdateReport: report)
    delegate.remoteControlSession(
        session,
        didReceivePassthroughData: Data([0x10]),
        fromVehicle: "veh-1"
    )
    precondition(delegate.invalidations == [.SessionNotActive])
    precondition(delegate.reports.count == 1)
    precondition(delegate.reports[0].identifier == "veh-1")
    precondition(delegate.passthrough.count == 1)
    precondition(delegate.passthrough[0].0 == Data([0x10]))
    precondition(delegate.passthrough[0].1 == "veh-1")
}

func testDelegateDefaultDidCreateKey() {
    let session = CarKeyRemoteControlSession()
    let delegate = RequiredOnlyDelegate()
    delegate.remoteControlSession(session, didCreateKey: "key-1", forVehicle: "veh-1")
    let full = FullDelegate()
    full.remoteControlSession(session, didCreateKey: "key-2", forVehicle: "veh-2")
    precondition(full.created.count == 1)
    precondition(full.created[0].0 == "key-2")
    precondition(full.created[0].1 == "veh-2")
}
