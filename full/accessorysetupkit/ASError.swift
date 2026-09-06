import Foundation

/// Bridged Accessory Setup Kit error.
///
/// Raw values are the `NS_ERROR_ENUM` integers recorded by the pinned
/// dotnet-macios `ASErrorCode` (`Success = 0` … `UserRestricted = 750`).
@frozen
public struct ASError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = ASError

        case success = 0
        case unknown = 1
        case activationFailed = 100
        case connectionFailed = 150
        case discoveryTimeout = 200
        case extensionNotFound = 300
        case invalidated = 400
        case invalidRequest = 450
        case pickerAlreadyActive = 500
        case pickerRestricted = 550
        case userCancelled = 700
        case userRestricted = 750
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { ASErrorDomain }

    public static var errorDomain: String { ASErrorDomain }

    public static var success: Code { .success }
    public static var unknown: Code { .unknown }
    public static var activationFailed: Code { .activationFailed }
    public static var connectionFailed: Code { .connectionFailed }
    public static var discoveryTimeout: Code { .discoveryTimeout }
    public static var extensionNotFound: Code { .extensionNotFound }
    public static var invalidated: Code { .invalidated }
    public static var invalidRequest: Code { .invalidRequest }
    public static var pickerAlreadyActive: Code { .pickerAlreadyActive }
    public static var pickerRestricted: Code { .pickerRestricted }
    public static var userCancelled: Code { .userCancelled }
    public static var userRestricted: Code { .userRestricted }

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

extension ASError.Code {
    public static func ~= (match: ASError.Code, error: any Error) -> Bool {
        if let typed = error as? ASError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ASErrorDomain && nsError.code == match.rawValue
    }
}
