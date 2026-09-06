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

@resultBuilder
public enum ResolverSpecificationBuilder<Property: _IntentValue>: Hashable, Sendable {
    public struct Specification: ResolverSpecification {
        public typealias Element = any Resolver
        public var resolvers: [any Resolver]
        public init(resolvers: [any Resolver] = []) {
            self.resolvers = resolvers
        }
        public static func == (lhs: Specification, rhs: Specification) -> Bool {
            lhs.resolvers.count == rhs.resolvers.count
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(resolvers.count)
        }
        public func makeIterator() -> IndexingIterator<[any Resolver]> {
            resolvers.makeIterator()
        }
        public func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
            try resolvers.contains(where: predicate)
        }
    }

    public static func buildExpression<ResolverType: Resolver>(
        _ expression: ResolverType
    ) -> ResolverType {
        expression
    }

    public static func buildBlock() -> Specification {
        Specification(resolvers: [])
    }

    public static func buildBlock<R0: Resolver>(_ r0: R0) -> Specification {
        Specification(resolvers: [r0])
    }

    public static func buildBlock<R0: Resolver, R1: Resolver>(_ r0: R0, _ r1: R1) -> Specification {
        Specification(resolvers: [r0, r1])
    }

    public static func buildBlock<R0: Resolver, R1: Resolver, R2: Resolver>(
        _ r0: R0, _ r1: R1, _ r2: R2
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2])
    }

    public static func buildBlock<R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3])
    }

    public static func buildBlock<R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver, R6: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6, _ r7: R7
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6, _ r7: R7, _ r8: R8
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver, R9: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5,
        _ r6: R6, _ r7: R7, _ r8: R8, _ r9: R9
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver, R9: Resolver, R10: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5,
        _ r6: R6, _ r7: R7, _ r8: R8, _ r9: R9, _ r10: R10
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver, R9: Resolver, R10: Resolver, R11: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5,
        _ r6: R6, _ r7: R7, _ r8: R8, _ r9: R9, _ r10: R10, _ r11: R11
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver, R9: Resolver, R10: Resolver, R11: Resolver,
        R12: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5,
        _ r6: R6, _ r7: R7, _ r8: R8, _ r9: R9, _ r10: R10, _ r11: R11, _ r12: R12
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver, R9: Resolver, R10: Resolver, R11: Resolver,
        R12: Resolver, R13: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5,
        _ r6: R6, _ r7: R7, _ r8: R8, _ r9: R9, _ r10: R10, _ r11: R11, _ r12: R12, _ r13: R13
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13])
    }

    public static func buildBlock<
        R0: Resolver, R1: Resolver, R2: Resolver, R3: Resolver, R4: Resolver, R5: Resolver,
        R6: Resolver, R7: Resolver, R8: Resolver, R9: Resolver, R10: Resolver, R11: Resolver,
        R12: Resolver, R13: Resolver, R14: Resolver
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6,
        _ r7: R7, _ r8: R8, _ r9: R9, _ r10: R10, _ r11: R11, _ r12: R12, _ r13: R13, _ r14: R14
    ) -> Specification {
        Specification(resolvers: [r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14])
    }
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


