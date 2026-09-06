import Foundation

/// Picker presentation settings. Timeout named constants follow Apple's
/// header prose (about 60s / 2 min / 5 min / unbounded). Exact Mach-O
/// payloads are unobserved; see oracle-questions.tsv.
open class ASPickerDisplaySettings: NSObject {
    /// Discovery-timeout newtype over `TimeInterval`.
    public struct DiscoveryTimeout: RawRepresentable, Hashable, Sendable {
        public var rawValue: TimeInterval

        public init(rawValue: TimeInterval) {
            self.rawValue = rawValue
        }

        /// About 60 seconds per Apple's header comment.
        public static let short = DiscoveryTimeout(rawValue: 60)

        /// About two minutes per Apple's header comment.
        public static let medium = DiscoveryTimeout(rawValue: 120)

        /// About five minutes per Apple's header comment.
        public static let long = DiscoveryTimeout(rawValue: 300)

        /// Does not time out until the app finishes discovery.
        public static let unbounded = DiscoveryTimeout(rawValue: .infinity)
    }

    /// Picker option bits. `filterDiscoveryResults` is `1 << 0` from pinned
    /// `ASPickerDisplaySettingsOptions`.
    public struct Options: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let filterDiscoveryResults = Options(rawValue: 1 << 0)
    }

    /// Apple's header documents the property default as 30 seconds.
    public static let defaultTimeoutSeconds: TimeInterval = 30

    public override init() {
        discoveryTimeout = DiscoveryTimeout(rawValue: Self.defaultTimeoutSeconds)
        super.init()
    }

    open class var `default`: ASPickerDisplaySettings {
        ASPickerDisplaySettings()
    }

    open var discoveryTimeout: DiscoveryTimeout
    open var options: Options = []
}
