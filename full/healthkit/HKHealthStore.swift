import Foundation

open class HKHealthStore: NSObject, @unchecked Sendable {
    public var workoutSessionMirroringStartHandler: ((HKWorkoutSession) -> Void)?

    public override init() {
        super.init()
    }

    public class func isHealthDataAvailable() -> Bool {
        true
    }

    public func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        HKHealthStorePortable.loadState().shareStatus(for: type.identifier)
    }

    public func supportsHealthRecords() -> Bool {
        false
    }

    public func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        let handler = HKHealthStorePortable.authorizationHandlerLocked()
        let shareTypes = typesToShare ?? []
        let readTypes = typesToRead ?? []
        let granted: HKAuthorizationStatus
        if let handler {
            granted = handler(typesToShare, typesToRead)
        } else {
            granted = .sharingDenied
        }
        HKHealthStorePortable.mutate { state in
            for type in shareTypes {
                if state.shareStatus(for: type.identifier) == .notDetermined {
                    state.share[type.identifier] = granted.rawValue
                }
            }
            for type in readTypes {
                if state.readStatus(for: type.identifier) == .notDetermined {
                    state.read[type.identifier] = granted.rawValue
                }
            }
        }
        let success = granted == .sharingAuthorized
        completion(success, nil)
    }

    public func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error {
                    cont.resume(throwing: error)
                } else if success {
                    cont.resume()
                } else {
                    cont.resume(throwing: hkError(.errorAuthorizationDenied, reason: "authorization denied"))
                }
            }
        }
    }

    public func getRequestStatusForAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>,
        completion: @escaping (HKAuthorizationRequestStatus, (any Error)?) -> Void
    ) {
        let state = HKHealthStorePortable.loadState()
        let pendingShare = typesToShare.contains { state.shareStatus(for: $0.identifier) == .notDetermined }
        let pendingRead = typesToRead.contains { state.readStatus(for: $0.identifier) == .notDetermined }
        let status: HKAuthorizationRequestStatus = (pendingShare || pendingRead) ? .shouldRequest : .unnecessary
        completion(status, nil)
    }

    public func save(_ object: HKObject) async throws {
        try await save([object])
    }

    public func save(_ objects: [HKObject]) async throws {
        try hkSave(objects)
    }

    public func delete(_ object: HKObject) async throws {
        try await delete([object])
    }

    public func delete(_ objects: [HKObject]) async throws {
        try hkDelete(objects)
    }

    public func deleteObjects(of objectType: HKObjectType, predicate: NSPredicate) async throws -> Int {
        let state = HKHealthStorePortable.loadState()
        switch state.shareStatus(for: objectType.identifier) {
        case .notDetermined:
            throw hkError(.errorAuthorizationNotDetermined, reason: "authorization not determined")
        case .sharingDenied:
            throw hkError(.errorAuthorizationDenied, reason: "authorization denied")
        case .sharingAuthorized:
            break
        @unknown default:
            break
        }
        let matching = state.samples.compactMap { record -> HKSample? in
            guard record.type == objectType.identifier else { return nil }
            return hkMaterialize(record)
        }.filter { hkEvaluatePredicate(predicate, object: $0) }
        try hkDelete(matching)
        return matching.count
    }

    public func execute(_ query: HKQuery) {
        if HKHealthStorePortable.isStopped(query) {
            return
        }
        hkExecute(query)
    }

    public func stop(_ query: HKQuery) {
        HKHealthStorePortable.markStopped(query)
    }

    public func earliestPermittedSampleDate() -> Date {
        Date.distantPast
    }

    public func biologicalSex() throws -> HKBiologicalSexObject {
        let raw = HKHealthStorePortable.loadState().biologicalSex
        return HKBiologicalSexObject(biologicalSex: HKBiologicalSex(rawValue: raw) ?? .notSet)
    }

    public func bloodType() throws -> HKBloodTypeObject {
        let raw = HKHealthStorePortable.loadState().bloodType
        return HKBloodTypeObject(bloodType: HKBloodType(rawValue: raw) ?? .notSet)
    }

    public func fitzpatrickSkinType() throws -> HKFitzpatrickSkinTypeObject {
        let raw = HKHealthStorePortable.loadState().fitzpatrickSkinType
        return HKFitzpatrickSkinTypeObject(skinType: HKFitzpatrickSkinType(rawValue: raw) ?? .notSet)
    }

    public func wheelchairUse() throws -> HKWheelchairUseObject {
        let raw = HKHealthStorePortable.loadState().wheelchairUse
        return HKWheelchairUseObject(wheelchairUse: HKWheelchairUse(rawValue: raw) ?? .notSet)
    }

    public func activityMoveMode() throws -> HKActivityMoveModeObject {
        let raw = HKHealthStorePortable.loadState().activityMoveMode
        return HKActivityMoveModeObject(activityMoveMode: HKActivityMoveMode(rawValue: raw) ?? .activeEnergy)
    }

    public func dateOfBirth() throws -> Date {
        let components = try dateOfBirthComponents()
        guard let date = Calendar.current.date(from: components) else {
            throw hkError(.errorNoData, reason: "date of birth is not set")
        }
        return date
    }

    public func dateOfBirthComponents() throws -> DateComponents {
        let state = HKHealthStorePortable.loadState()
        guard let year = state.birthYear, let month = state.birthMonth, let day = state.birthDay else {
            throw hkError(.errorNoData, reason: "date of birth is not set")
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return components
    }

    public func add(
        _ samples: [HKSample],
        to workout: HKWorkout,
        completion: @escaping (Bool, (any Error)?) -> Void
    ) {
        do {
            try hkSave(samples)
            HKHealthStorePortable.associate(sampleIDs: samples.map(\.uuid), with: workout.uuid)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    public func enableBackgroundDelivery(for type: HKObjectType, frequency: HKUpdateFrequency) async throws {
        _ = type
        _ = frequency
        throw hkError(
            .errorHealthDataUnavailable,
            reason: "background delivery is fail-closed on this Linux host"
        )
    }

    public func disableBackgroundDelivery(for type: HKObjectType) async throws {
        _ = type
    }

    public func disableAllBackgroundDelivery(completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(true, nil)
    }

    public func preferredUnits(for quantityTypes: Set<HKQuantityType>) async throws -> [HKQuantityType: HKUnit] {
        var result: [HKQuantityType: HKUnit] = [:]
        for type in quantityTypes {
            result[type] = type.canonicalUnit
        }
        return result
    }

    public func handleAuthorizationForExtension(completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(false, hkError(.errorHealthDataUnavailable, reason: "no Health extension host"))
    }

    public func recalibrateEstimates(sampleType: HKSampleType, date: Date) async throws {
        _ = sampleType
        _ = date
        throw hkError(.errorHealthDataUnavailable, reason: "estimate recalibration is Apple-only")
    }

    public func recoverActiveWorkoutSession(
        completion: @escaping (HKWorkoutSession?, (any Error)?) -> Void
    ) {
        completion(nil, hkError(.errorHealthDataUnavailable, reason: "no Watch workout session on Linux"))
    }

    public func relateWorkoutEffortSample(
        _ sample: HKSample,
        with workout: HKWorkout,
        activity: HKWorkoutActivity?
    ) async throws -> Bool {
        _ = activity
        HKHealthStorePortable.associate(sampleIDs: [sample.uuid], with: workout.uuid)
        return true
    }

    public func unrelateWorkoutEffortSample(
        _ sample: HKSample,
        from workout: HKWorkout,
        activity: HKWorkoutActivity?
    ) async throws -> Bool {
        _ = sample
        _ = workout
        _ = activity
        return true
    }

    public func requestPerObjectReadAuthorization(
        for objectType: HKObjectType,
        predicate: NSPredicate?
    ) async throws {
        _ = objectType
        _ = predicate
        throw hkError(.errorHealthDataUnavailable, reason: "per-object Health records are fail-closed")
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
        resultsHandler(nil, nil, hkError(.errorHealthDataUnavailable, reason: "energy split is Apple-modelled"))
    }

    public func startWatchApp(toHandle workoutConfiguration: HKWorkoutConfiguration) async throws {
        _ = workoutConfiguration
        throw hkError(.errorHealthDataUnavailable, reason: "Watch app launch is fail-closed on Linux")
    }

    func hkSave(_ objects: [HKObject]) throws {
        for object in objects {
            if let sample = object as? HKQuantitySample {
                try hkRequireShare(sample.quantityType)
                if !sample.quantityType.`is`(compatibleWith: sample.quantity.unit) {
                    throw hkError(.errorInvalidArgument, reason: "quantity unit is not compatible with type")
                }
            } else if let sample = object as? HKCategorySample {
                try hkRequireShare(sample.categoryType)
            } else if let sample = object as? HKSample {
                try hkRequireShare(sample.sampleType)
            }
        }
        HKHealthStorePortable.mutate { state in
            for object in objects {
                if let sample = object as? HKSample {
                    let stored = hkStore(sample, anchor: state.nextAnchor)
                    state.nextAnchor += 1
                    state.samples.removeAll { $0.uuid == stored.uuid }
                    state.samples.append(stored)
                }
            }
        }
        notifyObservers(of: objects.compactMap { $0 as? HKSample }.map(\.sampleType))
    }

    func hkDelete(_ objects: [HKObject]) throws {
        for object in objects {
            if let sample = object as? HKSample {
                try hkRequireShare(sample.sampleType)
            }
        }
        HKHealthStorePortable.mutate { state in
            for object in objects {
                state.deleted.append(HKStoredDeleted(uuid: object.uuid.uuidString, metadata: [:]))
            }
            let idStrings = Set(objects.map { $0.uuid.uuidString })
            state.samples.removeAll { idStrings.contains($0.uuid) }
        }
    }

    func hkRequireShare(_ type: HKObjectType) throws {
        switch HKHealthStorePortable.loadState().shareStatus(for: type.identifier) {
        case .notDetermined:
            throw hkError(.errorAuthorizationNotDetermined, reason: "authorization not determined")
        case .sharingDenied:
            throw hkError(.errorAuthorizationDenied, reason: "authorization denied")
        case .sharingAuthorized:
            return
        @unknown default:
            return
        }
    }

    func hkRequireRead(_ type: HKObjectType) throws {
        switch HKHealthStorePortable.loadState().readStatus(for: type.identifier) {
        case .notDetermined:
            throw hkError(.errorAuthorizationNotDetermined, reason: "authorization not determined")
        case .sharingDenied:
            throw hkError(.errorAuthorizationDenied, reason: "authorization denied")
        case .sharingAuthorized:
            return
        @unknown default:
            return
        }
    }

    func hkAllSamples() -> [HKSample] {
        HKHealthStorePortable.loadState().samples.compactMap(hkMaterialize)
    }

    func hkSamples(
        of type: HKSampleType?,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?
    ) throws -> [HKSample] {
        if let type {
            try hkRequireRead(type)
        }
        var items = hkAllSamples()
        if let type {
            items = items.filter { $0.sampleType.identifier == type.identifier }
        }
        items = items.filter { hkEvaluatePredicate(predicate, object: $0) }
        items = hkSort(items, descriptors: sortDescriptors)
        if limit > 0, items.count > limit {
            items = Array(items.prefix(limit))
        }
        return items
    }

    func hkDeleted() -> [HKDeletedObject] {
        HKHealthStorePortable.loadState().deleted.compactMap { row in
            guard let uuid = UUID(uuidString: row.uuid) else { return nil }
            return HKDeletedObject(uuid: uuid)
        }
    }

    private func notifyObservers(of types: [HKSampleType]) {
        let unique = Set(types.map(\.identifier))
        for query in HKHealthStorePortable.activeObservers() {
            if HKHealthStorePortable.isStopped(query) { continue }
            query.deliverUpdate(changed: unique)
        }
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

func hkStore(_ sample: HKSample, anchor: Int) -> HKStoredSample {
    var stored = HKStoredSample(
        kind: "sample",
        uuid: sample.uuid.uuidString,
        type: sample.sampleType.identifier,
        start: sample.startDate.timeIntervalSince1970,
        end: sample.endDate.timeIntervalSince1970,
        unit: nil,
        value: nil,
        categoryValue: nil,
        workoutActivity: nil,
        duration: nil,
        energy: nil,
        distance: nil,
        sourceName: sample.sourceRevision.source.name,
        sourceBundle: sample.sourceRevision.source.bundleIdentifier,
        deviceName: sample.device?.name,
        metadata: (sample.metadata as? [String: String]) ?? [:],
        correlationChildren: [],
        anchor: anchor
    )
    if let quantity = sample as? HKQuantitySample {
        stored.kind = "quantity"
        stored.unit = quantity.quantity.unit.unitString
        stored.value = quantity.quantity.doubleValue
    } else if let category = sample as? HKCategorySample {
        stored.kind = "category"
        stored.categoryValue = category.value
    } else if let workout = sample as? HKWorkout {
        stored.kind = "workout"
        stored.workoutActivity = workout.workoutActivityType.rawValue
        stored.duration = workout.duration
        stored.energy = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        stored.distance = workout.totalDistance?.doubleValue(for: .meter())
    } else if let correlation = sample as? HKCorrelation {
        stored.kind = "correlation"
        stored.correlationChildren = correlation.objects.map { $0.uuid.uuidString }
    } else if sample is HKWorkoutRoute {
        stored.kind = "route"
    }
    return stored
}

func hkMaterialize(_ stored: HKStoredSample) -> HKSample? {
    guard let uuid = UUID(uuidString: stored.uuid) else { return nil }
    let start = Date(timeIntervalSince1970: stored.start)
    let end = Date(timeIntervalSince1970: stored.end)
    let source = HKSource(name: stored.sourceName, bundleIdentifier: stored.sourceBundle)
    let revision = HKSourceRevision(source: source, version: nil)
    let device = stored.deviceName.map {
        HKDevice(
            name: $0,
            manufacturer: nil,
            model: nil,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }
    switch stored.kind {
    case "quantity":
        let type = HKQuantityType(identifier: stored.type)
        let unit = HKUnit.unit(stored.unit ?? "count") ?? .count()
        let quantity = HKQuantity(unit: unit, doubleValue: stored.value ?? 0)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end, device: device, metadata: stored.metadata)
        sample.replaceIdentity(uuid: uuid, sourceRevision: revision)
        return sample
    case "category":
        let type = HKCategoryType(identifier: stored.type)
        let sample = HKCategorySample(type: type, value: stored.categoryValue ?? 0, start: start, end: end, device: device, metadata: stored.metadata)
        sample.replaceIdentity(uuid: uuid, sourceRevision: revision)
        return sample
    case "workout":
        let workout = HKWorkout(
            activityType: HKWorkoutActivityType(rawValue: stored.workoutActivity ?? 3000) ?? .other,
            start: start,
            end: end,
            duration: stored.duration ?? end.timeIntervalSince(start),
            totalEnergyBurned: stored.energy.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
            totalDistance: stored.distance.map { HKQuantity(unit: .meter(), doubleValue: $0) },
            metadata: stored.metadata
        )
        workout.replaceIdentity(uuid: uuid, sourceRevision: revision)
        return workout
    case "correlation":
        let type = HKCorrelationType(identifier: stored.type)
        let sample = HKCorrelation(type: type, start: start, end: end, objects: [], device: device, metadata: stored.metadata)
        sample.replaceIdentity(uuid: uuid, sourceRevision: revision)
        return sample
    case "route":
        let route = HKWorkoutRoute(start: start, end: end, metadata: stored.metadata)
        route.replaceIdentity(uuid: uuid, sourceRevision: revision)
        return route
    default:
        let type = HKSampleType(identifier: stored.type)
        let sample = HKSample(type: type, start: start, end: end, uuid: uuid, sourceRevision: revision, device: device, metadata: stored.metadata)
        return sample
    }
}

func hkSort(_ samples: [HKSample], descriptors: [NSSortDescriptor]?) -> [HKSample] {
    guard let descriptors, let first = descriptors.first else {
        return samples.sorted { $0.startDate < $1.startDate }
    }
    return samples.sorted { lhs, rhs in
        let description = String(describing: first.keyPath)
        let ascending = first.ascending
        if description.contains("endDate") {
            return ascending ? lhs.endDate < rhs.endDate : lhs.endDate > rhs.endDate
        }
        return ascending ? lhs.startDate < rhs.startDate : lhs.startDate > rhs.startDate
    }
}
