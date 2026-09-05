import Foundation
import AppIntents

/// Focused Linux in-process checks. Each `test*` is cited only for identifiers
/// it actually calls or asserts — not for a whole type's unused members.

private final class WaitBox<T>: @unchecked Sendable {
    var value: T?
    var error: Error?
}

private func wait<T>(_ work: @escaping @Sendable () async throws -> T) -> T {
    let box = WaitBox<T>()
    let sem = DispatchSemaphore(value: 0)
    Task {
        do {
            box.value = try await work()
        } catch {
            box.error = error
        }
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + 5) == .success)
    if let error = box.error {
        preconditionFailure(String(describing: error))
    }
    return box.value!
}

private enum SiteKind: String, AppEnum {
    case news
    case blog

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Site Kind" }
    static var caseDisplayRepresentations: [SiteKind: DisplayRepresentation] {
        [.news: "News", .blog: "Blog"]
    }
}

private struct SiteEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Site" }
    static var defaultQuery = SiteQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: name, subtitle: id)
    }
}

private struct SiteQuery: EntityStringQuery, EntityPropertyQuery {
    typealias Entity = SiteEntity
    typealias Result = [SiteEntity]
    typealias ComparatorMappingType = String
    init() {}
    func entities(for identifiers: [String]) async throws -> [SiteEntity] {
        try await suggestedEntities().filter { entity in
            identifiers.contains { $0 == entity.id }
        }
    }
    func suggestedEntities() async throws -> [SiteEntity] {
        [SiteEntity(id: "hn", name: "Hacker News")]
    }
    func entities(matching string: String) async throws -> [SiteEntity] {
        try await suggestedEntities().filter { entity in
            entity.name.hasPrefix(string) || entity.id.hasPrefix(string)
        }
    }
}

private struct UniqueFeed: UniqueAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Feed" }
    static var defaultQuery = UniqueAppEntityProvider<UniqueFeed> {
        UniqueFeed(id: "unique", name: "Only")
    }
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: name) }
}

private struct AddFeedIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Feed" }
    static var description: IntentDescription? {
        IntentDescription(
            LocalizedStringResource("Adds a feed"),
            categoryName: "Feeds",
            searchKeywords: ["rss"],
            resultValueName: "Feed"
        )
    }
    static var openAppWhenRun: Bool { false }
    static var isDiscoverable: Bool { true }

    @Parameter(title: "URL")
    var url: String

    @Parameter(
        title: "Count",
        default: 1,
        controlStyle: .stepper,
        inclusiveRange: (1, 10)
    )
    var count: Int

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: url, dialog: IntentDialog("added=\(url)"))
    }
}

private struct ValueOnlyIntent: AppIntent {
    static var title: LocalizedStringResource { "Value Only" }
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: "payload")
    }
}

private struct OpensURLIntent: AppIntent {
    static var title: LocalizedStringResource { "Opens URL" }
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(fileURLWithPath: "/tmp/opened")))
    }
}

private struct CatalogProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddFeedIntent(),
            phrases: ["Add feed with \(.applicationName)"],
            shortTitle: "Add Feed",
            systemImageName: "plus"
        )
    }
}

private struct SamplePackage: AppIntentsPackage {}

func testAppIntentStaticRequirements() {
    precondition(AddFeedIntent.title.key == "Add Feed")
    precondition(AddFeedIntent.description?.text == "Adds a feed")
    precondition(AddFeedIntent.description?.categoryName?.key == "Feeds")
    precondition(AddFeedIntent.description?.searchKeywords.count == 1)
    precondition(AddFeedIntent.description?.resultValueName?.key == "Feed")
    precondition(AddFeedIntent.openAppWhenRun == false)
    precondition(AddFeedIntent.isDiscoverable == true)
    precondition(AddFeedIntent.supportedModes.contains(.background))
    precondition(AddFeedIntent.authenticationPolicy == .alwaysAllowed)
    let identifier = AddFeedIntent.persistentIdentifier
    precondition(identifier.hasPrefix("AddFeed") || identifier == "AddFeedIntent")
}

func testIntentPerformValueShape() {
    let valued: IntentResultContainer<String, Never, Never, Never> = .result(value: "ok")
    precondition(valued.value == "ok")
    let performed = wait { try await ValueOnlyIntent().perform() }
    let container = performed as? IntentResultContainer<String, Never, Never, Never>
    precondition(container?.value == "payload")
}

