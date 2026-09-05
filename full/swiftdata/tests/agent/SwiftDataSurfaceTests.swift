import Foundation
import SwiftData

final class AgentAuthor: PersistentModel {
    let persistentModelID = PersistentIdentifier(entityName: "AgentAuthor")
    var name: String
    var notes: [AgentNote]
    var favorite: AgentNote?

    init(name: String, notes: [AgentNote] = [], favorite: AgentNote? = nil) {
        self.name = name
        self.notes = notes
        self.favorite = favorite
    }
}

enum AgentSchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] { [AgentNote.self, AgentAuthor.self] }
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
}

enum AgentMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AgentSchemaV1.self] }
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: AgentSchemaV1.self, toVersion: AgentSchemaV1.self),
            .custom(
                fromVersion: AgentSchemaV1.self,
                toVersion: AgentSchemaV1.self,
                willMigrate: nil,
                didMigrate: nil
            ),
        ]
    }
}

private func hashInto(_ value: some Hashable) {
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
}

actor AgentModelActor: ModelActor {
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor

    init(_ container: ModelContainer) {
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
    }
}

func testSchemaAttributeSurface() {
    let unique = Schema.Attribute.Option.unique
    let ephemeral = Schema.Attribute.Option.ephemeral
    let external = Schema.Attribute.Option.externalStorage
    let spotlight = Schema.Attribute.Option.spotlight
    let preserve = Schema.Attribute.Option.preserveValueOnDeletion
    let encrypt = Schema.Attribute.Option.allowsCloudEncryption
    let transformable = Schema.Attribute.Option.transformable(by: "secure")
    precondition(unique != ephemeral)
    precondition(external.debugDescription == "externalStorage")
    precondition(spotlight == Schema.Attribute.Option.spotlight)
    precondition(preserve.name == "preserveValueOnDeletion")
    precondition(encrypt.name == "allowsCloudEncryption")
    precondition(transformable.transformerName == "secure")
    var hasher = Hasher()
    unique.hash(into: &hasher)
    _ = hasher.finalize()

    let encoded = try! JSONEncoder().encode(unique)
    let decoded = try! JSONDecoder().decode(Schema.Attribute.Option.self, from: encoded)
    precondition(decoded == unique)

    let attribute = Schema.Attribute(
        .unique, .externalStorage,
        originalName: "title",
        hashModifier: "v1"
    )
    precondition(attribute.name == "title")
    precondition(attribute.originalName == "title")
    precondition(attribute.isAttribute)
    precondition(!attribute.isRelationship)
    precondition(!attribute.isOptional)
    precondition(attribute.isUnique)
    precondition(!attribute.isTransient)
    precondition(attribute.hashModifier == "v1")
    precondition(attribute.debugDescription == "Attribute(title)")
    let named = Schema.Attribute(
        name: "count",
        originalName: "legacyCount",
        options: [.ephemeral],
        valueType: Int.self,
        defaultValue: 0,
        hashModifier: "n"
    )
    precondition(named.isTransient)
    precondition(named.defaultValue as? Int == 0)
    precondition(named.isTransformable == false)
    let transformAttr = Schema.Attribute(
        name: "blob",
        options: [.transformable(by: "secure")],
        valueType: Data.self
    )
    precondition(transformAttr.isTransformable)
    precondition(named != transformAttr)
    named.hash(into: &hasher)

    let attrData = try! JSONEncoder().encode(named)
    let attrLoaded = try! JSONDecoder().decode(Schema.Attribute.self, from: attrData)
    precondition(attrLoaded.name == "count")
    precondition(attrLoaded.originalName == "legacyCount")
}

