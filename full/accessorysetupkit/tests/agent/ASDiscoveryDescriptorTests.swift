@_spi(OpenUIKitHost) import AccessorySetupKit
import Foundation

func testASDiscoveryDescriptorPropertyStorage() {
    let descriptor = ASDiscoveryDescriptor()
    precondition(descriptor.supportedOptions.isEmpty)
    precondition(descriptor.bluetoothCompanyIdentifier.rawValue == 0)
    precondition(descriptor.bluetoothManufacturerDataBlob == nil)
    precondition(descriptor.bluetoothManufacturerDataMask == nil)
    precondition(descriptor.bluetoothNameSubstring == nil)
    precondition(descriptor.bluetoothNameSubstringCompareOptions.isEmpty)
    precondition(descriptor.bluetoothRange == .default)
    precondition(descriptor.bluetoothServiceDataBlob == nil)
    precondition(descriptor.bluetoothServiceDataMask == nil)
    precondition(descriptor.bluetoothServiceUUID == nil)
    precondition(descriptor.ssid == nil)
    precondition(descriptor.ssidPrefix == nil)
    precondition(descriptor.wifiAwareServiceName == nil)
    precondition(descriptor.wifiAwareServiceRole == .subscriber)
    precondition(descriptor.wifiAwareModelNameMatch == nil)
    precondition(descriptor.wifiAwareVendorNameMatch == nil)

    descriptor.supportedOptions = .bluetoothPairingLE
    descriptor.bluetoothCompanyIdentifier = ASBluetoothCompanyIdentifier(0x004C)
    descriptor.bluetoothManufacturerDataBlob = Data([0x4C, 0x00, 0x01])
    descriptor.bluetoothManufacturerDataMask = Data([0xFF, 0xFF, 0x00])
    descriptor.bluetoothNameSubstring = "Lamp"
    descriptor.bluetoothNameSubstringCompareOptions = [.caseInsensitive]
    descriptor.bluetoothRange = .immediate
    descriptor.bluetoothServiceDataBlob = Data([0xAA])
    descriptor.bluetoothServiceDataMask = Data([0xFF])
    let uuidObject = NSObject()
    descriptor.bluetoothServiceUUID = uuidObject
    descriptor.ssid = "ExactNet"
    descriptor.ssidPrefix = "Prefix"
    descriptor.wifiAwareServiceName = "nan-service"
    descriptor.wifiAwareServiceRole = .publisher
    let model = ASPropertyCompareString(string: "Model", compareOptions: [.caseInsensitive])
    let vendor = ASPropertyCompareString(string: "Vendor")
    descriptor.wifiAwareModelNameMatch = model
    descriptor.wifiAwareVendorNameMatch = vendor

    precondition(descriptor.supportedOptions.contains(.bluetoothPairingLE))
    precondition(descriptor.bluetoothCompanyIdentifier.rawValue == 0x004C)
    precondition(descriptor.bluetoothManufacturerDataBlob == Data([0x4C, 0x00, 0x01]))
    precondition(descriptor.bluetoothManufacturerDataMask == Data([0xFF, 0xFF, 0x00]))
    precondition(descriptor.bluetoothNameSubstring == "Lamp")
    precondition(descriptor.bluetoothNameSubstringCompareOptions.contains(.caseInsensitive))
    precondition(descriptor.bluetoothRange == .immediate)
    precondition(descriptor.bluetoothServiceDataBlob == Data([0xAA]))
    precondition(descriptor.bluetoothServiceDataMask == Data([0xFF]))
    precondition(descriptor.bluetoothServiceUUID === uuidObject)
    precondition(descriptor.ssid == "ExactNet")
    precondition(descriptor.ssidPrefix == "Prefix")
    precondition(descriptor.wifiAwareServiceName == "nan-service")
    precondition(descriptor.wifiAwareServiceRole == .publisher)
    precondition(descriptor.wifiAwareModelNameMatch === model)
    precondition(descriptor.wifiAwareVendorNameMatch === vendor)
}

func testASDiscoveryDescriptorManufacturerDataMatch() {
    let descriptor = ASDiscoveryDescriptor()
    precondition(descriptor.hostMatchesBluetoothManufacturerData(Data([0x00])))
    descriptor.bluetoothManufacturerDataBlob = Data([0x4C, 0x00, 0x01])
    descriptor.bluetoothManufacturerDataMask = Data([0xFF, 0xFF, 0x00])
    precondition(descriptor.hostMatchesBluetoothManufacturerData(Data([0x4C, 0x00, 0x99])))
    precondition(!descriptor.hostMatchesBluetoothManufacturerData(Data([0x4C, 0x01, 0x00])))
    precondition(!descriptor.hostMatchesBluetoothManufacturerData(Data([0x4C])))
}

func testASDiscoveryDescriptorServiceDataMatch() {
    let descriptor = ASDiscoveryDescriptor()
    descriptor.bluetoothServiceDataBlob = Data([0x0A, 0x0B])
    descriptor.bluetoothServiceDataMask = Data([0x0F, 0xFF])
    precondition(descriptor.hostMatchesBluetoothServiceData(Data([0x1A, 0x0B])))
    precondition(!descriptor.hostMatchesBluetoothServiceData(Data([0x0A, 0x0C])))
}

func testASDiscoveryDescriptorNameAndSSIDMatch() {
    let descriptor = ASDiscoveryDescriptor()
    descriptor.bluetoothNameSubstring = "lamp"
    descriptor.bluetoothNameSubstringCompareOptions = [.caseInsensitive]
    precondition(descriptor.hostMatchesBluetoothName("Kitchen Lamp"))
    precondition(!descriptor.hostMatchesBluetoothName("Speaker"))
    descriptor.ssid = "ExactNet"
    precondition(descriptor.hostMatchesSSID("ExactNet"))
    precondition(!descriptor.hostMatchesSSID("Other"))
    descriptor.ssid = nil
    descriptor.ssidPrefix = "Home"
    precondition(descriptor.hostMatchesSSID("HomeKit"))
    precondition(!descriptor.hostMatchesSSID("Office"))
}

func testASPropertyCompareString() {
    let compare = ASPropertyCompareString(
        string: "Nano",
        compareOptions: [.caseInsensitive]
    )
    precondition(compare.string == "Nano")
    precondition(compare.compareOptions.contains(.caseInsensitive))
    precondition(compare.hostMatches("nano-leaf"))
    precondition(!compare.hostMatches("other"))
    let exact = ASPropertyCompareString(string: "Exact")
    precondition(exact.compareOptions.isEmpty)
    precondition(exact.hostMatches("ExactMatch"))
}
