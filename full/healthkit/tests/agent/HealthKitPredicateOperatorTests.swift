import Foundation
import HealthKit

private func hkOpRequire(_ condition: Bool, _ message: String = "") {
    if !condition {
        fputs("HealthKit operator test failed: \(message)\n", stderr)
        exit(1)
    }
}

private func hkOpSleepSample(value: Int) -> HKCategorySample {
    HKCategorySample(
        type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        value: value,
        start: Date(),
        end: Date()
    )
}

private func hkOpCheckBase<T: HKCategoryValuePredicateProviding>(_ value: T) -> Bool where T.RawValue == Int {
    T.predicateForSamples(NSComparisonPredicate.Operator.equalTo, value: value)
        .evaluate(with: hkOpSleepSample(value: value.rawValue))
}

func testOperatorPredicateCategory() {
    typealias Op = NSComparisonPredicate.Operator
    let sleep = hkOpSleepSample(value: HKCategoryValueSleepAnalysis.asleepCore.rawValue)
    hkOpRequire(HKQuery.predicateForCategorySamples(with: Op.equalTo, value: HKCategoryValueSleepAnalysis.asleepCore.rawValue).evaluate(with: sleep), "category eq")
    hkOpRequire(!HKQuery.predicateForCategorySamples(with: Op.notEqualTo, value: HKCategoryValueSleepAnalysis.asleepCore.rawValue).evaluate(with: sleep), "category ne")
    hkOpRequire(HKQuery.predicateForCategorySamples(with: Op.greaterThan, value: 0).evaluate(with: sleep), "category gt")
    hkOpRequire(!HKQuery.predicateForCategorySamples(with: Op.lessThan, value: 0).evaluate(with: sleep), "category lt")
    hkOpRequire(!HKQuery.predicateForCategorySamples(with: Op.equalTo, value: 3).evaluate(with: HKObject()), "category wrong type")
    hkOpRequire(hkOpCheckBase(HKCategoryValueSleepAnalysis.asleepCore), "base protocol sleep")
    hkOpRequire(hkOpCheckBase(HKCategoryValueSeverity.mild), "base protocol severity")
    hkOpRequire(HKCategoryValue.predicateForSamples(Op.equalTo, value: .notApplicable).evaluate(with: hkOpSleepSample(value: 0)), "cat HKCategoryValue")
    hkOpRequire(HKCategoryValueAppetiteChanges.predicateForSamples(Op.equalTo, value: .decreased).evaluate(with: hkOpSleepSample(value: 2)), "cat appetite")
    hkOpRequire(HKCategoryValueAppleStandHour.predicateForSamples(Op.equalTo, value: .stood).evaluate(with: hkOpSleepSample(value: 0)), "cat stand")
    hkOpRequire(HKCategoryValueAppleWalkingSteadinessEvent.predicateForSamples(Op.equalTo, value: .initialLow).evaluate(with: hkOpSleepSample(value: 1)), "cat steadiness")
    hkOpRequire(HKCategoryValueCervicalMucusQuality.predicateForSamples(Op.equalTo, value: .creamy).evaluate(with: hkOpSleepSample(value: 3)), "cat mucus")
    hkOpRequire(HKCategoryValueContraceptive.predicateForSamples(Op.equalTo, value: .oral).evaluate(with: hkOpSleepSample(value: HKCategoryValueContraceptive.oral.rawValue)), "cat contraceptive")
    hkOpRequire(HKCategoryValueEnvironmentalAudioExposureEvent.predicateForSamples(Op.equalTo, value: .momentaryLimit).evaluate(with: hkOpSleepSample(value: 1)), "cat env audio")
    hkOpRequire(HKCategoryValueHeadphoneAudioExposureEvent.predicateForSamples(Op.equalTo, value: .sevenDayLimit).evaluate(with: hkOpSleepSample(value: 1)), "cat headphone")
    hkOpRequire(HKCategoryValueLowCardioFitnessEvent.predicateForSamples(Op.equalTo, value: .lowFitness).evaluate(with: hkOpSleepSample(value: HKCategoryValueLowCardioFitnessEvent.lowFitness.rawValue)), "cat cardio")
    hkOpRequire(HKCategoryValueMenstrualFlow.predicateForSamples(Op.equalTo, value: .light).evaluate(with: hkOpSleepSample(value: 2)), "cat flow")
    hkOpRequire(HKCategoryValueOvulationTestResult.predicateForSamples(Op.equalTo, value: .negative).evaluate(with: hkOpSleepSample(value: 1)), "cat ovulation")
    hkOpRequire(HKCategoryValuePregnancyTestResult.predicateForSamples(Op.equalTo, value: .positive).evaluate(with: hkOpSleepSample(value: 2)), "cat pregnancy")
    hkOpRequire(HKCategoryValuePresence.predicateForSamples(Op.equalTo, value: .present).evaluate(with: hkOpSleepSample(value: 0)), "cat presence")
    hkOpRequire(HKCategoryValueProgesteroneTestResult.predicateForSamples(Op.equalTo, value: .negative).evaluate(with: hkOpSleepSample(value: 1)), "cat progesterone")
    hkOpRequire(HKCategoryValueSeverity.predicateForSamples(Op.equalTo, value: .severe).evaluate(with: hkOpSleepSample(value: 4)), "cat severity")
    hkOpRequire(!HKCategoryValueSeverity.predicateForSamples(Op.equalTo, value: .severe).evaluate(with: hkOpSleepSample(value: 2)), "cat severity mismatch")
    hkOpRequire(HKCategoryValueSleepAnalysis.predicateForSamples(Op.equalTo, value: .asleepDeep).evaluate(with: hkOpSleepSample(value: 4)), "cat sleep")
    hkOpRequire(HKCategoryValueVaginalBleeding.predicateForSamples(Op.equalTo, value: .medium).evaluate(with: hkOpSleepSample(value: 3)), "cat bleeding")
}

