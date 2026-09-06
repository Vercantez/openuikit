import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct MusicDataRequest: Hashable, CustomStringConvertible {
    public let urlRequest: URLRequest
    public static var tokenProvider: any MusicUserTokenProvider & MusicDeveloperTokenProvider =
        DefaultMusicTokenProvider()

    public static func == (a: MusicDataRequest, b: MusicDataRequest) -> Bool {
        a.urlRequest.url == b.urlRequest.url
            && a.urlRequest.httpMethod == b.urlRequest.httpMethod
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(urlRequest.url)
        hasher.combine(urlRequest.httpMethod)
    }
    public static var currentCountryCode: String {
        get async throws {
            throw MusicKitPortableError.catalogUnavailable
        }
    }

    public init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }

    public var description: String {
        urlRequest.url?.absoluteString ?? "MusicDataRequest"
    }

    public func response() async throws -> MusicDataResponse {
        throw MusicKitPortableError.catalogUnavailable
    }

    public struct Error: Swift.Error, CustomStringConvertible {
        public let detailText: String
        public let originalResponse: MusicDataResponse
        public let id: String
        public let code: Int
        public let title: String
        public enum Source: Hashable, CustomStringConvertible {
            case parameter(String)
            public var description: String {
                switch self {
                case .parameter(let name): return name
                }
            }
        }
        public let source: Source?
        public let status: Int
        public var description: String { title }

        public init(
            id: String,
            title: String,
            detailText: String,
            code: Int,
            status: Int,
            source: Source?,
            originalResponse: MusicDataResponse
        ) {
            self.id = id
            self.title = title
            self.detailText = detailText
            self.code = code
            self.status = status
            self.source = source
            self.originalResponse = originalResponse
        }
    }
}

public struct MusicDataResponse: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let urlResponse: HTTPURLResponse
    public let data: Data

    public init(data: Data, urlResponse: HTTPURLResponse) {
        self.data = data
        self.urlResponse = urlResponse
    }

    public static func == (a: MusicDataResponse, b: MusicDataResponse) -> Bool {
        a.data == b.data && a.urlResponse.statusCode == b.urlResponse.statusCode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(urlResponse.statusCode)
    }

    public var description: String { "MusicDataResponse(\(urlResponse.statusCode))" }
    public var debugDescription: String { description }
}

open class MusicUserTokenProvider {
    public init() {}
    open func userToken(for developerToken: String, options: MusicTokenRequestOptions) async throws -> String {
        _ = (developerToken, options)
        throw MusicTokenRequestError.userNotSignedIn
    }
}

open class DefaultMusicTokenProvider: MusicUserTokenProvider, MusicDeveloperTokenProvider {
    public override init() { super.init() }
    open func developerToken(options: MusicTokenRequestOptions) async throws -> String {
        _ = options
        throw MusicTokenRequestError.developerTokenRequestFailed
    }
}

public struct MusicCatalogSearchRequest {
    public var includeTopResults = true
    public let term: String
    public var limit: Int?
    public var types: [any MusicCatalogSearchable.Type]
    public var offset: Int?

    public init(term: String, types: [any MusicCatalogSearchable.Type]) {
        self.term = term
        self.types = types
    }

    public func response() async throws -> MusicCatalogSearchResponse {
        throw MusicKitPortableError.catalogUnavailable
    }
}

