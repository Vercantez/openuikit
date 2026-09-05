@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityRequestContent() {
    activityKitReset()
    let activity = try! activityKitRequest("content")
    activityKitRequire(activity.attributes.label == "content", "created")
    activityKitRequire(type(of: activity) == Activity<ProbeAttributes>.self, "Activity type")
}

func testActivityRequestContentState() {
    activityKitReset()
    let state = ProbeAttributes.ContentState(message: "state-only", progress: 1)
    let activity = try! Activity.request(
        attributes: ProbeAttributes(label: "state-only"),
        contentState: state
    )
    activityKitRequire(activity.content.staleDate == nil, "contentState request")
    activityKitRequire(activity.contentState.message == "state-only", "state")
}

func testActivityRequestStyle() {
    activityKitReset()
    let activity = try! activityKitRequest("styled", style: .transient)
    activityKitRequire(activity.activityState == .active, "style request")
}

func testActivityRequestDenied() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setAreActivitiesEnabled(false)
    activityKitExpectError(.denied) {
        _ = try activityKitRequest("denied")
    }
}

func testActivityRequestUnsupported() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setDeviceSupportsActivities(false)
    activityKitExpectError(.unsupported) {
        _ = try activityKitRequest("unsupported")
    }
}

func testActivityRequestUnentitled() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setEntitled(false)
    activityKitExpectError(.unentitled) {
        _ = try activityKitRequest("unentitled")
    }
}

func testActivityRequestVisibility() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setBackgrounded(true)
    activityKitExpectError(.visibility) {
        _ = try activityKitRequest("bg")
    }
}

func testActivityRequestMalformedIdentifier() {
    activityKitReset()
    let content = activityKitContent("channel")
    activityKitExpectError(.malformedActivityIdentifier) {
        _ = try Activity.request(
            attributes: ProbeAttributes(label: "channel"),
            content: content,
            pushType: .channel("")
        )
    }
    activityKitExpectError(.malformedActivityIdentifier) {
        _ = try Activity.openUIKitHostRequest(
            attributes: ProbeAttributes(label: "bad-id"),
            content: content,
            id: ""
        )
    }
    activityKitExpectError(.malformedActivityIdentifier) {
        _ = try Activity.openUIKitHostRequest(
            attributes: ProbeAttributes(label: "slash"),
            content: content,
            id: "not/valid"
        )
    }
}

func testActivityRequestReconnectNotPermitted() {
    activityKitReset()
    let content = activityKitContent("dup")
    let first = try! Activity.openUIKitHostRequest(
        attributes: ProbeAttributes(label: "dup"),
        content: content,
        id: "stable-id"
    )
    activityKitExpectError(.reconnectNotPermitted) {
        _ = try Activity.openUIKitHostRequest(
            attributes: ProbeAttributes(label: "dup2"),
            content: content,
            id: "stable-id"
        )
    }
    activityKitRequire(first.id == "stable-id", "explicit id")
}

func testActivityRequestAttributesTooLarge() {
    activityKitReset()
    struct HugeAttributes: ActivityAttributes {
        struct ContentState: Codable, Hashable {
            var n: Int
        }
        var blob: String
    }
    activityKitExpectError(.attributesTooLarge) {
        _ = try Activity.request(
            attributes: HugeAttributes(blob: String(repeating: "A", count: 5000)),
            contentState: HugeAttributes.ContentState(n: 1)
        )
    }
}

func testActivityRequestEightCap() {
    activityKitReset()
    let start = Date(timeIntervalSince1970: 1_900_000_000)
    OpenUIKitActivityKitTesting.setNow(start)
    var started: [Activity<ProbeAttributes>] = []
    for index in 0..<8 {
        started.append(try! activityKitRequest("cap-\(index)"))
    }
    activityKitRequire(Activity<ProbeAttributes>.activities.count == 8, "cap full")
    activityKitExpectError(.targetMaximumExceeded) {
        _ = try activityKitRequest("ninth")
    }
    let first = started[0]
    activityKitRunAsync {
        await first.end(nil, dismissalPolicy: .immediate, timestamp: start)
    }
    activityKitRequire(first.activityState == .dismissed, "slot freed")
    let ninth = try! activityKitRequest("ninth")
    activityKitRequire(ninth.activityState == .active, "ninth after free")
}

func testActivityRequestInjectedGlobalMaximum() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setInjectedRequestError(.globalMaximumExceeded)
    activityKitExpectError(.globalMaximumExceeded) {
        _ = try activityKitRequest("global")
    }
}

func testActivityRequestInjectedUnsupportedTarget() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setInjectedRequestError(.unsupportedTarget)
    activityKitExpectError(.unsupportedTarget) {
        _ = try activityKitRequest("target")
    }
}

func testActivityRequestInjectedPersistenceFailure() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setInjectedRequestError(.persistenceFailure)
    activityKitExpectError(.persistenceFailure) {
        _ = try activityKitRequest("persist")
    }
}

func testActivityRequestInjectedMissingProcessIdentifier() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setInjectedRequestError(.missingProcessIdentifier)
    activityKitExpectError(.missingProcessIdentifier) {
        _ = try activityKitRequest("pid")
    }
}
