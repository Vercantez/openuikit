import WorkoutKit
import Foundation

func testWorkoutPlanIdentityAndRoundTrip() {
    let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let goal = SingleGoalWorkout(activity: .running, goal: .open)
    let plan = WorkoutPlan(.goal(goal), id: id)
    wkRequire(plan.id == id)
    wkRequire(WorkoutPlan.ID.self == UUID.self)
    wkRequire(plan.workout == .goal(goal))
    wkRequire(plan.workout.activity == .running)

    let data = try! plan.dataRepresentation
    let decoded = try! WorkoutPlan(from: data)
    wkRequire(decoded == plan)
    wkRequire(decoded.id == id)

    let pacer = WorkoutPlan(
        .pacer(
            PacerWorkout(
                activity: .cycling,
                distance: Measurement(value: 20, unit: .kilometers),
                time: Measurement(value: 40, unit: .minutes)
            )
        ),
        id: id
    )
    wkRequire(try! WorkoutPlan(from: try! pacer.dataRepresentation) == pacer)
    wkRequire(pacer.workout.activity == .cycling)

    let custom = WorkoutPlan(
        .custom(
            CustomWorkout(
                activity: .running,
                displayName: "Track",
                warmup: WorkoutStep(goal: .time(3, .minutes)),
                blocks: [
                    IntervalBlock(
                        steps: [IntervalStep(.work, goal: .time(60, .seconds))],
                        iterations: 2
                    ),
                ],
                cooldown: WorkoutStep(goal: .open)
            )
        ),
        id: id
    )
    wkRequire(try! WorkoutPlan(from: try! custom.dataRepresentation).workout == custom.workout)
    wkRequire(custom.workout.activity == .running)

    let triathlon = WorkoutPlan(
        .swimBikeRun(
            SwimBikeRunWorkout(
                activities: [
                    .swimming(.pool),
                    .cycling(.outdoor),
                    .running(.outdoor),
                ]
            )
        ),
        id: id
    )
    wkRequire(triathlon.workout.activity == .swimBikeRun)
    wkRequire(try! WorkoutPlan(from: try! triathlon.dataRepresentation) == triathlon)

    wkRequire(plan != pacer)
    var hasher = Hasher()
    plan.hash(into: &hasher)
    plan.workout.hash(into: &hasher)
    wkRequire(plan.hashValue == WorkoutPlan(.goal(goal), id: id).hashValue)
    wkRequire(plan.workout.hashValue == WorkoutPlan.Workout.goal(goal).hashValue)
}

func testWorkoutPlanRejectsUnknownFormat() {
    let junk = Data("not-a-plan".utf8)
    var threw = false
    do {
        _ = try WorkoutPlan(from: junk)
    } catch {
        threw = true
    }
    wkRequire(threw)

    let appleShaped = try! JSONSerialization.data(
        withJSONObject: ["format": "Apple.WorkoutKit.Unknown", "id": UUID().uuidString]
    )
    var formatThrew = false
    do {
        _ = try WorkoutPlan(from: appleShaped)
    } catch {
        formatThrew = true
    }
    wkRequire(formatThrew)
}

func testScheduledWorkoutPlan() {
    let plan = WorkoutPlan(.goal(SingleGoalWorkout(activity: .running)))
    var scheduled = ScheduledWorkoutPlan(plan, date: DateComponents(year: 2026, month: 9, day: 5))
    wkRequire(scheduled.plan == plan)
    wkRequire(scheduled.date.year == 2026)
    wkRequire(scheduled.complete == false)
    scheduled.complete = true
    scheduled.date.hour = 7
    wkRequire(scheduled.complete)
    wkRequire(scheduled.date.hour == 7)
    wkRequire(scheduled != ScheduledWorkoutPlan(plan, date: DateComponents(year: 2026, month: 9, day: 5)))
    var hasher = Hasher()
    scheduled.hash(into: &hasher)
    wkRequire(scheduled.hashValue != 0 || plan.hashValue != 0)
}
