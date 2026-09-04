//===----------------------------------------------------------------------===//
// Portable SwiftData
//
// This is an in-memory, object-identity persistence runtime. It implements
// real insert/delete/predicate/sort/limit behavior without claiming that
// CoreData, CloudKit, schema migration, or durable storage exists on Linux.
// Durable configurations fail during ModelContainer construction.
//===----------------------------------------------------------------------===//

@_exported import Foundation
import Observation

// MARK: - Model identity and macro

public struct PersistentIdentifier: Comparable, Hashable, Sendable, Codable, CustomStringConvertible {
    public struct ID: Hashable, Sendable {
        public let rawValue: UInt64
        public init(rawValue: UInt64) { self.rawValue = rawValue }
    }

    public let rawValue: UInt64
    public let id: PersistentIdentifier.ID
    public let entityName: String
    public let storeIdentifier: String?
    fileprivate let primaryKeyDescription: String?

    public init() {
        self.init(entityName: "", storeIdentifier: nil)
    }

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
        self.id = ID(rawValue: rawValue)
        self.entityName = ""
        self.storeIdentifier = nil
        self.primaryKeyDescription = nil
    }

    public init(entityName: String, storeIdentifier: String? = nil) {
        let raw = _PersistentIdentifierSource.next()
        self.rawValue = raw
        self.id = ID(rawValue: raw)
        self.entityName = entityName
        self.storeIdentifier = storeIdentifier
        self.primaryKeyDescription = nil
    }

    public var description: String { "SwiftData.PersistentIdentifier(\(rawValue))" }

    public static func < (lhs: PersistentIdentifier, rhs: PersistentIdentifier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func identifier<T>(
        for storeIdentifier: String,
        entityName: String,
        primaryKey: T
    ) throws -> PersistentIdentifier
    where T: Comparable, T: CustomStringConvertible, T: Decodable, T: Encodable, T: Hashable {
        var identifier = PersistentIdentifier(entityName: entityName, storeIdentifier: storeIdentifier)
        identifier = PersistentIdentifier(
            cloned: identifier,
            primaryKeyDescription: String(describing: primaryKey)
        )
        return identifier
    }

    private init(cloned base: PersistentIdentifier, primaryKeyDescription: String) {
        self.rawValue = base.rawValue
        self.id = base.id
        self.entityName = base.entityName
        self.storeIdentifier = base.storeIdentifier
        self.primaryKeyDescription = primaryKeyDescription
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(UInt64.self, forKey: .rawValue)
        self.rawValue = rawValue
        self.id = ID(rawValue: rawValue)
        self.entityName = try container.decode(String.self, forKey: .entityName)
        self.storeIdentifier = try container.decodeIfPresent(String.self, forKey: .storeIdentifier)
        self.primaryKeyDescription = try container.decodeIfPresent(String.self, forKey: .primaryKeyDescription)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .rawValue)
        try container.encode(entityName, forKey: .entityName)
        try container.encodeIfPresent(storeIdentifier, forKey: .storeIdentifier)
        try container.encodeIfPresent(primaryKeyDescription, forKey: .primaryKeyDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case rawValue, entityName, storeIdentifier, primaryKeyDescription
    }
}

private enum _PersistentIdentifierSource {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var value: UInt64 = 0

    static func next() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        value &+= 1
        precondition(value != 0, "SwiftData persistent identifier space exhausted")
        return value
    }
}

public protocol PersistentModel: AnyObject, Identifiable, Hashable, Observable, SendableMetatype
where ID == PersistentIdentifier {
    var persistentModelID: PersistentIdentifier { get }
}

