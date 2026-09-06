import AccessorySetupKit
import Foundation

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public AccessorySetupKit APIs.
func accessorySetupKitDependencyIdentityProbe() {
    let domain: String = ASErrorDomain
    precondition(domain == "ASErrorDomain")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = ASError(.pickerRestricted, userInfo: info)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == ASErrorDomain)
    precondition(ns.code == ASError.Code.pickerRestricted.rawValue)

    let descriptor = ASDiscoveryDescriptor()
    descriptor.ssid = UUID().uuidString
    descriptor.bluetoothManufacturerDataBlob = Data([0x01, 0x02])
    descriptor.bluetoothNameSubstringCompareOptions = [.caseInsensitive]
    precondition(descriptor.ssid == descriptor.ssid)

    let settings = ASAccessorySettings()
    settings.ssid = "identity-ssid"
    settings.bluetoothTransportBridgingIdentifier = Data([0xAA])
    precondition(settings.ssid == "identity-ssid")

    let compare = ASPropertyCompareString(
        string: "Kit",
        compareOptions: [.caseInsensitive]
    )
    precondition(compare.string == "Kit")

    _ = NotificationCenter.default
    _ = NSPredicate(value: true)
}
