import Foundation

/// A handle for deleting and fetching web-usage history reported to Screen Time.
///
/// Construction validates a bundle identifier locally. Fetch always fails
/// closed: Linux has no Screen Time history store. Delete methods are inert
/// (they do not throw and do not invent a successful daemon round-trip).
open class STWebHistory: NSObject {
    /// Strongly typed Safari / browser profile identifier.
    ///
    /// Apple's overlay is an `NS_TYPED_EXTENSIBLE_ENUM` over `NSString`. No
    /// named cases are published; any string is a valid raw value.
    public struct ProfileIdentifier: RawRepresentable, Hashable, Sendable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let bundleIdentifier: String?
    public let profileIdentifier: ProfileIdentifier?

    /// Creates a history handle for `bundleIdentifier`.
    ///
    /// Throws `STScreenTimeError.invalidBundleIdentifier` when the string is
    /// empty or whitespace. A successful handle is not a live daemon session.
    public init(bundleIdentifier: String) throws {
        try screenTimeRequireNonemptyBundleIdentifier(bundleIdentifier)
        self.bundleIdentifier = bundleIdentifier
        self.profileIdentifier = nil
        super.init()
    }

    /// Creates a history handle for `bundleIdentifier` and an optional profile.
    public init(
        bundleIdentifier: String,
        profileIdentifier: ProfileIdentifier?
    ) throws {
        try screenTimeRequireNonemptyBundleIdentifier(bundleIdentifier)
        self.bundleIdentifier = bundleIdentifier
        self.profileIdentifier = profileIdentifier
        super.init()
    }

    /// Creates a history handle scoped only to `profileIdentifier`.
    ///
    /// Apple's overlay does not throw. Linux stores the identifier and still
    /// fail-closes every fetch.
    public init(profileIdentifier: ProfileIdentifier?) {
        self.bundleIdentifier = nil
        self.profileIdentifier = profileIdentifier
        super.init()
    }

    /// Requests deletion of every recorded URL. Linux has nothing to delete.
    open func deleteAllHistory() {}

    /// Requests deletion of URLs whose recorded time falls in `interval`.
    open func deleteHistory(during interval: DateInterval) {
        _ = interval
    }

    /// Requests deletion of history for `url`.
    open func deleteHistory(for url: URL) {
        _ = url
    }

    /// Fetches every recorded URL. Linux invokes `completionHandler` inline
    /// with `nil` URLs and `STScreenTimeError.unavailable`. Apple's callback
    /// queue is unobserved.
    open func fetchAllHistory(
        completionHandler: @escaping (Set<URL>?, (any Error)?) -> Void
    ) {
        completionHandler(nil, STScreenTimeError.unavailable)
    }

    /// Fetches URLs recorded during `interval`. Linux never suspends and
    /// always throws `STScreenTimeError.unavailable`.
    open func fetchHistory(during interval: DateInterval) async throws -> Set<URL> {
        try linuxFetchHistory(during: interval)
    }

    /// Completion-handler twin of the async fetch. Same fail-closed error,
    /// delivered inline.
    open func fetchHistory(
        during interval: DateInterval,
        completionHandler: @escaping (Set<URL>?, (any Error)?) -> Void
    ) {
        completionHandler(nil, STScreenTimeError.unavailable)
        _ = interval
    }

    func linuxFetchHistory(during interval: DateInterval) throws -> Set<URL> {
        _ = interval
        throw STScreenTimeError.unavailable
    }
}
