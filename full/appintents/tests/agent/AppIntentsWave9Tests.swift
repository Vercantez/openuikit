import Foundation
import AppIntents

private struct Wave9PlaceHolder: AppEntity {
    typealias DefaultQuery = Wave9PlaceHolderQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Place Holder" }
    static var defaultQuery = Wave9PlaceHolderQuery()
    var id: String
    var payload: CLPlacemark
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id)
    }
}

private struct Wave9PlaceHolderQuery: EntityQuery {
    typealias Entity = Wave9PlaceHolder
    init() {}
    func entities(for identifiers: [String]) async throws -> [Wave9PlaceHolder] {
        EntityResolutionEngine.entities(for: identifiers, as: Wave9PlaceHolder.self)
    }
    func suggestedEntities() async throws -> [Wave9PlaceHolder] {
        EntityResolutionEngine.suggestedEntities(Wave9PlaceHolder.self)
    }
}

private struct Wave9PlaceIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Place" }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

    @Parameter(
        title: "Place",
        default: CLPlacemark(name: "Ada", locality: "London"),
        displayStyle: .name
    )
    var place: CLPlacemark

    func hostResult() -> IntentResultContainer<String, Never, Never, IntentDialog> {
        let title = place.name ?? "missing"
        return .result(value: title, dialog: IntentDialog("place=\(title)"))
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: place.name ?? "", dialog: IntentDialog("place=\(place.name ?? "")"))
    }
}

private func wave9Placemark() -> CLPlacemark {
    CLPlacemark(name: "Ada Lovelace", locality: "London", thoroughfare: "St James's")
}

private func registerPlaceHolder(_ payload: CLPlacemark) -> Wave9PlaceHolder {
    EntityResolutionEngine.reset()
    let holder = Wave9PlaceHolder(id: "row", payload: payload)
    EntityResolutionEngine.register([holder], default: holder)
    return holder
}

func testEntityPropertyPlacemarkTitleIdentifierGetterAndIndexing() {
    let sample = wave9Placemark()
    let holder = registerPlaceHolder(sample)
    let titled = EntityProperty<CLPlacemark>(title: LocalizedStringResource("Field"))
    titled.wrappedValue = sample
    precondition(titled.wrappedValue.name == "Ada Lovelace")
    let empty = EntityProperty<CLPlacemark>()
    empty.wrappedValue = sample
    precondition(empty.wrappedValue.locality == "London")
    let identified = EntityProperty<CLPlacemark>(identifier: "payload")
    precondition(identified.identifier == "payload")
    let titledId = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Field")
    )
    precondition(titledId.title.key == "Field")
    let getter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Field"),
        getter: \Wave9PlaceHolder.payload
    )
    precondition(getter.wrappedValue.name == "Ada Lovelace")
    let setter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Field"),
        getSetter: \Wave9PlaceHolder.payload
    )
    precondition(setter.wrappedValue.thoroughfare == "St James's")
    let idGetter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        getter: \Wave9PlaceHolder.payload
    )
    precondition(idGetter.wrappedValue.name == "Ada Lovelace")
    let idSetter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        getSetter: \Wave9PlaceHolder.payload
    )
    precondition(idSetter.wrappedValue.locality == "London")
    let indexed = EntityProperty<CLPlacemark>(indexingKey: \CSSearchableItemAttributeSet.title)
    precondition(indexed.indexingKeyPath != nil)
    let customOnly = EntityProperty<CLPlacemark>(
        customIndexingKey: CSCustomAttributeKey(keyName: "place.custom")
    )
    precondition(customOnly.customIndexingKey?.keyName == "place.custom")
    let titleIndexed = EntityProperty<CLPlacemark>(
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(titleIndexed.indexingKeyName == "indexingKey")
    let titleCustom = EntityProperty<CLPlacemark>(
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "place.title")
    )
    precondition(titleCustom.customIndexingKey?.keyName == "place.title")
    precondition(CLPlacemark.typeDisplayRepresentation.name == "Placemark")
    precondition(sample.displayRepresentation.title.key == "Ada Lovelace")
    precondition(sample.localizedStringResource.key == "Ada Lovelace")
    _ = CLPlacemark.defaultResolverSpecification
    _ = holder
}

