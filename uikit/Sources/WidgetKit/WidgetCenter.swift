// WidgetCenter for route (b) on the iOS target. The curated iOS SDK drops
// Apple's WidgetKit (it imports SwiftUI), and NetNewsWire
// Shared/Widget/WidgetDataEncoder.swift:102-120 asks WidgetCenter to reload
// its widgets' timelines. The port runs an app with no widget extension and
// no widget host, which is exactly the state measured here:
//
// MEASURED iPhone 16 / iOS 26.1, app without a widget extension
// (Tools/oracle2/widgetcenterprobe/transcript-ios26.1.txt): `shared` is one
// instance; reloadTimelines(ofKind:) and reloadAllTimelines() return with no
// effect; getCurrentConfigurations delivers .success([]) off the main
// thread; the async currentConfigurations() returns [].
//
// The Linux guest's full framework is full/widgetkit (a separate dylib).

import Dispatch

public struct WidgetInfo: Hashable, Sendable {
    public let kind: String
}

public final class WidgetCenter: @unchecked Sendable {
    public static let shared = WidgetCenter()
    private let queue = DispatchQueue(label: "openuikit.widgetcenter")

    private init() {}

    public func reloadTimelines(ofKind kind: String) { _ = kind }
    public func reloadAllTimelines() {}
    public func invalidateConfigurationRecommendations() {}

    public func getCurrentConfigurations(_ completion: @escaping @Sendable (Result<[WidgetInfo], any Error>) -> Void) {
        queue.async { completion(.success([])) }
    }

    public func currentConfigurations() async throws -> [WidgetInfo] { [] }
}