public extension PersistentModel {
    typealias Root = Self

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }

    var id: PersistentIdentifier { persistentModelID }

    var hasChanges: Bool { modelContext?.hasChanges ?? false }

    var isDeleted: Bool {
        guard let context = modelContext else { return false }
        return context.deletedModelsArray.contains { $0.persistentModelID == persistentModelID }
    }

    var modelContext: ModelContext? { _ModelContextRegistry.context(for: persistentModelID) }

    static var schemaMetadata: [Schema.PropertyMetadata] { [] }

    static func createBackingData<P>() -> some BackingData<P> where P: PersistentModel {
        PortableBackingData<P>(for: P.self)
    }

    var persistentBackingData: any BackingData<Self> {
        get { PortableBackingData<Self>(model: self) }
        set { _ = newValue }
    }

    init(backingData: any BackingData<Self>) {
        fatalError("PersistentModel.init(backingData:) requires a @Model type on this platform")
    }

    func getTransformableValue<Value>(forKey keyPath: KeyPath<Self, Value>) -> Value {
        self[keyPath: keyPath]
    }

    func setTransformableValue<Value>(forKey keyPath: KeyPath<Self, Value>, to newValue: Value) {
        _ = keyPath
        _ = newValue
    }

    func getValue<Value>(forKey keyPath: KeyPath<Self, Value>) -> Value where Value: Decodable {
        self[keyPath: keyPath]
    }

    func getValue<Value>(forKey keyPath: KeyPath<Self, Value>) -> Value where Value: PersistentModel {
        self[keyPath: keyPath]
    }

    func getValue<Value>(forKey keyPath: KeyPath<Self, Value?>) -> Value? where Value: PersistentModel {
        self[keyPath: keyPath]
    }

    func getValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Self, Value>
    ) -> Value where Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        self[keyPath: keyPath]
    }

    func getValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Self, Value>
    ) -> Value
    where Value: Decodable, Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        self[keyPath: keyPath]
    }

    func setValue<Value>(forKey keyPath: KeyPath<Self, Value>, to newValue: Value) where Value: Encodable {
        _ = keyPath
        _ = newValue
    }

    func setValue<Value>(forKey keyPath: KeyPath<Self, Value>, to newValue: Value) where Value: PersistentModel {
        _ = keyPath
        _ = newValue
    }

    func setValue<Value>(forKey keyPath: KeyPath<Self, Value?>, to newValue: Value?) where Value: PersistentModel {
        _ = keyPath
        _ = newValue
    }

    func setValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Self, Value>,
        to newValue: Value
    ) where Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        _ = keyPath
        _ = newValue
    }

    func setValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Self, Value>,
        to newValue: Value
    ) where Value: Encodable, Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        _ = keyPath
        _ = newValue
    }
}

#if hasFeature(Macros) && !os(Linux)
@attached(
    member,
    names: named(_swiftDataPersistentIdentifier),
    named(persistentModelID),
    named(id)
)
@attached(extension, conformances: PersistentModel)
public macro Model() =
    #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")
#endif

public protocol RelationshipCollection {
    associatedtype PersistentElement: PersistentModel
}

extension Array: RelationshipCollection where Element: PersistentModel {
    public typealias PersistentElement = Element
}

extension Optional: RelationshipCollection where Wrapped: Sequence, Wrapped.Element: PersistentModel {
    public typealias PersistentElement = Wrapped.Element
}

// MARK: - Configuration and failure boundary

public struct SwiftDataError: Error, Equatable, Hashable, CustomStringConvertible {
    public let code: Int
    public let message: String

    public var description: String { message }

    public static let unsupportedPersistentStore = SwiftDataError(
        code: -1,
        message: "durable SwiftData stores are unavailable on this platform"
    )
    public static let unknownSchema = SwiftDataError(code: 1, message: "unknown schema")
    public static let loadIssueModelContainer = SwiftDataError(code: 2, message: "model container failed to load")
    public static let missingModelContext = SwiftDataError(code: 3, message: "missing model context")
    public static let unsupportedPredicate = SwiftDataError(code: 4, message: "unsupported predicate")
    public static let unsupportedSortDescriptor = SwiftDataError(code: 5, message: "unsupported sort descriptor")
    public static let unsupportedKeyPath = SwiftDataError(code: 6, message: "unsupported key path")
    public static let invalidTransactionFetchRequest = SwiftDataError(
        code: 7,
        message: "invalid transaction fetch request"
    )
    public static let includePendingChangesWithBatchSize = SwiftDataError(
        code: 8,
        message: "includePendingChanges cannot be combined with a batch size"
    )
    public static let sortingPendingChangesWithIdentifiers = SwiftDataError(
        code: 9,
        message: "pending identifier fetches cannot be sorted"
    )
    public static let historyTokenExpired = SwiftDataError(code: 10, message: "history token expired")
    public static let duplicateConfiguration = SwiftDataError(code: 11, message: "duplicate configuration")
    public static let configurationSchemaNotFoundInContainerSchema = SwiftDataError(
        code: 12,
        message: "configuration schema is not in the container schema"
    )
    public static let configurationFileNameTooLong = SwiftDataError(
        code: 13,
        message: "configuration file name is too long"
    )
    public static let configurationFileNameContainsInvalidCharacters = SwiftDataError(
        code: 14,
        message: "configuration file name contains invalid characters"
    )
    public static let modelValidationFailure = SwiftDataError(code: 15, message: "model validation failed")
    public static let backwardMigration = SwiftDataError(code: 16, message: "backward migration is not supported")