func testEntityPropertyPlacemarkIndexingKeyGetters() {
    let sample = wave9Placemark()
    _ = registerPlaceHolder(sample)
    let byIndex = EntityProperty<CLPlacemark>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \Wave9PlaceHolder.payload
    )
    precondition(byIndex.wrappedValue.name == "Ada Lovelace")
    let byIndexSet = EntityProperty<CLPlacemark>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \Wave9PlaceHolder.payload
    )
    precondition(byIndexSet.wrappedValue.locality == "London")
    let identIndex = EntityProperty<CLPlacemark>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title
    )
    precondition(identIndex.indexingKeyPath != nil)
    let customGetter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "place.idx"),
        getter: \Wave9PlaceHolder.payload
    )
    precondition(customGetter.wrappedValue.name == "Ada Lovelace")
    let customSetter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "place.set"),
        getSetter: \Wave9PlaceHolder.payload
    )
    precondition(customSetter.wrappedValue.thoroughfare == "St James's")
    let identCustom = EntityProperty<CLPlacemark>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "place.id")
    )
    precondition(identCustom.customIndexingKey?.keyName == "place.id")
    let titledIndex = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \Wave9PlaceHolder.payload
    )
    precondition(titledIndex.wrappedValue.name == "Ada Lovelace")
    let titledIndexSet = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \Wave9PlaceHolder.payload
    )
    precondition(titledIndexSet.wrappedValue.locality == "London")
    let titledIndexOnly = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.title
    )
    precondition(titledIndexOnly.title.key == "Indexed")
    let titledCustomGetter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "place.g"),
        getter: \Wave9PlaceHolder.payload
    )
    precondition(titledCustomGetter.wrappedValue.name == "Ada Lovelace")
    let titledCustomSetter = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "place.s"),
        getSetter: \Wave9PlaceHolder.payload
    )
    precondition(titledCustomSetter.wrappedValue.locality == "London")
    let titledCustom = EntityProperty<CLPlacemark>(
        identifier: "payload",
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "place.c")
    )
    precondition(titledCustom.customIndexingKey?.keyName == "place.c")
}

func testIntentParameterPlacemarkDisplayStyleDefaultsAndProviders() {
    let mark = wave9Placemark()
    let withDefault = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("Place"),
        description: LocalizedStringResource("Where"),
        default: mark,
        displayStyle: .city,
        requestValueDialog: IntentDialog("need place")
    )
    precondition(withDefault.wrappedValue.name == "Ada Lovelace")
    precondition(withDefault.displayStyle == .city)
    let descriptionOnly = IntentParameter<CLPlacemark>(
        description: LocalizedStringResource("bare"),
        default: mark,
        displayStyle: .address
    )
    precondition(descriptionOnly.wrappedValue.locality == "London")
    precondition(descriptionOnly.displayStyle == .address)
    let titled = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("Place"),
        description: LocalizedStringResource("Where"),
        displayStyle: .name
    )
    titled.wrappedValue = mark
    precondition(titled.wrappedValue.name == "Ada Lovelace")
    precondition(titled.displayStyle == .name)
    let withProvider = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("Place"),
        default: mark,
        displayStyle: .city,
        optionsProvider: Wave9PlaceHolderQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    let descProvider = IntentParameter<CLPlacemark>(
        description: LocalizedStringResource("d"),
        default: mark,
        displayStyle: .name,
        optionsProvider: Wave9PlaceHolderQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)
    let titledProvider = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("T"),
        displayStyle: .address,
        optionsProvider: Wave9PlaceHolderQuery()
    )
    precondition(titledProvider.hasOptionsProvider == true)
    let withResolvers = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("R"),
        default: mark,
        displayStyle: .city,
        resolvers: EmptyResolverSpecification<CLPlacemark>()
    )
    precondition(withResolvers.displayStyle == .city)
    let descResolvers = IntentParameter<CLPlacemark>(
        description: LocalizedStringResource("d"),
        default: mark,
        displayStyle: .name,
        resolvers: EmptyResolverSpecification<CLPlacemark>()
    )
    precondition(descResolvers.displayStyle == .name)
    let titledResolvers = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("R"),
        displayStyle: .address,
        resolvers: EmptyResolverSpecification<CLPlacemark>()
    )
    titledResolvers.wrappedValue = mark
    precondition(titledResolvers.displayStyle == .address)
    let both = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("B"),
        default: mark,
        displayStyle: .city,
        optionsProvider: Wave9PlaceHolderQuery(),
        resolvers: EmptyResolverSpecification<CLPlacemark>()
    )
    precondition(both.hasOptionsProvider == true)
    let descBoth = IntentParameter<CLPlacemark>(
        description: LocalizedStringResource("d"),
        default: mark,
        displayStyle: .name,
        optionsProvider: Wave9PlaceHolderQuery(),
        resolvers: EmptyResolverSpecification<CLPlacemark>()
    )
    precondition(descBoth.hasOptionsProvider == true)
    let titledBoth = IntentParameter<CLPlacemark>(
        title: LocalizedStringResource("B"),
        displayStyle: .address,
        optionsProvider: Wave9PlaceHolderQuery(),
        resolvers: EmptyResolverSpecification<CLPlacemark>()
    )
    precondition(titledBoth.hasOptionsProvider == true)
    let context = withDefault.makeContext()
    precondition(context.displayStyle == .city)
    precondition(IntentParameter<String>.PlacemarkDisplayStyle.city != .name)
    precondition(IntentParameter<String>.PlacemarkDisplayStyle.address != .city)
}

