@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var lastError: (any Error)?

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(_ error: (any Error)? = nil) {
        lock.lock()
        sawReturned = returned
        count += 1
        lastError = error
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int, error: (any Error)?) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, lastError)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class CompletionQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        MultipeerConnectivityHostControl.enqueueCompletionProbe {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "completion queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func drainCompletionQueue() {
    let drained = DispatchSemaphore(value: 0)
    MultipeerConnectivityHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    waitEvent(drained, "completion queue did not drain")
}

private func requireUnavailable(_ error: any Error) {
    let nsError = error as NSError
    precondition(nsError.domain == MCErrorDomain)
    precondition(nsError.code == MCError.Code.unavailable.rawValue)
    precondition(MCError.Code.unavailable ~= error)
}

private func requireNotConnected(_ error: any Error) {
    let nsError = error as NSError
    precondition(nsError.domain == MCErrorDomain)
    precondition(nsError.code == MCError.Code.notConnected.rawValue)
    precondition(MCError.Code.notConnected ~= error)
}

private func assertConstantsAndEnums() {
    precondition(MCErrorDomain == "MCErrorDomain")
    precondition(MCError.errorDomain == MCErrorDomain)
    precondition(kMCSessionMinimumNumberOfPeers == 2)
    precondition(kMCSessionMaximumNumberOfPeers == 8)

    precondition(MCEncryptionPreference.optional.rawValue == 0)
    precondition(MCEncryptionPreference.required.rawValue == 1)
    precondition(MCEncryptionPreference.none.rawValue == 2)
    precondition(MCEncryptionPreference(rawValue: 0) == .optional)
    precondition(MCEncryptionPreference(rawValue: 99) == nil)
    precondition(MCEncryptionPreference.none != .optional)

    precondition(MCSessionSendDataMode.reliable.rawValue == 0)
    precondition(MCSessionSendDataMode.unreliable.rawValue == 1)
    precondition(MCSessionSendDataMode(rawValue: 1) == .unreliable)
    precondition(MCSessionSendDataMode.reliable != .unreliable)

    precondition(MCSessionState.notConnected.rawValue == 0)
    precondition(MCSessionState.connecting.rawValue == 1)
    precondition(MCSessionState.connected.rawValue == 2)
    precondition(MCSessionState(rawValue: 2) == .connected)
    precondition(MCSessionState.connected != .notConnected)

    let codes: [(MCError.Code, Int)] = [
        (.unknown, 0),
        (.notConnected, 1),
        (.invalidParameter, 2),
        (.unsupported, 3),
        (.timedOut, 4),
        (.cancelled, 5),
        (.unavailable, 6),
    ]
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        precondition(MCError.Code(rawValue: raw) == code)
    }
    precondition(MCError.unknown == .unknown)
    precondition(MCError.notConnected == .notConnected)
    precondition(MCError.invalidParameter == .invalidParameter)
    precondition(MCError.unsupported == .unsupported)
    precondition(MCError.timedOut == .timedOut)
    precondition(MCError.cancelled == .cancelled)
    precondition(MCError.unavailable == .unavailable)
    precondition(MCError.Code.unknown != .unavailable)

    let typed = MCError(.unavailable, userInfo: ["k": "v"])
    precondition(typed.code == .unavailable)
    precondition(typed.errorCode == 6)
    precondition(typed.errorUserInfo["k"] as? String == "v")
    precondition(typed.userInfo["k"] as? String == "v")
    precondition(typed.localizedDescription.isEmpty == false)
    precondition(typed != MCError(.notConnected))
    precondition(typed == MCError(.unavailable, userInfo: ["k": "v"]))

    var hasher = Hasher()
    MCEncryptionPreference.required.hash(into: &hasher)
    MCSessionSendDataMode.reliable.hash(into: &hasher)
    MCSessionState.connected.hash(into: &hasher)
    MCError.Code.timedOut.hash(into: &hasher)
    typed.hash(into: &hasher)
    _ = hasher.finalize()

    do {
        throw MCError(.unavailable)
    } catch {
        requireUnavailable(error)
    }
}

