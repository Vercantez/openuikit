import DeviceDiscoveryExtension
import Foundation

func testDDDeviceStateRawValues() {
    ddExpect(DDDeviceState.invalid.rawValue == 0, "invalid")
    ddExpect(DDDeviceState.activating.rawValue == 10, "activating")
    ddExpect(DDDeviceState.activated.rawValue == 20, "activated")
    ddExpect(DDDeviceState.authorized.rawValue == 25, "authorized")
    ddExpect(DDDeviceState.invalidating.rawValue == 30, "invalidating")
}

func testDDDeviceStateInitRawValue() {
    ddExpect(DDDeviceState(rawValue: 0) == .invalid, "0")
    ddExpect(DDDeviceState(rawValue: 25) == .authorized, "25")
    ddExpect(DDDeviceState(rawValue: 1) == nil, "gap")
    ddExpect(DDDeviceState(rawValue: 15) == nil, "between")
}

func testDDDeviceStateInequality() {
    ddExpect(DDDeviceState.activated != .activating, "!=")
    ddExpect(!(DDDeviceState.invalid != .invalid), "equal inverse")
}

func testDDDeviceStateHashable() {
    var hasher = Hasher()
    DDDeviceState.authorized.hash(into: &hasher)
    _ = hasher.finalize()
    ddExpect(DDDeviceState.activated.hashValue == DDDeviceState.activated.hashValue, "hashValue")
    ddExpect(DDDeviceState.activated.hashValue != DDDeviceState.invalid.hashValue, "distinct")
}

func testDDDeviceStateToString() {
    ddExpect(DDDeviceStateToString(.invalid) == "DDDeviceStateInvalid", "invalid")
    ddExpect(DDDeviceStateToString(.activating) == "DDDeviceStateActivating", "activating")
    ddExpect(DDDeviceStateToString(.activated) == "DDDeviceStateActivated", "activated")
    ddExpect(DDDeviceStateToString(.authorized) == "DDDeviceStateAuthorized", "authorized")
    ddExpect(DDDeviceStateToString(.invalidating) == "DDDeviceStateInvalidating", "invalidating")
}
