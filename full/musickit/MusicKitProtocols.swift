import Foundation

public protocol MusicItem: Sendable {
    var id: MusicItemID { get }
}

extension MusicItem {
    public func with(
        _ properties: PartialMusicAsyncProperty<Self>...,
        preferredSource: MusicPropertySource
    ) async throws -> Self {
        _ = properties
        _ = preferredSource
        throw MusicKitPortableError.catalogUnavailable
    }

    public func with(
        _ properties: [PartialMusicAsyncProperty<Self>],
        preferredSource: MusicPropertySource
    ) async throws -> Self {
        _ = properties
        _ = preferredSource
        throw MusicKitPortableError.catalogUnavailable
    }

    public func with(_ properties: [PartialMusicAsyncProperty<Self>]) async throws -> Self {
        _ = properties
        throw MusicKitPortableError.catalogUnavailable
    }

    public func with(_ properties: PartialMusicAsyncProperty<Self>...) async throws -> Self {
        _ = properties
        throw MusicKitPortableError.catalogUnavailable
    }
}

public protocol PlayableMusicItem: MusicItem {
    var playParameters: PlayParameters? { get }
}

public protocol FilterableMusicItem: MusicItem {
    associatedtype FilterType
}

public protocol MusicLibraryAddable: MusicItem {}
public protocol MusicPlaylistAddable: MusicItem {}
public protocol MusicCatalogSearchable: MusicItem {}
public protocol MusicLibrarySearchable: MusicItem {}
public protocol MusicCatalogChartRequestable: MusicItem {}
public protocol MusicRecentlyPlayedRequestable: MusicItem {}
public protocol MusicPersonalRecommendationItem: MusicItem {}
public protocol MusicCatalogTopLevelResourceRequesting: MusicItem {}
public protocol MusicLibrarySectionRequestable {}

public protocol MusicLibraryRequestable: MusicItem {
    associatedtype LibrarySortProperties
    associatedtype LibraryFilter
}

public protocol MusicPropertyContainer {
    func with(
        _ properties: PartialMusicAsyncProperty<Self>...,
        preferredSource: MusicPropertySource
    ) async throws -> Self
    func with(
        _ properties: [PartialMusicAsyncProperty<Self>],
        preferredSource: MusicPropertySource
    ) async throws -> Self
    func with(_ properties: [PartialMusicAsyncProperty<Self>]) async throws -> Self
    func with(_ properties: PartialMusicAsyncProperty<Self>...) async throws -> Self
}

extension MusicPropertyContainer {
    public func with(
        _ properties: PartialMusicAsyncProperty<Self>...,
        preferredSource: MusicPropertySource
    ) async throws -> Self {
        _ = properties
        _ = preferredSource
        throw MusicKitPortableError.catalogUnavailable
    }

    public func with(
        _ properties: [PartialMusicAsyncProperty<Self>],
        preferredSource: MusicPropertySource
    ) async throws -> Self {
        _ = properties
        _ = preferredSource
        throw MusicKitPortableError.catalogUnavailable
    }

    public func with(_ properties: [PartialMusicAsyncProperty<Self>]) async throws -> Self {
        _ = properties
        throw MusicKitPortableError.catalogUnavailable
    }

    public func with(_ properties: PartialMusicAsyncProperty<Self>...) async throws -> Self {
        _ = properties
        throw MusicKitPortableError.catalogUnavailable
    }
}

public protocol SongFilter {
    var id: MusicItemID { get }
    var isrc: String? { get }
}

public protocol AlbumFilter {
    var id: MusicItemID { get }
    var upc: String? { get }
}

public protocol GenreFilter {
    var id: MusicItemID { get }
}

public protocol ArtistFilter {
    var id: MusicItemID { get }
}

public protocol CuratorFilter {
    var id: MusicItemID { get }
}

public protocol StationFilter {
    var id: MusicItemID { get }
}

public protocol PlaylistFilter {
    var id: MusicItemID { get }
}

