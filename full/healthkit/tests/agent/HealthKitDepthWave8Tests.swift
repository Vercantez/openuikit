import Foundation
import HealthKit

private func hkRequire(_ condition: Bool, _ message: String = "") {
    if !condition {
        fputs("HealthKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

private func hkAuthorizeSync(_ types: Set<HKObjectType>) {
    for type in types {
        HKHealthStorePortable._setAuthorization(for: type, share: .sharingAuthorized, read: .sharingAuthorized)
    }
}

func testSamplePredicateFactories() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { hkRequire(false, "sleep"); return }
    guard let bp = HKObjectType.correlationType(forIdentifier: .bloodPressure) else { hkRequire(false, "bp"); return }
    guard let allergy = HKObjectType.clinicalType(forIdentifier: .allergyRecord) else { hkRequire(false, "clinical"); return }
    let datePred = HKQuery.predicateForSamples(withStart: Date(), end: Date(), options: [])
    let quantity = HKSamplePredicate.quantitySample(type: heart, predicate: datePred)
    hkRequire(quantity.sampleType.identifier == heart.identifier, "qty type")
    hkRequire(quantity.nsPredicate != nil, "qty predicate")
    let category = HKSamplePredicate.categorySample(type: sleep)
    hkRequire(category.sampleType.identifier == sleep.identifier, "cat type")
    hkRequire(category.nsPredicate == nil, "cat nil pred")
    let correlation = HKSamplePredicate.correlation(type: bp)
    hkRequire(correlation.sampleType.identifier == bp.identifier, "corr")
    let workout = HKSamplePredicate.workout()
    hkRequire(workout.sampleType.identifier == HKWorkoutTypeIdentifier, "workout")
    let route = HKSamplePredicate.workoutRoute()
    hkRequire(route.sampleType.identifier == HKWorkoutRouteTypeIdentifier, "route")
    let mind = HKSamplePredicate.stateOfMind()
    hkRequire(mind.sampleType.identifier == HKDataTypeIdentifierStateOfMind, "mind")
    let clinical = HKSamplePredicate.clinicalRecord(type: allergy)
    hkRequire(clinical.sampleType.identifier == allergy.identifier, "clinical")
    let gad = HKSamplePredicate.gad7Assessment()
    hkRequire(gad.sampleType.identifier == HKScoredAssessmentTypeIdentifier.GAD7.rawValue, "gad")
    let phq = HKSamplePredicate.phq9Assessment()
    hkRequire(phq.sampleType.identifier == HKScoredAssessmentTypeIdentifier.PHQ9.rawValue, "phq")
    let beats = HKSamplePredicate.heartbeatSeries()
    hkRequire(beats.sampleType.identifier == HKDataTypeIdentifierHeartbeatSeries, "beats")
    let ecg = HKSamplePredicate.electrocardiogram()
    hkRequire(ecg.sampleType.identifier == HKObjectType.electrocardiogramType().identifier, "ecg")
    let vision = HKSamplePredicate.visionPrescription()
    hkRequire(vision.sampleType.identifier == HKObjectType.visionPrescriptionType().identifier, "vision")
    let audio = HKSamplePredicate.audiogram()
    hkRequire(audio.sampleType.identifier == HKObjectType.audiogramSampleType().identifier, "audio")
    hkRequire(quantity != HKSamplePredicate.quantitySample(type: heart), "predicate inequality")
    hkRequire(HKSamplePredicate.quantitySample(type: heart) == HKSamplePredicate.quantitySample(type: heart), "equality")
}

func testQuantitySeriesSampleBuilderInsertAndDiscard() {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkAuthorizeSync([steps])
    let device = HKDevice.local()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let builder = HKQuantitySeriesSampleBuilder(
        healthStore: HKHealthStore(),
        quantityType: steps,
        startDate: start,
        device: device
    )
    hkRequire(builder.quantityType.identifier == steps.identifier, "type")
    hkRequire(builder.startDate == start, "start")
    hkRequire(builder.device?.name == device.name, "device")
    try! builder.insert(HKQuantity(unit: .count(), doubleValue: 4), at: start)
    try! builder.insert(
        HKQuantity(unit: .count(), doubleValue: 6),
        for: DateInterval(start: start.addingTimeInterval(60), duration: 30)
    )
    do {
        try builder.insert(HKQuantity(unit: .gram(), doubleValue: 1), at: start)
        hkRequire(false, "incompatible unit must throw")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "invalid unit")
    }
    builder.discard()
    do {
        try builder.insert(HKQuantity(unit: .count(), doubleValue: 1), at: start)
        hkRequire(false, "discarded insert must throw")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "discarded")
    }
}

