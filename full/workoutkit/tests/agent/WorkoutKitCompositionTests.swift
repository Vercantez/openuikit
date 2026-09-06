import WorkoutKit
import Foundation

func testWorkoutStepInitAndEquality() {
    let step = WorkoutStep(
        goal: .time(5, .minutes),
        alert: HeartRateZoneAlert(zone: 3),
        displayName: "Warmup"
    )
    wkRequire(step.displayName == "Warmup")
    wkRequire(step.goal == .time(5, .minutes))
    wkRequire(step.alert is HeartRateZoneAlert)
    let named = step.alert as? HeartRateZoneAlert
    wkRequire(named?.zone == 3)

    let short = WorkoutStep(goal: .open, alert: nil)
    wkRequire(short.displayName == nil)
    wkRequire(short.goal == .open)
    wkRequire(short.alert == nil)

    let copy = WorkoutStep(
        goal: .time(5, .minutes),
        alert: HeartRateZoneAlert(zone: 3),
        displayName: "Warmup"
    )
    wkRequire(step == copy)
    wkRequire(step != short)
    var hasher = Hasher()
    step.hash(into: &hasher)
    wkRequire(step.hashValue == copy.hashValue)
}

func testIntervalStepAndBlock() {
    let work = IntervalStep(.work, goal: .distance(400, .meters), alert: nil)
    wkRequire(work.purpose == .work)
    wkRequire(work.step.goal == .distance(400, .meters))

    let recoveryStep = WorkoutStep(goal: .time(90, .seconds))
    let recovery = IntervalStep(.recovery, step: recoveryStep)
    wkRequire(recovery.purpose == .recovery)
    wkRequire(recovery.step == recoveryStep)
    wkRequire(work != recovery)

    let block = IntervalBlock(steps: [work, recovery], iterations: 4)
    wkRequire(block.steps.count == 2)
    wkRequire(block.iterations == 4)
    var mutated = block
    mutated.iterations = 8
    wkRequire(mutated.iterations == 8)
    wkRequire(block != mutated, "block mutated iterations")
    let blockCopy = IntervalBlock(steps: [work, recovery], iterations: 4)
    wkRequire(block == blockCopy, "block copy equal")
    var hasher = Hasher()
    work.hash(into: &hasher)
    block.hash(into: &hasher)
    let workCopy = IntervalStep(.work, goal: .distance(400, .meters))
    wkRequire(work == workCopy, "work copy equal")
    wkRequire(work.hashValue == workCopy.hashValue, "work hashValue")
    wkRequire(block.hashValue == blockCopy.hashValue, "block hashValue")
}
