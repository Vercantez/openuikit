import Foundation

public typealias MPMediaEntityPersistentID = UInt64

private let _filterableMediaProperties: Set<String> = [
    MPMediaItemPropertyPersistentID,
    MPMediaItemPropertyMediaType,
    MPMediaItemPropertyTitle,
    MPMediaItemPropertyAlbumTitle,
    MPMediaItemPropertyArtist,
    MPMediaItemPropertyAlbumArtist,
    MPMediaItemPropertyGenre,
    MPMediaItemPropertyComposer,
    MPMediaItemPropertyIsCompilation,
    MPMediaItemPropertyPodcastTitle,
    MPMediaItemPropertyAlbumPersistentID,
    MPMediaItemPropertyArtistPersistentID,
    MPMediaItemPropertyAlbumArtistPersistentID,
    MPMediaItemPropertyGenrePersistentID,
    MPMediaItemPropertyComposerPersistentID,
    MPMediaItemPropertyPodcastPersistentID,
    MPMediaPlaylistPropertyName,
    MPMediaPlaylistPropertyPersistentID,
]

open class MPMediaEntity: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    var storage: [String: Any] = [:]

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open class func canFilter(byProperty property: String) -> Bool {
        _filterableMediaProperties.contains(property)
    }

    open var persistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyPersistentID) as? NSNumber)?
            .uint64Value ?? 0
    }

    open func value(forProperty property: String) -> Any? {
        storage[property]
    }

    open subscript(key: Any) -> Any? {
        guard let property = key as? String else { return nil }
        return value(forProperty: property)
    }

    open func enumerateValues(
        forProperties properties: Set<String>,
        using block: @escaping (String, Any, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        for property in properties.sorted() {
            guard let value = value(forProperty: property) else { continue }
            withUnsafeMutablePointer(to: &stop) { pointer in
                block(property, value, pointer)
            }
            if stop.boolValue { break }
        }
    }
}

open class MPMediaItem: MPMediaEntity, NSCopying, @unchecked Sendable {
    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = MPMediaItem()
        copy.storage = storage
        return copy
    }

    open class func persistentIDProperty(forGroupingType groupingType: MPMediaGrouping) -> String {
        switch groupingType {
        case .title: return MPMediaItemPropertyPersistentID
        case .album: return MPMediaItemPropertyAlbumPersistentID
        case .artist: return MPMediaItemPropertyArtistPersistentID
        case .albumArtist: return MPMediaItemPropertyAlbumArtistPersistentID
        case .composer: return MPMediaItemPropertyComposerPersistentID
        case .genre: return MPMediaItemPropertyGenrePersistentID
        case .playlist: return MPMediaPlaylistPropertyPersistentID
        case .podcastTitle: return MPMediaItemPropertyPodcastPersistentID
        }
    }

    open class func titleProperty(forGroupingType groupingType: MPMediaGrouping) -> String {
        switch groupingType {
        case .title: return MPMediaItemPropertyTitle
        case .album: return MPMediaItemPropertyAlbumTitle
        case .artist: return MPMediaItemPropertyArtist
        case .albumArtist: return MPMediaItemPropertyAlbumArtist
        case .composer: return MPMediaItemPropertyComposer
        case .genre: return MPMediaItemPropertyGenre
        case .playlist: return MPMediaPlaylistPropertyName
        case .podcastTitle: return MPMediaItemPropertyPodcastTitle
        }
    }

    open override var persistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyPersistentID) as? NSNumber)?
            .uint64Value ?? 0
    }

    open var albumArtist: String? { value(forProperty: MPMediaItemPropertyAlbumArtist) as? String }
    open var albumArtistPersistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyAlbumArtistPersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var albumPersistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyAlbumPersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var albumTitle: String? { value(forProperty: MPMediaItemPropertyAlbumTitle) as? String }
    open var albumTrackCount: Int { (value(forProperty: MPMediaItemPropertyAlbumTrackCount) as? NSNumber)?.intValue ?? 0 }
    open var albumTrackNumber: Int { (value(forProperty: MPMediaItemPropertyAlbumTrackNumber) as? NSNumber)?.intValue ?? 0 }
    open var artist: String? { value(forProperty: MPMediaItemPropertyArtist) as? String }
    open var artistPersistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyArtistPersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var artwork: MPMediaItemArtwork? { value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork }
    open var assetURL: URL? { value(forProperty: MPMediaItemPropertyAssetURL) as? URL }
    open var beatsPerMinute: Int { (value(forProperty: MPMediaItemPropertyBeatsPerMinute) as? NSNumber)?.intValue ?? 0 }
    open var bookmarkTime: TimeInterval { (value(forProperty: MPMediaItemPropertyBookmarkTime) as? NSNumber)?.doubleValue ?? 0 }
    open var isCloudItem: Bool { (value(forProperty: MPMediaItemPropertyIsCloudItem) as? NSNumber)?.boolValue ?? false }
    open var comments: String? { value(forProperty: MPMediaItemPropertyComments) as? String }
    open var isCompilation: Bool { (value(forProperty: MPMediaItemPropertyIsCompilation) as? NSNumber)?.boolValue ?? false }
    open var composer: String? { value(forProperty: MPMediaItemPropertyComposer) as? String }
    open var composerPersistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyComposerPersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var dateAdded: Date { (value(forProperty: MPMediaItemPropertyDateAdded) as? Date) ?? .distantPast }
    open var discCount: Int { (value(forProperty: MPMediaItemPropertyDiscCount) as? NSNumber)?.intValue ?? 0 }
    open var discNumber: Int { (value(forProperty: MPMediaItemPropertyDiscNumber) as? NSNumber)?.intValue ?? 0 }
    open var isExplicitItem: Bool { (value(forProperty: MPMediaItemPropertyIsExplicit) as? NSNumber)?.boolValue ?? false }
    open var genre: String? { value(forProperty: MPMediaItemPropertyGenre) as? String }
    open var genrePersistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyGenrePersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var lastPlayedDate: Date? { value(forProperty: MPMediaItemPropertyLastPlayedDate) as? Date }
    open var lyrics: String? { value(forProperty: MPMediaItemPropertyLyrics) as? String }
    open var mediaType: MPMediaType {
        if let number = value(forProperty: MPMediaItemPropertyMediaType) as? NSNumber {
            return MPMediaType(rawValue: number.uintValue)
        }
        return []
    }
    open var playCount: Int { (value(forProperty: MPMediaItemPropertyPlayCount) as? NSNumber)?.intValue ?? 0 }
    open var playbackDuration: TimeInterval {
        (value(forProperty: MPMediaItemPropertyPlaybackDuration) as? NSNumber)?.doubleValue ?? 0
    }
    open var playbackStoreID: String { (value(forProperty: MPMediaItemPropertyPlaybackStoreID) as? String) ?? "" }
    open var podcastPersistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaItemPropertyPodcastPersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var podcastTitle: String? { value(forProperty: MPMediaItemPropertyPodcastTitle) as? String }
    open var isPreorder: Bool { (value(forProperty: MPMediaItemPropertyIsPreorder) as? NSNumber)?.boolValue ?? false }
    open var hasProtectedAsset: Bool { (value(forProperty: MPMediaItemPropertyHasProtectedAsset) as? NSNumber)?.boolValue ?? false }
    open var rating: Int { (value(forProperty: MPMediaItemPropertyRating) as? NSNumber)?.intValue ?? 0 }
    open var releaseDate: Date? { value(forProperty: MPMediaItemPropertyReleaseDate) as? Date }
    open var skipCount: Int { (value(forProperty: MPMediaItemPropertySkipCount) as? NSNumber)?.intValue ?? 0 }
    open var title: String? { value(forProperty: MPMediaItemPropertyTitle) as? String }
    open var userGrouping: String? { value(forProperty: MPMediaItemPropertyUserGrouping) as? String }

    @_spi(OpenUIKitHost)
    public func _openUIKit_setValue(_ value: Any?, forProperty property: String) {
        if let value {
            storage[property] = value
        } else {
            storage.removeValue(forKey: property)
        }
    }
}

