import Foundation

/// Portable counterpart of MultipeerConnectivity's bridged `NS_ERROR_ENUM`.
///
/// Numeric codes follow the public `MCErrorCode` enumeration:
/// `unknown = 0` through `unavailable = 6`. The stored `userInfo` is preserved
/// exactly; this overlay does not insert a default localized-description entry.
public struct MCError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case notConnected = 1
        case invalidParameter = 2
        case unsupported = 3
        case timedOut = 4
        case cancelled = 5
        case unavailable = 6
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MCErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknown = Code.unknown
    public static let notConnected = Code.notConnected
    public static let invalidParameter = Code.invalidParameter
    public static let unsupported = Code.unsupported
    public static let timedOut = Code.timedOut
    public static let cancelled = Code.cancelled
    public static let unavailable = Code.unavailable

    public static func == (lhs: MCError, rhs: MCError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MCError.Code {
    /// Allow matching a MultipeerConnectivity error code against an arbitrary error.
    public static func ~= (match: MCError.Code, error: any Error) -> Bool {
        (error as? MCError)?.code == match
    }
}
