// A NO-OP Glean, so focus-ios can be compiled from source without Mozilla's
// prebuilt Glean.xcframework.
//
// WHY A STUB IS THE RIGHT ANSWER HERE, AND WHY THAT IS NOT A GENERAL LICENCE.
// The real package is a `.binaryTarget` — a Rust static library with no source
// to recompile — so "port it" is not on the table. What makes stubbing SOUND
// rather than convenient is what Glean DOES: every call in focus-ios is
// `record`, `add` or `set`, i.e. WRITE-ONLY telemetry. Measured over the app
// (see full/ladder/focus-ios-scope-2026-08-28.md): 48 distinct call paths, and
// NOT ONE of them reads a value back. A function whose entire contract is
// "remember that this happened, elsewhere" can be a no-op without any screen or
// any piece of app state differing — which is exactly the deny-list taxonomy's
// "stub-able" class, and it is a claim about THIS surface, not about stubs.
//
// THE ONE PLACE THAT WOULD NOT BE SAFE, and it does not exist here: a metric
// whose value the app reads back and branches on. If such a call ever appears,
// it must NOT get a plausible default from this file — it belongs in the
// die-loudly class, like the WebKit browsing surface next door.
//
// SURFACE THIS FILE COVERS (all measured, none invented):
//   Glean.shared.initialize / setUploadEnabled / handleCustomUrl
//   Configuration(channel:)                       — passed to initialize
//   GleanMetrics, 17 categories, 45 metric paths
//   4 event-extra structs: BrowserMenuActionExtra, CardViewExtra,
//                          CloseTapExtra, PrimaryButtonTapExtra
//   labeled counters used by subscript: searchCount, inContent, withAds,
//                          adClicks, shortcutRemovedCounter

import Foundation

// MARK: - Metric kinds

public final class CounterMetricType {
    public init() {}
    public func add(_ amount: Int32 = 1) {}
}

public final class BooleanMetricType {
    public init() {}
    public func set(_ value: Bool) {}
}

public final class StringMetricType {
    public init() {}
    public func set(_ value: String) {}
}

public final class QuantityMetricType {
    public init() {}
    public func set(_ value: Int64) {}
}

/// Glean's labeled metrics are reached by subscript: `searchCount["label"].add()`.
/// A fresh no-op child per lookup is fine precisely because nothing is stored.
public final class LabeledMetricType<T> {
    private let make: () -> T
    public init(_ make: @escaping () -> T) { self.make = make }
    public subscript(label: String) -> T { make() }
}

/// Events come in two shapes in this app — `record()` and `record(SomeExtra(...))`
/// — and both are present on the same metrics, so both overloads exist here.
public final class EventMetricType<Extra> {
    public init() {}
    public func record() {}
    public func record(_ extra: Extra) {}
}

public struct NoExtras {
    public init() {}
}

// MARK: - The client object

public struct Configuration {
    public let channel: String?
    public init(channel: String? = nil) { self.channel = channel }
}

public struct BuildInfo {
    public init() {}
}

public final class Glean {
    public static let shared = Glean()
    private init() {}

    public func initialize(uploadEnabled: Bool,
                           configuration: Configuration = Configuration(),
                           buildInfo: BuildInfo) {}
    public func setUploadEnabled(_ enabled: Bool) {}
    public func handleCustomUrl(url: URL) {}
}

// MARK: - The generated metric tree
//
// Real Glean generates this from metrics.yaml at build time. Every name below
// was harvested from the app's own call sites, so this tree is exactly as large
// as focus-ios needs and no larger; a name the app does not use is a name that
// cannot silently diverge from Mozilla's definition.

public enum GleanMetrics {
    public enum GleanBuild {
        public static let info = BuildInfo()
    }

    public enum App {
        public static let keyboardType = StringMetricType()
        public static let openedAsDefaultBrowser = CounterMetricType()
    }

    public enum Browser {
        public static let pdfViewerUsed = CounterMetricType()
        public static let totalUriCount = CounterMetricType()
    }

    public enum BrowserMenu {
        public struct BrowserMenuActionExtra {
            public let item: String
            public init(item: String) { self.item = item }
        }
        public static let browserMenuAction = EventMetricType<BrowserMenuActionExtra>()
    }

    public enum BrowserSearch {
        public static let searchCount = LabeledMetricType { CounterMetricType() }
        public static let inContent = LabeledMetricType { CounterMetricType() }
        public static let withAds = LabeledMetricType { CounterMetricType() }
        public static let adClicks = LabeledMetricType { CounterMetricType() }
    }

    public enum DefaultBrowserOnboarding {
        public static let goToSettingsPressed = CounterMetricType()
        public static let skipButtonTapped = EventMetricType<NoExtras>()
    }

    public enum MozillaProducts {
        public static let hasFirefoxInstalled = BooleanMetricType()
    }

    public enum Onboarding {
        public struct CardViewExtra {
            public let cardType: String
            public init(cardType: String) { self.cardType = cardType }
        }
        public struct CloseTapExtra {
            public let cardType: String
            public init(cardType: String) { self.cardType = cardType }
        }
        public struct PrimaryButtonTapExtra {
            public let cardType: String
            public init(cardType: String) { self.cardType = cardType }
        }
        public static let cardView = EventMetricType<CardViewExtra>()
        public static let closeTap = EventMetricType<CloseTapExtra>()
        public static let primaryButtonTap = EventMetricType<PrimaryButtonTapExtra>()
    }

    public enum Preferences {
        public static let userTheme = StringMetricType()
    }

    public enum Search {
        public static let defaultEngine = StringMetricType()
    }

    public enum SettingsScreen {
        public static let autocompleteDomainAdded = CounterMetricType()
        public static let setAsDefaultBrowserPressed = CounterMetricType()
    }

    public enum Shortcuts {
        public static let shortcutAddedCounter = CounterMetricType()
        public static let shortcutOpenedCounter = CounterMetricType()
        public static let shortcutRemovedCounter = LabeledMetricType { CounterMetricType() }
        public static let shortcutsOnHomeNumber = QuantityMetricType()
    }

    public enum ShowSearchSuggestions {
        public static let enabledFromPanel = EventMetricType<NoExtras>()
        public static let disabledFromPanel = EventMetricType<NoExtras>()
    }

    public enum Siri {
        public static let eraseInBackground = EventMetricType<NoExtras>()
        public static let eraseAndOpen = EventMetricType<NoExtras>()
        public static let openFavoriteSite = EventMetricType<NoExtras>()
    }

    public enum TrackingProtection {
        public static let hasAdvertisingBlocked = BooleanMetricType()
        public static let hasAnalyticsBlocked = BooleanMetricType()
        public static let hasContentBlocked = BooleanMetricType()
        public static let hasEverChangedEtp = BooleanMetricType()
        public static let hasSocialBlocked = BooleanMetricType()
        public static let toolbarShieldClicked = CounterMetricType()
        public static let trackingProtectionChanged = EventMetricType<NoExtras>()
    }

    public enum UrlInteraction {
        public static let pasteAndGo = EventMetricType<NoExtras>()
        public static let dragStarted = EventMetricType<NoExtras>()
        public static let dropEnded = EventMetricType<NoExtras>()
    }

    public enum Webview {
        public static let fail = EventMetricType<NoExtras>()
        public static let failProvisional = EventMetricType<NoExtras>()
    }
}
