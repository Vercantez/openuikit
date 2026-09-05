@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityId() {
    activityKitReset()
    activityKitRequire(Activity<ProbeAttributes>.ID.self == String.self, "ID alias")
    let activity = try! Activity.openUIKitHostRequest(
        attributes: ProbeAttributes(label: "id"),
        content: activityKitContent(),
        id: "explicit-id"
    )
    activityKitRequire(activity.id == "explicit-id", "id")
}

func testActivityAttributesProperty() {
    activityKitReset()
    let activity = try! activityKitRequest("attrs")
    activityKitRequire(activity.attributes.label == "attrs", "attributes")
}

func testActivityContentProperty() {
    activityKitReset()
    let activity = try! activityKitRequest(
        "content-prop",
        content: activityKitContent("idle", relevanceScore: 1.5)
    )
    activityKitRequire(activity.content.relevanceScore == 1.5, "content")
}

func testActivityContentStateProperty() {
    activityKitReset()
    let activity = try! activityKitRequest(
        "state-prop",
        content: activityKitContent("idle", progress: 7)
    )
    activityKitRequire(activity.contentState.progress == 7, "contentState")
}

func testActivityActivityStateProperty() {
    activityKitReset()
    let activity = try! activityKitRequest("state")
    activityKitRequire(activity.activityState == .active, "activityState")
}

func testActivityPushToken() {
    activityKitReset()
    let activity = try! activityKitRequest("token", pushType: .token)
    activityKitRequire(activity.pushToken == nil, "no APNs token")
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    activityKitRequire(activity.pushToken == payload, "pushToken set")
}

func testActivityList() {
    activityKitReset()
    activityKitRequire(Activity<ProbeAttributes>.activities.isEmpty, "start empty")
    let activity = try! activityKitRequest("list")
    activityKitRequire(
        Activity<ProbeAttributes>.activities.map(\.id) == [activity.id],
        "list"
    )
}

func testActivityPushToStartToken() {
    activityKitReset()
    activityKitRequire(Activity<ProbeAttributes>.pushToStartToken == nil, "pushToStartToken")
}
