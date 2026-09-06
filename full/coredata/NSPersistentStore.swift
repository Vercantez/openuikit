import Foundation

struct _CDStoredRow {
    var entityName: String
    var reference: String
    var values: [String: Any]
}

final class _CDInMemoryBacking {
    let lock = NSLock()
    let uuid = UUID().uuidString
    var rows: [String: _CDStoredRow] = [:]
    var metadata: [String: Any] = [:]
}

open class NSPersistentStore: NSObject {
    public struct StoreType: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let sqlite = StoreType(rawValue: NSSQLiteStoreType)
        public static let binary = StoreType(rawValue: NSBinaryStoreType)
        public static let inMemory = StoreType(rawValue: NSInMemoryStoreType)
    }

    public private(set) weak var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    public private(set) var configurationName: String
    public var url: URL?
    public private(set) var options: [AnyHashable: Any]?
    public var identifier: String!
    public var metadata: [String: Any]!
    public var isReadOnly: Bool = false
    open var type: String { NSInMemoryStoreType }

    public required init(
        persistentStoreCoordinator root: NSPersistentStoreCoordinator?,
        configurationName name: String?,
        at url: URL,
        options: [AnyHashable: Any]? = nil
    ) {
        self.persistentStoreCoordinator = root
        self.configurationName = name ?? "PF_DEFAULT_CONFIGURATION_NAME"
        self.url = url
        self.options = options
        self.identifier = UUID().uuidString
        self.metadata = [
            NSStoreTypeKey: NSInMemoryStoreType,
            NSStoreUUIDKey: self.identifier as Any
        ]
        super.init()
    }

    public convenience init(
        persistentStoreCoordinator root: NSPersistentStoreCoordinator?,
        configurationName name: String?,
        URL url: URL,
        options: [AnyHashable: Any]? = nil
    ) {
        self.init(persistentStoreCoordinator: root, configurationName: name, at: url, options: options)
    }

    open class func metadataForPersistentStore(with url: URL) throws -> [String: Any] {
        try _CDReadSQLiteMetadata(at: url)
    }

    open class func setMetadata(_ metadata: [String: Any]?, forPersistentStoreAt url: URL) throws {
        try _CDWriteSQLiteMetadata(metadata, at: url)
    }

    open class func migrationManagerClass() -> AnyClass { NSMigrationManager.self }

    open func loadMetadata() throws {}
    open func didAdd(to coordinator: NSPersistentStoreCoordinator) {
        persistentStoreCoordinator = coordinator
    }
    open func willRemove(from coordinator: NSPersistentStoreCoordinator?) {
        persistentStoreCoordinator = nil
        _ = coordinator
    }

    public var coreSpotlightExporter: NSCoreDataCoreSpotlightDelegate {
        NSCoreDataCoreSpotlightDelegate(
            forStoreWith: NSPersistentStoreDescription(url: url ?? URL(fileURLWithPath: "/dev/null")),
            coordinator: persistentStoreCoordinator ?? NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        )
    }
}

final class _CDInMemoryPersistentStore: NSPersistentStore {
    let backing = _CDInMemoryBacking()
    override var type: String { NSInMemoryStoreType }

    required init(
        persistentStoreCoordinator root: NSPersistentStoreCoordinator?,
        configurationName name: String?,
        at url: URL,
        options: [AnyHashable: Any]? = nil
    ) {
        super.init(persistentStoreCoordinator: root, configurationName: name, at: url, options: options)
        backing.metadata = metadata
        identifier = backing.uuid
        metadata[NSStoreUUIDKey] = backing.uuid
        metadata[NSStoreTypeKey] = NSInMemoryStoreType
    }
}

open class NSPersistentStoreDescription: NSObject {
    public var url: URL?
    public var type: String = NSSQLiteStoreType
    public var configuration: String?
    public var timeout: TimeInterval = 0
    public var isReadOnly: Bool = false
    public var shouldAddStoreAsynchronously: Bool = false
    public var shouldMigrateStoreAutomatically: Bool = true
    public var shouldInferMappingModelAutomatically: Bool = true
    public var cloudKitContainerOptions: NSPersistentCloudKitContainerOptions?
    private var _options: [String: NSObject] = [:]
    private var _pragmas: [String: NSObject] = [:]