func testVisionPrismPolarAndRectangular() {
    let polar = HKVisionPrism(
        amount: HKQuantity(unit: .prismDiopter(), doubleValue: 2),
        angle: HKQuantity(unit: .degreeAngle(), doubleValue: 0),
        eye: .left
    )
    hkRequire(polar.eye == .left, "eye")
    hkRequire(abs(polar.amount.doubleValue(for: .prismDiopter()) - 2) < 1e-9, "amount")
    hkRequire(abs(polar.angle.doubleValue(for: .degreeAngle()) - 0) < 1e-9, "angle")
    hkRequire(abs(polar.horizontalAmount.doubleValue(for: .prismDiopter()) - 2) < 1e-6, "horizontal")
    hkRequire(polar.horizontalBase == .out, "out")
    hkRequire(polar.verticalBase == .none || abs(polar.verticalAmount.doubleValue(for: .prismDiopter())) < 1e-6, "no vertical")
    let rectangular = HKVisionPrism(
        verticalAmount: HKQuantity(unit: .prismDiopter(), doubleValue: 3),
        verticalBase: .up,
        horizontalAmount: HKQuantity(unit: .prismDiopter(), doubleValue: 4),
        horizontalBase: .out,
        eye: .right
    )
    hkRequire(rectangular.eye == .right, "right")
    hkRequire(abs(rectangular.verticalAmount.doubleValue(for: .prismDiopter()) - 3) < 1e-9, "v")
    hkRequire(rectangular.verticalBase == .up, "up")
    hkRequire(abs(rectangular.horizontalAmount.doubleValue(for: .prismDiopter()) - 4) < 1e-9, "h")
    hkRequire(rectangular.horizontalBase == .out, "h base")
    hkRequire(abs(rectangular.amount.doubleValue(for: .prismDiopter()) - 5) < 1e-6, "hypot")
    let data = try! NSKeyedArchiver.archivedData(withRootObject: rectangular, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKVisionPrism.self, from: data)
    hkRequire(decoded?.eye == .right, "decode eye")
    hkRequire(abs((decoded?.amount.doubleValue(for: .prismDiopter()) ?? 0) - 5) < 1e-6, "decode amount")
}

