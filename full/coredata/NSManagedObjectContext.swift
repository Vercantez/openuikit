import Foundation

open class NSManagedObjectContext: NSObject, NSLocking {
    public struct ConcurrencyType: RawRepresentable, Hashable, Sendable {
        public var rawValue: NSManagedObjectContextConcurrencyType
        public init(rawValue: NSManagedObjectContextConcurrencyType) { self.rawValue = rawValue }
        public static let mainQueue = ConcurrencyType(rawValue: .mainQueueConcurrencyType)
        public static let privateQueue = ConcurrencyType(rawValue: .privateQueueConcurrencyType)
    }

    public enum NotificationKey: String, Hashable {
        case insertedObjects
        case updatedObjects
        case deletedObjects
        case refreshedObjects
        case invalidatedObjects
        case insertedObjectIDs
        case updatedObjectIDs
        case deletedObjectIDs
        case refreshedObjectIDs
        case invalidatedObjectIDs
        case invalidatedAllObjects
        case queryGeneration
    }

    public enum ScheduledTaskType: Hashable, Sendable {
        case immediate
        case enqueued
    }

    public static let didSaveObjectsNotification = Notification.Name("NSManagedObjectContextDidSaveObjectsNotification")
    public static let willSaveObjectsNotification = Notification.Name("NSManagedObjectContextWillSaveObjectsNotification")
    public static let didChangeObjectsNotification = Notification.Name("NSManagedObjectContextObjectsDidChange")
    public static let didSaveObjectIDsNotification = Notification.Name("NSManagedObjectContextDidSaveObjectIDsNotification")
    public static let didMergeChangesObjectIDsNotification = Notification.Name("NSManagedObjectContextDidMergeChangesObjectIDsNotification")

    public let concurrencyType: NSManagedObjectContextConcurrencyType
    public var name: String?
    public var transactionAuthor: String?
    public var automaticallyMergesChangesFromParent: Bool = false
    public var propagatesDeletesAtEndOfEvent: Bool = true
    public var retainsRegisteredObjects: Bool = false
    public var shouldDeleteInaccessibleFaults: Bool = true
    public var stalenessInterval: TimeInterval = -1
    public var mergePolicy: Any = NSMergePolicy.error
    public let userInfo = NSMutableDictionary()
    public private(set) var queryGenerationToken: NSQueryGenerationToken?

    public weak var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    public weak var parent: NSManagedObjectContext? {
        didSet {
            if let parent {
                persistentStoreCoordinator = parent.persistentStoreCoordinator
            }
        }
    }

    private let _lock = NSRecursiveLock()
    private let _queue: DispatchQueue
    private let _queueKey = DispatchSpecificKey<UInt8>()
    private var _inserted: [ObjectIdentifier: NSManagedObject] = [:]
    private var _updated: [ObjectIdentifier: NSManagedObject] = [:]
    private var _deleted: [ObjectIdentifier: NSManagedObject] = [:]
    private var _registered: [String: NSManagedObject] = [:]

    public var insertedObjects: Set<NSManagedObject> { Set(_inserted.values) }
    public var updatedObjects: Set<NSManagedObject> { Set(_updated.values) }
    public var deletedObjects: Set<NSManagedObject> { Set(_deleted.values) }
    public var registeredObjects: Set<NSManagedObject> { Set(_registered.values) }
    public var hasChanges: Bool { !_inserted.isEmpty || !_updated.isEmpty || !_deleted.isEmpty }

    public convenience override init() {
        self.init(concurrencyType: .mainQueueConcurrencyType)
    }

    public class func new() -> Self {
        Self(concurrencyType: .mainQueueConcurrencyType)
    }

    public required init(concurrencyType ct: NSManagedObjectContextConcurrencyType) {
        self.concurrencyType = ct
        if ct == .mainQueueConcurrencyType {
            self._queue = DispatchQueue.main
        } else {
            self._queue = DispatchQueue(label: "coredata.nsmanagedobjectcontext.\(UUID().uuidString)")
        }
        super.init()
        _queue.setSpecific(key: _queueKey, value: 1)
    }

    public convenience init(_ type: ConcurrencyType) {
        self.init(concurrencyType: type.rawValue)
    }

    public init?(coder: NSCoder) {
        self.concurrencyType = .mainQueueConcurrencyType
        self._queue = DispatchQueue.main
        super.init()
        _queue.setSpecific(key: _queueKey, value: 1)
    }

