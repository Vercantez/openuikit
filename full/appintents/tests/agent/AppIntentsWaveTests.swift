import Foundation
import AppIntents

private struct WaveNote: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave Note" }
    static var defaultQuery = WaveNoteQuery()
    var id: String
    var title: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: title)
    }
}

private struct WaveNoteQuery: EntityPropertyQuery, EntityStringQuery {
    typealias Entity = WaveNote
    typealias ComparatorMappingType = String
    init() {}
    func entities(for identifiers: [String]) async throws -> [WaveNote] {
        EntityResolutionEngine.entities(for: identifiers, as: WaveNote.self)
    }
    func suggestedEntities() async throws -> [WaveNote] {
        EntityResolutionEngine.suggestedEntities(WaveNote.self)
    }
    func defaultResult() async -> WaveNote? {
        EntityResolutionEngine.defaultResult(WaveNote.self)
    }
    func entities(matching string: String) async throws -> [WaveNote] {
        EntityResolutionEngine.entities(matching: string, as: WaveNote.self)
    }
}

private struct WaveOpenIntent: OpenIntent, SystemIntent, ForegroundContinuableIntent {
    var target: WaveNote
    init(target: WaveNote) { self.target = target }
    static var title: LocalizedStringResource { "Open Wave Note" }
    func perform() async throws -> some IntentResult {
        .result()
    }
}

private struct WaveDeleteIntent: DeleteIntent {
    typealias Entity = WaveNote
    var entities: [WaveNote]
    static var title: LocalizedStringResource { "Delete Wave Notes" }
    func perform() async throws -> some IntentResult {
        .result()
    }
}

private struct WaveSetTitleIntent: SetValueIntent {
    typealias ValueType = String
    var value: String
    static var title: LocalizedStringResource { "Set Title" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: value)
    }
}

private struct WaveProgressIntent: ProgressReportingIntent {
    static var title: LocalizedStringResource { "Import" }
    func perform() async throws -> some IntentResult {
        .result()
    }
}

private struct WaveWidgetIntent: WidgetConfigurationIntent {
    typealias PerformResult = IntentResultValue
    static var title: LocalizedStringResource { "Wave Widget" }
}

private struct WaveFileEntity: FileEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave File" }
    static var defaultQuery = WaveFileQuery()
    var id: FileEntityIdentifier
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id.entityIdentifierString)
    }
}

private struct WaveFileQuery: EntityQuery {
    typealias Entity = WaveFileEntity
    init() {}
    func entities(for identifiers: [FileEntityIdentifier]) async throws -> [WaveFileEntity] {
        identifiers.map { WaveFileEntity(id: $0) }
    }
}

func testEntityPropertyClassAndProjectedValue() {
    let property = EntityProperty<String>(
        title: LocalizedStringResource("Name"),
        identifier: "name"
    )
    property.wrappedValue = "Ada"
    precondition(property.wrappedValue == "Ada")
    precondition(property.projectedValue.wrappedValue == "Ada")
    precondition(property.title.key == "Name")
    precondition(property.description == "Name")
    precondition(property.identifier == "name")
    _ = EntityProperty<String>()
}

func testEntityPropertyIdentifierTitleInit() {
    let named = EntityProperty<String>(identifier: "slug", title: LocalizedStringResource("Slug"))
    named.wrappedValue = "hn"
    precondition(named.identifier == "slug")
    precondition(named.title.key == "Slug")
    precondition(named.wrappedValue == "hn")
    let identifierOnly = EntityProperty<Int>(identifier: "count")
    identifierOnly.wrappedValue = 3
    precondition(identifierOnly.identifier == "count")
    precondition(identifierOnly.wrappedValue == 3)
}

func testEntityPropertyIndexingKeyAndCustomKey() {
    let indexed = EntityProperty<String>(
        title: LocalizedStringResource("Display"),
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    indexed.wrappedValue = "shown"
    precondition(indexed.wrappedValue == "shown")
    precondition(indexed.indexingKeyName == "indexingKey")
    precondition(indexed.indexingKeyPath != nil)
    let custom = EntityProperty<String>(
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "com.openuikit.wave")
    )
    custom.wrappedValue = "k"
    precondition(custom.customIndexingKey?.keyName == "com.openuikit.wave")
    precondition(custom.identifier == "com.openuikit.wave")
    let withIdent = EntityProperty<String>(
        identifier: "title",
        title: LocalizedStringResource("Title"),
        indexingKey: \CSSearchableItemAttributeSet.title
    )
    precondition(withIdent.identifier == "title")
}

