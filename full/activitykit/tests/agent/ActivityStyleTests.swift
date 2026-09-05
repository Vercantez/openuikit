@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityStyleCases() {
    let cases: [ActivityStyle] = [.standard, .transient]
    activityKitRequire(Set(cases).count == 2, "two styles")
}

func testActivityStyleHashable() {
    activityKitRequire(ActivityStyle.standard == .standard, "equal")
    activityKitRequire(ActivityStyle.standard != .transient, "unequal")
    var hasher = Hasher()
    ActivityStyle.standard.hash(into: &hasher)
    activityKitRequire(
        ActivityStyle.standard.hashValue == ActivityStyle.standard.hashValue,
        "hash"
    )
}
