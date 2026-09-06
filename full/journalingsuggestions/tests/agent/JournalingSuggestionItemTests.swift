import Foundation
@_spi(OpenUIKitHost)
import JournalingSuggestions

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
