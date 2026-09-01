import Foundation

open class HKWorkoutEvent: NSObject {
    public let type: HKWorkoutEventType
    public let dateInterval: DateInterval
    public let metadata: [String: Any]?

    public var date: Date { dateInterval.start }

    public convenience init(type: HKWorkoutEventType, date: Date) {
        self.init(type: type, dateInterval: DateInterval(start: date, duration: 0), metadata: nil)
    }

    public convenience init(type: HKWorkoutEventType, date: Date, metadata: [String: Any]) {
        self.init(type: type, dateInterval: DateInterval(start: date, duration: 0), metadata: metadata)
    }

    public convenience init(type: HKWorkoutEventType, dateInterval: DateInterval, metadata: [String: Any]?) {
        self.init(_type: type, dateInterval: dateInterval, metadata: metadata)
    }

    init(_type type: HKWorkoutEventType, dateInterval: DateInterval, metadata: [String: Any]?) {
        self.type = type
        self.dateInterval = dateInterval
        self.metadata = metadata
        super.init()
    }

    public convenience init?(coder: NSCoder) { nil }
}

open class HKWorkoutConfiguration: NSObject, NSCopying {
    public var activityType: HKWorkoutActivityType = .other
    public var locationType: HKWorkoutSessionLocationType = .unknown
    public var swimmingLocationType: HKWorkoutSwimmingLocationType = .unknown
    public var lapLength: HKQuantity?

    public override init() {
        super.init()
    }

    public convenience init?(coder: NSCoder) { nil }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = HKWorkoutConfiguration()
        copy.activityType = activityType
        copy.locationType = locationType
        copy.swimmingLocationType = swimmingLocationType
        copy.lapLength = lapLength
        return copy
    }
}

open class HKWorkoutActivity: NSObject {
    public let uuid: UUID
    public let startDate: Date
    public let endDate: Date?
    public let workoutConfiguration: HKWorkoutConfiguration

    init(
        configuration: HKWorkoutConfiguration,
        start startDate: Date,
        end endDate: Date?,
        uuid: UUID = UUID()
    ) {
        self.workoutConfiguration = configuration
        self.startDate = startDate
        self.endDate = endDate
        self.uuid = uuid
        super.init()
    }

    public convenience init?(coder: NSCoder) { nil }
}

open class HKStatistics: NSObject {
    public let quantityType: HKQuantityType
    public let startDate: Date
    public let endDate: Date
    public let sources: [HKSource]?

    init(
        quantityType: HKQuantityType,
        start startDate: Date,
        end endDate: Date,
        sources: [HKSource]? = nil
    ) {
        self.quantityType = quantityType
        self.startDate = startDate
        self.endDate = endDate
        self.sources = sources
        super.init()
    }

    public convenience init?(coder: NSCoder) { nil }

    open func averageQuantity() -> HKQuantity? { nil }
    open func averageQuantity(for source: HKSource) -> HKQuantity? { nil }
    open func duration() -> HKQuantity? { nil }
    open func duration(for source: HKSource) -> HKQuantity? { nil }
    open func maximumQuantity() -> HKQuantity? { nil }
    open func maximumQuantity(for source: HKSource) -> HKQuantity? { nil }
    open func minimumQuantity() -> HKQuantity? { nil }
    open func minimumQuantity(for source: HKSource) -> HKQuantity? { nil }
    open func mostRecentQuantity() -> HKQuantity? { nil }
    open func mostRecentQuantity(for source: HKSource) -> HKQuantity? { nil }
    open func mostRecentQuantityDateInterval() -> DateInterval? { nil }
    open func mostRecentQuantityDateInterval(for source: HKSource) -> DateInterval? { nil }
    open func sumQuantity() -> HKQuantity? { nil }
    open func sumQuantity(for source: HKSource) -> HKQuantity? { nil }
}

open class HKWorkout: HKSample {
    public let workoutActivityType: HKWorkoutActivityType
    public let duration: TimeInterval
    public let totalEnergyBurned: HKQuantity?
    public let totalDistance: HKQuantity?
    public let totalFlightsClimbed: HKQuantity?
    public let totalSwimmingStrokeCount: HKQuantity?
    public let workoutEvents: [HKWorkoutEvent]?
    public let workoutActivities: [HKWorkoutActivity]
    public let allStatistics: [HKQuantityType: HKStatistics]

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: nil,
            duration: max(0, endDate.timeIntervalSince(startDate)),
            totalEnergyBurned: nil,
            totalDistance: nil,
            totalFlightsClimbed: nil,
            totalSwimmingStrokeCount: nil,
            device: nil,
            metadata: nil
        )
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date
    ) {
        self.init(activityType: workoutActivityType, start: startDate, end: endDate)
    }

    public convenience init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: nil,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: nil,
            totalSwimmingStrokeCount: nil,
            device: nil,
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
            workoutEvents: nil,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: nil,
            totalSwimmingStrokeCount: nil,
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
        metadata: [String: Any]?
    ) {
        self.init(
            activityType: workoutActivityType,
            start: startDate,
            end: endDate,
            workoutEvents: workoutEvents,
            duration: max(0, endDate.timeIntervalSince(startDate)),
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: nil,
            totalSwimmingStrokeCount: nil,
            device: nil,
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
            workoutEvents: workoutEvents,
            duration: max(0, endDate.timeIntervalSince(startDate)),
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: nil,
            totalSwimmingStrokeCount: nil,
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
            workoutEvents: workoutEvents,
            duration: max(0, endDate.timeIntervalSince(startDate)),
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: totalFlightsClimbed,
            totalSwimmingStrokeCount: nil,
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
            workoutEvents: workoutEvents,
            duration: max(0, endDate.timeIntervalSince(startDate)),
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            totalFlightsClimbed: nil,
            totalSwimmingStrokeCount: totalSwimmingStrokeCount,
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

    init(
        activityType workoutActivityType: HKWorkoutActivityType,
        start startDate: Date,
        end endDate: Date,
        workoutEvents: [HKWorkoutEvent]?,
        duration: TimeInterval,
        totalEnergyBurned: HKQuantity?,
        totalDistance: HKQuantity?,
        totalFlightsClimbed: HKQuantity?,
        totalSwimmingStrokeCount: HKQuantity?,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.workoutActivityType = workoutActivityType
        self.duration = duration > 0 ? duration : max(0, endDate.timeIntervalSince(startDate))
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.totalFlightsClimbed = totalFlightsClimbed
        self.totalSwimmingStrokeCount = totalSwimmingStrokeCount
        self.workoutEvents = workoutEvents
        self.workoutActivities = []
        self.allStatistics = [:]
        super.init(
            sampleType: HKObjectType.workoutType(),
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    open func statistics(for quantityType: HKQuantityType) -> HKStatistics? {
        allStatistics[quantityType]
    }
}
