import Foundation

public protocol MPMediaPlayback: AnyObject {
    var currentPlaybackRate: Float { get set }
    var currentPlaybackTime: TimeInterval { get set }
    var isPreparedToPlay: Bool { get }
    func beginSeekingBackward()
    func beginSeekingForward()
    func endSeeking()
    func pause()
    func play()
    func prepareToPlay()
    func stop()
}

extension MPMediaPlayback {
    public static var MPMediaPlaybackIsPreparedToPlayDidChange: NSNotification.Name {
        .MPMediaPlaybackIsPreparedToPlayDidChange
    }
}

public protocol MPSystemMusicPlayerController: NSObjectProtocol {
    func openToPlay(_ queueDescriptor: MPMusicPlayerQueueDescriptor)
}

open class MPMusicPlayerQueueDescriptor: NSObject {}

open class MPMusicPlayerMediaItemQueueDescriptor: MPMusicPlayerQueueDescriptor {
    public let itemCollection: MPMediaItemCollection
    public let query: MPMediaQuery
    public var startItem: MPMediaItem?

    public init(itemCollection: MPMediaItemCollection) {
        self.itemCollection = itemCollection
        self.query = MPMediaQuery(filterPredicates: nil)
        super.init()
    }

    public init(query: MPMediaQuery) {
        self.query = query
        self.itemCollection = MPMediaItemCollection(items: query.items ?? [])
        super.init()
    }

    public func setEndTime(_ endTime: TimeInterval, for mediaItem: MPMediaItem) {
        _ = endTime
        _ = mediaItem
    }

    public func setStartTime(_ startTime: TimeInterval, for mediaItem: MPMediaItem) {
        _ = startTime
        _ = mediaItem
    }
}

open class MPMusicPlayerStoreQueueDescriptor: MPMusicPlayerQueueDescriptor {
    public var storeIDs: [String]?
    public var startItemID: String?

    public init(storeIDs: [String]) {
        self.storeIDs = storeIDs
        super.init()
    }

    public func setEndTime(_ endTime: TimeInterval, forItemWithStoreID storeID: String) {
        _ = endTime
        _ = storeID
    }

    public func setStartTime(_ startTime: TimeInterval, forItemWithStoreID storeID: String) {
        _ = startTime
        _ = storeID
    }
}

open class MPMusicPlayerPlayParameters: NSObject {
    public let dictionary: [String: Any]

    public init?(dictionary: [String: Any]) {
        if dictionary.isEmpty { return nil }
        self.dictionary = dictionary
        super.init()
    }
}

open class MPMusicPlayerPlayParametersQueueDescriptor: MPMusicPlayerQueueDescriptor {
    public var playParametersQueue: [MPMusicPlayerPlayParameters]
    public var startItemPlayParameters: MPMusicPlayerPlayParameters?

    public init(playParametersQueue: [MPMusicPlayerPlayParameters]) {
        self.playParametersQueue = playParametersQueue
        super.init()
    }

    public func setEndTime(_ endTime: TimeInterval, forItemWith playParameters: MPMusicPlayerPlayParameters) {
        _ = endTime
        _ = playParameters
    }

    public func setStartTime(_ startTime: TimeInterval, forItemWith playParameters: MPMusicPlayerPlayParameters) {
        _ = startTime
        _ = playParameters
    }
}

open class MPMusicPlayerControllerQueue: NSObject {
    public internal(set) var items: [MPMediaItem] = []
}

open class MPMusicPlayerControllerMutableQueue: MPMusicPlayerControllerQueue {
    public func insert(_ queueDescriptor: MPMusicPlayerQueueDescriptor, after afterItem: MPMediaItem?) {
        _ = queueDescriptor
        _ = afterItem
    }

    public func remove(_ item: MPMediaItem) {
        items.removeAll { $0 === item }
    }
}

open class MPMusicPlayerController: NSObject, MPMediaPlayback, MPSystemMusicPlayerController {
    private static let application = MPMusicPlayerController()
    private static let system = MPMusicPlayerController()
    private static let applicationQueue = MPMusicPlayerApplicationController()

    public class var applicationMusicPlayer: MPMusicPlayerController { application }
    public class var iPodMusicPlayer: MPMusicPlayerController { system }
    public class var systemMusicPlayer: any MPMusicPlayerController & MPSystemMusicPlayerController { system }
    public class var applicationQueuePlayer: MPMusicPlayerApplicationController { applicationQueue }

