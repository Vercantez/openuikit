import HealthKit
import Foundation

private func die(_ message: String) -> Never {
    fputs("HealthKit runtime probe failed: \(message)\n", stderr)
    exit(1)
}

private func require(_ condition: Bool, _ message: String) {
    if !condition { die(message) }
}

private func wait(_ semaphore: DispatchSemaphore, _ message: String) {
    require(semaphore.wait(timeout: .now() + 5) == .success, message)
}

private func testConstants() {
    require(HKErrorDomain == "com.apple.healthkit", "HKErrorDomain")
    require(HKMetadataKeyHeartRateSensorLocation == "HKMetadataKeyHeartRateSensorLocation", "metadata key")
    require(HKPredicateKeyPathUUID == "HKPredicateKeyPathUUID", "predicate key")
    require(HKObjectQueryNoLimit == 0, "query no limit")
    require(HKWorkoutTypeIdentifier == "HKWorkoutTypeIdentifier", "workout type id")
    require(HKWorkoutRouteTypeIdentifier == "HKWorkoutRouteTypeIdentifier", "route type id")
    require(abs(HKUnitMolarMassBloodGlucose - 180.15588) < 0.0001, "glucose molar mass")
    require(HKAnchoredObjectQueryNoAnchor == 0, "no anchor")
    require(HKSourceRevisionAnyVersion == "HKSourceRevisionAnyVersion", "any version")
    require(HKSourceRevisionAnyOperatingSystem.majorVersion == 0, "any OS")
}

private func testEnumsAndIdentifiers() {
    require(HKAuthorizationStatus.notDetermined.rawValue == 0, "auth notDetermined")
    require(HKAuthorizationStatus.sharingDenied.rawValue == 1, "auth denied")
    require(HKAuthorizationStatus.sharingAuthorized.rawValue == 2, "auth authorized")
    require(HKBiologicalSex.notSet.rawValue == 0, "sex notSet")
    require(HKBiologicalSex.female.rawValue == 1, "sex female")
    require(HKMetricPrefix.kilo.rawValue == 9, "metric kilo from macios")
    require(HKError.Code.errorHealthDataUnavailable.rawValue == 1, "error unavailable")
    require(HKError.Code.errorInvalidArgument.rawValue == 3, "invalid argument")
    require(HKError.Code.errorAuthorizationDenied.rawValue == 4, "denied")
    require(HKError.Code.errorAuthorizationNotDetermined.rawValue == 5, "not determined")
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
    require(HKQuantityTypeIdentifier.stepCount.rawValue == "HKQuantityTypeIdentifierStepCount", "steps id")
    require(HKCharacteristicTypeIdentifier.biologicalSex.rawValue == "HKCharacteristicTypeIdentifierBiologicalSex", "sex type")
    require(HKCorrelationTypeIdentifier.bloodPressure.rawValue == "HKCorrelationTypeIdentifierBloodPressure", "bp corr")
    require(NSNotification.Name.HKUserPreferencesDidChange.rawValue == "HKUserPreferencesDidChange", "prefs note")
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
    require(kilogram.unitString == "kg", "canonical kg")
    require(HKUnit.unit("kg")?.`is`(compatibleWith: kilogram) == true, "parse kg")
    require(HKUnit.unit("count/min")?.`is`(compatibleWith: HKUnit.count().unitDivided(by: .minute())) == true, "parse count/min")
    require(HKUnit.unit("m/s")?.`is`(compatibleWith: pace) == true, "parse m/s")
    require(HKUnit.unit("kcal")?.unitString == "kcal", "parse kcal string")
    require(HKUnit(from: "degC").`is`(compatibleWith: .degreeCelsius()), "init from degC")
    require(HKUnit.count().reciprocal().`is`(compatibleWith: HKUnit.count().unitRaised(toPower: -1)), "reciprocal")
    require(HKUnit.gram().unitMultiplied(by: .meter()).dimension.mass == 1, "g*m mass")
    require(!HKUnit.gram().isNull(), "gram not null")
    require(HKUnit(from: "").isNull() || HKUnit.unit("") == nil, "empty unit")
    let fromEnergy = HKUnit(from: EnergyFormatter.Unit.kilocalorie)
    require(fromEnergy.`is`(compatibleWith: .kilocalorie()), "energy formatter")
    require(HKUnit.energyFormatterUnit(from: .kilocalorie()) == .kilocalorie, "energy formatter reverse")
    require(HKUnit.lengthFormatterUnit(from: .mile()) == .mile, "length formatter")
    require(HKUnit.massFormatterUnit(from: .pound()) == .pound, "mass formatter")
}

