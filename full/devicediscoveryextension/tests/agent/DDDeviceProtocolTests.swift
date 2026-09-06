import DeviceDiscoveryExtension
import Foundation

func testDDDeviceProtocolRawValues() {
    ddExpect(DDDeviceProtocol.invalid.rawValue == 0, "invalid")
    ddExpect(DDDeviceProtocol.dial.rawValue == 1, "dial")
}

func testDDDeviceProtocolInitRawValue() {
    ddExpect(DDDeviceProtocol(rawValue: 0) == .invalid, "0")
    ddExpect(DDDeviceProtocol(rawValue: 1) == .dial, "1")
    ddExpect(DDDeviceProtocol(rawValue: 2) == nil, "unknown")
}

func testDDDeviceProtocolInequality() {
    ddExpect(DDDeviceProtocol.invalid != .dial, "!=")
    ddExpect(!(DDDeviceProtocol.dial != .dial), "equal inverse")
}

func testDDDeviceProtocolHashable() {
    var hasher = Hasher()
    DDDeviceProtocol.dial.hash(into: &hasher)
    _ = hasher.finalize()
    ddExpect(DDDeviceProtocol.dial.hashValue == DDDeviceProtocol.dial.hashValue, "hashValue")
    ddExpect(DDDeviceProtocol.invalid.hashValue != DDDeviceProtocol.dial.hashValue, "distinct")
}

func testDDDeviceProtocolToString() {
    ddExpect(DDDeviceProtocolToString(.invalid) == "DDDeviceProtocolInvalid", "invalid")
    ddExpect(DDDeviceProtocolToString(.dial) == "DDDeviceProtocolDIAL", "dial")
}

func testDDDeviceProtocolStringConstants() {
    ddExpect(DDDeviceProtocolString.invalid.rawValue == "DDDeviceProtocolStringInvalid", "invalid raw")
    ddExpect(DDDeviceProtocolString.dial.rawValue == "DDDeviceProtocolStringDIAL", "dial raw")
    ddExpect(DDDeviceProtocolString.invalid != DDDeviceProtocolString.dial, "distinct")
}

func testDDDeviceProtocolStringInitRawValue() {
    let custom = DDDeviceProtocolString(rawValue: "com.example.proto")
    ddExpect(custom.rawValue == "com.example.proto", "custom raw")
    ddExpect(custom != .dial, "not dial")
}

func testDDDeviceProtocolStringInequality() {
    ddExpect(DDDeviceProtocolString.dial != .invalid, "!=")
    ddExpect(!(DDDeviceProtocolString.dial != DDDeviceProtocolString(rawValue: "DDDeviceProtocolStringDIAL")), "equal inverse")
}

func testDDDeviceProtocolStringHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    DDDeviceProtocolString.dial.hash(into: &hasherA)
    DDDeviceProtocolString.dial.hash(into: &hasherB)
    ddExpect(hasherA.finalize() == hasherB.finalize(), "hash(into:)")
    ddExpect(DDDeviceProtocolString.dial.hashValue == DDDeviceProtocolString.dial.hashValue, "hashValue")
    ddExpect(DDDeviceProtocolString.dial.hashValue != DDDeviceProtocolString.invalid.hashValue, "distinct")
}
