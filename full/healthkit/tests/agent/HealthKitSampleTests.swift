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

func testTypeFactoriesAndAggregation() {
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkRequire(heart.identifier == "HKQuantityTypeIdentifierHeartRate", "id")
    hkRequire(heart.requiresPerObjectAuthorization() == false, "per-object")
    hkRequire(steps.aggregationStyle == .cumulative, "cumulative")
    hkRequire(heart.aggregationStyle == .discreteArithmetic, "discrete")
    hkRequire(heart.`is`(compatibleWith: HKUnit.count().unitDivided(by: .minute())), "hr unit")
    hkRequire(steps.`is`(compatibleWith: .count()), "steps unit")
    _ = HKObjectType.quantityType(for: .bodyMass)
    _ = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    _ = HKObjectType.categoryType(for: .sleepAnalysis)
    _ = HKObjectType.characteristicType(forIdentifier: .biologicalSex)
    _ = HKObjectType.characteristicType(for: .bloodType)
    _ = HKObjectType.correlationType(forIdentifier: .bloodPressure)
    _ = HKObjectType.correlationType(for: .bloodPressure)
    _ = HKObjectType.documentType(forIdentifier: .CDA)
    _ = HKObjectType.documentType(for: .CDA)
    _ = HKObjectType.clinicalType(forIdentifier: .allergyRecord)
    _ = HKObjectType.workoutType()
    _ = HKObjectType.stateOfMindType()
    _ = HKObjectType.audiogramSampleType()
    _ = HKSeriesType.workoutRoute()
    _ = HKSeriesType.heartbeat()
    _ = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)
}

func testQuantityCategoryWorkoutSamples() {
    let now = Date()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { hkRequire(false, "sleep"); return }
    let sample = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60), start: now, end: now)
    hkRequire(sample.quantityType.identifier == heart.identifier, "qty type")
    hkRequire(sample.startDate == now, "start")
    _ = sample.endDate
    _ = sample.uuid
    _ = sample.metadata
    _ = sample.device
    _ = sample.sourceRevision
    let category = HKCategorySample(type: sleep, value: HKCategoryValueSleepAnalysis.asleep.rawValue, start: now, end: now.addingTimeInterval(60))
    hkRequire(category.value == HKCategoryValueSleepAnalysis.asleep.rawValue, "sleep")
    _ = HKCategorySample(type: sleep, value: HKCategoryValueSleepAnalysis.asleepCore.rawValue, start: now, end: now, metadata: [HKMetadataKeyWasUserEntered: true])
    _ = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: [.asleepCore])
    let workout = HKWorkout(activityType: .running, start: now, end: now.addingTimeInterval(1200))
    hkRequire(workout.workoutActivityType == .running, "run")
    hkRequire(abs(workout.duration - 1200) < 0.01, "duration")
    _ = workout.totalEnergyBurned
    _ = workout.totalDistance
    _ = workout.totalFlightsClimbed
    _ = workout.totalSwimmingStrokeCount
    _ = workout.workoutEvents
    _ = workout.workoutActivities
    hkRequire(HKSource.default().name == "linux", "source")
    let device = HKDevice.local()
    hkRequire(device.name == "linux", "device")
    _ = device.manufacturer
    _ = device.model
    _ = device.hardwareVersion
    _ = device.firmwareVersion
    _ = device.softwareVersion
    _ = device.localIdentifier
    _ = device.udiDeviceIdentifier
    let revision = HKSourceRevision(source: .default(), version: "1")
    hkRequire(revision.version == "1", "revision")
    _ = revision.productType
    _ = revision.operatingSystemVersion
    _ = HKSourceRevisionAnyVersion
    _ = HKSourceRevisionAnyProductType
    _ = HKDeletedObject(uuid: UUID())
}

func testActivitySummaryAndErrorOverlay() {
    let summary = HKActivitySummary()
    summary.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: 200)
    summary.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: 400)
    summary.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: 10)
    summary.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: 30)
    summary.appleStandHours = HKQuantity(unit: .count(), doubleValue: 6)
    summary.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: 12)
    summary.appleMoveTime = HKQuantity(unit: .minute(), doubleValue: 20)
    summary.appleMoveTimeGoal = HKQuantity(unit: .minute(), doubleValue: 30)
    summary.activityMoveMode = .activeEnergy
    summary.isPaused = false
    _ = summary.dateComponents(for: .current)
    _ = summary.exerciseTimeGoal
    _ = summary.standHoursGoal
    _ = HKError.errorHealthDataUnavailable
    _ = HKError.errorAuthorizationDenied
    _ = HKError.errorAuthorizationNotDetermined
    _ = HKError.errorInvalidArgument
    _ = HKError.unknownError
    _ = HKError.noError
    _ = HKError.errorHealthDataRestricted
    _ = HKError.errorDatabaseInaccessible
    _ = HKError.errorUserCanceled
    _ = HKError.errorAnotherWorkoutSessionStarted
    _ = HKError.errorUserExitedWorkoutSession
    _ = HKError.errorRequiredAuthorizationDenied
    _ = HKError.errorNoData
    _ = HKError.errorWorkoutActivityNotAllowed
    _ = HKError.errorDataSizeExceeded
    _ = HKError.errorBackgroundWorkoutSessionNotAllowed
    _ = HKError.errorNotPermissibleForGuestUserMode
    _ = HKError.Code.errorHealthDataUnavailable
    _ = HKError(HKError.Code.errorNoData)
    _ = HKAppleSleepingBreathingDisturbancesClassification.elevated.minimum
    _ = HKAppleSleepingBreathingDisturbancesClassification.minimumQuantity(for: .elevated)
}
