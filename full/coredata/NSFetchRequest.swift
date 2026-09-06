import Foundation

open class NSPersistentStoreRequest: NSObject {
    public var affectedStores: [NSPersistentStore]?
    open var requestType: NSPersistentStoreRequestType { .fetchRequestType }
}

open class NSPersistentStoreResult: NSObject {}

open class NSFetchRequest<ResultType>: NSPersistentStoreRequest {
    public var entity: NSEntityDescription?
    public var predicate: NSPredicate?
    public var sortDescriptors: [NSSortDescriptor]?
    public var fetchLimit: Int = 0
    public var fetchOffset: Int = 0
    public var fetchBatchSize: Int = 0
    public var includesPendingChanges: Bool = true
    public var includesPropertyValues: Bool = true
    public var includesSubentities: Bool = true
    public var returnsObjectsAsFaults: Bool = true
    public var returnsDistinctResults: Bool = false
    public var shouldRefreshRefetchedObjects: Bool = false
    public var resultType: NSFetchRequestResultType = .managedObjectResultType
    public var propertiesToFetch: [Any]?
    public var propertiesToGroupBy: [Any]?
    public var havingPredicate: NSPredicate?
    public var relationshipKeyPathsForPrefetching: [String]?
    var _entityName: String?
    weak var _boundContext: NSManagedObjectContext?

    public var entityName: String? { entity?.name ?? _entityName }

    public override init() {
        super.init()
    }

    public convenience init(entityName: String) {
        self.init()
        self._entityName = entityName
    }

    public init?(coder: NSCoder) {
        super.init()
    }

    public override var requestType: NSPersistentStoreRequestType { .fetchRequestType }

    public func execute() throws -> [ResultType] {
        guard let context = _boundContext else {
            throw _CDMakeError(NSCoreDataError, "NSFetchRequest.execute() requires a bound managed object context")
        }
        return try context.fetch(self)
    }
}

open class NSSaveChangesRequest: NSPersistentStoreRequest {
    public let insertedObjects: Set<NSManagedObject>?
    public let updatedObjects: Set<NSManagedObject>?
    public let deletedObjects: Set<NSManagedObject>?
    public let lockedObjects: Set<NSManagedObject>?

    public init(
        inserted insertedObjects: Set<NSManagedObject>?,
        updated updatedObjects: Set<NSManagedObject>?,
        deleted deletedObjects: Set<NSManagedObject>?,
        locked lockedObjects: Set<NSManagedObject>?
    ) {
        self.insertedObjects = insertedObjects
        self.updatedObjects = updatedObjects
        self.deletedObjects = deletedObjects
        self.lockedObjects = lockedObjects
        super.init()
    }

    public convenience init(
        insertedObjects: Set<NSManagedObject>?,
        updatedObjects: Set<NSManagedObject>?,
        deletedObjects: Set<NSManagedObject>?,
        lockedObjects: Set<NSManagedObject>?
    ) {
        self.init(
            inserted: insertedObjects,
            updated: updatedObjects,
            deleted: deletedObjects,
            locked: lockedObjects
        )
    }

    public override var requestType: NSPersistentStoreRequestType { .saveRequestType }
}

open class NSBatchDeleteRequest: NSPersistentStoreRequest {
    public let fetchRequest: NSFetchRequest<any NSFetchRequestResult>
    public var resultType: NSBatchDeleteRequestResultType = .resultTypeStatusOnly

    public init(fetchRequest fetch: NSFetchRequest<any NSFetchRequestResult>) {
        self.fetchRequest = fetch
        super.init()
    }

    public convenience init(objectIDs objects: [NSManagedObjectID]) {
        let fetch = NSFetchRequest<any NSFetchRequestResult>()
        fetch.resultType = .managedObjectIDResultType
        self.init(fetchRequest: fetch)
        self._objectIDs = objects
    }

    var _objectIDs: [NSManagedObjectID] = []
    public override var requestType: NSPersistentStoreRequestType { .batchDeleteRequestType }
}

open class NSBatchInsertRequest: NSPersistentStoreRequest {
    public private(set) var entity: NSEntityDescription?
    public private(set) var entityName: String = ""
    public var objectsToInsert: [[String: Any]]?
    public var dictionaryHandler: ((NSMutableDictionary) -> Bool)?
    public var managedObjectHandler: ((NSManagedObject) -> Bool)?
    public var resultType: NSBatchInsertRequestResultType = .statusOnly

    public convenience override init() {
        self.init(entityName: "", objects: [])
    }

    public init(entity: NSEntityDescription, objects dictionaries: [[String: Any]]) {
        self.entity = entity
        self.entityName = entity.name ?? ""
        self.objectsToInsert = dictionaries
        super.init()
    }

