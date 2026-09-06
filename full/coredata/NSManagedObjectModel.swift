import Foundation

private let _CDDetachedModel = NSManagedObjectModel()

open class NSPropertyDescription: NSObject {
    public var name: String = ""
    public var isOptional: Bool = true
    public var isTransient: Bool = false
    public var isIndexed: Bool = false
    public var isIndexedBySpotlight: Bool = false
    public var isStoredInExternalRecord: Bool = false
    public var renamingIdentifier: String?
    public var userInfo: [AnyHashable: Any]?
    public var versionHashModifier: String?
    public var validationPredicates: [NSPredicate] = []
    public var validationWarnings: [Any] = []
    weak var _entity: NSEntityDescription?

    public var entity: NSEntityDescription { _entity ?? NSEntityDescription() }

    public var versionHash: Data {
        _CDStableData([name, isOptional ? "1" : "0", isTransient ? "1" : "0"])
    }

    public override init() { super.init() }

    public init?(coder: NSCoder) {
        super.init()
    }

    public func setValidationPredicates(
        _ validationPredicates: [NSPredicate]?,
        withValidationWarnings validationWarnings: [String]?
    ) {
        self.validationPredicates = validationPredicates ?? []
        self.validationWarnings = validationWarnings ?? []
    }
}

open class NSAttributeDescription: NSPropertyDescription {
    public struct AttributeType: RawRepresentable, Hashable, Sendable {
        public var rawValue: NSAttributeType
        public init(rawValue: NSAttributeType) { self.rawValue = rawValue }
        public static let undefined = AttributeType(rawValue: .undefinedAttributeType)
        public static let integer16 = AttributeType(rawValue: .integer16AttributeType)
        public static let integer32 = AttributeType(rawValue: .integer32AttributeType)
        public static let integer64 = AttributeType(rawValue: .integer64AttributeType)
        public static let decimal = AttributeType(rawValue: .decimalAttributeType)
        public static let double = AttributeType(rawValue: .doubleAttributeType)
        public static let float = AttributeType(rawValue: .floatAttributeType)
        public static let string = AttributeType(rawValue: .stringAttributeType)
        public static let boolean = AttributeType(rawValue: .booleanAttributeType)
        public static let date = AttributeType(rawValue: .dateAttributeType)
        public static let binaryData = AttributeType(rawValue: .binaryDataAttributeType)
        public static let uuid = AttributeType(rawValue: .UUIDAttributeType)
        public static let uri = AttributeType(rawValue: .URIAttributeType)
        public static let transformable = AttributeType(rawValue: .transformableAttributeType)
        public static let objectID = AttributeType(rawValue: .objectIDAttributeType)
        public static let composite = AttributeType(rawValue: .compositeAttributeType)
    }

    public var attributeType: NSAttributeType = .undefinedAttributeType
    public var attributeValueClassName: String?
    public var defaultValue: Any?
    public var valueTransformerName: String?
    public var allowsExternalBinaryDataStorage: Bool = false
    public var allowsCloudEncryption: Bool = false
    public var preservesValueInHistoryOnDeletion: Bool = false

    public var type: AttributeType {
        get { AttributeType(rawValue: attributeType) }
        set { attributeType = newValue.rawValue }
    }

    public override var versionHash: Data {
        _CDStableData([name, "attr", String(attributeType.rawValue)])
    }
}

open class NSCompositeAttributeDescription: NSAttributeDescription {
    public var elements: [NSAttributeDescription] = []
}

open class NSDerivedAttributeDescription: NSAttributeDescription {
    // NSExpression is deprecated in swift-corelibs-foundation; omitted.
}

open class NSRelationshipDescription: NSPropertyDescription {
    public var deleteRule: NSDeleteRule = .nullifyDeleteRule
    public var maxCount: Int = 0
    public var minCount: Int = 0
    public var isOrdered: Bool = false
    weak var _destinationEntity: NSEntityDescription?
    weak var _inverseRelationship: NSRelationshipDescription?

    public var destinationEntity: NSEntityDescription? {
        get { _destinationEntity }
        set { _destinationEntity = newValue }
    }

    public var inverseRelationship: NSRelationshipDescription? {
        get { _inverseRelationship }
        set { _inverseRelationship = newValue }
    }

    public var isToMany: Bool { maxCount != 1 }

    public override var versionHash: Data {
        _CDStableData([
            name,
            "rel",
            String(deleteRule.rawValue),
            String(maxCount),
            String(minCount),
            isOrdered ? "1" : "0"
        ])
    }
}

open class NSFetchedPropertyDescription: NSPropertyDescription {
    public var fetchRequest: NSFetchRequest<any NSFetchRequestResult>?
}

