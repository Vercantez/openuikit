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

func testFHIRVersionParsingAndCoding() {
    let dstu2 = HKFHIRVersion.primaryDSTU2()
    hkRequire(dstu2.majorVersion == 1, "dstu2 major")
    hkRequire(dstu2.minorVersion == 0, "dstu2 minor")
    hkRequire(dstu2.patchVersion == 2, "dstu2 patch")
    hkRequire(dstu2.fhirRelease == .dstu2, "dstu2 release")
    hkRequire(dstu2.stringRepresentation == "1.0.2", "dstu2 string")
    let r4 = HKFHIRVersion.primaryR4()
    hkRequire(r4.majorVersion == 4 && r4.minorVersion == 0 && r4.patchVersion == 1, "r4 4.0.1")
    hkRequire(r4.fhirRelease == .r4, "r4 release")
    hkRequire(r4.stringRepresentation == "4.0.1", "r4 string")
    let parsed = try! HKFHIRVersion(fromVersionString: "4.3.0")
    hkRequire(parsed.majorVersion == 4 && parsed.minorVersion == 3 && parsed.patchVersion == 0, "parsed")
    hkRequire(parsed.fhirRelease == .r4, "4.x is r4")
    let dstuParsed = try! HKFHIRVersion(fromVersionString: "1.0.1")
    hkRequire(dstuParsed.fhirRelease == .dstu2, "1.x is dstu2")
    do {
        _ = try HKFHIRVersion(fromVersionString: "not-a-version")
        hkRequire(false, "invalid version must throw")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "invalid version")
    }
    let data = try! NSKeyedArchiver.archivedData(withRootObject: r4, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKFHIRVersion.self, from: data)
    hkRequire(decoded == r4, "round trip")
    let resource = HKFHIRResource()
    resource.fhirVersion = r4
    hkRequire(resource.fhirVersion.stringRepresentation == "4.0.1", "resource version")
}

func testAudiogramSensitivityPointAndTests() {
    let hz = HKQuantity(unit: .hertz(), doubleValue: 1000)
    let left = HKQuantity(unit: .decibelHearingLevel(), doubleValue: 15)
    let right = HKQuantity(unit: .decibelHearingLevel(), doubleValue: 20)
    let point = try! HKAudiogramSensitivityPoint(
        frequency: hz,
        leftEarSensitivity: left,
        rightEarSensitivity: right
    )
    hkRequire(abs(point.frequency.doubleValue(for: .hertz()) - 1000) < 1e-9, "freq")
    hkRequire(abs((point.leftEarSensitivity?.doubleValue(for: .decibelHearingLevel()) ?? 0) - 15) < 1e-9, "left")
    hkRequire(abs((point.rightEarSensitivity?.doubleValue(for: .decibelHearingLevel()) ?? 0) - 20) < 1e-9, "right")
    hkRequire(point.tests.count == 2, "two tests")
    do {
        _ = try HKAudiogramSensitivityPoint(
            frequency: HKQuantity(unit: .meter(), doubleValue: 1),
            leftEarSensitivity: left,
            rightEarSensitivity: nil
        )
        hkRequire(false, "bad frequency unit")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "freq unit")
    }
    let range = try! HKAudiogramSensitivityPointClampingRange(
        lowerBound: NSNumber(value: 0),
        upperBound: NSNumber(value: 40)
    )
    hkRequire(abs((range.lowerBound?.doubleValue(for: .decibelHearingLevel()) ?? -1)) < 1e-9, "lower")
    hkRequire(abs((range.upperBound?.doubleValue(for: .decibelHearingLevel()) ?? 0) - 40) < 1e-9, "upper")
    do {
        _ = try HKAudiogramSensitivityPointClampingRange(lowerBound: 10, upperBound: 1)
        hkRequire(false, "inverted range")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "range")
    }
    let test = try! HKAudiogramSensitivityTest(
        sensitivity: left,
        type: .air,
        masked: true,
        side: .left,
        clampingRange: range
    )
    hkRequire(test.type == .air, "air")
    hkRequire(test.side == .left, "side")
    hkRequire(test.masked, "masked")
    hkRequire(test.clampingRange != nil, "clamp")
    hkRequire(HKAudiogramSensitivityTestSide(rawValue: 1) == .right, "side raw")
    let fromTests = try! HKAudiogramSensitivityPoint(frequency: hz, tests: [test])
    hkRequire(fromTests.tests.count == 1, "one test")
    hkRequire(fromTests.leftEarSensitivity != nil, "left from tests")
    let start = Date(timeIntervalSince1970: 1_710_000_000)
    let sample = HKAudiogramSample(
        sensitivityPoints: [point],
        start: start,
        end: start.addingTimeInterval(60),
        metadata: nil
    )
    hkRequire(sample.sensitivityPoints.count == 1, "sample points")
    let withDevice = HKAudiogramSample(
        sensitivityPoints: [point],
        startDate: start,
        endDate: start.addingTimeInterval(30),
        device: .local(),
        metadata: [HKMetadataKeyWasUserEntered: true]
    )
    hkRequire(withDevice.device?.name == "linux", "device")
    let data = try! NSKeyedArchiver.archivedData(withRootObject: point, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKAudiogramSensitivityPoint.self, from: data)
    hkRequire(abs((decoded?.frequency.doubleValue(for: .hertz()) ?? 0) - 1000) < 1e-9, "decode freq")
}

