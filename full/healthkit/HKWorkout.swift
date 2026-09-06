import Foundation

open class HKWorkoutEvent: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let type: HKWorkoutEventType
    public let dateInterval: DateInterval
    public let metadata: [String: Any]?

    public init(type: HKWorkoutEventType, date: Date, metadata: [String: Any]? = nil) {
        self.type = type
        self.dateInterval = DateInterval(start: date, duration: 0)
        self.metadata = metadata
        super.init()
    }

    public init(type: HKWorkoutEventType, dateInterval: DateInterval, metadata: [String: Any]?) {
        self.type = type
        self.dateInterval = dateInterval
        self.metadata = metadata
        super.init()
    }

    public var date: Date { dateInterval.start }

    public required init?(coder: NSCoder) {
        self.type = .pause
        self.dateInterval = DateInterval(start: Date(), duration: 0)
        self.metadata = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        HKWorkoutEvent(type: type, dateInterval: dateInterval, metadata: metadata)
    }
}

open class HKWorkoutConfiguration: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public var activityType: HKWorkoutActivityType = .other
    public var locationType: HKWorkoutSessionLocationType = .unknown
    public var swimmingLocationType: HKWorkoutSwimmingLocationType = .unknown
    public var lapLength: HKQuantity?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = HKWorkoutConfiguration()
        copy.activityType = activityType
        copy.locationType = locationType
        copy.swimmingLocationType = swimmingLocationType
        copy.lapLength = lapLength
        return copy
    }
}

open class HKWorkoutActivity: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let uuid: UUID
    public let startDate: Date
    public let endDate: Date?
    public let workoutConfiguration: HKWorkoutConfiguration
    public let metadata: [String: Any]?
    public var workoutEvents: [HKWorkoutEvent]
    public var allStatistics: [HKQuantityType: HKStatistics] { [:] }
    public var duration: TimeInterval {
        (endDate ?? startDate).timeIntervalSince(startDate)
    }

    public init(
        workoutConfiguration: HKWorkoutConfiguration,
        start startDate: Date,
        end endDate: Date?,
        uuid: UUID = UUID(),
        metadata: [String: Any]? = nil
    ) {
        self.workoutConfiguration = workoutConfiguration
        self.startDate = startDate
        self.endDate = endDate
        self.uuid = uuid
        self.metadata = metadata
        self.workoutEvents = []
        super.init()
    }

    public convenience init(
        workoutConfiguration: HKWorkoutConfiguration,
        startDate: Date,
        endDate: Date?,
        metadata: [String: Any]?
    ) {
        self.init(
            workoutConfiguration: workoutConfiguration,
            start: startDate,
            end: endDate,
            metadata: metadata
        )
    }

    public func statistics(for quantityType: HKQuantityType) -> HKStatistics? {
        allStatistics[quantityType]
    }

    public required init?(coder: NSCoder) {
        self.workoutConfiguration = HKWorkoutConfiguration()
        self.startDate = Date()
        self.endDate = nil
        self.uuid = UUID()
        self.metadata = nil
        self.workoutEvents = []
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = HKWorkoutActivity(
            workoutConfiguration: workoutConfiguration,
            start: startDate,
            end: endDate,
            uuid: uuid,
            metadata: metadata
        )
        copy.workoutEvents = workoutEvents
        return copy
    }
}

open class HKWorkout: HKSample, @unchecked Sendable {
    public let workoutActivityType: HKWorkoutActivityType
    public let duration: TimeInterval
    public let totalEnergyBurned: HKQuantity?
    public let totalDistance: HKQuantity?
    public let totalSwimmingStrokeCount: HKQuantity?
    public let totalFlightsClimbed: HKQuantity?
    public let workoutEvents: [HKWorkoutEvent]
    public let workoutActivities: [HKWorkoutActivity]