public protocol RadioShowFilter {
    var id: MusicItemID { get }
}

public protocol RecordLabelFilter {
    var id: MusicItemID { get }
}

public protocol MusicVideoFilter {
    var id: MusicItemID { get }
}

public protocol LibrarySongFilter {
    var albumTitle: String? { get }
    var artistName: String? { get }
    var composerName: String? { get }
    var id: MusicItemID { get }
    var title: String { get }
    var albums: MusicItemCollection<Album>? { get }
    var genres: MusicItemCollection<Genre>? { get }
    var artists: MusicItemCollection<Artist>? { get }
}

public protocol LibraryAlbumFilter {
    var artistName: String { get }
    var isCompilation: Bool? { get }
    var id: MusicItemID { get }
    var title: String { get }
    var genres: MusicItemCollection<Genre>? { get }
    var artists: MusicItemCollection<Artist>? { get }
}

public protocol LibraryGenreFilter {
    var id: MusicItemID { get }
}

public protocol LibraryTrackFilter {
    var id: MusicItemID { get }
}

public protocol LibraryArtistFilter {
    var id: MusicItemID { get }
    var name: String { get }
    var genres: MusicItemCollection<Genre>? { get }
    var playlists: MusicItemCollection<Playlist>? { get }
}

public protocol LibraryPlaylistFilter {
    var id: MusicItemID { get }
}

public protocol LibraryPlaylistEntryFilter {
    var id: MusicItemID { get }
}

public protocol LibraryMusicVideoFilter {
    var id: MusicItemID { get }
}

public protocol LibrarySongSortProperties {
    var albumTitle: String? { get }
    var artistName: String? { get }
    var discNumber: Int? { get }
    var trackNumber: Int? { get }
    var composerName: String? { get }
    var lastPlayedDate: Date? { get }
    var libraryAddedDate: Date? { get }
    var title: String { get }
    var duration: TimeInterval? { get }
    var playCount: Int? { get }
}

public protocol LibraryAlbumSortProperties {
    var title: String { get }
    var artistName: String { get }
    var trackCount: Int { get }
    var releaseDate: Date? { get }
    var lastPlayedDate: Date? { get }
    var libraryAddedDate: Date? { get }
}

public protocol LibraryGenreSortProperties {
    var name: String { get }
}

public protocol LibraryTrackSortProperties {
    var title: String { get }
    var lastPlayedDate: Date? { get }
}

public protocol LibraryArtistSortProperties {
    var name: String { get }
    var albumCount: Int? { get }
    var libraryAddedDate: Date? { get }
}

public protocol LibraryPlaylistSortProperties {
    var name: String { get }
    var lastPlayedDate: Date? { get }
}

public protocol LibraryPlaylistEntrySortProperties {
    var title: String { get }
}

public protocol LibraryMusicVideoSortProperties {
    var title: String { get }
}

public protocol MusicLibraryRequestFilterValueEquatable {}
public protocol MusicLibraryRequestFilterValueMembershipComparable {}

extension String: MusicLibraryRequestFilterValueEquatable, MusicLibraryRequestFilterValueMembershipComparable {}
extension Int: MusicLibraryRequestFilterValueEquatable, MusicLibraryRequestFilterValueMembershipComparable {}
extension Bool: MusicLibraryRequestFilterValueEquatable, MusicLibraryRequestFilterValueMembershipComparable {}
extension Optional: MusicLibraryRequestFilterValueEquatable where Wrapped: MusicLibraryRequestFilterValueEquatable {}
extension Optional: MusicLibraryRequestFilterValueMembershipComparable
    where Wrapped: MusicLibraryRequestFilterValueMembershipComparable {}
extension MusicItemID: MusicLibraryRequestFilterValueEquatable, MusicLibraryRequestFilterValueMembershipComparable {}

public protocol MusicDeveloperTokenProvider {
    func developerToken(options: MusicTokenRequestOptions) async throws -> String
}