private func assertPeerIdentity() {
    let peer = MCPeerID(displayName: "linux-peer")
    precondition(peer.displayName == "linux-peer")
    precondition(peer === peer)
    let other = MCPeerID(displayName: "linux-peer")
    precondition(peer !== other)

    let coder = NSKeyedArchiver(requiringSecureCoding: true)
    peer.encode(with: coder)
    let data = coder.encodedData
    let decoder = try! NSKeyedUnarchiver(forReadingFrom: data)
    decoder.requiresSecureCoding = true
    precondition(MCPeerID(coder: decoder) == nil)
    precondition(MCPeerID.supportsSecureCoding)
}

private class SessionProbe: NSObject, MCSessionDelegate {
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

private class SessionOverride: SessionProbe {
    var overrideCount = 0

    override func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        overrideCount += 1
        super.session(session, peer: peerID, didChange: state)
    }
}

private func assertSession(peer: MCPeerID) {
    let session = MCSession(peer: peer)
    precondition(session.myPeerID === peer)
    precondition(session.connectedPeers.isEmpty)
    precondition(session.encryptionPreference == .optional)
    precondition(session.securityIdentity == nil)

    let identitySession = MCSession(
        peer: peer,
        securityIdentity: ["placeholder"],
        encryptionPreference: .required
    )
    precondition(identitySession.encryptionPreference == .required)
    precondition((identitySession.securityIdentity as? [String]) == ["placeholder"])

    let probe = SessionOverride()
    session.delegate = probe
    precondition(session.delegate === probe)
    let asExistential: any MCSessionDelegate = probe
    asExistential.session(session, peer: peer, didChange: .notConnected)
    precondition(probe.overrideCount == 1)

    do {
        try session.send(Data([1]), toPeers: [peer], with: .reliable)
        fatalError("send should throw")
    } catch {
        requireNotConnected(error)
    }

    do {
        _ = try session.startStream(withName: "s", toPeer: peer)
        fatalError("startStream should throw")
    } catch {
        requireNotConnected(error)
    }

    session.connectPeer(peer, withNearbyConnectionData: Data([9]))
    session.cancelConnectPeer(peer)
    session.disconnect()
    precondition(session.connectedPeers.isEmpty)
}

private func assertSendResourceNonInline(session: MCSession, peer: MCPeerID) {
    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    let progress = session.sendResource(
        at: URL(fileURLWithPath: "/tmp/does-not-exist-mc"),
        withName: "blob",
        toPeer: peer
    ) { error in
        state.noteCallback(error)
        finished.signal()
    }
    precondition(progress == nil)
    state.markReturned()
    precondition(state.snapshot().count == 0)
    blocker.release()
    waitEvent(finished, "sendResource completion did not run")
    drainCompletionQueue()
    let snap = state.snapshot()
    precondition(snap.count == 1)
    precondition(snap.sawReturned)
    requireNotConnected(snap.error!)
}

private func assertNearbyConnectionNonInline(session: MCSession, peer: MCPeerID) {
    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    Task {
        do {
            _ = try await session.nearbyConnectionData(forPeer: peer)
            fatalError("nearbyConnectionData should throw")
        } catch {
            state.noteCallback(error)
            finished.signal()
        }
    }
    Thread.sleep(forTimeInterval: 0.05)
    state.markReturned()
    precondition(state.snapshot().count == 0)
    blocker.release()
    waitEvent(finished, "nearbyConnectionData did not throw")
    drainCompletionQueue()
    let snap = state.snapshot()
    precondition(snap.count == 1)
    precondition(snap.sawReturned)
    requireUnavailable(snap.error!)
}

private class AdvertiserProbe: NSObject, MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        _ = (advertiser, peerID, context)
        invitationHandler(false, nil)
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        _ = (advertiser, error)
    }
}

