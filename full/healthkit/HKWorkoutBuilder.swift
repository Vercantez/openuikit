import Foundation

public enum HKWorkoutBuilderState: String, Sendable {
    case idle
    case collecting
    case ended
    case finished
    case discarded
}

open class HKWorkoutBuilder: NSObject, @unchecked Sendable {
    public let workoutConfiguration: HKWorkoutConfiguration
    public let device: HKDevice?
    public private(set) var startDate: Date?
    public private(set) var endDate: Date?
    public private(set) var metadata: [String: Any] = [:]
    public private(set) var workoutEvents: [HKWorkoutEvent] = []
    public private(set) var workoutActivities: [HKWorkoutActivity] = []
    public private(set) var allStatistics: [HKQuantityType: HKStatistics] = [:]
    private let healthStore: HKHealthStore
    private var samples: [HKSample] = []
    private var state: HKWorkoutBuilderState = .idle

    public init(healthStore: HKHealthStore, configuration: HKWorkoutConfiguration, device: HKDevice?) {
        self.healthStore = healthStore
        self.workoutConfiguration = configuration
        self.device = device
        super.init()
    }

    public func beginCollection(at startDate: Date, completion: @escaping (Bool, (any Error)?) -> Void) {
        do {
            try beginCollectionSync(at: startDate)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    public func beginCollection(at startDate: Date) async throws {
        try beginCollectionSync(at: startDate)
    }

    func beginCollectionSync(at startDate: Date) throws {
        guard state == .idle else {
            throw hkError(.errorInvalidArgument, reason: "beginCollection requires idle builder")
        }
        self.startDate = startDate
        state = .collecting
    }

    public func endCollection(at endDate: Date, completion: @escaping (Bool, (any Error)?) -> Void) {
        do {
            try endCollectionSync(at: endDate)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    public func endCollection(at endDate: Date) async throws {
        try endCollectionSync(at: endDate)
    }

    func endCollectionSync(at endDate: Date) throws {
        guard state == .collecting else {
            throw hkError(.errorInvalidArgument, reason: "endCollection requires collecting builder")
        }
        self.endDate = endDate
        state = .ended
    }

    public func addMetadata(_ metadata: [String: Any]) async throws {
        guard state == .collecting || state == .ended else {
            throw hkError(.errorInvalidArgument, reason: "addMetadata requires an active collection")
        }
        for (key, value) in metadata {
            self.metadata[key] = value
        }
    }

    public func add(_ samples: [HKSample], completion: @escaping (Bool, (any Error)?) -> Void) {
        guard state == .collecting || state == .ended else {
            completion(false, hkError(.errorInvalidArgument, reason: "add samples requires an active collection"))
            return
        }
        self.samples.append(contentsOf: samples)
        for sample in samples.compactMap({ $0 as? HKQuantitySample }) {
            allStatistics[sample.quantityType] = HKStatistics.compute(
                quantityType: sample.quantityType,
                samples: self.samples.compactMap { $0 as? HKQuantitySample }.filter { $0.quantityType == sample.quantityType },
                options: sample.quantityType.aggregationStyle == .cumulative ? .cumulativeSum : .discreteAverage,
                start: startDate ?? sample.startDate,
                end: self.endDate ?? sample.endDate
            )
        }
        completion(true, nil)
    }

    public func addWorkoutActivity(_ workoutActivity: HKWorkoutActivity, completion: @escaping (Bool, (any Error)?) -> Void) {
        do {
            try addWorkoutActivitySync(workoutActivity)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    public func addWorkoutActivity(_ workoutActivity: HKWorkoutActivity) async throws {
        try addWorkoutActivitySync(workoutActivity)
    }

    func addWorkoutActivitySync(_ workoutActivity: HKWorkoutActivity) throws {
        guard state == .collecting || state == .ended else {
            throw hkError(.errorInvalidArgument, reason: "addWorkoutActivity requires an active collection")
        }
        workoutActivities.append(workoutActivity)
    }

    public func addWorkoutEvents(_ workoutEvents: [HKWorkoutEvent]) async throws {
        guard state == .collecting || state == .ended else {
            throw hkError(.errorInvalidArgument, reason: "addWorkoutEvents requires an active collection")
        }
        self.workoutEvents.append(contentsOf: workoutEvents)
    }

    public func elapsedTime(at date: Date) -> TimeInterval {
        guard let startDate else { return 0 }
        return date.timeIntervalSince(startDate)
    }

    public func seriesBuilder(for seriesType: HKSeriesType) -> HKSeriesBuilder? {
        HKSeriesBuilder(healthStore: healthStore, device: device, seriesType: seriesType)
    }

    public func statistics(for quantityType: HKQuantityType) -> HKStatistics? {
        allStatistics[quantityType]
    }

    public func updateActivity(uuid UUID: UUID, adding metadata: [String: Any], completion: @escaping (Bool, (any Error)?) -> Void) {
        do {
            try updateActivitySync(uuid: UUID, adding: metadata)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    public func updateActivity(uuid UUID: UUID, adding metadata: [String: Any]) async throws {
        try updateActivitySync(uuid: UUID, adding: metadata)
    }

    func updateActivitySync(uuid UUID: UUID, adding metadata: [String: Any]) throws {
        guard state == .collecting || state == .ended else {
            throw hkError(.errorInvalidArgument, reason: "updateActivity requires an active collection")
        }
        guard let index = workoutActivities.firstIndex(where: { $0.uuid == UUID }) else {
            throw hkError(.errorInvalidArgument, reason: "unknown workout activity UUID")
        }
        let current = workoutActivities[index]
        var merged = current.metadata ?? [:]
        for (key, value) in metadata {
            merged[key] = value
        }
        workoutActivities[index] = HKWorkoutActivity(
            workoutConfiguration: current.workoutConfiguration,
            start: current.startDate,
            end: current.endDate,
            uuid: current.uuid,
            metadata: merged
        )
    }

    public func updateActivity(uuid UUID: UUID, end endDate: Date, completion: @escaping (Bool, (any Error)?) -> Void) {
        do {
            try updateActivitySync(uuid: UUID, end: endDate)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    public func updateActivity(uuid UUID: UUID, end endDate: Date) async throws {
        try updateActivitySync(uuid: UUID, end: endDate)
    }

    func updateActivitySync(uuid UUID: UUID, end endDate: Date) throws {
        guard state == .collecting || state == .ended else {
            throw hkError(.errorInvalidArgument, reason: "updateActivity requires an active collection")
        }
        guard let index = workoutActivities.firstIndex(where: { $0.uuid == UUID }) else {
            throw hkError(.errorInvalidArgument, reason: "unknown workout activity UUID")
        }
        let current = workoutActivities[index]
        workoutActivities[index] = HKWorkoutActivity(
            workoutConfiguration: current.workoutConfiguration,
            start: current.startDate,
            end: endDate,
            uuid: current.uuid,
            metadata: current.metadata
        )
    }

    public func discardWorkout() {
        state = .discarded
        samples.removeAll()
        workoutEvents.removeAll()
        workoutActivities.removeAll()
        metadata.removeAll()
        startDate = nil
        endDate = nil
    }

    public func finishWorkout(completion: @escaping (HKWorkout?, (any Error)?) -> Void) {
        guard state == .ended || state == .collecting else {
            completion(nil, hkError(.errorInvalidArgument, reason: "finishWorkout requires collection to have begun"))
            return
        }
        let start = startDate ?? Date()
        let end = endDate ?? Date()
        let energy = samples.compactMap { $0 as? HKQuantitySample }
            .filter { $0.quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue }
            .map { $0.quantity.doubleValue(for: .kilocalorie()) }
            .reduce(0, +)
        let distance = samples.compactMap { $0 as? HKQuantitySample }
            .filter { $0.quantityType.identifier.contains("Distance") }
            .map { $0.quantity.doubleValue(for: .meter()) }
            .reduce(0, +)
        let workout = HKWorkout(
            activityType: workoutConfiguration.activityType,
            start: start,
            end: end,
            workoutEvents: workoutEvents,
            totalEnergyBurned: energy > 0 ? HKQuantity(unit: .kilocalorie(), doubleValue: energy) : nil,
            totalDistance: distance > 0 ? HKQuantity(unit: .meter(), doubleValue: distance) : nil,
            metadata: metadata
        )
        do {
            try healthStore.hkSave([workout])
            try healthStore.hkSave(samples)
            HKHealthStorePortable.associate(sampleIDs: samples.map(\.uuid), with: workout.uuid)
            state = .finished
            completion(workout, nil)
        } catch {
            completion(nil, error)
        }
    }
}

open class HKLiveWorkoutBuilder: HKWorkoutBuilder, @unchecked Sendable {
    public weak var delegate: (any HKLiveWorkoutBuilderDelegate)?
    public var dataSource: HKLiveWorkoutDataSource?
    public weak var workoutSession: HKWorkoutSession?
    public var shouldCollectWorkoutEvents: Bool = true
    public var elapsedTime: TimeInterval { elapsedTime(at: Date()) }
    public var currentWorkoutActivity: HKWorkoutActivity? { workoutActivities.last }
}

public protocol HKLiveWorkoutBuilderDelegate: AnyObject {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>)
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder)
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didBegin workoutActivity: HKWorkoutActivity)
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didEnd workoutActivity: HKWorkoutActivity)
}

extension HKLiveWorkoutBuilderDelegate {
    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didBegin workoutActivity: HKWorkoutActivity) {
        _ = (workoutBuilder, workoutActivity)
    }

    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didEnd workoutActivity: HKWorkoutActivity) {
        _ = (workoutBuilder, workoutActivity)
    }
}

open class HKLiveWorkoutDataSource: NSObject, @unchecked Sendable {
    public private(set) var typesToCollect: Set<HKQuantityType>
    private var predicates: [String: NSPredicate] = [:]
    public var workoutConfiguration: HKWorkoutConfiguration?

    public init(healthStore: HKHealthStore, workoutConfiguration: HKWorkoutConfiguration?) {
        _ = healthStore
        self.workoutConfiguration = workoutConfiguration
        self.typesToCollect = []
        super.init()
    }

    public func enableCollection(for type: HKQuantityType, predicate: NSPredicate?) {
        typesToCollect.insert(type)
        if let predicate { predicates[type.identifier] = predicate }
        else { predicates.removeValue(forKey: type.identifier) }
    }

    public func disableCollection(for type: HKQuantityType) {
        typesToCollect.remove(type)
        predicates.removeValue(forKey: type.identifier)
    }
}

open class HKWorkoutSession: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public weak var delegate: (any HKWorkoutSessionDelegate)?
    public let workoutConfiguration: HKWorkoutConfiguration
    public private(set) var state: HKWorkoutSessionState = .notStarted
    public var type: HKWorkoutSessionType { .primary }
    public var locationType: HKWorkoutSessionLocationType { workoutConfiguration.locationType }
    public var startDate: Date?
    public var endDate: Date?
    public private(set) var currentActivity: HKWorkoutActivity
    private var associatedBuilder: HKLiveWorkoutBuilder?
    private let healthStore: HKHealthStore

    public init(healthStore: HKHealthStore, configuration: HKWorkoutConfiguration) throws {
        self.healthStore = healthStore
        self.workoutConfiguration = configuration
        self.currentActivity = HKWorkoutActivity(
            workoutConfiguration: configuration,
            start: Date(),
            end: nil,
            metadata: nil
        )
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.healthStore = HKHealthStore()
        self.workoutConfiguration = HKWorkoutConfiguration()
        self.currentActivity = HKWorkoutActivity(
            workoutConfiguration: workoutConfiguration,
            start: Date(),
            end: nil
        )
        super.init()
        self.state = HKWorkoutSessionState(rawValue: coder.decodeInteger(forKey: "state")) ?? .notStarted
    }

    public func encode(with coder: NSCoder) {
        coder.encode(state.rawValue, forKey: "state")
    }

    private func transition(to newState: HKWorkoutSessionState, at date: Date) {
        let from = state
        state = newState
        delegate?.workoutSession(self, didChangeTo: newState, from: from, date: date)
    }

    public func prepare() {
        guard state == .notStarted else {
            delegate?.workoutSession(self, didFailWithError: hkError(.errorInvalidArgument, reason: "prepare requires notStarted"))
            return
        }
        transition(to: .prepared, at: Date())
    }

    public func startActivity(with date: Date?) {
        let when = date ?? Date()
        startDate = when
        currentActivity = HKWorkoutActivity(
            workoutConfiguration: workoutConfiguration,
            start: when,
            end: nil,
            uuid: currentActivity.uuid,
            metadata: currentActivity.metadata
        )
        transition(to: .running, at: when)
        delegate?.workoutSession(self, didBeginActivityWith: workoutConfiguration, date: when)
    }

    public func pause() {
        guard state == .running else {
            delegate?.workoutSession(self, didFailWithError: hkError(.errorInvalidArgument, reason: "pause requires running"))
            return
        }
        let date = Date()
        transition(to: .paused, at: date)
        let event = HKWorkoutEvent(type: .pause, date: date)
        delegate?.workoutSession(self, didGenerate: event)
    }

    public func resume() {
        guard state == .paused else {
            delegate?.workoutSession(self, didFailWithError: hkError(.errorInvalidArgument, reason: "resume requires paused"))
            return
        }
        let date = Date()
        transition(to: .running, at: date)
        let event = HKWorkoutEvent(type: .resume, date: date)
        delegate?.workoutSession(self, didGenerate: event)
    }

    public func stopActivity(with date: Date?) {
        let when = date ?? Date()
        endDate = when
        transition(to: .stopped, at: when)
    }

    public func end() {
        let when = Date()
        if state == .running || state == .paused {
            endDate = when
        }
        transition(to: .ended, at: when)
    }

    public func associatedWorkoutBuilder() -> HKLiveWorkoutBuilder {
        if let associatedBuilder { return associatedBuilder }
        let builder = HKLiveWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: nil)
        builder.workoutSession = self
        associatedBuilder = builder
        return builder
    }

    public func beginNewActivity(configuration workoutConfiguration: HKWorkoutConfiguration, date: Date, metadata: [String: Any]?) {
        currentActivity = HKWorkoutActivity(
            workoutConfiguration: workoutConfiguration,
            start: date,
            end: nil,
            metadata: metadata
        )
        delegate?.workoutSession(self, didBeginActivityWith: workoutConfiguration, date: date)
    }

    public func endCurrentActivity(on date: Date) {
        let configuration = currentActivity.workoutConfiguration
        currentActivity = HKWorkoutActivity(
            workoutConfiguration: configuration,
            start: currentActivity.startDate,
            end: date,
            uuid: currentActivity.uuid,
            metadata: currentActivity.metadata
        )
        delegate?.workoutSession(self, didEndActivityWith: configuration, date: date)
    }

    public func sendToRemoteWorkoutSession(data: Data, completion: @escaping (Bool, (any Error)?) -> Void) {
        completion(
            false,
            hkError(
                .errorHealthDataUnavailable,
                reason: "remote workout sessions require Apple Watch pairing; Linux is fail-closed"
            )
        )
    }

    public func sendToRemoteWorkoutSession(data: Data) async throws {
        _ = data
        throw hkError(
            .errorHealthDataUnavailable,
            reason: "remote workout sessions require Apple Watch pairing; Linux is fail-closed"
        )
    }
}

public protocol HKWorkoutSessionDelegate: AnyObject {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date)
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error)
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent)
    func workoutSession(_ workoutSession: HKWorkoutSession, didBeginActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date)
    func workoutSession(_ workoutSession: HKWorkoutSession, didEndActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date)
    func workoutSession(_ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: (any Error)?)
    func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data])
}