func testDiscreteQuantitySampleAggregates() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    let unit = HKUnit.count().unitDivided(by: .minute())
    let start = Date(timeIntervalSince1970: 1_711_000_000)
    let sample = HKDiscreteQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: unit, doubleValue: 70),
        start: start,
        end: start.addingTimeInterval(120)
    )
    hkRequire(abs(sample.averageQuantity.doubleValue(for: unit) - 70) < 1e-9, "single avg")
    hkRequire(abs(sample.minimumQuantity.doubleValue(for: unit) - 70) < 1e-9, "single min")
    hkRequire(abs(sample.maximumQuantity.doubleValue(for: unit) - 70) < 1e-9, "single max")
    hkRequire(abs(sample.mostRecentQuantity.doubleValue(for: unit) - 70) < 1e-9, "single recent")
    hkRequire(sample.mostRecentQuantityDateInterval.duration == 120, "interval")
    HKHealthStorePortable._setQuantitySeries(
        [
            (HKQuantity(unit: unit, doubleValue: 60), DateInterval(start: start, duration: 60)),
            (HKQuantity(unit: unit, doubleValue: 80), DateInterval(start: start.addingTimeInterval(60), duration: 60))
        ],
        for: sample
    )
    hkRequire(abs(sample.minimumQuantity.doubleValue(for: unit) - 60) < 1e-9, "series min")
    hkRequire(abs(sample.maximumQuantity.doubleValue(for: unit) - 80) < 1e-9, "series max")
    hkRequire(abs(sample.averageQuantity.doubleValue(for: unit) - 70) < 1e-9, "series avg")
    hkRequire(abs(sample.mostRecentQuantity.doubleValue(for: unit) - 80) < 1e-9, "series recent")
    hkRequire(sample.mostRecentQuantityDateInterval.duration == 60, "last interval")
}

