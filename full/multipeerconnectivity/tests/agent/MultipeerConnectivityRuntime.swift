import Dispatch
import Foundation
import MultipeerConnectivity

class SessionProbeDelegate: NSObject, MCSessionDelegate {
    var receivedDataCount = 0

    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        _ = (session, peerID, state)
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        _ = (session, peerID)
        receivedDataCount += 1
        _ = data
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

final class SessionOverrideDelegate: SessionProbeDelegate {
    override func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        receivedDataCount += 10
        super.session(session, didReceive: data, fromPeer: peerID)
    }
}

class AdvertiserProbeDelegate: NSObject, MCNearbyServiceAdvertiserDelegate {
    var startError: (any Error)?
    var startCount = 0
    let startLock = DispatchSemaphore(value: 0)

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
        _ = advertiser
        startError = error
        startCount += 1
        startLock.signal()
    }
}

final class AdvertiserOverrideDelegate: AdvertiserProbeDelegate {
    var overrideCount = 0

    override func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        overrideCount += 1
        super.advertiser(advertiser, didNotStartAdvertisingPeer: error)
    }
}

class BrowserProbeDelegate: NSObject, MCNearbyServiceBrowserDelegate {
    var startError: (any Error)?
    var startCount = 0
    var foundCount = 0
    let startLock = DispatchSemaphore(value: 0)

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        _ = (browser, peerID, info)
        foundCount += 1
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        _ = (browser, peerID)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        _ = browser
        startError = error
        startCount += 1
        startLock.signal()
    }
}

final class BrowserOverrideDelegate: BrowserProbeDelegate {
    var overrideCount = 0

    override func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        overrideCount += 1
        super.browser(browser, didNotStartBrowsingForPeers: error)
    }
}

final class AssistantProbeDelegate: NSObject, MCAdvertiserAssistantDelegate {
    var presented = false
    var dismissed = false

    func advertiserAssistantWillPresentInvitation(
        _ advertiserAssistant: MCAdvertiserAssistant
    ) {
        _ = advertiserAssistant
        presented = true
    }

    func advertiserAssistantDidDismissInvitation(
        _ advertiserAssistant: MCAdvertiserAssistant
    ) {
        _ = advertiserAssistant
        dismissed = true
    }
}

final class CountingAdvertiser: MCNearbyServiceAdvertiser {
    var startCalls = 0

    override func startAdvertisingPeer() {
        startCalls += 1
        super.startAdvertisingPeer()
    }
}

final class CountingBrowser: MCNearbyServiceBrowser {
    var startCalls = 0

    override func startBrowsingForPeers() {
        startCalls += 1
        super.startBrowsingForPeers()
    }
}

func requireMCError(_ error: any Error, code: MCError.Code) {
    guard let typed = error as? MCError else {
        fatalError("expected typed MCError")
    }
    precondition(typed.code == code)
    precondition(typed.errorCode == code.rawValue)
    precondition(MCError.errorDomain == MCErrorDomain)
}

func waitForCallback(_ semaphore: DispatchSemaphore) {
    let result = semaphore.wait(timeout: .now() + 2)
    precondition(result == .success, "fail-closed callback was not delivered")
}

precondition(kMCSessionMinimumNumberOfPeers == 2)
precondition(kMCSessionMaximumNumberOfPeers == 8)
precondition(!MCErrorDomain.isEmpty)
precondition(MCError.errorDomain == MCErrorDomain)

precondition(MCEncryptionPreference.optional.rawValue == 0)
precondition(MCEncryptionPreference.required.rawValue == 1)
precondition(MCEncryptionPreference.none.rawValue == 2)
precondition(MCEncryptionPreference.optional != .required)
precondition(MCSessionSendDataMode.reliable.rawValue == 0)
precondition(MCSessionSendDataMode.unreliable.rawValue == 1)
precondition(MCSessionState.notConnected.rawValue == 0)
precondition(MCSessionState.connecting.rawValue == 1)
precondition(MCSessionState.connected.rawValue == 2)
precondition(MCError.Code.unknown.rawValue == 0)
precondition(MCError.Code.unavailable.rawValue == 6)
precondition(MCError.Code(rawValue: 99) == nil)

