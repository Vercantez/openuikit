import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// A workout with a single distance, time, energy, or open goal.
public struct SingleGoalWorkout: Hashable, Sendable {
    public var activity: HKWorkoutActivityType
    public let location: HKWorkoutSessionLocationType
    public let swimmingLocation: HKWorkoutSwimmingLocationType
    public var goal: WorkoutGoal

    public init(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType = .unknown,
        swimmingLocation: HKWorkoutSwimmingLocationType = .unknown,
        goal: WorkoutGoal = .open
    ) {
        self.activity = activity
        self.location = location
        self.swimmingLocation = swimmingLocation
        self.goal = goal
    }

    public static func supportsActivity(_ activity: HKWorkoutActivityType) -> Bool {
        WorkoutSupport.isStructuredActivity(activity)
    }

    public static func supportsGoal(
        _ goal: WorkoutGoal,
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType = .unknown
    ) -> Bool {
        WorkoutSupport.supportsGoal(goal, activity: activity, location: location)
    }
}

/// A distance-over-time pacer workout.
public struct PacerWorkout: Hashable, Sendable {
    public var activity: HKWorkoutActivityType
    public let location: HKWorkoutSessionLocationType
    public var distance: Measurement<UnitLength>
    public var time: Measurement<UnitDuration>

    public init(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType = .unknown,
        distance: Measurement<UnitLength>,
        time: Measurement<UnitDuration>
    ) {
        self.activity = activity
        self.location = location
        self.distance = distance
        self.time = time
    }

    public static func supportsActivity(_ activity: HKWorkoutActivityType) -> Bool {
        WorkoutSupport.isPacerActivity(activity)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(activity)
        hasher.combine(location)
        WorkoutKitDimension.hashMeasurement(distance, into: &hasher)
        WorkoutKitDimension.hashMeasurement(time, into: &hasher)
    }
}

/// A custom workout with warmup, interval blocks, and cooldown.
public struct CustomWorkout: Hashable, Sendable {
    public var activity: HKWorkoutActivityType
    public var location: HKWorkoutSessionLocationType
    public var displayName: String?
    public var warmup: WorkoutStep?
    public var blocks: [IntervalBlock]
    public var cooldown: WorkoutStep?

    public init(
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType = .unknown,
        displayName: String? = nil,
        warmup: WorkoutStep? = nil,
        blocks: [IntervalBlock] = [],
        cooldown: WorkoutStep? = nil
    ) {
        self.activity = activity
        self.location = location
        self.displayName = displayName
        self.warmup = warmup
        self.blocks = blocks
        self.cooldown = cooldown
    }

    public static func supportsActivity(_ activity: HKWorkoutActivityType) -> Bool {
        WorkoutSupport.isStructuredActivity(activity)
    }

    public static func supportsGoal(
        _ goal: WorkoutGoal,
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType = .unknown
    ) -> Bool {
        WorkoutSupport.supportsGoal(goal, activity: activity, location: location)
    }

    public static func supportsAlert(
        _ alert: any WorkoutAlert,
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType = .unknown
    ) -> Bool {
        supportsActivity(activity)
            && alert.supports(activity: activity, location: location)
    }
}

/// A triathlon-style swim, bike, and run workout.
public struct SwimBikeRunWorkout: Hashable, Sendable {
    public enum Activity: Hashable, Sendable {
        case swimming(HKWorkoutSwimmingLocationType)
        case cycling(HKWorkoutSessionLocationType)
        case running(HKWorkoutSessionLocationType)
    }

    public var activities: [Activity]
    public var displayName: String?

    public init(activities: [Activity], displayName: String? = nil) {
        self.activities = activities
        self.displayName = displayName
    }

    public static func supportsActivityOrdering(_ activities: [Activity]) -> Bool {
        var swim = 0
        var bike = 0
        var run = 0
        for activity in activities {
            switch activity {
            case .swimming: swim += 1
            case .cycling: bike += 1
            case .running: run += 1
            }
        }
        return swim == 1 && bike == 1 && run == 1 && activities.count == 3
    }
}
