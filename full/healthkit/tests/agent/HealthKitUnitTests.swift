import Foundation
import HealthKit

private func hkRequire(_ condition: Bool, _ message: String = "") {
    if !condition {
        fputs("HealthKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

private func hkWait(_ body: @escaping @Sendable () async throws -> Void) {
    let lock = DispatchSemaphore(value: 0)
    Task {
        do { try await body() } catch { hkRequire(false, "async \(error)") }
        lock.signal()
    }
    hkRequire(lock.wait(timeout: .now() + 8) == .success, "async timeout")
}

private func hkAuthorize(_ types: Set<HKSampleType>) {
    HKHealthStorePortable._installAuthorizationHandler { _, _ in .sharingAuthorized }
    let lock = DispatchSemaphore(value: 0)
    HKHealthStore().requestAuthorization(toShare: types, read: types) { _, _ in lock.signal() }
    hkRequire(lock.wait(timeout: .now() + 5) == .success, "auth")
}

func testUnitFactories() {
    _ = HKUnit.appleEffortScore()
    _ = HKUnit.atmosphere()
    _ = HKUnit.calorie()
    _ = HKUnit.centimeterOfWater()
    _ = HKUnit.count()
    _ = HKUnit.cupImperial()
    _ = HKUnit.cupUS()
    _ = HKUnit.day()
    _ = HKUnit.decibelAWeightedSoundPressureLevel()
    _ = HKUnit.decibelHearingLevel()
    _ = HKUnit.degreeAngle()
    _ = HKUnit.degreeCelsius()
    _ = HKUnit.degreeFahrenheit()
    _ = HKUnit.diopter()
    _ = HKUnit.fluidOunceImperial()
    _ = HKUnit.fluidOunceUS()
    _ = HKUnit.foot()
    _ = HKUnit.gram()
    _ = HKUnit.gramUnit(with: .kilo)
    _ = HKUnit.hertz()
    _ = HKUnit.hertzUnit(with: .kilo)
    _ = HKUnit.hour()
    _ = HKUnit.inch()
    _ = HKUnit.inchesOfMercury()
    _ = HKUnit.internationalUnit()
    _ = HKUnit.joule()
    _ = HKUnit.jouleUnit(with: .kilo)
    _ = HKUnit.kelvin()
    _ = HKUnit.kilocalorie()
    _ = HKUnit.largeCalorie()
    _ = HKUnit.liter()
    _ = HKUnit.literUnit(with: .milli)
    _ = HKUnit.lux()
    _ = HKUnit.luxUnit(with: .kilo)
    _ = HKUnit.meter()
    _ = HKUnit.meterUnit(with: .kilo)
    _ = HKUnit.mile()
    _ = HKUnit.millimeterOfMercury()
    _ = HKUnit.minute()
    _ = HKUnit.moleUnit(withMolarMass: HKUnitMolarMassBloodGlucose)
    _ = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
    _ = HKUnit.ounce()
    _ = HKUnit.pascal()
    _ = HKUnit.pascalUnit(with: .kilo)
    _ = HKUnit.percent()
    _ = HKUnit.pintImperial()
    _ = HKUnit.pintUS()
    _ = HKUnit.pound()
    _ = HKUnit.prismDiopter()
    _ = HKUnit.radianAngle()
    _ = HKUnit.radianAngleUnit(with: .milli)
    _ = HKUnit.second()
    _ = HKUnit.secondUnit(with: .milli)
    _ = HKUnit.siemen()
    _ = HKUnit.siemenUnit(with: .milli)
    _ = HKUnit.smallCalorie()
    _ = HKUnit.stone()
    _ = HKUnit.volt()
    _ = HKUnit.voltUnit(with: .milli)
    _ = HKUnit.watt()
    _ = HKUnit.wattUnit(with: .kilo)
    _ = HKUnit.yard()
    hkRequire(HKUnit.gram().unitString == "g" || HKUnit.gram().unitString.contains("g"), "gram string")
}

func testUnitAlgebraAndConversion() {
    let gram = HKUnit.gram()
    let kilogram = HKUnit.gramUnit(with: .kilo)
    hkRequire(gram.`is`(compatibleWith: kilogram), "g/kg")
    hkRequire(!gram.`is`(compatibleWith: HKUnit.meter()), "g not m")
    hkRequire(!gram.isNull(), "not null")
    _ = gram.reciprocal()
    _ = gram.unitMultiplied(by: HKUnit.meter())
    _ = HKUnit.meter().unitDivided(by: HKUnit.second())
    _ = HKUnit.count().unitRaised(toPower: 1)
    let qty = HKQuantity(unit: kilogram, doubleValue: 2)
    hkRequire(abs(qty.doubleValue(for: gram) - 2000) < 1e-9, "2kg")
    _ = qty.compare(HKQuantity(unit: gram, doubleValue: 1))
    _ = qty.`is`(compatibleWith: gram)
    hkRequire(HKUnit.unit("kg")?.`is`(compatibleWith: kilogram) == true, "parse kg")
    hkRequire(HKUnit.unit("count/min") != nil, "count/min")
    hkRequire(HKUnit.unit("m/s") != nil, "m/s")
    hkRequire(HKUnit.unit("kcal")?.unitString == "kcal", "kcal")
    hkRequire(HKUnit(from: "degC").`is`(compatibleWith: .degreeCelsius()), "degC")
    _ = HKUnit(from: EnergyFormatter.Unit.kilocalorie)
    _ = HKUnit.energyFormatterUnit(from: .kilocalorie())
    _ = HKUnit.lengthFormatterUnit(from: .mile())
    _ = HKUnit.massFormatterUnit(from: .pound())
    _ = HKMetricPrefixFactors.factor(.kilo)
    _ = HKMetricPrefixFactors.symbol(.kilo)
    _ = kilogram.dimension.mass
}