    /// MEASURED /tmp/mp_oracle.json iOS 26.1: rate 0 at rest.
    public var currentPlaybackRate: Float = 0
    public var currentPlaybackTime: TimeInterval = 0
    public private(set) var isPreparedToPlay: Bool = false
    public private(set) var playbackState: MPMusicPlaybackState = .stopped
    /// MEASURED: application/system/queue players start at `.none` / `.off`, not `.default`.
    public var repeatMode: MPMusicRepeatMode = .none
    public var shuffleMode: MPMusicShuffleMode = .off
    public var nowPlayingItem: MPMediaItem? {
        didSet {
            postIfNeeded(.MPMusicPlayerControllerNowPlayingItemDidChange)
        }
    }
    /// MEASURED: 0 when no item (not NSNotFound).
    public private(set) var indexOfNowPlayingItem: Int = 0
    private var queueItems: [MPMediaItem] = []
    private var generatingNotifications = 0

    public func beginSeekingBackward() {
        if playbackState == .playing { playbackState = .seekingBackward }
        postIfNeeded(.MPMusicPlayerControllerPlaybackStateDidChange)
    }

    public func beginSeekingForward() {
        if playbackState == .playing { playbackState = .seekingForward }
        postIfNeeded(.MPMusicPlayerControllerPlaybackStateDidChange)
    }

    public func endSeeking() {
        if playbackState == .seekingForward || playbackState == .seekingBackward {
            playbackState = queueItems.isEmpty ? .stopped : .playing
            postIfNeeded(.MPMusicPlayerControllerPlaybackStateDidChange)
        }
    }

    public func pause() {
        if playbackState == .playing || playbackState == .seekingForward || playbackState == .seekingBackward {
            playbackState = .paused
            currentPlaybackRate = 0
            postIfNeeded(.MPMusicPlayerControllerPlaybackStateDidChange)
        }
    }

    /// MEASURED: `play()` with an empty queue stays `.stopped`. With in-process
    /// queue items (setQueue / fixture), this is a local state machine — not
    /// Apple Music playback.
    public func play() {
        guard !queueItems.isEmpty, nowPlayingItem != nil else {
            playbackState = .stopped
            currentPlaybackRate = 0
            return
        }
        isPreparedToPlay = true
        playbackState = .playing
        currentPlaybackRate = 1
        postIfNeeded(.MPMusicPlayerControllerPlaybackStateDidChange)
    }

    public func prepareToPlay() {
        isPreparedToPlay = !queueItems.isEmpty
    }

    public func stop() {
        playbackState = .stopped
        isPreparedToPlay = false
        currentPlaybackTime = 0
        currentPlaybackRate = 0
        postIfNeeded(.MPMusicPlayerControllerPlaybackStateDidChange)
    }

    public func prepareToPlay(completionHandler: @escaping ((any Error)?) -> Void) {
        if !queueItems.isEmpty {
            isPreparedToPlay = true
            DispatchQueue.global(qos: .utility).async {
                completionHandler(nil)
            }
            return
        }
        isPreparedToPlay = false
        DispatchQueue.global(qos: .utility).async {
            completionHandler(MPError(.notSupported))
        }
    }

    public func beginGeneratingPlaybackNotifications() {
        generatingNotifications += 1
    }

    public func endGeneratingPlaybackNotifications() {
        if generatingNotifications > 0 {
            generatingNotifications -= 1
        }
    }

    public func skipToBeginning() {
        currentPlaybackTime = 0
    }

    public func skipToNextItem() {
        guard !queueItems.isEmpty else { return }
        let next = min(indexOfNowPlayingItem + 1, queueItems.count - 1)
        if next != indexOfNowPlayingItem {
            indexOfNowPlayingItem = next
            nowPlayingItem = queueItems[next]
        } else if repeatMode == .all, let first = queueItems.first {
            indexOfNowPlayingItem = 0
            nowPlayingItem = first
        }
        currentPlaybackTime = 0
    }

    public func skipToPreviousItem() {
        guard !queueItems.isEmpty else { return }
        let prev = max(indexOfNowPlayingItem - 1, 0)
        if prev != indexOfNowPlayingItem {
            indexOfNowPlayingItem = prev
            nowPlayingItem = queueItems[prev]
        }
        currentPlaybackTime = 0
    }

    public func append(_ descriptor: MPMusicPlayerQueueDescriptor) {
        let extra = items(from: descriptor)
        queueItems.append(contentsOf: extra)
        if nowPlayingItem == nil {
            nowPlayingItem = queueItems.first
            indexOfNowPlayingItem = 0
        }
        postIfNeeded(.MPMusicPlayerControllerQueueDidChange)
    }

    public func prepend(_ descriptor: MPMusicPlayerQueueDescriptor) {
        let extra = items(from: descriptor)
        queueItems.insert(contentsOf: extra, at: 0)
        if let current = nowPlayingItem, let idx = queueItems.firstIndex(where: { $0 === current }) {
            indexOfNowPlayingItem = idx
        } else {
            nowPlayingItem = queueItems.first
            indexOfNowPlayingItem = 0
        }
        postIfNeeded(.MPMusicPlayerControllerQueueDidChange)
    }

