@_exported import Foundation
import Dispatch

/// Serial queue that delivers `requestTrackingAuthorization` completions.
///
/// The label is the documented Linux delivery target. Completions never run
/// inline on the caller and never require the main run loop.
private enum TrackingAuthorizationDelivery {
    static let queue = DispatchQueue(
        label: "org.openuikit.AppTrackingTransparency.authorization-status",
        qos: .userInitiated
    )

    static func schedule(
        status: ATTrackingManager.AuthorizationStatus,
        completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void
    ) {
        let once = TrackingAuthorizationOnce(completion)
        queue.async {
            once.deliver(status)
        }
    }
}

/// Guarantees the caller-supplied handler runs at most once.
private final class TrackingAuthorizationOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var completion: ((ATTrackingManager.AuthorizationStatus) -> Void)?

    init(_ completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void) {
        self.completion = completion
    }

    func deliver(_ status: ATTrackingManager.AuthorizationStatus) {
        lock.lock()
        let pending = completion
        completion = nil
        lock.unlock()
        pending?(status)
    }
}

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

    /// Schedules `completion` once with the current fail-closed status.
    ///
    /// There is no system prompt. The handler is delivered asynchronously on
    /// `org.openuikit.AppTrackingTransparency.authorization-status` and is
    /// never invoked inline. This does not claim Apple queue identity.
    open class func requestTrackingAuthorization(
        completionHandler completion: @escaping (AuthorizationStatus) -> Void
    ) {
        TrackingAuthorizationDelivery.schedule(
            status: trackingAuthorizationStatus,
            completion: completion
        )
    }

    /// Async overlay of the same precise request identifier. Awaits the
    /// completion-handler path so delivery, fail-closed status, and
    /// exactly-once semantics stay on one implementation.
    open class func requestTrackingAuthorization() async -> AuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