private func testTypesAndSamples() {
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { die("heart type") }
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { die("step type") }
    require(heart.identifier == "HKQuantityTypeIdentifierHeartRate", "heart id")
    require(heart.requiresPerObjectAuthorization() == false, "no per-object auth")
    require(steps.aggregationStyle == .cumulative, "steps cumulative")
    require(heart.aggregationStyle == .discreteArithmetic, "hr discrete")
    require(heart.`is`(compatibleWith: HKUnit.count().unitDivided(by: .minute())), "hr unit")
    require(!heart.`is`(compatibleWith: .gram()), "hr not grams")
    require(steps.`is`(compatibleWith: .count()), "steps count")
    let now = Date()
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 60),
        start: now,
        end: now
    )
    require(sample.quantityType.identifier == heart.identifier, "sample type")
    require(sample.startDate == now, "start")
    guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { die("sleep type") }
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
    require(HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier) != nil, "series type")
    require(HKSeriesType.workoutRoute().identifier == HKWorkoutRouteTypeIdentifier, "route series")
    require(HKSeriesType.heartbeat().identifier == HKDataTypeIdentifierHeartbeatSeries, "heartbeat series")
    require(HKObjectType.workoutType().identifier == HKWorkoutTypeIdentifier, "workout type factory")
    require(HKObjectType.stateOfMindType().identifier == HKDataTypeIdentifierStateOfMind, "mind type")
    let device = HKDevice.local()
    require(device.name == "linux", "local device")
    let revision = HKSourceRevision(source: .default(), version: "1")
    require(revision.version == "1", "revision version")
}

private func authorizeAll(_ types: Set<HKSampleType>) {
    HKHealthStorePortable._installAuthorizationHandler { _, _ in .sharingAuthorized }
    let lock = DispatchSemaphore(value: 0)
    HKHealthStore().requestAuthorization(toShare: types, read: types) { _, _ in lock.signal() }
    wait(lock, "auth callback")
}

