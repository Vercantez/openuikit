import WorkoutKit
import Foundation

func testPowerRangeAlert() {
    let watts = UnitPower.watts
    let target = Measurement(value: 180, unit: watts) ... Measurement(value: 220, unit: watts)
    let alert = PowerRangeAlert(target: target, metric: .average)
    wkRequire(alert.target.lowerBound.value == 180)
    wkRequire(alert.metric == .average)
    wkRequire(alert.targetQuantityLowerBound.doubleValue == 180)
    wkRequire(alert.targetQuantityUpperBound.doubleValue == 220)
    var mutable = alert
    mutable.metric = .current
    wkRequire(mutable.metric == .current)
    let defaults = PowerRangeAlert(target: target)
    wkRequire(defaults.metric == .current)
    wkRequire(alert.supports(activity: .cycling, location: .outdoor))
    wkRequire(!alert.supports(activity: .running, location: .outdoor))
    wkRequire(alert != defaults)
    wkRequire(defaults == PowerRangeAlert(target: target, metric: .current))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(defaults.hashValue == PowerRangeAlert(target: target).hashValue)
}

func testPowerThresholdAlert() {
    let target = Measurement(value: 250, unit: UnitPower.watts)
    let alert = PowerThresholdAlert(target: target, metric: .average)
    wkRequire(alert.target.value == 250)
    wkRequire(alert.metric == .average)
    wkRequire(alert.targetQuantity.doubleValue == 250)
    var mutable = alert
    mutable.metric = .current
    wkRequire(mutable.metric == .current)
    let defaults = PowerThresholdAlert(target: target)
    wkRequire(defaults.metric == .current)
    wkRequire(alert.supports(activity: .handCycling, location: .indoor))
    wkRequire(!alert.supports(activity: .yoga, location: .unknown))
    wkRequire(alert != defaults)
    var hasher = Hasher()
    defaults.hash(into: &hasher)
    wkRequire(defaults.hashValue == PowerThresholdAlert(target: target).hashValue)
}

func testPowerZoneAlert() {
    let alert = PowerZoneAlert(zone: 5)
    wkRequire(alert.zone == 5)
    wkRequire(alert.metric == .current)
    wkRequire(alert.supports(activity: .cycling, location: .unknown))
    wkRequire(!alert.supports(activity: .swimming, location: .indoor))
    wkRequire(alert == PowerZoneAlert(zone: 5))
    wkRequire(alert != PowerZoneAlert(zone: 1))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == PowerZoneAlert(zone: 5).hashValue)
}

func testPowerAlertFactories() {
    let range: PowerRangeAlert = .power(200 ... 240, unit: .watts, metric: .average)
    wkRequire(range.target.lowerBound.value == 200)
    wkRequire(range.metric == .average)
    let rangeDefault: PowerRangeAlert = .power(100 ... 120, unit: .watts)
    wkRequire(rangeDefault.metric == .current)
    let threshold: PowerThresholdAlert = .power(300, unit: .watts, metric: .average)
    wkRequire(threshold.target.value == 300)
    let thresholdDefault: PowerThresholdAlert = .power(150, unit: UnitPower.watts)
    wkRequire(thresholdDefault.metric == .current)
    let zone: PowerZoneAlert = .power(zone: 3)
    wkRequire(zone.zone == 3)
}