func testSamplePlaceIntentHostResult() {
    let intent = Wave9PlaceIntent()
    precondition(intent.place.name == "Ada")
    let result = intent.hostResult()
    precondition(result.value == "Ada")
    precondition(result.dialog?.text == "place=Ada")
    intent.place = CLPlacemark(name: "Paris")
    let converted = intent.hostResult()
    precondition(converted.value == "Paris")
}

func testEnumURLRepresentationInterpolationAndCaseMap() {
    let literal: EnumURLRepresentation<VideoCategory> = "video/${rawValue}"
    precondition(literal.expanded(for: .tv) == "video/tv")
    var interpolation = EnumURLRepresentation<VideoCategory>.StringInterpolation(
        literalCapacity: 8,
        interpolationCount: 2
    )
    interpolation.appendLiteral("open/")
    interpolation.appendInterpolation(EnumURLRepresentation<VideoCategory>.StringInterpolation.Token.rawValue)
    interpolation.appendLiteral("/")
    interpolation.appendInterpolation(VideoCategory.movies)
    let interpolated = EnumURLRepresentation<VideoCategory>(stringInterpolation: interpolation)
    precondition(interpolated.expanded(for: .movies) == "open/${rawValue}/movies")
    let single: EnumURLRepresentation<VideoCategory>.EnumSingleURLRepresentation = "case/${rawValue}"
    let mapped = EnumURLRepresentation<VideoCategory>([
        .tv: "tv/${rawValue}",
        .movies: single,
        .freeform: "free/${rawValue}"
    ])
    precondition(mapped.expanded(for: .tv) == "tv/tv")
    precondition(mapped.expanded(for: .movies) == "case/movies")
    let fromString = EnumURLRepresentation<VideoCategory>("plain")
    precondition(fromString.expanded(for: .tv) == "plain")
    let scalar = EnumURLRepresentation<VideoCategory>(unicodeScalarLiteral: "u")
    precondition(scalar.template == "u")
    let cluster = EnumURLRepresentation<VideoCategory>(extendedGraphemeClusterLiteral: "c")
    precondition(cluster.template == "c")
    let singleScalar = EnumURLRepresentation<VideoCategory>.EnumSingleURLRepresentation(
        unicodeScalarLiteral: "s"
    )
    precondition(singleScalar.template == "s")
    let singleCluster = EnumURLRepresentation<VideoCategory>.EnumSingleURLRepresentation(
        extendedGraphemeClusterLiteral: "g"
    )
    precondition(singleCluster.template == "g")
    precondition(EnumURLRepresentation<VideoCategory>.StringInterpolation.Token.rawValue == .rawValue)
}

