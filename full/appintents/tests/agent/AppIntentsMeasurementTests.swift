import Foundation
import AppIntents

private enum MeasureKind: String, AppEnum {
    case length
    case volume
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Measure Kind" }
    static var caseDisplayRepresentations: [MeasureKind: DisplayRepresentation] {
        [.length: "Length", .volume: "Volume"]
    }
}

private struct MeasureFileHolder: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Measure File" }
    static var defaultQuery = MeasureFileQuery()
    var id: String
    var document: File
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id)
    }
}

private struct MeasureFileQuery: EntityQuery {
    typealias Entity = MeasureFileHolder
    init() {}
    func entities(for identifiers: [String]) async throws -> [MeasureFileHolder] {
        EntityResolutionEngine.entities(for: identifiers, as: MeasureFileHolder.self)
    }
    func suggestedEntities() async throws -> [MeasureFileHolder] {
        EntityResolutionEngine.suggestedEntities(MeasureFileHolder.self)
    }
}

func testIntentParameterVolumeUnitTable() {
    let cases = IntentParameter<Measurement<UnitVolume>>.Volume.allCases
    precondition(cases.count == 31)
    precondition(Set(cases).count == 31)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitVolume>>.Volume.liters.rawValue == "liters")
    let _: IntentParameter<Measurement<UnitVolume>>.Volume.AllCases = IntentParameter<Measurement<UnitVolume>>.Volume.allCases
    var context = IntentParameterContext<Measurement<UnitVolume>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitVolume>>.Volume.liters
    context.storedUnit = IntentParameter<Measurement<UnitVolume>>.Volume.gallons
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .liters)
    precondition(context.unit == .gallons)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterLengthUnitTable() {
    let cases = IntentParameter<Measurement<UnitLength>>.Length.allCases
    precondition(cases.count == 22)
    precondition(Set(cases).count == 22)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitLength>>.Length.meters.rawValue == "meters")
    let _: IntentParameter<Measurement<UnitLength>>.Length.AllCases = IntentParameter<Measurement<UnitLength>>.Length.allCases
    var context = IntentParameterContext<Measurement<UnitLength>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitLength>>.Length.meters
    context.storedUnit = IntentParameter<Measurement<UnitLength>>.Length.feet
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .meters)
    precondition(context.unit == .feet)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterInformationStorageUnitTable() {
    let cases = IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases
    precondition(cases.count == 35)
    precondition(Set(cases).count == 35)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.bytes.rawValue == "bytes")
    let _: IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.AllCases = IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases
    var context = IntentParameterContext<Measurement<UnitInformationStorage>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.bytes
    context.storedUnit = IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.megabytes
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .bytes)
    precondition(context.unit == .megabytes)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterMassUnitTable() {
    let cases = IntentParameter<Measurement<UnitMass>>.Mass.allCases
    precondition(cases.count == 16)
    precondition(Set(cases).count == 16)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitMass>>.Mass.grams.rawValue == "grams")
    let _: IntentParameter<Measurement<UnitMass>>.Mass.AllCases = IntentParameter<Measurement<UnitMass>>.Mass.allCases
    var context = IntentParameterContext<Measurement<UnitMass>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitMass>>.Mass.grams
    context.storedUnit = IntentParameter<Measurement<UnitMass>>.Mass.kilograms
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .grams)
    precondition(context.unit == .kilograms)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterAreaUnitTable() {
    let cases = IntentParameter<Measurement<UnitArea>>.Area.allCases
    precondition(cases.count == 14)
    precondition(Set(cases).count == 14)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitArea>>.Area.acres.rawValue == "acres")
    let _: IntentParameter<Measurement<UnitArea>>.Area.AllCases = IntentParameter<Measurement<UnitArea>>.Area.allCases
    var context = IntentParameterContext<Measurement<UnitArea>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitArea>>.Area.acres
    context.storedUnit = IntentParameter<Measurement<UnitArea>>.Area.hectares
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .acres)
    precondition(context.unit == .hectares)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterPowerUnitTable() {
    let cases = IntentParameter<Measurement<UnitPower>>.Power.allCases
    precondition(cases.count == 11)
    precondition(Set(cases).count == 11)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitPower>>.Power.watts.rawValue == "watts")
    let _: IntentParameter<Measurement<UnitPower>>.Power.AllCases = IntentParameter<Measurement<UnitPower>>.Power.allCases
    var context = IntentParameterContext<Measurement<UnitPower>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitPower>>.Power.watts
    context.storedUnit = IntentParameter<Measurement<UnitPower>>.Power.kilowatts
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .watts)
    precondition(context.unit == .kilowatts)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterPressureUnitTable() {
    let cases = IntentParameter<Measurement<UnitPressure>>.Pressure.allCases
    precondition(cases.count == 10)
    precondition(Set(cases).count == 10)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitPressure>>.Pressure.bars.rawValue == "bars")
    let _: IntentParameter<Measurement<UnitPressure>>.Pressure.AllCases = IntentParameter<Measurement<UnitPressure>>.Pressure.allCases
    var context = IntentParameterContext<Measurement<UnitPressure>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitPressure>>.Pressure.bars
    context.storedUnit = IntentParameter<Measurement<UnitPressure>>.Pressure.millibars
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .bars)
    precondition(context.unit == .millibars)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterFrequencyUnitTable() {
    let cases = IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases
    precondition(cases.count == 9)
    precondition(Set(cases).count == 9)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitFrequency>>.Frequency.hertz.rawValue == "hertz")
    let _: IntentParameter<Measurement<UnitFrequency>>.Frequency.AllCases = IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases
    var context = IntentParameterContext<Measurement<UnitFrequency>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitFrequency>>.Frequency.hertz
    context.storedUnit = IntentParameter<Measurement<UnitFrequency>>.Frequency.kilohertz
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .hertz)
    precondition(context.unit == .kilohertz)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterDurationUnitTable() {
    let cases = IntentParameter<Measurement<UnitDuration>>.Duration.allCases
    precondition(cases.count == 7)
    precondition(Set(cases).count == 7)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitDuration>>.Duration.seconds.rawValue == "seconds")
    let _: IntentParameter<Measurement<UnitDuration>>.Duration.AllCases = IntentParameter<Measurement<UnitDuration>>.Duration.allCases
    var context = IntentParameterContext<Measurement<UnitDuration>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitDuration>>.Duration.seconds
    context.storedUnit = IntentParameter<Measurement<UnitDuration>>.Duration.minutes
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .seconds)
    precondition(context.unit == .minutes)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterAngleUnitTable() {
    let cases = IntentParameter<Measurement<UnitAngle>>.Angle.allCases
    precondition(cases.count == 6)
    precondition(Set(cases).count == 6)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitAngle>>.Angle.degrees.rawValue == "degrees")
    let _: IntentParameter<Measurement<UnitAngle>>.Angle.AllCases = IntentParameter<Measurement<UnitAngle>>.Angle.allCases
    var context = IntentParameterContext<Measurement<UnitAngle>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitAngle>>.Angle.degrees
    context.storedUnit = IntentParameter<Measurement<UnitAngle>>.Angle.radians
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .degrees)
    precondition(context.unit == .radians)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterElectricChargeUnitTable() {
    let cases = IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases
    precondition(cases.count == 6)
    precondition(Set(cases).count == 6)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.coulombs.rawValue == "coulombs")
    let _: IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.AllCases = IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases
    var context = IntentParameterContext<Measurement<UnitElectricCharge>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.coulombs
    context.storedUnit = IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.ampereHours
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .coulombs)
    precondition(context.unit == .ampereHours)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterEnergyUnitTable() {
    let cases = IntentParameter<Measurement<UnitEnergy>>.Energy.allCases
    precondition(cases.count == 5)
    precondition(Set(cases).count == 5)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitEnergy>>.Energy.joules.rawValue == "joules")
    let _: IntentParameter<Measurement<UnitEnergy>>.Energy.AllCases = IntentParameter<Measurement<UnitEnergy>>.Energy.allCases
    var context = IntentParameterContext<Measurement<UnitEnergy>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitEnergy>>.Energy.joules
    context.storedUnit = IntentParameter<Measurement<UnitEnergy>>.Energy.calories
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .joules)
    precondition(context.unit == .calories)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterElectricCurrentUnitTable() {
    let cases = IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases
    precondition(cases.count == 5)
    precondition(Set(cases).count == 5)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.amperes.rawValue == "amperes")
    let _: IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.AllCases = IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases
    var context = IntentParameterContext<Measurement<UnitElectricCurrent>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.amperes
    context.storedUnit = IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.milliamperes
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .amperes)
    precondition(context.unit == .milliamperes)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterElectricResistanceUnitTable() {
    let cases = IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases
    precondition(cases.count == 5)
    precondition(Set(cases).count == 5)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.ohms.rawValue == "ohms")
    let _: IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.AllCases = IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases
    var context = IntentParameterContext<Measurement<UnitElectricResistance>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.ohms
    context.storedUnit = IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.kiloohms
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .ohms)
    precondition(context.unit == .kiloohms)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterElectricPotentialDifferenceUnitTable() {
    let cases = IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases
    precondition(cases.count == 5)
    precondition(Set(cases).count == 5)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.volts.rawValue == "volts")
    let _: IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.AllCases = IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases
    var context = IntentParameterContext<Measurement<UnitElectricPotentialDifference>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.volts
    context.storedUnit = IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.kilovolts
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .volts)
    precondition(context.unit == .kilovolts)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterSpeedUnitTable() {
    let cases = IntentParameter<Measurement<UnitSpeed>>.Speed.allCases
    precondition(cases.count == 4)
    precondition(Set(cases).count == 4)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitSpeed>>.Speed.knots.rawValue == "knots")
    let _: IntentParameter<Measurement<UnitSpeed>>.Speed.AllCases = IntentParameter<Measurement<UnitSpeed>>.Speed.allCases
    var context = IntentParameterContext<Measurement<UnitSpeed>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitSpeed>>.Speed.knots
    context.storedUnit = IntentParameter<Measurement<UnitSpeed>>.Speed.milesPerHour
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .knots)
    precondition(context.unit == .milesPerHour)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterTemperatureUnitTable() {
    let cases = IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases
    precondition(cases.count == 3)
    precondition(Set(cases).count == 3)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitTemperature>>.Temperature.celsius.rawValue == "celsius")
    let _: IntentParameter<Measurement<UnitTemperature>>.Temperature.AllCases = IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases
    var context = IntentParameterContext<Measurement<UnitTemperature>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitTemperature>>.Temperature.celsius
    context.storedUnit = IntentParameter<Measurement<UnitTemperature>>.Temperature.kelvin
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .celsius)
    precondition(context.unit == .kelvin)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterFuelEfficiencyUnitTable() {
    let cases = IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases
    precondition(cases.count == 3)
    precondition(Set(cases).count == 3)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.milesPerGallon.rawValue == "milesPerGallon")
    let _: IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.AllCases = IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases
    var context = IntentParameterContext<Measurement<UnitFuelEfficiency>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.milesPerGallon
    context.storedUnit = IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.litersPer100Kilometers
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .milesPerGallon)
    precondition(context.unit == .litersPer100Kilometers)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterAccelerationUnitTable() {
    let cases = IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases
    precondition(cases.count == 2)
    precondition(Set(cases).count == 2)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitAcceleration>>.Acceleration.gravity.rawValue == "gravity")
    let _: IntentParameter<Measurement<UnitAcceleration>>.Acceleration.AllCases = IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases
    var context = IntentParameterContext<Measurement<UnitAcceleration>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitAcceleration>>.Acceleration.gravity
    context.storedUnit = IntentParameter<Measurement<UnitAcceleration>>.Acceleration.metersPerSecondSquared
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .gravity)
    precondition(context.unit == .metersPerSecondSquared)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterConcentrationMassUnitTable() {
    let cases = IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases
    precondition(cases.count == 2)
    precondition(Set(cases).count == 2)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.gramsPerLiter.rawValue == "gramsPerLiter")
    let _: IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.AllCases = IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases
    var context = IntentParameterContext<Measurement<UnitConcentrationMass>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.gramsPerLiter
    context.storedUnit = IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.milligramsPerDeciliter
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .gramsPerLiter)
    precondition(context.unit == .milligramsPerDeciliter)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterDispersionUnitTable() {
    let cases = IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases
    precondition(cases.count == 1)
    precondition(Set(cases).count == 1)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitDispersion>>.Dispersion.partsPerMillion.rawValue == "partsPerMillion")
    let _: IntentParameter<Measurement<UnitDispersion>>.Dispersion.AllCases = IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases
    var context = IntentParameterContext<Measurement<UnitDispersion>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitDispersion>>.Dispersion.partsPerMillion
    context.storedUnit = IntentParameter<Measurement<UnitDispersion>>.Dispersion.partsPerMillion
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .partsPerMillion)
    precondition(context.unit == .partsPerMillion)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterIlluminanceUnitTable() {
    let cases = IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases
    precondition(cases.count == 1)
    precondition(Set(cases).count == 1)
    for unit in cases {
        precondition(unit.foundationUnit.symbol == unit.rawValue)
    }
    precondition(IntentParameter<Measurement<UnitIlluminance>>.Illuminance.lux.rawValue == "lux")
    let _: IntentParameter<Measurement<UnitIlluminance>>.Illuminance.AllCases = IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases
    var context = IntentParameterContext<Measurement<UnitIlluminance>>()
    context.storedDefaultUnit = IntentParameter<Measurement<UnitIlluminance>>.Illuminance.lux
    context.storedUnit = IntentParameter<Measurement<UnitIlluminance>>.Illuminance.lux
    context.storedUnitAdjustForLocale = true
    context.storedSupportsNegativeNumbers = false
    precondition(context.defaultUnit == .lux)
    precondition(context.unit == .lux)
    precondition(context.unitAdjustForLocale == true)
    precondition(context.supportsNegativeNumbers == false)
}