func testOperatorPredicateQuantityAndMetadata() {
    typealias Op = NSComparisonPredicate.Operator
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else {
        hkOpRequire(false, "heart type")
        return
    }
    let unit = HKUnit.count().unitDivided(by: .minute())
    let now = Date()
    let sample = HKQuantitySample(type: heart, quantity: HKQuantity(unit: unit, doubleValue: 60), start: now, end: now)
    hkOpRequire(HKQuery.predicateForQuantitySamples(with: Op.greaterThan, quantity: HKQuantity(unit: unit, doubleValue: 50)).evaluate(with: sample), "qty gt")
    hkOpRequire(HKQuery.predicateForQuantitySamples(with: Op.equalTo, quantity: HKQuantity(unit: unit, doubleValue: 60)).evaluate(with: sample), "qty eq")
    hkOpRequire(!HKQuery.predicateForQuantitySamples(with: Op.lessThan, quantity: HKQuantity(unit: unit, doubleValue: 50)).evaluate(with: sample), "qty lt")
    hkOpRequire(!HKQuery.predicateForQuantitySamples(with: Op.equalTo, quantity: HKQuantity(unit: .meter(), doubleValue: 60)).evaluate(with: sample), "qty incompatible")
    hkOpRequire(!HKQuery.predicateForQuantitySamples(with: Op.equalTo, quantity: HKQuantity(unit: unit, doubleValue: 60)).evaluate(with: HKObject()), "qty wrong type")
    let flagged = HKObject(metadata: [HKMetadataKeyWasUserEntered: true])
    hkOpRequire(HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, operatorType: Op.equalTo, value: true).evaluate(with: flagged), "meta eq")
    hkOpRequire(!HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, operatorType: Op.notEqualTo, value: true).evaluate(with: flagged), "meta ne")
    hkOpRequire(!HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, operatorType: Op.equalTo, value: true).evaluate(with: HKObject()), "meta missing")
    let numbered = HKObject(metadata: ["hkOpCount": 5])
    hkOpRequire(HKQuery.predicateForObjects(withMetadataKey: "hkOpCount", operatorType: Op.greaterThan, value: 3).evaluate(with: numbered), "meta gt")
    hkOpRequire(!HKQuery.predicateForObjects(withMetadataKey: "hkOpCount", operatorType: Op.lessThan, value: 3).evaluate(with: numbered), "meta lt")
}