    public var options: [String: NSObject] { _options }
    public var sqlitePragmas: [String: NSObject] { _pragmas }

    public init(url: URL) {
        self.url = url
        super.init()
    }

    public convenience init(URL url: URL) {
        self.init(url: url)
    }

    public func setOption(_ option: NSObject?, forKey key: String) {
        if let option {
            _options[key] = option
        } else {
            _options.removeValue(forKey: key)
        }
    }

    public func setValue(_ value: NSObject?, forPragmaNamed name: String) {
        if let value {
            _pragmas[name] = value
        } else {
            _pragmas.removeValue(forKey: name)
        }
    }
}

open class NSPersistentStoreCoordinator: NSObject, NSLocking {
    public let managedObjectModel: NSManagedObjectModel
    public var name: String?
    public private(set) var persistentStores: [NSPersistentStore] = []
    private let _lock = NSRecursiveLock()
    private static let _registryLock = NSLock()
    private nonisolated(unsafe) static var _registry: [String: AnyClass] = [
        NSInMemoryStoreType: _CDInMemoryPersistentStore.self,
        NSSQLiteStoreType: _CDSQLitePersistentStore.self
    ]

    public init(managedObjectModel model: NSManagedObjectModel) {
        self.managedObjectModel = model
        super.init()
    }

    public func lock() { _lock.lock() }
    public func unlock() { _lock.unlock() }
    public func tryLock() -> Bool { _lock.try() }

    public func withLock<R>(_ body: () throws -> R) rethrows -> R {
        try performAndWait(body)
    }

    public func perform(_ block: @escaping () -> Void) {
        // Isolated Linux hosts have no run loop. Host drivers stay synchronous
        // so the sealed gate cannot hang on an un-pumped queue.
        performAndWait(block)
    }

    public func performAndWait(_ block: () -> Void) {
        lock()
        defer { unlock() }
        block()
    }

