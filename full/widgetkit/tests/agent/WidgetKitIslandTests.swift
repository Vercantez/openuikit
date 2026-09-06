@_spi(OpenUIKitHost) import WidgetKit
import Foundation

private struct _IslandAttributes: ActivityAttributes {
    struct ContentState: Equatable, Sendable {
        var label: String
    }

    var title: String
}

private struct _IslandEntry: TimelineEntry, Sendable {
    var date: Date
    var stamp: Int
}

private final class _PushBox: @unchecked Sendable {
    var info: WidgetPushInfo?
    var widgets: [WidgetInfo] = []
}

private struct _RecordingPushHandler: WidgetPushHandler {
    static let box = _PushBox()
    init() {}
    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        Self.box.info = pushInfo
        Self.box.widgets = widgets
    }
}

func testActivityPreviewViewKindCases() {
    let states: [ActivityPreviewViewKind.DynamicIslandPreviewViewState] = [
        .compact, .minimal, .expanded,
    ]
    precondition(states.count == 3)
    precondition(ActivityPreviewViewKind.DynamicIslandPreviewViewState.compact
        == .compact)
    precondition(ActivityPreviewViewKind.DynamicIslandPreviewViewState.compact
        != .minimal)
    precondition(ActivityPreviewViewKind.DynamicIslandPreviewViewState.minimal
        != .expanded)
    precondition(ActivityPreviewViewKind.content != .dynamicIsland(.compact))
    precondition(
        ActivityPreviewViewKind.dynamicIsland(.expanded)
            == .dynamicIsland(.expanded)
    )
    precondition(
        ActivityPreviewViewKind.dynamicIsland(.compact)
            != .dynamicIsland(.minimal)
    )

    var hasher = Hasher()
    ActivityPreviewViewKind.DynamicIslandPreviewViewState.compact.hash(into: &hasher)
    ActivityPreviewViewKind.content.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        ActivityPreviewViewKind.DynamicIslandPreviewViewState.compact.hashValue
            == ActivityPreviewViewKind.DynamicIslandPreviewViewState.compact.hashValue
    )
    precondition(
        Set(states).count == 3
    )
}

func testDynamicIslandModeEquality() {
    let modes: [DynamicIslandMode] = [
        .compactLeading, .compactTrailing, .minimal, .expanded,
    ]
    precondition(Set(modes).count == 4)
    precondition(DynamicIslandMode.compactLeading == .compactLeading)
    precondition(DynamicIslandMode.compactLeading != .compactTrailing)
    precondition(DynamicIslandMode.minimal != .expanded)
    precondition(DynamicIslandMode.compactLeading.portableName == "compactLeading")
    precondition(DynamicIslandMode.compactTrailing.portableName == "compactTrailing")
    precondition(DynamicIslandMode.minimal.portableName == "minimal")
    precondition(DynamicIslandMode.expanded.portableName == "expanded")
}

func testDynamicIslandExpandedRegionPositionCases() {
    let positions: [DynamicIslandExpandedRegionPosition] = [
        .leading, .trailing, .center, .bottom,
    ]
    precondition(Set(positions).count == 4)
    precondition(DynamicIslandExpandedRegionPosition.leading == .leading)
    precondition(DynamicIslandExpandedRegionPosition.leading != .trailing)
    precondition(DynamicIslandExpandedRegionPosition.center != .bottom)
    precondition(DynamicIslandExpandedRegionPosition.leading.portableName == "leading")
    precondition(DynamicIslandExpandedRegionPosition.trailing.portableName == "trailing")
    precondition(DynamicIslandExpandedRegionPosition.center.portableName == "center")
    precondition(DynamicIslandExpandedRegionPosition.bottom.portableName == "bottom")
}

func testDynamicIslandExpandedRegionVerticalPlacementCases() {
    precondition(
        DynamicIslandExpandedRegionVerticalPlacement.default
            == .default
    )
    precondition(
        DynamicIslandExpandedRegionVerticalPlacement.default
            != .belowIfTooWide
    )
    precondition(
        DynamicIslandExpandedRegionVerticalPlacement.belowIfTooWide.portableName
            == "belowIfTooWide"
    )
    precondition(
        DynamicIslandExpandedRegionVerticalPlacement.default.portableName
            == "default"
    )
}

