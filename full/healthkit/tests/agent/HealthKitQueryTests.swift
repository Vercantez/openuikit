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

func testSampleQueryPredicateSortAndLimit() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    hkAuthorize([heart])
    let store = HKHealthStore()
    let t0 = Date()
    let hr1 = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60), start: t0, end: t0)
    let hr2 = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 80), start: t0.addingTimeInterval(60), end: t0.addingTimeInterval(60))
    hkWait { try await store.save([hr1, hr2]) }
    let lock = DispatchSemaphore(value: 0)
    var count = 0
    let query = HKSampleQuery(
        sampleType: heart,
        predicate: HKQuery.predicateForSamples(withStart: t0.addingTimeInterval(-1), end: t0.addingTimeInterval(120), options: [.strictStartDate, .strictEndDate]),
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(keyPath: \HKSample.startDate, ascending: true)]
    ) { _, samples, err in
        hkRequire(err == nil, "query")
        count = samples?.count ?? 0
        lock.signal()
    }
    store.execute(query)
    hkRequire(lock.wait(timeout: .now() + 5) == .success, "exec")
    hkRequire(count == 2, "two")
    let limited = DispatchSemaphore(value: 0)
    store.execute(HKSampleQuery(sampleType: heart, predicate: nil, limit: 1, sortDescriptors: nil) { _, samples, _ in
        hkRequire((samples?.count ?? 0) == 1, "limit")
        limited.signal()
    })
    hkRequire(limited.wait(timeout: .now() + 5) == .success, "limited")
    let uuidLock = DispatchSemaphore(value: 0)
    store.execute(HKSampleQuery(sampleType: heart, predicate: HKQuery.predicateForObject(with: hr1.uuid), limit: 0, sortDescriptors: nil) { _, samples, _ in
        hkRequire((samples?.count ?? 0) == 1, "uuid")
        uuidLock.signal()
    })
    hkRequire(uuidLock.wait(timeout: .now() + 5) == .success, "uuid")
}

func testQueryPredicateBuilders() {
    let source = HKSource.default()
    let device = HKDevice.local()
    let revision = HKSourceRevision(source: source, version: "1")
    let workout = HKWorkout(activityType: .running, start: Date(), end: Date().addingTimeInterval(60))
    _ = HKQuery.predicateForObjects(from: source)
    _ = HKQuery.predicateForObjects(from: [source])
    _ = HKQuery.predicateForObjects(from: [revision])
    _ = HKQuery.predicateForObjects(from: [device])
    _ = HKQuery.predicateForObjects(from: workout)
    _ = HKQuery.predicateForObjectsFromWorkout(workout)
    _ = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered)
    _ = HKQuery.predicateForObjects(with: HKMetadataKeyWasUserEntered)
    _ = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, allowedValues: [true])
    _ = HKQuery.predicateForObjects(with: HKMetadataKeyWasUserEntered, allowedValues: [true])
    _ = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, operatorType: .equalTo, value: true)
    _ = HKQuery.predicateForObjects(with: [UUID()])
    _ = HKQuery.predicateForObjects(withNoUUIDs: [UUID()])
    _ = HKQuery.predicateForObjectsWithDeviceProperty(HKDevicePropertyKeyName, allowedValues: ["linux"])
    _ = HKQuery.predicateForObjects(withDeviceProperty: HKDevicePropertyKeyName, allowedValues: ["linux"])
    _ = HKQuery.predicateForSamples(withStart: Date(), end: Date(), options: [])
    _ = HKQuery.predicateForObject(with: UUID())
    _ = HKQuery.predicateForObjectsWithNoCorrelation()
    _ = HKQuery.predicateForActivitySummary(with: DateComponents())
    _ = HKQuery.predicateForActivitySummaries(with: DateComponents())
    _ = HKQuery.predicate(forActivitySummariesBetweenStart: DateComponents(), end: DateComponents())
    _ = HKQuery.predicateForActivitySummaries(betweenStart: DateComponents(), end: DateComponents())
    _ = HKQuery.predicateForElectrocardiograms(classification: .sinusRhythm)
    _ = HKQuery.predicateForElectrocardiograms(symptomsStatus: .none)
    _ = HKQuery.predicateForCategorySamplesEqualToValues([NSNumber(value: 1)])
    _ = HKQuery.predicateForCategorySamples(with: .equalTo, value: 1)
    _ = HKQuery.predicateForQuantitySamples(with: .greaterThan, quantity: HKQuantity(unit: .count(), doubleValue: 1))
    _ = HKQuery.predicateForWorkouts(with: .running)
    _ = HKQuery.predicateForWorkouts(activityPredicate: NSPredicate(value: true))
    _ = HKQuery.predicateForWorkouts(associatedWithAttempt: UUID())
    _ = HKQuery.predicateForWorkouts(with: .greaterThan, duration: 1)
    _ = HKQuery.predicateForWorkouts(with: .greaterThan, totalDistance: HKQuantity(unit: .meter(), doubleValue: 1))
    _ = HKQuery.predicateForWorkouts(with: .greaterThan, totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 1))
    _ = HKQuery.predicateForWorkouts(with: .greaterThan, totalFlightsClimbed: HKQuantity(unit: .count(), doubleValue: 1))
    _ = HKQuery.predicateForWorkouts(with: .greaterThan, totalSwimmingStrokeCount: HKQuantity(unit: .count(), doubleValue: 1))
    _ = HKQuery.predicateForWorkoutActivities(workoutActivityType: .running)
    _ = HKQuery.predicateForWorkoutActivities(start: Date(), end: Date(), options: [])
    _ = HKQuery.predicateForWorkoutActivities(operatorType: .greaterThan, duration: 1)
    _ = HKQuery.predicateForWorkoutEffortSamplesRelated(workout: workout, activity: nil)
    _ = HKQuery.predicateForClinicalRecords(withFHIRResourceType: .observation)
    _ = HKQuery.predicateForStatesOfMind(with: HKStateOfMind.Association.community)
    _ = HKQuery.predicateForStatesOfMind(with: HKStateOfMind.Kind.dailyMood)
    _ = HKQuery.predicateForStatesOfMind(with: HKStateOfMind.Label.happy)
    _ = HKQuery.predicateForStatesOfMind(withValence: 0, operatorType: .equalTo)
    _ = HKQuery.predicateForUserAnnotatedMedications(hasSchedule: true)
    _ = HKQuery.predicateForUserAnnotatedMedications(isArchived: false)
    _ = HKQuery.predicateForVerifiableClinicalRecords(withRelevantDateWithin: DateInterval(start: Date(), duration: 1))
    _ = HKQuery.predicateForMedicationDoseEvent(scheduledDate: Date())
    _ = HKQuery.predicateForMedicationDoseEvent(scheduledDates: [Date()])
    _ = HKQuery.predicateForMedicationDoseEvent(scheduledStart: Date(), end: Date())
    hkRequire(HKPredicateOperator.equalTo.rawValue == 4, "equalTo")
}

