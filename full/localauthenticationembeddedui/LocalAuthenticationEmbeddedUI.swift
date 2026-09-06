@_exported import Foundation

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Linux starting point for Apple's public `LocalAuthenticationEmbeddedUI` module.
///
/// The pinned Xcode 26.1 iPhoneOS graph publishes two public identifiers:
/// `LAPresentationContext` (`UIWindow`) and the `LARight` presentation-context
/// authorize method. Isolated host compilation has Foundation only; UIKit and
/// LocalAuthentication types use the lookalikes in
/// `LocalAuthenticationEmbeddedUILookalikes.swift` until those modules are on
/// the link line.
///
/// Linux has no LocalAuthentication UI sheet, Secure Enclave, or entitlement
/// prompt. `authorize(localizedReason:in:)` never succeeds.

/// Apple `kLAErrorNotInteractive` (`LAPublicDefines.h`). Authentication would
/// require showing UI that this host cannot present.
private let kLAErrorNotInteractive = -1004

/// Apple `LAErrorDomain` / `kLAErrorDomain`.
private let linuxLAErrorDomain = "com.apple.LocalAuthentication"

/// Linux fail-closed result for presentation-context authorization.
///
/// Apple's completion delivers an `LAError`. This module-owned error bridges
/// to the same domain and `kLAErrorNotInteractive` (-1004). It is not a claim
/// that Darwin uses this Swift type.
public struct LocalAuthenticationEmbeddedUIPresentationError: Error, Equatable, Sendable {
    public static let notInteractive = LocalAuthenticationEmbeddedUIPresentationError()

    public init() {}
}

extension LocalAuthenticationEmbeddedUIPresentationError: CustomNSError {
    public static var errorDomain: String { linuxLAErrorDomain }

    public var errorCode: Int { kLAErrorNotInteractive }

    public var errorUserInfo: [String: Any] {
        [
            NSLocalizedDescriptionKey:
                "Linux cannot present LocalAuthentication authorization UI"
        ]
    }
}

/// Presentation context for `LARight` authorization UI.
///
/// Apple: `LAPresentationContext.h` / symbol graph — `typedef UIWindow *LAPresentationContext`.
/// macios corroborates `using LAPresentationContext = UIKit.UIWindow` on iOS.
public typealias LAPresentationContext = UIWindow

/// Host inspection for fail-closed authorize. Hidden from ordinary
/// `import LocalAuthenticationEmbeddedUI` clients and not part of Apple's
/// public surface.
@_spi(OpenUIKitHost)
public enum LocalAuthenticationEmbeddedUIHostControl {
    private final class Box: @unchecked Sendable {
        let lock = NSLock()
        var localizedReason: String?
        weak var presentationContext: LAPresentationContext?
        var attempts = 0
    }

    private static let box = Box()

    public static func reset() {
        box.lock.lock()
        box.localizedReason = nil
        box.presentationContext = nil
        box.attempts = 0
        box.lock.unlock()
    }

    public static func lastLocalizedReason() -> String? {
        box.lock.lock()
        defer { box.lock.unlock() }
        return box.localizedReason
    }

    public static func lastPresentationContext() -> LAPresentationContext? {
        box.lock.lock()
        defer { box.lock.unlock() }
        return box.presentationContext
    }

    public static func authorizationAttempts() -> Int {
        box.lock.lock()
        defer { box.lock.unlock() }
        return box.attempts
    }

    static func record(
        localizedReason: String,
        presentationContext: LAPresentationContext
    ) {
        box.lock.lock()
        box.localizedReason = localizedReason
        box.presentationContext = presentationContext
        box.attempts += 1
        box.lock.unlock()
    }
}

extension LARight {
    /// Authorizes the right by presenting UI in `presentationContext`.
    ///
    /// Apple overlay of
    /// `authorizeWithLocalizedReason:inPresentationContext:completion:`.
    /// Linux never presents a sheet and never reports success.
    public func authorize(
        localizedReason: String,
        in presentationContext: LAPresentationContext
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            authorize(
                localizedReason: localizedReason,
                in: presentationContext
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Completion-handler form of the same ObjC selector
    /// `authorizeWithLocalizedReason:inPresentationContext:completion:`.
    ///
    /// The completion runs on the calling thread before this method returns.
    /// Apple's queue is unobserved (see `oracle-questions.tsv`). Linux does
    /// not hop onto a private queue: the isolated host runner has no run loop.
    public func authorize(
        localizedReason: String,
        in presentationContext: LAPresentationContext,
        completion handler: @escaping ((any Error)?) -> Void
    ) {
        linuxMarkAuthorizing()
        LocalAuthenticationEmbeddedUIHostControl.record(
            localizedReason: localizedReason,
            presentationContext: presentationContext
        )
        linuxMarkNotAuthorized()
        handler(LocalAuthenticationEmbeddedUIPresentationError.notInteractive)
    }

    private func linuxMarkAuthorizing() {
        #if !canImport(LocalAuthentication)
        state = .authorizing
        #endif
    }

    private func linuxMarkNotAuthorized() {
        #if !canImport(LocalAuthentication)
        state = .notAuthorized
        #endif
    }
}
