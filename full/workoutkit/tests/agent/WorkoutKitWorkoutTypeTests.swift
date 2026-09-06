import WorkoutKit
import Foundation

func testSingleGoalWorkout() {
    let workout = SingleGoalWorkout(
        activity: .running,
        location: .outdoor,
        swimmingLocation: .unknown,
        goal: .distance(10, .kilometers)
    )
    wkRequire(workout.activity == .running)
    wkRequire(workout.location == .outdoor)
    wkRequire(workout.swimmingLocation == .unknown)
    wkRequire(workout.goal == .distance(10, .kilometers))
    var mutated = workout
    mutated.activity = .walking
    mutated.goal = .time(45, .minutes)
    wkRequire(mutated.activity == .walking)
    wkRequire(mutated.goal == .time(45, .minutes))
    wkRequire(workout != mutated)
    wkRequire(
        workout == SingleGoalWorkout(
            activity: .running,
            location: .outdoor,
            goal: .distance(10, .kilometers)
        )
    )
    var hasher = Hasher()
    workout.hash(into: &hasher)
    wkRequire(
        workout.hashValue
            == SingleGoalWorkout(
                activity: .running,
                location: .outdoor,
                goal: .distance(10, .kilometers)
            ).hashValue
    )
}

func testSingleGoalSupports() {
    wkRequire(SingleGoalWorkout.supportsActivity(.running))
    wkRequire(SingleGoalWorkout.supportsActivity(.cycling))
    wkRequire(!SingleGoalWorkout.supportsActivity(.play))
    wkRequire(!SingleGoalWorkout.supportsActivity(.transition))
    wkRequire(!SingleGoalWorkout.supportsActivity(.swimBikeRun))
    wkRequire(SingleGoalWorkout.supportsGoal(.open, activity: .running))
    wkRequire(SingleGoalWorkout.supportsGoal(.time(20, .minutes), activity: .yoga))
    wkRequire(SingleGoalWorkout.supportsGoal(.distance(5, .kilometers), activity: .running, location: .outdoor))
    wkRequire(!SingleGoalWorkout.supportsGoal(.distance(5, .kilometers), activity: .yoga))
    wkRequire(
        SingleGoalWorkout.supportsGoal(
            .poolSwimDistanceWithTime(
                Measurement(value: 400, unit: .meters),
                Measurement(value: 8, unit: .minutes)
            ),
            activity: .swimming,
            location: .indoor
        )
    )
    wkRequire(
        !SingleGoalWorkout.supportsGoal(
            .poolSwimDistanceWithTime(
                Measurement(value: 400, unit: .meters),
                Measurement(value: 8, unit: .minutes)
            ),
            activity: .swimming,
            location: .outdoor
        )
    )
    wkRequire(!SingleGoalWorkout.supportsGoal(.open, activity: .play))
}

func testPacerWorkout() {
    let workout = PacerWorkout(
        activity: .running,
        location: .outdoor,
        distance: Measurement(value: 5, unit: .kilometers),
        time: Measurement(value: 25, unit: .minutes)
    )
    wkRequire(workout.activity == .running)
    wkRequire(workout.location == .outdoor)
    wkRequire(workout.distance.value == 5)
    wkRequire(workout.time.value == 25)
    var mutated = workout
    mutated.activity = .walking
    mutated.distance = Measurement(value: 3, unit: .kilometers)
    mutated.time = Measurement(value: 30, unit: .minutes)
    wkRequire(mutated.activity == .walking)
    wkRequire(workout != mutated)
    wkRequire(PacerWorkout.supportsActivity(.running))
    wkRequire(PacerWorkout.supportsActivity(.swimming))
    wkRequire(PacerWorkout.supportsActivity(.wheelchairRunPace))
    wkRequire(!PacerWorkout.supportsActivity(.yoga))
    var hasher = Hasher()
    workout.hash(into: &hasher)
    wkRequire(
        workout.hashValue
            == PacerWorkout(
                activity: .running,
                location: .outdoor,
                distance: Measurement(value: 5, unit: .kilometers),
                time: Measurement(value: 25, unit: .minutes)
            ).hashValue
    )
}

func testCustomWorkout() {
    let warmup = WorkoutStep(goal: .time(5, .minutes), displayName: "WU")
    let work = IntervalStep(.work, goal: .time(1, .minutes))
    let block = IntervalBlock(steps: [work], iterations: 3)
    let cooldown = WorkoutStep(goal: .time(3, .minutes))
    let workout = CustomWorkout(
        activity: .running,
        location: .indoor,
        displayName: "Intervals",
        warmup: warmup,
        blocks: [block],
        cooldown: cooldown
    )
    wkRequire(workout.activity == .running)
    wkRequire(workout.location == .indoor)
    wkRequire(workout.displayName == "Intervals")
    wkRequire(workout.warmup == warmup)
    wkRequire(workout.blocks.count == 1)
    wkRequire(workout.cooldown == cooldown)
    var mutated = workout
    mutated.location = .outdoor
    mutated.activity = .cycling
    mutated.blocks = []
    wkRequire(mutated.location == .outdoor)
    wkRequire(workout != mutated)
    wkRequire(CustomWorkout.supportsActivity(.running))
    wkRequire(!CustomWorkout.supportsActivity(.cooldown))
    wkRequire(CustomWorkout.supportsGoal(.energy(300, .kilocalories), activity: .cycling))
    let hr: HeartRateRangeAlert = .heartRate(140 ... 160)
    wkRequire(CustomWorkout.supportsAlert(hr, activity: .running, location: .outdoor))
    let power: PowerZoneAlert = .power(zone: 3)
    wkRequire(!CustomWorkout.supportsAlert(power, activity: .running, location: .outdoor))
    wkRequire(CustomWorkout.supportsAlert(power, activity: .cycling))
    var hasher = Hasher()
    workout.hash(into: &hasher)
    wkRequire(workout.hashValue == workout.hashValue)
}

func testSwimBikeRunWorkout() {
    let activities: [SwimBikeRunWorkout.Activity] = [
        .swimming(.pool),
        .cycling(.outdoor),
        .running(.outdoor),
    ]
    let workout = SwimBikeRunWorkout(activities: activities, displayName: "Olympic")
    wkRequire(workout.activities.count == 3)
    wkRequire(workout.displayName == "Olympic")
    wkRequire(SwimBikeRunWorkout.supportsActivityOrdering(activities))
    wkRequire(
        SwimBikeRunWorkout.supportsActivityOrdering([
            .running(.indoor),
            .swimming(.openWater),
            .cycling(.indoor),
        ])
    )
    wkRequire(
        !SwimBikeRunWorkout.supportsActivityOrdering([
            .swimming(.pool),
            .cycling(.outdoor),
        ])
    )
    wkRequire(
        !SwimBikeRunWorkout.supportsActivityOrdering([
            .swimming(.pool),
            .swimming(.openWater),
            .running(.outdoor),
        ])
    )
    var mutated = workout
    mutated.activities = [.running(.outdoor), .cycling(.outdoor), .swimming(.pool)]
    wkRequire(workout != mutated)
    wkRequire(
        workout == SwimBikeRunWorkout(activities: activities, displayName: "Olympic")
    )
    var hasher = Hasher()
    workout.hash(into: &hasher)
    wkRequire(
        workout.hashValue
            == SwimBikeRunWorkout(activities: activities, displayName: "Olympic").hashValue
    )
}
