import Foundation
import AppIntents

// Wave 18: synchronous in-process coverage for leftover declared surface.
// No daemon, Siri service, Spotlight index, waiting, or suspension point.
// Async request/confirmation/donation, `EntityProperty.asyncGetter`, View
// execution, and service success stay declared or fail-closed.

// MARK: - Probes

private struct Wave18Intent: AppIntent {
    static var title: LocalizedStringResource { "Wave18" }
    @Parameter(title: "Name")
    var name: String
    @Parameter(title: "Count")
    var count: Int
    @Parameter(title: "Flag")
    var flag: Bool
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: name)
    }
}

private struct Wave18Query: EntityPropertyQuery {
    typealias Entity = Wave18Entity
    typealias ComparatorMappingType = String
    func entities(for identifiers: [String]) async throws -> [Wave18Entity] { [] }
    func suggestedEntities() async throws -> [Wave18Entity] { [] }
}

private struct Wave18Entity: AppEntity {
    typealias DefaultQuery = Wave18Query
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18" }
    static var defaultQuery = Wave18Query()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave18EnumerableQuery: EnumerableEntityQuery {
    typealias Entity = Wave18Entity
    static var findIntentDescription: IntentDescription? { nil }
    func entities(for identifiers: [String]) async throws -> [Wave18Entity] { [] }
    func allEntities() async throws -> [Wave18Entity] { [] }
}

private struct Wave18ValueQuery: IntentValueQuery {
    typealias Input = String
    typealias Result = [String]
    init() {}
    func values(for input: String) async throws -> [String] { [input] }
}

private struct Wave18Options: DynamicOptionsProvider {
    typealias Result = [String]
    func results() async throws -> [String] { [] }
}

private struct Wave18SetValue: SetValueIntent {
    static var title: LocalizedStringResource { "Wave18Set" }
    var value: String = ""
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: value)
    }
}

private struct Wave18AnyValue: AnyIntentValue {
    typealias Value = String
}

private struct Wave18Summary: ParameterSummary {
    typealias Intent = Wave18Intent
    var evaluatedDisplayString: String
}

private struct Wave18Case: _ParameterSummarySwitchCase, ParameterSummary {
    typealias Intent = Wave18Intent
    var evaluatedDisplayString: String
}

private struct Wave18Projected: AppIntent {
    static var title: LocalizedStringResource { "Wave18Projected" }
    var plain: String = "hi"
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: plain)
    }
}

private struct Wave18Video: PlayVideoIntent {
    static var title: LocalizedStringResource { "Wave18Video" }
    var term: String = ""
    static var supportedCategories: [VideoCategory] { [.movies] }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: term)
    }
}

private struct Wave18Predictable: PredictableIntent {
    static var title: LocalizedStringResource { "Wave18Predictable" }
    typealias Prediction = String
    static var predictionConfiguration = "wave18"
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: "wave18")
    }
}

private struct Wave18Workout: StartWorkoutIntent {
    static var title: LocalizedStringResource { "Wave18Workout" }
    typealias WorkoutStyle = String
    var workoutStyle = "run"
    static var suggestedWorkouts: [Wave18Workout] { [] }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "workout") }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: workoutStyle)
    }
}

private struct Wave18Live: LiveActivityIntent {
    static var title: LocalizedStringResource { "Wave18Live" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "live") }
}

private struct Wave18LiveStarting: LiveActivityStartingIntent {
    static var title: LocalizedStringResource { "Wave18LiveStarting" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "live") }
}

private struct Wave18Pause: PauseWorkoutIntent {
    static var title: LocalizedStringResource { "Wave18Pause" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "pause") }
}

private struct Wave18Resume: ResumeWorkoutIntent {
    static var title: LocalizedStringResource { "Wave18Resume" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "resume") }
}

private struct Wave18AudioPlayback: AudioPlaybackIntent {
    static var title: LocalizedStringResource { "Wave18AudioPlayback" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "audio") }
}

private struct Wave18AudioStarting: AudioStartingIntent {
    static var title: LocalizedStringResource { "Wave18AudioStarting" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "audio") }
}

private struct Wave18AudioRecording: AudioRecordingIntent {
    static var title: LocalizedStringResource { "Wave18AudioRecording" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "audio") }
}

private struct Wave18Camera: CameraCaptureIntent {
    static var title: LocalizedStringResource { "Wave18Camera" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "camera") }
}

private struct Wave18PushToTalk: PushToTalkTransmissionIntent {
    static var title: LocalizedStringResource { "Wave18PushToTalk" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "ptt") }
}

private struct Wave18TargetContent: TargetContentProvidingIntent {
    static var title: LocalizedStringResource { "Wave18TargetContent" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "target") }
}