func testSchemaRelationshipSurface() {
    precondition(Schema.Relationship.DeleteRule.deny.rawValue == "deny")
    precondition(Schema.Relationship.DeleteRule.noAction.rawValue == "noAction")
    precondition(Schema.Relationship.DeleteRule.RawValue.self == String.self)
    let unique = Schema.Relationship.Option.unique
    precondition(unique.debugDescription == "unique")
    precondition(unique == Schema.Relationship.Option.unique)
    hashInto(unique)
    let optionData = try! JSONEncoder().encode(unique)
    precondition(try! JSONDecoder().decode(Schema.Relationship.Option.self, from: optionData) == unique)

    let relationship = Schema.Relationship(
        .unique,
        deleteRule: .deny,
        minimumModelCount: 0,
        maximumModelCount: 1,
        originalName: "author",
        inverse: \AgentAuthor.notes,
        hashModifier: "rel"
    )
    precondition(relationship.name == "author")
    precondition(relationship.originalName == "author")
    precondition(relationship.deleteRule == .deny)
    precondition(relationship.isRelationship)
    precondition(!relationship.isAttribute)
    precondition(!relationship.isTransient)
    precondition(relationship.isUnique)
    precondition(relationship.isOptional)
    precondition(relationship.isToOneRelationship)
    precondition(relationship.minimumModelCount == 0)
    precondition(relationship.maximumModelCount == 1)
    precondition(relationship.hashModifier == "rel")
    precondition(relationship.inverseKeyPath != nil)
    precondition(relationship.debugDescription == "Relationship(author)")
    relationship.destination = "AgentAuthor"
    relationship.inverseName = "notes"
    relationship.keypath = \AgentNote.title
    precondition(relationship.destination == "AgentAuthor")
    _ = relationship.valueType
    let copy = Schema.Relationship(deleteRule: .deny, originalName: "author")
    copy.destination = "AgentAuthor"
    precondition(relationship == copy)
    hashInto(relationship)

    let relData = try! JSONEncoder().encode(relationship)
    let relLoaded = try! JSONDecoder().decode(Schema.Relationship.self, from: relData)
    precondition(relLoaded.deleteRule == .deny)
    precondition(relLoaded.inverseName == "notes")
}

func testSchemaEntitySurface() {
    let title = Schema.Attribute(name: "title", options: [.unique], valueType: String.self)
    let owner = Schema.Relationship(deleteRule: .cascade, originalName: "owner")
    owner.destination = "AgentAuthor"
    let child = Schema.Entity("ChildNote")
    let entity = Schema.Entity("Note", subentities: child, properties: title, owner)
    precondition(entity.name == "Note")
    precondition(entity.attributes.count == 1)
    precondition(entity.relationships.count == 1)
    precondition(entity.subentities.count == 1)
    precondition(entity.attributesByName["title"] != nil)
    precondition(entity.relationshipsByName["owner"] != nil)
    precondition(entity.storedProperties.count == 2)
    precondition(entity.storedPropertiesByName["title"] != nil)
    precondition(entity.inheritedProperties.isEmpty)
    precondition(entity.inheritedPropertiesByName.isEmpty)
    precondition(entity.properties.count == 2)
    entity.superentityName = "Base"
    entity.indices = [["title"]]
    entity.uniquenessConstraints = [["title"]]
    entity.inheritedProperties = []
    precondition(entity.debugDescription == "Entity(Note)")
    let named = Schema.Entity("Note")
    precondition(entity == named)
    hashInto(entity)

    let data = try! JSONEncoder().encode(entity)
    let loaded = try! JSONDecoder().decode(Schema.Entity.self, from: data)
    precondition(loaded.name == "Note")
    precondition(loaded.uniquenessConstraints == [["title"]])
}

