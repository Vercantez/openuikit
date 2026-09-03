import HealthKit
import Foundation

private func die(_ message: String) -> Never {
    fputs("HealthKit runtime probe failed: \(message)\n", stderr)
    exit(1)
}

private func require(_ condition: Bool, _ message: String) {
    if !condition { die(message) }
}

private func testConstants() {
    require(HKErrorDomain == "com.apple.healthkit", "HKErrorDomain")
    require(HKMetadataKeyHeartRateSensorLocation == "HKMetadataKeyHeartRateSensorLocation", "metadata key")
    require(HKPredicateKeyPathUUID == "HKPredicateKeyPathUUID", "predicate key")
    require(HKObjectQueryNoLimit == 0, "query no limit")
}

private func testEnumsAndIdentifiers() {
    require(HKAuthorizationStatus.notDetermined.rawValue == 0, "auth notDetermined")
    require(HKAuthorizationStatus.sharingDenied.rawValue == 1, "auth denied")
    require(HKAuthorizationStatus.sharingAuthorized.rawValue == 2, "auth authorized")
    require(HKBiologicalSex.notSet.rawValue == 0, "sex notSet")
    require(HKBiologicalSex.female.rawValue == 1, "sex female")
    require(HKMetricPrefix.kilo.rawValue == 9, "metric kilo from macios")
    require(HKError.Code.errorHealthDataUnavailable.rawValue == 1, "error unavailable")
    require(HKError.noError.rawValue == 0, "noError alias")
    require(HKError.unknownError == HKError.Code.unknownError, "error overlay static")
    require(HKWorkoutActivityType.running.rawValue == 37, "running")
    require(HKWorkoutActivityType.other.rawValue == 3000, "other workout")
    require(HKActivityMoveMode.activeEnergy.rawValue == 1, "move mode")
    require(HKQuantityTypeIdentifier.heartRate.rawValue == "HKQuantityTypeIdentifierHeartRate", "qty id")
    require(HKCategoryTypeIdentifier.sleepAnalysis.rawValue == "HKCategoryTypeIdentifierSleepAnalysis", "cat id")
    require(HKQueryOptions.strictStartDate.rawValue == 1, "query options")
    require(HKStatisticsOptions.cumulativeSum.rawValue == 1 << 4, "stats options")
    require(HKStatisticsOptions.discreteMostRecent == HKStatisticsOptions.mostRecent, "discreteMostRecent alias")
    require(HKAuthorizationStatus.notDetermined != HKAuthorizationStatus.sharingAuthorized, "enum !=")
    require(HKCategoryValueSleepAnalysis.asleep == .asleepUnspecified, "asleep alias")
    require(HKCategoryValueSleepAnalysis.asleep.rawValue == 1, "asleep raw")
    require(HKCategoryValueSleepAnalysis.allAsleepValues.contains(.asleepCore), "allAsleepValues")
    require(HKCategoryValueOvulationTestResult.positive == .luteinizingHormoneSurge, "ovulation positive alias")
    require(HKHealthStore().supportsHealthRecords() == false, "no health records")
}

private func testUnitsAndQuantities() {
    let gram = HKUnit.gram()
    let kilogram = HKUnit.gramUnit(with: .kilo)
    require(gram.`is`(compatibleWith: kilogram), "g compatible kg")
    require(!gram.`is`(compatibleWith: HKUnit.meter()), "g not compatible m")
    let qty = HKQuantity(unit: kilogram, doubleValue: 2)
    require(abs(qty.doubleValue(for: gram) - 2000) < 1e-9, "2kg -> g")
    let celsius = HKQuantity(unit: .degreeCelsius(), doubleValue: 0)
    require(abs(celsius.doubleValue(for: .kelvin()) - 273.15) < 1e-9, "0C -> K")
    let pace = HKUnit.meter().unitDivided(by: HKUnit.second())
    require(pace.`is`(compatibleWith: HKUnit.meterUnit(with: .kilo).unitDivided(by: HKUnit.hour())), "speed dim")
    let kcal = HKQuantity(unit: .kilocalorie(), doubleValue: 1)
    require(abs(kcal.doubleValue(for: .joule()) - 4184) < 1e-6, "kcal -> J")
}