func testDynamicIslandStoresURLMarginsAndTint() {
    let url = URL(string: "widget://island")
    let island = DynamicIsland(
        expanded: {
            DynamicIslandExpandedRegion(.center, priority: 1) {
                Text("center")
            }
        },
        compactLeading: { Text("L") },
        compactTrailing: { Text("T") },
        minimal: { Text("M") }
    )
    .widgetURL(url)
    .keylineTint(.blue)
    .contentMargins(.all, 8, for: .expanded)
    .contentMargins(.horizontal, 4, for: .minimal)

    let descriptor = island.portableDescriptor
    precondition(descriptor.compactLeading == "L")
    precondition(descriptor.compactTrailing == "T")
    precondition(descriptor.minimal == "M")
    precondition(descriptor.widgetURL == url)
    precondition(descriptor.hasKeylineTint)
    precondition(descriptor.margins["expanded"] == 8)
    precondition(descriptor.margins["minimal"] == 4)
    precondition(descriptor.regions.count == 1)
    precondition(descriptor.regions[0].position == .center)
    precondition(descriptor.regions[0].priority == 1)

    let clear = island.keylineTint(nil)
    precondition(!clear.portableDescriptor.hasKeylineTint)
    precondition(DynamicIsland(
        expanded: { DynamicIslandExpandedContent<Text>() },
        compactLeading: { Text("a") },
        compactTrailing: { Text("b") },
        minimal: { Text("c") }
    ).portableDescriptor.regions.isEmpty)
}

func testDynamicIslandExpandedRegionStoresPriorityAndMargins() {
    let region = DynamicIslandExpandedRegion(.leading, priority: 2.5) {
        Text("lead")
    }
    .contentMargins(.vertical, 6)
    precondition(region.portableDescriptor.position == .leading)
    precondition(region.portableDescriptor.priority == 2.5)
    precondition(region.portableDescriptor.marginLength == 6)
    precondition(region.portableDescriptor.marginEdges == Edge.Set.vertical.rawValue)
    precondition(region.content.content == "lead")

    let trailing = DynamicIslandExpandedRegion(.trailing) { Text("t") }
    precondition(trailing.portableDescriptor.priority == 0)
    precondition(trailing.portableDescriptor.marginLength == nil)
}

func testDynamicIslandExpandedContentBuilderAccumulatesRegions() {
    let first = DynamicIslandExpandedContentBuilder.buildPartialBlock(
        first: DynamicIslandExpandedRegion(.leading) { Text("L") }
    )
    precondition(first.portableRegions.count == 1)
    precondition(first.portableRegions[0].position == .leading)

    let passthrough = DynamicIslandExpandedContentBuilder.buildPartialBlock(
        first: DynamicIslandExpandedContent<Text>(
            regions: [
                DynamicIslandExpandedRegionDescriptor(position: .center, priority: 9),
            ]
        )
    )
    precondition(passthrough.portableRegions[0].priority == 9)

    let accumulated = DynamicIslandExpandedContentBuilder.buildPartialBlock(
        accumulated: first,
        next: DynamicIslandExpandedRegion(.trailing, priority: 3) { Text("R") }
    )
    precondition(accumulated.portableRegions.map(\.position) == [.leading, .trailing])
    precondition(accumulated.portableRegions[1].priority == 3)

    let merged = DynamicIslandExpandedContentBuilder.buildPartialBlock(
        accumulated: accumulated,
        next: DynamicIslandExpandedContent<Text>(
            regions: [
                DynamicIslandExpandedRegionDescriptor(position: .bottom, priority: 0),
            ]
        )
    )
    precondition(merged.portableRegions.map(\.position) == [.leading, .trailing, .bottom])
    precondition(DynamicIslandExpandedContent<Text>().portableRegions.isEmpty)
}

func testActivityViewContextStaleAndLiveState() {
    ActivityViewHost.resetProcessLocalState()
    let attributes = _IslandAttributes(title: "train")
    let liveState = _IslandAttributes.ContentState(label: "on-time")
    do {
        _ = try ActivityViewHost.makeContext(
            activityID: "",
            attributes: attributes,
            state: liveState
        )
        preconditionFailure("empty activityID must fail closed")
    } catch ActivityViewHostError.emptyActivityID {
        ()
    } catch {
        preconditionFailure("unexpected activity host error")
    }

    let live: ActivityViewContext<_IslandAttributes>
    do {
        live = try ActivityViewHost.makeContext(
            activityID: "activity.1",
            attributes: attributes,
            state: liveState
        )
    } catch {
        preconditionFailure("live context must construct")
    }
    precondition(live.activityID == "activity.1")
    precondition(live.attributes.title == "train")
    precondition(live.state.label == "on-time")
    precondition(!live.isStale)

    ActivityViewHost.markStale(activityID: "activity.1")
    precondition(ActivityViewHost.isMarkedStale(activityID: "activity.1"))
    let stale: ActivityViewContext<_IslandAttributes>
    do {
        stale = try ActivityViewHost.makeContext(
            activityID: "activity.1",
            attributes: attributes,
            state: _IslandAttributes.ContentState(label: "delayed")
        )
    } catch {
        preconditionFailure("stale context must construct")
    }
    precondition(stale.isStale)
    precondition(stale.state.label == "delayed")

    let explicit = ActivityViewContext(
        activityID: "activity.2",
        attributes: attributes,
        state: liveState,
        isStale: true
    )
    precondition(explicit.isStale)
    ActivityViewHost.resetProcessLocalState()
}