extension HKWorkoutSessionDelegate {
    public func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        _ = (workoutSession, event)
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didBeginActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date) {
        _ = (workoutSession, workoutConfiguration, date)
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didEndActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date) {
        _ = (workoutSession, workoutConfiguration, date)
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: (any Error)?) {
        _ = (workoutSession, error)
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        _ = (workoutSession, data)
    }
}

open class HKWorkoutRouteBuilder: NSObject, @unchecked Sendable {
    private let healthStore: HKHealthStore
    public let device: HKDevice?
    private var locations: [CLLocation] = []
    private var metadata: [String: Any] = [:]

    public init(healthStore: HKHealthStore, device: HKDevice?) {
        self.healthStore = healthStore
        self.device = device
        super.init()
    }

    public func insertRouteData(_ routeData: [CLLocation]) async throws {
        locations.append(contentsOf: routeData)
    }

    public func addMetadata(_ metadata: [String: Any]) async throws {
        for (key, value) in metadata {
            self.metadata[key] = value
        }
    }

    public func finishRoute(with workout: HKWorkout, metadata: [String: Any]?) async throws -> HKWorkoutRoute {
        let route = HKWorkoutRoute(start: workout.startDate, end: workout.endDate, metadata: metadata ?? self.metadata)
        HKHealthStorePortable._setRouteLocations(locations, for: route)
        try await healthStore.save(route)
        return route
    }
}

