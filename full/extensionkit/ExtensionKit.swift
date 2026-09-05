// OpenUIKit Linux starting point for Apple's public ExtensionKit module.
// Isolated host compilation imports Foundation only. UIKit, SwiftUI,
// ExtensionFoundation, and Foundation XPC types are module-local lookalikes
// when those modules are absent. Lookalikes are not Darwin types and are
// compiled out when the real modules are on the import path.
//
// Linux never talks to `appex`, `nsxpc`, or an extension catalog. Hosted UI
// and XPC success are fail-closed. Scene value types, result-builder
// composition, and onConnection accept/reject are process-local and real.

import Foundation

/// Linux-local fail-closed errors. Apple's ExtensionKit NSError domain and
/// codes are unobserved; these discriminators are not Darwin codes.
public enum ExtensionKitHostError: Error, Equatable, Hashable, Sendable {
    /// `EXHostViewController.makeXPCConnection()` cannot open a session.
    case xpcUnavailable
    /// `AppExtension.main()` has no extension process to enter.
    case extensionProcessUnavailable
    /// `EXAppExtensionBrowserViewController` has no extension catalog.
    case extensionCatalogUnavailable
}

extension ExtensionKitHostError: CustomNSError {
    public static var errorDomain: String { "ExtensionKit.Linux" }

    public var errorCode: Int {
        switch self {
        case .xpcUnavailable: return 1
        case .extensionProcessUnavailable: return 2
        case .extensionCatalogUnavailable: return 3
        }
    }
}

extension AppExtension where Configuration == AppExtensionSceneConfiguration {
    /// Fail-closed entry point. Darwin calls this when a host launches the
    /// extension process; Linux has no such process.
    public static func main() throws {
        throw ExtensionKitHostError.extensionProcessUnavailable
    }
}