    public func lock() { _lock.lock() }
    public func unlock() { _lock.unlock() }
    public func tryLock() -> Bool { _lock.try() }

    public func perform(_ block: @escaping () -> Void) {
        _enqueue {
            block()
        }
    }

    public func performAndWait(_ block: () -> Void) {
        _runImmediate(block)
    }

    public func performAndWait<T>(_ block: () throws -> T) rethrows -> T {
        try _runImmediate(block)
    }

    public func perform<T>(
        schedule: ScheduledTaskType = .immediate,
        _ block: @escaping () throws -> T
    ) async throws -> T {
        if schedule == .immediate, _isOnContextQueue() {
            return try _runConfined(block)
        }
        return try await _performEnqueued(block)
    }

    private func _isOnContextQueue() -> Bool {
        if DispatchQueue.getSpecific(key: _queueKey) != nil {
            return true
        }
        return concurrencyType == .mainQueueConcurrencyType && Thread.isMainThread
    }

    private func _runConfined<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }

    private func _runImmediate<T>(_ block: () throws -> T) rethrows -> T {
        if _isOnContextQueue() {
            return try _runConfined(block)
        }
        return try _queue.sync {
            try self._runConfined(block)
        }
    }

    private func _enqueue(_ block: @escaping () -> Void) {
        _queue.async { [weak self] in
            guard let self else { return }
            self._runConfined(block)
        }
    }

    private func _performEnqueued<T>(_ block: @escaping () throws -> T) async throws -> T {
        let result: Result<T, Error> = await withCheckedContinuation { continuation in
            self._queue.async {
                continuation.resume(returning: Result { try self._runConfined(block) })
            }
        }
        return try _cdUnwrapResult(result)
    }

    private func _withContextLock<T>(_ block: () throws -> T) rethrows -> T {
        try _runImmediate(block)
    }

    public func insert(_ object: NSManagedObject) {
        lock()
        defer { unlock() }
        object.managedObjectContext = self
        object.isInserted = true
        object.isFault = false
        _inserted[ObjectIdentifier(object)] = object
        _registered[object.objectID.uriRepresentation().absoluteString] = object
        object.awakeFromInsert()
        _postChange()
    }

    public func delete(_ object: NSManagedObject) {
        lock()
        defer { unlock() }
        object.prepareForDeletion()
        object.isDeleted = true
        _deleted[ObjectIdentifier(object)] = object
        _inserted.removeValue(forKey: ObjectIdentifier(object))
        _updated.removeValue(forKey: ObjectIdentifier(object))
        _postChange()
    }

    func _noteUpdated(_ object: NSManagedObject) {
        _syncUpdated(object)
    }

    func _syncUpdated(_ object: NSManagedObject) {
        lock()
        defer { unlock() }
        if object.isInserted || object.isDeleted {
            return
        }
        if object._changedValues.isEmpty {
            object.isUpdated = false
            _updated.removeValue(forKey: ObjectIdentifier(object))
        } else {
            object.isUpdated = true
            _updated[ObjectIdentifier(object)] = object
        }
    }

    public func assign(_ object: Any, to store: NSPersistentStore) {
        guard let managed = object as? NSManagedObject else { return }
        managed.objectID.persistentStore = store
    }

    public func object(with objectID: NSManagedObjectID) -> NSManagedObject {
        if let existing = registeredObject(for: objectID) {
            return existing
        }
        let object = NSManagedObject(entity: objectID.entity, insertInto: nil)
        object.objectID = objectID
        object.managedObjectContext = self
        object.isFault = true
        _registered[objectID.uriRepresentation().absoluteString] = object
        return object
    }

    public func registeredObject(for objectID: NSManagedObjectID) -> NSManagedObject? {
        _registered[objectID.uriRepresentation().absoluteString]
    }

    public func existingObject(with objectID: NSManagedObjectID) throws -> NSManagedObject {
        if let existing = registeredObject(for: objectID), !existing.isFault {
            return existing
        }
        let materialized = object(with: objectID)
        _fulfillFault(materialized)
        if materialized.isFault && !_storeContains(objectID) && !materialized.isInserted {
            throw _CDMakeError(NSManagedObjectReferentialIntegrityError, "object ID is not in any attached store")
        }
        return materialized
    }

    public func detectConflicts(for object: NSManagedObject) { _ = object }

    public func obtainPermanentIDs(for objects: [NSManagedObject]) throws {
        for object in objects where object.objectID.isTemporaryID {
            let store = object.objectID.persistentStore
                ?? persistentStoreCoordinator?.persistentStores.first
            guard let store else {
                throw _CDMakeError(NSPersistentStoreOperationError, "no persistent store available to assign a permanent ID")
            }
            let permanent = object.objectID.promotingToPermanent(store: store)
            let oldKey = object.objectID.uriRepresentation().absoluteString
            object.objectID = permanent
            _registered.removeValue(forKey: oldKey)
            _registered[permanent.uriRepresentation().absoluteString] = object
        }
    }

    public func processPendingChanges() {
        _eventReset()
        _postChange()
    }

    public func refreshAllObjects() {
        for object in _registered.values where !object.isInserted {
            refresh(object, mergeChanges: false)
        }
    }

    public func refresh(_ object: NSManagedObject, mergeChanges flag: Bool) {
        if flag { return }
        object.willTurnIntoFault()
        object.isFault = true
        object.didTurnIntoFault()
    }

    public func reset() {
        lock()
        defer { unlock() }
        _inserted.removeAll()
        _updated.removeAll()
        _deleted.removeAll()
        _registered.removeAll()
    }

    public func rollback() {
        lock()
        defer { unlock() }
        for object in _inserted.values {
            object.isInserted = false
            object.managedObjectContext = nil
            _registered.removeValue(forKey: object.objectID.uriRepresentation().absoluteString)
        }
        for object in _updated.values {
            object._restoreFromCommitted()
        }
        for object in _deleted.values {
            object._restoreFromCommitted()
            object.isDeleted = false
        }
        _inserted.removeAll()
        _updated.removeAll()
        _deleted.removeAll()
    }

    public func undo() {}
    public func redo() {}

    public func save() throws {
        try _withContextLock {
            NotificationCenter.default.post(name: Self.willSaveObjectsNotification, object: self)
            for object in insertedObjects { try object.validateForInsert(); object.willSave() }
            for object in updatedObjects { try object.validateForUpdate(); object.willSave() }
            for object in deletedObjects { try object.validateForDelete(); object.willSave() }

            try obtainPermanentIDs(for: Array(insertedObjects))

            if let parent {
                try _pushToParent(parent)
            } else {
                try _pushToStore()
            }

            for object in insertedObjects { object.isInserted = false; object.didSave(); object._clearChangeTracking() }
            for object in updatedObjects { object.didSave(); object._clearChangeTracking() }
            for object in deletedObjects {
                object.didSave()
                object.managedObjectContext = nil
                _registered.removeValue(forKey: object.objectID.uriRepresentation().absoluteString)
            }
            let inserted = insertedObjects
            let updated = updatedObjects
            let deleted = deletedObjects
            _inserted.removeAll()
            _updated.removeAll()
            _deleted.removeAll()
            NotificationCenter.default.post(
                name: Self.didSaveObjectsNotification,
                object: self,
                userInfo: [
                    NSInsertedObjectsKey: inserted,
                    NSUpdatedObjectsKey: updated,
                    NSDeletedObjectsKey: deleted
                ]
            )
        }
    }

    public func execute(_ request: NSPersistentStoreRequest) throws -> NSPersistentStoreResult {
        if let fetchRequest = request as? NSFetchRequest<any NSFetchRequestResult> {
            _ = try self.fetch(fetchRequest)
            return NSPersistentStoreResult()
        }
        if let delete = request as? NSBatchDeleteRequest {
            return try _executeBatchDelete(delete)
        }
        if let insert = request as? NSBatchInsertRequest {
            return try _executeBatchInsert(insert)
        }
        if let update = request as? NSBatchUpdateRequest {
            return try _executeBatchUpdate(update)
        }
        throw _CDMakeError(NSPersistentStoreUnsupportedRequestTypeError, "unsupported persistent store request")
    }

    public func count(for request: NSFetchRequest<any NSFetchRequestResult>) throws -> Int {
        try fetch(request).count
    }

    public func count<T>(for request: NSFetchRequest<T>) throws -> Int {
        try fetch(request).count
    }

    public func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T] {
        let untyped = NSFetchRequest<any NSFetchRequestResult>()
        untyped.entity = request.entity
        untyped._entityName = request.entityName ?? request._entityName
        untyped.predicate = request.predicate
        untyped.sortDescriptors = request.sortDescriptors
        untyped.fetchLimit = request.fetchLimit
        untyped.fetchOffset = request.fetchOffset
        untyped.fetchBatchSize = request.fetchBatchSize
        untyped.includesPendingChanges = request.includesPendingChanges
        untyped.includesSubentities = request.includesSubentities
        untyped.includesPropertyValues = request.includesPropertyValues
        untyped.returnsObjectsAsFaults = request.returnsObjectsAsFaults
        untyped.returnsDistinctResults = request.returnsDistinctResults
        untyped.shouldRefreshRefetchedObjects = request.shouldRefreshRefetchedObjects
        untyped.resultType = request.resultType
        untyped.propertiesToFetch = request.propertiesToFetch
        untyped.affectedStores = request.affectedStores
        let boxed = try fetch(untyped)
        return boxed.compactMap { $0 as? T }
    }

    public func fetch(_ request: NSFetchRequest<any NSFetchRequestResult>) throws -> [Any] {
        try _withContextLock {
            request._boundContext = self
            let entity = try _entity(for: request)
            var objects: [NSManagedObject] = []

            if let coordinator = persistentStoreCoordinator {
                let rows = coordinator._fetchRows(
                    entityName: entity.name ?? "",
                    stores: request.affectedStores,
                    includesSubentities: request.includesSubentities
                )
                for row in rows {
                    objects.append(_materialize(row: row, entity: entity, asFault: request.returnsObjectsAsFaults))
                }
            }

            if request.includesPendingChanges {
                for object in insertedObjects where _matchesEntity(object, entity, includesSubentities: request.includesSubentities) {
                    objects.append(object)
                }
                objects.removeAll { deletedObjects.contains($0) }
            }

            if let predicate = request.predicate {
                objects = objects.filter { predicate.evaluate(with: $0) }
            }

            if let descriptors = request.sortDescriptors, !descriptors.isEmpty {
                objects.sort { lhs, rhs in
                    for descriptor in descriptors {
                        let order = descriptor.compare(lhs, to: rhs)
                        if order == .orderedAscending { return true }
                        if order == .orderedDescending { return false }
                    }
                    return false
                }
            }

            if request.fetchOffset > 0 {
                objects = Array(objects.dropFirst(min(request.fetchOffset, objects.count)))
            }
            if request.fetchLimit > 0, objects.count > request.fetchLimit {
                objects = Array(objects.prefix(request.fetchLimit))
            }

            switch request.resultType {
            case .countResultType:
                return [NSNumber(value: objects.count)]
            case .managedObjectIDResultType:
                return objects.map(\.objectID)
            case .dictionaryResultType:
                return objects.map { object -> NSDictionary in
                    let keys = request.propertiesToFetch as? [String] ?? Array(object.entity.attributesByName.keys)
                    var dict: [String: Any] = [:]
                    for key in keys {
                        dict[key] = object.value(forKey: key) as Any
                    }
                    return dict as NSDictionary
                }
            default:
                return objects
            }
        }
    }

    public func mergeChanges(fromContextDidSave notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let inserted = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for object in inserted {
                _ = self.object(with: object.objectID)
            }
        }
        if let updated = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for object in updated {
                refresh(object, mergeChanges: true)
            }
        }
        if let deleted = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
            for object in deleted {
                if let registered = registeredObject(for: object.objectID) {
                    refresh(registered, mergeChanges: false)
                }
            }
        }
    }

    open class func mergeChanges(
        fromRemoteContextSave changeNotificationData: [AnyHashable: Any],
        into contexts: [NSManagedObjectContext]
    ) {
        for context in contexts {
            context.mergeChanges(
                fromContextDidSave: Notification(
                    name: didSaveObjectsNotification,
                    object: nil,
                    userInfo: changeNotificationData as [AnyHashable: Any]
                )
            )
        }
    }

    public func setQueryGenerationFrom(_ generation: NSQueryGenerationToken?) throws {
        queryGenerationToken = generation
    }

    public func shouldHandleInaccessibleFault(
        _ fault: NSManagedObject,
        for oid: NSManagedObjectID,
        triggeredByProperty property: NSPropertyDescription?
    ) -> Bool {
        _ = (fault, oid, property)
        return shouldDeleteInaccessibleFaults
    }

    public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [String: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        _ = (keyPath, object, change, context)
    }

    func _fulfillFault(_ object: NSManagedObject) {
        guard object.isFault else { return }
        if let row = persistentStoreCoordinator?._row(for: object.objectID) {
            object._loadPersistentValues(row.values)
            object.awakeFromFetch()
        }
    }

    private func _entity(for request: NSFetchRequest<any NSFetchRequestResult>) throws -> NSEntityDescription {
        if let entity = request.entity { return entity }
        if let name = request.entityName ?? request._entityName,
           let entity = persistentStoreCoordinator?.managedObjectModel.entitiesByName[name] {
            request.entity = entity
            return entity
        }
        throw _CDMakeError(NSCoreDataError, "fetch request has no entity")
    }

    private func _matchesEntity(_ object: NSManagedObject, _ entity: NSEntityDescription, includesSubentities: Bool) -> Bool {
        if object.entity === entity { return true }
        if includesSubentities { return object.entity.isKindOf(entity: entity) }
        return object.entity.name == entity.name
    }

    private func _materialize(row: _CDStoredRow, entity: NSEntityDescription, asFault: Bool) -> NSManagedObject {
        let store = persistentStoreCoordinator?.persistentStores.first
        let objectID = NSManagedObjectID(
            entity: entity,
            reference: row.reference,
            storeIdentifier: store?.identifier ?? "memory",
            isTemporary: false,
            store: store
        )
        if let existing = registeredObject(for: objectID) {
            if !asFault {
                existing._loadPersistentValues(row.values)
            }
            return existing
        }
        let object = NSManagedObject(entity: entity, insertInto: nil)
        object.objectID = objectID
        object.managedObjectContext = self
        object._loadPersistentValues(row.values)
        object.isFault = asFault
        object.isInserted = false
        _registered[objectID.uriRepresentation().absoluteString] = object
        if !asFault { object.awakeFromFetch() }
        return object
    }

    private func _storeContains(_ objectID: NSManagedObjectID) -> Bool {
        persistentStoreCoordinator?._row(for: objectID) != nil
    }

    private func _pushToParent(_ parent: NSManagedObjectContext) throws {
        let inserts = Array(insertedObjects)
        let updates = Array(updatedObjects)
        let deletes = Array(deletedObjects)
        parent.performAndWait {
            for object in inserts {
                self._applyChildInsert(object, into: parent)
            }
            for object in updates {
                self._applyChildUpdate(object, into: parent)
            }
            for object in deletes {
                self._applyChildDelete(object, into: parent)
            }
        }
    }

    private func _applyChildInsert(_ object: NSManagedObject, into parent: NSManagedObjectContext) {
        if let existing = parent.registeredObject(for: object.objectID) {
            _copyAttributeSnapshot(from: object, into: existing, trackChanges: true)
            return
        }
        let clone = NSManagedObject(entity: object.entity, insertInto: nil)
        clone.objectID = object.objectID
        _copyAttributeSnapshot(from: object, into: clone, trackChanges: false)
        parent.insert(clone)
    }

    private func _applyChildUpdate(_ object: NSManagedObject, into parent: NSManagedObjectContext) {
        let target: NSManagedObject
        if let existing = parent.registeredObject(for: object.objectID) {
            target = existing
            if target.isFault {
                parent._fulfillFault(target)
            }
        } else {
            target = parent.object(with: object.objectID)
            if target.isFault {
                parent._fulfillFault(target)
            }
        }
        _copyAttributeSnapshot(from: object, into: target, trackChanges: true)
    }

    private func _applyChildDelete(_ object: NSManagedObject, into parent: NSManagedObjectContext) {
        parent.delete(parent.object(with: object.objectID))
    }

    private func _copyAttributeSnapshot(
        from object: NSManagedObject,
        into target: NSManagedObject,
        trackChanges: Bool
    ) {
        var snapshot: [String: Any] = [:]
        for name in object.entity.attributesByName.keys {
            snapshot[name] = _CDBox(object.primitiveValue(forKey: name))
        }
        target._applyBoxedSnapshot(snapshot, trackChanges: trackChanges)
    }

    private func _pushToStore() throws {
        guard let coordinator = persistentStoreCoordinator else {
            throw _CDMakeError(NSPersistentStoreOperationError, "context has no persistent store coordinator")
        }
        try coordinator._save(
            inserted: Array(insertedObjects),
            updated: Array(updatedObjects),
            deleted: Array(deletedObjects)
        )
    }

    private func _executeBatchDelete(_ request: NSBatchDeleteRequest) throws -> NSBatchDeleteResult {
        let fetch = request.fetchRequest
        fetch.resultType = .managedObjectResultType
        let objects = try self.fetch(fetch) as? [NSManagedObject] ?? []
        for object in objects { delete(object) }
        try save()
        let result = NSBatchDeleteResult()
        result.resultType = request.resultType
        switch request.resultType {
        case .resultTypeCount:
            result.result = objects.count
        case .resultTypeObjectIDs:
            result.result = objects.map(\.objectID)
        default:
            result.result = true
        }
        return result
    }

    private func _executeBatchInsert(_ request: NSBatchInsertRequest) throws -> NSBatchInsertResult {
        guard let entity = request.entity
            ?? persistentStoreCoordinator?.managedObjectModel.entitiesByName[request.entityName] else {
            throw _CDMakeError(NSCoreDataError, "batch insert is missing an entity")
        }
        var inserted: [NSManagedObject] = []
        if let dictionaries = request.objectsToInsert {
            for dictionary in dictionaries {
                let object = NSManagedObject(entity: entity, insertInto: self)
                for (key, value) in dictionary {
                    object.setValue(value, forKey: key)
                }
                inserted.append(object)
            }
        }
        try save()
        let result = NSBatchInsertResult()
        result.resultType = request.resultType
        switch request.resultType {
        case .count:
            result.result = inserted.count
        case .objectIDs:
            result.result = inserted.map(\.objectID)
        default:
            result.result = true
        }
        return result
    }

    private func _executeBatchUpdate(_ request: NSBatchUpdateRequest) throws -> NSBatchUpdateResult {
        let fetch = NSFetchRequest<NSManagedObject>()
        fetch.entity = request.entity
        fetch.predicate = request.predicate
        fetch.includesSubentities = request.includesSubentities
        let objects = try self.fetch(fetch)
        if let updates = request.propertiesToUpdate {
            for object in objects {
                for (key, value) in updates {
                    if let name = key as? String {
                        object.setValue(value, forKey: name)
                    }
                }
            }
        }
        try save()
        let result = NSBatchUpdateResult()
        result.resultType = request.resultType
        switch request.resultType {
        case .updatedObjectsCountResultType:
            result.result = objects.count
        case .updatedObjectIDsResultType:
            result.result = objects.map(\.objectID)
        default:
            result.result = true
        }
        return result
    }

    private func _postChange() {
        NotificationCenter.default.post(
            name: Self.didChangeObjectsNotification,
            object: self,
            userInfo: [
                NSInsertedObjectsKey: insertedObjects,
                NSUpdatedObjectsKey: updatedObjects,
                NSDeletedObjectsKey: deletedObjects
            ]
        )
    }

    private func _eventReset() {
        for object in _registered.values {
            object._eventChangedValues.removeAll()
        }
    }
}

