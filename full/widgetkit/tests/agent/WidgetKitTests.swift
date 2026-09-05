@_spi(OpenUIKitHost) import WidgetKit
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
    // Apple WidgetCenter documentation: clients use WidgetCenter.shared.
    // Linux is a process-local registry the host can drive; every instance
    // shares that storage so WidgetCenter() and .shared agree.
    let center = WidgetCenter.shared
    center.resetProcessLocalState()
    precondition(center === WidgetCenter.shared)
    let alias = WidgetCenter()

    let configurations = _ValueBox<[WidgetInfo]>()
    center.getCurrentConfigurations { result in
        configurations.value = try? result.get()
    }
    precondition(configurations.value?.isEmpty == true)

    center.reloadTimelines(ofKind: "account")
    alias.reloadAllTimelines()
    center.reloadTimelines(ofKind: "note")
    let drained = center.drainReloadRequests()
    precondition(drained.count == 3)
    precondition(drained[0].scope == .kind("account"))
    precondition(drained[1].scope == .all)
    precondition(drained[2].scope == .kind("note"))
    precondition(drained[0].sequence == 1)
    precondition(drained[1].sequence == 2)
    precondition(drained[2].sequence == 3)
    precondition(alias.drainReloadRequests().isEmpty)

    let info = WidgetInfo(kind: "account", family: .systemSmall)
    center.installCurrentConfigurations([info])
    let installed = _ValueBox<[WidgetInfo]>()
    center.getCurrentConfigurations { result in
        installed.value = try? result.get()
    }
    precondition(installed.value == [info])
    precondition(center.portableCurrentConfigurations() == [info])
    precondition(center.portableCurrentPushInfo == nil)
    // invalidateConfigurationRecommendations does not drop installed widgets
    // (Apple: it asks WidgetKit for new recommendations, not current configs).
    center.invalidateConfigurationRecommendations()
    center.invalidateConfigurationRecommendations()
    precondition(center.drainConfigurationRecommendationInvalidations() == 2)
    let stillInstalled = _ValueBox<[WidgetInfo]>()
    center.getCurrentConfigurations { result in
        stillInstalled.value = try? result.get()
    }
    precondition(stillInstalled.value == [info])
    center.invalidateRelevance(ofKind: "account")
    _ = WidgetCenter.UserInfoKey.kind
    _ = WidgetCenter.UserInfoKey.family
    _ = WidgetCenter.UserInfoKey.activityID
    center.resetProcessLocalState()
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
    precondition(first.debugDescription.hasPrefix("WidgetInfo(kind: a"))
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
    // AccessoryWidgetBackground is the Lock Screen / accessory chrome shape.
    // Cited: Apple AccessoryWidgetBackground. containerBackground(for: .widget)
    // is the Home Screen container fill (Apple View.containerBackground).
    let background = AccessoryWidgetBackground()
    _ = background.body
    _ = background.containerBackground(Color.clear, for: .widget)
    _ = background.containerBackground(for: .widget) { Color.clear }
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
    let center = ControlCenter.shared
    center.resetProcessLocalState()
    center.reloadControls(ofKind: "toggle")
    center.reloadAllControls()
    precondition(center.drainReloadKinds() == ["toggle"])
    precondition(center.drainReloadAllCount() == 1)
    precondition(center.portableCurrentControls().isEmpty)
    let info = ControlInfo(kind: "toggle", pushInfo: ControlPushInfo(token: Data([1])))
    center.installCurrentControls([info])
    precondition(center.portableCurrentControls() == [info])
    precondition(ControlCenter().portableCurrentControls() == [info])
    _ = ControlCenter.shared
    center.resetProcessLocalState()
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
    let provider = Provider()
    precondition(provider.placeholder(in: context).date == Date(timeIntervalSinceReferenceDate: 1))
    do {
        let evaluation = try WidgetTimelineValidation.evaluate(
            Timeline(
                entries: [
                    Entry(date: Date(timeIntervalSinceReferenceDate: 10)),
                    Entry(date: Date(timeIntervalSinceReferenceDate: 20)),
                ],
                policy: .after(Date(timeIntervalSinceReferenceDate: 30))
            )
        )
        precondition(evaluation.nextReload == Date(timeIntervalSinceReferenceDate: 30))
        precondition(
            WidgetTimelineValidation.entry(
                at: Date(timeIntervalSinceReferenceDate: 15),
                in: evaluation.timeline
            )?.date == Date(timeIntervalSinceReferenceDate: 10)
        )
    } catch {
        preconditionFailure("valid timeline must not throw")
    }
    _ = Intent()
}

private final class _ValueBox<T>: @unchecked Sendable {
    var value: T?
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
    let context = RelevantContext()
    let relevance = WidgetRelevance<Void>([
        WidgetRelevanceAttribute(group: .automatic),
        WidgetRelevanceAttribute(context: context),
    ])
    _ = relevance
    _ = WidgetRelevanceAttribute(configuration: "cfg", group: .named("mail"))
    _ = WidgetRelevanceAttribute(configuration: "cfg", context: context)
    let intent = INIntent()
    _ = WidgetRelevanceAttribute(configuration: intent, group: .automatic)
    _ = WidgetRelevanceAttribute(configuration: intent, context: context)
    struct ConfigIntent: WidgetConfigurationIntent {}
    _ = WidgetRelevanceAttribute(configuration: ConfigIntent(), group: .ungrouped)
    _ = WidgetRelevanceAttribute(configuration: ConfigIntent(), context: context)
    let push = WidgetPushInfo(token: Data([1, 2, 3]))
    precondition(push.token.count == 3)
}
