import Foundation

/// System browser UI for nearby peers.
///
/// Apple's overlay subclasses `UIViewController`. The host gate compiles
/// against Foundation only, so this Linux starting point subclasses
/// `NSObject`, keeps the documented peer-limit and session/browser properties,
/// and never presents Apple's peer picker or discovers peers.
@MainActor
open class MCBrowserViewController: NSObject {
    open weak var delegate: (any MCBrowserViewControllerDelegate)?
    open var browser: MCNearbyServiceBrowser? { _browser }
    open var session: MCSession { _session }

    private let _browser: MCNearbyServiceBrowser?
    private let _session: MCSession
    private var _minimumNumberOfPeers: Int
    private var _maximumNumberOfPeers: Int

    @MainActor
    public init(browser: MCNearbyServiceBrowser, session: MCSession) {
        _browser = browser
        _session = session
        _minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers
        _maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers
        super.init()
    }

    @MainActor
    public convenience init(serviceType: String, session: MCSession) {
        let browser = MCNearbyServiceBrowser(
            peer: session.myPeerID,
            serviceType: serviceType
        )
        self.init(browser: browser, session: session)
    }

    @MainActor
    open var minimumNumberOfPeers: Int {
        get { _minimumNumberOfPeers }
        set {
            let upper = min(_maximumNumberOfPeers, kMCSessionMaximumNumberOfPeers)
            _minimumNumberOfPeers = min(
                max(newValue, kMCSessionMinimumNumberOfPeers),
                upper
            )
        }
    }

    @MainActor
    open var maximumNumberOfPeers: Int {
        get { _maximumNumberOfPeers }
        set {
            let lower = max(_minimumNumberOfPeers, kMCSessionMinimumNumberOfPeers)
            _maximumNumberOfPeers = max(
                min(newValue, kMCSessionMaximumNumberOfPeers),
                lower
            )
        }
    }
}

/// Delegate for the system peer-browser UI.
public protocol MCBrowserViewControllerDelegate: NSObjectProtocol {
    func browserViewControllerDidFinish(
        _ browserViewController: MCBrowserViewController
    )

    func browserViewControllerWasCancelled(
        _ browserViewController: MCBrowserViewController
    )

    func browserViewController(
        _ browserViewController: MCBrowserViewController,
        shouldPresentNearbyPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) -> Bool
}

public extension MCBrowserViewControllerDelegate {
    func browserViewController(
        _ browserViewController: MCBrowserViewController,
        shouldPresentNearbyPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) -> Bool {
        _ = (browserViewController, peerID, info)
        return true
    }
}
