import Foundation

/// Bridged `NS_ERROR_ENUM` for Video Subscriber Account failures.
///
/// `Code` raw values match pinned `dotnet/macios` `[Native]`:
/// `accessNotGranted = 0` through `unsupported = 7`.
public struct VSError: Error, Hashable {
    public enum Code: Int, Hashable, Sendable {
        case accessNotGranted = 0
        case unsupportedProvider = 1
        case userCancelled = 2
        case serviceTemporarilyUnavailable = 3
        case providerRejected = 4
        case invalidVerificationToken = 5
        case rejected = 6
        case unsupported = 7

        public static func ~= (match: VSError.Code, error: any Error) -> Bool {
            (error as? VSError)?.code == match
        }
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }

    public var errorUserInfo: [String: Any] { userInfo }

    public static var errorDomain: String { VSErrorDomain }

    public var localizedDescription: String {
        if let description = userInfo[NSLocalizedDescriptionKey] as? String {
            return description
        }
        return "VSError.\(code) (\(code.rawValue))"
    }

    public static var accessNotGranted: Code { .accessNotGranted }
    public static var unsupportedProvider: Code { .unsupportedProvider }
    public static var userCancelled: Code { .userCancelled }
    public static var serviceTemporarilyUnavailable: Code { .serviceTemporarilyUnavailable }
    public static var providerRejected: Code { .providerRejected }
    public static var invalidVerificationToken: Code { .invalidVerificationToken }
    public static var rejected: Code { .rejected }
    public static var unsupported: Code { .unsupported }

    public static func == (lhs: VSError, rhs: VSError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension VSError: CustomNSError {}
