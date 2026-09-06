import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryUI

func testPairingAccessType() {
    let typeName = String(describing: DDDevicePairingAccess.self)
    precondition(typeName == "DDDevicePairingAccess")
    precondition(DDDevicePairingAccess.default != DDDevicePairingAccess.permanent)
    precondition(DDDevicePairingAccess.default == DDDevicePairingAccess.default)
    precondition(DDDevicePairingAccess.permanent == DDDevicePairingAccess.permanent)
    var hasher = Hasher()
    DDDevicePairingAccess.default.hash(into: &hasher)
    DDDevicePairingAccess.permanent.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPairingAccessDefault() {
    let access = DDDevicePairingAccess.default
    precondition(DeviceDiscoveryUIHostControl.isDefault(access))
    precondition(!DeviceDiscoveryUIHostControl.isPermanent(access))
    precondition(access == .default)
    precondition(access != .permanent)
}

func testPairingAccessPermanent() {
    let access = DDDevicePairingAccess.permanent
    precondition(DeviceDiscoveryUIHostControl.isPermanent(access))
    precondition(!DeviceDiscoveryUIHostControl.isDefault(access))
    precondition(access == .permanent)
    precondition(access != .default)
}