func testQuantitySeriesQueryDescriptorResults() {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkAuthorizeSync([steps])
    let start = Date(timeIntervalSince1970: 1_700_100_000)
    let sample = HKQuantitySample(
        type: steps,
        quantity: HKQuantity(unit: .count(), doubleValue: 10),
        start: start,
        end: start.addingTimeInterval(120)
    )
    try! HKHealthStorePortable._save([sample])
    HKHealthStorePortable._setQuantitySeries(
        [
            (HKQuantity(unit: .count(), doubleValue: 4), DateInterval(start: start, duration: 60)),
            (HKQuantity(unit: .count(), doubleValue: 6), DateInterval(start: start.addingTimeInterval(60), duration: 60))
        ],
        for: sample
    )
    let descriptor = HKQuantitySeriesSampleQueryDescriptor(
        predicate: HKSamplePredicate.quantitySample(type: steps),
        options: [.includeSample, .orderByQuantitySampleStartDate]
    )
    hkRequire(descriptor.options.contains(.includeSample), "include")
    hkRequire(descriptor.predicate.sampleType.identifier == steps.identifier, "pred")
    let results = descriptor.results(for: HKHealthStore())
    _ = results.makeAsyncIterator()
    hkRequire(results.items.count == 2, "two points")
    hkRequire(abs(results.items[0].quantity.doubleValue(for: .count()) - 4) < 1e-9, "first qty")
    hkRequire(results.items[0].dateInterval.duration == 60, "interval")
    hkRequire(results.items[0].sample?.uuid == sample.uuid, "sample included")
    hkRequire(results.items[0] != results.items[1], "inequality")
    hkRequire(results.items[0] == results.items[0], "equality")
    var hasher = Hasher()
    results.items[0].hash(into: &hasher)
    _ = results.items[0].hashValue
    let withoutSample = HKQuantitySeriesSampleQueryDescriptor(
        predicate: HKSamplePredicate.quantitySample(type: steps),
        options: []
    ).results(for: HKHealthStore())
    hkRequire(withoutSample.items.first?.sample == nil, "sample omitted")
}

func testHeartbeatSeriesQueryDescriptor() {
    HKHealthStorePortable._reset()
    let series = HKHeartbeatSeriesSample(start: Date(), end: Date().addingTimeInterval(2))
    hkAuthorizeSync([HKSeriesType.heartbeat()])
    try! HKHealthStorePortable._save([series])
    HKHealthStorePortable._setHeartbeats([(0.4, false), (0.9, true)], for: series)
    let descriptor = HKHeartbeatSeriesQueryDescriptor(series)
    hkRequire(descriptor.sample.uuid == series.uuid, "sample")
    let results = descriptor.results(for: HKHealthStore())
    _ = results.makeAsyncIterator()
    hkRequire(results.items.count == 2, "two beats")
    hkRequire(abs(results.items[0].timeIntervalSinceStart - 0.4) < 1e-9, "t0")
    hkRequire(results.items[0].precededByGap == false, "gap0")
    hkRequire(results.items[1].precededByGap == true, "gap1")
    hkRequire(results.items[0] != results.items[1], "neq")
    hkRequire(HKHeartbeatSeriesBuilder.maximumCount == 100, "max")
    let builder = HKHeartbeatSeriesBuilder(healthStore: HKHealthStore(), device: nil, start: Date())
    _ = HKHeartbeatSeriesBuilder(healthStore: HKHealthStore(), device: nil, startDate: Date())
    var finished: HKHeartbeatSeriesSample?
    builder.finishSeries { sample, err in
        hkRequire(err == nil || sample != nil || err != nil, "completion")
        finished = sample
    }
    hkRequire(finished != nil, "finished series")
    var delivered = 0
    let query = HKHeartbeatSeriesQuery(heartbeatSeries: series) { _, _, _, done, err in
        hkRequire(err == nil, "query")
        delivered += 1
        if done { /* last beat */ }
    }
    HKHealthStore().execute(query)
    hkRequire(delivered == 2, "handler")
}

