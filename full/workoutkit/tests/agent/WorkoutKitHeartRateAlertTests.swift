import WorkoutKit
import Foundation

func testHeartRateRangeAlert() {
    let unit = WorkoutAlertMetric.countPerMinute
    let target = Measurement(value: 120, unit: unit) ... Measurement(value: 150, unit: unit)
    let alert = HeartRateRangeAlert(target: target)
    wkRequire(alert.target.lowerBound.value == 120)
    wkRequire(alert.target.upperBound.value == 150)
    wkRequire(alert.metric == .current)
    wkRequire(alert.targetQuantityLowerBound.doubleValue == 120)
    wkRequire(alert.targetQuantityUpperBound.doubleValue == 150)
    wkRequire(alert.supports(activity: .running, location: .outdoor))
    wkRequire(alert == HeartRateRangeAlert(target: target))
    wkRequire(alert != HeartRateRangeAlert(
        target: Measurement(value: 100, unit: unit) ... Measurement(value: 110, unit: unit)
    ))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == HeartRateRangeAlert(target: target).hashValue)
}

func testHeartRateZoneAlert() {
    let alert = HeartRateZoneAlert(zone: 4)
    wkRequire(alert.zone == 4)
    wkRequire(alert.metric == .current)
    wkRequire(alert.supports(activity: .running, location: .indoor))
    wkRequire(alert == HeartRateZoneAlert(zone: 4))
    wkRequire(alert != HeartRateZoneAlert(zone: 2))
    var hasher = Hasher()
    alert.hash(into: &hasher)
    wkRequire(alert.hashValue == HeartRateZoneAlert(zone: 4).hashValue)
}

func testHeartRateAlertFactories() {
    let range: HeartRateRangeAlert = .heartRate(130 ... 160)
    wkRequire(range.target.lowerBound.value == 130)
    wkRequire(range.target.upperBound.unit.symbol == "count/min")
    let custom: HeartRateRangeAlert = .heartRate(60 ... 80, unit: UnitFrequency.hertz)
    wkRequire(custom.target.lowerBound.unit.symbol == "Hz")
    let zone: HeartRateZoneAlert = .heartRate(zone: 2)
    wkRequire(zone.zone == 2)
    let proto: any WorkoutAlert = HeartRateRangeAlert.heartRate(100 ... 110)
    wkRequire(proto.metric == .current)
}
