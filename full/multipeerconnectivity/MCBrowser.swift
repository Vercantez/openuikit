import Foundation
#if canImport(UIKit)
import UIKit
#endif

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
    /// Apple's optional method defaults to presenting every discovered peer.
    /// Linux never discovers peers, so the default is not observed as UI.
    public func browserViewController(
        _ browserViewController: MCBrowserViewController,
        shouldPresentNearbyPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) -> Bool {
        _ = (browserViewController, peerID, info)
        return true
    }
}

/// Nearby-peer browser UI. Darwin subclasses `UIViewController`. Isolated Linux
/// uses `NSObject` and never presents a peer list or invitation sheet.
#if canImport(UIKit)
@MainActor
open class MCBrowserViewController: UIViewController {
    private let _session: MCSession
    private let _browser: MCNearbyServiceBrowser?
    private var _minimumNumberOfPeers: Int = kMCSessionMinimumNumberOfPeers
    private var _maximumNumberOfPeers: Int = kMCSessionMaximumNumberOfPeers

    public var session: MCSession { _session }
    public var browser: MCNearbyServiceBrowser? { _browser }
    public weak var delegate: (any MCBrowserViewControllerDelegate)?

    public var minimumNumberOfPeers: Int {
        get { _minimumNumberOfPeers }
        set { _minimumNumberOfPeers = mcClampPeerCount(newValue) }
    }

    public var maximumNumberOfPeers: Int {
        get { _maximumNumberOfPeers }
        set { _maximumNumberOfPeers = mcClampPeerCount(newValue) }
    }

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
#else
open class MCBrowserViewController: NSObject {
    private let _session: MCSession
    private let _browser: MCNearbyServiceBrowser?
    private var _minimumNumberOfPeers: Int = kMCSessionMinimumNumberOfPeers
    private var _maximumNumberOfPeers: Int = kMCSessionMaximumNumberOfPeers

    public var session: MCSession { _session }
    public var browser: MCNearbyServiceBrowser? { _browser }
    public weak var delegate: (any MCBrowserViewControllerDelegate)?

    public var minimumNumberOfPeers: Int {
        get { _minimumNumberOfPeers }
        set { _minimumNumberOfPeers = mcClampPeerCount(newValue) }
    }

    public var maximumNumberOfPeers: Int {
        get { _maximumNumberOfPeers }
        set { _maximumNumberOfPeers = mcClampPeerCount(newValue) }
    }

    public init(browser: MCNearbyServiceBrowser, session: MCSession) {
        _browser = browser
        _session = session
        super.init()
    }

    public convenience init(serviceType: String, session: MCSession) {
        let browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType)
        self.init(browser: browser, session: session)
    }
}
#endif
