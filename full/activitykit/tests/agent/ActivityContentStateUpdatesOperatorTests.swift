@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testContentStateUpdatesMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await value in sequence.map({ _ in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "mapped")
        }
        activityKitRequire(count == 1, "map count")
    }
}

func testContentStateUpdatesThrowingMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await value in sequence.map({ _ throws in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing map")
        }
        activityKitRequire(count == 1, "throwing map count")
    }
}

func testContentStateUpdatesCompactMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await value in sequence.compactMap({ _ in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "compactMap")
        }
        activityKitRequire(count == 1, "compactMap count")
    }
}

func testContentStateUpdatesThrowingCompactMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await value in sequence.compactMap({ _ throws -> Int? in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing compactMap")
        }
        activityKitRequire(count == 1, "throwing compactMap count")
    }
}

func testContentStateUpdatesFilter() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await _ in sequence.filter({ _ in true }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "filter count")
    }
}

func testContentStateUpdatesDropFirst() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await _ in sequence.dropFirst(0).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "dropFirst count")
    }
}

func testContentStateUpdatesDropWhile() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await _ in sequence.drop(while: { _ in false }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "drop while count")
    }
}

func testContentStateUpdatesPrefix() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await _ in sequence.prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "prefix count")
    }
}

func testContentStateUpdatesPrefixWhile() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        var count = 0
        for await _ in sequence.prefix(while: { _ in true }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "prefix while count")
    }
}

func testContentStateUpdatesContainsWhere() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        let found = await sequence.contains(where: { _ in true })
        activityKitRequire(found, "contains where")
    }
}

func testContentStateUpdatesFirstWhere() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        let first = await sequence.first(where: { _ in true })
        activityKitRequire(first != nil, "first where")
    }
}

func testContentStateUpdatesAllSatisfy() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        let ok = await sequence.allSatisfy({ _ in false })
        activityKitRequire(!ok, "allSatisfy false")
    }
}

func testContentStateUpdatesFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
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

func testContentStateUpdatesContains() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest(
        "op",
        content: activityKitContent("s", progress: 1)
    )
    let sequence = activity.contentStateUpdates
        let found = await sequence.contains(ProbeAttributes.ContentState(message: "s", progress: 1))
        activityKitRequire(found, "contains element")
    }
}
