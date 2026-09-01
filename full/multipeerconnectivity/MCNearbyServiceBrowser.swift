import Foundation

/// Browses for nearby peers over Apple's nearby-discovery stack.
///
/// Linux has no Bonjour/AWDL MultipeerConnectivity browser. Starting browsing
/// fails closed with `didNotStartBrowsingForPeers` asynchronously, exactly
/// once per start. `invitePeer` does not mutate any session and never reports
/// a connected peer.
open class MCNearbyServiceBrowser: NSObject {
    open weak var delegate: (any MCNearbyServiceBrowserDelegate)?
    open var myPeerID: MCPeerID { _myPeerID }
    open var serviceType: String { _serviceType }

    private let _myPeerID: MCPeerID
    private let _serviceType: String
    private let stateLock = NSLock()
    private var isBrowsing = false
    private var deliveryGeneration = 0

    public init(peer myPeerID: MCPeerID, serviceType: String) {
        _myPeerID = myPeerID
        _serviceType = serviceType
        super.init()
    }

    open func startBrowsingForPeers() {
        stateLock.lock()
        if isBrowsing {
            stateLock.unlock()
            return
        }
        isBrowsing = true
        deliveryGeneration += 1
        let generation = deliveryGeneration
        stateLock.unlock()

        let error: MCError = mc_isValidServiceType(_serviceType)
            ? mc_unavailableError()
            : mc_invalidParameterError()
        MCFailClosed.deliver { [weak self] in
            guard let self else { return }
            self.stateLock.lock()
            let shouldDeliver =
                self.isBrowsing && self.deliveryGeneration == generation
            if shouldDeliver {
                self.isBrowsing = false
            }
            self.stateLock.unlock()
            guard shouldDeliver else { return }
            self.delegate?.browser(self, didNotStartBrowsingForPeers: error)
        }
    }

    open func stopBrowsingForPeers() {
        stateLock.lock()
        isBrowsing = false
        deliveryGeneration += 1
        stateLock.unlock()
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
