import Foundation
import AppIntents

private struct PropertyNote: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Property Note" }
    static var defaultQuery = PropertyNoteQuery()
    var id: String
    var title: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: title)
    }
}

private struct PropertyNoteQuery: EntityQuery {
    typealias Entity = PropertyNote
    init() {}
    func entities(for identifiers: [String]) async throws -> [PropertyNote] {
        EntityResolutionEngine.entities(for: identifiers, as: PropertyNote.self)
    }
    func suggestedEntities() async throws -> [PropertyNote] {
        EntityResolutionEngine.suggestedEntities(PropertyNote.self)
    }
}

private struct PropertyHolder<Value: _IntentValue>: AppEntity {
    typealias DefaultQuery = PropertyHolderQuery<Value>
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Holder" }
    static var defaultQuery: PropertyHolderQuery<Value> { PropertyHolderQuery() }
    var id: String
    var payload: Value
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id)
    }
}

private struct PropertyHolderQuery<Value: _IntentValue>: EntityQuery {
    typealias Entity = PropertyHolder<Value>
    init() {}
    func entities(for identifiers: [String]) async throws -> [PropertyHolder<Value>] {
        EntityResolutionEngine.entities(for: identifiers, as: PropertyHolder<Value>.self)
    }
    func suggestedEntities() async throws -> [PropertyHolder<Value>] {
        EntityResolutionEngine.suggestedEntities(PropertyHolder<Value>.self)
    }
}

private struct PropertyPayIntent: AppIntent {
    static var title: LocalizedStringResource { "Pay" }

    @Parameter(
        title: "Amount",
        default: IntentCurrencyAmount(amount: 5, currencyCode: "USD"),
        currencyCodes: ["USD", "EUR"],
        inclusiveRange: (Decimal(0), Decimal(1000))
    )
    var amount: IntentCurrencyAmount

    func hostResult() -> IntentResultContainer<String, Never, Never, IntentDialog> {
        .result(value: amount.currencyCode, dialog: IntentDialog("paid=\(amount.currencyCode)"))
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: amount.currencyCode, dialog: IntentDialog("paid=\(amount.currencyCode)"))
    }
}

private func propertyRecurrenceRule() -> Calendar.RecurrenceRule {
    Calendar.RecurrenceRule(calendar: Calendar(identifier: .gregorian), frequency: .weekly)
}

private func propertyPerson() -> IntentPerson {
    IntentPerson(
        identifier: .applicationDefined("ada"),
        name: .displayName("Ada"),
        handle: IntentPerson.Handle(emailAddress: "ada@example.test")
    )
}

private func registerHolder<Value: _IntentValue>(_ payload: Value) -> PropertyHolder<Value> {
    EntityResolutionEngine.reset()
    let holder = PropertyHolder(id: "row", payload: payload)
    EntityResolutionEngine.register([holder], default: holder)
    return holder
}

private func exerciseTitleIdentifierGetterAndIndexing<Value: _IntentValue>(
    sample: Value,
    matches: (Value) -> Bool
) {
    let holder = registerHolder(sample)
    let titled = EntityProperty<Value>(title: LocalizedStringResource("Field"))
    titled.wrappedValue = sample
    precondition(matches(titled.wrappedValue))
    let empty = EntityProperty<Value>()
    empty.wrappedValue = sample
    precondition(matches(empty.wrappedValue))
    let identified = EntityProperty<Value>(identifier: "payload")
    precondition(identified.identifier == "payload")
    let titledId = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("Field")
    )
    precondition(titledId.title.key == "Field")
    let getter = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("Field"),
        getter: \PropertyHolder<Value>.payload
    )
    precondition(matches(getter.wrappedValue))
    let setter = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("Field"),
        getSetter: \PropertyHolder<Value>.payload
    )
    precondition(matches(setter.wrappedValue))
    let idGetter = EntityProperty<Value>(
        identifier: "payload",
        getter: \PropertyHolder<Value>.payload
    )
    precondition(matches(idGetter.wrappedValue))
    let idSetter = EntityProperty<Value>(
        identifier: "payload",
        getSetter: \PropertyHolder<Value>.payload
    )
    precondition(matches(idSetter.wrappedValue))
    let indexed = EntityProperty<Value>(indexingKey: \CSSearchableItemAttributeSet.title)
    precondition(indexed.indexingKeyPath != nil)
    let customOnly = EntityProperty<Value>(
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.custom")
    )
    precondition(customOnly.customIndexingKey?.keyName == "prop.custom")
    let titleIndexed = EntityProperty<Value>(
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(titleIndexed.indexingKeyName == "indexingKey")
    let titleCustom = EntityProperty<Value>(
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.title")
    )
    precondition(titleCustom.customIndexingKey?.keyName == "prop.title")
    _ = holder
}

