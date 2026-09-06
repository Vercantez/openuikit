import Foundation
import MusicKit

func testLibraryAndResourceResponses() {
    let song = Song(id: "1", title: "S", artistName: "A")
    let library = MusicLibraryResponse(items: MusicItemCollection([song]))
    precondition(library.items.count == 1)
    precondition(library.items[0].title == "S")
    precondition(library.description.contains("1"))
    precondition(library.debugDescription == library.description)
    precondition(library == library)
    var hasher = Hasher()
    library.hash(into: &hasher)
    _ = library.hashValue

    let catalog = MusicCatalogResourceResponse(items: MusicItemCollection([song]))
    precondition(catalog.items.count == 1)
    precondition(catalog.description.contains("1"))
    precondition(catalog.debugDescription == catalog.description)
    precondition(catalog == catalog)
    catalog.hash(into: &hasher)
    _ = catalog.hashValue

    let recentItem = RecentlyPlayedMusicItem.album(Album(id: "9", title: "HB", artistName: "FF"))
    let recent = MusicRecentlyPlayedResponse(items: MusicItemCollection([recentItem]))
    precondition(recent.items.count == 1)
    precondition(recent.items[0].title == "HB")
    precondition(recent.description.contains("1"))
    precondition(recent.debugDescription == recent.description)
    precondition(recent == recent)
    recent.hash(into: &hasher)
    _ = recent.hashValue
}
