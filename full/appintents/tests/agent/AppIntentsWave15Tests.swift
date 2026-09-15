import Foundation
import AppIntents

// Wave 15: portable in-process entity-query comparison and container models.
// Every test below is synchronous and uses no Apple daemon, Spotlight index,
// Siri service, waiting, or suspension point. Comparators
// store mapping transforms and attached resolver specifications as metadata.
// Containers store declarations in arrays and vend them back by index.

private struct Wave15Entity: AppEntity {
    typealias DefaultQuery = Wave15EntityQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave15" }
    static var defaultQuery = Wave15EntityQuery()
    var id: String
    var tag: EntityProperty<String>
    var sortKey: Wave15SortKey
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave15SortKey: AnyIntentValue, Hashable {}

private struct Wave15EntityQuery: EntityQuery {
    typealias Entity = Wave15Entity
    func entities(for identifiers: [String]) async throws -> [Wave15Entity] { [] }
    func suggestedEntities() async throws -> [Wave15Entity] { [] }
}

private struct Wave15Intent: AppIntent {
    static var title: LocalizedStringResource { "Wave15" }
    @Parameter(title: "Name")
    var name: String
    init() {
        _name = IntentParameter(title: "Name")
    }
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: name, dialog: IntentDialog("ok"))
    }
}

private struct Wave15Summary: ParameterSummary {
    typealias Intent = Wave15Intent
    var evaluatedDisplayString: String
}

private struct Wave15Score: RangeComparableProperty, Hashable, Comparable {
    var points: Int
    static func < (lhs: Wave15Score, rhs: Wave15Score) -> Bool { lhs.points < rhs.points }
}

private func wave15CollectionItems<V: _IntentValue>(_ collection: [V]) -> [V.ValueType] {
    collection.items
}

private func wave15Clamp<T: RangeComparableProperty>(_ value: T) -> T { value }

func testEntityQueryEqualityComparatorTransforms() {
    let equals = EqualToComparator<EntityProperty<String>, String, String>(mappingTransform: { $0 })
    precondition(equals.mappingTransform?("a") == "a")
    let equalsResolvers = EqualToComparator<EntityProperty<String>, String, String>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { $0 }
    )
    precondition(equalsResolvers.mappingTransform?("b") == "b")
    precondition(equalsResolvers.hostResolverSpecification != nil)
    let differs = NotEqualToComparator<EntityProperty<String>, String, String>(mappingTransform: { $0 })
    precondition(differs.mappingTransform?("a") == "a")
    let differsResolvers = NotEqualToComparator<EntityProperty<String>, String, String>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { $0 }
    )
    precondition(differsResolvers.mappingTransform?("c") == "c")
    precondition(differsResolvers.hostResolverSpecification != nil)
}

func testEntityQueryOrderingComparatorTransforms() {
    let less = LessThanComparator<EntityProperty<Int>, Int, Int>(mappingTransform: { $0 })
    precondition(less.mappingTransform?(3) == 3)
    let lessResolvers = LessThanComparator<EntityProperty<Int>, Int, Int>(
        withResolvers: { EmptyResolverSpecification<Int>() },
        mappingTransform: { $0 }
    )
    precondition(lessResolvers.mappingTransform?(4) == 4)
    precondition(lessResolvers.hostResolverSpecification != nil)
    let greater = GreaterThanComparator<EntityProperty<Int>, Int, Int>(mappingTransform: { $0 })
    precondition(greater.mappingTransform?(5) == 5)
    let greaterResolvers = GreaterThanComparator<EntityProperty<Int>, Int, Int>(
        withResolvers: { EmptyResolverSpecification<Int>() },
        mappingTransform: { $0 }
    )
    precondition(greaterResolvers.mappingTransform?(6) == 6)
    precondition(greaterResolvers.hostResolverSpecification != nil)
    let lessEqual = LessThanOrEqualToComparator<EntityProperty<Int>, Int, Int>(mappingTransform: { $0 })
    precondition(lessEqual.mappingTransform?(7) == 7)
    let lessEqualResolvers = LessThanOrEqualToComparator<EntityProperty<Int>, Int, Int>(
        withResolvers: { EmptyResolverSpecification<Int>() },
        mappingTransform: { $0 }
    )
    precondition(lessEqualResolvers.mappingTransform?(8) == 8)
    precondition(lessEqualResolvers.hostResolverSpecification != nil)
    let greaterEqual = GreaterThanOrEqualToComparator<EntityProperty<Int>, Int, Int>(mappingTransform: { $0 })
    precondition(greaterEqual.mappingTransform?(9) == 9)
    let greaterEqualResolvers = GreaterThanOrEqualToComparator<EntityProperty<Int>, Int, Int>(
        withResolvers: { EmptyResolverSpecification<Int>() },
        mappingTransform: { $0 }
    )
    precondition(greaterEqualResolvers.mappingTransform?(10) == 10)
    precondition(greaterEqualResolvers.hostResolverSpecification != nil)
}

