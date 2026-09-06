import Foundation

// Fail-closed Apple-service, migration, history, Spotlight, and store-subclass
// surfaces. Methods either throw, return nil/false, or are inert. They exist so
// unchanged application sources can compile against the public names.

open class NSQueryGenerationToken: NSObject {
    public static var current: NSQueryGenerationToken { NSQueryGenerationToken() }
    public override init() { super.init() }
    public init?(coder: NSCoder) { super.init() }
}

open class NSPersistentHistoryToken: NSObject {
    public override init() { super.init() }
    public init?(coder: NSCoder) { super.init() }
}

open class NSPersistentHistoryChange: NSObject {
    public var changeID: Int64 { 0 }
    public var changeType: NSPersistentHistoryChangeType { .insert }
    public var changedObjectID: NSManagedObjectID {
        NSManagedObjectID(
            entity: NSEntityDescription(),
            reference: "0",
            storeIdentifier: "history",
            isTemporary: true,
            store: nil
        )
    }
    public var tombstone: [AnyHashable: Any]? { nil }
    public var transaction: NSPersistentHistoryTransaction? { nil }
    public var updatedProperties: Set<NSPropertyDescription>? { nil }
    open class var entityDescription: NSEntityDescription? { nil }
    open class var fetchRequest: NSFetchRequest<any NSFetchRequestResult>? { nil }
    open class func entityDescription(with context: NSManagedObjectContext) -> NSEntityDescription? {
        _ = context
        return nil
    }
}

open class NSPersistentHistoryTransaction: NSObject {
    public var author: String? { nil }
    public var bundleID: String { "" }
    public var changes: [NSPersistentHistoryChange]? { nil }
    public var contextName: String? { nil }
    public var processID: String { "" }
    public var storeID: String { "" }
    public var timestamp: Date { Date(timeIntervalSince1970: 0) }
    public var token: NSPersistentHistoryToken { NSPersistentHistoryToken() }
    public var transactionNumber: Int64 { 0 }
    open class var entityDescription: NSEntityDescription? { nil }
    open class var fetchRequest: NSFetchRequest<any NSFetchRequestResult>? { nil }
    open class func entityDescription(with context: NSManagedObjectContext) -> NSEntityDescription? {
        _ = context
        return nil
    }
    public func objectIDNotification() -> Notification {
        Notification(name: .NSPersistentStoreRemoteChange, object: nil, userInfo: nil)
    }
}

open class NSPersistentHistoryChangeRequest: NSPersistentStoreRequest {
    public var fetchRequest: NSFetchRequest<any NSFetchRequestResult>?
    public var resultType: NSPersistentHistoryResultType = .transactionsAndChanges
    public private(set) var token: NSPersistentHistoryToken?

    public required override init() {
        super.init()
    }

    public override var requestType: NSPersistentStoreRequestType { .fetchRequestType }

    open class func deleteHistory(before date: Date) -> Self {
        _ = date
        return Self()
    }
    open class func deleteHistory(before token: NSPersistentHistoryToken?) -> Self {
        let request = Self()
        request.token = token
        return request
    }
    open class func deleteHistory(before transaction: NSPersistentHistoryTransaction?) -> Self {
        Self.deleteHistory(before: transaction?.token)
    }
    open class func fetchHistory(after date: Date) -> Self {
        _ = date
        return Self()
    }
    open class func fetchHistory(after token: NSPersistentHistoryToken?) -> Self {
        let request = Self()
        request.token = token
        return request
    }
    open class func fetchHistory(after transaction: NSPersistentHistoryTransaction?) -> Self {
        Self.fetchHistory(after: transaction?.token)
    }
    open class func fetchHistory(withFetch fetchRequest: NSFetchRequest<any NSFetchRequestResult>) -> Self {
        let request = Self()
        request.fetchRequest = fetchRequest
        return request
    }
}

open class NSPersistentHistoryResult: NSPersistentStoreResult {
    public var result: Any?
    public var resultType: NSPersistentHistoryResultType = .statusOnly
}

open class NSPersistentCloudKitContainerOptions: NSObject {
    public let containerIdentifier: String
    public init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        super.init()
    }
}

