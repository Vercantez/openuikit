import Foundation

public typealias DataStoreSnapshotValue = Codable & Sendable

public protocol DataStoreConfiguration: Hashable {
    associatedtype Store: DataStore where Self == Self.Store.Configuration
    var name: String { get }
    var schema: Schema? { get set }
    func validate() throws
}

public extension DataStoreConfiguration {
    func validate() throws {}
}

public protocol DataStore: AnyObject {
    associatedtype Configuration: DataStoreConfiguration where Self == Self.Configuration.Store
    associatedtype Snapshot: DataStoreSnapshot
    var configuration: Configuration { get }
    var identifier: String { get }
    var schema: Schema { get }
    init(_ configuration: Configuration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws
    func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot>
        where T: PersistentModel
    func fetchCount<T>(_ request: DataStoreFetchRequest<T>) throws -> Int where T: PersistentModel
    func fetchIdentifiers<T>(_ request: DataStoreFetchRequest<T>) throws -> [PersistentIdentifier]
        where T: PersistentModel
    func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot>
    func cachedSnapshots(
        for persistentIdentifiers: [PersistentIdentifier],
        editingState: EditingState
    ) throws -> [PersistentIdentifier: Snapshot]
    func initializeState(for editingState: EditingState)
    func invalidateState(for editingState: EditingState)
    func erase() throws
}

public extension DataStore {
    func fetchCount<T>(_ request: DataStoreFetchRequest<T>) throws -> Int where T: PersistentModel {
        try fetch(request).fetchedSnapshots.count
    }

    func fetchIdentifiers<T>(
        _ request: DataStoreFetchRequest<T>
    ) throws -> [PersistentIdentifier] where T: PersistentModel {
        try fetch(request).fetchedSnapshots.map(\.persistentIdentifier)
    }

    func cachedSnapshots(
        for persistentIdentifiers: [PersistentIdentifier],
        editingState: EditingState
    ) throws -> [PersistentIdentifier: Snapshot] {
        _ = editingState
        _ = persistentIdentifiers
        return [:]
    }

    func initializeState(for editingState: EditingState) { _ = editingState }
    func invalidateState(for editingState: EditingState) { _ = editingState }
    func erase() throws {}
}

public protocol DataStoreBatching: DataStore {
    func delete<T>(_ request: DataStoreBatchDeleteRequest<T>) throws where T: PersistentModel
}

public protocol DataStoreSnapshot: Codable, Sendable {
    var persistentIdentifier: PersistentIdentifier { get }
    init(from: any BackingData, relatedBackingDatas: inout [PersistentIdentifier: any BackingData])
    func copy(
        persistentIdentifier: PersistentIdentifier,
        remappedIdentifiers: [PersistentIdentifier: PersistentIdentifier]?
    ) -> Self
}

public enum DataStoreError: Hashable, Error {
    case invalidPredicate
    case preferInMemorySort
    case preferInMemoryFilter
    case unsupportedFeature

}

public enum DataStoreSnapshotCodingKey: CodingKey {
    case persistentIdentifier
    case modeledProperty(String)

    public var stringValue: String {
        switch self {
        case .persistentIdentifier: return "persistentIdentifier"
        case .modeledProperty(let name): return name
        }
    }

    public var intValue: Int? { nil }

    public init?(intValue: Int) {
        _ = intValue
        return nil
    }

    public init?(stringValue: String) {
        if stringValue == "persistentIdentifier" {
            self = .persistentIdentifier
        } else {
            self = .modeledProperty(stringValue)
        }
    }
}

public struct EditingState: Identifiable, Sendable {
    public typealias ID = UUID
    public let id: UUID
    public var author: String?

    public init(author: String? = nil) {
        self.id = UUID()
        self.author = author
    }
}

public struct DataStoreFetchRequest<T: PersistentModel> {
    public let descriptor: FetchDescriptor<T>
    public let editingState: EditingState