func testEntityQueryStringAndBetweenComparators() {
    let between = IsBetweenComparator<EntityProperty<Int>, Int, Int, Bool>(
        mappingTransform: { low, high in low <= high }
    )
    precondition(between.mappingTransform?(1, 9) == true)
    precondition(between.mappingTransform?(9, 1) == false)
    let betweenResolvers = IsBetweenComparator<EntityProperty<Int>, Int, Int, Bool>(
        withResolvers: { EmptyResolverSpecification<Int>() },
        mappingTransform: { low, high in low <= high }
    )
    precondition(betweenResolvers.mappingTransform?(2, 3) == true)
    precondition(betweenResolvers.hostResolverSpecification != nil)
    let prefix = HasPrefixComparator<EntityProperty<String>, String, String, Bool>(
        mappingTransform: { !$0.isEmpty }
    )
    precondition(prefix.mappingTransform?("wave") == true)
    let prefixResolvers = HasPrefixComparator<EntityProperty<String>, String, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { !$0.isEmpty }
    )
    precondition(prefixResolvers.mappingTransform?("") == false)
    precondition(prefixResolvers.hostResolverSpecification != nil)
    let suffix = HasSuffixComparator<EntityProperty<String>, String, String, Bool>(
        mappingTransform: { !$0.isEmpty }
    )
    precondition(suffix.mappingTransform?("wave") == true)
    let suffixResolvers = HasSuffixComparator<EntityProperty<String>, String, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { !$0.isEmpty }
    )
    precondition(suffixResolvers.mappingTransform?("") == false)
    precondition(suffixResolvers.hostResolverSpecification != nil)
    let contains = ContainsComparator<EntityProperty<String>, String, String, Bool>(
        mappingTransform: { !$0.isEmpty }
    )
    precondition(contains.mappingTransform?("wave") == true)
    let containsResolvers = ContainsComparator<EntityProperty<String>, String, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { !$0.isEmpty }
    )
    precondition(containsResolvers.mappingTransform?("") == false)
    precondition(containsResolvers.hostResolverSpecification != nil)
    let containsAttributed = ContainsComparator<
        EntityProperty<AttributedString>, AttributedString, AttributedString, Bool
    >(mappingTransform: { _ in true })
    precondition(containsAttributed.mappingTransform?(AttributedString("wave")) == true)
    let containsAttributedResolvers = ContainsComparator<
        EntityProperty<AttributedString>, AttributedString, AttributedString, Bool
    >(
        withResolvers: { EmptyResolverSpecification<AttributedString>() },
        mappingTransform: { _ in true }
    )
    precondition(containsAttributedResolvers.mappingTransform?(AttributedString("tide")) == true)
    precondition(containsAttributedResolvers.hostResolverSpecification != nil)
}