open class NSPersistentCloudKitContainer: NSPersistentContainer {
    public static let eventChangedNotification = Notification.Name("NSPersistentCloudKitContainerEventChanged")
    public static let eventNotificationUserInfoKey = "event"

    public enum EventType: Int, Hashable, Sendable {
        case setup = 0
        case `import` = 1
        case export = 2
    }

    open class Event: NSObject {
        public var identifier: UUID { UUID() }
        public var storeIdentifier: String { "" }
        public var type: EventType { .setup }
        public var startDate: Date { Date(timeIntervalSince1970: 0) }
        public var endDate: Date? { nil }
        public var succeeded: Bool { false }
        public var error: (any Error)? {
            _CDMakeError(NSPersistentStoreOperationError, "CloudKit is unavailable on Linux")
        }
    }

    public func initializeCloudKitSchema(
        options: NSPersistentCloudKitContainerSchemaInitializationOptions = []
    ) throws {
        _ = options
        throw _CDMakeError(NSPersistentStoreOperationError, "CloudKit schema initialization is unavailable on Linux")
    }

    public func canDeleteRecord(forManagedObjectWith objectID: NSManagedObjectID) -> Bool {
        _ = objectID
        return false
    }

    public func canUpdateRecord(forManagedObjectWith objectID: NSManagedObjectID) -> Bool {
        _ = objectID
        return false
    }

    public func canModifyManagedObjects(in store: NSPersistentStore) -> Bool {
        _ = store
        return false
    }
}

open class NSPersistentCloudKitContainerEventRequest: NSPersistentStoreRequest {
    public var resultType: NSPersistentCloudKitContainerEventResult.ResultType = .events

    public required override init() {
        super.init()
    }

    open class func fetchEvents(after date: Date) -> Self {
        _ = date
        return Self()
    }
    open class func fetchEvents(after event: NSPersistentCloudKitContainer.Event?) -> Self {
        _ = event
        return Self()
    }
    open class func fetchEvents(matchingFetch fetchRequest: NSFetchRequest<any NSFetchRequestResult>) -> Self {
        _ = fetchRequest
        return Self()
    }
    open class func fetchForEvents() -> NSFetchRequest<any NSFetchRequestResult> {
        NSFetchRequest<any NSFetchRequestResult>()
    }
}

open class NSPersistentCloudKitContainerEventResult: NSPersistentStoreResult {
    public enum ResultType: Int, Hashable, Sendable {
        case events = 0
        case countEvents = 1
    }
    public var result: Any?
    public var resultType: ResultType = .events
}

open class NSCoreDataCoreSpotlightDelegate: NSObject {
    public static let indexDidUpdateNotification = Notification.Name("NSCoreDataCoreSpotlightDelegateIndexDidUpdate")
    public private(set) var isIndexingEnabled: Bool = false

    public init(forStoreWith description: NSPersistentStoreDescription, coordinator psc: NSPersistentStoreCoordinator) {
        _ = (description, psc)
        super.init()
    }

    public init(forStoreWithDescription description: NSPersistentStoreDescription, coordinator psc: NSPersistentStoreCoordinator) {
        _ = (description, psc)
        super.init()
    }

    public convenience init(forStoreWith description: NSPersistentStoreDescription, model: NSManagedObjectModel) {
        self.init(
            forStoreWith: description,
            coordinator: NSPersistentStoreCoordinator(managedObjectModel: model)
        )
    }

    public convenience init(forStoreWithDescription description: NSPersistentStoreDescription, model: NSManagedObjectModel) {
        self.init(forStoreWith: description, model: model)
    }

    public func domainIdentifier() -> String { "linux.coredata.spotlight.unavailable" }
    public func indexName() -> String? { nil }
    public func startSpotlightIndexing() { isIndexingEnabled = false }
    public func stopSpotlightIndexing() { isIndexingEnabled = false }
    public func deleteSpotlightIndex(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(_CDMakeError(NSPersistentStoreOperationError, "Core Spotlight is unavailable on Linux"))
    }
}

