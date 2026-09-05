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

func testQueryOptionsAlgebra() {
    var options: HKQueryOptions = []
    hkRequire(options.isEmpty)
    options.insert(.strictStartDate)
    hkRequire(options.contains(.strictStartDate))
    options.insert(.strictEndDate)
    _ = options.contains(.strictEndDate)
    let unioned = HKQueryOptions.strictStartDate.union(.strictEndDate)
    hkRequire(unioned.contains(.strictStartDate) && unioned.contains(.strictEndDate))
    let inter = unioned.intersection(.strictStartDate)
    hkRequire(inter == .strictStartDate)
    let diff = unioned.symmetricDifference(.strictStartDate)
    hkRequire(diff.contains(.strictEndDate))
    var mutating = HKQueryOptions.strictStartDate
    mutating.formUnion(.strictEndDate)
    mutating.formIntersection(.strictStartDate)
    mutating.formSymmetricDifference(.strictEndDate)
    _ = mutating.subtracting(.strictStartDate)
    mutating.subtract(.strictStartDate)
    _ = mutating.update(with: .strictEndDate)
    _ = mutating.remove(.strictEndDate)
    hkRequire(HKQueryOptions.strictStartDate.isSubset(of: unioned))
    hkRequire(unioned.isSuperset(of: .strictStartDate))
    hkRequire(HKQueryOptions.strictStartDate.isDisjoint(with: .strictEndDate))
    hkRequire(!HKQueryOptions.strictStartDate.isStrictSubset(of: .strictStartDate))
    hkRequire(unioned.isStrictSuperset(of: .strictStartDate))
    let fromArray: HKQueryOptions = [.strictStartDate, .strictEndDate]
    _ = HKQueryOptions(rawValue: 1)
    _ = fromArray
}

func testStatisticsOptionsAlgebra() {
    var options: HKStatisticsOptions = []
    options.insert(.cumulativeSum)
    options.insert(.discreteAverage)
    options.insert(.discreteMin)
    options.insert(.discreteMax)
    options.insert(.mostRecent)
    options.insert(.discreteMostRecent)
    options.insert(.duration)
    options.insert(.separateBySource)
    hkRequire(options.contains(.cumulativeSum))
    let unioned = HKStatisticsOptions.cumulativeSum.union(.discreteAverage)
    _ = unioned.intersection(.cumulativeSum)
    _ = unioned.symmetricDifference(.discreteMin)
    var mutating = HKStatisticsOptions.cumulativeSum
    mutating.formUnion(.discreteMax)
    mutating.formIntersection(.cumulativeSum)
    mutating.formSymmetricDifference(.duration)
    _ = mutating.subtracting(.duration)
    mutating.subtract(.cumulativeSum)
    _ = mutating.update(with: .duration)
    _ = mutating.remove(.duration)
    hkRequire(HKStatisticsOptions.mostRecent == .discreteMostRecent)
    _ = HKStatisticsOptions(rawValue: 1 << 4)
    let fromArray: HKStatisticsOptions = [.cumulativeSum, .discreteAverage]
    _ = fromArray.isEmpty
}

func testQuantitySeriesOptionsAlgebra() {
    var options: HKQuantitySeriesSampleQueryDescriptor.Options = []
    _ = options.isEmpty
    options.formUnion([])
    _ = HKQuantitySeriesSampleQueryDescriptor.Options(rawValue: 0)
    let unioned = options.union([])
    _ = unioned.intersection([])
    _ = unioned.symmetricDifference([])
    var mutating = options
    mutating.formUnion([])
    mutating.formIntersection([])
    mutating.formSymmetricDifference([])
    _ = mutating.subtracting([])
    mutating.subtract([])
    _ = mutating.insert(.init(rawValue: 0))
    _ = mutating.update(with: .init(rawValue: 0))
    _ = mutating.remove(.init(rawValue: 0))
    _ = options.contains(.init(rawValue: 0))
    _ = options.isSubset(of: [])
    _ = options.isSuperset(of: [])
    _ = options.isDisjoint(with: [])
    _ = options.isStrictSubset(of: unioned)
    _ = options.isStrictSuperset(of: [])
}
