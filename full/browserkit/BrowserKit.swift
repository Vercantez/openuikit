@_exported import Foundation

/// Linux-local fail-closed error for BrowserKit eligibility queries.
///
/// Apple's BrowserKit `NSError` domain and integer codes are not in the
/// pinned Xcode 26.1 graph, API digester, TBD, or macios checkout. This
/// discriminator is not a Darwin code and must not be treated as one.
public enum BrowserKitHostError: Error, Equatable, Hashable, Sendable {
    /// No Apple region, entitlement, or process-eligibility service is
    /// present. The lookup did not succeed.
    case eligibilityUnavailable
}

extension BrowserKitHostError: CustomNSError {
    public static var errorDomain: String { "BrowserKit.Linux" }

    public var errorCode: Int {
        switch self {
        case .eligibilityUnavailable:
            return 1
        }
    }
}

/// Linux starting point for Apple's public `BEAvailability` type.
///
/// Darwin asks a region / entitlement / process service whether this
/// installation may use an alternative browser engine. Linux has no such
/// daemon, so every lookup fails closed. Constructing an instance does not
/// confer eligibility.
open class BEAvailability: NSObject {
    /// Context for an eligibility query. Nested name and `Int` raw type
    /// match the imported `NS_ENUM(NSInteger, BEEligibilityContext)` with
    /// `NS_SWIFT_NAME(BEAvailability.Context)`.
    ///
    /// Xcode 26.1 publishes a single case, `webBrowser`. The first
    /// `NS_ENUM` enumerator without an explicit payload is `0`.
    public enum Context: Int, Sendable, Hashable {
        /// Alternative browser engines in a web-browser app.
        case webBrowser = 0
    }

    private static let unavailable = BrowserKitHostError.eligibilityUnavailable

    /// Fail-closed completion-handler overlay of
    /// `isEligibleForContext:completionHandler:`.
    ///
    /// Linux invokes `completionHandler` exactly once, on the calling
    /// thread, before this method returns. The Boolean is `false` and the
    /// error is `BrowserKitHostError.eligibilityUnavailable`. This never
    /// reports a successful eligibility determination.
    open class func isEligible(
        for context: Context,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = context
        completionHandler(false, unavailable)
    }

    /// Fail-closed async overlay (`NS_SWIFT_ASYNC_NAME(isEligible(for:))`).
    /// Always throws `BrowserKitHostError.eligibilityUnavailable`.
    open class func isEligible(for context: Context) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            isEligible(for: context) { _, error in
                continuation.resume(throwing: error ?? unavailable)
            }
        }
    }
}
