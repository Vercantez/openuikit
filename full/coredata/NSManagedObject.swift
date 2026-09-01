import Foundation

open class NSManagedObjectID: NSObject, NSFetchRequestResult {
    public let entity: NSEntityDescription
    public internal(set) weak var persistentStore: NSPersistentStore?
    public private(set) var isTemporaryID: Bool
    let reference: String
    let storeIdentifier: String

    init(entity: NSEntityDescription, reference: String, storeIdentifier: String, isTemporary: Bool, store: NSPersistentStore?) {
        self.entity = entity
        self.reference = reference
        self.storeIdentifier = storeIdentifier
        self.isTemporaryID = isTemporary
        self.persistentStore = store
        super.init()
    }

    public func uriRepresentation() -> URL {
        let kind = isTemporaryID ? "t" : "p"
        return URL(string: "x-coredata://\(storeIdentifier)/\(entity.name ?? "Unknown")/\(kind)\(reference)")!
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(storeIdentifier)
        hasher.combine(entity.name)
        hasher.combine(reference)
        hasher.combine(isTemporaryID)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSManagedObjectID else { return false }
        return storeIdentifier == other.storeIdentifier
            && entity.name == other.entity.name
            && reference == other.reference
            && isTemporaryID == other.isTemporaryID
    }

    func promotingToPermanent(store: NSPersistentStore) -> NSManagedObjectID {
        NSManagedObjectID(
            entity: entity,
            reference: reference,
            storeIdentifier: store.identifier ?? storeIdentifier,
            isTemporary: false,
            store: store
        )
    }
}

open class NSManagedObject: NSObject, NSFetchRequestResult {
    public private(set) var entity: NSEntityDescription
    public internal(set) var objectID: NSManagedObjectID
    public internal(set) weak var managedObjectContext: NSManagedObjectContext?

    public var isInserted: Bool = false
    public var isUpdated: Bool = false
    public var isDeleted: Bool = false
    public var isFault: Bool = false
    public var faultingState: Int = 0
    public var hasChanges: Bool { isInserted || isUpdated || isDeleted || !_changedValues.isEmpty }
    public var hasPersistentChangedValues: Bool { !_committed.isEmpty && hasChanges }

    var _values: [String: Any] = [:]
    var _committed: [String: Any] = [:]
    var _changedValues: [String: Any] = [:]
    var _eventChangedValues: [String: Any] = [:]

    open class var contextShouldIgnoreUnmodeledPropertyChanges: Bool { true }

    open class func entity() -> NSEntityDescription {
        NSEntityDescription()
    }

