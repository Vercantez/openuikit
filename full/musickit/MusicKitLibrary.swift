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

public struct MusicLibrarySectionedRequest<SectionType, MusicItemType: MusicItem & Hashable>
    where SectionType: MusicLibrarySectionRequestable & Hashable
{
    public var limit: Int = 0
    public var offset: Int = 0
    public init() {}
    public func response() async throws -> MusicLibrarySectionedResponse<SectionType, MusicItemType> {
        throw MusicLibrary.Error.permissionDenied
    }
}

public struct MusicLibrarySectionedResponse<SectionType, MusicItemType: MusicItem & Hashable>: Hashable
    where SectionType: MusicLibrarySectionRequestable & Hashable
{
    public var sections: [MusicLibrarySection<SectionType, MusicItemType>]
    public init(sections: [MusicLibrarySection<SectionType, MusicItemType>] = []) {
        self.sections = sections
    }
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

public struct MusicLibrarySearchResponse: Hashable, Sendable {
    public enum TopResult: MusicItem, Hashable, Sendable {
        case song(Song)
        case album(Album)
        case artist(Artist)
        case playlist(Playlist)
        case musicVideo(MusicVideo)
        public var id: MusicItemID {
            switch self {
            case .song(let item): return item.id
            case .album(let item): return item.id
            case .artist(let item): return item.id
            case .playlist(let item): return item.id
            case .musicVideo(let item): return item.id
            }
        }
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
}

extension Genre: MusicLibrarySectionRequestable {}
extension Artist: MusicLibrarySectionRequestable {}
extension Album: MusicLibrarySectionRequestable {}