func testResolverSpecificationBuilderConcatenatesResolvers() {
    typealias Builder = ResolverSpecificationBuilder<String>
    let empty = Builder.buildBlock()
    precondition(empty.resolvers.isEmpty)
    precondition(!empty.contains(where: { _ in true }))
    let intR = IntFromStringResolver()
    let urlR = URLFromStringResolver()
    let boolR = BoolFromStringResolver()
    let doubleR = DoubleFromStringResolver()
    let fromInt = DoubleFromIntResolver()
    let fromDouble = IntFromDoubleResolver(roundingRule: .towardZero)
    let attr = AttributedStringFromStringResolver()
    let search = StringSearchCriteriaFromStringResolverSpecificification()
    let one = Builder.buildBlock(intR)
    precondition(one.resolvers.count == 1)
    precondition(Builder.buildExpression(intR).radix == 10)
    precondition(Builder.buildBlock(intR, urlR).resolvers.count == 2)
    precondition(Builder.buildBlock(intR, urlR, boolR).resolvers.count == 3)
    precondition(Builder.buildBlock(intR, urlR, boolR, doubleR).resolvers.count == 4)
    precondition(Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt).resolvers.count == 5)
    precondition(Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble).resolvers.count == 6)
    precondition(Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble, attr).resolvers.count == 7)
    precondition(
        Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search).resolvers.count == 8
    )
    precondition(
        Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search, intR).resolvers.count == 9
    )
    precondition(
        Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search, intR, urlR).resolvers.count == 10
    )
    precondition(
        Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search, intR, urlR, boolR)
            .resolvers.count == 11
    )
    precondition(
        Builder.buildBlock(intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search, intR, urlR, boolR, doubleR)
            .resolvers.count == 12
    )
    precondition(
        Builder.buildBlock(
            intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search, intR, urlR, boolR, doubleR, fromInt
        ).resolvers.count == 13
    )
    precondition(
        Builder.buildBlock(
            intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search,
            intR, urlR, boolR, doubleR, fromInt, fromDouble
        ).resolvers.count == 14
    )
    precondition(
        Builder.buildBlock(
            intR, urlR, boolR, doubleR, fromInt, fromDouble, attr, search,
            intR, urlR, boolR, doubleR, fromInt, fromDouble, attr
        ).resolvers.count == 15
    )
}

func testResolverHostConversions() {
    let context = IntentParameterContext<Int>(title: "n", isOptional: false)
    let parsed = try? IntFromStringResolver(radix: 16).hostResolve(from: "2a", context: context)
    precondition(parsed == 42)
    let hex = IntFromStringResolver(radix: 16)
    precondition(hex.radix == 16)
    let doubleContext = IntentParameterContext<Double>(title: "d")
    precondition((try? DoubleFromIntResolver().hostResolve(from: 7, context: doubleContext)) == 7)
    let intFromDouble = IntFromDoubleResolver(roundingRule: .towardZero)
    precondition(intFromDouble.roundingRule == .towardZero)
    let rounded = try? intFromDouble.hostResolve(
        from: 3.9,
        context: IntentParameterContext<Int>(title: "i")
    )
    precondition(rounded == 3)
    let url = try? URLFromStringResolver().hostResolve(
        from: "https://example.test",
        context: IntentParameterContext<URL>(title: "u")
    )
    precondition(url?.host == "example.test")
    let flag = try? BoolFromStringResolver().hostResolve(
        from: "true",
        context: IntentParameterContext<Bool>(title: "b")
    )
    precondition(flag == true)
    let no = try? BoolFromStringResolver().hostResolve(
        from: "nope",
        context: IntentParameterContext<Bool>(title: "b")
    )
    precondition(no == nil)
    let parsedDouble = try? DoubleFromStringResolver().hostResolve(
        from: "1.5",
        context: IntentParameterContext<Double>(title: "d")
    )
    precondition(parsedDouble == 1.5)
    let attributed = try? AttributedStringFromStringResolver().hostResolve(
        from: "hello",
        context: IntentParameterContext<AttributedString>(title: "a")
    )
    precondition(String(describing: attributed).contains("hello"))
    let stringed = try? StringFromIntResolver<Int, String>().hostResolve(
        from: 9,
        context: IntentParameterContext<String>(title: "s")
    )
    precondition(stringed == "9")
}