func testGlassesLensSpecificationAndPrescription() {
    let sphere = HKQuantity(unit: .diopter(), doubleValue: -2.5)
    let cylinder = HKQuantity(unit: .diopter(), doubleValue: -0.75)
    let axis = HKQuantity(unit: .degreeAngle(), doubleValue: 90)
    let add = HKQuantity(unit: .diopter(), doubleValue: 1.25)
    let vertex = HKQuantity(unit: .meterUnit(with: .milli), doubleValue: 12)
    let farPD = HKQuantity(unit: .meterUnit(with: .milli), doubleValue: 62)
    let nearPD = HKQuantity(unit: .meterUnit(with: .milli), doubleValue: 58)
    let prism = HKVisionPrism(
        amount: HKQuantity(unit: .prismDiopter(), doubleValue: 1),
        angle: HKQuantity(unit: .degreeAngle(), doubleValue: 0),
        eye: .left
    )
    let lens = HKGlassesLensSpecification(
        sphere: sphere,
        cylinder: cylinder,
        axis: axis,
        addPower: add,
        vertexDistance: vertex,
        prism: prism,
        farPupillaryDistance: farPD,
        nearPupillaryDistance: nearPD
    )
    hkRequire(abs((lens.sphere?.doubleValue(for: .diopter()) ?? 0) + 2.5) < 1e-9, "sphere")
    hkRequire(abs((lens.cylinder?.doubleValue(for: .diopter()) ?? 0) + 0.75) < 1e-9, "cyl")
    hkRequire(abs((lens.axis?.doubleValue(for: .degreeAngle()) ?? 0) - 90) < 1e-9, "axis")
    hkRequire(abs((lens.addPower?.doubleValue(for: .diopter()) ?? 0) - 1.25) < 1e-9, "add")
    hkRequire(abs((lens.vertexDistance?.doubleValue(for: .meterUnit(with: .milli)) ?? 0) - 12) < 1e-9, "vertex")
    hkRequire(lens.prism?.eye == .left, "prism")
    hkRequire(abs((lens.farPupillaryDistance?.doubleValue(for: .meterUnit(with: .milli)) ?? 0) - 62) < 1e-9, "far")
    hkRequire(abs((lens.nearPupillaryDistance?.doubleValue(for: .meterUnit(with: .milli)) ?? 0) - 58) < 1e-9, "near")
    let issued = Date(timeIntervalSince1970: 1_712_000_000)
    let prescription = HKGlassesPrescription(
        rightEyeSpecification: lens,
        leftEyeSpecification: lens,
        dateIssued: issued,
        expirationDate: issued.addingTimeInterval(31_536_000),
        device: .local(),
        metadata: nil
    )
    hkRequire(prescription.rightEye != nil && prescription.leftEye != nil, "both eyes")
    hkRequire(prescription.prescriptionType == .glasses, "glasses type")
    hkRequire(prescription.dateIssued == issued, "issued")
}

func testMedicationDoseEventValueType() {
    hkRequire(HKMedicationDoseEvent.LogStatus.notInteracted.rawValue == 1, "notInteracted")
    hkRequire(HKMedicationDoseEvent.LogStatus.notificationNotSent.rawValue == 2, "notif")
    hkRequire(HKMedicationDoseEvent.LogStatus.snoozed.rawValue == 3, "snoozed")
    hkRequire(HKMedicationDoseEvent.LogStatus.taken.rawValue == 4, "taken")
    hkRequire(HKMedicationDoseEvent.LogStatus.skipped.rawValue == 5, "skipped")
    hkRequire(HKMedicationDoseEvent.LogStatus.notLogged.rawValue == 6, "notLogged")
    hkRequire(HKMedicationDoseEvent.ScheduleType.asNeeded.rawValue == 1, "asNeeded")
    hkRequire(HKMedicationDoseEvent.ScheduleType.schedule.rawValue == 2, "schedule")
    hkRequire(HKMedicationDoseEvent.LogStatus(rawValue: 4) == .taken, "raw init")
    hkRequire(HKMedicationDoseEvent.ScheduleType(rawValue: 2) == .schedule, "sched raw")
    let concept = HKHealthConceptIdentifier(identifier: "med.aspirin")
    let start = Date(timeIntervalSince1970: 1_713_000_000)
    let event = HKMedicationDoseEvent(
        medicationConceptIdentifier: concept,
        logStatus: .taken,
        scheduleType: .schedule,
        scheduledDate: start,
        scheduledDoseQuantity: 2,
        doseQuantity: 1.5,
        unit: .count(),
        start: start,
        end: start
    )
    hkRequire(event.logStatus == .taken, "status")
    hkRequire(event.scheduleType == .schedule, "type")
    hkRequire(event.scheduledDate == start, "scheduled")
    hkRequire(event.doseQuantity == 1.5, "dose")
    hkRequire(event.scheduledDoseQuantity == 2, "scheduled dose")
    hkRequire(event.unit.`is`(compatibleWith: .count()), "unit")
    hkRequire(event.medicationConceptIdentifier.identifier == "med.aspirin", "concept")
    hkRequire(event.medicationDoseEventType.identifier == HKMedicationDoseEventTypeIdentifierMedicationDoseEvent, "type id")
    hkRequire(HKObjectType.medicationDoseEventType().identifier == event.sampleType.identifier, "object type")
}

