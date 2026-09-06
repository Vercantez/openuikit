import Foundation

// Additional AppIntents structs from the sealed public surface.

public struct FocusFilterAppContext: @unchecked Sendable {
    public init() {}
}

public struct AttributedStringFromStringResolver: Resolver {
    public typealias Input = String
    public typealias Output = AttributedString
    public init() {}
    public func hostResolve(
        from input: String,
        context: IntentParameterContext<AttributedString>
    ) throws -> AttributedString? {
        _ = context
        return AttributedString(input)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<AttributedString>
    ) throws -> AttributedString? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<AttributedString>
    ) async throws -> AttributedString? {
        try hostResolve(from: input, context: context)
    }
}

public struct StringSearchCriteriaFromStringResolverSpecificification: Resolver {
    public typealias Input = String
    public typealias Output = StringSearchCriteria
    public init() {}
    public func hostResolve(
        from input: String,
        context: IntentParameterContext<StringSearchCriteria>
    ) throws -> StringSearchCriteria? {
        _ = input
        _ = context
        return StringSearchCriteria()
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<StringSearchCriteria>
    ) throws -> StringSearchCriteria? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<StringSearchCriteria>
    ) async throws -> StringSearchCriteria? {
        try hostResolve(from: input, context: context)
    }
}

public struct UniqueAppEntityProvider<Entity: UniqueAppEntity>: UniqueAppEntityQuery, Sendable {
    public typealias Unique = Entity
    public typealias Result = [Entity]
    public typealias DefaultValue = Entity
    public typealias Dependency = AppDependency
    private let provider: @Sendable () async throws -> Entity

    public init() {
        self.provider = { throw AppIntentError.Unrecoverable.entityNotFound }
    }

    public init(_ provider: @escaping @Sendable () async throws -> Entity) {
        self.provider = provider
    }

    public func uniqueEntity() async throws -> Entity {
        try await provider()
    }
}

public struct NegativeAppShortcutPhrase: @unchecked Sendable {
    public init() {}
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
    }
}

public struct NegativeAppShortcutPhrases: @unchecked Sendable {
    public init() {}
}

public struct AppShortcutOptionsCollection<Provider>: @unchecked Sendable {
    public init() {}
}

public struct AppShortcutParameterPresentation<Intent, Value, Parameter, ParameterKeyPath>: @unchecked Sendable {
    public init() {}
}

public struct AppShortcutParameterPresentationTitle<Intent, Value, Parameter, ParameterKeyPath>: @unchecked Sendable {
    public init() {}
}

public struct AppShortcutParameterPresentationSummary<Intent, Value, Parameter, ParameterKeyPath>: @unchecked Sendable {
    public init() {}
}

public struct AppShortcutParameterPresentationTitleString<Intent, Value, Parameter, ParameterKeyPath>: @unchecked Sendable {
    public init() {}
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
    }
}

public struct AppShortcutParameterPresentationSummaryString<Intent, Value, Parameter, ParameterKeyPath>: @unchecked Sendable {
    public init() {}
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
    }
}

public struct IntentItem<Value: _IntentValue>: @unchecked Sendable {
    public var value: Value
    public var description: DisplayRepresentation

    public init(_ value: Value) {
        self.value = value
        self.description = DisplayRepresentation(title: String(describing: value))
    }

    public init(
        _ value: Value,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        image: DisplayRepresentation.Image? = nil
    ) {
        self.value = value
        self.description = DisplayRepresentation(
            title: title,
            subtitle: subtitle,
            image: image
        )
    }

    public enum Builder: Hashable, Sendable {
        case _appIntentsPlaceholder
        public static func buildBlock(_ items: IntentItem<Value>...) -> [IntentItem<Value>] {
            items
        }
        public static func buildBlock() -> [Value] { [] }
        public static func buildArray(_ components: [[IntentItem<Value>]]) -> [IntentItem<Value>] {
            components.flatMap { $0 }
        }
        public static func buildExpression(_ expression: Value) -> IntentItem<Value> {
            IntentItem(expression)
        }
        public static func buildExpression<ExpressionValue: _IntentValue>(
            _ expression: IntentItem<ExpressionValue>
        ) -> IntentItem<ExpressionValue> {
            expression
        }
    }
}

public struct IntResolver: @unchecked Sendable {
    public init() {}
}

