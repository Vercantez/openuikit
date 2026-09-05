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

public struct MusicCatalogChart<MusicItemType: MusicCatalogChartRequestable & Hashable>: Hashable {
    public var kind: MusicCatalogChartKind
    public var title: String
    public var items: MusicItemCollection<MusicItemType>
    public init(
        kind: MusicCatalogChartKind,
        title: String,
        items: MusicItemCollection<MusicItemType> = MusicItemCollection([])
    ) {
        self.kind = kind
        self.title = title
        self.items = items
    }
}

public struct MusicCatalogChartsResponse: Hashable {
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

public struct MusicCatalogResourceResponse<MusicItemType: MusicItem & Hashable>: Hashable {
    public var items: MusicItemCollection<MusicItemType>
    public init(items: MusicItemCollection<MusicItemType> = MusicItemCollection([])) {
        self.items = items
    }
}

public struct MusicRecentlyPlayedRequest<MusicItemType: MusicRecentlyPlayedRequestable & Hashable> {
    public var limit: Int?
    public var offset: Int?
    public init() {}
    public func response() async throws -> MusicRecentlyPlayedResponse<MusicItemType> {
        throw MusicKitPortableError.catalogUnavailable
    }
}

public struct MusicRecentlyPlayedResponse<MusicItemType: MusicRecentlyPlayedRequestable & Hashable>: Hashable {
    public var items: MusicItemCollection<MusicItemType>
    public init(items: MusicItemCollection<MusicItemType> = MusicItemCollection([])) {
        self.items = items
    }
}

public struct MusicPersonalRecommendationsRequest: Hashable {
    public var limit: Int?
    public var offset: Int?
    public init() {}
    public init<S>(refreshing recommendations: S)
        where S: Sequence, S.Element == MusicPersonalRecommendation
    {
        _ = Array(recommendations)
    }
    public func response() async throws -> MusicPersonalRecommendationsResponse {
        throw MusicKitPortableError.catalogUnavailable
    }
}

public struct MusicPersonalRecommendation: MusicItem, Hashable, Sendable {
    public enum Item: MusicItem, Hashable, Sendable {
        case album(Album)
        case station(Station)
        case playlist(Playlist)
        case song(Song)
        public var id: MusicItemID {
            switch self {
            case .album(let item): return item.id
            case .station(let item): return item.id
            case .playlist(let item): return item.id
            case .song(let item): return item.id
            }
        }
    }

    public let id: MusicItemID
    public var title: String
    public var items: MusicItemCollection<Item>
    public init(id: MusicItemID, title: String, items: MusicItemCollection<Item> = MusicItemCollection([])) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public struct MusicPersonalRecommendationsResponse: Hashable {
    public var recommendations: MusicItemCollection<MusicPersonalRecommendation>
    public init(recommendations: MusicItemCollection<MusicPersonalRecommendation> = MusicItemCollection([])) {
        self.recommendations = recommendations
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

public struct MusicCatalogSearchSuggestionsResponse: Hashable {
    public struct Suggestion: Hashable, Sendable {
        public var displayTerm: String
        public var searchTerm: String
        public init(displayTerm: String, searchTerm: String) {
            self.displayTerm = displayTerm
            self.searchTerm = searchTerm
        }
    }

    public var suggestions: [Suggestion]
    public var topResults: MusicItemCollection<MusicCatalogSearchResponse.TopResult>
    public init(
        suggestions: [Suggestion] = [],
        topResults: MusicItemCollection<MusicCatalogSearchResponse.TopResult> = MusicItemCollection([])
    ) {
        self.suggestions = suggestions
        self.topResults = topResults
    }
}
