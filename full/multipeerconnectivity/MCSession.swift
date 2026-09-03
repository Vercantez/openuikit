import Foundation

public protocol MCSessionDelegate: NSObjectProtocol {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)
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

extension MCSessionDelegate {
    public func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        _ = (session, certificate, peerID)
        certificateHandler(false)
    }
}

open class MCSession: NSObject {
    private let _myPeerID: MCPeerID
    private let _securityIdentity: [Any]?
    private let _encryptionPreference: MCEncryptionPreference
    private let lock = NSLock()
    private var _delegate: (any MCSessionDelegate)?

    public var myPeerID: MCPeerID { _myPeerID }
    public var securityIdentity: [Any]? { _securityIdentity }
    public var encryptionPreference: MCEncryptionPreference { _encryptionPreference }
    public var connectedPeers: [MCPeerID] { [] }

    public weak var delegate: (any MCSessionDelegate)? {
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
        fatalError("use init(peer:)")
    }

    public convenience init(peer myPeerID: MCPeerID) {
        self.init(peer: myPeerID, securityIdentity: nil, encryptionPreference: .optional)
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

    open func send(_ data: Data, toPeers peerIDs: [MCPeerID], with mode: MCSessionSendDataMode) throws {
        _ = (data, peerIDs, mode)
        throw MCError(.notConnected)
    }

    @discardableResult
    open func sendResource(
        at resourceURL: URL,
        withName resourceName: String,
        toPeer peerID: MCPeerID,
        withCompletionHandler completionHandler: (((any Error)?) -> Void)? = nil
    ) -> Progress? {
        _ = (resourceURL, resourceName, peerID)
        if let completionHandler {
            mcDeliver {
                completionHandler(MCError(.notConnected))
            }
        }
        return nil
    }

    open func startStream(withName streamName: String, toPeer peerID: MCPeerID) throws -> OutputStream {
        _ = (streamName, peerID)
        throw MCError(.notConnected)
    }

    open func disconnect() {}

    open func nearbyConnectionData(forPeer peerID: MCPeerID) async throws -> Data {
        _ = peerID
        return try await withCheckedThrowingContinuation { continuation in
            mcDeliver {
                continuation.resume(throwing: MCError(.unavailable))
            }
        }
    }

    open func connectPeer(_ peerID: MCPeerID, withNearbyConnectionData data: Data) {
        _ = (peerID, data)
    }

    open func cancelConnectPeer(_ peerID: MCPeerID) {
        _ = peerID
    }
}