private class AdvertiserOverride: AdvertiserProbe {
    let onFail: (any Error) -> Void

    init(onFail: @escaping (any Error) -> Void) {
        self.onFail = onFail
        super.init()
    }

    override func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        onFail(error)
    }
}

private class BrowserProbe: NSObject, MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        _ = (browser, peerID, info)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        _ = (browser, peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        _ = (browser, error)
    }
}

private class BrowserOverride: BrowserProbe {
    let onFail: (any Error) -> Void

    init(onFail: @escaping (any Error) -> Void) {
        self.onFail = onFail
        super.init()
    }

    override func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        onFail(error)
    }
}

private func assertAdvertiserNonInline(peer: MCPeerID) {
    let info = ["k": "v"]
    let advertiser = MCNearbyServiceAdvertiser(
        peer: peer,
        discoveryInfo: info,
        serviceType: "ou-xfer"
    )
    precondition(advertiser.myPeerID === peer)
    precondition(advertiser.discoveryInfo?["k"] == "v")
    precondition(advertiser.serviceType == "ou-xfer")

    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    let probe = AdvertiserOverride { error in
        state.noteCallback(error)
        finished.signal()
    }
    advertiser.delegate = probe
    let asExistential: any MCNearbyServiceAdvertiserDelegate = probe
    _ = asExistential

    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    advertiser.startAdvertisingPeer()
    state.markReturned()
    precondition(state.snapshot().count == 0)
    blocker.release()
    waitEvent(finished, "advertiser failure did not run")
    drainCompletionQueue()
    let snap = state.snapshot()
    precondition(snap.count == 1)
    precondition(snap.sawReturned)
    requireUnavailable(snap.error!)
    advertiser.stopAdvertisingPeer()
}

private func assertBrowserNonInline(peer: MCPeerID, session: MCSession) {
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    precondition(browser.myPeerID === peer)
    precondition(browser.serviceType == "ou-xfer")

    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    let probe = BrowserOverride { error in
        state.noteCallback(error)
        finished.signal()
    }
    browser.delegate = probe
    let asExistential: any MCNearbyServiceBrowserDelegate = probe
    asExistential.browser(browser, foundPeer: peer, withDiscoveryInfo: nil)
    asExistential.browser(browser, lostPeer: peer)

    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    browser.startBrowsingForPeers()
    state.markReturned()
    precondition(state.snapshot().count == 0)
    blocker.release()
    waitEvent(finished, "browser failure did not run")
    drainCompletionQueue()
    let snap = state.snapshot()
    precondition(snap.count == 1)
    precondition(snap.sawReturned)
    requireUnavailable(snap.error!)

    browser.invitePeer(peer, to: session, withContext: Data(), timeout: 1)
    browser.stopBrowsingForPeers()
}

private func assertAssistant(peer: MCPeerID, session: MCSession) {
    let assistant = MCAdvertiserAssistant(
        serviceType: "ou-xfer",
        discoveryInfo: nil,
        session: session
    )
    precondition(assistant.session === session)
    precondition(assistant.serviceType == "ou-xfer")
    precondition(assistant.discoveryInfo == nil)
    assistant.delegate = nil
    assistant.start()
    assistant.stop()
    _ = peer
}

func multipeerConnectivityRuntimeMain() async {
    assertConstantsAndEnums()
    assertPeerIdentity()
    let peer = MCPeerID(displayName: "runtime-peer")
    assertSession(peer: peer)
    let session = MCSession(peer: peer)
    assertSendResourceNonInline(session: session, peer: peer)
    assertNearbyConnectionNonInline(session: session, peer: peer)
    assertAdvertiserNonInline(peer: peer)
    assertBrowserNonInline(peer: peer, session: session)
    assertAssistant(peer: peer, session: session)
    print("MULTIPEERCONNECTIVITY_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await multipeerConnectivityRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()