func testAnchoredObserverSourceAndRouteQueries() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    hkAuthorize([heart, HKObjectType.workoutType(), HKSeriesType.workoutRoute()])
    let store = HKHealthStore()
    let sample = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 64), start: Date(), end: Date())
    hkWait { try await store.save(sample) }
    let anchoredLock = DispatchSemaphore(value: 0)
    let anchored = HKAnchoredObjectQuery(type: heart, predicate: nil, anchor: HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor)), limit: HKObjectQueryNoLimit) { _, samples, _, _, err in
        hkRequire(err == nil, "anchored")
        hkRequire((samples?.count ?? 0) >= 1, "anchored count")
        anchoredLock.signal()
    }
    store.execute(anchored)
    hkRequire(anchoredLock.wait(timeout: .now() + 5) == .success, "anchored wait")
    let sourceLock = DispatchSemaphore(value: 0)
    store.execute(HKSourceQuery(sampleType: heart, samplePredicate: nil) { _, sources, err in
        hkRequire(err == nil, "source")
        hkRequire((sources?.count ?? 0) >= 1, "sources")
        sourceLock.signal()
    })
    hkRequire(sourceLock.wait(timeout: .now() + 5) == .success, "source wait")
    let observerLock = DispatchSemaphore(value: 0)
    let observer = HKObserverQuery(sampleType: heart, predicate: nil) { _, completion, err in
        hkRequire(err == nil, "observer")
        completion()
        observerLock.signal()
    }
    store.execute(observer)
    hkRequire(observerLock.wait(timeout: .now() + 5) == .success, "observer")
    store.stop(observer)
    let workout = HKWorkout(activityType: .running, start: Date(), end: Date().addingTimeInterval(600))
    hkWait { try await store.save(workout) }
    store.add([sample], to: workout) { _, _ in }
    let route = HKWorkoutRoute(start: workout.startDate, end: workout.endDate)
    HKHealthStorePortable._setRouteLocations([CLLocation(latitude: 37.3, longitude: -122.0)], for: route)
    hkWait { try await store.save(route) }
    let routeLock = DispatchSemaphore(value: 0)
    store.execute(HKWorkoutRouteQuery(route: route) { _, locations, done, err in
        hkRequire(err == nil, "route")
        if done { hkRequire((locations?.count ?? 0) == 1, "point") }
        routeLock.signal()
    })
    hkRequire(routeLock.wait(timeout: .now() + 5) == .success, "route")
    guard let bp = HKObjectType.correlationType(forIdentifier: .bloodPressure) else { hkRequire(false, "bp"); return }
    HKHealthStorePortable._setAuthorization(for: bp, share: .sharingAuthorized, read: .sharingAuthorized)
    let corr = HKCorrelation(type: bp, start: Date(), end: Date(), objects: [])
    hkWait { try await store.save(corr) }
    let corrLock = DispatchSemaphore(value: 0)
    store.execute(HKCorrelationQuery(type: bp, predicate: nil, samplePredicates: nil) { _, objects, err in
        hkRequire(err == nil, "corr")
        hkRequire((objects?.count ?? 0) == 1, "corr count")
        corrLock.signal()
    })
    hkRequire(corrLock.wait(timeout: .now() + 5) == .success, "corr")
}