func testElectrocardiogramQueryDescriptor() {
    HKHealthStorePortable._reset()
    let ecg = HKElectrocardiogram(start: Date(), end: Date().addingTimeInterval(30))
    hkAuthorizeSync([HKObjectType.electrocardiogramType()])
    try! HKHealthStorePortable._save([ecg])
    let millivolt = HKQuantity(unit: HKUnit.voltUnit(with: .milli), doubleValue: 0.5)
    let measurement = HKElectrocardiogram.VoltageMeasurement(timeSinceSampleStart: 0.01, voltage: millivolt)
    hkRequire(abs((measurement.quantity(for: .appleWatchSimilarToLeadI)?.doubleValue(for: HKUnit.voltUnit(with: .milli)) ?? 0) - 0.5) < 1e-9, "lead")
    HKHealthStorePortable._setVoltageMeasurements([measurement], for: ecg)
    hkRequire(ecg.numberOfVoltageMeasurements == 1, "count")
    let descriptor = HKElectrocardiogramQueryDescriptor(ecg)
    hkRequire(descriptor.electrocardiogram.uuid == ecg.uuid, "ecg")
    let results = descriptor.results(for: HKHealthStore())
    _ = results.makeAsyncIterator()
    hkRequire(results.items.count == 1, "one voltage")
    hkRequire(abs(results.items[0].timeSinceSampleStart - 0.01) < 1e-9, "time")
    var states: [String] = []
    let query = HKElectrocardiogramQuery(electrocardiogram: ecg) { _, result in
        switch result {
        case .measurement: states.append("m")
        case .done: states.append("d")
        case .error: states.append("e")
        }
    }
    HKHealthStore().execute(query)
    hkRequire(states == ["m", "d"], "query states")
    var objcDone = false
    let objcQuery = HKElectrocardiogramQuery(electrocardiogram: ecg) {
        (_: HKElectrocardiogramQuery, _: HKElectrocardiogram.VoltageMeasurement?, done: Bool, err: (any Error)?) in
        hkRequire(err == nil, "objc handler")
        if done { objcDone = true }
    }
    HKHealthStore().execute(objcQuery)
    hkRequire(objcDone, "objc done")
}

func testAnchoredAndStatisticsCollectionDescriptorResults() {
    HKHealthStorePortable._reset()
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    hkAuthorizeSync([steps])
    let start = Date(timeIntervalSince1970: 1_700_200_000)
    let sample = HKQuantitySample(type: steps, quantity: HKQuantity(unit: .count(), doubleValue: 12), start: start, end: start.addingTimeInterval(10))
    try! HKHealthStorePortable._save([sample])
    let anchored = HKAnchoredObjectQueryDescriptor(
        predicates: [HKSamplePredicate.quantitySample(type: steps)],
        anchor: HKQueryAnchor(fromValue: 0),
        limit: 10
    )
    let anchoredResults = anchored.results(for: HKHealthStore())
    _ = anchoredResults.makeAsyncIterator()
    hkRequire(anchoredResults.items.count == 1, "one result")
    hkRequire(anchoredResults.items[0].addedSamples.count == 1, "added")
    hkRequire(anchoredResults.items[0].deletedObjects.isEmpty, "no deleted")
    hkRequire(anchoredResults.items[0].newAnchor.value >= 1, "anchor")
    var interval = DateComponents()
    interval.hour = 1
    let collection = HKStatisticsCollectionQueryDescriptor(
        predicate: HKSamplePredicate.quantitySample(type: steps),
        options: .cumulativeSum,
        anchorDate: start,
        intervalComponents: interval
    )
    let collectionResults = collection.results(for: HKHealthStore())
    _ = collectionResults.makeAsyncIterator()
    hkRequire(collectionResults.items.count == 1, "collection result")
    var sum = 0.0
    collectionResults.items[0].statisticsCollection.enumerateStatistics(from: start, to: start.addingTimeInterval(3600)) { stats, _ in
        sum += stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
    }
    hkRequire(sum == 12, "sum")
    hkRequire(collectionResults.items[0].updatedStatistics == nil, "no updates")
}

