import Foundation

/// Empty, fail-closed media library. Linux has no iPod library or Apple Music catalog.
open class MPMediaEntity: NSObject, NSSecureCoding {
    public class var supportsSecureCoding: Bool { true }

    public var persistentID: MPMediaEntityPersistentID = 0

    public required init?(coder: NSCoder) {
        super.init()
        persistentID = UInt64(bitPattern: coder.decodeInt64(forKey: "persistentID"))
    }

    public override init() {
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int64(bitPattern: persistentID), forKey: "persistentID")
    }

    open class func canFilter(byProperty property: String) -> Bool {
        _ = property
        return false
    }

    open func value(forProperty property: String) -> Any? {
        _ = property
        return nil
    }

    open subscript(key: Any) -> Any? {
        guard let property = key as? String else { return nil }
        return value(forProperty: property)
    }

    open func enumerateValues(
        forProperties properties: Set<String>,
        using block: (String, Any, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        _ = properties
        _ = block
    }
}

open class MPMediaItem: MPMediaEntity {
    public var albumArtist: String? { nil }
    public var albumArtistPersistentID: MPMediaEntityPersistentID { 0 }
    public var albumPersistentID: MPMediaEntityPersistentID { 0 }
    public var albumTitle: String? { nil }
    public var albumTrackCount: Int { 0 }
    public var albumTrackNumber: Int { 0 }
    public var artist: String? { nil }
    public var artistPersistentID: MPMediaEntityPersistentID { 0 }
    public var assetURL: URL? { nil }
    public var beatsPerMinute: Int { 0 }
    public var bookmarkTime: TimeInterval { 0 }
    public var isCloudItem: Bool { false }
    public var comments: String? { nil }
    public var isCompilation: Bool { false }
    public var composer: String? { nil }
    public var composerPersistentID: MPMediaEntityPersistentID { 0 }
    public var dateAdded: Date { Date(timeIntervalSince1970: 0) }
    public var discCount: Int { 0 }
    public var discNumber: Int { 0 }
    public var isExplicitItem: Bool { false }
    public var genre: String? { nil }
    public var genrePersistentID: MPMediaEntityPersistentID { 0 }
    public var lastPlayedDate: Date? { nil }
    public var lyrics: String? { nil }
    public var mediaType: MPMediaType { [] }
    public override var persistentID: MPMediaEntityPersistentID {
        get { super.persistentID }
        set { super.persistentID = newValue }
    }
    public var playCount: Int { 0 }
    public var playbackDuration: TimeInterval { 0 }
    public var playbackStoreID: String { "" }
    public var podcastPersistentID: MPMediaEntityPersistentID { 0 }
    public var podcastTitle: String? { nil }
    public var isPreorder: Bool { false }
    public var hasProtectedAsset: Bool { false }
    public var rating: Int { 0 }
    public var releaseDate: Date? { nil }
    public var skipCount: Int { 0 }
    public var title: String? { nil }
    public var userGrouping: String? { nil }

    public class func persistentIDProperty(forGroupingType groupingType: MPMediaGrouping) -> String {
        switch groupingType {
        case .title: return MPMediaItemPropertyPersistentID
        case .album: return MPMediaItemPropertyAlbumPersistentID
        case .albumArtist: return MPMediaItemPropertyAlbumArtistPersistentID
        case .artist: return MPMediaItemPropertyArtistPersistentID
        case .composer: return MPMediaItemPropertyComposerPersistentID
        case .genre: return MPMediaItemPropertyGenrePersistentID
        case .playlist: return MPMediaPlaylistPropertyPersistentID
        case .podcastTitle: return MPMediaItemPropertyPodcastPersistentID
        }
    }

    public class func titleProperty(forGroupingType groupingType: MPMediaGrouping) -> String {
        switch groupingType {
        case .title: return MPMediaItemPropertyTitle
        case .album: return MPMediaItemPropertyAlbumTitle
        case .albumArtist: return MPMediaItemPropertyAlbumArtist
        case .artist: return MPMediaItemPropertyArtist
        case .composer: return MPMediaItemPropertyComposer
        case .genre: return MPMediaItemPropertyGenre
        case .playlist: return MPMediaPlaylistPropertyName
        case .podcastTitle: return MPMediaItemPropertyPodcastTitle
        }
    }

    public override func value(forProperty property: String) -> Any? {
        switch property {
        case MPMediaItemPropertyPersistentID, MPMediaEntityPropertyPersistentID:
            return persistentID
        case MPMediaItemPropertyTitle:
            return title
        case MPMediaItemPropertyMediaType:
            return mediaType
        default:
            return nil
        }
    }
}

open class MPMediaItemCollection: MPMediaEntity {
    public private(set) var items: [MPMediaItem]
    public var count: Int { items.count }
    public var representativeItem: MPMediaItem? { items.first }
    public var mediaTypes: MPMediaType {
        items.reduce(into: MPMediaType()) { $0.formUnion($1.mediaType) }
    }

    public init(items: [MPMediaItem]) {
        self.items = items
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.items = []
        super.init(coder: coder)
    }
}

open class MPMediaPredicate: NSObject, NSSecureCoding {
    public class var supportsSecureCoding: Bool { true }
    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
}

open class MPMediaPropertyPredicate: MPMediaPredicate {
    public let property: String
    public let value: Any?
    public let comparisonType: MPMediaPredicateComparison

