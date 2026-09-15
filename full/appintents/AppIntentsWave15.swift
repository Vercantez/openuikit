import Foundation

// Wave 15: portable in-process entity-query comparison and container models.
//
// Everything below runs in-process on Linux. Comparators store mapping
// transforms and attached resolver specifications as metadata; no query
// daemon, Spotlight index, or Siri service ever sees them. Containers
// (properties, sorting options) store their declarations in arrays and
// vend them back by index. Two deliberate deviations from Apple's spelling
// are documented inline:
// - `withResolvers` takes a plain closure. Apple's spelling applies
//   `@ResolverSpecificationBuilder<PropertyType.UnwrappedType>` to the
//   parameter, but the host toolchain rejects result-builder attributes
//   whose generic arguments mention enclosing generic parameters.
// - `EntityQueryProperty` initializers and the properties/content
//   initializers likewise take plain closures for the same reason.
// Behavior is unchanged: resolver specifications and comparator lists are
// attached as metadata and never consulted.

// MARK: - Equality comparators

extension EqualToComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Equatable, PropertyType: Sendable {
    public convenience init(mappingTransform: @escaping (PropertyType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (PropertyType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension NotEqualToComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Equatable, PropertyType: Sendable {
    public convenience init(mappingTransform: @escaping (PropertyType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (PropertyType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

// MARK: - Ordering comparators

extension LessThanComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
    public var mappingTransform: ((PropertyType.UnwrappedType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((PropertyType.UnwrappedType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
    public convenience init(
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension GreaterThanComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
    public var mappingTransform: ((PropertyType.UnwrappedType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((PropertyType.UnwrappedType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
    public convenience init(
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension LessThanOrEqualToComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable, PropertyType.UnwrappedType: Comparable {
    public var mappingTransform: ((PropertyType.UnwrappedType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((PropertyType.UnwrappedType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
    public convenience init(
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension GreaterThanOrEqualToComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable, PropertyType.UnwrappedType: Comparable {
    public var mappingTransform: ((PropertyType.UnwrappedType) -> ComparatorMappingType)? {
        get { hostMappingTransform as? ((PropertyType.UnwrappedType) -> ComparatorMappingType) }
        set { hostMappingTransform = newValue }
    }
    public convenience init(
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (PropertyType.UnwrappedType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

// MARK: - Between comparator

extension IsBetweenComparator
where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable, InputType: Comparable, InputType == PropertyType.UnwrappedType {
    public convenience init(mappingTransform: @escaping (InputType, InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType, InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

// MARK: - String comparators (EntityProperty overloads)

extension ContainsComparator
where Property: EntityProperty<String>, PropertyType == String, InputType == String {
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension ContainsComparator
where Property: EntityProperty<AttributedString>, PropertyType == AttributedString, InputType == AttributedString {
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension HasPrefixComparator
where Property: EntityProperty<String>, PropertyType == String, InputType == String {
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

extension HasSuffixComparator
where Property: EntityProperty<String>, PropertyType == String, InputType == String {
    public convenience init(mappingTransform: @escaping (InputType) -> ComparatorMappingType) {
        self.init()
        self.mappingTransform = mappingTransform
    }
    public convenience init<Spec: ResolverSpecification>(
        withResolvers resolvers: @escaping () -> Spec,
        mappingTransform: @escaping (InputType) -> ComparatorMappingType
    ) {
        self.init()
        self.mappingTransform = mappingTransform
        hostResolverSpecification = resolvers()
    }
}

// MARK: - Entity query properties

extension EntityQueryPropertyDeclaration {
    public convenience init(hostKeyPathDescription: String) {
        self.init()
        self.hostKeyPathDescription = hostKeyPathDescription
    }
}

extension EntityQueryProperty
where Entity: AppEntity, Subject: AppEntity, Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
    public convenience init(
        _ keyPath: KeyPath<Subject, Property>,
        comparators: () -> [AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>]
    ) where Entity == Subject {
        self.init()
        hostKeyPathDescription = String(describing: keyPath)
        hostComparators = comparators()
    }
    public convenience init(
        _ keyPath: KeyPath<Subject, Property>,
        entityProvider: @escaping (Entity) -> Subject,
        comparators: () -> [AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>]
    ) {
        self.init()
        hostKeyPathDescription = String(describing: keyPath)
        hostEntityProvider = entityProvider
        hostComparators = comparators()
    }
    /// Links this property to its declaration for in-process container storage.
    public func hostDeclaration() -> EntityQueryPropertyDeclaration<Entity, ComparatorMappingType> {
        EntityQueryPropertyDeclaration(hostKeyPathDescription: hostKeyPathDescription)
    }
}

extension EntityQueryProperties {
    public init(
        properties: () -> [EntityQueryPropertyDeclaration<Entity, ComparatorMappingType>]
    ) {
        self.init()
        hostDeclarations = properties()
    }
    public subscript(index: Int) -> EntityQueryPropertyDeclaration<Entity, ComparatorMappingType> {
        hostDeclarations[index]
    }
}

extension EntityQuerySortingOptions {
    public init(content: () -> [EntityQuerySortableByProperty<Entity>]) {
        self.init()
        hostSorting = content()
    }
    public subscript(index: Int) -> EntityQuerySortableByProperty<Entity> {
        hostSorting[index]
    }
}

extension EntityQuerySortableByProperty where Entity: AppEntity {
    public init<Property: AnyIntentValue>(_ keyPath: KeyPath<Entity, Property>) {
        self.init()
        hostKeyPath = keyPath
    }
}

// MARK: - Type-erased comparators

extension AnyEntityQueryComparator {
    public init<InputType: _IntentValue>(
        erasingContains comparator: ContainsComparator<Property, PropertyType, InputType, ComparatorMappingType>
    ) where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
        self.init()
        hostKind = "contains"
        _ = comparator
    }
    public init<InputType>(
        erasingIsBetween comparator: IsBetweenComparator<Property, PropertyType, InputType, ComparatorMappingType>
    ) where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable, InputType: Comparable, InputType == PropertyType.UnwrappedType {
        self.init()
        hostKind = "isBetween"
        _ = comparator
    }
    public init<InputType>(
        erasingEntityQuery comparator: EntityQueryComparator<Property, PropertyType, InputType, ComparatorMappingType>
    ) where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
        self.init()
        hostKind = "entityQuery"
        _ = comparator
    }
}

// MARK: - Results collections

extension ResultsCollection {
    public var promptLabel: LocalizedStringResource? { nil }
    public var usesIndexedCollation: Bool { false }
}

extension Array where Element: _IntentValue {
    public var promptLabel: LocalizedStringResource? { nil }
    public var usesIndexedCollation: Bool { false }
    public static var empty: [Element] { [] }
    /// Host-local projection of elements to their value type. Elements that do
    /// not project (for example `nil` optionals) are omitted; nothing is sent
    /// to a query daemon.
    public var items: [Element.ValueType] { compactMap { $0 as? Element.ValueType } }
}

// MARK: - Scalar intent-value aliases

extension Optional where Wrapped: _IntentValue {
    public typealias ValueType = Wrapped.ValueType
    public typealias UnwrappedType = Wrapped.UnwrappedType
}

extension Set: _IntentValue where Element: _IntentValue {
    public typealias ValueType = Element
    public typealias UnwrappedType = Set<Element>
}

// MARK: - Identifier coding

extension DisplayRepresentation.Image: Codable {}

extension FileEntityIdentifier: Codable {
    private enum CodingKeys: String, CodingKey {
        case url
        case draftIdentifier
    }
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let urlString = try container.decode(String.self, forKey: .url)
        let draft = try container.decodeIfPresent(String.self, forKey: .draftIdentifier)
        if let draft, !draft.isEmpty {
            self = FileEntityIdentifier.draft(identifier: draft)
        } else {
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "FileEntityIdentifier has an invalid URL string"
                    )
                )
            }
            self = FileEntityIdentifier(url)
        }
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url.absoluteString, forKey: .url)
        try container.encodeIfPresent(draftIdentifier, forKey: .draftIdentifier)
    }
    /// The file URL this identifier names. The host model always carries one.
    public var fileURL: URL? { url }
}

extension IntentDonationIdentifier: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(String.self))
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
