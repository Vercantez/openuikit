@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testPushTypeToken() {
    activityKitRequire(PushType.token == .token, "token identity")
}

func testPushTypeChannel() {
    activityKitRequire(PushType.channel("sports") == PushType.channel("sports"), "same channel")
    activityKitRequire(PushType.channel("a") != PushType.channel("b"), "different channels")
}

func testPushTypeEquality() {
    activityKitRequire(PushType.channel("sports") != .token, "channel vs token")
    activityKitRequire(PushType.token == PushType.token, "token equal")
}
