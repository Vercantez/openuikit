import AccessorySetupKit
import Foundation

func testASAccessoryEventTypeRawValues() {
    let cases: [(ASAccessoryEventType, Int)] = [
        (.unknown, 0),
        (.activated, 10),
        (.invalidated, 11),
        (.migrationComplete, 20),
        (.accessoryAdded, 30),
        (.accessoryRemoved, 31),
        (.accessoryChanged, 32),
        (.accessoryDiscovered, 33),
        (.pickerDidPresent, 40),
        (.pickerDidDismiss, 50),
        (.pickerSetupBridging, 60),
        (.pickerSetupFailed, 70),
        (.pickerSetupPairing, 80),
        (.pickerSetupRename, 90),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ASAccessoryEventType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ASAccessoryEventType(rawValue: 1) == nil)
    precondition(ASAccessoryEventType.activated != .invalidated)
}

func testASAccessoryStateRawValues() {
    let cases: [(ASAccessory.AccessoryState, Int)] = [
        (.unauthorized, 0),
        (.awaitingAuthorization, 10),
        (.authorized, 20),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ASAccessory.AccessoryState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ASAccessory.AccessoryState(rawValue: 5) == nil)
    precondition(ASAccessory.AccessoryState.unauthorized != .authorized)
}

func testASDiscoveryDescriptorRangeRawValues() {
    let cases: [(ASDiscoveryDescriptor.Range, Int)] = [
        (.default, 0),
        (.immediate, 10),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ASDiscoveryDescriptor.Range(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ASDiscoveryDescriptor.Range(rawValue: 1) == nil)
    precondition(ASDiscoveryDescriptor.Range.default != .immediate)
}

func testASDiscoveryDescriptorWiFiAwareServiceRoleRawValues() {
    let cases: [(ASDiscoveryDescriptor.WiFiAwareServiceRole, Int)] = [
        (.subscriber, 10),
        (.publisher, 20),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ASDiscoveryDescriptor.WiFiAwareServiceRole(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ASDiscoveryDescriptor.WiFiAwareServiceRole(rawValue: 0) == nil)
    precondition(
        ASDiscoveryDescriptor.WiFiAwareServiceRole.subscriber != .publisher
    )
}
