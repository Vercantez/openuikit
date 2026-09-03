import Foundation

/// Deprecated call snapshot. Linux has no call stack; instances created
/// through `NSObject` init expose empty strings and are never injected into
/// `CTCallCenter`.
open class CTCall: NSObject {
    public override init() {
        super.init()
    }

    open var callID: String { "" }

    open var callState: String { "" }
}

/// Deprecated call center. `currentCalls` is `nil` and `callEventHandler` is
/// stored but never invoked: there is no telephony service to observe.
open class CTCallCenter: NSObject {
    public override init() {
        super.init()
    }

    open var currentCalls: Set<CTCall>? { nil }

    open var callEventHandler: ((CTCall) -> Void)?
}