func testIntentPerformValueDialogShape() {
    let valuedDialog: IntentResultContainer<String, Never, Never, IntentDialog> =
        .result(value: "ok", dialog: IntentDialog("done"))
    precondition(valuedDialog.value == "ok")
    precondition(valuedDialog.dialog?.text == "done")
    let intent = AddFeedIntent()
    intent.url = "https://example.test/rss"
    let performed = wait { try await AppIntentRuntime.shared.perform(intent) }
    let container = performed as? IntentResultContainer<String, Never, Never, IntentDialog>
    precondition(container?.value == "https://example.test/rss")
    precondition(container?.dialog?.text == "added=https://example.test/rss")
}

func testIntentPerformOpensIntentShape() {
    let url = URL(fileURLWithPath: "/tmp/opened")
    let opened: IntentResultContainer<Never, OpenURLIntent, Never, Never> =
        .result(opensIntent: OpenURLIntent(url))
    precondition(opened.opensIntent != nil)
    let performed = wait { try await OpensURLIntent().perform() }
    let container = performed as? IntentResultContainer<Never, OpenURLIntent, Never, Never>
    precondition(container?.opensIntent != nil)
}

func testIntentPerformViewShape() {
    let snippet: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(view: ShortcutsLink())
    precondition(snippet.dialog == nil)
    precondition(snippet.value == nil)
    let content: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(content: { ShortcutsLink() })
    precondition(content.value == nil)
}

func testIntentDialogInterpolationAndFullSupporting() {
    let dialog = IntentDialog(full: "Full text", supporting: "Support")
    precondition(dialog.full == "Full text")
    precondition(dialog.supporting == "Support")
    precondition(dialog.text == "Full text")
    let withImage = IntentDialog(
        full: "Shown",
        supporting: "More",
        systemImageName: "star"
    )
    precondition(withImage.systemImageName == "star")
    let fromResource = IntentDialog(LocalizedStringResource("resource"))
    precondition(fromResource.text == "resource")
    let interpolated: IntentDialog = "added=\("feed")"
    precondition(interpolated.text == "added=feed")
}

func testParameterStorageDefaultsAndProjection() {
    let query = IntentParameter<String>(title: "Query", default: "search")
    precondition(query.wrappedValue == "search")
    query.wrappedValue = "typed"
    precondition(query.wrappedValue == "typed")
    precondition(query.projectedValue.metadata.title == "Query")
    precondition(query.isOptional == false)
    switch query.valueState {
    case .set(let value):
        precondition(value == "typed")
    case .unset:
        preconditionFailure("typed parameter must be set")
    }
    let optionalParam = IntentParameter<String?>(title: "Maybe")
    precondition(optionalParam.isOptional == true)
    precondition(optionalParam.wrappedValue == nil)
}

func testParameterControlStyleAndInclusiveRange() {
    // Measured: Int inclusiveRange (1, 9) round-trips as lower=1 upper=9
    // (testParameterControlStyleAndInclusiveRange, Linux swiftc).
    let count = IntentParameter<Int>(
        title: "Count",
        default: 3,
        controlStyle: .field,
        inclusiveRange: (1, 9)
    )
    precondition(count.wrappedValue == 3)
    precondition(count.controlStyle == .field)
    precondition(count.inclusiveRange?.lowerBound == 1)
    precondition(count.inclusiveRange?.upperBound == 9)
    precondition(IntentParameter<Int>.IntControlStyle.field != .stepper)
    precondition(IntentParameter<Double>.DoubleControlStyle.slider != .field)
    precondition(IntentParameter<Double>.DoubleControlStyle.stepper != .slider)
    let amount = IntentParameter<Double>(
        title: "Amount",
        default: 1.5,
        controlStyle: .slider,
        inclusiveRange: (0.0, 5.0)
    )
    precondition(amount.wrappedValue == 1.5)
    precondition(amount.controlStyle == .slider)
    precondition(amount.inclusiveRange?.lowerBound == 0.0)
    precondition(amount.inclusiveRange?.upperBound == 5.0)
    precondition(IntentParameter<Int>.DateKind.date != .time)
    precondition(IntentParameter<Int>.DateKind.dateTime != .date)
    precondition(IntentParameter<String>.PlacemarkDisplayStyle.city != .address)
}

