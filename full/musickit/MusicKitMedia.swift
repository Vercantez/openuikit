import Foundation

public struct Playlist: MusicItem, PlayableMusicItem, FilterableMusicItem, MusicLibraryRequestable,
    MusicCatalogSearchable, MusicLibrarySearchable, MusicLibraryAddable, MusicPlaylistAddable,
    MusicCatalogChartRequestable, MusicRecentlyPlayedRequestable, MusicPersonalRecommendationItem,
    PlaylistFilter, LibraryPlaylistFilter, LibraryPlaylistSortProperties,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = PlaylistFilter
    public typealias LibraryFilter = LibraryPlaylistFilter
    public typealias LibrarySortProperties = LibraryPlaylistSortProperties
    public typealias ID = MusicItemID

    public enum Kind: Hashable, Sendable, Codable {
        case userShared
        case personalMix
        case replay
        case external
        case editorial
    }

    public struct Entry: MusicItem, PlayableMusicItem, MusicLibraryRequestable,
        LibraryPlaylistEntryFilter, LibraryPlaylistEntrySortProperties,
        Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
    {
        public typealias LibraryFilter = LibraryPlaylistEntryFilter
        public typealias LibrarySortProperties = LibraryPlaylistEntrySortProperties
        public typealias ID = MusicItemID

        public enum Item: MusicItem, PlayableMusicItem, Hashable, Sendable, Codable,
            CustomStringConvertible, CustomDebugStringConvertible
        {
            case musicVideo(MusicVideo)
            case song(Song)

            public typealias ID = MusicItemID
            public var id: MusicItemID {
                switch self {
                case .musicVideo(let item): return item.id
                case .song(let item): return item.id
                }
            }
            public var albumTitle: String? {
                switch self {
                case .musicVideo(let item): return item.albumTitle
                case .song(let item): return item.albumTitle
                }
            }
            public var artistName: String {
                switch self {
                case .musicVideo(let item): return item.artistName
                case .song(let item): return item.artistName
                }
            }
            public var genreNames: [String] {
                switch self {
                case .musicVideo(let item): return item.genreNames
                case .song(let item): return item.genreNames
                }
            }
            public var description: String { title }
            public var releaseDate: Date? {
                switch self {
                case .musicVideo(let item): return item.releaseDate
                case .song(let item): return item.releaseDate
                }
            }
            public var contentRating: ContentRating? {
                switch self {
                case .musicVideo(let item): return item.contentRating
                case .song(let item): return item.contentRating
                }
            }
            public var previewAssets: [PreviewAsset]? {
                switch self {
                case .musicVideo(let item): return item.previewAssets
                case .song(let item): return item.previewAssets
                }
            }
            public var editorialNotes: EditorialNotes? {
                switch self {
                case .musicVideo(let item): return item.editorialNotes
                case .song(let item): return item.editorialNotes
                }
            }
            public var lastPlayedDate: Date? {
                switch self {
                case .musicVideo(let item): return item.lastPlayedDate
                case .song(let item): return item.lastPlayedDate
                }
            }
            public var playParameters: PlayParameters? {
                switch self {
                case .musicVideo(let item): return item.playParameters
                case .song(let item): return item.playParameters
                }
            }
            public var debugDescription: String { description }
            public var libraryAddedDate: Date? {
                switch self {
                case .musicVideo(let item): return item.libraryAddedDate
                case .song(let item): return item.libraryAddedDate
                }
            }
            public var url: URL? {
                switch self {
                case .musicVideo(let item): return item.url
                case .song(let item): return item.url
                }
            }
            public var isrc: String? {
                switch self {
                case .musicVideo(let item): return item.isrc
                case .song(let item): return item.isrc
                }
            }
            public var title: String {
                switch self {
                case .musicVideo(let item): return item.title
                case .song(let item): return item.title
                }
            }
            public var artwork: Artwork? {
                switch self {
                case .musicVideo(let item): return item.artwork
                case .song(let item): return item.artwork
                }
            }
            public var duration: TimeInterval? {
                switch self {
                case .musicVideo(let item): return item.duration
                case .song(let item): return item.duration
                }
            }
            public var artistURL: URL? {
                switch self {
                case .musicVideo(let item): return item.artistURL
                case .song(let item): return item.artistURL
                }
            }
            public var playCount: Int? {
                switch self {
                case .musicVideo(let item): return item.playCount
                case .song(let item): return item.playCount
                }
            }
        }

        public let id: MusicItemID
        public var albumTitle: String?
        public var artistName: String
        public var genreNames: [String]
        public var releaseDate: Date?
        public var contentRating: ContentRating?
        public var previewAssets: [PreviewAsset]?
        public var editorialNotes: EditorialNotes?
        public var lastPlayedDate: Date?
        public var playParameters: PlayParameters?
        public var libraryAddedDate: Date?
        public var url: URL?
        public var isrc: String?
        public var item: Item?
        public var title: String
        public var artwork: Artwork?
        public var duration: TimeInterval?
        public var position: Int
        public var artistURL: URL?
        public var playCount: Int?

        public init(id: MusicItemID, title: String, artistName: String = "", position: Int = 0, item: Item? = nil) {
            self.id = id
            self.title = title
            self.artistName = artistName
            self.genreNames = []
            self.position = position
            self.item = item
            self.playParameters = PlayParameters(id: id, kind: "playlist-entry")
        }

        public var description: String { title }
        public var debugDescription: String { "Playlist.Entry(\(id.rawValue) \(title))" }

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
            albumTitle = try attributes?.decodeIfPresent(String.self, forKey: .albumName)
            genreNames = (try attributes?.decodeIfPresent([String].self, forKey: .genreNames)) ?? []
            playParameters = try attributes?.decodeIfPresent(PlayParameters.self, forKey: .playParams)
            artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
            if let millis = try attributes?.decodeIfPresent(Int.self, forKey: .durationInMillis) {
                duration = TimeInterval(millis) / 1000
            } else {
                duration = nil
            }
            position = 0
            item = nil
        }

        public func encode(to encoder: any Encoder) throws {
            var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
            try root.encode(id.rawValue, forKey: .id)
            var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
            try attributes.encode(title, forKey: .name)
            try attributes.encode(artistName, forKey: .artistName)
        }
    }

    public let id: MusicItemID
    public var curatorName: String?
    public var moreByCurator: MusicItemCollection<Playlist>?
    public var lastPlayedDate: Date?
    public var playParameters: PlayParameters?
    public var featuredArtists: MusicItemCollection<Artist>?
    public var lastModifiedDate: Date?
    public var libraryAddedDate: Date?
    public var shortDescription: String?
    public var standardDescription: String?
    public var url: URL?
    public var kind: Kind?
    public var name: String
    public var tracks: MusicItemCollection<Track>?
    public var artwork: Artwork?
    public var curator: Curator?
    public var entries: MusicItemCollection<Entry>?
    public var isChart: Bool?
    public var radioShow: RadioShow?

    public init(id: MusicItemID, name: String, kind: Kind? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.playParameters = PlayParameters(id: id, kind: "playlist")
    }

    public var description: String { name }
    public var debugDescription: String { "Playlist(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        let attributes = parsed.attributes
        name = (try attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        curatorName = try attributes?.decodeIfPresent(String.self, forKey: .curatorName)
        shortDescription = try attributes?.decodeIfPresent(String.self, forKey: .shortDescription)
        standardDescription = try attributes?.decodeIfPresent(String.self, forKey: .standardDescription)
        isChart = try attributes?.decodeIfPresent(Bool.self, forKey: .isChart)
        artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        playParameters = try attributes?.decodeIfPresent(PlayParameters.self, forKey: .playParams)
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        if let raw = try attributes?.decodeIfPresent(String.self, forKey: .kind) {
            switch raw {
            case "user-shared", "userShared": kind = .userShared
            case "personal-mix", "personalMix": kind = .personalMix
            case "replay": kind = .replay
            case "external": kind = .external
            case "editorial": kind = .editorial
            default: kind = nil
            }
        } else {
            kind = nil
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("playlists", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
        try attributes.encodeIfPresent(artwork, forKey: .artwork)
    }
}

public struct MusicVideo: MusicItem, PlayableMusicItem, FilterableMusicItem, MusicLibraryRequestable,
    MusicCatalogSearchable, MusicLibrarySearchable, MusicLibraryAddable, MusicPlaylistAddable,
    MusicCatalogChartRequestable, MusicVideoFilter, LibraryMusicVideoFilter, LibraryMusicVideoSortProperties,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = MusicVideoFilter
    public typealias LibraryFilter = LibraryMusicVideoFilter
    public typealias LibrarySortProperties = LibraryMusicVideoSortProperties
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var albumTitle: String?
    public var artistName: String
    public var genreNames: [String]
    public var moreInGenre: MusicItemCollection<MusicVideo>?
    public var releaseDate: Date?
    public var trackNumber: Int?
    public var moreByArtist: MusicItemCollection<MusicVideo>?
    public var contentRating: ContentRating?
    public var previewAssets: [PreviewAsset]?
    public var editorialNotes: EditorialNotes?
    public var lastPlayedDate: Date?
    public var playParameters: PlayParameters?
    public var libraryAddedDate: Date?
    public var url: URL?
    public var isrc: String?
    public var has4K: Bool?
    public var songs: MusicItemCollection<Song>?
    public var title: String
    public var albums: MusicItemCollection<Album>?
    public var genres: MusicItemCollection<Genre>?
    public var hasHDR: Bool?
    public var artists: MusicItemCollection<Artist>?
    public var artwork: Artwork?
    public var duration: TimeInterval?
    public var workName: String?
    public var artistURL: URL?
    public var isPreview: Bool
    public var playCount: Int?

    public init(id: MusicItemID, title: String, artistName: String = "") {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.genreNames = []
        self.isPreview = false
        self.playParameters = PlayParameters(id: id, kind: "music-video")
    }

    public var description: String { title }
    public var debugDescription: String { "MusicVideo(\(id.rawValue) \(title))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        let attributes = parsed.attributes
        title = (try attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        artistName = (try attributes?.decodeIfPresent(String.self, forKey: .artistName)) ?? ""
        albumTitle = try attributes?.decodeIfPresent(String.self, forKey: .albumName)
        genreNames = (try attributes?.decodeIfPresent([String].self, forKey: .genreNames)) ?? []
        artwork = try attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        isrc = try attributes?.decodeIfPresent(String.self, forKey: .isrc)
        has4K = try attributes?.decodeIfPresent(Bool.self, forKey: .has4K)
        hasHDR = try attributes?.decodeIfPresent(Bool.self, forKey: .hasHDR)
        isPreview = (try attributes?.decodeIfPresent(Bool.self, forKey: .isPreview)) ?? false
        playParameters = try attributes?.decodeIfPresent(PlayParameters.self, forKey: .playParams)
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
        try root.encode("music-videos", forKey: .type)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(title, forKey: .name)
        try attributes.encode(artistName, forKey: .artistName)
    }
}

public enum Track: MusicItem, PlayableMusicItem, MusicLibraryRequestable,
    LibraryTrackFilter, LibraryTrackSortProperties, Hashable, Sendable, Codable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    case musicVideo(MusicVideo)
    case song(Song)

    public typealias LibraryFilter = LibraryTrackFilter
    public typealias LibrarySortProperties = LibraryTrackSortProperties
    public typealias ID = MusicItemID

    public var id: MusicItemID {
        switch self {
        case .musicVideo(let item): return item.id
        case .song(let item): return item.id
        }
    }
    public var albumTitle: String? {
        switch self {
        case .musicVideo(let item): return item.albumTitle
        case .song(let item): return item.albumTitle
        }
    }
    public var artistName: String {
        switch self {
        case .musicVideo(let item): return item.artistName
        case .song(let item): return item.artistName
        }
    }
    public var discNumber: Int? {
        switch self {
        case .song(let item): return item.discNumber
        case .musicVideo: return nil
        }
    }
    public var genreNames: [String] {
        switch self {
        case .musicVideo(let item): return item.genreNames
        case .song(let item): return item.genreNames
        }
    }
    public var description: String { title }
    public var releaseDate: Date? {
        switch self {
        case .musicVideo(let item): return item.releaseDate
        case .song(let item): return item.releaseDate
        }
    }
    public var trackNumber: Int? {
        switch self {
        case .musicVideo(let item): return item.trackNumber
        case .song(let item): return item.trackNumber
        }
    }
    public var contentRating: ContentRating? {
        switch self {
        case .musicVideo(let item): return item.contentRating
        case .song(let item): return item.contentRating
        }
    }
    public var previewAssets: [PreviewAsset]? {
        switch self {
        case .musicVideo(let item): return item.previewAssets
        case .song(let item): return item.previewAssets
        }
    }
    public var editorialNotes: EditorialNotes? {
        switch self {
        case .musicVideo(let item): return item.editorialNotes
        case .song(let item): return item.editorialNotes
        }
    }
    public var lastPlayedDate: Date? {
        switch self {
        case .musicVideo(let item): return item.lastPlayedDate
        case .song(let item): return item.lastPlayedDate
        }
    }
    public var playParameters: PlayParameters? {
        switch self {
        case .musicVideo(let item): return item.playParameters
        case .song(let item): return item.playParameters
        }
    }
    public var debugDescription: String { description }
    public var libraryAddedDate: Date? {
        switch self {
        case .musicVideo(let item): return item.libraryAddedDate
        case .song(let item): return item.libraryAddedDate
        }
    }
    public var url: URL? {
        switch self {
        case .musicVideo(let item): return item.url
        case .song(let item): return item.url
        }
    }
    public var isrc: String? {
        switch self {
        case .musicVideo(let item): return item.isrc
        case .song(let item): return item.isrc
        }
    }
    public var title: String {
        switch self {
        case .musicVideo(let item): return item.title
        case .song(let item): return item.title
        }
    }
    public var albums: MusicItemCollection<Album>? {
        switch self {
        case .musicVideo(let item): return item.albums
        case .song(let item): return item.albums
        }
    }
    public var artwork: Artwork? {
        switch self {
        case .musicVideo(let item): return item.artwork
        case .song(let item): return item.artwork
        }
    }
    public var duration: TimeInterval? {
        switch self {
        case .musicVideo(let item): return item.duration
        case .song(let item): return item.duration
        }
    }
    public var playCount: Int? {
        switch self {
        case .musicVideo(let item): return item.playCount
        case .song(let item): return item.playCount
        }
    }
}

public struct Curator: MusicItem, FilterableMusicItem, MusicCatalogSearchable, CuratorFilter,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = CuratorFilter
    public typealias ID = MusicItemID

    public enum Kind: Hashable, Sendable, Codable {
        case external
        case editorial
    }

    public let id: MusicItemID
    public var editorialNotes: EditorialNotes?
    public var url: URL?
    public var kind: Kind
    public var name: String
    public var artwork: Artwork?
    public var playlists: MusicItemCollection<Playlist>?

    public init(id: MusicItemID, name: String, kind: Kind = .editorial) {
        self.id = id
        self.name = name
        self.kind = kind
    }

    public var description: String { name }
    public var debugDescription: String { "Curator(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        name = (try parsed.attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        editorialNotes = try parsed.attributes?.decodeIfPresent(EditorialNotes.self, forKey: .editorialNotes)
        artwork = try parsed.attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        kind = .editorial
        if let raw = try parsed.attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        playlists = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
    }
}

