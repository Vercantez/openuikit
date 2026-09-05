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

    public func beginCollection(at startDate: Date) async throws {
        guard state == .idle else {
            throw hkError(.errorInvalidArgument, reason: "beginCollection requires idle builder")
        }
        self.startDate = startDate
        state = .collecting
    }

    public func endCollection(at endDate: Date) async throws {
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

    public func addWorkoutActivity(_ workoutActivity: HKWorkoutActivity) async throws {
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

    public func updateActivity(uuid UUID: UUID, adding metadata: [String: Any]) async throws {
        _ = (UUID, metadata)
    }

    public func updateActivity(uuid UUID: UUID, end endDate: Date) async throws {
        if let index = workoutActivities.firstIndex(where: { $0.uuid == UUID }) {
            let current = workoutActivities[index]
            workoutActivities[index] = HKWorkoutActivity(
                workoutConfiguration: current.workoutConfiguration,
                start: current.startDate,
                end: endDate,
                uuid: current.uuid,
                metadata: current.metadata
            )
        }
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
    public let typesToCollect: Set<HKQuantityType>
    public var workoutConfiguration: HKWorkoutConfiguration?

    public init(healthStore: HKHealthStore, workoutConfiguration: HKWorkoutConfiguration?) {
        _ = healthStore
        self.workoutConfiguration = workoutConfiguration
        self.typesToCollect = []
        super.init()
    }

    public func enableCollection(for type: HKQuantityType, predicate: NSPredicate?) {
        _ = (type, predicate)
    }

    public func disableCollection(for type: HKQuantityType) {
        _ = type
    }
}

open class HKWorkoutSession: NSObject, @unchecked Sendable {
    public weak var delegate: (any HKWorkoutSessionDelegate)?
    public let workoutConfiguration: HKWorkoutConfiguration
    public private(set) var state: HKWorkoutSessionState = .notStarted
    public var type: HKWorkoutSessionType { .primary }
    public var locationType: HKWorkoutSessionLocationType { workoutConfiguration.locationType }
    public var startDate: Date?
    public var endDate: Date?

    public init(healthStore: HKHealthStore, configuration: HKWorkoutConfiguration) throws {
        _ = healthStore
        self.workoutConfiguration = configuration
        super.init()
    }

    public func prepare() {
        state = .prepared
    }

    public func startActivity(with date: Date?) {
        startDate = date ?? Date()
        state = .running
    }

    public func pause() {
        state = .paused
    }

    public func resume() {
        state = .running
    }

    public func stopActivity(with date: Date?) {
        endDate = date ?? Date()
        state = .stopped
    }

    public func end() {
        state = .ended
    }
}

public protocol HKWorkoutSessionDelegate: AnyObject {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date)
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error)
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent)
}

extension HKWorkoutSessionDelegate {
    public func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        _ = (workoutSession, event)
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
    public init(healthStore: HKHealthStore, device: HKDevice?, start startDate: Date) {
        _ = startDate
        super.init(healthStore: healthStore, device: device, seriesType: .heartbeat())
    }

    public func addHeartbeat(at date: Date, precededByGap: Bool) async throws {
        _ = (date, precededByGap)
    }

    public func finishSeries() async throws -> HKHeartbeatSeriesSample {
        HKHeartbeatSeriesSample(start: Date(), end: Date())
    }
}

open class HKQuantitySeriesSampleBuilder: NSObject, @unchecked Sendable {
    public let quantityType: HKQuantityType
    public let startDate: Date
    public let device: HKDevice?
    private var quantities: [(HKQuantity, Date)] = []

    public init(healthStore: HKHealthStore, quantityType: HKQuantityType, startDate: Date, device: HKDevice?) {
        _ = healthStore
        self.quantityType = quantityType
        self.startDate = startDate
        self.device = device
        super.init()
    }

    public func insert(_ quantity: HKQuantity, date: Date) async throws {
        if !quantityType.`is`(compatibleWith: quantity.unit) {
            throw hkError(.errorInvalidArgument, reason: "quantity unit is not compatible")
        }
        quantities.append((quantity, date))
    }

    public func finishSeries(metadata: [String: Any]?) async throws -> [HKQuantitySample] {
        quantities.map { quantity, date in
            HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date, device: device, metadata: metadata)
        }
    }

    public func discard() {
        quantities.removeAll()
    }
}
