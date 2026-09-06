import DeviceDiscoveryExtension
import Foundation

func testDDDeviceWiFiAwareServiceRoleRawValues() {
    ddExpect(DDDevice.WiFiAwareServiceRole.subscriber.rawValue == 10, "subscriber")
    ddExpect(DDDevice.WiFiAwareServiceRole.publisher.rawValue == 20, "publisher")
}

func testDDDeviceWiFiAwareServiceRoleInitRawValue() {
    ddExpect(DDDevice.WiFiAwareServiceRole(rawValue: 10) == .subscriber, "10")
    ddExpect(DDDevice.WiFiAwareServiceRole(rawValue: 20) == .publisher, "20")
    ddExpect(DDDevice.WiFiAwareServiceRole(rawValue: 0) == nil, "zero")
    ddExpect(DDDevice.WiFiAwareServiceRole(rawValue: 15) == nil, "gap")
}

func testDDDeviceWiFiAwareServiceRoleInequality() {
    ddExpect(DDDevice.WiFiAwareServiceRole.subscriber != .publisher, "!=")
    ddExpect(!(DDDevice.WiFiAwareServiceRole.publisher != .publisher), "equal inverse")
}

func testDDDeviceWiFiAwareServiceRoleHashable() {
    var hasher = Hasher()
    DDDevice.WiFiAwareServiceRole.publisher.hash(into: &hasher)
    _ = hasher.finalize()
    ddExpect(
        DDDevice.WiFiAwareServiceRole.subscriber.hashValue
            == DDDevice.WiFiAwareServiceRole.subscriber.hashValue,
        "hashValue"
    )
    ddExpect(
        DDDevice.WiFiAwareServiceRole.subscriber.hashValue
            != DDDevice.WiFiAwareServiceRole.publisher.hashValue,
        "distinct"
    )
}
