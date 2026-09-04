import Foundation
import SwiftData

final class AgentNote: PersistentModel {
    let persistentModelID = PersistentIdentifier(entityName: "AgentNote")
    var title: String
    var count: Int

    init(title: String, count: Int) {
        self.title = title
        self.count = count
    }
}

private func makeContext() throws -> ModelContext {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

func testInMemoryInsertFetchDelete() {
    let context = try! makeContext()
    let one = AgentNote(title: "one", count: 1)
    let two = AgentNote(title: "two", count: 2)
    context.insert(one)
    context.insert(two)
    precondition(context.hasChanges)
    precondition(context.insertedModelsArray.count == 2)
    try! context.save()
    precondition(!context.hasChanges)
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 2)
    context.delete(one)
    precondition(context.deletedModelsArray.count == 1)
    try! context.save()
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 1)
}

func testPredicateSortLimit() {
    let context = try! makeContext()
    context.insert(AgentNote(title: "a", count: 1))
    context.insert(AgentNote(title: "b", count: 5))
    context.insert(AgentNote(title: "a", count: 3))
    try! context.save()
    var descriptor = FetchDescriptor<AgentNote>(
        sortBy: [SortDescriptor(\AgentNote.count, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    let rows = try! context.fetch(descriptor)
    precondition(rows.count == 1)
    precondition(rows[0].count == 5)
}

func testRollbackRestoresDeleted() {
    let context = try! makeContext()
    let keep = AgentNote(title: "keep", count: 1)
    context.insert(keep)
    try! context.save()
    let transient = AgentNote(title: "transient", count: 9)
    context.insert(transient)
    context.rollback()
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 1)
    context.delete(keep)
    context.rollback()
    precondition(context.model(for: keep.persistentModelID) as? AgentNote === keep)
}

func testDurableConfigurationFailsClosed() {
    do {
        _ = try ModelContainer(
            for: AgentNote.self,
            configurations: ModelConfiguration()
        )
        preconditionFailure("durable configuration unexpectedly succeeded")
    } catch SwiftDataError.unsupportedPersistentStore {
        precondition(!SwiftDataPortable.supportsDurableStorage)
        precondition(!SwiftDataPortable.supportsCloudKit)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testQueryLiveReads() {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    context.insert(AgentNote(title: "q", count: 4))
    context.insert(AgentNote(title: "q", count: 8))
    try! context.save()
    SwiftDataPortable.installDefaultContainer(container)
    @Query(sort: \AgentNote.count, order: .reverse)
    var values: [AgentNote]
    precondition(values.map(\.count) == [8, 4])
}

func testFetchCountAndOffset() {
    let context = try! makeContext()
    context.insert(AgentNote(title: "n", count: 1))
    context.insert(AgentNote(title: "n", count: 2))
    context.insert(AgentNote(title: "n", count: 3))
    var descriptor = FetchDescriptor<AgentNote>(
        sortBy: [SortDescriptor(\AgentNote.count, order: .forward)]
    )
    descriptor.fetchOffset = 1
    descriptor.fetchLimit = 1
    let rows = try! context.fetch(descriptor)
    precondition(rows.map(\.count) == [2])
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 3)
}

func testSchemaEntitiesAndEquality() {
    let entity = Schema.Entity(
        "Note",
        properties: Schema.Attribute(
            name: "title",
            options: [.unique],
            valueType: String.self
        )
    )
    let schema = Schema(entity, version: Schema.Version(1, 2, 3))
    precondition(schema.entities.count == 1)
    precondition(schema.entitiesByName["Note"] != nil)
    precondition(schema.version.major == 1)
    precondition(schema.entity(for: AgentNote.self) == nil)
    let copy = Schema(entity, version: Schema.Version(1, 2, 3))
    precondition(schema == copy)
    precondition(Schema.entityName(for: AgentNote.self) == "AgentNote")
}

func testSchemaSaveLoadRoundTrip() {
    let schema = Schema(
        Schema.Entity("Metric"),
        version: Schema.Version(2, 0, 0)
    )
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("swiftdata-schema-\(UUID().uuidString).json")
    try! schema.save(to: url)
    let loaded = try! Schema.load(from: url)
    precondition(loaded == schema)
    try! FileManager.default.removeItem(at: url)
}

func testSchemaVersionOrder() {
    precondition(Schema.Version(1, 0, 0) < Schema.Version(1, 1, 0))
    precondition(Schema.Version(1, 1, 0) < Schema.Version(2, 0, 0))
    precondition(Schema.schemaEncodingVersion.major == 1)
}

func testPersistentIdentifierRoundTrip() {
    let identifier = try! PersistentIdentifier.identifier(
        for: "store",
        entityName: "AgentNote",
        primaryKey: "abc"
    )
    precondition(identifier.entityName == "AgentNote")
    precondition(identifier.storeIdentifier == "store")
    let data = try! JSONEncoder().encode(identifier)
    let decoded = try! JSONDecoder().decode(PersistentIdentifier.self, from: data)
    precondition(decoded.rawValue == identifier.rawValue)
    precondition(identifier < PersistentIdentifier())
}

func testFetchResultsCollectionBatch() {
    let context = try! makeContext()
    context.insert(AgentNote(title: "b", count: 1))
    try! context.save()
    var descriptor = FetchDescriptor<AgentNote>()
    descriptor.includePendingChanges = false
    let collection = try! context.fetch(descriptor, batchSize: 10)
    precondition(collection.count == 1)
    precondition(collection.startIndex == 0)
    precondition(collection[0].title == "b")
}

func testFetchIdentifiers() {
    let context = try! makeContext()
    let note = AgentNote(title: "id", count: 1)
    context.insert(note)
    try! context.save()
    let ids = try! context.fetchIdentifiers(FetchDescriptor<AgentNote>())
    precondition(ids == [note.persistentModelID])
}

func testTransactionSave() {
    let context = try! makeContext()
    try! context.transaction {
        context.insert(AgentNote(title: "tx", count: 7))
    }
    precondition(!context.hasChanges)
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 1)
}

func testDeleteWhere() {
    let context = try! makeContext()
    context.insert(AgentNote(title: "keep", count: 1))
    context.insert(AgentNote(title: "drop", count: 2))
    try! context.save()
    try! context.delete(model: AgentNote.self, where: nil)
    try! context.save()
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 0)
}

func testEnumerate() {
    let context = try! makeContext()
    context.insert(AgentNote(title: "e", count: 1))
    context.insert(AgentNote(title: "e", count: 2))
    var seen = 0
    try! context.enumerate(FetchDescriptor<AgentNote>()) { _ in seen += 1 }
    precondition(seen == 2)
}

func testDeleteAllData() {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    context.insert(AgentNote(title: "gone", count: 1))
    try! context.save()
    container.deleteAllData()
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 0)
}