func testIntentResultActionButtonAndSnippetFactories() {
    let buttonIntent = OpenURLIntent(URL(string: "https://example.test")!)
    let snippet = EmptySnippetIntent()
    let action: IntentResultContainer<Never, Never, Never, Never> =
        .result(actionButtonIntent: buttonIntent)
    precondition(action.actionButtonIntent != nil)
    let actionDialog: IntentResultContainer<Never, Never, Never, IntentDialog> =
        .result(actionButtonIntent: buttonIntent, dialog: IntentDialog("tap"))
    precondition(actionDialog.dialog?.text == "tap")
    let actionId: IntentResultContainer<Never, Never, Never, Never> =
        .result(actionButtonIntent: buttonIntent, activityIdentifier: "scene.1")
    precondition(actionId.activityIdentifier == "scene.1")
    let actionIdDialog: IntentResultContainer<Never, Never, Never, IntentDialog> =
        .result(
            actionButtonIntent: buttonIntent,
            activityIdentifier: "scene.2",
            dialog: IntentDialog("go")
        )
    precondition(actionIdDialog.activityIdentifier == "scene.2")
    let valued: IntentResultContainer<String, Never, Never, Never> =
        .result(value: "ok", actionButtonIntent: buttonIntent)
    precondition(valued.value == "ok")
    let valuedDialog: IntentResultContainer<String, Never, Never, IntentDialog> =
        .result(value: "ok", actionButtonIntent: buttonIntent, dialog: IntentDialog("d"))
    precondition(valuedDialog.dialog?.text == "d")
    let valuedId: IntentResultContainer<String, Never, Never, Never> =
        .result(value: "ok", actionButtonIntent: buttonIntent, activityIdentifier: "a")
    precondition(valuedId.activityIdentifier == "a")
    let valuedIdDialog: IntentResultContainer<String, Never, Never, IntentDialog> =
        .result(
            value: "ok",
            actionButtonIntent: buttonIntent,
            activityIdentifier: "b",
            dialog: IntentDialog("e")
        )
    precondition(valuedIdDialog.activityIdentifier == "b")
    let snippetOnly: IntentResultContainer<Never, Never, _SnippetIntentContainer, Never> =
        .result(snippetIntent: snippet)
    precondition(snippetOnly.snippetIntent != nil)
    let snippetDialog: IntentResultContainer<Never, Never, _SnippetIntentContainer, IntentDialog> =
        .result(dialog: IntentDialog("s"), snippetIntent: snippet)
    precondition(snippetDialog.dialog?.text == "s")
    let snippetValue: IntentResultContainer<String, Never, _SnippetIntentContainer, Never> =
        .result(value: "v", snippetIntent: snippet)
    precondition(snippetValue.value == "v")
    let snippetValueDialog: IntentResultContainer<String, Never, _SnippetIntentContainer, IntentDialog> =
        .result(value: "v", dialog: IntentDialog("sd"), snippetIntent: snippet)
    precondition(snippetValueDialog.dialog?.text == "sd")
    let openedSnippet: IntentResultContainer<Never, Never, _SnippetIntentContainer, Never> =
        .result(opensIntent: buttonIntent, snippetIntent: snippet)
    precondition(openedSnippet.opensIntent != nil)
    let openedSnippetDialog: IntentResultContainer<Never, Never, _SnippetIntentContainer, IntentDialog> =
        .result(opensIntent: buttonIntent, dialog: IntentDialog("od"), snippetIntent: snippet)
    precondition(openedSnippetDialog.dialog?.text == "od")
    let valuedOpenSnippet: IntentResultContainer<String, Never, _SnippetIntentContainer, Never> =
        .result(value: "v", opensIntent: buttonIntent, snippetIntent: snippet)
    precondition(valuedOpenSnippet.value == "v")
    let valuedOpenSnippetDialog: IntentResultContainer<String, Never, _SnippetIntentContainer, IntentDialog> =
        .result(
            value: "v",
            opensIntent: buttonIntent,
            dialog: IntentDialog("vod"),
            snippetIntent: snippet
        )
    precondition(valuedOpenSnippetDialog.dialog?.text == "vod")
    let valuedOpen: IntentResultContainer<String, OpenURLIntent, Never, Never> =
        .result(value: "v", opensIntent: buttonIntent)
    precondition(valuedOpen.value == "v")
    let valuedOpenDialog: IntentResultContainer<String, OpenURLIntent, Never, IntentDialog> =
        .result(value: "v", opensIntent: buttonIntent, dialog: IntentDialog("vo"))
    precondition(valuedOpenDialog.dialog?.text == "vo")
}

