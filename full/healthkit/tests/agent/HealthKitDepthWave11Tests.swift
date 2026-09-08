import Foundation
import HealthKit

private func wave11Require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HealthKit wave-11 test failed: \(message)\n", stderr)
        exit(1)
    }
}

func testClinicalDocumentAndSeriesValues() {
    let now = Date(timeIntervalSince1970: 1_788_000_000)
    let clinicalType = HKObjectType.clinicalType(forIdentifier: .allergyRecord)!
    let record = HKClinicalRecord(type: clinicalType, start: now, end: now)
    record.displayName = "Portable allergy"
    record.fhirResourceType = .allergyIntolerance
    record.fhirIdentifier = "AllergyIntolerance/linux"
    record.fhirSourceURL = URL(string: "https://example.invalid/fhir/allergy")
    wave11Require(record.clinicalType === clinicalType, "clinical type")
    wave11Require(record.displayName == "Portable allergy", "clinical display name")
    wave11Require(record.FHIRResource?.identifier == "AllergyIntolerance/linux", "FHIR projection")

    let documentType = HKObjectType.documentType(forIdentifier: .CDA)!
    let document = HKDocumentSample(type: documentType, start: now, end: now)
    wave11Require(document.documentType === documentType, "document type")

    let series = HKSeriesSample(type: HKSeriesType.heartbeat(), start: now, end: now)
    wave11Require(series.count == 0, "empty series count")
    wave11Require(!HKSource.default().bundleIdentifier.isEmpty, "source bundle")
}

func testBuilderStateMachinesSynchronously() {
    HKHealthStorePortable._reset()
    let store = HKHealthStore()
    let now = Date(timeIntervalSince1970: 1_788_100_000)
    let generic = HKSeriesBuilder(healthStore: store, device: .local(), seriesType: .heartbeat())
    wave11Require(generic.seriesType == .heartbeat(), "series type")
    generic.discard()

    let heartbeat = HKHeartbeatSeriesBuilder(healthStore: store, device: .local(), start: now)
    var completed = false
    heartbeat.finishSeries { sample, error in
        completed = true
        wave11Require(sample == nil && error != nil, "unauthorized heartbeat finish fails closed")
    }
    wave11Require(completed, "heartbeat completion is deterministic")

    let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let quantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: 72)
    let quantityBuilder = HKQuantitySeriesSampleBuilder(healthStore: store, quantityType: quantityType, startDate: now, device: nil)
    try! quantityBuilder.insert(quantity, at: now)
    quantityBuilder.discard()
    do {
        try quantityBuilder.insert(quantity, at: now)
        wave11Require(false, "discarded quantity builder accepted data")
    } catch {
        wave11Require(HKError.Code.errorInvalidArgument ~= error, "discard fail closed")
    }
}

func testDeclaredTypesAndSecureCoding() {
    let types: [HKObjectType] = [
        HKObjectType.activitySummaryType(), HKObjectType.audiogramSampleType(),
        HKObjectType.electrocardiogramType(), HKObjectType.stateOfMindType(),
        HKObjectType.userAnnotatedMedicationType(), HKObjectType.workoutType(),
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
    ]
    wave11Require(types.allSatisfy { !$0.identifier.isEmpty }, "specialized types")

    let values: [NSObject & NSSecureCoding] = [
        HKBiologicalSexObject(biologicalSex: .female), HKBloodTypeObject(bloodType: .aPositive),
        HKFitzpatrickSkinTypeObject(skinType: .III), HKWheelchairUseObject(wheelchairUse: .no),
        HKActivityMoveModeObject(activityMoveMode: .activeEnergy)
    ]
    for value in values {
        let data = try! NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
        wave11Require(!data.isEmpty && value.copy() is NSObject, "secure coding and copy")
    }
}

func testAsyncDescriptorSequenceConstruction() {
    let store = HKHealthStore()
    let summary = HKActivitySummaryQueryDescriptor(predicate: nil).results(for: store)
    _ = summary.map { $0.count }
    _ = summary.compactMap { $0.first }
    _ = summary.filter { !$0.isEmpty }
    _ = summary.prefix(1)
    _ = summary.dropFirst(1)
    _ = summary.drop { $0.isEmpty }
    _ = summary.flatMap { values in
        AsyncStream<[HKActivitySummary]> { (continuation: AsyncStream<[HKActivitySummary]>.Continuation) in
            continuation.yield(values)
            continuation.finish()
        }
    }

    let bytes = HKAttachmentDataReader().bytes
    _ = bytes.map { Int($0) }
    _ = bytes.filter { $0 > 0 }
    _ = bytes.prefix(4)
    _ = bytes.dropFirst(1)
    let byteIterator = bytes.makeAsyncIterator()
    wave11Require(String(reflecting: type(of: byteIterator)).contains("Iterator"), "attachment iterator")
    _ = byteIterator
}

func testAsyncDescriptorOperationsAreBounded() {
    let store = HKHealthStore()
    let descriptor = HKWorkoutEffortRelationshipQueryDescriptor(predicate: nil, anchor: nil, option: .mostRelevant)
    let results = descriptor.results(for: store)
    _ = results.map { $0.relationships.count }
    _ = results.compactMap { $0.relationships.first }
    _ = results.filter { !$0.relationships.isEmpty }
    _ = results.prefix(1)
    _ = results.dropFirst(1)
    let iterator = results.makeAsyncIterator()
    wave11Require(String(reflecting: type(of: iterator)).contains("Iterator"), "effort iterator")
    _ = iterator
}
