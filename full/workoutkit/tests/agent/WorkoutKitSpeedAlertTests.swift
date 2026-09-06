import WorkoutKit
import Foundation

func testSpeedRangeAlert() {
    let unit = UnitSpeed.metersPerSecond
    let target = Measurement(value: 3, unit: unit) ... Measurement(value: 4, unit: unit)
    let alert = SpeedRangeAlert(target: target, metric: .current)
    wkRequire(alert.target.lowerBound.value == 3)
    wkRequire(alert.metric == .current)
    wkRequire(alert.targetQuantityLowerBound.doubleValue == 3)
    wkRequire(alert.targetQuantityUpperBound.doubleValue == 4)
    wkRequire(alert.supports(activity: .running, location: .outdoor))
    wkRequire(!alert.supports(activity: .yoga, location: .unknown))
    wkRequire(alert == SpeedRangeAlert(target: target, metric: .current))
    wkRequire(alert != SpeedRangeAlert(target: target, metric: .average))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == SpeedRangeAlert(target: target, metric: .current).hashValue)
}

func testSpeedThresholdAlert() {
    let target = Measurement(value: 4.5, unit: UnitSpeed.metersPerSecond)
    let alert = SpeedThresholdAlert(target: target, metric: .average)
    wkRequire(alert.target.value == 4.5)
    wkRequire(alert.metric == .average)
    wkRequire(alert.targetQuantity.doubleValue == 4.5)
    wkRequire(alert.supports(activity: .cycling, location: .outdoor))
    wkRequire(alert == SpeedThresholdAlert(target: target, metric: .average))
    wkRequire(alert != SpeedThresholdAlert(target: target, metric: .current))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == SpeedThresholdAlert(target: target, metric: .average).hashValue)
}

func testSpeedAlertFactories() {
    let range: SpeedRangeAlert = .speed(2.5 ... 3.5, unit: .metersPerSecond)
    wkRequire(range.metric == .current)
    let ranged: SpeedRangeAlert = .speed(1 ... 2, unit: .metersPerSecond, metric: .average)
    wkRequire(ranged.metric == .average)
    let threshold: SpeedThresholdAlert = .speed(5, unit: .metersPerSecond, metric: .current)
    wkRequire(threshold.target.value == 5)
}
