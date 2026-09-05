@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityUpdateContent() {
    activityKitReset()
    let activity = try! activityKitRequest("update", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        await activity.update(
            ActivityContent(
                state: ProbeAttributes.ContentState(message: "running", progress: 40),
                staleDate: nil,
                relevanceScore: 2
            )
        )
    }
    activityKitRequire(activity.contentState.progress == 40, "updated")
    activityKitRequire(activity.content.relevanceScore == 2, "score")
}

func testActivityUpdateUsing() {
    activityKitReset()
    let activity = try! activityKitRequest("using")
    activityKitRunAsync {
        await activity.update(using: ProbeAttributes.ContentState(message: "using", progress: 41))
    }
    activityKitRequire(activity.contentState.message == "using", "update(using:)")
}

func testActivityEndImmediate() {
    activityKitReset()
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    OpenUIKitActivityKitTesting.setNow(start)
    let activity = try! activityKitRequest("immediate")
    activityKitRunAsync {
        await activity.end(nil, dismissalPolicy: .immediate, timestamp: start)
    }
    activityKitRequire(activity.activityState == .dismissed, "immediate dismiss")
}

func testActivityEndDefaultFourHours() {
    activityKitReset()
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    OpenUIKitActivityKitTesting.setNow(start)
    let activity = try! activityKitRequest("default")
    let endAt = start.addingTimeInterval(60)
    OpenUIKitActivityKitTesting.setNow(endAt)
    activityKitRunAsync {
        await activity.end(
            ActivityContent(
                state: ProbeAttributes.ContentState(message: "final", progress: 100),
                staleDate: nil,
                relevanceScore: 0
            ),
            dismissalPolicy: .default
        )
    }
    activityKitRequire(activity.activityState == .ended, "default still ended")
    activityKitRequire(activity.contentState.message == "final", "final content")
    OpenUIKitActivityKitTesting.setNow(endAt.addingTimeInterval(4 * 60 * 60 - 1))
    activityKitRequire(activity.activityState == .ended, "before 4h")
    OpenUIKitActivityKitTesting.setNow(endAt.addingTimeInterval(4 * 60 * 60))
    activityKitRequire(activity.activityState == .dismissed, "default 4h")
}

func testActivityEndUsingAfterDate() {
    activityKitReset()
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    OpenUIKitActivityKitTesting.setNow(start)
    let activity = try! activityKitRequest("after")
    let afterDate = start.addingTimeInterval(120)
    activityKitRunAsync {
        await activity.end(using: nil, dismissalPolicy: .after(afterDate))
    }
    activityKitRequire(activity.activityState == .ended, "after pending")
    OpenUIKitActivityKitTesting.setNow(afterDate)
    activityKitRequire(activity.activityState == .dismissed, "after date")
}

func testActivityStaleDate() {
    activityKitReset()
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    OpenUIKitActivityKitTesting.setNow(start)
    let activity = try! activityKitRequest(
        "stale",
        content: activityKitContent("go", progress: 1, staleDate: start.addingTimeInterval(30))
    )
    activityKitRequire(activity.activityState == .active, "not yet stale")
    OpenUIKitActivityKitTesting.setNow(start.addingTimeInterval(30))
    activityKitRequire(activity.activityState == .stale, "staleDate")
}

func testActivityEightHourAutoEnd() {
    activityKitReset()
    let born = Date(timeIntervalSince1970: 1_800_000_240)
    OpenUIKitActivityKitTesting.setNow(born)
    let activity = try! activityKitRequest("auto")
    OpenUIKitActivityKitTesting.setNow(born.addingTimeInterval(8 * 60 * 60))
    activityKitRequire(activity.activityState == .ended, "8h auto-end")
    OpenUIKitActivityKitTesting.setNow(born.addingTimeInterval(12 * 60 * 60))
    activityKitRequire(activity.activityState == .dismissed, "8h + 4h dismiss")
}