public struct IntentPerson: @unchecked Sendable, Hashable, _IntentValue {
    public var identifier: Identifier
    public var name: Name
    public var handle: Handle?
    public var aliases: [Handle]
    public var isMe: Bool
    public var image: DisplayRepresentation.Image?

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Person" }

    public var displayRepresentation: DisplayRepresentation {
        switch name {
        case .displayName(let display):
            return DisplayRepresentation(title: display)
        case .components, .unknown:
            return DisplayRepresentation(title: "Person")
        }
    }

    public init(
        identifier: Identifier,
        name: Name,
        handle: Handle?,
        aliases: [Handle] = [],
        isMe: Bool = false,
        image: DisplayRepresentation.Image? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.handle = handle
        self.aliases = aliases
        self.isMe = isMe
        self.image = image
    }

    public init(handle: Handle) {
        self.init(
            identifier: .unknown,
            name: .unknown,
            handle: handle
        )
    }

    public var localizedStringResource: LocalizedStringResource {
        displayRepresentation.title
    }

    public enum Identifier: Hashable, Sendable {
        case applicationDefined(String)
        case contact(String)
        case unknown
    }

    public enum ParameterMode: String, Hashable, Sendable {
        case emailOrPhone
        case email
        case phone
        case contact
    }

    public enum Name: Hashable, Sendable {
        case displayName(String)
        case components(PersonNameComponents)
        case unknown
    }

    public struct Handle: @unchecked Sendable, Hashable {
        public var label: Label
        public var value: Value

        public init(_ value: Value, label: Label = .other) {
            self.value = value
            self.label = label
        }

        public init(phoneNumber phoneNumberString: String, label: Label = .other) {
            self.init(.phoneNumber(phoneNumberString), label: label)
        }

        public init(emailAddress emailAddressString: String, label: Label = .other) {
            self.init(.emailAddress(emailAddressString), label: label)
        }

        public init(applicationDefined stringValue: String, label labelString: String? = nil) {
            self.init(
                .applicationDefined(stringValue),
                label: labelString.map { .custom($0) } ?? .other
            )
        }

        public enum Label: Hashable, Sendable {
            case home
            case main
            case work
            case other
            case pager
            case custom(String)
            case iPhone
            case mobile
            case school
            case homeFax
            case workFax
        }

        public enum Value: Hashable, Sendable {
            case phoneNumber(String)
            case emailAddress(String)
            case applicationDefined(String)
        }
    }

    public typealias ValueType = IntentPerson
    public typealias UnwrappedType = IntentPerson
}

extension IntentPerson.Identifier: Codable {
    private enum CodingKeys: String, CodingKey { case applicationDefined, contact, unknown }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .applicationDefined) {
            self = .applicationDefined(value)
        } else if let value = try container.decodeIfPresent(String.self, forKey: .contact) {
            self = .contact(value)
        } else {
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .applicationDefined(let value):
            try container.encode(value, forKey: .applicationDefined)
        case .contact(let value):
            try container.encode(value, forKey: .contact)
        case .unknown:
            try container.encode(true, forKey: .unknown)
        }
    }
}

extension IntentPerson.Name: Codable {
    private enum CodingKeys: String, CodingKey { case displayName, components, unknown }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .displayName) {
            self = .displayName(value)
        } else if let value = try container.decodeIfPresent(PersonNameComponents.self, forKey: .components) {
            self = .components(value)
        } else {
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .displayName(let value):
            try container.encode(value, forKey: .displayName)
        case .components(let value):
            try container.encode(value, forKey: .components)
        case .unknown:
            try container.encode(true, forKey: .unknown)
        }
    }
}

extension IntentPerson.Handle.Label: Codable {
    private enum CodingKeys: String, CodingKey { case named, custom }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let custom = try container.decodeIfPresent(String.self, forKey: .custom) {
            self = .custom(custom)
            return
        }
        switch try container.decode(String.self, forKey: .named) {
        case "home": self = .home
        case "main": self = .main
        case "work": self = .work
        case "pager": self = .pager
        case "iPhone": self = .iPhone
        case "mobile": self = .mobile
        case "school": self = .school
        case "homeFax": self = .homeFax
        case "workFax": self = .workFax
        default: self = .other
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .custom(let value):
            try container.encode(value, forKey: .custom)
        case .home: try container.encode("home", forKey: .named)
        case .main: try container.encode("main", forKey: .named)
        case .work: try container.encode("work", forKey: .named)
        case .other: try container.encode("other", forKey: .named)
        case .pager: try container.encode("pager", forKey: .named)
        case .iPhone: try container.encode("iPhone", forKey: .named)
        case .mobile: try container.encode("mobile", forKey: .named)
        case .school: try container.encode("school", forKey: .named)
        case .homeFax: try container.encode("homeFax", forKey: .named)
        case .workFax: try container.encode("workFax", forKey: .named)
        }
    }
}