open class HKSeriesBuilder: NSObject, @unchecked Sendable {
    public let seriesType: HKSeriesType
    public let device: HKDevice?

    public init(healthStore: HKHealthStore, device: HKDevice?, seriesType: HKSeriesType) {
        _ = healthStore
        self.device = device
        self.seriesType = seriesType
        super.init()
    }

    public func discard() {}
}

open class HKHeartbeatSeriesBuilder: HKSeriesBuilder, @unchecked Sendable {
    public static var maximumCount: Int { 100 }

    private let healthStore: HKHealthStore
    private let seriesStart: Date
    private var beats: [(TimeInterval, Bool)] = []
    private var metadata: [String: Any] = [:]
    private var discarded = false

    public init(healthStore: HKHealthStore, device: HKDevice?, start startDate: Date) {
        self.healthStore = healthStore
        self.seriesStart = startDate
        super.init(healthStore: healthStore, device: device, seriesType: .heartbeat())
    }

    public convenience init(healthStore: HKHealthStore, device: HKDevice?, startDate: Date) {
        self.init(healthStore: healthStore, device: device, start: startDate)
    }

    public func addHeartbeat(at timeIntervalSinceStart: TimeInterval, precededByGap: Bool) async throws {
        try addHeartbeatSync(at: timeIntervalSinceStart, precededByGap: precededByGap)
    }

