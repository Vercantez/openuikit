import Foundation

/// Advertises the local peer over Apple's nearby-discovery stack.
///
/// Linux has no Bonjour/AWDL MultipeerConnectivity advertiser. Starting
/// advertising fails closed: the optional delegate is told
/// `didNotStartAdvertisingPeer` with `MCError.unavailable` (or
/// `invalidParameter` when the service type is not a documented Bonjour-style
/// name). No invitation is ever delivered.
open class MCNearbyServiceAdvertiser: NSObject {
    open weak var delegate: (any MCNearbyServiceAdvertiserDelegate)?
    open var myPeerID: MCPeerID { _myPeerID }
    open var discoveryInfo: [String: String]? { _discoveryInfo }
    open var serviceType: String { _serviceType }

    private let _myPeerID: MCPeerID
    private let _discoveryInfo: [String: String]?
    private let _serviceType: String
    private var isAdvertising = false

    public init(
        peer myPeerID: MCPeerID,
        discoveryInfo info: [String: String]?,
        serviceType: String
    ) {
        _myPeerID = myPeerID
        _discoveryInfo = info
        _serviceType = serviceType
        super.init()
    }

    open func startAdvertisingPeer() {
        guard !isAdvertising else { return }
        isAdvertising = true
        if !mc_isValidServiceType(_serviceType) {
            delegate?.advertiser(self, didNotStartAdvertisingPeer: mc_invalidParameterError())
            return
        }
        delegate?.advertiser(self, didNotStartAdvertisingPeer: mc_unavailableError())
    }

    open func stopAdvertisingPeer() {
        isAdvertising = false
    }
}

/// Delegate for nearby advertising.
///
/// The invitation callback is required. The start-failure callback is optional
/// on Apple; a default empty body is provided for Swift conformers.
public protocol MCNearbyServiceAdvertiserDelegate: NSObjectProtocol {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    )

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    )
}

public extension MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        _ = (advertiser, error)
    }
}
