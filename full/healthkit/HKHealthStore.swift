import Foundation

open class HKHealthStore: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public class func isHealthDataAvailable() -> Bool {
        false
    }

    public func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        _ = type
        return .notDetermined
    }

    public func supportsHealthRecords() -> Bool {
        false
    }

    public func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = typesToShare
        _ = typesToRead
        completion(false, hkUnavailableError(.errorHealthDataUnavailable))
    }

    public func getRequestStatusForAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>,
        completion: @escaping (HKAuthorizationRequestStatus, (any Error)?) -> Void
    ) {
        _ = typesToShare
        _ = typesToRead
        completion(.unknown, hkUnavailableError())
    }

    public func save(_ object: HKObject) async throws {
        _ = object
        throw hkUnavailableError()
    }

    public func save(_ objects: [HKObject]) async throws {
        _ = objects
        throw hkUnavailableError()
    }

    public func delete(_ object: HKObject) async throws {
        _ = object
        throw hkUnavailableError()
    }

    public func delete(_ objects: [HKObject]) async throws {
        _ = objects
        throw hkUnavailableError()
    }

    public func deleteObjects(of objectType: HKObjectType, predicate: NSPredicate) async throws -> Int {
        _ = objectType
        _ = predicate
        throw hkUnavailableError()
    }

    public func execute(_ query: HKQuery) {
        if let sampleQuery = query as? HKSampleQuery {
            sampleQuery.deliverUnavailable()
            return
        }
        _ = query
    }

    public func stop(_ query: HKQuery) {
        _ = query
    }

    public func earliestPermittedSampleDate() -> Date {
        Date.distantPast
    }

    public func biologicalSex() throws -> HKBiologicalSexObject {
        throw hkUnavailableError()
    }

    public func bloodType() throws -> HKBloodTypeObject {
        throw hkUnavailableError()
    }

    public func fitzpatrickSkinType() throws -> HKFitzpatrickSkinTypeObject {
        throw hkUnavailableError()
    }

    public func wheelchairUse() throws -> HKWheelchairUseObject {
        throw hkUnavailableError()
    }

    public func activityMoveMode() throws -> HKActivityMoveModeObject {
        throw hkUnavailableError()
    }

    public func dateOfBirth() throws -> Date {
        throw hkUnavailableError()
    }

    public func dateOfBirthComponents() throws -> DateComponents {
        throw hkUnavailableError()
    }

    public func add(
        _ samples: [HKSample],
        to workout: HKWorkout,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = samples
        _ = workout
        completion(false, hkUnavailableError())
    }

    public func enableBackgroundDelivery(for type: HKObjectType, frequency: HKUpdateFrequency) async throws {
        _ = type
        _ = frequency
        throw hkUnavailableError()
    }

    public func disableBackgroundDelivery(for type: HKObjectType) async throws {
        _ = type
        throw hkUnavailableError()
    }

    public func disableAllBackgroundDelivery(completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(false, hkUnavailableError())
    }

    public func preferredUnits(for quantityTypes: Set<HKQuantityType>) async throws -> [HKQuantityType: HKUnit] {
        _ = quantityTypes
        throw hkUnavailableError()
    }

    public func handleAuthorizationForExtension(completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(false, hkUnavailableError())
    }

    public func recalibrateEstimates(sampleType: HKSampleType, date: Date) async throws {
        _ = sampleType
        _ = date
        throw hkUnavailableError()
    }

    public func recoverActiveWorkoutSession(
        completion: @escaping (HKWorkoutSession?, (any Error)?) -> Void
    ) {
        completion(nil, hkUnavailableError())
    }

    public func relateWorkoutEffortSample(
        _ sample: HKSample,
        with workout: HKWorkout,
        activity: HKWorkoutActivity?
    ) async throws -> Bool {
        _ = sample
        _ = workout
        _ = activity
        throw hkUnavailableError()
    }

    public func requestPerObjectReadAuthorization(
        for objectType: HKObjectType,
        predicate: NSPredicate?
    ) async throws {
        _ = objectType
        _ = predicate
        throw hkUnavailableError()
    }

    public func splitTotalEnergy(
        _ totalEnergy: HKQuantity,
        start startDate: Date,
        end endDate: Date,
        resultsHandler: @escaping (HKQuantity?, HKQuantity?, (any Error)?) -> Void
    ) {
        _ = totalEnergy
        _ = startDate
        _ = endDate
        resultsHandler(nil, nil, hkUnavailableError())
    }

    public func startWatchApp(toHandle workoutConfiguration: HKWorkoutConfiguration) async throws {
        _ = workoutConfiguration
        throw hkUnavailableError()
    }
}

open class HKBiologicalSexObject: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let biologicalSex: HKBiologicalSex
    public init(biologicalSex: HKBiologicalSex) {
        self.biologicalSex = biologicalSex
        super.init()
    }
    public required init?(coder: NSCoder) {
        self.biologicalSex = .notSet
        super.init()
    }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any { HKBiologicalSexObject(biologicalSex: biologicalSex) }
}

open class HKBloodTypeObject: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let bloodType: HKBloodType
    public init(bloodType: HKBloodType) {
        self.bloodType = bloodType
        super.init()
    }
    public required init?(coder: NSCoder) {
        self.bloodType = .notSet
        super.init()
    }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any { HKBloodTypeObject(bloodType: bloodType) }
}

open class HKFitzpatrickSkinTypeObject: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let skinType: HKFitzpatrickSkinType
    public init(skinType: HKFitzpatrickSkinType) {
        self.skinType = skinType
        super.init()
    }
    public required init?(coder: NSCoder) {
        self.skinType = .notSet
        super.init()
    }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any { HKFitzpatrickSkinTypeObject(skinType: skinType) }
}

open class HKWheelchairUseObject: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let wheelchairUse: HKWheelchairUse
    public init(wheelchairUse: HKWheelchairUse) {
        self.wheelchairUse = wheelchairUse
        super.init()
    }
    public required init?(coder: NSCoder) {
        self.wheelchairUse = .notSet
        super.init()
    }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any { HKWheelchairUseObject(wheelchairUse: wheelchairUse) }
}

open class HKActivityMoveModeObject: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let activityMoveMode: HKActivityMoveMode
    public init(activityMoveMode: HKActivityMoveMode) {
        self.activityMoveMode = activityMoveMode
        super.init()
    }
    public required init?(coder: NSCoder) {
        self.activityMoveMode = .activeEnergy
        super.init()
    }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any {
        HKActivityMoveModeObject(activityMoveMode: activityMoveMode)
    }
}