private func exerciseIndexingKeyGetters<Value: _IntentValue>(
    sample: Value,
    matches: (Value) -> Bool
) {
    let holder = registerHolder(sample)
    let byIndex = EntityProperty<Value>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \PropertyHolder<Value>.payload
    )
    precondition(matches(byIndex.wrappedValue))
    let byIndexSet = EntityProperty<Value>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \PropertyHolder<Value>.payload
    )
    precondition(matches(byIndexSet.wrappedValue))
    let identIndex = EntityProperty<Value>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(identIndex.identifier == "payload")
    let customGetter = EntityProperty<Value>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.idx"),
        getter: \PropertyHolder<Value>.payload
    )
    precondition(matches(customGetter.wrappedValue))
    let customSetter = EntityProperty<Value>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.idx2"),
        getSetter: \PropertyHolder<Value>.payload
    )
    precondition(matches(customSetter.wrappedValue))
    let identCustom = EntityProperty<Value>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.idx3")
    )
    precondition(identCustom.customIndexingKey?.keyName == "prop.idx3")
    let titledIndex = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \PropertyHolder<Value>.payload
    )
    precondition(matches(titledIndex.wrappedValue))
    let titledIndexSet = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \PropertyHolder<Value>.payload
    )
    precondition(titledIndexSet.identifier == "payload")
    let titledIndexOnly = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title
    )
    precondition(titledIndexOnly.indexingKeyPath != nil)
    let titledCustomGetter = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.t"),
        getter: \PropertyHolder<Value>.payload
    )
    precondition(matches(titledCustomGetter.wrappedValue))
    let titledCustomSetter = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.t2"),
        getSetter: \PropertyHolder<Value>.payload
    )
    precondition(titledCustomSetter.customIndexingKey?.keyName == "prop.t2")
    let titledCustom = EntityProperty<Value>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "prop.t3")
    )
    precondition(titledCustom.customIndexingKey?.keyName == "prop.t3")
    _ = holder
}

func testEntityPropertyURLTitleIdentifierGetterAndIndexing() {
    let url = URL(fileURLWithPath: "/tmp/property-url")
    exerciseTitleIdentifierGetterAndIndexing(sample: url) { $0.path == "/tmp/property-url" }
}

func testEntityPropertyURLIndexingKeyGetters() {
    let url = URL(fileURLWithPath: "/tmp/property-url-idx")
    exerciseIndexingKeyGetters(sample: url) { $0.lastPathComponent == "property-url-idx" }
}

func testEntityPropertyDateTitleIdentifierGetterAndIndexing() {
    let date = Date(timeIntervalSinceReferenceDate: 42)
    exerciseTitleIdentifierGetterAndIndexing(sample: date) { $0 == date }
}

func testEntityPropertyDateIndexingKeyGetters() {
    let date = Date(timeIntervalSinceReferenceDate: 84)
    exerciseIndexingKeyGetters(sample: date) { $0.timeIntervalSinceReferenceDate == 84 }
}

func testEntityPropertyDateComponentsTitleIdentifierGetterAndIndexing() {
    var components = DateComponents()
    components.year = 2026
    components.month = 9
    exerciseTitleIdentifierGetterAndIndexing(sample: components) { $0.year == 2026 && $0.month == 9 }
}

func testEntityPropertyDateComponentsIndexingKeyGetters() {
    var components = DateComponents()
    components.day = 6
    exerciseIndexingKeyGetters(sample: components) { $0.day == 6 }
}

