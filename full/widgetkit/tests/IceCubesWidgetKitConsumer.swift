import AppIntents
import Foundation
import SwiftUI
import WidgetKit

private struct AccountConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Account configuration"
}

private struct AccountEntry: TimelineEntry, Sendable {
    let date: Date
    let title: String
}

private struct AccountProvider: AppIntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> AccountEntry {
        AccountEntry(date: .now, title: "Placeholder")
    }

    func snapshot(for _: AccountConfiguration, in _: Context) async -> AccountEntry {
        AccountEntry(date: .now, title: "Snapshot")
    }

    func timeline(
        for _: AccountConfiguration,
        in _: Context
    ) async -> Timeline<AccountEntry> {
        Timeline(
            entries: [AccountEntry(date: .now, title: "Timeline")],
            policy: .atEnd
        )
    }
}

private struct IceCubesAccountWidget: Widget {
    let kind = "AccountWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AccountConfiguration.self,
            provider: AccountProvider()
        ) { entry in
            Text(entry.title)
                .containerBackground(Color.blue, for: .widget)
                .widgetURL(URL(string: "icecubes://account"))
                .widgetAccentable()
        }
        .configurationDisplayName("Account")
        .description("Show information about your account")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct LegacyProvider: TimelineProvider {
    func placeholder(in _: Context) -> AccountEntry {
        AccountEntry(date: .now, title: "Placeholder")
    }

    func getSnapshot(
        in _: Context,
        completion: @escaping @Sendable (AccountEntry) -> Void
    ) {
        completion(AccountEntry(date: .now, title: "Snapshot"))
    }

    func getTimeline(
        in _: Context,
        completion: @escaping @Sendable (Timeline<AccountEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [AccountEntry(date: .now, title: "Timeline")],
                policy: .never
            )
        )
    }
}

private struct StaticTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StaticTimeline", provider: LegacyProvider()) {
            Text($0.title)
        }
        .contentMarginsDisabled()
    }
}
