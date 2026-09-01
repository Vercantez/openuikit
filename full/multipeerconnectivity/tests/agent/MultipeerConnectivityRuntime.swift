import Foundation
import MultipeerConnectivity

final class SessionProbeDelegate: NSObject, MCSessionDelegate {
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

final class AdvertiserProbeDelegate: NSObject, MCNearbyServiceAdvertiserDelegate {
    var startError: (any Error)?

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
    }
}

final class BrowserProbeDelegate: NSObject, MCNearbyServiceBrowserDelegate {
    var startError: (any Error)?
    var foundCount = 0

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

final class BrowserUIProbeDelegate: NSObject, MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(
        _ browserViewController: MCBrowserViewController
    ) {
        _ = browserViewController
    }

    func browserViewControllerWasCancelled(
        _ browserViewController: MCBrowserViewController
    ) {
        _ = browserViewController
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

precondition(kMCSessionMinimumNumberOfPeers == 2)
precondition(kMCSessionMaximumNumberOfPeers == 8)
precondition(MCErrorDomain == "MCErrorDomain")
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
    let data = try NSKeyedArchiver.archivedData(
        withRootObject: alice,
        requiringSecureCoding: true
    )
    let decoded = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: MCPeerID.self,
        from: data
    )
    precondition(decoded == alice)
    precondition(decoded?.displayName == "alice")
} catch {
    fatalError("MCPeerID archive failed: \(error)")
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

do {
    try session.send(Data([0x01]), toPeers: [], with: .reliable)
    fatalError("empty peer list must be invalidParameter")
} catch {
    requireMCError(error, code: .invalidParameter)
}

do {
    try session.send(Data([0x01]), toPeers: [aliceTwin], with: .reliable)
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
    _ = try session.startStream(withName: "chat", toPeer: aliceTwin)
    fatalError("startStream must fail closed")
} catch {
    requireMCError(error, code: .notConnected)
}

var resourceProgress: Progress? = Progress(totalUnitCount: 1)
var resourceError: (any Error)?
resourceProgress = session.sendResource(
    at: URL(fileURLWithPath: "/tmp/missing-mc-resource"),
    withName: "payload.bin",
    toPeer: aliceTwin
) { error in
    resourceError = error
}
precondition(resourceProgress == nil)
requireMCError(resourceError!, code: .notConnected)

var nearbyError: (any Error)?
session.nearbyConnectionData(forPeer: aliceTwin) { data, error in
    precondition(data == nil)
    nearbyError = error
}
requireMCError(nearbyError!, code: .unavailable)

let nearbyLock = DispatchSemaphore(value: 0)
var nearbyAsyncError: (any Error)?
Task {
    do {
        _ = try await session.nearbyConnectionData(forPeer: aliceTwin)
        fatalError("nearbyConnectionData must fail closed")
    } catch {
        nearbyAsyncError = error
    }
    nearbyLock.signal()
}
nearbyLock.wait()
requireMCError(nearbyAsyncError!, code: .unavailable)

session.connectPeer(aliceTwin, withNearbyConnectionData: Data([0xFF]))
session.cancelConnectPeer(aliceTwin)
session.disconnect()
precondition(session.connectedPeers.isEmpty)

let advertiserDelegate = AdvertiserProbeDelegate()
let advertiser = MCNearbyServiceAdvertiser(
    peer: alice,
    discoveryInfo: ["role": "source"],
    serviceType: "sig-xfer"
)
precondition(advertiser.myPeerID == alice)
precondition(advertiser.discoveryInfo?["role"] == "source")
precondition(advertiser.serviceType == "sig-xfer")
advertiser.delegate = advertiserDelegate
advertiser.startAdvertisingPeer()
requireMCError(advertiserDelegate.startError!, code: .unavailable)
advertiser.stopAdvertisingPeer()

let invalidAdvertiserDelegate = AdvertiserProbeDelegate()
let invalidAdvertiser = MCNearbyServiceAdvertiser(
    peer: alice,
    discoveryInfo: nil,
    serviceType: "INVALID_TYPE"
)
invalidAdvertiser.delegate = invalidAdvertiserDelegate
invalidAdvertiser.startAdvertisingPeer()
requireMCError(invalidAdvertiserDelegate.startError!, code: .invalidParameter)

let browserDelegate = BrowserProbeDelegate()
let browser = MCNearbyServiceBrowser(peer: alice, serviceType: "sig-xfer")
precondition(browser.myPeerID == alice)
precondition(browser.serviceType == "sig-xfer")
browser.delegate = browserDelegate
browser.startBrowsingForPeers()
requireMCError(browserDelegate.startError!, code: .unavailable)
precondition(browserDelegate.foundCount == 0)
browser.invitePeer(
    aliceTwin,
    to: session,
    withContext: Data([0x02]),
    timeout: 30
)
precondition(session.connectedPeers.isEmpty)
browser.stopBrowsingForPeers()

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

let uiDelegate = BrowserUIProbeDelegate()
MainActor.assumeIsolated {
    let controller = MCBrowserViewController(serviceType: "sig-xfer", session: session)
    controller.delegate = uiDelegate
    precondition(controller.session === session)
    precondition(controller.browser?.serviceType == "sig-xfer")
    precondition(controller.minimumNumberOfPeers == kMCSessionMinimumNumberOfPeers)
    precondition(controller.maximumNumberOfPeers == kMCSessionMaximumNumberOfPeers)
    controller.minimumNumberOfPeers = 0
    precondition(controller.minimumNumberOfPeers == kMCSessionMinimumNumberOfPeers)
    controller.maximumNumberOfPeers = 99
    precondition(controller.maximumNumberOfPeers == kMCSessionMaximumNumberOfPeers)
    let wrapped = MCBrowserViewController(browser: browser, session: session)
    precondition(wrapped.browser === browser)
}
_ = uiDelegate
_ = sessionDelegate

print("MULTIPEERCONNECTIVITY_AGENT_RUNTIME_OK")