public struct MusicCatalogSearchResponse: Hashable, Sendable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    public enum TopResult: MusicItem, Hashable, Sendable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible
    {
        case musicVideo(MusicVideo)
        case recordLabel(RecordLabel)
        case song(Song)
        case album(Album)
        case artist(Artist)
        case curator(Curator)
        case station(Station)
        case playlist(Playlist)
        case radioShow(RadioShow)

        public typealias ID = MusicItemID
        public var id: MusicItemID {
            switch self {
            case .musicVideo(let item): return item.id
            case .recordLabel(let item): return item.id
            case .song(let item): return item.id
            case .album(let item): return item.id
            case .artist(let item): return item.id
            case .curator(let item): return item.id
            case .station(let item): return item.id
            case .playlist(let item): return item.id
            case .radioShow(let item): return item.id
            }
        }
        public var title: String {
            switch self {
            case .musicVideo(let item): return item.title
            case .recordLabel(let item): return item.name
            case .song(let item): return item.title
            case .album(let item): return item.title
            case .artist(let item): return item.name
            case .curator(let item): return item.name
            case .station(let item): return item.name
            case .playlist(let item): return item.name
            case .radioShow(let item): return item.name
            }
        }
        public var artwork: Artwork? {
            switch self {
            case .musicVideo(let item): return item.artwork
            case .recordLabel(let item): return item.artwork
            case .song(let item): return item.artwork
            case .album(let item): return item.artwork
            case .artist(let item): return item.artwork
            case .curator(let item): return item.artwork
            case .station(let item): return item.artwork
            case .playlist(let item): return item.artwork
            case .radioShow(let item): return item.artwork
            }
        }
        public var description: String { title }
        public var debugDescription: String { title }

        public init(from decoder: any Decoder) throws {
            let root = try decoder.container(keyedBy: ResourceKey.self)
            let type = try root.decodeIfPresent(String.self, forKey: .type) ?? ""
            switch type {
            case "music-videos": self = .musicVideo(try MusicVideo(from: decoder))
            case "record-labels": self = .recordLabel(try RecordLabel(from: decoder))
            case "songs": self = .song(try Song(from: decoder))
            case "albums": self = .album(try Album(from: decoder))
            case "artists": self = .artist(try Artist(from: decoder))
            case "apple-curators", "curators": self = .curator(try Curator(from: decoder))
            case "stations": self = .station(try Station(from: decoder))
            case "playlists": self = .playlist(try Playlist(from: decoder))
            case "radio-shows": self = .radioShow(try RadioShow(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: root,
                    debugDescription: "unknown search top result \(type)"
                )
            }
        }

        public func encode(to encoder: any Encoder) throws {
            switch self {
            case .musicVideo(let item): try item.encode(to: encoder)
            case .recordLabel(let item): try item.encode(to: encoder)
            case .song(let item): try item.encode(to: encoder)
            case .album(let item): try item.encode(to: encoder)
            case .artist(let item): try item.encode(to: encoder)
            case .curator(let item): try item.encode(to: encoder)
            case .station(let item): try item.encode(to: encoder)
            case .playlist(let item): try item.encode(to: encoder)
            case .radioShow(let item): try item.encode(to: encoder)
            }
        }

        private enum ResourceKey: String, CodingKey { case type }
    }

    public let radioShows: MusicItemCollection<RadioShow>
    public let topResults: MusicItemCollection<TopResult>
    public let musicVideos: MusicItemCollection<MusicVideo>
    public let recordLabels: MusicItemCollection<RecordLabel>
    public let songs: MusicItemCollection<Song>
    public let albums: MusicItemCollection<Album>
    public let artists: MusicItemCollection<Artist>
    public let curators: MusicItemCollection<Curator>
    public let stations: MusicItemCollection<Station>
    public let playlists: MusicItemCollection<Playlist>

    public init() {
        radioShows = MusicItemCollection([])
        topResults = MusicItemCollection([])
        musicVideos = MusicItemCollection([])
        recordLabels = MusicItemCollection([])
        songs = MusicItemCollection([])
        albums = MusicItemCollection([])
        artists = MusicItemCollection([])
        curators = MusicItemCollection([])
        stations = MusicItemCollection([])
        playlists = MusicItemCollection([])
    }

    public var description: String { "MusicCatalogSearchResponse(songs: \(songs.count))" }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let results = try MusicKitJSON.resultsContainer(from: decoder)
        radioShows = MusicKitJSON.decodeCollection(results, keys: "radio-shows", "radioShows")
        topResults = MusicKitJSON.decodeCollection(results, keys: "top", "topResults")
        musicVideos = MusicKitJSON.decodeCollection(results, keys: "music-videos", "musicVideos")
        recordLabels = MusicKitJSON.decodeCollection(results, keys: "record-labels", "recordLabels")
        songs = MusicKitJSON.decodeCollection(results, keys: "songs")
        albums = MusicKitJSON.decodeCollection(results, keys: "albums")
        artists = MusicKitJSON.decodeCollection(results, keys: "artists")
        curators = MusicKitJSON.decodeCollection(results, keys: "apple-curators", "curators")
        stations = MusicKitJSON.decodeCollection(results, keys: "stations")
        playlists = MusicKitJSON.decodeCollection(results, keys: "playlists")
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicKitJSON.FlexibleKey.self)
        var results = root.nestedContainer(keyedBy: MusicKitJSON.FlexibleKey.self, forKey: MusicKitJSON.FlexibleKey("results"))
        try MusicKitJSON.encodeCollection(songs, into: &results, key: "songs")
        try MusicKitJSON.encodeCollection(albums, into: &results, key: "albums")
        try MusicKitJSON.encodeCollection(artists, into: &results, key: "artists")
        try MusicKitJSON.encodeCollection(playlists, into: &results, key: "playlists")
        try MusicKitJSON.encodeCollection(musicVideos, into: &results, key: "music-videos")
        try MusicKitJSON.encodeCollection(recordLabels, into: &results, key: "record-labels")
        try MusicKitJSON.encodeCollection(curators, into: &results, key: "apple-curators")
        try MusicKitJSON.encodeCollection(stations, into: &results, key: "stations")
        try MusicKitJSON.encodeCollection(radioShows, into: &results, key: "radio-shows")
        try MusicKitJSON.encodeCollection(topResults, into: &results, key: "top")
    }
}