open class NSEntityMapping: NSObject {
    public var name: String! = ""
    public var mappingType: NSEntityMappingType = .undefinedEntityMappingType
    public var sourceEntityName: String?
    public var destinationEntityName: String?
    public var sourceEntityVersionHash: Data?
    public var destinationEntityVersionHash: Data?
    public var attributeMappings: [NSPropertyMapping]?
    public var relationshipMappings: [NSPropertyMapping]?
    public var entityMigrationPolicyClassName: String?
    public var userInfo: [AnyHashable: Any]?
    // NSExpression is deprecated in swift-corelibs-foundation; omitted.
}

open class NSPropertyMapping: NSObject {
    public var name: String?
    public var userInfo: [AnyHashable: Any]?
    // NSExpression is deprecated in swift-corelibs-foundation; omitted.
}

open class NSMappingModel: NSObject {
    public var entityMappings: [NSEntityMapping]! = []
    public override init() { super.init() }
    public var entityMappingsByName: [String: NSEntityMapping] {
        var result: [String: NSEntityMapping] = [:]
        for mapping in entityMappings ?? [] {
            if let name = mapping.name {
                result[name] = mapping
            }
        }
        return result
    }

    public init?(from bundles: [Bundle]?, forSourceModel sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) {
        _ = (bundles, sourceModel, destinationModel)
        return nil
    }

    public convenience init?(
        fromBundles bundles: [Bundle]?,
        forSourceModel sourceModel: NSManagedObjectModel?,
        destinationModel: NSManagedObjectModel?
    ) {
        self.init(from: bundles, forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    public init?(contentsOf url: URL?) {
        _ = url
        return nil
    }

    public convenience init?(contentsOfURL url: URL?) {
        self.init(contentsOf: url)
    }

    open class func inferredMappingModel(
        forSourceModel sourceModel: NSManagedObjectModel,
        destinationModel: NSManagedObjectModel
    ) throws -> NSMappingModel {
        _ = (sourceModel, destinationModel)
        throw _CDMakeError(NSInferredMappingModelError, "inferred mapping models are not produced on Linux")
    }
}

open class NSMigrationManager: NSObject {
    public let sourceModel: NSManagedObjectModel
    public let destinationModel: NSManagedObjectModel
    public var mappingModel: NSMappingModel
    public var userInfo: [AnyHashable: Any]?
    public var usesStoreSpecificMigrationManager: Bool = false
    public private(set) var migrationProgress: Float = 0
    public let sourceContext: NSManagedObjectContext
    public let destinationContext: NSManagedObjectContext
    public private(set) var currentEntityMapping: NSEntityMapping = NSEntityMapping()
    private var _pairs: [(mapping: String, source: NSManagedObject, destination: NSManagedObject)] = []
    private var _cancelledError: (any Error)?

    public init(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) {
        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = NSMappingModel()
        self.sourceContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.destinationContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        super.init()
        mappingModel.entityMappings = []
    }

    public func migrateStore(
        from sourceURL: URL,
        sourceType sStoreType: String,
        options sOptions: [AnyHashable: Any]? = nil,
        with mappings: NSMappingModel?,
        toDestinationURL dURL: URL,
        destinationType dStoreType: String,
        destinationOptions dOptions: [AnyHashable: Any]? = nil
    ) throws {
        _ = (sourceURL, sStoreType, sOptions, mappings, dURL, dStoreType, dOptions)
        if let cancelled = _cancelledError {
            throw cancelled
        }
        throw _CDMakeError(NSMigrationError, "store migration is fail-closed on Linux")
    }

    public func migrateStore(
        from sourceURL: URL,
        type sourceType: NSPersistentStore.StoreType,
        options sourceOptions: [AnyHashable: Any]? = nil,
        mapping: NSMappingModel,
        to destinationURL: URL,
        type destinationType: NSPersistentStore.StoreType,
        options destinationOptions: [AnyHashable: Any]? = nil
    ) throws {
        try migrateStore(
            from: sourceURL,
            sourceType: sourceType.rawValue,
            options: sourceOptions,
            with: mapping,
            toDestinationURL: destinationURL,
            destinationType: destinationType.rawValue,
            destinationOptions: destinationOptions
        )
    }

    public func reset() {
        _pairs.removeAll()
        migrationProgress = 0
        currentEntityMapping = NSEntityMapping()
        _cancelledError = nil
    }

    public func cancelMigrationWithError(_ error: any Error) {
        _cancelledError = error
    }

    public func associate(
        sourceInstance: NSManagedObject,
        withDestinationInstance destinationInstance: NSManagedObject,
        for entityMapping: NSEntityMapping
    ) {
        currentEntityMapping = entityMapping
        let name = entityMapping.name ?? ""
        _pairs.append((name, sourceInstance, destinationInstance))
        if !_pairs.isEmpty {
            migrationProgress = 1
        }
    }

    public func destinationEntity(for mEntity: NSEntityMapping) -> NSEntityDescription? {
        destinationModel.entitiesByName[mEntity.destinationEntityName ?? ""]
    }

    public func sourceEntity(for mEntity: NSEntityMapping) -> NSEntityDescription? {
        sourceModel.entitiesByName[mEntity.sourceEntityName ?? ""]
    }

    public func destinationInstances(
        forEntityMappingName mappingName: String,
        sourceInstances: [NSManagedObject]?
    ) -> [NSManagedObject] {
        _pairs.compactMap { pair in
            if pair.mapping != mappingName { return nil }
            if let sourceInstances, !sourceInstances.contains(where: { $0 === pair.source }) {
                return nil
            }
            return pair.destination
        }
    }

    public func sourceInstances(
        forEntityMappingName mappingName: String,
        destinationInstances: [NSManagedObject]?
    ) -> [NSManagedObject] {
        _pairs.compactMap { pair in
            if pair.mapping != mappingName { return nil }
            if let destinationInstances, !destinationInstances.contains(where: { $0 === pair.destination }) {
                return nil
            }
            return pair.source
        }
    }
}

open class NSEntityMigrationPolicy: NSObject {
    open func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws { _ = (mapping, manager) }
    open func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws { _ = (sInstance, mapping, manager) }
    open func endInstanceCreation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        _ = (mapping, manager)
    }
    open func createRelationships(
        forDestination dInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws { _ = (dInstance, mapping, manager) }
    open func endRelationshipCreation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        _ = (mapping, manager)
    }
    open func performCustomValidation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        _ = (mapping, manager)
    }
    open func end(_ mapping: NSEntityMapping, manager: NSMigrationManager) throws { _ = (mapping, manager) }
}