    public init(descriptor: FetchDescriptor<T>, editingState: EditingState = EditingState()) {
        self.descriptor = descriptor
        self.editingState = editingState
    }
}

public struct DataStoreFetchResult<ModelType: PersistentModel, SnapshotType: DataStoreSnapshot> {
    public let descriptor: FetchDescriptor<ModelType>
    public let fetchedSnapshots: [SnapshotType]
    public let relatedSnapshots: [PersistentIdentifier: SnapshotType]

    public init(
        descriptor: FetchDescriptor<ModelType>,
        fetchedSnapshots: [SnapshotType],
        relatedSnapshots: [PersistentIdentifier: SnapshotType] = [:]
    ) {
        self.descriptor = descriptor
        self.fetchedSnapshots = fetchedSnapshots
        self.relatedSnapshots = relatedSnapshots
    }
}

public struct DataStoreBatchDeleteRequest<T: PersistentModel> {
    public let editingState: EditingState
    public let includeSubclasses: Bool
    public let predicate: Predicate<T>?

    public init(
        predicate: Predicate<T>? = nil,
        includeSubclasses: Bool = true,
        editingState: EditingState = EditingState()
    ) {
        self.predicate = predicate
        self.includeSubclasses = includeSubclasses
        self.editingState = editingState
    }
}

public struct DataStoreSaveChangesRequest<SnapshotType: DataStoreSnapshot> {
    public let inserted: [SnapshotType]
    public let updated: [SnapshotType]
    public let deleted: [SnapshotType]
    public let editingState: EditingState

    public init(
        inserted: [SnapshotType] = [],
        updated: [SnapshotType] = [],
        deleted: [SnapshotType] = [],
        editingState: EditingState = EditingState()
    ) {
        self.inserted = inserted
        self.updated = updated
        self.deleted = deleted
        self.editingState = editingState
    }
}

public final class DataStoreSaveChangesResult<T: DataStoreSnapshot>: @unchecked Sendable {
    public let storeIdentifier: String
    public let remappedIdentifiers: [PersistentIdentifier: PersistentIdentifier]
    public let snapshotsToReregister: [PersistentIdentifier: T]

    public init(
        for storeIdentifier: String,
        remappedIdentifiers: [PersistentIdentifier: PersistentIdentifier] = [:],
        snapshotsToReregister: [PersistentIdentifier: T] = [:]
    ) {
        self.storeIdentifier = storeIdentifier
        self.remappedIdentifiers = remappedIdentifiers
        self.snapshotsToReregister = snapshotsToReregister
    }
}

public protocol BackingData<Model> {
    associatedtype Model: PersistentModel
    var persistentModelID: PersistentIdentifier? { get set }
    var metadata: Any { get }
    init(for modelType: Model.Type)
    func getTransformableValue<Value>(forKey: KeyPath<Model, Value>) -> Value
    func setTransformableValue<Value>(forKey: KeyPath<Model, Value>, to newValue: Value)
    func getValue<Value>(forKey: KeyPath<Model, Value>) -> Value where Value: Decodable
    func getValue<Value>(forKey: KeyPath<Model, Value>) -> Value where Value: PersistentModel
    func getValue<Value>(forKey: KeyPath<Model, Value?>) -> Value? where Value: PersistentModel
    func getValue<Value, OtherModel>(
        forKey: KeyPath<Model, Value>
    ) -> Value where Value: RelationshipCollection, OtherModel == Value.PersistentElement
    func getValue<Value, OtherModel>(
        forKey: KeyPath<Model, Value>
    ) -> Value
    where Value: Decodable, Value: RelationshipCollection, OtherModel == Value.PersistentElement
    func setValue<Value>(forKey: KeyPath<Model, Value>, to newValue: Value) where Value: Encodable
    func setValue<Value>(forKey: KeyPath<Model, Value>, to newValue: Value) where Value: PersistentModel
    func setValue<Value>(forKey: KeyPath<Model, Value?>, to newValue: Value?) where Value: PersistentModel
    func setValue<Value, OtherModel>(
        forKey: KeyPath<Model, Value>,
        to newValue: Value
    ) where Value: RelationshipCollection, OtherModel == Value.PersistentElement
    func setValue<Value, OtherModel>(
        forKey: KeyPath<Model, Value>,
        to newValue: Value
    ) where Value: Encodable, Value: RelationshipCollection, OtherModel == Value.PersistentElement
}

public final class PortableBackingData<Model: PersistentModel>: BackingData, @unchecked Sendable {
    public var persistentModelID: PersistentIdentifier?
    public var metadata: Any { persistentModelID as Any? as Any }
    private weak var model: Model?

