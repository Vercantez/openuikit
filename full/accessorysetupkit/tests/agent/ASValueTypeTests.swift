import AccessorySetupKit
import Foundation

func testASBluetoothCompanyIdentifier() {
    let viaRaw = ASBluetoothCompanyIdentifier(rawValue: 0x004C)
    let viaLabel = ASBluetoothCompanyIdentifier(0x004C)
    precondition(viaRaw.rawValue == 0x004C)
    precondition(viaLabel.rawValue == 0x004C)
    precondition(viaRaw == viaLabel)
    precondition(viaRaw != ASBluetoothCompanyIdentifier(0))
    _ = viaRaw.hashValue
    var hasher = Hasher()
    viaRaw.hash(into: &hasher)
    _ = hasher.finalize()
}

func testASPickerDisplaySettingsDiscoveryTimeout() {
    precondition(ASPickerDisplaySettings.DiscoveryTimeout.short.rawValue == 60)
    precondition(ASPickerDisplaySettings.DiscoveryTimeout.medium.rawValue == 120)
    precondition(ASPickerDisplaySettings.DiscoveryTimeout.long.rawValue == 300)
    precondition(ASPickerDisplaySettings.DiscoveryTimeout.unbounded.rawValue.isInfinite)
    let custom = ASPickerDisplaySettings.DiscoveryTimeout(rawValue: 30)
    precondition(custom.rawValue == 30)
    precondition(
        ASPickerDisplaySettings.DiscoveryTimeout.short
            != .medium
    )
    precondition(
        ASPickerDisplaySettings.DiscoveryTimeout.long
            != .unbounded
    )
    _ = ASPickerDisplaySettings.DiscoveryTimeout.short.hashValue
    var hasher = Hasher()
    ASPickerDisplaySettings.DiscoveryTimeout.medium.hash(into: &hasher)
    _ = hasher.finalize()
}

func testASPickerDisplaySettingsDefaults() {
    let settings = ASPickerDisplaySettings.default
    precondition(settings.discoveryTimeout.rawValue == 30)
    precondition(settings.options.isEmpty)
    settings.discoveryTimeout = .short
    settings.options = .filterDiscoveryResults
    precondition(settings.discoveryTimeout == .short)
    precondition(settings.options.contains(.filterDiscoveryResults))
    let copy = ASPickerDisplaySettings()
    precondition(copy.discoveryTimeout.rawValue == ASPickerDisplaySettings.defaultTimeoutSeconds)
}
