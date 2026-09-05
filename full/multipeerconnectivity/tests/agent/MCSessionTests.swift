@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private final class SessionRecordingDelegate: NSObject, MCSessionDelegate {
    var states: [(MCPeerID, MCSessionState)] = []
    var data: [(Data, MCPeerID)] = []
    var streams: [(InputStream, String, MCPeerID)] = []
    var startedResources: [(String, MCPeerID, Progress)] = []
    var finishedResources: [(String, MCPeerID, URL?, (any Error)?)] = []
    var certificates: [([Any]?, MCPeerID)] = []
    var certificateDecisions: [Bool] = []

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        _ = session
        states.append((peerID, state))
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        _ = session
        self.data.append((data, peerID))
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        _ = session
        streams.append((stream, streamName, peerID))
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        _ = session
        startedResources.append((resourceName, peerID, progress))
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {
        _ = session
        finishedResources.append((resourceName, peerID, localURL, error))
    }

    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        certificates.append((certificate, peerID))
        certificateHandler(false)
    }
}

func testMCSessionInitAndProperties() {
    let peer = MCPeerID(displayName: "session-peer")
    let session = MCSession(peer: peer)
    precondition(session.myPeerID === peer)
    precondition(session.connectedPeers.isEmpty)
    precondition(session.encryptionPreference == .optional)
    precondition(session.securityIdentity == nil)
    precondition(session.delegate == nil)

    let identitySession = MCSession(
        peer: peer,
        securityIdentity: ["placeholder"],
        encryptionPreference: .required
    )
    precondition(identitySession.encryptionPreference == .required)
    precondition((identitySession.securityIdentity as? [String]) == ["placeholder"])
    precondition(identitySession.myPeerID === peer)
}

func testMCSessionDelegateProperty() {
    let peer = MCPeerID(displayName: "delegate-peer")
    let session = MCSession(peer: peer)
    let probe = SessionRecordingDelegate()
    session.delegate = probe
    precondition(session.delegate === probe)
    session.delegate = nil
    precondition(session.delegate == nil)
}

func testMCSessionConnectCancelDisconnectAreInert() {
    let peer = MCPeerID(displayName: "local")
    let remote = MCPeerID(displayName: "remote")
    let session = MCSession(peer: peer)
    session.connectPeer(remote, withNearbyConnectionData: Data([9]))
    session.cancelConnectPeer(remote)
    session.disconnect()
    precondition(session.connectedPeers.isEmpty)
}

func testMCSessionSendFailsNotConnected() {
    let peer = MCPeerID(displayName: "sender")
    let remote = MCPeerID(displayName: "target")
    let session = MCSession(peer: peer)
    do {
        try session.send(Data([1]), toPeers: [remote], with: .reliable)
        fatalError("send should throw")
    } catch {
        let nsError = error as NSError
        precondition(nsError.domain == MCErrorDomain)
        precondition(nsError.code == MCError.Code.notConnected.rawValue)
        precondition(MCError.Code.notConnected ~= error)
    }
    do {
        try session.send(Data([1]), toPeers: [], with: .unreliable)
        fatalError("empty peer list should throw")
    } catch {
        precondition(MCError.Code.invalidParameter ~= error)
    }
}

func testMCSessionStartStreamFailsNotConnected() {
    let peer = MCPeerID(displayName: "streamer")
    let remote = MCPeerID(displayName: "target")
    let session = MCSession(peer: peer)
    do {
        _ = try session.startStream(withName: "s", toPeer: remote)
        fatalError("startStream should throw")
    } catch {
        precondition(MCError.Code.notConnected ~= error)
    }
}

func testMCSessionSendResourceFailsNotConnected() {
    let peer = MCPeerID(displayName: "resource-sender")
    let remote = MCPeerID(displayName: "target")
    let session = MCSession(peer: peer)
    var completionCount = 0
    var completionError: (any Error)?
    let progress = session.sendResource(
        at: URL(fileURLWithPath: "/tmp/does-not-exist-mc"),
        withName: "blob",
        toPeer: remote
    ) { error in
        completionCount += 1
        completionError = error
    }
    precondition(progress == nil)
    precondition(completionCount == 1)
    precondition(MCError.Code.notConnected ~= completionError!)
    let skipped = session.sendResource(
        at: URL(fileURLWithPath: "/tmp/mc-skip"),
        withName: "n",
        toPeer: remote,
        withCompletionHandler: nil
    )
    precondition(skipped == nil)
}

