import Foundation

public final class MusicLibrary {
    public static let shared = MusicLibrary()

    public enum Error: String, Swift.Error, Sendable, LocalizedError, CustomStringConvertible {
        case playlistNotInLibrary
        case unableToAddItem
        case itemAlreadyAdded
        case permissionDenied
        case editPlaylistFailed
        case addToPlaylistFailed
        case createPlaylistFailed
        case unknown

        public typealias RawValue = String
        public var description: String { rawValue }
        public var errorDescription: String? { rawValue }
        public var failureReason: String? { rawValue }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
    }

    public func createPlaylist<S, MusicPlaylistAddableType>(
        name: String,
        description: String? = nil,
        authorDisplayName: String? = nil,
        items: S
    ) async throws -> Playlist
        where S: Sequence, MusicPlaylistAddableType: MusicPlaylistAddable, S.Element == MusicPlaylistAddableType
    {
        _ = (name, description, authorDisplayName, Array(items))
        throw Error.permissionDenied
    }

    public func createPlaylist(
        name: String,
        description: String? = nil,
        authorDisplayName: String? = nil
    ) async throws -> Playlist {
        _ = (name, description, authorDisplayName)
        throw Error.permissionDenied
    }

    @discardableResult
    public func add<MusicItemType: MusicPlaylistAddable>(
        _ item: MusicItemType,
        to playlist: Playlist
    ) async throws -> Playlist {
        _ = (item, playlist)
        throw Error.permissionDenied
    }

    public func add<MusicItemType: MusicLibraryAddable>(_ item: MusicItemType) async throws {
        _ = item
        throw Error.permissionDenied
    }

    @discardableResult
    public func edit<S, MusicPlaylistAddableType>(
        _ playlist: Playlist,
        name: String? = nil,
        description: String? = nil,
        authorDisplayName: String? = nil,
        items: S
    ) async throws -> Playlist
        where S: Sequence, MusicPlaylistAddableType: MusicPlaylistAddable, S.Element == MusicPlaylistAddableType
    {
        _ = (playlist, name, description, authorDisplayName, Array(items))
        throw Error.permissionDenied
    }

    @discardableResult
    public func edit(
        _ playlist: Playlist,
        name: String? = nil,
        description: String? = nil,
        authorDisplayName: String? = nil
    ) async throws -> Playlist {
        _ = (playlist, name, description, authorDisplayName)
        throw Error.permissionDenied
    }
}

public struct MusicLibraryRequest<MusicItemType: MusicLibraryRequestable & Hashable> {
    public var includeOnlyDownloadedContent = false
    public var limit: Int = 0
    public var offset: Int = 0
    var textFilter: String?
    var equalFilters: [(String, String)] = []
    var sortAscending = true
    var sortDescription: String?

    public init() {}

    public mutating func sort<Value>(
        by keyPath: KeyPath<MusicItemType, Value>,
        ascending: Bool
    ) {
        sortAscending = ascending
        sortDescription = String(describing: keyPath)
    }

    public mutating func filter(text: String) {
        textFilter = text
    }

    public mutating func filter<Value: MusicLibraryRequestFilterValueEquatable>(
        matching keyPath: KeyPath<MusicItemType, Value>,
        equalTo value: Value
    ) {
        equalFilters.append((String(describing: keyPath), String(describing: value)))
    }

    public mutating func filter<Value: MusicLibraryRequestFilterValueEquatable>(
        matching keyPath: KeyPath<MusicItemType, Value?>,
        equalTo value: Value?
    ) {
        equalFilters.append((String(describing: keyPath), String(describing: value)))
    }

    public mutating func filter<RelatedMusicItemType: MusicItem>(
        matching keyPath: KeyPath<MusicItemType, MusicItemCollection<RelatedMusicItemType>?>,
        contains item: RelatedMusicItemType
    ) {
        equalFilters.append((String(describing: keyPath), item.id.rawValue))
    }

    public mutating func filter(
        matching keyPath: KeyPath<MusicItemType, String>,
        contains text: String
    ) {
        equalFilters.append((String(describing: keyPath), text))
    }

    public mutating func filter(
        matching keyPath: KeyPath<MusicItemType, String?>,
        contains text: String
    ) {
        equalFilters.append((String(describing: keyPath), text))
    }

    public mutating func filter<Value: MusicLibraryRequestFilterValueMembershipComparable>(
        matching keyPath: KeyPath<MusicItemType, Value>,
        memberOf values: [Value]
    ) {
        equalFilters.append((String(describing: keyPath), values.map { String(describing: $0) }.joined(separator: ",")))
    }

    public mutating func filter<Value: MusicLibraryRequestFilterValueMembershipComparable>(
        matching keyPath: KeyPath<MusicItemType, Value?>,
        memberOf values: [Value?]
    ) {
        equalFilters.append((String(describing: keyPath), values.map { String(describing: $0) }.joined(separator: ",")))
    }

    public func response() async throws -> MusicLibraryResponse<MusicItemType> {
        throw MusicLibrary.Error.permissionDenied
    }
}

