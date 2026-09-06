import Foundation
import MusicKit

func testLibrarySongSortAndFilter() {
    let albums = MusicItemCollection([Album(id: "2", title: "HB", artistName: "FF")])
    let genres = MusicItemCollection([Genre(id: "g", name: "Folk")])
    let artists = MusicItemCollection([Artist(id: "3", name: "Fleet Foxes")])
    let probe = LibrarySongProbe(
        id: "1",
        title: "Helplessness Blues",
        albumTitle: "Helplessness Blues",
        artistName: "Fleet Foxes",
        composerName: "Robin Pecknold",
        discNumber: 1,
        trackNumber: 2,
        duration: 303,
        playCount: 9,
        lastPlayedDate: Date(timeIntervalSince1970: 1_600_000_000),
        libraryAddedDate: Date(timeIntervalSince1970: 1_500_000_000),
        albums: albums,
        genres: genres,
        artists: artists
    )
    inspectLibrarySongFilter(probe)
    inspectLibrarySongSort(probe)
}

func testLibraryTrackSort() {
    let played = Date(timeIntervalSince1970: 1_700_000_000)
    let added = Date(timeIntervalSince1970: 1_600_000_000)
    let probe = LibraryTrackProbe(
        title: "S",
        albumTitle: "HB",
        artistName: "FF",
        discNumber: 1,
        trackNumber: 3,
        lastPlayedDate: played,
        libraryAddedDate: added,
        duration: 200,
        playCount: 4
    )
    inspectLibraryTrackSort(probe)
}

func testLibraryMusicVideoSortAndFilter() {
    let albums = MusicItemCollection([Album(id: "2", title: "HB", artistName: "FF")])
    let genres = MusicItemCollection([Genre(id: "g", name: "Folk")])
    let artists = MusicItemCollection([Artist(id: "3", name: "Fleet Foxes")])
    let probe = LibraryMusicVideoProbe(
        id: "v1",
        title: "White Winter Hymnal",
        albumTitle: "HB",
        artistName: "Fleet Foxes",
        trackNumber: 1,
        duration: 180,
        playCount: 2,
        lastPlayedDate: Date(timeIntervalSince1970: 1_600_000_000),
        libraryAddedDate: Date(timeIntervalSince1970: 1_500_000_000),
        albums: albums,
        genres: genres,
        artists: artists
    )
    inspectLibraryMusicVideoFilter(probe)
    inspectLibraryMusicVideoSort(probe)
}

private struct LibrarySongProbe: LibrarySongFilter, LibrarySongSortProperties {
    var id: MusicItemID
    var title: String
    var albumTitle: String?
    var artistName: String?
    var composerName: String?
    var discNumber: Int?
    var trackNumber: Int?
    var duration: TimeInterval?
    var playCount: Int?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
    var albums: MusicItemCollection<Album>?
    var genres: MusicItemCollection<Genre>?
    var artists: MusicItemCollection<Artist>?
}

private struct LibraryTrackProbe: LibraryTrackSortProperties {
    var title: String
    var albumTitle: String?
    var artistName: String?
    var discNumber: Int?
    var trackNumber: Int?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
    var duration: TimeInterval?
    var playCount: Int?
}

private struct LibraryMusicVideoProbe: LibraryMusicVideoFilter, LibraryMusicVideoSortProperties {
    var id: MusicItemID
    var title: String
    var albumTitle: String?
    var artistName: String?
    var trackNumber: Int?
    var duration: TimeInterval?
    var playCount: Int?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
    var albums: MusicItemCollection<Album>?
    var genres: MusicItemCollection<Genre>?
    var artists: MusicItemCollection<Artist>?
}

private func inspectLibrarySongFilter(_ item: some LibrarySongFilter) {
    precondition(item.title == "Helplessness Blues")
    precondition(item.albumTitle == "Helplessness Blues")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.composerName == "Robin Pecknold")
    precondition(item.id.rawValue == "1")
    precondition(item.albums?.count == 1)
    precondition(item.genres?.count == 1)
    precondition(item.artists?.count == 1)
}

private func inspectLibrarySongSort(_ item: some LibrarySongSortProperties) {
    precondition(item.title == "Helplessness Blues")
    precondition(item.albumTitle == "Helplessness Blues")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.composerName == "Robin Pecknold")
    precondition(item.discNumber == 1)
    precondition(item.trackNumber == 2)
    precondition(item.duration == 303)
    precondition(item.playCount == 9)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryTrackSort(_ item: some LibraryTrackSortProperties) {
    precondition(item.title == "S")
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "FF")
    precondition(item.discNumber == 1)
    precondition(item.trackNumber == 3)
    precondition(item.duration == 200)
    precondition(item.playCount == 4)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryMusicVideoFilter(_ item: some LibraryMusicVideoFilter) {
    precondition(item.id.rawValue == "v1")
    precondition(item.title == "White Winter Hymnal")
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.albums?.count == 1)
    precondition(item.genres?.count == 1)
    precondition(item.artists?.count == 1)
}

private func inspectLibraryMusicVideoSort(_ item: some LibraryMusicVideoSortProperties) {
    precondition(item.title == "White Winter Hymnal")
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.trackNumber == 1)
    precondition(item.duration == 180)
    precondition(item.playCount == 2)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}
