import Foundation

/// Public SafetyKit error domain. The pinned macios binding annotates the
/// enum with `[ErrorDomain ("SAErrorDomain")]`. Whether Darwin's loaded
/// `SAErrorDomain` string is exactly this token or a reverse-DNS form is an
/// oracle question.
public let SAErrorDomain: String = "SAErrorDomain"

/// Portable counterpart of SafetyKit's bridged `NS_ERROR_ENUM(SAErrorDomain, SAErrorCode)`.
///
/// Numeric codes follow the pinned `dotnet/macios` `SAErrorCode` enumeration:
/// `notAuthorized = 1` through `operationFailed = 4`. The stored `userInfo` is
/// preserved exactly; this overlay does not insert a default localized-description
/// entry.
public struct SAError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case notAuthorized = 1
        case notAllowed = 2
        case invalidArgument = 3
        case operationFailed = 4
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { SAErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var notAuthorized: Code { .notAuthorized }
    public static var notAllowed: Code { .notAllowed }
    public static var invalidArgument: Code { .invalidArgument }
    public static var operationFailed: Code { .operationFailed }

    public static func == (lhs: SAError, rhs: SAError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension SAError.Code {
    /// Allow matching a SafetyKit error code against an arbitrary error.
    public static func ~= (match: SAError.Code, error: any Error) -> Bool {
        (error as? SAError)?.code == match
    }
}