func testEntityPropertyGetterFromRegisteredEntity() {
    EntityResolutionEngine.reset()
    let note = WaveNote(id: "n1", title: "Indexed")
    EntityResolutionEngine.register([note], default: note)
    let property = EntityProperty<String>(
        identifier: "title",
        title: LocalizedStringResource("Title"),
        indexingKey: \CSSearchableItemAttributeSet.displayName,
        getter: \WaveNote.title
    )
    precondition(property.wrappedValue == "Indexed")
}

func testIntentParameterDateKindStoresKind() {
    let when = Date(timeIntervalSinceReferenceDate: 100)
    let parameter = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        description: LocalizedStringResource("Date"),
        default: when,
        kind: .date,
        requestValueDialog: IntentDialog("need date")
    )
    precondition(parameter.wrappedValue == when)
    precondition(parameter.dateKind == .date)
    precondition(parameter.metadata.requestValueDialog?.text == "need date")
    let timeOnly = IntentParameter<Date>(
        title: LocalizedStringResource("Time"),
        kind: .time
    )
    timeOnly.wrappedValue = when
    precondition(timeOnly.dateKind == .time)
}

func testIntentParameterBoolAndURLDefaults() {
    let flag = IntentParameter<Bool>(
        title: LocalizedStringResource("On"),
        default: true
    )
    precondition(flag.wrappedValue == true)
    flag.wrappedValue = false
    precondition(flag.wrappedValue == false)
    let url = URL(fileURLWithPath: "/tmp/wave")
    let link = IntentParameter<URL>(
        title: LocalizedStringResource("Link"),
        default: url
    )
    precondition(link.wrappedValue == url)
}

func testIntentParameterFileSupportedContentTypes() {
    let file = IntentFile(data: Data([9]), filename: "x.bin", type: .data)
    let parameter = IntentParameter<IntentFile>(
        title: LocalizedStringResource("Attachment"),
        default: file,
        supportedContentTypes: [.data, .image]
    )
    precondition(parameter.wrappedValue.filename == "x.bin")
    precondition(parameter.metadata.supportedContentTypes == [.data, .image])
}

func testFileEntityIdentifierFileDraftAndParse() {
    let url = URL(fileURLWithPath: "/tmp/wave.txt")
    let file: FileEntityIdentifier
    do {
        file = try FileEntityIdentifier.file(url: url)
    } catch {
        preconditionFailure("file identifier must succeed: \(error)")
    }
    precondition(file.isDraft == false)
    precondition(file.entityIdentifierString.contains("wave.txt") || file.url.path.hasSuffix("wave.txt"))
    let draft = FileEntityIdentifier.draft(identifier: "scratch")
    precondition(draft.isDraft == true)
    precondition(draft.draftIdentifier == "scratch")
    precondition(draft.entityIdentifierString == "draft:scratch")
    let parsedDraft = FileEntityIdentifier.entityIdentifier(for: "draft:scratch")
    precondition(parsedDraft?.isDraft == true)
    let parsedPath = FileEntityIdentifier.entityIdentifier(for: "/tmp/wave.txt")
    precondition(parsedPath?.isDraft == false)
    precondition(FileEntityIdentifier.entityIdentifier(for: "") == nil)
    let entity = WaveFileEntity(id: file)
    precondition(entity.id.url.path.hasSuffix("wave.txt"))
}

func testIntentPaymentMethodTypeTableAndDisplay() {
    let types: [IntentPaymentMethod.PaymentType] = [
        .debit, .store, .credit, .prepaid, .savings, .unknown, .applePay, .checking, .brokerage
    ]
    precondition(Set(types).count == 9)
    precondition(IntentPaymentMethod.PaymentType.applePay != .checking)
    let method = IntentPaymentMethod(
        type: .applePay,
        name: LocalizedStringResource("Card"),
        identificationHint: "••90"
    )
    precondition(method.paymentType == .applePay)
    precondition(method.name == "Card")
    precondition(method.identificationHint == "••90")
    precondition(method.displayRepresentation.title.key == "Card")
    precondition(IntentPaymentMethod.typeDisplayRepresentation.name == "Payment Method")
}