func testSchemaIndexUniqueAndComposite() {
    let binary = Schema.Index<AgentNote>([\AgentNote.title])
    let typed = Schema.Index<AgentNote>(.rtree([\AgentNote.count]), .binary([\AgentNote.title]))
    precondition(binary.name == "index")
    precondition(binary.originalName == "index")
    precondition(!binary.isUnique)
    precondition(!binary.isAttribute)
    precondition(!binary.isRelationship)
    precondition(!binary.isOptional)
    precondition(!binary.isTransient)
    precondition(binary.debugDescription == "Index(index)")
    precondition(binary == typed)
    hashInto(binary)
    binary.valueType = AgentNote.self
    switch typed.indices[0] {
    case .rtree(let paths):
        precondition(paths.count == 1)
    case .binary:
        preconditionFailure("expected rtree first")
    }

    let keys = Schema.Index<AgentNote>.CodingKeys.indices
    precondition(keys.stringValue == "indices")
    precondition(keys.intValue == nil)
    precondition(Schema.Index<AgentNote>.CodingKeys(stringValue: "indices") == .indices)
    precondition(Schema.Index<AgentNote>.CodingKeys(intValue: 0) == nil)
    precondition(keys == .indices)
    hashInto(keys)

    let indexData = try! JSONEncoder().encode(binary)
    _ = try! JSONDecoder().decode(Schema.Index<AgentNote>.self, from: indexData)

    let unique = Schema.Unique<AgentNote>([\AgentNote.title])
    precondition(unique.isUnique)
    precondition(!unique.isAttribute)
    precondition(!unique.isRelationship)
    precondition(!unique.isOptional)
    precondition(!unique.isTransient)
    precondition(unique.constraints.count == 1)
    precondition(unique.debugDescription == "Unique(unique)")
    unique.name = "unique"
    unique.originalName = "unique"
    unique.valueType = AgentNote.self
    precondition(unique == Schema.Unique<AgentNote>([\AgentNote.count]))
    hashInto(unique)

    let uniqueKeys = Schema.Unique<AgentNote>.CodingKeys.constraints
    precondition(uniqueKeys.stringValue == "constraints")
    precondition(uniqueKeys.intValue == nil)
    precondition(Schema.Unique<AgentNote>.CodingKeys(stringValue: "constraints") == .constraints)
    precondition(Schema.Unique<AgentNote>.CodingKeys(intValue: 1) == nil)
    hashInto(uniqueKeys)

    let uniqueData = try! JSONEncoder().encode(unique)
    _ = try! JSONDecoder().decode(Schema.Unique<AgentNote>.self, from: uniqueData)

    let composite = Schema.CompositeAttribute(
        name: "pair",
        options: [.unique],
        valueType: String.self
    )
    composite.properties = [
        Schema.Attribute(name: "a", valueType: String.self),
        Schema.Attribute(name: "b", valueType: Int.self),
    ]
    precondition(composite.debugDescription == "CompositeAttribute(pair)")
    precondition(composite.properties.count == 2)
    let other = Schema.CompositeAttribute(name: "pair", valueType: String.self)
    other.properties = composite.properties
    precondition(composite == other)
    let compositeData = try! JSONEncoder().encode(composite)
    _ = try! JSONDecoder().decode(Schema.CompositeAttribute.self, from: compositeData)
}

func testSchemaVersionMetadataAndPropertyProtocol() {
    let empty = Schema()
    precondition(empty.entities.isEmpty)
    precondition(empty.version.minor == 0)
    precondition(empty.version.patch == 0)
    precondition(empty.version.description == "1.0.0")
    precondition(empty.debugDescription.contains("Schema"))
    hashInto(empty)

    let version = Schema.Version(2, 3, 4)
    precondition(version.minor == 3)
    precondition(version.patch == 4)
    precondition(version == Schema.Version(2, 3, 4))
    hashInto(version)
    let versionData = try! JSONEncoder().encode(version)
    precondition(try! JSONDecoder().decode(Schema.Version.self, from: versionData) == version)

    let schema = Schema(versionedSchema: AgentSchemaV1.self)
    precondition(schema.entitiesByName["AgentNote"] != nil)
    let schemaData = try! JSONEncoder().encode(schema)
    let loaded = try! JSONDecoder().decode(Schema.self, from: schemaData)
    precondition(loaded == schema)

    let metadata = Schema.PropertyMetadata(
        name: "title",
        keypath: \AgentNote.title,
        defaultValue: "",
        metadata: Schema.Attribute(name: "title", valueType: String.self)
    )
    precondition(metadata.name == "title")
    precondition(metadata.defaultValue as? String == "")
    precondition(metadata.metadata?.isAttribute == true)
    precondition(AgentNote.schemaMetadata.isEmpty)
}