/// Artwork image loading requires UIKit `UIImage` and CoreGraphics sizes.
/// The type exists so media items can type-check `artwork`; no image is ever
/// produced on Linux.
open class MPMediaItemArtwork: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class MPMediaItemCollection: MPMediaEntity, NSCopying, @unchecked Sendable {
    private var _items: [MPMediaItem]

    public init(items: [MPMediaItem]) {
        _items = items
        super.init()
    }

    public override init() {
        _items = []
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MPMediaItemCollection(items: _items)
    }

    open var items: [MPMediaItem] { _items }
    open var count: Int { _items.count }
    open var representativeItem: MPMediaItem? { _items.first }
    open var mediaTypes: MPMediaType {
        var types = MPMediaType()
        for item in _items {
            types.formUnion(item.mediaType)
        }
        return types
    }
}

open class MPMediaPredicate: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class MPMediaPropertyPredicate: MPMediaPredicate, @unchecked Sendable {
    public let property: String
    public let value: Any?
    public let comparisonType: MPMediaPredicateComparison

    public init(value: Any?, forProperty property: String) {
        self.property = property
        self.value = value
        self.comparisonType = .equalTo
        super.init()
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
        _ = coder
        return nil
    }
}

open class MPMediaQuerySection: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let title: String
    public let range: NSRange

    init(title: String, range: NSRange) {
        self.title = title
        self.range = range
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

/// Local query object. Linux has no iPod/Music library, so `items` and
/// `collections` are always `nil`.
open class MPMediaQuery: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private var predicates: Set<MPMediaPredicate>
    open var groupingType: MPMediaGrouping = .title

    public init(filterPredicates: Set<MPMediaPredicate>?) {
        predicates = filterPredicates ?? []
        super.init()
    }

    public convenience override init() {
        self.init(filterPredicates: nil)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = MPMediaQuery(filterPredicates: predicates)
        copy.groupingType = groupingType
        return copy
    }

    open var filterPredicates: Set<MPMediaPredicate>? {
        get { predicates.isEmpty ? nil : predicates }
        set { predicates = newValue ?? [] }
    }

    open func addFilterPredicate(_ predicate: MPMediaPredicate) {
        predicates.insert(predicate)
    }

    open func removeFilterPredicate(_ predicate: MPMediaPredicate) {
        predicates.remove(predicate)
    }

    /// No local media library exists, matching Apple's "nil when empty" docs.
    open var items: [MPMediaItem]? { nil }
    open var collections: [MPMediaItemCollection]? { nil }
    open var itemSections: [MPMediaQuerySection]? { nil }
    open var collectionSections: [MPMediaQuerySection]? { nil }

    open class func albums() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .album
        return query
    }

    open class func artists() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .artist
        return query
    }

    open class func audiobooks() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.addFilterPredicate(
            MPMediaPropertyPredicate(value: NSNumber(value: MPMediaType.audioBook.rawValue), forProperty: MPMediaItemPropertyMediaType)
        )
        return query
    }

    open class func compilations() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.addFilterPredicate(
            MPMediaPropertyPredicate(value: true, forProperty: MPMediaItemPropertyIsCompilation)
        )
        return query
    }

    open class func composers() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .composer
        return query
    }

    open class func genres() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .genre
        return query
    }

    open class func playlists() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .playlist
        return query
    }

    open class func podcasts() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .podcastTitle
        query.addFilterPredicate(
            MPMediaPropertyPredicate(value: NSNumber(value: MPMediaType.podcast.rawValue), forProperty: MPMediaItemPropertyMediaType)
        )
        return query
    }

    open class func songs() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = .title
        query.addFilterPredicate(
            MPMediaPropertyPredicate(value: NSNumber(value: MPMediaType.music.rawValue), forProperty: MPMediaItemPropertyMediaType)
        )
        return query
    }
}

