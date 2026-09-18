import WorkoutKit
import Foundation

private func wkAsyncPlan() -> WorkoutPlan {
    WorkoutPlan(.goal(SingleGoalWorkout(activity: .running, goal: .open)))
}

private func wkAsyncDate() -> DateComponents {
    DateComponents(year: 2026, month: 9, day: 5)
}

func testSchedulerScheduleAsync() async {
    await WorkoutScheduler.shared.schedule(wkAsyncPlan(), at: wkAsyncDate())
    let list = await WorkoutScheduler.shared.scheduledWorkouts
    wkRequire(list.isEmpty)
}

func testSchedulerRemoveAsync() async {
    await WorkoutScheduler.shared.remove(wkAsyncPlan(), at: wkAsyncDate())
    let list = await WorkoutScheduler.shared.scheduledWorkouts
    wkRequire(list.isEmpty)
}

func testSchedulerMarkCompleteAsync() async {
    await WorkoutScheduler.shared.markComplete(wkAsyncPlan(), at: wkAsyncDate())
    let list = await WorkoutScheduler.shared.scheduledWorkouts
    wkRequire(list.isEmpty)
}

func testSchedulerRemoveAllWorkoutsAsync() async {
    await WorkoutScheduler.shared.removeAllWorkouts()
    let list = await WorkoutScheduler.shared.scheduledWorkouts
    wkRequire(list.isEmpty)
}

func testSchedulerScheduledWorkoutsAsync() async {
    let scheduledWorkouts = await WorkoutScheduler.shared.scheduledWorkouts
    wkRequire(scheduledWorkouts.isEmpty)
}

func testSchedulerAuthorizationStateAsync() async {
    let authorizationState = await WorkoutScheduler.shared.authorizationState
    wkRequire(authorizationState == .notDetermined)
}

func testSchedulerRequestAuthorizationAsync() async {
    let state = await WorkoutScheduler.shared.requestAuthorization()
    wkRequire(state == .denied)
    wkRequire(state != .authorized)
}

func testHKWorkoutPlanAsync() async {
    let workout = HKWorkout()
    do {
        _ = try await workout.workoutPlan
        wkRequire(false, "workoutPlan should throw")
    } catch let error as StateError {
        wkRequire(error == .watchNotPaired)
    } catch {
        wkRequire(false, "unexpected error type")
    }
}
