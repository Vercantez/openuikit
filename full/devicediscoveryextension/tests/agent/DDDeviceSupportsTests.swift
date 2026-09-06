import DeviceDiscoveryExtension
import Foundation

func testDDDeviceSupportsMembers() {
    ddExpect(DDDeviceSupports.bluetoothPairingLE.rawValue == 1 << 1, "LE bit")
    ddExpect(DDDeviceSupports.bluetoothTransportBridging.rawValue == 1 << 2, "bridge bit")
    ddExpect(DDDeviceSupports.bluetoothHID.rawValue == 1 << 3, "HID bit")
}

func testDDDeviceSupportsInitRawValue() {
    let combined = DDDeviceSupports(rawValue: (1 << 1) | (1 << 3))
    ddExpect(combined.contains(.bluetoothPairingLE), "LE")
    ddExpect(combined.contains(.bluetoothHID), "HID")
    ddExpect(!combined.contains(.bluetoothTransportBridging), "no bridge")
}

func testDDDeviceSupportsInitEmpty() {
    let empty = DDDeviceSupports()
    ddExpect(empty.rawValue == 0, "zero")
    ddExpect(empty.isEmpty, "isEmpty")
}

func testDDDeviceSupportsInitArrayLiteral() {
    let value: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    ddExpect(value.contains(.bluetoothPairingLE), "LE")
    ddExpect(value.contains(.bluetoothHID), "HID")
    ddExpect(!value.contains(.bluetoothTransportBridging), "no bridge")
}

func testDDDeviceSupportsInitSequence() {
    let value = DDDeviceSupports([DDDeviceSupports.bluetoothTransportBridging, .bluetoothHID])
    ddExpect(value.contains(.bluetoothTransportBridging), "bridge")
    ddExpect(value.contains(.bluetoothHID), "HID")
}

func testDDDeviceSupportsContains() {
    let value: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    ddExpect(value.contains(.bluetoothPairingLE), "member")
    ddExpect(!value.contains(.bluetoothTransportBridging), "absent")
}

func testDDDeviceSupportsInsert() {
    var value = DDDeviceSupports()
    let first = value.insert(.bluetoothPairingLE)
    ddExpect(first.inserted, "first insert")
    ddExpect(first.memberAfterInsert == .bluetoothPairingLE, "member")
    let second = value.insert(.bluetoothPairingLE)
    ddExpect(!second.inserted, "duplicate")
    ddExpect(value.contains(.bluetoothPairingLE), "retained")
}

func testDDDeviceSupportsRemove() {
    var value: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    let removed = value.remove(.bluetoothPairingLE)
    ddExpect(removed == .bluetoothPairingLE, "removed")
    ddExpect(!value.contains(.bluetoothPairingLE), "gone")
    ddExpect(value.remove(.bluetoothTransportBridging) == nil, "absent")
}

func testDDDeviceSupportsUpdate() {
    var value: DDDeviceSupports = [.bluetoothPairingLE]
    let previous = value.update(with: .bluetoothHID)
    ddExpect(previous == nil, "new member")
    ddExpect(value.contains(.bluetoothHID), "inserted by update")
    let again = value.update(with: .bluetoothHID)
    ddExpect(again == .bluetoothHID, "existing")
}

func testDDDeviceSupportsUnion() {
    let left: DDDeviceSupports = [.bluetoothPairingLE]
    let right: DDDeviceSupports = [.bluetoothHID]
    let combined = left.union(right)
    ddExpect(combined.contains(.bluetoothPairingLE), "LE")
    ddExpect(combined.contains(.bluetoothHID), "HID")
    ddExpect(!left.contains(.bluetoothHID), "left unchanged")
}

func testDDDeviceSupportsIntersection() {
    let left: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    let right: DDDeviceSupports = [.bluetoothHID, .bluetoothTransportBridging]
    let both = left.intersection(right)
    ddExpect(both == .bluetoothHID, "HID only")
}

