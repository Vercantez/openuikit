import Foundation
import AppIntents

// Wave 16: portable in-process data-model coverage.
// Every test below is synchronous and uses no Apple daemon, Spotlight index,
// Siri service, waiting, or suspension point. Measurement unit enums exercise
// compiler-synthesized `CaseIterable`/`Hashable` behavior in-process (host
// hashing is process-local). `EntityPropertyQuery` defaults, assistant
// schema values, and `ParameterSummaryWhenCondition` overloads store and
// return in-process metadata; key-path conditions never claim a Siri match
// and evaluate to the `otherwise` branch.

private struct Wave16AnyValue: AnyIntentValue {}

private struct Wave16Summary: ParameterSummary {
    typealias Intent = Wave16Intent
    var evaluatedDisplayString: String
}

private struct Wave16Intent: AppIntent {
    static var title: LocalizedStringResource { "Wave16" }
    var marker: Wave16AnyValue
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: "wave16", dialog: IntentDialog("ok"))
    }
}

private struct Wave16Entity: AppEntity {
    typealias DefaultQuery = Wave16Query
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave16" }
    static var defaultQuery = Wave16Query()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave16Query: EntityPropertyQuery {
    typealias Entity = Wave16Entity
    typealias ComparatorMappingType = String
    func entities(for identifiers: [String]) async throws -> [Wave16Entity] { [] }
    func suggestedEntities() async throws -> [Wave16Entity] { [] }
}

private enum Wave16AssistEnum: String, AssistantEnum {
    case wave
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave16" }
    static var caseDisplayRepresentations: [Wave16AssistEnum: DisplayRepresentation] {
        [.wave: DisplayRepresentation(title: "wave")]
    }
}

private enum Wave16SchemaEnum: String, AssistantSchemaEnum {
    case wave
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave16" }
    static var caseDisplayRepresentations: [Wave16SchemaEnum: DisplayRepresentation] {
        [.wave: DisplayRepresentation(title: "wave")]
    }
}

private struct Wave16AssistEntityQuery: EntityQuery {
    typealias Entity = Wave16AssistEntity
    func entities(for identifiers: [String]) async throws -> [Wave16AssistEntity] { [] }
    func suggestedEntities() async throws -> [Wave16AssistEntity] { [] }
}

private struct Wave16AssistEntity: AssistantEntity {
    typealias DefaultQuery = Wave16AssistEntityQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave16" }
    static var defaultQuery = Wave16AssistEntityQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave16AssistIntent: AssistantIntent {
    static var title: LocalizedStringResource { "Wave16" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: "wave16", dialog: IntentDialog("ok"))
    }
}

private func wave16IsAssistantEnum<T: AssistantEnum>(_: T.Type) -> Bool { true }
private func wave16IsAssistantEntity<T: AssistantEntity>(_: T.Type) -> Bool { true }
private func wave16IsAssistantIntent<T: AssistantIntent>(_: T.Type) -> Bool { true }
private func wave16IsAssistantSchemaEnum<T: AssistantSchemaEnum>(_: T.Type) -> Bool { true }
private func wave16IsModel<T: AssistantSchemas.Model>(_: T.Type) -> Bool { true }
private func wave16IsSchemaEnum<T: AssistantSchemas.Enum>(_: T.Type) -> Bool { true }
private func wave16IsSchemaEntity<T: AssistantSchemas.Entity>(_: T.Type) -> Bool { true }
private func wave16IsSchemaIntent<T: AssistantSchemas.Intent>(_: T.Type) -> Bool { true }
private func wave16IsSearchCriteria<S: SearchCriteria>(_: S.Type) -> Bool { true }

private func wave16Branch(_ string: String) -> Wave16Summary {
    Wave16Summary(evaluatedDisplayString: string)
}

func testMeasurementValueTypeAllCasesTable() {
    precondition(!IntentParameter<Measurement<UnitVolume>>.Volume.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitLength>>.Length.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitMass>>.Mass.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitArea>>.Area.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitPower>>.Power.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitPressure>>.Pressure.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitDuration>>.Duration.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitAngle>>.Angle.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitEnergy>>.Energy.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitSpeed>>.Speed.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases.isEmpty)
    precondition(!IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases.isEmpty)
    precondition(Set(IntentParameter<Measurement<UnitArea>>.Area.allCases).count == IntentParameter<Measurement<UnitArea>>.Area.allCases.count)
}

func testMeasurementValueTypeHashValueTable() {
    precondition(IntentParameter<Measurement<UnitVolume>>.Volume.allCases[0].hashValue == IntentParameter<Measurement<UnitVolume>>.Volume.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitLength>>.Length.allCases[0].hashValue == IntentParameter<Measurement<UnitLength>>.Length.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases[0].hashValue == IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitMass>>.Mass.allCases[0].hashValue == IntentParameter<Measurement<UnitMass>>.Mass.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitArea>>.Area.allCases[0].hashValue == IntentParameter<Measurement<UnitArea>>.Area.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitPower>>.Power.allCases[0].hashValue == IntentParameter<Measurement<UnitPower>>.Power.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitPressure>>.Pressure.allCases[0].hashValue == IntentParameter<Measurement<UnitPressure>>.Pressure.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases[0].hashValue == IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitDuration>>.Duration.allCases[0].hashValue == IntentParameter<Measurement<UnitDuration>>.Duration.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitAngle>>.Angle.allCases[0].hashValue == IntentParameter<Measurement<UnitAngle>>.Angle.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases[0].hashValue == IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitEnergy>>.Energy.allCases[0].hashValue == IntentParameter<Measurement<UnitEnergy>>.Energy.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases[0].hashValue == IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases[0].hashValue == IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases[0].hashValue == IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitSpeed>>.Speed.allCases[0].hashValue == IntentParameter<Measurement<UnitSpeed>>.Speed.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases[0].hashValue == IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases[0].hashValue == IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases[0].hashValue == IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases[0].hashValue == IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases[0].hashValue == IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases[0].hashValue)
    precondition(IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases[0].hashValue == IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases[0].hashValue)
}

func testMeasurementValueTypeHashIntoTable() {
    var volume1 = Hasher()
    IntentParameter<Measurement<UnitVolume>>.Volume.allCases[0].hash(into: &volume1)
    var volume2 = Hasher()
    IntentParameter<Measurement<UnitVolume>>.Volume.allCases[0].hash(into: &volume2)
    precondition(volume1.finalize() == volume2.finalize())
    var length1 = Hasher()
    IntentParameter<Measurement<UnitLength>>.Length.allCases[0].hash(into: &length1)
    var length2 = Hasher()
    IntentParameter<Measurement<UnitLength>>.Length.allCases[0].hash(into: &length2)
    precondition(length1.finalize() == length2.finalize())
    var storage1 = Hasher()
    IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases[0].hash(into: &storage1)
    var storage2 = Hasher()
    IntentParameter<Measurement<UnitInformationStorage>>.InformationStorage.allCases[0].hash(into: &storage2)
    precondition(storage1.finalize() == storage2.finalize())
    var mass1 = Hasher()
    IntentParameter<Measurement<UnitMass>>.Mass.allCases[0].hash(into: &mass1)
    var mass2 = Hasher()
    IntentParameter<Measurement<UnitMass>>.Mass.allCases[0].hash(into: &mass2)
    precondition(mass1.finalize() == mass2.finalize())
    var area1 = Hasher()
    IntentParameter<Measurement<UnitArea>>.Area.allCases[0].hash(into: &area1)
    var area2 = Hasher()
    IntentParameter<Measurement<UnitArea>>.Area.allCases[0].hash(into: &area2)
    precondition(area1.finalize() == area2.finalize())
    var power1 = Hasher()
    IntentParameter<Measurement<UnitPower>>.Power.allCases[0].hash(into: &power1)
    var power2 = Hasher()
    IntentParameter<Measurement<UnitPower>>.Power.allCases[0].hash(into: &power2)
    precondition(power1.finalize() == power2.finalize())
    var pressure1 = Hasher()
    IntentParameter<Measurement<UnitPressure>>.Pressure.allCases[0].hash(into: &pressure1)
    var pressure2 = Hasher()
    IntentParameter<Measurement<UnitPressure>>.Pressure.allCases[0].hash(into: &pressure2)
    precondition(pressure1.finalize() == pressure2.finalize())
    var frequency1 = Hasher()
    IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases[0].hash(into: &frequency1)
    var frequency2 = Hasher()
    IntentParameter<Measurement<UnitFrequency>>.Frequency.allCases[0].hash(into: &frequency2)
    precondition(frequency1.finalize() == frequency2.finalize())
    var duration1 = Hasher()
    IntentParameter<Measurement<UnitDuration>>.Duration.allCases[0].hash(into: &duration1)
    var duration2 = Hasher()
    IntentParameter<Measurement<UnitDuration>>.Duration.allCases[0].hash(into: &duration2)
    precondition(duration1.finalize() == duration2.finalize())
    var angle1 = Hasher()
    IntentParameter<Measurement<UnitAngle>>.Angle.allCases[0].hash(into: &angle1)
    var angle2 = Hasher()
    IntentParameter<Measurement<UnitAngle>>.Angle.allCases[0].hash(into: &angle2)
    precondition(angle1.finalize() == angle2.finalize())
    var charge1 = Hasher()
    IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases[0].hash(into: &charge1)
    var charge2 = Hasher()
    IntentParameter<Measurement<UnitElectricCharge>>.ElectricCharge.allCases[0].hash(into: &charge2)
    precondition(charge1.finalize() == charge2.finalize())
    var energy1 = Hasher()
    IntentParameter<Measurement<UnitEnergy>>.Energy.allCases[0].hash(into: &energy1)
    var energy2 = Hasher()
    IntentParameter<Measurement<UnitEnergy>>.Energy.allCases[0].hash(into: &energy2)
    precondition(energy1.finalize() == energy2.finalize())
    var current1 = Hasher()
    IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases[0].hash(into: &current1)
    var current2 = Hasher()
    IntentParameter<Measurement<UnitElectricCurrent>>.ElectricCurrent.allCases[0].hash(into: &current2)
    precondition(current1.finalize() == current2.finalize())
    var resistance1 = Hasher()
    IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases[0].hash(into: &resistance1)
    var resistance2 = Hasher()
    IntentParameter<Measurement<UnitElectricResistance>>.ElectricResistance.allCases[0].hash(into: &resistance2)
    precondition(resistance1.finalize() == resistance2.finalize())
    var potential1 = Hasher()
    IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases[0].hash(into: &potential1)
    var potential2 = Hasher()
    IntentParameter<Measurement<UnitElectricPotentialDifference>>.ElectricPotentialDifference.allCases[0].hash(into: &potential2)
    precondition(potential1.finalize() == potential2.finalize())
    var speed1 = Hasher()
    IntentParameter<Measurement<UnitSpeed>>.Speed.allCases[0].hash(into: &speed1)
    var speed2 = Hasher()
    IntentParameter<Measurement<UnitSpeed>>.Speed.allCases[0].hash(into: &speed2)
    precondition(speed1.finalize() == speed2.finalize())
    var temperature1 = Hasher()
    IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases[0].hash(into: &temperature1)
    var temperature2 = Hasher()
    IntentParameter<Measurement<UnitTemperature>>.Temperature.allCases[0].hash(into: &temperature2)
    precondition(temperature1.finalize() == temperature2.finalize())
    var efficiency1 = Hasher()
    IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases[0].hash(into: &efficiency1)
    var efficiency2 = Hasher()
    IntentParameter<Measurement<UnitFuelEfficiency>>.FuelEfficiency.allCases[0].hash(into: &efficiency2)
    precondition(efficiency1.finalize() == efficiency2.finalize())
    var acceleration1 = Hasher()
    IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases[0].hash(into: &acceleration1)
    var acceleration2 = Hasher()
    IntentParameter<Measurement<UnitAcceleration>>.Acceleration.allCases[0].hash(into: &acceleration2)
    precondition(acceleration1.finalize() == acceleration2.finalize())
    var concentration1 = Hasher()
    IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases[0].hash(into: &concentration1)
    var concentration2 = Hasher()
    IntentParameter<Measurement<UnitConcentrationMass>>.ConcentrationMass.allCases[0].hash(into: &concentration2)
    precondition(concentration1.finalize() == concentration2.finalize())
    var dispersion1 = Hasher()
    IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases[0].hash(into: &dispersion1)
    var dispersion2 = Hasher()
    IntentParameter<Measurement<UnitDispersion>>.Dispersion.allCases[0].hash(into: &dispersion2)
    precondition(dispersion1.finalize() == dispersion2.finalize())
    var illuminance1 = Hasher()
    IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases[0].hash(into: &illuminance1)
    var illuminance2 = Hasher()
    IntentParameter<Measurement<UnitIlluminance>>.Illuminance.allCases[0].hash(into: &illuminance2)
    precondition(illuminance1.finalize() == illuminance2.finalize())
}

func testEntityPropertyQueryDefaults() {
    precondition(Wave16Query.properties.hostDeclarations.isEmpty)
    precondition(Wave16Query.sortingOptions.hostSorting.isEmpty)
    precondition(Wave16Query.findIntentDescription == nil)
    let properties: Wave16Query.QueryProperties = Wave16Query.properties
    precondition(properties.hostDeclarations.isEmpty)
}

func testEntityPropertyQueryTypeAliases() {
    let mapping: Wave16Query.ComparatorMappingType = "wave16"
    precondition(mapping == "wave16")
    let properties: Wave16Query.QueryProperties = Wave16Query.properties
    precondition(properties.hostDeclarations.isEmpty)
    let mode: Wave16Query.ComparatorMode = .or
    precondition(mode == .or)
    let options: Wave16Query.SortingOptions = Wave16Query.sortingOptions
    precondition(options.hostSorting.isEmpty)
    let sort: Wave16Query.Sort<Wave16Entity> = EntityQuerySort()
    precondition(sort.order == .ascending)
}

func testAssistantSchemaConstruction() {
    let empty = AssistantSchema()
    let fromEnum = AssistantSchema(AssistantSchemas.EnumSchema("camera"))
    let fromEntity = AssistantSchema(AssistantSchemas.EntitySchema("mail"))
    let fromIntent = AssistantSchema(AssistantSchemas.IntentSchema("search"))
    let nestedEnum = AssistantSchema.EnumSchema()
    let nestedEntity = AssistantSchema.EntitySchema()
    let nestedIntent = AssistantSchema.IntentSchema()
    _ = (empty, fromEnum, fromEntity, fromIntent, nestedEnum, nestedEntity, nestedIntent)
}

func testAssistantProtocolIdentities() {
    precondition(wave16IsAssistantEnum(Wave16AssistEnum.self))
    precondition(wave16IsAssistantEntity(Wave16AssistEntity.self))
    precondition(wave16IsAssistantIntent(Wave16AssistIntent.self))
    precondition(wave16IsAssistantSchemaEnum(Wave16SchemaEnum.self))
    precondition(wave16IsModel(AssistantSchemas.EnumSchema.self))
    precondition(wave16IsSchemaEnum(AssistantSchemas.EnumSchema.self))
    precondition(wave16IsSchemaEntity(AssistantSchemas.EntitySchema.self))
    precondition(wave16IsSchemaIntent(AssistantSchemas.IntentSchema.self))
    precondition(wave16IsSearchCriteria(StringSearchCriteria.self))
}

func testWhenConditionIdentifierOverloads() {
    let stringMatch = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        identifier: StringComparisonOperator.contains,
        "wave",
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(stringMatch.evaluatedDisplayString == "otherwise")
    let equalMatch = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        identifier: EquatableComparisonOperator.equalTo,
        "wave",
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(equalMatch.evaluatedDisplayString == "otherwise")
    let comparableMatch = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        identifier: ComparableComparisonOperator.greaterThan,
        3,
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(comparableMatch.evaluatedDisplayString == "otherwise")
    let equalIntMatch = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        identifier: EquatableComparisonOperator.equalTo,
        3,
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(equalIntMatch.evaluatedDisplayString == "otherwise")
    let oneOfStrings = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        identifier: OneOfComparisonOperator.oneOf,
        ["wave"],
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(oneOfStrings.evaluatedDisplayString == "otherwise")
    let oneOfInts = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        identifier: OneOfComparisonOperator.oneOf,
        [3],
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(oneOfInts.evaluatedDisplayString == "otherwise")
}

func testWhenConditionWidgetFamilyAndHasValue() {
    let familyOneOf = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        widgetFamily: OneOfComparisonOperator.oneOf,
        [.systemSmall],
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(familyOneOf.evaluatedDisplayString == "otherwise")
    let familyEqual = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        widgetFamily: EquatableComparisonOperator.equalTo,
        .systemSmall,
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(familyEqual.evaluatedDisplayString == "otherwise")
    let hasValue = ParameterSummaryWhenCondition<Wave16Intent, Wave16Summary, Wave16Summary>(
        \Wave16Intent.marker,
        HasValueComparisonOperator.hasAnyValue,
        { wave16Branch("when") },
        otherwise: { wave16Branch("otherwise") }
    )
    precondition(hasValue.evaluatedDisplayString == "otherwise")
}
