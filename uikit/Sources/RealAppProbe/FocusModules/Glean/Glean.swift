// Harness stub for mozilla-mobile/focus-ios's Glean import.
// SettingsViewController records telemetry in didSelect / toggle handlers
// that the real-app capture never drives; these are no-ops.

public final class Glean {
    public static let shared = Glean()
    public func setUploadEnabled(_ enabled: Bool) { _ = enabled }
}

public enum GleanMetrics {
    public enum SettingsScreen {
        public static let setAsDefaultBrowserPressed = CounterMetric()
    }

    public enum ShowSearchSuggestions {
        public struct ChangedFromSettingsExtra {
            public var isEnabled: Bool
            public init(isEnabled: Bool) { self.isEnabled = isEnabled }
        }
        public static let changedFromSettings = EventMetric<ChangedFromSettingsExtra>()
    }
}

public struct CounterMetric {
    public init() {}
    public func add() {}
}

public struct EventMetric<Extra> {
    public init() {}
    public func record(_ extra: Extra) { _ = extra }
}
