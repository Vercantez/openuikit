import Foundation
@_exported import Combine

/// Policies accepted by the portable local-authentication boundary.
public enum LAPolicy: Int, Sendable {
    case deviceOwnerAuthenticationWithBiometrics = 1
    case deviceOwnerAuthentication = 2
}

public enum LABiometryType: Int, Sendable {
    case none = 0
    case touchID = 1
    case faceID = 2
    case opticID = 4
}

/// A source-compatible, typed failure for a host that has no enrolled device
/// owner or Secure Enclave authentication service.
public struct LAError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Code: Int, Sendable {
        case authenticationFailed = -1
        case userCancel = -2
        case userFallback = -3
        case systemCancel = -4
        case passcodeNotSet = -5
        case biometryNotAvailable = -6
        case biometryNotEnrolled = -7
        case biometryLockout = -8
        case appCancel = -9
        case invalidContext = -10
        case notInteractive = -1004
    }

    public let code: Code
    public let reason: String

    public init(_ code: Code, reason: String? = nil) {
        self.code = code
        self.reason = reason ?? "Local authentication is unavailable on this host"
    }

    public var description: String { reason }

    public static let authenticationFailed = Code.authenticationFailed
    public static let userCancel = Code.userCancel
    public static let userFallback = Code.userFallback
    public static let systemCancel = Code.systemCancel
    public static let passcodeNotSet = Code.passcodeNotSet
    public static let biometryNotAvailable = Code.biometryNotAvailable
    public static let biometryNotEnrolled = Code.biometryNotEnrolled
    public static let biometryLockout = Code.biometryLockout
    public static let appCancel = Code.appCancel
    public static let invalidContext = Code.invalidContext
    public static let notInteractive = Code.notInteractive
}

/// Linux has no device-owner authentication broker. The context is still a
/// real mutable request object, but every capability query and evaluation
/// fails closed with `biometryNotAvailable`.
open class LAContext {
    public init() {}

    open var localizedReason = ""
    open var localizedCancelTitle: String?
    open var localizedFallbackTitle: String?
    open var interactionNotAllowed = false
    open private(set) var biometryType: LABiometryType = .none

    private var invalidated = false

    open func canEvaluatePolicy(
        _ policy: LAPolicy,
        error: UnsafeMutablePointer<LAError?>?
    ) -> Bool {
        error?.pointee = LAError(
            invalidated ? .invalidContext : .biometryNotAvailable
        )
        return false
    }

    open func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        self.localizedReason = localizedReason
        reply(
            false,
            LAError(invalidated ? .invalidContext : .biometryNotAvailable)
        )
    }

    open func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async throws -> Bool {
        self.localizedReason = localizedReason
        throw LAError(invalidated ? .invalidContext : .biometryNotAvailable)
    }

    open func invalidate() {
        invalidated = true
    }
}
