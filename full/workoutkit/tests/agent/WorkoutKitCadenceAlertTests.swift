import WorkoutKit
import Foundation

func testCadenceRangeAlert() {
    let unit = WorkoutAlertMetric.countPerMinute
    let target = Measurement(value: 80, unit: unit) ... Measurement(value: 100, unit: unit)
    let alert = CadenceRangeAlert(target: target)
    wkRequire(alert.target.lowerBound.value == 80)
    wkRequire(alert.metric == .current)
    wkRequire(alert.targetQuantityLowerBound.doubleValue == 80)
    wkRequire(alert.targetQuantityUpperBound.doubleValue == 100)
    wkRequire(alert.supports(activity: .running, location: .outdoor))
    wkRequire(!alert.supports(activity: .swimming, location: .indoor))
    wkRequire(alert == CadenceRangeAlert(target: target))
    wkRequire(alert != CadenceRangeAlert(
        target: Measurement(value: 70, unit: unit) ... Measurement(value: 75, unit: unit)
    ))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == CadenceRangeAlert(target: target).hashValue)
}

func testCadenceThresholdAlert() {
    let target = Measurement(value: 90, unit: WorkoutAlertMetric.countPerMinute)
    let alert = CadenceThresholdAlert(target: target)
    wkRequire(alert.target.value == 90)
    wkRequire(alert.metric == .current)
    wkRequire(alert.targetQuantity.doubleValue == 90)
    wkRequire(alert.supports(activity: .cycling, location: .indoor))
    wkRequire(alert == CadenceThresholdAlert(target: target))
    wkRequire(alert != CadenceThresholdAlert(target: Measurement(value: 70, unit: WorkoutAlertMetric.countPerMinute)))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == CadenceThresholdAlert(target: target).hashValue)
}

func testCadenceAlertFactories() {
    let range: CadenceRangeAlert = .cadence(85 ... 95)
    wkRequire(range.target.lowerBound.unit.symbol == "count/min")
    let custom: CadenceRangeAlert = .cadence(1 ... 2, unit: UnitFrequency.hertz)
    wkRequire(custom.target.upperBound.unit.symbol == UnitFrequency.hertz.symbol)
    let threshold: CadenceThresholdAlert = .cadence(88)
    wkRequire(threshold.target.value == 88)
    let thresholdUnit: CadenceThresholdAlert = .cadence(40, unit: UnitFrequency.hertz)
    wkRequire(thresholdUnit.target.unit.symbol == UnitFrequency.hertz.symbol)
}