/// Linux has no Music/iPod library or privacy prompt. Authorization is
/// permanently denied and mutation APIs throw `MPError.notSupported`.
open class MPMediaLibrary: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    private static let _default = MPMediaLibrary()
    private var generatingNotifications = false

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open class func `default`() -> MPMediaLibrary { _default }

    open class func authorizationStatus() -> MPMediaLibraryAuthorizationStatus {
        .denied
    }

    open class func requestAuthorization(
        _ completionHandler: @escaping (MPMediaLibraryAuthorizationStatus) -> Void
    ) {
        completionHandler(.denied)
    }

    open var lastModifiedDate: Date { .distantPast }

    open func beginGeneratingLibraryChangeNotifications() {
        generatingNotifications = true
    }

    open func endGeneratingLibraryChangeNotifications() {
        generatingNotifications = false
    }

    open func addItem(withProductID productID: String) async throws -> [MPMediaEntity] {
        _ = productID
        throw _mpNotSupportedError()
    }

    open func getPlaylist(
        with uuid: UUID,
        creationMetadata: MPMediaPlaylistCreationMetadata?
    ) async throws -> MPMediaPlaylist {
        _ = (uuid, creationMetadata)
        throw _mpNotSupportedError()
    }
}

open class MPMediaPlaylistCreationMetadata: NSObject, @unchecked Sendable {
    public let name: String
    open var authorDisplayName: String!
    open var descriptionText: String = ""

    public init(name: String) {
        self.name = name
        super.init()
    }
}

open class MPMediaPlaylist: MPMediaItemCollection, @unchecked Sendable {
    open var authorDisplayName: String? {
        value(forProperty: MPMediaPlaylistPropertyAuthorDisplayName) as? String
    }
    open var cloudGlobalID: String? {
        value(forProperty: MPMediaPlaylistPropertyCloudGlobalID) as? String
    }
    open var descriptionText: String? {
        value(forProperty: MPMediaPlaylistPropertyDescriptionText) as? String
    }
    open var name: String? {
        value(forProperty: MPMediaPlaylistPropertyName) as? String
    }
    open override var persistentID: MPMediaEntityPersistentID {
        (value(forProperty: MPMediaPlaylistPropertyPersistentID) as? NSNumber)?.uint64Value ?? 0
    }
    open var playlistAttributes: MPMediaPlaylistAttribute {
        if let number = value(forProperty: MPMediaPlaylistPropertyPlaylistAttributes) as? NSNumber {
            return MPMediaPlaylistAttribute(rawValue: number.uintValue)
        }
        return []
    }
    open var seedItems: [MPMediaItem]? {
        value(forProperty: MPMediaPlaylistPropertySeedItems) as? [MPMediaItem]
    }

    open func addItem(withProductID productID: String) async throws {
        _ = productID
        throw _mpNotSupportedError()
    }

    open func add(_ mediaItems: [MPMediaItem]) async throws {
        _ = mediaItems
        throw _mpNotSupportedError()
    }
}

public protocol MPMediaPlayback: AnyObject {
    var isPreparedToPlay: Bool { get }
    var currentPlaybackTime: TimeInterval { get set }
    var currentPlaybackRate: Float { get set }
    func prepareToPlay()
    func play()
    func pause()
    func stop()
    func beginSeekingForward()
    func beginSeekingBackward()
    func endSeeking()
}