func testIntentParameterVolumeDefaultUnitAndValue() {
    let parameter = IntentParameter<Measurement<UnitVolume>>(
        title: LocalizedStringResource("Amount"),
        description: LocalizedStringResource("Measure"),
        defaultValue: 2.5,
        defaultUnit: .liters,
        defaultUnitAdjustForLocale: false,
        supportsNegativeNumbers: false,
        requestValueDialog: IntentDialog("need value")
    )
    precondition(parameter.defaultUnit == .liters)
    precondition(parameter.wrappedValue.value == 2.5)
    precondition(parameter.wrappedValue.unit.symbol == "liters")
    precondition(parameter.supportsNegativeNumbers == false)
    precondition(parameter.metadata.requestValueDialog?.text == "need value")
    let context = parameter.makeContext()
    precondition(context.defaultUnit == .liters)
    precondition(context.supportsNegativeNumbers == false)

    let fixed = IntentParameter<Measurement<UnitVolume>>(
        title: LocalizedStringResource("Fixed"),
        defaultValue: 1,
        unit: .gallons,
        unitAdjustForLocale: true,
        supportsNegativeNumbers: true
    )
    precondition(fixed.unit == .gallons)
    precondition(fixed.unitAdjustForLocale == true)

    let described = IntentParameter<Measurement<UnitVolume>>(
        description: LocalizedStringResource("desc"),
        defaultValue: 3,
        defaultUnit: .liters
    )
    precondition(described.defaultUnit == .liters)

    let describedUnit = IntentParameter<Measurement<UnitVolume>>(
        description: LocalizedStringResource("desc"),
        defaultValue: 4,
        unit: .gallons
    )
    precondition(describedUnit.unit == .gallons)

    let withResolvers = IntentParameter<Measurement<UnitVolume>>(
        title: LocalizedStringResource("R"),
        defaultValue: 5,
        defaultUnit: .liters,
        resolvers: EmptyResolverSpecification<Measurement<UnitVolume>>()
    )
    precondition(withResolvers.defaultUnit == .liters)

    let descResolvers = IntentParameter<Measurement<UnitVolume>>(
        description: LocalizedStringResource("d"),
        defaultValue: 6,
        defaultUnit: .liters,
        resolvers: EmptyResolverSpecification<Measurement<UnitVolume>>()
    )
    precondition(descResolvers.defaultUnit == .liters)

    let unitResolvers = IntentParameter<Measurement<UnitVolume>>(
        title: LocalizedStringResource("U"),
        defaultValue: 7,
        unit: .gallons,
        resolvers: EmptyResolverSpecification<Measurement<UnitVolume>>()
    )
    precondition(unitResolvers.unit == .gallons)

    let descUnitResolvers = IntentParameter<Measurement<UnitVolume>>(
        description: LocalizedStringResource("d"),
        defaultValue: 8,
        unit: .gallons,
        resolvers: EmptyResolverSpecification<Measurement<UnitVolume>>()
    )
    precondition(descUnitResolvers.unit == .gallons)

    let withProvider = IntentParameter<Measurement<UnitVolume>>(
        title: LocalizedStringResource("P"),
        optionsProvider: MeasureFileQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)

    let descProvider = IntentParameter<Measurement<UnitVolume>>(
        description: LocalizedStringResource("p"),
        optionsProvider: MeasureFileQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)

    let both = IntentParameter<Measurement<UnitVolume>>(
        title: LocalizedStringResource("B"),
        resolvers: EmptyResolverSpecification<Measurement<UnitVolume>>(),
        optionsProvider: MeasureFileQuery()
    )
    precondition(both.hasOptionsProvider == true)

    let descBoth = IntentParameter<Measurement<UnitVolume>>(
        description: LocalizedStringResource("b"),
        resolvers: EmptyResolverSpecification<Measurement<UnitVolume>>(),
        optionsProvider: MeasureFileQuery()
    )
    precondition(descBoth.hasOptionsProvider == true)
}