func testParameterRequestValueDialogAndOptionsProvider() {
    let dialog = IntentDialog("need site")
    let parameter = IntentParameter<String>(
        title: "Site",
        default: "hn",
        requestValueDialog: dialog,
        optionsProvider: SiteQuery()
    )
    precondition(parameter.wrappedValue == "hn")
    precondition(parameter.metadata.requestValueDialog?.text == "need site")
    let results = wait { try await SiteQuery().results() }
    precondition(results.count == 1)
    precondition(results[0].id == "hn")
    let need = parameter.needsValueError(IntentDialog("need url"))
    precondition(need.description == "entityNotFound")
    let request = parameter.requestValue(IntentDialog("need"))
    precondition((request as? AppIntentError)?.description == "unsupportedOnDevice")
    let context = IntentParameterContext<String>(title: "Query", isOptional: false)
    precondition(context.isOptional == false)
    precondition(context.needsValueError(IntentDialog("need")).description == "entityNotFound")
}

func testAppEnumCaseDisplayRepresentations() {
    precondition(SiteKind.news.rawValue == "news")
    precondition(SiteKind.caseDisplayRepresentations[.blog]?.title.key == "Blog")
    precondition(SiteKind.typeDisplayRepresentation.name == "Site Kind")
}

func testAppEntityQuerySuggestedMatchingAndIdentifiers() {
    precondition(SiteEntity.typeDisplayRepresentation.name == "Site")
    let site = SiteEntity(id: "hn", name: "Hacker News")
    precondition(site.displayRepresentation.title.key == "Hacker News")
    let query = SiteQuery()
    let suggested = wait { try await query.suggestedEntities() }
    precondition(suggested.count == 1)
    precondition(suggested[0].id == "hn")
    let matched = wait { try await query.entities(matching: "Hack") }
    precondition(matched.count == 1)
    let missed = wait { try await query.entities(matching: "zzz") }
    precondition(missed.isEmpty)
    let byId = wait { try await query.entities(for: ["hn"]) }
    precondition(byId.count == 1)
    let missingId = wait { try await query.entities(for: ["nope"]) }
    precondition(missingId.isEmpty)
}

func testEntityPropertyQueryAndUniqueEntity() {
    let query = SiteQuery()
    let comparators: [String] = ["hn"]
    let fromProperty = wait {
        try await query.entities(
            matching: comparators,
            mode: .and,
            sortedBy: [],
            limit: 1
        )
    }
    precondition(fromProperty.count == 1)
    precondition(EntityQueryComparatorMode.and != .or)
    let unique = wait { try await UniqueFeed.defaultQuery.uniqueEntity() }
    precondition(unique.id == "unique")
    let allUnique = wait { try await UniqueFeed.defaultQuery.allEntities() }
    precondition(allUnique.count == 1)
}

func testDisplayRepresentationImagesAndSynonyms() {
    let image = DisplayRepresentation.Image(systemName: "star", isTemplate: true)
    precondition(image.systemName == "star")
    precondition(image.isTemplate == true)
    let named = DisplayRepresentation.Image(named: "feed", isTemplate: false)
    precondition(named.systemName == "feed")
    let dataImage = DisplayRepresentation.Image(data: Data([1]), isTemplate: true)
    precondition(dataImage.data == Data([1]))
    let url = URL(fileURLWithPath: "/tmp/icon.png")
    let urlImage = DisplayRepresentation.Image(url: url, width: 16, height: 16)
    precondition(urlImage.url == url)
    precondition(DisplayRepresentation.Image.DisplayStyle.circular != .default)
    let representation = DisplayRepresentation(
        title: LocalizedStringResource("Site"),
        subtitle: LocalizedStringResource("News"),
        image: image,
        synonyms: [LocalizedStringResource("feed")]
    )
    precondition(representation.title.key == "Site")
    precondition(representation.subtitle?.key == "News")
    precondition(representation.synonyms.count == 1)
}

func testTypeDisplayRepresentationNameFormatAndSynonyms() {
    let typeRep = TypeDisplayRepresentation(
        name: LocalizedStringResource("Feed"),
        numericFormat: LocalizedStringResource("%lld feeds"),
        synonyms: [LocalizedStringResource("RSS")]
    )
    precondition(typeRep.name == "Feed")
    precondition(typeRep.numericFormat?.key == "%lld feeds")
    precondition(typeRep.synonyms.count == 1)
}