    public func performAndWait<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }

    public func perform<T>(_ block: @escaping () throws -> T) async rethrows -> T {
        try performAndWait(block)
    }

    open class var registeredStoreTypes: [String: NSValue] {
        _registryLock.lock()
        defer { _registryLock.unlock() }
        var types: [String: NSValue] = [:]
        for key in _registry.keys {
            types[key] = NSNumber(value: 1)
        }
        return types
    }

    open class func registerStoreClass(_ storeClass: AnyClass?, forStoreType storeType: String) {
        _registryLock.lock()
        defer { _registryLock.unlock() }
        if let storeClass {
            _registry[storeType] = storeClass
        } else {
            _registry.removeValue(forKey: storeType)
        }
    }

    open class func registerStoreClass(_ storeClass: AnyClass?, type: NSPersistentStore.StoreType) {
        registerStoreClass(storeClass, forStoreType: type.rawValue)
    }

    open class func metadataForPersistentStore(ofType storeType: String?, at url: URL) throws -> [String: Any] {
        try metadataForPersistentStore(ofType: storeType ?? NSSQLiteStoreType, at: url, options: nil)
    }

    open class func metadataForPersistentStore(
        ofType storeType: String,
        at url: URL,
        options: [AnyHashable: Any]? = nil
    ) throws -> [String: Any] {
        _ = (url, options)
        if storeType == NSInMemoryStoreType {
            return [NSStoreTypeKey: NSInMemoryStoreType]
        }
        if storeType == NSSQLiteStoreType {
            return try _CDReadSQLiteMetadata(at: url)
        }
        throw _CDUnsupportedStoreError(storeType)
    }

    open class func metadataForPersistentStore(
        type storeType: NSPersistentStore.StoreType,
        at storeURL: URL,
        options: [AnyHashable: Any]? = nil
    ) throws -> [String: Any] {
        try metadataForPersistentStore(ofType: storeType.rawValue, at: storeURL, options: options)
    }

    open class func setMetadata(
        _ metadata: [String: Any]?,
        forPersistentStoreOfType storeType: String?,
        at url: URL
    ) throws {
        try setMetadata(metadata, forPersistentStoreOfType: storeType ?? NSSQLiteStoreType, at: url, options: nil)
    }

    open class func setMetadata(
        _ metadata: [String: Any]?,
        forPersistentStoreOfType storeType: String,
        at url: URL,
        options: [AnyHashable: Any]? = nil
    ) throws {
        _ = options
        if storeType == NSInMemoryStoreType {
            return
        }
        if storeType == NSSQLiteStoreType {
            try _CDWriteSQLiteMetadata(metadata, at: url)
            return
        }
        throw _CDUnsupportedStoreError(storeType)
    }

    open class func setMetadata(
        _ metadata: [String: Any]?,
        type storeType: NSPersistentStore.StoreType,
        at storeURL: URL,
        options: [AnyHashable: Any]? = nil
    ) throws {
        try setMetadata(metadata, forPersistentStoreOfType: storeType.rawValue, at: storeURL, options: options)
    }

    open class func removeUbiquitousContentAndPersistentStore(
        at storeURL: URL,
        options: [AnyHashable: Any]? = nil
    ) throws {
        _ = (storeURL, options)
        throw _CDMakeError(
            NSPersistentStoreOperationError,
            "iCloud ubiquity stores are unavailable on Linux"
        )
    }

    public func addPersistentStore(
        ofType storeType: String,
        configurationName configuration: String?,
        at storeURL: URL?,
        options: [AnyHashable: Any]? = nil
    ) throws -> NSPersistentStore {
        Self._registryLock.lock()
        let registered: AnyClass? = Self._registry[storeType]
        Self._registryLock.unlock()
        guard let registered, let storeClass = registered as? NSPersistentStore.Type else {
            throw _CDUnsupportedStoreError(storeType)
        }
        let url = storeURL ?? URL(string: "x-coredata-\(storeType.lowercased())://\(_CDIDSource.next())")!
        let store = storeClass.init(
            persistentStoreCoordinator: self,
            configurationName: configuration,
            at: url,
            options: options
        )
        try store.loadMetadata()
        store.metadata[NSStoreModelVersionHashesKey] = managedObjectModel.entityVersionHashesByName
        persistentStores.append(store)
        store.didAdd(to: self)
        NotificationCenter.default.post(
            name: .NSPersistentStoreCoordinatorStoresDidChange,
            object: self,
            userInfo: [NSAddedPersistentStoresKey: [store]]
        )
        return store
    }

    public func addPersistentStore(
        type: NSPersistentStore.StoreType,
        configuration: String? = nil,
        at storeURL: URL,
        options: [AnyHashable: Any]? = nil
    ) throws -> NSPersistentStore {
        try addPersistentStore(ofType: type.rawValue, configurationName: configuration, at: storeURL, options: options)
    }

    public func addPersistentStore(
        with storeDescription: NSPersistentStoreDescription,
        completionHandler block: @escaping (NSPersistentStoreDescription, (any Error)?) -> Void
    ) {
        let work = {
            do {
                _ = try self.addPersistentStore(
                    ofType: storeDescription.type,
                    configurationName: storeDescription.configuration,
                    at: storeDescription.url,
                    options: storeDescription.options
                )
                block(storeDescription, nil)
            } catch {
                block(storeDescription, error)
            }
        }
        if storeDescription.shouldAddStoreAsynchronously {
            perform(work)
        } else {
            performAndWait(work)
        }
    }

    public func remove(_ store: NSPersistentStore) throws {
        store.willRemove(from: self)
        persistentStores.removeAll { $0 === store }
        NotificationCenter.default.post(
            name: .NSPersistentStoreCoordinatorStoresDidChange,
            object: self,
            userInfo: [NSRemovedPersistentStoresKey: [store]]
        )
    }

    public func persistentStore(for URL: URL) -> NSPersistentStore? {
        persistentStores.first { $0.url == URL }
    }

    public func url(for store: NSPersistentStore) -> URL {
        store.url ?? URL(string: "x-coredata-in-memory://\(store.identifier ?? "store")")!
    }

    public func setURL(_ url: URL, for store: NSPersistentStore) -> Bool {
        store.url = url
        return true
    }

    public func metadata(for store: NSPersistentStore) -> [String: Any] {
        store.metadata ?? [:]
    }

    public func setMetadata(_ metadata: [String: Any]?, for store: NSPersistentStore) {
        store.metadata = metadata
    }

    public func managedObjectID(forURIRepresentation url: URL) -> NSManagedObjectID? {
        managedObjectID(for: url.absoluteString)
    }

    public func managedObjectID(for string: String) -> NSManagedObjectID? {
        guard let url = URL(string: string) else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }
        let entityName = parts[0]
        let refToken = parts[1]
        guard let entity = managedObjectModel.entitiesByName[entityName] else { return nil }
        let isTemporary = refToken.hasPrefix("t")
        let reference = String(refToken.dropFirst())
        return NSManagedObjectID(
            entity: entity,
            reference: reference,
            storeIdentifier: url.host ?? "memory",
            isTemporary: isTemporary,
            store: persistentStores.first
        )
    }

    public func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext) throws -> Any {
        try context.execute(request)
    }

    public func currentPersistentHistoryToken(fromStores stores: [Any]?) -> NSPersistentHistoryToken? {
        _ = stores
        return nil
    }

    public func finishDeferredLightweightMigration() throws {
        throw _CDMakeError(NSMigrationError, "lightweight migration is not implemented on Linux")
    }

    public func finishDeferredLightweightMigrationTask() throws {
        try finishDeferredLightweightMigration()
    }

    public func destroyPersistentStore(
        at url: URL,
        ofType storeType: String,
        options: [AnyHashable: Any]? = nil
    ) throws {
        _ = options
        if let store = persistentStore(for: url) {
            try remove(store)
        }
        if storeType == NSSQLiteStoreType {
            let fm = FileManager.default
            try? fm.removeItem(at: url)
            try? fm.removeItem(atPath: url.path + "-wal")
            try? fm.removeItem(atPath: url.path + "-shm")
            return
        }
        if storeType != NSInMemoryStoreType {
            throw _CDUnsupportedStoreError(storeType)
        }
    }

    public func destroyPersistentStore(
        at url: URL,
        type storeType: NSPersistentStore.StoreType,
        options: [AnyHashable: Any]? = nil
    ) throws {
        try destroyPersistentStore(at: url, ofType: storeType.rawValue, options: options)
    }

    public func migratePersistentStore(
        _ store: NSPersistentStore,
        to URL: URL,
        options: [AnyHashable: Any]? = nil,
        withType storeType: String
    ) throws -> NSPersistentStore {
        _ = (store, URL, options)
        throw _CDUnsupportedStoreError(storeType)
    }

    public func migratePersistentStore(
        _ store: NSPersistentStore,
        to storeURL: URL,
        options: [AnyHashable: Any]? = nil,
        type storeType: NSPersistentStore.StoreType
    ) throws -> NSPersistentStore {
        try migratePersistentStore(store, to: storeURL, options: options, withType: storeType.rawValue)
    }

    public func replacePersistentStore(
        at destinationURL: URL,
        destinationOptions: [AnyHashable: Any]? = nil,
        withPersistentStoreFrom sourceURL: URL,
        sourceOptions: [AnyHashable: Any]? = nil,
        ofType storeType: String
    ) throws {
        _ = (destinationURL, destinationOptions, sourceURL, sourceOptions)
        throw _CDUnsupportedStoreError(storeType)
    }

    public func replacePersistentStore(
        at destinationURL: URL,
        destinationOptions: [AnyHashable: Any]? = nil,
        withPersistentStoreFrom sourceURL: URL,
        sourceOptions: [AnyHashable: Any]? = nil,
        type sourceType: NSPersistentStore.StoreType
    ) throws {
        try replacePersistentStore(
            at: destinationURL,
            destinationOptions: destinationOptions,
            withPersistentStoreFrom: sourceURL,
            sourceOptions: sourceOptions,
            ofType: sourceType.rawValue
        )
    }

    func _fetchRows(
        entityName: String,
        stores: [NSPersistentStore]?,
        includesSubentities: Bool
    ) -> [_CDStoredRow] {
        let targetStores = stores ?? persistentStores
        var rows: [_CDStoredRow] = []
        let names = _entityNames(matching: entityName, includesSubentities: includesSubentities)
        for store in targetStores {
            guard let rowStore = store as? _CDRowStore else { continue }
            rows.append(contentsOf: rowStore._cdAllRows(entityNames: names))
        }
        return rows
    }

    func _row(for objectID: NSManagedObjectID) -> _CDStoredRow? {
        for store in persistentStores {
            if let rowStore = store as? _CDRowStore, let row = rowStore._cdRow(for: objectID.reference) {
                return row
            }
        }
        return nil
    }

    func _save(inserted: [NSManagedObject], updated: [NSManagedObject], deleted: [NSManagedObject]) throws {
        guard let fallback = persistentStores.first else {
            throw _CDMakeError(NSPersistentStoreSaveError, "no persistent store is attached")
        }
        var buckets: [ObjectIdentifier: (store: NSPersistentStore, inserted: [_CDStoredRow], updated: [_CDStoredRow], deleted: [String])] = [:]
        func bucketID(for object: NSManagedObject) -> ObjectIdentifier {
            let store = object.objectID.persistentStore ?? fallback
            let id = ObjectIdentifier(store)
            if buckets[id] == nil {
                buckets[id] = (store, [], [], [])
            }
            return id
        }
        for object in deleted {
            let id = bucketID(for: object)
            var entry = buckets[id]!
            entry.deleted.append(object.objectID.reference)
            buckets[id] = entry
        }
        for object in inserted {
            let id = bucketID(for: object)
            var entry = buckets[id]!
            entry.inserted.append(
                _CDStoredRow(
                    entityName: object.entity.name ?? "",
                    reference: object.objectID.reference,
                    values: object._snapshotValues()
                )
            )
            buckets[id] = entry
        }
        for object in updated {
            let id = bucketID(for: object)
            var entry = buckets[id]!
            entry.updated.append(
                _CDStoredRow(
                    entityName: object.entity.name ?? "",
                    reference: object.objectID.reference,
                    values: object._snapshotValues()
                )
            )
            buckets[id] = entry
        }
        for entry in buckets.values {
            guard let rowStore = entry.store as? _CDRowStore else {
                throw _CDMakeError(NSPersistentStoreSaveError, "store type \(entry.store.type) cannot save rows")
            }
            try rowStore._cdApplySave(inserted: entry.inserted, updated: entry.updated, deleted: entry.deleted)
        }
    }

    private func _entityNames(matching name: String, includesSubentities: Bool) -> Set<String> {
        var names: Set<String> = [name]
        if includesSubentities, let entity = managedObjectModel.entitiesByName[name] {
            func walk(_ entity: NSEntityDescription) {
                for child in entity.subentities {
                    if let childName = child.name {
                        names.insert(childName)
                    }
                    walk(child)
                }
            }
            walk(entity)
        }
        return names
    }
}

