@_spi(OpenUIKitHost) import WidgetKit
import Foundation

private struct _EngineEntry: TimelineEntry, Sendable {
    var date: Date
    var stamp: Int
}

private struct _StaticProvider: TimelineProvider, Sendable {
    func placeholder(in _: Context) -> _EngineEntry {
        _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 1), stamp: 0)
    }

    func getSnapshot(
        in _: Context,
        completion: @escaping @Sendable (_EngineEntry) -> Void
    ) {
        completion(_EngineEntry(date: Date(timeIntervalSinceReferenceDate: 2), stamp: 1))
    }

    func getTimeline(
        in _: Context,
        completion: @escaping @Sendable (Timeline<_EngineEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [
                    _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 10), stamp: 10),
                    _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 20), stamp: 20),
                    _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 30), stamp: 30),
                ],
                policy: .after(Date(timeIntervalSinceReferenceDate: 40))
            )
        )
    }
}

private final class _LegacyIntent: INIntent, @unchecked Sendable {}

private struct _LegacyProvider: IntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> _EngineEntry {
        _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 1), stamp: 0)
    }

    func getSnapshot(
        for _: _LegacyIntent,
        in _: Context,
        completion: @escaping (_EngineEntry) -> Void
    ) {
        completion(_EngineEntry(date: Date(timeIntervalSinceReferenceDate: 2), stamp: 1))
    }

    func getTimeline(
        for _: _LegacyIntent,
        in _: Context,
        completion: @escaping (Timeline<_EngineEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [
                    _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 50), stamp: 50)
                ],
                policy: .atEnd
            )
        )
    }
}

private struct _AppIntent: WidgetConfigurationIntent {}

private struct _AppProvider: AppIntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> _EngineEntry {
        _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 1), stamp: 0)
    }

    func snapshot(for _: _AppIntent, in _: Context) async -> _EngineEntry {
        _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 2), stamp: 1)
    }

    func timeline(for _: _AppIntent, in _: Context) async -> Timeline<_EngineEntry> {
        Timeline(
            entries: [
                _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 100), stamp: 100),
                _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 200), stamp: 200),
            ],
            policy: .never
        )
    }
}

private struct _NeverProvider: TimelineProvider, Sendable {
    func placeholder(in _: Context) -> _EngineEntry {
        _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 1), stamp: 0)
    }

    func getSnapshot(
        in _: Context,
        completion: @escaping @Sendable (_EngineEntry) -> Void
    ) {
        completion(placeholder(in: TimelineProviderContext(
            family: .systemSmall,
            displaySize: CGSize(width: 1, height: 1)
        )))
    }

    func getTimeline(
        in _: Context,
        completion: @escaping @Sendable (Timeline<_EngineEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [
                    _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 5), stamp: 5)
                ],
                policy: .never
            )
        )
    }
}

private struct _PushHandler: WidgetPushHandler {
    init() {}
    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        _ = pushInfo
        _ = widgets
    }
}

private final class _Box<T>: @unchecked Sendable {
    var value: T?
    var failed = false
}

/// Runs an async API from the sealed gate's deliberately synchronous test
/// entry points. The deadline makes a lost task an immediate test failure
/// rather than an indefinitely blocked host process.
private func _awaitCompletion(
    timeout: TimeInterval = 2,
    _ operation: @escaping @Sendable () async -> Void
) {
    let completion = _Box<Bool>()
    Task.detached {
        await operation()
        completion.value = true
    }
    let deadline = Date().addingTimeInterval(timeout)
    while completion.value == nil, Date() < deadline {
        Thread.sleep(forTimeInterval: 0.001)
    }
    precondition(completion.value == true, "async WidgetKit operation timed out")
}

