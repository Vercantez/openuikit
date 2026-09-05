import Foundation

public struct MusicItemCollection<MusicItemType: MusicItem & Hashable>: Hashable, Sendable,
    RandomAccessCollection, CustomStringConvertible
{
    public typealias Element = MusicItemType
    public typealias Index = Int
    public typealias SubSequence = MusicItemCollection<MusicItemType>
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<MusicItemCollection<MusicItemType>>

    var items: [MusicItemType]
    public var title: String?

    public init<S>(_ elements: S) where S: Sequence, S.Element == MusicItemType {
        items = Array(elements)
        title = nil
    }

    public init(items: [MusicItemType] = [], title: String? = nil) {
        self.items = items
        self.title = title
    }

    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }
    public var indices: Range<Int> { items.indices }

    public subscript(position: Int) -> MusicItemType { items[position] }

    public subscript(bounds: Range<Int>) -> MusicItemCollection<MusicItemType> {
        MusicItemCollection(items: Array(items[bounds]), title: title)
    }

    public func index(after i: Int) -> Int { items.index(after: i) }
    public func index(before i: Int) -> Int { items.index(before: i) }
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        items.index(i, offsetBy: distance)
    }
    public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
        items.index(i, offsetBy: distance, limitedBy: limit)
    }
    public func distance(from start: Int, to end: Int) -> Int {
        items.distance(from: start, to: end)
    }
    public func formIndex(after i: inout Int) { items.formIndex(after: &i) }
    public func formIndex(before i: inout Int) { items.formIndex(before: &i) }

    public var description: String {
        title.map { "\($0)(\(items.count))" } ?? "MusicItemCollection(\(items.count))"
    }

    public func nextBatch(limit: Int? = nil) async throws -> MusicItemCollection<MusicItemType>? {
        _ = limit
        throw MusicKitPortableError.catalogUnavailable
    }

    public static func += (
        collection: inout MusicItemCollection<MusicItemType>,
        nextBatchCollection: MusicItemCollection<MusicItemType>
    ) {
        collection.items.append(contentsOf: nextBatchCollection.items)
    }
}

extension MusicItemCollection: Decodable where MusicItemType: Decodable {
    public init(from decoder: any Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CollectionCodingKeys.self),
           keyed.contains(.data)
        {
            items = try keyed.decode([MusicItemType].self, forKey: .data)
            title = try keyed.decodeIfPresent(String.self, forKey: .title)
            return
        }
        items = try decoder.singleValueContainer().decode([MusicItemType].self)
        title = nil
    }
}

extension MusicItemCollection: Encodable where MusicItemType: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CollectionCodingKeys.self)
        try container.encode(items, forKey: .data)
        try container.encodeIfPresent(title, forKey: .title)
    }
}

enum CollectionCodingKeys: String, CodingKey { case data, title }

public struct TitledSection: Hashable, Sendable, Identifiable {
    public typealias ID = MusicItemID
    public var id: MusicItemID
    public let title: String

    public init(id: MusicItemID, title: String) {
        self.id = id
        self.title = title
    }
}

