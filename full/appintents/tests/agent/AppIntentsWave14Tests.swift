import Foundation
import AppIntents

// Wave 14: portable in-process data models for shortcut presentation,
// URL templates, parameter dependencies, summaries, and items.
// Every test below is synchronous; no Siri daemon, Shortcuts registrar,
// run loop, semaphore, or suspension point is used.

private struct Wave14Intent: AppIntent {
    static var title: LocalizedStringResource { "Wave14" }
    @Parameter(title: "Name")
    var name: String
    init() {
        _name = IntentParameter(title: "Name")
    }
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: name, dialog: IntentDialog("ok"))
    }
}

private struct Wave14PropertyHolder {
    var name: EntityProperty<String> = EntityProperty()
}

private struct Wave14Options: DynamicOptionsProvider {
    typealias Result = [String]
    func results() async throws -> [String] { [] }
}

private struct Wave14Content: AppShortcutsContent {
    static var appShortcuts: [AppShortcut] { [] }
}

private struct Wave14Unique: UniqueAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave14 Unique" }
    static var defaultQuery = UniqueAppEntityProvider<Wave14Unique> {
        Wave14Unique(id: "wave14")
    }
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private typealias Wave14TitleString = AppShortcutParameterPresentationTitleString<
    Wave14Intent, String, IntentParameter<String>, KeyPath<Wave14Intent, IntentParameter<String>>
>
private typealias Wave14SummaryString = AppShortcutParameterPresentationSummaryString<
    Wave14Intent, String, IntentParameter<String>, KeyPath<Wave14Intent, IntentParameter<String>>
>

private func wave14Collection(_ title: LocalizedStringResource) -> AppShortcutOptionsCollection<Wave14Options> {
    AppShortcutOptionsCollection(
        Wave14Options(),
        title: title,
        systemImageName: "star"
    )
}

func testNegativeAppShortcutPhraseLiterals() {
    let keyed = NegativeAppShortcutPhrase("wave14.key")
    precondition(keyed.template == "wave14.key")
    let literal: NegativeAppShortcutPhrase = "Silent Night"
    precondition(literal.template == "Silent Night")
    let explicit = NegativeAppShortcutPhrase(stringLiteral: "Quiet")
    precondition(explicit.template == "Quiet")
    let interpolated: NegativeAppShortcutPhrase = "Run \(.applicationName) now"
    precondition(interpolated.template == "Run ${applicationName} now")
    var builder = NegativeAppShortcutPhrase.StringInterpolation(
        literalCapacity: 4,
        interpolationCount: 1
    )
    builder.appendLiteral("Go ")
    builder.appendInterpolation(.applicationName)
    let built = NegativeAppShortcutPhrase(stringInterpolation: builder)
    precondition(built.template == "Go ${applicationName}")
    let _: NegativeAppShortcutPhrase.StringLiteralType = "alias"
    let _: NegativeAppShortcutPhrase.UnicodeScalarLiteralType = "alias"
    let _: NegativeAppShortcutPhrase.ExtendedGraphemeClusterLiteralType = "alias"
    let _: NegativeAppShortcutPhrase.StringInterpolation.StringLiteralType = "alias"
    let empty = NegativeAppShortcutPhrases()
    precondition(empty.phrases.isEmpty)
    let phrases = NegativeAppShortcutPhrases(phrases: [keyed, literal])
    precondition(phrases.phrases.count == 2)
    precondition(phrases.phrases[0].template == "wave14.key")
}

func testAppShortcutsContentProvider() {
    let content = Wave14Content.appShortcuts
    precondition(content.isEmpty)
    let _: any AppShortcutsContent.Type = Wave14Content.self
}

func testAppShortcutOptionsCollectionStorage() {
    let collection = wave14Collection("Feed")
    precondition(collection.title.key == "Feed")
    precondition(collection.systemImageName == "star")
    precondition(collection.hostProviderTypeName.contains("Wave14Options"))
    let erased: any AppShortcutOptionsCollectionProtocol = collection
    precondition(erased.title.key == "Feed")
    precondition(erased.systemImageName == "star")
    let _: AppShortcutOptionsCollection<Wave14Options>.Provider.Type = Wave14Options.self
    let spec = AppShortcutOptionsCollectionSpecificationBuilder<String>.Specification<String>(
        collections: [collection]
    )
    precondition(spec.collections.count == 1)
    let _: AppShortcutOptionsCollectionSpecificationBuilder<String>.Specification<String>.Value.Type =
        String.self
    let existential: any AppShortcutOptionsCollectionSpecification<String> = spec
    precondition(existential.reduce(0) { count, _ in count + 1 } == 1)
}

