import Foundation
import HealthKit

private func wave10Require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HealthKit wave-10 test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testClinicalCodingAndMedicationValues() {
    let coding = HKClinicalCoding(system: "http://www.nlm.nih.gov/research/umls/rxnorm", version: "2026-09", code: "1191")
    wave10Require(coding.system.hasSuffix("rxnorm") && coding.version == "2026-09" && coding.code == "1191", "coding fields")
    let archived = try! NSKeyedArchiver.archivedData(withRootObject: coding, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKClinicalCoding.self, from: archived)
    wave10Require(decoded == coding && decoded !== coding, "coding secure-copy value semantics")

    let identifier = HKHealthConceptIdentifier(identifier: "medication.aspirin")
    let concept = HKMedicationConcept(identifier: identifier, displayText: "Aspirin", generalForm: .tablet, relatedCodings: [coding])
    wave10Require(concept.identifier == identifier && concept.displayText == "Aspirin", "medication identity")
    wave10Require(concept.generalForm == .tablet && concept.relatedCodings == [coding], "medication coding")
    let medication = HKUserAnnotatedMedication(medication: concept, nickname: "morning", hasSchedule: true, isArchived: false)
    wave10Require(medication.medication === concept && medication.nickname == "morning", "annotated medication")
    wave10Require(medication.hasSchedule && !medication.isArchived, "annotated flags")
}

func testIdentifierWrapperRoundTrips() {
    wave10Require(HKCategoryTypeIdentifier(rawValue: "category").rawValue == "category", "category identifier")
    wave10Require(HKCharacteristicTypeIdentifier(rawValue: "characteristic").rawValue == "characteristic", "characteristic identifier")
    wave10Require(HKClinicalTypeIdentifier(rawValue: "clinical").rawValue == "clinical", "clinical identifier")
    wave10Require(HKCorrelationTypeIdentifier(rawValue: "correlation").rawValue == "correlation", "correlation identifier")
    wave10Require(HKDocumentTypeIdentifier(rawValue: "document").rawValue == "document", "document identifier")
    wave10Require(HKQuantityTypeIdentifier(rawValue: "quantity").rawValue == "quantity", "quantity identifier")
    wave10Require(HKScoredAssessmentTypeIdentifier(rawValue: "assessment").rawValue == "assessment", "assessment identifier")
    wave10Require(HKFHIRRelease(rawValue: "R4").rawValue == "R4", "FHIR release")
    wave10Require(HKFHIRResourceType(rawValue: "Observation").rawValue == "Observation", "FHIR resource type")
    wave10Require(HKHealthConceptDomain(rawValue: "medication").rawValue == "medication", "concept domain")
    wave10Require(HKMedicationGeneralForm(rawValue: "tablet").rawValue == "tablet", "medication form")
}

func testContactsPrescriptionValueTypes() {
    let diopter = HKUnit.diopter()
    let millimeter = HKUnit.meterUnit(with: .milli)
    let lens = HKContactsLensSpecification(
        sphere: HKQuantity(unit: diopter, doubleValue: -1.5),
        cylinder: HKQuantity(unit: diopter, doubleValue: -0.5),
        axis: HKQuantity(unit: .degreeAngle(), doubleValue: 85),
        addPower: HKQuantity(unit: diopter, doubleValue: 1.25),
        baseCurve: HKQuantity(unit: millimeter, doubleValue: 8.6),
        diameter: HKQuantity(unit: millimeter, doubleValue: 14.2)
    )
    wave10Require(lens.sphere?.doubleValue(for: diopter) == -1.5, "sphere")
    wave10Require(lens.cylinder?.doubleValue(for: diopter) == -0.5, "cylinder")
    wave10Require(lens.axis?.doubleValue(for: .degreeAngle()) == 85, "axis")
    wave10Require(lens.addPower?.doubleValue(for: diopter) == 1.25, "add power")
    wave10Require(lens.baseCurve?.doubleValue(for: millimeter) == 8.6, "base curve")
    wave10Require(lens.diameter?.doubleValue(for: millimeter) == 14.2, "diameter")
    let issued = Date(timeIntervalSince1970: 1_780_000_000)
    let prescription = HKContactsPrescription(rightEyeSpecification: lens, leftEyeSpecification: nil, brand: "Portable", dateIssued: issued, expirationDate: issued.addingTimeInterval(86400), device: .local(), metadata: ["verified": false])
    wave10Require(prescription.rightEye === lens && prescription.leftEye == nil, "eyes")
    wave10Require(prescription.brand == "Portable" && prescription.dateIssued == issued, "prescription values")
}

func testVisionPrescriptionAndFHIRValues() {
    let issued = Date(timeIntervalSince1970: 1_780_100_000)
    let vision = HKVisionPrescription(type: .contacts, dateIssued: issued, expirationDate: nil, device: .local(), metadata: nil)
    wave10Require(vision.prescriptionType == .contacts && vision.dateIssued == issued, "vision type and date")
    wave10Require(vision.expirationDate == nil && vision.startDate == issued && vision.endDate == issued, "vision interval")
    let resource = HKFHIRResource()
    resource.resourceType = .observation
    resource.identifier = "Observation/linux-1"
    resource.sourceURL = URL(string: "https://example.invalid/fhir/Observation/linux-1")
    resource.data = Data("{\"resourceType\":\"Observation\"}".utf8)
    resource.fhirVersion = .primaryR4()
    wave10Require(resource.resourceType == .observation && resource.identifier.hasSuffix("linux-1"), "FHIR identity")
    wave10Require(!resource.data.isEmpty && resource.fhirVersion.stringRepresentation == "4.0.1", "FHIR local bytes")
}

func testLiveWorkoutDataSourceCollectionState() {
    let configuration = HKWorkoutConfiguration()
    let source = HKLiveWorkoutDataSource(healthStore: HKHealthStore(), workoutConfiguration: configuration)
    let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    wave10Require(source.typesToCollect.isEmpty && source.workoutConfiguration === configuration, "initial state")
    source.enableCollection(for: heartRate, predicate: nil)
    source.enableCollection(for: distance, predicate: NSPredicate(value: true))
    wave10Require(source.typesToCollect == [heartRate, distance], "enabled types")
    source.disableCollection(for: heartRate)
    wave10Require(source.typesToCollect == [distance], "disabled type")
}

func testHardwareAndServiceBoundariesFailClosed() {
    HKHealthStorePortable._reset()
    let store = HKHealthStore()
    let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
    wave10Require(store.authorizationStatus(for: heartRate) == .notDetermined, "authorization starts fail closed")
    wave10Require(HKHealthStore.isHealthDataAvailable(), "portable local store remains available")
}
