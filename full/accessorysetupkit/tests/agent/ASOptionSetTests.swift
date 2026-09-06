import AccessorySetupKit
import Foundation

func testASAccessoryRenameOptionsMembers() {
    precondition(ASAccessory.RenameOptions.ssid.rawValue == 1 << 0)
    precondition(ASAccessory.RenameOptions(rawValue: 1 << 0) == .ssid)
    precondition(ASAccessory.RenameOptions(rawValue: 0).isEmpty)
    precondition(ASAccessory.RenameOptions.ssid != ASAccessory.RenameOptions())
}

func testASAccessoryRenameOptionsAlgebra() {
    var options: ASAccessory.RenameOptions = [.ssid]
    precondition(options.contains(.ssid))
    let inserted = options.insert(.ssid)
    precondition(!inserted.inserted)
    _ = options.remove(.ssid)
    precondition(options.isEmpty)
    options.update(with: .ssid)
    precondition(options.contains(.ssid))
    let unioned = ASAccessory.RenameOptions.ssid.union([])
    precondition(unioned.intersection(.ssid) == .ssid)
    precondition(unioned.subtracting(.ssid).isEmpty)
    precondition(unioned.isSuperset(of: .ssid))
    precondition(ASAccessory.RenameOptions.ssid.isSubset(of: unioned))
    precondition(ASAccessory.RenameOptions().isDisjoint(with: .ssid))
    precondition(
        unioned.symmetricDifference(.ssid).isEmpty
    )
    var mutable = ASAccessory.RenameOptions()
    mutable.formUnion(.ssid)
    mutable.formIntersection(.ssid)
    mutable.formSymmetricDifference(.ssid)
    mutable.subtract(.ssid)
    _ = ASAccessory.RenameOptions([.ssid])
    _ = ASAccessory.RenameOptions()
    _ = ASAccessory.RenameOptions(arrayLiteral: .ssid)
    precondition(ASAccessory.RenameOptions().isEmpty)
    precondition(!ASAccessory.RenameOptions.ssid.isEmpty)
    precondition(ASAccessory.RenameOptions().isStrictSubset(of: .ssid))
    precondition(ASAccessory.RenameOptions.ssid.isStrictSuperset(of: []))
}

func testASAccessorySupportOptionsMembers() {
    let members: [(ASAccessory.SupportOptions, UInt)] = [
        (.bluetoothPairingLE, 1 << 1),
        (.bluetoothTransportBridging, 1 << 2),
        (.bluetoothHID, 1 << 3),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(ASAccessory.SupportOptions(rawValue: raw) == member)
    }
    precondition(
        ASAccessory.SupportOptions.bluetoothPairingLE
            != .bluetoothTransportBridging
    )
}

func testASAccessorySupportOptionsAlgebra() {
    var options: ASAccessory.SupportOptions = [
        .bluetoothPairingLE, .bluetoothHID
    ]
    precondition(options.contains(.bluetoothPairingLE))
    options.insert(.bluetoothTransportBridging)
    _ = options.remove(.bluetoothHID)
    _ = options.update(with: .bluetoothHID)
    let unioned = ASAccessory.SupportOptions.bluetoothPairingLE
        .union(.bluetoothTransportBridging)
    precondition(
        unioned.intersection(.bluetoothPairingLE) == .bluetoothPairingLE
    )
    precondition(
        unioned.subtracting(.bluetoothTransportBridging) == .bluetoothPairingLE
    )
    precondition(unioned.isSuperset(of: .bluetoothPairingLE))
    precondition(ASAccessory.SupportOptions.bluetoothPairingLE.isSubset(of: unioned))
    precondition(
        ASAccessory.SupportOptions.bluetoothPairingLE
            .isDisjoint(with: .bluetoothHID)
    )
    precondition(
        unioned.symmetricDifference(.bluetoothPairingLE)
            == .bluetoothTransportBridging
    )
    var mutable = ASAccessory.SupportOptions.bluetoothPairingLE
    mutable.formUnion(.bluetoothTransportBridging)
    mutable.formIntersection(.bluetoothTransportBridging)
    mutable.formSymmetricDifference(.bluetoothHID)
    mutable.subtract(.bluetoothHID)
    _ = ASAccessory.SupportOptions([
        .bluetoothPairingLE, .bluetoothHID
    ])
    _ = ASAccessory.SupportOptions()
    _ = ASAccessory.SupportOptions(
        arrayLiteral: .bluetoothPairingLE, .bluetoothHID
    )
    precondition(
        ASAccessory.SupportOptions.bluetoothPairingLE.isStrictSubset(of: unioned)
    )
    precondition(unioned.isStrictSuperset(of: .bluetoothPairingLE))
    precondition(ASAccessory.SupportOptions().isEmpty)
    precondition(!ASAccessory.SupportOptions.bluetoothHID.isEmpty)
}

