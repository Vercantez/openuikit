import Foundation
import AppIntents

private struct Wave10IntegerEntity: AppEntity {
    typealias DefaultQuery = Wave10IntegerQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Integer row" }
    static var defaultQuery = Wave10IntegerQuery()
    var id: String
    var number: Int
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave10IntegerQuery: EntityQuery {
    typealias Entity = Wave10IntegerEntity
    func entities(for identifiers: [String]) async throws -> [Wave10IntegerEntity] {
        EntityResolutionEngine.entities(for: identifiers, as: Wave10IntegerEntity.self)
    }
    func suggestedEntities() async throws -> [Wave10IntegerEntity] {
        EntityResolutionEngine.suggestedEntities(Wave10IntegerEntity.self)
    }
}

/// Exercises the stored-value and metadata variants shared by the concrete
/// EntityProperty specializations in the pinned graph.
func testEntityPropertyConcreteStorageAndMetadataMatrix() {
    let value = 42
    let title = LocalizedStringResource("Number")
    let key = CSCustomAttributeKey(keyName: "number.custom")
    let wrappers: [EntityProperty<Int>] = [
        EntityProperty(), EntityProperty(title: title),
        EntityProperty(indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(title: title, indexingKey: \CSSearchableItemAttributeSet.displayName),
        EntityProperty(customIndexingKey: key), EntityProperty(title: title, customIndexingKey: key),
        EntityProperty(identifier: "number"), EntityProperty(identifier: "number", title: title),
        EntityProperty(identifier: "number", indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(identifier: "number", customIndexingKey: key),
        EntityProperty(identifier: "number", title: title, indexingKey: \CSSearchableItemAttributeSet.title),
        EntityProperty(identifier: "number", title: title, customIndexingKey: key),
    ]
    for wrapper in wrappers {
        wrapper.wrappedValue = value
        precondition(wrapper.wrappedValue == value)
        precondition(wrapper.projectedValue === wrapper)
    }
    precondition(wrappers[1].title.key == "Number")
    precondition(wrappers[6].identifier == "number")
    precondition(wrappers[2].indexingKeyPath != nil)
    precondition(wrappers[4].customIndexingKey?.keyName == "number.custom")
}

/// Exercises every synchronous key-path/get-set form against the host-driven
/// default entity resolution engine; no daemon or run-loop behavior is used.
func testEntityPropertyConcreteAccessorMatrix() {
    EntityResolutionEngine.reset()
    let row = Wave10IntegerEntity(id: "answer", number: 42)
    EntityResolutionEngine.register([row], default: row)
    let title = LocalizedStringResource("Number")
    let key = CSCustomAttributeKey(keyName: "number.custom")
    let wrappers: [EntityProperty<Int>] = [
        EntityProperty(identifier: "number", getter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", getSetter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", indexingKey: \CSSearchableItemAttributeSet.title, getter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", indexingKey: \CSSearchableItemAttributeSet.title, getSetter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", customIndexingKey: key, getter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", customIndexingKey: key, getSetter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", title: title, getter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", title: title, getSetter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", title: title, indexingKey: \CSSearchableItemAttributeSet.title, getter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", title: title, indexingKey: \CSSearchableItemAttributeSet.title, getSetter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", title: title, customIndexingKey: key, getter: \Wave10IntegerEntity.number),
        EntityProperty(identifier: "number", title: title, customIndexingKey: key, getSetter: \Wave10IntegerEntity.number),
    ]
    for wrapper in wrappers { precondition(wrapper.wrappedValue == 42) }
    precondition(wrappers[2].indexingKeyPath != nil)
    precondition(wrappers[4].customIndexingKey?.keyName == "number.custom")
    precondition(wrappers[6].title.key == "Number")
}
