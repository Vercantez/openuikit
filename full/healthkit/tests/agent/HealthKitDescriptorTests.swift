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

func testSampleQueryDescriptor() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    hkAuthorize([heart])
    let store = HKHealthStore()
    let sample = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 70), start: Date(), end: Date())
    hkWait { try await store.save(sample) }
    let predicate = HKSamplePredicate.quantitySample(type: heart)
    let descriptor = HKSampleQueryDescriptor(predicates: [predicate], sortDescriptors: [], limit: 10)
    hkWait {
        let results = try await descriptor.result(for: store)
        hkRequire(results.count >= 1, "descriptor")
    }
    _ = descriptor.limit
}

func testStatisticsAndAnchoredDescriptors() {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkAuthorize([steps])
    let store = HKHealthStore()
    let start = Date()
    hkWait {
        try await store.save(HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 5), start: start, end: start))
    }
    let stats = HKStatisticsQueryDescriptor(predicate: HKSamplePredicate.quantitySample(type: steps), options: .cumulativeSum)
    hkWait { _ = try await stats.result(for: store) }
    _ = stats.options
    var interval = DateComponents()
    interval.hour = 1
    let collection = HKStatisticsCollectionQueryDescriptor(
        predicate: HKSamplePredicate.quantitySample(type: steps),
        options: .cumulativeSum,
        anchorDate: start,
        intervalComponents: interval
    )
    hkWait { _ = try await collection.result(for: store) }
    let anchored = HKAnchoredObjectQueryDescriptor(predicates: [HKSamplePredicate.quantitySample(type: steps)], anchor: nil, limit: 10)
    hkWait { _ = try await anchored.result(for: store) }
}

func testActivityAndRouteDescriptors() {
    HKHealthStorePortable._reset()
    hkAuthorize([HKObjectType.workoutType(), HKSeriesType.workoutRoute()])
    let store = HKHealthStore()
    let summary = HKActivitySummaryQueryDescriptor(predicate: nil)
    hkWait { _ = try await summary.result(for: store) }
    let routeDesc = HKWorkoutRouteQueryDescriptor(predicate: HKSamplePredicate.workoutRoute())
    hkWait { _ = try await routeDesc.result(for: store) }
    let sourceDesc = HKSourceQueryDescriptor(predicate: HKSamplePredicate.workout())
    hkWait { _ = try await sourceDesc.result(for: store) }
}