func testEntityPropertyAttributedStringTitleIdentifierGetterAndIndexing() {
    let text = AttributedString("hello")
    exerciseTitleIdentifierGetterAndIndexing(sample: text) { String(describing: $0).contains("hello") }
}

func testEntityPropertyAttributedStringIndexingKeyGetters() {
    let text = AttributedString("indexed")
    exerciseIndexingKeyGetters(sample: text) { String(describing: $0).contains("indexed") }
}

func testEntityPropertyRecurrenceRuleTitleIdentifierGetterAndIndexing() {
    let rule = propertyRecurrenceRule()
    exerciseTitleIdentifierGetterAndIndexing(sample: rule) { $0.frequency == .weekly }
}

func testEntityPropertyRecurrenceRuleIndexingKeyGetters() {
    let rule = propertyRecurrenceRule()
    exerciseIndexingKeyGetters(sample: rule) { $0.frequency == .weekly }
}

func testEntityPropertyIntentFileTitleIdentifierGetterAndIndexing() {
    let file = IntentFile(data: Data([0x0A]), filename: "note.bin", type: .data)
    exerciseTitleIdentifierGetterAndIndexing(sample: file) { $0.filename == "note.bin" }
}

func testEntityPropertyIntentFileIndexingKeyGetters() {
    let file = IntentFile(fileURL: URL(fileURLWithPath: "/tmp/idx.bin"), filename: "idx.bin")
    exerciseIndexingKeyGetters(sample: file) { $0.filename == "idx.bin" }
}

func testEntityPropertyIntentPersonTitleIdentifierGetterAndIndexing() {
    let person = propertyPerson()
    exerciseTitleIdentifierGetterAndIndexing(sample: person) {
        if case .applicationDefined(let id) = $0.identifier { return id == "ada" }
        return false
    }
}

func testEntityPropertyIntentPersonIndexingKeyGetters() {
    let person = propertyPerson()
    exerciseIndexingKeyGetters(sample: person) {
        if case .displayName(let name) = $0.name { return name == "Ada" }
        return false
    }
}

func testEntityPropertyIntentPaymentMethodTitleIdentifierGetterAndIndexing() {
    let method = IntentPaymentMethod(type: .applePay, name: LocalizedStringResource("Card"))
    exerciseTitleIdentifierGetterAndIndexing(sample: method) { $0.paymentType == .applePay }
}

func testEntityPropertyIntentPaymentMethodIndexingKeyGetters() {
    let method = IntentPaymentMethod(type: .checking, name: LocalizedStringResource("Bank"))
    exerciseIndexingKeyGetters(sample: method) { $0.paymentType == .checking }
}

func testEntityPropertyIntentCurrencyAmountTitleIdentifierGetterAndIndexing() {
    let amount = IntentCurrencyAmount(amount: 12, currencyCode: "EUR")
    exerciseTitleIdentifierGetterAndIndexing(sample: amount) {
        $0.amount == 12 && $0.currencyCode == "EUR"
    }
}

func testEntityPropertyIntentCurrencyAmountIndexingKeyGetters() {
    let amount = IntentCurrencyAmount(amount: 3, currencyCode: "USD")
    exerciseIndexingKeyGetters(sample: amount) { $0.currencyCode == "USD" }
}

