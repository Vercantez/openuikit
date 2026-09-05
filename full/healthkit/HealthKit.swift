@_exported import Foundation

/// Linux HealthKit starting point. Isolated host compilation produces
/// `libHealthKit.dylib`. Persistence is a local on-disk store, not Apple Health.

public struct HKError: Error, Hashable, Sendable, CustomNSError {
    public var code: Code

    public init(_ code: Code) {
        self.code = code
    }

    public static var errorDomain: String { HKErrorDomain }
    public var errorCode: Int { code.rawValue }

    public static var unknownError: Code { .unknownError }
    public static var noError: Code { .noError }
    public static var errorHealthDataUnavailable: Code { .errorHealthDataUnavailable }
    public static var errorHealthDataRestricted: Code { .errorHealthDataRestricted }
    public static var errorInvalidArgument: Code { .errorInvalidArgument }
    public static var errorAuthorizationDenied: Code { .errorAuthorizationDenied }
    public static var errorAuthorizationNotDetermined: Code { .errorAuthorizationNotDetermined }
    public static var errorDatabaseInaccessible: Code { .errorDatabaseInaccessible }
    public static var errorUserCanceled: Code { .errorUserCanceled }
    public static var errorAnotherWorkoutSessionStarted: Code { .errorAnotherWorkoutSessionStarted }
    public static var errorUserExitedWorkoutSession: Code { .errorUserExitedWorkoutSession }
    public static var errorRequiredAuthorizationDenied: Code { .errorRequiredAuthorizationDenied }
    public static var errorNoData: Code { .errorNoData }
    public static var errorWorkoutActivityNotAllowed: Code { .errorWorkoutActivityNotAllowed }
    public static var errorDataSizeExceeded: Code { .errorDataSizeExceeded }
    public static var errorBackgroundWorkoutSessionNotAllowed: Code {
        .errorBackgroundWorkoutSessionNotAllowed
    }
    public static var errorNotPermissibleForGuestUserMode: Code {
        .errorNotPermissibleForGuestUserMode
    }

}

public func ~= (match: HKError.Code, error: any Error) -> Bool {
    let nsError = error as NSError
    return nsError.domain == HKErrorDomain && nsError.code == match.rawValue
}

func hkUnavailableError(
    _ code: HKError.Code = .errorHealthDataUnavailable,
    reason: String = "HealthKit is unavailable on this Linux host"
) -> NSError {
    NSError(
        domain: HKErrorDomain,
        code: code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: reason]
    )
}