func testIntentResultOpensIntentViewFactories() {
    let opened = OpenURLIntent(URL(string: "https://example.test")!)
    let viewOnly: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(opensIntent: opened, view: EmptyView())
    precondition(viewOnly.opensIntent != nil)
    let typedView: IntentResultContainer<Never, OpenURLIntent, _SnippetViewContainer, Never> =
        .result(opensIntent: opened, view: EmptyView())
    precondition(typedView.opensIntent != nil)
    let dialogView: IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> =
        .result(opensIntent: opened, dialog: IntentDialog("v"), view: EmptyView())
    precondition(dialogView.dialog?.text == "v")
    let typedDialogView: IntentResultContainer<Never, OpenURLIntent, _SnippetViewContainer, IntentDialog> =
        .result(opensIntent: opened, dialog: IntentDialog("tv"), view: EmptyView())
    precondition(typedDialogView.dialog?.text == "tv")
    let content: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(opensIntent: opened, content: { EmptyView() })
    precondition(content.opensIntent != nil)
    let typedContent: IntentResultContainer<Never, OpenURLIntent, _SnippetViewContainer, Never> =
        .result(opensIntent: opened, content: { EmptyView() })
    precondition(typedContent.opensIntent != nil)
    let dialogContent: IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> =
        .result(opensIntent: opened, dialog: IntentDialog("c"), content: { EmptyView() })
    precondition(dialogContent.dialog?.text == "c")
    let typedDialogContent: IntentResultContainer<Never, OpenURLIntent, _SnippetViewContainer, IntentDialog> =
        .result(opensIntent: opened, dialog: IntentDialog("tc"), content: { EmptyView() })
    precondition(typedDialogContent.dialog?.text == "tc")
    let valuedView: IntentResultContainer<String, Never, _SnippetViewContainer, Never> =
        .result(value: "x", opensIntent: opened, view: EmptyView())
    precondition(valuedView.value == "x")
    let typedValuedView: IntentResultContainer<String, OpenURLIntent, _SnippetViewContainer, Never> =
        .result(value: "x", opensIntent: opened, view: EmptyView())
    precondition(typedValuedView.value == "x")
    let valuedDialogView: IntentResultContainer<String, Never, _SnippetViewContainer, IntentDialog> =
        .result(value: "x", opensIntent: opened, dialog: IntentDialog("vd"), view: EmptyView())
    precondition(valuedDialogView.dialog?.text == "vd")
    let typedValuedDialogView: IntentResultContainer<String, OpenURLIntent, _SnippetViewContainer, IntentDialog> =
        .result(value: "x", opensIntent: opened, dialog: IntentDialog("tvd"), view: EmptyView())
    precondition(typedValuedDialogView.dialog?.text == "tvd")
    let valuedContent: IntentResultContainer<String, Never, _SnippetViewContainer, Never> =
        .result(value: "x", opensIntent: opened, content: { EmptyView() })
    precondition(valuedContent.value == "x")
    let typedValuedContent: IntentResultContainer<String, OpenURLIntent, _SnippetViewContainer, Never> =
        .result(value: "x", opensIntent: opened, content: { EmptyView() })
    precondition(typedValuedContent.value == "x")
    let valuedDialogContent: IntentResultContainer<String, Never, _SnippetViewContainer, IntentDialog> =
        .result(value: "x", opensIntent: opened, dialog: IntentDialog("vc"), content: { EmptyView() })
    precondition(valuedDialogContent.dialog?.text == "vc")
    let typedValuedDialogContent: IntentResultContainer<String, OpenURLIntent, _SnippetViewContainer, IntentDialog> =
        .result(value: "x", opensIntent: opened, dialog: IntentDialog("tvc"), content: { EmptyView() })
    precondition(typedValuedDialogContent.dialog?.text == "tvc")
    let dialogOnlyView: IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> =
        .result(dialog: IntentDialog("dv"), view: EmptyView())
    precondition(dialogOnlyView.dialog?.text == "dv")
    let dialogOnlyContent: IntentResultContainer<Never, Never, _SnippetViewContainer, IntentDialog> =
        .result(dialog: IntentDialog("dc"), content: { EmptyView() })
    precondition(dialogOnlyContent.dialog?.text == "dc")
}