func testDDDeviceSupportsSymmetricDifference() {
    let left: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    let right: DDDeviceSupports = [.bluetoothHID, .bluetoothTransportBridging]
    let diff = left.symmetricDifference(right)
    ddExpect(diff.contains(.bluetoothPairingLE), "LE")
    ddExpect(diff.contains(.bluetoothTransportBridging), "bridge")
    ddExpect(!diff.contains(.bluetoothHID), "HID dropped")
}

func testDDDeviceSupportsSubtracting() {
    let left: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    let result = left.subtracting(.bluetoothPairingLE)
    ddExpect(result == .bluetoothHID, "HID remains")
    ddExpect(left.contains(.bluetoothPairingLE), "left unchanged")
}

func testDDDeviceSupportsFormUnion() {
    var value: DDDeviceSupports = [.bluetoothPairingLE]
    value.formUnion(.bluetoothHID)
    ddExpect(value.contains(.bluetoothPairingLE) && value.contains(.bluetoothHID), "both")
}

func testDDDeviceSupportsFormIntersection() {
    var value: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    value.formIntersection(.bluetoothHID)
    ddExpect(value == .bluetoothHID, "HID")
}

func testDDDeviceSupportsFormSymmetricDifference() {
    var value: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    value.formSymmetricDifference([.bluetoothHID, .bluetoothTransportBridging])
    ddExpect(value.contains(.bluetoothPairingLE), "LE")
    ddExpect(value.contains(.bluetoothTransportBridging), "bridge")
    ddExpect(!value.contains(.bluetoothHID), "HID")
}

func testDDDeviceSupportsSubtract() {
    var value: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    value.subtract(.bluetoothHID)
    ddExpect(value == .bluetoothPairingLE, "LE remains")
}

func testDDDeviceSupportsIsEmpty() {
    ddExpect(DDDeviceSupports().isEmpty, "empty")
    ddExpect(!DDDeviceSupports.bluetoothHID.isEmpty, "nonempty")
}

func testDDDeviceSupportsIsSubset() {
    let subset: DDDeviceSupports = [.bluetoothPairingLE]
    let superset: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    ddExpect(subset.isSubset(of: superset), "subset")
    ddExpect(subset.isSubset(of: subset), "equal is subset")
    ddExpect(!superset.isSubset(of: subset), "not subset")
}

func testDDDeviceSupportsIsSuperset() {
    let subset: DDDeviceSupports = [.bluetoothPairingLE]
    let superset: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    ddExpect(superset.isSuperset(of: subset), "superset")
    ddExpect(!subset.isSuperset(of: superset), "not")
}

func testDDDeviceSupportsIsDisjoint() {
    ddExpect(
        DDDeviceSupports.bluetoothPairingLE.isDisjoint(with: .bluetoothHID),
        "disjoint"
    )
    ddExpect(
        !DDDeviceSupports.bluetoothPairingLE.isDisjoint(with: [.bluetoothPairingLE, .bluetoothHID]),
        "overlap"
    )
}

func testDDDeviceSupportsIsStrictSubset() {
    let subset: DDDeviceSupports = [.bluetoothPairingLE]
    let superset: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    ddExpect(subset.isStrictSubset(of: superset), "strict")
    ddExpect(!subset.isStrictSubset(of: subset), "equal is not strict")
}

func testDDDeviceSupportsIsStrictSuperset() {
    let subset: DDDeviceSupports = [.bluetoothPairingLE]
    let superset: DDDeviceSupports = [.bluetoothPairingLE, .bluetoothHID]
    ddExpect(superset.isStrictSuperset(of: subset), "strict")
    ddExpect(!superset.isStrictSuperset(of: superset), "equal is not strict")
}

func testDDDeviceSupportsInequality() {
    ddExpect(DDDeviceSupports.bluetoothHID != .bluetoothPairingLE, "!=")
    ddExpect(!(DDDeviceSupports.bluetoothHID != .bluetoothHID), "equal inverse")
}