extension IntentPerson.Handle.Value: Codable {
    private enum CodingKeys: String, CodingKey { case phoneNumber, emailAddress, applicationDefined }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .phoneNumber) {
            self = .phoneNumber(value)
        } else if let value = try container.decodeIfPresent(String.self, forKey: .emailAddress) {
            self = .emailAddress(value)
        } else {
            self = .applicationDefined(try container.decode(String.self, forKey: .applicationDefined))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .phoneNumber(let value):
            try container.encode(value, forKey: .phoneNumber)
        case .emailAddress(let value):
            try container.encode(value, forKey: .emailAddress)
        case .applicationDefined(let value):
            try container.encode(value, forKey: .applicationDefined)
        }
    }
}

extension IntentPerson.Handle: Codable {}

extension IntentPerson: Codable {
    private enum CodingKeys: String, CodingKey { case identifier, name, handle, aliases, isMe }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(Identifier.self, forKey: .identifier)
        let name = try container.decode(Name.self, forKey: .name)
        let handle = try container.decodeIfPresent(Handle.self, forKey: .handle)
        let aliases = try container.decodeIfPresent([Handle].self, forKey: .aliases) ?? []
        let isMe = try container.decodeIfPresent(Bool.self, forKey: .isMe) ?? false
        self.init(identifier: identifier, name: name, handle: handle, aliases: aliases, isMe: isMe, image: nil)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(handle, forKey: .handle)
        try container.encode(aliases, forKey: .aliases)
        try container.encode(isMe, forKey: .isMe)
    }
}

public struct DoubleResolver: @unchecked Sendable {
    public init() {}
}

#if !canImport(RelevanceKit)
public struct RelevantContext: Sendable, Hashable {
    public var score: Double
    public init(score: Double = 0) { self.score = score }
}
#endif

public struct RelevantIntent: @unchecked Sendable {
    public let widgetKind: String
    public let relevanceScore: Double
    public var debugDescription: String { "\(widgetKind):\(relevanceScore)" }

    public init() {
        self.widgetKind = ""
        self.relevanceScore = 0
    }

    public init<IntentType: WidgetConfigurationIntent>(
        _ intent: IntentType,
        widgetKind: String,
        relevance: RelevantContext
    ) {
        _ = intent
        self.widgetKind = widgetKind
        self.relevanceScore = relevance.score
    }
}

public struct EntityQuerySort<Entity>: @unchecked Sendable {
    public let by: PartialKeyPath<Entity>?
    public let order: Ordering

    public init() {
        self.by = nil
        self.order = .ascending
    }

    public init(by: PartialKeyPath<Entity>, order: Ordering = .ascending) {
        self.by = by
        self.order = order
    }

    public enum Ordering: Hashable, Sendable {
        case descending
        case ascending
    }
}

public struct EntityIdentifier: Hashable, Sendable, CustomStringConvertible, _IntentValue {
    public let entityTypeName: String
    public let identifier: String

    public var description: String { entityTypeName + "/" + identifier }

    public init<Entity: AppEntity>(for entity: Entity) {
        self.entityTypeName = String(describing: Entity.self)
        self.identifier = String(describing: entity.id)
    }

    public init<Entity: AppEntity>(for entityType: Entity.Type, identifier: Entity.ID) {
        self.entityTypeName = String(describing: entityType)
        self.identifier = String(describing: identifier)
    }

    /// Apple's activity-identifier encoding is unobserved. Linux accepts a
    /// non-empty string and stores it as the identifier with type `activity`.
    public init?(activityIdentifier: String) {
        guard !activityIdentifier.isEmpty else { return nil }
        self.entityTypeName = "activity"
        self.identifier = activityIdentifier
    }
}

public struct IntentPrediction<Intent, T>: @unchecked Sendable {
    public init() {}
}