func testIntentParameterLengthDefaultUnitAndValue() {
    let parameter = IntentParameter<Measurement<UnitLength>>(
        title: LocalizedStringResource("Amount"),
        description: LocalizedStringResource("Measure"),
        defaultValue: 2.5,
        defaultUnit: .meters,
        defaultUnitAdjustForLocale: false,
        supportsNegativeNumbers: false,
        requestValueDialog: IntentDialog("need value")
    )
    precondition(parameter.defaultUnit == .meters)
    precondition(parameter.wrappedValue.value == 2.5)
    precondition(parameter.wrappedValue.unit.symbol == "meters")
    precondition(parameter.supportsNegativeNumbers == false)
    precondition(parameter.metadata.requestValueDialog?.text == "need value")
    let context = parameter.makeContext()
    precondition(context.defaultUnit == .meters)
    precondition(context.supportsNegativeNumbers == false)

    let fixed = IntentParameter<Measurement<UnitLength>>(
        title: LocalizedStringResource("Fixed"),
        defaultValue: 1,
        unit: .feet,
        unitAdjustForLocale: true,
        supportsNegativeNumbers: true
    )
    precondition(fixed.unit == .feet)
    precondition(fixed.unitAdjustForLocale == true)

    let described = IntentParameter<Measurement<UnitLength>>(
        description: LocalizedStringResource("desc"),
        defaultValue: 3,
        defaultUnit: .meters
    )
    precondition(described.defaultUnit == .meters)

    let describedUnit = IntentParameter<Measurement<UnitLength>>(
        description: LocalizedStringResource("desc"),
        defaultValue: 4,
        unit: .feet
    )
    precondition(describedUnit.unit == .feet)

    let withResolvers = IntentParameter<Measurement<UnitLength>>(
        title: LocalizedStringResource("R"),
        defaultValue: 5,
        defaultUnit: .meters,
        resolvers: EmptyResolverSpecification<Measurement<UnitLength>>()
    )
    precondition(withResolvers.defaultUnit == .meters)

    let descResolvers = IntentParameter<Measurement<UnitLength>>(
        description: LocalizedStringResource("d"),
        defaultValue: 6,
        defaultUnit: .meters,
        resolvers: EmptyResolverSpecification<Measurement<UnitLength>>()
    )
    precondition(descResolvers.defaultUnit == .meters)

    let unitResolvers = IntentParameter<Measurement<UnitLength>>(
        title: LocalizedStringResource("U"),
        defaultValue: 7,
        unit: .feet,
        resolvers: EmptyResolverSpecification<Measurement<UnitLength>>()
    )
    precondition(unitResolvers.unit == .feet)

    let descUnitResolvers = IntentParameter<Measurement<UnitLength>>(
        description: LocalizedStringResource("d"),
        defaultValue: 8,
        unit: .feet,
        resolvers: EmptyResolverSpecification<Measurement<UnitLength>>()
    )
    precondition(descUnitResolvers.unit == .feet)

    let withProvider = IntentParameter<Measurement<UnitLength>>(
        title: LocalizedStringResource("P"),
        optionsProvider: MeasureFileQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)

    let descProvider = IntentParameter<Measurement<UnitLength>>(
        description: LocalizedStringResource("p"),
        optionsProvider: MeasureFileQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)

    let both = IntentParameter<Measurement<UnitLength>>(
        title: LocalizedStringResource("B"),
        resolvers: EmptyResolverSpecification<Measurement<UnitLength>>(),
        optionsProvider: MeasureFileQuery()
    )
    precondition(both.hasOptionsProvider == true)

    let descBoth = IntentParameter<Measurement<UnitLength>>(
        description: LocalizedStringResource("b"),
        resolvers: EmptyResolverSpecification<Measurement<UnitLength>>(),
        optionsProvider: MeasureFileQuery()
    )
    precondition(descBoth.hasOptionsProvider == true)
}

