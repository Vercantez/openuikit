import Foundation

/// Apple's public ClassKit error domain string (`CLSErrorCodeDomain`).
public let CLSErrorCodeDomain = "CLSErrorCodeDomain"

/// Portable counterpart of ClassKit's bridged `NS_ERROR_ENUM(CLSErrorCodeDomain)`.
///
/// Numeric codes follow the public Xcode 26.1 / pinned macios `CLSErrorCode`
/// order (`none = 0` through `invalidAccountCredentials = 10`). Stored
/// `userInfo` is preserved exactly; this overlay does not insert a default
/// localized-description entry.
public struct CLSError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case none = 0
        case classKitUnavailable = 1
        case invalidArgument = 2
        case invalidModification = 3
        case authorizationDenied = 4
        case databaseInaccessible = 5
        case limits = 6
        case invalidCreate = 7
        case invalidUpdate = 8
        case partialFailure = 9
        case invalidAccountCredentials = 10
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CLSErrorCodeDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public var localizedDescription: String {
        "The operation couldn’t be completed. (\(CLSErrorCodeDomain) error \(errorCode).)"
    }

    public static var none: Code { .none }
    public static var classKitUnavailable: Code { .classKitUnavailable }
    public static var invalidArgument: Code { .invalidArgument }
    public static var invalidModification: Code { .invalidModification }
    public static var authorizationDenied: Code { .authorizationDenied }
    public static var databaseInaccessible: Code { .databaseInaccessible }
    public static var limits: Code { .limits }
    public static var invalidCreate: Code { .invalidCreate }
    public static var invalidUpdate: Code { .invalidUpdate }
    public static var partialFailure: Code { .partialFailure }
    public static var invalidAccountCredentials: Code { .invalidAccountCredentials }

    public static func == (lhs: CLSError, rhs: CLSError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CLSError.Code {
    public static func ~= (match: CLSError.Code, error: any Error) -> Bool {
        (error as? CLSError)?.code == match
    }
}

func CLSMakeError(_ code: CLSError.Code, userInfo: [String: Any] = [:]) -> CLSError {
    CLSError(code, userInfo: userInfo)
}
