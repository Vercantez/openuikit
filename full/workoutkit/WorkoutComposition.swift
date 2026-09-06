import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// A single goal, optional alert, and optional display name.
public struct WorkoutStep: Hashable, Sendable {
    public var goal: WorkoutGoal
    public var displayName: String?
    private var alertBox: WorkoutAlertBox?

    public var alert: (any WorkoutAlert)? {
        get { alertBox?.alert }
        set { alertBox = newValue.flatMap(WorkoutAlertBox.init) }
    }

    public init(
        goal: WorkoutGoal = .open,
        alert: (any WorkoutAlert)? = nil,
        displayName: String? = nil
    ) {
        self.goal = goal
        self.alertBox = alert.flatMap(WorkoutAlertBox.init)
        self.displayName = displayName
    }

    public init(goal: WorkoutGoal = .open, alert: (any WorkoutAlert)? = nil) {
        self.init(goal: goal, alert: alert, displayName: nil)
    }

    public static func == (lhs: WorkoutStep, rhs: WorkoutStep) -> Bool {
        lhs.goal == rhs.goal
            && lhs.displayName == rhs.displayName
            && lhs.alertBox == rhs.alertBox
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(goal)
        hasher.combine(displayName)
        hasher.combine(alertBox)
    }
}

/// One work or recovery step inside an `IntervalBlock`.
public struct IntervalStep: Hashable, Sendable {
    public enum Purpose: Hashable, Sendable {
        case work
        case recovery
    }

    public let purpose: Purpose
    public let step: WorkoutStep

    public init(_ purpose: Purpose, step: WorkoutStep) {
        self.purpose = purpose
        self.step = step
    }

    public init(
        _ purpose: Purpose,
        goal: WorkoutGoal = .open,
        alert: (any WorkoutAlert)? = nil
    ) {
        self.init(purpose, step: WorkoutStep(goal: goal, alert: alert))
    }
}

/// A repeated sequence of interval steps.
public struct IntervalBlock: Hashable, Sendable {
    public let steps: [IntervalStep]
    public var iterations: Int

    public init(steps: [IntervalStep] = [], iterations: Int = 1) {
        self.steps = steps
        self.iterations = iterations
    }
}
