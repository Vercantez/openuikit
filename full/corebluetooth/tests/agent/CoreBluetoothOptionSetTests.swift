@_spi(OpenUIKitHost) import CoreBluetooth
import Foundation

func testCBCharacteristicPropertiesMembers() {
    let members: [(CBCharacteristicProperties, UInt)] = [
        (.broadcast, 1 << 0),
        (.read, 1 << 1),
        (.writeWithoutResponse, 1 << 2),
        (.write, 1 << 3),
        (.notify, 1 << 4),
        (.indicate, 1 << 5),
        (.authenticatedSignedWrites, 1 << 6),
        (.extendedProperties, 1 << 7),
        (.notifyEncryptionRequired, 1 << 8),
        (.indicateEncryptionRequired, 1 << 9),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(CBCharacteristicProperties(rawValue: raw) == member)
    }
    precondition(CBCharacteristicProperties.read != .write)
    precondition(CBCharacteristicProperties.authenticatedSignedWrites.rawValue == 0x40)
}

func testCBCharacteristicPropertiesAlgebra() {
    var properties: CBCharacteristicProperties = [.read, .notify]
    precondition(properties.contains(.read))
    properties.insert(.write)
    _ = properties.remove(.notify)
    _ = properties.update(with: .indicate)
    let unioned = CBCharacteristicProperties.read.union(.write)
    precondition(unioned.intersection(.read) == .read)
    precondition(unioned.subtracting(.write) == .read)
    precondition(unioned.isSuperset(of: .read))
    precondition(CBCharacteristicProperties.read.isSubset(of: unioned))
    precondition(CBCharacteristicProperties.read.isDisjoint(with: .write))
    precondition(unioned.symmetricDifference(.read) == .write)
    var mutable = CBCharacteristicProperties.read
    mutable.formUnion(.write)
    mutable.formIntersection(.write)
    mutable.formSymmetricDifference(.notify)
    mutable.subtract(.notify)
    _ = CBCharacteristicProperties([.read, .write])
    _ = CBCharacteristicProperties()
    _ = CBCharacteristicProperties(arrayLiteral: .broadcast, .extendedProperties)
    precondition(CBCharacteristicProperties.read.isStrictSubset(of: [.read, .write]))
    precondition(CBCharacteristicProperties([.read, .write]).isStrictSuperset(of: .read))
    precondition(CBCharacteristicProperties().isEmpty)
    precondition(!CBCharacteristicProperties.read.isEmpty)
}

func testCBAttributePermissionsMembers() {
    let members: [(CBAttributePermissions, UInt)] = [
        (.readable, 1 << 0),
        (.writeable, 1 << 1),
        (.readEncryptionRequired, 1 << 2),
        (.writeEncryptionRequired, 1 << 3),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(CBAttributePermissions(rawValue: raw) == member)
    }
    precondition(CBAttributePermissions.readable != .writeable)
}

func testCBAttributePermissionsAlgebra() {
    var permissions: CBAttributePermissions = [.readable]
    permissions.insert(.writeable)
    _ = permissions.union(.readEncryptionRequired)
    _ = permissions.intersection(.readable)
    _ = permissions.subtracting(.writeable)
    _ = permissions.symmetricDifference(.readable)
    _ = permissions.isSubset(of: [.readable, .writeable])
    _ = permissions.isSuperset(of: .readable)
    _ = permissions.isDisjoint(with: .writeEncryptionRequired)
    _ = permissions.contains(.readable)
    _ = permissions.isEmpty
    _ = CBAttributePermissions()
    _ = CBAttributePermissions(arrayLiteral: .readable)
    _ = CBAttributePermissions([.readable, .writeable])
    var permMut = CBAttributePermissions.readable
    permMut.formUnion(.writeable)
    permMut.formIntersection(.writeable)
    permMut.formSymmetricDifference(.readable)
    permMut.subtract(.readable)
    _ = permMut.remove(.writeable)
    _ = permMut.update(with: .readable)
    precondition(CBAttributePermissions.readable.isStrictSubset(of: [.readable, .writeable]))
    precondition(CBAttributePermissions([.readable, .writeable]).isStrictSuperset(of: .readable))
}

func testCBCentralManagerFeatureMembers() {
    precondition(CBCentralManager.Feature.extendedScanAndConnect.rawValue != 0)
    precondition(
        CBCentralManager.Feature(rawValue: CBCentralManager.Feature.extendedScanAndConnect.rawValue)
            == .extendedScanAndConnect
    )
    precondition(CBCentralManager.Feature() != .extendedScanAndConnect)
}

func testCBCentralManagerFeatureAlgebra() {
    var feature = CBCentralManager.Feature()
    feature.insert(.extendedScanAndConnect)
    precondition(feature.contains(.extendedScanAndConnect))
    _ = feature.union(.extendedScanAndConnect)
    _ = feature.intersection(.extendedScanAndConnect)
    _ = feature.subtracting(.extendedScanAndConnect)
    _ = feature.symmetricDifference(.extendedScanAndConnect)
    _ = feature.isSubset(of: .extendedScanAndConnect)
    _ = feature.isSuperset(of: [])
    _ = feature.isDisjoint(with: [])
    _ = feature.isEmpty
    _ = CBCentralManager.Feature(arrayLiteral: .extendedScanAndConnect)
    _ = CBCentralManager.Feature([.extendedScanAndConnect])
    var featMut = CBCentralManager.Feature.extendedScanAndConnect
    featMut.formUnion([])
    featMut.formIntersection(.extendedScanAndConnect)
    featMut.formSymmetricDifference([])
    featMut.subtract([])
    _ = featMut.remove(.extendedScanAndConnect)
    _ = featMut.update(with: .extendedScanAndConnect)
    precondition(CBCentralManager.Feature().isEmpty)
    precondition(CBCentralManager.Feature().isStrictSubset(of: .extendedScanAndConnect))
    precondition(CBCentralManager.Feature.extendedScanAndConnect.isStrictSuperset(of: []))
}
