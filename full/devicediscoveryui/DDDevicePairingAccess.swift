import Foundation

/// Specifies the access level requested for device discovery.
///
/// Two documented statics exist in the pinned graph. Apple's struct has no
/// public raw value, Equatable conformance, or additional cases in the
/// census; Linux stores an internal kind so `.default` and `.permanent` stay
/// distinct. Extra Hashable/Equatable are Linux conveniences, not Apple ABI.
///
/// https://developer.apple.com/documentation/devicediscoveryui/dddevicepairingaccess
public struct DDDevicePairingAccess: Hashable, Sendable {
    enum Kind: String, Hashable, Sendable {
        case `default`
        case permanent
    }

    let linuxKind: Kind

    /// Use the system's default access for the device selected by the user.
    public static let `default` = DDDevicePairingAccess(linuxKind: .default)

    /// Grant the app permanent access to the device selected by the user for
    /// future use.
    public static let permanent = DDDevicePairingAccess(linuxKind: .permanent)
}
