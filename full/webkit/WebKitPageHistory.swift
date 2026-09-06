import Foundation

extension WebPage {
    @preconcurrency @MainActor
    public struct BackForwardList: Equatable, Sendable {
        public struct Item: Equatable, Identifiable, Sendable {
            public struct ID: Hashable, Sendable {
                fileprivate let value: UUID
            }

            public let id: ID
            public let title: String?
            public let url: URL
            public let initialURL: URL
            // A presentation ID is deliberately distinct from the navigation
            // entry token: a saved item can still select its original entry.
            internal let entryToken: UUID

            internal init(_ entry: WebPageHistoryEntry) {
                id = ID(value: UUID())
                title = entry.title
                url = entry.url
                initialURL = entry.url
                entryToken = entry.token
            }
        }

        internal let storage: WebPageHistoryStorage?
        internal init(storage: WebPageHistoryStorage? = nil) { self.storage = storage }

        // iPhone 17 Pro / iOS 26.1, WebKitPageHistoryOracle: an empty saved
        // list stays empty; after the first entry a saved list follows A→B→C.
        // Separate populated pages compare unequal, even with identical URLs.
        public nonisolated static func == (a: Self, b: Self) -> Bool {
            a.storage === b.storage
        }

        public var currentItem: Item? { self[0] }
        public var backList: [Item] {
            guard let storage else { return [] }
            return storage.entries[..<storage.index].map(Item.init)
        }
        public var forwardList: [Item] {
            guard let storage else { return [] }
            return storage.entries[(storage.index + 1)...].map(Item.init)
        }
        public subscript(index: Int) -> Item? {
            guard let storage else { return nil }
            let (offset, overflow) = storage.index.addingReportingOverflow(index)
            guard !overflow, storage.entries.indices.contains(offset) else { return nil }
            // Native: two reads of currentItem compare unequal (including ID);
            // a value copy compares equal and preserves its ID/hash.
            return Item(storage.entries[offset])
        }
    }
}

internal struct WebPageHistoryEntry: Sendable {
    let token = UUID()
    let url: URL
    var title: String?
    var document: String
    var mimeType: String
}

@MainActor
internal final class WebPageHistoryStorage {
    var entries: [WebPageHistoryEntry]
    var index: Int

    init(first: WebPageHistoryEntry) {
        entries = [first]
        index = 0
    }

    func append(_ entry: WebPageHistoryEntry) {
        // Native 26.1 same-URL matrix: A/A2/A3 keeps back count 0.
        // Replacing A after going back preserves B in the forward list, and
        // load(savedA) restores A2: the entry token survives replacement.
        if entries[index].url == entry.url {
            entries[index].title = entry.title
            entries[index].document = entry.document
            entries[index].mimeType = entry.mimeType
            return
        }
        entries.removeSubrange((index + 1)...)
        entries.append(entry)
        index = entries.count - 1
    }
}