func testWidgetFamilyCanvasSizes() {
    // Cited: Apple Human Interface Guidelines, Widgets
    // https://developer.apple.com/design/human-interface-guidelines/widgets
    // Home Screen logical-point table used here (iPhoneOS 26.1):
    //   SE 375-pt class: small 155×155, medium 329×155, large 329×345
    //   393-pt iPhone:   small 158×158, medium 338×158, large 338×354
    //   430-pt iPhone:   small 170×170, medium 364×170, large 364×382
    // Extra-large (iPad) and Lock Screen accessory families are not in that
    // phone table; portableCanvasSize returns nil and the host must pass
    // TimelineProviderContext.displaySize (oracle-questions.tsv).
    precondition(WidgetFamily.portableHomeScreenFamilies.map(\.rawValue) == [0, 1, 2, 3, 5, 6, 7])
    precondition(WidgetFamily.accessoryCorner.rawValue == 8)
    precondition(WidgetFamily.accessoryCorner.description == "accessoryCorner")

    precondition(WidgetFamily.systemSmall.portableCanvasSize(for: .iPhoneSE375) == CGSize(width: 155, height: 155))
    precondition(WidgetFamily.systemMedium.portableCanvasSize(for: .iPhoneSE375) == CGSize(width: 329, height: 155))
    precondition(WidgetFamily.systemLarge.portableCanvasSize(for: .iPhoneSE375) == CGSize(width: 329, height: 345))
    precondition(WidgetFamily.systemSmall.portableCanvasSize(for: .iPhone393) == CGSize(width: 158, height: 158))
    precondition(WidgetFamily.systemMedium.portableCanvasSize(for: .iPhone393) == CGSize(width: 338, height: 158))
    precondition(WidgetFamily.systemLarge.portableCanvasSize(for: .iPhone393) == CGSize(width: 338, height: 354))
    precondition(WidgetFamily.systemSmall.portableCanvasSize(for: .iPhone430) == CGSize(width: 170, height: 170))
    precondition(WidgetFamily.systemMedium.portableCanvasSize(for: .iPhone430) == CGSize(width: 364, height: 170))
    precondition(WidgetFamily.systemLarge.portableCanvasSize(for: .iPhone430) == CGSize(width: 364, height: 382))
    precondition(WidgetFamily.systemExtraLarge.portableCanvasSize(for: .iPhone393) == nil)
    precondition(WidgetFamily.accessoryCircular.portableCanvasSize(for: .iPhone393) == nil)
    precondition(WidgetFamily.accessoryRectangular.portableCanvasSize(for: .iPhone393) == nil)
    precondition(WidgetFamily.accessoryInline.portableCanvasSize(for: .iPhone393) == nil)
    precondition(WidgetFamily.accessoryCorner.portableCanvasSize(for: .iPhone393) == nil)

    var hasher = Hasher()
    WidgetFamily.systemSmall.hash(into: &hasher)
    _ = hasher.finalize()
}

func testTimelineProviderCallbacks() {
    let provider = _StaticProvider()
    let context = TimelineProviderContext(
        family: .systemSmall,
        displaySize: CGSize(width: 158, height: 158)
    )
    let placeholder = provider.placeholder(in: context)
    precondition(placeholder.stamp == 0)

    let snapshot = _Box<_EngineEntry>()
    provider.getSnapshot(in: context) { entry in
        snapshot.value = entry
    }
    precondition(snapshot.value?.stamp == 1)

    let timeline = _Box<Timeline<_EngineEntry>>()
    provider.getTimeline(in: context) { value in
        timeline.value = value
    }
    precondition(timeline.value?.entries.map(\.stamp) == [10, 20, 30])
    precondition(timeline.value?.policy == .after(Date(timeIntervalSinceReferenceDate: 40)))

    precondition(WidgetTimelineHost.placeholder(provider, in: context).stamp == 0)
    precondition(WidgetTimelineHost.snapshot(provider, in: context).stamp == 1)
    do {
        let evaluation = try WidgetTimelineHost.timeline(provider, in: context)
        precondition(evaluation.nextReload == Date(timeIntervalSinceReferenceDate: 40))
        precondition(
            WidgetTimelineHost.entry(
                at: Date(timeIntervalSinceReferenceDate: 25),
                in: evaluation.timeline
            )?.stamp == 20
        )
    } catch {
        preconditionFailure("static provider timeline must validate")
    }
    _assertTimelineRuntimeFailClosed()
}