func testSampleTypeDurationRestrictions() {
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    let workout = HKObjectType.workoutType()
    hkRequire(heart.isMaximumDurationRestricted, "heart max restricted")
    hkRequire(abs(heart.maximumAllowedDuration - 7 * 24 * 3600) < 1e-9, "seven days")
    hkRequire(!heart.isMinimumDurationRestricted, "no min")
    hkRequire(heart.minimumAllowedDuration == 0, "min 0")
    hkRequire(!workout.isMaximumDurationRestricted, "workout unrestricted")
    hkRequire(workout.maximumAllowedDuration == 0, "workout max 0")
    hkRequire(HKSeriesType.heartbeat().isMaximumDurationRestricted == false, "series")
    hkRequire(steps.allowsRecalibrationForEstimates == false, "steps not estimate")
    guard let walking = HKObjectType.quantityType(forIdentifier: .appleWalkingSteadiness) else {
        hkRequire(HKQuantityType(identifier: "HKQuantityTypeIdentifierAppleWalkingSteadiness").allowsRecalibrationForEstimates, "walking estimate")
        return
    }
    hkRequire(walking.allowsRecalibrationForEstimates, "walking estimate")
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60),
        start: Date(),
        end: Date()
    )
    hkRequire(sample.sampleType.identifier == heart.identifier, "sampleType")
}

func testAppleWalkingSteadinessClassification() {
    hkRequire(HKAppleWalkingSteadinessClassification.ok.rawValue == 1, "ok raw")
    hkRequire(HKAppleWalkingSteadinessClassification.low.rawValue == 2, "low raw")
    hkRequire(HKAppleWalkingSteadinessClassification.veryLow.rawValue == 3, "veryLow raw")
    hkRequire(HKAppleWalkingSteadinessClassification(rawValue: 2) == .low, "raw init")
    hkRequire(Set(HKAppleWalkingSteadinessClassification.allCases) == [.ok, .low, .veryLow], "allCases")
    let _ : HKAppleWalkingSteadinessClassification.AllCases = HKAppleWalkingSteadinessClassification.allCases
    let ok = try! HKAppleWalkingSteadinessClassification(for: HKQuantity(unit: .percent(), doubleValue: 0.8))
    hkRequire(ok == .ok, "0.8 ok")
    let low = try! HKAppleWalkingSteadinessClassification(for: HKQuantity(unit: .percent(), doubleValue: 0.6))
    hkRequire(low == .low, "0.6 low")
    let veryLow = try! HKAppleWalkingSteadinessClassification(for: HKQuantity(unit: .percent(), doubleValue: 0.2))
    hkRequire(veryLow == .veryLow, "0.2 veryLow")
    hkRequire(abs(ok.minimum.doubleValue(for: .percent()) - 0.75) < 1e-9, "ok min")
    hkRequire(abs(ok.maximum.doubleValue(for: .percent()) - 1.0) < 1e-9, "ok max")
    hkRequire(abs(low.minimum.doubleValue(for: .percent()) - 0.50) < 1e-9, "low min")
    hkRequire(abs(veryLow.maximum.doubleValue(for: .percent()) - 0.50) < 1e-9, "veryLow max")
    do {
        _ = try HKAppleWalkingSteadinessClassification(for: HKQuantity(unit: .count(), doubleValue: 1))
        hkRequire(false, "incompatible")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "unit")
    }
    do {
        _ = try HKAppleWalkingSteadinessClassification(for: HKQuantity(unit: .percent(), doubleValue: 1.5))
        hkRequire(false, "out of range")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "range")
    }
}