public struct MusicLibraryResponse<MusicItemType: MusicItem & Hashable>: Hashable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    public let items: MusicItemCollection<MusicItemType>
    public init(items: MusicItemCollection<MusicItemType> = MusicItemCollection([])) {
        self.items = items
    }
    public var description: String { "MusicLibraryResponse(\(items.count))" }
    public var debugDescription: String { description }
}

@dynamicMemberLookup
public struct MusicLibrarySection<SectionType, MusicItemType: MusicItem & Hashable>: Hashable,
    CustomStringConvertible, CustomDebugStringConvertible
    where SectionType: MusicLibrarySectionRequestable & Hashable
{
    public typealias ID = MusicItemID
    public var id: MusicItemID
    public let items: MusicItemCollection<MusicItemType>
    let section: SectionType

    public init(id: MusicItemID, section: SectionType, items: MusicItemCollection<MusicItemType>) {
        self.id = id
        self.section = section
        self.items = items
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<SectionType, T>) -> T {
        section[keyPath: keyPath]
    }

    public var description: String { "MusicLibrarySection(\(id.rawValue))" }
    public var debugDescription: String { description }
}

public struct MusicLibrarySectionedRequest<SectionType, MusicItemType: MusicLibraryRequestable & Hashable>
    where SectionType: MusicLibrarySectionRequestable & Hashable
{
    public var includeOnlyDownloadedContent = false
    public var limit: Int = 0
    public var offset: Int = 0
    var textFilter: String?
    var sectionTextFilter: String?

    public init() {}

    public mutating func filterItems(text: String) {
        textFilter = text
    }

    public mutating func filterItems<Value: MusicLibraryRequestFilterValueEquatable>(
        matching keyPath: KeyPath<MusicItemType, Value>,
        equalTo value: Value
    ) {
        _ = (keyPath, value)
        textFilter = String(describing: value)
    }

    public mutating func filterItems<Value: MusicLibraryRequestFilterValueEquatable>(
        matching keyPath: KeyPath<MusicItemType, Value?>,
        equalTo value: Value?
    ) {
        _ = (keyPath, value)
        textFilter = String(describing: value)
    }

    public mutating func filterItems<RelatedMusicItemType: MusicItem>(
        matching keyPath: KeyPath<MusicItemType, MusicItemCollection<RelatedMusicItemType>?>,
        contains relatedItem: RelatedMusicItemType
    ) {
        _ = keyPath
        textFilter = relatedItem.id.rawValue
    }

    public mutating func filterItems(
        matching keyPath: KeyPath<MusicItemType, String>,
        contains text: String
    ) {
        _ = keyPath
        textFilter = text
    }

    public mutating func filterItems(
        matching keyPath: KeyPath<MusicItemType, String?>,
        contains text: String
    ) {
        _ = keyPath
        textFilter = text
    }

    public mutating func filterItems<Value: MusicLibraryRequestFilterValueMembershipComparable>(
        matching keyPath: KeyPath<MusicItemType, Value>,
        memberOf values: [Value]
    ) {
        _ = keyPath
        textFilter = values.map { String(describing: $0) }.joined(separator: ",")
    }

    public mutating func filterItems<Value: MusicLibraryRequestFilterValueMembershipComparable>(
        matching keyPath: KeyPath<MusicItemType, Value?>,
        memberOf values: [Value?]
    ) {
        _ = keyPath
        textFilter = values.map { String(describing: $0) }.joined(separator: ",")
    }

    public mutating func sortItems<Value>(
        by keyPath: KeyPath<MusicItemType, Value>,
        ascending: Bool
    ) {
        _ = (keyPath, ascending)
    }

    public mutating func filterSections(text: String) {
        sectionTextFilter = text
    }

    public mutating func filterSections<Value: MusicLibraryRequestFilterValueEquatable>(
        matching keyPath: KeyPath<SectionType, Value>,
        equalTo value: Value
    ) {
        _ = (keyPath, value)
        sectionTextFilter = String(describing: value)
    }

    public mutating func filterSections<Value: MusicLibraryRequestFilterValueEquatable>(
        matching keyPath: KeyPath<SectionType, Value?>,
        equalTo value: Value?
    ) {
        _ = (keyPath, value)
        sectionTextFilter = String(describing: value)
    }

    public mutating func filterSections(
        matching keyPath: KeyPath<SectionType, String>,
        contains text: String
    ) {
        _ = keyPath
        sectionTextFilter = text
    }

    public mutating func filterSections(
        matching keyPath: KeyPath<SectionType, String?>,
        contains text: String
    ) {
        _ = keyPath
        sectionTextFilter = text
    }

    public mutating func filterSections<Value: MusicLibraryRequestFilterValueMembershipComparable>(
        matching keyPath: KeyPath<SectionType, Value>,
        memberOf values: [Value]
    ) {
        _ = keyPath
        sectionTextFilter = values.map { String(describing: $0) }.joined(separator: ",")
    }

    public mutating func filterSections<Value: MusicLibraryRequestFilterValueMembershipComparable>(
        matching keyPath: KeyPath<SectionType, Value?>,
        memberOf values: [Value?]
    ) {
        _ = keyPath
        sectionTextFilter = values.map { String(describing: $0) }.joined(separator: ",")
    }

    public mutating func sortSections<Value>(
        by keyPath: KeyPath<SectionType, Value>,
        ascending: Bool
    ) {
        _ = (keyPath, ascending)
    }

    public func response() async throws -> MusicLibrarySectionedResponse<SectionType, MusicItemType> {
        throw MusicLibrary.Error.permissionDenied
    }
}

