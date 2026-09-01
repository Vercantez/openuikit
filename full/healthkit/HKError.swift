import Foundation

/// Bridged `NS_ERROR_ENUM` overlay for `HKErrorDomain`.
///
/// Numeric codes follow the public `HKErrorCode` enumeration from the
/// iPhoneOS 26.1 headers: `unknownError`/`noError` = 0 through
/// `errorNotPermissibleForGuestUserMode` = 15.
public struct HKError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = 0
        case errorHealthDataUnavailable = 1
        case errorHealthDataRestricted = 2
        case errorInvalidArgument = 3
        case errorAuthorizationDenied = 4
        case errorAuthorizationNotDetermined = 5
        case errorDatabaseInaccessible = 6
        case errorUserCanceled = 7
        case errorAnotherWorkoutSessionStarted = 8
        case errorUserExitedWorkoutSession = 9
        case errorRequiredAuthorizationDenied = 10
        case errorNoData = 11
        case errorWorkoutActivityNotAllowed = 12
        case errorDataSizeExceeded = 13
        case errorBackgroundWorkoutSessionNotAllowed = 14
        case errorNotPermissibleForGuestUserMode = 15

        public static var noError: HKError.Code { .unknownError }
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { HKErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknownError = Code.unknownError
    public static let noError = Code.noError
    public static let errorHealthDataUnavailable = Code.errorHealthDataUnavailable
    public static let errorHealthDataRestricted = Code.errorHealthDataRestricted
    public static let errorInvalidArgument = Code.errorInvalidArgument
    public static let errorAuthorizationDenied = Code.errorAuthorizationDenied
    public static let errorAuthorizationNotDetermined = Code.errorAuthorizationNotDetermined
    public static let errorDatabaseInaccessible = Code.errorDatabaseInaccessible
    public static let errorUserCanceled = Code.errorUserCanceled
    public static let errorAnotherWorkoutSessionStarted = Code.errorAnotherWorkoutSessionStarted
    public static let errorUserExitedWorkoutSession = Code.errorUserExitedWorkoutSession
    public static let errorRequiredAuthorizationDenied = Code.errorRequiredAuthorizationDenied
    public static let errorNoData = Code.errorNoData
    public static let errorWorkoutActivityNotAllowed = Code.errorWorkoutActivityNotAllowed
    public static let errorDataSizeExceeded = Code.errorDataSizeExceeded
    public static let errorBackgroundWorkoutSessionNotAllowed = Code.errorBackgroundWorkoutSessionNotAllowed
    public static let errorNotPermissibleForGuestUserMode = Code.errorNotPermissibleForGuestUserMode

    public static func == (lhs: HKError, rhs: HKError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension HKError.Code {
    public static func ~= (match: HKError.Code, error: any Error) -> Bool {
        (error as? HKError)?.code == match
    }
}

func hkUnavailableError(_ message: String = "Health data is unavailable on this platform.") -> HKError {
    HKError(.errorHealthDataUnavailable, userInfo: [NSLocalizedDescriptionKey: message])
}

func hkInvalidArgument(_ message: String) -> HKError {
    HKError(.errorInvalidArgument, userInfo: [NSLocalizedDescriptionKey: message])
}