public struct IntentItemSection<Result: _IntentValue>: @unchecked Sendable {
    public var title: LocalizedStringResource?
    public var items: [IntentItem<Result>]
    public var description: DisplayRepresentation?

    public init(items: [IntentItem<Result>]) {
        self.title = nil
        self.items = items
        self.description = nil
    }

    public init(title: LocalizedStringResource, items: [IntentItem<Result>]) {
        self.title = title
        self.items = items
        self.description = nil
    }

    public init(_ title: LocalizedStringResource, items: [IntentItem<Result>]) {
        self.init(title: title, items: items)
    }

    public init(_ title: LocalizedStringResource, items: [Result]) {
        self.init(title: title, items: items.map { IntentItem($0) })
    }

    public init(
        _ title: LocalizedStringResource? = nil,
        itemsBuilder: () -> [IntentItem<Result>]
    ) {
        self.title = title
        self.items = itemsBuilder()
        self.description = nil
    }

    public enum Builder: Hashable, Sendable {
        case _appIntentsPlaceholder
        public static func buildBlock() -> [IntentItemSection<Result>] { [] }
        public static func buildBlock(_ sections: IntentItemSection<Result>...) -> [IntentItemSection<Result>] {
            sections
        }
        public static func buildBlock(_ items: IntentItem<Result>...) -> [IntentItemSection<Result>] {
            [IntentItemSection(items: items)]
        }
    }
}

public struct IntentPaymentMethod: @unchecked Sendable, Hashable, _IntentValue {
    public var paymentType: PaymentType
    public var name: String?
    public var identificationHint: String?
    public var icon: DisplayRepresentation.Image?

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Payment Method" }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: name ?? paymentType.rawToken, image: icon)
    }

    public init() {
        self.paymentType = .unknown
        self.name = nil
        self.identificationHint = nil
        self.icon = nil
    }

    public init(
        type: PaymentType,
        name: LocalizedStringResource? = nil,
        identificationHint: String? = nil,
        icon: DisplayRepresentation.Image? = nil
    ) {
        self.paymentType = type
        self.name = name.map { appIntentsString($0) }
        self.identificationHint = identificationHint
        self.icon = icon
    }

    public enum PaymentType: Hashable, Sendable {
        case debit
        case store
        case credit
        case prepaid
        case savings
        case unknown
        case applePay
        case checking
        case brokerage

        public var rawToken: String {
            switch self {
            case .debit: return "debit"
            case .store: return "store"
            case .credit: return "credit"
            case .prepaid: return "prepaid"
            case .savings: return "savings"
            case .unknown: return "unknown"
            case .applePay: return "applePay"
            case .checking: return "checking"
            case .brokerage: return "brokerage"
            }
        }
    }
}

public struct IntentCollectionSize: @unchecked Sendable, Hashable, ExpressibleByIntegerLiteral {
    public let min: Int
    public let max: Int

    public init() {
        self.min = 0
        self.max = 0
    }

    public init(integerLiteral value: Int) {
        self.min = value
        self.max = value
    }

    public init(min: Int, max: Int) {
        self.min = min
        self.max = max
    }

    public init(exactly value: Int) {
        self.min = value
        self.max = value
    }
}

public struct IntentCurrencyAmount: @unchecked Sendable, Hashable, _IntentValue {
    public let amount: Decimal
    public let currencyCode: String

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Currency Amount" }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(amount) \(currencyCode)")
    }

    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource("\(amount) \(currencyCode)")
    }

    public init() {
        self.amount = 0
        self.currencyCode = "USD"
    }

    public init(amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }
}

public struct IntentItemCollection<Result: _IntentValue>: @unchecked Sendable {
    public var promptLabel: LocalizedStringResource?
    public var usesIndexedCollation: Bool
    public var sections: [IntentItemSection<Result>]

    public var items: [Result.ValueType] {
        var collected: [Result.ValueType] = []
        for section in sections {
            for item in section.items {
                if let value = item.value as? Result.ValueType {
                    collected.append(value)
                }
            }
        }
        return collected
    }

    public static var empty: IntentItemCollection<Result> {
        IntentItemCollection(promptLabel: nil, usesIndexedCollation: false, sections: [])
    }

    public init(
        promptLabel: LocalizedStringResource? = nil,
        usesIndexedCollation: Bool = false,
        sections: [IntentItemSection<Result>]
    ) {
        self.promptLabel = promptLabel
        self.usesIndexedCollation = usesIndexedCollation
        self.sections = sections
    }

