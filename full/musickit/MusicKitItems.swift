import Foundation

enum MusicResourceDecoder {
    static func container(_ decoder: any Decoder) throws -> (
        id: MusicItemID, attributes: KeyedDecodingContainer<AttrKey>?
    ) {
        let root = try decoder.container(keyedBy: RootKey.self)
        let id: MusicItemID
        if let raw = try root.decodeIfPresent(String.self, forKey: .id) {
            id = MusicItemID(raw)
        } else {
            id = MusicItemID("")
        }
        let attributes = try? root.nestedContainer(keyedBy: AttrKey.self, forKey: .attributes)
        return (id, attributes)
    }

    enum RootKey: String, CodingKey { case id, type, href, attributes, relationships }
    enum AttrKey: String, CodingKey {
        case name, title, artistName, albumName, albumTitle, durationInMillis
        case genreNames, isrc, upc, url, hasLyrics, trackNumber, discNumber
        case releaseDate, contentRating, artwork, playParams, editorialNotes
        case isComplete, trackCount, isCompilation, isSingle, recordLabelName
        case copyright, composerName, movementName, movementCount, movementNumber
        case workName, attribution, has4K, hasHDR, isLive, isPreview
        case stationProviderName, episodeNumber, curatorName, shortDescription
        case standardDescription, isChart, kind, hostName, isAppleDigitalMaster
        case audioVariants, previewAssets, artistUrl, lastPlayedDate, libraryAddedDate
        case playCount, parent, tagline
    }
}

