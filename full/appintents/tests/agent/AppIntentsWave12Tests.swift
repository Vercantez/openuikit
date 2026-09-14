import Foundation
import AppIntents

private struct Wave12Entity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave12" }
    static var defaultQuery = Wave12Query()
    var id: String
    var number: Int
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave12Query: EntityQuery {
    typealias Entity = Wave12Entity
    init() {}
    func entities(for identifiers: [String]) async throws -> [Wave12Entity] {
        EntityResolutionEngine.entities(for: identifiers, as: Wave12Entity.self)
    }
    func suggestedEntities() async throws -> [Wave12Entity] {
        EntityResolutionEngine.suggestedEntities(Wave12Entity.self)
    }
}

func testIntentParameterRemainingMeasurementDefaultUnitInits() {
    do {
        let parameter = IntentParameter<Measurement<UnitMass>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .grams,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .grams)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "grams")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .grams)
        let described = IntentParameter<Measurement<UnitMass>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .grams
        )
        precondition(described.defaultUnit == .grams)
        let withResolvers = IntentParameter<Measurement<UnitMass>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .grams,
            resolvers: EmptyResolverSpecification<Measurement<UnitMass>>()
        )
        precondition(withResolvers.defaultUnit == .grams)
        let descResolvers = IntentParameter<Measurement<UnitMass>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .grams,
            resolvers: EmptyResolverSpecification<Measurement<UnitMass>>()
        )
        precondition(descResolvers.defaultUnit == .grams)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitArea>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .acres,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .acres)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "acres")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .acres)
        let described = IntentParameter<Measurement<UnitArea>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .acres
        )
        precondition(described.defaultUnit == .acres)
        let withResolvers = IntentParameter<Measurement<UnitArea>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .acres,
            resolvers: EmptyResolverSpecification<Measurement<UnitArea>>()
        )
        precondition(withResolvers.defaultUnit == .acres)
        let descResolvers = IntentParameter<Measurement<UnitArea>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .acres,
            resolvers: EmptyResolverSpecification<Measurement<UnitArea>>()
        )
        precondition(descResolvers.defaultUnit == .acres)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitPower>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .watts,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .watts)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "watts")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .watts)
        let described = IntentParameter<Measurement<UnitPower>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .watts
        )
        precondition(described.defaultUnit == .watts)
        let withResolvers = IntentParameter<Measurement<UnitPower>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .watts,
            resolvers: EmptyResolverSpecification<Measurement<UnitPower>>()
        )
        precondition(withResolvers.defaultUnit == .watts)
        let descResolvers = IntentParameter<Measurement<UnitPower>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .watts,
            resolvers: EmptyResolverSpecification<Measurement<UnitPower>>()
        )
        precondition(descResolvers.defaultUnit == .watts)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitPressure>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .bars,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .bars)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "bars")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .bars)
        let described = IntentParameter<Measurement<UnitPressure>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .bars
        )
        precondition(described.defaultUnit == .bars)
        let withResolvers = IntentParameter<Measurement<UnitPressure>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .bars,
            resolvers: EmptyResolverSpecification<Measurement<UnitPressure>>()
        )
        precondition(withResolvers.defaultUnit == .bars)
        let descResolvers = IntentParameter<Measurement<UnitPressure>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .bars,
            resolvers: EmptyResolverSpecification<Measurement<UnitPressure>>()
        )
        precondition(descResolvers.defaultUnit == .bars)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitFrequency>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .hertz,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .hertz)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "hertz")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .hertz)
        let described = IntentParameter<Measurement<UnitFrequency>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .hertz
        )
        precondition(described.defaultUnit == .hertz)
        let withResolvers = IntentParameter<Measurement<UnitFrequency>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .hertz,
            resolvers: EmptyResolverSpecification<Measurement<UnitFrequency>>()
        )
        precondition(withResolvers.defaultUnit == .hertz)
        let descResolvers = IntentParameter<Measurement<UnitFrequency>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .hertz,
            resolvers: EmptyResolverSpecification<Measurement<UnitFrequency>>()
        )
        precondition(descResolvers.defaultUnit == .hertz)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitDuration>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .seconds,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .seconds)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "seconds")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .seconds)
        let described = IntentParameter<Measurement<UnitDuration>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .seconds
        )
        precondition(described.defaultUnit == .seconds)
        let withResolvers = IntentParameter<Measurement<UnitDuration>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .seconds,
            resolvers: EmptyResolverSpecification<Measurement<UnitDuration>>()
        )
        precondition(withResolvers.defaultUnit == .seconds)
        let descResolvers = IntentParameter<Measurement<UnitDuration>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .seconds,
            resolvers: EmptyResolverSpecification<Measurement<UnitDuration>>()
        )
        precondition(descResolvers.defaultUnit == .seconds)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitAngle>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .degrees,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .degrees)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "degrees")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .degrees)
        let described = IntentParameter<Measurement<UnitAngle>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .degrees
        )
        precondition(described.defaultUnit == .degrees)
        let withResolvers = IntentParameter<Measurement<UnitAngle>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .degrees,
            resolvers: EmptyResolverSpecification<Measurement<UnitAngle>>()
        )
        precondition(withResolvers.defaultUnit == .degrees)
        let descResolvers = IntentParameter<Measurement<UnitAngle>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .degrees,
            resolvers: EmptyResolverSpecification<Measurement<UnitAngle>>()
        )
        precondition(descResolvers.defaultUnit == .degrees)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitElectricCharge>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .coulombs,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .coulombs)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "coulombs")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .coulombs)
        let described = IntentParameter<Measurement<UnitElectricCharge>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .coulombs
        )
        precondition(described.defaultUnit == .coulombs)
        let withResolvers = IntentParameter<Measurement<UnitElectricCharge>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .coulombs,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCharge>>()
        )
        precondition(withResolvers.defaultUnit == .coulombs)
        let descResolvers = IntentParameter<Measurement<UnitElectricCharge>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .coulombs,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCharge>>()
        )
        precondition(descResolvers.defaultUnit == .coulombs)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitEnergy>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .joules,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .joules)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "joules")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .joules)
        let described = IntentParameter<Measurement<UnitEnergy>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .joules
        )
        precondition(described.defaultUnit == .joules)
        let withResolvers = IntentParameter<Measurement<UnitEnergy>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .joules,
            resolvers: EmptyResolverSpecification<Measurement<UnitEnergy>>()
        )
        precondition(withResolvers.defaultUnit == .joules)
        let descResolvers = IntentParameter<Measurement<UnitEnergy>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .joules,
            resolvers: EmptyResolverSpecification<Measurement<UnitEnergy>>()
        )
        precondition(descResolvers.defaultUnit == .joules)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitElectricCurrent>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .amperes,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .amperes)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "amperes")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .amperes)
        let described = IntentParameter<Measurement<UnitElectricCurrent>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .amperes
        )
        precondition(described.defaultUnit == .amperes)
        let withResolvers = IntentParameter<Measurement<UnitElectricCurrent>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .amperes,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCurrent>>()
        )
        precondition(withResolvers.defaultUnit == .amperes)
        let descResolvers = IntentParameter<Measurement<UnitElectricCurrent>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .amperes,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCurrent>>()
        )
        precondition(descResolvers.defaultUnit == .amperes)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitElectricResistance>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .ohms,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .ohms)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "ohms")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .ohms)
        let described = IntentParameter<Measurement<UnitElectricResistance>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .ohms
        )
        precondition(described.defaultUnit == .ohms)
        let withResolvers = IntentParameter<Measurement<UnitElectricResistance>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .ohms,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricResistance>>()
        )
        precondition(withResolvers.defaultUnit == .ohms)
        let descResolvers = IntentParameter<Measurement<UnitElectricResistance>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .ohms,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricResistance>>()
        )
        precondition(descResolvers.defaultUnit == .ohms)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .volts,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .volts)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "volts")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .volts)
        let described = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .volts
        )
        precondition(described.defaultUnit == .volts)
        let withResolvers = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .volts,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricPotentialDifference>>()
        )
        precondition(withResolvers.defaultUnit == .volts)
        let descResolvers = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .volts,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricPotentialDifference>>()
        )
        precondition(descResolvers.defaultUnit == .volts)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitSpeed>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .metersPerSecond,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .metersPerSecond)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "metersPerSecond")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .metersPerSecond)
        let described = IntentParameter<Measurement<UnitSpeed>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .metersPerSecond
        )
        precondition(described.defaultUnit == .metersPerSecond)
        let withResolvers = IntentParameter<Measurement<UnitSpeed>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .metersPerSecond,
            resolvers: EmptyResolverSpecification<Measurement<UnitSpeed>>()
        )
        precondition(withResolvers.defaultUnit == .metersPerSecond)
        let descResolvers = IntentParameter<Measurement<UnitSpeed>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .metersPerSecond,
            resolvers: EmptyResolverSpecification<Measurement<UnitSpeed>>()
        )
        precondition(descResolvers.defaultUnit == .metersPerSecond)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitTemperature>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .kelvin,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .kelvin)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "kelvin")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .kelvin)
        let described = IntentParameter<Measurement<UnitTemperature>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .kelvin
        )
        precondition(described.defaultUnit == .kelvin)
        let withResolvers = IntentParameter<Measurement<UnitTemperature>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .kelvin,
            resolvers: EmptyResolverSpecification<Measurement<UnitTemperature>>()
        )
        precondition(withResolvers.defaultUnit == .kelvin)
        let descResolvers = IntentParameter<Measurement<UnitTemperature>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .kelvin,
            resolvers: EmptyResolverSpecification<Measurement<UnitTemperature>>()
        )
        precondition(descResolvers.defaultUnit == .kelvin)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitFuelEfficiency>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .litersPer100Kilometers,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .litersPer100Kilometers)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "litersPer100Kilometers")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .litersPer100Kilometers)
        let described = IntentParameter<Measurement<UnitFuelEfficiency>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .litersPer100Kilometers
        )
        precondition(described.defaultUnit == .litersPer100Kilometers)
        let withResolvers = IntentParameter<Measurement<UnitFuelEfficiency>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .litersPer100Kilometers,
            resolvers: EmptyResolverSpecification<Measurement<UnitFuelEfficiency>>()
        )
        precondition(withResolvers.defaultUnit == .litersPer100Kilometers)
        let descResolvers = IntentParameter<Measurement<UnitFuelEfficiency>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .litersPer100Kilometers,
            resolvers: EmptyResolverSpecification<Measurement<UnitFuelEfficiency>>()
        )
        precondition(descResolvers.defaultUnit == .litersPer100Kilometers)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitAcceleration>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .metersPerSecondSquared,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .metersPerSecondSquared)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "metersPerSecondSquared")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .metersPerSecondSquared)
        let described = IntentParameter<Measurement<UnitAcceleration>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .metersPerSecondSquared
        )
        precondition(described.defaultUnit == .metersPerSecondSquared)
        let withResolvers = IntentParameter<Measurement<UnitAcceleration>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .metersPerSecondSquared,
            resolvers: EmptyResolverSpecification<Measurement<UnitAcceleration>>()
        )
        precondition(withResolvers.defaultUnit == .metersPerSecondSquared)
        let descResolvers = IntentParameter<Measurement<UnitAcceleration>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .metersPerSecondSquared,
            resolvers: EmptyResolverSpecification<Measurement<UnitAcceleration>>()
        )
        precondition(descResolvers.defaultUnit == .metersPerSecondSquared)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitConcentrationMass>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .gramsPerLiter,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .gramsPerLiter)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "gramsPerLiter")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .gramsPerLiter)
        let described = IntentParameter<Measurement<UnitConcentrationMass>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .gramsPerLiter
        )
        precondition(described.defaultUnit == .gramsPerLiter)
        let withResolvers = IntentParameter<Measurement<UnitConcentrationMass>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .gramsPerLiter,
            resolvers: EmptyResolverSpecification<Measurement<UnitConcentrationMass>>()
        )
        precondition(withResolvers.defaultUnit == .gramsPerLiter)
        let descResolvers = IntentParameter<Measurement<UnitConcentrationMass>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .gramsPerLiter,
            resolvers: EmptyResolverSpecification<Measurement<UnitConcentrationMass>>()
        )
        precondition(descResolvers.defaultUnit == .gramsPerLiter)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitDispersion>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .partsPerMillion,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .partsPerMillion)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "partsPerMillion")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .partsPerMillion)
        let described = IntentParameter<Measurement<UnitDispersion>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .partsPerMillion
        )
        precondition(described.defaultUnit == .partsPerMillion)
        let withResolvers = IntentParameter<Measurement<UnitDispersion>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .partsPerMillion,
            resolvers: EmptyResolverSpecification<Measurement<UnitDispersion>>()
        )
        precondition(withResolvers.defaultUnit == .partsPerMillion)
        let descResolvers = IntentParameter<Measurement<UnitDispersion>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .partsPerMillion,
            resolvers: EmptyResolverSpecification<Measurement<UnitDispersion>>()
        )
        precondition(descResolvers.defaultUnit == .partsPerMillion)
        _ = parameter.unitAdjustForLocale
    }
    do {
        let parameter = IntentParameter<Measurement<UnitIlluminance>>(
            title: LocalizedStringResource("Amount"),
            description: LocalizedStringResource("Measure"),
            defaultValue: 2.5,
            defaultUnit: .lux,
            defaultUnitAdjustForLocale: false,
            supportsNegativeNumbers: false,
            requestValueDialog: IntentDialog("need value")
        )
        precondition(parameter.defaultUnit == .lux)
        precondition(parameter.wrappedValue.value == 2.5)
        precondition(parameter.wrappedValue.unit.symbol == "lux")
        precondition(parameter.supportsNegativeNumbers == false)
        precondition(parameter.metadata.requestValueDialog?.text == "need value")
        precondition(parameter.makeContext().defaultUnit == .lux)
        let described = IntentParameter<Measurement<UnitIlluminance>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 3,
            defaultUnit: .lux
        )
        precondition(described.defaultUnit == .lux)
        let withResolvers = IntentParameter<Measurement<UnitIlluminance>>(
            title: LocalizedStringResource("R"),
            defaultValue: 5,
            defaultUnit: .lux,
            resolvers: EmptyResolverSpecification<Measurement<UnitIlluminance>>()
        )
        precondition(withResolvers.defaultUnit == .lux)
        let descResolvers = IntentParameter<Measurement<UnitIlluminance>>(
            description: LocalizedStringResource("d"),
            defaultValue: 6,
            defaultUnit: .lux,
            resolvers: EmptyResolverSpecification<Measurement<UnitIlluminance>>()
        )
        precondition(descResolvers.defaultUnit == .lux)
        _ = parameter.unitAdjustForLocale
    }
}

