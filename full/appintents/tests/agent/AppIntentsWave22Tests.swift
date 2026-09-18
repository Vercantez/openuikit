import Foundation
import AppIntents

// Wave 22: async pins for leftover declared async helpers. Every test below
// is a top-level async no-argument function that awaits in-process work
// only: unique-entity delegation, local donation records, in-memory file
// bytes, first-option choice, and fail-closed throws. No Siri daemon,
// Shortcuts registrar, run loop, dispatch queue, or semaphore is involved.

private struct Wave22Intent: AppIntent {
    static var title: LocalizedStringResource { "Wave22" }
    func perform() async throws -> IntentResultValue { .result() }
}

private struct Wave22Note: UniqueAppEntity, URLRepresentableEntity {
    typealias DefaultQuery = Wave22NoteQuery
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave22 Note" }
    static var defaultQuery: Wave22NoteQuery { Wave22NoteQuery() }
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id)
    }
}

private struct Wave22NoteQuery: UniqueAppEntityQuery {
    typealias Entity = Wave22Note
    typealias Unique = Wave22Note
    init() {}
    func uniqueEntity() async throws -> Wave22Note {
        Wave22Note(id: "only")
    }
}

private struct Wave22ValueQuery: IntentValueQuery {
    typealias Input = String
    typealias Result = [String]
    init() {}
    func values(for input: String) async throws -> [String] {
        [input, input + "+alt"]
    }
}

private struct Wave22Snippet: AppIntent, SnippetIntent {
    static var title: LocalizedStringResource { "Wave22 Snippet" }
    func perform() async throws -> IntentResultContainer<String, Never, Never, Never> {
        .result(value: "wave22")
    }
}

private struct Wave22Control: ControlConfigurationIntent {
    static var title: LocalizedStringResource { "Wave22Control" }
    func perform() async throws -> IntentResultValue { .result() }
}

private struct Wave22URL: URLRepresentableIntent {
    static var title: LocalizedStringResource { "Wave22URL" }
    func perform() async throws -> IntentResultValue { .result() }
}

private enum Wave22Kind: String, AppEnum {
    case alpha
    case beta

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave22 Kind" }
    static var caseDisplayRepresentations: [Wave22Kind: DisplayRepresentation] {
        [.alpha: "Alpha", .beta: "Beta"]
    }
}

private struct Wave22Holder<Value: _IntentValue & Sendable>: AppEntity {
    typealias DefaultQuery = Wave22HolderQuery<Value>
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave22 Holder" }
    static var defaultQuery: Wave22HolderQuery<Value> { Wave22HolderQuery() }
    var id: String
    var payload: Value
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id)
    }
}

private struct Wave22HolderQuery<Value: _IntentValue & Sendable>: EntityQuery {
    typealias Entity = Wave22Holder<Value>
    init() {}
    func entities(for identifiers: [String]) async throws -> [Entity] {
        EntityResolutionEngine.entities(for: identifiers, as: Entity.self)
    }
    func suggestedEntities() async throws -> [Entity] {
        EntityResolutionEngine.suggestedEntities(Entity.self)
    }
}

private func checkWave22FailClosed(_ label: String, _ work: () async throws -> Void) async {
    do {
        try await work()
        preconditionFailure(label + " must fail closed")
    } catch let error as AppIntentError {
        precondition(error == .Unrecoverable.unsupportedOnDevice, label)
    } catch {
        preconditionFailure(label + " threw an unexpected error")
    }
}

func testWave22UniqueEntityQueryAsync() async throws {
    let query = Wave22NoteQuery()
    let only = try await query.uniqueEntity()
    precondition(only.id == "only")
    let all = try await query.allEntities()
    precondition(all.map(\.id) == ["only"])
    let suggested = try await query.suggestedEntities()
    precondition(suggested.map(\.id) == ["only"])
    let matched = try await query.entities(for: ["only", "missing"])
    precondition(matched.map(\.id) == ["only"])
    let none = try await query.entities(for: ["missing"])
    precondition(none.isEmpty)
    let provider = UniqueAppEntityProvider<Wave22Note> { Wave22Note(id: "only") }
    let single = try await provider.uniqueEntity()
    precondition(single.id == "only")
    let providedAll = try await provider.allEntities()
    precondition(providedAll.map(\.id) == ["only"])
}

