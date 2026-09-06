import Foundation
import JournalingSuggestions

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation
/// values through public JournalingSuggestions APIs; this file is not
/// compiled by the sealed host gate.
func journalingSuggestionsDependencyIdentityProbe() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(type(of: stamp) == Date.self)
    precondition(!String(reflecting: type(of: stamp)).hasPrefix("JournalingSuggestions."))

    let interval = DateInterval(start: stamp, duration: 60)
    precondition(type(of: interval) == DateInterval.self)

    let uuid = UUID(uuidString: "00000000-0000-4000-8000-000000000000")!
    precondition(type(of: uuid) == UUID.self)

    let url = URL(fileURLWithPath: "/tmp/photo.jpg")
    precondition(type(of: url) == URL.self)

    let attributed = AttributedString("hello")
    precondition(type(of: attributed) == AttributedString.self)

    _ = JournalingSuggestionsConfiguration()
    _ = JournalingSuggestionPresentationToken(suggestionIdentifier: uuid)
    _ = JournalingSuggestionsConfiguration.NotificationSchedule.off
}

#if JOURNALINGSUGGESTIONS_IDENTITY_MAIN
journalingSuggestionsDependencyIdentityProbe()
print("JOURNALINGSUGGESTIONS_DEPENDENCY_IDENTITY_OK")
#endif