func testIntentParameterRemainingMeasurementFixedUnitAndProviderInits() {
    do {
        let fixed = IntentParameter<Measurement<UnitMass>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .kilograms,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .kilograms)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitMass>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .kilograms
        )
        precondition(describedUnit.unit == .kilograms)
        let unitResolvers = IntentParameter<Measurement<UnitMass>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .kilograms,
            resolvers: EmptyResolverSpecification<Measurement<UnitMass>>()
        )
        precondition(unitResolvers.unit == .kilograms)
        let descUnitResolvers = IntentParameter<Measurement<UnitMass>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .kilograms,
            resolvers: EmptyResolverSpecification<Measurement<UnitMass>>()
        )
        precondition(descUnitResolvers.unit == .kilograms)
        let withProvider = IntentParameter<Measurement<UnitMass>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitMass>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitMass>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitMass>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitMass>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitMass>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitArea>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .hectares,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .hectares)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitArea>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .hectares
        )
        precondition(describedUnit.unit == .hectares)
        let unitResolvers = IntentParameter<Measurement<UnitArea>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .hectares,
            resolvers: EmptyResolverSpecification<Measurement<UnitArea>>()
        )
        precondition(unitResolvers.unit == .hectares)
        let descUnitResolvers = IntentParameter<Measurement<UnitArea>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .hectares,
            resolvers: EmptyResolverSpecification<Measurement<UnitArea>>()
        )
        precondition(descUnitResolvers.unit == .hectares)
        let withProvider = IntentParameter<Measurement<UnitArea>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitArea>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitArea>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitArea>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitArea>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitArea>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitPower>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .kilowatts,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .kilowatts)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitPower>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .kilowatts
        )
        precondition(describedUnit.unit == .kilowatts)
        let unitResolvers = IntentParameter<Measurement<UnitPower>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .kilowatts,
            resolvers: EmptyResolverSpecification<Measurement<UnitPower>>()
        )
        precondition(unitResolvers.unit == .kilowatts)
        let descUnitResolvers = IntentParameter<Measurement<UnitPower>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .kilowatts,
            resolvers: EmptyResolverSpecification<Measurement<UnitPower>>()
        )
        precondition(descUnitResolvers.unit == .kilowatts)
        let withProvider = IntentParameter<Measurement<UnitPower>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitPower>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitPower>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitPower>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitPower>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitPower>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitPressure>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .millibars,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .millibars)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitPressure>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .millibars
        )
        precondition(describedUnit.unit == .millibars)
        let unitResolvers = IntentParameter<Measurement<UnitPressure>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .millibars,
            resolvers: EmptyResolverSpecification<Measurement<UnitPressure>>()
        )
        precondition(unitResolvers.unit == .millibars)
        let descUnitResolvers = IntentParameter<Measurement<UnitPressure>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .millibars,
            resolvers: EmptyResolverSpecification<Measurement<UnitPressure>>()
        )
        precondition(descUnitResolvers.unit == .millibars)
        let withProvider = IntentParameter<Measurement<UnitPressure>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitPressure>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitPressure>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitPressure>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitPressure>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitPressure>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitFrequency>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .kilohertz,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .kilohertz)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitFrequency>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .kilohertz
        )
        precondition(describedUnit.unit == .kilohertz)
        let unitResolvers = IntentParameter<Measurement<UnitFrequency>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .kilohertz,
            resolvers: EmptyResolverSpecification<Measurement<UnitFrequency>>()
        )
        precondition(unitResolvers.unit == .kilohertz)
        let descUnitResolvers = IntentParameter<Measurement<UnitFrequency>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .kilohertz,
            resolvers: EmptyResolverSpecification<Measurement<UnitFrequency>>()
        )
        precondition(descUnitResolvers.unit == .kilohertz)
        let withProvider = IntentParameter<Measurement<UnitFrequency>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitFrequency>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitFrequency>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitFrequency>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitFrequency>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitFrequency>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitDuration>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .minutes,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .minutes)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitDuration>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .minutes
        )
        precondition(describedUnit.unit == .minutes)
        let unitResolvers = IntentParameter<Measurement<UnitDuration>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .minutes,
            resolvers: EmptyResolverSpecification<Measurement<UnitDuration>>()
        )
        precondition(unitResolvers.unit == .minutes)
        let descUnitResolvers = IntentParameter<Measurement<UnitDuration>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .minutes,
            resolvers: EmptyResolverSpecification<Measurement<UnitDuration>>()
        )
        precondition(descUnitResolvers.unit == .minutes)
        let withProvider = IntentParameter<Measurement<UnitDuration>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitDuration>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitDuration>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitDuration>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitDuration>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitDuration>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitAngle>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .radians,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .radians)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitAngle>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .radians
        )
        precondition(describedUnit.unit == .radians)
        let unitResolvers = IntentParameter<Measurement<UnitAngle>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .radians,
            resolvers: EmptyResolverSpecification<Measurement<UnitAngle>>()
        )
        precondition(unitResolvers.unit == .radians)
        let descUnitResolvers = IntentParameter<Measurement<UnitAngle>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .radians,
            resolvers: EmptyResolverSpecification<Measurement<UnitAngle>>()
        )
        precondition(descUnitResolvers.unit == .radians)
        let withProvider = IntentParameter<Measurement<UnitAngle>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitAngle>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitAngle>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitAngle>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitAngle>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitAngle>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitElectricCharge>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .ampereHours,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .ampereHours)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitElectricCharge>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .ampereHours
        )
        precondition(describedUnit.unit == .ampereHours)
        let unitResolvers = IntentParameter<Measurement<UnitElectricCharge>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .ampereHours,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCharge>>()
        )
        precondition(unitResolvers.unit == .ampereHours)
        let descUnitResolvers = IntentParameter<Measurement<UnitElectricCharge>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .ampereHours,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCharge>>()
        )
        precondition(descUnitResolvers.unit == .ampereHours)
        let withProvider = IntentParameter<Measurement<UnitElectricCharge>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitElectricCharge>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitElectricCharge>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCharge>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitElectricCharge>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCharge>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitEnergy>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .kilojoules,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .kilojoules)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitEnergy>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .kilojoules
        )
        precondition(describedUnit.unit == .kilojoules)
        let unitResolvers = IntentParameter<Measurement<UnitEnergy>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .kilojoules,
            resolvers: EmptyResolverSpecification<Measurement<UnitEnergy>>()
        )
        precondition(unitResolvers.unit == .kilojoules)
        let descUnitResolvers = IntentParameter<Measurement<UnitEnergy>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .kilojoules,
            resolvers: EmptyResolverSpecification<Measurement<UnitEnergy>>()
        )
        precondition(descUnitResolvers.unit == .kilojoules)
        let withProvider = IntentParameter<Measurement<UnitEnergy>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitEnergy>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitEnergy>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitEnergy>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitEnergy>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitEnergy>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitElectricCurrent>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .milliamperes,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .milliamperes)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitElectricCurrent>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .milliamperes
        )
        precondition(describedUnit.unit == .milliamperes)
        let unitResolvers = IntentParameter<Measurement<UnitElectricCurrent>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .milliamperes,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCurrent>>()
        )
        precondition(unitResolvers.unit == .milliamperes)
        let descUnitResolvers = IntentParameter<Measurement<UnitElectricCurrent>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .milliamperes,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCurrent>>()
        )
        precondition(descUnitResolvers.unit == .milliamperes)
        let withProvider = IntentParameter<Measurement<UnitElectricCurrent>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitElectricCurrent>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitElectricCurrent>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCurrent>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitElectricCurrent>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricCurrent>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitElectricResistance>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .kiloohms,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .kiloohms)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitElectricResistance>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .kiloohms
        )
        precondition(describedUnit.unit == .kiloohms)
        let unitResolvers = IntentParameter<Measurement<UnitElectricResistance>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .kiloohms,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricResistance>>()
        )
        precondition(unitResolvers.unit == .kiloohms)
        let descUnitResolvers = IntentParameter<Measurement<UnitElectricResistance>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .kiloohms,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricResistance>>()
        )
        precondition(descUnitResolvers.unit == .kiloohms)
        let withProvider = IntentParameter<Measurement<UnitElectricResistance>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitElectricResistance>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitElectricResistance>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricResistance>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitElectricResistance>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricResistance>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .millivolts,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .millivolts)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .millivolts
        )
        precondition(describedUnit.unit == .millivolts)
        let unitResolvers = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .millivolts,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricPotentialDifference>>()
        )
        precondition(unitResolvers.unit == .millivolts)
        let descUnitResolvers = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .millivolts,
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricPotentialDifference>>()
        )
        precondition(descUnitResolvers.unit == .millivolts)
        let withProvider = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricPotentialDifference>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitElectricPotentialDifference>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitElectricPotentialDifference>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitSpeed>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .kilometersPerHour,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .kilometersPerHour)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitSpeed>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .kilometersPerHour
        )
        precondition(describedUnit.unit == .kilometersPerHour)
        let unitResolvers = IntentParameter<Measurement<UnitSpeed>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .kilometersPerHour,
            resolvers: EmptyResolverSpecification<Measurement<UnitSpeed>>()
        )
        precondition(unitResolvers.unit == .kilometersPerHour)
        let descUnitResolvers = IntentParameter<Measurement<UnitSpeed>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .kilometersPerHour,
            resolvers: EmptyResolverSpecification<Measurement<UnitSpeed>>()
        )
        precondition(descUnitResolvers.unit == .kilometersPerHour)
        let withProvider = IntentParameter<Measurement<UnitSpeed>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitSpeed>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitSpeed>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitSpeed>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitSpeed>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitSpeed>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitTemperature>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .celsius,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .celsius)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitTemperature>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .celsius
        )
        precondition(describedUnit.unit == .celsius)
        let unitResolvers = IntentParameter<Measurement<UnitTemperature>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .celsius,
            resolvers: EmptyResolverSpecification<Measurement<UnitTemperature>>()
        )
        precondition(unitResolvers.unit == .celsius)
        let descUnitResolvers = IntentParameter<Measurement<UnitTemperature>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .celsius,
            resolvers: EmptyResolverSpecification<Measurement<UnitTemperature>>()
        )
        precondition(descUnitResolvers.unit == .celsius)
        let withProvider = IntentParameter<Measurement<UnitTemperature>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitTemperature>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitTemperature>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitTemperature>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitTemperature>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitTemperature>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitFuelEfficiency>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .milesPerGallon,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .milesPerGallon)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitFuelEfficiency>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .milesPerGallon
        )
        precondition(describedUnit.unit == .milesPerGallon)
        let unitResolvers = IntentParameter<Measurement<UnitFuelEfficiency>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .milesPerGallon,
            resolvers: EmptyResolverSpecification<Measurement<UnitFuelEfficiency>>()
        )
        precondition(unitResolvers.unit == .milesPerGallon)
        let descUnitResolvers = IntentParameter<Measurement<UnitFuelEfficiency>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .milesPerGallon,
            resolvers: EmptyResolverSpecification<Measurement<UnitFuelEfficiency>>()
        )
        precondition(descUnitResolvers.unit == .milesPerGallon)
        let withProvider = IntentParameter<Measurement<UnitFuelEfficiency>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitFuelEfficiency>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitFuelEfficiency>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitFuelEfficiency>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitFuelEfficiency>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitFuelEfficiency>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitAcceleration>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .gravity,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .gravity)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitAcceleration>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .gravity
        )
        precondition(describedUnit.unit == .gravity)
        let unitResolvers = IntentParameter<Measurement<UnitAcceleration>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .gravity,
            resolvers: EmptyResolverSpecification<Measurement<UnitAcceleration>>()
        )
        precondition(unitResolvers.unit == .gravity)
        let descUnitResolvers = IntentParameter<Measurement<UnitAcceleration>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .gravity,
            resolvers: EmptyResolverSpecification<Measurement<UnitAcceleration>>()
        )
        precondition(descUnitResolvers.unit == .gravity)
        let withProvider = IntentParameter<Measurement<UnitAcceleration>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitAcceleration>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitAcceleration>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitAcceleration>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitAcceleration>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitAcceleration>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitConcentrationMass>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .milligramsPerDeciliter,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .milligramsPerDeciliter)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitConcentrationMass>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .milligramsPerDeciliter
        )
        precondition(describedUnit.unit == .milligramsPerDeciliter)
        let unitResolvers = IntentParameter<Measurement<UnitConcentrationMass>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .milligramsPerDeciliter,
            resolvers: EmptyResolverSpecification<Measurement<UnitConcentrationMass>>()
        )
        precondition(unitResolvers.unit == .milligramsPerDeciliter)
        let descUnitResolvers = IntentParameter<Measurement<UnitConcentrationMass>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .milligramsPerDeciliter,
            resolvers: EmptyResolverSpecification<Measurement<UnitConcentrationMass>>()
        )
        precondition(descUnitResolvers.unit == .milligramsPerDeciliter)
        let withProvider = IntentParameter<Measurement<UnitConcentrationMass>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitConcentrationMass>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitConcentrationMass>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitConcentrationMass>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitConcentrationMass>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitConcentrationMass>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitDispersion>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .partsPerMillion,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .partsPerMillion)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitDispersion>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .partsPerMillion
        )
        precondition(describedUnit.unit == .partsPerMillion)
        let unitResolvers = IntentParameter<Measurement<UnitDispersion>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .partsPerMillion,
            resolvers: EmptyResolverSpecification<Measurement<UnitDispersion>>()
        )
        precondition(unitResolvers.unit == .partsPerMillion)
        let descUnitResolvers = IntentParameter<Measurement<UnitDispersion>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .partsPerMillion,
            resolvers: EmptyResolverSpecification<Measurement<UnitDispersion>>()
        )
        precondition(descUnitResolvers.unit == .partsPerMillion)
        let withProvider = IntentParameter<Measurement<UnitDispersion>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitDispersion>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitDispersion>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitDispersion>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitDispersion>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitDispersion>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
    do {
        let fixed = IntentParameter<Measurement<UnitIlluminance>>(
            title: LocalizedStringResource("Fixed"),
            defaultValue: 1,
            unit: .lux,
            unitAdjustForLocale: true,
            supportsNegativeNumbers: true
        )
        precondition(fixed.unit == .lux)
        precondition(fixed.unitAdjustForLocale == true)
        let describedUnit = IntentParameter<Measurement<UnitIlluminance>>(
            description: LocalizedStringResource("desc"),
            defaultValue: 4,
            unit: .lux
        )
        precondition(describedUnit.unit == .lux)
        let unitResolvers = IntentParameter<Measurement<UnitIlluminance>>(
            title: LocalizedStringResource("U"),
            defaultValue: 7,
            unit: .lux,
            resolvers: EmptyResolverSpecification<Measurement<UnitIlluminance>>()
        )
        precondition(unitResolvers.unit == .lux)
        let descUnitResolvers = IntentParameter<Measurement<UnitIlluminance>>(
            description: LocalizedStringResource("d"),
            defaultValue: 8,
            unit: .lux,
            resolvers: EmptyResolverSpecification<Measurement<UnitIlluminance>>()
        )
        precondition(descUnitResolvers.unit == .lux)
        let withProvider = IntentParameter<Measurement<UnitIlluminance>>(
            title: LocalizedStringResource("P"),
            optionsProvider: Wave12Query()
        )
        precondition(withProvider.hasOptionsProvider == true)
        let descProvider = IntentParameter<Measurement<UnitIlluminance>>(
            description: LocalizedStringResource("p"),
            optionsProvider: Wave12Query()
        )
        precondition(descProvider.hasOptionsProvider == true)
        let both = IntentParameter<Measurement<UnitIlluminance>>(
            title: LocalizedStringResource("B"),
            resolvers: EmptyResolverSpecification<Measurement<UnitIlluminance>>(),
            optionsProvider: Wave12Query()
        )
        precondition(both.hasOptionsProvider == true)
        let descBoth = IntentParameter<Measurement<UnitIlluminance>>(
            description: LocalizedStringResource("b"),
            resolvers: EmptyResolverSpecification<Measurement<UnitIlluminance>>(),
            optionsProvider: Wave12Query()
        )
        precondition(descBoth.hasOptionsProvider == true)
    }
}