public struct MusicCatalogChartsRequest: Hashable {
    public var genre: Genre?
    public var kinds: [MusicCatalogChartKind]
    public var limit: Int?
    public var types: [any MusicCatalogChartRequestable.Type]
    public var offset: Int?

    public init(
        genre: Genre? = nil,
        kinds: [MusicCatalogChartKind] = [.mostPlayed],
        types: [any MusicCatalogChartRequestable.Type]
    ) {
        self.genre = genre
        self.kinds = kinds
        self.types = types
    }

    public func response() async throws -> MusicCatalogChartsResponse {
        throw MusicKitPortableError.catalogUnavailable
    }

    public static func == (a: MusicCatalogChartsRequest, b: MusicCatalogChartsRequest) -> Bool {
        a.genre == b.genre && a.kinds == b.kinds && a.limit == b.limit && a.offset == b.offset
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(genre)
        hasher.combine(kinds)
        hasher.combine(limit)
        hasher.combine(offset)
    }
}

public struct MusicCatalogChart<MusicItemType: MusicCatalogChartRequestable & Hashable & Codable>: Hashable,
    Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible
{
    public typealias ID = String
    public let id: String
    public let kind: MusicCatalogChartKind
    public let items: MusicItemCollection<MusicItemType>
    public let title: String

    public init(
        id: String = "",
        kind: MusicCatalogChartKind,
        title: String,
        items: MusicItemCollection<MusicItemType> = MusicItemCollection([])
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.items = items
    }

    public var description: String { title }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(String.self, forKey: .chart)
            ?? ""
        if let kind = try container.decodeIfPresent(MusicCatalogChartKind.self, forKey: .kind) {
            self.kind = kind
        } else if let kind = try container.decodeIfPresent(MusicCatalogChartKind.self, forKey: .chart) {
            self.kind = kind
        } else {
            self.kind = .mostPlayed
        }
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? ""
        items = try container.decodeIfPresent(MusicItemCollection<MusicItemType>.self, forKey: .data)
            ?? MusicItemCollection([])
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .chart)
        try container.encode(title, forKey: .name)
        try container.encode(items, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey { case id, kind, title, name, data, chart }
}

public struct MusicCatalogChartsResponse: Hashable, Sendable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    public var songCharts: [MusicCatalogChart<Song>]
    public var albumCharts: [MusicCatalogChart<Album>]
    public var playlistCharts: [MusicCatalogChart<Playlist>]
    public var musicVideoCharts: [MusicCatalogChart<MusicVideo>]
    public init() {
        songCharts = []
        albumCharts = []
        playlistCharts = []
        musicVideoCharts = []
    }

    public var description: String { "MusicCatalogChartsResponse(songs: \(songCharts.count))" }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let results = try MusicKitJSON.resultsContainer(from: decoder)
        func charts<T: MusicCatalogChartRequestable & Hashable & Codable>(
            _ keys: String...
        ) -> [MusicCatalogChart<T>] {
            for key in keys {
                if let value = try? results.decode([MusicCatalogChart<T>].self, forKey: MusicKitJSON.FlexibleKey(key)) {
                    return value
                }
            }
            return []
        }
        songCharts = charts("songs")
        albumCharts = charts("albums")
        playlistCharts = charts("playlists")
        musicVideoCharts = charts("music-videos", "musicVideos")
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicKitJSON.FlexibleKey.self)
        var results = root.nestedContainer(
            keyedBy: MusicKitJSON.FlexibleKey.self,
            forKey: MusicKitJSON.FlexibleKey("results")
        )
        try results.encode(songCharts, forKey: MusicKitJSON.FlexibleKey("songs"))
        try results.encode(albumCharts, forKey: MusicKitJSON.FlexibleKey("albums"))
        try results.encode(playlistCharts, forKey: MusicKitJSON.FlexibleKey("playlists"))
        try results.encode(musicVideoCharts, forKey: MusicKitJSON.FlexibleKey("music-videos"))
    }
}

