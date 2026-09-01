import Foundation

/// Session between the local peer and zero or more remote peers.
///
/// Linux has no Apple MultipeerConnectivity transport, encryption, or nearby
/// connection-data format. Construction, property storage, and fail-closed
/// send/stream/resource APIs are real. Discovery-derived connection never
/// succeeds: `connectedPeers` stays empty, sends throw `notConnected`, and
/// nearby-connection helpers fail with `unavailable`. Fabricating a connected
/// peer or a successful transfer would be a network/privacy bug.
open class MCSession: NSObject {
    private let lock = NSLock()
    private var _connectedPeers: [MCPeerID] = []

    open weak var delegate: (any MCSessionDelegate)?
    open var myPeerID: MCPeerID { _myPeerID }
    open var securityIdentity: [Any]? { _securityIdentity }
    open var encryptionPreference: MCEncryptionPreference { _encryptionPreference }

    private let _myPeerID: MCPeerID
    private let _securityIdentity: [Any]?
    private let _encryptionPreference: MCEncryptionPreference

    public convenience init(peer myPeerID: MCPeerID) {
        self.init(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .optional
        )
    }

    public init(
        peer myPeerID: MCPeerID,
        securityIdentity identity: [Any]?,
        encryptionPreference: MCEncryptionPreference
    ) {
        _myPeerID = myPeerID
        _securityIdentity = identity
        _encryptionPreference = encryptionPreference
        super.init()
    }

    open var connectedPeers: [MCPeerID] {
        lock.lock()
        defer { lock.unlock() }
        return _connectedPeers
    }

    open func send(
        _ data: Data,
        toPeers peerIDs: [MCPeerID],
        with mode: MCSessionSendDataMode
    ) throws {
        _ = (data, mode)
        guard !peerIDs.isEmpty else { throw mc_invalidParameterError() }
        throw mc_notConnectedError()
    }

    open func disconnect() {
        lock.lock()
        let peers = _connectedPeers
        _connectedPeers.removeAll()
        lock.unlock()
        for peer in peers {
            delegate?.session(self, peer: peer, didChange: .notConnected)
        }
    }

    open func sendResource(
        at resourceURL: URL,
        withName resourceName: String,
        toPeer peerID: MCPeerID,
        withCompletionHandler completionHandler: (((any Error)?) -> Void)? = nil
    ) -> Progress? {
        _ = (resourceURL, resourceName, peerID)
        completionHandler?(mc_notConnectedError())
        return nil
    }

    open func startStream(
        withName streamName: String,
        toPeer peerID: MCPeerID
    ) throws -> OutputStream {
        _ = (streamName, peerID)
        guard !streamName.isEmpty else { throw mc_invalidParameterError() }
        throw mc_notConnectedError()
    }

    open func nearbyConnectionData(
        forPeer peerID: MCPeerID,
        withCompletionHandler completionHandler: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = peerID
        completionHandler(nil, mc_unavailableError())
    }

    open func nearbyConnectionData(forPeer peerID: MCPeerID) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            nearbyConnectionData(forPeer: peerID) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? mc_unavailableError())
                }
            }
        }
    }

    /// Custom discovery hook. Linux cannot interpret Apple nearby connection
    /// data, so this method does not change session state.
    open func connectPeer(_ peerID: MCPeerID, withNearbyConnectionData data: Data) {
        _ = (peerID, data)
    }

    open func cancelConnectPeer(_ peerID: MCPeerID) {
        _ = peerID
    }
}

/// Delegate for session state, data, streams, and resource transfers.
///
/// Objective-C optional requirements are expressed with protocol defaults so
/// ordinary Swift conformers can omit them without `@objc`.
public protocol MCSessionDelegate: NSObjectProtocol {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    )

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    )

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    )

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    )

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    )

    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    )
}

public extension MCSessionDelegate {
    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        _ = (session, certificate, peerID)
        // Fail closed: do not auto-trust a certificate that was never presented.
        certificateHandler(false)
    }
}