public struct RecordLabel: MusicItem, FilterableMusicItem, MusicCatalogSearchable, RecordLabelFilter,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = RecordLabelFilter
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var topReleases: MusicItemCollection<Album>?
    public var latestReleases: MusicItemCollection<Album>?
    public var shortDescription: String?
    public var standardDescription: String?
    public var url: URL?
    public var name: String
    public var artwork: Artwork?

    public init(id: MusicItemID, name: String) {
        self.id = id
        self.name = name
    }

    public var description: String { name }
    public var debugDescription: String { "RecordLabel(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        name = (try parsed.attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        shortDescription = try parsed.attributes?.decodeIfPresent(String.self, forKey: .shortDescription)
        standardDescription = try parsed.attributes?.decodeIfPresent(String.self, forKey: .standardDescription)
        artwork = try parsed.attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        if let raw = try parsed.attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        topReleases = nil
        latestReleases = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
    }
}

public struct RadioShow: MusicItem, FilterableMusicItem, MusicCatalogSearchable, RadioShowFilter,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias FilterType = RadioShowFilter
    public typealias ID = MusicItemID

    public let id: MusicItemID
    public var editorialNotes: EditorialNotes?
    public var url: URL?
    public var name: String
    public var artwork: Artwork?
    public var hostName: String?
    public var playlists: MusicItemCollection<Playlist>?

    public init(id: MusicItemID, name: String, hostName: String? = nil) {
        self.id = id
        self.name = name
        self.hostName = hostName
    }

    public var description: String { name }
    public var debugDescription: String { "RadioShow(\(id.rawValue) \(name))" }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        name = (try parsed.attributes?.decodeIfPresent(String.self, forKey: .name)) ?? ""
        hostName = try parsed.attributes?.decodeIfPresent(String.self, forKey: .hostName)
        editorialNotes = try parsed.attributes?.decodeIfPresent(EditorialNotes.self, forKey: .editorialNotes)
        artwork = try parsed.attributes?.decodeIfPresent(Artwork.self, forKey: .artwork)
        if let raw = try parsed.attributes?.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        playlists = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        var attributes = root.nestedContainer(keyedBy: MusicResourceDecoder.AttrKey.self, forKey: .attributes)
        try attributes.encode(name, forKey: .name)
    }
}

public enum RecentlyPlayedMusicItem: MusicItem, PlayableMusicItem, MusicRecentlyPlayedRequestable,
    Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    case album(Album)
    case station(Station)
    case playlist(Playlist)

    public typealias ID = MusicItemID
    public var id: MusicItemID {
        switch self {
        case .album(let item): return item.id
        case .station(let item): return item.id
        case .playlist(let item): return item.id
        }
    }
    public var playParameters: PlayParameters? {
        switch self {
        case .album(let item): return item.playParameters
        case .station(let item): return item.playParameters
        case .playlist(let item): return item.playParameters
        }
    }
    public var title: String {
        switch self {
        case .album(let item): return item.title
        case .station(let item): return item.name
        case .playlist(let item): return item.name
        }
    }
    public var artwork: Artwork? {
        switch self {
        case .album(let item): return item.artwork
        case .station(let item): return item.artwork
        case .playlist(let item): return item.artwork
        }
    }
    public var subtitle: String? {
        switch self {
        case .album(let item): return item.artistName
        case .station(let item): return item.stationProviderName
        case .playlist(let item): return item.curatorName
        }
    }
    public var description: String { title }
    public var debugDescription: String { description }
}
