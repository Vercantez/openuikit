import Foundation
import MusicKit

func testSectionedRequestFilters() {
    var request = MusicLibrarySectionedRequest<Album, Song>()
    request.limit = 20
    request.offset = 4
    request.includeOnlyDownloadedContent = true
    request.filterItems(text: "helpless")
    precondition(request._openuikit_itemFilterText == "helpless")
    request.filterItems(matching: \LibrarySongFilter.title, equalTo: "Helplessness Blues")
    precondition(request._openuikit_itemFilterText == "Helplessness Blues")
    request.filterItems(matching: \LibrarySongFilter.albumTitle, equalTo: Optional("HB"))
    request.filterItems(matching: \LibrarySongFilter.title, contains: "Blue")
    request.filterItems(matching: \LibrarySongFilter.albumTitle, contains: "Help")
    let album = Album(id: "2", title: "HB", artistName: "FF")
    request.filterItems(matching: \LibrarySongFilter.albums, contains: album)
    request.filterItems(matching: \LibrarySongFilter.id, memberOf: [MusicItemID("1")])
    request.filterItems(matching: \LibrarySongFilter.albumTitle, memberOf: [Optional("HB")])
    request.sortItems(by: \LibrarySongSortProperties.title, ascending: false)
    precondition(request._openuikit_itemSortAscending == false)
    request.filterSections(text: "folk")
    request.filterSections(matching: \LibraryAlbumFilter.title, equalTo: "HB")
    request.filterSections(matching: \LibraryAlbumFilter.isCompilation, equalTo: Optional(false))
    request.filterSections(matching: \LibraryAlbumFilter.title, contains: "Help")
    request.filterSections(matching: \LibraryAlbumFilter.artistName, contains: "Fleet")
    request.filterSections(matching: \LibraryAlbumFilter.id, memberOf: [MusicItemID("2")])
    request.filterSections(matching: \LibraryAlbumFilter.isCompilation, memberOf: [Optional(false)])
    request.sortSections(by: \LibraryAlbumSortProperties.title, ascending: true)
    precondition(request.limit == 20)
    precondition(request.offset == 4)
    precondition(request.includeOnlyDownloadedContent)
    precondition(request._openuikit_sectionFilterText != nil)
    precondition(request._openuikit_sectionSortAscending)
    let blank = MusicLibrarySectionedRequest<Album, Song>()
    precondition(blank.limit == 0)
}

func testLibrarySection() {
    let genre = Genre(id: "g1", name: "Folk")
    let song = Song(id: "1", title: "S", artistName: "A")
    let section = MusicLibrarySection(id: "g1", section: genre, items: MusicItemCollection([song]))
    let sectionID: MusicLibrarySection<Genre, Song>.ID = section.id
    precondition(sectionID.rawValue == "g1")
    precondition(section.items.count == 1)
    precondition(section.name == "Folk")
    precondition(section.description.contains("g1"))
    precondition(section.debugDescription == section.description)
    precondition(section == section)
    var hasher = Hasher()
    section.hash(into: &hasher)
    _ = section.hashValue
    let response = MusicLibrarySectionedResponse(sections: [section])
    precondition(response.sections.count == 1)
    precondition(response.description.contains("1"))
    precondition(response.debugDescription == response.description)
    precondition(response == response)
    response.hash(into: &hasher)
    _ = response.hashValue
    _ = MusicLibrarySectionRequestable.self
}
