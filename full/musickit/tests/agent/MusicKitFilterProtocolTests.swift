import Foundation
import MusicKit

func testCatalogFilterProtocols() {
    inspectSongFilter(SongFilterProbe(id: "s1", isrc: "USUM71106461"))
    inspectAlbumFilter(AlbumFilterProbe(id: "a1", upc: "00602527708414"))
    inspectGenreFilter(GenreFilterProbe(id: "g1"))
    inspectArtistFilter(ArtistFilterProbe(id: "ar1"))
    inspectCuratorFilter(CuratorFilterProbe(id: "c1"))
    inspectStationFilter(StationFilterProbe(id: "st1"))
    inspectPlaylistFilter(PlaylistFilterProbe(id: "p1"))
    inspectRadioShowFilter(RadioShowFilterProbe(id: "r1"))
    inspectRecordLabelFilter(RecordLabelFilterProbe(id: "l1"))
    inspectMusicVideoFilter(MusicVideoFilterProbe(id: "v1", isrc: "USUM71106462"))
    checkSongFilterType(Song(id: "9", title: "T", artistName: "A"))
}

func testLibraryFilterProtocols() {
    let albums = MusicItemCollection([Album(id: "2", title: "HB", artistName: "FF")])
    let genres = MusicItemCollection([Genre(id: "g", name: "Folk")])
    let artists = MusicItemCollection([Artist(id: "3", name: "Fleet Foxes")])
    let playlists = MusicItemCollection([Playlist(id: "p9", name: "Mix")])
    let added = Date(timeIntervalSince1970: 1_500_000_000)
    let played = Date(timeIntervalSince1970: 1_600_000_000)
    inspectLibraryAlbumFilter(
        LibraryAlbumFilterProbe(
            artistName: "Fleet Foxes", isCompilation: false, id: "a2", title: "HB",
            genres: genres, artists: artists))
    inspectLibraryGenreFilter(LibraryGenreFilterProbe(id: "g2", name: "Folk"))
    inspectLibraryTrackFilter(
        LibraryTrackFilterProbe(
            albumTitle: "HB", artistName: "Fleet Foxes", id: "t1", title: "Song",
            albums: albums, genres: genres, artists: artists))
    inspectLibraryArtistFilter(
        LibraryArtistFilterProbe(id: "ar2", name: "Fleet Foxes", genres: genres, playlists: playlists))
    inspectLibraryPlaylistFilter(LibraryPlaylistFilterProbe(id: "p2", name: "Mix"))
    inspectLibraryPlaylistEntryFilter(LibraryPlaylistEntryFilterProbe(id: "e7"))
    inspectLibraryAlbumSort(
        LibraryAlbumSortProbe(
            title: "HB", artistName: "Fleet Foxes", trackCount: 12,
            releaseDate: played, lastPlayedDate: played, libraryAddedDate: added))
    inspectLibraryGenreSort(LibraryGenreSortProbe(name: "Folk", libraryAddedDate: added))
    inspectLibraryArtistSort(
        LibraryArtistSortProbe(name: "Fleet Foxes", albumCount: 5, libraryAddedDate: added))
    inspectLibraryPlaylistSort(
        LibraryPlaylistSortProbe(name: "Mix", lastPlayedDate: played, libraryAddedDate: added))
    inspectLibraryPlaylistEntrySort(LibraryPlaylistEntrySortProbe(title: "Track"))
}

private struct SongFilterProbe: SongFilter {
    var id: MusicItemID
    var isrc: String?
}

private struct AlbumFilterProbe: AlbumFilter {
    var id: MusicItemID
    var upc: String?
}

private struct GenreFilterProbe: GenreFilter {
    var id: MusicItemID
}

private struct ArtistFilterProbe: ArtistFilter {
    var id: MusicItemID
}

private struct CuratorFilterProbe: CuratorFilter {
    var id: MusicItemID
}

private struct StationFilterProbe: StationFilter {
    var id: MusicItemID
}

private struct PlaylistFilterProbe: PlaylistFilter {
    var id: MusicItemID
}

private struct RadioShowFilterProbe: RadioShowFilter {
    var id: MusicItemID
}

private struct RecordLabelFilterProbe: RecordLabelFilter {
    var id: MusicItemID
}

private struct MusicVideoFilterProbe: MusicVideoFilter {
    var id: MusicItemID
    var isrc: String?
}

private struct LibraryAlbumFilterProbe: LibraryAlbumFilter {
    var artistName: String
    var isCompilation: Bool?
    var id: MusicItemID
    var title: String
    var genres: MusicItemCollection<Genre>?
    var artists: MusicItemCollection<Artist>?
}

private struct LibraryGenreFilterProbe: LibraryGenreFilter {
    var id: MusicItemID
    var name: String
}

private struct LibraryTrackFilterProbe: LibraryTrackFilter {
    var albumTitle: String?
    var artistName: String?
    var id: MusicItemID
    var title: String
    var albums: MusicItemCollection<Album>?
    var genres: MusicItemCollection<Genre>?
    var artists: MusicItemCollection<Artist>?
}

