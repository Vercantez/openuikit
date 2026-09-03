import Foundation
import WidgetKit

func widgetKitDependencyIdentityProbe() {
    let date = Date(timeIntervalSinceReferenceDate: 100)
    let relevance = TimelineEntryRelevance(score: 0.5, duration: 15)
    precondition(relevance.score == 0.5)
    precondition(relevance.duration == 15)

    struct Entry: TimelineEntry {
        var date: Date
        var relevance: TimelineEntryRelevance?
    }
    let timeline = Timeline(
        entries: [Entry(date: date, relevance: relevance)],
        policy: .after(date)
    )
    precondition(timeline.entries[0].date == date)
    precondition(timeline.policy == .after(date))

    let center = WidgetCenter()
    center.reloadAllTimelines()
    var received: [WidgetInfo]?
    center.getCurrentConfigurations { result in
        received = try? result.get()
    }
    precondition(received?.isEmpty == true)
    _ = WidgetFamily.systemSmall
    _ = WidgetCenter.shared
    _ = date
}

#if WIDGETKIT_IDENTITY_MAIN
widgetKitDependencyIdentityProbe()
print("WIDGETKIT_DEPENDENCY_IDENTITY_OK")
#endif