    public init(entityName: String, objects dictionaries: [[String: Any]]) {
        self.entityName = entityName
        self.objectsToInsert = dictionaries
        super.init()
    }

    public convenience init(
        entity: NSEntityDescription,
        dictionaryHandler handler: @escaping (NSMutableDictionary) -> Bool
    ) {
        self.init(entity: entity, objects: [])
        self.dictionaryHandler = handler
    }

    public convenience init(
        entity: NSEntityDescription,
        managedObjectHandler handler: @escaping (NSManagedObject) -> Bool
    ) {
        self.init(entity: entity, objects: [])
        self.managedObjectHandler = handler
    }

    public convenience init(
        entityName: String,
        dictionaryHandler handler: @escaping (NSMutableDictionary) -> Bool
    ) {
        self.init(entityName: entityName, objects: [])
        self.dictionaryHandler = handler
    }

    public convenience init(
        entityName: String,
        managedObjectHandler handler: @escaping (NSManagedObject) -> Bool
    ) {
        self.init(entityName: entityName, objects: [])
        self.managedObjectHandler = handler
    }

    public override var requestType: NSPersistentStoreRequestType { .batchInsertRequestType }
}

open class NSBatchUpdateRequest: NSPersistentStoreRequest {
    public var entity: NSEntityDescription
    public var entityName: String { entity.name ?? "" }
    public var includesSubentities: Bool = true
    public var predicate: NSPredicate?
    public var propertiesToUpdate: [AnyHashable: Any]?
    public var resultType: NSBatchUpdateRequestResultType = .statusOnlyResultType

    public init(entity: NSEntityDescription) {
        self.entity = entity
        super.init()
    }

    public init(entityName: String) {
        let entity = NSEntityDescription()
        entity.name = entityName
        self.entity = entity
        super.init()
    }

    public override var requestType: NSPersistentStoreRequestType { .batchUpdateRequestType }
}

open class NSBatchDeleteResult: NSPersistentStoreResult {
    public var result: Any?
    public var resultType: NSBatchDeleteRequestResultType = .resultTypeStatusOnly
}

open class NSBatchInsertResult: NSPersistentStoreResult {
    public var result: Any?
    public var resultType: NSBatchInsertRequestResultType = .statusOnly
}

open class NSBatchUpdateResult: NSPersistentStoreResult {
    public var result: Any?
    public var resultType: NSBatchUpdateRequestResultType = .statusOnlyResultType
}

public protocol NSFetchedResultsSectionInfo {
    var name: String { get }
    var indexTitle: String? { get }
    var numberOfObjects: Int { get }
    var objects: [Any]? { get }
}

struct _CDFetchedSection: NSFetchedResultsSectionInfo {
    var name: String
    var indexTitle: String?
    var objects: [Any]?
    var numberOfObjects: Int { objects?.count ?? 0 }
}

public protocol NSFetchedResultsControllerDelegate: NSObjectProtocol {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>)
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>)
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    )
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange sectionInfo: any NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    )
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        sectionIndexTitleForSectionName sectionName: String
    ) -> String?
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChangeContentWith diff: CollectionDifference<NSManagedObjectID>
    )
}

public extension NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {}
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {}
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {}
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange sectionInfo: any NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {}
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        sectionIndexTitleForSectionName sectionName: String
    ) -> String? { String(sectionName.prefix(1)) }
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChangeContentWith diff: CollectionDifference<NSManagedObjectID>
    ) {}
}

open class NSFetchedResultsController<ResultType>: NSObject {
    public let fetchRequest: NSFetchRequest<ResultType>
    public let managedObjectContext: NSManagedObjectContext
    public let sectionNameKeyPath: String?
    public let cacheName: String?
    public weak var delegate: (any NSFetchedResultsControllerDelegate)?
    public private(set) var fetchedObjects: [ResultType]?
    public private(set) var sections: [any NSFetchedResultsSectionInfo]?

    public var sectionIndexTitles: [String] {
        sections?.compactMap(\.indexTitle) ?? []
    }

    public init(
        fetchRequest: NSFetchRequest<ResultType>,
        managedObjectContext context: NSManagedObjectContext,
        sectionNameKeyPath: String?,
        cacheName name: String?
    ) {
        self.fetchRequest = fetchRequest
        self.managedObjectContext = context
        self.sectionNameKeyPath = sectionNameKeyPath
        self.cacheName = name
        super.init()
        context._registerFetchedResultsController(self)
    }

    open class func deleteCache(withName name: String?) { _ = name }

