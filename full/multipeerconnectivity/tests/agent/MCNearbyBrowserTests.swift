@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private final class BrowserRecordingDelegate: NSObject, MCNearbyServiceBrowserDelegate {
    var startErrors: [any Error] = []
    var found: [(MCPeerID, [String: String]?)] = []
    var lost: [MCPeerID] = []

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        _ = browser
        found.append((peerID, info))
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        _ = browser
        lost.append(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        _ = browser
        startErrors.append(error)
    }
}

func testMCNearbyServiceBrowserConfiguration() {
    let peer = MCPeerID(displayName: "browser")
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    precondition(browser.myPeerID === peer)
    precondition(browser.serviceType == "ou-xfer")
    precondition(browser.delegate == nil)
    let probe = BrowserRecordingDelegate()
    browser.delegate = probe
    precondition(browser.delegate === probe)
}

func testMCNearbyServiceBrowserStartFailsUnavailable() {
    let peer = MCPeerID(displayName: "browser")
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    let probe = BrowserRecordingDelegate()
    browser.delegate = probe
    browser.startBrowsingForPeers()
    precondition(probe.startErrors.count == 1)
    precondition(MCError.Code.unavailable ~= probe.startErrors[0])
    browser.stopBrowsingForPeers()
    precondition(probe.startErrors.count == 1)
    precondition(probe.found.isEmpty)
    precondition(probe.lost.isEmpty)
}

func testMCNearbyServiceBrowserInvitePeerInert() {
    let peer = MCPeerID(displayName: "browser")
    let remote = MCPeerID(displayName: "remote")
    let session = MCSession(peer: peer)
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    browser.invitePeer(remote, to: session, withContext: Data(), timeout: 1)
    precondition(session.connectedPeers.isEmpty)
}

func testMCNearbyServiceBrowserFoundPeer() {
    let peer = MCPeerID(displayName: "browser")
    let remote = MCPeerID(displayName: "found")
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    let probe = BrowserRecordingDelegate()
    let asExistential: any MCNearbyServiceBrowserDelegate = probe
    asExistential.browser(browser, foundPeer: remote, withDiscoveryInfo: ["k": "v"])
    precondition(probe.found.count == 1)
    precondition(probe.found[0].0 === remote)
    precondition(probe.found[0].1?["k"] == "v")
    browser.startBrowsingForPeers()
    precondition(probe.found.count == 1)
}

func testMCNearbyServiceBrowserLostPeer() {
    let peer = MCPeerID(displayName: "browser")
    let remote = MCPeerID(displayName: "lost")
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    let probe = BrowserRecordingDelegate()
    let asExistential: any MCNearbyServiceBrowserDelegate = probe
    asExistential.browser(browser, lostPeer: remote)
    precondition(probe.lost.count == 1)
    precondition(probe.lost[0] === remote)
    browser.startBrowsingForPeers()
    precondition(probe.lost.count == 1)
}