func testRegisteredModel() {
    let context = try! makeContext()
    let note = AgentNote(title: "reg", count: 4)
    context.insert(note)
    let found: AgentNote? = context.registeredModel(for: note.persistentModelID)
    precondition(found === note)
}

func testDefaultStoreInMemorySaveFetch() {
    let store = try! DefaultStore(ModelConfiguration(isStoredInMemoryOnly: true))
    let snapshot = DefaultSnapshot(persistentIdentifier: PersistentIdentifier(entityName: "AgentNote"))
    _ = try! store.save(
        DataStoreSaveChangesRequest(inserted: [snapshot], editingState: EditingState())
    )
    let fetched = try! store.fetch(
        DataStoreFetchRequest(descriptor: FetchDescriptor<AgentNote>())
    )
    precondition(fetched.fetchedSnapshots.count == 1)
    precondition(try! store.fetchCount(DataStoreFetchRequest(descriptor: FetchDescriptor<AgentNote>())) == 1)
}

func testDefaultStoreDurableFails() {
    do {
        _ = try DefaultStore(ModelConfiguration(isStoredInMemoryOnly: false))
        preconditionFailure("durable DefaultStore unexpectedly succeeded")
    } catch SwiftDataError.unsupportedPersistentStore {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testSwiftDataErrorPatternMatch() {
    let error: any Error = SwiftDataError.unsupportedPredicate
    precondition(SwiftDataError.unsupportedPredicate ~= error)
    precondition(SwiftDataError.unknownSchema != SwiftDataError.missingModelContext)
}

func testModelConfigurationValidation() {
    do {
        try ModelConfiguration("bad/name", isStoredInMemoryOnly: true).validate()
        preconditionFailure("invalid name unexpectedly validated")
    } catch SwiftDataError.configurationFileNameContainsInvalidCharacters {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testNotificationNames() {
    precondition(ModelContext.didSave.rawValue.contains("didSave"))
    precondition(ModelContext.willSave.rawValue.contains("willSave"))
    precondition(ModelContext.NotificationKey.insertedIdentifiers.rawValue == "insertedIdentifiers")
}

func testAttributeOptionsAndRelationshipRules() {
    precondition(Schema.Attribute.Option.unique.name == "unique")
    precondition(Schema.Attribute.Option.transformable(by: "secure").transformerName == "secure")
    let relationship = Schema.Relationship(deleteRule: .cascade, originalName: "owner")
    precondition(relationship.deleteRule == .cascade)
    precondition(Schema.Relationship.DeleteRule(rawValue: "nullify") == .nullify)
}

func testHistoryFetchEmpty() {
    let context = try! makeContext()
    let history = try! context.fetchHistory(HistoryDescriptor<DefaultHistoryTransaction>())
    precondition(history.isEmpty)
    try! context.deleteHistory(HistoryDescriptor<DefaultHistoryTransaction>())
}

func testGetValueForKey() {
    let note = AgentNote(title: "key", count: 11)
    precondition(note.getValue(forKey: \AgentNote.count) == 11)
    precondition(note.getTransformableValue(forKey: \AgentNote.title) == "key")
}

func testModelConfigurationIdentity() {
    let configuration = ModelConfiguration("notes", isStoredInMemoryOnly: true)
    precondition(configuration.id.scheme == "file")
    precondition(configuration.name == "notes")
    precondition(configuration.cloudKitDatabase == .automatic)
    precondition(configuration.groupContainer == .automatic)
}

func testFetchDescriptorEquality() {
    let lhs = FetchDescriptor<AgentNote>()
    let rhs = FetchDescriptor<AgentNote>()
    precondition(lhs == rhs)
}

func testDataStoreErrorCases() {
    precondition(DataStoreError.invalidPredicate != DataStoreError.unsupportedFeature)
    var hasher = Hasher()
    DataStoreError.preferInMemorySort.hash(into: &hasher)
    _ = hasher.finalize()
}

func testEditingStateIdentity() {
    let state = EditingState(author: "agent")
    precondition(state.author == "agent")
    precondition(state.id != UUID())
}

func testDefaultSnapshotCopy() {
    let identifier = PersistentIdentifier(entityName: "AgentNote")
    let snapshot = DefaultSnapshot(persistentIdentifier: identifier, values: ["title": "x"])
    let copied = snapshot.copy(persistentIdentifier: PersistentIdentifier(entityName: "AgentNote"))
    precondition(copied.values["title"] == "x")
    precondition(copied.persistentIdentifier != identifier)
}

func testSchemaFromModelTypes() {
    let schema = Schema(AgentNote.self, version: Schema.Version(1, 0, 0))
    precondition(schema.entitiesByName["AgentNote"] != nil)
    precondition(schema.encodingVersion == Schema.schemaEncodingVersion)
}

func testModelContextAuthorAndDebugDescription() {
    let context = try! makeContext()
    context.author = "lane"
    precondition(context.author == "lane")
    precondition(context.debugDescription.contains("hasChanges"))
}

func testPersistentModelHasChangesAndContext() {
    let context = try! makeContext()
    let note = AgentNote(title: "ctx", count: 1)
    context.insert(note)
    precondition(note.modelContext === context)
    precondition(note.hasChanges)
    try! context.save()
    precondition(!context.hasChanges)
}