    public static func modelTypeNotInSchema(_ name: String) -> SwiftDataError {
        SwiftDataError(code: 17, message: "model type is not present in this container schema: \(name)")
    }

    public static func predicateEvaluation(_ reason: String) -> SwiftDataError {
        SwiftDataError(code: 18, message: "SwiftData predicate evaluation failed: \(reason)")
    }

    public static func ~= (lhs: SwiftDataError, rhs: any Error) -> Bool {
        (rhs as? SwiftDataError) == lhs
    }
}

public struct ModelConfiguration: Hashable, Identifiable, Sendable, DataStoreConfiguration {
    public typealias ID = URL
    public typealias Store = DefaultStore

    public struct GroupContainer: Hashable, Sendable {
        private let token: String
        private init(_ token: String) { self.token = token }
        public static var automatic: GroupContainer { GroupContainer("automatic") }
        public static var none: GroupContainer { GroupContainer("none") }
        public static func identifier(_ groupName: String) -> GroupContainer {
            GroupContainer("id:\(groupName)")
        }
    }

    public struct CloudKitDatabase: Hashable, Sendable {
        private let token: String
        private init(_ token: String) { self.token = token }
        public static var automatic: CloudKitDatabase { CloudKitDatabase("automatic") }
        public static var none: CloudKitDatabase { CloudKitDatabase("none") }
        public static func `private`(_ privateDBName: String) -> CloudKitDatabase {
            CloudKitDatabase("private:\(privateDBName)")
        }
    }

    public let name: String
    public let url: URL
    public var id: URL { url }
    public let isStoredInMemoryOnly: Bool
    public let allowsSave: Bool
    public let groupContainer: GroupContainer
    public let cloudKitDatabase: CloudKitDatabase
    public let cloudKitContainerIdentifier: String?
    public let groupAppContainerIdentifier: String?
    public var schema: Schema?
    public var debugDescription: String {
        "ModelConfiguration(name: \(name), inMemory: \(isStoredInMemoryOnly))"
    }

    let modelTypeNames: [String]

    public init(isStoredInMemoryOnly: Bool = false) {
        self.init(
            nil,
            schema: nil,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .automatic
        )
    }

    public init(
        _ name: String? = nil,
        schema: Schema? = nil,
        isStoredInMemoryOnly: Bool = false,
        allowsSave: Bool = true,
        groupContainer: GroupContainer = .automatic,
        cloudKitDatabase: CloudKitDatabase = .automatic
    ) {
        let resolvedName = name ?? "Default"
        self.name = resolvedName
        self.url = Self.memoryURL(name: resolvedName)
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.allowsSave = allowsSave
        self.groupContainer = groupContainer
        self.cloudKitDatabase = cloudKitDatabase
        self.cloudKitContainerIdentifier = nil
        self.groupAppContainerIdentifier = nil
        self.schema = schema
        self.modelTypeNames = []
    }

    public init(
        _ name: String? = nil,
        schema: Schema? = nil,
        url: URL,
        allowsSave: Bool = true,
        cloudKitDatabase: CloudKitDatabase = .automatic
    ) {
        let resolvedName = name ?? "Default"
        self.name = resolvedName
        self.url = url
        self.isStoredInMemoryOnly = false
        self.allowsSave = allowsSave
        self.groupContainer = .automatic
        self.cloudKitDatabase = cloudKitDatabase
        self.cloudKitContainerIdentifier = nil
        self.groupAppContainerIdentifier = nil
        self.schema = schema
        self.modelTypeNames = []
    }

    public init(
        for modelTypes: any PersistentModel.Type...,
        isStoredInMemoryOnly: Bool = false
    ) {
        let resolvedName = "Default"
        self.name = resolvedName
        self.url = Self.memoryURL(name: resolvedName)
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.allowsSave = true
        self.groupContainer = .automatic
        self.cloudKitDatabase = .automatic
        self.cloudKitContainerIdentifier = nil
        self.groupAppContainerIdentifier = nil
        self.schema = Schema(Array(modelTypes))
        self.modelTypeNames = modelTypes.map { String(reflecting: $0) }
    }

