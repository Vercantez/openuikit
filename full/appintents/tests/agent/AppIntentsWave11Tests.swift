import Foundation
import AppIntents

private struct Wave11Entity<Value: _IntentValue & Sendable>: AppEntity {
    typealias DefaultQuery = Wave11Query<Value>
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Generic property row" }
    static var defaultQuery: Wave11Query<Value> { Wave11Query<Value>() }
    var id: String
    var value: Value
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave11Query<Value: _IntentValue & Sendable>: EntityQuery {
    typealias Entity = Wave11Entity<Value>
    init() {}
    func entities(for identifiers: [String]) async throws -> [Entity] {
        EntityResolutionEngine.entities(for: identifiers, as: Entity.self)
    }
    func suggestedEntities() async throws -> [Entity] {
        EntityResolutionEngine.suggestedEntities(Entity.self)
    }
}

private func checkStoredProperty<Value: _IntentValue & Sendable>(_ value: Value) {
    let title = LocalizedStringResource("Value")
    let custom = CSCustomAttributeKey(keyName: "wave11.value")
    let values: [EntityProperty<Value>] = [
        EntityProperty(), EntityProperty(title: title),
        EntityProperty(indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(title: title, indexingKey: \CSSearchableItemAttributeSet.displayName),
        EntityProperty(customIndexingKey: custom),
        EntityProperty(title: title, customIndexingKey: custom),
        EntityProperty(identifier: "value"),
        EntityProperty(identifier: "value", title: title),
        EntityProperty(identifier: "value", indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(identifier: "value", customIndexingKey: custom),
        EntityProperty(identifier: "value", title: title, indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(identifier: "value", title: title, customIndexingKey: custom),
    ]
    for property in values {
        property.wrappedValue = value
        precondition(String(describing: property.wrappedValue) == String(describing: value))
        precondition(property.projectedValue === property)
    }
    precondition(values[1].title.key == "Value")
    precondition(values[6].identifier == "value")
    precondition(values[2].indexingKeyPath != nil)
    precondition(values[4].customIndexingKey?.keyName == "wave11.value")
    let asyncProperty = EntityProperty<Value>(identifier: "value") {
        (entity: Wave11Entity<Value>) async throws -> Value in entity.value
    }
    let titledAsyncProperty = EntityProperty<Value>(identifier: "value", title: title) {
        (entity: Wave11Entity<Value>) async throws -> Value in entity.value
    }
    precondition(asyncProperty.hasAsyncGetter)
    precondition(titledAsyncProperty.hasAsyncGetter)
}

private func checkAccessedProperty<Value: _IntentValue & Sendable>(_ value: Value) {
    let entity = Wave11Entity(id: "default", value: value)
    EntityResolutionEngine.register([entity], default: entity)
    let title = LocalizedStringResource("Value")
    let custom = CSCustomAttributeKey(keyName: "wave11.value")
    let values: [EntityProperty<Value>] = [
        EntityProperty(identifier: "value", getter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", getSetter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", indexingKey: \CSSearchableItemAttributeSet.title, getter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", indexingKey: \CSSearchableItemAttributeSet.title, getSetter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", customIndexingKey: custom, getter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", customIndexingKey: custom, getSetter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", title: title, getter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", title: title, getSetter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", title: title, indexingKey: \CSSearchableItemAttributeSet.title, getter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", title: title, indexingKey: \CSSearchableItemAttributeSet.title, getSetter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", title: title, customIndexingKey: custom, getter: \Wave11Entity<Value>.value),
        EntityProperty(identifier: "value", title: title, customIndexingKey: custom, getSetter: \Wave11Entity<Value>.value),
    ]
    for property in values {
        precondition(String(describing: property.wrappedValue) == String(describing: value))
    }
}

private func checkWave11Value<Value: _IntentValue & Sendable>(_ value: Value, accessor: Bool) {
    if accessor { checkAccessedProperty(value) } else { checkStoredProperty(value) }
}

private func wave11Values(accessor: Bool) {
    checkWave11Value("text", accessor: accessor)
    checkWave11Value(true, accessor: accessor)
    checkWave11Value(3, accessor: accessor)
    checkWave11Value(2.5, accessor: accessor)
    checkWave11Value(Date(timeIntervalSince1970: 42), accessor: accessor)
    checkWave11Value(URL(string: "https://example.invalid/value")!, accessor: accessor)
    checkWave11Value(DateComponents(year: 2026, month: 9, day: 8), accessor: accessor)
    checkWave11Value(AttributedString("value"), accessor: accessor)
    checkWave11Value(Measurement(value: 1, unit: UnitAcceleration.metersPerSecondSquared), accessor: accessor)
    checkWave11Value(Measurement(value: 2, unit: UnitAngle.degrees), accessor: accessor)
    checkWave11Value(Measurement(value: 3, unit: UnitArea.squareMeters), accessor: accessor)
    checkWave11Value(Measurement(value: 4, unit: UnitDuration.seconds), accessor: accessor)
    checkWave11Value(Measurement(value: 5, unit: UnitElectricCharge.coulombs), accessor: accessor)
    checkWave11Value(Measurement(value: 6, unit: UnitElectricCurrent.amperes), accessor: accessor)
    checkWave11Value(Measurement(value: 7, unit: UnitElectricPotentialDifference.volts), accessor: accessor)
    checkWave11Value(Measurement(value: 8, unit: UnitElectricResistance.ohms), accessor: accessor)
    checkWave11Value(Measurement(value: 9, unit: UnitEnergy.joules), accessor: accessor)
    checkWave11Value(Measurement(value: 10, unit: UnitFrequency.hertz), accessor: accessor)
    checkWave11Value(Measurement(value: 11, unit: UnitFuelEfficiency.litersPer100Kilometers), accessor: accessor)
    checkWave11Value(Measurement(value: 12, unit: UnitIlluminance.lux), accessor: accessor)
    checkWave11Value(Measurement(value: 13, unit: UnitInformationStorage.bytes), accessor: accessor)
    checkWave11Value(Measurement(value: 14, unit: UnitLength.meters), accessor: accessor)
    checkWave11Value(Measurement(value: 15, unit: UnitMass.kilograms), accessor: accessor)
    checkWave11Value(Measurement(value: 16, unit: UnitPower.watts), accessor: accessor)
    checkWave11Value(Measurement(value: 17, unit: UnitPressure.newtonsPerMetersSquared), accessor: accessor)
    checkWave11Value(Measurement(value: 18, unit: UnitSpeed.metersPerSecond), accessor: accessor)
    checkWave11Value(Measurement(value: 19, unit: UnitTemperature.kelvin), accessor: accessor)
    checkWave11Value(Measurement(value: 20, unit: UnitVolume.liters), accessor: accessor)
}

func testEntityPropertyConcreteValueStorageMatrix() {
    wave11Values(accessor: false)
}

func testEntityPropertyConcreteValueAccessorMatrix() {
    EntityResolutionEngine.reset()
    wave11Values(accessor: true)
}
