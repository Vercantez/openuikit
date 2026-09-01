import Foundation

/// Linux has no HealthKit data store, entitlements, or Health app.
/// Availability is `false` and every store mutation or characteristic read
/// fails closed with `HKError.errorHealthDataUnavailable`.
open class HKHealthStore: NSObject {
    public var workoutSessionMirroringStartHandler: ((HKWorkoutSession) -> Void)?

    public override init() {
        super.init()
    }

    open class func isHealthDataAvailable() -> Bool { false }

    open func supportsHealthRecords() -> Bool { false }

    open func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        .notDetermined
    }

    open func earliestPermittedSampleDate() -> Date {
        Date.distantPast
    }

    open func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        completion(false, hkUnavailableError())
    }

    open func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws {
        throw hkUnavailableError()
    }

    open func getRequestStatusForAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>,
        completion: @escaping (HKAuthorizationRequestStatus, (any Error)?) -> Void
    ) {
        completion(.unknown, hkUnavailableError())
    }

    open func handleAuthorizationForExtension(completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(false, hkUnavailableError())
    }

    open func requestPerObjectReadAuthorization(
        for objectType: HKObjectType,
        predicate: NSPredicate?
    ) async throws {
        throw hkUnavailableError()
    }

    open func save(_ object: HKObject) async throws {
        throw hkUnavailableError()
    }

    open func save(_ objects: [HKObject]) async throws {
        throw hkUnavailableError()
    }

    open func delete(_ object: HKObject) async throws {
        throw hkUnavailableError()
    }

    open func delete(_ objects: [HKObject]) async throws {
        throw hkUnavailableError()
    }

    open func deleteObjects(
        of objectType: HKObjectType,
        predicate: NSPredicate
    ) async throws -> Int {
        throw hkUnavailableError()
    }

    open func execute(_ query: HKQuery) {
        query.isExecuting = true
        query.handleExecution(on: self)
    }

    open func stop(_ query: HKQuery) {
        query.handleStop()
    }

    open func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency
    ) async throws {
        throw hkUnavailableError()
    }

    open func disableBackgroundDelivery(for type: HKObjectType) async throws {
        throw hkUnavailableError()
    }

    open func disableAllBackgroundDelivery(completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(false, hkUnavailableError())
    }

    open func biologicalSex() throws -> HKBiologicalSexObject {
        throw hkUnavailableError()
    }

    open func bloodType() throws -> HKBloodTypeObject {
        throw hkUnavailableError()
    }

    open func dateOfBirthComponents() throws -> DateComponents {
        throw hkUnavailableError()
    }

    open func dateOfBirth() throws -> Date {
        throw hkUnavailableError()
    }

    open func fitzpatrickSkinType() throws -> HKFitzpatrickSkinTypeObject {
        throw hkUnavailableError()
    }

    open func wheelchairUse() throws -> HKWheelchairUseObject {
        throw hkUnavailableError()
    }

    open func activityMoveMode() throws -> HKActivityMoveModeObject {
        throw hkUnavailableError()
    }

    open func preferredUnits(for quantityTypes: Set<HKQuantityType>) async throws -> [HKQuantityType: HKUnit] {
        throw hkUnavailableError()
    }

    open func add(
        _ samples: [HKSample],
        to workout: HKWorkout,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        completion(false, hkUnavailableError())
    }

    open func startWatchApp(toHandle workoutConfiguration: HKWorkoutConfiguration) async throws {
        throw hkUnavailableError()
    }

    open func recoverActiveWorkoutSession(
        completion: @escaping (HKWorkoutSession?, (any Error)?) -> Void
    ) {
        completion(nil, hkUnavailableError())
    }

    open func splitTotalEnergy(
        _ totalEnergy: HKQuantity,
        start startDate: Date,
        end endDate: Date,
        resultsHandler: @escaping (HKQuantity?, HKQuantity?, (any Error)?) -> Void
    ) {
        resultsHandler(nil, nil, hkUnavailableError())
    }

    open func recalibrateEstimates(sampleType: HKSampleType, date: Date) async throws {
        throw hkUnavailableError()
    }

    open func relateWorkoutEffortSample(
        _ sample: HKSample,
        with workout: HKWorkout,
        activity: HKWorkoutActivity?
    ) async throws -> Bool {
        throw hkUnavailableError()
    }

    open func unrelateWorkoutEffortSample(
        _ sample: HKSample,
        from workout: HKWorkout,
        activity: HKWorkoutActivity?
    ) async throws -> Bool {
        throw hkUnavailableError()
    }
}