    func addHeartbeatSync(at timeIntervalSinceStart: TimeInterval, precededByGap: Bool) throws {
        if discarded {
            throw hkError(.errorInvalidArgument, reason: "heartbeat builder was discarded")
        }
        if beats.count >= Self.maximumCount {
            throw hkError(.errorDataSizeExceeded, reason: "heartbeat series exceeds maximumCount")
        }
        beats.append((timeIntervalSinceStart, precededByGap))
    }

    public func addMetadata(_ metadata: [String: Any]) async throws {
        for (key, value) in metadata {
            self.metadata[key] = value
        }
    }

    public func finishSeries(completion: @escaping (HKHeartbeatSeriesSample?, (any Error)?) -> Void) {
        if discarded {
            completion(nil, hkError(.errorInvalidArgument, reason: "heartbeat builder was discarded"))
            return
        }
        let end = seriesStart.addingTimeInterval(beats.last?.0 ?? 0)
        let sample = HKHeartbeatSeriesSample(start: seriesStart, end: end)
        HKHealthStorePortable._setHeartbeats(beats, for: sample)
        do {
            try healthStore.hkSave([sample])
            completion(sample, nil)
        } catch {
            completion(nil, error)
        }
    }

    public func finishSeries() async throws -> HKHeartbeatSeriesSample {
        try await withCheckedThrowingContinuation { cont in
            finishSeries { sample, error in
                if let error {
                    cont.resume(throwing: error)
                } else if let sample {
                    cont.resume(returning: sample)
                } else {
                    cont.resume(throwing: hkError(.errorNoData, reason: "heartbeat series was empty"))
                }
            }
        }
    }