func testWave22DonationManagerAsync() async throws {
    IntentDonationManager.resetLocalDonations()
    let manager = IntentDonationManager()
    let first = try await manager.donate(intent: Wave22Intent())
    precondition(first.rawValue.hasPrefix("local."))
    let second = try await manager.donate(intent: Wave22Intent(), result: IntentResultValue.result())
    precondition(second.rawValue.hasPrefix("local."))
    precondition(first != second)
    precondition(IntentDonationManager.recordedLocalDonations.count == 2)
    try await manager.deleteDonations(matching: IntentDonationMatchingPredicate())
    precondition(IntentDonationManager.recordedLocalDonations.isEmpty)
}

func testWave22IntentFileAsync() async throws {
    let file = IntentFile(data: Data([0x01, 0x02]), filename: "wave22.bin", type: .data)
    let roundTrip = try await file.data(contentType: .data)
    precondition(roundTrip == Data([0x01, 0x02]))
    let placed = try await file.file(contentType: .data)
    precondition(placed.openedInPlace == false)
    precondition(FileManager.default.fileExists(atPath: placed.fileURL.path))
    try? FileManager.default.removeItem(at: placed.fileURL)
}

func testWave22AppIntentDonateAsync() async throws {
    IntentDonationManager.resetLocalDonations()
    let intent = Wave22Intent()
    let first = try await intent.donate()
    precondition(first.rawValue.hasPrefix("local."))
    let second = try await intent.donate(result: IntentResultValue.result())
    precondition(second.rawValue.hasPrefix("local."))
    precondition(first != second)
    let open = OpenURLIntent(URL(string: "https://example.invalid")!)
    let openDonation = try await open.donate()
    precondition(openDonation.rawValue.hasPrefix("local."))
    let empty = EmptySnippetIntent()
    let emptyDonation = try await empty.donate(result: IntentResultValue.result())
    precondition(emptyDonation.rawValue.hasPrefix("local."))
}

func testWave22AppIntentRequestChoiceAsync() async throws {
    let intent = Wave22Intent()
    let options = [
        IntentChoiceOption(title: LocalizedStringResource("Alpha")),
        IntentChoiceOption(title: LocalizedStringResource("Beta")),
    ]
    let chosen = try await intent.requestChoice(between: options, dialog: IntentDialog("Pick one"))
    precondition(chosen == options[0])
    let open = OpenURLIntent(URL(string: "https://example.invalid")!)
    let openChosen = try await open.requestChoice(between: options)
    precondition(openChosen == options[0])
    let empty = EmptySnippetIntent()
    let emptyChosen = try await empty.requestChoice(between: options)
    precondition(emptyChosen == options[0])
    do {
        _ = try await intent.requestChoice(between: [], dialog: nil)
        preconditionFailure("empty choice must fail closed")
    } catch let error as AppIntentError {
        precondition(error == .Unrecoverable.entityNotFound)
    } catch {
        preconditionFailure("empty choice threw an unexpected error")
    }
}

func testWave22AppIntentRequestConfirmationAsync() async throws {
    let dialog = IntentDialog("Confirm?")
    await checkWave22FailClosed("requestConfirmation") {
        try await Wave22Intent().requestConfirmation(
            conditions: [], actionName: .continue, dialog: dialog)
    }
    await checkWave22FailClosed("openURL requestConfirmation") {
        try await OpenURLIntent(URL(string: "https://example.invalid")!).requestConfirmation(
            conditions: [], actionName: .continue, dialog: dialog)
    }
    await checkWave22FailClosed("emptySnippet requestConfirmation") {
        try await EmptySnippetIntent().requestConfirmation(
            conditions: [], actionName: .continue, dialog: dialog)
    }
}

func testWave22AppIntentRequestConfirmationOutputAsync() async throws {
    let result: IntentResultValue = .result()
    await checkWave22FailClosed("output confirmation") {
        try await Wave22Intent().requestConfirmation(
            output: result, confirmationActionName: .continue, showPrompt: true)
    }
    await checkWave22FailClosed("result confirmation") {
        try await Wave22Intent().requestConfirmation(
            result: result, confirmationActionName: .continue, showPrompt: true)
    }
    let open = OpenURLIntent(URL(string: "https://example.invalid")!)
    await checkWave22FailClosed("openURL output confirmation") {
        try await open.requestConfirmation(
            output: result, confirmationActionName: .continue, showPrompt: true)
    }
    await checkWave22FailClosed("openURL result confirmation") {
        try await open.requestConfirmation(
            result: result, confirmationActionName: .continue, showPrompt: true)
    }
    let empty = EmptySnippetIntent()
    await checkWave22FailClosed("emptySnippet output confirmation") {
        try await empty.requestConfirmation(
            output: result, confirmationActionName: .continue, showPrompt: true)
    }
    await checkWave22FailClosed("emptySnippet result confirmation") {
        try await empty.requestConfirmation(
            result: result, confirmationActionName: .continue, showPrompt: true)
    }
}

