import Foundation

/// Process-local identity of Apple's `DDErrorDomain` export. Whether Darwin's
/// loaded string is exactly this token or a reverse-DNS form is an oracle
/// question.
public let DDErrorDomain: String = "DDErrorDomain"

/// Bridged DeviceDiscoveryExtension error.
///
/// Raw values follow the pinned `dotnet/macios` `DDErrorCode` enumeration
/// (`Success = 0`, then `Unknown = 350000` … `Permission = 350006`). `next` is
/// the C auto-increment after `permission` (`350007`); macios did not bind
/// `Next` because it is a moving sentinel — recorded as an oracle question.
///
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// (`__HALT`) on this toolchain, so those two Hashable members are provided
/// here. Equality uses the bridged `NSError` (domain, code, and userInfo).
@frozen
public struct DDError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = DDError

        case success = 0
        case unknown = 350000
        case badParameter = 350001
        case unsupported = 350002
        case timeout = 350003
        case `internal` = 350004
        case missingEntitlement = 350005
        case permission = 350006
        case next = 350007
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { DDErrorDomain }

    public static var errorDomain: String { DDErrorDomain }

    public static var success: Code { .success }
    public static var unknown: Code { .unknown }
    public static var badParameter: Code { .badParameter }
    public static var unsupported: Code { .unsupported }
    public static var timeout: Code { .timeout }
    public static var `internal`: Code { .internal }
    public static var missingEntitlement: Code { .missingEntitlement }
    public static var permission: Code { .permission }
    public static var next: Code { .next }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension DDError.Code {
    public static func ~= (match: DDError.Code, error: any Error) -> Bool {
        if let typed = error as? DDError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == DDErrorDomain && nsError.code == match.rawValue
    }
}