func testAppShortcutOptionsCollectionBuilderLowArity() {
    typealias Builder = AppShortcutOptionsCollectionSpecificationBuilder<String>
    let a = wave14Collection("a")
    precondition(Builder.buildBlock(a).collections.count == 1)
    precondition(Builder.buildBlock(a, a).collections.count == 2)
    precondition(Builder.buildBlock(a, a, a).collections.count == 3)
    precondition(Builder.buildBlock(a, a, a, a).collections.count == 4)
    precondition(Builder.buildBlock(a, a, a, a, a).collections.count == 5)
    precondition(Builder.buildBlock(a, a, a, a, a, a).collections.count == 6)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a).collections.count == 7)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a).collections.count == 8)
}

func testAppShortcutOptionsCollectionBuilderHighArity() {
    typealias Builder = AppShortcutOptionsCollectionSpecificationBuilder<String>
    let a = wave14Collection("a")
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a).collections.count == 9)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a, a).collections.count == 10)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a, a, a).collections.count == 11)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a, a, a, a).collections.count == 12)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a, a, a, a, a).collections.count == 13)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a, a, a, a, a, a).collections.count == 14)
    precondition(Builder.buildBlock(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a).collections.count == 15)
}

func testAppShortcutParameterPresentationStack() {
    let keyPath = \Wave14Intent.$name
    let titleString = Wave14TitleString("Name: \(keyPath)")
    let summaryString = Wave14SummaryString("Hello \(keyPath)")
    let summary = AppShortcutParameterPresentationSummary<Wave14Intent, String, IntentParameter<String>, KeyPath<Wave14Intent, IntentParameter<String>>>(
        summaryString,
        table: "Wave14Table"
    )
    precondition(summary.summary.template == "Hello ${parameter}")
    precondition(summary.table == "Wave14Table")
    let title = AppShortcutParameterPresentationTitle<Wave14Intent, String, IntentParameter<String>, KeyPath<Wave14Intent, IntentParameter<String>>>(
        specific: titleString,
        generic: "Name",
        table: "Wave14Table"
    )
    precondition(title.specific.template == "Name: ${parameter}")
    precondition(title.generic == "Name")
    precondition(title.table == "Wave14Table")
    let presentation = AppShortcutParameterPresentation<Wave14Intent, String, IntentParameter<String>, KeyPath<Wave14Intent, IntentParameter<String>>>(
        for: keyPath,
        summary: summary
    ) {
        wave14Collection("options")
    }
    precondition(presentation.optionsCollectionsCount == 1)
    precondition(!presentation.hostKeyPathDescription.isEmpty)
}

func testAppShortcutParameterTitleStringInterpolation() {
    let keyPath = \Wave14Intent.$name
    let direct = Wave14TitleString("Title!")
    precondition(direct.template == "Title!")
    let literal: Wave14TitleString = "Plain"
    precondition(literal.template == "Plain")
    let explicit = Wave14TitleString(stringLiteral: "Explicit")
    precondition(explicit.template == "Explicit")
    let interpolated: Wave14TitleString = "For \(keyPath)"
    precondition(interpolated.template == "For ${parameter}")
    var builder = Wave14TitleString.StringInterpolation(literalCapacity: 8, interpolationCount: 1)
    builder.appendLiteral("Hi ")
    builder.appendInterpolation(keyPath)
    let built = Wave14TitleString(stringInterpolation: builder)
    precondition(built.template == "Hi ${parameter}")
    let _: Wave14TitleString.StringLiteralType = "alias"
    let _: Wave14TitleString.UnicodeScalarLiteralType = "alias"
    let _: Wave14TitleString.ExtendedGraphemeClusterLiteralType = "alias"
    let _: Wave14TitleString.StringInterpolation.StringLiteralType = "alias"
}

