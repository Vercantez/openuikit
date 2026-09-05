@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testContentUpdatesMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await value in sequence.map({ _ in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "mapped")
        }
        activityKitRequire(count == 1, "map count")
    }
}

func testContentUpdatesThrowingMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await value in sequence.map({ _ throws in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing map")
        }
        activityKitRequire(count == 1, "throwing map count")
    }
}

func testContentUpdatesCompactMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await value in sequence.compactMap({ _ in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "compactMap")
        }
        activityKitRequire(count == 1, "compactMap count")
    }
}

func testContentUpdatesThrowingCompactMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await value in sequence.compactMap({ _ throws -> Int? in 1 }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing compactMap")
        }
        activityKitRequire(count == 1, "throwing compactMap count")
    }
}

func testContentUpdatesFilter() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await _ in sequence.filter({ _ in true }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "filter count")
    }
}

func testContentUpdatesDropFirst() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await _ in sequence.dropFirst(0).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "dropFirst count")
    }
}

func testContentUpdatesDropWhile() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await _ in sequence.drop(while: { _ in false }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "drop while count")
    }
}

func testContentUpdatesPrefix() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for try await _ in sequence.prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "prefix count")
    }
}

func testContentUpdatesPrefixWhile() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        var count = 0
        for await _ in sequence.prefix(while: { _ in true }).prefix(1) {
            count += 1
        }
        activityKitRequire(count == 1, "prefix while count")
    }
}

func testContentUpdatesContainsWhere() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        let found = await sequence.contains(where: { _ in true })
        activityKitRequire(found, "contains where")
    }
}

func testContentUpdatesFirstWhere() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        let first = await sequence.first(where: { _ in true })
        activityKitRequire(first != nil, "first where")
    }
}

func testContentUpdatesAllSatisfy() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
        let ok = await sequence.allSatisfy({ _ in false })
        activityKitRequire(!ok, "allSatisfy false")
    }
}

func testContentUpdatesFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("op")
    let sequence = activity.contentUpdates
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
