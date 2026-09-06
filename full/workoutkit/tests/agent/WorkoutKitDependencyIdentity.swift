import Foundation
import HealthKit
import WorkoutKit

/// Future clean EC2 probe. Build real guest Foundation and HealthKit first,
/// then WorkoutKit with their -I/-L paths. This file is not part of the
/// isolated host gate and does not claim integrated Linux success.
let _: Foundation.UUID.Type = UUID.self
let _: Foundation.Measurement<UnitLength>.Type = Measurement<UnitLength>.self
let _: HealthKit.HKWorkoutActivityType.Type = HKWorkoutActivityType.self
let _: HealthKit.HKWorkoutSessionLocationType.Type = HKWorkoutSessionLocationType.self
let _: HealthKit.HKWorkoutSwimmingLocationType.Type = HKWorkoutSwimmingLocationType.self
let _: HealthKit.HKQuantity.Type = HKQuantity.self
let _: HealthKit.HKWorkout.Type = HKWorkout.self
let _: WorkoutKit.WorkoutPlan.Type = WorkoutPlan.self
let _: WorkoutKit.WorkoutGoal.Type = WorkoutGoal.self
let _: WorkoutKit.WorkoutScheduler.Type = WorkoutScheduler.self

let running = HealthKit.HKWorkoutActivityType.running
precondition(SingleGoalWorkout.supportsActivity(running))
let workout = SingleGoalWorkout(
    activity: running,
    location: .outdoor,
    goal: .open
)
precondition(workout.activity == running)
let plan = WorkoutPlan(.goal(workout))
precondition(plan.workout.activity == running)
precondition(WorkoutScheduler.isSupported == false)
precondition(WorkoutScheduler.maxAllowedScheduledWorkoutCount == 50)
precondition(WorkoutAlertMetric.countPerMinute.symbol == "count/min")

print("WORKOUTKIT_DEPENDENCY_IDENTITY_OK")