func testIntentCurrencyAmountAmountAndCode() {
    let amount = IntentCurrencyAmount(amount: Decimal(12.5), currencyCode: "USD")
    precondition(amount.amount == Decimal(12.5))
    precondition(amount.currencyCode == "USD")
    precondition(amount.displayRepresentation.title.key.contains("USD"))
    precondition(amount.localizedStringResource.key.contains("USD"))
    precondition(IntentCurrencyAmount.typeDisplayRepresentation.name == "Currency Amount")
}

func testIntentPersonHandleLabelsAndParameterModes() {
    let labels: [IntentPerson.Handle.Label] = [
        .home, .main, .work, .other, .pager, .custom("desk"), .iPhone, .mobile, .school, .homeFax, .workFax
    ]
    precondition(Set(labels).count == 11)
    let modes: [IntentPerson.ParameterMode] = [.emailOrPhone, .email, .phone, .contact]
    precondition(Set(modes).count == 4)
    precondition(IntentPerson.ParameterMode.email.rawValue == "email")
    let phone = IntentPerson.Handle(phoneNumber: "+1555", label: .mobile)
    precondition(phone.label == .mobile)
    let appDefined = IntentPerson.Handle(applicationDefined: "x", label: "desk")
    precondition(appDefined.label == .custom("desk"))
    let fromValue = IntentPerson.Handle(.emailAddress("a@b.test"), label: .work)
    precondition(fromValue.value == .emailAddress("a@b.test"))
    let person = IntentPerson(handle: phone)
    precondition(person.handle?.label == .mobile)
    precondition(person.identifier == .unknown)
    precondition(person.name == .unknown)
    precondition(person.isMe == false)
    precondition(person.aliases.isEmpty)
    let named = IntentPerson.Name.components(PersonNameComponents())
    switch named {
    case .components:
        break
    default:
        preconditionFailure("expected components")
    }
    precondition(IntentPerson.Identifier.contact("ab") != .unknown)
    precondition(IntentPerson.typeDisplayRepresentation.name == "Person")
}

func testIntentCollectionSizeMinMaxAndLiteral() {
    let exact = IntentCollectionSize(exactly: 4)
    precondition(exact.min == 4)
    precondition(exact.max == 4)
    let range = IntentCollectionSize(min: 1, max: 8)
    precondition(range.min == 1)
    precondition(range.max == 8)
    let literal: IntentCollectionSize = 2
    precondition(literal.min == 2)
}

func testIntentItemTitledDescriptionAndBuilder() {
    let item = IntentItem(
        "hn",
        title: LocalizedStringResource("Hacker News"),
        subtitle: LocalizedStringResource("Feed")
    )
    precondition(item.value == "hn")
    precondition(item.description.title.key == "Hacker News")
    precondition(item.description.subtitle?.key == "Feed")
    let built = IntentItem<String>.Builder.buildBlock(IntentItem("a"), IntentItem("b"))
    precondition(built.count == 2)
    let expressed = IntentItem<String>.Builder.buildExpression("c")
    precondition(expressed.value == "c")
    let emptyValues = IntentItem<String>.Builder.buildBlock()
    precondition(emptyValues.isEmpty)
}

func testEntityQuerySortOrderAndLimit() {
    let sort = EntityQuerySort<WaveNote>(by: \WaveNote.title, order: .descending)
    precondition(sort.order == .descending)
    precondition(sort.by != nil)
    precondition(EntityQuerySort<WaveNote>.Ordering.ascending != .descending)
    EntityResolutionEngine.reset()
    EntityResolutionEngine.register([
        WaveNote(id: "a", title: "Alpha"),
        WaveNote(id: "b", title: "Beta")
    ])
    // Default protocol implementation applies descending reverse + limit.
    // suggestedEntities order is registration order; reverse yields Beta first.
}

