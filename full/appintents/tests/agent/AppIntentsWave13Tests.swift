import Foundation
import AppIntents

private struct Wave13Entity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave13" }
    static var defaultQuery = Wave13Query()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: id) }
}

private struct Wave13Query: EntityQuery {
    typealias Entity = Wave13Entity
    init() {}
    func entities(for identifiers: [String]) async throws -> [Wave13Entity] {
        EntityResolutionEngine.entities(for: identifiers, as: Wave13Entity.self)
    }
    func suggestedEntities() async throws -> [Wave13Entity] {
        EntityResolutionEngine.suggestedEntities(Wave13Entity.self)
    }
}

private enum Wave13Kind: String, AppEnum, AppEntity {
    case alpha
    case beta
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave13 Kind" }
    static var caseDisplayRepresentations: [Wave13Kind: DisplayRepresentation] {
        [.alpha: "Alpha", .beta: "Beta"]
    }
    static var defaultQuery = Wave13KindQuery()
    var id: String { rawValue }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: rawValue) }
    var localizedStringResource: LocalizedStringResource { displayRepresentation.title }
}

private struct Wave13KindQuery: EntityQuery {
    typealias Entity = Wave13Kind
    init() {}
    func entities(for identifiers: [String]) async throws -> [Wave13Kind] {
        identifiers.compactMap { Wave13Kind(rawValue: $0) }
    }
}

private struct Wave13FileEntity: FileEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave13 File" }
    static var defaultQuery = Wave13FileQuery()
    var id: FileEntityIdentifier
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: id.entityIdentifierString)
    }
}

private struct Wave13FileQuery: EntityQuery {
    typealias Entity = Wave13FileEntity
    init() {}
    func entities(for identifiers: [FileEntityIdentifier]) async throws -> [Wave13FileEntity] {
        identifiers.map { Wave13FileEntity(id: $0) }
    }
}

private enum Wave13Enum: String, AppEnum {
    case one
    case two
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Wave13 Enum" }
    static var caseDisplayRepresentations: [Wave13Enum: DisplayRepresentation] {
        [.one: "One", .two: "Two"]
    }
}

func testDeprecatedAppIntentStoresReplacementTypeName() {
    let deprecation = HostDeprecatedOpenURLIntent.deprecation
    precondition(deprecation.message.key == "Use OpenURLIntent")
    precondition(deprecation.hostReplacementTypeName == String(describing: OpenURLIntent.self))
    precondition(deprecation.replacedBy == OpenURLIntent.self)
    let byType = IntentDeprecation<OpenURLIntent>(replacedBy: OpenURLIntent.self)
    precondition(byType.hostReplacementTypeName == String(describing: OpenURLIntent.self))
    precondition(byType.replacedBy == OpenURLIntent.self)
    let neverMessage = IntentDeprecation<Never>(message: LocalizedStringResource("gone"))
    precondition(neverMessage.message.key == "gone")
    precondition(neverMessage.replacedBy == nil)
    precondition(neverMessage.hostReplacementTypeName == nil)
    let empty = IntentDeprecation<Never>()
    precondition(empty.replacedBy == nil)
    let _: any DeprecatedAppIntent.Type = HostDeprecatedOpenURLIntent.self
    _ = HostDeprecatedOpenURLIntent.ReplacementIntent.self
}

func testFocusFilterAppContextStoresPredicateAndPrefix() {
    let empty = FocusFilterAppContext()
    precondition(empty.notificationFilterPredicate == nil)
    precondition(empty.targetContentIdentifierPrefix == nil)
    precondition(empty.hostPredicateFormat == nil)
    let predicate = NSPredicate(value: true)
    let filtered = FocusFilterAppContext(notificationFilterPredicate: predicate)
    precondition(filtered.notificationFilterPredicate != nil)
    precondition(filtered.hostPredicateFormat != nil)
    precondition(filtered.targetContentIdentifierPrefix == nil)
    let prefixed = FocusFilterAppContext(
        notificationFilterPredicate: predicate,
        targetContentIdentifierPrefix: "note."
    )
    precondition(prefixed.targetContentIdentifierPrefix == "note.")
    precondition(prefixed.notificationFilterPredicate != nil)
}

