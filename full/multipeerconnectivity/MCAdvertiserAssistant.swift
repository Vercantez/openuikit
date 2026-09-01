import Foundation

/// System invitation UI for advertising a local session.
///
/// Linux has no Apple invitation sheet. `start()`/`stop()` retain caller state
/// and never present UI or advertise on the network. Invitation delegate
/// callbacks are therefore never fired.
open class MCAdvertiserAssistant: NSObject {
    open weak var delegate: (any MCAdvertiserAssistantDelegate)?
    open var session: MCSession { _session }
    open var discoveryInfo: [String: String]? { _discoveryInfo }
    open var serviceType: String { _serviceType }

    private let _session: MCSession
    private let _discoveryInfo: [String: String]?
    private let _serviceType: String
    private var isStarted = false

    public init(
        serviceType: String,
        discoveryInfo info: [String: String]?,
        session: MCSession
    ) {
        _serviceType = serviceType
        _discoveryInfo = info
        _session = session
        super.init()
    }

    open func start() {
        guard !isStarted else { return }
        isStarted = true
    }

    open func stop() {
        isStarted = false
    }
}

/// Optional invitation-presentation callbacks for `MCAdvertiserAssistant`.
public protocol MCAdvertiserAssistantDelegate: NSObjectProtocol {
    func advertiserAssistantWillPresentInvitation(
        _ advertiserAssistant: MCAdvertiserAssistant
    )

    func advertiserAssistantDidDismissInvitation(
        _ advertiserAssistant: MCAdvertiserAssistant
    )
}

public extension MCAdvertiserAssistantDelegate {
    func advertiserAssistantWillPresentInvitation(
        _ advertiserAssistant: MCAdvertiserAssistant
    ) {
        _ = advertiserAssistant
    }

    func advertiserAssistantDidDismissInvitation(
        _ advertiserAssistant: MCAdvertiserAssistant
    ) {
        _ = advertiserAssistant
    }
}