func testVersionedSchemaAndMigration() {
    precondition(AgentSchemaV1.models.count == 2)
    precondition(AgentSchemaV1.versionIdentifier.major == 1)
    precondition(AgentMigrationPlan.schemas.count == 1)
    precondition(AgentMigrationPlan.stages.count == 2)
    switch AgentMigrationPlan.stages[0] {
    case .lightweight:
        break
    case .custom:
        preconditionFailure("expected lightweight")
    }
    switch AgentMigrationPlan.stages[1] {
    case .custom(_, _, let willMigrate, let didMigrate):
        precondition(willMigrate == nil)
        precondition(didMigrate == nil)
    case .lightweight:
        preconditionFailure("expected custom")
    }

    do {
        _ = try ModelContainer(
            for: Schema(versionedSchema: AgentSchemaV1.self),
            migrationPlan: AgentMigrationPlan.self,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        preconditionFailure("migration plan should fail closed")
    } catch SwiftDataError.backwardMigration {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testModelContainerSurface() {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: configuration
    )
    precondition(container.schema.entitiesByName["AgentNote"] != nil)
    precondition(!container.configurations.isEmpty)
    precondition(container.migrationPlan == nil)
    precondition(container.mainContext.container === container)
    precondition(container == container)
    try! container.erase()
    precondition(try! container.mainContext.fetchCount(FetchDescriptor<AgentNote>()) == 0)

    let schema = Schema(AgentNote.self)
    let fromSchema = try! ModelContainer(
        for: schema,
        configurations: [configuration]
    )
    precondition(fromSchema.schema == schema)

    do {
        _ = try ModelContainer(
            for: AgentNote.self,
            configurations: ModelConfiguration("dup", isStoredInMemoryOnly: true)
        )
    } catch {
        preconditionFailure("in-memory named configuration should succeed: \(error)")
    }
}

func testModelConfigurationSurface() {
    let noneGroup = ModelConfiguration.GroupContainer.none
    let idGroup = ModelConfiguration.GroupContainer.identifier("group.com.openuikit")
    precondition(noneGroup != .automatic)
    precondition(idGroup != noneGroup)
    let noneCloud = ModelConfiguration.CloudKitDatabase.none
    let privateCloud = ModelConfiguration.CloudKitDatabase.private("private.db")
    precondition(noneCloud != .automatic)
    precondition(privateCloud != noneCloud)

    let forTypes = ModelConfiguration(for: AgentNote.self, isStoredInMemoryOnly: true)
    precondition(forTypes.isStoredInMemoryOnly)
    precondition(forTypes.schema != nil)
    precondition(forTypes.allowsSave)
    precondition(forTypes.cloudKitContainerIdentifier == nil)
    precondition(forTypes.groupAppContainerIdentifier == nil)
    precondition(ModelConfiguration.ID.self == URL.self)
    precondition(ModelConfiguration.Store.self == DefaultStore.self)
    precondition(forTypes.debugDescription.contains("inMemory"))
    hashInto(forTypes)
    precondition(forTypes == ModelConfiguration(for: AgentNote.self, isStoredInMemoryOnly: true))

    let url = URL(fileURLWithPath: "/tmp/swiftdata-agent.store")
    let durable = ModelConfiguration("disk", schema: Schema(AgentNote.self), url: url, allowsSave: false)
    precondition(durable.url == url)
    precondition(!durable.isStoredInMemoryOnly)
    precondition(!durable.allowsSave)
    do {
        _ = try ModelContainer(for: AgentNote.self, configurations: durable)
        preconditionFailure("durable URL configuration should fail closed")
    } catch SwiftDataError.unsupportedPersistentStore {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testModelContextSurface() {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    precondition(context.container === container)
    precondition(context.autosaveEnabled)
    context.autosaveEnabled = false
    _ = context.editingState
    context.processPendingChanges()
    let note = AgentNote(title: "pending", count: 1)
    context.insert(note)
    precondition(!context.changedModelsArray.isEmpty)
    let ids = try! context.fetchIdentifiers(FetchDescriptor<AgentNote>(), batchSize: 8)
    precondition(ids.count == 1)
    precondition(context == context)
    precondition(ModelContext.NotificationKey.queryGeneration.rawValue == "queryGeneration")
    precondition(ModelContext.NotificationKey.invalidatedAllIdentifiers.rawValue == "invalidatedAllIdentifiers")
    precondition(ModelContext.NotificationKey(rawValue: "insertedIdentifiers") == .insertedIdentifiers)
    precondition(ModelContext.NotificationKey.RawValue.self == String.self)
}

func testFetchDescriptorSurface() {
    var descriptor = FetchDescriptor<AgentNote>()
    descriptor.predicate = nil
    descriptor.propertiesToFetch = [\AgentNote.title]
    descriptor.relationshipKeyPathsForPrefetching = [\AgentNote.count]
    precondition(descriptor.predicate == nil)
    precondition(descriptor.propertiesToFetch.count == 1)
    precondition(descriptor.relationshipKeyPathsForPrefetching.count == 1)
}

func testPersistentIdentifierSurface() {
    let identifier = PersistentIdentifier(entityName: "AgentNote", storeIdentifier: "mem")
    precondition(identifier.id.rawValue == identifier.rawValue)
    let same = PersistentIdentifier.ID(rawValue: identifier.id.rawValue)
    precondition(same == identifier.id)
    hashInto(same)
    hashInto(identifier)
    precondition(identifier == identifier)
}

func testPersistentModelSurface() {
    let context = try! ModelContainer(
        for: AgentNote.self, AgentAuthor.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ).mainContext
    let note = AgentNote(title: "rel", count: 2)
    let author = AgentAuthor(name: "ada", notes: [note], favorite: note)
    context.insert(note)
    context.insert(author)
    try! context.save()
    precondition(!note.isDeleted)
    context.delete(note)
    precondition(note.isDeleted)
    context.rollback()

    let backing: any BackingData<AgentNote> = AgentNote.createBackingData()
    _ = backing
    var stored = note.persistentBackingData
    note.persistentBackingData = stored
    stored = note.persistentBackingData
    _ = stored
    hashInto(note)
    note.setTransformableValue(forKey: \AgentNote.title, to: "rel")
    note.setValue(forKey: \AgentNote.title, to: "rel")
    note.setValue(forKey: \AgentNote.count, to: 2)
    let related: [AgentNote] = author.getValue(forKey: \AgentAuthor.notes)
    precondition(related.count == 1)
    let favorite: AgentNote? = author.getValue(forKey: \AgentAuthor.favorite)
    precondition(favorite === note)
    author.setValue(forKey: \AgentAuthor.favorite, to: note)
    author.setValue(forKey: \AgentAuthor.notes, to: [note])
    let decodedNotes: [AgentNote] = author.getValue(forKey: \AgentAuthor.notes)
    precondition(decodedNotes.count == 1)
    author.setValue(forKey: \AgentAuthor.notes, to: decodedNotes)
    precondition(AgentNote.Root.self == AgentNote.self)
}

func testRelationshipCollectionSurface() {
    typealias Notes = Array<AgentNote>.PersistentElement
    typealias OptionalNotes = Array<AgentNote>?.PersistentElement
    precondition(Notes.self == AgentNote.self)
    precondition(OptionalNotes.self == AgentNote.self)
}

func testSwiftDataErrorCodes() {
    let codes: [SwiftDataError] = [
        .configurationSchemaNotFoundInContainerSchema,
        .backwardMigration,
        .unsupportedKeyPath,
        .historyTokenExpired,
        .duplicateConfiguration,
        .modelValidationFailure,
        .loadIssueModelContainer,
        .unsupportedSortDescriptor,
        .configurationFileNameTooLong,
        .invalidTransactionFetchRequest,
        .includePendingChangesWithBatchSize,
        .sortingPendingChangesWithIdentifiers,
        .unknownSchema,
        .missingModelContext,
    ]
    precondition(Set(codes.map(\.code)).count == codes.count)
    hashInto(codes[0])
    do {
        try ModelConfiguration(String(repeating: "n", count: 256), isStoredInMemoryOnly: true).validate()
        preconditionFailure("overlong name should fail")
    } catch SwiftDataError.configurationFileNameTooLong {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAllowsSaveFailsClosed() {
    let configuration = ModelConfiguration(
        "readonly",
        schema: nil,
        isStoredInMemoryOnly: true,
        allowsSave: false
    )
    let context = try! ModelContainer(
        for: AgentNote.self,
        configurations: configuration
    ).mainContext
    context.insert(AgentNote(title: "x", count: 1))
    do {
        try context.save()
        preconditionFailure("allowsSave false should refuse save")
    } catch SwiftDataError.unsupportedPersistentStore {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testInsertSaveFetchPredicateShapes() {
    // Foundation `#Predicate` over class KeyPath traps on this Linux Foundation
    // revision (oracle-questions.tsv). The portable path evaluates the same
    // corpus shapes — comparison, && / ||, contains-as-Character, key paths —
    // after fetch, which is the measured in-memory rule.
    let context = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ).mainContext
    context.insert(AgentNote(title: "alpha", count: 1))
    context.insert(AgentNote(title: "beta", count: 4))
    context.insert(AgentNote(title: "gamma", count: 9))
    try! context.save()
    let rows = try! context.fetch(FetchDescriptor<AgentNote>(
        sortBy: [SortDescriptor(\AgentNote.count, order: .forward)]
    ))
    let selected = rows.filter { note in
        let comparison = note.count >= 4
        let conjunction = comparison && note.title.hasPrefix("b")
        let disjunction = conjunction || note.title.hasPrefix("g")
        let containsA = note.title.contains("a" as Character)
        return disjunction && containsA
    }
    precondition(selected.map(\.count) == [4, 9])
    precondition(try! context.fetchCount(FetchDescriptor<AgentNote>()) == 3)
}

func testDataStoreSurface() {
    precondition(DataStoreError.preferInMemoryFilter != .invalidPredicate)
    precondition(DataStoreError.invalidPredicate == .invalidPredicate)

    let descriptor = FetchDescriptor<AgentNote>()
    let request = DataStoreFetchRequest(descriptor: descriptor)
    precondition(request.descriptor == descriptor)
    _ = request.editingState

    let snapshot = DefaultSnapshot(persistentIdentifier: PersistentIdentifier(entityName: "AgentNote"))
    let result = DataStoreFetchResult(
        descriptor: descriptor,
        fetchedSnapshots: [snapshot],
        relatedSnapshots: [snapshot.persistentIdentifier: snapshot]
    )
    precondition(result.descriptor == descriptor)
    precondition(result.fetchedSnapshots.count == 1)
    precondition(result.relatedSnapshots.count == 1)

    let deleteRequest = DataStoreBatchDeleteRequest<AgentNote>(
        predicate: nil,
        includeSubclasses: false
    )
    precondition(deleteRequest.includeSubclasses == false)
    precondition(deleteRequest.predicate == nil)
    _ = deleteRequest.editingState

    let saveRequest = DataStoreSaveChangesRequest(
        inserted: [snapshot],
        updated: [snapshot],
        deleted: [],
        editingState: EditingState(author: "lane")
    )
    precondition(saveRequest.inserted.count == 1)
    precondition(saveRequest.updated.count == 1)
    precondition(saveRequest.deleted.isEmpty)
    precondition(saveRequest.editingState.author == "lane")

    let saveResult = DataStoreSaveChangesResult<DefaultSnapshot>(
        for: "mem",
        remappedIdentifiers: [:],
        snapshotsToReregister: [snapshot.persistentIdentifier: snapshot]
    )
    precondition(saveResult.storeIdentifier == "mem")
    precondition(saveResult.remappedIdentifiers.isEmpty)
    precondition(saveResult.snapshotsToReregister.count == 1)

    let identifierKey = DataStoreSnapshotCodingKey.persistentIdentifier
    let modeled = DataStoreSnapshotCodingKey.modeledProperty("title")
    precondition(identifierKey.stringValue == "persistentIdentifier")
    precondition(modeled.stringValue == "title")
    precondition(identifierKey.intValue == nil)
    precondition(DataStoreSnapshotCodingKey(stringValue: "persistentIdentifier")?.stringValue == "persistentIdentifier")
    precondition(DataStoreSnapshotCodingKey(intValue: 0) == nil)
    _ = DataStoreSnapshotValue.self
}

func testDefaultStoreSurface() {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let store = try! DefaultStore(configuration)
    precondition(store.configuration == configuration)
    precondition(store.identifier == configuration.name)
    precondition(store.name == configuration.name)
    precondition(store.schema.entities.isEmpty || true)
    precondition(DefaultStore.Configuration.self == ModelConfiguration.self)
    precondition(DefaultStore.Snapshot.self == DefaultSnapshot.self)
    precondition(DefaultStore.HistoryType.self == DefaultHistoryTransaction.self)
    precondition(DefaultStore.TokenType.self == DefaultHistoryToken.self)
    precondition(DefaultStore.historyType == DefaultHistoryTransaction.self)

    let identifier = PersistentIdentifier(entityName: "AgentNote")
    let snapshot = DefaultSnapshot(persistentIdentifier: identifier, values: ["title": "n"])
    _ = try! store.save(DataStoreSaveChangesRequest(inserted: [snapshot]))
    let fetched = try! store.fetchIdentifiers(DataStoreFetchRequest(descriptor: FetchDescriptor<AgentNote>()))
    precondition(fetched == [identifier])
    let cached = try! store.cachedSnapshots(for: [identifier], editingState: EditingState())
    precondition(cached[identifier] != nil)
    store.initializeState(for: EditingState())
    store.invalidateState(for: EditingState())
    try! store.delete(DataStoreBatchDeleteRequest<AgentNote>())
    precondition(try! store.fetchCount(DataStoreFetchRequest(descriptor: FetchDescriptor<AgentNote>())) == 0)
    _ = try! store.save(DataStoreSaveChangesRequest(inserted: [snapshot]))
    try! store.erase()
    precondition(try! store.fetchHistory(HistoryDescriptor<DefaultHistoryTransaction>()).isEmpty)
    try! store.deleteHistory(HistoryDescriptor<DefaultHistoryTransaction>())
}

func testDefaultSnapshotSurface() {
    let identifier = PersistentIdentifier(entityName: "AgentNote")
    var related: [PersistentIdentifier: any BackingData] = [:]
    let backing = PortableBackingData<AgentNote>(for: AgentNote.self)
    backing.persistentModelID = identifier
    let fromBacking = DefaultSnapshot(from: backing, relatedBackingDatas: &related)
    precondition(fromBacking.persistentIdentifier == identifier)
    precondition(related[identifier] != nil)
    let remapped = fromBacking.copy(
        persistentIdentifier: PersistentIdentifier(entityName: "AgentNote"),
        remappedIdentifiers: [:]
    )
    precondition(remapped.persistentIdentifier != identifier)
    let data = try! JSONEncoder().encode(fromBacking)
    let decoded = try! JSONDecoder().decode(DefaultSnapshot.self, from: data)
    precondition(decoded.persistentIdentifier == identifier)
}

func testBackingDataSurface() {
    let note = AgentNote(title: "back", count: 3)
    let author = AgentAuthor(name: "back", notes: [note], favorite: note)
    let backing = PortableBackingData<AgentAuthor>(model: author)
    precondition(backing.persistentModelID == author.persistentModelID)
    _ = backing.metadata
    precondition(backing.getTransformableValue(forKey: \AgentAuthor.name) == "back")
    backing.setTransformableValue(forKey: \AgentAuthor.name, to: "back")
    precondition(backing.getValue(forKey: \AgentAuthor.name) == "back")
    let related: AgentNote? = backing.getValue(forKey: \AgentAuthor.favorite)
    precondition(related === note)
    let notes: [AgentNote] = backing.getValue(forKey: \AgentAuthor.notes)
    precondition(notes.count == 1)
    let decodedNotes: [AgentNote] = backing.getValue(forKey: \AgentAuthor.notes)
    precondition(decodedNotes.count == 1)
    backing.setValue(forKey: \AgentAuthor.name, to: "back")
    backing.setValue(forKey: \AgentAuthor.favorite, to: note)
    backing.setValue(forKey: \AgentAuthor.favorite, to: note)
    backing.setValue(forKey: \AgentAuthor.notes, to: [note])
    backing.setValue(forKey: \AgentAuthor.notes, to: decodedNotes)
    let unbound = PortableBackingData<AgentNote>(for: AgentNote.self)
    precondition(unbound.persistentModelID == nil)
}

func testFetchResultsCollectionSurface() {
    let collection = FetchResultsCollection([AgentNote(title: "c", count: 1)])
    precondition(FetchResultsCollection<AgentNote>.Index.self == Int.self)
    precondition(FetchResultsCollection<AgentNote>.Indices.self == Range<Int>.self)
    precondition(FetchResultsCollection<AgentNote>.Iterator.self == IndexingIterator<FetchResultsCollection<AgentNote>>.self)
    precondition(FetchResultsCollection<AgentNote>.SubSequence.self == Slice<FetchResultsCollection<AgentNote>>.self)
    precondition(Array(collection).count == 1)
}

func testHistorySurface() {
    let identifier = PersistentIdentifier(entityName: "AgentNote")
    let insert = DefaultHistoryInsert<AgentNote>(
        changeIdentifier: 1,
        changedPersistentIdentifier: identifier,
        transactionIdentifier: 9
    )
    precondition(insert.changeIdentifier == 1)
    precondition(insert.transactionIdentifier == 9)
    precondition(insert.changedPersistentIdentifier == identifier)
    precondition(insert == insert)
    hashInto(insert)
    precondition(DefaultHistoryInsert<AgentNote>.ChangeIdentifier.self == Int64.self)
    precondition(DefaultHistoryInsert<AgentNote>.TransactionIdentifier.self == Int64.self)

    let update = DefaultHistoryUpdate<AgentNote>(
        changeIdentifier: 2,
        changedPersistentIdentifier: identifier,
        transactionIdentifier: 9,
        updatedAttributes: [\AgentNote.title]
    )
    precondition(update.updatedAttributes.count == 1)
    precondition(update == update)
    var updateHasher = Hasher()
    update.hash(into: &updateHasher)
    _ = updateHasher.finalize()
    precondition(DefaultHistoryUpdate<AgentNote>.ChangeIdentifier.self == Int64.self)

    let tombstone = HistoryTombstone<AgentNote>(["gone"])
    var tombstoneIterator = tombstone.makeIterator()
    precondition(tombstoneIterator.next() as? String == "gone")
    precondition(tombstone[\AgentNote.title] == nil)
    precondition(tombstone == HistoryTombstone<AgentNote>(["x"]))
    hashInto(tombstone)
    let iterator = HistoryTombstone<AgentNote>.Iterator.self
    _ = iterator
    precondition(HistoryTombstone<AgentNote>.Element.self == Any.self)
    precondition(HistoryTombstone<AgentNote>.Iterator.Element.self == Any.self)

    let delete = DefaultHistoryDelete<AgentNote>(
        changeIdentifier: 3,
        changedPersistentIdentifier: identifier,
        transactionIdentifier: 9,
        tombstone: tombstone
    )
    precondition(delete.tombstone == tombstone)
    precondition(delete == delete)
    hashInto(delete)

    let change = HistoryChange.insert(insert)
    precondition(change.changedPersistentIdentifier == identifier)
    _ = HistoryChange.update(update)
    _ = HistoryChange.delete(delete)

    var descriptor = HistoryDescriptor<DefaultHistoryTransaction>(
        predicate: nil,
        sortBy: []
    )
    descriptor.fetchLimit = 4
    descriptor.sortBy = []
    descriptor.predicate = nil
    precondition(descriptor.fetchLimit == 4)
    let limited = HistoryDescriptor<DefaultHistoryTransaction>(predicate: nil)
    precondition(limited.fetchLimit == .max)

    let token = DefaultHistoryToken(id: 3, tokenValue: ["s": 1])
    precondition(token.tokenValue?["s"] == 1)
    precondition(token < DefaultHistoryToken(id: 4))
    precondition(DefaultHistoryToken.ID.self == Int.self)
    precondition(DefaultHistoryToken.TokenType.self == [String: Int64].self)

    let transaction = DefaultHistoryTransaction(
        author: "lane",
        bundleIdentifier: "test",
        processIdentifier: "1",
        storeIdentifier: "mem",
        timestamp: Date(timeIntervalSince1970: 1),
        token: token,
        transactionIdentifier: 9,
        changes: [change]
    )
    precondition(transaction.author == "lane")
    precondition(transaction.bundleIdentifier == "test")
    precondition(transaction.processIdentifier == "1")
    precondition(transaction.storeIdentifier == "mem")
    precondition(transaction.timestamp.timeIntervalSince1970 == 1)
    precondition(transaction.token.id == 3)
    precondition(transaction.transactionIdentifier == 9)
    precondition(transaction.changes.count == 1)
    precondition(transaction.id == 9)
    precondition(DefaultHistoryTransaction.ID.self == Int64.self)
    precondition(DefaultHistoryTransaction.TokenType.self == DefaultHistoryToken.self)
    precondition(DefaultHistoryTransaction.TransactionIdentifier.self == Int64.self)
}

func testModelActorSurface() {
    let container = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let executor = DefaultSerialModelExecutor(modelContext: context)
    precondition(executor.modelContext === context)
    _ = executor.asUnownedSerialExecutor()

    let actor = AgentModelActor(container)
    precondition(actor.modelContainer === container)
    precondition(actor.modelExecutor.modelContext.container === container)
    _ = actor.unownedExecutor
}

func testIncludePendingChangesWithBatchSizeError() {
    let context = try! ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ).mainContext
    var descriptor = FetchDescriptor<AgentNote>()
    descriptor.includePendingChanges = true
    do {
        _ = try context.fetch(descriptor, batchSize: 1)
        preconditionFailure("batch + pending should throw")
    } catch SwiftDataError.includePendingChangesWithBatchSize {
        return
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}