    public override func discard() {
        discarded = true
        beats.removeAll()
    }
}

open class HKQuantitySeriesSampleBuilder: NSObject, @unchecked Sendable {
    public let quantityType: HKQuantityType
    public let startDate: Date
    public let device: HKDevice?
    private let healthStore: HKHealthStore
    private var quantities: [(HKQuantity, DateInterval)] = []
    private var discarded = false

    public init(healthStore: HKHealthStore, quantityType: HKQuantityType, startDate: Date, device: HKDevice?) {
        self.healthStore = healthStore
        self.quantityType = quantityType
        self.startDate = startDate
        self.device = device
        super.init()
    }

    public func insert(_ quantity: HKQuantity, at date: Date) throws {
        try insert(quantity, for: DateInterval(start: date, duration: 0))
    }

    public func insert(_ quantity: HKQuantity, for dateInterval: DateInterval) throws {
        if discarded {
            throw hkError(.errorInvalidArgument, reason: "quantity series builder was discarded")
        }
        if !quantityType.`is`(compatibleWith: quantity.unit) {
            throw hkError(.errorInvalidArgument, reason: "quantity unit is not compatible")
        }
        quantities.append((quantity, dateInterval))
    }

    public func finishSeries(metadata: [String: Any]?) async throws -> [HKQuantitySample] {
        try finishSeriesSync(metadata: metadata, endDate: nil)
    }

    public func finishSeries(metadata: [String: Any]?, endDate: Date?) async throws -> [HKQuantitySample] {
        try finishSeriesSync(metadata: metadata, endDate: endDate)
    }

    func finishSeriesSync(metadata: [String: Any]?, endDate: Date?) throws -> [HKQuantitySample] {
        if discarded {
            throw hkError(.errorInvalidArgument, reason: "quantity series builder was discarded")
        }
        let lastEnd = quantities.map(\.1.end).max() ?? endDate ?? startDate
        let sampleEnd = endDate ?? lastEnd
        let sample = HKQuantitySample(
            type: quantityType,
            quantity: quantities.last?.0 ?? HKQuantity(unit: quantityType.canonicalUnit, doubleValue: 0),
            start: startDate,
            end: sampleEnd,
            device: device,
            metadata: metadata
        )
        HKHealthStorePortable._setQuantitySeries(quantities, for: sample)
        try healthStore.hkSave([sample])
        discarded = true
        return [sample]
    }

    public func discard() {
        discarded = true
        quantities.removeAll()
    }
}