func testCustomIntentMigratedAppIntentPersistentIdentifier() {
    precondition(HostMigratedCustomIntent.intentClassName == "INLegacyCustomIntent")
    precondition(HostMigratedCustomIntent.persistentIdentifier == "INLegacyCustomIntent")
    let _: any CustomIntentMigratedAppIntent.Type = HostMigratedCustomIntent.self
}

func testShowInAppSearchResultsIntentStoresScopesCriteriaAndOpensApp() {
    precondition(HostShowStringSearchResultsIntent.openAppWhenRun == true)
    precondition(HostShowStringSearchResultsIntent.searchScopes == [.general, .movies])
    var intent = HostShowStringSearchResultsIntent(criteria: StringSearchCriteria(term: "notes"))
    precondition(intent.criteria.term == "notes")
    intent.criteria = StringSearchCriteria(term: "updated")
    precondition(intent.criteria.term == "updated")
    let voidIntent = HostShowVoidSearchResultsIntent()
    precondition(HostShowVoidSearchResultsIntent.searchScopes == ())
    _ = voidIntent.criteria
    let _: any ShowInAppSearchResultsIntent = intent
}

func testStringSearchCriteriaTermHashAndParameter() {
    let criteria = StringSearchCriteria(term: "hello")
    precondition(criteria.term == "hello")
    var hasher = Hasher()
    criteria.hash(into: &hasher)
    let hashed = hasher.finalize()
    var hasher2 = Hasher()
    StringSearchCriteria(term: "hello").hash(into: &hasher2)
    precondition(hashed == hasher2.finalize())
    precondition(StringSearchCriteria().term == "")
    let _: StringSearchCriteria.SearchScopes.Type = [StringSearchScope].self
    let titled = IntentParameter<StringSearchCriteria>(
        title: LocalizedStringResource("Query"),
        description: LocalizedStringResource("Find"),
        requestValueDialog: IntentDialog("need query")
    )
    titled.wrappedValue = criteria
    precondition(titled.wrappedValue.term == "hello")
    precondition(titled.title.key == "Query")
    let described = IntentParameter<StringSearchCriteria>(
        description: LocalizedStringResource("Find")
    )
    described.wrappedValue = StringSearchCriteria(term: "d")
    precondition(described.wrappedValue.term == "d")
    let resolved = try! StringSearchCriteriaFromStringResolverSpecificification().hostResolve(
        from: "resolved",
        context: IntentParameterContext<StringSearchCriteria>(title: "q")
    )
    precondition(resolved?.term == "resolved")
}