func testWave22AppIntentRequestConfirmationSnippetAsync() async throws {
    let snippet = Wave22Snippet()
    await checkWave22FailClosed("snippet confirmation") {
        let _: Void = try await Wave22Intent().requestConfirmation(snippetIntent: snippet)
    }
    await checkWave22FailClosed("valued snippet confirmation") {
        let _: String = try await Wave22Intent().requestConfirmation(snippetIntent: snippet)
    }
    let open = OpenURLIntent(URL(string: "https://example.invalid")!)
    await checkWave22FailClosed("openURL snippet confirmation") {
        let _: Void = try await open.requestConfirmation(snippetIntent: snippet)
    }
    await checkWave22FailClosed("openURL valued snippet confirmation") {
        let _: String = try await open.requestConfirmation(snippetIntent: snippet)
    }
    let empty = EmptySnippetIntent()
    await checkWave22FailClosed("emptySnippet snippet confirmation") {
        let _: Void = try await empty.requestConfirmation(snippetIntent: snippet)
    }
    await checkWave22FailClosed("emptySnippet valued snippet confirmation") {
        let _: String = try await empty.requestConfirmation(snippetIntent: snippet)
    }
}

func testWave22ParameterRequestAsync() async throws {
    let parameter = IntentParameter<String>(title: LocalizedStringResource("Name"))
    await checkWave22FailClosed("parameter disambiguation") {
        _ = try await parameter.requestDisambiguation(among: ["a", "b"], dialog: nil)
    }
    await checkWave22FailClosed("parameter confirmation") {
        _ = try await parameter.requestConfirmation(for: "a", dialog: nil)
    }
    let context = IntentParameterContext<String>()
    await checkWave22FailClosed("context requestValue") {
        _ = try await context.requestValue(nil)
    }
    await checkWave22FailClosed("context confirmation") {
        _ = try await context.requestConfirmation(for: "a", dialog: nil)
    }
    await checkWave22FailClosed("context disambiguation") {
        _ = try await context.requestDisambiguation(among: ["a"], dialog: nil)
    }
}

func testWave22EmptySnippetPerformAsync() async throws {
    let result = try await EmptySnippetIntent().perform()
    precondition(result.dialog == nil)
}

func testWave22IntentValueQueryAsync() async throws {
    let query = Wave22ValueQuery()
    let values = try await query.values(for: "wave22")
    precondition(values == ["wave22", "wave22+alt"])
}

func testWave22FailClosedPerformsAsync() async throws {
    let controlResult: Never? = try? await Wave22Control().performs()
    precondition(controlResult == nil)
    let urlResult: Never? = try? await Wave22URL().performs()
    precondition(urlResult == nil)
    let open = OpenURLIntent(URL(string: "https://example.invalid")!)
    let openResult: Never? = try? await open.performs()
    precondition(openResult == nil)
    await checkWave22FailClosed("entity urlRepresentable init") {
        _ = try await OpenURLIntent(urlRepresentable: Wave22Note(id: "only"))
    }
}

private func checkWave22AsyncGetter<Value: _IntentValue & Sendable>(_ sample: Value) async throws {
    let property = EntityProperty<Value>(identifier: "wave22.async") {
        (entity: Wave22Holder<Value>) async throws -> Value in
        _ = entity
        return sample
    }
    precondition(property.hasAsyncGetter)
    precondition(property.identifier == "wave22.async")
    let holder = Wave22Holder(id: "wave22", payload: sample)
    let resolved = try await property.resolveAsyncGetter(for: holder)
    precondition(String(describing: resolved) == String(describing: sample))
    let titled = EntityProperty<Value>(
        identifier: "wave22.async",
        title: LocalizedStringResource("Wave22")
    ) { (entity: Wave22Holder<Value>) async throws -> Value in
        _ = entity
        return sample
    }
    precondition(titled.hasAsyncGetter)
    precondition(titled.title.key == "Wave22")
    let titledResolved = try await titled.resolveAsyncGetter(for: holder)
    precondition(String(describing: titledResolved) == String(describing: sample))
}