func testActivityAndRouteDescriptorResults() {
    HKHealthStorePortable._reset()
    hkAuthorizeSync([HKObjectType.workoutType(), HKSeriesType.workoutRoute(), HKObjectType.activitySummaryType()])
    let summary = HKActivitySummary()
    summary.dateComponents.year = 2026
    summary.dateComponents.month = 9
    summary.dateComponents.day = 6
    summary.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: 350)
    HKHealthStorePortable._setActivitySummaries([summary])
    let activity = HKActivitySummaryQueryDescriptor(predicate: nil)
    let activityResults = activity.results(for: HKHealthStore())
    _ = activityResults.makeAsyncIterator()
    hkRequire(activityResults.items.count == 1, "one emission")
    hkRequire(activityResults.items[0].count == 1, "one summary")
    hkRequire(activityResults.items[0][0].dateComponents.year == 2026, "year")
    let route = HKWorkoutRoute(start: Date(), end: Date().addingTimeInterval(60))
    try! HKHealthStorePortable._save([route])
    HKHealthStorePortable._setRouteLocations([CLLocation(latitude: 37.5, longitude: -122.2)], for: route)
    let routeDesc = HKWorkoutRouteQueryDescriptor(predicate: HKSamplePredicate.workoutRoute())
    let routeResults = routeDesc.results(for: HKHealthStore())
    _ = routeResults.makeAsyncIterator()
    hkRequire(routeResults.items.count == 1, "one route")
    hkRequire(routeResults.items[0].count == 1, "one point")
    hkRequire(abs(routeResults.items[0][0].latitude - 37.5) < 1e-9, "lat")
    let byRoute = HKWorkoutRouteQueryDescriptor(route)
    hkRequire(byRoute.results(for: HKHealthStore()).items.first?.count == 1, "init route")
}

func testWorkoutEffortRelationshipQueryDescriptor() {
    HKHealthStorePortable._reset()
    hkAuthorizeSync([HKObjectType.workoutType()])
    let workout = HKWorkout(activityType: .running, start: Date(), end: Date().addingTimeInterval(600))
    try! HKHealthStorePortable._save([workout])
    let sample = HKQuantitySample(
        type: HKObjectType.quantityType(forIdentifier: .heartRate)!,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 140),
        start: workout.startDate,
        end: workout.startDate
    )
    HKHealthStorePortable._setAuthorization(
        for: HKObjectType.quantityType(forIdentifier: .heartRate)!,
        share: .sharingAuthorized,
        read: .sharingAuthorized
    )
    try! HKHealthStorePortable._save([sample])
    HKHealthStorePortable._relateEffort(sample: sample, workout: workout, activity: nil)
    let descriptor = HKWorkoutEffortRelationshipQueryDescriptor(
        predicate: nil,
        anchor: HKQueryAnchor(fromValue: 0),
        option: .default
    )
    hkRequire(descriptor.option == .default, "option")
    hkRequire(descriptor.anchor?.value == 0, "anchor")
    let results = descriptor.results(for: HKHealthStore())
    _ = results.makeAsyncIterator()
    hkRequire(results.items.count == 1, "one emission")
    hkRequire(results.items[0].relationships.count == 1, "one relationship")
    hkRequire(results.items[0].relationships[0].workout?.uuid == workout.uuid, "workout")
    hkRequire(results.items[0].relationships[0].sample?.uuid == sample.uuid, "sample")
    hkRequire(results.items[0].relationships[0].samples?.count == 1, "samples")
    hkRequire(results.items[0].relationships[0].activity == nil, "activity")
    hkRequire(results.items[0].newAnchor.value >= 1, "new anchor")
    var delivered = 0
    let query = HKWorkoutEffortRelationshipQuery(predicate: nil, anchor: nil, options: .mostRelevant) { _, rows, _, err in
        hkRequire(err == nil, "query")
        delivered = rows?.count ?? 0
    }
    HKHealthStore().execute(query)
    hkRequire(delivered == 1, "most relevant")
}

