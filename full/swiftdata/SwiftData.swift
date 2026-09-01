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

public struct PersistentIdentifier: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UInt64

    public init() {
        rawValue = _PersistentIdentifierSource.next()
    }

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public var description: String { "SwiftData.PersistentIdentifier(\(rawValue))" }
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

public protocol PersistentModel: AnyObject, Identifiable, Hashable, Observable
where ID == PersistentIdentifier {
    var persistentModelID: PersistentIdentifier { get }
}

public extension PersistentModel {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
}

#if hasFeature(Macros)
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

// MARK: - Configuration and failure boundary

public enum SwiftDataError: Error, Equatable, CustomStringConvertible {
    case unsupportedPersistentStore
    case modelTypeNotInSchema(String)
    case predicateEvaluation(String)

    public var description: String {
        switch self {
        case .unsupportedPersistentStore:
            return "durable SwiftData stores are unavailable on this platform"
        case .modelTypeNotInSchema(let name):
            return "model type is not present in this container schema: \(name)"
        case .predicateEvaluation(let reason):
            return "SwiftData predicate evaluation failed: \(reason)"
        }
    }
}

public struct ModelConfiguration: Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let isStoredInMemoryOnly: Bool
    public let allowsSave: Bool
    fileprivate let modelTypeNames: [String]

    public init(isStoredInMemoryOnly: Bool = false) {
        self.id = "Default"
        self.name = "Default"
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.allowsSave = true
        self.modelTypeNames = []
    }

    public init(
        _ name: String? = nil,
        isStoredInMemoryOnly: Bool = false,
        allowsSave: Bool = true
    ) {
        let resolvedName = name ?? "Default"
        self.id = resolvedName
        self.name = resolvedName
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.allowsSave = allowsSave
        self.modelTypeNames = []
    }

    public init(
        for modelTypes: any PersistentModel.Type...,
        isStoredInMemoryOnly: Bool = false
    ) {
        self.id = "Default"
        self.name = "Default"
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
        self.allowsSave = true
        self.modelTypeNames = modelTypes.map { String(reflecting: $0) }
    }
}

private final class _ModelStorage: @unchecked Sendable {
    let lock = NSLock()
    var objects: [ObjectIdentifier: any PersistentModel] = [:]
    var insertionOrder: [ObjectIdentifier] = []
}

public final class ModelContainer: @unchecked Sendable {
    fileprivate let storage = _ModelStorage()
    fileprivate let modelTypes: Set<ObjectIdentifier>
    public let configurations: [ModelConfiguration]
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
        self.configurations = effective
    }

    public convenience init(
        for modelTypes: any PersistentModel.Type...,
        configurations: ModelConfiguration...
    ) throws {
        try self.init(modelTypes: modelTypes, configurations: configurations)
    }
}

// MARK: - Fetching and mutation

public struct FetchDescriptor<T> {
    public var predicate: Predicate<T>?
    public var sortBy: [SortDescriptor<T>]
    public var fetchLimit: Int?
    public var fetchOffset: Int?
    public var includePendingChanges: Bool

    public init(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) {
        self.predicate = predicate
        self.sortBy = sortBy
        self.fetchLimit = nil
        self.fetchOffset = nil
        self.includePendingChanges = true
    }
}

public final class ModelContext: Equatable, @unchecked Sendable {
    public let container: ModelContainer
    public var autosaveEnabled = true

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

    public func fetchCount<T>(_ descriptor: FetchDescriptor<T>) throws -> Int
    where T: PersistentModel {
        try fetch(descriptor).count
    }

    public func save() throws {
        guard container.configurations.allSatisfy(\.allowsSave) else {
            throw SwiftDataError.unsupportedPersistentStore
        }
        stateLock.lock()
        inserted.removeAll(keepingCapacity: true)
        deleted.removeAll(keepingCapacity: true)
        stateLock.unlock()
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

    public func model(for persistentModelID: PersistentIdentifier) -> any PersistentModel {
        guard let model = _allModels().first(where: {
            $0.persistentModelID == persistentModelID
        }) else {
            preconditionFailure("SwiftData model identifier is not registered")
        }
        return model
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

// MARK: - Query property wrapper

private enum _DefaultModelContext {
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
