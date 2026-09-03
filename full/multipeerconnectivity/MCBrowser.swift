#if canImport(UIKit)
import Foundation
import UIKit

public protocol MCBrowserViewControllerDelegate: NSObjectProtocol {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController)
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController)
    func browserViewController(
        _ browserViewController: MCBrowserViewController,
        shouldPresentNearbyPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) -> Bool
}

extension MCBrowserViewControllerDelegate {
    public func browserViewController(
        _ browserViewController: MCBrowserViewController,
        shouldPresentNearbyPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) -> Bool {
        _ = (browserViewController, peerID, info)
        return false
    }
}

@MainActor
open class MCBrowserViewController: UIViewController {
    private let _session: MCSession
    private let _browser: MCNearbyServiceBrowser?

    public var session: MCSession { _session }
    public var browser: MCNearbyServiceBrowser? { _browser }
    public weak var delegate: (any MCBrowserViewControllerDelegate)?
    public var minimumNumberOfPeers: Int = kMCSessionMinimumNumberOfPeers
    public var maximumNumberOfPeers: Int = kMCSessionMaximumNumberOfPeers

    public init(browser: MCNearbyServiceBrowser, session: MCSession) {
        _browser = browser
        _session = session
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init(serviceType: String, session: MCSession) {
        let browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType)
        self.init(browser: browser, session: session)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        nil
    }
}
#endif