public struct Song: MusicItem, PlayableMusicItem, FilterableMusicItem, MusicLibraryRequestable,
    MusicCatalogSearchable, MusicLibrarySearchable, MusicLibraryAddable, MusicPlaylistAddable,
    MusicCatalogChartRequestable, MusicRecentlyPlayedRequestable, MusicPersonalRecommendationItem,
    MusicCatalogTopLevelResourceRequesting, SongFilter,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = SongFilter
    public typealias LibraryFilter = LibrarySongFilter
    public typealias LibrarySortProperties = LibrarySongSortProperties
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var title: String
    public var artistName: String
    public var albumTitle: String?
    public var discNumber: Int?
    public var genreNames: [String]
    public var attribution: String?
    public var releaseDate: Date?
    public var trackNumber: Int?
    public var composerName: String?
    public var movementName: String?
    public var audioVariants: [AudioVariant]?
    public var contentRating: ContentRating?
    public var movementCount: Int?
    public var previewAssets: [PreviewAsset]?
    public var editorialNotes: EditorialNotes?
    public var lastPlayedDate: Date?
    public var movementNumber: Int?
    public var playParameters: PlayParameters?
    public var libraryAddedDate: Date?
    public var isAppleDigitalMaster: Bool?
    public var url: URL?
    public var isrc: String?
    public var artwork: Artwork?
    public var duration: TimeInterval?
    public var workName: String?
    public var artistURL: URL?
    public var hasLyrics: Bool
    public var playCount: Int?
    public var musicVideos: MusicItemCollection<MusicVideo>?
    public var albums: MusicItemCollection<Album>?
    public var genres: MusicItemCollection<Genre>?
    public var artists: MusicItemCollection<Artist>?
    public var station: Station?
    public var composers: MusicItemCollection<Artist>?

    public init(
        id: MusicItemID,
        title: String,
        artistName: String = "",
        albumTitle: String? = nil,
        duration: TimeInterval? = nil,
        isrc: String? = nil,
        artwork: Artwork? = nil,
        hasLyrics: Bool = false,
        playParameters: PlayParameters? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.discNumber = nil
        self.genreNames = []
        self.attribution = nil
        self.releaseDate = nil
        self.trackNumber = nil
        self.composerName = nil
        self.movementName = nil
        self.audioVariants = nil
        self.contentRating = nil
        self.movementCount = nil
        self.previewAssets = nil
        self.editorialNotes = nil
        self.lastPlayedDate = nil
        self.movementNumber = nil
        self.playParameters = playParameters ?? PlayParameters(id: id, kind: "song")
        self.libraryAddedDate = nil
        self.isAppleDigitalMaster = nil
        self.url = nil
        self.isrc = isrc
        self.artwork = artwork
        self.duration = duration
        self.workName = nil
        self.artistURL = nil
        self.hasLyrics = hasLyrics
        self.playCount = nil
        self.musicVideos = nil
        self.albums = nil
        self.genres = nil
        self.artists = nil
        self.station = nil
        self.composers = nil
    }

    public var description: String { title }
    public var debugDescription: String { "Song(\(id.rawValue) \(title))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        let attributes = parsed.attributes
        if let name = try attributes?.decodeIfPresent(String.self, forKey: .name) {
            title = name
        } else {
            title = (try attributes?.decodeIfPresent(String.self, forKey: .title)) ?? ""
        }
        artistName = (try attributes?.decodeIfPresent(String.self, forKey: .artistName)) ?? ""
        if let albumName = try attributes?.decodeIfPresent(String.self, forKey: .albumName) {
            albumTitle = albumName
        } else {
            albumTitle = try attributes?.decodeIfPresent(String.self, forKey: .albumTitle)
        }
        discNumber = try attributes?.decodeIfPresent(Int.self, forKey: .discNumber)
        genreNames = (try attributes?.decodeIfPresent([String].self, forKey: .genreNames)) ?? []
        attribution = try attributes?.decodeIfPresent(String.self, forKey: .attribution)
        releaseDate = MusicKitJSON.decodeDate(try attributes?.decodeIfPresent(String.self, forKey: .releaseDate))
        trackNumber = try attributes?.decodeIfPresent(Int.self, forKey: .trackNumber)
        composerName = try attributes?.decodeIfPresent(String.self, forKey: .composerName)
        movementName = try attributes?.decodeIfPresent(String.self, forKey: .movementName)
        audioVariants = try attributes?.decodeIfPresent([AudioVariant].self, forKey: .audioVariants)
        contentRating = try attributes?.decodeIfPresent(ContentRating.self, forKey: .contentRating)
        movementCount = try attributes?.decodeIfPresent(Int.self, forKey: .movementCount)
        previewAssets = try attributes?.decodeIfPresent([PreviewAsset].self, forKey: .previewAssets)
        editorialNotes = try attributes?.decodeIfPresent(EditorialNotes.self, forKey: .editorialNotes)
        lastPlayedDate = MusicKitJSON.decodeDate(try attributes?.decodeIfPresent(String.self, forKey: .lastPlayedDate))
        movementNumber = try attributes?.decodeIfPresent(Int.self, forKey: .movementNumber)
        playParameters = try attributes?.decodeIfPresent(PlayParameters.self, forKey: .playParams)
        libraryAddedDate = MusicKitJSON.decodeDate(try attributes?.decodeIfPresent(String.self, forKey: .libraryAddedDate))
        isAppleDigitalMaster = try attributes?.decodeIfPresent(Bool.self, forKey: .isAppleDigitalMaster)
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        isrc = try attributes?.decodeIfPresent(String.self, forKey: .isrc)
        artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        if let millis = try attributes?.decodeIfPresent(Int.self, forKey: .durationInMillis) {
            duration = TimeInterval(millis) / 1000
        } else {
            duration = nil
        }
        workName = try attributes?.decodeIfPresent(String.self, forKey: .workName)
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .artistUrl) {
            artistURL = URL(string: raw)
        } else {
            artistURL = nil
        }
        hasLyrics = (try attributes?.decodeIfPresent(Bool.self, forKey: .hasLyrics)) ?? false
        playCount = try attributes?.decodeIfPresent(Int.self, forKey: .playCount)
        musicVideos = nil
        albums = nil
        genres = nil
        artists = nil
        station = nil
        composers = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("songs", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(title, forKey: .name)
        try attributes.encode(artistName, forKey: .artistName)
        try attributes.encodeIfPresent(albumTitle, forKey: .albumName)
        if let duration {
            try attributes.encode(Int(duration * 1000), forKey: .durationInMillis)
        }
        try attributes.encodeIfPresent(isrc, forKey: .isrc)
        try attributes.encode(hasLyrics, forKey: .hasLyrics)
        try attributes.encodeIfPresent(artwork, forKey: .artwork)
    }
}

