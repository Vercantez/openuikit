import CarKey
import Foundation

func testRegisterAndUnregisterLaunchEvents() {
    expectCarKeyError(.FeatureNotSupported) {
        try CarKeyRemoteControl.registerForLaunchOnCarKeyEvent()
    }
    expectCarKeyError(.FeatureNotSupported) {
        try CarKeyRemoteControl.unregisterForLaunchOnCarKeyEvent()
    }
}

func testInactiveSessionVehicleReports() {
    let session = CarKeyRemoteControlSession()
    expectCarKeyError(.SessionNotActive) {
        _ = try session.vehicleReports
    }
}

func testInactiveSessionEnd() {
    let session = CarKeyRemoteControlSession()
    expectCarKeyError(.SessionNotActive) {
        try session.end()
    }
}

func testInactiveSessionPerformAction() {
    let session = CarKeyRemoteControlSession()
    let action = RemoteKeylessEntryAction(
        functionID: FunctionIdentifier(1),
        actionID: ActionIdentifier(1),
        vehicleID: "none"
    )
    expectCarKeyError(.SessionNotActive) {
        _ = try session.perform(action)
    }
}

func testInactiveSessionPerformEnduringAction() {
    let session = CarKeyRemoteControlSession()
    let action = RemoteKeylessEntryEnduringAction(
        functionID: FunctionIdentifier(1),
        actionID: ActionIdentifier(1),
        vehicleID: "none"
    )
    expectCarKeyError(.SessionNotActive) {
        _ = try session.perform(action)
    }
}

func testInactiveSessionPerformConfigurableAction() {
    let session = CarKeyRemoteControlSession()
    let action = RemoteKeylessEntryConfigurableEnduringAction(
        functionID: FunctionIdentifier(1),
        actionID: ActionIdentifier(1),
        vehicleID: "none"
    )
    expectCarKeyError(.SessionNotActive) {
        _ = try session.perform(action, continuationStrategy: .manual)
    }
    expectCarKeyError(.SessionNotActive) {
        _ = try session.perform(action, continuationStrategy: .automatic)
    }
}

func testInactiveSessionSendPassthrough() {
    let session = CarKeyRemoteControlSession()
    expectCarKeyError(.SessionNotActive) {
        try session.sendPassthroughData(Data([0x00]), toVehicle: "none")
    }
}

func testInactiveSessionPassiveEntry() {
    let session = CarKeyRemoteControlSession()
    expectCarKeyError(.SessionNotActive) {
        _ = try session.isPassiveEntryAvailable(forVehicle: "none")
    }
}

func testInactiveSessionSign() {
    let session = CarKeyRemoteControlSession()
    expectCarKeyError(.SessionNotActive) {
        _ = try session.sign(data: Data([0x11]), forVehicle: "none")
    }
}

func testAttestationStoredProperties() {
    let nonce = Data("nonce-bytes".utf8)
    let signed = Data([0xDE, 0xAD])
    let signature = Data([0xBE, 0xEF])
    let attestation = CarKeyRemoteControlSession.Attestation(
        appBundleIdentifier: "com.example.carkey",
        nonce: nonce,
        signedData: signed,
        signature: signature
    )
    precondition(attestation.appBundleIdentifier == "com.example.carkey")
    precondition(attestation.nonce == nonce)
    precondition(attestation.signedData == signed)
    precondition(attestation.signature == signature)
}