func testIntentTimelineProviderCallbacks() {
    let provider = _LegacyProvider()
    let intent = _LegacyIntent()
    let context = TimelineProviderContext(
        family: .systemMedium,
        displaySize: CGSize(width: 338, height: 158)
    )
    precondition(provider.placeholder(in: context).stamp == 0)
    precondition(provider.recommendations().isEmpty)

    let snapshot = _Box<_EngineEntry>()
    provider.getSnapshot(for: intent, in: context) { entry in
        snapshot.value = entry
    }
    precondition(snapshot.value?.stamp == 1)

    let timeline = _Box<Timeline<_EngineEntry>>()
    provider.getTimeline(for: intent, in: context) { value in
        timeline.value = value
    }
    precondition(timeline.value?.policy == .atEnd)
    precondition(timeline.value?.entries.first?.stamp == 50)

    let rec = IntentRecommendation(intent: intent, description: Text("legacy"))
    precondition(rec.description.content == "legacy")
    _ = IntentRecommendation(intent: intent, description: LocalizedStringKey("k"))
    _ = IntentRecommendation(intent: intent, description: LocalizedStringResource("r"))
    _ = IntentRecommendation(intent: intent, description: Text("t"))

    precondition(WidgetTimelineHost.placeholder(provider, in: context).stamp == 0)
    precondition(WidgetTimelineHost.snapshot(provider, configuration: intent, in: context).stamp == 1)
    do {
        let evaluation = try WidgetTimelineHost.timeline(
            provider,
            configuration: intent,
            in: context
        )
        precondition(evaluation.timeline.policy == .atEnd)
        precondition(evaluation.nextReload == Date(timeIntervalSinceReferenceDate: 50))
    } catch {
        preconditionFailure("legacy provider timeline must validate")
    }
}

func testAppIntentTimelineProviderAsync() {
    let provider = _AppProvider()
    let intent = _AppIntent()
    let context = TimelineProviderContext(
        family: .systemLarge,
        displaySize: CGSize(width: 338, height: 354)
    )
    precondition(provider.placeholder(in: context).stamp == 0)
    precondition(provider.recommendations().isEmpty)

    let rec = AppIntentRecommendation(intent: intent, description: Text("app"))
    precondition(rec.description.content == "app")
    _ = AppIntentRecommendation(intent: intent, description: LocalizedStringKey("k"))
    _ = AppIntentRecommendation(intent: intent, description: Text("t"))

    let timeline = Timeline(
        entries: [
            _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 100), stamp: 100),
            _EngineEntry(date: Date(timeIntervalSinceReferenceDate: 200), stamp: 200),
        ],
        policy: .never
    )
    do {
        let evaluation = try WidgetTimelineValidation.evaluate(timeline)
        precondition(evaluation.nextReload == nil)
        precondition(
            WidgetTimelineHost.entry(
                at: Date(timeIntervalSinceReferenceDate: 150),
                in: evaluation.timeline
            )?.stamp == 100
        )
    } catch {
        preconditionFailure("app-intent timeline must validate")
    }
}

func testAppIntentTimelineProviderAsyncRequirements() {
    let provider = _AppProvider()
    let context = TimelineProviderContext(
        family: .systemLarge,
        displaySize: CGSize(width: 338, height: 354)
    )
    _awaitCompletion {
        let snapshot = await provider.snapshot(for: _AppIntent(), in: context)
        precondition(snapshot.stamp == 1)
        let timeline = await provider.timeline(for: _AppIntent(), in: context)
        precondition(timeline.entries.map(\.stamp) == [100, 200])
        precondition(timeline.policy == .never)
        let relevance = await provider.relevance()
        precondition(relevance.portableAttributeCount == 0)
    }
}

func testTimelineProviderAsyncRelevance() {
    _awaitCompletion {
        let relevance = await _StaticProvider().relevance()
        precondition(relevance.portableAttributeCount == 0)
    }
}

func testIntentTimelineProviderAsyncRelevance() {
    _awaitCompletion {
        let relevance = await _LegacyProvider().relevance()
        precondition(relevance.portableAttributeCount == 0)
    }
}

