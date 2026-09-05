import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Artwork request handler. Isolated host uses MPHostTypes.UIImage;
/// guest uses OpenUIKit.UIImage.
open class MPMediaItemArtwork: NSObject {
    public let bounds: CGRect
    public var imageCropRect: CGRect { bounds }
    private let handler: (CGSize) -> UIImage

    /// MEASURED /tmp/mp_oracle.json iOS 26.1: bounds is `(0,0,boundsSize)`.
    public init(boundsSize: CGSize, requestHandler: @escaping (CGSize) -> UIImage) {
        self.bounds = CGRect(origin: .zero, size: boundsSize)
        self.handler = requestHandler
        super.init()
    }

    /// MEASURED: `init(image:)` bounds equal `image.size`.
    public convenience init(image: UIImage) {
        let size = image.size
        self.init(boundsSize: size) { _ in image }
    }

    /// MEASURED: `image(at: 50×40)` of a 100×80 artwork returns 50×40.
    public func image(at size: CGSize) -> UIImage? {
        handler(size)
    }
}

func _mpStringContains(_ haystack: String, _ needle: String) -> Bool {
    if needle.isEmpty { return true }
    let h = Array(haystack)
    let n = Array(needle)
    if n.count > h.count { return false }
    let last = h.count - n.count
    var i = 0
    while i <= last {
        var j = 0
        var ok = true
        while j < n.count {
            if h[i + j] != n[j] {
                ok = false
                break
            }
            j += 1
        }
        if ok { return true }
        i += 1
    }
    return false
}

open class MPMediaEntity: NSObject, NSSecureCoding, NSCopying {
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

    public func copy(with zone: NSZone? = nil) -> Any { self }

    /// MEASURED /tmp/mp_oracle.json: entity-level canFilter is true only for
    /// `persistentID` / `MPMediaEntityPropertyPersistentID`.
    open class func canFilter(byProperty property: String) -> Bool {
        property == MPMediaEntityPropertyPersistentID || property == MPMediaItemPropertyPersistentID
    }

    open func value(forProperty property: String) -> Any? {
        if property == MPMediaEntityPropertyPersistentID || property == MPMediaItemPropertyPersistentID {
            return persistentID
        }
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
        var stop = ObjCBool(false)
        for property in properties {
            if stop.boolValue { break }
            if let value = value(forProperty: property) {
                block(property, value, &stop)
            }
        }
    }
}

open class MPMediaItem: MPMediaEntity {
    var hostValues: [String: Any] = [:]