    public func performFetch() throws {
        let previous = fetchedObjects
        let objects = try managedObjectContext.fetch(fetchRequest)
        fetchedObjects = objects
        let previousSections = sections
        if let keyPath = sectionNameKeyPath {
            var grouped: [String: [ResultType]] = [:]
            var order: [String] = []
            for object in objects {
                let name: String
                if let managed = object as? NSManagedObject {
                    name = String(describing: managed.value(forKey: keyPath) ?? "")
                } else {
                    name = ""
                }
                if grouped[name] == nil {
                    order.append(name)
                    grouped[name] = []
                }
                grouped[name]?.append(object)
            }
            sections = order.map { name in
                _CDFetchedSection(
                    name: name,
                    indexTitle: sectionIndexTitle(forSectionName: name),
                    objects: grouped[name]
                )
            }
        } else {
            sections = [
                _CDFetchedSection(name: "", indexTitle: nil, objects: objects)
            ]
        }
        _notifyDelegateChanges(previous: previous, previousSections: previousSections, current: objects)
    }

    public func object(at indexPath: IndexPath) -> ResultType {
        if let sections, indexPath.count >= 2 {
            let section = sections[indexPath[0]]
            return section.objects?[indexPath[1]] as! ResultType
        }
        return fetchedObjects![indexPath[0]]
    }

    public func indexPath(forObject object: ResultType) -> IndexPath? {
        guard let fetchedObjects else { return nil }
        if let sections {
            for (sectionIndex, section) in sections.enumerated() {
                if let objects = section.objects {
                    for (item, candidate) in objects.enumerated() {
                        if (candidate as AnyObject) === (object as AnyObject) {
                            return IndexPath(indexes: [sectionIndex, item])
                        }
                    }
                }
            }
        }
        if let index = fetchedObjects.firstIndex(where: { ($0 as AnyObject) === (object as AnyObject) }) {
            return IndexPath(indexes: [index])
        }
        return nil
    }

    public func section(forSectionIndexTitle title: String, at sectionIndex: Int) -> Int {
        _ = title
        return sectionIndex
    }

    public func sectionIndexTitle(forSectionName sectionName: String) -> String? {
        if let untyped = _untypedController() {
            if let title = delegate?.controller(untyped, sectionIndexTitleForSectionName: sectionName) {
                return title
            }
        }
        if sectionName.isEmpty { return nil }
        return String(sectionName.prefix(1))
    }

    private func _untypedController() -> NSFetchedResultsController<any NSFetchRequestResult>? {
        self as? NSFetchedResultsController<any NSFetchRequestResult>
    }

    private func _notifyDelegateChanges(
        previous: [ResultType]?,
        previousSections: [any NSFetchedResultsSectionInfo]?,
        current: [ResultType]
    ) {
        guard previous != nil else { return }
        guard let delegate, let untyped = _untypedController() else { return }
        let oldIDs = _objectIDs(previous)
        let newIDs = _objectIDs(current)
        let oldSet = Set(oldIDs)
        let newSet = Set(newIDs)
        let deleted = oldIDs.filter { !newSet.contains($0) }
        let inserted = newIDs.filter { !oldSet.contains($0) }
        let movedOrUpdated = newIDs.filter { oldSet.contains($0) }

        // Documented FRC callback order used here: willChange, section
        // deletes/inserts, object deletes, inserts, moves, updates, didChange.
        delegate.controllerWillChangeContent(untyped)

        let oldSectionNames = previousSections?.map(\.name) ?? []
        let newSectionNames = sections?.map(\.name) ?? []
        for (index, name) in oldSectionNames.enumerated() where !newSectionNames.contains(name) {
            if let info = previousSections?[index] {
                delegate.controller(untyped, didChange: info, atSectionIndex: index, for: .delete)
            }
        }
        for (index, name) in newSectionNames.enumerated() where !oldSectionNames.contains(name) {
            if let info = sections?[index] {
                delegate.controller(untyped, didChange: info, atSectionIndex: index, for: .insert)
            }
        }

        for objectID in deleted {
            if let object = _object(with: objectID, in: previous),
               let indexPath = _indexPath(of: objectID, in: previous, sections: previousSections) {
                delegate.controller(untyped, didChange: object, at: indexPath, for: .delete, newIndexPath: nil)
            }
        }
        for objectID in inserted {
            if let object = _object(with: objectID, in: current),
               let indexPath = _indexPath(of: objectID, in: current, sections: sections) {
                delegate.controller(untyped, didChange: object, at: nil, for: .insert, newIndexPath: indexPath)
            }
        }
        for objectID in movedOrUpdated {
            let oldPath = _indexPath(of: objectID, in: previous, sections: previousSections)
            let newPath = _indexPath(of: objectID, in: current, sections: sections)
            if let object = _object(with: objectID, in: current) {
                if oldPath != newPath {
                    delegate.controller(untyped, didChange: object, at: oldPath, for: .move, newIndexPath: newPath)
                } else {
                    delegate.controller(untyped, didChange: object, at: oldPath, for: .update, newIndexPath: newPath)
                }
            }
        }
        delegate.controllerDidChangeContent(untyped)
        if previous != nil {
            let diff = newIDs.difference(from: oldIDs)
            delegate.controller(untyped, didChangeContentWith: diff)
        }
    }