func testIntentParameterInformationStorageDefaultUnitAndValue() {
    let parameter = IntentParameter<Measurement<UnitInformationStorage>>(
        title: LocalizedStringResource("Amount"),
        description: LocalizedStringResource("Measure"),
        defaultValue: 2.5,
        defaultUnit: .bytes,
        defaultUnitAdjustForLocale: false,
        supportsNegativeNumbers: false,
        requestValueDialog: IntentDialog("need value")
    )
    precondition(parameter.defaultUnit == .bytes)
    precondition(parameter.wrappedValue.value == 2.5)
    precondition(parameter.wrappedValue.unit.symbol == "bytes")
    precondition(parameter.supportsNegativeNumbers == false)
    precondition(parameter.metadata.requestValueDialog?.text == "need value")
    let context = parameter.makeContext()
    precondition(context.defaultUnit == .bytes)
    precondition(context.supportsNegativeNumbers == false)

    let fixed = IntentParameter<Measurement<UnitInformationStorage>>(
        title: LocalizedStringResource("Fixed"),
        defaultValue: 1,
        unit: .megabytes,
        unitAdjustForLocale: true,
        supportsNegativeNumbers: true
    )
    precondition(fixed.unit == .megabytes)
    precondition(fixed.unitAdjustForLocale == true)

    let described = IntentParameter<Measurement<UnitInformationStorage>>(
        description: LocalizedStringResource("desc"),
        defaultValue: 3,
        defaultUnit: .bytes
    )
    precondition(described.defaultUnit == .bytes)

    let describedUnit = IntentParameter<Measurement<UnitInformationStorage>>(
        description: LocalizedStringResource("desc"),
        defaultValue: 4,
        unit: .megabytes
    )
    precondition(describedUnit.unit == .megabytes)

    let withResolvers = IntentParameter<Measurement<UnitInformationStorage>>(
        title: LocalizedStringResource("R"),
        defaultValue: 5,
        defaultUnit: .bytes,
        resolvers: EmptyResolverSpecification<Measurement<UnitInformationStorage>>()
    )
    precondition(withResolvers.defaultUnit == .bytes)

    let descResolvers = IntentParameter<Measurement<UnitInformationStorage>>(
        description: LocalizedStringResource("d"),
        defaultValue: 6,
        defaultUnit: .bytes,
        resolvers: EmptyResolverSpecification<Measurement<UnitInformationStorage>>()
    )
    precondition(descResolvers.defaultUnit == .bytes)

    let unitResolvers = IntentParameter<Measurement<UnitInformationStorage>>(
        title: LocalizedStringResource("U"),
        defaultValue: 7,
        unit: .megabytes,
        resolvers: EmptyResolverSpecification<Measurement<UnitInformationStorage>>()
    )
    precondition(unitResolvers.unit == .megabytes)

    let descUnitResolvers = IntentParameter<Measurement<UnitInformationStorage>>(
        description: LocalizedStringResource("d"),
        defaultValue: 8,
        unit: .megabytes,
        resolvers: EmptyResolverSpecification<Measurement<UnitInformationStorage>>()
    )
    precondition(descUnitResolvers.unit == .megabytes)

    let withProvider = IntentParameter<Measurement<UnitInformationStorage>>(
        title: LocalizedStringResource("P"),
        optionsProvider: MeasureFileQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)

    let descProvider = IntentParameter<Measurement<UnitInformationStorage>>(
        description: LocalizedStringResource("p"),
        optionsProvider: MeasureFileQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)

    let both = IntentParameter<Measurement<UnitInformationStorage>>(
        title: LocalizedStringResource("B"),
        resolvers: EmptyResolverSpecification<Measurement<UnitInformationStorage>>(),
        optionsProvider: MeasureFileQuery()
    )
    precondition(both.hasOptionsProvider == true)

    let descBoth = IntentParameter<Measurement<UnitInformationStorage>>(
        description: LocalizedStringResource("b"),
        resolvers: EmptyResolverSpecification<Measurement<UnitInformationStorage>>(),
        optionsProvider: MeasureFileQuery()
    )
    precondition(descBoth.hasOptionsProvider == true)
}

