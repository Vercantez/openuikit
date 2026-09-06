// Fail-closed Glean for mozilla-mobile/focus-ios a2832521.
// Call shapes grepped from Blockzilla (focus-e2e.md wave 1d: 92 GleanMetrics
// diagnostics against the Settings-only stub). Not Mozilla Glean: every
// recorder is a no-op. Generated Metrics.swift / AppNimbus.swift are absent
// from the pin (`expected_generated_missing` in focus-main-sources.json).

import Foundation

@_exported import UIKit

public final class Glean {
    public static let shared = Glean()
    public func setUploadEnabled(_ enabled: Bool) { _ = enabled }
    public func handleCustomUrl(url: URL) { _ = url }
    public func initialize(
        uploadEnabled: Bool,
        configuration: Configuration,
        buildInfo: BuildInfo
    ) {
        _ = (uploadEnabled, configuration, buildInfo)
    }
}

public struct Configuration {
    public var channel: String
    public init(channel: String) { self.channel = channel }
}

public struct BuildInfo {
    public init() {}
}

public struct CounterMetric {
    public init() {}
    public func add(_ amount: Int64 = 1) { _ = amount }
}

public struct StringMetric {
    public init() {}
    public func set(_ value: String) { _ = value }
}

public struct BooleanMetric {
    public init() {}
    public func set(_ value: Bool) { _ = value }
}

public struct QuantityMetric {
    public init() {}
    public func set(_ value: Int64) { _ = value }
}

public struct LabeledCounter {
    public init() {}
    public subscript(_ key: String) -> CounterMetric {
        _ = key
        return CounterMetric()
    }
}

public struct EventMetric<Extra> {
    public init() {}
    public func record(_ extra: Extra) { _ = extra }
    public func record() {}
}

    public enum GleanMetrics {
    public enum GleanBuild {
        public static let info = BuildInfo()
    }

    public enum SettingsScreen {
        public static let setAsDefaultBrowserPressed = CounterMetric()
        public static let autocompleteDomainAdded = CounterMetric()
    }

    public enum ShowSearchSuggestions {
        public struct ChangedFromSettingsExtra {
            public var isEnabled: Bool
            public init(isEnabled: Bool) { self.isEnabled = isEnabled }
        }
        public static let changedFromSettings = EventMetric<ChangedFromSettingsExtra>()
        public static let disabledFromPanel = EventMetric<Void>()
        public static let enabledFromPanel = EventMetric<Void>()
    }

    /// OverlayView.swift:464 searchTapped / suggestionTapped.
    /// MEASURED Blockzilla 2026-09-06: `GleanMetrics` has no member
    /// `SearchSuggestions` (5 unique sites).
    public enum SearchSuggestions {
        public struct SearchTappedExtra {
            public var engineName: String
            public init(engineName: String) { self.engineName = engineName }
        }
        public struct SuggestionTappedExtra {
            public var engineName: String
            public init(engineName: String) { self.engineName = engineName }
        }
        public static let searchTapped = EventMetric<SearchTappedExtra>()
        public static let suggestionTapped = EventMetric<SuggestionTappedExtra>()
        public static let autocompleteArrowTapped = EventMetric<Void>()
    }

    public enum Onboarding {
        public struct CardViewExtra {
            public var cardType: String
            public init(cardType: String) { self.cardType = cardType }
        }
        public struct CloseTapExtra {
            public var cardType: String
            public init(cardType: String) { self.cardType = cardType }
        }
        public struct PrimaryButtonTapExtra {
            public var cardType: String
            public init(cardType: String) { self.cardType = cardType }
        }
        public static let cardView = EventMetric<CardViewExtra>()
        public static let closeTap = EventMetric<CloseTapExtra>()
        public static let primaryButtonTap = EventMetric<PrimaryButtonTapExtra>()
    }

    public enum DefaultBrowserOnboarding {
        public static let goToSettingsPressed = CounterMetric()
        public static let skipButtonTapped = EventMetric<Void>()
    }

    public enum App {
        public static let keyboardType = StringMetric()
        public static let openedAsDefaultBrowser = CounterMetric()
    }

    public enum BrowserSearch {
        public static let inContent = LabeledCounter()
        public static let withAds = LabeledCounter()
        public static let adClicks = LabeledCounter()
        public static let searchCount = LabeledCounter()
    }

    public enum UrlInteraction {
        public static let pasteAndGo = EventMetric<Void>()
        public static let dragStarted = EventMetric<Void>()
        public static let dropEnded = EventMetric<Void>()
    }

    public enum TrackingProtection {
        public struct TrackingProtectionChangedExtra {
            public var isEnabled: Bool
            public init(isEnabled: Bool) { self.isEnabled = isEnabled }
        }
        public static let trackingProtectionChanged = EventMetric<TrackingProtectionChangedExtra>()
        public struct TrackerSettingChangedExtra {
            public var isEnabled: Bool
            public var sourceOfChange: String
            public var trackerChanged: String
            public init(isEnabled: Bool, sourceOfChange: String, trackerChanged: String) {
                self.isEnabled = isEnabled
                self.sourceOfChange = sourceOfChange
                self.trackerChanged = trackerChanged
            }
        }
        /// TrackingProtectionViewController.swift:118. MEASURED Blockzilla
        /// 2026-09-06.
        public static let trackerSettingChanged = EventMetric<TrackerSettingChangedExtra>()
        public static let hasEverChangedEtp = BooleanMetric()
        public static let toolbarShieldClicked = CounterMetric()
        public static let hasAdvertisingBlocked = BooleanMetric()
        public static let hasAnalyticsBlocked = BooleanMetric()
        public static let hasContentBlocked = BooleanMetric()
        public static let hasSocialBlocked = BooleanMetric()
    }

    public enum Webview {
        public static let fail = EventMetric<Void>()
        public static let failProvisional = EventMetric<Void>()
    }

    public enum Browser {
        public static let totalUriCount = CounterMetric()
        public static let pdfViewerUsed = CounterMetric()
    }

    public enum BrowserMenu {
        public struct BrowserMenuActionExtra {
            public var item: String
            public init(item: String) { self.item = item }
        }
        public static let browserMenuAction = EventMetric<BrowserMenuActionExtra>()
    }

    public enum Shortcuts {
        public static let shortcutAddedCounter = CounterMetric()
        public static let shortcutRemovedCounter = LabeledCounter()
        public static let shortcutOpenedCounter = CounterMetric()
        public static let shortcutsOnHomeNumber = QuantityMetric()
    }

    public enum Siri {
        public static let eraseInBackground = EventMetric<Void>()
        public static let eraseAndOpen = EventMetric<Void>()
        public static let openFavoriteSite = EventMetric<Void>()
    }

    public enum Search {
        public static let defaultEngine = StringMetric()
    }

    public enum MozillaProducts {
        public static let hasFirefoxInstalled = BooleanMetric()
    }

    public enum Preferences {
        public static let userTheme = StringMetric()
    }
}
