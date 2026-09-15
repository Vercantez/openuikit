import Foundation
import SwiftData

/// A `PersistentModel` that provides its own `init(backingData:)` witness
/// instead of trapping in the protocol extension default. The initializer
/// adopts the bound backing data's identifier when one is present.
final class AgentBackedNote: PersistentModel {
    let persistentModelID: PersistentIdentifier
    var title: String

    init(title: String) {
        self.persistentModelID = PersistentIdentifier(entityName: "AgentBackedNote")
        self.title = title
    }

    init(backingData: any BackingData<AgentBackedNote>) {
        self.persistentModelID =
            backingData.persistentModelID
            ?? PersistentIdentifier(entityName: "AgentBackedNote")
        self.title = "backed"
    }
}

func testModelActorModelContext() {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let actor = AgentModelActor(container)
    let context = actor.modelContext
    precondition(context.container === container)
    precondition(context === actor.modelExecutor.modelContext)
    let note = AgentNote(title: "actor-context", count: 7)
    context.insert(note)
    try! context.save()
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 1)
}

func testModelActorSubscriptLookup() {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let actor = AgentModelActor(container)
    let note = AgentNote(title: "lookup", count: 3)
    actor.modelContext.insert(note)
    let found: AgentNote? = actor[note.persistentModelID, as: AgentNote.self]
    precondition(found === note)
    let missing: AgentNote? = actor[
        PersistentIdentifier(entityName: "AgentNote"),
        as: AgentNote.self
    ]
    precondition(missing == nil)
}

func testPersistentModelInitBackingData() {
    let source = AgentBackedNote(title: "source")
    let bound = PortableBackingData<AgentBackedNote>(model: source)
    let restored = AgentBackedNote(backingData: bound)
    precondition(restored.persistentModelID == source.persistentModelID)
    precondition(restored.title == "backed")
    let unbound = PortableBackingData<AgentBackedNote>(for: AgentBackedNote.self)
    precondition(unbound.persistentModelID == nil)
    let fresh = AgentBackedNote(backingData: unbound)
    precondition(fresh.title == "backed")
}
