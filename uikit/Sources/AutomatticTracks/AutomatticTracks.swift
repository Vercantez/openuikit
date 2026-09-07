import Foundation

public struct TracksUser {
    public let userID: String?
    public let email: String?
    public let username: String?

    public init(userID: String?, email: String?, username: String?) {
        self.userID = userID
        self.email = email
        self.username = username
    }

    public init(email: String) {
        self.userID = nil
        self.email = email
        self.username = nil
    }
}

public enum PerformanceTracking {
    case disabled
}

public protocol CrashLoggingDataProvider {
    var sentryDSN: String { get }
    var userHasOptedOut: Bool { get }
    var buildType: String { get }
    var currentUser: TracksUser? { get }
}

public final class CrashLogging {
    private static var didLogUnavailable = false
    private let dataProvider: CrashLoggingDataProvider

    public init(dataProvider: CrashLoggingDataProvider) {
        self.dataProvider = dataProvider
    }

    public func start() throws -> CrashLogging {
        logUnavailable()
        throw TracksUnavailableError.crashLogging
    }

    public func setNeedsDataRefresh() {
        logUnavailable()
    }

    public func crash() {
        logUnavailable()
    }

    public func logError(_ error: Error) {
        _ = error
        logUnavailable()
    }

    private func logUnavailable() {
        guard !Self.didLogUnavailable else { return }
        Self.didLogUnavailable = true
        NSLog("[OpenUIKit] AutomatticTracks crash logging is unavailable; no report or network success is fabricated")
        _ = dataProvider
    }
}

public enum TracksUnavailableError: Error {
    case crashLogging
}