func testAppShortcutBuilderUpdateAndApplicationNameToken() {
    // Measured: "Add feed with \(.applicationName)" → "Add feed with ${applicationName}"
    // (testAppShortcutBuilderUpdateAndApplicationNameToken, Linux swiftc).
    precondition(CatalogProvider.appShortcuts.count == 1)
    precondition(CatalogProvider.appShortcuts[0].shortTitle == "Add Feed")
    precondition(CatalogProvider.appShortcuts[0].systemImageName == "plus")
    precondition(
        CatalogProvider.appShortcuts[0].phrases[0].template ==
            "Add feed with ${applicationName}"
    )
    CatalogProvider.updateAppShortcutParameters()
    let empty = AppShortcutsBuilder.buildBlock()
    precondition(empty.isEmpty)
    let built = AppShortcutsBuilder.buildBlock(CatalogProvider.appShortcuts[0])
    precondition(built.count == 1)
    let expressed = AppShortcutsBuilder.buildExpression(CatalogProvider.appShortcuts[0])
    precondition(expressed.systemImageName == "plus")
    let limited = AppShortcutsBuilder.buildLimitedAvailability([expressed])
    precondition(limited.count == 1)
    precondition(CatalogProvider.shortcutTileColor == .navy)
    _ = CatalogProvider.negativePhrases
}

func testIntentFilePersonAndItemCollection() {
    let data = Data([1, 2, 3])
    let file = IntentFile(data: data, filename: "a.bin", type: .data)
    precondition(file.data == data)
    precondition(file.filename == "a.bin")
    precondition(file.type == .data)
    precondition(file.displayRepresentation.title.key == "a.bin")
    precondition(IntentFile.typeDisplayRepresentation.name == "File")
    precondition(IntentFile.IntentFileError.failedToLoadFile != .failedToLoadData)
    precondition(IntentFile.IntentFileError.errorDomain == "AppIntents.IntentFileError")
    let handle = IntentPerson.Handle(emailAddress: "a@b.test", label: .work)
    let person = IntentPerson(
        identifier: .applicationDefined("p1"),
        name: .displayName("Ada"),
        handle: handle,
        aliases: [],
        isMe: false
    )
    precondition(person.identifier == .applicationDefined("p1"))
    precondition(person.handle?.label == .work)
    precondition(person.displayRepresentation.title.key == "Ada")
    let items = IntentItemCollection(items: ["one", "two"])
    precondition(items.items.count == 2)
    precondition(IntentItemCollection<String>.empty.items.isEmpty)
    let section = IntentItemSection("Sites", items: ["hn"])
    precondition(section.items.count == 1)
}

func testEntityIdentifierAndPackage() {
    let site = SiteEntity(id: "hn", name: "Hacker News")
    let identifier = EntityIdentifier(for: site)
    precondition(identifier.identifier == "hn")
    let typed = EntityIdentifier(for: SiteEntity.self, identifier: "hn")
    precondition(typed.identifier == "hn")
    let activity = EntityIdentifier(activityIdentifier: "scene.1")
    precondition(activity?.identifier == "scene.1")
    precondition(EntityIdentifier(activityIdentifier: "") == nil)
    precondition(SamplePackage.includedPackages.isEmpty)
}

func testAppDependencyManagerRegisterGetFailClosed() {
    // Measured: missing get() throws failedToRetrieveDependency (Linux);
    // Apple crash-on-missing is unobserved (oracle-questions.tsv).
    let manager = AppDependencyManager()
    manager.reset()
    manager.add(key: "clock", dependency: "tick")
    do {
        let value: String = try manager.get(String.self, key: "clock")
        precondition(value == "tick")
    } catch {
        preconditionFailure("registered dependency must return: \(error)")
    }
    do {
        let _: Int = try manager.get(Int.self, key: "missing")
        preconditionFailure("missing dependency should throw")
    } catch let error as AppDependencyManager.Error<Int> {
        switch error {
        case .failedToRetrieveDependency:
            break
        default:
            preconditionFailure("expected failedToRetrieveDependency, got \(error)")
        }
    } catch {
        preconditionFailure("expected AppDependencyManager.Error, got \(error)")
    }
    let withDefault = AppDependency<String>(
        key: "unused",
        manager: manager,
        default: "fallback"
    )
    precondition(withDefault.wrappedValue == "fallback")
}