private func testTypesAndSamples() {
    guard let heart = HKObjectType.quantityType(for: .heartRate) else { die("heart type") }
    guard let steps = HKObjectType.quantityType(for: .stepCount) else { die("step type") }
    require(heart.identifier == "HKQuantityTypeIdentifierHeartRate", "heart id")
    require(heart.requiresPerObjectAuthorization() == false, "no per-object auth")
    require(steps.aggregationStyle == .cumulative, "steps cumulative")
    require(heart.aggregationStyle == .discreteArithmetic, "hr discrete")
    let now = Date()
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 60),
        start: now,
        end: now
    )
    require(sample.quantityType.identifier == heart.identifier, "sample type")
    require(sample.startDate == now, "start")
    guard let sleep = HKObjectType.categoryType(for: .sleepAnalysis) else { die("sleep type") }
    let category = HKCategorySample(
        type: sleep,
        value: HKCategoryValueSleepAnalysis.asleep.rawValue,
        start: now,
        end: now.addingTimeInterval(60)
    )
    require(category.value == HKCategoryValueSleepAnalysis.asleep.rawValue, "sleep value")
    let workout = HKWorkout(
        activityType: .running,
        start: now,
        end: now.addingTimeInterval(1200)
    )
    require(workout.workoutActivityType == .running, "workout type")
    require(abs(workout.duration - 1200) < 0.01, "workout duration")
    require(HKSource.default().name == "linux", "default source")
}

private func testStoreFailClosed() {
    require(HKHealthStore.isHealthDataAvailable() == false, "store unavailable")
    let store = HKHealthStore()
    guard let heart = HKObjectType.quantityType(for: .heartRate) else { die("heart") }
    require(store.authorizationStatus(for: heart) == .notDetermined, "auth status")
    let lock = DispatchSemaphore(value: 0)
    var ok = true
    var error: (any Error)?
    store.requestAuthorization(toShare: [heart], read: [heart]) { success, err in
        ok = success
        error = err
        lock.signal()
    }
    require(lock.wait(timeout: .now() + 2) == .success, "auth callback")
    require(ok == false, "auth must fail")
    let nsError = error as NSError?
    require(nsError?.domain == HKErrorDomain, "error domain")
    require(nsError?.code == HKError.Code.errorHealthDataUnavailable.rawValue, "error code")
    require(HKError.Code.errorHealthDataUnavailable ~= (error!), "pattern match")

    let queryLock = DispatchSemaphore(value: 0)
    var queryError: (any Error)?
    let query = HKSampleQuery(
        sampleType: heart,
        predicate: HKQuery.predicateForSamples(withStart: nil, end: nil, options: []),
        limit: HKObjectQueryNoLimit,
        sortDescriptors: nil
    ) { _, samples, err in
        require(samples == nil, "query samples nil")
        queryError = err
        queryLock.signal()
    }
    store.execute(query)
    require(queryLock.wait(timeout: .now() + 2) == .success, "query callback")
    require((queryError as NSError?)?.code == HKError.Code.errorHealthDataUnavailable.rawValue, "query error")
}

private func testThrows() async {
    let store = HKHealthStore()
    guard let heart = HKObjectType.quantityType(for: .heartRate) else { die("heart") }
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 60),
        start: Date(),
        end: Date()
    )
    do {
        try await store.save(sample)
        die("save must throw")
    } catch {
        require(HKError.Code.errorHealthDataUnavailable ~= error, "save error")
    }
}

func healthKitRuntimeMain() async {
    testConstants()
    testEnumsAndIdentifiers()
    testUnitsAndQuantities()
    testTypesAndSamples()
    testStoreFailClosed()
    await testThrows()
    print("HEALTHKIT_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await healthKitRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()