func testEntityPropertyFileTitleIdentifierGetterAndIndexing() {
    EntityResolutionEngine.reset()
    let file = File(url: URL(fileURLWithPath: "/tmp/wave.bin"), data: Data([0x01]), filename: "wave.bin")
    let holder = MeasureFileHolder(id: "doc", document: file)
    EntityResolutionEngine.register([holder], default: holder)
    let titled = EntityProperty<File>(title: LocalizedStringResource("Document"))
    titled.wrappedValue = file
    precondition(titled.wrappedValue.filename == "wave.bin")
    let empty = EntityProperty<File>()
    empty.wrappedValue = file
    precondition(empty.wrappedValue.data.count == 1)
    let identified = EntityProperty<File>(identifier: "document")
    precondition(identified.identifier == "document")
    let titledId = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("Document")
    )
    precondition(titledId.title.key == "Document")
    let getter = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("Document"),
        getter: \MeasureFileHolder.document
    )
    precondition(getter.wrappedValue.filename == "wave.bin")
    let setter = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("Document"),
        getSetter: \MeasureFileHolder.document
    )
    precondition(setter.wrappedValue.filename == "wave.bin")
    let idGetter = EntityProperty<File>(
        identifier: "document",
        getter: \MeasureFileHolder.document
    )
    precondition(idGetter.wrappedValue.url?.path == "/tmp/wave.bin")
    let idSetter = EntityProperty<File>(
        identifier: "document",
        getSetter: \MeasureFileHolder.document
    )
    precondition(idSetter.wrappedValue.data.count == 1)
    let indexed = EntityProperty<File>(indexingKey: \CSSearchableItemAttributeSet.title)
    precondition(indexed.indexingKeyPath != nil)
    let customOnly = EntityProperty<File>(customIndexingKey: CSCustomAttributeKey(keyName: "file.custom"))
    precondition(customOnly.customIndexingKey?.keyName == "file.custom")
    let titleIndexed = EntityProperty<File>(
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(titleIndexed.indexingKeyName == "indexingKey")
    let titleCustom = EntityProperty<File>(
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "file.title")
    )
    precondition(titleCustom.customIndexingKey?.keyName == "file.title")
}

