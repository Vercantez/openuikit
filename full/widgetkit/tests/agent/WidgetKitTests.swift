@_spi(OpenUIKitHost) import WidgetKit
import Dispatch
import Foundation

func testWidgetFamilyCases() {
    let families: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
        .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]
    precondition(families.map(\.rawValue) == [0, 1, 2, 3, 5, 6, 7])
    precondition(WidgetFamily.systemSmall.description == "systemSmall")
    precondition(WidgetFamily.systemSmall.debugDescription == "systemSmall")
    precondition(WidgetFamily(rawValue: 1) == .systemMedium)
    precondition(WidgetFamily(rawValue: 99) == nil)
}

func testTimelineReloadPolicy() {
    let date = Date(timeIntervalSinceReferenceDate: 50)
    precondition(TimelineReloadPolicy.atEnd == TimelineReloadPolicy.atEnd)
    precondition(TimelineReloadPolicy.never != TimelineReloadPolicy.atEnd)
    precondition(TimelineReloadPolicy.after(date) == TimelineReloadPolicy.after(date))
    precondition(TimelineReloadPolicy.after(date) != TimelineReloadPolicy.atEnd)
}

func testTimelineEntryRelevance() {
    let first = TimelineEntryRelevance(score: 1.5, duration: 30)
    let second = TimelineEntryRelevance(score: 1.5, duration: 30)
    let third = TimelineEntryRelevance(score: 0, duration: 0)
    precondition(first.score == 1.5)
    precondition(first.duration == 30)
    precondition(first == second)
    precondition(first != third)
    precondition(first.hashValue == second.hashValue)
}

func testWidgetRenderingMode() {
    precondition(WidgetRenderingMode.fullColor != WidgetRenderingMode.accented)
    precondition(WidgetRenderingMode.accented != WidgetRenderingMode.vibrant)
    precondition(WidgetRenderingMode.fullColor.description == "fullColor")
    precondition(WidgetRenderingMode.accented.description == "accented")
    precondition(WidgetRenderingMode.vibrant.description == "vibrant")
}

func testWidgetCenterReloadAndConfigurations() {
    let center = WidgetCenter()
    let configurations = _ValueBox<[WidgetInfo]>()
    center.getCurrentConfigurations { result in
        configurations.value = try? result.get()
    }
    precondition(configurations.value?.isEmpty == true)

    center.reloadTimelines(ofKind: "account")
    center.reloadAllTimelines()
    center.reloadTimelines(ofKind: "note")
    let drained = center.drainReloadRequests()
    precondition(drained.count == 3)
    precondition(drained[0].scope == .kind("account"))
    precondition(drained[1].scope == .all)
    precondition(drained[2].scope == .kind("note"))
    precondition(drained[0].sequence == 1)
    precondition(drained[1].sequence == 2)
    precondition(drained[2].sequence == 3)
    precondition(center.drainReloadRequests().isEmpty)

    let info = WidgetInfo(kind: "account", family: .systemSmall)
    center.installCurrentConfigurations([info])
    let installed = _ValueBox<[WidgetInfo]>()
    center.getCurrentConfigurations { result in
        installed.value = try? result.get()
    }
    precondition(installed.value == [info])
    center.invalidateConfigurationRecommendations()
    center.invalidateRelevance(ofKind: "account")
    _ = WidgetCenter.shared
    _ = WidgetCenter.UserInfoKey.kind
    _ = WidgetCenter.UserInfoKey.family
    _ = WidgetCenter.UserInfoKey.activityID
}

func testWidgetInfoHashable() {
    let first = WidgetInfo(kind: "a", family: .systemSmall)
    let second = WidgetInfo(kind: "a", family: .systemSmall)
    let third = WidgetInfo(kind: "b", family: .systemMedium)
    precondition(first == second)
    precondition(first != third)
    precondition(first.hashValue == second.hashValue)
    precondition(first.kind == "a")
    precondition(first.family == .systemSmall)
    precondition(first.debugDescription.contains("a"))
    precondition(first.widgetConfigurationIntent(of: String.self) == nil)
}

func testTimelineConstruction() {
    struct Entry: TimelineEntry {
        var date: Date
    }
    let first = Date(timeIntervalSinceReferenceDate: 10)
    let second = Date(timeIntervalSinceReferenceDate: 20)
    let timeline = Timeline(
        entries: [Entry(date: first), Entry(date: second)],
        policy: .atEnd
    )
    precondition(timeline.entries.count == 2)
    precondition(timeline.entries[0].date == first)
    precondition(timeline.policy == .atEnd)
    precondition(timeline.entries[0].relevance == nil)
}

func testAccessoryWidgetBackground() {
    let background = AccessoryWidgetBackground()
    _ = background.body
}

