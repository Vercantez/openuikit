import Foundation
import EnergyKit

func testMeasurementGreaterThan() {
    let lhs = Measurement(value: 2, unit: UnitEnergy.joules)
    let rhs = Measurement(value: 1, unit: UnitEnergy.joules)
    energyKitExpect(lhs > rhs)
}

func testMeasurementGreaterThanOrEqual() {
    let value = Measurement(value: 3, unit: UnitEnergy.joules)
    energyKitExpect(value >= value)
    energyKitExpect(value >= Measurement(value: 1, unit: UnitEnergy.joules))
}

func testMeasurementLessThanOrEqual() {
    let value = Measurement(value: 1, unit: UnitEnergy.joules)
    energyKitExpect(value <= value)
    energyKitExpect(value <= Measurement(value: 4, unit: UnitEnergy.joules))
}

func testMeasurementNotEqual() {
    let lhs = Measurement(value: 2, unit: UnitEnergy.joules)
    let rhs = Measurement(value: 1, unit: UnitEnergy.joules)
    energyKitExpect(lhs != rhs)
}

func testMeasurementRange() {
    let minimum = Measurement(value: 1, unit: UnitEnergy.joules)
    let maximum = Measurement(value: 4, unit: UnitEnergy.joules)
    energyKitExpect((minimum..<maximum).contains(Measurement(value: 2, unit: UnitEnergy.joules)))
}

func testMeasurementPartialRangeUpTo() {
    let maximum = Measurement(value: 5, unit: UnitEnergy.joules)
    let range: PartialRangeUpTo<Measurement<UnitEnergy>> = ..<maximum
    energyKitExpectEqual(range.upperBound, maximum)
}

func testMeasurementPartialRangeFrom() {
    let minimum = Measurement(value: 2, unit: UnitEnergy.joules)
    let range: PartialRangeFrom<Measurement<UnitEnergy>> = minimum...
    energyKitExpectEqual(range.lowerBound, minimum)
}

func testMeasurementClosedRange() {
    let minimum = Measurement(value: 1, unit: UnitEnergy.joules)
    let maximum = Measurement(value: 3, unit: UnitEnergy.joules)
    energyKitExpect((minimum...maximum).contains(maximum))
}

func testMeasurementPartialRangeThrough() {
    let maximum = Measurement(value: 9, unit: UnitEnergy.joules)
    let range: PartialRangeThrough<Measurement<UnitEnergy>> = ...maximum
    energyKitExpectEqual(range.upperBound, maximum)
}

func testMilliwattHoursUnit() {
    energyKitExpectEqual(UnitEnergy.EnergyKit.milliwattHours.symbol, "mWh")
}

func testMilliwattHoursConversion() {
    let joules = Measurement(value: 3.6, unit: UnitEnergy.joules)
    let milliwattHours = joules.converted(to: UnitEnergy.EnergyKit.milliwattHours)
    energyKitExpectEqual(milliwattHours.value, 1.0)
}

func testUnitEnergyEnergyKitSymbolInit() {
    let unit = UnitEnergy.EnergyKit(symbol: "xWh")
    energyKitExpectEqual(unit.symbol, "xWh")
}

func testUnitEnergyEnergyKitCoderInit() {
    let unit = UnitEnergy.EnergyKit(symbol: "mWhX")
    let coder = NSKeyedArchiver(requiringSecureCoding: true)
    unit.encode(with: coder)
    coder.finishEncoding()
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: coder.encodedData)
        let restored = UnitEnergy.EnergyKit(coder: unarchiver)
        energyKitExpectEqual(restored?.symbol, "mWhX")
    } catch {
        preconditionFailure("UnitEnergy.EnergyKit coder round-trip failed: \(error)")
    }
}

func testUnitEnergyEnergyKitClass() {
    energyKitExpectEqual(String(describing: UnitEnergy.EnergyKit.self), "EnergyKit")
}
