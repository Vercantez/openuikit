@_exported import Dispatch
@_exported import Foundation

/// Linux starting point for Apple's public `ScreenTime` module.
///
/// Value types, local webpage-usage flags, bundle-identifier validation, and
/// the configuration-observer start/stop machine are real. There is no Screen
/// Time daemon, Family Sharing child-restriction service, or usage-reporting
/// agent on Linux: fetches, live configuration delivery, and URL blocking
/// fail closed. See `README.md`.
enum ScreenTimeModuleMarker {
    static let name = "ScreenTime"
}

/// Fail-closed errors for Linux `ScreenTime`.
///
/// Apple's NSError domain and integer codes are unobserved; this type is a
/// local Swift error, not a Darwin overlay. See `oracle-questions.tsv`.
public struct STScreenTimeError: Error, Equatable, Hashable, Sendable, LocalizedError {
    public enum Code: Equatable, Hashable, Sendable {
        /// No Screen Time agent, daemon, or entitlement is available.
        case unavailable
        /// The bundle identifier is empty or contains only whitespace.
        case invalidBundleIdentifier
    }

    public var code: Code

    public static let unavailable = STScreenTimeError(code: .unavailable)
    public static let invalidBundleIdentifier = STScreenTimeError(
        code: .invalidBundleIdentifier
    )

    public var errorDescription: String? {
        switch code {
        case .unavailable:
            return "Screen Time is unavailable on this platform."
        case .invalidBundleIdentifier:
            return "The bundle identifier is empty or invalid."
        }
    }
}

func screenTimeRequireNonemptyBundleIdentifier(_ bundleIdentifier: String) throws {
    if bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw STScreenTimeError.invalidBundleIdentifier
    }
}

/// Linux host-test control. Hidden from ordinary `import ScreenTime` clients
/// and not part of Apple's public ScreenTime surface.
@_spi(OpenUIKitHost)
public enum ScreenTimeHostControl {
    /// Snapshot whose `enforcesChildRestrictions` is always `false`.
    public static func failClosedConfiguration() -> STScreenTimeConfiguration {
        STScreenTimeConfiguration(enforcesChildRestrictions: false)
    }

    /// Synchronous twin of `STWebHistory.fetchHistory(during:)`. The async
    /// method never suspends; it always throws this error.
    public static func fetchHistorySync(
        _ history: STWebHistory,
        during interval: DateInterval
    ) throws -> Set<URL> {
        try history.linuxFetchHistory(during: interval)
    }

    public static var linuxFetchError: STScreenTimeError { .unavailable }
}