func testIntentFileHostDataCodableAndRemovedOnCompletion() {
    let bytes = Data([0x01, 0x02, 0x03])
    var memory = IntentFile(data: bytes, filename: "note.bin", type: .data)
    memory.removedOnCompletion = true
    precondition(memory.fileURL == nil)
    precondition(memory.removedOnCompletion == true)
    precondition(memory.localizedStringResource.key == "note.bin")
    let hostBytes = try? memory.hostData(contentType: .data)
    precondition(hostBytes == bytes)
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
    let written = try? memory.hostFile(contentType: .data, destinationDirectory: directory)
    precondition(written?.openedInPlace == false)
    precondition(written?.fileURL.lastPathComponent == "note.bin")
    let onDisk = IntentFile(
        fileURL: written!.fileURL,
        filename: "note.bin",
        type: .data
    )
    precondition(onDisk.fileURL?.lastPathComponent == "note.bin")
    let inPlace = try? onDisk.hostFile(contentType: .data)
    precondition(inPlace?.openedInPlace == true)
    let encoded = try? JSONEncoder().encode(memory)
    precondition(encoded != nil)
    let decoded = try? JSONDecoder().decode(IntentFile.self, from: encoded!)
    precondition(decoded?.filename == "note.bin")
    precondition(decoded?.removedOnCompletion == true)
    precondition(decoded?.data == bytes)
    precondition(IntentFile.IntentFileError.unreadable.errorCode == 1)
    precondition(IntentFile.IntentFileError.unsupportedType.errorUserInfo["errorCode"] as? Int == 2)
}

func testIntentPersonLocalizedStringAndEquality() {
    let ada = IntentPerson(
        identifier: .applicationDefined("ada"),
        name: .displayName("Ada"),
        handle: IntentPerson.Handle(emailAddress: "ada@example.test")
    )
    let same = IntentPerson(
        identifier: .applicationDefined("ada"),
        name: .displayName("Ada"),
        handle: IntentPerson.Handle(emailAddress: "ada@example.test")
    )
    let other = IntentPerson(
        identifier: .applicationDefined("grace"),
        name: .displayName("Grace"),
        handle: IntentPerson.Handle(emailAddress: "grace@example.test")
    )
    precondition(ada == same)
    precondition(ada != other)
    precondition(ada.localizedStringResource.key == "Ada")
    precondition(ada.identifier == .applicationDefined("ada"))
    precondition(ada.handle?.value != other.handle?.value)
}

func testAppIntentErrorRemainingCatalogAndLocalizedResource() {
    precondition(AppIntentError.Unrecoverable.unknown.description == "unknown")
    precondition(AppIntentError.Unrecoverable.notAllowed.description == "notAllowed")
    precondition(AppIntentError.Unrecoverable.entityNotFound.description == "entityNotFound")
    precondition(AppIntentError.Unrecoverable.networkFailure.description == "networkFailure")
    precondition(AppIntentError.Unrecoverable.partialFailure.description == "partialFailure")
    precondition(
        AppIntentError.Unrecoverable.featureCurrentlyRestricted.description == "featureCurrentlyRestricted"
    )
    precondition(AppIntentError.PermissionRequired.localNetwork.description == "localNetwork")
    precondition(AppIntentError.PermissionRequired.photos.description == "photos")
    precondition(AppIntentError.PermissionRequired.contacts.description == "contacts")
    precondition(AppIntentError.PermissionRequired.bluetooth.description == "bluetooth")
    let precise = AppIntentError.PermissionRequired.location(precise: true)
    precondition(precise.description == "locationPrecise")
    let coarse = AppIntentError.PermissionRequired.location(precise: false)
    precondition(coarse.description == "location")
    precondition(AppIntentError.UserActionRequired.accountSetup.description == "accountSetup")
    precondition(AppIntentError.UserActionRequired.signin.description == "signin")
    precondition(AppIntentError.restartPerform.localizedStringResource.key == "restartPerform")
}
