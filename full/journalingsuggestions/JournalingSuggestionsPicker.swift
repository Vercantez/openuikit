import Foundation

public struct JournalingSuggestionsPicker<Label: View>: View {
    public typealias Body = Label

    private let label: Label
    private let hasCompletion: Bool

    public var body: Label { label }

    @_spi(OpenUIKitHost)
    public var _hasCompletionHandler: Bool { hasCompletion }

    public init(
        @ViewBuilder label: () -> Label,
        onCompletion: @escaping (JournalingSuggestion) async -> Void
    ) {
        self.label = label()
        self.hasCompletion = true
        _ = onCompletion
    }
}

extension JournalingSuggestionsPicker where Label == Text {
    public init(
        _ title: LocalizedStringKey,
        onCompletion: @escaping (JournalingSuggestion) async -> Void
    ) {
        self.init(label: { Text(title) }, onCompletion: onCompletion)
    }

    public init<S: StringProtocol>(
        _ title: S,
        onCompletion: @escaping (JournalingSuggestion) async -> Void
    ) {
        self.init(label: { Text(String(title)) }, onCompletion: onCompletion)
    }
}

extension View {
    public func journalingSuggestionsPicker(
        isPresented: Binding<Bool>,
        onCompletion: @escaping (JournalingSuggestion) async -> Void
    ) -> Self {
        _ = onCompletion
        JournalingSuggestionsHost.recordPickerRequest(
            hasToken: false,
            isPresentedValue: isPresented.wrappedValue
        )
        return self
    }

    public func journalingSuggestionsPicker(
        isPresented: Binding<Bool>,
        journalingSuggestionToken: JournalingSuggestionPresentationToken?,
        onCompletion: @escaping (JournalingSuggestion) async -> Void
    ) -> Self {
        _ = onCompletion
        JournalingSuggestionsHost.recordPickerRequest(
            hasToken: journalingSuggestionToken != nil,
            isPresentedValue: isPresented.wrappedValue
        )
        return self
    }
}
