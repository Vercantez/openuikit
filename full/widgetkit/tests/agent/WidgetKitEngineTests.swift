@_spi(OpenUIKitHost) import WidgetKit
import Dispatch
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

func testWidgetFamilyCanvasSizes() {
    precondition(WidgetFamily.portableHomeScreenFamilies.map(\.rawValue) == [0, 1, 2, 3, 5, 6, 7])
    precondition(WidgetFamily.accessoryCorner.rawValue == 8)
    precondition(WidgetFamily.accessoryCorner.description == "accessoryCorner")

    let seSmall = WidgetFamily.systemSmall.portableCanvasSize(for: .iPhoneSE375)
    precondition(seSmall == CGSize(width: 155, height: 155))
    let proMedium = WidgetFamily.systemMedium.portableCanvasSize(for: .iPhone393)
    precondition(proMedium == CGSize(width: 338, height: 158))
    let maxLarge = WidgetFamily.systemLarge.portableCanvasSize(for: .iPhone430)
    precondition(maxLarge == CGSize(width: 364, height: 382))
    let extra = WidgetFamily.systemExtraLarge.portableCanvasSize(for: .iPhone393)
    precondition(extra == nil)
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

    let runtime = WidgetTimelineRuntime()
    let done = DispatchSemaphore(value: 0)
    let eval = _Box<WidgetTimelineEvaluation<_EngineEntry>>()
    Task {
        do {
            eval.value = try await runtime.evaluate(provider, context: context)
            let snap = await runtime.snapshot(provider, context: context)
            precondition(snap.stamp == 1)
        } catch {
            eval.failed = true
        }
        done.signal()
    }
    precondition(done.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(eval.failed == false)
    precondition(eval.value?.nextReload == Date(timeIntervalSinceReferenceDate: 40))
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

    let done = DispatchSemaphore(value: 0)
    let box = _Box<Int>()
    Task {
        let snap = await provider.snapshot(for: intent, in: context)
        let timeline = await provider.timeline(for: intent, in: context)
        box.value = snap.stamp + timeline.entries.count
        done.signal()
    }
    precondition(done.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(box.value == 3)
}

func testTimelineEngineEntryAtTime() {
    let engine = WidgetTimelineEngine()
    let done = DispatchSemaphore(value: 0)
    let stamps = _Box<[Int]>()
    Task {
        await engine.register(kind: "static", provider: _StaticProvider())
        await engine.register(
            kind: "legacy",
            provider: _LegacyProvider(),
            configuration: _LegacyIntent()
        )
        await engine.register(
            kind: "app",
            provider: _AppProvider(),
            configuration: _AppIntent()
        )
        await engine.register(kind: "never", provider: _NeverProvider())
        await engine.setClock { Date(timeIntervalSinceReferenceDate: 25) }

        do {
            func stamp(_ kind: String, at t: Double) async throws -> Int {
                let entry = try await engine.entry(
                    ofKind: kind,
                    at: Date(timeIntervalSinceReferenceDate: t)
                )
                return (entry as? _EngineEntry)?.stamp ?? -1
            }
            let before = try await stamp("static", at: 0)
            let mid = try await stamp("static", at: 25)
            let after = try await stamp("static", at: 100)
            let current = try await engine.currentEntry(ofKind: "static")
            let reload = try await engine.nextReloadDate(ofKind: "static")
            let neverReload = try await engine.nextReloadDate(ofKind: "never")
            let missing = try await engine.entry(ofKind: "absent", at: Date())
            let placeholder = await engine.placeholder(ofKind: "static")
            let kinds = await engine.registeredKinds
            stamps.value = [
                before,
                mid,
                after,
                (current as? _EngineEntry)?.stamp ?? -1,
                reload == Date(timeIntervalSinceReferenceDate: 40) ? 1 : 0,
                neverReload == nil ? 1 : 0,
                missing == nil ? 1 : 0,
                (placeholder as? _EngineEntry)?.stamp ?? -1,
                kinds.count,
            ]
        } catch {
            stamps.failed = true
        }
        await engine.unregister(kind: "static")
        done.signal()
    }
    precondition(done.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(stamps.failed == false)
    precondition(stamps.value == [10, 20, 30, 20, 1, 1, 1, 0, 4])
}

func testWidgetCenterCurrentPushInfo() {
    let center = WidgetCenter()
    let done = DispatchSemaphore(value: 0)
    let box = _Box<Bool>()
    Task {
        let push = await center.currentPushInfo
        let configs = try? await center.currentConfigurations()
        box.value = push == nil && configs?.isEmpty == true
        done.signal()
    }
    precondition(done.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(box.value == true)
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
    let view = AccessoryWidgetBackground()
    _ = view.widgetURL(URL(string: "widget://kind"))
    _ = view.widgetAccentable(true)
    _ = view.widgetCurvesContent(false)
    _ = view.widgetLabel(Text("label"))
    _ = view.widgetLabel(LocalizedStringKey("key"))
    _ = view.widgetLabel(LocalizedStringResource("resource"))
    _ = view.widgetLabel("plain")
    _ = view.widgetLabel { Text("builder") }
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
    let box = _Box<Bool>()
    Task { @MainActor in
        struct ProbeWidget: Widget {
            var body: some WidgetConfiguration {
                StaticConfiguration(kind: "probe", provider: _StaticProvider()) { entry in
                    Text("\(entry.stamp)")
                }
            }
        }
        struct ProbeBundle: WidgetBundle {
            var body: some Widget {
                ProbeWidget()
            }
        }
        ProbeWidget.main()
        ProbeBundle.main()
        box.value = true
    }
    _waitForBox(box)
    precondition(box.value == true)
}

func testConfigurationModifiers() {
    let box = _Box<Bool>()
    Task { @MainActor in
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

        let staticDescriptor = WidgetKitPortable.descriptor(of: staticConfig)
        let intentDescriptor = WidgetKitPortable.descriptor(of: intentConfig)
        let appDescriptor = WidgetKitPortable.descriptor(of: appConfig)
        let activityDescriptor = WidgetKitPortable.descriptor(of: activity)
        box.value =
            staticDescriptor.kind == "static.kind"
            && staticDescriptor.displayName != nil
            && staticDescriptor.contentMarginsDisabled
            && !staticDescriptor.containerBackgroundRemovable
            && staticDescriptor.supportedFamilies == [.systemSmall, .systemMedium]
            && intentDescriptor.kind == "intent.kind"
            && appDescriptor.kind == "app.kind"
            && appDescriptor.contentMarginsDisabled
            && activityDescriptor.displayName != nil
    }
    _waitForBox(box)
    precondition(box.value == true)
}

private func _waitForBox<T>(_ box: _Box<T>) {
    let deadline = Date().addingTimeInterval(5)
    while box.value == nil && box.failed == false && Date() < deadline {
        _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
}