func testIntentParameterPortableTitleDefaultHashAndDisplay() {
    let parameter = IntentParameter<String>(
        title: LocalizedStringResource("Query"),
        description: LocalizedStringResource("Find"),
        default: "search",
        requestValueDialog: IntentDialog("need query")
    )
    precondition(parameter.title.key == "Query")
    precondition(parameter.defaultValue == "search")
    precondition(parameter.wrappedValue == "search")
    precondition(parameter.hostRequestValueDisplayRepresentation()?.title != nil)
    parameter.wrappedValue = "typed"
    precondition(parameter.wrappedValue == "typed")
    precondition(String(describing: parameter.hostDisplayRepresentation.title).contains("typed"))

    let described = IntentParameter<Int>(
        description: LocalizedStringResource("count"),
        default: 4
    )
    precondition(described.defaultValue == 4)
    precondition(described.wrappedValue == 4)
    let descProvider = IntentParameter<Bool>(
        description: LocalizedStringResource("flag"),
        default: true,
        optionsProvider: Wave12Query()
    )
    precondition(descProvider.hasOptionsProvider == true)
    precondition(descProvider.wrappedValue == true)
    let descResolvers = IntentParameter<Double>(
        description: LocalizedStringResource("n"),
        default: 1.5,
        resolvers: EmptyResolverSpecification<Double>()
    )
    precondition(descResolvers.wrappedValue == 1.5)
    let both = IntentParameter<String>(
        description: LocalizedStringResource("both"),
        default: "x",
        optionsProvider: Wave12Query(),
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(both.hasOptionsProvider == true)
    let titledResolvers = IntentParameter<URL>(
        title: LocalizedStringResource("Link"),
        default: URL(string: "https://example.invalid")!,
        resolvers: EmptyResolverSpecification<URL>()
    )
    precondition(titledResolvers.wrappedValue.host == "example.invalid")
    let titledBoth = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        default: Date(timeIntervalSince1970: 1),
        optionsProvider: Wave12Query(),
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(titledBoth.hasOptionsProvider == true)

    func hostHash<T: Hashable>(_ value: T) -> Int {
        var hasher = Hasher()
        value.hash(into: &hasher)
        return hasher.finalize()
    }
    precondition(hostHash(IntentParameter<Int>.DateKind.time) != hostHash(IntentParameter<Int>.DateKind.date))
    precondition(hostHash(IntentParameter<Int>.IntControlStyle.stepper) != hostHash(IntentParameter<Int>.IntControlStyle.field))
    precondition(hostHash(IntentParameter<Int>.DoubleControlStyle.field) != hostHash(IntentParameter<Int>.DoubleControlStyle.stepper))
    precondition(hostHash(IntentParameter<Int>.PlacemarkDisplayStyle.city) != hostHash(IntentParameter<Int>.PlacemarkDisplayStyle.address))
}

func testEntityPropertyCodableStorageRoundTrip() {
    let title = LocalizedStringResource("Number")
    let key = CSCustomAttributeKey(keyName: "wave12.number")
    let stored: [EntityProperty<Int>] = [
        EntityProperty(),
        EntityProperty(title: title),
        EntityProperty(identifier: "number"),
        EntityProperty(identifier: "number", title: title),
        EntityProperty(indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(identifier: "number", indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(identifier: "number", title: title, indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(customIndexingKey: key),
        EntityProperty(identifier: "number", customIndexingKey: key),
        EntityProperty(identifier: "number", title: title, customIndexingKey: key),
    ]
    for property in stored {
        property.wrappedValue = 9
        precondition(property.wrappedValue == 9)
        let data = try! JSONEncoder().encode(property)
        let decoded = try! JSONDecoder().decode(EntityProperty<Int>.self, from: data)
        precondition(decoded.wrappedValue == 9)
        precondition(property.hostHashStoredValue() == decoded.hostHashStoredValue())
        precondition(String(describing: property.hostDisplayRepresentation.title).contains("9"))
    }
}

func testEntityPropertyCodableAccessorAndHash() {
    EntityResolutionEngine.reset()
    let row = Wave12Entity(id: "n", number: 11)
    EntityResolutionEngine.register([row], default: row)
    let title = LocalizedStringResource("Number")
    let key = CSCustomAttributeKey(keyName: "wave12.number")
    let accessors: [EntityProperty<Int>] = [
        EntityProperty(identifier: "number", getter: \Wave12Entity.number),
        EntityProperty(identifier: "number", getSetter: \Wave12Entity.number),
        EntityProperty(identifier: "number", title: title, getter: \Wave12Entity.number),
        EntityProperty(identifier: "number", title: title, getSetter: \Wave12Entity.number),
        EntityProperty(identifier: "number", indexingKey: \CSSearchableItemAttributeSet.title, getter: \Wave12Entity.number),
        EntityProperty(identifier: "number", indexingKey: \CSSearchableItemAttributeSet.title, getSetter: \Wave12Entity.number),
        EntityProperty(identifier: "number", customIndexingKey: key, getter: \Wave12Entity.number),
        EntityProperty(identifier: "number", customIndexingKey: key, getSetter: \Wave12Entity.number),
        EntityProperty(identifier: "number", title: title, indexingKey: \CSSearchableItemAttributeSet.title, getter: \Wave12Entity.number),
        EntityProperty(identifier: "number", title: title, indexingKey: \CSSearchableItemAttributeSet.title, getSetter: \Wave12Entity.number),
        EntityProperty(identifier: "number", title: title, customIndexingKey: key, getter: \Wave12Entity.number),
        EntityProperty(identifier: "number", title: title, customIndexingKey: key, getSetter: \Wave12Entity.number),
    ]
    for property in accessors {
        precondition(property.wrappedValue == 11)
        property.wrappedValue = 11
        let data = try! JSONEncoder().encode(property)
        let decoded = try! JSONDecoder().decode(EntityProperty<Int>.self, from: data)
        precondition(decoded.wrappedValue == 11)
        _ = property.hostHashStoredValue()
    }
}
