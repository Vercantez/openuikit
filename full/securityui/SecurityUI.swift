@_exported import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Security)
import Security
#endif

/// Linux starting point for Apple's public `SecurityUI` module.
///
/// Isolated host compilation has Foundation only. UIKit / SwiftUI / Security
/// APIs use the lookalikes in `SecurityUILookalikes.swift` until those modules
/// are on the link line. Linux has no Apple certificate sheet chrome, no
/// SecurityUI daemon, and no entitlement to present system trust UI: every
/// path that would display a certificate, evaluate `SecTrust`, or invent a
/// default "Learn More" URL stays fail-closed.
///
/// Public census: `SFCertificatePresentation` and
/// `View.certificateSheet(trust:title:message:help:)`.
/// Darwin: https://developer.apple.com/documentation/securityui

/// Fail-closed error for hardware, daemon, entitlement, or Apple-service
/// paths. Linux never invents a successful certificate-sheet presentation.
public enum SecurityUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}

/// Presentation request recorded by `SFCertificatePresentation` on Linux.
/// Darwin would drive UIKit sheet chrome; Linux never leaves `.idle` via a
/// successful present. `.requested` means `presentSheet` was called and the
/// sheet has not been programmatically dismissed. `.dismissed` means
/// `dismissSheet` ran after a request.
public enum SFCertificatePresentationPhase: Equatable, Hashable, Sendable {
    case idle
    case requested
    case dismissed
}

/// Linux host-test control. Hidden from ordinary `import SecurityUI`
/// clients and not part of Apple's public SecurityUI surface.
@_spi(OpenUIKitHost)
public enum SecurityUIHostControl {
    /// Isolated-host `SecTrust` construction. When Security is imported, the
    /// caller must supply a real trust created with Security APIs; this
    /// factory then fails closed instead of inventing `SecTrustCreateWithCertificates`.
    public static func makeTrust() -> SecTrust {
        #if canImport(Security)
        preconditionFailure(
            "EC2 Security integration must construct SecTrust via Security; Linux must not invent evaluation"
        )
        #else
        return SecTrust()
        #endif
    }

    public static func phase(of presentation: SFCertificatePresentation) -> SFCertificatePresentationPhase {
        presentation.linuxPhase
    }

    public static func presentingViewController(
        of presentation: SFCertificatePresentation
    ) -> UIViewController? {
        presentation.linuxPresentingViewController
    }

    public static func presentCount(of presentation: SFCertificatePresentation) -> Int {
        presentation.linuxPresentCount
    }

    public static func dismissCount(of presentation: SFCertificatePresentation) -> Int {
        presentation.linuxDismissCount
    }

    public static func dismissHandlerInstalled(on presentation: SFCertificatePresentation) -> Bool {
        presentation.linuxDismissHandlerInstalled
    }

    /// Records a present attempt and returns the fail-closed error. Does not
    /// evaluate `trust` and does not invoke the dismiss handler.
    @discardableResult
    public static func presentSheetFailClosed(
        _ presentation: SFCertificatePresentation,
        in viewController: UIViewController,
        dismissHandler: (() -> Void)? = nil
    ) -> Result<Void, SecurityUIUnavailable> {
        presentation.presentSheet(in: viewController, dismissHandler: dismissHandler)
        return .failure(.linuxHost(operation: "SFCertificatePresentation.presentSheet"))
    }

    public static func certificateSheetTitle<Content: View>(
        _ view: SecurityUICertificateSheetView<Content>
    ) -> String? {
        view.title
    }

    public static func certificateSheetMessage<Content: View>(
        _ view: SecurityUICertificateSheetView<Content>
    ) -> String? {
        view.message
    }

    public static func certificateSheetHelp<Content: View>(
        _ view: SecurityUICertificateSheetView<Content>
    ) -> URL? {
        view.help
    }

    public static func certificateSheetHasTrust<Content: View>(
        _ view: SecurityUICertificateSheetView<Content>
    ) -> Bool {
        view.linuxHasTrust
    }

    public static func certificateSheetDidPresent<Content: View>(
        _ view: SecurityUICertificateSheetView<Content>
    ) -> Bool {
        view.linuxDidPresent
    }
}