private struct LibraryArtistFilterProbe: LibraryArtistFilter {
    var id: MusicItemID
    var name: String
    var genres: MusicItemCollection<Genre>?
    var playlists: MusicItemCollection<Playlist>?
}

private struct LibraryPlaylistFilterProbe: LibraryPlaylistFilter {
    var id: MusicItemID
    var name: String
}

private struct LibraryPlaylistEntryFilterProbe: LibraryPlaylistEntryFilter {
    var id: MusicItemID
}

private struct LibraryAlbumSortProbe: LibraryAlbumSortProperties {
    var title: String
    var artistName: String
    var trackCount: Int
    var releaseDate: Date?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
}

private struct LibraryGenreSortProbe: LibraryGenreSortProperties {
    var name: String
    var libraryAddedDate: Date?
}

private struct LibraryArtistSortProbe: LibraryArtistSortProperties {
    var name: String
    var albumCount: Int?
    var libraryAddedDate: Date?
}

private struct LibraryPlaylistSortProbe: LibraryPlaylistSortProperties {
    var name: String
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
}

private struct LibraryPlaylistEntrySortProbe: LibraryPlaylistEntrySortProperties {
    var title: String
}

private func checkSongFilterType<T: FilterableMusicItem>(_ item: T) where T.FilterType == SongFilter {
    precondition(item.id.rawValue == "9")
    func accept(_ filter: T.FilterType) -> MusicItemID { filter.id }
    precondition(accept(SongFilterProbe(id: "99", isrc: nil)).rawValue == "99")
}

private func inspectSongFilter(_ item: some SongFilter) {
    precondition(item.id.rawValue == "s1")
    precondition(item.isrc == "USUM71106461")
}

private func inspectAlbumFilter(_ item: some AlbumFilter) {
    precondition(item.id.rawValue == "a1")
    precondition(item.upc == "00602527708414")
}

private func inspectGenreFilter(_ item: some GenreFilter) {
    precondition(item.id.rawValue == "g1")
}

private func inspectArtistFilter(_ item: some ArtistFilter) {
    precondition(item.id.rawValue == "ar1")
}

private func inspectCuratorFilter(_ item: some CuratorFilter) {
    precondition(item.id.rawValue == "c1")
}

private func inspectStationFilter(_ item: some StationFilter) {
    precondition(item.id.rawValue == "st1")
}

private func inspectPlaylistFilter(_ item: some PlaylistFilter) {
    precondition(item.id.rawValue == "p1")
}

private func inspectRadioShowFilter(_ item: some RadioShowFilter) {
    precondition(item.id.rawValue == "r1")
}

private func inspectRecordLabelFilter(_ item: some RecordLabelFilter) {
    precondition(item.id.rawValue == "l1")
}

private func inspectMusicVideoFilter(_ item: some MusicVideoFilter) {
    precondition(item.id.rawValue == "v1")
    precondition(item.isrc == "USUM71106462")
}

private func inspectLibraryAlbumFilter(_ item: some LibraryAlbumFilter) {
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.isCompilation == false)
    precondition(item.id.rawValue == "a2")
    precondition(item.title == "HB")
    precondition(item.genres?.count == 1)
    precondition(item.artists?.count == 1)
}

private func inspectLibraryGenreFilter(_ item: some LibraryGenreFilter) {
    precondition(item.id.rawValue == "g2")
    precondition(item.name == "Folk")
}

private func inspectLibraryTrackFilter(_ item: some LibraryTrackFilter) {
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.id.rawValue == "t1")
    precondition(item.title == "Song")
    precondition(item.albums?.count == 1)
    precondition(item.genres?.count == 1)
    precondition(item.artists?.count == 1)
}

private func inspectLibraryArtistFilter(_ item: some LibraryArtistFilter) {
    precondition(item.id.rawValue == "ar2")
    precondition(item.name == "Fleet Foxes")
    precondition(item.genres?.count == 1)
    precondition(item.playlists?.count == 1)
}

private func inspectLibraryPlaylistFilter(_ item: some LibraryPlaylistFilter) {
    precondition(item.id.rawValue == "p2")
    precondition(item.name == "Mix")
}

private func inspectLibraryPlaylistEntryFilter(_ item: some LibraryPlaylistEntryFilter) {
    precondition(item.id.rawValue == "e7")
}

private func inspectLibraryAlbumSort(_ item: some LibraryAlbumSortProperties) {
    precondition(item.title == "HB")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.trackCount == 12)
    precondition(item.releaseDate != nil)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryGenreSort(_ item: some LibraryGenreSortProperties) {
    precondition(item.name == "Folk")
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryArtistSort(_ item: some LibraryArtistSortProperties) {
    precondition(item.name == "Fleet Foxes")
    precondition(item.albumCount == 5)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryPlaylistSort(_ item: some LibraryPlaylistSortProperties) {
    precondition(item.name == "Mix")
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryPlaylistEntrySort(_ item: some LibraryPlaylistEntrySortProperties) {
    precondition(item.title == "Track")
}
