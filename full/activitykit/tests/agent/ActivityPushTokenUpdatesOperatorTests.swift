@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testPushTokenUpdatesMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await value in sequence.map({ _ in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "mapped")
        }
        activityKitRequire(count == 1, "map count")
    }
}

func testPushTokenUpdatesThrowingMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await value in sequence.map({ _ throws in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing map")
        }
        activityKitRequire(count == 1, "throwing map count")
    }
}

func testPushTokenUpdatesCompactMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await value in sequence.compactMap({ _ in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "compactMap")
        }
        activityKitRequire(count == 1, "compactMap count")
    }
}

func testPushTokenUpdatesThrowingCompactMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await value in sequence.compactMap({ _ throws -> Int? in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing compactMap")
        }
        activityKitRequire(count == 1, "throwing compactMap count")
    }
}

func testPushTokenUpdatesFilter() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await _ in sequence.filter({ _ in true }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "filter count")
    }
}

func testPushTokenUpdatesDropFirst() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await _ in sequence.dropFirst(0).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "dropFirst count")
    }
}

func testPushTokenUpdatesDropWhile() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await _ in sequence.drop(while: { _ in false }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "drop while count")
    }
}

func testPushTokenUpdatesPrefix() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await _ in sequence.prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "prefix count")
    }
}

func testPushTokenUpdatesPrefixWhile() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for await _ in sequence.prefix(while: { _ in true }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "prefix while count")
    }
}

func testPushTokenUpdatesContainsWhere() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        let found = await sequence.contains(where: { _ in true })
        activityKitRequire(found, "contains where")
    }
}

func testPushTokenUpdatesFirstWhere() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        let first = await sequence.first(where: { _ in true })
        activityKitRequire(first != nil, "first where")
    }
}

func testPushTokenUpdatesAllSatisfy() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        let ok = await sequence.allSatisfy({ _ in false })
        activityKitRequire(!ok, "allSatisfy false")
    }
}

func testPushTokenUpdatesFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "flatMap")
        }
        activityKitRequire(count == 1, "flatMap count")
    }
}

func testPushTokenUpdatesContains() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        let found = await sequence.contains(payload)
        activityKitRequire(found, "contains element")
    }
}

func testPushTokenUpdatesMaxBy() {
    activityKitReset()
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.pushToStartTokenUpdates
        let maximum = await sequence.max(by: { $0.count < $1.count })
        activityKitRequire(maximum == nil, "empty max")
    }
}

func testPushTokenUpdatesMinBy() {
    activityKitReset()
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.pushToStartTokenUpdates
        let minimum = await sequence.min(by: { $0.count < $1.count })
        activityKitRequire(minimum == nil, "empty min")
    }
}

func testPushTokenUpdatesReduce() {
    activityKitReset()
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.pushToStartTokenUpdates
        let count = await sequence.reduce(0) { total, _ in total + 1 }
        activityKitRequire(count == 0, "empty reduce")
    }
}

func testPushTokenUpdatesReduceInto() {
    activityKitReset()
    activityKitRunAsync {
        let sequence = Activity<ProbeAttributes>.pushToStartTokenUpdates
        let count = await sequence.reduce(into: 0) { total, _ in total += 1 }
        activityKitRequire(count == 0, "empty reduce into")
    }
}
