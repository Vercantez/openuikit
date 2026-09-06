import Foundation

/// Public Cinematic error domain. The pinned macios binding annotates the
/// enum with `[ErrorDomain ("CNCinematicErrorDomain")]`. Whether Darwin's
/// loaded `CNCinematicErrorDomain` string is exactly this token or a
/// reverse-DNS form is an oracle question.
public let CNCinematicErrorDomain: String = "CNCinematicErrorDomain"

/// Portable counterpart of Cinematic's bridged
/// `NS_ERROR_ENUM(CNCinematicErrorDomain, CNCinematicErrorCode)`.
///
/// Numeric codes follow the pinned `dotnet/macios` `CNCinematicErrorCode`
/// enumeration: `unknown = 1` through `cancelled = 7`. Stored `userInfo` is
/// preserved exactly; this overlay does not insert a default localized
/// description.
public struct CNCinematicError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 1
        case unreadable = 2
        case incomplete = 3
        case malformed = 4
        case unsupported = 5
        case incompatible = 6
        case cancelled = 7
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CNCinematicErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var unreadable: Code { .unreadable }
    public static var incomplete: Code { .incomplete }
    public static var malformed: Code { .malformed }
    public static var unsupported: Code { .unsupported }
    public static var incompatible: Code { .incompatible }
    public static var cancelled: Code { .cancelled }

    public static func == (lhs: CNCinematicError, rhs: CNCinematicError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CNCinematicError.Code {
    /// Allow matching a Cinematic error code against an arbitrary error.
    public static func ~= (match: CNCinematicError.Code, error: any Error) -> Bool {
        (error as? CNCinematicError)?.code == match
    }
}
