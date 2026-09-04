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

public struct UniqueAppEntityProvider<Entity>: @unchecked Sendable {
    public init() {}
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

public struct IntentItem<Value>: @unchecked Sendable {
    public init() {}
    public enum Builder: Hashable, Sendable {
        case _appIntentsPlaceholder
    }
}

public struct IntResolver: @unchecked Sendable {
    public init() {}
}

public struct IntentPerson: @unchecked Sendable {
    public init() {}
    public enum Identifier: Hashable, Sendable {
        case `applicationDefined(_:)`
        case `contact(_:)`
        case unknown
    }
    public enum ParameterMode: Hashable, Sendable {
        case emailOrPhone
        case email
        case phone
        case contact
    }
    public enum Name: Hashable, Sendable {
        case `displayName(_:)`
        case `components(_:)`
        case unknown
    }
    public struct Handle: @unchecked Sendable {
        public init() {}
        public enum Label: Hashable, Sendable {
            case home
            case main
            case work
            case other
            case pager
            case `custom(_:)`
            case iPhone
            case mobile
            case school
            case homeFax
            case workFax
        }
        public enum Value: Hashable, Sendable {
            case `phoneNumber(_:)`
            case `emailAddress(_:)`
            case `applicationDefined(_:)`
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

public struct EntityIdentifier: @unchecked Sendable {
    public init() {}
}

public struct IntentPrediction<Intent, T>: @unchecked Sendable {
    public init() {}
}

public struct IntentItemSection<Result>: @unchecked Sendable {
    public init() {}
    public enum Builder: Hashable, Sendable {
        case _appIntentsPlaceholder
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

public struct IntentItemCollection<Result>: @unchecked Sendable {
    public init() {}
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

public struct IntentParameterContext<Value>: @unchecked Sendable {
    public init() {}
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

