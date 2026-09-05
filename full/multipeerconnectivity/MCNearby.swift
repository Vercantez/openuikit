import Foundation

public protocol MCNearbyServiceAdvertiserDelegate: NSObjectProtocol {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    )
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error)
}

extension MCNearbyServiceAdvertiserDelegate {
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        _ = (advertiser, error)
    }
}

open class MCNearbyServiceAdvertiser: NSObject {
    private let _myPeerID: MCPeerID
    private let _discoveryInfo: [String: String]?
    private let _serviceType: String
    private let lock = NSLock()
    private var _delegate: (any MCNearbyServiceAdvertiserDelegate)?

    public var myPeerID: MCPeerID { _myPeerID }
    public var discoveryInfo: [String: String]? { _discoveryInfo }
    public var serviceType: String { _serviceType }

    public weak var delegate: (any MCNearbyServiceAdvertiserDelegate)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _delegate
        }
        set {
            lock.lock()
            _delegate = newValue
            lock.unlock()
        }
    }

    @available(*, unavailable)
    public override init() {
        fatalError("use init(peer:discoveryInfo:serviceType:)")
    }

    public init(peer myPeerID: MCPeerID, discoveryInfo info: [String: String]?, serviceType: String) {
        _myPeerID = myPeerID
        _discoveryInfo = info
        _serviceType = serviceType
        super.init()
    }

    /// Linux has no Bonjour/AWDL advertiser. The optional start-failure
    /// callback is delivered on the caller thread with `MCError.unavailable`.
    /// Invitation handlers are never invoked.
    open func startAdvertisingPeer() {
        delegate?.advertiser(self, didNotStartAdvertisingPeer: MCError(.unavailable))
    }

    open func stopAdvertisingPeer() {}
}

public protocol MCNearbyServiceBrowserDelegate: NSObjectProtocol {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    )
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID)
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error)
}

extension MCNearbyServiceBrowserDelegate {
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        _ = (browser, error)
    }
}

open class MCNearbyServiceBrowser: NSObject {
    private let _myPeerID: MCPeerID
    private let _serviceType: String
    private let lock = NSLock()
    private var _delegate: (any MCNearbyServiceBrowserDelegate)?

    public var myPeerID: MCPeerID { _myPeerID }
    public var serviceType: String { _serviceType }

    public weak var delegate: (any MCNearbyServiceBrowserDelegate)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _delegate
        }
        set {
            lock.lock()
            _delegate = newValue
            lock.unlock()
        }
    }

    @available(*, unavailable)
    public override init() {
        fatalError("use init(peer:serviceType:)")
    }

    public init(peer myPeerID: MCPeerID, serviceType: String) {
        _myPeerID = myPeerID
        _serviceType = serviceType
        super.init()
    }

    /// Linux has no Bonjour/AWDL browser. The optional start-failure callback
    /// is delivered on the caller thread with `MCError.unavailable`. Peers are
    /// never found or lost.
    open func startBrowsingForPeers() {
        delegate?.browser(self, didNotStartBrowsingForPeers: MCError(.unavailable))
    }

    open func stopBrowsingForPeers() {}

    open func invitePeer(
        _ peerID: MCPeerID,
        to session: MCSession,
        withContext context: Data?,
        timeout: TimeInterval
    ) {
        _ = (peerID, session, context, timeout)
    }
}

public protocol MCAdvertiserAssistantDelegate: NSObjectProtocol {
    func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant)
    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant)
}

extension MCAdvertiserAssistantDelegate {
    public func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        _ = advertiserAssistant
    }

    public func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        _ = advertiserAssistant
    }
}

/// Invitation UI assistant. Linux never presents invitation UI or advertises.
open class MCAdvertiserAssistant: NSObject {
    private let _session: MCSession
    private let _serviceType: String
    private let _discoveryInfo: [String: String]?
    private let lock = NSLock()
    private var _delegate: (any MCAdvertiserAssistantDelegate)?

    public var session: MCSession { _session }
    public var serviceType: String { _serviceType }
    public var discoveryInfo: [String: String]? { _discoveryInfo }

    public weak var delegate: (any MCAdvertiserAssistantDelegate)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _delegate
        }
        set {
            lock.lock()
            _delegate = newValue
            lock.unlock()
        }
    }

    @available(*, unavailable)
    public override init() {
        fatalError("use init(serviceType:discoveryInfo:session:)")
    }

    public init(serviceType: String, discoveryInfo info: [String: String]?, session: MCSession) {
        _serviceType = serviceType
        _discoveryInfo = info
        _session = session
        super.init()
    }

    open func start() {}

    open func stop() {}
}