func testWidgetCenterAsyncState() {
    let center = WidgetCenter.shared
    center.resetProcessLocalState()
    let expected = WidgetInfo(kind: "async-widget", family: .systemSmall)
    center.installCurrentConfigurations([expected])
    _awaitCompletion {
        let pushInfo = await center.currentPushInfo
        precondition(pushInfo == nil)
        do {
            let values = try await center.currentConfigurations()
            precondition(values == [expected])
        } catch {
            preconditionFailure("process-local configurations must not throw")
        }
    }
    center.resetProcessLocalState()
}

func testControlCenterAsyncState() {
    let center = ControlCenter.shared
    center.resetProcessLocalState()
    let expected = ControlInfo(kind: "async-control", pushInfo: nil)
    center.installCurrentControls([expected])
    _awaitCompletion {
        let controls = await center.currentControls()
        precondition(controls == [expected])
    }
    center.resetProcessLocalState()
}

func testTimelineEngineEntryAtTime() {
    let context = TimelineProviderContext(
        family: .systemSmall,
        displaySize: CGSize(width: 158, height: 158)
    )
    let staticEval: WidgetTimelineEvaluation<_EngineEntry>
    do {
        staticEval = try WidgetTimelineHost.timeline(_StaticProvider(), in: context)
    } catch {
        preconditionFailure("static timeline must validate")
    }
    precondition(
        WidgetTimelineHost.entry(
            at: Date(timeIntervalSinceReferenceDate: 0),
            in: staticEval.timeline
        )?.stamp == 10
    )
    precondition(
        WidgetTimelineHost.entry(
            at: Date(timeIntervalSinceReferenceDate: 25),
            in: staticEval.timeline
        )?.stamp == 20
    )
    precondition(
        WidgetTimelineHost.entry(
            at: Date(timeIntervalSinceReferenceDate: 100),
            in: staticEval.timeline
        )?.stamp == 30
    )
    precondition(staticEval.nextReload == Date(timeIntervalSinceReferenceDate: 40))

    do {
        let neverEval = try WidgetTimelineHost.timeline(_NeverProvider(), in: context)
        precondition(neverEval.nextReload == nil)
        precondition(
            WidgetTimelineHost.entry(
                at: Date(timeIntervalSinceReferenceDate: 5),
                in: neverEval.timeline
            )?.stamp == 5
        )
    } catch {
        preconditionFailure("never timeline must validate")
    }

    do {
        let legacyEval = try WidgetTimelineHost.timeline(
            _LegacyProvider(),
            configuration: _LegacyIntent(),
            in: context
        )
        precondition(legacyEval.nextReload == Date(timeIntervalSinceReferenceDate: 50))
    } catch {
        preconditionFailure("legacy timeline must validate")
    }

    precondition(WidgetTimelineHost.placeholder(_StaticProvider(), in: context).stamp == 0)
    precondition(WidgetTimelineHost.placeholder(_AppProvider(), in: context).stamp == 0)
}

func testWidgetCenterCurrentPushInfo() {
    // Cited: Apple WidgetCenter.currentPushInfo — nil until aps delivers a token.
    let center = WidgetCenter.shared
    center.resetProcessLocalState()
    precondition(center.portableCurrentPushInfo == nil)
    precondition(center.portableCurrentConfigurations().isEmpty)
    center.resetProcessLocalState()
}

func testEnvironmentValuesRemaining() {
    var values = EnvironmentValues()
    precondition(values.widgetContentMargins == EdgeInsets())
    values.widgetContentMargins = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
    precondition(values.widgetContentMargins.top == 1)
    precondition(values.widgetContentMargins.leading == 2)
    precondition(!values.showsWidgetLabel)
    values.showsWidgetLabel = true
    precondition(values.showsWidgetLabel)
    precondition(!values.isActivityUpdateReduced)
    values.isActivityUpdateReduced = true
    precondition(values.isActivityUpdateReduced)
    precondition(values.supportedActivityFamilies.isEmpty)
    values.supportedActivityFamilies = [.medium]
    precondition(values.supportedActivityFamilies == [.medium])
    precondition(values.showsWidgetContainerBackground)
    values.showsWidgetContainerBackground = false
    precondition(!values.showsWidgetContainerBackground)
    precondition(!values.isActivityFullscreen)
    values.isActivityFullscreen = true
    precondition(values.isActivityFullscreen)
}

