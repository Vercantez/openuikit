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

func testDeclaredSurfaceDefaultObjects() {
    _ = HKActivitySummary()
    _ = HKAttachment()
    _ = HKAttachmentStore()
    _ = HKAttachmentDataReader()
    _ = HKAudiogramSensitivityPoint()
    _ = HKAudiogramSensitivityPointClampingRange()
    _ = HKAudiogramSensitivityTest()
    _ = HKCDADocument()
    _ = HKClinicalCoding()
    _ = HKContactsLensSpecification()
    _ = HKContactsPrescription()
    _ = HKFHIRResource()
    _ = HKFHIRVersion()
    _ = HKGlassesLensSpecification()
    _ = HKGlassesPrescription()
    _ = HKHealthConceptIdentifier()
    _ = HKLensSpecification()
    _ = HKMedicationConcept()
    _ = HKQueryAnchor(fromValue: 0)
    _ = HKQueryDescriptor(sampleType: HKObjectType.workoutType(), predicate: nil)
    _ = HKWorkoutConfiguration()
    _ = HKVisionPrism()
    _ = HKHeartbeatSeriesBuilder(healthStore: HKHealthStore(), device: nil, start: Date())
    _ = HKQuantitySeriesSampleBuilder(healthStore: HKHealthStore(), quantityType: HKObjectType.quantityType(forIdentifier: .stepCount)!, startDate: Date(), device: nil)
}

func testElectrocardiogramAndClinicalSurface() {
    let now = Date()
    _ = HKElectrocardiogram.self
    _ = HKElectrocardiogram.Classification.sinusRhythm
    _ = HKElectrocardiogram.SymptomsStatus.notSet
    _ = HKAudiogramSample(type: HKObjectType.audiogramSampleType(), start: now, end: now)
    _ = HKCDADocumentSample.self
    _ = HKClinicalRecord.self
    _ = HKHeartbeatSeriesSample(start: now, end: now)
    _ = HKMedicationDoseEvent.self
    _ = HKStateOfMind(type: HKObjectType.stateOfMindType(), start: now, end: now)
    _ = HKUserAnnotatedMedication()
    _ = HKVerifiableClinicalRecord.self
    _ = HKVisionPrescription.self
    _ = HKScoredAssessment(type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, start: now, end: now)
}