func testIntentParameterRemainingAppEntityFileAndEnumStorage() {
    let entity = Wave13Entity(id: "e1")
    let query = Wave13Query()
    let titled = IntentParameter<Wave13Entity>(
        title: LocalizedStringResource("Item"),
        description: LocalizedStringResource("Pick"),
        default: entity,
        requestValueDialog: IntentDialog("need"),
        requestDisambiguationDialog: IntentDialog("which")
    )
    precondition(titled.wrappedValue.id == "e1")
    precondition(titled.requestDisambiguationDialog?.text == "which")
    let described = IntentParameter<Wave13Entity>(
        description: LocalizedStringResource("Pick"),
        default: entity,
        requestDisambiguationDialog: IntentDialog("which")
    )
    precondition(described.wrappedValue.id == "e1")
    let withQuery = IntentParameter<Wave13Entity>(
        description: LocalizedStringResource("Pick"),
        default: entity,
        requestDisambiguationDialog: IntentDialog("which"),
        query: query
    )
    precondition(withQuery.wrappedValue.id == "e1")
    let provider = IntentParameter<Wave13Entity>(
        title: LocalizedStringResource("Item"),
        default: entity,
        optionsProvider: query
    )
    precondition(provider.hasOptionsProvider == true)
    let descProvider = IntentParameter<Wave13Entity>(
        description: LocalizedStringResource("Pick"),
        default: entity,
        optionsProvider: query
    )
    precondition(descProvider.hasOptionsProvider == true)
    let titledProvider = IntentParameter<Wave13Entity>(
        title: LocalizedStringResource("Item"),
        requestDisambiguationDialog: nil,
        optionsProvider: query
    )
    titledProvider.wrappedValue = entity
    precondition(titledProvider.hasOptionsProvider == true)
    let resolvers = IntentParameter<Wave13Entity>(
        title: LocalizedStringResource("Item"),
        default: entity,
        resolvers: EmptyResolverSpecification<Wave13Entity>()
    )
    precondition(resolvers.wrappedValue.id == "e1")
    let descResolvers = IntentParameter<Wave13Entity>(
        description: LocalizedStringResource("Pick"),
        default: entity,
        resolvers: EmptyResolverSpecification<Wave13Entity>()
    )
    precondition(descResolvers.wrappedValue.id == "e1")
    let both = IntentParameter<Wave13Entity>(
        title: LocalizedStringResource("Item"),
        default: entity,
        optionsProvider: query,
        resolvers: EmptyResolverSpecification<Wave13Entity>()
    )
    precondition(both.hasOptionsProvider == true)
    let descBoth = IntentParameter<Wave13Entity>(
        description: LocalizedStringResource("Pick"),
        default: entity,
        optionsProvider: query,
        resolvers: EmptyResolverSpecification<Wave13Entity>()
    )
    precondition(descBoth.hasOptionsProvider == true)
    let titledBoth = IntentParameter<Wave13Entity>(
        title: LocalizedStringResource("Item"),
        optionsProvider: query,
        resolvers: EmptyResolverSpecification<Wave13Entity>()
    )
    titledBoth.wrappedValue = entity
    precondition(titledBoth.hasOptionsProvider == true)

    let kind = IntentParameter<Wave13Kind>(
        title: LocalizedStringResource("Kind"),
        default: .alpha,
        supportedValues: [.alpha, .beta]
    )
    precondition(kind.wrappedValue == .alpha)
    precondition(kind.supportedValues.count == 2)
    let kindDesc = IntentParameter<Wave13Kind>(
        description: LocalizedStringResource("Kind"),
        default: .beta,
        supportedValues: [.beta]
    )
    precondition(kindDesc.wrappedValue == .beta)
    let kindProvider = IntentParameter<Wave13Kind>(
        title: LocalizedStringResource("Kind"),
        default: .alpha,
        supportedValues: [.alpha],
        optionsProvider: Wave13KindQuery()
    )
    precondition(kindProvider.hasOptionsProvider == true)
    let kindDescProvider = IntentParameter<Wave13Kind>(
        description: LocalizedStringResource("Kind"),
        default: .alpha,
        supportedValues: [.alpha],
        optionsProvider: Wave13KindQuery()
    )
    precondition(kindDescProvider.hasOptionsProvider == true)
    let kindResolvers = IntentParameter<Wave13Kind>(
        title: LocalizedStringResource("Kind"),
        default: .beta,
        supportedValues: [.beta],
        resolvers: EmptyResolverSpecification<Wave13Kind>()
    )
    precondition(kindResolvers.wrappedValue == .beta)
    let kindDescResolvers = IntentParameter<Wave13Kind>(
        description: LocalizedStringResource("Kind"),
        default: .beta,
        supportedValues: [.beta],
        resolvers: EmptyResolverSpecification<Wave13Kind>()
    )
    precondition(kindDescResolvers.wrappedValue == .beta)

    let enumProvider = IntentParameter<Wave13Enum>(
        description: LocalizedStringResource("E"),
        default: .one,
        supportedValues: [.one],
        optionsProvider: query
    )
    precondition(enumProvider.hasOptionsProvider == true)
    let enumResolvers = IntentParameter<Wave13Enum>(
        description: LocalizedStringResource("E"),
        default: .two,
        supportedValues: [.two],
        resolvers: EmptyResolverSpecification<Wave13Enum>()
    )
    precondition(enumResolvers.wrappedValue == .two)

    let file = IntentFile(data: Data([1]), filename: "a.bin", type: .item)
    let fileDesc = IntentParameter<IntentFile>(
        description: LocalizedStringResource("File"),
        default: file,
        supportedContentTypes: [.item]
    )
    precondition(fileDesc.wrappedValue.filename == "a.bin")
    let fileIds = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        default: file,
        supportedTypeIdentifiers: ["public.data"]
    )
    precondition(fileIds.supportedTypeIdentifiers == ["public.data"])
    let fileIdsOnly = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        supportedTypeIdentifiers: ["public.item"]
    )
    fileIdsOnly.wrappedValue = file
    precondition(fileIdsOnly.supportedTypeIdentifiers == ["public.item"])
    let fileDescProvider = IntentParameter<IntentFile>(
        description: LocalizedStringResource("File"),
        default: file,
        optionsProvider: query
    )
    precondition(fileDescProvider.hasOptionsProvider == true)
    let fileProvider = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        default: file,
        supportedContentTypes: [.item],
        optionsProvider: query
    )
    precondition(fileProvider.hasOptionsProvider == true)
    let fileIdProvider = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        supportedTypeIdentifiers: ["public.item"],
        optionsProvider: query
    )
    precondition(fileIdProvider.hasOptionsProvider == true)
    let fileDescResolvers = IntentParameter<IntentFile>(
        description: LocalizedStringResource("File"),
        default: file,
        resolvers: EmptyResolverSpecification<IntentFile>()
    )
    precondition(fileDescResolvers.wrappedValue.filename == "a.bin")
    let fileResolvers = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        default: file,
        supportedContentTypes: [.item],
        resolvers: EmptyResolverSpecification<IntentFile>()
    )
    precondition(fileResolvers.wrappedValue.filename == "a.bin")
    let fileIdResolvers = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        default: file,
        supportedTypeIdentifiers: ["public.data"],
        resolvers: EmptyResolverSpecification<IntentFile>()
    )
    precondition(fileIdResolvers.supportedTypeIdentifiers == ["public.data"])
    let fileDescBoth = IntentParameter<IntentFile>(
        description: LocalizedStringResource("File"),
        default: file,
        optionsProvider: query,
        resolvers: EmptyResolverSpecification<IntentFile>()
    )
    precondition(fileDescBoth.hasOptionsProvider == true)
    let fileBoth = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        default: file,
        supportedContentTypes: [.item],
        optionsProvider: query,
        resolvers: EmptyResolverSpecification<IntentFile>()
    )
    precondition(fileBoth.hasOptionsProvider == true)
    let fileIdBoth = IntentParameter<IntentFile>(
        title: LocalizedStringResource("File"),
        supportedTypeIdentifiers: ["public.item"],
        optionsProvider: query,
        resolvers: EmptyResolverSpecification<IntentFile>()
    )
    precondition(fileIdBoth.hasOptionsProvider == true)

    let fileEntity = Wave13FileEntity(id: FileEntityIdentifier(URL(fileURLWithPath: "/tmp/w13.bin")))
    let fe = IntentParameter<Wave13FileEntity>(
        title: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item]
    )
    precondition(fe.wrappedValue.id.entityIdentifierString.contains("w13.bin"))
    let feDesc = IntentParameter<Wave13FileEntity>(
        description: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item]
    )
    precondition(feDesc.wrappedValue.id.isDraft == false)
    let feQuery = IntentParameter<Wave13FileEntity>(
        title: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.data],
        query: Wave13FileQuery()
    )
    precondition(feQuery.supportedTypeIdentifiers == ["public.data"])
    let feDescQuery = IntentParameter<Wave13FileEntity>(
        description: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        query: Wave13FileQuery()
    )
    precondition(feDescQuery.wrappedValue.id.entityIdentifierString.contains("w13.bin"))
    let feProvider = IntentParameter<Wave13FileEntity>(
        title: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        optionsProvider: Wave13FileQuery()
    )
    precondition(feProvider.hasOptionsProvider == true)
    let feDescProvider = IntentParameter<Wave13FileEntity>(
        description: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        optionsProvider: Wave13FileQuery()
    )
    precondition(feDescProvider.hasOptionsProvider == true)
    let feResolvers = IntentParameter<Wave13FileEntity>(
        title: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        resolvers: EmptyResolverSpecification<Wave13FileEntity>()
    )
    precondition(feResolvers.wrappedValue.id.entityIdentifierString.contains("w13.bin"))
    let feDescResolvers = IntentParameter<Wave13FileEntity>(
        description: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        resolvers: EmptyResolverSpecification<Wave13FileEntity>()
    )
    precondition(feDescResolvers.wrappedValue.id.entityIdentifierString.contains("w13.bin"))
    let feBoth = IntentParameter<Wave13FileEntity>(
        title: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        optionsProvider: Wave13FileQuery(),
        resolvers: EmptyResolverSpecification<Wave13FileEntity>()
    )
    precondition(feBoth.hasOptionsProvider == true)
    let feDescBoth = IntentParameter<Wave13FileEntity>(
        description: LocalizedStringResource("Doc"),
        default: fileEntity,
        supportedContentTypes: [.item],
        optionsProvider: Wave13FileQuery(),
        resolvers: EmptyResolverSpecification<Wave13FileEntity>()
    )
    precondition(feDescBoth.hasOptionsProvider == true)
}