func testTimelineEntryRelevanceCodable() {
    let first = TimelineEntryRelevance(score: 2.5, duration: 12)
    do {
        let data = try JSONEncoder().encode(first)
        let decoded = try JSONDecoder().decode(TimelineEntryRelevance.self, from: data)
        precondition(decoded == first)
        precondition(decoded.score == 2.5)
        precondition(decoded.duration == 12)
    } catch {
        preconditionFailure("TimelineEntryRelevance Codable round-trip failed")
    }
}

func testViewWidgetModifiers() {
    let url = URL(string: "widget://kind")
    let labeled = AccessoryWidgetBackground()
        .widgetURL(url)
        .widgetAccentable(true)
        .widgetCurvesContent(false)
        .widgetLabel("plain")
    let notes = WidgetChrome.annotations(of: labeled)
    precondition(notes.widgetURL == url)
    precondition(notes.widgetLabel == "plain")
    precondition(notes.widgetAccentable == true)
    precondition(notes.widgetCurvesContent == false)

    let view = AccessoryWidgetBackground()
    _ = view.widgetURL(url)
    _ = view.widgetAccentable(true)
    _ = view.widgetCurvesContent(false)
    let textLabel = WidgetChrome.annotations(of: view.widgetLabel(Text("label")))
    precondition(textLabel.widgetLabel == "label")
    let keyLabel = WidgetChrome.annotations(of: view.widgetLabel(LocalizedStringKey("key")))
    precondition(keyLabel.widgetLabel == "key")
    let resourceLabel = WidgetChrome.annotations(
        of: view.widgetLabel(LocalizedStringResource("resource"))
    )
    precondition(resourceLabel.widgetLabel == "resource")
    let builderLabel = WidgetChrome.annotations(
        of: AccessoryWidgetBackground().widgetLabel { Text("builder") }
    )
    precondition(builderLabel.widgetLabel == "builder")
    _ = view.controlWidgetActionHint(Text("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringKey("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringResource("hint"))
    _ = view.controlWidgetActionHint("hint")
    _ = view.controlWidgetStatus(Text("status"))
    _ = view.controlWidgetStatus(LocalizedStringKey("status"))
    _ = view.controlWidgetStatus(LocalizedStringResource("status"))
    _ = view.controlWidgetStatus("status")
    _ = view.activityBackgroundTint(.blue)
    _ = view.activitySystemActionForegroundColor(.primary)
    _ = view.dynamicIsland(verticalPlacement: .default)
    _ = view.containerBackground(Color.clear, for: .widget)
    _ = view.containerBackground(for: .widget) { Color.clear }
    _ = Image(systemName: "star").widgetAccentedRenderingMode(.accented)
}

func testWidgetAndBundleMain() {
    struct ProbeWidget: Widget {
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: "probe", provider: _StaticProvider()) { entry in
                Text("\(entry.stamp)")
            }
        }
    }
    struct SecondWidget: Widget {
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: "second", provider: _StaticProvider()) { _ in
                Text("2")
            }
        }
    }
    struct ThirdWidget: Widget {
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: "third", provider: _StaticProvider()) { _ in
                Text("3")
            }
        }
    }
    struct FourthWidget: Widget {
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: "fourth", provider: _StaticProvider()) { _ in
                Text("4")
            }
        }
    }
    struct FifthWidget: Widget {
        var body: some WidgetConfiguration {
            StaticConfiguration(kind: "fifth", provider: _StaticProvider()) { _ in
                Text("5")
            }
        }
    }
    // IceCubes' exact @main bundle is five widgets; WidgetBundleBuilder
    // buildBlock overloads 1...5 must typecheck. Cited: Apple WidgetBundle.
    struct ProbeBundle: WidgetBundle {
        var body: some Widget {
            ProbeWidget()
            SecondWidget()
            ThirdWidget()
            FourthWidget()
            FifthWidget()
        }
    }
    ProbeWidget.main()
    ProbeBundle.main()
    _ = ProbeWidget().body
    _ = ProbeBundle().body
}

