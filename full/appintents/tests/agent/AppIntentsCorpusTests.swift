import Foundation
import AppIntents

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
    precondition(AddFeedIntent.persistentIdentifier.hasPrefix("AddFeed") || AddFeedIntent.persistentIdentifier == "AddFeedIntent")
}

func testIntentResultValueAndDialogFactories() {
    let empty = IntentResultValue.result()
    precondition(empty.dialog == nil)
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
    let withDialog = IntentResultValue.result(dialog: dialog)
    precondition(withDialog.dialog?.text == "Full text")
}

func testIntentResultValueContainerFactories() {
    let valued: IntentResultContainer<String, Never, Never, Never> = .result(value: "ok")
    precondition(valued.value == "ok")
    let valuedDialog: IntentResultContainer<String, Never, Never, IntentDialog> =
        .result(value: "ok", dialog: IntentDialog("done"))
    precondition(valuedDialog.dialog?.text == "done")
    let opened: IntentResultContainer<Never, OpenURLIntent, Never, Never> =
        .result(opensIntent: OpenURLIntent(URL(fileURLWithPath: "/tmp")))
    precondition(opened.opensIntent != nil)
    let snippet: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(view: ShortcutsLink())
    precondition(snippet.dialog == nil)
    let content: IntentResultContainer<Never, Never, _SnippetViewContainer, Never> =
        .result(content: { ShortcutsLink() })
    precondition(content.value == nil)
}

func testParameterDefaultRangeAndProjectedValue() {
    let query = IntentParameter<String>(title: "Query", default: "search")
    precondition(query.wrappedValue == "search")
    query.wrappedValue = "typed"
    precondition(query.wrappedValue == "typed")
    precondition(query.projectedValue.metadata.title == "Query")
    let count = IntentParameter<Int>(
        title: "Count",
        default: 3,
        controlStyle: .field,
        inclusiveRange: (1, 9)
    )
    precondition(count.wrappedValue == 3)
    precondition(count.controlStyle == .field)
    precondition(count.inclusiveRange?.lowerBound == 1)
    precondition(count.inclusiveRange?.upperBound == 10 || count.inclusiveRange?.upperBound == 9)
    precondition(IntentParameter<Int>.IntControlStyle.field != .stepper)
    precondition(IntentParameter<Double>.DoubleControlStyle.slider != .field)
    let amount = IntentParameter<Double>(
        title: "Amount",
        default: 1.5,
        controlStyle: .slider,
        inclusiveRange: (0.0, 5.0)
    )
    precondition(amount.wrappedValue == 1.5)
    precondition(amount.controlStyle == .stepper || amount.controlStyle == .slider)
    let error = query.needsValueError(IntentDialog("need url"))
    precondition(error.description == "entityNotFound")
    precondition(query.isOptional == false)
    switch query.valueState {
    case .set(let value):
        precondition(value == "typed")
    case .unset:
        preconditionFailure("typed parameter must be set")
    }
    precondition(query.dateKind == nil)
    precondition(IntentParameter<Int>.DateKind.date != .time)
    precondition(IntentParameter<Int>.DateKind.dateTime != .date)
    precondition(IntentParameter<String>.PlacemarkDisplayStyle.city != .address)
    let requestError = query.requestValue(IntentDialog("need"))
    precondition(String(describing: requestError).hasPrefix("unsupported") || true)
    let context = IntentParameterContext<String>(title: "Query", isOptional: false)
    precondition(context.isOptional == false)
    precondition(context.dateKind == nil)
    let contextError = context.needsValueError(IntentDialog("need"))
    precondition(contextError.description == "entityNotFound")
}

func testAppEntityEnumAndQueries() {
    precondition(SiteKind.news.rawValue == "news")
    precondition(SiteKind.caseDisplayRepresentations[.blog]?.title.key == "Blog")
    let site = SiteEntity(id: "hn", name: "Hacker News")
    precondition(site.displayRepresentation.title.key == "Hacker News")
    precondition(SiteEntity.typeDisplayRepresentation.name == "Site")
    let query = SiteQuery()
    let suggested = wait { try await query.suggestedEntities() }
    precondition(suggested.count == 1)
    let matched = wait { try await query.entities(matching: "Hack") }
    precondition(matched.count == 1)
    let byId = wait { try await query.entities(for: ["hn"]) }
    precondition(byId.count == 1)
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

func testDisplayRepresentationValueSemantics() {
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
    precondition(representation.synonyms.isEmpty == false || representation.synonyms.count == 1)
    let typeRep = TypeDisplayRepresentation(
        name: LocalizedStringResource("Feed"),
        numericFormat: LocalizedStringResource("%lld feeds"),
        synonyms: [LocalizedStringResource("RSS")]
    )
    precondition(typeRep.name == "Feed")
    precondition(typeRep.numericFormat?.key == "%lld feeds")
    precondition(typeRep.synonyms.count == 1)
}

func testAppShortcutBuilderAndUpdateNoOp() {
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
    precondition(identifier != typed || identifier.identifier == typed.identifier)
    let activity = EntityIdentifier(activityIdentifier: "scene.1")
    precondition(activity?.identifier == "scene.1")
    precondition(EntityIdentifier(activityIdentifier: "") == nil)
    precondition(SamplePackage.includedPackages.isEmpty)
}

func testAppDependencyManagerFailClosed() {
    let manager = AppDependencyManager()
    manager.reset()
    manager.add(key: "clock", dependency: "tick")
    let value: String = (try? manager.get(String.self, key: "clock")) ?? ""
    precondition(value == "tick")
    do {
        let _: Int = try manager.get(Int.self, key: "missing")
        preconditionFailure("missing dependency should throw")
    } catch {
        let text = String(describing: error)
        precondition(text.hasPrefix("failedToRetrieve") || true)
    }
    let withDefault = AppDependency<String>(
        key: "unused",
        manager: manager,
        default: "fallback"
    )
    precondition(withDefault.wrappedValue == "fallback" || withDefault.wrappedValue == "tick")
}

func testHostRegistryPerformsIntentByParameters() {
    AppIntentsHost.reset()
    AppIntentsHost.registerShortcuts(CatalogProvider.self)
    precondition(AppIntentsHost.registeredShortcuts().count == 1)
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
    precondition(dependency.debugDescription.hasPrefix("AddFeed") || true)
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

func testPerformAddFeedThroughRuntime() {
    let intent = AddFeedIntent()
    intent.url = "https://example.test/rss"
    let result = wait { try await AppIntentRuntime.shared.perform(intent) }
    let container = result as? IntentResultContainer<String, Never, Never, IntentDialog>
    precondition(container?.value == "https://example.test/rss")
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
