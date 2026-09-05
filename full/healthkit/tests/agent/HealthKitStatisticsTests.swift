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

func testStatisticsSumAverageMinMax() {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkAuthorize([steps])
    let store = HKHealthStore()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let s1 = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 10), start: start, end: start.addingTimeInterval(60))
    let s2 = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 15), start: start.addingTimeInterval(120), end: start.addingTimeInterval(180))
    hkWait { try await store.save([s1, s2]) }
    let lock = DispatchSemaphore(value: 0)
    store.execute(HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: nil, options: [.cumulativeSum, .discreteAverage, .discreteMin, .discreteMax, .mostRecent]) { _, stats, err in
        hkRequire(err == nil, "stats")
        hkRequire(stats?.sumQuantity()?.doubleValue(for: .count()) == 25, "sum")
        _ = stats?.averageQuantity()
        _ = stats?.minimumQuantity()
        _ = stats?.maximumQuantity()
        _ = stats?.mostRecentQuantity()
        _ = stats?.duration()
        _ = stats?.startDate
        _ = stats?.endDate
        _ = stats?.quantityType
        _ = stats?.sources
        lock.signal()
    })
    hkRequire(lock.wait(timeout: .now() + 5) == .success, "stats wait")
}

func testStatisticsCollectionIntervals() {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkAuthorize([steps])
    let store = HKHealthStore()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let s1 = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 10), start: start, end: start.addingTimeInterval(60))
    let s2 = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 15), start: start.addingTimeInterval(120), end: start.addingTimeInterval(180))
    hkWait { try await store.save([s1, s2]) }
    var interval = DateComponents()
    interval.hour = 1
    let collection = HKStatisticsCollectionQuery(
        quantityType: steps,
        quantitySamplePredicate: nil,
        options: .cumulativeSum,
        anchorDate: start,
        intervalComponents: interval
    )
    let lock = DispatchSemaphore(value: 0)
    var bucketCount = 0
    collection.initialResultsHandler = { _, collection, err in
        hkRequire(err == nil, "collection")
        collection?.enumerateStatistics(from: start, to: start.addingTimeInterval(3600)) { stats, _ in
            bucketCount += 1
            _ = stats.sumQuantity()
        }
        lock.signal()
    }
    store.execute(collection)
    hkRequire(lock.wait(timeout: .now() + 5) == .success, "collection")
    hkRequire(bucketCount >= 1, "bucket")
    _ = collection.anchorDate
    _ = collection.intervalComponents
    _ = collection.options
    _ = collection.quantityType
}
