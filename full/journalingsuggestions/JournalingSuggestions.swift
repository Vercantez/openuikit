import Foundation

/// Isolated-host presentation recorder. Linux never mounts Apple's Journaling
/// Suggestions picker chrome or talks to the journaling daemon.
public enum JournalingSuggestionsHost {
    public struct PickerRequest: Equatable, Sendable {
        public var hasToken: Bool
        public var isPresentedValue: Bool
    }

    private static let lock = NSLock()
    private static var lastRequest: PickerRequest?

    public static var lastPickerRequest: PickerRequest? {
        lock.withLock { lastRequest }
    }

    public static func recordPickerRequest(hasToken: Bool, isPresentedValue: Bool) {
        lock.withLock {
            lastRequest = PickerRequest(hasToken: hasToken, isPresentedValue: isPresentedValue)
        }
    }

    public static func reset() {
        lock.withLock { lastRequest = nil }
    }
}
