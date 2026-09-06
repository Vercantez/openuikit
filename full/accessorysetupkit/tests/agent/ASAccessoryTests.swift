@_spi(OpenUIKitHost) import AccessorySetupKit
import Foundation

func testASAccessoryHostPropertyStorage() {
    let descriptor = ASDiscoveryDescriptor()
    descriptor.ssid = "DemoSSID"
    let identifier = UUID()
    let bridging = Data([0x01, 0x02, 0x03])
    let accessory = ASAccessory(
        hostDisplayName: "Lamp",
        hostState: .authorized,
        hostBluetoothIdentifier: identifier,
        hostSSID: "DemoSSID",
        hostDescriptor: descriptor,
        hostBluetoothTransportBridgingIdentifier: bridging,
        hostWifiAwarePairedDeviceID: 42
    )
    precondition(accessory.displayName == "Lamp")
    precondition(accessory.state == .authorized)
    precondition(accessory.bluetoothIdentifier == identifier)
    precondition(accessory.ssid == "DemoSSID")
    precondition(accessory.descriptor.ssid == "DemoSSID")
    precondition(accessory.bluetoothTransportBridgingIdentifier == bridging)
    precondition(accessory.wifiAwarePairedDeviceID == 42)
}

func testASAccessoryUnauthorizedDefaults() {
    let accessory = ASAccessory(hostDisplayName: "")
    precondition(accessory.displayName.isEmpty)
    precondition(accessory.state == .unauthorized)
    precondition(accessory.bluetoothIdentifier == nil)
    precondition(accessory.ssid == nil)
    precondition(accessory.bluetoothTransportBridgingIdentifier == nil)
    precondition(accessory.wifiAwarePairedDeviceID == 0)
}

func testASAccessoryEventHostProperties() {
    let accessory = ASAccessory(hostDisplayName: "Speaker")
    let error = ASError(.connectionFailed)
    let event = ASAccessoryEvent(
        hostEventType: .accessoryAdded,
        hostAccessory: accessory,
        hostError: error
    )
    precondition(event.eventType == .accessoryAdded)
    precondition(event.accessory === accessory)
    let typed = event.error as? ASError
    precondition(typed?.code == .connectionFailed)
}

func testASDiscoveredAccessoryHostProperties() {
    let advertisement: [AnyHashable: Any] = ["kCBAdvDataIsConnectable": true]
    let discovered = ASDiscoveredAccessory(
        hostDisplayName: "Beacon",
        hostBluetoothAdvertisementData: advertisement,
        hostBluetoothRSSI: -42
    )
    precondition(discovered.displayName == "Beacon")
    precondition(discovered.bluetoothRSSI == -42)
    precondition(discovered.bluetoothAdvertisementData?["kCBAdvDataIsConnectable"] as? Bool == true)
    precondition(discovered.state == .unauthorized)
}