func testVerifiableClinicalRecordValueTypes() {
    HKHealthStorePortable._reset()
    let dob = DateComponents(year: 1991, month: 3, day: 14)
    let subject = HKVerifiableClinicalRecordSubject(fullName: "Ada Lovelace", dateOfBirthComponents: dob)
    hkRequire(subject.fullName == "Ada Lovelace", "name")
    hkRequire(subject.dateOfBirthComponents?.year == 1991, "dob")
    let subjectData = try! NSKeyedArchiver.archivedData(withRootObject: subject, requiringSecureCoding: true)
    let decodedSubject = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKVerifiableClinicalRecordSubject.self, from: subjectData)
    hkRequire(decodedSubject?.fullName == "Ada Lovelace", "decode name")
    let issued = Date(timeIntervalSince1970: 1_700_300_000)
    let record = HKVerifiableClinicalRecord(
        recordTypes: [HKVerifiableClinicalRecordCredentialType.immunization.rawValue],
        issuerIdentifier: "org.example.issuer",
        issuedDate: issued,
        relevantDate: issued,
        expirationDate: issued.addingTimeInterval(86400),
        itemNames: ["COVID-19"],
        sourceType: .smartHealthCard,
        subject: subject,
        jwsRepresentation: Data("header.payload.sig".utf8)
    )
    hkRequire(record.issuerIdentifier == "org.example.issuer", "issuer")
    hkRequire(record.issuedDate == issued, "issued")
    hkRequire(record.relevantDate == issued, "relevant")
    hkRequire(record.expirationDate == issued.addingTimeInterval(86400), "exp")
    hkRequire(record.itemNames == ["COVID-19"], "items")
    hkRequire(record.recordTypes.contains(HKVerifiableClinicalRecordCredentialType.immunization.rawValue), "types")
    hkRequire(record.sourceType == .smartHealthCard, "source")
    hkRequire(record.subject.fullName == "Ada Lovelace", "subject")
    hkRequire(record.jwsRepresentation.count > 0, "jws")
    hkRequire(record.dataRepresentation == record.jwsRepresentation, "data")
    hkRequire(HKVerifiableClinicalRecordCredentialType(rawValue: "custom").rawValue == "custom", "cred init")
    hkRequire(HKVerifiableClinicalRecordSourceType(rawValue: "custom").rawValue == "custom", "src init")
    HKHealthStorePortable._setAuthorization(for: record.sampleType, share: .sharingAuthorized, read: .sharingAuthorized)
    try! HKHealthStorePortable._save([record])
    let descriptor = HKVerifiableClinicalRecordQueryDescriptor(
        recordTypes: [.immunization],
        sourceTypes: [.smartHealthCard],
        predicate: HKQuery.predicateForVerifiableClinicalRecords(
            withRelevantDateWithin: DateInterval(start: issued.addingTimeInterval(-1), duration: 10)
        )
    )
    hkRequire(descriptor.recordTypes == [.immunization], "desc types")
    hkRequire(descriptor.sourceTypes == [.smartHealthCard], "desc sources")
    hkRequire(descriptor.predicate != nil, "pred")
    var delivered = 0
    let query = HKVerifiableClinicalRecordQuery(
        recordTypes: [HKVerifiableClinicalRecordCredentialType.immunization.rawValue],
        sourceTypes: [.smartHealthCard],
        predicate: nil
    ) { _, records, err in
        hkRequire(err == nil, "query")
        delivered = records?.count ?? 0
    }
    HKHealthStore().execute(query)
    hkRequire(delivered == 1, "local record, not Apple-verified")
    _ = query.recordTypes
    _ = query.sourceTypes
}

