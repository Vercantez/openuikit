import Foundation
@_spi(OpenUIKitHost)
import JournalingSuggestions

func testPickerLabeledInit() {
    let picker = JournalingSuggestionsPicker(label: { Text("Pick") }) { _ in }
    precondition(picker._hasCompletionHandler)
    let body = picker.body
    precondition(body.storage == "Pick")
}

func testPickerTitleInits() {
    let keyed = JournalingSuggestionsPicker(LocalizedStringKey("Choose"), onCompletion: { _ in })
    precondition(keyed._hasCompletionHandler)
    precondition(keyed.body.storage == "Choose")
    let stringy = JournalingSuggestionsPicker("Select", onCompletion: { _ in })
    precondition(stringy._hasCompletionHandler)
    precondition(stringy.body.storage == "Select")
}

func testViewPickerModifiers() {
    JournalingSuggestionsHost.reset()
    var presented = false
    let base = EmptyView()
    _ = base.journalingSuggestionsPicker(isPresented: Binding(get: { presented }, set: { presented = $0 })) { _ in }
    precondition(JournalingSuggestionsHost.lastPickerRequest?.hasToken == false)
    precondition(JournalingSuggestionsHost.lastPickerRequest?.isPresentedValue == false)

    presented = true
    let token = JournalingSuggestionPresentationToken(suggestionIdentifier: UUID())
    _ = base.journalingSuggestionsPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        journalingSuggestionToken: token
    ) { _ in }
    precondition(JournalingSuggestionsHost.lastPickerRequest?.hasToken == true)
    precondition(JournalingSuggestionsHost.lastPickerRequest?.isPresentedValue == true)

    _ = base.journalingSuggestionsPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        journalingSuggestionToken: nil
    ) { _ in }
    precondition(JournalingSuggestionsHost.lastPickerRequest?.hasToken == false)
}

func testImageInequality() {
    let a = Image("one")
    let b = Image("two")
    let c = Image("one")
    precondition(a != b)
    precondition((a != c) == false)
    precondition(a == c)
}

func testUnavailableError() {
    let error = JournalingSuggestionsUnavailable.linuxHost(operation: "picker")
    precondition(error == .linuxHost(operation: "picker"))
    precondition(error != .linuxHost(operation: "other"))
}

func testFoundationDateThroughSuggestion() {
    let stamp = Date(timeIntervalSince1970: 1_111_111_111)
    precondition(String(reflecting: type(of: stamp)).hasPrefix("Foundation.") || type(of: stamp) == Date.self)
    let suggestion = JournalingSuggestion(
        title: "Stamp",
        date: DateInterval(start: stamp, duration: 1),
        items: []
    )
    precondition(suggestion.date?.start == stamp)
}