    private func _objectIDs(_ objects: [ResultType]?) -> [NSManagedObjectID] {
        guard let objects else { return [] }
        return objects.compactMap { ($0 as? NSManagedObject)?.objectID }
    }

    private func _object(with objectID: NSManagedObjectID, in objects: [ResultType]?) -> Any? {
        objects?.first { ($0 as? NSManagedObject)?.objectID == objectID }
    }

    private func _indexPath(
        of objectID: NSManagedObjectID,
        in objects: [ResultType]?,
        sections: [any NSFetchedResultsSectionInfo]?
    ) -> IndexPath? {
        if let sections {
            for (sectionIndex, section) in sections.enumerated() {
                if let items = section.objects {
                    for (item, candidate) in items.enumerated() {
                        if (candidate as? NSManagedObject)?.objectID == objectID {
                            return IndexPath(indexes: [sectionIndex, item])
                        }
                    }
                }
            }
        }
        if let objects,
           let index = objects.firstIndex(where: { ($0 as? NSManagedObject)?.objectID == objectID }) {
            return IndexPath(indexes: [index])
        }
        return nil
    }
}

extension NSFetchedResultsController: _CDFetchedResultsControllerNotifying {
    func controllerDidObserveContextSave() {
        try? performFetch()
    }
}

public typealias NSPersistentStoreAsynchronousFetchResultCompletionBlock = (NSAsynchronousFetchResult<any NSFetchRequestResult>) -> Void

open class NSPersistentStoreAsynchronousResult: NSPersistentStoreResult {
    public let managedObjectContext: NSManagedObjectContext
    public var operationError: (any Error)?
    public var progress: Progress?

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }

    public func cancel() {
        operationError = _CDMakeError(NSPersistentStoreOperationError, "asynchronous fetch cancelled")
    }
}

protocol _CDAsynchronousFetchExecuting: AnyObject {
    func _cdExecute(on context: NSManagedObjectContext) throws -> NSPersistentStoreResult
}

open class NSAsynchronousFetchRequest<ResultType>: NSPersistentStoreRequest, _CDAsynchronousFetchExecuting {
    public let fetchRequest: NSFetchRequest<ResultType>
    public var estimatedResultCount: Int = 0
    public var completionBlock: NSPersistentStoreAsynchronousFetchResultCompletionBlock?
    private var _typedCompletion: ((NSAsynchronousFetchResult<ResultType>) -> Void)?
    private var _cancelled = false

    public override var requestType: NSPersistentStoreRequestType { .fetchRequestType }

    public init(
        fetchRequest request: NSFetchRequest<ResultType>,
        completionBlock blk: ((NSAsynchronousFetchResult<ResultType>) -> Void)? = nil
    ) {
        self.fetchRequest = request
        super.init()
        self._typedCompletion = blk
        if let blk {
            self.completionBlock = { boxed in
                if let typed = boxed as? NSAsynchronousFetchResult<ResultType> {
                    blk(typed)
                }
            }
        }
    }

    func _cdExecute(on context: NSManagedObjectContext) throws -> NSPersistentStoreResult {
        if _cancelled {
            let result = NSAsynchronousFetchResult(fetchRequest: self, context: context, finalResult: nil)
            result.operationError = _CDMakeError(NSPersistentStoreOperationError, "asynchronous fetch cancelled")
            return result
        }
        let objects = try context.fetch(fetchRequest)
        let result = NSAsynchronousFetchResult(fetchRequest: self, context: context, finalResult: objects)
        result.progress = Progress(totalUnitCount: Int64(objects.count))
        _typedCompletion?(result)
        return result
    }

    public func cancel() {
        _cancelled = true
    }
}

open class NSAsynchronousFetchResult<ResultType>: NSPersistentStoreAsynchronousResult {
    public let fetchRequest: NSAsynchronousFetchRequest<ResultType>
    public var finalResult: [ResultType]?

    init(
        fetchRequest: NSAsynchronousFetchRequest<ResultType>,
        context: NSManagedObjectContext,
        finalResult: [ResultType]?
    ) {
        self.fetchRequest = fetchRequest
        super.init(managedObjectContext: context)
        self.finalResult = finalResult
    }
}