let empty = MCError(.unavailable)
precondition(empty.userInfo.isEmpty)
precondition(empty.errorUserInfo.isEmpty)
precondition(empty == MCError(.unavailable))
precondition(empty != MCError(.notConnected))
precondition(empty.hashValue == MCError(.unavailable).hashValue)
switch empty {
case MCError.unavailable:
    break
default:
    fatalError("MCError.Code.~= failed")
}

let alice = MCPeerID(displayName: "alice")
let aliceTwin = MCPeerID(displayName: "alice")
precondition(alice.displayName == "alice")
precondition(alice != aliceTwin)
let aliceCopy = alice.copy() as! MCPeerID
precondition(aliceCopy == alice)
precondition(aliceCopy.displayName == "alice")
do {
    let coder = NSKeyedArchiver(requiringSecureCoding: true)
    precondition(MCPeerID(coder: coder) == nil)
}

let session = MCSession(peer: alice)
precondition(session.myPeerID == alice)
precondition(session.connectedPeers.isEmpty)
precondition(session.encryptionPreference == .optional)
precondition(session.securityIdentity == nil)
let sessionDelegate = SessionProbeDelegate()
session.delegate = sessionDelegate

let required = MCSession(
    peer: aliceTwin,
    securityIdentity: nil,
    encryptionPreference: .required
)
precondition(required.encryptionPreference == .required)

let payload = Data([0x01, 0x02])
do {
    try session.send(Data(), toPeers: [], with: .reliable)
    fatalError("empty peer list must be invalidParameter")
} catch {
    requireMCError(error, code: .invalidParameter)
}

do {
    try session.send(payload, toPeers: [aliceTwin], with: .reliable)
    fatalError("send must fail closed")
} catch {
    requireMCError(error, code: .notConnected)
}

do {
    _ = try session.startStream(withName: "", toPeer: aliceTwin)
    fatalError("empty stream name must be invalidParameter")
} catch {
    requireMCError(error, code: .invalidParameter)
}

do {
    let produced: OutputStream = try session.startStream(
        withName: "chat",
        toPeer: aliceTwin
    )
    _ = produced
    fatalError("startStream must fail closed")
} catch {
    requireMCError(error, code: .notConnected)
}

var resourceCount = 0
var resourceError: (any Error)?
let resourceLock = DispatchSemaphore(value: 0)
let resourceProgress = session.sendResource(
    at: URL(fileURLWithPath: "/tmp/missing-mc-resource"),
    withName: "payload.bin",
    toPeer: aliceTwin
) { error in
    resourceCount += 1
    resourceError = error
    resourceLock.signal()
}
precondition(resourceProgress == nil)
precondition(resourceCount == 0)
waitForCallback(resourceLock)
precondition(resourceCount == 1)
requireMCError(resourceError!, code: .notConnected)
Thread.sleep(forTimeInterval: 0.05)
precondition(resourceCount == 1)

var nearbyCount = 0
var nearbyError: (any Error)?
let nearbyLock = DispatchSemaphore(value: 0)
session.nearbyConnectionData(forPeer: aliceTwin) { data, error in
    precondition(data == nil)
    nearbyCount += 1
    nearbyError = error
    nearbyLock.signal()
}
precondition(nearbyCount == 0)
waitForCallback(nearbyLock)
precondition(nearbyCount == 1)
requireMCError(nearbyError!, code: .unavailable)
Thread.sleep(forTimeInterval: 0.05)
precondition(nearbyCount == 1)

let nearbyAsyncLock = DispatchSemaphore(value: 0)
var nearbyAsyncError: (any Error)?
Task {
    do {
        _ = try await session.nearbyConnectionData(forPeer: aliceTwin)
        fatalError("nearbyConnectionData must fail closed")
    } catch {
        nearbyAsyncError = error
    }
    nearbyAsyncLock.signal()
}
waitForCallback(nearbyAsyncLock)
requireMCError(nearbyAsyncError!, code: .unavailable)

session.connectPeer(aliceTwin, withNearbyConnectionData: payload)
session.cancelConnectPeer(aliceTwin)
session.disconnect()
precondition(session.connectedPeers.isEmpty)