func testEntityPropertyAppEntityTitleIdentifierGetterAndIndexing() {
    EntityResolutionEngine.reset()
    let note = PropertyNote(id: "n1", title: "Nested")
    let holder = PropertyHolder(id: "row", payload: note)
    EntityResolutionEngine.register([holder], default: holder)
    let titled = EntityProperty<PropertyNote>(title: LocalizedStringResource("Note"))
    titled.wrappedValue = note
    precondition(titled.wrappedValue.title == "Nested")
    let empty = EntityProperty<PropertyNote>()
    empty.wrappedValue = note
    precondition(empty.wrappedValue.id == "n1")
    let identified = EntityProperty<PropertyNote>(identifier: "payload")
    precondition(identified.identifier == "payload")
    let titledId = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("Note")
    )
    precondition(titledId.title.key == "Note")
    let getter = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("Note"),
        getter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(getter.wrappedValue.title == "Nested")
    let setter = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("Note"),
        getSetter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(setter.wrappedValue.id == "n1")
    let idGetter = EntityProperty<PropertyNote>(
        identifier: "payload",
        getter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(idGetter.wrappedValue.title == "Nested")
    let idSetter = EntityProperty<PropertyNote>(
        identifier: "payload",
        getSetter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(idSetter.wrappedValue.id == "n1")
    let indexed = EntityProperty<PropertyNote>(indexingKey: \CSSearchableItemAttributeSet.title)
    precondition(indexed.indexingKeyPath != nil)
    let customOnly = EntityProperty<PropertyNote>(
        customIndexingKey: CSCustomAttributeKey(keyName: "note.custom")
    )
    precondition(customOnly.customIndexingKey?.keyName == "note.custom")
    let titleIndexed = EntityProperty<PropertyNote>(
        title: LocalizedStringResource("Indexed"),
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(titleIndexed.indexingKeyName == "indexingKey")
    let titleCustom = EntityProperty<PropertyNote>(
        title: LocalizedStringResource("Custom"),
        customIndexingKey: CSCustomAttributeKey(keyName: "note.title")
    )
    precondition(titleCustom.customIndexingKey?.keyName == "note.title")
}

func testEntityPropertyAppEntityIndexingKeyGetters() {
    EntityResolutionEngine.reset()
    let note = PropertyNote(id: "n2", title: "Indexed Note")
    let holder = PropertyHolder(id: "row", payload: note)
    EntityResolutionEngine.register([holder], default: holder)
    let byIndex = EntityProperty<PropertyNote>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(byIndex.wrappedValue.title == "Indexed Note")
    let byIndexSet = EntityProperty<PropertyNote>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(byIndexSet.wrappedValue.id == "n2")
    let identIndex = EntityProperty<PropertyNote>(
        identifier: "payload",
        indexingKey: \CSSearchableItemAttributeSet.displayName
    )
    precondition(identIndex.identifier == "payload")
    let customGetter = EntityProperty<PropertyNote>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "note.idx"),
        getter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(customGetter.wrappedValue.title == "Indexed Note")
    let customSetter = EntityProperty<PropertyNote>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "note.idx2"),
        getSetter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(customSetter.wrappedValue.id == "n2")
    let identCustom = EntityProperty<PropertyNote>(
        identifier: "payload",
        customIndexingKey: CSCustomAttributeKey(keyName: "note.idx3")
    )
    precondition(identCustom.customIndexingKey?.keyName == "note.idx3")
    let titledIndex = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(titledIndex.wrappedValue.title == "Indexed Note")
    let titledIndexSet = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title,
        getSetter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(titledIndexSet.identifier == "payload")
    let titledIndexOnly = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        indexingKey: \CSSearchableItemAttributeSet.title
    )
    precondition(titledIndexOnly.indexingKeyPath != nil)
    let titledCustomGetter = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "note.t"),
        getter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(titledCustomGetter.wrappedValue.title == "Indexed Note")
    let titledCustomSetter = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "note.t2"),
        getSetter: \PropertyHolder<PropertyNote>.payload
    )
    precondition(titledCustomSetter.customIndexingKey?.keyName == "note.t2")
    let titledCustom = EntityProperty<PropertyNote>(
        identifier: "payload",
        title: LocalizedStringResource("T"),
        customIndexingKey: CSCustomAttributeKey(keyName: "note.t3")
    )
    precondition(titledCustom.customIndexingKey?.keyName == "note.t3")
}