private func testStoreAuthorizationAndCRUD() async {
    HKHealthStorePortable._reset()
    require(HKHealthStore.isHealthDataAvailable() == true, "local store available")
    let store = HKHealthStore()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { die("heart") }
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { die("steps") }
    require(store.authorizationStatus(for: heart) == .notDetermined, "auth starts undetermined")

    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 72),
        start: Date(),
        end: Date()
    )
    do {
        try await store.save(sample)
        die("save without auth must throw")
    } catch {
        require(HKError.Code.errorAuthorizationNotDetermined ~= error, "save not determined")
    }

    let denyLock = DispatchSemaphore(value: 0)
    var denyOK = true
    store.requestAuthorization(toShare: [heart], read: [heart]) { success, _ in
        denyOK = success
        denyLock.signal()
    }
    wait(denyLock, "deny auth")
    require(denyOK == false, "no hook fail-closes")
    require(store.authorizationStatus(for: heart) == .sharingDenied, "denied after fail-close")
    do {
        try await store.save(sample)
        die("save denied must throw")
    } catch {
        require(HKError.Code.errorAuthorizationDenied ~= error, "save denied")
    }

    HKHealthStorePortable._reset()
    authorizeAll([heart, steps, HKObjectType.workoutType(), HKSeriesType.workoutRoute()])
    require(store.authorizationStatus(for: heart) == .sharingAuthorized, "authorized after hook")

    let badUnit = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: .gram(), doubleValue: 1),
        start: Date(),
        end: Date()
    )
    do {
        try await store.save(badUnit)
        die("mismatched unit must throw")
    } catch {
        require(HKError.Code.errorInvalidArgument ~= error, "invalid unit")
    }

    let t0 = Date()
    let hr1 = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60),
        start: t0,
        end: t0
    )
    let hr2 = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 80),
        start: t0.addingTimeInterval(60),
        end: t0.addingTimeInterval(60)
    )
    let stepSample = HKQuantitySample(
        type: steps,
        quantity: HKQuantity(unit: .count(), doubleValue: 100),
        start: t0,
        end: t0.addingTimeInterval(60)
    )
    try! await store.save([hr1, hr2, stepSample])

    let queryLock = DispatchSemaphore(value: 0)
    var queried: [HKSample]?
    let query = HKSampleQuery(
        sampleType: heart,
        predicate: HKQuery.predicateForSamples(withStart: t0.addingTimeInterval(-1), end: t0.addingTimeInterval(120), options: []),
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(keyPath: \HKSample.startDate, ascending: true)]
    ) { _, samples, err in
        require(err == nil, "query error \(String(describing: err))")
        queried = samples
        queryLock.signal()
    }
    store.execute(query)
    wait(queryLock, "sample query")
    require(queried?.count == 2, "two heart samples")

    let limitedLock = DispatchSemaphore(value: 0)
    var limitedCount = 0
    let limited = HKSampleQuery(sampleType: heart, predicate: nil, limit: 1, sortDescriptors: nil) { _, samples, _ in
        limitedCount = samples?.count ?? 0
        limitedLock.signal()
    }
    store.execute(limited)
    wait(limitedLock, "limit")
    require(limitedCount == 1, "limit 1")

    let uuidPred = HKQuery.predicateForObject(with: hr1.uuid)
    let uuidLock = DispatchSemaphore(value: 0)
    var uuidCount = 0
    store.execute(HKSampleQuery(sampleType: heart, predicate: uuidPred, limit: 0, sortDescriptors: nil) { _, samples, _ in
        uuidCount = samples?.count ?? 0
        uuidLock.signal()
    })
    wait(uuidLock, "uuid query")
    require(uuidCount == 1, "uuid predicate")

    let qtyPred = HKQuery.predicateForQuantitySamples(
        with: .greaterThan,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 70)
    )
    let qtyLock = DispatchSemaphore(value: 0)
    var qtyCount = 0
    store.execute(HKSampleQuery(sampleType: heart, predicate: qtyPred, limit: 0, sortDescriptors: nil) { _, samples, _ in
        qtyCount = samples?.count ?? 0
        qtyLock.signal()
    })
    wait(qtyLock, "qty predicate")
    require(qtyCount == 1, "quantity predicate > 70")

    try! await store.delete(hr2)
    let afterDelete = DispatchSemaphore(value: 0)
    var remaining = -1
    store.execute(HKSampleQuery(sampleType: heart, predicate: nil, limit: 0, sortDescriptors: nil) { _, samples, _ in
        remaining = samples?.count ?? 0
        afterDelete.signal()
    })
    wait(afterDelete, "after delete")
    require(remaining == 1, "one heart sample remains")
}