func testEntityPropertyFileIndexingKeyGetters() {
    EntityResolutionEngine.reset()
    let file = File(url: URL(fileURLWithPath: "/tmp/idx.bin"), filename: "idx.bin")
    let holder = MeasureFileHolder(id: "idx", document: file)
    EntityResolutionEngine.register([holder], default: holder)
    let byIndex = EntityProperty<File>(
        identifier: "document",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \MeasureFileHolder.document
    )
    precondition(byIndex.wrappedValue.filename == "idx.bin")
    let byIndexSet = EntityProperty<File>(
        identifier: "document",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \MeasureFileHolder.document
    )
    precondition(byIndexSet.wrappedValue.filename == "idx.bin")
    let identIndex = EntityProperty<File>(
        identifier: "document",
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(identIndex.identifier == "document")
    let customGetter = EntityProperty<File>(
        identifier: "document",
        customIndexingKey: CSCustomAttributeKey(keyName: "file.idx"),
        getter: \MeasureFileHolder.document
    )
    precondition(customGetter.wrappedValue.filename == "idx.bin")
    let customSetter = EntityProperty<File>(
        identifier: "document",
        customIndexingKey: CSCustomAttributeKey(keyName: "file.idx2"),
        getSetter: \MeasureFileHolder.document
    )
    precondition(customSetter.wrappedValue.filename == "idx.bin")
    let identCustom = EntityProperty<File>(
        identifier: "document",
        customIndexingKey: CSCustomAttributeKey(keyName: "file.idx3")
    )
    precondition(identCustom.customIndexingKey?.keyName == "file.idx3")
    let titledIndex = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \MeasureFileHolder.document
    )
    precondition(titledIndex.wrappedValue.filename == "idx.bin")
    let titledIndexSet = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \MeasureFileHolder.document
    )
    precondition(titledIndexSet.identifier == "document")
    let titledIndexOnly = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title
    )
    precondition(titledIndexOnly.indexingKeyPath != nil)
    let titledCustomGetter = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "file.t"),
        getter: \MeasureFileHolder.document
    )
    precondition(titledCustomGetter.wrappedValue.filename == "idx.bin")
    let titledCustomSetter = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "file.t2"),
        getSetter: \MeasureFileHolder.document
    )
    precondition(titledCustomSetter.customIndexingKey?.keyName == "file.t2")
    let titledCustom = EntityProperty<File>(
        identifier: "document",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "file.t3")
    )
    precondition(titledCustom.identifier == "document")
}