func testIntentParameterRemainingCollectionSizeAndDisplayName() {
    let entity = Wave13Entity(id: "c1")
    let sized = IntentParameter<[Wave13Entity]>(
        title: LocalizedStringResource("Items"),
        description: LocalizedStringResource("Many"),
        default: entity,
        size: IntentCollectionSize(exactly: 2)
    )
    precondition(sized.collectionSize?.min == 2)
    precondition(sized.wrappedValue.first?.id == "c1")
    let sizedDesc = IntentParameter<[Wave13Entity]>(
        description: LocalizedStringResource("Many"),
        default: entity,
        size: 3
    )
    precondition(sizedDesc.collectionSize?.max == 3)
    let sizedQuery = IntentParameter<[Wave13Entity]>(
        title: LocalizedStringResource("Items"),
        default: entity,
        size: IntentCollectionSize(min: 1, max: 4),
        query: Wave13Query()
    )
    precondition(sizedQuery.collectionSize?.min == 1)
    let sizedDescQuery = IntentParameter<[Wave13Entity]>(
        description: LocalizedStringResource("Many"),
        default: entity,
        size: 1,
        query: Wave13Query()
    )
    precondition(sizedDescQuery.wrappedValue.count == 1)
    let sizedResolvers = IntentParameter<[Wave13Entity]>(
        title: LocalizedStringResource("Items"),
        default: entity,
        size: 2,
        resolvers: EmptyResolverSpecification<[Wave13Entity]>()
    )
    precondition(sizedResolvers.collectionSize?.min == 2)
    let sizedDescResolvers = IntentParameter<[Wave13Entity]>(
        description: LocalizedStringResource("Many"),
        default: entity,
        size: 2,
        resolvers: EmptyResolverSpecification<[Wave13Entity]>()
    )
    precondition(sizedDescResolvers.wrappedValue.first?.id == "c1")

    let person = IntentPerson(
        identifier: .applicationDefined("p"),
        name: .displayName("Ada"),
        handle: IntentPerson.Handle(emailAddress: "a@b.test")
    )
    let people = IntentParameter<[IntentPerson]>(
        title: LocalizedStringResource("People"),
        default: person,
        mode: .contact,
        size: 2
    )
    precondition(people.parameterMode == .contact)
    precondition(people.wrappedValue.first?.name == .displayName("Ada"))
    let peopleDesc = IntentParameter<[IntentPerson]>(
        description: LocalizedStringResource("People"),
        default: person,
        mode: .email,
        size: 1
    )
    precondition(peopleDesc.parameterMode == .email)
    let peopleMode = IntentParameter<[IntentPerson]>(
        title: LocalizedStringResource("People"),
        mode: .phone,
        size: 3
    )
    peopleMode.wrappedValue = [person]
    precondition(peopleMode.parameterMode == .phone)

    let fileEntity = Wave13FileEntity(id: FileEntityIdentifier(URL(fileURLWithPath: "/tmp/c.bin")))
    let files = IntentParameter<[Wave13FileEntity]>(
        title: LocalizedStringResource("Files"),
        default: fileEntity,
        supportedContentTypes: [.item],
        size: 2
    )
    precondition(files.collectionSize?.min == 2)
    let filesDesc = IntentParameter<[Wave13FileEntity]>(
        description: LocalizedStringResource("Files"),
        default: fileEntity,
        supportedContentTypes: [.data],
        size: 1
    )
    precondition(filesDesc.supportedTypeIdentifiers == ["public.data"])
    let filesQuery = IntentParameter<[Wave13FileEntity]>(
        title: LocalizedStringResource("Files"),
        default: fileEntity,
        supportedContentTypes: [.item],
        size: 2,
        query: Wave13FileQuery()
    )
    precondition(filesQuery.wrappedValue.count == 1)
    let filesDescQuery = IntentParameter<[Wave13FileEntity]>(
        description: LocalizedStringResource("Files"),
        default: fileEntity,
        supportedContentTypes: [.item],
        size: 2,
        query: Wave13FileQuery()
    )
    precondition(filesDescQuery.collectionSize?.max == 2)
    let filesResolvers = IntentParameter<[Wave13FileEntity]>(
        title: LocalizedStringResource("Files"),
        default: fileEntity,
        supportedContentTypes: [.item],
        size: 2,
        resolvers: EmptyResolverSpecification<[Wave13FileEntity]>()
    )
    precondition(filesResolvers.wrappedValue.first?.id.entityIdentifierString.contains("c.bin") == true)
    let filesDescResolvers = IntentParameter<[Wave13FileEntity]>(
        description: LocalizedStringResource("Files"),
        default: fileEntity,
        supportedContentTypes: [.item],
        size: 2,
        resolvers: EmptyResolverSpecification<[Wave13FileEntity]>()
    )
    precondition(filesDescResolvers.collectionSize?.min == 2)

    let urls = IntentParameter<[URL]>(
        description: LocalizedStringResource("Links"),
        default: [URL(string: "https://example.invalid")!, nil]
    )
    precondition(urls.wrappedValue.count == 1)
    let urlResolvers = IntentParameter<[URL]>(
        description: LocalizedStringResource("Links"),
        default: [URL(string: "https://a.test")!],
        resolvers: EmptyResolverSpecification<[URL]>()
    )
    precondition(urlResolvers.wrappedValue.first?.host == "a.test")
    let urlTitleResolvers = IntentParameter<[URL]>(
        title: LocalizedStringResource("Links"),
        default: [URL(string: "https://b.test")!],
        resolvers: EmptyResolverSpecification<[URL]>()
    )
    precondition(urlTitleResolvers.wrappedValue.first?.host == "b.test")

    let labels = Bool.IntentDisplayName(true: "On", false: "Off")
    precondition(labels.true.key == "On")
    precondition(labels.false.key == "Off")
    let flag = IntentParameter<Bool>(
        title: LocalizedStringResource("Enabled"),
        default: true,
        displayName: labels
    )
    precondition(flag.displayName?.true.key == "On")
    precondition(flag.wrappedValue == true)
    let flagDesc = IntentParameter<Bool>(
        description: LocalizedStringResource("Enabled"),
        default: false,
        displayName: labels
    )
    precondition(flagDesc.displayName?.false.key == "Off")
    let flagResolvers = IntentParameter<Bool>(
        title: LocalizedStringResource("Enabled"),
        default: true,
        displayName: labels,
        resolvers: EmptyResolverSpecification<Bool>()
    )
    precondition(flagResolvers.displayName?.true.key == "On")
    let flagDescResolvers = IntentParameter<Bool>(
        description: LocalizedStringResource("Enabled"),
        default: false,
        displayName: labels,
        resolvers: EmptyResolverSpecification<Bool>()
    )
    precondition(flagDescResolvers.wrappedValue == false)
    let context = flag.makeContext()
    precondition(context.displayName?.true.key == "On")
}

