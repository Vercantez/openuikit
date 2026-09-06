import Foundation

// Linux starting point for Apple's CarKey (iPhoneOS 26.1 public Swift surface).
// Digital car-key hardware, the CarKey daemon, entitlements, Secure Enclave
// attestation, and vehicle radios are absent on this host. Value types, error
// cases, identifier/status wrappers, and fail-closed session/request state
// are implemented here. Apple-only success is never invented.

/// CarKey remote-control and keyless-entry failures.
///
/// The pinned symbol graph and API digester record a Swift enum with PascalCase
/// cases, `Error`/`Equatable`/`Hashable`/`Sendable` conformances, and no
/// `RawRepresentable` witnesses. Integer NSError codes are unobserved; this
/// port does not invent them.
public enum CarKeyErrorCode: Error, Equatable, Hashable, Sendable {
    case Internal
    case VehicleNotConnected
    case AnotherRequestInProgress
    case SessionNotActive
    case FunctionUnknown
    case SecurityViolation
    case VehicleNotFound
    case MessageTooLong
    case RequestTimedOut
    case EnduringRequestUsingEventMethod
    case RequestNotInProgress
    case ClientInBackground
    case FeatureNotSupported
}

/// Integer function identifier used by remote keyless-entry actions and reports.
public struct FunctionIdentifier: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = Int

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Integer action identifier used by remote keyless-entry actions.
public struct ActionIdentifier: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = Int

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Status of a vehicle function in a `VehicleReport`.
public struct FunctionStatus: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = Int

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Result of a remote keyless-entry execution request.
///
/// The public graph records `RawRepresentable` and `Sendable` only — not
/// `Equatable`/`Hashable`. Named status constants are unobserved.
public struct ExecutionStatus: RawRepresentable, Sendable {
    public typealias RawValue = Int

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}
