import Foundation

// Generated AppIntents enumerations from the sealed public surface.

@resultBuilder
public enum AppShortcutOptionsCollectionSpecificationBuilder<Value: _IntentValue>: Hashable, Sendable {
    case _appIntentsPlaceholder

    public struct Specification<SpecValue: _IntentValue>: @unchecked Sendable, AppShortcutOptionsCollectionSpecification {
        public typealias Value = SpecValue
        public typealias Element = any AppShortcutOptionsCollectionProtocol
        public var collections: [any AppShortcutOptionsCollectionProtocol]
        public init(collections: [any AppShortcutOptionsCollectionProtocol] = []) {
            self.collections = collections
        }
        public func makeIterator() -> IndexingIterator<[any AppShortcutOptionsCollectionProtocol]> {
            collections.makeIterator()
        }
    }

    public static func buildBlock<C0: AppShortcutOptionsCollectionProtocol>(_ c0: C0) -> Specification<Value> {
        Specification(collections: [c0])
    }

    public static func buildBlock<C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol>(
        _ c0: C0, _ c1: C1
    ) -> Specification<Value> {
        Specification(collections: [c0, c1])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2) -> Specification<Value> {
        Specification(collections: [c0, c1, c2])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol, C9: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol, C9: AppShortcutOptionsCollectionProtocol,
        C10: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9, _ c10: C10) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol, C9: AppShortcutOptionsCollectionProtocol,
        C10: AppShortcutOptionsCollectionProtocol, C11: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9, _ c10: C10, _ c11: C11) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol, C9: AppShortcutOptionsCollectionProtocol,
        C10: AppShortcutOptionsCollectionProtocol, C11: AppShortcutOptionsCollectionProtocol,
        C12: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9, _ c10: C10, _ c11: C11, _ c12: C12) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol, C9: AppShortcutOptionsCollectionProtocol,
        C10: AppShortcutOptionsCollectionProtocol, C11: AppShortcutOptionsCollectionProtocol,
        C12: AppShortcutOptionsCollectionProtocol, C13: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9, _ c10: C10, _ c11: C11, _ c12: C12, _ c13: C13) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13])
    }

    public static func buildBlock<
        C0: AppShortcutOptionsCollectionProtocol, C1: AppShortcutOptionsCollectionProtocol,
        C2: AppShortcutOptionsCollectionProtocol, C3: AppShortcutOptionsCollectionProtocol,
        C4: AppShortcutOptionsCollectionProtocol, C5: AppShortcutOptionsCollectionProtocol,
        C6: AppShortcutOptionsCollectionProtocol, C7: AppShortcutOptionsCollectionProtocol,
        C8: AppShortcutOptionsCollectionProtocol, C9: AppShortcutOptionsCollectionProtocol,
        C10: AppShortcutOptionsCollectionProtocol, C11: AppShortcutOptionsCollectionProtocol,
        C12: AppShortcutOptionsCollectionProtocol, C13: AppShortcutOptionsCollectionProtocol,
        C14: AppShortcutOptionsCollectionProtocol
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9, _ c10: C10, _ c11: C11, _ c12: C12, _ c13: C13, _ c14: C14) -> Specification<Value> {
        Specification(collections: [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14])
    }
}

public enum VideoCategory: String, Hashable, Sendable, CaseIterable {
    case tv
    case movies
    case freeform
}

public enum StringSearchScope: String, Hashable, Sendable, CaseIterable {
    case freeformVideo
    case tv
    case movies
    case general
}

public enum IntentWidgetFamily: Hashable, Sendable, _IntentValue {
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

extension ParameterSummaryBuilder {
    /// Identity combination. Linux never matches a Siri case.
    public static func buildBlock<Intent: AppIntent, Summary: ParameterSummary>(
        _ summary: Summary
    ) -> Summary where Summary.Intent == Intent {
        summary
    }
    public static func buildExpression<Intent: AppIntent, Summary: ParameterSummary>(
        _ summary: Summary
    ) -> Summary where Summary.Intent == Intent {
        summary
    }
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

public enum EntityQueryPropertiesBuilder<Entity, ComparatorMappingType>: Hashable, Sendable {
    case _appIntentsPlaceholder
    /// Count-preserving in-process combination. Nothing is indexed.
    public static func buildBlock(
        _ declarations: EntityQueryPropertyDeclaration<Entity, ComparatorMappingType>...
    ) -> [EntityQueryPropertyDeclaration<Entity, ComparatorMappingType>] {
        declarations
    }
    public static func buildExpression(
        _ declaration: EntityQueryPropertyDeclaration<Entity, ComparatorMappingType>
    ) -> EntityQueryPropertyDeclaration<Entity, ComparatorMappingType> {
        declaration
    }
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

public enum EntityQueryComparatorsBuilder<Entity, Subject, Property, PropertyType, ComparatorMappingType>: Hashable, Sendable {
    case _appIntentsPlaceholder
    /// Type-erasing in-process combination. Nothing is sent to a query daemon.
    public static func buildExpression<InputType: _IntentValue>(
        _ comparator: ContainsComparator<Property, PropertyType, InputType, ComparatorMappingType>
    ) -> AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>
    where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
        AnyEntityQueryComparator(erasingContains: comparator)
    }
    public static func buildExpression<InputType>(
        _ comparator: IsBetweenComparator<Property, PropertyType, InputType, ComparatorMappingType>
    ) -> AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>
    where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable,
        InputType: Comparable, InputType == PropertyType.UnwrappedType {
        AnyEntityQueryComparator(erasingIsBetween: comparator)
    }
    public static func buildExpression<InputType: _IntentValue>(
        _ comparator: EntityQueryComparator<Property, PropertyType, InputType, ComparatorMappingType>
    ) -> AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>
    where Property: EntityProperty<PropertyType>, PropertyType: _IntentValue, PropertyType: Sendable {
        AnyEntityQueryComparator(erasingEntityQuery: comparator)
    }
    public static func buildBlock(
        _ components: AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>...
    ) -> [AnyEntityQueryComparator<Entity, Subject, Property, PropertyType, ComparatorMappingType>] {
        components
    }
}

public enum EntityQuerySortingOptionsBuilder<Entity>: Hashable, Sendable {
    case _appIntentsPlaceholder
    /// Count-preserving in-process combination. Nothing is sent to a query daemon.
    public static func buildBlock(
        _ sortables: EntityQuerySortableByProperty<Entity>...
    ) -> [EntityQuerySortableByProperty<Entity>] {
        sortables
    }
    public static func buildExpression(
        _ sortable: EntityQuerySortableByProperty<Entity>
    ) -> EntityQuerySortableByProperty<Entity> {
        sortable
    }
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