func testIntentPersonCodableImageAndTypeAliases() {
    let handle = IntentPerson.Handle(emailAddress: "a@b.test", label: .work)
    let person = IntentPerson(
        identifier: .applicationDefined("p1"),
        name: .displayName("Ada"),
        handle: handle,
        aliases: [handle],
        isMe: true,
        image: DisplayRepresentation.Image(systemName: "person")
    )
    precondition(person.image?.systemName == "person")
    let data = try! JSONEncoder().encode(person)
    let decoded = try! JSONDecoder().decode(IntentPerson.self, from: data)
    precondition(decoded.identifier == .applicationDefined("p1"))
    precondition(decoded.name == .displayName("Ada"))
    precondition(decoded.handle?.value == .emailAddress("a@b.test"))
    precondition(decoded.handle?.label == .work)
    precondition(decoded.aliases.count == 1)
    precondition(decoded.isMe == true)
    let identData = try! JSONEncoder().encode(IntentPerson.Identifier.contact("c1"))
    let ident = try! JSONDecoder().decode(IntentPerson.Identifier.self, from: identData)
    precondition(ident == .contact("c1"))
    var components = PersonNameComponents()
    components.givenName = "Ada"
    let nameData = try! JSONEncoder().encode(IntentPerson.Name.components(components))
    let name = try! JSONDecoder().decode(IntentPerson.Name.self, from: nameData)
    switch name {
    case .components(let value):
        precondition(value.givenName == "Ada")
    default:
        preconditionFailure("expected components")
    }
    let labelData = try! JSONEncoder().encode(IntentPerson.Handle.Label.mobile)
    let label = try! JSONDecoder().decode(IntentPerson.Handle.Label.self, from: labelData)
    precondition(label == .mobile)
    let valueData = try! JSONEncoder().encode(IntentPerson.Handle.Value.phoneNumber("+1"))
    let value = try! JSONDecoder().decode(IntentPerson.Handle.Value.self, from: valueData)
    precondition(value == .phoneNumber("+1"))
    let handleData = try! JSONEncoder().encode(handle)
    let decodedHandle = try! JSONDecoder().decode(IntentPerson.Handle.self, from: handleData)
    precondition(decodedHandle.label == .work)
    precondition(IntentPerson.ParameterMode(rawValue: "email") == .email)
    let _: IntentPerson.ValueType.Type = IntentPerson.self
    let _: IntentPerson.UnwrappedType.Type = IntentPerson.self
}