    public func validate() throws {
        if name.utf8.count > 255 {
            throw SwiftDataError.configurationFileNameTooLong
        }
        if name.contains("/") || name.contains("\0") {
            throw SwiftDataError.configurationFileNameContainsInvalidCharacters
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(url)
        hasher.combine(isStoredInMemoryOnly)
        hasher.combine(allowsSave)
        hasher.combine(groupContainer)
        hasher.combine(cloudKitDatabase)
    }

    public static func == (lhs: ModelConfiguration, rhs: ModelConfiguration) -> Bool {
        lhs.name == rhs.name
            && lhs.url == rhs.url
            && lhs.isStoredInMemoryOnly == rhs.isStoredInMemoryOnly
            && lhs.allowsSave == rhs.allowsSave
            && lhs.groupContainer == rhs.groupContainer
            && lhs.cloudKitDatabase == rhs.cloudKitDatabase
    }

    private static func memoryURL(name: String) -> URL {
        URL(fileURLWithPath: "/swift-data/memory/\(name)")
    }
}

final class _ModelStorage: @unchecked Sendable {
    let lock = NSLock()
    var objects: [ObjectIdentifier: any PersistentModel] = [:]
    var insertionOrder: [ObjectIdentifier] = []
}

public final class ModelContainer: @unchecked Sendable {
    let storage = _ModelStorage()
    let modelTypes: Set<ObjectIdentifier>
    public var configurations: Set<ModelConfiguration>
    public let schema: Schema
    public let migrationPlan: (any SchemaMigrationPlan.Type)?
    public lazy var mainContext = ModelContext(self)

    public init(
        modelTypes: [any PersistentModel.Type],
        configurations: [ModelConfiguration]
    ) throws {
        let effective = configurations.isEmpty
            ? [ModelConfiguration(isStoredInMemoryOnly: false)]
            : configurations
        guard effective.allSatisfy(\.isStoredInMemoryOnly) else {
            throw SwiftDataError.unsupportedPersistentStore
        }
        self.modelTypes = Set(modelTypes.map(ObjectIdentifier.init))
        self.configurations = Set(effective)
        self.schema = effective.compactMap(\.schema).first ?? Schema(modelTypes)
        self.migrationPlan = nil
    }

    public convenience init(
        for modelTypes: any PersistentModel.Type...,
        configurations: ModelConfiguration...
    ) throws {
        try self.init(modelTypes: modelTypes, configurations: configurations)
    }

    public convenience init(
        for forTypes: any PersistentModel.Type...,
        configurations: any DataStoreConfiguration...
    ) throws {
        let modelConfigurations = configurations.compactMap { $0 as? ModelConfiguration }
        try self.init(modelTypes: forTypes, configurations: modelConfigurations)
    }

    public convenience init(
        for forTypes: any PersistentModel.Type...,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        configurations: ModelConfiguration...
    ) throws {
        _ = migrationPlan
        try self.init(modelTypes: forTypes, configurations: configurations)
    }

    public convenience init(
        for givenSchema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        configurations: ModelConfiguration...
    ) throws {
        try self.init(for: givenSchema, migrationPlan: migrationPlan, configurations: Array(configurations))
    }

    public init(
        for givenSchema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        configurations: [ModelConfiguration]
    ) throws {
        let effective = configurations.isEmpty
            ? [ModelConfiguration(isStoredInMemoryOnly: false)]
            : configurations
        guard effective.allSatisfy(\.isStoredInMemoryOnly) else {
            throw SwiftDataError.unsupportedPersistentStore
        }
        if migrationPlan != nil {
            throw SwiftDataError.backwardMigration
        }
        self.modelTypes = []
        self.configurations = Set(effective)
        self.schema = givenSchema
        self.migrationPlan = migrationPlan
    }

    public init(
        for givenSchema: Schema,
        configurations: [any DataStoreConfiguration]
    ) throws {
        let modelConfigurations = configurations.compactMap { $0 as? ModelConfiguration }
        let effective = modelConfigurations.isEmpty
            ? [ModelConfiguration(isStoredInMemoryOnly: false)]
            : modelConfigurations
        guard effective.allSatisfy(\.isStoredInMemoryOnly) else {
            throw SwiftDataError.unsupportedPersistentStore
        }
        self.modelTypes = []
        self.configurations = Set(effective)
        self.schema = givenSchema
        self.migrationPlan = nil
    }