func testConfigurationTypes() {
    let built = _makePortableConfigurations()
    precondition(built.staticDescriptor.kind == "static.kind")
    precondition(built.intentDescriptor.kind == "intent.kind")
    precondition(built.appDescriptor.kind == "app.kind")
    precondition(built.activityDescriptor.displayName != nil)
}

func testConfigurationDisplayNameAndDescription() {
    // WidgetConfiguration modifiers are value stores: two independently
    // built configs with the same display name / description compare equal.
    // Cited: Apple WidgetConfiguration.configurationDisplayName / description.
    let first = _makePortableConfigurations()
    let second = _makePortableConfigurations()
    precondition(first.staticDescriptor.displayName != nil)
    precondition(first.staticDescriptor.description != nil)
    precondition(first.staticDescriptor == second.staticDescriptor)
    precondition(first.intentDescriptor.displayName != nil)
    precondition(first.appDescriptor.description != nil)
    precondition(first.activityDescriptor.displayName != nil)
    precondition(first.activityDescriptor == second.activityDescriptor)
}

func testConfigurationFamiliesMarginsAndBackground() {
    let built = _makePortableConfigurations()
    let other = StaticConfiguration(
        kind: "static.kind",
        provider: _StaticProvider()
    ) { entry in
        Text("\(entry.stamp)")
    }
    .supportedFamilies([.systemLarge])
    let otherDescriptor = WidgetKitPortable.descriptor(of: other)
    precondition(built.staticDescriptor.supportedFamilies == [.systemSmall, .systemMedium])
    precondition(built.staticDescriptor.contentMarginsDisabled)
    precondition(!built.staticDescriptor.containerBackgroundRemovable)
    precondition(built.intentDescriptor.supportedFamilies == [.systemLarge])
    precondition(built.appDescriptor.contentMarginsDisabled)
    precondition(built.staticDescriptor != otherDescriptor)
}

func testConfigurationPushAndSession() {
    let built = _makePortableConfigurations()
    // promptsForUserConfiguration is stored host data; pushHandler /
    // associatedKind / onBackgroundURLSessionEvents / backgroundTask keep
    // the rest of the descriptor and never invent a chronod success.
    precondition(built.staticDescriptor.kind == "static.kind")
    precondition(built.staticDescriptor.promptsForUserConfiguration)
    precondition(built.appDescriptor.kind == "app.kind")
    precondition(built.appDescriptor.promptsForUserConfiguration)
}