func testQueryExecuteStopAndDescriptorInits() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    hkAuthorizeSync([heart])
    let store = HKHealthStore()
    let t0 = Date(timeIntervalSince1970: 1_714_000_000)
    let unit = HKUnit.count().unitDivided(by: .minute())
    let hr = HKQuantitySample(type: heart, quantity: HKQuantity(unit: unit, doubleValue: 64), start: t0, end: t0)
    try! HKHealthStorePortable._save([hr])
    let descriptor = HKQueryDescriptor(sampleType: heart, predicate: nil)
    var descriptorCount = -1
    store.execute(HKSampleQuery(queryDescriptors: [descriptor], limit: HKObjectQueryNoLimit) { _, samples, err in
        hkRequire(err == nil, "desc query")
        descriptorCount = samples?.count ?? 0
    })
    hkRequire(descriptorCount == 1, "descriptor init")
    var sortedCount = -1
    store.execute(HKSampleQuery(
        queryDescriptors: [descriptor],
        limit: 1,
        sortDescriptors: [NSSortDescriptor(keyPath: \HKSample.startDate, ascending: true)]
    ) { _, samples, err in
        hkRequire(err == nil, "sorted")
        sortedCount = samples?.count ?? 0
    })
    hkRequire(sortedCount == 1, "sorted descriptors")
    var stopped = false
    let observer = HKObserverQuery(queryDescriptors: [descriptor]) { _, types, completion, err in
        hkRequire(err == nil, "observer")
        hkRequire(types?.contains(heart) == true, "observer types")
        stopped = true
        completion()
    }
    store.execute(observer)
    hkRequire(stopped, "observer descriptors fired")
    store.stop(observer)
    hkRequire(true, "stop")
}

