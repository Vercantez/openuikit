import Foundation

// Additional AppIntents structs from the sealed public surface.

public struct FocusFilterAppContext: @unchecked Sendable {
    public init() {}
}

public struct AttributedStringFromStringResolver: @unchecked Sendable {
    public init() {}
}

public struct StringSearchCriteriaFromStringResolverSpecificification: @unchecked Sendable {
    public init() {}
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
    public init(_ value: Value) { self.value = value }
    public enum Builder: Hashable, Sendable {
        case _appIntentsPlaceholder
        public static func buildBlock(_ items: IntentItem<Value>...) -> [IntentItem<Value>] {
            items
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
}

public struct DoubleResolver: @unchecked Sendable {
    public init() {}
}

public struct RelevantIntent: @unchecked Sendable {
    public init() {}
}

public struct EntityQuerySort<Entity>: @unchecked Sendable {
    public init() {}
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

public struct IntentPaymentMethod: @unchecked Sendable {
    public init() {}
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
    }
}

public struct IntentCollectionSize: @unchecked Sendable {
    public init() {}
}

public struct IntentCurrencyAmount: @unchecked Sendable {
    public init() {}
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

public struct StringSearchCriteria: @unchecked Sendable {
    public init() {}
}

public struct DoubleFromIntResolver: @unchecked Sendable {
    public init() {}
}

public struct EntityQueryProperties<Entity, ComparatorMappingType>: @unchecked Sendable {
    public init() {}
}

public struct EnumURLRepresentation<Enum>: @unchecked Sendable {
    public init() {}
    public struct EnumSingleURLRepresentation: @unchecked Sendable {
        public init() {}
    }
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
        public enum Token: Hashable, Sendable {
            case rawValue
        }
    }
}

public struct IntFromDoubleResolver: @unchecked Sendable {
    public init() {}
}

public struct IntFromStringResolver: @unchecked Sendable {
    public init() {}
}

public struct StringFromIntResolver<Input, Output>: @unchecked Sendable {
    public init() {}
}

public struct TupleIntentPrediction<Intent, T>: @unchecked Sendable {
    public init() {}
}

public struct URLFromStringResolver: @unchecked Sendable {
    public init() {}
}

public struct BoolFromStringResolver: @unchecked Sendable {
    public init() {}
}

public struct IntentParameterContext<Value: _IntentValue>: @unchecked Sendable {
    public var title: LocalizedStringResource
    public var isOptional: Bool

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
}

public struct ParameterSummaryString<Intent>: @unchecked Sendable {
    public init() {}
    public struct StringInterpolation: @unchecked Sendable {
        public init() {}
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

public struct DoubleFromStringResolver: @unchecked Sendable {
    public init() {}
}

public struct StringFromDoubleResolver: @unchecked Sendable {
    public init() {}
}

public struct EntityQuerySortingOptions<Entity>: @unchecked Sendable {
    public init() {}
}

public struct EmptyResolverSpecification<Value>: @unchecked Sendable {
    public init() {}
}

public struct FocusFilterSuggestionContext: @unchecked Sendable {
    public init() {}
}

public struct EntityQuerySortableByProperty<Entity>: @unchecked Sendable {
    public init() {}
}

public struct ParameterSummaryCaseCondition<Intent, Value, Summary>: @unchecked Sendable {
    public init() {}
}

public struct ParameterSummaryWhenCondition<Intent, WhenCondition, Otherwise>: @unchecked Sendable {
    public init() {}
}

public struct ParameterSummarySwitchCondition<Intent, Value, CaseCondition>: @unchecked Sendable {
    public init() {}
    public enum WidgetFamily: Hashable, Sendable {
        case widgetFamily
    }
}

public struct ParameterSummaryTupleCaseCondition<Intent, Value, ValueType>: @unchecked Sendable {
    public init() {}
}

public struct ParameterSummaryDefaultCaseCondition<Intent, Value, Summary>: @unchecked Sendable {
    public init() {}
}