open class NSExpressionDescription: NSPropertyDescription {
    // NSExpression is deprecated in swift-corelibs-foundation; omitted.
    public var expressionResultType: NSAttributeType = .undefinedAttributeType
    public var resultType: NSAttributeDescription.AttributeType {
        get { NSAttributeDescription.AttributeType(rawValue: expressionResultType) }
        set { expressionResultType = newValue.rawValue }
    }
}

open class NSFetchIndexElementDescription: NSObject {
    public var isAscending: Bool = true
    public var collationType: NSFetchIndexElementType
    public internal(set) weak var indexDescription: NSFetchIndexDescription?
    public private(set) var property: NSPropertyDescription?
    public var propertyName: String? { property?.name }

    public init(property: NSPropertyDescription, collationType: NSFetchIndexElementType) {
        self.property = property
        self.collationType = collationType
        super.init()
    }

    public init?(coder: NSCoder) {
        self.collationType = .binary
        super.init()
    }
}

open class NSFetchIndexDescription: NSObject {
    public var name: String
    public var elements: [NSFetchIndexElementDescription]
    public var partialIndexPredicate: NSPredicate?
    public internal(set) weak var entity: NSEntityDescription?

    public init(name: String, elements: [NSFetchIndexElementDescription]?) {
        self.name = name
        self.elements = elements ?? []
        super.init()
        for element in self.elements {
            element.indexDescription = self
        }
    }

    public init?(coder: NSCoder) {
        self.name = ""
        self.elements = []
        super.init()
    }
}

open class NSEntityDescription: NSObject {
    public var name: String?
    public var isAbstract: Bool = false
    public var managedObjectClassName: String! = "NSManagedObject"
    public var renamingIdentifier: String?
    public var userInfo: [AnyHashable: Any]?
    public var versionHashModifier: String?
    public var uniquenessConstraints: [[Any]] = []
    public var compoundIndexes: [[Any]] = []
    public var indexes: [NSFetchIndexDescription] = []
    public var properties: [NSPropertyDescription] = [] {
        didSet { _reindexProperties() }
    }
    public var subentities: [NSEntityDescription] = [] {
        didSet {
            for child in subentities {
                child._superentity = self
                child._model = _model
            }
        }
    }

    weak var _model: NSManagedObjectModel?
    weak var _superentity: NSEntityDescription?
    private var _propertiesByName: [String: NSPropertyDescription] = [:]

    public var managedObjectModel: NSManagedObjectModel { _model ?? _CDDetachedModel }
    public var superentity: NSEntityDescription? { _superentity }

    public var propertiesByName: [String: NSPropertyDescription] {
        var result: [String: NSPropertyDescription] = [:]
        if let superentity {
            result.merge(superentity.propertiesByName) { _, current in current }
        }
        for (key, value) in _propertiesByName {
            result[key] = value
        }
        return result
    }

    public var attributesByName: [String: NSAttributeDescription] {
        var result: [String: NSAttributeDescription] = [:]
        for (key, value) in propertiesByName {
            if let attribute = value as? NSAttributeDescription {
                result[key] = attribute
            }
        }
        return result
    }

    public var relationshipsByName: [String: NSRelationshipDescription] {
        var result: [String: NSRelationshipDescription] = [:]
        for (key, value) in propertiesByName {
            if let relationship = value as? NSRelationshipDescription {
                result[key] = relationship
            }
        }
        return result
    }

    public var subentitiesByName: [String: NSEntityDescription] {
        var result: [String: NSEntityDescription] = [:]
        for entity in subentities {
            if let name = entity.name {
                result[name] = entity
            }
        }
        return result
    }

    public var versionHash: Data {
        var parts = [name ?? "", "entity"]
        for property in properties.sorted(by: { $0.name < $1.name }) {
            parts.append(String(data: property.versionHash, encoding: .utf8) ?? property.name)
        }
        return _CDStableData(parts)
    }

    public override init() { super.init() }

    public init?(coder: NSCoder) {
        super.init()
    }

    private func _reindexProperties() {
        var map: [String: NSPropertyDescription] = [:]
        for property in properties {
            property._entity = self
            map[property.name] = property
        }
        _propertiesByName = map
        for index in indexes {
            index.entity = self
        }
    }

    public func isKindOf(entity: NSEntityDescription) -> Bool {
        if self === entity { return true }
        var current = superentity
        while let walk = current {
            if walk === entity { return true }
            current = walk.superentity
        }
        return false
    }

    public func relationships(forDestination entity: NSEntityDescription) -> [NSRelationshipDescription] {
        relationshipsByName.values.filter { $0.destinationEntity === entity }
    }

    open class func entity(forEntityName entityName: String, in context: NSManagedObjectContext) -> NSEntityDescription? {
        let model = context.persistentStoreCoordinator?.managedObjectModel
            ?? context.parent?.persistentStoreCoordinator?.managedObjectModel
        return model?.entitiesByName[entityName]
    }

