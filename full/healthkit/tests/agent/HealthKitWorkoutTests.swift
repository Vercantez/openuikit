import Foundation
import HealthKit

private func hkRequire(_ condition: Bool, _ message: String = "") {
    if !condition {
        fputs("HealthKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

private func hkWait(_ body: @escaping @Sendable () async throws -> Void) {
    let lock = DispatchSemaphore(value: 0)
    Task {
        do { try await body() } catch { hkRequire(false, "async \(error)") }
        lock.signal()
    }
    hkRequire(lock.wait(timeout: .now() + 8) == .success, "async timeout")
}

private func hkAuthorize(_ types: Set<HKSampleType>) {
    HKHealthStorePortable._installAuthorizationHandler { _, _ in .sharingAuthorized }
    let lock = DispatchSemaphore(value: 0)
    HKHealthStore().requestAuthorization(toShare: types, read: types) { _, _ in lock.signal() }
    hkRequire(lock.wait(timeout: .now() + 5) == .success, "auth")
}

func testWorkoutBuilderStateMachine() {
    HKHealthStorePortable._reset()
    hkAuthorize([HKObjectType.workoutType()])
    let store = HKHealthStore()
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .cycling
    configuration.locationType = .outdoor
    _ = configuration.swimmingLocationType
    _ = configuration.lapLength
    let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
    hkWait {
        try await builder.beginCollection(at: Date())
        try await builder.addMetadata([HKMetadataKeyIndoorWorkout: false])
        try await builder.addWorkoutEvents([HKWorkoutEvent(type: .pause, date: Date())])
        try await builder.endCollection(at: Date().addingTimeInterval(120))
    }
    let finishLock = DispatchSemaphore(value: 0)
    var finished: HKWorkout?
    builder.finishWorkout { workout, err in
        hkRequire(err == nil, "finish")
        finished = workout
        finishLock.signal()
    }
    hkRequire(finishLock.wait(timeout: .now() + 5) == .success, "finish")
    hkRequire(finished?.workoutActivityType == .cycling, "cycling")
    _ = builder.workoutConfiguration
    _ = builder.device
    _ = builder.startDate
    _ = builder.endDate
    _ = builder.metadata
    _ = builder.workoutEvents
    _ = builder.workoutActivities
    _ = builder.allStatistics
    hkWait {
        do {
            try await builder.beginCollection(at: Date())
            hkRequire(false, "second begin")
        } catch {
            hkRequire(HKError.Code.errorInvalidArgument ~= error, "state")
        }
        builder.discardWorkout()
    }
}

func testLiveWorkoutSessionAndRouteBuilder() {
    HKHealthStorePortable._reset()
    hkAuthorize([HKObjectType.workoutType()])
    let store = HKHealthStore()
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .running
    let live = HKLiveWorkoutBuilder(healthStore: store, configuration: configuration, device: nil)
    hkRequire(live.elapsedTime >= 0, "elapsed")
    _ = live.workoutSession
    _ = live.dataSource
    _ = live.delegate
    _ = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
    let session = try! HKWorkoutSession(healthStore: store, configuration: configuration)
    session.prepare()
    hkRequire(session.state == .prepared, "prepared")
    session.startActivity(with: Date())
    hkRequire(session.state == .running, "running")
    session.pause()
    session.resume()
    session.end()
    hkRequire(session.state == .ended, "ended")
    _ = session.type
    _ = session.locationType
    _ = session.startDate
    _ = session.endDate
    let routeBuilder = HKWorkoutRouteBuilder(healthStore: store, device: .local())
    hkWait {
        try await routeBuilder.insertRouteData([CLLocation(latitude: 1, longitude: 2)])
        _ = try? await routeBuilder.finishRoute(with: HKWorkout(activityType: .running, start: Date(), end: Date()), metadata: nil)
    }
    _ = HKWorkoutEvent(type: .pause, date: Date())
    _ = HKWorkoutActivity(workoutConfiguration: configuration, start: Date(), end: Date(), metadata: nil)
}
