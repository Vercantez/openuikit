import Foundation

/// Deprecated iOS 10. On Linux this is an inert stub: no live call objects
/// exist, and `callEventHandler` is never invoked.
open class CTCall: NSObject {
    private let _callState: String
    private let _callID: String

    public override init() {
        _callState = CTCallStateDisconnected
        _callID = ""
        super.init()
    }

    /// Current call state. Always `CTCallStateDisconnected` for constructed stubs.
    open var callState: String { _callState }

    /// Call identifier. Empty on Linux; this port never fabricates a UUID.
    open var callID: String { _callID }
}

/// Deprecated iOS 10. Linux has no call list; `currentCalls` is `nil` and the
/// event handler is stored but never fired.
open class CTCallCenter: NSObject {
    public override init() {
        super.init()
    }

    /// Active calls. Apple returns `nil` when none are active; Linux matches that.
    open var currentCalls: Set<CTCall>? { nil }

    /// Invoked by Apple when call state changes. Never invoked on this host.
    open var callEventHandler: ((CTCall) -> Void)?
}