    public func setQueue(with descriptor: MPMusicPlayerQueueDescriptor) {
        applyQueue(items(from: descriptor))
    }

    public func setQueue(with itemCollection: MPMediaItemCollection) {
        applyQueue(itemCollection.items)
    }

    public func setQueue(with query: MPMediaQuery) {
        applyQueue(query.items ?? [])
    }

    public func setQueue(with storeIDs: [String]) {
        _ = storeIDs
        applyQueue([])
    }

    public func openToPlay(_ queueDescriptor: MPMusicPlayerQueueDescriptor) {
        setQueue(with: queueDescriptor)
        play()
    }

    private func applyQueue(_ items: [MPMediaItem]) {
        queueItems = items
        nowPlayingItem = queueItems.first
        indexOfNowPlayingItem = 0
        playbackState = .stopped
        currentPlaybackTime = 0
        currentPlaybackRate = 0
        postIfNeeded(.MPMusicPlayerControllerQueueDidChange)
    }

    private func items(from descriptor: MPMusicPlayerQueueDescriptor) -> [MPMediaItem] {
        if let media = descriptor as? MPMusicPlayerMediaItemQueueDescriptor {
            if !media.itemCollection.items.isEmpty {
                return media.itemCollection.items
            }
            return media.query.items ?? []
        }
        return []
    }

    private func postIfNeeded(_ name: NSNotification.Name) {
        guard generatingNotifications > 0 else { return }
        NotificationCenter.default.post(name: name, object: self)
    }
}

open class MPMusicPlayerApplicationController: MPMusicPlayerController {
    public func perform(
        queueTransaction: @escaping (MPMusicPlayerControllerMutableQueue) -> Void
    ) async throws -> MPMusicPlayerControllerQueue {
        let queue = MPMusicPlayerControllerMutableQueue()
        queue.items = []
        queueTransaction(queue)
        throw MPError(.notSupported)
    }
}

open class MPNowPlayingInfoCenter: NSObject {
    private static let sharedCenter = MPNowPlayingInfoCenter()
    public var nowPlayingInfo: [String: Any]?
    public var playbackState: MPNowPlayingPlaybackState = .unknown

    public class func `default`() -> MPNowPlayingInfoCenter { sharedCenter }

    /// MEASURED /tmp/mp_oracle.json iOS 26.1: only the 3×4 animated-artwork key.
    public class var supportedAnimatedArtworkKeys: [String] {
        [MPNowPlayingInfoProperty3x4AnimatedArtwork]
    }
}

open class MPNowPlayingInfoLanguageOption: NSObject {
    public let languageOptionType: MPNowPlayingInfoLanguageOptionType
    public let languageTag: String?
    public let languageOptionCharacteristics: [String]?
    public let displayName: String?
    public let identifier: String?

    public init(
        type languageOptionType: MPNowPlayingInfoLanguageOptionType,
        languageTag: String,
        characteristics languageOptionCharacteristics: [String]?,
        displayName: String,
        identifier: String
    ) {
        self.languageOptionType = languageOptionType
        self.languageTag = languageTag
        self.languageOptionCharacteristics = languageOptionCharacteristics
        self.displayName = displayName
        self.identifier = identifier
    }

    public func isAutomaticAudibleLanguageOption() -> Bool { false }
    public func isAutomaticLegibleLanguageOption() -> Bool { false }
}

open class MPNowPlayingInfoLanguageOptionGroup: NSObject {
    public let languageOptions: [MPNowPlayingInfoLanguageOption]
    public let defaultLanguageOption: MPNowPlayingInfoLanguageOption?
    public let allowEmptySelection: Bool

    public init(
        languageOptions: [MPNowPlayingInfoLanguageOption],
        defaultLanguageOption: MPNowPlayingInfoLanguageOption?,
        allowEmptySelection: Bool
    ) {
        self.languageOptions = languageOptions
        self.defaultLanguageOption = defaultLanguageOption
        self.allowEmptySelection = allowEmptySelection
    }
}

public protocol MPNowPlayingSessionDelegate: NSObjectProtocol {
    func nowPlayingSessionDidChangeActive(_ nowPlayingSession: MPNowPlayingSession)
    func nowPlayingSessionDidChangeCanBecomeActive(_ nowPlayingSession: MPNowPlayingSession)
}

extension MPNowPlayingSessionDelegate {
    public func nowPlayingSessionDidChangeActive(_ nowPlayingSession: MPNowPlayingSession) {
        _ = nowPlayingSession
    }

    public func nowPlayingSessionDidChangeCanBecomeActive(_ nowPlayingSession: MPNowPlayingSession) {
        _ = nowPlayingSession
    }
}

