import Foundation
import AppIntents

// Wave 19: synchronous pins for leftover declared surface. Every test below
// is a top-level synchronous no-argument function; no Siri daemon,
// Shortcuts registrar, run loop, semaphore, or suspension point is used.
// Async request/donation/confirmation paths stay fail-closed and declared.

private struct Wave19Video: PlayVideoIntent {
    static var title: LocalizedStringResource { "Wave19Video" }
    var term: String = ""
    static var supportedCategories: [VideoCategory] { [.movies] }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: term)
    }
}

private struct Wave19Workout: StartWorkoutIntent {
    static var title: LocalizedStringResource { "Wave19Workout" }
    typealias WorkoutStyle = String
    var workoutStyle = "run"
    static var suggestedWorkouts: [Wave19Workout] { [] }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "workout") }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: workoutStyle)
    }
}

private enum Wave19Display: String, CaseDisplayRepresentable {
    case one
    static var caseDisplayRepresentations: [Wave19Display: DisplayRepresentation] {
        [.one: DisplayRepresentation(title: "one")]
    }
}

private enum Wave19SchemaEnum: String, AssistantSchemaEnum {
    case wave
    static var caseDisplayRepresentations: [Wave19SchemaEnum: DisplayRepresentation] {
        [.wave: DisplayRepresentation(title: "wave")]
    }
}

private struct Wave19SchemaEntityQuery: EntityQuery {
    typealias Entity = Wave19SchemaEntity
    func entities(for identifiers: [String]) async throws -> [Wave19SchemaEntity] { [] }
}

private struct Wave19SchemaEntity: AssistantSchemaEntity {
    typealias DefaultQuery = Wave19SchemaEntityQuery
    static var defaultQuery = Wave19SchemaEntityQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave19SchemaIntent: AssistantSchemaIntent {
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: "wave19")
    }
}

private struct Wave19FileQuery: EntityQuery {
    typealias Entity = Wave19FileEntity
    func entities(for identifiers: [Wave19FileEntity.ID]) async throws -> [Wave19FileEntity] { [] }
}

private struct Wave19FileEntity: FileEntity {
    static var title: LocalizedStringResource { "Wave19File" }
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave19File" }
    static var supportedContentTypes: [IntentFileContentType] { [] }
    static var defaultQuery = Wave19FileQuery()
    var id: FileEntityIdentifier { FileEntityIdentifier(URL(fileURLWithPath: "/tmp/wave19")) }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "wave19") }
}

private struct Wave19Foreground: ForegroundContinuableIntent {
    static var title: LocalizedStringResource { "Wave19Foreground" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: "wave19")
    }
}

private struct Wave19EntityQuery: EntityQuery {
    typealias Entity = Wave19Entity
    func entities(for identifiers: [String]) async throws -> [Wave19Entity] { [] }
}

private struct Wave19Entity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave19Entity" }
    static var defaultQuery = Wave19EntityQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave19IntEntityQuery: EntityQuery {
    typealias Entity = Wave19IntEntity
    func entities(for identifiers: [Int]) async throws -> [Wave19IntEntity] { [] }
}

private struct Wave19IntEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave19IntEntity" }
    static var defaultQuery = Wave19IntEntityQuery()
    var id: Int
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: String(id)) }
}

private struct Wave19Summary: ParameterSummary {
    typealias Intent = Wave19Intent
    var evaluatedDisplayString: String
}

private struct Wave19Intent: AppIntent {
    static var title: LocalizedStringResource { "Wave19" }
    @Parameter(title: "Nickname")
    var nickname: String
    @Parameter(title: "Count")
    var count: Int
    @Parameter(title: "Item")
    var item: Wave19Entity
    @Parameter(title: "Numbered")
    var numbered: Wave19IntEntity
    init() {
        _nickname = IntentParameter(title: "Nickname")
        _count = IntentParameter(title: "Count")
        _item = IntentParameter(title: "Item")
        _numbered = IntentParameter(title: "Numbered")
    }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: nickname)
    }
}

private func wave19Branch(_ string: String) -> Wave19Summary {
    Wave19Summary(evaluatedDisplayString: string)
}

func testWave19NeverResultAliases() {
    _ = Never.PerformResult.self
    _ = Never.SummaryContent.self
    precondition(String(describing: Never.PerformResult.self) == "IntentResultValue")
}

func testWave19ForegroundContinuationError() {
    let error = Wave19Foreground().needsToContinueInForegroundError()
    precondition(error.description == "unsupportedOnDevice")
    let prompted = Wave19Foreground().needsToContinueInForegroundError(
        IntentDialog("go"), alwaysConfirm: true
    )
    precondition(prompted.description == "unsupportedOnDevice")
}

func testWave19MediaIntentOpenAppWhenRun() {
    precondition(Wave19Video.openAppWhenRun == false)
    precondition(Wave19Workout.openAppWhenRun == false)
}

func testWave19CaseDisplayResource() {
    precondition(Wave19Display.one.localizedStringResource.key == "one")
}

func testWave19FileEntityContentTypes() {
    precondition(Wave19FileEntity.supportedContentTypes.isEmpty)
}

func testWave19AssistantSchemaDisplay() {
    precondition(Wave19SchemaEnum.typeDisplayRepresentation.name == "Wave19SchemaEnum")
    precondition(Wave19SchemaEntity.typeDisplayRepresentation.name == "Wave19SchemaEntity")
    precondition(Wave19SchemaIntent.title.key == "Wave19SchemaIntent")
}

func testWave19WhenConditionEntityIdentifiers() {
    let stringMatch = ParameterSummaryWhenCondition<Wave19Intent, Wave19Summary, Wave19Summary>(
        \Wave19Intent.$item,
        identifier: StringComparisonOperator.contains,
        .some("wave"),
        { wave19Branch("when") },
        otherwise: { wave19Branch("otherwise") }
    )
    precondition(stringMatch.evaluatedDisplayString == "otherwise")
    let intMatch = ParameterSummaryWhenCondition<Wave19Intent, Wave19Summary, Wave19Summary>(
        \Wave19Intent.$numbered,
        identifier: ComparableComparisonOperator.greaterThan,
        3,
        { wave19Branch("when") },
        otherwise: { wave19Branch("otherwise") }
    )
    precondition(intMatch.evaluatedDisplayString == "otherwise")
}

func testWave19WhenConditionValueOverloads() {
    let equalMatch = ParameterSummaryWhenCondition<Wave19Intent, Wave19Summary, Wave19Summary>(
        \Wave19Intent.$nickname,
        EquatableComparisonOperator.equalTo,
        "wave",
        { wave19Branch("when") },
        otherwise: { wave19Branch("otherwise") }
    )
    precondition(equalMatch.evaluatedDisplayString == "otherwise")
    let comparableMatch = ParameterSummaryWhenCondition<Wave19Intent, Wave19Summary, Wave19Summary>(
        \Wave19Intent.$count,
        ComparableComparisonOperator.greaterThan,
        3,
        { wave19Branch("when") },
        otherwise: { wave19Branch("otherwise") }
    )
    precondition(comparableMatch.evaluatedDisplayString == "otherwise")
    let oneOfMatch = ParameterSummaryWhenCondition<Wave19Intent, Wave19Summary, Wave19Summary>(
        \Wave19Intent.$nickname,
        OneOfComparisonOperator.oneOf,
        ["wave"],
        { wave19Branch("when") },
        otherwise: { wave19Branch("otherwise") }
    )
    precondition(oneOfMatch.evaluatedDisplayString == "otherwise")
}
