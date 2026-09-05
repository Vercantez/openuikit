@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private func requireCode(_ error: any Error, _ code: MCError.Code) {
    precondition(code ~= error)
    let nsError = error as NSError
    precondition(nsError.domain == MCErrorDomain)
    precondition(nsError.code == code.rawValue)
}

/// Schema-v1 sealed gate compiles only this file. The probe is synchronous so
/// a runner without a run loop cannot hang.
func multipeerConnectivityRuntimeProbe() {
    precondition(MCErrorDomain == "MCErrorDomain")
    precondition(kMCSessionMinimumNumberOfPeers == 2)
    precondition(kMCSessionMaximumNumberOfPeers == 8)
    precondition(MCEncryptionPreference.optional.rawValue == 0)
    precondition(MCSessionSendDataMode.reliable.rawValue == 0)
    precondition(MCSessionState.notConnected.rawValue == 0)
    precondition(MCError.Code.unavailable.rawValue == 6)

    let peer = MCPeerID(displayName: "runtime-peer")
    precondition(peer.displayName == "runtime-peer")
    let session = MCSession(peer: peer)
    precondition(session.connectedPeers.isEmpty)
    do {
        try session.send(Data([1]), toPeers: [peer], with: .reliable)
        fatalError("send should throw")
    } catch {
        requireCode(error, .notConnected)
    }

    var resourceCalls = 0
    let progress = session.sendResource(
        at: URL(fileURLWithPath: "/tmp/mc-runtime"),
        withName: "blob",
        toPeer: peer
    ) { error in
        resourceCalls += 1
        requireCode(error!, .notConnected)
    }
    precondition(progress == nil)
    precondition(resourceCalls == 1)

    var nearbyCalls = 0
    session.nearbyConnectionData(forPeer: peer) { data, error in
        nearbyCalls += 1
        precondition(data == nil)
        requireCode(error!, .unavailable)
    }
    precondition(nearbyCalls == 1)

    final class AdvertiserProbe: NSObject, MCNearbyServiceAdvertiserDelegate {
        var failures = 0
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
            failures += 1
            requireCode(error, .unavailable)
        }
    }
    let advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "ou-xfer")
    let advertiserProbe = AdvertiserProbe()
    advertiser.delegate = advertiserProbe
    advertiser.startAdvertisingPeer()
    precondition(advertiserProbe.failures == 1)
    advertiser.stopAdvertisingPeer()

    final class BrowserProbe: NSObject, MCNearbyServiceBrowserDelegate {
        var failures = 0
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
            _ = browser
            failures += 1
            requireCode(error, .unavailable)
        }
    }
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    let browserProbe = BrowserProbe()
    browser.delegate = browserProbe
    browser.startBrowsingForPeers()
    precondition(browserProbe.failures == 1)
    browser.invitePeer(peer, to: session, withContext: nil, timeout: 1)
    browser.stopBrowsingForPeers()

    let assistant = MCAdvertiserAssistant(serviceType: "ou-xfer", discoveryInfo: nil, session: session)
    assistant.start()
    assistant.stop()

    let controller = MCBrowserViewController(serviceType: "ou-xfer", session: session)
    precondition(controller.session === session)
    precondition(controller.minimumNumberOfPeers == kMCSessionMinimumNumberOfPeers)
    controller.maximumNumberOfPeers = 3
    precondition(controller.maximumNumberOfPeers == 3)

    MultipeerConnectivityHostControl.enqueueCompletionProbe {}
}

multipeerConnectivityRuntimeProbe()
print("MULTIPEERCONNECTIVITY_AGENT_RUNTIME_OK")
