#if canImport(UIKit)
import UIKit

/// System browser UI for nearby peers.
///
/// Subclasses the real `UIKit.UIViewController`. This type is omitted from
/// the isolated Foundation-only host compile (`canImport(UIKit)` is false)
/// and must not be replaced with an `NSObject` stand-in. The controller never
/// presents Apple's peer picker and never discovers peers.
@MainActor
open class MCBrowserViewController: UIKit.UIViewController {
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
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor
    public convenience init(serviceType: String, session: MCSession) {
        let browser = MCNearbyServiceBrowser(
            peer: session.myPeerID,
            serviceType: serviceType
        )
        self.init(browser: browser, session: session)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("MCBrowserViewController does not support storyboard decoding")
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
#endif
