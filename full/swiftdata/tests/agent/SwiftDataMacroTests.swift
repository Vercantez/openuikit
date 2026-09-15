import Foundation
import SwiftData

/// Portable counterpart of the Darwin `@Model` macro: the Linux port adopts
/// `PersistentModel` directly instead of expanding the macro plugin.
final class MacroNote: PersistentModel {
    let persistentModelID = PersistentIdentifier(entityName: "MacroNote")
    var title: String
    var count: Int

    init(title: String, count: Int) {
        self.title = title
        self.count = count
    }
}

private func makeMacroContext() -> ModelContext {
    let container = try! ModelContainer(
        for: MacroNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

func testModelMacroPortable() {
    typealias Model = MacroNote
    let container = try! ModelContainer(
        for: Model.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    context.insert(Model(title: "macro", count: 1))
    context.insert(Model(title: "macro", count: 2))
    try! context.save()
    let rows = try! context.fetch(FetchDescriptor<Model>())
    precondition(rows.count == 2)
    precondition(rows.map(\.count).sorted() == [1, 2])
    precondition(Schema.entityName(for: Model.self) == "MacroNote")
    precondition(Schema([Model.self]).entity(for: Model.self)?.name == "MacroNote")
}

func testModelActorMacroPortable() {
    func containerOf<A: ModelActor>(actor: A) -> ModelContainer {
        actor.modelContainer
    }
    let container = try! ModelContainer(
        for: MacroNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let actor = AgentModelActor(container)
    precondition(containerOf(actor: actor) === container)
    precondition(actor.modelExecutor.modelContext.container === container)
    _ = actor.unownedExecutor
    let note = MacroNote(title: "actor", count: 2)
    actor.modelContext.insert(note)
    try! actor.modelContext.save()
    let found: MacroNote? = actor[note.persistentModelID, as: MacroNote.self]
    precondition(found === note)
}

func testTransientMacroPortable() {
    typealias Transient = Schema.Attribute
    let scratch = Transient(
        name: "scratch",
        options: [.ephemeral],
        valueType: String.self
    )
    precondition(scratch.isTransient)
    precondition(!scratch.isUnique)
    precondition(scratch.isAttribute)
    let kept = Transient(name: "kept", valueType: String.self)
    precondition(!kept.isTransient)
    let data = try! JSONEncoder().encode(scratch)
    let loaded = try! JSONDecoder().decode(Schema.Attribute.self, from: data)
    precondition(loaded.isTransient)
    precondition(loaded.name == "scratch")
}

func testAttributeMacroPortable() {
    let attribute = Schema.Attribute(
        .unique,
        .spotlight,
        originalName: "title",
        hashModifier: "v1"
    )
    precondition(attribute.name == "title")
    precondition(attribute.originalName == "title")
    precondition(attribute.isAttribute)
    precondition(attribute.isUnique)
    precondition(!attribute.isTransient)
    precondition(attribute.hashModifier == "v1")
    precondition(attribute.debugDescription == "Attribute(title)")
    let data = try! JSONEncoder().encode(attribute)
    let loaded = try! JSONDecoder().decode(Schema.Attribute.self, from: data)
    precondition(loaded == attribute)
}

func testRelationshipMacroPortable() {
    let relationship = Schema.Relationship(
        .unique,
        deleteRule: .cascade,
        minimumModelCount: 0,
        maximumModelCount: 1,
        originalName: "favorite",
        inverse: \MacroNote.title,
        hashModifier: "r1"
    )
    precondition(relationship.name == "favorite")
    precondition(relationship.originalName == "favorite")
    precondition(relationship.deleteRule == .cascade)
    precondition(relationship.isRelationship)
    precondition(relationship.isToOneRelationship)
    precondition(relationship.isOptional)
    precondition(relationship.minimumModelCount == 0)
    precondition(relationship.maximumModelCount == 1)
    precondition(relationship.inverseKeyPath != nil)
    precondition(relationship.hashModifier == "r1")
    precondition(relationship.debugDescription == "Relationship(favorite)")
    let data = try! JSONEncoder().encode(relationship)
    let loaded = try! JSONDecoder().decode(Schema.Relationship.self, from: data)
    precondition(loaded.deleteRule == .cascade)
    precondition(loaded.name == "favorite")
}

func testIndexTypesMacroPortable() {
    let index = Schema.Index<MacroNote>(
        .binary([\MacroNote.title]),
        .rtree([\MacroNote.count])
    )
    precondition(index.name == "index")
    precondition(index.indices.count == 2)
    precondition(!index.isUnique)
    switch index.indices[0] {
    case .binary(let paths):
        precondition(paths.count == 1)
    case .rtree:
        preconditionFailure("expected binary first")
    }
    switch index.indices[1] {
    case .rtree(let paths):
        precondition(paths.count == 1)
    case .binary:
        preconditionFailure("expected rtree second")
    }
    let entity = Schema.Entity(
        "MacroNote",
        properties: Schema.Attribute(name: "title", valueType: String.self)
    )
    precondition(entity.attributesByName["title"]?.name == "title")
}

func testIndexKeyPathsMacroPortable() {
    let index = Schema.Index<MacroNote>([\MacroNote.title], [\MacroNote.count])
    precondition(index.indices.count == 2)
    for entry in index.indices {
        switch entry {
        case .binary(let paths):
            precondition(paths.count == 1)
        case .rtree:
            preconditionFailure("key-path list must lower to binary indices")
        }
    }
    let data = try! JSONEncoder().encode(index)
    _ = try! JSONDecoder().decode(Schema.Index<MacroNote>.self, from: data)
}

func testUniqueMacroPortable() {
    let unique = Schema.Unique<MacroNote>([\MacroNote.title], [\MacroNote.count])
    precondition(unique.isUnique)
    precondition(unique.constraints.count == 2)
    precondition(unique.debugDescription == "Unique(unique)")
    precondition(!unique.isAttribute)
    precondition(!unique.isRelationship)
    let single = Schema.Unique<MacroNote>([\MacroNote.title])
    precondition(single.constraints.count == 1)
    precondition(single == Schema.Unique<MacroNote>([\MacroNote.title]))
    let data = try! JSONEncoder().encode(single)
    _ = try! JSONDecoder().decode(Schema.Unique<MacroNote>.self, from: data)
}