func testASPickerDisplayItemSetupOptionsMembers() {
    let members: [(ASPickerDisplayItem.SetupOptions, UInt)] = [
        (.rename, 1 << 0),
        (.confirmAuthorization, 1 << 1),
        (.finishInApp, 1 << 2),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(ASPickerDisplayItem.SetupOptions(rawValue: raw) == member)
    }
    precondition(
        ASPickerDisplayItem.SetupOptions.rename
            != .confirmAuthorization
    )
}

func testASPickerDisplayItemSetupOptionsAlgebra() {
    var options: ASPickerDisplayItem.SetupOptions = [.rename, .finishInApp]
    precondition(options.contains(.rename))
    options.insert(.confirmAuthorization)
    _ = options.remove(.finishInApp)
    _ = options.update(with: .finishInApp)
    let unioned = ASPickerDisplayItem.SetupOptions.rename
        .union(.confirmAuthorization)
    precondition(unioned.intersection(.rename) == .rename)
    precondition(unioned.subtracting(.confirmAuthorization) == .rename)
    precondition(unioned.isSuperset(of: .rename))
    precondition(ASPickerDisplayItem.SetupOptions.rename.isSubset(of: unioned))
    precondition(
        ASPickerDisplayItem.SetupOptions.rename.isDisjoint(with: .finishInApp)
    )
    precondition(
        unioned.symmetricDifference(.rename) == .confirmAuthorization
    )
    var mutable = ASPickerDisplayItem.SetupOptions.rename
    mutable.formUnion(.confirmAuthorization)
    mutable.formIntersection(.confirmAuthorization)
    mutable.formSymmetricDifference(.finishInApp)
    mutable.subtract(.finishInApp)
    _ = ASPickerDisplayItem.SetupOptions([.rename, .finishInApp])
    _ = ASPickerDisplayItem.SetupOptions()
    _ = ASPickerDisplayItem.SetupOptions(arrayLiteral: .rename, .finishInApp)
    precondition(
        ASPickerDisplayItem.SetupOptions.rename.isStrictSubset(of: unioned)
    )
    precondition(unioned.isStrictSuperset(of: .rename))
    precondition(ASPickerDisplayItem.SetupOptions().isEmpty)
    precondition(!ASPickerDisplayItem.SetupOptions.finishInApp.isEmpty)
}

func testASPickerDisplaySettingsOptionsMembers() {
    precondition(
        ASPickerDisplaySettings.Options.filterDiscoveryResults.rawValue == 1 << 0
    )
    precondition(
        ASPickerDisplaySettings.Options(rawValue: 1 << 0)
            == .filterDiscoveryResults
    )
    precondition(
        ASPickerDisplaySettings.Options.filterDiscoveryResults
            != ASPickerDisplaySettings.Options()
    )
}

func testASPickerDisplaySettingsOptionsAlgebra() {
    var options: ASPickerDisplaySettings.Options = [.filterDiscoveryResults]
    precondition(options.contains(.filterDiscoveryResults))
    let inserted = options.insert(.filterDiscoveryResults)
    precondition(!inserted.inserted)
    _ = options.remove(.filterDiscoveryResults)
    precondition(options.isEmpty)
    options.update(with: .filterDiscoveryResults)
    let unioned = ASPickerDisplaySettings.Options.filterDiscoveryResults.union([])
    precondition(
        unioned.intersection(.filterDiscoveryResults) == .filterDiscoveryResults
    )
    precondition(unioned.subtracting(.filterDiscoveryResults).isEmpty)
    precondition(unioned.isSuperset(of: .filterDiscoveryResults))
    precondition(
        ASPickerDisplaySettings.Options.filterDiscoveryResults.isSubset(of: unioned)
    )
    precondition(
        ASPickerDisplaySettings.Options().isDisjoint(with: .filterDiscoveryResults)
    )
    precondition(unioned.symmetricDifference(.filterDiscoveryResults).isEmpty)
    var mutable = ASPickerDisplaySettings.Options()
    mutable.formUnion(.filterDiscoveryResults)
    mutable.formIntersection(.filterDiscoveryResults)
    mutable.formSymmetricDifference(.filterDiscoveryResults)
    mutable.subtract(.filterDiscoveryResults)
    _ = ASPickerDisplaySettings.Options([.filterDiscoveryResults])
    _ = ASPickerDisplaySettings.Options()
    _ = ASPickerDisplaySettings.Options(arrayLiteral: .filterDiscoveryResults)
    precondition(ASPickerDisplaySettings.Options().isEmpty)
    precondition(!ASPickerDisplaySettings.Options.filterDiscoveryResults.isEmpty)
    precondition(
        ASPickerDisplaySettings.Options().isStrictSubset(of: .filterDiscoveryResults)
    )
    precondition(
        ASPickerDisplaySettings.Options.filterDiscoveryResults.isStrictSuperset(of: [])
    )
}