func testWidgetLocationAndMounting() {
    precondition(WidgetLocation.homeScreen != WidgetLocation.lockScreen)
    precondition(WidgetLocation.standBy != WidgetLocation.carPlay)
    precondition(WidgetLocation.iPhoneWidgetsOnMac != WidgetLocation.homeScreen)
    precondition(WidgetMountingStyle.elevated != WidgetMountingStyle.recessed)
    var hasher = Hasher()
    WidgetMountingStyle.elevated.hash(into: &hasher)
    _ = hasher.finalize()
}

func testActivityFamilyAndLevelOfDetail() {
    precondition(ActivityFamily.small.rawValue == 0)
    precondition(ActivityFamily.medium.rawValue == 1)
    precondition(ActivityFamily.small.description == "small")
    precondition(ActivityFamily(rawValue: 1) == .medium)
    precondition(LevelOfDetail.default != LevelOfDetail.simplified)
}

func testControlCenterFailClosed() {
    let center = ControlCenter()
    center.reloadControls(ofKind: "toggle")
    center.reloadAllControls()
    var controls: [ControlInfo]?
    let lock = NSLock()
    let done = { (value: [ControlInfo]) in
        lock.lock()
        controls = value
        lock.unlock()
    }
    // currentControls is async; drive it with a semaphore from a detached task.
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        let value = await center.currentControls()
        done(value)
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + .seconds(5)) == .success)
    lock.lock()
    let snapshot = controls
    lock.unlock()
    precondition(snapshot?.isEmpty == true)
    _ = ControlCenter.shared
}

func testWidgetAccentedRenderingMode() {
    precondition(
        WidgetAccentedRenderingMode.fullColor
            != WidgetAccentedRenderingMode.accented
    )
    precondition(
        WidgetAccentedRenderingMode.desaturated
            != WidgetAccentedRenderingMode.accentedDesaturated
    )
}

func testTimelineProviderContext() {
    let context = TimelineProviderContext(
        family: .systemMedium,
        isPreview: true,
        displaySize: CGSize(width: 160, height: 160)
    )
    precondition(context.family == .systemMedium)
    precondition(context.isPreview)
    precondition(context.displaySize.width == 160)
    precondition(context.displaySize.height == 160)
    precondition(context.environmentVariants[dynamicMember: \.widgetFamily] == nil)
}

func testTimelineRuntimeValidation() {
    struct Entry: TimelineEntry, Sendable {
        var date: Date
    }
    struct Intent: WidgetConfigurationIntent {}
    struct Provider: AppIntentTimelineProvider, Sendable {
        func placeholder(in _: Context) -> Entry {
            Entry(date: Date(timeIntervalSinceReferenceDate: 1))
        }
        func snapshot(for _: Intent, in _: Context) async -> Entry {
            Entry(date: Date(timeIntervalSinceReferenceDate: 2))
        }
        func timeline(for _: Intent, in _: Context) async -> Timeline<Entry> {
            Timeline(
                entries: [
                    Entry(date: Date(timeIntervalSinceReferenceDate: 10)),
                    Entry(date: Date(timeIntervalSinceReferenceDate: 20)),
                ],
                policy: .after(Date(timeIntervalSinceReferenceDate: 30))
            )
        }
    }
    let context = TimelineProviderContext(
        family: .systemSmall,
        displaySize: CGSize(width: 1, height: 1)
    )
    let runtime = WidgetTimelineRuntime()
    let semaphore = DispatchSemaphore(value: 0)
    let box = _EvalBox()
    Task {
        do {
            let evaluation = try await runtime.evaluate(
                Provider(),
                configuration: Intent(),
                context: context
            )
            box.nextReload = evaluation.nextReload
            box.count = await runtime.evaluationCount
        } catch {
            box.failed = true
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(box.failed == false)
    precondition(box.nextReload == Date(timeIntervalSinceReferenceDate: 30))
    precondition(box.count == 1)
}

private final class _ValueBox<T>: @unchecked Sendable {
    var value: T?
}

private final class _EvalBox: @unchecked Sendable {
    var nextReload: Date?
    var count: UInt64 = 0
    var failed = false
}

func testEnvironmentValuesDefaults() {
    var values = EnvironmentValues()
    precondition(values.widgetFamily == .systemSmall)
    values.widgetFamily = .systemLarge
    precondition(values.widgetFamily == .systemLarge)
    precondition(values.widgetRenderingMode == .fullColor)
    precondition(values.showsWidgetContainerBackground)
    precondition(values.levelOfDetail == .default)
    precondition(values.activityFamily == .small)
    precondition(!values.isActivityFullscreen)
}

func testWidgetRelevanceAndPush() {
    let group = WidgetRelevanceGroup.named("mail")
    precondition(group != .automatic)
    precondition(WidgetRelevanceGroup.ungrouped != .automatic)
    let relevance = WidgetRelevance<Void>([
        WidgetRelevanceAttribute(group: .automatic),
    ])
    _ = relevance
    let push = WidgetPushInfo(token: Data([1, 2, 3]))
    precondition(push.token.count == 3)
}