func testWave22AsyncGetterScalars() async throws {
    try await checkWave22AsyncGetter("text")
    try await checkWave22AsyncGetter(true)
    try await checkWave22AsyncGetter(3)
    try await checkWave22AsyncGetter(2.5)
    try await checkWave22AsyncGetter(URL(string: "https://example.invalid/value")!)
    try await checkWave22AsyncGetter(Date(timeIntervalSince1970: 42))
}

func testWave22AsyncGetterTexts() async throws {
    try await checkWave22AsyncGetter(AttributedString("value"))
    try await checkWave22AsyncGetter(DateComponents(year: 2026, month: 9, day: 8))
    try await checkWave22AsyncGetter(
        Calendar.RecurrenceRule(calendar: Calendar(identifier: .gregorian), frequency: .weekly))
    try await checkWave22AsyncGetter(CLPlacemark(name: "Ada", locality: "London"))
    try await checkWave22AsyncGetter(IntentPerson(
        identifier: .applicationDefined("ada"),
        name: .displayName("Ada"),
        handle: IntentPerson.Handle(emailAddress: "ada@example.test")))
    try await checkWave22AsyncGetter(IntentCurrencyAmount(amount: 5, currencyCode: "USD"))
}

func testWave22AsyncGetterEntities() async throws {
    try await checkWave22AsyncGetter(
        IntentPaymentMethod(type: .credit, name: LocalizedStringResource("Visa")))
    try await checkWave22AsyncGetter(
        IntentFile(data: Data([0x22]), filename: "wave22.bin", type: .data))
    try await checkWave22AsyncGetter(File(
        url: URL(fileURLWithPath: "/tmp/wave22.bin"),
        data: Data([0x22]),
        filename: "wave22.bin"))
    try await checkWave22AsyncGetter(Wave22Kind.alpha)
    try await checkWave22AsyncGetter(Wave22Note(id: "nested"))
}

func testWave22AsyncGetterMeasurementsA() async throws {
    try await checkWave22AsyncGetter(Measurement(value: 1, unit: UnitSpeed.metersPerSecond))
    try await checkWave22AsyncGetter(Measurement(value: 2, unit: UnitEnergy.joules))
    try await checkWave22AsyncGetter(Measurement(value: 3, unit: UnitLength.meters))
    try await checkWave22AsyncGetter(Measurement(value: 4, unit: UnitVolume.liters))
    try await checkWave22AsyncGetter(Measurement(value: 5, unit: UnitDuration.seconds))
    try await checkWave22AsyncGetter(Measurement(value: 6, unit: UnitPressure.newtonsPerMetersSquared))
    try await checkWave22AsyncGetter(Measurement(value: 7, unit: UnitFrequency.hertz))
    try await checkWave22AsyncGetter(Measurement(value: 8, unit: UnitDispersion.partsPerMillion))
    try await checkWave22AsyncGetter(Measurement(value: 9, unit: UnitIlluminance.lux))
}

func testWave22AsyncGetterMeasurementsB() async throws {
    try await checkWave22AsyncGetter(Measurement(value: 10, unit: UnitTemperature.kelvin))
    try await checkWave22AsyncGetter(
        Measurement(value: 11, unit: UnitAcceleration.metersPerSecondSquared))
    try await checkWave22AsyncGetter(Measurement(value: 12, unit: UnitElectricCharge.coulombs))
    try await checkWave22AsyncGetter(
        Measurement(value: 13, unit: UnitFuelEfficiency.litersPer100Kilometers))
    try await checkWave22AsyncGetter(Measurement(value: 14, unit: UnitElectricCurrent.amperes))
    try await checkWave22AsyncGetter(Measurement(value: 15, unit: UnitConcentrationMass.gramsPerLiter))
    try await checkWave22AsyncGetter(Measurement(value: 16, unit: UnitElectricResistance.ohms))
    try await checkWave22AsyncGetter(Measurement(value: 17, unit: UnitInformationStorage.bytes))
    try await checkWave22AsyncGetter(
        Measurement(value: 18, unit: UnitElectricPotentialDifference.volts))
}