public struct Album: MusicItem, PlayableMusicItem, FilterableMusicItem, MusicLibraryRequestable,
    MusicCatalogSearchable, MusicLibrarySearchable, MusicLibraryAddable, MusicPlaylistAddable,
    MusicCatalogChartRequestable, MusicRecentlyPlayedRequestable, MusicPersonalRecommendationItem,
    MusicCatalogTopLevelResourceRequesting, AlbumFilter, LibraryAlbumFilter, LibraryAlbumSortProperties,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = AlbumFilter
    public typealias LibraryFilter = LibraryAlbumFilter
    public typealias LibrarySortProperties = LibraryAlbumSortProperties
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var title: String
    public var artistName: String
    public var genreNames: [String]
    public var isComplete: Bool?
    public var trackCount: Int
    public var releaseDate: Date?
    public var recordLabels: MusicItemCollection<RecordLabel>?
    public var audioVariants: [AudioVariant]?
    public var contentRating: ContentRating?
    public var isCompilation: Bool?
    public var otherVersions: MusicItemCollection<Album>?
    public var relatedAlbums: MusicItemCollection<Album>?
    public var relatedVideos: MusicItemCollection<MusicVideo>?
    public var editorialNotes: EditorialNotes?
    public var lastPlayedDate: Date?
    public var playParameters: PlayParameters?
    public var recordLabelName: String?
    public var libraryAddedDate: Date?
    public var isAppleDigitalMaster: Bool?
    public var upc: String?
    public var url: URL?
    public var genres: MusicItemCollection<Genre>?
    public var tracks: MusicItemCollection<Track>?
    public var artists: MusicItemCollection<Artist>?
    public var artwork: Artwork?
    public var isSingle: Bool?
    public var appearsOn: MusicItemCollection<Playlist>?
    public var artistURL: URL?
    public var copyright: String?

    public init(id: MusicItemID, title: String, artistName: String = "", trackCount: Int = 0) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.genreNames = []
        self.isComplete = nil
        self.trackCount = trackCount
        self.releaseDate = nil
        self.recordLabels = nil
        self.audioVariants = nil
        self.contentRating = nil
        self.isCompilation = nil
        self.otherVersions = nil
        self.relatedAlbums = nil
        self.relatedVideos = nil
        self.editorialNotes = nil
        self.lastPlayedDate = nil
        self.playParameters = PlayParameters(id: id, kind: "album")
        self.recordLabelName = nil
        self.libraryAddedDate = nil
        self.isAppleDigitalMaster = nil
        self.upc = nil
        self.url = nil
        self.genres = nil
        self.tracks = nil
        self.artists = nil
        self.artwork = nil
        self.isSingle = nil
        self.appearsOn = nil
        self.artistURL = nil
        self.copyright = nil
    }

    public var description: String { title }
    public var debugDescription: String { "Album(\(id.rawValue) \(title))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        let attributes = parsed.attributes
        title = (try attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        artistName = (try attributes?.decodeIfPresent(String.self, forKey: .artistName)) ?? ""
        genreNames = (try attributes?.decodeIfPresent([String].self, forKey: .genreNames)) ?? []
        isComplete = try attributes?.decodeIfPresent(Bool.self, forKey: .isComplete)
        trackCount = (try attributes?.decodeIfPresent(Int.self, forKey: .trackCount)) ?? 0
        releaseDate = MusicKitJSON.decodeDate(try attributes?.decodeIfPresent(String.self, forKey: .releaseDate))
        upc = try attributes?.decodeIfPresent(String.self, forKey: .upc)
        isCompilation = try attributes?.decodeIfPresent(Bool.self, forKey: .isCompilation)
        isSingle = try attributes?.decodeIfPresent(Bool.self, forKey: .isSingle)
        contentRating = try attributes?.decodeIfPresent(ContentRating.self, forKey: .contentRating)
        artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        copyright = try attributes?.decodeIfPresent(String.self, forKey: .copyright)
        recordLabelName = try attributes?.decodeIfPresent(String.self, forKey: .recordLabelName)
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        playParameters = try attributes?.decodeIfPresent(PlayParameters.self, forKey: .playParams)
        editorialNotes = try attributes?.decodeIfPresent(EditorialNotes.self, forKey: .editorialNotes)
        audioVariants = try attributes?.decodeIfPresent([AudioVariant].self, forKey: .audioVariants)
        isAppleDigitalMaster = try attributes?.decodeIfPresent(Bool.self, forKey: .isAppleDigitalMaster)
        recordLabels = nil
        otherVersions = nil
        relatedAlbums = nil
        relatedVideos = nil
        lastPlayedDate = nil
        libraryAddedDate = nil
        genres = nil
        tracks = nil
        artists = nil
        appearsOn = nil
        artistURL = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("albums", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(title, forKey: .name)
        try attributes.encode(artistName, forKey: .artistName)
        try attributes.encode(trackCount, forKey: .trackCount)
        try attributes.encodeIfPresent(upc, forKey: .upc)
        try attributes.encodeIfPresent(artwork, forKey: .artwork)
    }
}

public struct Artist: MusicItem, FilterableMusicItem, MusicLibraryRequestable,
    MusicCatalogSearchable, MusicLibrarySearchable, MusicCatalogChartRequestable,
    MusicCatalogTopLevelResourceRequesting, ArtistFilter, LibraryArtistFilter, LibraryArtistSortProperties,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = ArtistFilter
    public typealias LibraryFilter = LibraryArtistFilter
    public typealias LibrarySortProperties = LibraryArtistSortProperties
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var name: String
    public var genreNames: [String]?
    public var editorialNotes: EditorialNotes?
    public var libraryAddedDate: Date?
    public var url: URL?
    public var artwork: Artwork?
    public var topMusicVideos: MusicItemCollection<MusicVideo>?
    public var fullAlbums: MusicItemCollection<Album>?
    public var liveAlbums: MusicItemCollection<Album>?
    public var musicVideos: MusicItemCollection<MusicVideo>?
    public var latestRelease: Album?
    public var featuredAlbums: MusicItemCollection<Album>?
    public var similarArtists: MusicItemCollection<Artist>?
    public var appearsOnAlbums: MusicItemCollection<Album>?
    public var compilationAlbums: MusicItemCollection<Album>?
    public var featuredPlaylists: MusicItemCollection<Playlist>?
    public var albums: MusicItemCollection<Album>?
    public var genres: MusicItemCollection<Genre>?
    public var singles: MusicItemCollection<Album>?
    public var station: Station?
    public var topSongs: MusicItemCollection<Song>?
    public var playlists: MusicItemCollection<Playlist>?

    public init(id: MusicItemID, name: String) {
        self.id = id
        self.name = name
        self.genreNames = nil
        self.editorialNotes = nil
        self.libraryAddedDate = nil
        self.url = nil
        self.artwork = nil
    }

    public var description: String { name }
    public var debugDescription: String { "Artist(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        let attributes = parsed.attributes
        name = (try attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        genreNames = try attributes?.decodeIfPresent([String].self, forKey: .genreNames)
        editorialNotes = try attributes?.decodeIfPresent(EditorialNotes.self, forKey: .editorialNotes)
        artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        libraryAddedDate = nil
        topMusicVideos = nil
        fullAlbums = nil
        liveAlbums = nil
        musicVideos = nil
        latestRelease = nil
        featuredAlbums = nil
        similarArtists = nil
        appearsOnAlbums = nil
        compilationAlbums = nil
        featuredPlaylists = nil
        albums = nil
        genres = nil
        singles = nil
        station = nil
        topSongs = nil
        playlists = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("artists", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
        try attributes.encodeIfPresent(artwork, forKey: .artwork)
    }
}

public struct Genre: MusicItem, FilterableMusicItem, MusicLibraryRequestable,
    MusicCatalogSearchable, GenreFilter, LibraryGenreFilter, LibraryGenreSortProperties,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = GenreFilter
    public typealias LibraryFilter = LibraryGenreFilter
    public typealias LibrarySortProperties = LibraryGenreSortProperties
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var name: String
    public var libraryAddedDate: Date?
    public var parent: Genre? {
        get { _parentBox?.value }
        set {
            if let newValue {
                _parentBox = GenreBox(value: newValue)
            } else {
                _parentBox = nil
            }
        }
    }
    private var _parentBox: GenreBox?

    private final class GenreBox: @unchecked Sendable, Hashable {
        let value: Genre
        init(value: Genre) { self.value = value }
        static func == (lhs: GenreBox, rhs: GenreBox) -> Bool { lhs.value.id == rhs.value.id }
        func hash(into hasher: inout Hasher) { hasher.combine(value.id) }
    }

    public init(id: MusicItemID, name: String, parent: Genre? = nil) {
        self.id = id
        self.name = name
        if let parent {
            _parentBox = GenreBox(value: parent)
        } else {
            _parentBox = nil
        }
    }

    public var description: String { name }
    public var debugDescription: String { "Genre(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        name = (try parsed.attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        _parentBox = nil
        libraryAddedDate = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("genres", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
    }
}

public struct Station: MusicItem, PlayableMusicItem, FilterableMusicItem,
    MusicCatalogSearchable, MusicRecentlyPlayedRequestable, StationFilter,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = StationFilter
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var name: String
    public var contentRating: ContentRating?
    public var episodeNumber: Int?
    public var editorialNotes: EditorialNotes?
    public var playParameters: PlayParameters?
    public var stationProviderName: String?
    public var url: URL?
    public var isLive: Bool
    public var artwork: Artwork?
    public var duration: TimeInterval?

    public init(id: MusicItemID, name: String, isLive: Bool = false) {
        self.id = id
        self.name = name
        self.isLive = isLive
        self.playParameters = PlayParameters(id: id, kind: "station")
    }

    public var description: String { name }
    public var debugDescription: String { "Station(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        let attributes = parsed.attributes
        name = (try attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        isLive = (try attributes?.decodeIfPresent(Bool.self, forKey: .isLive)) ?? false
        contentRating = try attributes?.decodeIfPresent(ContentRating.self, forKey: .contentRating)
        episodeNumber = try attributes?.decodeIfPresent(Int.self, forKey: .episodeNumber)
        editorialNotes = try attributes?.decodeIfPresent(EditorialNotes.self, forKey: .editorialNotes)
        playParameters = try attributes?.decodeIfPresent(PlayParameters.self, forKey: .playParams)
        stationProviderName = try attributes?.decodeIfPresent(String.self, forKey: .stationProviderName)
        artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        if let millis = try attributes?.decodeIfPresent(Int.self, forKey: .durationInMillis) {
            duration = TimeInterval(millis) / 1000
        } else {
            duration = nil
        }
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("stations", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
        try attributes.encode(isLive, forKey: .isLive)
    }
}