    public var albumArtist: String? { hostValues[MPMediaItemPropertyAlbumArtist] as? String }
    public var albumArtistPersistentID: MPMediaEntityPersistentID {
        hostValues[MPMediaItemPropertyAlbumArtistPersistentID] as? MPMediaEntityPersistentID ?? 0
    }
    public var albumPersistentID: MPMediaEntityPersistentID {
        hostValues[MPMediaItemPropertyAlbumPersistentID] as? MPMediaEntityPersistentID ?? 0
    }
    public var albumTitle: String? { hostValues[MPMediaItemPropertyAlbumTitle] as? String }
    public var albumTrackCount: Int { hostValues[MPMediaItemPropertyAlbumTrackCount] as? Int ?? 0 }
    public var albumTrackNumber: Int { hostValues[MPMediaItemPropertyAlbumTrackNumber] as? Int ?? 0 }
    public var artist: String? { hostValues[MPMediaItemPropertyArtist] as? String }
    public var artistPersistentID: MPMediaEntityPersistentID {
        hostValues[MPMediaItemPropertyArtistPersistentID] as? MPMediaEntityPersistentID ?? 0
    }
    public var artwork: MPMediaItemArtwork? { hostValues[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork }
    public var assetURL: URL? { hostValues[MPMediaItemPropertyAssetURL] as? URL }
    public var beatsPerMinute: Int { hostValues[MPMediaItemPropertyBeatsPerMinute] as? Int ?? 0 }
    public var bookmarkTime: TimeInterval { hostValues[MPMediaItemPropertyBookmarkTime] as? TimeInterval ?? 0 }
    public var isCloudItem: Bool { hostValues[MPMediaItemPropertyIsCloudItem] as? Bool ?? false }
    public var comments: String? { hostValues[MPMediaItemPropertyComments] as? String }
    public var isCompilation: Bool { hostValues[MPMediaItemPropertyIsCompilation] as? Bool ?? false }
    public var composer: String? { hostValues[MPMediaItemPropertyComposer] as? String }
    public var composerPersistentID: MPMediaEntityPersistentID {
        hostValues[MPMediaItemPropertyComposerPersistentID] as? MPMediaEntityPersistentID ?? 0
    }
    public var dateAdded: Date {
        hostValues[MPMediaItemPropertyDateAdded] as? Date ?? Date(timeIntervalSince1970: 0)
    }
    public var discCount: Int { hostValues[MPMediaItemPropertyDiscCount] as? Int ?? 0 }
    public var discNumber: Int { hostValues[MPMediaItemPropertyDiscNumber] as? Int ?? 0 }
    public var isExplicitItem: Bool { hostValues[MPMediaItemPropertyIsExplicit] as? Bool ?? false }
    public var genre: String? { hostValues[MPMediaItemPropertyGenre] as? String }
    public var genrePersistentID: MPMediaEntityPersistentID {
        hostValues[MPMediaItemPropertyGenrePersistentID] as? MPMediaEntityPersistentID ?? 0
    }
    public var lastPlayedDate: Date? { hostValues[MPMediaItemPropertyLastPlayedDate] as? Date }
    public var lyrics: String? { hostValues[MPMediaItemPropertyLyrics] as? String }
    public var mediaType: MPMediaType {
        if let type = hostValues[MPMediaItemPropertyMediaType] as? MPMediaType { return type }
        if let raw = hostValues[MPMediaItemPropertyMediaType] as? UInt { return MPMediaType(rawValue: raw) }
        return []
    }
    public override var persistentID: MPMediaEntityPersistentID {
        get {
            if let stored = hostValues[MPMediaItemPropertyPersistentID] as? MPMediaEntityPersistentID {
                return stored
            }
            return super.persistentID
        }
        set {
            super.persistentID = newValue
            hostValues[MPMediaItemPropertyPersistentID] = newValue
        }
    }
    public var playCount: Int { hostValues[MPMediaItemPropertyPlayCount] as? Int ?? 0 }
    public var playbackDuration: TimeInterval {
        hostValues[MPMediaItemPropertyPlaybackDuration] as? TimeInterval ?? 0
    }
    public var playbackStoreID: String { hostValues[MPMediaItemPropertyPlaybackStoreID] as? String ?? "" }
    public var podcastPersistentID: MPMediaEntityPersistentID {
        hostValues[MPMediaItemPropertyPodcastPersistentID] as? MPMediaEntityPersistentID ?? 0
    }
    public var podcastTitle: String? { hostValues[MPMediaItemPropertyPodcastTitle] as? String }
    public var isPreorder: Bool { hostValues[MPMediaItemPropertyIsPreorder] as? Bool ?? false }
    public var hasProtectedAsset: Bool { hostValues[MPMediaItemPropertyHasProtectedAsset] as? Bool ?? false }
    public var rating: Int { hostValues[MPMediaItemPropertyRating] as? Int ?? 0 }
    public var releaseDate: Date? { hostValues[MPMediaItemPropertyReleaseDate] as? Date }
    public var skipCount: Int { hostValues[MPMediaItemPropertySkipCount] as? Int ?? 0 }
    public var title: String? { hostValues[MPMediaItemPropertyTitle] as? String }
    public var userGrouping: String? { hostValues[MPMediaItemPropertyUserGrouping] as? String }

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

    /// MEASURED /tmp/mp_oracle.json iOS 26.1 canFilter table (item class).
    public override class func canFilter(byProperty property: String) -> Bool {
        switch property {
        case MPMediaItemPropertyTitle,
             MPMediaItemPropertyPersistentID,
             MPMediaEntityPropertyPersistentID,
             MPMediaItemPropertyAlbumTitle,
             MPMediaItemPropertyArtist,
             MPMediaItemPropertyGenre,
             MPMediaItemPropertyMediaType,
             MPMediaItemPropertyPlayCount,
             MPMediaItemPropertyAssetURL,
             MPMediaItemPropertyAlbumArtist,
             MPMediaItemPropertyAlbumPersistentID,
             MPMediaItemPropertyAlbumArtistPersistentID,
             MPMediaItemPropertyArtistPersistentID,
             MPMediaItemPropertyComposer,
             MPMediaItemPropertyComposerPersistentID,
             MPMediaItemPropertyDateAdded,
             MPMediaItemPropertyGenrePersistentID,
             MPMediaItemPropertyHasProtectedAsset,
             MPMediaItemPropertyIsCloudItem,
             MPMediaItemPropertyIsCompilation,
             MPMediaItemPropertyIsExplicit,
             MPMediaItemPropertyIsPreorder,
             MPMediaItemPropertyPodcastPersistentID,
             MPMediaItemPropertyPodcastTitle,
             MPMediaItemPropertyRating:
            return true
        default:
            return false
        }
    }

    public override func value(forProperty property: String) -> Any? {
        switch property {
        case MPMediaItemPropertyPersistentID, MPMediaEntityPropertyPersistentID:
            return persistentID
        case MPMediaItemPropertyTitle: return title
        case MPMediaItemPropertyAlbumTitle: return albumTitle
        case MPMediaItemPropertyArtist: return artist
        case MPMediaItemPropertyAlbumArtist: return albumArtist
        case MPMediaItemPropertyComposer: return composer
        case MPMediaItemPropertyGenre: return genre
        case MPMediaItemPropertyLyrics: return lyrics
        case MPMediaItemPropertyComments: return comments
        case MPMediaItemPropertyAssetURL: return assetURL
        case MPMediaItemPropertyArtwork: return artwork
        case MPMediaItemPropertyMediaType: return mediaType
        case MPMediaItemPropertyPlaybackDuration: return playbackDuration
        case MPMediaItemPropertyAlbumTrackNumber: return albumTrackNumber
        case MPMediaItemPropertyAlbumTrackCount: return albumTrackCount
        case MPMediaItemPropertyDiscNumber: return discNumber
        case MPMediaItemPropertyDiscCount: return discCount
        case MPMediaItemPropertyPlayCount: return playCount
        case MPMediaItemPropertySkipCount: return skipCount
        case MPMediaItemPropertyRating: return rating
        case MPMediaItemPropertyBeatsPerMinute: return beatsPerMinute
        case MPMediaItemPropertyBookmarkTime: return bookmarkTime
        case MPMediaItemPropertyIsCloudItem: return isCloudItem
        case MPMediaItemPropertyIsCompilation: return isCompilation
        case MPMediaItemPropertyIsExplicit: return isExplicitItem
        case MPMediaItemPropertyIsPreorder: return isPreorder
        case MPMediaItemPropertyHasProtectedAsset: return hasProtectedAsset
        case MPMediaItemPropertyDateAdded: return dateAdded
        case MPMediaItemPropertyLastPlayedDate: return lastPlayedDate
        case MPMediaItemPropertyReleaseDate: return releaseDate
        case MPMediaItemPropertyPlaybackStoreID: return playbackStoreID
        case MPMediaItemPropertyPodcastTitle: return podcastTitle
        case MPMediaItemPropertyUserGrouping: return userGrouping
        case MPMediaItemPropertyAlbumPersistentID: return albumPersistentID
        case MPMediaItemPropertyAlbumArtistPersistentID: return albumArtistPersistentID
        case MPMediaItemPropertyArtistPersistentID: return artistPersistentID
        case MPMediaItemPropertyComposerPersistentID: return composerPersistentID
        case MPMediaItemPropertyGenrePersistentID: return genrePersistentID
        case MPMediaItemPropertyPodcastPersistentID: return podcastPersistentID
        default:
            return hostValues[property]
        }
    }

    /// Test-hook constructor. Not Apple public API.
    @_spi(OpenUIKitHost)
    public convenience init(hostProperties: [String: Any]) {
        self.init()
        hostValues = hostProperties
        if let pid = hostProperties[MPMediaItemPropertyPersistentID] as? MPMediaEntityPersistentID {
            super.persistentID = pid
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

    func matches(_ item: MPMediaItem) -> Bool {
        let actual = item.value(forProperty: property)
        switch comparisonType {
        case .contains:
            let a = stringify(actual)
            let b = stringify(value)
            return _mpStringContains(a, b)
        case .equalTo:
            return valuesEqual(actual, value)
        }
    }

    private func stringify(_ value: Any?) -> String {
        if let s = value as? String { return s }
        if let n = value as? NSNumber { return n.stringValue }
        return ""
    }

    private func valuesEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l as String, r as String):
            return l == r
        case let (l as MPMediaType, r as MPMediaType):
            return l == r
        case let (l as MPMediaType, r as UInt):
            return l.rawValue == r
        case let (l as UInt, r as MPMediaType):
            return l == r.rawValue
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as UInt64, r as UInt64):
            return l == r
        case let (l as NSNumber, r as NSNumber):
            return l == r
        default:
            return stringify(lhs) == stringify(rhs) && !stringify(lhs).isEmpty
        }
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

open class MPMediaQuery: NSObject, NSSecureCoding, NSCopying {
    public class var supportsSecureCoding: Bool { true }