func testIntentParameterDateComponentsKindAndDefaults() {
    var components = DateComponents()
    components.hour = 9
    let withDefault = IntentParameter<DateComponents>(
        title: LocalizedStringResource("When"),
        description: LocalizedStringResource("Due"),
        default: components,
        kind: .date,
        requestValueDialog: IntentDialog("need date")
    )
    precondition(withDefault.wrappedValue.hour == 9)
    precondition(withDefault.dateKind == .date)
    precondition(withDefault.metadata.requestValueDialog?.text == "need date")
    let titledKind = IntentParameter<DateComponents>(
        title: LocalizedStringResource("Time"),
        description: LocalizedStringResource("Clock"),
        kind: .time
    )
    titledKind.wrappedValue = components
    precondition(titledKind.dateKind == .time)
    let descriptionOnly = IntentParameter<DateComponents>(
        description: LocalizedStringResource("bare"),
        default: components,
        kind: .dateTime
    )
    precondition(descriptionOnly.wrappedValue.hour == 9)
    precondition(descriptionOnly.dateKind == .dateTime)
    let context = IntentParameterContext<DateComponents>()
    _ = context.dateKind
}

func testIntentParameterDateComponentsOptionsProviderAndResolvers() {
    var components = DateComponents()
    components.minute = 15
    let withProvider = IntentParameter<DateComponents>(
        title: LocalizedStringResource("When"),
        description: LocalizedStringResource("Due"),
        default: components,
        kind: .dateTime,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    precondition(withProvider.wrappedValue.minute == 15)
    let descProvider = IntentParameter<DateComponents>(
        description: LocalizedStringResource("d"),
        default: components,
        kind: .date,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)
    let titledProvider = IntentParameter<DateComponents>(
        title: LocalizedStringResource("T"),
        kind: .time,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(titledProvider.hasOptionsProvider == true)
    let withResolvers = IntentParameter<DateComponents>(
        title: LocalizedStringResource("R"),
        description: LocalizedStringResource("d"),
        default: components,
        kind: .date,
        resolvers: EmptyResolverSpecification<DateComponents>()
    )
    precondition(withResolvers.dateKind == .date)
    let descResolvers = IntentParameter<DateComponents>(
        description: LocalizedStringResource("d"),
        default: components,
        kind: .time,
        resolvers: EmptyResolverSpecification<DateComponents>()
    )
    precondition(descResolvers.dateKind == .time)
    let titledResolvers = IntentParameter<DateComponents>(
        title: LocalizedStringResource("R"),
        kind: .dateTime,
        resolvers: EmptyResolverSpecification<DateComponents>()
    )
    precondition(titledResolvers.dateKind == .dateTime)
    let both = IntentParameter<DateComponents>(
        title: LocalizedStringResource("B"),
        description: LocalizedStringResource("d"),
        default: components,
        kind: .date,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<DateComponents>()
    )
    precondition(both.hasOptionsProvider == true)
    let descBoth = IntentParameter<DateComponents>(
        description: LocalizedStringResource("d"),
        default: components,
        kind: .time,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<DateComponents>()
    )
    precondition(descBoth.hasOptionsProvider == true)
    let titledBoth = IntentParameter<DateComponents>(
        title: LocalizedStringResource("B"),
        kind: .dateTime,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<DateComponents>()
    )
    precondition(titledBoth.hasOptionsProvider == true)
}

func testIntentParameterCurrencyAmountCodesRangeAndDefaults() {
    let amount = IntentCurrencyAmount(amount: 20, currencyCode: "USD")
    let parameter = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("Price"),
        description: LocalizedStringResource("Pay"),
        default: amount,
        currencyCodes: ["USD", "EUR"],
        inclusiveRange: (Decimal(0), Decimal(500)),
        requestValueDialog: IntentDialog("need amount")
    )
    precondition(parameter.wrappedValue.amount == 20)
    precondition(parameter.currencyCodes == ["USD", "EUR"])
    precondition(parameter.inclusiveRange?.lowerBound == 0)
    precondition(parameter.inclusiveRange?.upperBound == 500)
    let titled = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("Fee"),
        currencyCodes: ["GBP"]
    )
    titled.wrappedValue = amount
    precondition(titled.currencyCodes == ["GBP"])
    let descriptionOnly = IntentParameter<IntentCurrencyAmount>(
        description: LocalizedStringResource("bare"),
        default: amount,
        currencyCodes: ["USD"]
    )
    precondition(descriptionOnly.wrappedValue.currencyCode == "USD")
    var context = IntentParameterContext<IntentCurrencyAmount>()
    context.storedCurrencyCodes = ["JPY"]
    precondition(context.currencyCodes == ["JPY"])
}