func testOperatorPredicateStatesOfMind() {
    typealias Op = NSComparisonPredicate.Operator
    let mind = HKStateOfMind(date: Date(), kind: .dailyMood, valence: 0.25, labels: [.happy], associations: [.community])
    hkOpRequire(HKQuery.predicateForStatesOfMind(withValence: 0.25, operatorType: Op.equalTo).evaluate(with: mind), "valence eq")
    hkOpRequire(HKQuery.predicateForStatesOfMind(withValence: 0.5, operatorType: Op.lessThan).evaluate(with: mind), "valence lt")
    hkOpRequire(!HKQuery.predicateForStatesOfMind(withValence: 0.25, operatorType: Op.greaterThan).evaluate(with: mind), "valence gt")
    hkOpRequire(!HKQuery.predicateForStatesOfMind(withValence: 0.25, operatorType: Op.equalTo).evaluate(with: HKObject()), "valence wrong type")
}

func testOperatorPredicateWorkoutActivities() {
    typealias Op = NSComparisonPredicate.Operator
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else {
        hkOpRequire(false, "heart type")
        return
    }
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .running
    let now = Date()
    let activity = HKWorkoutActivity(workoutConfiguration: configuration, start: now, end: now.addingTimeInterval(600))
    hkOpRequire(HKQuery.predicateForWorkoutActivities(operatorType: Op.greaterThan, duration: 60).evaluate(with: activity), "activity gt")
    hkOpRequire(!HKQuery.predicateForWorkoutActivities(operatorType: Op.lessThan, duration: 60).evaluate(with: activity), "activity lt")
    hkOpRequire(!HKQuery.predicateForWorkoutActivities(operatorType: Op.equalTo, duration: 60).evaluate(with: HKObject()), "activity wrong type")
    let qty = HKQuantity(unit: .count(), doubleValue: 1)
    hkOpRequire(HKQuery.predicateForWorkoutActivities(operatorType: Op.greaterThan, quantityType: heart, averageQuantity: qty).evaluate(with: activity), "activity avg")
    hkOpRequire(HKQuery.predicateForWorkoutActivities(operatorType: Op.greaterThan, quantityType: heart, maximumQuantity: qty).evaluate(with: activity), "activity max")
    hkOpRequire(HKQuery.predicateForWorkoutActivities(operatorType: Op.greaterThan, quantityType: heart, minimumQuantity: qty).evaluate(with: activity), "activity min")
    hkOpRequire(HKQuery.predicateForWorkoutActivities(operatorType: Op.greaterThan, quantityType: heart, sumQuantity: qty).evaluate(with: activity), "activity sum")
}

