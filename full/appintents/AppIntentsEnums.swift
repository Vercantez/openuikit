import Foundation

// Generated AppIntents enumerations from the sealed public surface.

public enum AppShortcutOptionsCollectionSpecificationBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum VideoCategory: String, Hashable, Sendable {
    case tv
    case movies
    case freeform
}

public enum StringSearchScope: String, Hashable, Sendable {
    case freeformVideo
    case tv
    case movies
    case general
}

public enum IntentWidgetFamily: Hashable, Sendable {
    case systemLarge
    case systemSmall
    case systemMedium
    case accessoryCorner
    case accessoryInline
    case systemExtraLarge
    case accessoryCircular
    case accessoryRectangular
}

public enum OneOfComparisonOperator: Hashable, Sendable {
    case oneOf
}

public enum ParameterSummaryBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum IntentPredictionsBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum StringComparisonOperator: Hashable, Sendable {
    case doesNotContain
    case contains
    case hasPrefix
    case hasSuffix
}

public enum EntityQueryComparatorMode: Hashable, Sendable {
    case or
    case and
}

public enum SetFocusFilterIntentError: Hashable, Sendable {
    case missingParameterValue
    case notFound
}

public enum HasValueComparisonOperator: Hashable, Sendable {
    case hasNoValue
    case hasAnyValue
}

public enum EquatableComparisonOperator: Hashable, Sendable {
    case notEqualTo
    case equalTo
}

public enum ParameterSummaryCaseBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum ComparableComparisonOperator: Hashable, Sendable {
    case greaterThan
    case lessThanOrEqualTo
    case greaterThanOrEqualTo
    case lessThan
}

public enum EntityQueryPropertiesBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum ResolverSpecificationBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum EntityQueryComparatorsBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

public enum EntityQuerySortingOptionsBuilder: Hashable, Sendable {
    case _appIntentsPlaceholder
}

extension VideoCategory: AppEnum {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Video Category")
    }
    public static var caseDisplayRepresentations: [VideoCategory: DisplayRepresentation] {
        [
            .tv: "TV",
            .movies: "Movies",
            .freeform: "Freeform"
        ]
    }
}

extension StringSearchScope: AppEnum {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "String Search Scope")
    }
    public static var caseDisplayRepresentations: [StringSearchScope: DisplayRepresentation] {
        [
            .freeformVideo: "Freeform Video",
            .tv: "TV",
            .movies: "Movies",
            .general: "General"
        ]
    }
}