func testEntityQueryComparatorsBuilderConcatenates() {
    typealias Builder = EntityQueryComparatorsBuilder<
        Wave15Entity, Wave15Entity, EntityProperty<String>, String, Bool
    >
    typealias OptionalBuilder = EntityQueryComparatorsBuilder<
        Wave15Entity, Wave15Entity, EntityProperty<String?>, String?, Bool
    >
    let contains = ContainsComparator<EntityProperty<String>, String, String, Bool>(
        mappingTransform: { !$0.isEmpty }
    )
    let between = IsBetweenComparator<EntityProperty<String>, String, String, Bool>(
        mappingTransform: { low, high in low <= high }
    )
    let base = EntityQueryComparator<EntityProperty<String>, String, String, Bool>()
    let erasedContains = Builder.buildExpression(contains)
    let erasedBetween = Builder.buildExpression(between)
    let erasedBase = Builder.buildExpression(base)
    precondition(erasedContains.hostKind == "contains")
    precondition(erasedBetween.hostKind == "isBetween")
    precondition(erasedBase.hostKind == "entityQuery")
    let optionalBase = EntityQueryComparator<EntityProperty<String?>, String?, String, Bool>()
    let erasedOptional = OptionalBuilder.buildExpression(optionalBase)
    precondition(erasedOptional.hostKind == "entityQuery")
    let combined = Builder.buildBlock(erasedContains, erasedBetween, erasedBase)
    precondition(combined.count == 3)
    precondition(combined.map(\.hostKind) == ["contains", "isBetween", "entityQuery"])
    let empty: AnyEntityQueryComparator<
        Wave15Entity, Wave15Entity, EntityProperty<String>, String, Bool
    > = AnyEntityQueryComparator()
    precondition(empty.hostKind == "empty")
}

func testEntityQueryPropertiesBuilderAndContainers() {
    typealias Builder = EntityQueryPropertiesBuilder<Wave15Entity, Bool>
    typealias Comparators = EntityQueryComparatorsBuilder<
        Wave15Entity, Wave15Entity, EntityProperty<String>, String, Bool
    >
    let entity = Wave15Entity(
        id: "wave15",
        tag: EntityProperty<String>(),
        sortKey: Wave15SortKey()
    )
    let first = EntityQueryProperty<
        Wave15Entity, Wave15Entity, EntityProperty<String>, String, Bool
    >(\Wave15Entity.tag) {
        Comparators.buildBlock(
            Comparators.buildExpression(
                EntityQueryComparator<EntityProperty<String>, String, String, Bool>()
            )
        )
    }
    precondition(first.hostComparators.count == 1)
    precondition(first.hostKeyPathDescription == String(describing: \Wave15Entity.tag))
    let second = EntityQueryProperty<
        Wave15Entity, Wave15Entity, EntityProperty<String>, String, Bool
    >(\Wave15Entity.tag, entityProvider: { $0 }) { [] }
    precondition(second.hostComparators.isEmpty)
    precondition(second.hostEntityProvider?(entity).id == "wave15")
    let declarations = Builder.buildBlock(first.hostDeclaration(), second.hostDeclaration())
    precondition(declarations.count == 2)
    let single = Builder.buildExpression(first.hostDeclaration())
    precondition(single.hostKeyPathDescription == String(describing: \Wave15Entity.tag))
    let properties = EntityQueryProperties<Wave15Entity, Bool> { declarations }
    precondition(properties.hostDeclarations.count == 2)
    precondition(properties[0].hostKeyPathDescription == String(describing: \Wave15Entity.tag))
    precondition(properties[1].hostKeyPathDescription == String(describing: \Wave15Entity.tag))
}

func testEntityQuerySortingOptionsBuilderAndContainers() {
    typealias Builder = EntityQuerySortingOptionsBuilder<Wave15Entity>
    let sortable = EntityQuerySortableByProperty<Wave15Entity>(\Wave15Entity.sortKey)
    precondition(sortable.hostKeyPath == (\Wave15Entity.sortKey as AnyKeyPath))
    let expressed = Builder.buildExpression(sortable)
    precondition(expressed.hostKeyPath == (\Wave15Entity.sortKey as AnyKeyPath))
    let blocked = Builder.buildBlock(sortable, expressed)
    precondition(blocked.count == 2)
    let options = EntityQuerySortingOptions<Wave15Entity> { blocked }
    precondition(options.hostSorting.count == 2)
    precondition(options[0].hostKeyPath == (\Wave15Entity.sortKey as AnyKeyPath))
    precondition(options[1].hostKeyPath == (\Wave15Entity.sortKey as AnyKeyPath))
    let empty = EntityQuerySortingOptions<Wave15Entity>()
    precondition(empty.hostSorting.isEmpty)
    let literal = EntityQuerySortingOptions<Wave15Entity>(
        content: { [sortable] }
    )
    precondition(literal.hostSorting.count == 1)
}