func testConfirmationActionNameCatalogTable() {
    let names: [(ConfirmationActionName, String)] = [
        (.startNavigation, "startNavigation"),
        (.do, "do"),
        (.go, "go"),
        (.add, "add"),
        (.buy, "buy"),
        (.get, "get"),
        (.log, "log"),
        (.pay, "pay"),
        (.run, "run"),
        (.set, "set"),
        (.book, "book"),
        (.call, "call"),
        (.find, "find"),
        (.open, "open"),
        (.play, "play"),
        (.post, "post"),
        (.send, "send"),
        (.view, "view"),
        (.order, "order"),
        (.share, "share"),
        (.start, "start"),
        (.create, "create"),
        (.filter, "filter"),
        (.search, "search"),
        (.toggle, "toggle"),
        (.turnOn, "turnOn"),
        (.addData, "addData"),
        (.checkIn, "checkIn"),
        (.request, "request"),
        (.turnOff, "turnOff"),
        (.download, "download"),
        (.playSound, "playSound"),
        (.continue, "continue"),
        (.cancel, "cancel"),
        (.ok, "ok")
    ]
    for (name, token) in names {
        precondition(name.rawValue == token)
    }
    let custom = ConfirmationActionName.custom(
        acceptLabel: LocalizedStringResource("Yes"),
        acceptAlternatives: [],
        denyLabel: LocalizedStringResource("No"),
        denyAlternatives: [],
        destructive: false
    )
    precondition(custom.rawValue == "custom:Yes")
}

func testShortcutTileColorRemainingCases() {
    let colors: [ShortcutTileColor] = [
        .red, .blue, .lime, .navy, .pink, .teal, .grape, .orange, .purple, .yellow,
        .grayBlue, .grayBrown, .grayGreen, .lightBlue, .tangerine
    ]
    precondition(Set(colors).count == 15)
    precondition(ShortcutTileColor.pink != .teal)
    precondition(ShortcutTileColor.grape != .orange)
    precondition(ShortcutTileColor.grayBlue != .grayBrown)
}

func testIntentWidgetFamilyRemainingCases() {
    let families: [IntentWidgetFamily] = [
        .systemLarge, .systemSmall, .systemMedium, .accessoryCorner,
        .accessoryInline, .systemExtraLarge, .accessoryCircular, .accessoryRectangular
    ]
    precondition(Set(families).count == 8)
    precondition(IntentWidgetFamily.systemMedium != .systemExtraLarge)
    precondition(IntentWidgetFamily.accessoryCorner != .accessoryCircular)
}

func testComparisonOperatorTables() {
    let strings: [StringComparisonOperator] = [
        .doesNotContain, .contains, .hasPrefix, .hasSuffix
    ]
    precondition(Set(strings).count == 4)
    let equatable: [EquatableComparisonOperator] = [.notEqualTo, .equalTo]
    precondition(Set(equatable).count == 2)
    let comparable: [ComparableComparisonOperator] = [
        .greaterThan, .lessThanOrEqualTo, .greaterThanOrEqualTo, .lessThan
    ]
    precondition(Set(comparable).count == 4)
    let hasValue: [HasValueComparisonOperator] = [.hasNoValue, .hasAnyValue]
    precondition(Set(hasValue).count == 2)
    precondition(OneOfComparisonOperator.oneOf == .oneOf)
}

func testIntentModesCurrentForegroundAndRawValue() {
    precondition(IntentModes.Current.background.canContinueInForeground == false)
    precondition(IntentModes.Current.foreground.canContinueInForeground == true)
    precondition(IntentModes.Current.background.debugDescription == "background")
    precondition(IntentModes.Current.foreground.debugDescription == "foreground")
    precondition(IntentModes.ForegroundMode.dynamic != .immediate)
    let combined: IntentModes = [.background, .foreground]
    precondition(combined.contains(.background))
    precondition(IntentModes(rawValue: 1).rawValue == 1)
    precondition(IntentModes.background.isEmpty == false)
    let empty = IntentModes()
    precondition(empty.isEmpty)
}

func testProgressReportingIntentHostProgress() {
    ProgressReportingHost.reset()
    ProgressReportingHost.setCompleted(40, for: String(describing: WaveProgressIntent.self))
    let intent = WaveProgressIntent()
    precondition(intent.progress.totalUnitCount == 100)
    precondition(intent.progress.completedUnitCount == 40)
}