    open class func insertNewObject(forEntityName entityName: String, into context: NSManagedObjectContext) -> NSManagedObject {
        guard let entity = entity(forEntityName: entityName, in: context) else {
            fatalError("CoreData: no entity named \(entityName) in the context model")
        }
        return NSManagedObject(entity: entity, insertInto: context)
    }
}

open class NSManagedObjectModel: NSObject {
    public var entities: [NSEntityDescription] = [] {
        didSet { _reindex() }
    }
    public var versionIdentifiers: Set<AnyHashable> = []
    public var localizationDictionary: [String: String]?
    private var _configurations: [String: [NSEntityDescription]] = [:]
    private var _templates: [String: NSFetchRequest<any NSFetchRequestResult>] = [:]
    private var _entitiesByName: [String: NSEntityDescription] = [:]

    public var entitiesByName: [String: NSEntityDescription] { _entitiesByName }
    public var configurations: [String] { Array(_configurations.keys).sorted() }
    public var fetchRequestTemplatesByName: [String: NSFetchRequest<any NSFetchRequestResult>] { _templates }

    public var entityVersionHashesByName: [String: Data] {
        var result: [String: Data] = [:]
        for (name, entity) in _entitiesByName {
            result[name] = entity.versionHash
        }
        return result
    }

    public var versionChecksum: String {
        var parts: [String] = []
        for name in _entitiesByName.keys.sorted() {
            parts.append(name)
            if let hash = _entitiesByName[name]?.versionHash, let text = String(data: hash, encoding: .utf8) {
                parts.append(text)
            }
        }
        return String(_CDStableData(parts).hashValue)
    }

    public override init() { super.init() }

    public init?(coder: NSCoder) {
        super.init()
    }

    public convenience init?(contentsOf url: URL) {
        self.init(contentsOfURL: url)
    }

    public convenience init?(contentsOfURL url: URL) {
        guard let loaded = _CDLoadManagedObjectModel(from: url) else {
            self.init()
            return nil
        }
        self.init()
        entities = loaded.entities
        versionIdentifiers = loaded.versionIdentifiers
        localizationDictionary = loaded.localizationDictionary
        for configuration in loaded.configurations {
            if let configured = loaded.entities(forConfigurationName: configuration) {
                setEntities(configured, forConfigurationName: configuration)
            }
        }
        _reindex()
    }

    public convenience init?(byMerging models: [NSManagedObjectModel]?) {
        self.init(byMergingModels: models)
    }

    public init?(byMergingModels models: [NSManagedObjectModel]?) {
        super.init()
        guard let models else { return nil }
        var merged: [NSEntityDescription] = []
        for model in models {
            merged.append(contentsOf: model.entities)
        }
        entities = merged
    }

    public convenience init?(byMerging models: [NSManagedObjectModel], forStoreMetadata metadata: [String: Any]) {
        self.init(byMergingModels: models, forStoreMetadata: metadata)
    }

    public convenience init?(byMergingModels models: [NSManagedObjectModel], forStoreMetadata metadata: [String: Any]) {
        self.init(byMergingModels: models)
        _ = metadata
    }

    open class func mergedModel(from bundles: [Bundle]?) -> NSManagedObjectModel? {
        _ = bundles
        return nil
    }

    open class func mergedModel(from bundles: [Bundle]?, forStoreMetadata metadata: [String: Any]) -> NSManagedObjectModel? {
        _ = (bundles, metadata)
        return nil
    }

    public func entities(forConfigurationName configuration: String?) -> [NSEntityDescription]? {
        guard let configuration else { return entities }
        return _configurations[configuration]
    }

    public func setEntities(_ entities: [NSEntityDescription], forConfigurationName configuration: String) {
        _configurations[configuration] = entities
    }

    public func fetchRequestTemplate(forName name: String) -> NSFetchRequest<any NSFetchRequestResult>? {
        _templates[name]
    }

    public func fetchRequestFromTemplate(
        withName name: String,
        substitutionVariables variables: [String: Any]
    ) -> NSFetchRequest<any NSFetchRequestResult>? {
        _ = variables
        return _templates[name]
    }

    public func setFetchRequestTemplate(
        _ fetchRequestTemplate: NSFetchRequest<any NSFetchRequestResult>?,
        forName name: String
    ) {
        _templates[name] = fetchRequestTemplate
    }

    public func isConfiguration(withName configuration: String?, compatibleWithStoreMetadata metadata: [String: Any]) -> Bool {
        let hashes = metadata[NSStoreModelVersionHashesKey] as? [String: Data]
        if hashes == nil { return true }
        return hashes == entityVersionHashesByName
    }

    private func _reindex() {
        var map: [String: NSEntityDescription] = [:]
        for entity in entities {
            entity._model = self
            if let name = entity.name {
                map[name] = entity
            }
        }
        _entitiesByName = map
    }
}
