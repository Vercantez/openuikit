import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// Documented support matrices for WorkoutKit activity / goal / alert
/// combinations. Exact Apple tables for every `HKWorkoutActivityType` are
/// unobserved on this host and are recorded as oracle questions; the sets
/// below follow Apple's public WorkoutKit documentation (pacer sports,
/// triathlon ordering, pool-swim goals, power vs cadence vs heart-rate
/// sports).
enum WorkoutSupport {
    static func isStructuredActivity(_ activity: HKWorkoutActivityType) -> Bool {
        switch activity {
        case .play, .preparationAndRecovery, .transition, .cooldown, .swimBikeRun:
            return false
        default:
            return true
        }
    }

    static func isPacerActivity(_ activity: HKWorkoutActivityType) -> Bool {
        switch activity {
        case .running, .walking, .cycling, .swimming,
             .wheelchairWalkPace, .wheelchairRunPace:
            return true
        default:
            return false
        }
    }

    static func isDistanceActivity(_ activity: HKWorkoutActivityType) -> Bool {
        switch activity {
        case .running, .walking, .cycling, .swimming, .hiking,
             .wheelchairWalkPace, .wheelchairRunPace, .rowing,
             .elliptical, .stairs, .stairClimbing, .handCycling,
             .skatingSports, .downhillSkiing, .crossCountrySkiing,
             .snowboarding, .paddleSports, .surfingSports, .sailing,
             .waterSports, .golf, .discSports, .climbing:
            return true
        default:
            return false
        }
    }

    static func isPowerActivity(_ activity: HKWorkoutActivityType) -> Bool {
        switch activity {
        case .cycling, .handCycling:
            return true
        default:
            return false
        }
    }

    static func isSpeedActivity(_ activity: HKWorkoutActivityType) -> Bool {
        switch activity {
        case .running, .walking, .cycling, .swimming, .hiking,
             .wheelchairWalkPace, .wheelchairRunPace, .rowing,
             .elliptical, .handCycling:
            return true
        default:
            return false
        }
    }

    static func isCadenceActivity(_ activity: HKWorkoutActivityType) -> Bool {
        switch activity {
        case .running, .walking, .cycling, .wheelchairWalkPace,
             .wheelchairRunPace, .hiking, .elliptical:
            return true
        default:
            return false
        }
    }

    static func supportsGoal(
        _ goal: WorkoutGoal,
        activity: HKWorkoutActivityType,
        location: HKWorkoutSessionLocationType
    ) -> Bool {
        guard isStructuredActivity(activity) else { return false }
        switch goal {
        case .open, .time, .energy:
            return true
        case .distance:
            return isDistanceActivity(activity)
        case .poolSwimDistanceWithTime:
            return activity == .swimming && location != .outdoor
        }
    }
}