    public static func == (lhs: ModelContainer, rhs: ModelContainer) -> Bool {
        lhs === rhs
    }

    public func deleteAllData() {
        storage.lock.lock()
        storage.objects.removeAll()
        storage.insertionOrder.removeAll()
        storage.lock.unlock()
    }

    public func erase() throws {
        deleteAllData()
    }
}

// MARK: - Fetching and mutation

public struct FetchDescriptor<T: PersistentModel> {
    public var predicate: Predicate<T>?
    public var sortBy: [SortDescriptor<T>]
    public var fetchLimit: Int?
    public var fetchOffset: Int?
    public var includePendingChanges: Bool
    public var propertiesToFetch: [PartialKeyPath<T>]
    public var relationshipKeyPathsForPrefetching: [PartialKeyPath<T>]

    public init(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) {
        self.predicate = predicate
        self.sortBy = sortBy
        self.fetchLimit = nil
        self.fetchOffset = nil
        self.includePendingChanges = true
        self.propertiesToFetch = []
        self.relationshipKeyPathsForPrefetching = []
    }

    public static func == (lhs: FetchDescriptor<T>, rhs: FetchDescriptor<T>) -> Bool {
        lhs.fetchLimit == rhs.fetchLimit
            && lhs.fetchOffset == rhs.fetchOffset
            && lhs.includePendingChanges == rhs.includePendingChanges
            && lhs.sortBy.count == rhs.sortBy.count
            && (lhs.predicate == nil) == (rhs.predicate == nil)
    }
}

public struct FetchResultsCollection<Element>: RandomAccessCollection {
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<FetchResultsCollection<Element>>
    public typealias SubSequence = Slice<FetchResultsCollection<Element>>

    private let items: [Element]

    public init(_ items: [Element]) {
        self.items = items
    }

    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }
    public subscript(position: Int) -> Element { items[position] }
}

public final class ModelContext: Equatable, CustomDebugStringConvertible, @unchecked Sendable {
    public enum NotificationKey: String {
        case insertedIdentifiers
        case deletedIdentifiers
        case updatedIdentifiers
        case invalidatedAllIdentifiers
        case queryGeneration
    }

    public static let didSave = Notification.Name("SwiftData.ModelContext.didSave")
    public static let willSave = Notification.Name("SwiftData.ModelContext.willSave")

    public let container: ModelContainer
    public var autosaveEnabled = true
    public var author: String?
    public var editingState = EditingState()
    public var debugDescription: String {
        "ModelContext(hasChanges: \(hasChanges))"
    }

    private let stateLock = NSLock()
    private var inserted: Set<PersistentIdentifier> = []
    private var deleted: [PersistentIdentifier: any PersistentModel] = [:]

    public init(_ container: ModelContainer) {
        self.container = container
    }

    public static func == (lhs: ModelContext, rhs: ModelContext) -> Bool {
        lhs === rhs
    }