open class NSManagedObjectModelReference: NSObject {
    public let versionChecksum: String
    public let resolvedModel: NSManagedObjectModel

    public init(model: NSManagedObjectModel, versionChecksum: String) {
        self.resolvedModel = model
        self.versionChecksum = versionChecksum
        super.init()
    }

    public init(fileURL: URL, versionChecksum: String) {
        self.resolvedModel = NSManagedObjectModel()
        self.versionChecksum = versionChecksum
        super.init()
        _ = fileURL
    }

    public init(entityVersionHashes versionHash: [AnyHashable: Any], in bundle: Bundle?, versionChecksum: String) {
        self.resolvedModel = NSManagedObjectModel()
        self.versionChecksum = versionChecksum
        super.init()
        _ = (versionHash, bundle)
    }

    public convenience init(
        entityVersionHashes versionHash: [AnyHashable: Any],
        inBundle bundle: Bundle?,
        versionChecksum: String
    ) {
        self.init(entityVersionHashes: versionHash, in: bundle, versionChecksum: versionChecksum)
    }

    public init(name modelName: String, in bundle: Bundle?, versionChecksum: String) {
        self.resolvedModel = NSManagedObjectModel()
        self.versionChecksum = versionChecksum
        super.init()
        _ = (modelName, bundle)
    }

    public convenience init(name modelName: String, inBundle bundle: Bundle?, versionChecksum: String) {
        self.init(name: modelName, in: bundle, versionChecksum: versionChecksum)
    }
}

open class NSMigrationStage: NSObject {
    public var label: String! = ""
}