func testOperatorPredicateWorkouts() {
    typealias Op = NSComparisonPredicate.Operator
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else {
        hkOpRequire(false, "heart type")
        return
    }
    let now = Date()
    let workout = HKWorkout(
        activityType: .running,
        start: now,
        end: now.addingTimeInterval(3600),
        duration: 3600,
        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 200),
        totalDistance: HKQuantity(unit: .meter(), doubleValue: 5000),
        metadata: nil
    )
    hkOpRequire(HKQuery.predicateForWorkouts(with: Op.greaterThan, duration: 60).evaluate(with: workout), "workout duration gt")
    hkOpRequire(!HKQuery.predicateForWorkouts(with: Op.lessThan, duration: 60).evaluate(with: workout), "workout duration lt")
    hkOpRequire(HKQuery.predicateForWorkouts(with: Op.greaterThan, totalDistance: HKQuantity(unit: .meter(), doubleValue: 1000)).evaluate(with: workout), "workout distance")
    hkOpRequire(HKQuery.predicateForWorkouts(with: Op.equalTo, totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 200)).evaluate(with: workout), "workout energy")
    hkOpRequire(!HKQuery.predicateForWorkouts(with: Op.equalTo, totalDistance: HKQuantity(unit: .count(), doubleValue: 5000)).evaluate(with: workout), "workout incompatible")
    hkOpRequire(!HKQuery.predicateForWorkouts(with: Op.greaterThan, totalFlightsClimbed: HKQuantity(unit: .count(), doubleValue: 1)).evaluate(with: workout), "workout flights nil")
    hkOpRequire(!HKQuery.predicateForWorkouts(with: Op.greaterThan, totalSwimmingStrokeCount: HKQuantity(unit: .count(), doubleValue: 1)).evaluate(with: workout), "workout strokes nil")
    let energy = HKQuantity(unit: .kilocalorie(), doubleValue: 100)
    hkOpRequire(HKQuery.predicateForWorkouts(operatorType: Op.greaterThan, quantityType: heart, averageQuantity: energy).evaluate(with: workout), "workout avg")
    hkOpRequire(HKQuery.predicateForWorkouts(operatorType: Op.greaterThan, quantityType: heart, maximumQuantity: energy).evaluate(with: workout), "workout max")
    hkOpRequire(HKQuery.predicateForWorkouts(operatorType: Op.greaterThan, quantityType: heart, minimumQuantity: energy).evaluate(with: workout), "workout min")
    hkOpRequire(HKQuery.predicateForWorkouts(operatorType: Op.greaterThan, quantityType: heart, sumQuantity: energy).evaluate(with: workout), "workout sum")
}

func testAttachmentContentTypeAndFileURLAdd() {
    let store = HKAttachmentStore()
    let object = HKObject()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("hk-op-test-\(UUID().uuidString).bin")
    guard (try? Data([1, 2, 3, 4]).write(to: url)) != nil else {
        hkOpRequire(false, "write temp")
        return
    }
    defer { try? FileManager.default.removeItem(at: url) }
    var added: HKAttachment?
    var addError: (any Error)?
    store.addAttachment(to: object, name: "reading", contentType: .pdf, url: url, metadata: ["hkOp": "yes"]) { attachment, error in
        added = attachment
        addError = error
    }
    hkOpRequire(addError == nil, "file add error")
    hkOpRequire(added?.name == "reading", "file add name")
    hkOpRequire(added?.size == 4, "file add size")
    hkOpRequire(added?.contentType == .pdf, "file add content type")
    hkOpRequire(added?.metadata?["hkOp"] as? String == "yes", "file add metadata")
    var missingAttachment: HKAttachment?
    var missingError: (any Error)?
    store.addAttachment(to: object, name: "missing", contentType: .plainText, url: url.appendingPathComponent("nope.bin")) { attachment, error in
        missingAttachment = attachment
        missingError = error
    }
    hkOpRequire(missingAttachment == nil, "missing add nil")
    hkOpRequire(missingError != nil, "missing add error")
    guard let dataMade = try? store.addAttachment(to: object, name: "bytes", data: Data([9])) else {
        hkOpRequire(false, "data add")
        return
    }
    hkOpRequire(dataMade.contentType == .data, "data default content type")
}

func testAttachmentAsyncFileURLAdd() async throws {
    let store = HKAttachmentStore()
    let object = HKObject()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("hk-op-async-\(UUID().uuidString).bin")
    guard (try? Data([5, 6, 7, 8]).write(to: url)) != nil else {
        hkOpRequire(false, "write temp async")
        return
    }
    defer { try? FileManager.default.removeItem(at: url) }
    let added = try await store.addAttachment(to: object, name: "async-reading", contentType: .pdf, url: url, metadata: ["hkOp": "async"])
    hkOpRequire(added.name == "async-reading", "async add name")
    hkOpRequire(added.size == 4, "async add size")
    hkOpRequire(added.contentType == .pdf, "async add content type")
    hkOpRequire(added.metadata?["hkOp"] as? String == "async", "async add metadata")
    do {
        _ = try await store.addAttachment(to: object, name: "async-missing", contentType: .plainText, url: url.appendingPathComponent("nope.bin"))
        hkOpRequire(false, "async missing should throw")
    } catch {
    }
}