open class NSPersistentContainer: NSObject {
    public let name: String
    public let managedObjectModel: NSManagedObjectModel
    public let persistentStoreCoordinator: NSPersistentStoreCoordinator
    public var persistentStoreDescriptions: [NSPersistentStoreDescription]
    public let viewContext: NSManagedObjectContext

    open class func defaultDirectoryURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("CoreData", isDirectory: true)
    }

    public convenience init(name: String) {
        self.init(name: name, managedObjectModel: NSManagedObjectModel())
    }

    public init(name: String, managedObjectModel model: NSManagedObjectModel) {
        self.name = name
        self.managedObjectModel = model
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let description = NSPersistentStoreDescription(
            url: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(name).sqlite")
        )
        description.type = NSSQLiteStoreType
        self.persistentStoreDescriptions = [description]
        self.viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        super.init()
        viewContext.persistentStoreCoordinator = persistentStoreCoordinator
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.name = "viewContext"
    }

    public func loadPersistentStores(
        completionHandler block: @escaping (NSPersistentStoreDescription, (any Error)?) -> Void
    ) {
        for description in persistentStoreDescriptions {
            persistentStoreCoordinator.addPersistentStore(with: description, completionHandler: block)
        }
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        context.name = "background"
        return context
    }

    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = newBackgroundContext()
        context.perform { block(context) }
    }

    public func performBackgroundTask<T>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = newBackgroundContext()
        return try await context.perform(schedule: .enqueued) {
            try block(context)
        }
    }
}