public struct MusicCatalogResourceRequest<MusicItemType: MusicItem & Decodable & Hashable> {
    public var properties: [PartialMusicAsyncProperty<MusicItemType>] = []
    public var limit: Int?
    var equalDescription: String?

    public init() where MusicItemType: MusicCatalogTopLevelResourceRequesting {}

    public init<Value>(
        matching keyPath: KeyPath<MusicItemType, Value>,
        equalTo value: Value
    ) {
        equalDescription = "\(String(describing: keyPath))=\(String(describing: value))"
    }

    public init<Value>(
        matching keyPath: KeyPath<MusicItemType, Value>,
        memberOf values: [Value]
    ) {
        equalDescription = "\(String(describing: keyPath)) in \(values.count)"
    }

    public func response() async throws -> MusicCatalogResourceResponse<MusicItemType> {
        throw MusicKitPortableError.catalogUnavailable
    }
}

public struct MusicCatalogResourceResponse<MusicItemType: MusicItem & Hashable>: Hashable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    public var items: MusicItemCollection<MusicItemType>
    public init(items: MusicItemCollection<MusicItemType> = MusicItemCollection([])) {
        self.items = items
    }
    public var description: String { "MusicCatalogResourceResponse(\(items.count))" }
    public var debugDescription: String { description }
}

public struct MusicRecentlyPlayedRequest<MusicItemType: MusicRecentlyPlayedRequestable & Hashable> {
    public var limit: Int?
    public var offset: Int?
    public init() {}
    public func response() async throws -> MusicRecentlyPlayedResponse<MusicItemType> {
        throw MusicKitPortableError.catalogUnavailable
    }
}

public struct MusicRecentlyPlayedResponse<MusicItemType: MusicRecentlyPlayedRequestable & Hashable>: Hashable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    public var items: MusicItemCollection<MusicItemType>
    public init(items: MusicItemCollection<MusicItemType> = MusicItemCollection([])) {
        self.items = items
    }
    public var description: String { "MusicRecentlyPlayedResponse(\(items.count))" }
    public var debugDescription: String { description }
}

public typealias MusicRecentlyPlayedContainerRequest = MusicRecentlyPlayedRequest<RecentlyPlayedMusicItem>
public typealias MusicRecentlyPlayedContainerResponse = MusicRecentlyPlayedResponse<RecentlyPlayedMusicItem>
public typealias MusicTokenProvider = MusicUserTokenProvider & MusicDeveloperTokenProvider

public struct MusicPersonalRecommendationsRequest: Hashable {
    public var limit: Int?
    public var offset: Int?
    var refreshingIDs: [MusicItemID] = []

    public init() {}
    public init<S>(refreshing recommendations: S)
        where S: Sequence, S.Element == MusicPersonalRecommendation
    {
        refreshingIDs = Array(recommendations).map(\.id)
    }
    public func response() async throws -> MusicPersonalRecommendationsResponse {
        throw MusicKitPortableError.catalogUnavailable
    }

    public static func == (
        a: MusicPersonalRecommendationsRequest,
        b: MusicPersonalRecommendationsRequest
    ) -> Bool {
        a.limit == b.limit && a.offset == b.offset && a.refreshingIDs == b.refreshingIDs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(limit)
        hasher.combine(offset)
        hasher.combine(refreshingIDs)
    }
}

