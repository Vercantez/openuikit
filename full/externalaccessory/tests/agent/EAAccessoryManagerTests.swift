@_spi(OpenUIKitHost) import ExternalAccessory
import Foundation

func testEAAccessoryNotificationNames() {
    precondition(
        NSNotification.Name.EAAccessoryDidConnect.rawValue
            == "EAAccessoryDidConnectNotification"
    )
    precondition(
        NSNotification.Name.EAAccessoryDidDisconnect.rawValue
            == "EAAccessoryDidDisconnectNotification"
    )
}

func testEAAccessoryNotificationKeys() {
    precondition(EAAccessoryKey == "EAAccessoryKey")
    precondition(EAAccessorySelectedKey == "EAAccessorySelectedKey")
}

func testEAConnectionIDNone() {
    precondition(EAConnectionIDNone == 0)
}

func testEAAccessoryManagerShared() {
    let a = EAAccessoryManager.shared()
    let b = EAAccessoryManager.shared()
    precondition(a === b)
}

func testEAAccessoryManagerConnectedAccessoriesEmpty() {
    precondition(EAAccessoryManager.shared().connectedAccessories.isEmpty)
}

func testEAAccessoryManagerNotificationRegistration() {
    let manager = EAAccessoryManager.shared()
    let before = manager.hostNotificationRegistrationCount
    manager.registerForLocalNotifications()
    precondition(manager.hostNotificationRegistrationCount == before + 1)
    manager.unregisterForLocalNotifications()
    precondition(manager.hostNotificationRegistrationCount == before)
}

func testEAAccessoryManagerPickerFailClosed() {
    var captured: (any Error)?
    var calls = 0
    EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: nil) { error in
        captured = error
        calls += 1
    }
    precondition(calls == 1)
    let typed = captured as? EABluetoothAccessoryPickerError
    precondition(typed?.code == .resultFailed)
    let ns = captured as NSError?
    precondition(ns?.domain == EABluetoothAccessoryPickerErrorDomain)
    precondition(ns?.code == 3)
}

func testEAAccessoryHostPropertyStorage() {
    let accessory = EAAccessory.hostMakeAccessory(
        connected: false,
        connectionID: 0,
        name: "Dock",
        manufacturer: "Acme",
        modelNumber: "M1",
        serialNumber: "SN1",
        firmwareRevision: "1.0",
        hardwareRevision: "A",
        protocolStrings: ["com.example.proto"],
        dockType: "Lightning"
    )
    precondition(!accessory.isConnected)
    precondition(accessory.connectionID == 0)
    precondition(UInt(EAConnectionIDNone) == accessory.connectionID)
    precondition(accessory.name == "Dock")
    precondition(accessory.manufacturer == "Acme")
    precondition(accessory.modelNumber == "M1")
    precondition(accessory.serialNumber == "SN1")
    precondition(accessory.firmwareRevision == "1.0")
    precondition(accessory.hardwareRevision == "A")
    precondition(accessory.protocolStrings == ["com.example.proto"])
    precondition(accessory.dockType == "Lightning")
}

final class EADisconnectProbe: NSObject, EAAccessoryDelegate {
    var disconnected: EAAccessory?

    func accessoryDidDisconnect(_ accessory: EAAccessory) {
        disconnected = accessory
    }
}

func testEAAccessoryDelegateDisconnect() {
    let accessory = EAAccessory.hostMakeAccessory(
        connected: true,
        connectionID: 7,
        name: "Probe"
    )
    let probe = EADisconnectProbe()
    accessory.delegate = probe
    precondition(accessory.delegate === probe)
    accessory.hostNotifyDisconnect()
    precondition(!accessory.isConnected)
    precondition(probe.disconnected === accessory)
}

func testEASessionPublicInitFailClosed() {
    let accessory = EAAccessory.hostMakeAccessory(
        connected: true,
        connectionID: 1,
        protocolStrings: ["com.example.proto"]
    )
    let session = EASession(accessory: accessory, forProtocol: "com.example.proto")
    precondition(session == nil)
}

func testEASessionHostPropertiesNilStreams() {
    let accessory = EAAccessory.hostMakeAccessory(name: "HostSession")
    let session = EASession(hostAccessory: accessory, protocolString: "com.example.proto")
    precondition(session.accessory === accessory)
    precondition(session.protocolString == "com.example.proto")
    precondition(session.inputStream == nil)
    precondition(session.outputStream == nil)
}