func testAppShortcutParameterSummaryStringInterpolation() {
    let keyPath = \Wave14Intent.$name
    let direct = Wave14SummaryString("Summary!")
    precondition(direct.template == "Summary!")
    let literal: Wave14SummaryString = "Plain"
    precondition(literal.template == "Plain")
    let explicit = Wave14SummaryString(stringLiteral: "Explicit")
    precondition(explicit.template == "Explicit")
    let interpolated: Wave14SummaryString = "Hello \(keyPath)"
    precondition(interpolated.template == "Hello ${parameter}")
    var builder = Wave14SummaryString.StringInterpolation(literalCapacity: 8, interpolationCount: 1)
    builder.appendLiteral("Yo ")
    builder.appendInterpolation(keyPath)
    let built = Wave14SummaryString(stringInterpolation: builder)
    precondition(built.template == "Yo ${parameter}")
    let _: Wave14SummaryString.StringLiteralType = "alias"
    let _: Wave14SummaryString.UnicodeScalarLiteralType = "alias"
    let _: Wave14SummaryString.ExtendedGraphemeClusterLiteralType = "alias"
    let _: Wave14SummaryString.StringInterpolation.StringLiteralType = "alias"
}

func testEntityURLRepresentationTemplates() {
    let direct = EntityURLRepresentation<Wave14PropertyHolder>("https://example.com/feed")
    precondition(direct.template == "https://example.com/feed")
    let literal: EntityURLRepresentation<Wave14PropertyHolder> = "https://example.com/literal"
    precondition(literal.template == "https://example.com/literal")
    let explicit = EntityURLRepresentation<Wave14PropertyHolder>(
        stringLiteral: "https://example.com/explicit"
    )
    precondition(explicit.template == "https://example.com/explicit")
    var builder = EntityURLRepresentation<Wave14PropertyHolder>.StringInterpolation(
        literalCapacity: 32,
        interpolationCount: 2
    )
    builder.appendLiteral("https://example.com/")
    builder.appendInterpolation(.id)
    builder.appendInterpolation(\Wave14PropertyHolder.name)
    let built = EntityURLRepresentation<Wave14PropertyHolder>(stringInterpolation: builder)
    precondition(built.template == "https://example.com/${id}${property}")
    let _: EntityURLRepresentation<Wave14PropertyHolder>.StringLiteralType = "alias"
    let _: EntityURLRepresentation<Wave14PropertyHolder>.UnicodeScalarLiteralType = "alias"
    let _: EntityURLRepresentation<Wave14PropertyHolder>.ExtendedGraphemeClusterLiteralType = "alias"
    let _: EntityURLRepresentation<Wave14PropertyHolder>.StringInterpolation.StringLiteralType = "alias"
    let token = EntityURLRepresentation<Wave14PropertyHolder>.Token.id
    precondition(token == .id)
}

func testIntentURLRepresentationTemplates() {
    let keyPath = \Wave14Intent.$name
    let direct = IntentURLRepresentation<Wave14Intent>("myapp://open")
    precondition(direct.template == "myapp://open")
    let literal: IntentURLRepresentation<Wave14Intent> = "myapp://literal"
    precondition(literal.template == "myapp://literal")
    let explicit = IntentURLRepresentation<Wave14Intent>(stringLiteral: "myapp://explicit")
    precondition(explicit.template == "myapp://explicit")
    var builder = IntentURLRepresentation<Wave14Intent>.StringInterpolation(
        literalCapacity: 16,
        interpolationCount: 1
    )
    builder.appendLiteral("myapp://run/")
    builder.appendInterpolation(keyPath)
    let built = IntentURLRepresentation<Wave14Intent>(stringInterpolation: builder)
    precondition(built.template == "myapp://run/${parameter}")
    let _: IntentURLRepresentation<Wave14Intent>.StringLiteralType = "alias"
    let _: IntentURLRepresentation<Wave14Intent>.UnicodeScalarLiteralType = "alias"
    let _: IntentURLRepresentation<Wave14Intent>.ExtendedGraphemeClusterLiteralType = "alias"
    let _: IntentURLRepresentation<Wave14Intent>.StringInterpolation.StringLiteralType = "alias"
}