private struct Wave18UIScene: UISceneAppIntent {
    static var title: LocalizedStringResource { "Wave18UIScene" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "scene") }
}

private struct Wave18Undoable: UndoableIntent {
    static var title: LocalizedStringResource { "Wave18Undoable" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "undo") }
}

private struct Wave18SetFocus: SetFocusFilterIntent {
    static var title: LocalizedStringResource { "Wave18SetFocus" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "focus") }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "focus") }
}

private struct Wave18ControlConfiguration: ControlConfigurationIntent {
    static var title: LocalizedStringResource { "Wave18ControlConfiguration" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "control") }
}

private struct Wave18URLIntent: URLRepresentableIntent {
    static var title: LocalizedStringResource { "Wave18URLIntent" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "url") }
}

private struct Wave18Snippet: SnippetIntent {
    static var title: LocalizedStringResource { "Wave18Snippet" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "snippet") }
}

private struct Wave18ShowsSnippet: ShowsSnippetIntent {}

private enum Wave18URLEnum: String, URLRepresentableEnum {
    case wave
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18URL" }
    static var caseDisplayRepresentations: [Wave18URLEnum: DisplayRepresentation] {
        [.wave: DisplayRepresentation(title: "wave")]
    }
}

private struct Wave18URLQuery: EntityQuery {
    typealias Entity = Wave18URLEntity
    func entities(for identifiers: [String]) async throws -> [Wave18URLEntity] { [] }
    func suggestedEntities() async throws -> [Wave18URLEntity] { [] }
}

