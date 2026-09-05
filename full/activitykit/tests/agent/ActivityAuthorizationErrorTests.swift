@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityAuthorizationErrorCases() {
    let cases: [ActivityAuthorizationError] = [
        .attributesTooLarge,
        .unsupported,
        .denied,
        .globalMaximumExceeded,
        .targetMaximumExceeded,
        .unsupportedTarget,
        .visibility,
        .persistenceFailure,
        .missingProcessIdentifier,
        .unentitled,
        .malformedActivityIdentifier,
        .reconnectNotPermitted,
    ]
    activityKitRequire(Set(cases).count == 12, "12 distinct error cases")
    activityKitRequire(cases.count == 12, "table width")
}

func testActivityAuthorizationErrorEquality() {
    activityKitRequire(
        ActivityAuthorizationError.denied == ActivityAuthorizationError.denied,
        "equal"
    )
    activityKitRequire(
        ActivityAuthorizationError.denied != ActivityAuthorizationError.unsupported,
        "unequal"
    )
    activityKitRequire(
        ActivityAuthorizationError.unentitled != ActivityAuthorizationError.unsupportedTarget,
        "entitlement cases"
    )
    var hasher = Hasher()
    ActivityAuthorizationError.denied.hash(into: &hasher)
    activityKitRequire(
        ActivityAuthorizationError.denied.hashValue == ActivityAuthorizationError.denied.hashValue,
        "hashValue"
    )
}

func testActivityAuthorizationErrorErrorCode() {
    let expected: [(ActivityAuthorizationError, Int)] = [
        (.attributesTooLarge, 0),
        (.unsupported, 1),
        (.denied, 2),
        (.globalMaximumExceeded, 3),
        (.targetMaximumExceeded, 4),
        (.unsupportedTarget, 5),
        (.visibility, 6),
        (.persistenceFailure, 7),
        (.missingProcessIdentifier, 8),
        (.unentitled, 9),
        (.malformedActivityIdentifier, 10),
        (.reconnectNotPermitted, 11),
    ]
    for (error, code) in expected {
        activityKitRequire(error.errorCode == code, "code \(code)")
    }
}

func testActivityAuthorizationErrorFailureReason() {
    activityKitRequire(
        ActivityAuthorizationError.attributesTooLarge.failureReason
            == "The provided Live Activity attributes exceeded the maximum size of 4KB.",
        "too large"
    )
    activityKitRequire(
        ActivityAuthorizationError.targetMaximumExceeded.failureReason
            == "The app has already started the maximum number of concurrent Live Activities.",
        "cap"
    )
    activityKitRequire(
        ActivityAuthorizationError.denied.failureReason
            == "A person deactivated Live Activities in Settings.",
        "denied"
    )
}

func testActivityAuthorizationErrorNSErrorSurface() {
    activityKitRequire(
        ActivityAuthorizationError.errorDomain == "ActivityKit.ActivityAuthorizationError",
        "domain"
    )
    let error = ActivityAuthorizationError.unsupported
    activityKitRequire(error.errorUserInfo.isEmpty, "userInfo")
    activityKitRequire(error.helpAnchor == nil, "helpAnchor")
    activityKitRequire(error.errorDescription == error.failureReason, "errorDescription")
    activityKitRequire(error.recoverySuggestion == nil, "recovery")
    activityKitRequire(!error.localizedDescription.isEmpty, "localized")
}