func testAnchoredObserverSourceCorrelationAndDocumentQueries() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    guard let bp = HKObjectType.correlationType(forIdentifier: .bloodPressure) else { hkRequire(false, "bp"); return }
    let documentType = HKObjectType.documentType(forIdentifier: .CDA) ?? HKDocumentType(identifier: HKDocumentTypeIdentifier.CDA.rawValue)
    hkAuthorizeSync([heart, bp, documentType])
    let store = HKHealthStore()
    let t0 = Date(timeIntervalSince1970: 1_715_000_000)
    let unit = HKUnit.count().unitDivided(by: .minute())
    let hr = HKQuantitySample(type: heart, quantity: HKQuantity(unit: unit, doubleValue: 70), start: t0, end: t0)
    try! HKHealthStorePortable._save([hr])
    var anchored = 0
    store.execute(HKAnchoredObjectQuery(
        type: heart,
        predicate: nil,
        anchor: nil as HKQueryAnchor?,
        limit: HKObjectQueryNoLimit
    ) { _, samples, _, _, err in
        hkRequire(err == nil, "anchored results")
        anchored = samples?.count ?? 0
    })
    hkRequire(anchored == 1, "anchored resultsHandler")
    var completionCount = 0
    store.execute(HKAnchoredObjectQuery(
        type: heart,
        predicate: nil,
        anchor: Int(HKAnchoredObjectQueryNoAnchor),
        limit: 10
    ) { _, samples, _, err in
        hkRequire(err == nil, "completion")
        completionCount = samples?.count ?? 0
    })
    hkRequire(completionCount == 1, "anchored completionHandler")
    var updateFired = false
    let updating = HKAnchoredObjectQuery(
        queryDescriptors: [HKQueryDescriptor(sampleType: heart, predicate: nil)],
        anchor: HKQueryAnchor(fromValue: 0),
        limit: 5
    ) { _, samples, _, _, err in
        hkRequire(err == nil, "desc anchored")
        updateFired = (samples?.count ?? 0) == 1
    }
    updating.updateHandler = { _, _, _, _, _ in }
    store.execute(updating)
    hkRequire(updateFired, "queryDescriptors anchored")
    hkRequire(updating.updateHandler != nil, "updateHandler stored")
    var sources = 0
    store.execute(HKSourceQuery(sampleType: heart, samplePredicate: nil) { _, set, err in
        hkRequire(err == nil, "source")
        sources = set?.count ?? 0
    })
    hkRequire(sources >= 1, "source query")
    let xml = """
    <ClinicalDocument>
      <title>Discharge</title>
      <given>Ada</given>
      <family>Lovelace</family>
    </ClinicalDocument>
    """
    let cda = try! HKCDADocumentSample(
        data: Data(xml.utf8),
        start: t0,
        end: t0,
        metadata: nil
    )
    hkRequire(cda.document?.title == "Discharge", "title")
    hkRequire(cda.document?.patientName == "Ada Lovelace", "patient")
    hkRequire(cda.document?.documentData != nil, "payload")
    try! HKHealthStorePortable._save([cda])
    var docs = 0
    var included = false
    store.execute(HKDocumentQuery(
        documentType: documentType,
        predicate: nil,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: nil,
        includeDocumentData: true
    ) { query, samples, err in
        hkRequire(err == nil, "doc query")
        hkRequire(query.includeDocumentData, "include flag")
        hkRequire(query.limit == 0, "no limit")
        docs = samples?.count ?? 0
        included = (samples?.first as? HKCDADocumentSample)?.document?.documentData != nil
    })
    hkRequire(docs == 1, "one document")
    hkRequire(included, "document data included")
    let systolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
    let diastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    hkAuthorizeSync([systolic, diastolic])
    let corr = HKCorrelation(
        type: bp,
        start: t0,
        end: t0,
        objects: Set([
            HKQuantitySample(type: systolic, quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 120), start: t0, end: t0),
            HKQuantitySample(type: diastolic, quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 80), start: t0, end: t0)
        ])
    )
    try! HKHealthStorePortable._save([corr])
    var corrCount = 0
    store.execute(HKCorrelationQuery(type: bp, predicate: nil, samplePredicates: nil) { _, samples, err in
        hkRequire(err == nil, "corr")
        corrCount = samples?.count ?? 0
    })
    hkRequire(corrCount == 1, "one correlation")
}

func testCDADocumentParsing() {
    let xml = """
    <ClinicalDocument>
      <title>Consult</title>
      <given>Grace</given>
      <family>Hopper</family>
      <authorName>Dr. Kay</authorName>
      <custodianName>Navy Hospital</custodianName>
    </ClinicalDocument>
    """
    let document = try! HKCDADocument.parse(Data(xml.utf8))
    hkRequire(document.title == "Consult", "title")
    hkRequire(document.patientName == "Grace Hopper", "patient")
    hkRequire(document.authorName == "Dr. Kay", "author")
    hkRequire(document.custodianName == "Navy Hospital", "custodian")
    hkRequire(document.documentData != nil, "data")
    do {
        _ = try HKCDADocument.parse(Data("<note>not cda</note>".utf8))
        hkRequire(false, "must reject")
    } catch {
        hkRequire(HKError.Code.errorInvalidArgument ~= error, "invalid")
    }
    let start = Date(timeIntervalSince1970: 1_716_000_000)
    let sample = try! HKCDADocumentSample(
        data: Data(xml.utf8),
        startDate: start,
        endDate: start,
        metadata: nil
    )
    hkRequire(sample.document?.title == "Consult", "sample document")
}