let advertiserOverride = AdvertiserOverrideDelegate()
let advertiserExistential: any MCNearbyServiceAdvertiserDelegate = advertiserOverride
let countingAdvertiser = CountingAdvertiser(
    peer: alice,
    discoveryInfo: ["role": "source"],
    serviceType: "sig-xfer"
)
precondition(countingAdvertiser.myPeerID == alice)
precondition(countingAdvertiser.discoveryInfo?["role"] == "source")
precondition(countingAdvertiser.serviceType == "sig-xfer")
countingAdvertiser.delegate = advertiserExistential
countingAdvertiser.startAdvertisingPeer()
precondition(countingAdvertiser.startCalls == 1)
precondition(advertiserOverride.startCount == 0)
precondition(advertiserOverride.overrideCount == 0)
waitForCallback(advertiserOverride.startLock)
precondition(advertiserOverride.overrideCount == 1)
precondition(advertiserOverride.startCount == 1)
requireMCError(advertiserOverride.startError!, code: .unavailable)
Thread.sleep(forTimeInterval: 0.05)
precondition(advertiserOverride.startCount == 1)
countingAdvertiser.stopAdvertisingPeer()

let invalidAdvertiserDelegate = AdvertiserProbeDelegate()
let invalidAdvertiser = MCNearbyServiceAdvertiser(
    peer: alice,
    discoveryInfo: nil,
    serviceType: "INVALID_TYPE"
)
invalidAdvertiser.delegate = invalidAdvertiserDelegate
invalidAdvertiser.startAdvertisingPeer()
precondition(invalidAdvertiserDelegate.startCount == 0)
waitForCallback(invalidAdvertiserDelegate.startLock)
precondition(invalidAdvertiserDelegate.startCount == 1)
requireMCError(invalidAdvertiserDelegate.startError!, code: .invalidParameter)

let browserOverride = BrowserOverrideDelegate()
let browserExistential: any MCNearbyServiceBrowserDelegate = browserOverride
let countingBrowser = CountingBrowser(peer: alice, serviceType: "sig-xfer")
precondition(countingBrowser.myPeerID == alice)
precondition(countingBrowser.serviceType == "sig-xfer")
countingBrowser.delegate = browserExistential
countingBrowser.startBrowsingForPeers()
precondition(countingBrowser.startCalls == 1)
precondition(browserOverride.startCount == 0)
waitForCallback(browserOverride.startLock)
precondition(browserOverride.overrideCount == 1)
precondition(browserOverride.startCount == 1)
requireMCError(browserOverride.startError!, code: .unavailable)
precondition(browserOverride.foundCount == 0)
Thread.sleep(forTimeInterval: 0.05)
precondition(browserOverride.startCount == 1)
countingBrowser.invitePeer(
    aliceTwin,
    to: session,
    withContext: payload,
    timeout: 30
)
precondition(session.connectedPeers.isEmpty)
countingBrowser.stopBrowsingForPeers()

let assistantDelegate = AssistantProbeDelegate()
let assistant = MCAdvertiserAssistant(
    serviceType: "sig-xfer",
    discoveryInfo: ["role": "source"],
    session: session
)
precondition(assistant.session === session)
precondition(assistant.serviceType == "sig-xfer")
assistant.delegate = assistantDelegate
assistant.start()
assistant.stop()
precondition(assistantDelegate.presented == false)
precondition(assistantDelegate.dismissed == false)

let sessionOverride = SessionOverrideDelegate()
let sessionExistential: any MCSessionDelegate = sessionOverride
let incoming = Data([0xA5])
let incomingStream = InputStream(data: incoming)
let incomingProgress = Progress(totalUnitCount: 4)
sessionExistential.session(session, didReceive: incoming, fromPeer: aliceTwin)
sessionExistential.session(
    session,
    didReceive: incomingStream,
    withName: "chat",
    fromPeer: aliceTwin
)
sessionExistential.session(
    session,
    didStartReceivingResourceWithName: "payload.bin",
    fromPeer: aliceTwin,
    with: incomingProgress
)
precondition(sessionOverride.receivedDataCount == 11)
_ = OutputStream.toMemory()
_ = sessionDelegate

print("MULTIPEERCONNECTIVITY_AGENT_RUNTIME_OK")