func testMCSessionNearbyConnectionDataUnavailable() {
    let peer = MCPeerID(displayName: "local")
    let remote = MCPeerID(displayName: "remote")
    let session = MCSession(peer: peer)
    var data: Data? = Data()
    var error: (any Error)?
    var calls = 0
    session.nearbyConnectionData(forPeer: remote) { connectionData, connectionError in
        data = connectionData
        error = connectionError
        calls += 1
    }
    precondition(calls == 1)
    precondition(data == nil)
    precondition(MCError.Code.unavailable ~= error!)
}

func testMCSessionDelegateStateAndData() {
    let peer = MCPeerID(displayName: "local")
    let remote = MCPeerID(displayName: "remote")
    let session = MCSession(peer: peer)
    let probe = SessionRecordingDelegate()
    let asExistential: any MCSessionDelegate = probe
    asExistential.session(session, peer: remote, didChange: .connecting)
    asExistential.session(session, didReceive: Data([7]), fromPeer: remote)
    precondition(probe.states.count == 1)
    precondition(probe.states[0].0 === remote)
    precondition(probe.states[0].1 == .connecting)
    precondition(probe.data.count == 1)
    precondition(probe.data[0].0 == Data([7]))
}

func testMCSessionDelegateStreamAndResource() {
    let peer = MCPeerID(displayName: "local")
    let remote = MCPeerID(displayName: "remote")
    let session = MCSession(peer: peer)
    let probe = SessionRecordingDelegate()
    let asExistential: any MCSessionDelegate = probe
    let stream = InputStream(data: Data([1, 2]))
    asExistential.session(session, didReceive: stream, withName: "chunks", fromPeer: remote)
    let progress = Progress(totalUnitCount: 4)
    asExistential.session(
        session,
        didStartReceivingResourceWithName: "blob",
        fromPeer: remote,
        with: progress
    )
    let url = URL(fileURLWithPath: "/tmp/mc-resource")
    asExistential.session(
        session,
        didFinishReceivingResourceWithName: "blob",
        fromPeer: remote,
        at: url,
        withError: MCError(.timedOut)
    )
    precondition(probe.streams.count == 1)
    precondition(probe.streams[0].1 == "chunks")
    precondition(probe.startedResources.count == 1)
    precondition(probe.startedResources[0].2 === progress)
    precondition(probe.finishedResources.count == 1)
    precondition(probe.finishedResources[0].2 == url)
    precondition(MCError.Code.timedOut ~= probe.finishedResources[0].3!)
}

func testMCSessionDelegateCertificateHandler() {
    let peer = MCPeerID(displayName: "local")
    let remote = MCPeerID(displayName: "remote")
    let session = MCSession(peer: peer)
    let probe = SessionRecordingDelegate()
    var defaultDecision: Bool?
    let asExistential: any MCSessionDelegate = probe
    asExistential.session(
        session,
        didReceiveCertificate: nil,
        fromPeer: remote,
        certificateHandler: { accepted in
            _ = accepted
        }
    )
    precondition(probe.certificates.count == 1)
    precondition(probe.certificates[0].0 == nil)

    final class DefaultCertificate: NSObject, MCSessionDelegate {
        var decision: Bool?
        func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
            _ = (session, peerID, state)
        }
        func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            _ = (session, data, peerID)
        }
        func session(
            _ session: MCSession,
            didReceive stream: InputStream,
            withName streamName: String,
            fromPeer peerID: MCPeerID
        ) {
            _ = (session, stream, streamName, peerID)
        }
        func session(
            _ session: MCSession,
            didStartReceivingResourceWithName resourceName: String,
            fromPeer peerID: MCPeerID,
            with progress: Progress
        ) {
            _ = (session, resourceName, peerID, progress)
        }
        func session(
            _ session: MCSession,
            didFinishReceivingResourceWithName resourceName: String,
            fromPeer peerID: MCPeerID,
            at localURL: URL?,
            withError error: (any Error)?
        ) {
            _ = (session, resourceName, peerID, localURL, error)
        }
    }
    let defaults = DefaultCertificate()
    (defaults as any MCSessionDelegate).session(
        session,
        didReceiveCertificate: ["cert"],
        fromPeer: remote,
        certificateHandler: { accepted in
            defaultDecision = accepted
        }
    )
    precondition(defaultDecision == false)
}
