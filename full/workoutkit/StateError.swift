import Foundation

/// Fail-closed errors for Watch pairing and Workout app presence.
/// Linux never reports a paired watch or an installed Workout app, so
/// `HKWorkout.workoutPlan` throws `watchNotPaired` rather than inventing a
/// stored plan.
public enum StateError: Error, Hashable, Sendable {
    case watchNotPaired
    case workoutApplicationNotInstalled
}

extension StateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .watchNotPaired:
            return "No paired Apple Watch is available."
        case .workoutApplicationNotInstalled:
            return "The Workout application is not installed."
        }
    }
}