func testIntentParameterCurrencyAmountOptionsProviderAndResolvers() {
    let amount = IntentCurrencyAmount(amount: 7, currencyCode: "EUR")
    let withProvider = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("Price"),
        default: amount,
        currencyCodes: ["EUR"],
        optionsProvider: PropertyNoteQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    let descProvider = IntentParameter<IntentCurrencyAmount>(
        description: LocalizedStringResource("d"),
        default: amount,
        currencyCodes: ["EUR"],
        optionsProvider: PropertyNoteQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)
    let titledProvider = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("T"),
        currencyCodes: ["USD"],
        optionsProvider: PropertyNoteQuery()
    )
    precondition(titledProvider.hasOptionsProvider == true)
    let withResolvers = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("R"),
        default: amount,
        currencyCodes: ["EUR"],
        resolvers: EmptyResolverSpecification<IntentCurrencyAmount>()
    )
    precondition(withResolvers.currencyCodes == ["EUR"])
    let descResolvers = IntentParameter<IntentCurrencyAmount>(
        description: LocalizedStringResource("d"),
        default: amount,
        currencyCodes: ["USD"],
        resolvers: EmptyResolverSpecification<IntentCurrencyAmount>()
    )
    precondition(descResolvers.currencyCodes == ["USD"])
    let titledResolvers = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("R"),
        currencyCodes: ["GBP"],
        resolvers: EmptyResolverSpecification<IntentCurrencyAmount>()
    )
    precondition(titledResolvers.currencyCodes == ["GBP"])
    let both = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("B"),
        default: amount,
        currencyCodes: ["EUR"],
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentCurrencyAmount>()
    )
    precondition(both.hasOptionsProvider == true)
    let descBoth = IntentParameter<IntentCurrencyAmount>(
        description: LocalizedStringResource("d"),
        default: amount,
        currencyCodes: ["EUR"],
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentCurrencyAmount>()
    )
    precondition(descBoth.hasOptionsProvider == true)
    let titledBoth = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("B"),
        currencyCodes: ["USD"],
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentCurrencyAmount>()
    )
    precondition(titledBoth.hasOptionsProvider == true)
}

func testIntentParameterPersonModeAndDefaults() {
    let person = propertyPerson()
    let parameter = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("Who"),
        description: LocalizedStringResource("Contact"),
        default: person,
        mode: .email,
        requestValueDialog: IntentDialog("need person")
    )
    precondition(parameter.parameterMode == .email)
    if case .displayName(let name) = parameter.wrappedValue.name {
        precondition(name == "Ada")
    } else {
        preconditionFailure("expected display name")
    }
    let titled = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("Who"),
        mode: .phone
    )
    titled.wrappedValue = person
    precondition(titled.parameterMode == .phone)
    let descriptionOnly = IntentParameter<IntentPerson>(
        description: LocalizedStringResource("bare"),
        default: person,
        mode: .contact
    )
    precondition(descriptionOnly.parameterMode == .contact)
    var context = IntentParameterContext<IntentPerson>()
    context.storedPersonMode = .emailOrPhone
    precondition(context.parameterMode == .emailOrPhone)
}