    public init(
        promptLabel: LocalizedStringResource? = nil,
        usesIndexedCollation: Bool = false,
        items: [Result]
    ) {
        self.promptLabel = promptLabel
        self.usesIndexedCollation = usesIndexedCollation
        self.sections = [IntentItemSection(items: items.map { IntentItem($0) })]
    }

    public init(
        promptLabel: LocalizedStringResource? = nil,
        usesIndexedCollation: Bool = false,
        sectionsBuilder: () -> [IntentItemSection<Result>]
    ) {
        self.promptLabel = promptLabel
        self.usesIndexedCollation = usesIndexedCollation
        self.sections = sectionsBuilder()
    }
}

public struct StringSearchCriteria: @unchecked Sendable, _IntentValue {
    public init() {}
}

public struct DoubleFromIntResolver: Resolver {
    public typealias Input = Int
    public typealias Output = Double
    public init() {}
    public func hostResolve(
        from input: Int,
        context: IntentParameterContext<Double>
    ) throws -> Double? {
        _ = context
        return Double(input)
    }
    public func resolve(
        from input: Int,
        context: IntentParameterContext<Double>
    ) throws -> Double? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: Int,
        context: IntentParameterContext<Double>
    ) async throws -> Double? {
        try hostResolve(from: input, context: context)
    }
}

public struct IntFromDoubleResolver: Resolver {
    public typealias Input = Double
    public typealias Output = Int
    public var roundingRule: FloatingPointRoundingRule
    public init(roundingRule: FloatingPointRoundingRule = .towardZero) {
        self.roundingRule = roundingRule
    }
    public func hostResolve(
        from input: Double,
        context: IntentParameterContext<Int>
    ) throws -> Int? {
        _ = context
        return Int(input.rounded(roundingRule))
    }
    public func resolve(
        from input: Double,
        context: IntentParameterContext<Int>
    ) throws -> Int? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: Double,
        context: IntentParameterContext<Int>
    ) async throws -> Int? {
        try hostResolve(from: input, context: context)
    }
}

public struct IntFromStringResolver: Resolver {
    public typealias Input = String
    public typealias Output = Int
    public var radix: Int
    public init(radix: Int = 10) {
        self.radix = radix
    }
    public func hostResolve(
        from input: String,
        context: IntentParameterContext<Int>
    ) throws -> Int? {
        _ = context
        return Int(input, radix: radix)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<Int>
    ) throws -> Int? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<Int>
    ) async throws -> Int? {
        try hostResolve(from: input, context: context)
    }
}

public struct StringFromIntResolver<Input: _IntentValue, Output: _IntentValue>: Resolver
    where Output.ValueType == String
{
    public init() {}
    public func hostResolve(
        from input: Input,
        context: IntentParameterContext<Output>
    ) throws -> Output? {
        _ = context
        return String(describing: input) as? Output
    }
    public func resolve(
        from input: Input,
        context: IntentParameterContext<Output>
    ) throws -> Output? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: Input,
        context: IntentParameterContext<Output>
    ) async throws -> Output? {
        try hostResolve(from: input, context: context)
    }
}

public struct URLFromStringResolver: Resolver {
    public typealias Input = String
    public typealias Output = URL
    public init() {}
    public func hostResolve(
        from input: String,
        context: IntentParameterContext<URL>
    ) throws -> URL? {
        _ = context
        return URL(string: input) ?? URL(fileURLWithPath: input)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<URL>
    ) throws -> URL? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<URL>
    ) async throws -> URL? {
        try hostResolve(from: input, context: context)
    }
}

public struct BoolFromStringResolver: Resolver {
    public typealias Input = String
    public typealias Output = Bool
    public init() {}
    public func hostResolve(
        from input: String,
        context: IntentParameterContext<Bool>
    ) throws -> Bool? {
        _ = context
        switch input.lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return nil
        }
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<Bool>
    ) throws -> Bool? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<Bool>
    ) async throws -> Bool? {
        try hostResolve(from: input, context: context)
    }
}

public struct EntityQueryProperties<Entity, ComparatorMappingType>: @unchecked Sendable {
    public init() {}
}

