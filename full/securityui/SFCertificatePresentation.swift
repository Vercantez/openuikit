import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(Security)
import Security
#endif

/// UIKit object that presents a system certificate sheet on Darwin.
///
/// Isolated Linux stores `trust`, `title`, `message`, and `helpURL`, and
/// records `presentSheet` / `dismissSheet` as a small state machine. It never
/// evaluates the trust, never instantiates sheet chrome, and never invents a
/// default title, message, or help URL (Apple's nil-default strings are
/// unobserved).
///
/// Designated initializer is `init(trust:)` (`DisableDefaultCtor` in the
/// pinned `dotnet/macios` binding). `trust` is get-only; Darwin uses assign
/// / `unowned(unsafe)` and does not copy the `SecTrust` object.
///
/// https://developer.apple.com/documentation/securityui/sfcertificatepresentation
open class SFCertificatePresentation: NSObject {
    /// Linux retains the trust so an `unowned(unsafe)` public getter cannot
    /// dangle after `init` returns. Darwin's `ArgumentSemantic.Assign` does
    /// not retain; see `oracle-questions.tsv`.
    private let linuxRetainedTrust: SecTrust

    /// Get-only trust installed by `init(trust:)`. Matches the graph
    /// `unowned(unsafe) var trust: SecTrust { get }`.
    open private(set) unowned(unsafe) var trust: SecTrust

    open var title: String?
    open var message: String?
    open var helpURL: URL?

    private weak var presentingViewController: UIViewController?
    private var dismissHandler: (() -> Void)?
    private var phase: SFCertificatePresentationPhase = .idle
    private var presentCount = 0
    private var dismissCount = 0

    /// Designated initializer. The caller owns `trust` for Darwin's assign
    /// lifetime; Linux additionally retains it.
    public init(trust: SecTrust) {
        self.linuxRetainedTrust = trust
        self.trust = trust
        super.init()
    }

    /// Darwin presents a sheet over `viewController`. Linux records the
    /// request, retains a weak presenter and the optional dismiss handler,
    /// and returns without showing chrome and without calling the handler.
    /// A second `presentSheet` while `.requested` is fail-closed: no stacked
    /// sheet, existing handler kept.
    open func presentSheet(
        in viewController: UIViewController,
        dismissHandler: (() -> Void)? = nil
    ) {
        presentCount += 1
        guard phase != .requested else {
            return
        }
        presentingViewController = viewController
        self.dismissHandler = dismissHandler
        phase = .requested
    }

    /// Darwin dismisses the presented sheet. Linux: if a presentation was
    /// requested, clear presenter state and invoke the stored handler
    /// **once, synchronously** before return. If idle, this is a no-op.
    /// Darwin's animation/queue for the handler is unobserved.
    open func dismissSheet() {
        dismissCount += 1
        guard phase == .requested else {
            return
        }
        let handler = dismissHandler
        dismissHandler = nil
        presentingViewController = nil
        phase = .dismissed
        handler?()
    }

    var linuxPhase: SFCertificatePresentationPhase { phase }
    var linuxPresentingViewController: UIViewController? { presentingViewController }
    var linuxPresentCount: Int { presentCount }
    var linuxDismissCount: Int { dismissCount }
    var linuxDismissHandlerInstalled: Bool { dismissHandler != nil }
    var linuxRetainedTrustIdentity: SecTrust { linuxRetainedTrust }
}
