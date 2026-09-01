import Foundation
import SwiftUI
import WidgetKit

private struct BundleEntry: TimelineEntry {
    let date: Date
}

private struct BundleProvider: TimelineProvider {
    func placeholder(in _: Context) -> BundleEntry { BundleEntry(date: .now) }

    func getSnapshot(
        in _: Context,
        completion: @escaping @Sendable (BundleEntry) -> Void
    ) {
        completion(BundleEntry(date: .now))
    }

    func getTimeline(
        in _: Context,
        completion: @escaping @Sendable (Timeline<BundleEntry>) -> Void
    ) {
        completion(Timeline(entries: [BundleEntry(date: .now)], policy: .never))
    }
}

struct LatestPostsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "latest", provider: BundleProvider()) { _ in
            Text("latest")
        }
    }
}

typealias HashtagPostsWidget = LatestPostsWidget
typealias ListsPostWidget = LatestPostsWidget
typealias MentionsWidget = LatestPostsWidget
typealias AccountWidget = LatestPostsWidget