func testIntentParameterDependencyTwoToEightKeyPaths() {
    let keyPath = \Wave14Intent.$name
    precondition(IntentParameterDependency<Wave14Intent>(keyPath, keyPath).keyPathCount == 2)
    precondition(IntentParameterDependency<Wave14Intent>(keyPath, keyPath, keyPath).keyPathCount == 3)
    precondition(
        IntentParameterDependency<Wave14Intent>(keyPath, keyPath, keyPath, keyPath).keyPathCount == 4
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            keyPath, keyPath, keyPath, keyPath, keyPath
        ).keyPathCount == 5
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            keyPath, keyPath, keyPath, keyPath, keyPath, keyPath
        ).keyPathCount == 6
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            keyPath, keyPath, keyPath, keyPath, keyPath, keyPath, keyPath
        ).keyPathCount == 7
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            keyPath, keyPath, keyPath, keyPath, keyPath, keyPath, keyPath, keyPath
        ).keyPathCount == 8
    )
}

func testIntentParameterDependencyNineToFifteenKeyPaths() {
    let k = \Wave14Intent.$name
    precondition(
        IntentParameterDependency<Wave14Intent>(k, k, k, k, k, k, k, k, k).keyPathCount == 9
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(k, k, k, k, k, k, k, k, k, k).keyPathCount == 10
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            k, k, k, k, k, k, k, k, k, k, k
        ).keyPathCount == 11
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            k, k, k, k, k, k, k, k, k, k, k, k
        ).keyPathCount == 12
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            k, k, k, k, k, k, k, k, k, k, k, k, k
        ).keyPathCount == 13
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            k, k, k, k, k, k, k, k, k, k, k, k, k, k
        ).keyPathCount == 14
    )
    precondition(
        IntentParameterDependency<Wave14Intent>(
            k, k, k, k, k, k, k, k, k, k, k, k, k, k, k
        ).keyPathCount == 15
    )
}

func testParameterSummaryStringAndKeyPaths() {
    let keyPath = \Wave14Intent.$name
    let direct = ParameterSummaryString<Wave14Intent>("plain")
    precondition(direct.evaluatedDisplayString == "plain")
    let literal: ParameterSummaryString<Wave14Intent> = "literal"
    precondition(literal.evaluatedDisplayString == "literal")
    let explicit = ParameterSummaryString<Wave14Intent>(stringLiteral: "explicit")
    precondition(explicit.evaluatedDisplayString == "explicit")
    let interpolated: ParameterSummaryString<Wave14Intent> = "name=\(keyPath)"
    precondition(interpolated.evaluatedDisplayString == "name=${parameter}")
    var builder = ParameterSummaryString<Wave14Intent>.StringInterpolation(
        literalCapacity: 8,
        interpolationCount: 1
    )
    builder.appendLiteral("hi ")
    builder.appendInterpolation(keyPath)
    let built = ParameterSummaryString<Wave14Intent>(stringInterpolation: builder)
    precondition(built.evaluatedDisplayString == "hi ${parameter}")
    let _: ParameterSummaryString<Wave14Intent>.StringLiteralType = "alias"
    let _: ParameterSummaryString<Wave14Intent>.UnicodeScalarLiteralType = "alias"
    let _: ParameterSummaryString<Wave14Intent>.ExtendedGraphemeClusterLiteralType = "alias"
    let _: ParameterSummaryString<Wave14Intent>.StringInterpolation.StringLiteralType = "alias"
    let tabled = IntentParameterSummary<Wave14Intent>(
        ParameterSummaryString<Wave14Intent>("Feed \(keyPath)"),
        table: "Wave14"
    ) { keyPath }
    precondition(tabled.evaluatedDisplayString == "Feed ${parameter}")
    let keyed = IntentParameterSummary<Wave14Intent>({ keyPath })
    precondition(keyed.evaluatedDisplayString.isEmpty)
    let expressed = IntentParameterSummary<Wave14Intent>.ParameterKeyPathsBuilder.buildExpression(
        keyPath
    )
    let blocked = IntentParameterSummary<Wave14Intent>.ParameterKeyPathsBuilder.buildBlock(keyPath)
    precondition(blocked.count == 1)
    _ = expressed
}