    public init(for modelType: Model.Type) {
        _ = modelType
        self.persistentModelID = nil
    }

    public init(model: Model) {
        self.model = model
        self.persistentModelID = model.persistentModelID
    }

    public func getTransformableValue<Value>(forKey keyPath: KeyPath<Model, Value>) -> Value {
        guard let model else { fatalError("backing data is unbound") }
        return model[keyPath: keyPath]
    }

    public func setTransformableValue<Value>(forKey keyPath: KeyPath<Model, Value>, to newValue: Value) {
        _ = keyPath
        _ = newValue
    }

    public func getValue<Value>(forKey keyPath: KeyPath<Model, Value>) -> Value where Value: Decodable {
        guard let model else { fatalError("backing data is unbound") }
        return model[keyPath: keyPath]
    }

    public func getValue<Value>(forKey keyPath: KeyPath<Model, Value>) -> Value where Value: PersistentModel {
        guard let model else { fatalError("backing data is unbound") }
        return model[keyPath: keyPath]
    }

    public func getValue<Value>(forKey keyPath: KeyPath<Model, Value?>) -> Value? where Value: PersistentModel {
        guard let model else { fatalError("backing data is unbound") }
        return model[keyPath: keyPath]
    }

    public func getValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Model, Value>
    ) -> Value where Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        guard let model else { fatalError("backing data is unbound") }
        return model[keyPath: keyPath]
    }

    public func getValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Model, Value>
    ) -> Value
    where Value: Decodable, Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        guard let model else { fatalError("backing data is unbound") }
        return model[keyPath: keyPath]
    }

    public func setValue<Value>(forKey keyPath: KeyPath<Model, Value>, to newValue: Value) where Value: Encodable {
        _ = keyPath
        _ = newValue
    }

    public func setValue<Value>(
        forKey keyPath: KeyPath<Model, Value>,
        to newValue: Value
    ) where Value: PersistentModel {
        _ = keyPath
        _ = newValue
    }

    public func setValue<Value>(
        forKey keyPath: KeyPath<Model, Value?>,
        to newValue: Value?
    ) where Value: PersistentModel {
        _ = keyPath
        _ = newValue
    }

    public func setValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Model, Value>,
        to newValue: Value
    ) where Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        _ = keyPath
        _ = newValue
    }

    public func setValue<Value, OtherModel>(
        forKey keyPath: KeyPath<Model, Value>,
        to newValue: Value
    ) where Value: Encodable, Value: RelationshipCollection, OtherModel == Value.PersistentElement {
        _ = keyPath
        _ = newValue
    }
}

public struct DefaultSnapshot: DataStoreSnapshot, Hashable, Sendable {
    public let persistentIdentifier: PersistentIdentifier
    public let values: [String: String]

    public init(persistentIdentifier: PersistentIdentifier, values: [String: String] = [:]) {
        self.persistentIdentifier = persistentIdentifier
        self.values = values
    }

    public init(
        from backingData: any BackingData,
        relatedBackingDatas: inout [PersistentIdentifier: any BackingData]
    ) {
        self.persistentIdentifier = backingData.persistentModelID ?? PersistentIdentifier()
        self.values = [:]
        if let identifier = backingData.persistentModelID {
            relatedBackingDatas[identifier] = backingData
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        persistentIdentifier = try container.decode(PersistentIdentifier.self, forKey: .persistentIdentifier)
        values = try container.decode([String: String].self, forKey: .values)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(persistentIdentifier, forKey: .persistentIdentifier)
        try container.encode(values, forKey: .values)
    }

    public func copy(
        persistentIdentifier: PersistentIdentifier,
        remappedIdentifiers: [PersistentIdentifier: PersistentIdentifier]? = [:]
    ) -> DefaultSnapshot {
        _ = remappedIdentifiers
        return DefaultSnapshot(persistentIdentifier: persistentIdentifier, values: values)
    }

    private enum CodingKeys: String, CodingKey {
        case persistentIdentifier, values
    }
}

public final class DefaultStore: DataStore, DataStoreBatching, HistoryProviding, @unchecked Sendable {
    public typealias Configuration = ModelConfiguration
    public typealias Snapshot = DefaultSnapshot
    public typealias HistoryType = DefaultHistoryTransaction
    public typealias TokenType = DefaultHistoryToken