open class NSCustomMigrationStage: NSMigrationStage {
    public let currentModel: NSManagedObjectModelReference
    public let nextModel: NSManagedObjectModelReference
    public var willMigrateHandler: ((NSStagedMigrationManager, NSCustomMigrationStage) throws -> Void)?
    public var didMigrateHandler: ((NSStagedMigrationManager, NSCustomMigrationStage) throws -> Void)?

    public init(
        migratingFrom currentModel: NSManagedObjectModelReference,
        to nextModel: NSManagedObjectModelReference
    ) {
        self.currentModel = currentModel
        self.nextModel = nextModel
        super.init()
    }
}

open class NSLightweightMigrationStage: NSMigrationStage {
    public let versionChecksums: [String]
    public init(_ checksums: [String]) {
        self.versionChecksums = checksums
        super.init()
    }
}

open class NSStagedMigrationManager: NSObject {
    public let stages: [NSMigrationStage]
    public var container: NSPersistentContainer?
    public init(_ stages: [NSMigrationStage]) {
        self.stages = stages
        super.init()
    }
}

open class NSAtomicStoreCacheNode: NSObject {
    public let objectID: NSManagedObjectID
    public var propertyCache: NSMutableDictionary?

    public init(objectID moid: NSManagedObjectID) {
        self.objectID = moid
        self.propertyCache = NSMutableDictionary()
        super.init()
    }

    open func value(forKey key: String) -> Any? { propertyCache?[key] }
    open func setValue(_ value: Any?, forKey key: String) {
        if let value {
            propertyCache?[key] = value
        } else {
            propertyCache?.removeObject(forKey: key)
        }
    }
}

open class NSAtomicStore: NSPersistentStore {
    var _nodes: [String: NSAtomicStoreCacheNode] = [:]

    open override var type: String { "NSAtomicStore" }

    /// Linux atomic stores keep cache nodes in process. Apple's binary on-disk
    /// layout is not decoded; `load()` succeeds as an empty node set unless a
    /// subclass restores nodes.
    open func load() throws {}

    open func save() throws {}

    open override func loadMetadata() throws {
        metadata[NSStoreTypeKey] = type
        if metadata[NSStoreUUIDKey] == nil {
            metadata[NSStoreUUIDKey] = identifier as Any
        }
        try load()
    }

    open func newCacheNode(for managedObject: NSManagedObject) -> NSAtomicStoreCacheNode {
        let node = NSAtomicStoreCacheNode(objectID: managedObject.objectID)
        updateCacheNode(node, from: managedObject)
        return node
    }

    open func newReferenceObject(for managedObject: NSManagedObject) -> Any {
        managedObject.objectID.reference
    }

    open func referenceObject(for objectID: NSManagedObjectID) -> Any { objectID.reference }

    open func objectID(for entity: NSEntityDescription, withReferenceObject data: Any) -> NSManagedObjectID {
        NSManagedObjectID(
            entity: entity,
            reference: String(describing: data),
            storeIdentifier: identifier ?? "atomic",
            isTemporary: false,
            store: self
        )
    }

    open func cacheNode(for objectID: NSManagedObjectID) -> NSAtomicStoreCacheNode? {
        _nodes[objectID.reference]
    }

    open func addCacheNodes(_ cacheNodes: Set<NSAtomicStoreCacheNode>) {
        for node in cacheNodes {
            _nodes[node.objectID.reference] = node
        }
    }

    open func willRemoveCacheNodes(_ cacheNodes: Set<NSAtomicStoreCacheNode>) {
        for node in cacheNodes {
            _nodes.removeValue(forKey: node.objectID.reference)
        }
    }

    open func updateCacheNode(_ node: NSAtomicStoreCacheNode, from managedObject: NSManagedObject) {
        let cache = node.propertyCache ?? NSMutableDictionary()
        for name in managedObject.entity.attributesByName.keys {
            if let value = managedObject.primitiveValue(forKey: name) {
                cache[name] = value
            } else {
                cache.removeObject(forKey: name)
            }
        }
        node.propertyCache = cache
    }

    open func cacheNodes() -> Set<NSAtomicStoreCacheNode> { Set(_nodes.values) }
}