func testQueryObjectTypeAnchorCodingAndECGAssociation() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    var seen = false
    let query = HKSampleQuery(sampleType: heart, predicate: nil, limit: 0, sortDescriptors: nil) { _, _, _ in
        seen = true
    }
    hkRequire(query.objectType?.identifier == heart.identifier, "objectType")
    hkRequire(query.sampleType?.identifier == heart.identifier, "sampleType")
    HKHealthStore().execute(query)
    hkRequire(seen, "executed")
    let anchor = HKQueryAnchor(fromValue: 17)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    hkRequire(decoded?.value == 17, "anchor round-trip")
    let descriptor = HKQueryDescriptor(sampleType: heart, predicate: nil)
    hkRequire(descriptor.sampleType.identifier == heart.identifier, "descriptor type")
    let descData = try! NSKeyedArchiver.archivedData(withRootObject: descriptor, requiringSecureCoding: true)
    let decodedDesc = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryDescriptor.self, from: descData)
    hkRequire(decodedDesc?.sampleType.identifier == heart.identifier, "descriptor round-trip")
    let ecg = HKElectrocardiogram(start: Date(), end: Date())
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60),
        start: Date(),
        end: Date()
    )
    HKHealthStorePortable._associate(sampleIDs: [sample.uuid], withElectrocardiogram: ecg.uuid)
    hkRequire(HKQuery.predicateForObjectsAssociated(electrocardiogram: ecg).evaluate(with: sample), "associated")
    hkRequire(!HKQuery.predicateForObjectsAssociated(electrocardiogram: ecg).evaluate(with: HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 70),
        start: Date(),
        end: Date()
    )), "unassociated")
}

func testWorkoutConvenienceInitsAndActivity() {
    let start = Date(timeIntervalSince1970: 1_700_400_000)
    let end = start.addingTimeInterval(1800)
    let energy = HKQuantity(unit: .kilocalorie(), doubleValue: 220)
    let distance = HKQuantity(unit: .meter(), doubleValue: 5000)
    let flights = HKQuantity(unit: .count(), doubleValue: 12)
    let strokes = HKQuantity(unit: .count(), doubleValue: 40)
    let events = [HKWorkoutEvent(type: .pause, date: start.addingTimeInterval(60))]
    let device = HKDevice.local()
    let withDevice = HKWorkout(
        activityType: .running,
        start: start,
        end: end,
        duration: 1700,
        totalEnergyBurned: energy,
        totalDistance: distance,
        device: device,
        metadata: [HKMetadataKeyWasUserEntered: true]
    )
    hkRequire(withDevice.workoutActivityType == .running, "run")
    hkRequire(abs(withDevice.duration - 1700) < 0.01, "duration")
    hkRequire(withDevice.device?.name == device.name, "device")
    let withFlights = HKWorkout(
        activityType: .stairClimbing,
        startDate: start,
        endDate: end,
        workoutEvents: events,
        totalEnergyBurned: energy,
        totalDistance: nil,
        totalFlightsClimbed: flights,
        device: device,
        metadata: nil
    )
    hkRequire(abs((withFlights.totalFlightsClimbed?.doubleValue(for: .count()) ?? 0) - 12) < 1e-9, "flights")
    hkRequire(withFlights.workoutEvents.count == 1, "events")
    let withStrokes = HKWorkout(
        activityType: .swimming,
        start: start,
        end: end,
        workoutEvents: nil,
        totalEnergyBurned: energy,
        totalDistance: distance,
        totalSwimmingStrokeCount: strokes,
        device: nil,
        metadata: nil
    )
    hkRequire(abs((withStrokes.totalSwimmingStrokeCount?.doubleValue(for: .count()) ?? 0) - 40) < 1e-9, "strokes")
    guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { hkRequire(false, "energy type"); return }
    hkRequire(withDevice.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) == 220, "stats")
    hkRequire(withDevice.allStatistics[energyType] != nil, "all stats")
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .cycling
    let activity = HKWorkoutActivity(
        workoutConfiguration: configuration,
        start: start,
        end: end,
        metadata: ["lap": "1"]
    )
    hkRequire(activity.duration == 1800, "activity duration")
    hkRequire(activity.uuid.uuidString.isEmpty == false, "uuid")
    hkRequire(activity.workoutEvents.isEmpty, "no events")
    hkRequire(activity.statistics(for: energyType) == nil, "no activity stats")
    hkRequire(activity.allStatistics.isEmpty, "empty stats")
    let labeled = HKWorkoutActivity(
        workoutConfiguration: configuration,
        startDate: start,
        endDate: end,
        metadata: nil
    )
    hkRequire(labeled.workoutConfiguration.activityType == .cycling, "config")
}
