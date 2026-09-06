import WorkoutKit
import Foundation

func wkRequire(_ condition: Bool, _ message: String = "assertion failed") {
    precondition(condition, message)
}

func testAuthorizationStateRawValues() {
    let rows: [(WorkoutScheduler.AuthorizationState, Int)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.authorized, 3),
    ]
    for (value, raw) in rows {
        wkRequire(value.rawValue == raw, "raw \(raw)")
        wkRequire(WorkoutScheduler.AuthorizationState(rawValue: raw) == value)
    }
    wkRequire(WorkoutScheduler.AuthorizationState(rawValue: 4) == nil)
    wkRequire(WorkoutScheduler.AuthorizationState(rawValue: -1) == nil)
    wkRequire(WorkoutScheduler.AuthorizationState.RawValue.self == Int.self)
    wkRequire(WorkoutScheduler.AuthorizationState.notDetermined != .denied)
    var hasher = Hasher()
    WorkoutScheduler.AuthorizationState.authorized.hash(into: &hasher)
    wkRequire(WorkoutScheduler.AuthorizationState.authorized.hashValue != 0
        || WorkoutScheduler.AuthorizationState.denied.hashValue != 0)
}

func testIntervalStepPurposeCases() {
    wkRequire(IntervalStep.Purpose.work != .recovery)
    wkRequire(IntervalStep.Purpose.work == .work)
    var hasher = Hasher()
    IntervalStep.Purpose.work.hash(into: &hasher)
    wkRequire(IntervalStep.Purpose.work.hashValue == IntervalStep.Purpose.work.hashValue)
    wkRequire(IntervalStep.Purpose.recovery.hashValue != 0
        || IntervalStep.Purpose.work.hashValue != 0)
}

func testWorkoutAlertMetricCases() {
    wkRequire(WorkoutAlertMetric.current != .average)
    wkRequire(WorkoutAlertMetric.current == .current)
    wkRequire(WorkoutAlertMetric.average == .average)
    wkRequire(WorkoutAlertMetric.countPerMinute.symbol == "count/min")
    var hasher = Hasher()
    WorkoutAlertMetric.current.hash(into: &hasher)
    wkRequire(WorkoutAlertMetric.current.hashValue == WorkoutAlertMetric.current.hashValue)
}

func testWorkoutGoalCases() {
    let open = WorkoutGoal.open
    let time = WorkoutGoal.time(30, .minutes)
    let energy = WorkoutGoal.energy(200, .kilocalories)
    let distance = WorkoutGoal.distance(5, .kilometers)
    let pool = WorkoutGoal.poolSwimDistanceWithTime(
        Measurement(value: 400, unit: .meters),
        Measurement(value: 8, unit: .minutes)
    )
    wkRequire(open != time)
    wkRequire(time != energy)
    wkRequire(energy != distance)
    wkRequire(distance != pool)
    wkRequire(open == .open)
    var hasher = Hasher()
    open.hash(into: &hasher)
    time.hash(into: &hasher)
    wkRequire(open.hashValue == WorkoutGoal.open.hashValue)
}

func testStateErrorCases() {
    wkRequire(StateError.watchNotPaired != .workoutApplicationNotInstalled)
    wkRequire(StateError.watchNotPaired == .watchNotPaired)
    wkRequire(StateError.workoutApplicationNotInstalled == .workoutApplicationNotInstalled)
    var hasher = Hasher()
    StateError.watchNotPaired.hash(into: &hasher)
    wkRequire(StateError.watchNotPaired.hashValue == StateError.watchNotPaired.hashValue)
    let paired: Error = StateError.watchNotPaired
    wkRequire(!paired.localizedDescription.isEmpty)
    let missing: Error = StateError.workoutApplicationNotInstalled
    wkRequire(!missing.localizedDescription.isEmpty)
}

func testSwimBikeRunActivityCases() {
    let swim = SwimBikeRunWorkout.Activity.swimming(.pool)
    let bike = SwimBikeRunWorkout.Activity.cycling(.outdoor)
    let run = SwimBikeRunWorkout.Activity.running(.outdoor)
    wkRequire(swim != bike)
    wkRequire(bike != run)
    wkRequire(swim == .swimming(.pool))
    var hasher = Hasher()
    swim.hash(into: &hasher)
    wkRequire(swim.hashValue == SwimBikeRunWorkout.Activity.swimming(.pool).hashValue)
}