func testIntentItemSectionAndCollectionMatrices() {
    let item = IntentItem("hello")
    precondition(item.value == "hello")
    let built = IntentItem<String>.Builder.buildArray([[IntentItem("a"), IntentItem("b")]])
    precondition(built.count == 2)
    let section = IntentItemSection(items: [item])
    precondition(section.items.count == 1)
    precondition(section.description == nil)
    let titled = IntentItemSection(title: LocalizedStringResource("T"), items: [item])
    precondition(titled.title?.key == "T")
    let _ = IntentItemSection<String>.Builder.buildBlock()
    let fromSections = IntentItemSection<String>.Builder.buildBlock(section)
    precondition(fromSections.count == 1)
    let fromItems = IntentItemSection<String>.Builder.buildBlock(item)
    precondition(fromItems.count == 1)
    let viaBuilder = IntentItemSection<String>(LocalizedStringResource("B")) { [IntentItem("x")] }
    precondition(viaBuilder.items.count == 1)
    let rich = IntentItemSection<String>(
        LocalizedStringResource("R"),
        subtitle: LocalizedStringResource("sub"),
        image: nil
    ) {
        IntentItem("y")
    }
    precondition(rich.description?.title.key == "R")
    precondition(rich.description?.subtitle?.key == "sub")
    let unique = Wave14Unique(id: "wave14")
    let collection = IntentItemCollection(
        promptLabel: LocalizedStringResource("Pick"),
        usesIndexedCollation: true,
        sections: [section]
    )
    precondition(collection.promptLabel?.key == "Pick")
    precondition(collection.usesIndexedCollation == true)
    precondition(collection.sections.count == 1)
    let fromItemsCollection = IntentItemCollection(
        promptLabel: nil,
        usesIndexedCollation: false,
        items: [unique]
    )
    precondition(fromItemsCollection.sections.count == 1)
    let viaSectionsBuilder = IntentItemCollection<Wave14Unique>(
        promptLabel: nil,
        usesIndexedCollation: false
    ) {
        [IntentItemSection(items: [IntentItem(unique)])]
    }
    precondition(viaSectionsBuilder.sections.count == 1)
}

func testChoiceOptionStyleAndOptionSetFlags() {
    let plain = IntentChoiceOption(title: LocalizedStringResource("One"))
    precondition(plain.title.key == "One")
    let styled = IntentChoiceOption(
        title: LocalizedStringResource("Two"),
        style: .destructive
    )
    precondition(styled.style == .destructive)
    precondition(IntentChoiceOption.Style.default != .cancel)
    precondition(IntentChoiceOption.Style.cancel != .destructive)
    precondition(IntentChoiceOption.cancel.title.key == "Cancel")
    let conditions = ConfirmationConditions(rawValue: 1)
    precondition(conditions.rawValue == 1)
    precondition(conditions.contains(.lowConfidenceSource))
    let _: ConfirmationConditions.Element.Type = ConfirmationConditions.self
    let _: ConfirmationConditions.RawValue.Type = Int.self
    let modifiers = EntityPropertyModifiers(rawValue: 1)
    precondition(modifiers.rawValue == 1)
    precondition(modifiers.contains(.async))
    precondition(!modifiers.contains(.readOnly))
    let _: EntityPropertyModifiers.Element.Type = EntityPropertyModifiers.self
    let _: EntityPropertyModifiers.RawValue.Type = Int.self
}

func testDisplayRepresentationEntityAndSnippetLiterals() {
    let literal: DisplayRepresentation = "Hello"
    precondition(literal.title.key == "Hello")
    let _: DisplayRepresentation.StringLiteralType = "alias"
    let _: DisplayRepresentation.UnicodeScalarLiteralType = "alias"
    let _: DisplayRepresentation.ExtendedGraphemeClusterLiteralType = "alias"
    let unique = Wave14Unique(id: "wave14")
    let identifier = EntityIdentifier(for: unique)
    precondition(identifier.description == "Wave14Unique/wave14")
    let _: EntityIdentifier.UnwrappedType.Type = EntityIdentifier.self
    let _: EntityIdentifier.ValueType.Type = EntityIdentifier.self
    let snippet = EmptySnippetIntent()
    precondition(EmptySnippetIntent.title.key == "Empty Snippet")
    precondition(EmptySnippetIntent.isDiscoverable == true)
    let _: EmptySnippetIntent.PerformResult.Type = IntentResultValue.self
    let _: EmptySnippetIntent.SummaryContent.Type = IntentParameterSummary<EmptySnippetIntent>.self
    _ = snippet
}