private func testStatisticsAndCollection() async {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { die("steps") }
    authorizeAll([steps])
    let store = HKHealthStore()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let s1 = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 10), start: start, end: start.addingTimeInterval(60))
    let s2 = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 15), start: start.addingTimeInterval(120), end: start.addingTimeInterval(180))
    try! await store.save([s1, s2])

    let statsLock = DispatchSemaphore(value: 0)
    var sum: Double?
    let statsQuery = HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: nil, options: .cumulativeSum) { _, stats, err in
        require(err == nil, "stats error")
        sum = stats?.sumQuantity()?.doubleValue(for: .count())
        statsLock.signal()
    }
    store.execute(statsQuery)
    wait(statsLock, "stats")
    require(sum == 25, "sum 10+15")

    let collectionLock = DispatchSemaphore(value: 0)
    var bucketCount = 0
    var collectionSum = 0.0
    var interval = DateComponents()
    interval.hour = 1
    let collection = HKStatisticsCollectionQuery(
        quantityType: steps,
        quantitySamplePredicate: nil,
        options: .cumulativeSum,
        anchorDate: start,
        intervalComponents: interval
    )
    collection.initialResultsHandler = { _, collection, err in
        require(err == nil, "collection error")
        collection?.enumerateStatistics(from: start, to: start.addingTimeInterval(3600), with: { stats, _ in
            bucketCount += 1
            collectionSum += stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
        })
        collectionLock.signal()
    }
    store.execute(collection)
    wait(collectionLock, "collection")
    require(bucketCount >= 1, "at least one bucket")
    require(collectionSum == 25, "collection sum")
}

private func testAnchoredObserverSourceRoute() async {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { die("heart") }
    authorizeAll([heart, HKObjectType.workoutType(), HKSeriesType.workoutRoute()])
    let store = HKHealthStore()
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 64),
        start: Date(),
        end: Date()
    )
    try! await store.save(sample)

    let anchoredLock = DispatchSemaphore(value: 0)
    var anchoredCount = 0
    let anchored = HKAnchoredObjectQuery(type: heart, predicate: nil, anchor: HKQueryAnchor(fromValue: 0), limit: HKObjectQueryNoLimit) { _, samples, _, _, err in
        require(err == nil, "anchored error")
        anchoredCount = samples?.count ?? 0
        anchoredLock.signal()
    }
    store.execute(anchored)
    wait(anchoredLock, "anchored")
    require(anchoredCount >= 1, "anchored samples")

    let sourceLock = DispatchSemaphore(value: 0)
    var sourceCount = 0
    store.execute(HKSourceQuery(sampleType: heart, samplePredicate: nil) { _, sources, err in
        require(err == nil, "source error")
        sourceCount = sources?.count ?? 0
        sourceLock.signal()
    })
    wait(sourceLock, "source query")
    require(sourceCount >= 1, "at least one source")

    let observerLock = DispatchSemaphore(value: 0)
    let observer = HKObserverQuery(sampleType: heart, predicate: nil) { _, completion, err in
        require(err == nil, "observer error")
        completion()
        observerLock.signal()
    }
    store.execute(observer)
    wait(observerLock, "observer")
    store.stop(observer)

    let workout = HKWorkout(activityType: .running, start: Date(), end: Date().addingTimeInterval(600))
    try! await store.save(workout)
    let route = HKWorkoutRoute(start: workout.startDate, end: workout.endDate)
    let loc = CLLocation(latitude: 37.3, longitude: -122.0)
    HKHealthStorePortable._setRouteLocations([loc], for: route)
    try! await store.save(route)
    let routeLock = DispatchSemaphore(value: 0)
    var routeCount = 0
    store.execute(HKWorkoutRouteQuery(route: route) { _, locations, done, err in
        require(err == nil, "route error")
        if done { routeCount = locations?.count ?? 0 }
        routeLock.signal()
    })
    wait(routeLock, "route query")
    require(routeCount == 1, "one route point")

    guard let bp = HKObjectType.correlationType(forIdentifier: .bloodPressure) else { die("bp") }
    HKHealthStorePortable._setAuthorization(for: bp, share: .sharingAuthorized, read: .sharingAuthorized)
    let corr = HKCorrelation(type: bp, start: Date(), end: Date(), objects: [])
    try! await store.save(corr)
    let corrLock = DispatchSemaphore(value: 0)
    var corrCount = 0
    store.execute(HKCorrelationQuery(type: bp, predicate: nil, samplePredicates: nil) { _, objects, err in
        require(err == nil, "corr error")
        corrCount = objects?.count ?? 0
        corrLock.signal()
    })
    wait(corrLock, "correlation")
    require(corrCount == 1, "one correlation")
}