public struct EnumURLRepresentation<Enum: AppEnum>: @unchecked Sendable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let template: String
    public let caseTemplates: [Enum: String]

    public init() {
        self.template = ""
        self.caseTemplates = [:]
    }

    public init(_ value: String) {
        self.template = value
        self.caseTemplates = [:]
    }

    public init(_ urlRepresentations: [Enum: EnumSingleURLRepresentation]) {
        self.template = ""
        var mapped: [Enum: String] = [:]
        for (key, value) in urlRepresentations {
            mapped[key] = value.template
        }
        self.caseTemplates = mapped
    }

    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: StringInterpolation) {
        self.template = stringInterpolation.value
        self.caseTemplates = [:]
    }

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public func expanded(for value: Enum, applicationName: String = "App") -> String {
        var text = caseTemplates[value] ?? template
        text = text.replacingOccurrences(of: "${applicationName}", with: applicationName)
        text = text.replacingOccurrences(of: "${rawValue}", with: String(describing: value.rawValue))
        return text
    }

    public struct EnumSingleURLRepresentation: @unchecked Sendable,
        ExpressibleByStringLiteral, ExpressibleByStringInterpolation
    {
        public let template: String
        public init() { template = "" }
        public init(stringLiteral value: String) { template = value }
        public init(stringInterpolation: StringInterpolation) {
            template = stringInterpolation.value
        }
        public typealias StringLiteralType = EnumURLRepresentation<Enum>.StringLiteralType
        public typealias StringInterpolation = EnumURLRepresentation<Enum>.StringInterpolation
        public typealias UnicodeScalarLiteralType = EnumURLRepresentation<Enum>.StringLiteralType
        public typealias ExtendedGraphemeClusterLiteralType = EnumURLRepresentation<Enum>.StringLiteralType
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value = ""
        public typealias StringLiteralType = String
        public init(literalCapacity: Int, interpolationCount: Int) {
            value.reserveCapacity(literalCapacity + interpolationCount * 12)
        }
        public mutating func appendLiteral(_ literal: String) { value += literal }
        public mutating func appendInterpolation(_ subject: Token) {
            switch subject {
            case .rawValue:
                value += "${rawValue}"
            }
        }
        public mutating func appendInterpolation(_ subject: Enum) {
            value += String(describing: subject.rawValue)
        }
        public enum Token: Hashable, Sendable {
            case rawValue
        }
    }
}

public struct TupleIntentPrediction<Intent, T>: @unchecked Sendable {
    public init() {}
}

public struct IntentParameterContext<Value: _IntentValue>: @unchecked Sendable {
    public var title: LocalizedStringResource
    public var isOptional: Bool
    public var storedDefaultUnit: Any?
    public var storedUnit: Any?
    public var storedUnitAdjustForLocale: Bool?
    public var storedSupportsNegativeNumbers: Bool?
    public var storedCurrencyCodes: [String]?
    public var storedPersonMode: IntentPerson.ParameterMode?
    public var storedPlacemarkDisplayStyle: IntentParameter<Value>.PlacemarkDisplayStyle?

    public init(title: LocalizedStringResource = LocalizedStringResource(""), isOptional: Bool = true) {
        self.title = title
        self.isOptional = isOptional
    }

    public func needsValueError(_ dialog: IntentDialog? = nil) -> AppIntentError {
        _ = dialog
        return .Unrecoverable.entityNotFound
    }

    public func needsDisambiguationError(
        among itemsToDisambiguate: [Value.ValueType],
        dialog: IntentDialog? = nil
    ) -> AppIntentError {
        _ = itemsToDisambiguate
        _ = dialog
        return .Unrecoverable.entityNotFound
    }