func testDeleteIntentAndSetValueIntentHost() {
    let notes = [WaveNote(id: "a", title: "A")]
    let delete = WaveDeleteIntent(entities: notes)
    precondition(delete.entities.count == 1)
    precondition(delete.entities[0].id == "a")
    var setValue = WaveSetTitleIntent(value: "Hello")
    precondition(setValue.value == "Hello")
    setValue.value = "World"
    precondition(setValue.value == "World")
    let valued: IntentResultContainer<String, Never, Never, Never> = .result(value: setValue.value)
    precondition(valued.value == "World")
}

func testOpenIntentTargetAndForegroundPolicy() {
    let note = WaveNote(id: "open", title: "Open me")
    let intent = WaveOpenIntent(target: note)
    precondition(intent.target.id == "open")
    precondition(WaveOpenIntent.openAppWhenRun == true)
    precondition(WaveOpenIntent.authenticationPolicy == .alwaysAllowed)
    let _: (any OpenIntent) = intent
    let _: (any SystemIntent) = intent
    let _: (any ForegroundContinuableIntent) = intent
}

func testRelevantIntentManagerRecordsInProcess() {
    RelevantIntentManager.reset()
    let config = WaveWidgetIntent()
    let relevant = RelevantIntent(config, widgetKind: "wave.kind", relevance: RelevantContext(score: 0.8))
    precondition(relevant.widgetKind == "wave.kind")
    precondition(relevant.relevanceScore == 0.8)
    precondition(relevant.debugDescription.contains("wave.kind"))
    RelevantIntentManager.shared.updateRelevantIntentsSync([relevant])
    precondition(RelevantIntentManager.recordedRelevantIntents.count == 1)
    precondition(RelevantIntentManager.recordedRelevantIntents[0].widgetKind == "wave.kind")
}

func testAssistantSchemasNamespaceStatics() {
    precondition(AssistantSchemas.EnumSchema.camera.name == "camera")
    precondition(AssistantSchemas.EnumSchema.photos.name == "photos")
    precondition(AssistantSchemas.EnumSchema.books.name == "books")
    precondition(AssistantSchemas.EnumSchema.reader.name == "reader")
    precondition(AssistantSchemas.EnumSchema.browser.name == "browser")
    precondition(AssistantSchemas.EnumSchema.whiteboard.name == "whiteboard")
    precondition(AssistantSchemas.EntitySchema.mail.name == "mail")
    precondition(AssistantSchemas.EntitySchema.photos.name == "photos")
    precondition(AssistantSchemas.EntitySchema.files.name == "files")
    precondition(AssistantSchemas.EntitySchema.journal.name == "journal")
    precondition(AssistantSchemas.EntitySchema.books.name == "books")
    precondition(AssistantSchemas.EntitySchema.reader.name == "reader")
    precondition(AssistantSchemas.EntitySchema.browser.name == "browser")
    precondition(AssistantSchemas.EntitySchema.whiteboard.name == "whiteboard")
    precondition(AssistantSchemas.EntitySchema.spreadsheet.name == "spreadsheet")
    precondition(AssistantSchemas.EntitySchema.presentation.name == "presentation")
    precondition(AssistantSchemas.EntitySchema.wordProcessor.name == "wordProcessor")
    precondition(AssistantSchemas.IntentSchema.camera.name == "camera")
    precondition(AssistantSchemas.IntentSchema.photos.name == "photos")
    precondition(AssistantSchemas.IntentSchema.mail.name == "mail")
    precondition(AssistantSchemas.IntentSchema.system.name == "system")
    precondition(AssistantSchemas.IntentSchema.visualIntelligence.name == "visualIntelligence")
}

func testSampleIntentParameterSummaryAndHostResult() {
    struct WaveFeedIntent: AppIntent {
        static var title: LocalizedStringResource { "Add Wave Feed" }
        @Parameter(title: "URL", default: "https://example.test")
        var url: String
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
    let intent = WaveFeedIntent()
    intent.url = "https://example.test/rss"
    precondition(WaveFeedIntent.parameterSummary.evaluatedDisplayString == "Add ${parameter}")
    let result = intent.hostResult()
    precondition(result.value == "https://example.test/rss")
    precondition(result.dialog?.text == "added=https://example.test/rss")
    let hosted = AppIntentsHost.performOnHost(intent, result: result)
    precondition(hosted.value == result.value)
}
