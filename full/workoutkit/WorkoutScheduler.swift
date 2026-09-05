import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// Schedules workout plans onto a paired Apple Watch.
///
/// Linux has no Watch pairing daemon and no WorkoutKit entitlement, so
/// `isSupported` is `false`, authorization never becomes `.authorized`,
/// and the scheduled list stays empty.
public final class WorkoutScheduler: @unchecked Sendable {
    public static let shared = WorkoutScheduler()

    /// Documented Apple maximum of fifty scheduled workouts.
    public static let maxAllowedScheduledWorkoutCount = 50

    public static var isSupported: Bool { false }

    public enum AuthorizationState: Int, Sendable, Hashable {
        case notDetermined = 0
        case restricted = 1
        case denied = 2
        case authorized = 3
    }

    public var scheduledWorkouts: [ScheduledWorkoutPlan] {
        get async { [] }
    }

    public var authorizationState: AuthorizationState {
        get async { .notDetermined }
    }

    public func requestAuthorization() async -> AuthorizationState {
        .denied
    }

    public func schedule(_ workout: WorkoutPlan, at: DateComponents) async {
        _ = workout
        _ = at
    }

    public func remove(_ workout: WorkoutPlan, at: DateComponents) async {
        _ = workout
        _ = at
    }

    public func markComplete(_ workout: WorkoutPlan, at: DateComponents) async {
        _ = workout
        _ = at
    }

    public func removeAllWorkouts() async {}
}