    public convenience init(activityType workoutActivityType: HKWorkoutActivityType, startDate: Date, endDate: Date) {
        self.init(activityType: workoutActivityType, start: startDate, end: endDate)
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            metadata: metadata
        )
    }

    public convenience init(activityType: HKWorkoutActivityType, start startDate: Date, end endDate: Date) {
        self.init(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: 0,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: nil
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            duration: duration,
            workoutEvents: nil,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalSwimmingStrokeCount: nil,
            totalFlightsClimbed: nil,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            duration: 0,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalSwimmingStrokeCount: nil,
            totalFlightsClimbed: nil,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        totalFlightsClimbed: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            duration: 0,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalSwimmingStrokeCount: nil,
            totalFlightsClimbed: totalFlightsClimbed,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        totalFlightsClimbed: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: totalFlightsClimbed,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        totalSwimmingStrokeCount: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            duration: 0,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalSwimmingStrokeCount: totalSwimmingStrokeCount,
            totalFlightsClimbed: nil,
            device: device,
            metadata: metadata
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        totalSwimmingStrokeCount: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: workoutEvents,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalSwimmingStrokeCount: totalSwimmingStrokeCount,
            device: device,
            metadata: metadata
        )
    }

    public init(
        activityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        duration: TimeInterval,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        totalSwimmingStrokeCount: HKQuantity?,
        totalFlightsClimbed: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.workoutActivityType = activityType
        self.duration = duration > 0 ? duration : endDate.timeIntervalSince(startDate)
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.totalSwimmingStrokeCount = totalSwimmingStrokeCount
        self.totalFlightsClimbed = totalFlightsClimbed
        self.workoutEvents = workoutEvents ?? []
        self.workoutActivities = []
        super.init(
            type: HKObjectType.workoutType(),
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    public init(
        activityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        metadata: [String: Any]?
    ) {
        self.workoutActivityType = activityType
        self.duration = duration > 0 ? duration: endDate.timeIntervalSince(startDate)
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.totalSwimmingStrokeCount = nil
        self.totalFlightsClimbed = nil
        self.workoutEvents = []
        self.workoutActivities = []
        super.init(
            type: HKObjectType.workoutType(),
            start: startDate,
            end: endDate,
            metadata: metadata
        )
    }

    public init(
        activityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        metadata: [String: Any]?
    ) {
        self.workoutActivityType = activityType
        self.duration = endDate.timeIntervalSince(startDate)
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.totalSwimmingStrokeCount = nil
        self.totalFlightsClimbed = nil
        self.workoutEvents = workoutEvents ?? []
        self.workoutActivities = []
        super.init(
            type: HKObjectType.workoutType(),
            start: startDate,
            end: endDate,
            metadata: metadata
        )
    }

    public required init?(coder: NSCoder) {
        self.workoutActivityType = .other
        self.duration = 0
        self.totalEnergyBurned = nil
        self.totalDistance = nil
        self.totalSwimmingStrokeCount = nil
        self.totalFlightsClimbed = nil
        self.workoutEvents = []
        self.workoutActivities = []
        super.init(coder: coder)
    }

    public var allStatistics: [HKQuantityType: HKStatistics] {
        var stats: [HKQuantityType: HKStatistics] = [:]
        if let energy = totalEnergyBurned,
           let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            stats[type] = HKStatistics.compute(
                quantityType: type,
                samples: [
                    HKQuantitySample(type: type, quantity: energy, start: startDate, end: endDate)
                ],
                options: .cumulativeSum,
                start: startDate,
                end: endDate
            )
        }
        if let distance = totalDistance,
           let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            stats[type] = HKStatistics.compute(
                quantityType: type,
                samples: [
                    HKQuantitySample(type: type, quantity: distance, start: startDate, end: endDate)
                ],
                options: .cumulativeSum,
                start: startDate,
                end: endDate
            )
        }
        return stats
    }

    public func statistics(for quantityType: HKQuantityType) -> HKStatistics? {
        allStatistics[quantityType]
    }
}
