import Foundation

public protocol SchemaProperty: Codable, Hashable {
    var name: String { get set }
    var originalName: String { get set }
    var valueType: any Any.Type { get set }
    var isAttribute: Bool { get }
    var isOptional: Bool { get }
    var isRelationship: Bool { get }
    var isTransient: Bool { get }
    var isUnique: Bool { get }
}

public extension SchemaProperty {
    var isAttribute: Bool { false }
    var isOptional: Bool { false }
    var isRelationship: Bool { false }
    var isTransient: Bool { false }
}

public final class Schema: Hashable, Codable, CustomDebugStringConvertible, @unchecked Sendable {
    public struct Version: Comparable, Hashable, Codable, CustomStringConvertible, Sendable {
        public let major: Int
        public let minor: Int
        public let patch: Int

        public init(_ major: Int, _ minor: Int, _ patch: Int) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }

        public var description: String { "\(major).\(minor).\(patch)" }

        public static func < (lhs: Version, rhs: Version) -> Bool {
            (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
        }

        public static func == (lhs: Version, rhs: Version) -> Bool {
            lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(major)
            hasher.combine(minor)
            hasher.combine(patch)
        }

    }

    public struct PropertyMetadata: @unchecked Sendable {
        public let name: String
        public let keypath: AnyKeyPath
        public let defaultValue: Any?
        public let metadata: (any SchemaProperty)?

        public init(
            name: String,
            keypath: AnyKeyPath,
            defaultValue: Any? = nil,
            metadata: (any SchemaProperty)? = nil
        ) {
            self.name = name
            self.keypath = keypath
            self.defaultValue = defaultValue
            self.metadata = metadata
        }
    }

    public class Attribute: SchemaProperty, @unchecked Sendable {
        public struct Option: Hashable, Codable, CustomDebugStringConvertible, Sendable {
            public let name: String
            public let transformerName: String?

            public var debugDescription: String { name }

            public static var unique: Option { Option(name: "unique") }
            public static var ephemeral: Option { Option(name: "ephemeral") }
            public static var externalStorage: Option { Option(name: "externalStorage") }
            public static var spotlight: Option { Option(name: "spotlight") }
            public static var preserveValueOnDeletion: Option { Option(name: "preserveValueOnDeletion") }
            public static var allowsCloudEncryption: Option { Option(name: "allowsCloudEncryption") }

            public static func transformable(by transformerName: String) -> Option {
                Option(name: "transformable", transformerName: transformerName)
            }

            init(name: String, transformerName: String? = nil) {
                self.name = name
                self.transformerName = transformerName
            }

            public static func == (lhs: Option, rhs: Option) -> Bool {
                lhs.name == rhs.name && lhs.transformerName == rhs.transformerName
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(name)
                hasher.combine(transformerName)
            }

            }

        public var name: String
        public var originalName: String
        public var options: [Attribute.Option]
        public var valueType: any Any.Type
        public var defaultValue: Any?
        public var hashModifier: String?
        public var isOptional: Bool
        public var isAttribute: Bool { true }
        public var isRelationship: Bool { false }
        public var isTransient: Bool { options.contains(.ephemeral) }
        public var isUnique: Bool { options.contains(.unique) }
        public var isTransformable: Bool { options.contains { $0.name == "transformable" } }
        public var debugDescription: String { "Attribute(\(name))" }

        public init(
            _ options: Attribute.Option...,
            originalName: String? = nil,
            hashModifier: String? = nil
        ) {
            self.name = originalName ?? ""
            self.originalName = originalName ?? ""
            self.options = options
            self.valueType = String.self
            self.defaultValue = nil
            self.hashModifier = hashModifier
            self.isOptional = false
        }