public struct MusicPersonalRecommendation: MusicItem, Hashable, Sendable, Codable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    public enum Item: MusicItem, Hashable, Sendable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible
    {
        case album(Album)
        case station(Station)
        case playlist(Playlist)
        case song(Song)

        public typealias ID = MusicItemID
        public var id: MusicItemID {
            switch self {
            case .album(let item): return item.id
            case .station(let item): return item.id
            case .playlist(let item): return item.id
            case .song(let item): return item.id
            }
        }
        public var title: String {
            switch self {
            case .album(let item): return item.title
            case .station(let item): return item.name
            case .playlist(let item): return item.name
            case .song(let item): return item.title
            }
        }
        public var subtitle: String? {
            switch self {
            case .album(let item): return item.artistName
            case .station: return nil
            case .playlist: return nil
            case .song(let item): return item.artistName
            }
        }
        public var artwork: Artwork? {
            switch self {
            case .album(let item): return item.artwork
            case .station(let item): return item.artwork
            case .playlist(let item): return item.artwork
            case .song(let item): return item.artwork
            }
        }
        public var description: String { title }
        public var debugDescription: String { title }

        public init(from decoder: any Decoder) throws {
            let root = try decoder.container(keyedBy: ResourceKey.self)
            let type = try root.decodeIfPresent(String.self, forKey: .type) ?? ""
            switch type {
            case "albums": self = .album(try Album(from: decoder))
            case "stations": self = .station(try Station(from: decoder))
            case "playlists": self = .playlist(try Playlist(from: decoder))
            case "songs": self = .song(try Song(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: root,
                    debugDescription: "unknown personal recommendation item \(type)"
                )
            }
        }

        public func encode(to encoder: any Encoder) throws {
            switch self {
            case .album(let item): try item.encode(to: encoder)
            case .station(let item): try item.encode(to: encoder)
            case .playlist(let item): try item.encode(to: encoder)
            case .song(let item): try item.encode(to: encoder)
            }
        }

        private enum ResourceKey: String, CodingKey { case type }
    }

    public typealias ID = MusicItemID
    public let id: MusicItemID
    public var title: String?
    public var reason: String?
    public var nextRefreshDate: Date?
    public var items: MusicItemCollection<Item>
    public var types: [any MusicPersonalRecommendationItem.Type] {
        var seen = Set<String>()
        var result: [any MusicPersonalRecommendationItem.Type] = []
        for item in items {
            switch item {
            case .album:
                if seen.insert("album").inserted { result.append(Album.self) }
            case .station:
                if seen.insert("station").inserted { result.append(Station.self) }
            case .playlist:
                if seen.insert("playlist").inserted { result.append(Playlist.self) }
            case .song:
                if seen.insert("song").inserted { result.append(Song.self) }
            }
        }
        return result.isEmpty ? [Album.self, Station.self, Playlist.self] : result
    }
    public var albums: MusicItemCollection<Album> {
        MusicItemCollection(items.compactMap { if case .album(let item) = $0 { return item }; return nil })
    }
    public var stations: MusicItemCollection<Station> {
        MusicItemCollection(items.compactMap { if case .station(let item) = $0 { return item }; return nil })
    }
    public var playlists: MusicItemCollection<Playlist> {
        MusicItemCollection(items.compactMap { if case .playlist(let item) = $0 { return item }; return nil })
    }

    public init(
        id: MusicItemID,
        title: String? = nil,
        reason: String? = nil,
        nextRefreshDate: Date? = nil,
        items: MusicItemCollection<Item> = MusicItemCollection([])
    ) {
        self.id = id
        self.title = title
        self.reason = reason
        self.nextRefreshDate = nextRefreshDate
        self.items = items
    }

    public var description: String { title ?? id.rawValue }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let parsed = try MusicResourceDecoder.container(decoder)
        id = parsed.id
        title = MusicResourceDecoder.decodeDisplay(parsed.attributes, key: .title)
            ?? MusicResourceDecoder.decodeDisplay(parsed.attributes, key: .name)
        reason = MusicResourceDecoder.decodeDisplay(parsed.attributes, key: .reason)
        nextRefreshDate = MusicKitJSON.decodeDate(
            try parsed.attributes?.decodeIfPresent(String.self, forKey: .nextRefreshDate)
        )
        let root = try decoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        if let relationships = try? root.nestedContainer(
            keyedBy: RelationshipKey.self,
            forKey: .relationships
        ), let contents = try? relationships.decode(MusicItemCollection<Item>.self, forKey: .contents) {
            items = contents
        } else {
            items = MusicItemCollection([])
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicResourceDecoder.RootKey.self)
        try root.encode(id.rawValue, forKey: .id)
        try root.encode("personal-recommendation", forKey: .type)
        var attributes = root.nestedContainer(
            keyedBy: MusicResourceDecoder.AttrKey.self,
            forKey: .attributes
        )
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(reason, forKey: .reason)
        if let nextRefreshDate {
            try attributes.encode(
                ISO8601DateFormatter().string(from: nextRefreshDate),
                forKey: .nextRefreshDate
            )
        }
        var relationships = root.nestedContainer(keyedBy: RelationshipKey.self, forKey: .relationships)
        try relationships.encode(items, forKey: .contents)
    }

    private enum RelationshipKey: String, CodingKey { case contents }
}

