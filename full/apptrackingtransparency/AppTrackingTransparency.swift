@_exported import Foundation

/// Portable `AppTrackingTransparency` surface reconstructed from the Xcode 26.1
/// iPhoneOS public Swift graph.
///
/// Linux has no App Tracking Transparency system prompt, no advertising
/// identifier, and no user-consent UI. Tracking is never authorized. The
/// manager reports `.denied` and both request overloads complete with that
/// same fail-closed status. Returning `.authorized` would fabricate privacy
/// consent.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
open class ATTrackingManager: NSObject {
    /// Authorization states from Apple's public `NS_ENUM` overlay.
    ///
    /// Raw values follow the documented order: `notDetermined = 0`,
    /// `restricted = 1`, `denied = 2`, `authorized = 3`.
    public enum AuthorizationStatus: UInt, Sendable, Equatable, Hashable {
        case notDetermined = 0
        case restricted = 1
        case denied = 2
        case authorized = 3
    }

    /// Linux cannot grant tracking consent, so this is always `.denied`.
    /// It is never `.notDetermined` (that would imply a prompt is still
    /// pending) and never `.authorized`.
    open class var trackingAuthorizationStatus: AuthorizationStatus {
        .denied
    }

    /// Invokes `completion` once with the current fail-closed status.
    ///
    /// There is no system prompt. The handler runs on the caller queue so a
    /// Linux guest cannot hang waiting for UI that does not exist. This does
    /// not claim Apple queue identity.
    open class func requestTrackingAuthorization(
        completionHandler completion: @escaping (AuthorizationStatus) -> Void
    ) {
        completion(trackingAuthorizationStatus)
    }

    /// Async overlay of the same precise request identifier. Returns the
    /// fail-closed status without presenting UI.
    open class func requestTrackingAuthorization() async -> AuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
