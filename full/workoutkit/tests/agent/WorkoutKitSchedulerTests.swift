import WorkoutKit
import Foundation

func testWorkoutSchedulerFailClosed() {
    wkRequire(WorkoutScheduler.maxAllowedScheduledWorkoutCount == 50)
    wkRequire(WorkoutScheduler.isSupported == false)
    let shared = WorkoutScheduler.shared
    wkRequire(ObjectIdentifier(shared) == ObjectIdentifier(WorkoutScheduler.shared))
    _ = WorkoutScheduler.self
}

func testWorkoutAlertProtocolSurface() {
    let alert: any WorkoutAlert = HeartRateZoneAlert(zone: 3)
    wkRequire(alert.metric == .current)
    wkRequire(alert.supports(activity: .running, location: .outdoor))
    let power: any WorkoutAlert = PowerThresholdAlert(target: Measurement(value: 200, unit: .watts))
    wkRequire(!power.supports(activity: .running, location: .outdoor))
    wkRequire(power.supports(activity: .cycling, location: .indoor))
}
