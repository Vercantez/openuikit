@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityUpdatesIteration() {
    activityKitReset()
    let created = try! activityKitRequest("updates")
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.activityUpdates
        let iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first?.id == created.id, "activityUpdates replay")
        activityKitRequire(
            Activity<ProbeAttributes>.ActivityUpdates.Element.self
                == Activity<ProbeAttributes>.self,
            "Element"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ActivityUpdates.AsyncIterator.self
                == Activity<ProbeAttributes>.ActivityUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ActivityUpdates.Iterator.Element.self
                == Activity<ProbeAttributes>.self,
            "Iterator.Element"
        )
    }
}

func testActivityStateUpdatesIteration() {
    activityKitReset()
    let activity = try! activityKitRequest("state-seq")
    activityKitRunAsync {
        let sequence = activity.activityStateUpdates
        let iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first == .active, "state replay")
        activityKitRequire(
            Activity<ProbeAttributes>.ActivityStateUpdates.Element.self == ActivityState.self,
            "Element"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ActivityStateUpdates.AsyncIterator.self
                == Activity<ProbeAttributes>.ActivityStateUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ActivityStateUpdates.Iterator.Element.self
                == ActivityState.self,
            "Iterator.Element"
        )
    }
}

func testContentUpdatesIteration() {
    activityKitReset()
    let activity = try! activityKitRequest("content-seq", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        let sequence = activity.contentUpdates
        let iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first?.state.progress == 0, "content replay")
        await activity.update(
            ActivityContent(
                state: ProbeAttributes.ContentState(message: "running", progress: 40),
                staleDate: nil,
                relevanceScore: 2
            )
        )
        let second = await iterator.next()
        activityKitRequire(second?.state.progress == 40, "contentUpdates order")
        activityKitRequire(
            Activity<ProbeAttributes>.ContentUpdates.Element.self
                == ActivityContent<ProbeAttributes.ContentState>.self,
            "Element"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ContentUpdates.AsyncIterator.self
                == Activity<ProbeAttributes>.ContentUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ContentUpdates.Iterator.Element.self
                == ActivityContent<ProbeAttributes.ContentState>.self,
            "Iterator.Element"
        )
    }
}

func testContentStateUpdatesIteration() {
    activityKitReset()
    let activity = try! activityKitRequest(
        "cstate-seq",
        content: activityKitContent("idle", progress: 0)
    )
    activityKitRunAsync {
        let sequence = activity.contentStateUpdates
        let iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first?.message == "idle", "contentState replay")
        await activity.update(using: ProbeAttributes.ContentState(message: "running", progress: 40))
        let second = await iterator.next()
        activityKitRequire(second?.message == "running", "contentStateUpdates order")
        activityKitRequire(
            Activity<ProbeAttributes>.ContentStateUpdates.Element.self
                == ProbeAttributes.ContentState.self,
            "Element"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ContentStateUpdates.AsyncIterator.self
                == Activity<ProbeAttributes>.ContentStateUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.ContentStateUpdates.Iterator.Element.self
                == ProbeAttributes.ContentState.self,
            "Iterator.Element"
        )
    }
}

func testPushTokenUpdatesIteration() {
    activityKitReset()
    let activity = try! activityKitRequest("token-seq", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    activityKitRunAsync {
        let sequence = activity.pushTokenUpdates
        let iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first == payload, "pushTokenUpdates")
        activityKitRequire(
            Activity<ProbeAttributes>.PushTokenUpdates.Element.self == Data.self,
            "Element"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.PushTokenUpdates.AsyncIterator.self
                == Activity<ProbeAttributes>.PushTokenUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            Activity<ProbeAttributes>.PushTokenUpdates.Iterator.Element.self == Data.self,
            "Iterator.Element"
        )
    }
}

func testPushToStartTokenUpdatesIteration() {
    activityKitReset()
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.pushToStartTokenUpdates
        var tokens: [Data] = []
        let iterator = sequence.makeAsyncIterator()
        while let token = await iterator.next() {
            tokens.append(token)
        }
        activityKitRequire(tokens.isEmpty, "push-to-start empty")
    }
}

func testActivityEnablementUpdatesIteration() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRunAsync {
        let sequence = info.activityEnablementUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first == true, "enablement Element Bool")
        activityKitRequire(
            ActivityAuthorizationInfo.ActivityEnablementUpdates.Element.self == Bool.self,
            "Element"
        )
        activityKitRequire(
            ActivityAuthorizationInfo.ActivityEnablementUpdates.AsyncIterator.self
                == ActivityAuthorizationInfo.ActivityEnablementUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            ActivityAuthorizationInfo.ActivityEnablementUpdates.Iterator.Element.self == Bool.self,
            "Iterator.Element"
        )
    }
}

func testFrequentPushEnablementUpdatesIteration() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRunAsync {
        let sequence = info.frequentPushEnablementUpdates
        var iterator = sequence.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first == false, "frequent Element Bool")
        activityKitRequire(
            ActivityAuthorizationInfo.FrequentPushEnablementUpdates.Element.self == Bool.self,
            "Element"
        )
        activityKitRequire(
            ActivityAuthorizationInfo.FrequentPushEnablementUpdates.AsyncIterator.self
                == ActivityAuthorizationInfo.FrequentPushEnablementUpdates.Iterator.self,
            "AsyncIterator"
        )
        activityKitRequire(
            ActivityAuthorizationInfo.FrequentPushEnablementUpdates.Iterator.Element.self
                == Bool.self,
            "Iterator.Element"
        )
    }
}
