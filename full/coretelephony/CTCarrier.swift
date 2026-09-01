import Foundation

/// Deprecated iOS 16. Linux has no subscriber cellular provider, so every
/// identity field is `nil` and VoIP is not claimed to be allowed.
open class CTCarrier: NSObject {
    public override init() {
        super.init()
    }

    /// Carrier display name. `nil` when no provider is present.
    open var carrierName: String? { nil }

    /// MCC. `nil` when no provider is present. This port does not return the
    /// documented future stub value `"65535"`.
    open var mobileCountryCode: String? { nil }

    /// MNC. `nil` when no provider is present. This port does not return the
    /// documented future stub value `"65535"`.
    open var mobileNetworkCode: String? { nil }

    /// ISO country code. `nil` when no provider is present.
    open var isoCountryCode: String? { nil }

    /// Whether the carrier allows VoIP. `false` on Linux; do not infer `true`.
    open var allowsVOIP: Bool { false }
}
