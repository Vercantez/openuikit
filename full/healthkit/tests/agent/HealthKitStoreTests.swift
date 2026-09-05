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

func testHealthStoreAvailabilityAndAuthorization() {
    HKHealthStorePortable._reset()
    hkRequire(HKHealthStore.isHealthDataAvailable() == true, "available")
    let store = HKHealthStore()
    hkRequire(store.supportsHealthRecords() == false, "no records")
    _ = store.earliestPermittedSampleDate()
    _ = store.workoutSessionMirroringStartHandler
    store.workoutSessionMirroringStartHandler = nil
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    hkRequire(store.authorizationStatus(for: heart) == .notDetermined, "undetermined")
    let denyLock = DispatchSemaphore(value: 0)
    var denyOK = true
    store.requestAuthorization(toShare: [heart], read: [heart]) { success, _ in
        denyOK = success
        denyLock.signal()
    }
    hkRequire(denyLock.wait(timeout: .now() + 5) == .success, "deny")
    hkRequire(denyOK == false, "fail-closed")
    hkRequire(store.authorizationStatus(for: heart) == .sharingDenied, "denied")
    let statusLock = DispatchSemaphore(value: 0)
    store.getRequestStatusForAuthorization(toShare: [heart], read: [heart]) { status, _ in
        hkRequire(status == .unnecessary || status == .shouldRequest, "status")
        statusLock.signal()
    }
    hkRequire(statusLock.wait(timeout: .now() + 5) == .success, "req status")
}

func testHealthStoreSaveDeleteAndErrors() {
    HKHealthStorePortable._reset()
    let store = HKHealthStore()
    guard let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else { hkRequire(false, "heart"); return }
    guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { hkRequire(false, "steps"); return }
    let sample = HKQuantitySample(
        type: heart,
        quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 72),
        start: Date(),
        end: Date()
    )
    hkWait {
        do {
            try await store.save(sample)
            hkRequire(false, "save without auth")
        } catch {
            hkRequire(HKError.Code.errorAuthorizationNotDetermined ~= error, "not determined")
        }
    }
    HKHealthStorePortable._reset()
    hkAuthorize([heart, steps])
    hkRequire(store.authorizationStatus(for: heart) == .sharingAuthorized, "authorized")
    let bad = HKQuantitySample(type: heart, quantity: HKQuantity(unit: .gram(), doubleValue: 1), start: Date(), end: Date())
    hkWait {
        do {
            try await store.save(bad)
            hkRequire(false, "bad unit")
        } catch {
            hkRequire(HKError.Code.errorInvalidArgument ~= error, "invalid")
        }
        let s1 = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 60), start: Date(), end: Date())
        let s2 = HKQuantitySample(type: heart, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 80), start: Date(), end: Date())
        try await store.save([s1, s2])
        try await store.delete(s2)
        try await store.delete([s1])
        _ = try await store.deleteObjects(of: heart, predicate: NSPredicate(value: true))
    }
}

func testHealthStoreCharacteristicsAndFailClosed() {
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
    hkRequire((try? store.biologicalSex().biologicalSex) == .female, "sex")
    hkRequire((try? store.bloodType().bloodType) == .aPositive, "blood")
    hkRequire((try? store.fitzpatrickSkinType().skinType) == .III, "skin")
    hkRequire((try? store.wheelchairUse().wheelchairUse) == .no, "chair")
    hkRequire((try? store.activityMoveMode().activityMoveMode) == .appleMoveTime, "move")
    hkRequire((try? store.dateOfBirthComponents().year) == 1990, "dob")
    _ = try? store.dateOfBirth()
    hkWait {
        do {
            try await store.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .hourly)
            hkRequire(false, "background")
        } catch {
            hkRequire(HKError.Code.errorHealthDataUnavailable ~= error, "bg")
        }
        do { try await store.disableBackgroundDelivery(for: HKObjectType.workoutType()) } catch { _ = error }
        store.disableAllBackgroundDelivery { _, _ in }
        do { _ = try await store.preferredUnits(for: []) } catch { _ = error }
        store.handleAuthorizationForExtension { _, _ in }
        do { try await store.recalibrateEstimates(sampleType: HKObjectType.workoutType(), date: Date()) } catch { _ = error }
        store.recoverActiveWorkoutSession { _, _ in }
        store.splitTotalEnergy(HKQuantity(unit: .kilocalorie(), doubleValue: 1), start: Date(), end: Date()) { _, _, _ in }
        do { try await store.startWatchApp(toHandle: HKWorkoutConfiguration()) } catch { _ = error }
        do { try await store.requestPerObjectReadAuthorization(for: HKObjectType.workoutType(), predicate: nil) } catch { _ = error }
        do { _ = try await store.relateWorkoutEffortSample(HKWorkout(activityType: .running, start: Date(), end: Date()), with: HKWorkout(activityType: .running, start: Date(), end: Date()), activity: nil) } catch { _ = error }
        do { _ = try await store.unrelateWorkoutEffortSample(HKWorkout(activityType: .running, start: Date(), end: Date()), from: HKWorkout(activityType: .running, start: Date(), end: Date()), activity: nil) } catch { _ = error }
    }
}