    public convenience init(value: Any?, forProperty property: String) {
        self.init(value: value, forProperty: property, comparisonType: .equalTo)
    }

    public init(
        value: Any?,
        forProperty property: String,
        comparisonType: MPMediaPredicateComparison
    ) {
        self.property = property
        self.value = value
        self.comparisonType = comparisonType
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.property = coder.decodeObject(forKey: "property") as? String ?? ""
        self.value = nil
        let raw = coder.decodeInteger(forKey: "comparisonType")
        self.comparisonType = MPMediaPredicateComparison(rawValue: raw) ?? .equalTo
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(property, forKey: "property")
        coder.encode(comparisonType.rawValue, forKey: "comparisonType")
    }
}

open class MPMediaQuerySection: NSObject {
    public let range: NSRange
    public let title: String

    public init(title: String, range: NSRange) {
        self.title = title
        self.range = range
    }
}

open class MPMediaQuery: NSObject, NSSecureCoding {
    public class var supportsSecureCoding: Bool { true }

    public var filterPredicates: Set<MPMediaPredicate>?
    public var groupingType: MPMediaGrouping = .title

    /// Linux library is empty.
    public var items: [MPMediaItem]? { [] }
    public var collections: [MPMediaItemCollection]? { [] }
    public var itemSections: [MPMediaQuerySection]? { nil }
    public var collectionSections: [MPMediaQuerySection]? { nil }

    public init(filterPredicates: Set<MPMediaPredicate>?) {
        self.filterPredicates = filterPredicates
        super.init()
    }

    public convenience override init() {
        self.init(filterPredicates: nil)
    }

    public required init?(coder: NSCoder) {
        self.filterPredicates = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(groupingType.rawValue, forKey: "groupingType")
    }

    public func addFilterPredicate(_ predicate: MPMediaPredicate) {
        var set = filterPredicates ?? []
        set.insert(predicate)
        filterPredicates = set
    }

    public func removeFilterPredicate(_ predicate: MPMediaPredicate) {
        filterPredicates?.remove(predicate)
    }

    public class func albums() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .album
        return query
    }

    public class func artists() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .artist
        return query
    }

    public class func audiobooks() -> MPMediaQuery {
        MPMediaQuery(filterPredicates: [
            MPMediaPropertyPredicate(value: MPMediaType.audioBook, forProperty: MPMediaItemPropertyMediaType)
        ])
    }

    public class func compilations() -> MPMediaQuery {
        MPMediaQuery(filterPredicates: [
            MPMediaPropertyPredicate(value: true, forProperty: MPMediaItemPropertyIsCompilation)
        ])
    }

    public class func composers() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .composer
        return query
    }

    public class func genres() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .genre
        return query
    }

    public class func playlists() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .playlist
        return query
    }

    public class func podcasts() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .podcastTitle
        return query
    }

    public class func songs() -> MPMediaQuery {
        let query = MPMediaQuery(filterPredicates: nil)
        query.groupingType = .title
        return query
    }
}

open class MPMediaPlaylistCreationMetadata: NSObject {
    public let name: String
    public var authorDisplayName: String!
    public var descriptionText: String = ""

    public init(name: String) {
        self.name = name
        self.authorDisplayName = ""
    }
}

open class MPMediaPlaylist: MPMediaItemCollection {
    public var authorDisplayName: String? { nil }
    public var cloudGlobalID: String? { nil }
    public var descriptionText: String? { nil }
    public var name: String? { nil }
    public override var persistentID: MPMediaEntityPersistentID {
        get { super.persistentID }
        set { super.persistentID = newValue }
    }
    public var playlistAttributes: MPMediaPlaylistAttribute { [] }
    public var seedItems: [MPMediaItem]? { nil }

    public func addItem(withProductID productID: String) async throws {
        _ = productID
        throw MPError(.notSupported)
    }

    public func add(_ mediaItems: [MPMediaItem]) async throws {
        _ = mediaItems
        throw MPError(.notSupported)
    }
}

open class MPMediaLibrary: NSObject, NSSecureCoding {
    public class var supportsSecureCoding: Bool { true }

    private static let sharedLibrary = MPMediaLibrary()
    private static let authLock = NSLock()
    private static var status: MPMediaLibraryAuthorizationStatus = .denied

    public var lastModifiedDate: Date { Date(timeIntervalSince1970: 0) }

    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}

    public class func `default`() -> MPMediaLibrary { sharedLibrary }

    public class func authorizationStatus() -> MPMediaLibraryAuthorizationStatus {
        authLock.lock()
        defer { authLock.unlock() }
        return status
    }

    /// Linux never prompts. Completes asynchronously with `.denied`.
    public class func requestAuthorization(
        _ completionHandler: @escaping (MPMediaLibraryAuthorizationStatus) -> Void
    ) {
        let status = authorizationStatus()
        DispatchQueue.global(qos: .utility).async {
            completionHandler(status)
        }
    }

    public func beginGeneratingLibraryChangeNotifications() {}
    public func endGeneratingLibraryChangeNotifications() {}

    public func addItem(withProductID productID: String) async throws -> [MPMediaEntity] {
        _ = productID
        throw MPError(.notSupported)
    }

    public func getPlaylist(
        with uuid: UUID,
        creationMetadata: MPMediaPlaylistCreationMetadata?
    ) async throws -> MPMediaPlaylist {
        _ = uuid
        _ = creationMetadata
        throw MPError(.notSupported)
    }
}
