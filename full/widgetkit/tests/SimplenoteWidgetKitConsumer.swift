import Foundation
import Intents
import SwiftUI
import WidgetKit

private final class NoteWidgetIntent: INIntent, @unchecked Sendable {}

private struct NoteEntry: TimelineEntry, Sendable {
    let date: Date
    let title: String
}

private struct NoteProvider: IntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> NoteEntry {
        NoteEntry(date: .now, title: "Placeholder")
    }

    func getSnapshot(
        for _: NoteWidgetIntent,
        in _: Context,
        completion: @escaping (NoteEntry) -> Void
    ) {
        completion(NoteEntry(date: .now, title: "Snapshot"))
    }

    func getTimeline(
        for _: NoteWidgetIntent,
        in _: Context,
        completion: @escaping (Timeline<NoteEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [NoteEntry(date: .now, title: "Timeline")],
                policy: .atEnd
            )
        )
    }
}

private struct SimplenoteShapedWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: "NoteWidget",
            intent: NoteWidgetIntent.self,
            provider: NoteProvider()
        ) { entry in
            Text(entry.title)
                .containerBackground(for: .widget) {
                    Color.clear
                }
                .widgetURL(URL(string: "simplenote://note"))
        }
        .configurationDisplayName("Note")
        .description("Get quick access to one of your notes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