        public init(
            name: String,
            originalName: String? = nil,
            options: [Attribute.Option] = [],
            valueType: any Any.Type,
            defaultValue: Any? = nil,
            hashModifier: String? = nil
        ) {
            self.name = name
            self.originalName = originalName ?? name
            self.options = options
            self.valueType = valueType
            self.defaultValue = defaultValue
            self.hashModifier = hashModifier
            self.isOptional = false
        }

        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            originalName = try container.decode(String.self, forKey: .originalName)
            options = try container.decode([Attribute.Option].self, forKey: .options)
            valueType = _SwiftDataTypeRegistry.type(named: try container.decode(String.self, forKey: .valueType))
            hashModifier = try container.decodeIfPresent(String.self, forKey: .hashModifier)
            isOptional = try container.decode(Bool.self, forKey: .isOptional)
            defaultValue = nil
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(originalName, forKey: .originalName)
            try container.encode(options, forKey: .options)
            try container.encode(_SwiftDataTypeRegistry.name(of: valueType), forKey: .valueType)
            try container.encodeIfPresent(hashModifier, forKey: .hashModifier)
            try container.encode(isOptional, forKey: .isOptional)
        }

        public static func == (lhs: Schema.Attribute, rhs: Schema.Attribute) -> Bool {
            lhs.name == rhs.name
                && lhs.originalName == rhs.originalName
                && lhs.options == rhs.options
                && lhs.hashModifier == rhs.hashModifier
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(originalName)
            hasher.combine(options)
            hasher.combine(hashModifier)
        }


