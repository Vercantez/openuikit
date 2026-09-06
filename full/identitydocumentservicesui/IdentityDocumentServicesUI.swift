/// Portable Linux starting point for Apple's public `IdentityDocumentServicesUI`
/// module.
///
/// Request-context phase, result-builder composition, stored origin/request
/// values, and weak presentment delegates are real and process-local. Linux
/// has no ISO 18013 web-presentment sheet, Wallet identity daemon, or
/// Identity Document Provider `appex`: `performRequests(_:origin:)` and
/// `sendResponse(_:)` always throw, and `performRegistrationUpdates()` never
/// talks to `IdentityDocumentProviderRegistrationStore`.
///
/// Apple annotates extension and presentment types `@MainActor`. Isolated
/// Linux types are usable from synchronous tests because the sealed runner
/// has no run loop. Darwin `async throws` methods are synchronous `throws`.

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Linux-only result when a host asks to present Apple identity-document UI.
/// Not an Apple `IdentityDocumentPresentmentError` code or NSError domain.
public enum IdentityDocumentServicesUIUnavailable: Error, Equatable, Hashable, Sendable {
    case linuxHost(operation: String)
}

/// Process-local ISO 18013 request-context phase. Not an Apple presentment
/// session state.
public enum ISO18013MobileDocumentRequestHostPhase: Equatable, Sendable {
    case idle
    case cancelled
    case sendAttempted
}

/// Process-local web-presentment controller phase. Not an Apple UIKit sheet.
public enum IdentityDocumentWebPresentmentHostPhase: Equatable, Sendable {
    case idle
    case failed
}

/// Darwin aliases this to `UIWindow`. Linux uses the isolation `UIWindow`
/// when UIKit cannot be imported.
public typealias IdentityDocumentPresentationAnchor = UIWindow

/// Linux host-test control. Not part of Apple's public
/// `IdentityDocumentServicesUI` surface.
@_spi(OpenUIKitHost)
public enum IdentityDocumentServicesUIHostControl {
    /// Always throws. Linux never presents Apple identity-document UI.
    public static func presentWebPresentment() throws {
        throw IdentityDocumentServicesUIUnavailable.linuxHost(
            operation: "presentWebPresentment"
        )
    }
}