/// Session without AVPlayer. Linux cannot become the active Now Playing session.
open class MPNowPlayingSession: NSObject {
    public private(set) var isActive: Bool = false
    public var automaticallyPublishesNowPlayingInfo: Bool = false
    public var canBecomeActive: Bool { false }
    public weak var delegate: (any MPNowPlayingSessionDelegate)?
    public let nowPlayingInfoCenter = MPNowPlayingInfoCenter()
    public let remoteCommandCenter = MPRemoteCommandCenter()

    public func becomeActiveIfPossible(completion: ((Bool) -> Void)? = nil) {
        isActive = false
        DispatchQueue.global(qos: .utility).async {
            completion?(false)
        }
    }
}

open class MPMovieAccessLogEvent: NSObject {
    public var numberOfSegmentsDownloaded: Int { 0 }
    public var playbackStartDate: Date? { nil }
    public var URI: String? { nil }
    public var serverAddress: String? { nil }
    public var numberOfServerAddressChanges: Int { 0 }
    public var playbackSessionID: String? { nil }
    public var playbackStartOffset: TimeInterval { 0 }
    public var segmentsDownloadedDuration: TimeInterval { 0 }
    public var durationWatched: TimeInterval { 0 }
    public var numberOfStalls: Int { 0 }
    public var numberOfBytesTransferred: Int64 { 0 }
    public var indicatedBitrate: Double { 0 }
    public var observedBitrate: Double { 0 }
    public var numberOfDroppedVideoFrames: Int { 0 }
}

open class MPMovieAccessLog: NSObject {
    public var events: [MPMovieAccessLogEvent] { [] }
    public var extendedLogData: Data? { nil }
    public var extendedLogDataStringEncoding: UInt { String.Encoding.utf8.rawValue }
}

open class MPMovieErrorLogEvent: NSObject {
    public var date: Date? { nil }
    public var URI: String? { nil }
    public var serverAddress: String? { nil }
    public var playbackSessionID: String? { nil }
    public var errorStatusCode: Int { 0 }
    public var errorDomain: String { MPError.errorDomain }
    public var errorComment: String? { nil }
}

open class MPMovieErrorLog: NSObject {
    public var events: [MPMovieErrorLogEvent] { [] }
    public var extendedLogData: Data? { nil }
    public var extendedLogDataStringEncoding: UInt { String.Encoding.utf8.rawValue }
}

open class MPTimedMetadata: NSObject {
    public var allMetadata: [AnyHashable: Any]! { [:] }
    public var key: String! { "" }
    public var keyspace: String! { "" }
    public var timestamp: TimeInterval { 0 }
    public var value: Any! { NSNull() }
}

/// Deprecated movie controller without UIView. Playback stays stopped.
open class MPMoviePlayerController: NSObject, MPMediaPlayback {
    public var contentURL: URL!
    public var currentPlaybackRate: Float = 1
    public var currentPlaybackTime: TimeInterval = 0
    public private(set) var isPreparedToPlay: Bool = false
    public var allowsAirPlay: Bool = false
    public var isAirPlayVideoActive: Bool { false }
    public var controlStyle: MPMovieControlStyle = .fullscreen
    public var duration: TimeInterval { 0 }
    public var endPlaybackTime: TimeInterval = -1
    public var isFullscreen: Bool = false
    public var initialPlaybackTime: TimeInterval = -1
    public var loadState: MPMovieLoadState { [] }
    public var movieMediaTypes: MPMovieMediaTypeMask { [] }
    public var movieSourceType: MPMovieSourceType = .unknown
    public var playableDuration: TimeInterval { 0 }
    public private(set) var playbackState: MPMoviePlaybackState = .stopped
    public var readyForDisplay: Bool { false }
    public var repeatMode: MPMovieRepeatMode = .none
    public var scalingMode: MPMovieScalingMode = .aspectFit
    public var shouldAutoplay: Bool = false
    public var timedMetadata: [Any]! { [] }
    public var useApplicationAudioSession: Bool = true
    public var accessLog: MPMovieAccessLog! { MPMovieAccessLog() }
    public var errorLog: MPMovieErrorLog! { MPMovieErrorLog() }

    public init!(contentURL url: URL!) {
        self.contentURL = url
        super.init()
    }

    public func beginSeekingBackward() {}
    public func beginSeekingForward() {}
    public func endSeeking() {}
    public func pause() {
        if playbackState == .playing { playbackState = .paused }
    }
    public func play() { playbackState = .stopped }
    public func prepareToPlay() { isPreparedToPlay = false }
    public func stop() {
        playbackState = .stopped
        isPreparedToPlay = false
    }

    public func cancelAllThumbnailImageRequests() {}
    public func requestThumbnailImages(atTimes playbackTimes: [Any]!, timeOption option: MPMovieTimeOption) {
        _ = playbackTimes
        _ = option
    }
    public func setFullscreen(_ fullscreen: Bool, animated: Bool) {
        isFullscreen = fullscreen
        _ = animated
    }
}