func testPreviewActivityBuilderConcatenatesContentStates() {
    typealias Builder = PreviewActivityBuilder<_IslandAttributes>
    let onTime = _IslandAttributes.ContentState(label: "on-time")
    let delayed = _IslandAttributes.ContentState(label: "delayed")
    let first = Builder.buildExpression(onTime)
    precondition(first == [onTime])
    let partial = Builder.buildPartialBlock(first: first)
    precondition(partial == [onTime])
    let accumulated = Builder.buildPartialBlock(
        accumulated: partial,
        next: Builder.buildExpression(delayed)
    )
    precondition(accumulated == [onTime, delayed])
    let array = Builder.buildArray([[onTime], [delayed, onTime]])
    precondition(array.map(\.label) == ["on-time", "delayed", "on-time"])
}

func testPreviewTimelineBuilderConcatenatesEntries() {
    let early = _IslandEntry(date: Date(timeIntervalSinceReferenceDate: 10), stamp: 10)
    let late = _IslandEntry(date: Date(timeIntervalSinceReferenceDate: 20), stamp: 20)
    let first = PreviewTimelineBuilder.buildExpression(early)
    precondition(first.count == 1)
    precondition((first[0] as? _IslandEntry)?.stamp == 10)
    let partial = PreviewTimelineBuilder.buildPartialBlock(first: first)
    precondition((partial[0] as? _IslandEntry)?.stamp == 10)
    let accumulated = PreviewTimelineBuilder.buildPartialBlock(
        accumulated: partial,
        next: PreviewTimelineBuilder.buildExpression(late)
    )
    precondition(accumulated.count == 2)
    precondition((accumulated[1] as? _IslandEntry)?.stamp == 20)
    let array = PreviewTimelineBuilder.buildArray([first, [late]])
    precondition(array.count == 2)
    precondition((array[0] as? _IslandEntry)?.date == early.date)
}

func testWidgetPushHandlerRecordsProcessLocalToken() {
    let center = WidgetCenter.shared
    center.resetProcessLocalState()
    _RecordingPushHandler.box.info = nil
    _RecordingPushHandler.box.widgets = []

    let handler = _RecordingPushHandler()
    let widget = WidgetInfo(kind: "push.kind", family: .systemSmall)
    center.installCurrentConfigurations([widget])
    let token = WidgetPushInfo(token: Data([4, 5, 6]))
    center.deliverPushToken(token, to: handler)

    precondition(center.portableCurrentPushInfo?.token == Data([4, 5, 6]))
    precondition(_RecordingPushHandler.box.info?.token == Data([4, 5, 6]))
    precondition(_RecordingPushHandler.box.widgets.count == 1)
    precondition(_RecordingPushHandler.box.widgets[0].kind == "push.kind")
    center.resetProcessLocalState()
    precondition(center.portableCurrentPushInfo == nil)
}

func testSupportedActivityFamiliesEnvironmentKeyDefault() {
    precondition(SupportedActivityFamiliesEnvironmentKey.defaultValue.isEmpty)
    var values = EnvironmentValues()
    precondition(values.supportedActivityFamilies.isEmpty)
    values.supportedActivityFamilies = [.small, .medium]
    precondition(values.supportedActivityFamilies == [.small, .medium])
    typealias Value = SupportedActivityFamiliesEnvironmentKey.Value
    let stored: Value = [.medium]
    precondition(stored.contains(.medium))
}

func testWidgetInfoStoresConfiguration() {
    let intent = INIntent()
    let info = WidgetInfo(
        kind: "configured",
        family: .systemMedium,
        configuration: intent
    )
    precondition(info.configuration === intent)
    precondition(info.widgetConfigurationIntent(of: INIntent.self) === intent)
    let bare = WidgetInfo(kind: "bare", family: .systemSmall)
    precondition(bare.configuration == nil)
}

func testActivityConfigurationInvokesDynamicIslandWithContext() {
    ActivityViewHost.resetProcessLocalState()
    let attributes = _IslandAttributes(title: "bus")
    let configuration = ActivityConfiguration(
        for: _IslandAttributes.self,
        content: { context in
            Text(context.state.label)
        },
        dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.bottom) {
                        Text(context.attributes.title)
                    }
                },
                compactLeading: { Text(context.state.label) },
                compactTrailing: { Text("T") },
                minimal: { Text("M") }
            )
            .widgetURL(URL(string: "widget://activity/\(context.activityID)"))
        }
    )
    let context: ActivityViewContext<_IslandAttributes>
    do {
        context = try ActivityViewHost.makeContext(
            activityID: "live.9",
            attributes: attributes,
            state: _IslandAttributes.ContentState(label: "arriving")
        )
    } catch {
        preconditionFailure("activity context must construct")
    }
    let island = configuration.portableDynamicIsland(context)
    precondition(island.portableDescriptor.compactLeading == "arriving")
    precondition(island.portableDescriptor.widgetURL == URL(string: "widget://activity/live.9"))
    precondition(island.portableDescriptor.regions[0].position == .bottom)
    ActivityViewHost.resetProcessLocalState()
}