func testIntentParameterPersonOptionsProviderAndResolvers() {
    let person = propertyPerson()
    let withProvider = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("Who"),
        default: person,
        mode: .email,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    let descProvider = IntentParameter<IntentPerson>(
        description: LocalizedStringResource("d"),
        default: person,
        mode: .phone,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)
    let titledProvider = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("T"),
        mode: .contact,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(titledProvider.hasOptionsProvider == true)
    let withResolvers = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("R"),
        default: person,
        mode: .email,
        resolvers: EmptyResolverSpecification<IntentPerson>()
    )
    precondition(withResolvers.parameterMode == .email)
    let descResolvers = IntentParameter<IntentPerson>(
        description: LocalizedStringResource("d"),
        default: person,
        mode: .phone,
        resolvers: EmptyResolverSpecification<IntentPerson>()
    )
    precondition(descResolvers.parameterMode == .phone)
    let titledResolvers = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("R"),
        mode: .emailOrPhone,
        resolvers: EmptyResolverSpecification<IntentPerson>()
    )
    precondition(titledResolvers.parameterMode == .emailOrPhone)
    let both = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("B"),
        default: person,
        mode: .email,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentPerson>()
    )
    precondition(both.hasOptionsProvider == true)
    let descBoth = IntentParameter<IntentPerson>(
        description: LocalizedStringResource("d"),
        default: person,
        mode: .phone,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentPerson>()
    )
    precondition(descBoth.hasOptionsProvider == true)
    let titledBoth = IntentParameter<IntentPerson>(
        title: LocalizedStringResource("B"),
        mode: .contact,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentPerson>()
    )
    precondition(titledBoth.hasOptionsProvider == true)
}

func testIntentParameterPaymentMethodDefaultsAndProviders() {
    let method = IntentPaymentMethod(type: .credit, name: LocalizedStringResource("Visa"))
    let withDefault = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("Pay"),
        description: LocalizedStringResource("Card"),
        default: method,
        requestValueDialog: IntentDialog("need method")
    )
    precondition(withDefault.wrappedValue.paymentType == .credit)
    let descriptionOnly = IntentParameter<IntentPaymentMethod>(
        description: LocalizedStringResource("bare"),
        default: method
    )
    precondition(descriptionOnly.wrappedValue.paymentType == .credit)
    let titled = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("Pay"),
        description: LocalizedStringResource("Card")
    )
    titled.wrappedValue = method
    precondition(titled.wrappedValue.paymentType == .credit)
    let withProvider = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("Pay"),
        default: method,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(withProvider.hasOptionsProvider == true)
    let descProvider = IntentParameter<IntentPaymentMethod>(
        description: LocalizedStringResource("d"),
        default: method,
        optionsProvider: PropertyNoteQuery()
    )
    precondition(descProvider.hasOptionsProvider == true)
    let titledProvider = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("T"),
        optionsProvider: PropertyNoteQuery()
    )
    precondition(titledProvider.hasOptionsProvider == true)
    let withResolvers = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("R"),
        default: method,
        resolvers: EmptyResolverSpecification<IntentPaymentMethod>()
    )
    precondition(withResolvers.wrappedValue.paymentType == .credit)
    let descResolvers = IntentParameter<IntentPaymentMethod>(
        description: LocalizedStringResource("d"),
        default: method,
        resolvers: EmptyResolverSpecification<IntentPaymentMethod>()
    )
    precondition(descResolvers.wrappedValue.paymentType == .credit)
    let titledResolvers = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("R"),
        resolvers: EmptyResolverSpecification<IntentPaymentMethod>()
    )
    titledResolvers.wrappedValue = method
    precondition(titledResolvers.wrappedValue.paymentType == .credit)
    let both = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("B"),
        default: method,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentPaymentMethod>()
    )
    precondition(both.hasOptionsProvider == true)
    let descBoth = IntentParameter<IntentPaymentMethod>(
        description: LocalizedStringResource("d"),
        default: method,
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentPaymentMethod>()
    )
    precondition(descBoth.hasOptionsProvider == true)
    let titledBoth = IntentParameter<IntentPaymentMethod>(
        title: LocalizedStringResource("B"),
        optionsProvider: PropertyNoteQuery(),
        resolvers: EmptyResolverSpecification<IntentPaymentMethod>()
    )
    precondition(titledBoth.hasOptionsProvider == true)
}

func testSampleCurrencyIntentHostResult() {
    let intent = PropertyPayIntent()
    precondition(intent.amount.currencyCode == "USD")
    let result = intent.hostResult()
    precondition(result.value == "USD")
    precondition(result.dialog?.text == "paid=USD")
    intent.amount = IntentCurrencyAmount(amount: 9, currencyCode: "EUR")
    let converted = intent.hostResult()
    precondition(converted.value == "EUR")
}