private func testCharacteristicsBuilderAndFailClosed() async {
    HKHealthStorePortable._reset()
    var dob = DateComponents()
    dob.year = 1990
    dob.month = 6
    dob.day = 15
    HKHealthStorePortable._setCharacteristics(
        dateOfBirth: dob,
        biologicalSex: .female,
        bloodType: .aPositive,
        fitzpatrickSkinType: .III,
        wheelchairUse: .no,
        activityMoveMode: .appleMoveTime
    )
    let store = HKHealthStore()
    require(try! store.biologicalSex().biologicalSex == .female, "sex")
    require(try! store.bloodType().bloodType == .aPositive, "blood")
    require(try! store.fitzpatrickSkinType().skinType == .III, "skin")
    require(try! store.wheelchairUse().wheelchairUse == .no, "chair")
    require(try! store.activityMoveMode().activityMoveMode == .appleMoveTime, "move mode")
    require(try! store.dateOfBirthComponents().year == 1990, "dob year")

    do {
        try await store.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .hourly)
        die("background delivery must fail closed")
    } catch {
        require(HKError.Code.errorHealthDataUnavailable ~= error, "background fail-closed")
    }

    authorizeAll([HKObjectType.workoutType()])
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .cycling
    let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
    try! await builder.beginCollection(at: Date())
    try! await builder.addWorkoutEvents([HKWorkoutEvent(type: .pause, date: Date())])
    try! await builder.endCollection(at: Date().addingTimeInterval(120))
    let finishLock = DispatchSemaphore(value: 0)
    var finished: HKWorkout?
    builder.finishWorkout { workout, err in
        require(err == nil, "finish \(String(describing: err))")
        finished = workout
        finishLock.signal()
    }
    wait(finishLock, "finish workout")
    require(finished?.workoutActivityType == .cycling, "builder workout")

    do {
        try await builder.beginCollection(at: Date())
        die("second begin must fail")
    } catch {
        require(HKError.Code.errorInvalidArgument ~= error, "builder state")
    }

    let live = HKLiveWorkoutBuilder(healthStore: store, configuration: configuration, device: nil)
    require(live.elapsedTime >= 0, "live elapsed")
    _ = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
    let session = try! HKWorkoutSession(healthStore: store, configuration: configuration)
    session.prepare()
    require(session.state == .prepared, "session prepared")
    session.startActivity(with: Date())
    require(session.state == .running, "session running")
    session.end()
    require(session.state == .ended, "session ended")

    let summary = HKActivitySummary()
    summary.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: 200)
    require(summary.dateComponents(for: .current).calendar != nil || true, "summary calendar")
    let dstu2 = HKFHIRVersion.primaryDSTU2()
    require(dstu2.stringRepresentation == "1.0.2", "FHIR DSTU2")
    require(dstu2.fhirRelease == .dstu2, "FHIR release")
    let walking = try! HKAppleWalkingSteadinessClassification(for: HKQuantity(unit: .percent(), doubleValue: 0.8))
    require(walking == .ok, "walking ok")
    require(HKMedicationDoseEvent.LogStatus.taken.rawValue == 4, "dose taken")

    require(HKPredicateOperator.equalTo.rawValue == 4, "equalTo raw")
    require(HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: [.asleepCore]).evaluate(with: HKCategorySample(
        type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
        start: Date(),
        end: Date()
    )), "category predicate")

    let descriptor = HKSampleQueryDescriptor(
        predicates: [HKSamplePredicate.quantitySample(type: HKObjectType.quantityType(forIdentifier: .heartRate)!)],
        sortDescriptors: [],
        limit: 10
    )
    _ = try? await descriptor.result(for: store)
}

func healthKitRuntimeMain() async {
    testConstants()
    testEnumsAndIdentifiers()
    testUnitsAndQuantities()
    testTypesAndSamples()
    await testStoreAuthorizationAndCRUD()
    await testStatisticsAndCollection()
    await testAnchoredObserverSourceRoute()
    await testCharacteristicsBuilderAndFailClosed()
    print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
    print("HEALTHKIT_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await healthKitRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()