func testParameterSummaryBuilderIdentity() {
    let summary = Wave15Summary(evaluatedDisplayString: "Run wave")
    let blocked = ParameterSummaryBuilder.buildBlock(summary)
    precondition(blocked.evaluatedDisplayString == "Run wave")
    let expressed = ParameterSummaryBuilder.buildExpression(summary)
    precondition(expressed.evaluatedDisplayString == "Run wave")
}

func testResultsCollectionArrayConformances() {
    let words = ["a", "b"]
    precondition(words.items == ["a", "b"])
    precondition(wave15CollectionItems(words) == ["a", "b"])
    precondition([String].empty.isEmpty)
    precondition(words.promptLabel == nil)
    precondition(words.usesIndexedCollation == false)
    let _: [String].Result = "a"
    let _: [String].ValueType = "a"
    let _: [String].UnwrappedType = ["a"]
}

func testIntentValueScalarTypeAliases() {
    let _: Bool.ValueType = true
    let _: Bool.UnwrappedType = false
    let _: Int.ValueType = 1
    let _: Int.UnwrappedType = 2
    let _: Double.ValueType = 1.5
    let _: Double.UnwrappedType = 2.5
    let _: String.ValueType = "wave"
    let _: String.UnwrappedType = "tide"
    let _: Measurement<UnitLength>.ValueType = Measurement(value: 1, unit: UnitLength.meters)
    let _: Measurement<UnitLength>.UnwrappedType = Measurement(value: 2, unit: UnitLength.meters)
    let _: Date.ValueType = Date(timeIntervalSince1970: 0)
    let _: Date.UnwrappedType = Date(timeIntervalSince1970: 1)
    let _: URL.ValueType = URL(fileURLWithPath: "/wave15")
    let _: URL.UnwrappedType = URL(fileURLWithPath: "/tide")
    let _: DateComponents.ValueType = DateComponents(year: 2026)
    let _: DateComponents.UnwrappedType = DateComponents(month: 9)
    let _: AttributedString.ValueType = AttributedString("wave")
    let _: AttributedString.UnwrappedType = AttributedString("tide")
    let _: CLPlacemark.ValueType = CLPlacemark(name: "Ada")
    let _: CLPlacemark.UnwrappedType = CLPlacemark(locality: "London")
}

func testOptionalAndSetIntentValueAliases() {
    let _: String?.ValueType = "wave"
    let _: String?.UnwrappedType = "tide"
    let _: Set<String>.ValueType = "wave"
    let _: Set<String>.UnwrappedType = Set(["tide"])
}

func testFileEntityIdentifierCodableAndFileURL() {
    let url = URL(fileURLWithPath: "/tmp/wave15.txt")
    let original = try! FileEntityIdentifier.file(url: url)
    precondition(original.fileURL == url)
    precondition(original.isDraft == false)
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(FileEntityIdentifier.self, from: encoded)
    precondition(decoded == original)
    precondition(decoded.fileURL == url)
    let draft = FileEntityIdentifier.draft(identifier: "wave15")
    precondition(draft.isDraft == true)
    precondition(draft.fileURL != nil)
    let draftData = try! JSONEncoder().encode(draft)
    let draftDecoded = try! JSONDecoder().decode(FileEntityIdentifier.self, from: draftData)
    precondition(draftDecoded == draft)
}

func testIntentDonationIdentifierCodable() {
    let original = IntentDonationIdentifier("wave15.donation")
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(IntentDonationIdentifier.self, from: encoded)
    precondition(decoded == original)
    precondition(decoded.rawValue == "wave15.donation")
}

func testDisplayRepresentationImageEncode() {
    let image = DisplayRepresentation.Image(systemName: "star")
    let encoded = try! JSONEncoder().encode(image)
    let decoded = try! JSONDecoder().decode(DisplayRepresentation.Image.self, from: encoded)
    precondition(decoded.systemName == "star")
}

func testRangeComparablePropertyConformance() {
    let low = Wave15Score(points: 1)
    let high = Wave15Score(points: 9)
    precondition(low < high)
    precondition(wave15Clamp(high) == high)
}
