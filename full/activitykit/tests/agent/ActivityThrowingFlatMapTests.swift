@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    _ = try! activityKitRequest("tfm-updates")
    let sequence = Activity<ProbeAttributes>.activityUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}

func testActivityStateUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("tfm-state")
    let sequence = activity.activityStateUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}

func testContentUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("tfm-content", content: activityKitContent("idle", progress: 0))
    let sequence = activity.contentUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}

func testContentStateUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("tfm-cstate", content: activityKitContent("idle", progress: 0))
    let sequence = activity.contentStateUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}

func testPushTokenUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let activity = try! activityKitRequest("tfm-token", pushType: .token)
    let payload = Data([0x0A, 0x0B])
    OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
    let sequence = activity.pushTokenUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}

func testActivityEnablementUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let info = ActivityAuthorizationInfo()
    let sequence = info.activityEnablementUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}

func testFrequentPushEnablementUpdatesThrowingFlatMap() {
    activityKitRunAsync {

    activityKitReset()
    let info = ActivityAuthorizationInfo()
    let sequence = info.frequentPushEnablementUpdates
        var count = 0
        for try await value in sequence.flatMap({ _ throws in AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        } }).prefix(1) {
            count += 1
            activityKitRequire(value == 1, "throwing flatMap")
        }
        activityKitRequire(count == 1, "throwing flatMap count")
    }
}