open class AnyMusicProperty: Hashable {
    public let name: String
    public init(name: String) { self.name = name }
    public static func == (left: AnyMusicProperty, right: AnyMusicProperty) -> Bool {
        left.name == right.name
    }
    public func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

open class PartialMusicProperty<Root>: AnyMusicProperty {
    public init(property: String) { super.init(name: property) }
}

open class PartialMusicAsyncProperty<Root>: PartialMusicProperty<Root> {}

open class MusicAttributeProperty<Root, Value: Decodable>: PartialMusicProperty<Root>,
    CustomStringConvertible
{
    public var description: String { name }
}

open class MusicExtendedAttributeProperty<Root, Value: Decodable>: MusicAttributeProperty<Root, Value> {}

open class MusicRelationshipProperty<Root, RelatedMusicItemType: MusicItem>:
    PartialMusicAsyncProperty<Root> {}

extension PartialMusicProperty where Root == Song {
    public static let musicVideos = MusicRelationshipProperty<Song, MusicVideo>(property: "music-videos")
    public static let albums = MusicRelationshipProperty<Song, Album>(property: "albums")
    public static let genres = MusicRelationshipProperty<Song, Genre>(property: "genres")
    public static let artists = MusicRelationshipProperty<Song, Artist>(property: "artists")
    public static let station = MusicRelationshipProperty<Song, Station>(property: "station")
    public static let composers = MusicRelationshipProperty<Song, Artist>(property: "composers")
    public static let audioVariants = MusicExtendedAttributeProperty<Song, [AudioVariant]>(property: "audioVariants")
    public static var artistURL: MusicExtendedAttributeProperty<Song, URL> {
        MusicExtendedAttributeProperty<Song, URL>(property: "artistUrl")
    }
}

extension PartialMusicProperty where Root == Album {
    public static let recordLabels = MusicRelationshipProperty<Album, RecordLabel>(property: "record-labels")
    public static let audioVariants = MusicExtendedAttributeProperty<Album, [AudioVariant]>(property: "audioVariants")
    public static let otherVersions = MusicRelationshipProperty<Album, Album>(property: "other-versions")
    public static let relatedAlbums = MusicRelationshipProperty<Album, Album>(property: "related-albums")
    public static let relatedVideos = MusicRelationshipProperty<Album, MusicVideo>(property: "related-videos")
    public static let genres = MusicRelationshipProperty<Album, Genre>(property: "genres")
    public static let tracks = MusicRelationshipProperty<Album, Track>(property: "tracks")
    public static let artists = MusicRelationshipProperty<Album, Artist>(property: "artists")
    public static let appearsOn = MusicRelationshipProperty<Album, Playlist>(property: "appears-on")
    public static var artistURL: MusicExtendedAttributeProperty<Album, URL> {
        MusicExtendedAttributeProperty<Album, URL>(property: "artistUrl")
    }
}

extension PartialMusicProperty where Root == Artist {
    public static let topMusicVideos = MusicRelationshipProperty<Artist, MusicVideo>(property: "top-music-videos")
    public static let fullAlbums = MusicRelationshipProperty<Artist, Album>(property: "full-albums")
    public static let liveAlbums = MusicRelationshipProperty<Artist, Album>(property: "live-albums")
    public static let musicVideos = MusicRelationshipProperty<Artist, MusicVideo>(property: "music-videos")
    public static let latestRelease = MusicRelationshipProperty<Artist, Album>(property: "latest-release")
    public static let featuredAlbums = MusicRelationshipProperty<Artist, Album>(property: "featured-albums")
    public static let similarArtists = MusicRelationshipProperty<Artist, Artist>(property: "similar-artists")
    public static let appearsOnAlbums = MusicRelationshipProperty<Artist, Album>(property: "appears-on-albums")
    public static let compilationAlbums = MusicRelationshipProperty<Artist, Album>(property: "compilation-albums")
    public static let featuredPlaylists = MusicRelationshipProperty<Artist, Playlist>(property: "featured-playlists")
    public static let albums = MusicRelationshipProperty<Artist, Album>(property: "albums")
    public static let genres = MusicRelationshipProperty<Artist, Genre>(property: "genres")
    public static let singles = MusicRelationshipProperty<Artist, Album>(property: "singles")
    public static let station = MusicRelationshipProperty<Artist, Station>(property: "station")
    public static let topSongs = MusicRelationshipProperty<Artist, Song>(property: "top-songs")
    public static let playlists = MusicRelationshipProperty<Artist, Playlist>(property: "playlists")
}

extension PartialMusicProperty where Root == Playlist {
    public static let moreByCurator = MusicRelationshipProperty<Playlist, Playlist>(property: "more-by-curator")
    public static let featuredArtists = MusicRelationshipProperty<Playlist, Artist>(property: "featured-artists")
    public static let tracks = MusicRelationshipProperty<Playlist, Track>(property: "tracks")
    public static let curator = MusicRelationshipProperty<Playlist, Curator>(property: "curator")
    public static let entries = MusicRelationshipProperty<Playlist, Playlist.Entry>(property: "entries")
    public static let radioShow = MusicRelationshipProperty<Playlist, RadioShow>(property: "radio-show")
}

extension PartialMusicProperty where Root == MusicVideo {
    public static let moreInGenre = MusicRelationshipProperty<MusicVideo, MusicVideo>(property: "more-in-genre")
    public static let moreByArtist = MusicRelationshipProperty<MusicVideo, MusicVideo>(property: "more-by-artist")
    public static let songs = MusicRelationshipProperty<MusicVideo, Song>(property: "songs")
    public static let albums = MusicRelationshipProperty<MusicVideo, Album>(property: "albums")
    public static let genres = MusicRelationshipProperty<MusicVideo, Genre>(property: "genres")
    public static let artists = MusicRelationshipProperty<MusicVideo, Artist>(property: "artists")
    public static var artistURL: MusicExtendedAttributeProperty<MusicVideo, URL> {
        MusicExtendedAttributeProperty<MusicVideo, URL>(property: "artistUrl")
    }
}

extension PartialMusicProperty where Root == RecordLabel {
    public static var topReleases: MusicRelationshipProperty<RecordLabel, Album> {
        MusicRelationshipProperty<RecordLabel, Album>(property: "top-releases")
    }
    public static var latestReleases: MusicRelationshipProperty<RecordLabel, Album> {
        MusicRelationshipProperty<RecordLabel, Album>(property: "latest-releases")
    }
}

extension PartialMusicProperty where Root == Curator {
    public static let playlists = MusicRelationshipProperty<Curator, Playlist>(property: "playlists")
}

extension PartialMusicProperty where Root == RadioShow {
    public static let playlists = MusicRelationshipProperty<RadioShow, Playlist>(property: "playlists")
}
