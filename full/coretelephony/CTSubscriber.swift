import Foundation

/// Observer for carrier-token refresh. Required method; Linux never calls it.
public protocol CTSubscriberDelegate: AnyObject {
    func subscriberTokenRefreshed(_ subscriber: CTSubscriber)
}

/// One cellular subscriber. Linux has no SIM, so the token is `nil`,
/// `isSIMInserted` is `false`, and `identifier` is empty.
open class CTSubscriber: NSObject {
    public override init() {
        super.init()
    }

    /// Carrier token bytes. `nil` when no SIM or the token cannot be read.
    open var carrierToken: Data? { nil }

    /// Returns `false` on Linux; a token refresh cannot succeed without a SIM.
    open func refreshCarrierToken() -> Bool { false }

    /// Subscriber identifier. Empty rather than a fabricated ICCID-like value.
    open var identifier: String { "" }

    /// Whether a SIM is inserted. Always `false` on this host.
    open var isSIMInserted: Bool { false }

    open weak var delegate: (any CTSubscriberDelegate)?
}

/// Factory for `CTSubscriber` objects.
open class CTSubscriberInfo: NSObject {
    public override init() {
        super.init()
    }

    /// All known subscribers. Empty when no SIM is present.
    open class func subscribers() -> [CTSubscriber] { [] }

    /// Historical single-subscriber API. Returns a fail-closed stub with no SIM
    /// rather than inventing carrier identity.
    open class func subscriber() -> CTSubscriber { CTSubscriber() }
}
