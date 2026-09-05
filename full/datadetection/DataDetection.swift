@_exported import Foundation

/// Linux starting point for Apple's public `DataDetection` module.
///
/// Nested detector types live on this namespace enum. Exact Apple
/// `MatchType` bit payloads are unobserved; Linux uses sequential flags in
/// API-digester child order. Text scanning is a local, deterministic parser,
/// not Apple's DataDetectors daemon.
public enum DataDetector: Sendable {
    /// Bit flags selecting which semantic families to scan for.
    public struct MatchType: OptionSet, Sendable {
        public let rawValue: UInt64

        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }

        /// Sequential flag order matches the Xcode 26.1 API-digester children.
        public static let link = MatchType(rawValue: 1 << 0)
        public static let emailAddress = MatchType(rawValue: 1 << 1)
        public static let phoneNumber = MatchType(rawValue: 1 << 2)
        public static let postalAddress = MatchType(rawValue: 1 << 3)
        public static let calendarEvent = MatchType(rawValue: 1 << 4)
        public static let moneyAmount = MatchType(rawValue: 1 << 5)
        public static let measurement = MatchType(rawValue: 1 << 6)
        public static let flightNumber = MatchType(rawValue: 1 << 7)
        public static let shipmentTrackingNumber = MatchType(rawValue: 1 << 8)
        public static let paymentIdentifier = MatchType(rawValue: 1 << 9)

        public static let all: MatchType = [
            .link,
            .emailAddress,
            .phoneNumber,
            .postalAddress,
            .calendarEvent,
            .moneyAmount,
            .measurement,
            .flightNumber,
            .shipmentTrackingNumber,
            .paymentIdentifier,
        ]
    }

    /// Scanning hints. Defaults are all `nil` (no document context).
    public struct Options: Sendable {
        public var documentDate: Date?
        public var documentRegion: Locale.Region?
        public var documentTimeZone: TimeZone?
        public var documentLanguageCode: Locale.LanguageCode?

        public init() {
            documentDate = nil
            documentRegion = nil
            documentTimeZone = nil
            documentLanguageCode = nil
        }
    }

    /// Linux helper that collects matches without an async run loop.
    /// The Apple `StringProtocol.dataDetectorMatches` overlay returns an
    /// `AsyncSequence` wrapping this same synchronous scan.
    public static func collectMatches(
        in text: String,
        types: MatchType = .all,
        options: Options = Options()
    ) -> [Match] {
        DataDetectionScanner.scan(text: text, types: types, options: options)
    }
}