    open class func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        let request = NSFetchRequest<any NSFetchRequestResult>()
        let entity = self.entity()
        if let name = entity.name, !name.isEmpty {
            request._entityName = name
            request.entity = entity
        } else {
            request._entityName = String(describing: self)
        }
        return request
    }

    public convenience init(context moc: NSManagedObjectContext) {
        let resolved = NSManagedObject._entity(in: moc, className: String(describing: Self.self))
            ?? Self.entity()
        self.init(entity: resolved, insertInto: moc)
    }

    public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        self.entity = entity
        let storeID = context?.persistentStoreCoordinator?.persistentStores.first?.identifier ?? "temp"
        self.objectID = NSManagedObjectID(
            entity: entity,
            reference: String(_CDIDSource.next()),
            storeIdentifier: storeID,
            isTemporary: true,
            store: context?.persistentStoreCoordinator?.persistentStores.first
        )
        super.init()
        for (name, attribute) in entity.attributesByName {
            if let value = attribute.defaultValue {
                _values[name] = value
            }
        }
        if let context {
            context.insert(self)
        }
    }

    public convenience init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        self.init(entity: entity, insertInto: context)
    }

    private static func _entity(in context: NSManagedObjectContext, className: String) -> NSEntityDescription? {
        let model = context.persistentStoreCoordinator?.managedObjectModel
            ?? context.parent?.persistentStoreCoordinator?.managedObjectModel
        guard let model else { return nil }
        if let match = model.entities.first(where: { $0.managedObjectClassName == className }) {
            return match
        }
        let short = className.split(separator: ".").last.map(String.init) ?? className
        return model.entities.first(where: {
            ($0.managedObjectClassName ?? "").hasSuffix(short) || $0.name == short
        })
    }

    public subscript(key: String) -> Any? {
        get { value(forKey: key) }
        set { setValue(newValue, forKey: key) }
    }

    open func value(forKey key: String) -> Any? {
        willAccessValue(forKey: key)
        defer { didAccessValue(forKey: key) }
        return primitiveValue(forKey: key)
    }

    open func setValue(_ value: Any?, forKey key: String) {
        willChangeValue(forKey: key)
        setPrimitiveValue(value, forKey: key)
        didChangeValue(forKey: key)
        if !isInserted {
            isUpdated = true
        }
        managedObjectContext?._noteUpdated(self)
    }

    open func primitiveValue(forKey key: String) -> Any? {
        if isFault {
            managedObjectContext?._fulfillFault(self)
        }
        return _values[key]
    }

    open func setPrimitiveValue(_ value: Any?, forKey key: String) {
        let previous = _values[key]
        if _committed[key] == nil, let previous {
            _committed[key] = previous
        }
        if let value {
            _values[key] = value
        } else {
            _values.removeValue(forKey: key)
        }
        _changedValues[key] = value as Any
        _eventChangedValues[key] = value as Any
    }

    open func willAccessValue(forKey key: String?) {
        if isFault { managedObjectContext?._fulfillFault(self) }
        _ = key
    }

    open func didAccessValue(forKey key: String?) { _ = key }
    open func willChangeValue(forKey key: String) { _ = key }
    open func didChangeValue(forKey key: String) { _ = key }

    open func awakeFromInsert() {}
    open func awakeFromFetch() {}
    open func awake(fromSnapshotEvents flags: NSSnapshotEventType) { _ = flags }
    open func prepareForDeletion() {}
    open func willSave() {}
    open func didSave() {}
    open func willTurnIntoFault() {}
    open func didTurnIntoFault() {}

    open func changedValues() -> [String: Any] { _changedValues }
    open func changedValuesForCurrentEvent() -> [String: Any] { _eventChangedValues }

    open func committedValues(forKeys keys: [String]?) -> [String: Any] {
        guard let keys else { return _committed }
        var result: [String: Any] = [:]
        for key in keys {
            if let value = _committed[key] {
                result[key] = value
            }
        }
        return result
    }

    open func hasFault(forRelationshipNamed key: String) -> Bool {
        _ = key
        return isFault
    }

    open func objectIDs(forRelationshipNamed key: String) -> [NSManagedObjectID] {
        let value = primitiveValue(forKey: key)
        if let object = value as? NSManagedObject {
            return [object.objectID]
        }
        if let objects = value as? Set<NSManagedObject> {
            return objects.map(\.objectID)
        }
        if let objects = value as? [NSManagedObject] {
            return objects.map(\.objectID)
        }
        if let ids = value as? [NSManagedObjectID] {
            return ids
        }
        return []
    }

    open func validateForInsert() throws { try _validateRequiredAttributes() }
    open func validateForUpdate() throws { try _validateRequiredAttributes() }
    open func validateForDelete() throws {
        for relationship in entity.relationshipsByName.values where relationship.deleteRule == .denyDeleteRule {
            let related = objectIDs(forRelationshipNamed: relationship.name)
            if !related.isEmpty {
                throw _CDMakeError(
                    NSValidationRelationshipDeniedDeleteError,
                    "deny delete rule blocked deletion of \(entity.name ?? "object") because \(relationship.name) is non-empty"
                )
            }
        }
    }

    private func _validateRequiredAttributes() throws {
        for (name, attribute) in entity.attributesByName where !attribute.isOptional && !attribute.isTransient {
            if primitiveValue(forKey: name) == nil && attribute.defaultValue == nil {
                throw _CDMakeError(
                    NSValidationMissingMandatoryPropertyError,
                    "missing required attribute \(name)",
                    userInfo: [NSValidationKeyErrorKey: name]
                )
            }
        }
    }

    func _clearChangeTracking() {
        _committed.removeAll()
        _changedValues.removeAll()
        _eventChangedValues.removeAll()
        isUpdated = false
    }

    func _snapshotValues() -> [String: Any] { _values }

    func _restoreSnapshot(_ values: [String: Any]) {
        _values = values
        _clearChangeTracking()
        isUpdated = false
    }
}
