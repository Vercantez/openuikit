import Foundation

public struct JournalingSuggestionPresentationToken: Equatable, Sendable {
    public let suggestionIdentifier: UUID?

    public init(suggestionIdentifier: UUID?) {
        self.suggestionIdentifier = suggestionIdentifier
    }

    public static func == (
        a: JournalingSuggestionPresentationToken,
        b: JournalingSuggestionPresentationToken
    ) -> Bool {
        a.suggestionIdentifier == b.suggestionIdentifier
    }
}

public final class JournalingSuggestionsConfiguration: @unchecked Sendable {
    public enum NotificationSchedule: Equatable, Hashable, Sendable {
        case off
        case smart
        case custom
    }

    public private(set) var notificationSchedule: NotificationSchedule?

    /// Linux has no journaling daemon. `notificationSchedule` stays `nil`
    /// until a host test injects a value. Apple never grants a live schedule
    /// on this host.
    public init() {
        notificationSchedule = nil
    }

    @_spi(OpenUIKitHost)
    public func _hostSetNotificationSchedule(_ value: NotificationSchedule?) {
        notificationSchedule = value
    }
}
