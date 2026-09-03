import Foundation

public protocol CTSubscriberDelegate: AnyObject {
    func subscriberTokenRefreshed(_ subscriber: CTSubscriber)
}

/// Linux has no SIM / carrier-token service. `isSIMInserted` is `false`,
/// `carrierToken` is `nil`, `refreshCarrierToken()` returns `false` and does
/// not notify the delegate.
open class CTSubscriber: NSObject {
    public override init() {
        super.init()
    }

    open var carrierToken: Data? { nil }

    open var identifier: String { "" }

    open var isSIMInserted: Bool { false }

    public weak var delegate: (any CTSubscriberDelegate)?

    open func refreshCarrierToken() -> Bool {
        false
    }
}

open class CTSubscriberInfo: NSObject {
    public override init() {
        super.init()
    }

    open class func subscribers() -> [CTSubscriber] {
        []
    }

    /// Deprecated single-subscriber accessor. Returns an empty fail-closed
    /// subscriber rather than inventing SIM identity.
    open class func subscriber() -> CTSubscriber {
        CTSubscriber()
    }
}