    /// Linux has no parameter prompt UI.
    public func requestValue(_ dialog: IntentDialog? = nil) async throws -> Value.ValueType {
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestConfirmation(
        for itemToConfirm: Value.ValueType,
        dialog: IntentDialog? = nil
    ) async throws -> Bool {
        _ = itemToConfirm
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestDisambiguation(
        among itemsToDisambiguate: [Value.ValueType],
        dialog: IntentDialog? = nil
    ) async throws -> Value.ValueType {
        _ = itemsToDisambiguate
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public var dateKind: IntentParameter<Value>.DateKind? { nil }
    public var displayStyle: IntentParameter<Value>.PlacemarkDisplayStyle? {
        storedPlacemarkDisplayStyle
    }
}

public struct ParameterSummaryString<Intent: AppIntent>: Sendable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public let evaluatedDisplayString: String

    public init() { evaluatedDisplayString = "" }
    public init(_ value: String) { evaluatedDisplayString = value }
    public init(stringLiteral value: String) { evaluatedDisplayString = value }
    public init(stringInterpolation: StringInterpolation) {
        evaluatedDisplayString = stringInterpolation.value
    }

    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value = ""

        public init() {}
        public init(literalCapacity: Int, interpolationCount: Int) {
            value.reserveCapacity(literalCapacity + interpolationCount * 12)
        }

        public mutating func appendLiteral(_ literal: String) { value += literal }

        public mutating func appendInterpolation<Value: _IntentValue>(
            _ keyPath: KeyPath<Intent, IntentParameter<Value>>
        ) {
            _ = keyPath
            value += "${parameter}"
        }

        public mutating func appendInterpolation<T>(_ other: T) {
            value += String(describing: other)
        }
    }
}

public struct EntityPropertyModifiers: @unchecked Sendable {
    public init() {}
}

public struct EntityURLRepresentation<Entity>: @unchecked Sendable {
    public init() {}
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
        public enum Token: Hashable, Sendable {
            case id
        }
    }
}

public struct IntentURLRepresentation<Intent>: @unchecked Sendable {
    public init() {}
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
    }
}

public struct AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>: @unchecked Sendable {
    public init() {}
}

public struct DoubleFromStringResolver: Resolver {
    public typealias Input = String
    public typealias Output = Double
    public init() {}
    public func hostResolve(
        from input: String,
        context: IntentParameterContext<Double>
    ) throws -> Double? {
        _ = context
        return Double(input)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<Double>
    ) throws -> Double? {
        try hostResolve(from: input, context: context)
    }
    public func resolve(
        from input: String,
        context: IntentParameterContext<Double>
    ) async throws -> Double? {
        try hostResolve(from: input, context: context)
    }
}

public struct StringFromDoubleResolver: @unchecked Sendable {
    public init() {}
}

public struct EntityQuerySortingOptions<Entity>: @unchecked Sendable {
    public init() {}
}

public struct EmptyResolverSpecification<Value>: ResolverSpecification {
    public typealias Element = any Resolver
    public init() {}
    public static func == (
        lhs: EmptyResolverSpecification<Value>,
        rhs: EmptyResolverSpecification<Value>
    ) -> Bool {
        true
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(Value.self))
    }
    public func makeIterator() -> IndexingIterator<[any Resolver]> {
        [].makeIterator()
    }
}

public struct FocusFilterSuggestionContext: @unchecked Sendable {
    public init() {}
}

public struct EntityQuerySortableByProperty<Entity>: @unchecked Sendable {
    public init() {}
}

public struct ParameterSummaryCaseCondition<Intent, Value, Summary>: _ParameterSummarySwitchCase, @unchecked Sendable {
    public var evaluatedDisplayString: String = ""
    public var matched: Value?
    public init() {}
    public init(value: Value, summary: String) {
        matched = value
        evaluatedDisplayString = summary
    }
}

public struct ParameterSummaryWhenCondition<Intent, WhenCondition, Otherwise>: @unchecked Sendable {
    public var evaluatedDisplayString: String = ""
    public init() {}
    public init(condition: Bool, then: String, otherwise: String) {
        evaluatedDisplayString = condition ? then : otherwise
    }
}

extension ParameterSummaryWhenCondition: ParameterSummary where Intent: AppIntent {}

public struct ParameterSummarySwitchCondition<Intent, Value, CaseCondition>: @unchecked Sendable {
    public var evaluatedDisplayString: String = ""
    public init() {}
    public init(evaluatedDisplayString: String) {
        self.evaluatedDisplayString = evaluatedDisplayString
    }
    public enum WidgetFamily: Hashable, Sendable {
        case widgetFamily
    }
}

extension ParameterSummarySwitchCondition: ParameterSummary where Intent: AppIntent, Value: _IntentValue, CaseCondition: _ParameterSummarySwitchCase {}

public struct ParameterSummaryTupleCaseCondition<Intent, Value, ValueType>: @unchecked Sendable {
    public init() {}
}

public struct ParameterSummaryDefaultCaseCondition<Intent, Value, Summary>: @unchecked Sendable {
    public init() {}
}