private func _makePortableConfigurations() -> (
    staticDescriptor: WidgetConfigurationDescriptor,
    intentDescriptor: WidgetConfigurationDescriptor,
    appDescriptor: WidgetConfigurationDescriptor,
    activityDescriptor: WidgetConfigurationDescriptor
) {
    let staticConfig = StaticConfiguration(
        kind: "static.kind",
        provider: _StaticProvider()
    ) { entry in
        Text("\(entry.stamp)")
    }
    .configurationDisplayName("Static")
    .configurationDisplayName(LocalizedStringKey("Static"))
    .configurationDisplayName(LocalizedStringResource("Static"))
    .configurationDisplayName(Text("Static"))
    .description("Static desc")
    .description(LocalizedStringKey("Static desc"))
    .description(LocalizedStringResource("Static desc"))
    .description(Text("Static desc"))
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
    .containerBackgroundRemovable(false)
    .promptsForUserConfiguration()
    .pushHandler(_PushHandler.self)
    .associatedKind("other")
    .disfavoredLocations([.carPlay], for: [.systemSmall])
    .supportedMountingStyles([.elevated])
    .onBackgroundURLSessionEvents(matching: "id") { _, done in done() }
    .onBackgroundURLSessionEvents(matching: { name in
        name.hasPrefix("id")
    }) { _, done in done() }
    .supplementalActivityFamilies([.small])
    .backgroundTask(BackgroundTask<Int, Int>()) { value in value }

    let intentConfig = IntentConfiguration(
        kind: "intent.kind",
        intent: _LegacyIntent.self,
        provider: _LegacyProvider()
    ) { entry in
        Text("\(entry.stamp)")
    }
    .configurationDisplayName("Intent")
    .description("Intent desc")
    .supportedFamilies([.systemLarge])
    .promptsForUserConfiguration()
    .pushHandler(_PushHandler.self)
    .associatedKind("legacy")
    .disfavoredLocations([.lockScreen], for: [.systemLarge])
    .supportedMountingStyles([.recessed])
    .onBackgroundURLSessionEvents(matching: "intent") { _, done in done() }
    .onBackgroundURLSessionEvents(matching: { name in
        name.hasPrefix("in")
    }) { _, done in done() }
    .supplementalActivityFamilies([.medium])
    .backgroundTask(BackgroundTask<Int, Int>()) { value in value }

    let appConfig = AppIntentConfiguration(
        kind: "app.kind",
        intent: _AppIntent.self,
        provider: _AppProvider()
    ) { entry in
        Text("\(entry.stamp)")
    }
    .configurationDisplayName("App")
    .description("App desc")
    .contentMarginsDisabled()
    .promptsForUserConfiguration()
    .pushHandler(_PushHandler.self)
    .associatedKind("app")
    .onBackgroundURLSessionEvents(matching: "app") { _, done in done() }
    .onBackgroundURLSessionEvents(matching: { name in
        name.hasPrefix("ap")
    }) { _, done in done() }
    .backgroundTask(BackgroundTask<Int, Int>()) { value in value }

    struct Attr: ActivityAttributes {
        struct ContentState: Sendable {}
    }
    let activity = ActivityConfiguration(
        for: Attr.self,
        content: { _ in Text("a") },
        dynamicIsland: { _ in
            DynamicIsland(
                expanded: { DynamicIslandExpandedContent<Text>() },
                compactLeading: { Text("L") },
                compactTrailing: { Text("T") },
                minimal: { Text("M") }
            )
        }
    )
    .configurationDisplayName("Activity")
    .description("Activity desc")
    .promptsForUserConfiguration()
    .pushHandler(_PushHandler.self)
    .associatedKind("activity")
    .onBackgroundURLSessionEvents(matching: "act") { _, done in done() }
    .onBackgroundURLSessionEvents(matching: { name in
        name.hasPrefix("ac")
    }) { _, done in done() }
    .supplementalActivityFamilies([.small])
    .backgroundTask(BackgroundTask<Int, Int>()) { value in value }

    return (
        WidgetKitPortable.descriptor(of: staticConfig),
        WidgetKitPortable.descriptor(of: intentConfig),
        WidgetKitPortable.descriptor(of: appConfig),
        WidgetKitPortable.descriptor(of: activity)
    )
}

private func _assertTimelineRuntimeFailClosed() {
    struct Entry: TimelineEntry, Sendable {
        var date: Date
    }
    func expect(
        _ entries: [Double],
        _ policy: TimelineReloadPolicy,
        as error: WidgetTimelineRuntimeError
    ) {
        let timeline = Timeline(
            entries: entries.map { Entry(date: Date(timeIntervalSinceReferenceDate: $0)) },
            policy: policy
        )
        do {
            _ = try WidgetTimelineValidation.evaluate(timeline)
            preconditionFailure("expected fail-closed timeline error")
        } catch let seen as WidgetTimelineRuntimeError {
            precondition(seen == error)
        } catch {
            preconditionFailure("unexpected timeline error")
        }
    }
    expect([], .atEnd, as: .emptyTimeline)
    expect([20, 10], .atEnd, as: .entriesOutOfOrder)
    expect(
        [10, 10],
        .atEnd,
        as: .duplicateEntryDate(Date(timeIntervalSinceReferenceDate: 10))
    )
    expect(
        [10, 20],
        .after(Date(timeIntervalSinceReferenceDate: 5)),
        as: .reloadDateBeforeLastEntry(Date(timeIntervalSinceReferenceDate: 5))
    )
}