private struct Wave18URLEntity: URLRepresentableEntity {
    typealias DefaultQuery = Wave18URLQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18URLEntity" }
    static var defaultQuery = Wave18URLQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private enum Wave18AssistEnum: String, AssistantEnum {
    case wave
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18Assist" }
    static var caseDisplayRepresentations: [Wave18AssistEnum: DisplayRepresentation] {
        [.wave: DisplayRepresentation(title: "wave")]
    }
}

private struct Wave18AssistEntityQuery: EntityQuery {
    typealias Entity = Wave18AssistEntity
    func entities(for identifiers: [String]) async throws -> [Wave18AssistEntity] { [] }
    func suggestedEntities() async throws -> [Wave18AssistEntity] { [] }
}

private struct Wave18AssistEntity: AssistantEntity {
    typealias DefaultQuery = Wave18AssistEntityQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18AssistEntity" }
    static var defaultQuery = Wave18AssistEntityQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave18AssistIntent: AssistantIntent {
    static var title: LocalizedStringResource { "Wave18AssistIntent" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "assist") }
}

private enum Wave18SchemaEnum: String, AssistantSchemaEnum {
    case wave
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18Schema" }
    static var caseDisplayRepresentations: [Wave18SchemaEnum: DisplayRepresentation] {
        [.wave: DisplayRepresentation(title: "wave")]
    }
}

private struct Wave18SchemaEntityQuery: EntityQuery {
    typealias Entity = Wave18SchemaEntity
    func entities(for identifiers: [String]) async throws -> [Wave18SchemaEntity] { [] }
    func suggestedEntities() async throws -> [Wave18SchemaEntity] { [] }
}

private struct Wave18SchemaEntity: AssistantSchemaEntity {
    typealias DefaultQuery = Wave18SchemaEntityQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18SchemaEntity" }
    static var defaultQuery = Wave18SchemaEntityQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave18SchemaIntent: AssistantSchemaIntent {
    static var title: LocalizedStringResource { "Wave18SchemaIntent" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> { .result(value: "schema") }
}

private struct Wave18IndexedQuery: EntityQuery {
    typealias Entity = Wave18Indexed
    func entities(for identifiers: [String]) async throws -> [Wave18Indexed] { [] }
    func suggestedEntities() async throws -> [Wave18Indexed] { [] }
}

private struct Wave18Indexed: IndexedEntity {
    typealias DefaultQuery = Wave18IndexedQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18Indexed" }
    static var defaultQuery = Wave18IndexedQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave18UniqueQuery: UniqueAppEntityQuery {
    typealias Entity = Wave18UniqueEntity
    typealias Unique = Wave18UniqueEntity
    static var findIntentDescription: IntentDescription? { nil }
    func entities(for identifiers: [String]) async throws -> [Wave18UniqueEntity] { [] }
    func suggestedEntities() async throws -> [Wave18UniqueEntity] { [] }
    func allEntities() async throws -> [Wave18UniqueEntity] { [] }
    func uniqueEntity() async throws -> Wave18UniqueEntity { Wave18UniqueEntity(id: "unique") }
}

private struct Wave18UniqueEntity: UniqueAppEntity {
    typealias DefaultQuery = Wave18UniqueQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave18Unique" }
    static var defaultQuery = Wave18UniqueQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave18Annotatable: AppEntityAnnotatable {
    var appEntityIdentifier: EntityIdentifier?
}

private struct Wave18PredictionConfig: IntentPredictionConfiguration {
    typealias Intent = Wave18Intent
}

private struct Wave18RangeResolver: RangeCheckingResolver {
    typealias Input = String
    typealias Output = String
    func resolve(from input: String, context: IntentParameterContext<String>) async throws -> String? {
        _ = context
        return input
    }
}

private struct Wave18Extension: AppIntentsExtension {}

private final class Wave18SceneDelegate: NSObject, AppIntentSceneDelegate {}

private struct Wave18OptionsCollection: AppShortcutOptionsCollectionProtocol {
    typealias Provider = Wave18Options
    var title: LocalizedStringResource { "Wave18" }
    var systemImageName: String? { nil }
    var dynamicOptionsProvider: Wave18Options { Wave18Options() }
}

private enum Wave18Display: String, CaseDisplayRepresentable {
    case one
    static var caseDisplayRepresentations: [Wave18Display: DisplayRepresentation] {
        [.one: DisplayRepresentation(title: "one")]
    }
}

private struct Wave18Persist: PersistentlyIdentifiable {}

// MARK: - Conformance probes

private func wave18IsAppIntent<I: AppIntent>(_: I.Type) -> Bool { true }
private func wave18IsAppValue<V: AppValue>(_: V.Type) -> Bool { true }
private func wave18IsAppEnum<E: AppEnum>(_: E.Type) -> Bool { true }
private func wave18IsAppEntity<E: AppEntity>(_: E.Type) -> Bool { true }
private func wave18IsAnyIntentValue<V: AnyIntentValue>(_: V.Type) -> Bool { true }
private func wave18IsPlayVideoIntent<I: PlayVideoIntent>(_: I.Type) -> Bool { true }
private func wave18IsPredictableIntent<I: PredictableIntent>(_: I.Type) -> Bool { true }
private func wave18IsWorkoutIntent<I: StartWorkoutIntent>(_: I.Type) -> Bool { true }
private func wave18IsSystemIntent<I: SystemIntent>(_: I.Type) -> Bool { true }
private func wave18IsURLRepresentableEnum<E: URLRepresentableEnum>(_: E.Type) -> Bool { true }
private func wave18IsURLRepresentableEntity<E: URLRepresentableEntity>(_: E.Type) -> Bool { true }
private func wave18IsURLRepresentableIntent<I: URLRepresentableIntent>(_: I.Type) -> Bool { true }

private func wave18IsAssistantSchemaEnum<E: AssistantSchemaEnum>(_: E.Type) -> Bool { true }
private func wave18IsAssistantSchemaEntity<E: AssistantSchemaEntity>(_: E.Type) -> Bool { true }
private func wave18IsAssistantSchemaIntent<I: AssistantSchemaIntent>(_: I.Type) -> Bool { true }

// MARK: - Option sets and integer witnesses

func testWave18OptionSetLiteralsAndRawValues() {
    let modes = IntentModes(arrayLiteral: .background)
    precondition(modes.contains(.background))
    let modesSeq = IntentModes([.background])
    precondition(modesSeq.contains(.background))
    let cond = ConfirmationConditions(arrayLiteral: .lowConfidenceSource)
    precondition(cond.contains(.lowConfidenceSource))
    let condSeq = ConfirmationConditions([.lowConfidenceSource])
    precondition(condSeq.contains(.lowConfidenceSource))
    let mods = EntityPropertyModifiers(arrayLiteral: .async)
    precondition(mods.contains(.async))
    let modsSeq = EntityPropertyModifiers([.async])
    precondition(modsSeq.contains(.async))
    precondition(ConfirmationConditions(rawValue: 0).isEmpty)
    precondition(ConfirmationConditions(rawValue: 1).contains(.lowConfidenceSource))
    precondition(EntityPropertyModifiers(rawValue: 3).contains(.readOnly))
    _ = IntentModes.Element.self
}

func testWave18FixedWidthIntegerWitnesses() {
    precondition(Int(exactly: 5) == 5)
    precondition(Int(5) == 5)
    precondition((5).description == "5")
    precondition(Int() == 0)
    precondition(Int(bigEndian: (5).bigEndian) == 5)
    precondition(Int(littleEndian: (5).littleEndian) == 5)
    precondition(Int(truncatingIfNeeded: 5) == 5)
    precondition(Int(clamping: 5) == 5)
    precondition(Int(exactly: Int8(8)) == 8)
    precondition(Int(Int8(8)) == 8)
    precondition(Int("42") == 42)
    precondition(Int("ff", radix: 16) == 255)
    precondition(Int(integerLiteral: 5) == 5)
}

func testWave18StringLiteralWitnesses() {
    let phrase = AppShortcutPhrase<Wave18Intent>(extendedGraphemeClusterLiteral: "run")
    precondition(!phrase.template.isEmpty)
    let phraseScalar = AppShortcutPhrase<Wave18Intent>(unicodeScalarLiteral: "run")
    precondition(!phraseScalar.template.isEmpty)
    let negative = NegativeAppShortcutPhrase(extendedGraphemeClusterLiteral: "never")
    precondition(!negative.template.isEmpty)
    let negativeScalar = NegativeAppShortcutPhrase(unicodeScalarLiteral: "never")
    precondition(!negativeScalar.template.isEmpty)
    let dialog = IntentDialog(extendedGraphemeClusterLiteral: "hi")
    precondition(!dialog.text.isEmpty)
    let dialogScalar = IntentDialog(unicodeScalarLiteral: "hi")
    precondition(!dialogScalar.text.isEmpty)
    let description = IntentDescription(extendedGraphemeClusterLiteral: "desc")
    precondition(!description.text.isEmpty)
    let descriptionScalar = IntentDescription(unicodeScalarLiteral: "desc")
    precondition(!descriptionScalar.text.isEmpty)
    let display = DisplayRepresentation(extendedGraphemeClusterLiteral: "title")
    _ = display
    let displayScalar = DisplayRepresentation(unicodeScalarLiteral: "title")
    _ = displayScalar
    let summary = ParameterSummaryString<Wave18Intent>(extendedGraphemeClusterLiteral: "sum")
    precondition(!summary.evaluatedDisplayString.isEmpty)
    let summaryScalar = ParameterSummaryString<Wave18Intent>(unicodeScalarLiteral: "sum")
    precondition(!summaryScalar.evaluatedDisplayString.isEmpty)
    let entityURL = EntityURLRepresentation<Wave18Entity>(extendedGraphemeClusterLiteral: "url")
    precondition(!entityURL.template.isEmpty)
    let entityURLScalar = EntityURLRepresentation<Wave18Entity>(unicodeScalarLiteral: "url")
    precondition(!entityURLScalar.template.isEmpty)
    let intentURL = IntentURLRepresentation<Wave18Intent>(extendedGraphemeClusterLiteral: "url")
    precondition(!intentURL.template.isEmpty)
    let intentURLScalar = IntentURLRepresentation<Wave18Intent>(unicodeScalarLiteral: "url")
    precondition(!intentURLScalar.template.isEmpty)
    let typeDisplay = TypeDisplayRepresentation(extendedGraphemeClusterLiteral: "type")
    _ = typeDisplay
    let typeDisplayScalar = TypeDisplayRepresentation(unicodeScalarLiteral: "type")
    _ = typeDisplayScalar
    let titleString = AppShortcutParameterPresentationTitleString<
        Wave18Intent, String, IntentParameter<String>, KeyPath<Wave18Intent, IntentParameter<String>>
    >(extendedGraphemeClusterLiteral: "title")
    precondition(!titleString.template.isEmpty)
    let titleStringScalar = AppShortcutParameterPresentationTitleString<
        Wave18Intent, String, IntentParameter<String>, KeyPath<Wave18Intent, IntentParameter<String>>
    >(unicodeScalarLiteral: "title")
    precondition(!titleStringScalar.template.isEmpty)
    let summaryString = AppShortcutParameterPresentationSummaryString<
        Wave18Intent, String, IntentParameter<String>, KeyPath<Wave18Intent, IntentParameter<String>>
    >(extendedGraphemeClusterLiteral: "summary")
    precondition(!summaryString.template.isEmpty)
    let summaryStringScalar = AppShortcutParameterPresentationSummaryString<
        Wave18Intent, String, IntentParameter<String>, KeyPath<Wave18Intent, IntentParameter<String>>
    >(unicodeScalarLiteral: "summary")
    precondition(!summaryStringScalar.template.isEmpty)
}

// MARK: - Never and result factories

func testWave18NeverStaticsAndAliases() {
    precondition(Never.title.key == "Never")
    _ = Never.UnwrappedType.self
    _ = Never.ValueType.self
}

func testWave18ResultOpensIntentDialog() {
    let first: IntentResultContainer<Never, Wave18Intent, Never, IntentDialog> = .result(
        opensIntent: Wave18Intent(), dialog: IntentDialog("hi")
    )
    precondition(first.dialog?.text == "hi")
    let second: IntentResultContainer<Never, Wave18Intent, Never, IntentDialog> =
        IntentResultContainer.result(opensIntent: Wave18Intent(), dialog: IntentDialog("yo"))
    precondition(second.dialog?.text == "yo")
}

func testWave18ResultViewAndContentFactories() {
    let viewed: IntentResultContainer<String, Never, _SnippetViewContainer, Never> = .result(
        value: "x", view: EmptyView()
    )
    precondition(viewed.value == "x")
    let dialogViewed: IntentResultContainer<String, Never, _SnippetViewContainer, IntentDialog> = .result(
        value: "x", dialog: IntentDialog("d"), view: EmptyView()
    )
    precondition(dialogViewed.dialog?.text == "d")
    let content: IntentResultContainer<String, Never, _SnippetViewContainer, Never> = .result(
        value: "x", content: { EmptyView() }
    )
    precondition(content.value == "x")
    let dialogContent: IntentResultContainer<String, Never, _SnippetViewContainer, IntentDialog> = .result(
        value: "x", dialog: IntentDialog("dc"), content: { EmptyView() }
    )
    precondition(dialogContent.dialog?.text == "dc")
}

func testWave18IntentDonationManagerSync() {
    IntentDonationManager.resetLocalDonations()
    _ = IntentDonationManager.shared
    let first = IntentDonationManager.shared.donate(intent: Wave18Intent())
    precondition(!first.rawValue.isEmpty)
    let second = IntentDonationManager.shared.donate(
        intent: Wave18Intent(), result: IntentResultValue(dialog: IntentDialog("done"))
    )
    precondition(!second.rawValue.isEmpty)
    precondition(IntentDonationManager.recordedLocalDonations.count == 2)
}

// MARK: - Protocol identities

func testWave18IntentProtocolIdentities() {
    precondition(wave18IsAppIntent(Wave18Intent.self))
    precondition(wave18IsAppValue(String.self))
    precondition(wave18IsAppEnum(Wave18AssistEnum.self))
    precondition(wave18IsAppEntity(Wave18Entity.self))
    precondition(wave18IsAnyIntentValue(Wave18AnyValue.self))
    precondition(wave18IsPlayVideoIntent(Wave18Video.self))
    precondition(wave18IsPredictableIntent(Wave18Predictable.self))
    precondition(wave18IsWorkoutIntent(Wave18Workout.self))
    precondition(wave18IsSystemIntent(Wave18Video.self))
    precondition(wave18IsURLRepresentableEnum(Wave18URLEnum.self))
    precondition(wave18IsURLRepresentableEntity(Wave18URLEntity.self))
    precondition(wave18IsURLRepresentableIntent(Wave18URLIntent.self))
    let probe = Wave18Intent()
    _ = probe
}

func testWave18MarkerProtocolIdentities() {
    precondition(wave18IsSystemIntent(Wave18Live.self))
    precondition(wave18IsSystemIntent(Wave18LiveStarting.self))
    precondition(wave18IsSystemIntent(Wave18Pause.self))
    precondition(wave18IsSystemIntent(Wave18Resume.self))
    precondition(wave18IsSystemIntent(Wave18AudioPlayback.self))
    precondition(wave18IsSystemIntent(Wave18AudioStarting.self))
    precondition(wave18IsSystemIntent(Wave18AudioRecording.self))
    precondition(wave18IsSystemIntent(Wave18Camera.self))
    precondition(wave18IsAppIntent(Wave18PushToTalk.self))
    precondition(wave18IsAppIntent(Wave18TargetContent.self))
    precondition(wave18IsAppIntent(Wave18UIScene.self))
    precondition(wave18IsAppIntent(Wave18Undoable.self))
    precondition(wave18IsAppIntent(Wave18SetFocus.self))
    precondition(wave18IsAppIntent(Wave18ControlConfiguration.self))
    precondition(wave18IsAppIntent(Wave18Snippet.self))
    _ = Wave18ShowsSnippet()
    _ = Wave18Extension()
    _ = Wave18SceneDelegate()
    _ = Wave18RangeResolver.self
}

func testWave18DisplayProtocolIdentities() {
    _ = Wave18Display.one
    precondition(Wave18Display.caseDisplayRepresentations.count == 1)
    precondition(Wave18Display.one.localizedStringResource.key == "one")
    precondition(Wave18AssistEnum.caseDisplayRepresentations.count == 1)
    precondition(Wave18AssistEnum.wave.localizedStringResource.key == "wave")
    _ = Wave18Entity(id: "e").displayRepresentation
    _ = Wave18Entity.typeDisplayRepresentation
    _ = Wave18Persist.persistentIdentifier
    _ = Wave18Annotatable(appEntityIdentifier: nil)
    _ = Wave18PredictionConfig.self
}

// MARK: - Associated types

func testWave18AssociatedTypePins() {
    _ = Wave18Intent.PerformResult.self
    _ = OpenURLIntent.PerformResult.self
    _ = Wave18Intent.SummaryContent.self
    _ = OpenURLIntent.SummaryContent.self
    _ = Wave18AnyValue.Value.self
    _ = Wave18Query.Entity.self
    _ = Wave18Query.Result.self
    _ = Wave18Options.Result.self
    _ = Wave18Options.DefaultValue.self
    _ = Wave18Options.ItemCollection<String>.self
    _ = Wave18Options.ParameterDependency<Wave18Intent>.self
    _ = Wave18ValueQuery.Input.self
    _ = Wave18ValueQuery.Result.self
    _ = Wave18ValueQuery.ResultValue.self
    _ = Wave18Summary.Intent.self
    _ = Wave18PredictionConfig.Intent.self
    _ = Wave18SetValue.ValueType.self
    _ = Wave18UniqueQuery.Unique.self
    _ = EmptyResolverSpecification<String>.Output.self
}

func testWave18ValueTypePins() {
    _ = IntentFile.ValueType.self
    _ = IntentFile.UnwrappedType.self
    _ = IntentWidgetFamily.ValueType.self
    _ = IntentWidgetFamily.UnwrappedType.self
    _ = IntentPaymentMethod.ValueType.self
    _ = IntentPaymentMethod.UnwrappedType.self
    _ = IntentCurrencyAmount.ValueType.self
    _ = IntentCurrencyAmount.UnwrappedType.self
    precondition(IntentPaymentMethod.typeDisplayRepresentation.name == "Payment Method")
    precondition(IntentCurrencyAmount.typeDisplayRepresentation.name == "Currency Amount")
    _ = IntentFile(data: Data(), filename: "a").localizedStringResource
}

func testWave18QueryIdentities() {
    _ = Wave18ValueQuery()
    precondition(Wave18EnumerableQuery.findIntentDescription == nil)
    precondition(Wave18Query.findIntentDescription == nil)
    precondition(Wave18Entity(id: "e").id == "e")
    _ = Wave18Entity.Property<String>()
    _ = Wave18Query.Property<Wave18Entity, Wave18Entity, EntityProperty<String>, String, String>()
    _ = IntentSystemContext().currentMode
    _ = IntentSystemContext()
    precondition(IntentSystemContext().currentMode == .background)
    _ = IntentAuthenticationPolicy.alwaysAllowed
    _ = IntentDonationMatchingPredicate()
    _ = ParameterSummaryTupleCaseCondition<Wave18Intent, String, String>()
    _ = ParameterSummaryTupleCaseCondition<Wave18Intent, String, String>.Summary.self
    _ = ParameterSummaryDefaultCaseCondition<Wave18Intent, String, Wave18Summary>()
}

// MARK: - Assistant schemas

func testWave18AssistantSchemaDefaults() {
    precondition(Wave18SchemaEnum.isAssistantOnly == false)
    precondition(Wave18SchemaEntity.isAssistantOnly == false)
    precondition(Wave18SchemaIntent.isAssistantOnly == false)
    precondition(wave18IsAssistantSchemaEnum(Wave18SchemaEnum.self))
    precondition(wave18IsAssistantSchemaEntity(Wave18SchemaEntity.self))
    precondition(wave18IsAssistantSchemaIntent(Wave18SchemaIntent.self))
    precondition(wave18IsAppEnum(Wave18AssistEnum.self))
    precondition(wave18IsAppEntity(Wave18AssistEntity.self))
    precondition(wave18IsAppIntent(Wave18AssistIntent.self))
    precondition(wave18IsAppEntity(Wave18Indexed.self))
}

// MARK: - Projection and description

func testWave18ProjectionSubscript() {
    let projection = IntentProjection(Wave18Projected())
    precondition(projection[dynamicMember: \Wave18Projected.plain] == "hi")
}

func testWave18IntentDescriptionLiterals() {
    let literal = IntentDescription(stringLiteral: "hello")
    precondition(literal.text == "hello")
    let stringType: IntentDescription.StringLiteralType = "x"
    precondition(stringType == "x")
    let scalarType: IntentDescription.UnicodeScalarLiteralType = "y"
    precondition(scalarType == "y")
    let graphemeType: IntentDescription.ExtendedGraphemeClusterLiteralType = "z"
    precondition(graphemeType == "z")
}

// MARK: - Overlay views

func testWave18OverlayViewInits() {
    let binding = Binding<Bool>(get: { true }, set: { _ in })
    let tip = SiriTipView(intent: Wave18Intent(), isVisible: binding)
    _ = tip.body
    let link = ShortcutsLink(action: {})
    _ = link.body
    _ = SiriTipView.Body.self
    _ = ShortcutsLink.Body.self
    let button = ShortcutsUIButton(style: .automatic)
    precondition(button.style == .automatic)
    let tipView = SiriTipUIView(style: .automatic)
    precondition(tipView.style == .automatic)
}

// MARK: - Intent predictions

func testWave18PredictionInitTable() {
    let probe = Wave18Intent()
    let one = IntentPrediction<Wave18Intent, String>(
        parameters: ("x", probe.$name, \Wave18Intent.$name),
        displayRepresentation: { _ in DisplayRepresentation(title: "one") }
    )
    _ = one
    let two = IntentPrediction<Wave18Intent, String>(
        parameters: (("x", probe.$name, \Wave18Intent.$name), (3, probe.$count, \Wave18Intent.$count)),
        displayRepresentation: { _, _ in DisplayRepresentation(title: "two") }
    )
    _ = two
    let three = IntentPrediction<Wave18Intent, String>(
        parameters: (
            ("x", probe.$name, \Wave18Intent.$name),
            (3, probe.$count, \Wave18Intent.$count),
            (true, probe.$flag, \Wave18Intent.$flag)
        ),
        displayRepresentation: { _, _, _ in DisplayRepresentation(title: "three") }
    )
    _ = three
    let displayOnly = IntentPrediction<Wave18Intent, String>(
        displayRepresentation: { DisplayRepresentation(title: "display") }
    )
    _ = displayOnly
    let keyed = IntentPrediction<Wave18Intent, String>(
        \Wave18Intent.$name,
        displayRepresentation: { _ in DisplayRepresentation(title: "keyed") }
    )
    _ = keyed
}

func testWave18PredictionBuilderTable() {
    let prediction = IntentPrediction<Wave18Intent, String>()
    precondition(IntentPredictionsBuilder.buildBlock().isEmpty)
    precondition(IntentPredictionsBuilder.buildBlock(prediction).count == 1)
    precondition(IntentPredictionsBuilder.buildBlock(prediction, prediction).count == 2)
    precondition(IntentPredictionsBuilder.buildBlock(prediction, prediction, prediction).count == 3)
    let expressed = IntentPredictionsBuilder.buildExpression(prediction)
    _ = expressed
}

func testWave18CaseBuilderTable() {
    let single = ParameterSummaryCaseCondition<Wave18Intent, String, Wave18Summary>(
        "x", { Wave18Summary(evaluatedDisplayString: "single") }
    )
    let fallback = ParameterSummaryDefaultCaseCondition<Wave18Intent, String, Wave18Summary>(
        { Wave18Summary(evaluatedDisplayString: "fallback") }
    )
    precondition(ParameterSummaryCaseBuilder.buildBlock().isEmpty)
    precondition(ParameterSummaryCaseBuilder.buildBlock(single).count == 1)
    precondition(ParameterSummaryCaseBuilder.buildBlock(single, fallback).count == 2)
    precondition(ParameterSummaryCaseBuilder.buildBlock(single, fallback, single).count == 3)
    let expressed = ParameterSummaryCaseBuilder.buildExpression(single)
    precondition(expressed.evaluatedDisplayString == "single")
    precondition(fallback.evaluatedDisplayString == "fallback")
}

// MARK: - Comparators, conditions, shortcuts

func testWave18ExoticComparatorInits() {
    let nilString = ContainsComparator<EntityProperty<String?>, String?, String, Bool>(
        mappingTransform: { _ in true }
    )
    precondition(nilString.mappingTransform?("x") == true)
    let nilStringResolvers = ContainsComparator<EntityProperty<String?>, String?, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { _ in true }
    )
    precondition(nilStringResolvers.hostResolverSpecification != nil)
    let nilAttributed = ContainsComparator<EntityProperty<AttributedString?>, AttributedString?, AttributedString, Bool>(
        mappingTransform: { _ in true }
    )
    precondition(nilAttributed.mappingTransform?(AttributedString("x")) == true)
    let nilAttributedResolvers = ContainsComparator<EntityProperty<AttributedString?>, AttributedString?, AttributedString, Bool>(
        withResolvers: { EmptyResolverSpecification<AttributedString>() },
        mappingTransform: { _ in true }
    )
    precondition(nilAttributedResolvers.hostResolverSpecification != nil)
    let sequence = ContainsComparator<EntityProperty<[String]>, [String], String, Bool>(
        mappingTransform: { _ in true }
    )
    precondition(sequence.mappingTransform?("x") == true)
    let sequenceResolvers = ContainsComparator<EntityProperty<[String]>, [String], String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { _ in true }
    )
    precondition(sequenceResolvers.hostResolverSpecification != nil)
    let nilSequence = ContainsComparator<EntityProperty<[String]?>, [String]?, String, Bool>(
        mappingTransform: { _ in true }
    )
    precondition(nilSequence.mappingTransform?("x") == true)
    let nilSequenceResolvers = ContainsComparator<EntityProperty<[String]?>, [String]?, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { _ in true }
    )
    precondition(nilSequenceResolvers.hostResolverSpecification != nil)
    let prefix = HasPrefixComparator<EntityProperty<String?>, String?, String, Bool>(
        mappingTransform: { !$0.isEmpty }
    )
    precondition(prefix.mappingTransform?("x") == true)
    let prefixResolvers = HasPrefixComparator<EntityProperty<String?>, String?, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { !$0.isEmpty }
    )
    precondition(prefixResolvers.hostResolverSpecification != nil)
    let suffix = HasSuffixComparator<EntityProperty<String?>, String?, String, Bool>(
        mappingTransform: { !$0.isEmpty }
    )
    precondition(suffix.mappingTransform?("x") == true)
    let suffixResolvers = HasSuffixComparator<EntityProperty<String?>, String?, String, Bool>(
        withResolvers: { EmptyResolverSpecification<String>() },
        mappingTransform: { !$0.isEmpty }
    )
    precondition(suffixResolvers.hostResolverSpecification != nil)
}

func testWave18SummaryConditionInits() {
    let single = ParameterSummaryCaseCondition<Wave18Intent, String, Wave18Summary>(
        "x", { Wave18Summary(evaluatedDisplayString: "single") }
    )
    precondition(single.evaluatedDisplayString == "single")
    precondition(single.matched == "x")
    let multi = ParameterSummaryCaseCondition<Wave18Intent, String, Wave18Summary>(
        ["x", "y"], { Wave18Summary(evaluatedDisplayString: "multi") }
    )
    precondition(multi.evaluatedDisplayString == "multi")
    precondition(multi.matched == "x")
    let keyed = ParameterSummarySwitchCondition<Wave18Intent, String, Wave18Case>(
        \Wave18Intent.$name, { Wave18Case(evaluatedDisplayString: "branch") }
    )
    precondition(keyed.evaluatedDisplayString == "branch")
    let family = ParameterSummarySwitchCondition<Wave18Intent, IntentWidgetFamily, Wave18Case>(
        .widgetFamily, { Wave18Case(evaluatedDisplayString: "fam") }
    )
    precondition(family.evaluatedDisplayString == "fam")
    _ = ParameterSummarySwitchCondition<Wave18Intent, IntentWidgetFamily, Wave18Case>.WidgetFamily.widgetFamily
    let fallback = ParameterSummaryDefaultCaseCondition<Wave18Intent, String, Wave18Summary>(
        { Wave18Summary(evaluatedDisplayString: "dflt") }
    )
    precondition(fallback.evaluatedDisplayString == "dflt")
}

func testWave18AppShortcutPresentationInit() {
    typealias Presentation = AppShortcutParameterPresentation<
        Wave18Intent, String, IntentParameter<String>, KeyPath<Wave18Intent, IntentParameter<String>>
    >
    let summaryString = AppShortcutParameterPresentationSummaryString<
        Wave18Intent, String, IntentParameter<String>, KeyPath<Wave18Intent, IntentParameter<String>>
    >("Run ${applicationName}")
    let summary = AppShortcutParameterPresentationSummary(summaryString)
    let presentation = Presentation(
        for: \Wave18Intent.$name,
        summary: summary,
        optionsCollections: { Wave18OptionsCollection() }
    )
    precondition(presentation.optionsCollectionsCount == 1)
    let shortcut = AppShortcut(
        intent: Wave18Intent(),
        phrases: ["Run it"],
        shortTitle: "Run",
        systemImageName: "play",
        parameterPresentation: presentation
    )
    precondition(shortcut.systemImageName == "play")
}

func testWave18OpenURLRepresentableInit() {
    let threw: Bool = {
        do {
            _ = try OpenURLIntent(urlRepresentable: Wave18URLEnum.wave)
            return false
        } catch {
            return true
        }
    }()
    precondition(threw)
}

func testWave18SearchableItemFromEntity() {
    let item = CSSearchableItem(appEntity: Wave18Indexed(id: "a"))
    _ = item
    let prioritized = CSSearchableItem(appEntity: Wave18Indexed(id: "b"), priority: 1)
    _ = prioritized
}