    public var filterPredicates: Set<MPMediaPredicate>?
    /// MEASURED empty `MPMediaQuery()` groupingType = `.title` (0).
    public var groupingType: MPMediaGrouping = .title

    /// MEASURED unauthorized library: `items` is `nil`, not `[]`.
    public var items: [MPMediaItem]? {
        MPMediaLibrary.filteredItems(matching: filterPredicates)
    }

    public var collections: [MPMediaItemCollection]? {
        guard let items else { return nil }
        let key = MPMediaItem.titleProperty(forGroupingType: groupingType)
        var groups: [(String, [MPMediaItem])] = []
        var index: [String: Int] = [:]
        for item in items {
            let name = (item.value(forProperty: key) as? String) ?? ""
            if let existing = index[name] {
                groups[existing].1.append(item)
            } else {
                index[name] = groups.count
                groups.append((name, [item]))
            }
        }
        return groups.map { MPMediaItemCollection(items: $0.1) }
    }

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

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MPMediaQuery(filterPredicates: filterPredicates)
        copy.groupingType = groupingType
        return copy
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
    /// Linux never prompts. Default `.denied` per the corpus brief.
    /// Simulator oracle reported `.notDetermined` (0) with no TCC prompt —
    /// Linux has no TCC, so denied is the fail-closed mapping.
    private static var status: MPMediaLibraryAuthorizationStatus = .denied
    private static var fixtureItems: [MPMediaItem] = []

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

    /// Linux never prompts. Completes asynchronously with the current status.
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

    /// Loads an in-process fixture library and sets authorization `.authorized`.
    @_spi(OpenUIKitHost)
    public class func openuikit_loadFixtureLibrary(_ items: [MPMediaItem]) {
        authLock.lock()
        fixtureItems = items
        status = .authorized
        authLock.unlock()
    }

    /// Restores the empty denied library.
    @_spi(OpenUIKitHost)
    public class func openuikit_resetLibrary() {
        authLock.lock()
        fixtureItems = []
        status = .denied
        authLock.unlock()
    }

    static func filteredItems(matching predicates: Set<MPMediaPredicate>?) -> [MPMediaItem]? {
        authLock.lock()
        let items = fixtureItems
        let authorized = status == .authorized
        authLock.unlock()
        if !authorized || items.isEmpty { return nil }
        guard let predicates, !predicates.isEmpty else { return items }
        return items.filter { item in
            for predicate in predicates {
                if let property = predicate as? MPMediaPropertyPredicate {
                    if !property.matches(item) { return false }
                }
            }
            return true
        }
    }
}
