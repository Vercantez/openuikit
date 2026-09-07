import Foundation
@_spi(OpenUIKitHost)
import JournalingSuggestions

private final class AsyncResultBox<Value>: @unchecked Sendable {
    private let condition = NSCondition()
    private var result: Result<Value, any Error>?

    func finish(_ result: Result<Value, any Error>) {
        condition.lock()
        self.result = result
        condition.broadcast()
        condition.unlock()
    }

    func wait() throws -> Value {
        condition.lock()
        defer { condition.unlock() }
        let deadline = Date().addingTimeInterval(5)
        while result == nil {
            precondition(condition.wait(until: deadline), "async asset lookup timed out")
        }
        return try result!.get()
    }
}

private func resolve<Value: Sendable>(
    _ operation: @escaping @Sendable () async throws -> Value
) throws -> Value {
    let box = AsyncResultBox<Value>()
    Task.detached {
        do {
            box.finish(.success(try await operation()))
        } catch {
            box.finish(.failure(error))
        }
    }
    return try box.wait()
}

func testItemContentIdentity() {
    let id = UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!
    let item = JournalingSuggestion.ItemContent(id: id)
    precondition(item.id == id)
    typealias ItemID = JournalingSuggestion.ItemContent.ID
    precondition(ItemID.self == UUID.self)
}

func testItemContentHasContent() {
    let photo = JournalingSuggestion.Photo(photo: URL(fileURLWithPath: "/tmp/a.jpg"))
    let song = JournalingSuggestion.Song(song: "Song")
    let item = JournalingSuggestion.ItemContent(assets: [photo, song])
    precondition(item.hasContent(ofType: JournalingSuggestion.Photo.self))
    precondition(item.hasContent(ofType: JournalingSuggestion.Song.self))
    precondition(!item.hasContent(ofType: JournalingSuggestion.Video.self))
    let loadedPhoto = try! item._content(forType: JournalingSuggestion.Photo.self)
    precondition(loadedPhoto?.photo.path == "/tmp/a.jpg")
    let missing = try! item._content(forType: JournalingSuggestion.Video.self)
    precondition(missing == nil)
    precondition(item.representations.count == 2)
}

func testSuggestionHostContents() {
    let photo = JournalingSuggestion.Photo(photo: URL(fileURLWithPath: "/tmp/b.jpg"))
    let item = JournalingSuggestion.ItemContent(assets: [photo])
    let suggestion = JournalingSuggestion(title: "Photos", date: nil, items: [item])
    let photos = suggestion._contents(ofType: JournalingSuggestion.Photo.self)
    precondition(photos.count == 1)
    precondition(photos[0].photo.path == "/tmp/b.jpg")
    precondition(suggestion._contents(ofType: JournalingSuggestion.Video.self).isEmpty)
}

func testAssetProtocolAssociatedType() {
    func isAsset<T: JournalingSuggestionAsset>(_ value: T) -> Bool {
        T.JournalingSuggestionContent.self == T.self
    }
    precondition(isAsset(JournalingSuggestion.Photo(photo: URL(fileURLWithPath: "/tmp/x.jpg"))))
    precondition(isAsset(JournalingSuggestion.Contact(name: "Pat")))
}

func testItemContentAsyncLookup() {
    let photo = JournalingSuggestion.Photo(
        photo: URL(fileURLWithPath: "/tmp/async-photo.jpg"),
        date: Date(timeIntervalSince1970: 1_700_000_100)
    )
    let item = JournalingSuggestion.ItemContent(assets: [photo])
    let loaded: JournalingSuggestion.Photo? = try! resolve {
        try await item.content(forType: JournalingSuggestion.Photo.self)
    }
    let missing: JournalingSuggestion.Video? = try! resolve {
        try await item.content(forType: JournalingSuggestion.Video.self)
    }
    precondition(loaded == photo)
    precondition(missing == nil)
}

func testSuggestionAsyncContentLookup() {
    let first = JournalingSuggestion.Photo(photo: URL(fileURLWithPath: "/tmp/async-first.jpg"))
    let second = JournalingSuggestion.Photo(photo: URL(fileURLWithPath: "/tmp/async-second.jpg"))
    let suggestion = JournalingSuggestion(
        title: "Photos",
        date: nil,
        items: [
            JournalingSuggestion.ItemContent(assets: [first]),
            JournalingSuggestion.ItemContent(assets: [second]),
            JournalingSuggestion.ItemContent()
        ]
    )
    let loaded: [JournalingSuggestion.Photo] = try! resolve {
        await suggestion.content(forType: JournalingSuggestion.Photo.self)
    }
    let missing: [JournalingSuggestion.Video] = try! resolve {
        await suggestion.content(forType: JournalingSuggestion.Video.self)
    }
    precondition(loaded == [first, second])
    precondition(missing.isEmpty)
}
