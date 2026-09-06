import Foundation
@_spi(OpenUIKitHost)
import JournalingSuggestions

func testNotificationScheduleCases() {
    let cases: [JournalingSuggestionsConfiguration.NotificationSchedule] = [
        .off, .smart, .custom
    ]
    precondition(cases[0] == .off)
    precondition(cases[1] == .smart)
    precondition(cases[2] == .custom)
    precondition(cases[0] != cases[1])
}

func testNotificationScheduleHashing() {
    let a = JournalingSuggestionsConfiguration.NotificationSchedule.smart
    let b = JournalingSuggestionsConfiguration.NotificationSchedule.smart
    let c = JournalingSuggestionsConfiguration.NotificationSchedule.custom
    precondition(a == b)
    precondition(a != c)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(a.hashValue == b.hashValue)
}

func testConfigurationFailClosed() {
    let configuration = JournalingSuggestionsConfiguration()
    precondition(configuration.notificationSchedule == nil)
    configuration._hostSetNotificationSchedule(.off)
    precondition(configuration.notificationSchedule == .off)
    configuration._hostSetNotificationSchedule(.smart)
    precondition(configuration.notificationSchedule == .smart)
    configuration._hostSetNotificationSchedule(nil)
    precondition(configuration.notificationSchedule == nil)
}

func testPresentationToken() {
    let id = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    let token = JournalingSuggestionPresentationToken(suggestionIdentifier: id)
    let same = JournalingSuggestionPresentationToken(suggestionIdentifier: id)
    let empty = JournalingSuggestionPresentationToken(suggestionIdentifier: nil)
    precondition(token.suggestionIdentifier == id)
    precondition(token == same)
    precondition(token != empty)
    precondition(empty.suggestionIdentifier == nil)
}