        private enum CodingKeys: String, CodingKey {
            case name, originalName, options, valueType, hashModifier, isOptional
        }
    }

    public final class CompositeAttribute: Attribute, @unchecked Sendable {
        public var properties: [Attribute] = []

        public override var debugDescription: String { "CompositeAttribute(\(name))" }

        public override init(
            name: String,
            originalName: String? = nil,
            options: [Attribute.Option] = [],
            valueType: any Any.Type,
            defaultValue: Any? = nil,
            hashModifier: String? = nil
        ) {
            super.init(
                name: name,
                originalName: originalName,
                options: options,
                valueType: valueType,
                defaultValue: defaultValue,
                hashModifier: hashModifier
            )
        }

        public required init(from decoder: any Decoder) throws {
            try super.init(from: decoder)
        }

        public override func encode(to encoder: any Encoder) throws {
            try super.encode(to: encoder)
        }

        public static func == (lhs: CompositeAttribute, rhs: CompositeAttribute) -> Bool {
            lhs.name == rhs.name && lhs.properties == rhs.properties
        }
    }

    public final class Relationship: SchemaProperty, @unchecked Sendable {
        public enum DeleteRule: String, Codable, Sendable {
            public typealias RawValue = String
            case nullify
            case cascade
            case deny
            case noAction
        }

        public struct Option: Hashable, Codable, CustomDebugStringConvertible, Sendable {
            public let name: String
            public var debugDescription: String { name }
            public static var unique: Option { Option(name: "unique") }
            init(name: String) { self.name = name }

            public static func == (lhs: Option, rhs: Option) -> Bool {
                lhs.name == rhs.name
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(name)
            }

            }

        public var name: String
        public var originalName: String
        public var options: [Option]
        public var valueType: any Any.Type
        public var deleteRule: DeleteRule
        public var destination: String
        public var minimumModelCount: Int?
        public var maximumModelCount: Int?
        public var inverseKeyPath: AnyKeyPath?
        public var inverseName: String?
        public var keypath: AnyKeyPath?
        public var hashModifier: String?
        public var isAttribute: Bool { false }
        public var isOptional: Bool { minimumModelCount == 0 }
        public var isRelationship: Bool { true }
        public var isToOneRelationship: Bool { (maximumModelCount ?? 0) == 1 }
        public var isTransient: Bool { false }
        public var isUnique: Bool { options.contains(.unique) }
        public var debugDescription: String { "Relationship(\(name))" }

        public init(
            _ options: Option...,
            deleteRule: DeleteRule = .nullify,
            minimumModelCount: Int? = 0,
            maximumModelCount: Int? = 0,
            originalName: String? = nil,
            inverse: AnyKeyPath? = nil,
            hashModifier: String? = nil
        ) {
            self.name = originalName ?? ""
            self.originalName = originalName ?? ""
            self.options = options
            self.valueType = Any.self
            self.deleteRule = deleteRule
            self.destination = ""
            self.minimumModelCount = minimumModelCount
            self.maximumModelCount = maximumModelCount
            self.inverseKeyPath = inverse
            self.inverseName = nil
            self.keypath = nil
            self.hashModifier = hashModifier
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            originalName = try container.decode(String.self, forKey: .originalName)
            options = try container.decode([Option].self, forKey: .options)
            valueType = Any.self
            deleteRule = try container.decode(DeleteRule.self, forKey: .deleteRule)
            destination = try container.decode(String.self, forKey: .destination)
            minimumModelCount = try container.decodeIfPresent(Int.self, forKey: .minimumModelCount)
            maximumModelCount = try container.decodeIfPresent(Int.self, forKey: .maximumModelCount)
            inverseName = try container.decodeIfPresent(String.self, forKey: .inverseName)
            hashModifier = try container.decodeIfPresent(String.self, forKey: .hashModifier)
            inverseKeyPath = nil
            keypath = nil
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(originalName, forKey: .originalName)
            try container.encode(options, forKey: .options)
            try container.encode(deleteRule, forKey: .deleteRule)
            try container.encode(destination, forKey: .destination)
            try container.encodeIfPresent(minimumModelCount, forKey: .minimumModelCount)
            try container.encodeIfPresent(maximumModelCount, forKey: .maximumModelCount)
            try container.encodeIfPresent(inverseName, forKey: .inverseName)
            try container.encodeIfPresent(hashModifier, forKey: .hashModifier)
        }

        public static func == (lhs: Relationship, rhs: Relationship) -> Bool {
            lhs.name == rhs.name
                && lhs.originalName == rhs.originalName
                && lhs.deleteRule == rhs.deleteRule
                && lhs.destination == rhs.destination
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(originalName)
            hasher.combine(deleteRule)
            hasher.combine(destination)
        }


        private enum CodingKeys: String, CodingKey {
            case name, originalName, options, deleteRule, destination
            case minimumModelCount, maximumModelCount, inverseName, hashModifier
        }
    }

    public final class Entity: Hashable, Codable, CustomDebugStringConvertible, @unchecked Sendable {
        public var name: String
        public var attributes: Set<Attribute>
        public var relationships: Set<Relationship>
        public var storedProperties: [any SchemaProperty]
        public var inheritedProperties: [any SchemaProperty]
        public var subentities: Set<Entity>
        public var superentity: Entity?
        public var superentityName: String?
        public var indices: [[String]]
        public var uniquenessConstraints: [[String]]
        public var debugDescription: String { "Entity(\(name))" }

        public var attributesByName: [String: Attribute] {
            Dictionary(uniqueKeysWithValues: attributes.map { ($0.name, $0) })
        }
        public var relationshipsByName: [String: Relationship] {
            Dictionary(uniqueKeysWithValues: relationships.map { ($0.name, $0) })
        }
        public var storedPropertiesByName: [String: any SchemaProperty] {
            Dictionary(uniqueKeysWithValues: storedProperties.map { ($0.name, $0) })
        }
        public var inheritedPropertiesByName: [String: any SchemaProperty] {
            Dictionary(uniqueKeysWithValues: inheritedProperties.map { ($0.name, $0) })
        }
        public var properties: [any SchemaProperty] { storedProperties + inheritedProperties }

        public init(_ name: String) {
            self.name = name
            self.attributes = []
            self.relationships = []
            self.storedProperties = []
            self.inheritedProperties = []
            self.subentities = []
            self.superentity = nil
            self.superentityName = nil
            self.indices = []
            self.uniquenessConstraints = []
        }

        public init(_ name: String, properties: any SchemaProperty...) {
            self.name = name
            let attributes = properties.compactMap { $0 as? Attribute }
            let relationships = properties.compactMap { $0 as? Relationship }
            self.attributes = Set(attributes)
            self.relationships = Set(relationships)
            self.storedProperties = properties
            self.inheritedProperties = []
            self.subentities = []
            self.superentity = nil
            self.superentityName = nil
            self.indices = []
            self.uniquenessConstraints = []
        }

        public init(_ name: String, subentities: Entity..., properties: any SchemaProperty...) {
            self.name = name
            let attributes = properties.compactMap { $0 as? Attribute }
            let relationships = properties.compactMap { $0 as? Relationship }
            self.attributes = Set(attributes)
            self.relationships = Set(relationships)
            self.storedProperties = properties
            self.inheritedProperties = []
            self.subentities = Set(subentities)
            self.superentity = nil
            self.superentityName = nil
            self.indices = []
            self.uniquenessConstraints = []
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            let decodedAttributes = try container.decode([Attribute].self, forKey: .attributes)
            attributes = Set(decodedAttributes)
            let decodedRelationships = try container.decode([Relationship].self, forKey: .relationships)
            relationships = Set(decodedRelationships)
            storedProperties = decodedAttributes + decodedRelationships
            inheritedProperties = []
            subentities = []
            superentity = nil
            superentityName = try container.decodeIfPresent(String.self, forKey: .superentityName)
            indices = try container.decode([[String]].self, forKey: .indices)
            uniquenessConstraints = try container.decode([[String]].self, forKey: .uniquenessConstraints)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(Array(attributes), forKey: .attributes)
            try container.encode(Array(relationships), forKey: .relationships)
            try container.encodeIfPresent(superentityName, forKey: .superentityName)
            try container.encode(indices, forKey: .indices)
            try container.encode(uniquenessConstraints, forKey: .uniquenessConstraints)
        }

        public static func == (lhs: Entity, rhs: Entity) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }


        private enum CodingKeys: String, CodingKey {
            case name, attributes, relationships, superentityName, indices, uniquenessConstraints
        }
    }

    public final class Index<T: PersistentModel>: SchemaProperty, @unchecked Sendable {
        public enum CodingKeys: String, CodingKey {
            case indices

            public var stringValue: String { rawValue }
            public var intValue: Int? { nil }

            public init?(stringValue: String) {
                self.init(rawValue: stringValue)
            }

            public init?(intValue: Int) {
                _ = intValue
                return nil
            }

            public static func == (lhs: CodingKeys, rhs: CodingKeys) -> Bool {
                lhs.rawValue == rhs.rawValue
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(rawValue)
            }

            }

        public enum Types<P: PersistentModel> {
            case binary([PartialKeyPath<P>])
            case rtree([PartialKeyPath<P>])
        }

        public var name: String
        public var originalName: String
        public var valueType: any Any.Type
        public let indices: [Types<T>]
        public var isUnique: Bool { false }
        public var debugDescription: String { "Index(\(name))" }

        public init(_ binaryIndices: [PartialKeyPath<T>]...) {
            self.name = "index"
            self.originalName = "index"
            self.valueType = T.self
            self.indices = binaryIndices.map { .binary($0) }
        }

        public init(_ indices: Types<T>...) {
            self.name = "index"
            self.originalName = "index"
            self.valueType = T.self
            self.indices = indices
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            _ = try container.decode([String].self, forKey: .indices)
            self.name = "index"
            self.originalName = "index"
            self.valueType = T.self
            self.indices = []
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode([name], forKey: .indices)
        }

        public static func == (lhs: Index<T>, rhs: Index<T>) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

    }

    public final class Unique<T: PersistentModel>: SchemaProperty, @unchecked Sendable {
        public enum CodingKeys: String, CodingKey {
            case constraints

            public var stringValue: String { rawValue }
            public var intValue: Int? { nil }

            public init?(stringValue: String) {
                self.init(rawValue: stringValue)
            }

            public init?(intValue: Int) {
                _ = intValue
                return nil
            }

            public static func == (lhs: CodingKeys, rhs: CodingKeys) -> Bool {
                lhs.rawValue == rhs.rawValue
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(rawValue)
            }

            }

        public let constraints: [[PartialKeyPath<T>]]
        public var name: String
        public var originalName: String
        public var valueType: any Any.Type
        public var isUnique: Bool { true }
        public var debugDescription: String { "Unique(\(name))" }

        public init(_ constraints: [PartialKeyPath<T>]...) {
            self.constraints = constraints
            self.name = "unique"
            self.originalName = "unique"
            self.valueType = T.self
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            _ = try container.decode([String].self, forKey: .constraints)
            self.constraints = []
            self.name = "unique"
            self.originalName = "unique"
            self.valueType = T.self
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode([name], forKey: .constraints)
        }

        public static func == (lhs: Unique<T>, rhs: Unique<T>) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

    }

    public static let schemaEncodingVersion = Version(1, 0, 0)
    public let encodingVersion: Version
    public let version: Version
    public let entities: [Entity]
    public let entitiesByName: [String: Entity]
    public var debugDescription: String {
        "Schema(version: \(version), entities: \(entities.map(\.name)))"
    }

    public init() {
        self.encodingVersion = Schema.schemaEncodingVersion
        self.version = Version(1, 0, 0)
        self.entities = []
        self.entitiesByName = [:]
    }

    public convenience init(
        _ types: any PersistentModel.Type...,
        version: Version = Version(1, 0, 0)
    ) {
        self.init(Array(types), version: version)
    }

    public init(
        _ types: [any PersistentModel.Type],
        version: Version = Version(1, 0, 0)
    ) {
        self.encodingVersion = Schema.schemaEncodingVersion
        self.version = version
        let built = types.map { Entity(Schema.entityName(for: $0)) }
        self.entities = built
        self.entitiesByName = Dictionary(uniqueKeysWithValues: built.map { ($0.name, $0) })
    }

    public init(
        _ entities: Entity...,
        version: Version = Version(1, 0, 0)
    ) {
        self.encodingVersion = Schema.schemaEncodingVersion
        self.version = version
        self.entities = entities
        self.entitiesByName = Dictionary(uniqueKeysWithValues: entities.map { ($0.name, $0) })
    }

    public convenience init(versionedSchema: any VersionedSchema.Type) {
        self.init(versionedSchema.models, version: versionedSchema.versionIdentifier)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        encodingVersion = try container.decode(Version.self, forKey: .encodingVersion)
        version = try container.decode(Version.self, forKey: .version)
        entities = try container.decode([Entity].self, forKey: .entities)
        entitiesByName = Dictionary(uniqueKeysWithValues: entities.map { ($0.name, $0) })
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(encodingVersion, forKey: .encodingVersion)
        try container.encode(version, forKey: .version)
        try container.encode(entities, forKey: .entities)
    }

    public func entity<T>(for type: T.Type) -> Entity? where T: PersistentModel {
        entitiesByName[Schema.entityName(for: type)]
    }

    public static func entityName<T>(for type: T.Type) -> String where T: PersistentModel {
        String(describing: type)
    }

    public static func load(from fromURL: URL) throws -> Schema {
        let data = try Data(contentsOf: fromURL)
        return try JSONDecoder().decode(Schema.self, from: data)
    }

    public func save(to toURL: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: toURL, options: .atomic)
    }

    public static func == (lhs: Schema, rhs: Schema) -> Bool {
        lhs.version == rhs.version && lhs.entities.map(\.name) == rhs.entities.map(\.name)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(version)
        hasher.combine(entities.map(\.name))
    }


    private enum CodingKeys: String, CodingKey {
        case encodingVersion, version, entities
    }
}

enum _SwiftDataTypeRegistry {
    static func name(of type: any Any.Type) -> String {
        String(reflecting: type)
    }

    static func type(named name: String) -> any Any.Type {
        switch name {
        case String(reflecting: String.self): return String.self
        case String(reflecting: Int.self): return Int.self
        case String(reflecting: Bool.self): return Bool.self
        case String(reflecting: Double.self): return Double.self
        case String(reflecting: Date.self): return Date.self
        case String(reflecting: Data.self): return Data.self
        case String(reflecting: UUID.self): return UUID.self
        case String(reflecting: URL.self): return URL.self
        default: return String.self
        }
    }
}
