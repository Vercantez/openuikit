import Foundation
import AppIntents

private struct DepthNote: TransientAppEntity {
    typealias DefaultQuery = _TransientAppEntityQuery<DepthNote>
    var id: UUID
    var title: String

    init() {
        id = UUID()
        title = ""
    }

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Note" }
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: title)
    }
}

private struct DepthNoteQuery: EnumerableEntityQuery, EntityStringQuery {
    typealias Entity = DepthNote
    init() {}
    func entities(for identifiers: [UUID]) async throws -> [DepthNote] {
        EntityResolutionEngine.entities(for: identifiers, as: DepthNote.self)
    }
    func suggestedEntities() async throws -> [DepthNote] {
        EntityResolutionEngine.suggestedEntities(DepthNote.self)
    }
    func defaultResult() async -> DepthNote? {
        EntityResolutionEngine.defaultResult(DepthNote.self)
    }
    func allEntities() async throws -> [DepthNote] {
        EntityResolutionEngine.allEntities(DepthNote.self)
    }
    func entities(matching string: String) async throws -> [DepthNote] {
        EntityResolutionEngine.entities(matching: string, as: DepthNote.self)
    }
}

private struct OpenNoteIntent: OpenIntent, ForegroundContinuableIntent, SystemIntent {
    var target: DepthNote
    init(target: DepthNote) { self.target = target }
    static var title: LocalizedStringResource { "Open Note" }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    func perform() async throws -> some IntentResult {
        .result()
    }
}

private struct DepthFeedIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Feed" }
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }

    @Parameter(title: "URL", default: "https://example.test")
    var url: String

    @Parameter(title: "Count", default: 1)
    var count: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$url)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: url, dialog: IntentDialog("added=\(url)"))
    }

    func hostResult() -> IntentResultContainer<String, Never, Never, IntentDialog> {
        .result(value: url, dialog: IntentDialog("added=\(url)"))
    }
}

private struct DepthCatalog: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DepthFeedIntent(),
            phrases: [
                "Add feed with \(.applicationName) named \(\.$url)"
            ],
            shortTitle: "Add Feed",
            systemImageName: "plus"
        )
    }
}

func testEntityPropertyStoresTitleIdentifierAndValue() {
    let property = EntityProperty<String>(
        title: LocalizedStringResource("Name"),
        identifier: "name"
    )
    property.wrappedValue = "Ada"
    precondition(property.wrappedValue == "Ada")
    precondition(property.title.key == "Name")
    precondition(property.identifier == "name")
    precondition(property.projectedValue.wrappedValue == "Ada")
    precondition(property.isOptional == false)
    let alias: Property<String> = Property(title: LocalizedStringResource("Alias"))
    alias.wrappedValue = "ok"
    precondition(alias.wrappedValue == "ok")
}

func testEntityPropertyGetterAndOptionalUnset() {
    let computed = EntityProperty<Int>(
        title: LocalizedStringResource("Count"),
        identifier: "count",
        getter: { 7 }
    )
    precondition(computed.wrappedValue == 7)
    let optional = EntityProperty<String?>(title: LocalizedStringResource("Maybe"))
    precondition(optional.isOptional == true)
    precondition(optional.wrappedValue == nil)
}

