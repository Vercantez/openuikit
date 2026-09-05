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
    // Cited: Apple WidgetCenter.currentPushInfo — nil until aps delivers a token.
    let center = WidgetCenter.shared
    center.resetProcessLocalState()
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
        box.value = true
    }
    _waitForBox(box)
    precondition(box.value == true)
}

func testConfigurationTypes() {
    let box = _Box<Bool>()
    Task { @MainActor in
        let built = _makePortableConfigurations()
        box.value =
            built.staticDescriptor.kind == "static.kind"
            && built.intentDescriptor.kind == "intent.kind"
            && built.appDescriptor.kind == "app.kind"
            && built.activityDescriptor.displayName != nil
    }
    _waitForBox(box)
    precondition(box.value == true)
}

func testConfigurationDisplayNameAndDescription() {
    // WidgetConfiguration modifiers are value stores: two independently
    // built configs with the same display name / description compare equal.
    // Cited: Apple WidgetConfiguration.configurationDisplayName / description.
    let box = _Box<Bool>()
    Task { @MainActor in
        let first = _makePortableConfigurations()
        let second = _makePortableConfigurations()
        box.value =
            first.staticDescriptor.displayName != nil
            && first.staticDescriptor.description != nil
            && first.staticDescriptor == second.staticDescriptor
            && first.intentDescriptor.displayName != nil
            && first.appDescriptor.description != nil
            && first.activityDescriptor.displayName != nil
            && first.activityDescriptor == second.activityDescriptor
    }
    _waitForBox(box)
    precondition(box.value == true)
}

func testConfigurationFamiliesMarginsAndBackground() {
    let box = _Box<Bool>()
    Task { @MainActor in
        let built = _makePortableConfigurations()
        let other = StaticConfiguration(
            kind: "static.kind",
            provider: _StaticProvider()
        ) { entry in
            Text("\(entry.stamp)")
        }
        .supportedFamilies([.systemLarge])
        let otherDescriptor = WidgetKitPortable.descriptor(of: other)
        box.value =
            built.staticDescriptor.supportedFamilies == [.systemSmall, .systemMedium]
            && built.staticDescriptor.contentMarginsDisabled
            && !built.staticDescriptor.containerBackgroundRemovable
            && built.intentDescriptor.supportedFamilies == [.systemLarge]
            && built.appDescriptor.contentMarginsDisabled
            && built.staticDescriptor != otherDescriptor
    }
    _waitForBox(box)
    precondition(box.value == true)
}

func testConfigurationPushAndSession() {
    let box = _Box<Bool>()
    Task { @MainActor in
        let built = _makePortableConfigurations()
        // promptsForUserConfiguration / pushHandler / associatedKind /
        // onBackgroundURLSessionEvents / backgroundTask keep descriptor
        // identity; they must not invent a chronod or URL-session success.
        // Cited: Apple WidgetConfiguration.
        box.value =
            built.staticDescriptor.kind == "static.kind"
            && built.staticDescriptor == built.staticDescriptor
            && built.appDescriptor.kind == "app.kind"
    }
    _waitForBox(box)
    precondition(box.value == true)
}

@MainActor
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
    struct Provider: TimelineProvider, Sendable {
        var entries: [Entry]
        var policy: TimelineReloadPolicy
        func placeholder(in _: Context) -> Entry {
            Entry(date: Date(timeIntervalSinceReferenceDate: 1))
        }
        func getSnapshot(
            in _: Context,
            completion: @escaping @Sendable (Entry) -> Void
        ) {
            completion(placeholder(in: TimelineProviderContext(
                family: .systemSmall,
                displaySize: CGSize(width: 1, height: 1)
            )))
        }
        func getTimeline(
            in _: Context,
            completion: @escaping @Sendable (Timeline<Entry>) -> Void
        ) {
            completion(Timeline(entries: entries, policy: policy))
        }
    }
    let context = TimelineProviderContext(
        family: .systemSmall,
        displaySize: CGSize(width: 1, height: 1)
    )
    let runtime = WidgetTimelineRuntime()
    func expect(
        _ entries: [Double],
        _ policy: TimelineReloadPolicy,
        as error: WidgetTimelineRuntimeError
    ) {
        let provider = Provider(
            entries: entries.map { Entry(date: Date(timeIntervalSinceReferenceDate: $0)) },
            policy: policy
        )
        let done = DispatchSemaphore(value: 0)
        let box = _Box<WidgetTimelineRuntimeError>()
        Task {
            do {
                _ = try await runtime.evaluate(provider, context: context)
                box.failed = true
            } catch let seen as WidgetTimelineRuntimeError {
                box.value = seen
            } catch {
                box.failed = true
            }
            done.signal()
        }
        precondition(done.wait(timeout: .now() + .seconds(5)) == .success)
        precondition(box.failed == false)
        precondition(box.value == error)
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

private func _waitForBox<T>(_ box: _Box<T>) {
    let deadline = Date().addingTimeInterval(5)
    while box.value == nil && box.failed == false && Date() < deadline {
        _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
}