func testIntentParameterRemainingStringDateURLAndControlStyle() {
    let options = String.IntentInputOptions(
        keyboardType: .asciiCapable,
        capitalizationType: .none,
        multiline: false
    )
    let stringDesc = IntentParameter<String>(
        description: LocalizedStringResource("Q"),
        default: "x",
        inputOptions: options
    )
    precondition(stringDesc.wrappedValue == "x")
    precondition(stringDesc.inputOptions?.keyboardType == .asciiCapable)
    let stringDescResolvers = IntentParameter<String>(
        description: LocalizedStringResource("Q"),
        default: "y",
        inputOptions: options,
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(stringDescResolvers.wrappedValue == "y")
    let stringResolvers = IntentParameter<String>(
        title: LocalizedStringResource("Q"),
        default: "z",
        inputOptions: options,
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(stringResolvers.wrappedValue == "z")
    let stringDescProvider = IntentParameter<String>(
        description: LocalizedStringResource("Q"),
        inputOptions: options,
        optionsProvider: Wave13Query()
    )
    precondition(stringDescProvider.hasOptionsProvider == true)
    let stringDescBoth = IntentParameter<String>(
        description: LocalizedStringResource("Q"),
        inputOptions: options,
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(stringDescBoth.hasOptionsProvider == true)
    let stringBoth = IntentParameter<String>(
        title: LocalizedStringResource("Q"),
        inputOptions: options,
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<String>()
    )
    precondition(stringBoth.hasOptionsProvider == true)

    let date = Date(timeIntervalSince1970: 10)
    let dateDesc = IntentParameter<Date>(
        description: LocalizedStringResource("When"),
        default: date,
        kind: .date
    )
    precondition(dateDesc.dateKind == .date)
    precondition(dateDesc.wrappedValue.timeIntervalSince1970 == 10)
    let dateKind = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        kind: .time
    )
    dateKind.wrappedValue = date
    precondition(dateKind.dateKind == .time)
    let dateProvider = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        default: date,
        kind: .dateTime,
        optionsProvider: Wave13Query()
    )
    precondition(dateProvider.hasOptionsProvider == true)
    let dateDescProvider = IntentParameter<Date>(
        description: LocalizedStringResource("When"),
        default: date,
        optionsProvider: Wave13Query()
    )
    precondition(dateDescProvider.hasOptionsProvider == true)
    let dateKindProvider = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        kind: .date,
        optionsProvider: Wave13Query()
    )
    precondition(dateKindProvider.hasOptionsProvider == true)
    let dateResolvers = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        default: date,
        kind: .date,
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(dateResolvers.dateKind == .date)
    let dateDescResolvers = IntentParameter<Date>(
        description: LocalizedStringResource("When"),
        default: date,
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(dateDescResolvers.wrappedValue.timeIntervalSince1970 == 10)
    let dateKindResolvers = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        kind: .time,
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(dateKindResolvers.dateKind == .time)
    let dateBoth = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        default: date,
        kind: .dateTime,
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(dateBoth.hasOptionsProvider == true)
    let dateDescBoth = IntentParameter<Date>(
        description: LocalizedStringResource("When"),
        default: date,
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(dateDescBoth.hasOptionsProvider == true)
    let dateKindBoth = IntentParameter<Date>(
        title: LocalizedStringResource("When"),
        kind: .date,
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<Date>()
    )
    precondition(dateKindBoth.hasOptionsProvider == true)
    precondition(dateDesc.makeContext().dateKind == .date)

    let url = URL(string: "https://example.invalid")!
    let urlDesc = IntentParameter<URL>(
        description: LocalizedStringResource("Link"),
        default: url
    )
    precondition(urlDesc.wrappedValue.host == "example.invalid")
    let urlDescProvider = IntentParameter<URL>(
        description: LocalizedStringResource("Link"),
        optionsProvider: Wave13Query()
    )
    precondition(urlDescProvider.hasOptionsProvider == true)
    let urlProvider = IntentParameter<URL>(
        title: LocalizedStringResource("Link"),
        optionsProvider: Wave13Query()
    )
    precondition(urlProvider.hasOptionsProvider == true)
    let urlDescResolvers = IntentParameter<URL>(
        description: LocalizedStringResource("Link"),
        default: url,
        resolvers: EmptyResolverSpecification<URL>()
    )
    precondition(urlDescResolvers.wrappedValue.host == "example.invalid")
    let urlDescBoth = IntentParameter<URL>(
        description: LocalizedStringResource("Link"),
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<URL>()
    )
    precondition(urlDescBoth.hasOptionsProvider == true)
    let urlBoth = IntentParameter<URL>(
        title: LocalizedStringResource("Link"),
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<URL>()
    )
    precondition(urlBoth.hasOptionsProvider == true)

    let attributed = AttributedString("hello")
    let attr = IntentParameter<AttributedString>(
        title: LocalizedStringResource("Text"),
        default: attributed
    )
    precondition(String(attr.wrappedValue.characters) == "hello")
    let attrDesc = IntentParameter<AttributedString>(
        description: LocalizedStringResource("Text"),
        default: attributed
    )
    precondition(String(attrDesc.wrappedValue.characters) == "hello")
    let attrDescProvider = IntentParameter<AttributedString>(
        description: LocalizedStringResource("Text"),
        optionsProvider: Wave13Query()
    )
    precondition(attrDescProvider.hasOptionsProvider == true)
    let attrProvider = IntentParameter<AttributedString>(
        title: LocalizedStringResource("Text"),
        optionsProvider: Wave13Query()
    )
    precondition(attrProvider.hasOptionsProvider == true)
    let attrDescResolvers = IntentParameter<AttributedString>(
        description: LocalizedStringResource("Text"),
        default: attributed,
        resolvers: EmptyResolverSpecification<AttributedString>()
    )
    precondition(String(attrDescResolvers.wrappedValue.characters) == "hello")
    let attrResolvers = IntentParameter<AttributedString>(
        title: LocalizedStringResource("Text"),
        default: attributed,
        resolvers: EmptyResolverSpecification<AttributedString>()
    )
    precondition(String(attrResolvers.wrappedValue.characters) == "hello")
    let attrDescBoth = IntentParameter<AttributedString>(
        description: LocalizedStringResource("Text"),
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<AttributedString>()
    )
    precondition(attrDescBoth.hasOptionsProvider == true)
    let attrBoth = IntentParameter<AttributedString>(
        title: LocalizedStringResource("Text"),
        optionsProvider: Wave13Query(),
        resolvers: EmptyResolverSpecification<AttributedString>()
    )
    precondition(attrBoth.hasOptionsProvider == true)

    let count = IntentParameter<Int>(
        description: LocalizedStringResource("N"),
        default: 4,
        controlStyle: .field,
        inclusiveRange: (1, 9)
    )
    precondition(count.controlStyle == .field)
    precondition(count.inclusiveRange?.lowerBound == 1)
    precondition(count.wrappedValue == 4)
    let countResolvers = IntentParameter<Int>(
        description: LocalizedStringResource("N"),
        default: 5,
        controlStyle: .stepper,
        resolvers: EmptyResolverSpecification<Int>()
    )
    precondition(countResolvers.controlStyle == .stepper)
    let countTitleResolvers = IntentParameter<Int>(
        title: LocalizedStringResource("N"),
        default: 6,
        controlStyle: .field,
        inclusiveRange: (0, 10),
        resolvers: EmptyResolverSpecification<Int>()
    )
    precondition(countTitleResolvers.wrappedValue == 6)
    let intContext = count.makeContext()
    precondition(intContext.controlStyle == .field)
    precondition(intContext.inclusiveRange?.upperBound == 9)

    let amount = IntentParameter<Double>(
        description: LocalizedStringResource("N"),
        default: 1.5,
        controlStyle: .slider,
        inclusiveRange: (0, 10)
    )
    precondition(amount.controlStyle == .slider)
    precondition(amount.inclusiveRange?.upperBound == 10)
    let amountResolvers = IntentParameter<Double>(
        description: LocalizedStringResource("N"),
        default: 2,
        controlStyle: .field,
        resolvers: EmptyResolverSpecification<Double>()
    )
    precondition(amountResolvers.controlStyle == .field)
    let amountTitleResolvers = IntentParameter<Double>(
        title: LocalizedStringResource("N"),
        default: 3,
        controlStyle: .stepper,
        resolvers: EmptyResolverSpecification<Double>()
    )
    precondition(amountTitleResolvers.wrappedValue == 3)
    let doubleContext = amount.makeContext()
    precondition(doubleContext.controlStyle == .slider)

    let money = IntentParameter<IntentCurrencyAmount>(
        title: LocalizedStringResource("Pay"),
        default: IntentCurrencyAmount(amount: 5, currencyCode: "USD"),
        currencyCodes: ["USD"],
        inclusiveRange: (Decimal(1), Decimal(9))
    )
    precondition(money.makeContext().inclusiveRange?.lowerBound == Decimal(1))
}