public struct MusicLibrarySectionedResponse<SectionType, MusicItemType: MusicItem & Hashable>: Hashable,
    CustomStringConvertible, CustomDebugStringConvertible
    where SectionType: MusicLibrarySectionRequestable & Hashable
{
    public var sections: [MusicLibrarySection<SectionType, MusicItemType>]
    public init(sections: [MusicLibrarySection<SectionType, MusicItemType>] = []) {
        self.sections = sections
    }
    public var description: String { "MusicLibrarySectionedResponse(\(sections.count))" }
    public var debugDescription: String { description }
}

public struct MusicLibrarySearchRequest: Hashable {
    public var includeTopResults = true
    public let term: String
    public var limit: Int = 0
    public var types: [any MusicLibrarySearchable.Type]

    public init(term: String, types: [any MusicLibrarySearchable.Type]) {
        self.term = term
        self.types = types
    }

    public func response() async throws -> MusicLibrarySearchResponse {
        throw MusicLibrary.Error.permissionDenied
    }

    public static func == (a: MusicLibrarySearchRequest, b: MusicLibrarySearchRequest) -> Bool {
        a.term == b.term && a.limit == b.limit && a.includeTopResults == b.includeTopResults
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(term)
        hasher.combine(limit)
        hasher.combine(includeTopResults)
    }
}

public struct MusicLibrarySearchResponse: Hashable, Sendable, CustomStringConvertible,
    CustomDebugStringConvertible
{
    public enum TopResult: MusicItem, Hashable, Sendable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible
    {
        case song(Song)
        case album(Album)
        case artist(Artist)
        case playlist(Playlist)
        case musicVideo(MusicVideo)

        public typealias ID = MusicItemID
        public var id: MusicItemID {
            switch self {
            case .song(let item): return item.id
            case .album(let item): return item.id
            case .artist(let item): return item.id
            case .playlist(let item): return item.id
            case .musicVideo(let item): return item.id
            }
        }
        public var title: String {
            switch self {
            case .song(let item): return item.title
            case .album(let item): return item.title
            case .artist(let item): return item.name
            case .playlist(let item): return item.name
            case .musicVideo(let item): return item.title
            }
        }
        public var artwork: Artwork? {
            switch self {
            case .song(let item): return item.artwork
            case .album(let item): return item.artwork
            case .artist(let item): return item.artwork
            case .playlist(let item): return item.artwork
            case .musicVideo(let item): return item.artwork
            }
        }
        public var description: String { title }
        public var debugDescription: String { title }

        public init(from decoder: any Decoder) throws {
            let root = try decoder.container(keyedBy: ResourceKey.self)
            let type = try root.decodeIfPresent(String.self, forKey: .type) ?? ""
            switch type {
            case "songs": self = .song(try Song(from: decoder))
            case "albums": self = .album(try Album(from: decoder))
            case "artists": self = .artist(try Artist(from: decoder))
            case "playlists": self = .playlist(try Playlist(from: decoder))
            case "music-videos": self = .musicVideo(try MusicVideo(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: root,
                    debugDescription: "unknown library search top result \(type)"
                )
            }
        }

        public func encode(to encoder: any Encoder) throws {
            switch self {
            case .song(let item): try item.encode(to: encoder)
            case .album(let item): try item.encode(to: encoder)
            case .artist(let item): try item.encode(to: encoder)
            case .playlist(let item): try item.encode(to: encoder)
            case .musicVideo(let item): try item.encode(to: encoder)
            }
        }

        private enum ResourceKey: String, CodingKey { case type }
    }

    public var songs: MusicItemCollection<Song>
    public var albums: MusicItemCollection<Album>
    public var artists: MusicItemCollection<Artist>
    public var playlists: MusicItemCollection<Playlist>
    public var musicVideos: MusicItemCollection<MusicVideo>
    public var topResults: MusicItemCollection<TopResult>

    public init() {
        songs = MusicItemCollection([])
        albums = MusicItemCollection([])
        artists = MusicItemCollection([])
        playlists = MusicItemCollection([])
        musicVideos = MusicItemCollection([])
        topResults = MusicItemCollection([])
    }

    public var description: String { "MusicLibrarySearchResponse(songs: \(songs.count))" }
    public var debugDescription: String { description }
}

extension Genre: MusicLibrarySectionRequestable {}
extension Artist: MusicLibrarySectionRequestable {}
extension Album: MusicLibrarySectionRequestable {}