    public var hasChanges: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return !inserted.isEmpty || !deleted.isEmpty
    }

    public var insertedModelsArray: [any PersistentModel] {
        let identifiers = _pendingIdentifiers(inserted: true)
        return _allModels().filter { identifiers.contains($0.persistentModelID) }
    }

    public var deletedModelsArray: [any PersistentModel] {
        stateLock.lock()
        defer { stateLock.unlock() }
        return deleted.values.sorted {
            $0.persistentModelID.rawValue < $1.persistentModelID.rawValue
        }
    }
    public var changedModelsArray: [any PersistentModel] { insertedModelsArray }

    public func insert<T>(_ model: T) where T: PersistentModel {
        if !container.modelTypes.isEmpty,
           !container.modelTypes.contains(ObjectIdentifier(T.self)) {
            preconditionFailure(
                SwiftDataError.modelTypeNotInSchema(String(reflecting: T.self)).description
            )
        }
        let key = ObjectIdentifier(model)
        container.storage.lock.lock()
        let wasNew = container.storage.objects.updateValue(model, forKey: key) == nil
        if wasNew { container.storage.insertionOrder.append(key) }
        container.storage.lock.unlock()
        _ModelContextRegistry.register(self, for: model.persistentModelID)
        guard wasNew else { return }
        stateLock.lock()
        if deleted.removeValue(forKey: model.persistentModelID) == nil {
            inserted.insert(model.persistentModelID)
        }
        stateLock.unlock()
    }

    public func delete<T>(_ model: T) where T: PersistentModel {
        let key = ObjectIdentifier(model)
        container.storage.lock.lock()
        let removed = container.storage.objects.removeValue(forKey: key)
        if removed != nil {
            container.storage.insertionOrder.removeAll { $0 == key }
        }
        container.storage.lock.unlock()
        guard removed != nil else { return }
        stateLock.lock()
        if inserted.remove(model.persistentModelID) == nil {
            deleted[model.persistentModelID] = model
        }
        stateLock.unlock()
    }

    public func delete<T>(
        model: T.Type,
        where predicate: Predicate<T>? = nil,
        includeSubclasses: Bool = true
    ) throws where T: PersistentModel {
        _ = includeSubclasses
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.includePendingChanges = true
        for item in try fetch(descriptor) {
            delete(item)
        }
    }

    public func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T]
    where T: PersistentModel {
        var result = _allModels().compactMap { $0 as? T }
        if let predicate = descriptor.predicate {
            do {
                result = try result.filter { try predicate.evaluate($0) }
            } catch {
                throw SwiftDataError.predicateEvaluation(String(describing: error))
            }
        }
        if !descriptor.sortBy.isEmpty {
            result.sort { lhs, rhs in
                for descriptor in descriptor.sortBy {
                    switch descriptor.compare(lhs, rhs) {
                    case .orderedAscending: return true
                    case .orderedDescending: return false
                    case .orderedSame: continue
                    }
                }
                return false
            }
        }
        let offset = max(0, descriptor.fetchOffset ?? 0)
        guard offset < result.count else { return [] }
        result = Array(result.dropFirst(offset))
        if let limit = descriptor.fetchLimit {
            result = Array(result.prefix(max(0, limit)))
        }
        return result
    }

    public func fetch<T>(
        _ descriptor: FetchDescriptor<T>,
        batchSize: Int
    ) throws -> FetchResultsCollection<T> where T: PersistentModel {
        if descriptor.includePendingChanges && batchSize > 0 {
            throw SwiftDataError.includePendingChangesWithBatchSize
        }
        _ = batchSize
        return FetchResultsCollection(try fetch(descriptor))
    }

    public func fetchCount<T>(_ descriptor: FetchDescriptor<T>) throws -> Int
    where T: PersistentModel {
        try fetch(descriptor).count
    }

    public func fetchIdentifiers<T>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> [PersistentIdentifier] where T: PersistentModel {
        try fetch(descriptor).map(\.persistentModelID)
    }

    public func fetchIdentifiers<T>(
        _ descriptor: FetchDescriptor<T>,
        batchSize: Int
    ) throws -> FetchResultsCollection<PersistentIdentifier> where T: PersistentModel {
        FetchResultsCollection(try fetchIdentifiers(descriptor))
    }

    public func enumerate<T>(
        _ fetch: FetchDescriptor<T>,
        batchSize: Int = 5000,
        allowEscapingMutations: Bool = false,
        block: (T) throws -> Void
    ) throws where T: PersistentModel {
        _ = batchSize
        _ = allowEscapingMutations
        for model in try self.fetch(fetch) {
            try block(model)
        }
    }

    public func fetchHistory<T>(
        _ descriptor: HistoryDescriptor<T>
    ) throws -> [T] where T: HistoryTransaction {
        _ = descriptor
        return []
    }

    public func deleteHistory<T>(
        _ descriptor: HistoryDescriptor<T>
    ) throws where T: HistoryTransaction {
        _ = descriptor
    }

    public func save() throws {
        guard container.configurations.allSatisfy(\.allowsSave) else {
            throw SwiftDataError.unsupportedPersistentStore
        }
        NotificationCenter.default.post(name: ModelContext.willSave, object: self)
        stateLock.lock()
        inserted.removeAll(keepingCapacity: true)
        deleted.removeAll(keepingCapacity: true)
        stateLock.unlock()
        NotificationCenter.default.post(name: ModelContext.didSave, object: self)
    }

    public func rollback() {
        stateLock.lock()
        let insertedIdentifiers = inserted
        let deletedModels = Array(deleted.values)
        inserted.removeAll(keepingCapacity: true)
        deleted.removeAll(keepingCapacity: true)
        stateLock.unlock()

        container.storage.lock.lock()
        container.storage.objects = container.storage.objects.filter {
            !insertedIdentifiers.contains($0.value.persistentModelID)
        }
        container.storage.insertionOrder.removeAll {
            guard let model = container.storage.objects[$0] else { return true }
            return insertedIdentifiers.contains(model.persistentModelID)
        }
        for model in deletedModels {
            let key = ObjectIdentifier(model)
            if container.storage.objects.updateValue(model, forKey: key) == nil {
                container.storage.insertionOrder.append(key)
            }
        }
        container.storage.lock.unlock()
    }

    public func processPendingChanges() {}

    public func transaction(block: () throws -> Void) throws {
        try block()
        try save()
    }

    public func model(for persistentModelID: PersistentIdentifier) -> any PersistentModel {
        guard let model = _allModels().first(where: {
            $0.persistentModelID == persistentModelID
        }) else {
            preconditionFailure("SwiftData model identifier is not registered")
        }
        return model
    }

    public func registeredModel<T>(for persistentModelID: PersistentIdentifier) -> T?
    where T: PersistentModel {
        _allModels().first { $0.persistentModelID == persistentModelID } as? T
    }

    private func _allModels() -> [any PersistentModel] {
        container.storage.lock.lock()
        defer { container.storage.lock.unlock() }
        return container.storage.insertionOrder.compactMap {
            container.storage.objects[$0]
        }
    }

    private func _pendingIdentifiers(inserted wantsInserted: Bool) -> Set<PersistentIdentifier> {
        stateLock.lock()
        defer { stateLock.unlock() }
        return wantsInserted ? inserted : Set(deleted.keys)
    }
}

