import Foundation

/// Browses for nearby peers over Apple's nearby-discovery stack.
///
/// Linux has no Bonjour/AWDL MultipeerConnectivity browser. Starting browsing
/// fails closed with `didNotStartBrowsingForPeers`. `invitePeer` does not
/// mutate any session and never reports a connected peer.
open class MCNearbyServiceBrowser: NSObject {
    open weak var delegate: (any MCNearbyServiceBrowserDelegate)?
    open var myPeerID: MCPeerID { _myPeerID }
    open var serviceType: String { _serviceType }

    private let _myPeerID: MCPeerID
    private let _serviceType: String
    private var isBrowsing = false

    public init(peer myPeerID: MCPeerID, serviceType: String) {
        _myPeerID = myPeerID
        _serviceType = serviceType
        super.init()
    }

    open func startBrowsingForPeers() {
        guard !isBrowsing else { return }
        isBrowsing = true
        if !mc_isValidServiceType(_serviceType) {
            delegate?.browser(self, didNotStartBrowsingForPeers: mc_invalidParameterError())
            return
        }
        delegate?.browser(self, didNotStartBrowsingForPeers: mc_unavailableError())
    }

    open func stopBrowsingForPeers() {
        isBrowsing = false
    }

    open func invitePeer(
        _ peerID: MCPeerID,
        to session: MCSession,
        withContext context: Data?,
        timeout: TimeInterval
    ) {
        _ = (peerID, session, context, timeout)
    }
}

/// Delegate for nearby browsing.
public protocol MCNearbyServiceBrowserDelegate: NSObjectProtocol {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    )

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID)

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    )
}

public extension MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        _ = (browser, error)
    }
}