func testWorkoutBuilderElapsedStatisticsAndActivities() {
    HKHealthStorePortable._reset()
    hkAuthorizeSync([HKObjectType.workoutType()])
    guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { hkRequire(false, "energy"); return }
    hkAuthorizeSync([energyType])
    let store = HKHealthStore()
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .running
    let start = Date(timeIntervalSince1970: 1_717_000_000)
    let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
    var began = false
    builder.beginCollection(at: start) { success, err in
        hkRequire(success && err == nil, "begin")
        began = true
    }
    hkRequire(began, "began")
    hkRequire(abs(builder.elapsedTime(at: start.addingTimeInterval(90)) - 90) < 1e-9, "elapsed")
    let energy = HKQuantitySample(
        type: energyType,
        quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 50),
        start: start,
        end: start.addingTimeInterval(90)
    )
    var addedSamples = false
    builder.add([energy]) { success, err in
        hkRequire(success && err == nil, "add samples")
        addedSamples = true
    }
    hkRequire(addedSamples, "samples")
    hkRequire(builder.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) == 50, "stats")
    let activity = HKWorkoutActivity(workoutConfiguration: configuration, start: start, end: nil, metadata: ["lap": "1"])
    var addedActivity = false
    builder.addWorkoutActivity(activity) { success, err in
        hkRequire(success && err == nil, "activity")
        addedActivity = true
    }
    hkRequire(addedActivity, "activity added")
    var updatedEnd = false
    builder.updateActivity(uuid: activity.uuid, end: start.addingTimeInterval(60)) { success, err in
        hkRequire(success && err == nil, "end activity")
        updatedEnd = true
    }
    hkRequire(updatedEnd, "ended activity")
    var updatedMeta = false
    builder.updateActivity(uuid: activity.uuid, adding: ["note": "ok"]) { success, err in
        hkRequire(success && err == nil, "meta")
        updatedMeta = true
    }
    hkRequire(updatedMeta, "meta added")
    let series = builder.seriesBuilder(for: .heartbeat())
    hkRequire(series?.seriesType.identifier == HKDataTypeIdentifierHeartbeatSeries, "series")
    builder.endCollection(at: start.addingTimeInterval(120)) { success, err in
        hkRequire(success && err == nil, "end collection")
    }
}

final class HKRecordingWorkoutSessionDelegate: NSObject, HKWorkoutSessionDelegate {
    var states: [(HKWorkoutSessionState, HKWorkoutSessionState)] = []
    var events: [HKWorkoutEvent] = []
    var began: [Date] = []
    var ended: [Date] = []
    var failures: [NSError] = []
    var remoteDisconnects = 0
    var remoteChunks: [[Data]] = []

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        _ = (workoutSession, date)
        states.append((fromState, toState))
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        _ = workoutSession
        failures.append(error as NSError)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        events.append(event)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didBeginActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date) {
        _ = workoutConfiguration
        began.append(date)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didEndActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date) {
        _ = workoutConfiguration
        ended.append(date)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: (any Error)?) {
        _ = error
        remoteDisconnects += 1
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        remoteChunks.append(data)
    }
}