func testIntentParameterAppEnumSupportedValuesAndDisambiguationDialog() {
    let dialog = IntentDialog("which kind")
    let parameter = IntentParameter<MeasureKind>(
        title: LocalizedStringResource("Kind"),
        description: LocalizedStringResource("Measure kind"),
        default: .length,
        requestValueDialog: IntentDialog("need kind"),
        requestDisambiguationDialog: dialog,
        supportedValues: [.length, .volume]
    )
    precondition(parameter.wrappedValue == .length)
    precondition(parameter.requestDisambiguationDialog?.text == "which kind")
    precondition(parameter.supportedValues.count == 2)
    let described = IntentParameter<MeasureKind>(
        description: LocalizedStringResource("Kind"),
        default: .volume,
        requestDisambiguationDialog: dialog,
        supportedValues: [.volume]
    )
    precondition(described.wrappedValue == .volume)
    let withProvider = IntentParameter<MeasureKind>(
        title: LocalizedStringResource("Kind"),
        default: .length,
        requestDisambiguationDialog: dialog,
        supportedValues: [.length],
        optionsProvider: MeasureFileQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    let withResolvers = IntentParameter<MeasureKind>(
        title: LocalizedStringResource("Kind"),
        default: .volume,
        requestDisambiguationDialog: dialog,
        supportedValues: [.volume],
        resolvers: EmptyResolverSpecification<MeasureKind>()
    )
    precondition(withResolvers.wrappedValue == .volume)
}

func testIntentParameterAppEntityQueryAndDisambiguationDialog() {
    EntityResolutionEngine.reset()
    let file = File(filename: "q.bin")
    let holder = MeasureFileHolder(id: "q", document: file)
    EntityResolutionEngine.register([holder], default: holder)
    let parameter = IntentParameter<MeasureFileHolder>(
        title: LocalizedStringResource("Doc"),
        description: LocalizedStringResource("File entity"),
        default: holder,
        requestValueDialog: IntentDialog("need doc"),
        requestDisambiguationDialog: IntentDialog("which doc"),
        query: MeasureFileQuery()
    )
    precondition(parameter.wrappedValue.id == "q")
    precondition(parameter.requestDisambiguationDialog?.text == "which doc")
}

