import Foundation

/// Linux starting point for Apple's public `SensorKit` module.
///
/// Hardware streams, Research app entitlements, and SensorKit daemons are
/// absent. Authorization stays denied and reader operations fail closed with
/// `SRError` rather than fabricating samples.

/// ARKit is not part of this isolated Foundation-only Linux module.
public var SR_ARKIT_SUPPORTED: Int32 { 0 }

/// Exact domain spelling from the pinned Xcode 26.1 `SRErrorDomain` constant.
public let SRErrorDomain: String = "SRErrorDomain"

public struct SRError: Error, Hashable, CustomNSError {
    public enum Code: Int, Hashable, Sendable {
        case invalidEntitlement = 0
        case noAuthorization = 1
        case dataInaccessible = 2
        case fetchRequestInvalid = 3
        case promptDeclined = 4
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }

    public static var errorDomain: String { SRErrorDomain }

    public var errorUserInfo: [String: Any] { userInfo }

    public var hashValue: Int { code.rawValue }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public static func == (lhs: SRError, rhs: SRError) -> Bool {
        lhs.code == rhs.code
    }

    public static var invalidEntitlement: Code { .invalidEntitlement }
    public static var noAuthorization: Code { .noAuthorization }
    public static var dataInaccessible: Code { .dataInaccessible }
    public static var fetchRequestInvalid: Code { .fetchRequestInvalid }
    public static var promptDeclined: Code { .promptDeclined }
}

extension SRError.Code {
    public static func ~= (match: SRError.Code, error: any Error) -> Bool {
        if let typed = error as? SRError {
            return typed.code == match
        }
        let ns = error as NSError
        return ns.domain == SRErrorDomain && ns.code == match.rawValue
    }
}

func srMakeError(_ code: SRError.Code) -> SRError {
    SRError(code, userInfo: [NSLocalizedDescriptionKey: "SensorKit Linux fail-closed: \(code)"])
}