func testHostRegistryEnumeratesShortcutsAndPerformsFromParameters() {
    AppIntentsHost.reset()
    AppIntentsHost.registerShortcuts(CatalogProvider.self)
    precondition(AppIntentsHost.registeredShortcuts().count == 1)
    precondition(
        AppIntentsHost.registeredShortcuts()[0].phrases[0].template ==
            "Add feed with ${applicationName}"
    )
    AppIntentsHost.registerIntent(AddFeedIntent.self) { parameters in
        let intent = AddFeedIntent()
        AppIntentsHost.applyParameters(intent, parameters: parameters)
        return intent
    }
    let result = wait {
        try await AppIntentsHost.perform(
            identifier: AddFeedIntent.persistentIdentifier,
            parameters: ["url": "https://example.test/feed"]
        )
    }
    let container = result as? IntentResultContainer<String, Never, Never, IntentDialog>
    precondition(container?.value == "https://example.test/feed")
}

func testIntentParameterDependencyAndProjection() {
    let intent = OpenURLIntent(URL(fileURLWithPath: "/tmp/open"))
    let projection = IntentProjection(intent)
    precondition(projection.intent.url.path.hasPrefix("/tmp"))
    let dependency = IntentParameterDependency<AddFeedIntent>(\AddFeedIntent.$url)
    precondition(dependency.wrappedValue == nil)
    precondition(dependency.debugDescription.hasPrefix("AddFeed"))
}

func testAppIntentErrorCatalog() {
    precondition(AppIntentError.Unrecoverable.unknown.description == "unknown")
    precondition(AppIntentError.Unrecoverable.notAllowed.description == "notAllowed")
    precondition(AppIntentError.Unrecoverable.entityNotFound.description == "entityNotFound")
    precondition(AppIntentError.Unrecoverable.networkFailure.description == "networkFailure")
    precondition(AppIntentError.Unrecoverable.partialFailure.description == "partialFailure")
    precondition(AppIntentError.Unrecoverable.featureCurrentlyRestricted.description == "featureCurrentlyRestricted")
    precondition(AppIntentError.restartPerform.description == "restartPerform")
    precondition(AppIntentError.PermissionRequired.photos.description == "photos")
    precondition(AppIntentError.PermissionRequired.contacts.description == "contacts")
    precondition(AppIntentError.PermissionRequired.bluetooth.description == "bluetooth")
    precondition(AppIntentError.PermissionRequired.localNetwork.description == "localNetwork")
    precondition(AppIntentError.UserActionRequired.signin.description == "signin")
    precondition(AppIntentError.UserActionRequired.accountSetup.description == "accountSetup")
}

func testConfirmationAndForegroundStayFailClosed() {
    let intent = OpenURLIntent(URL(fileURLWithPath: "/"))
    let box = WaitBox<Void>()
    let sem = DispatchSemaphore(value: 0)
    Task {
        do {
            try await intent.requestConfirmation()
            box.value = ()
        } catch {
            box.error = error
        }
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + 5) == .success)
    precondition((box.error as? AppIntentError)?.description == "unsupportedOnDevice")
    let continueError = intent.needsToContinueInForegroundError(IntentDialog("go"), alwaysConfirm: true)
    precondition(continueError.description == "unsupportedOnDevice")
}

func testWidgetConfigurationIntentDefaultPerform() {
    struct Config: WidgetConfigurationIntent {
        typealias PerformResult = IntentResultValue
        static var title: LocalizedStringResource { "Config" }
    }
    let result = wait { try await Config().perform() }
    precondition(result.dialog == nil)
}

func testIntentModesAuthenticationAndTileColors() {
    precondition(IntentModes.background.contains(.background))
    precondition(IntentModes.foreground(.immediate) == .foreground)
    precondition(IntentAuthenticationPolicy.alwaysAllowed != .requiresAuthentication)
    precondition(ShortcutTileColor.navy != .tangerine)
    precondition(InputConnectionBehavior.connectToPreviousIntentResult != .never)
    precondition(ConfirmationActionName.ok.rawValue == "ok")
    precondition(VideoCategory.movies != .tv)
    precondition(StringSearchScope.general != .movies)
    precondition(IntentWidgetFamily.systemSmall != .systemLarge)
}