    public let configuration: ModelConfiguration
    public let schema: Schema
    public let name: String
    public var identifier: String { name }
    public static var historyType: DefaultHistoryTransaction.Type { DefaultHistoryTransaction.self }

    private let lock = NSLock()
    private var snapshots: [PersistentIdentifier: DefaultSnapshot] = [:]

    public init(
        _ configuration: ModelConfiguration,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) throws {
        guard configuration.isStoredInMemoryOnly else {
            throw SwiftDataError.unsupportedPersistentStore
        }
        if migrationPlan != nil {
            throw SwiftDataError.backwardMigration
        }
        try configuration.validate()
        self.configuration = configuration
        self.schema = configuration.schema ?? Schema()
        self.name = configuration.name
    }

    public func fetch<T>(
        _ request: DataStoreFetchRequest<T>
    ) throws -> DataStoreFetchResult<T, DefaultSnapshot> where T: PersistentModel {
        _ = request.descriptor
        lock.lock()
        let values = Array(snapshots.values)
        lock.unlock()
        return DataStoreFetchResult(descriptor: request.descriptor, fetchedSnapshots: values)
    }

    public func fetchCount<T>(_ request: DataStoreFetchRequest<T>) throws -> Int where T: PersistentModel {
        try fetch(request).fetchedSnapshots.count
    }

    public func fetchIdentifiers<T>(
        _ request: DataStoreFetchRequest<T>
    ) throws -> [PersistentIdentifier] where T: PersistentModel {
        try fetch(request).fetchedSnapshots.map(\.persistentIdentifier)
    }

    public func save(
        _ request: DataStoreSaveChangesRequest<DefaultSnapshot>
    ) throws -> DataStoreSaveChangesResult<DefaultSnapshot> {
        lock.lock()
        for snapshot in request.inserted + request.updated {
            snapshots[snapshot.persistentIdentifier] = snapshot
        }
        for snapshot in request.deleted {
            snapshots.removeValue(forKey: snapshot.persistentIdentifier)
        }
        lock.unlock()
        return DataStoreSaveChangesResult(for: identifier)
    }

    public func cachedSnapshots(
        for persistentIdentifiers: [PersistentIdentifier],
        editingState: EditingState
    ) throws -> [PersistentIdentifier: DefaultSnapshot] {
        _ = editingState
        lock.lock()
        defer { lock.unlock() }
        var result: [PersistentIdentifier: DefaultSnapshot] = [:]
        for identifier in persistentIdentifiers {
            if let snapshot = snapshots[identifier] {
                result[identifier] = snapshot
            }
        }
        return result
    }

    public func delete<T>(_ request: DataStoreBatchDeleteRequest<T>) throws where T: PersistentModel {
        _ = request
        lock.lock()
        snapshots.removeAll()
        lock.unlock()
    }

    public func fetchHistory(
        _ descriptor: HistoryDescriptor<DefaultHistoryTransaction>
    ) throws -> [DefaultHistoryTransaction] {
        _ = descriptor
        return []
    }

    public func deleteHistory(_ descriptor: HistoryDescriptor<DefaultHistoryTransaction>) throws {
        _ = descriptor
    }

    public func initializeState(for editingState: EditingState) { _ = editingState }
    public func invalidateState(for editingState: EditingState) { _ = editingState }
    public func erase() throws {
        lock.lock()
        snapshots.removeAll()
        lock.unlock()
    }
}