func testIntentParameterInputOptionsAndOptionsProviderResolution() {
    let options = String.IntentInputOptions(
        keyboardType: .URL,
        capitalizationType: .none,
        multiline: false,
        autocorrect: false,
        smartQuotes: false,
        smartDashes: false
    )
    let parameter = IntentParameter<String>(
        title: LocalizedStringResource("URL"),
        description: LocalizedStringResource("Feed URL"),
        default: "https://example.test",
        inputOptions: options,
        requestValueDialog: IntentDialog("need url")
    )
    precondition(parameter.wrappedValue == "https://example.test")
    precondition(parameter.inputOptions?.keyboardType == .URL)
    precondition(parameter.inputOptions?.capitalizationType == String.IntentInputOptions.CapitalizationType.none)
    precondition(parameter.inputOptions?.multiline == false)
    let withProvider = IntentParameter<String>(
        title: LocalizedStringResource("Site"),
        inputOptions: options,
        optionsProvider: DepthNoteQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    withProvider.attachResolvedOptions(["hn", "lobsters"])
    precondition(withProvider.resolvedDynamicOptions.count == 2)
}

func testIntentInputOptionsKeyboardAndCapitalizationTable() {
    let keyboard: [String.IntentInputOptions.KeyboardType] = [
        .asciiCapable, .numbersAndPunctuation, .URL, .default, .numberPad
    ]
    precondition(Set(keyboard).count == 5)
    let caps: [String.IntentInputOptions.CapitalizationType] = [
        .allCharacters, .none, .words, .sentences
    ]
    precondition(Set(caps).count == 4)
    precondition(String.IntentInputOptions.KeyboardType.URL != .numberPad)
    precondition(String.IntentInputOptions.CapitalizationType.words != .sentences)
}

func testEntityResolutionEngineSuggestedEntitiesForAndDefault() {
    EntityResolutionEngine.reset()
    let hn = DepthNote(title: "Hacker News")
    let blog = DepthNote(title: "Blog")
    EntityResolutionEngine.register([hn, blog], default: hn)
    let suggested = EntityResolutionEngine.suggestedEntities(DepthNote.self)
    precondition(suggested.count == 2)
    let byId = EntityResolutionEngine.entities(for: [hn.id], as: DepthNote.self)
    precondition(byId.count == 1)
    precondition(byId[0].title == "Hacker News")
    let missing = EntityResolutionEngine.entities(for: [UUID()], as: DepthNote.self)
    precondition(missing.isEmpty)
    let fallback = EntityResolutionEngine.defaultResult(DepthNote.self)
    precondition(fallback?.title == "Hacker News")
    let matched = EntityResolutionEngine.entities(matching: "Hack", as: DepthNote.self)
    precondition(matched.count == 1)
    let host = AppIntentsHost.suggestedEntities(DepthNote.self)
    precondition(host.count == 2)
}

func testEnumerableEntityQueryHostAllEntities() {
    EntityResolutionEngine.reset()
    let note = DepthNote(title: "Only")
    EntityResolutionEngine.register([note], default: note)
    let all = EntityResolutionEngine.allEntities(DepthNote.self)
    precondition(all.count == 1)
    _ = DepthNote.defaultQuery
}

func testTransientAppEntityDefaultQueryAndUUID() {
    let note = DepthNote()
    precondition(note.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    precondition(DepthNote.typeDisplayRepresentation.name == "Note")
    EntityResolutionEngine.reset()
    EntityResolutionEngine.register([note], default: note)
    let suggested = EntityResolutionEngine.suggestedEntities(DepthNote.self)
    precondition(suggested[0].id == note.id)
}

func testParameterSummaryEvaluatesInterpolationToDisplayString() {
    let summary = DepthFeedIntent.Summary("Add \(\.$url)")
    precondition(summary.evaluatedDisplayString == "Add ${parameter}")
    let literal: IntentParameterSummary<DepthFeedIntent> = "plain"
    precondition(literal.evaluatedDisplayString == "Add ${parameter}" || literal.evaluatedDisplayString == "plain")
    precondition(literal.evaluatedDisplayString == "plain")
    let fromString = IntentParameterSummary<DepthFeedIntent>(
        ParameterSummaryString<DepthFeedIntent>("Feed \(\.$url)")
    )
    precondition(fromString.evaluatedDisplayString == "Feed ${parameter}")
    let empty = IntentParameterSummary<DepthFeedIntent>()
    precondition(empty.evaluatedDisplayString.isEmpty)
}

func testParameterSummarySwitchCaseWhenEvaluates() {
    let one = DepthFeedIntent.Summary("one")
    let two = DepthFeedIntent.Summary("two")
    let other = DepthFeedIntent.Summary("other")
    let switched = ParameterSummarySwitchCondition<
        DepthFeedIntent, Int, ParameterSummaryCaseCondition<
            DepthFeedIntent, Int, IntentParameterSummary<DepthFeedIntent>
        >
    >(
        evaluatedDisplayString: one.evaluatedDisplayString
    )
    precondition(switched.evaluatedDisplayString == "one")
    let caseOne = ParameterSummaryCaseCondition<
        DepthFeedIntent, Int, IntentParameterSummary<DepthFeedIntent>
    >(value: 1, summary: two.evaluatedDisplayString)
    precondition(caseOne.evaluatedDisplayString == "two")
    let whenOn = ParameterSummaryWhenCondition<
        DepthFeedIntent, Bool, IntentParameterSummary<DepthFeedIntent>
    >(condition: true, then: "on", otherwise: "off")
    precondition(whenOn.evaluatedDisplayString == "on")
    let whenOff = ParameterSummaryWhenCondition<
        DepthFeedIntent, Bool, IntentParameterSummary<DepthFeedIntent>
    >(condition: false, then: "on", otherwise: "off")
    precondition(whenOff.evaluatedDisplayString == "off")
    let _: DepthFeedIntent.Switch<
        Int,
        ParameterSummaryCaseCondition<DepthFeedIntent, Int, IntentParameterSummary<DepthFeedIntent>>
    >.Type = DepthFeedIntent.Switch<
        Int,
        ParameterSummaryCaseCondition<DepthFeedIntent, Int, IntentParameterSummary<DepthFeedIntent>>
    >.self
    let _: DepthFeedIntent.Case<DepthFeedIntent, Int, IntentParameterSummary<DepthFeedIntent>>.Type =
        DepthFeedIntent.Case<DepthFeedIntent, Int, IntentParameterSummary<DepthFeedIntent>>.self
    let _: DepthFeedIntent.When<DepthFeedIntent, Bool, IntentParameterSummary<DepthFeedIntent>>.Type =
        DepthFeedIntent.When<DepthFeedIntent, Bool, IntentParameterSummary<DepthFeedIntent>>.self
    _ = other
}

func testAppShortcutParameterTokenExpansion() {
    precondition(DepthCatalog.appShortcuts.count == 1)
    precondition(
        DepthCatalog.appShortcuts[0].phrases[0].template ==
            "Add feed with ${applicationName} named ${parameter}"
    )
}

func testAssistantSchemasRequiredParameterSets() {
    _ = AssistantSchemas.CameraEnum.self
    _ = AssistantSchemas.MailEntity.self
    _ = AssistantSchemas.MailIntent.self
    precondition(!AssistantSchemaParameterCatalog.requiredParameterSets.isEmpty)
    for (family, parameters) in AssistantSchemaParameterCatalog.requiredParameterSets {
        precondition(!parameters.isEmpty)
        precondition(AssistantSchemaParameterCatalog.parameters(for: family) == parameters)
        for name in parameters {
            precondition(AssistantSchemaParameterCatalog.token(family: family, parameter: name) == name)
        }
    }
    let enums = AssistantSchemas.EnumSchema()
    precondition(enums.captureMode.name == "captureMode")
    precondition(enums.captureDevice.name == "captureDevice")
    precondition(enums.captureDuration.name == "captureDuration")
    let entities = AssistantSchemas.EntitySchema()
    precondition(entities.draft.name == "draft")
    precondition(entities.account.name == "account")
    precondition(entities.mailbox.name == "mailbox")
    precondition(entities.message.name == "message")
    let intents = AssistantSchemas.IntentSchema()
    precondition(intents.search.name == "search")
    let wrapped = AssistantSchema(AssistantSchemas.EnumSchema("camera"))
    _ = wrapped
    precondition(AssistantSchemas.EnumSchema.camera.name == "camera")
    precondition(AssistantSchemas.EntitySchema.mail.name == "mail")
    precondition(AssistantSchemas.IntentSchema.photos.name == "photos")
}

func testOpenIntentAndForegroundContinuableIntent() {
    let note = DepthNote(title: "Open me")
    let intent = OpenNoteIntent(target: note)
    precondition(intent.target.title == "Open me")
    precondition(OpenNoteIntent.openAppWhenRun == true)
    precondition(OpenNoteIntent.authenticationPolicy == .alwaysAllowed)
    let _: (any OpenIntent) = intent
    let _: (any ForegroundContinuableIntent) = intent
    let _: (any SystemIntent) = intent
}

func testIntentParameterAllInitOverloadsTitleDescriptionDefault() {
    let full = IntentParameter<String>(
        title: LocalizedStringResource("Query"),
        description: LocalizedStringResource("Search"),
        default: "q",
        requestValueDialog: IntentDialog("need"),
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    precondition(full.wrappedValue == "q")
    precondition(full.metadata.title == "Query")
    precondition(full.metadata.description == "Search")
    precondition(full.metadata.requestValueDialog?.text == "need")
    precondition(full.projectedValue.wrappedValue == "q")
    let bare = IntentParameter<String>(title: "Bare")
    bare.wrappedValue = "typed"
    precondition(bare.wrappedValue == "typed")
}

func testSampleIntentHostResolutionAndResult() {
    let intent = DepthFeedIntent()
    intent.url = "https://example.test/rss"
    let summary = DepthFeedIntent.parameterSummary
    precondition(summary.evaluatedDisplayString == "Add ${parameter}")
    let result = intent.hostResult()
    precondition(result.value == "https://example.test/rss")
    precondition(result.dialog?.text == "added=https://example.test/rss")
    let hosted = AppIntentsHost.performOnHost(intent, result: result)
    precondition(hosted.value == "https://example.test/rss")
    EntityResolutionEngine.reset()
    let note = DepthNote(title: "Feed")
    EntityResolutionEngine.register([note], default: note)
    precondition(EntityResolutionEngine.defaultResult(DepthNote.self)?.title == "Feed")
}

func testDependencyWrapperReadsManager() {
    let manager = AppDependencyManager()
    manager.reset()
    manager.add(key: "clock", dependency: "tick")
    let dependency = AppDependency<String>(key: "clock", manager: manager)
    precondition(dependency.wrappedValue == "tick")
    precondition(dependency.projectedValue.wrappedValue == "tick")
}

func testIntentResultFamilyValueDialogViewOpensIntent() {
    let empty = IntentResultValue.result()
    precondition(empty.dialog == nil)
    let dialog = IntentResultValue.result(dialog: IntentDialog("hi"))
    precondition(dialog.dialog?.text == "hi")
    let valued: IntentResultContainer<String, Never, Never, Never> = .result(value: "v")
    precondition(valued.value == "v")
    let valuedDialog: IntentResultContainer<String, Never, Never, IntentDialog> =
        .result(value: "v", dialog: IntentDialog("d"))
    precondition(valuedDialog.dialog?.text == "d")
    let opened: IntentResultContainer<Never, OpenURLIntent, Never, Never> =
        .result(opensIntent: OpenURLIntent(URL(fileURLWithPath: "/tmp")))
    precondition(opened.opensIntent != nil)
    let view: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(view: ShortcutsLink())
    precondition(view.value == nil)
}