func testVideoCategoryAndSearchScopeTables() {
    let _: VideoCategory.Type = VideoCategory.self
    precondition(VideoCategory.tv.rawValue == "tv")
    precondition(VideoCategory.movies.rawValue == "movies")
    precondition(VideoCategory.freeform.rawValue == "freeform")
    precondition(VideoCategory(rawValue: "tv") == .tv)
    precondition(VideoCategory.typeDisplayRepresentation.name == "Video Category")
    precondition(VideoCategory.caseDisplayRepresentations[.movies]?.title.key == "Movies")
    let _: VideoCategory.RawValue.Type = String.self
    let _: VideoCategory.ValueType.Type = VideoCategory.self
    let _: VideoCategory.UnwrappedType.Type = VideoCategory.self
    let _: StringSearchScope.Type = StringSearchScope.self
    precondition(StringSearchScope.freeformVideo.rawValue == "freeformVideo")
    precondition(StringSearchScope.tv.rawValue == "tv")
    precondition(StringSearchScope.movies.rawValue == "movies")
    precondition(StringSearchScope.general.rawValue == "general")
    precondition(StringSearchScope(rawValue: "general") == .general)
    precondition(StringSearchScope.typeDisplayRepresentation.name == "String Search Scope")
    precondition(StringSearchScope.caseDisplayRepresentations[.tv]?.title.key == "TV")
    let _: StringSearchScope.RawValue.Type = String.self
    let _: StringSearchScope.ValueType.Type = StringSearchScope.self
    let _: StringSearchScope.UnwrappedType.Type = StringSearchScope.self
}

func testUniqueAppEntityProviderSyncSurface() {
    _ = UniqueAppEntityProvider<Wave14Unique>()
    let _: UniqueAppEntityProvider<Wave14Unique>.Unique.Type = Wave14Unique.self
    let _: UniqueAppEntityProvider<Wave14Unique>.Result.Type = [Wave14Unique].self
    let _: UniqueAppEntityProvider<Wave14Unique>.DefaultValue.Type = Wave14Unique.self
    let entity = Wave14Unique(id: "wave14")
    precondition(entity.displayRepresentation.title.key == "wave14")
    precondition(entity.id == "wave14")
}

func testIntAndDoubleResolverTypeAliases() {
    let intResolver = IntResolver()
    let _: IntResolver.Input.Type = Int.self
    let _: IntResolver.Output.Type = Int.self
    let doubleResolver = DoubleResolver()
    let _: DoubleResolver.Input.Type = Double.self
    let _: DoubleResolver.Output.Type = Double.self
    let stringResolver = StringFromDoubleResolver()
    let _: StringFromDoubleResolver.Input.Type = Double.self
    let _: StringFromDoubleResolver.Output.Type = String.self
    _ = intResolver
    _ = doubleResolver
    _ = stringResolver
}

func testSyncDisambiguationDonationAndAliases() {
    let parameter = IntentParameter<String>(title: LocalizedStringResource("Name"))
    let parameterError = parameter.needsDisambiguationError(among: ["a"], dialog: nil)
    precondition(parameterError.description == "entityNotFound")
    let context = IntentParameterContext<String>()
    let contextError = context.needsDisambiguationError(among: ["a"])
    precondition(contextError.description == "entityNotFound")
    let intent = Wave14Intent()
    let donation = intent.donate()
    precondition(!donation.rawValue.isEmpty)
    let result: IntentResultValue = .result()
    let donationWithResult = intent.donate(result: result)
    precondition(!donationWithResult.rawValue.isEmpty)
    precondition(Wave14Intent.title.key == "Wave14")
    let _: Wave14Intent.Option.Type = IntentChoiceOption.self
    func useParameter<V>(_ type: Wave14Intent.Parameter<V>.Type) {}
    useParameter(Wave14Intent.Parameter<String>.self)
}
