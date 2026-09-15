@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityUpdatesNextIsolation() {
    activityKitReset()
    let created = try! activityKitRequest("ni-updates")
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.activityUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first?.id == created.id, "next(isolation:) replay")
    }
}

func testActivityStateUpdatesNextIsolation() {
    activityKitReset()
    let activity = try! activityKitRequest("ni-state")
    activityKitRunAsync {
        let sequence = activity.activityStateUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first == .active, "next(isolation:) state replay")
    }
}

func testContentUpdatesNextIsolation() {
    activityKitReset()
    let activity = try! activityKitRequest("ni-content", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        let sequence = activity.contentUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first?.state.progress == 0, "next(isolation:) content replay")
    }
}

func testContentStateUpdatesNextIsolation() {
    activityKitReset()
    let activity = try! activityKitRequest(
        "ni-cstate",
        content: activityKitContent("idle", progress: 0)
    )
    activityKitRunAsync {
        let sequence = activity.contentStateUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first?.message == "idle", "next(isolation:) contentState replay")
    }
}

func testPushTokenUpdatesNextIsolation() {
    activityKitReset()
    let activity = try! activityKitRequest("ni-token", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    activityKitRunAsync {
        let sequence = activity.pushTokenUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first == payload, "next(isolation:) pushToken replay")
    }
}

func testActivityEnablementUpdatesNextIsolation() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRunAsync {
        let sequence = info.activityEnablementUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first == true, "next(isolation:) enablement replay")
    }
}

func testFrequentPushEnablementUpdatesNextIsolation() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRunAsync {
        let sequence = info.frequentPushEnablementUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        activityKitRequire(first == false, "next(isolation:) frequent push replay")
    }
}