func testWorkoutSessionStateMachineAndDelegate() {
    HKHealthStorePortable._reset()
    let store = HKHealthStore()
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .cycling
    configuration.locationType = .outdoor
    let session = try! HKWorkoutSession(healthStore: store, configuration: configuration)
    hkRequire(session.state == .notStarted, "not started")
    hkRequire(HKWorkoutSessionState(rawValue: 1) == .notStarted, "state raw")
    hkRequire(HKWorkoutSessionType(rawValue: 0) == .primary, "type raw")
    hkRequire(HKWorkoutSessionLocationType(rawValue: 3) == .outdoor, "location raw")
    let recorder = HKRecordingWorkoutSessionDelegate()
    session.delegate = recorder
    session.prepare()
    hkRequire(session.state == .prepared, "prepared")
    let start = Date(timeIntervalSince1970: 1_718_000_000)
    session.startActivity(with: start)
    hkRequire(session.state == .running, "running")
    hkRequire(session.startDate == start, "start date")
    hkRequire(recorder.began.count == 1, "didBegin")
    session.pause()
    hkRequire(session.state == .paused, "paused")
    hkRequire(recorder.events.contains(where: { $0.type == .pause }), "pause event")
    session.resume()
    hkRequire(session.state == .running, "resumed")
    let next = HKWorkoutConfiguration()
    next.activityType = .walking
    session.beginNewActivity(configuration: next, date: start.addingTimeInterval(30), metadata: ["seg": "2"])
    hkRequire(session.currentActivity.workoutConfiguration.activityType == .walking, "current")
    session.endCurrentActivity(on: start.addingTimeInterval(90))
    hkRequire(session.currentActivity.endDate == start.addingTimeInterval(90), "ended activity")
    hkRequire(recorder.ended.count == 1, "didEnd")
    session.stopActivity(with: start.addingTimeInterval(120))
    hkRequire(session.state == .stopped, "stopped")
    session.end()
    hkRequire(session.state == .ended, "ended")
    hkRequire(recorder.states.contains(where: { $0.0 == .notStarted && $0.1 == .prepared }), "transition")
    let builder = session.associatedWorkoutBuilder()
    hkRequire(builder.workoutSession === session, "associated")
    hkRequire(session.associatedWorkoutBuilder() === builder, "same builder")
    var remoteFailed = false
    session.sendToRemoteWorkoutSession(data: Data("x".utf8)) { success, err in
        hkRequire(!success, "remote no success")
        hkRequire(HKError.Code.errorHealthDataUnavailable ~= err!, "watch pairing")
        remoteFailed = true
    }
    hkRequire(remoteFailed, "remote fail-closed")
    let remoteError = NSError(domain: HKErrorDomain, code: 1, userInfo: nil)
    recorder.workoutSession(session, didDisconnectFromRemoteDeviceWithError: remoteError)
    recorder.workoutSession(session, didReceiveDataFromRemoteWorkoutSession: [Data()])
    hkRequire(recorder.remoteDisconnects == 1, "disconnect")
    hkRequire(recorder.remoteChunks.count == 1, "remote data")
    let data = try! NSKeyedArchiver.archivedData(withRootObject: session, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKWorkoutSession.self, from: data)
    hkRequire(decoded != nil, "session coding")
}

func testLocalAttachmentStore() {
    HKHealthStorePortable._reset()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60),
        start: Date(),
        end: Date()
    )
    let store = HKAttachmentStore(healthStore: HKHealthStore())
    let payload = Data("ekg-note".utf8)
    let attachment = try! store.addAttachment(to: sample, name: "note.txt", data: payload, metadata: ["k": "v"])
    hkRequire(attachment.name == "note.txt", "name")
    hkRequire(attachment.size == payload.count, "size")
    hkRequire(attachment.identifier.uuidString.isEmpty == false, "id")
    hkRequire(attachment.creationDate.timeIntervalSince1970 > 0, "created")
    hkRequire(attachment.metadata?["k"] as? String == "v", "meta")
    var listed: [HKAttachment] = []
    store.getAttachments(for: sample) { attachments, err in
        hkRequire(err == nil, "list")
        listed = attachments ?? []
    }
    hkRequire(listed.count == 1, "one attachment")
    var loaded: Data?
    let progress = store.getData(for: attachment) { data, err in
        hkRequire(err == nil, "data")
        loaded = data
    }
    hkRequire(progress.isFinished || progress.completedUnitCount == 1, "progress")
    hkRequire(loaded == payload, "bytes")
    var streamed: Data?
    _ = store.streamData(for: attachment) { chunk, err, done in
        hkRequire(err == nil && done, "stream")
        streamed = chunk
    }
    hkRequire(streamed == payload, "streamed")
    let reader = store.dataReader(for: attachment)
    hkRequire(reader.attachment.identifier == attachment.identifier, "reader")
    hkRequire(reader.progress.totalUnitCount == 1, "reader progress")
    let archived = try! NSKeyedArchiver.archivedData(withRootObject: attachment, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKAttachment.self, from: archived)
    hkRequire(decoded?.name == "note.txt", "decode")
    var removed = false
    store.removeAttachment(attachment, from: sample) { success, err in
        hkRequire(success && err == nil, "remove")
        removed = true
    }
    hkRequire(removed, "removed")
    store.getAttachments(for: sample) { attachments, _ in
        hkRequire((attachments?.isEmpty) == true, "empty")
    }
}
