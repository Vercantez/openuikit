import DeviceDiscoveryExtension
import Foundation

func ddMakeDevice(
    name: String = "Speaker",
    category: DDDevice.Category = .hifiSpeaker,
    identifier: String = "id-1"
) -> DDDevice {
    DDDevice(
        displayName: name,
        category: category,
        protocolType: UTType("com.example.dial"),
        identifier: identifier
    )
}

func testDDDeviceInitStoresArguments() {
    let protocolType = UTType("com.example.protocol")
    let device = DDDevice(
        displayName: "Living Room",
        category: .tv,
        protocolType: protocolType,
        identifier: "tv-1"
    )
    ddExpect(device.displayName == "Living Room", "displayName")
    ddExpect(device.category == .tv, "category")
    ddExpect(device.protocolType == protocolType, "protocolType")
    ddExpect(device.identifier == "tv-1", "identifier")
}

func testDDDeviceInitDefaults() {
    let device = ddMakeDevice()
    ddExpect(device.`protocol` == .invalid, "protocol default")
    ddExpect(device.state == .invalid, "state default")
    ddExpect(device.mediaPlaybackState == .noContent, "playback default")
    ddExpect(device.deviceSupports.isEmpty, "supports default")
    ddExpect(device.supportsGrouping == false, "grouping default")
    ddExpect(device.url == URL(fileURLWithPath: "/"), "url placeholder")
    ddExpect(device.wifiAwareServiceRole == .subscriber, "role default")
    ddExpect(device.bluetoothIdentifier == nil, "bluetooth nil")
    ddExpect(device.displayImageName == nil, "image nil")
    ddExpect(device.ssid == nil, "ssid nil")
    ddExpect(device.mediaContentTitle == nil, "title nil")
    ddExpect(device.mediaContentSubtitle == nil, "subtitle nil")
    ddExpect(device.wifiAwareServiceName == nil, "service nil")
    ddExpect(device.wifiAwareModelName == nil, "model nil")
    ddExpect(device.wifiAwareVendorName == nil, "vendor nil")
    ddExpect(device.networkEndpoint == nil, "endpoint nil")
    ddExpect(device.txtRecord == nil, "txt nil")
}

func testDDDeviceDisplayNameMutation() {
    let device = ddMakeDevice()
    device.displayName = "Kitchen"
    ddExpect(device.displayName == "Kitchen", "mutated")
}

func testDDDeviceCategoryMutation() {
    let device = ddMakeDevice()
    device.category = .laptopComputer
    ddExpect(device.category == .laptopComputer, "mutated")
}

func testDDDeviceIdentifierMutation() {
    let device = ddMakeDevice()
    device.identifier = "id-2"
    ddExpect(device.identifier == "id-2", "mutated")
}

func testDDDeviceProtocolTypeMutation() {
    let device = ddMakeDevice()
    let next = UTType("public.data")
    device.protocolType = next
    ddExpect(device.protocolType == next, "mutated")
}

func testDDDeviceProtocolMutation() {
    let device = ddMakeDevice()
    device.`protocol` = .dial
    ddExpect(device.`protocol` == .dial, "mutated")
}

func testDDDeviceStateMutation() {
    let device = ddMakeDevice()
    device.state = .activated
    ddExpect(device.state == .activated, "mutated")
}

func testDDDeviceBluetoothIdentifierMutation() {
    let device = ddMakeDevice()
    let uuid = UUID()
    device.bluetoothIdentifier = uuid
    ddExpect(device.bluetoothIdentifier == uuid, "mutated")
    device.bluetoothIdentifier = nil
    ddExpect(device.bluetoothIdentifier == nil, "cleared")
}

func testDDDeviceDisplayImageNameMutation() {
    let device = ddMakeDevice()
    device.displayImageName = "speaker"
    ddExpect(device.displayImageName == "speaker", "mutated")
}

func testDDDeviceSSIDMutation() {
    let device = ddMakeDevice()
    device.ssid = "HomeNet"
    ddExpect(device.ssid == "HomeNet", "mutated")
}

func testDDDeviceMediaContentTitleMutation() {
    let device = ddMakeDevice()
    device.mediaContentTitle = "Track"
    ddExpect(device.mediaContentTitle == "Track", "mutated")
}

func testDDDeviceMediaContentSubtitleMutation() {
    let device = ddMakeDevice()
    device.mediaContentSubtitle = "Artist"
    ddExpect(device.mediaContentSubtitle == "Artist", "mutated")
}

func testDDDeviceMediaPlaybackStateMutation() {
    let device = ddMakeDevice()
    device.mediaPlaybackState = .playing
    ddExpect(device.mediaPlaybackState == .playing, "mutated")
}

func testDDDeviceDeviceSupportsMutation() {
    let device = ddMakeDevice()
    device.deviceSupports = [.bluetoothHID, .bluetoothPairingLE]
    ddExpect(device.deviceSupports.contains(.bluetoothHID), "HID")
    ddExpect(device.deviceSupports.contains(.bluetoothPairingLE), "LE")
}

func testDDDeviceSupportsGroupingMutation() {
    let device = ddMakeDevice()
    device.supportsGrouping = true
    ddExpect(device.supportsGrouping, "mutated")
}

func testDDDeviceURLMutation() {
    let device = ddMakeDevice()
    let url = URL(string: "https://example.invalid/device")!
    device.url = url
    ddExpect(device.url == url, "mutated")
}

func testDDDeviceWifiAwareServiceNameMutation() {
    let device = ddMakeDevice()
    device.wifiAwareServiceName = "aware-svc"
    ddExpect(device.wifiAwareServiceName == "aware-svc", "mutated")
}

func testDDDeviceWifiAwareModelNameMutation() {
    let device = ddMakeDevice()
    device.wifiAwareModelName = "Model X"
    ddExpect(device.wifiAwareModelName == "Model X", "mutated")
}

func testDDDeviceWifiAwareVendorNameMutation() {
    let device = ddMakeDevice()
    device.wifiAwareVendorName = "Vendor"
    ddExpect(device.wifiAwareVendorName == "Vendor", "mutated")
}

func testDDDeviceWifiAwareServiceRoleMutation() {
    let device = ddMakeDevice()
    device.wifiAwareServiceRole = .publisher
    ddExpect(device.wifiAwareServiceRole == .publisher, "mutated")
}

func testDDDeviceNetworkEndpointStoredNotOpened() {
    let device = ddMakeDevice()
    device.networkEndpoint = .hostPort(host: "192.0.2.10", port: 8009)
    ddExpect(device.networkEndpoint == .hostPort(host: "192.0.2.10", port: 8009), "stored")
    device.networkEndpoint = nil
    ddExpect(device.networkEndpoint == nil, "cleared")
}

func testDDDeviceTXTRecordStoredNotPublished() {
    let device = ddMakeDevice()
    let record = NWTXTRecord(Data([0x01, 0x02]))
    device.txtRecord = record
    ddExpect(device.txtRecord == record, "stored")
    device.txtRecord = nil
    ddExpect(device.txtRecord == nil, "cleared")
}