public struct MusicPersonalRecommendationsResponse: Hashable, Sendable, Codable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    public var recommendations: MusicItemCollection<MusicPersonalRecommendation>
    public init(recommendations: MusicItemCollection<MusicPersonalRecommendation> = MusicItemCollection([])) {
        self.recommendations = recommendations
    }

    public var description: String { "MusicPersonalRecommendationsResponse(\(recommendations.count))" }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let root = try decoder.container(keyedBy: MusicKitJSON.FlexibleKey.self)
        if let items = try? root.decode(
            [MusicPersonalRecommendation].self,
            forKey: MusicKitJSON.FlexibleKey("data")
        ) {
            recommendations = MusicItemCollection(items)
        } else {
            recommendations = (try? MusicItemCollection(from: decoder)) ?? MusicItemCollection([])
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicKitJSON.FlexibleKey.self)
        try root.encode(Array(recommendations), forKey: MusicKitJSON.FlexibleKey("data"))
    }
}

public struct MusicCatalogSearchSuggestionsRequest {
    public var typesForTopResults: [any MusicCatalogSearchable.Type]
    public let term: String
    public var limit: Int?

    public init(term: String, includingTopResultsOfTypes types: [any MusicCatalogSearchable.Type] = []) {
        self.term = term
        self.typesForTopResults = types
    }

    public func response() async throws -> MusicCatalogSearchSuggestionsResponse {
        throw MusicKitPortableError.catalogUnavailable
    }
}

public struct MusicCatalogSearchSuggestionsResponse: Hashable, Sendable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    public typealias TopResult = MusicCatalogSearchResponse.TopResult

    public struct Suggestion: Hashable, Sendable, Identifiable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible
    {
        public typealias ID = String
        public let displayTerm: String
        public let searchTerm: String
        public var id: String { searchTerm }
        public init(displayTerm: String, searchTerm: String) {
            self.displayTerm = displayTerm
            self.searchTerm = searchTerm
        }
        public var description: String { displayTerm }
        public var debugDescription: String { displayTerm }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let display = try container.decodeIfPresent(String.self, forKey: .displayTerm)
            let search = try container.decodeIfPresent(String.self, forKey: .searchTerm)
            displayTerm = display ?? search ?? ""
            searchTerm = search ?? displayTerm
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(displayTerm, forKey: .displayTerm)
            try container.encode(searchTerm, forKey: .searchTerm)
        }

        private enum CodingKeys: String, CodingKey { case displayTerm, searchTerm }
    }

    public var suggestions: [Suggestion]
    public var topResults: MusicItemCollection<TopResult>
    public init(
        suggestions: [Suggestion] = [],
        topResults: MusicItemCollection<TopResult> = MusicItemCollection([])
    ) {
        self.suggestions = suggestions
        self.topResults = topResults
    }

    public var description: String { "MusicCatalogSearchSuggestionsResponse(\(suggestions.count))" }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let results = try MusicKitJSON.resultsContainer(from: decoder)
        if let terms = try? results.decode([Suggestion].self, forKey: MusicKitJSON.FlexibleKey("suggestions")) {
            suggestions = terms
        } else if let terms = try? results.decode([Suggestion].self, forKey: MusicKitJSON.FlexibleKey("terms")) {
            suggestions = terms
        } else {
            suggestions = []
        }
        topResults = MusicKitJSON.decodeCollection(results, keys: "topResults", "top")
    }

    public func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: MusicKitJSON.FlexibleKey.self)
        var results = root.nestedContainer(
            keyedBy: MusicKitJSON.FlexibleKey.self,
            forKey: MusicKitJSON.FlexibleKey("results")
        )
        try results.encode(suggestions, forKey: MusicKitJSON.FlexibleKey("suggestions"))
        try MusicKitJSON.encodeCollection(topResults, into: &results, key: "topResults")
    }
}
