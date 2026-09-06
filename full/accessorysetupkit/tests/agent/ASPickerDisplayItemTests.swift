@_spi(OpenUIKitHost) import AccessorySetupKit
import Foundation

func testASPickerDisplayItemInit() {
    let descriptor = ASDiscoveryDescriptor()
    descriptor.ssidPrefix = "Demo"
    let image = NSObject()
    let item = ASPickerDisplayItem(
        name: "Demo Lamp",
        productImage: image,
        descriptor: descriptor
    )
    precondition(item.name == "Demo Lamp")
    precondition(item.productImage === image)
    precondition(item.descriptor === descriptor)
    precondition(item.renameOptions.isEmpty)
    precondition(item.setupOptions.isEmpty)
    item.renameOptions = .ssid
    item.setupOptions = [.rename, .finishInApp]
    precondition(item.renameOptions.contains(.ssid))
    precondition(item.setupOptions.contains(.rename))
    precondition(item.setupOptions.contains(.finishInApp))
}

func testASMigrationDisplayItemProperties() {
    let descriptor = ASDiscoveryDescriptor()
    let item = ASMigrationDisplayItem(
        name: "Migrated",
        productImage: NSObject(),
        descriptor: descriptor
    )
    precondition(item.name == "Migrated")
    precondition(item.hotspotSSID == nil)
    precondition(item.peripheralIdentifier == nil)
    precondition(item.wifiAwarePairedDeviceID == 0)
    let peripheral = UUID()
    item.hotspotSSID = "Hotspot"
    item.peripheralIdentifier = peripheral
    item.wifiAwarePairedDeviceID = 7
    precondition(item.hotspotSSID == "Hotspot")
    precondition(item.peripheralIdentifier == peripheral)
    precondition(item.wifiAwarePairedDeviceID == 7)
}

func testASDiscoveredDisplayItemInit() {
    let accessory = ASDiscoveredAccessory(hostDisplayName: "Found")
    let image = NSObject()
    let item = ASDiscoveredDisplayItem(
        name: "Found",
        productImage: image,
        accessory: accessory
    )
    precondition(item.name == "Found")
    precondition(item.productImage === image)
    precondition(item.hostDiscoveredAccessory === accessory)
    precondition(item.descriptor === accessory.descriptor)
}

func testASAccessorySettingsStorage() {
    let settings = ASAccessorySettings.default
    precondition(settings.ssid == nil)
    precondition(settings.bluetoothTransportBridgingIdentifier == nil)
    settings.ssid = "Assigned"
    settings.bluetoothTransportBridgingIdentifier = Data([0x10])
    precondition(settings.ssid == "Assigned")
    precondition(settings.bluetoothTransportBridgingIdentifier == Data([0x10]))
    let fresh = ASAccessorySettings()
    precondition(fresh.ssid == nil)
}