enum _ModelContextRegistry {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var table: [PersistentIdentifier: ModelContext] = [:]

    static func register(_ context: ModelContext, for id: PersistentIdentifier) {
        lock.lock()
        table[id] = context
        lock.unlock()
    }

    static func context(for id: PersistentIdentifier) -> ModelContext? {
        lock.lock()
        defer { lock.unlock() }
        return table[id]
    }
}

// MARK: - Query property wrapper

enum _DefaultModelContext {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var stored: ModelContext?

    static var current: ModelContext? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    static func install(_ context: ModelContext) {
        lock.lock()
        stored = context
        lock.unlock()
    }
}

@propertyWrapper
public struct Query<Element: PersistentModel> {
    private let descriptor: FetchDescriptor<Element>

    public init() {
        descriptor = FetchDescriptor()
    }

    public init<Value>(
        filter: Predicate<Element>? = nil,
        sort keyPath: KeyPath<Element, Value> & Sendable,
        order: SortOrder = .forward
    ) where Value: Comparable {
        descriptor = FetchDescriptor(
            predicate: filter,
            sortBy: [SortDescriptor(keyPath, order: order)]
        )
    }

    public init(
        filter: Predicate<Element>? = nil,
        sort descriptors: [SortDescriptor<Element>] = []
    ) {
        descriptor = FetchDescriptor(predicate: filter, sortBy: descriptors)
    }

    public init(_ descriptor: FetchDescriptor<Element>) {
        self.descriptor = descriptor
    }

    public var wrappedValue: [Element] {
        guard let context = _DefaultModelContext.current else { return [] }
        return (try? context.fetch(descriptor)) ?? []
    }

    public var projectedValue: Self { self }
}

public enum SwiftDataPortable {
    public static let supportsDurableStorage = false
    public static let supportsCloudKit = false
    private static let diagnosticLock = NSLock()
    private nonisolated(unsafe) static var emittedVolatileDiagnostic = false

    public static func installDefaultContainer(_ container: ModelContainer) {
        _DefaultModelContext.install(container.mainContext)
    }

    /// The SwiftUI convenience API remains runnable when its default durable
    /// backend is unavailable. It truthfully announces the process-lifetime
    /// fallback once; explicit ModelConfiguration durable stores still throw.
    public static func reportVolatileFallback() {
        diagnosticLock.lock()
        let shouldEmit = !emittedVolatileDiagnostic
        emittedVolatileDiagnostic = true
        diagnosticLock.unlock()
        guard shouldEmit else { return }
        let message = "SwiftData: durable storage unavailable; using a volatile in-memory container\n"
        FileHandle.standardError.write(Data(message.utf8))
    }
}
