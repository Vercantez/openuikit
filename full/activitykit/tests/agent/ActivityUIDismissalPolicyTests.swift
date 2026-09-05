@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityUIDismissalPolicyDefault() {
    let policy = ActivityUIDismissalPolicy.default
    activityKitRequire(policy == .default, "default identity")
}

func testActivityUIDismissalPolicyImmediate() {
    let policy = ActivityUIDismissalPolicy.immediate
    activityKitRequire(policy == .immediate, "immediate identity")
}

func testActivityUIDismissalPolicyAfter() {
    let date = Date(timeIntervalSince1970: 0)
    let policy = ActivityUIDismissalPolicy.after(date)
    activityKitRequire(policy == ActivityUIDismissalPolicy.after(date), "after identity")
}

func testActivityUIDismissalPolicyEquality() {
    activityKitRequire(
        ActivityUIDismissalPolicy.default != ActivityUIDismissalPolicy.immediate,
        "default != immediate"
    )
    activityKitRequire(
        ActivityUIDismissalPolicy.after(Date(timeIntervalSince1970: 0))
            != ActivityUIDismissalPolicy.default,
        "after != default"
    )
    activityKitRequire(
        ActivityUIDismissalPolicy.default == ActivityUIDismissalPolicy.default,
        "equal"
    )
}