private func _cdUnwrapResult<T>(_ result: Result<T, Error>) throws -> T {
    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        throw error
    }
}

extension Notification.Name {
    public static let NSManagedObjectContextDidSave = NSManagedObjectContext.didSaveObjectsNotification
    public static let NSManagedObjectContextWillSave = NSManagedObjectContext.willSaveObjectsNotification
    public static let NSManagedObjectContextObjectsDidChange = NSManagedObjectContext.didChangeObjectsNotification
    public static let NSManagedObjectContextDidSaveObjectIDs = NSManagedObjectContext.didSaveObjectIDsNotification
    public static let NSManagedObjectContextDidMergeChangesObjectIDs = NSManagedObjectContext.didMergeChangesObjectIDsNotification
    public static let NSPersistentStoreCoordinatorStoresDidChange = Notification.Name("NSPersistentStoreCoordinatorStoresDidChange")
    public static let NSPersistentStoreCoordinatorStoresWillChange = Notification.Name("NSPersistentStoreCoordinatorStoresWillChange")
    public static let NSPersistentStoreCoordinatorWillRemoveStore = Notification.Name("NSPersistentStoreCoordinatorWillRemoveStore")
    public static let NSPersistentStoreDidImportUbiquitousContentChanges = Notification.Name("NSPersistentStoreDidImportUbiquitousContentChanges")
    public static let NSPersistentStoreRemoteChange = Notification.Name("NSPersistentStoreRemoteChange")
}
