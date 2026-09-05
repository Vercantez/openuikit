@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private final class BrowserViewRecordingDelegate: NSObject, MCBrowserViewControllerDelegate {
    var finished = 0
    var cancelled = 0
    var presented: [(MCPeerID, [String: String]?)] = []
    var presentReturn = true

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        _ = browserViewController
        finished += 1
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        _ = browserViewController
        cancelled += 1
    }

    func browserViewController(
        _ browserViewController: MCBrowserViewController,
        shouldPresentNearbyPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) -> Bool {
        _ = browserViewController
        presented.append((peerID, info))
        return presentReturn
    }
}

func testMCBrowserViewControllerInits() {
    let peer = MCPeerID(displayName: "host")
    let session = MCSession(peer: peer)
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
    let controller = MCBrowserViewController(browser: browser, session: session)
    precondition(controller.session === session)
    precondition(controller.browser === browser)
    let viaService = MCBrowserViewController(serviceType: "ou-xfer", session: session)
    precondition(viaService.session === session)
    precondition(viaService.browser?.serviceType == "ou-xfer")
    precondition(viaService.browser?.myPeerID === peer)
}

func testMCBrowserViewControllerPeerLimits() {
    let peer = MCPeerID(displayName: "host")
    let session = MCSession(peer: peer)
    let controller = MCBrowserViewController(serviceType: "ou-xfer", session: session)
    precondition(controller.minimumNumberOfPeers == kMCSessionMinimumNumberOfPeers)
    precondition(controller.maximumNumberOfPeers == kMCSessionMaximumNumberOfPeers)
    controller.minimumNumberOfPeers = 0
    precondition(controller.minimumNumberOfPeers == kMCSessionMinimumNumberOfPeers)
    controller.maximumNumberOfPeers = 99
    precondition(controller.maximumNumberOfPeers == kMCSessionMaximumNumberOfPeers)
    controller.minimumNumberOfPeers = 4
    controller.maximumNumberOfPeers = 6
    precondition(controller.minimumNumberOfPeers == 4)
    precondition(controller.maximumNumberOfPeers == 6)
}

func testMCBrowserViewControllerDelegateCallbacks() {
    let peer = MCPeerID(displayName: "host")
    let remote = MCPeerID(displayName: "nearby")
    let session = MCSession(peer: peer)
    let controller = MCBrowserViewController(serviceType: "ou-xfer", session: session)
    let probe = BrowserViewRecordingDelegate()
    controller.delegate = probe
    precondition(controller.delegate === probe)
    let asExistential: any MCBrowserViewControllerDelegate = probe
    asExistential.browserViewControllerDidFinish(controller)
    asExistential.browserViewControllerWasCancelled(controller)
    let shouldPresent = asExistential.browserViewController(
        controller,
        shouldPresentNearbyPeer: remote,
        withDiscoveryInfo: ["a": "b"]
    )
    precondition(probe.finished == 1)
    precondition(probe.cancelled == 1)
    precondition(shouldPresent)
    precondition(probe.presented.count == 1)
    precondition(probe.presented[0].0 === remote)

    final class DefaultPresenter: NSObject, MCBrowserViewControllerDelegate {
        func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
            _ = browserViewController
        }
        func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
            _ = browserViewController
        }
    }
    let defaults = DefaultPresenter()
    let defaultPresent = (defaults as any MCBrowserViewControllerDelegate).browserViewController(
        controller,
        shouldPresentNearbyPeer: remote,
        withDiscoveryInfo: nil
    )
    precondition(defaultPresent)
}