open class NSIncrementalStoreNode: NSObject {
    public let objectID: NSManagedObjectID
    public private(set) var version: UInt64
    private var _values: [String: Any]

    public init(objectID: NSManagedObjectID, withValues values: [String: Any], version: UInt64) {
        self.objectID = objectID
        self._values = values
        self.version = version
        super.init()
    }

    public func update(withValues values: [String: Any], version: UInt64) {
        _values = values
        self.version = version
    }

    public func value(for prop: NSPropertyDescription) -> Any? { _values[prop.name] }
}

open class NSIncrementalStore: NSPersistentStore {
    var _nodes: [String: NSIncrementalStoreNode] = [:]
    var _relationships: [String: [String: Any]] = [:]
    var _nextReference: UInt64 = 1

    open override var type: String { "NSIncrementalStore" }

    open class func identifierForNewStore(at storeURL: URL) -> Any { storeURL.absoluteString }

    open override func loadMetadata() throws {
        metadata[NSStoreTypeKey] = type
        if metadata[NSStoreUUIDKey] == nil {
            metadata[NSStoreUUIDKey] = Self.identifierForNewStore(at: url ?? URL(string: "x-coredata-incremental://store")!)
        }
    }

    open func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        if let fetch = request as? NSFetchRequest<any NSFetchRequestResult> {
            _ = context
            let names = Set([fetch.entity?.name ?? fetch.entityName ?? ""])
            return _cdSnapshotRows(entityNames: names)
        }
        if request is NSSaveChangesRequest {
            return [] as [Any]
        }
        throw _CDMakeError(NSPersistentStoreUnsupportedRequestTypeError, "NSIncrementalStore.execute does not implement this request type")
    }

    open func newValuesForObject(
        with objectID: NSManagedObjectID,
        with context: NSManagedObjectContext
    ) throws -> NSIncrementalStoreNode {
        _ = context
        if let node = _nodes[objectID.reference] {
            return node
        }
        throw _CDMakeError(NSPersistentStoreOperationError, "NSIncrementalStore has no node for \(objectID.uriRepresentation())")
    }

    open func newValue(
        forRelationship relationship: NSRelationshipDescription,
        forObjectWith objectID: NSManagedObjectID,
        with context: NSManagedObjectContext?
    ) throws -> Any {
        _ = context
        if let value = _relationships[objectID.reference]?[relationship.name] {
            return value
        }
        return relationship.isToMany ? [] as [Any] : NSNull()
    }

    open func obtainPermanentIDs(for array: [NSManagedObject]) throws -> [NSManagedObjectID] {
        array.map { object in
            if object.objectID.isTemporaryID {
                let data = _nextReference
                _nextReference += 1
                return newObjectID(for: object.entity, referenceObject: data)
            }
            return object.objectID
        }
    }

    open func managedObjectContextDidRegisterObjects(with objectIDs: [NSManagedObjectID]) { _ = objectIDs }
    open func managedObjectContextDidUnregisterObjects(with objectIDs: [NSManagedObjectID]) { _ = objectIDs }

    open func newObjectID(for entity: NSEntityDescription, referenceObject data: Any) -> NSManagedObjectID {
        NSManagedObjectID(
            entity: entity,
            reference: String(describing: data),
            storeIdentifier: identifier ?? "incremental",
            isTemporary: false,
            store: self
        )
    }

    open func referenceObject(for objectID: NSManagedObjectID) -> Any { objectID.reference }
}

open class NSFetchRequestExpression: NSObject {
    public let isCountOnlyRequest: Bool

    public init(countOnly: Bool) {
        self.isCountOnlyRequest = countOnly
        super.init()
    }

    public init?(coder: NSCoder) {
        self.isCountOnlyRequest = false
        super.init()
        _ = coder
    }

    /// Linux stand-in: Foundation has no `NSExpression`, so this does not
    /// claim Apple's `expression(forFetch:context:countOnly:)` signature.
    open class func expression(countOnly countFlag: Bool) -> NSFetchRequestExpression {
        NSFetchRequestExpression(countOnly: countFlag)
    }
}
