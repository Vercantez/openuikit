import Foundation

public protocol MPSystemMusicPlayerController: NSObjectProtocol {
    func openToPlay(_ queueDescriptor: MPMusicPlayerQueueDescriptor)
}

open class MPMusicPlayerQueueDescriptor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class MPMusicPlayerMediaItemQueueDescriptor: MPMusicPlayerQueueDescriptor, @unchecked Sendable {
    public let itemCollection: MPMediaItemCollection
    public let query: MPMediaQuery
    open var startItem: MPMediaItem?
    private var startTimes: [ObjectIdentifier: TimeInterval] = [:]
    private var endTimes: [ObjectIdentifier: TimeInterval] = [:]

    public init(itemCollection: MPMediaItemCollection) {
        self.itemCollection = itemCollection
        self.query = MPMediaQuery()
        super.init()
    }

    public init(query: MPMediaQuery) {
        self.query = (query.copy() as? MPMediaQuery) ?? query
        self.itemCollection = MPMediaItemCollection(items: query.items ?? [])
        super.init()
    }

    open func setStartTime(_ startTime: TimeInterval, for mediaItem: MPMediaItem) {
        startTimes[ObjectIdentifier(mediaItem)] = startTime
    }

    open func setEndTime(_ endTime: TimeInterval, for mediaItem: MPMediaItem) {
        endTimes[ObjectIdentifier(mediaItem)] = endTime
    }
}

open class MPMusicPlayerStoreQueueDescriptor: MPMusicPlayerQueueDescriptor, @unchecked Sendable {
    open var storeIDs: [String]?
    open var startItemID: String?
    private var startTimes: [String: TimeInterval] = [:]
    private var endTimes: [String: TimeInterval] = [:]

    public init(storeIDs: [String]) {
        self.storeIDs = storeIDs
        super.init()
    }

    open func setStartTime(_ startTime: TimeInterval, forItemWithStoreID storeID: String) {
        startTimes[storeID] = startTime
    }

    open func setEndTime(_ endTime: TimeInterval, forItemWithStoreID storeID: String) {
        endTimes[storeID] = endTime
    }
}

open class MPMusicPlayerPlayParameters: NSObject, Codable, @unchecked Sendable {
    public let dictionary: [String: Any]

    public init?(dictionary: [String: Any]) {
        self.dictionary = dictionary
        super.init()
    }

    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw MPError(.notSupported)
        }
        self.init(dictionary: dictionary)!
    }

    public func encode(to encoder: any Encoder) throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

open class MPMusicPlayerPlayParametersQueueDescriptor: MPMusicPlayerQueueDescriptor, @unchecked Sendable {
    open var playParametersQueue: [MPMusicPlayerPlayParameters]
    open var startItemPlayParameters: MPMusicPlayerPlayParameters?
    private var startTimes: [ObjectIdentifier: TimeInterval] = [:]
    private var endTimes: [ObjectIdentifier: TimeInterval] = [:]

    public init(playParametersQueue: [MPMusicPlayerPlayParameters]) {
        self.playParametersQueue = playParametersQueue
        super.init()
    }

    open func setStartTime(
        _ startTime: TimeInterval,
        forItemWith playParameters: MPMusicPlayerPlayParameters
    ) {
        startTimes[ObjectIdentifier(playParameters)] = startTime
    }

    open func setEndTime(
        _ endTime: TimeInterval,
        forItemWith playParameters: MPMusicPlayerPlayParameters
    ) {
        endTimes[ObjectIdentifier(playParameters)] = endTime
    }
}

open class MPMusicPlayerControllerQueue: NSObject, @unchecked Sendable {
    public internal(set) var items: [MPMediaItem]

    init(items: [MPMediaItem]) {
        self.items = items
        super.init()
    }
}

open class MPMusicPlayerControllerMutableQueue: MPMusicPlayerControllerQueue, @unchecked Sendable {
    open func insert(
        _ queueDescriptor: MPMusicPlayerQueueDescriptor,
        after afterItem: MPMediaItem?
    ) {
        _ = (queueDescriptor, afterItem)
    }

    open func remove(_ item: MPMediaItem) {
        items.removeAll { $0 === item }
    }
}

/// Local music-player object. There is no Apple Music, Music.app, or iPod
/// library. Playback methods are inert and `playbackState` stays `.stopped`.
open class MPMusicPlayerController: NSObject, MPMediaPlayback, @unchecked Sendable {
    private static let _application = MPMusicPlayerController()
    private static let _system = _MPSystemMusicPlayerController()
    private static let _applicationQueue = MPMusicPlayerApplicationController()

    private let lock = NSLock()
    private var _nowPlayingItem: MPMediaItem?
    private var _repeatMode: MPMusicRepeatMode = .default
    private var _shuffleMode: MPMusicShuffleMode = .default
    private var _currentPlaybackTime: TimeInterval = 0
    private var _currentPlaybackRate: Float = 1
    private var generatingNotifications = false
    private var queueItems: [MPMediaItem] = []
    private var storeIDs: [String] = []

    public override init() {
        super.init()
    }

    open class var applicationMusicPlayer: MPMusicPlayerController { _application }

    open class var applicationQueuePlayer: MPMusicPlayerApplicationController {
        _applicationQueue
    }

    open class var iPodMusicPlayer: MPMusicPlayerController { _system }

    open class var systemMusicPlayer: any MPMusicPlayerController & MPSystemMusicPlayerController {
        _system
    }

    open var nowPlayingItem: MPMediaItem? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _nowPlayingItem
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _nowPlayingItem = newValue
        }
    }

    open var indexOfNowPlayingItem: Int {
        lock.lock()
        defer { lock.unlock() }
        guard let item = _nowPlayingItem else { return NSNotFound }
        if let index = queueItems.firstIndex(where: { $0 === item }) {
            return index
        }
        return NSNotFound
    }

    open var playbackState: MPMusicPlaybackState { .stopped }

    open var repeatMode: MPMusicRepeatMode {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _repeatMode
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _repeatMode = newValue
        }
    }

    open var shuffleMode: MPMusicShuffleMode {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shuffleMode
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shuffleMode = newValue
        }
    }

    open var isPreparedToPlay: Bool { false }

    open var currentPlaybackTime: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentPlaybackTime
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _currentPlaybackTime = newValue
        }
    }

    open var currentPlaybackRate: Float {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentPlaybackRate
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _currentPlaybackRate = newValue
        }
    }

    open func prepareToPlay() {}

    open func prepareToPlay(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(_mpNotSupportedError())
    }

    open func play() {}
    open func pause() {}
    open func stop() {}
    open func beginSeekingForward() {}
    open func beginSeekingBackward() {}
    open func endSeeking() {}

    open func skipToNextItem() {}
    open func skipToPreviousItem() {}
    open func skipToBeginning() {
        currentPlaybackTime = 0
    }

    open func beginGeneratingPlaybackNotifications() {
        generatingNotifications = true
    }

    open func endGeneratingPlaybackNotifications() {
        generatingNotifications = false
    }

    open func setQueue(with descriptor: MPMusicPlayerQueueDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        applyLocked(descriptor: descriptor)
    }

    open func setQueue(with itemCollection: MPMediaItemCollection) {
        lock.lock()
        defer { lock.unlock() }
        queueItems = itemCollection.items
        storeIDs = []
        _nowPlayingItem = queueItems.first
    }

    open func setQueue(with query: MPMediaQuery) {
        lock.lock()
        defer { lock.unlock() }
        queueItems = query.items ?? []
        storeIDs = []
        _nowPlayingItem = queueItems.first
    }

    open func setQueue(with storeIDs: [String]) {
        lock.lock()
        defer { lock.unlock() }
        self.storeIDs = storeIDs
        queueItems = []
        _nowPlayingItem = nil
    }

    open func append(_ descriptor: MPMusicPlayerQueueDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        if let media = descriptor as? MPMusicPlayerMediaItemQueueDescriptor {
            queueItems.append(contentsOf: media.itemCollection.items)
        } else if let store = descriptor as? MPMusicPlayerStoreQueueDescriptor {
            storeIDs.append(contentsOf: store.storeIDs ?? [])
        }
    }

    open func prepend(_ descriptor: MPMusicPlayerQueueDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        if let media = descriptor as? MPMusicPlayerMediaItemQueueDescriptor {
            queueItems.insert(contentsOf: media.itemCollection.items, at: 0)
        } else if let store = descriptor as? MPMusicPlayerStoreQueueDescriptor {
            storeIDs.insert(contentsOf: store.storeIDs ?? [], at: 0)
        }
    }

    private func applyLocked(descriptor: MPMusicPlayerQueueDescriptor) {
        if let media = descriptor as? MPMusicPlayerMediaItemQueueDescriptor {
            queueItems = media.itemCollection.items
            storeIDs = []
            _nowPlayingItem = media.startItem ?? queueItems.first
        } else if let store = descriptor as? MPMusicPlayerStoreQueueDescriptor {
            storeIDs = store.storeIDs ?? []
            queueItems = []
            _nowPlayingItem = nil
        } else if let parameters = descriptor as? MPMusicPlayerPlayParametersQueueDescriptor {
            _ = parameters
            queueItems = []
            storeIDs = []
            _nowPlayingItem = nil
        }
    }
}

open class MPMusicPlayerApplicationController: MPMusicPlayerController, @unchecked Sendable {
    open func perform(
        queueTransaction: @escaping (MPMusicPlayerControllerMutableQueue) -> Void
    ) async throws -> MPMusicPlayerControllerQueue {
        _ = queueTransaction
        throw _mpNotSupportedError()
    }
}

private final class _MPSystemMusicPlayerController: MPMusicPlayerController, MPSystemMusicPlayerController, @unchecked Sendable {
    func openToPlay(_ queueDescriptor: MPMusicPlayerQueueDescriptor) {
        setQueue(with: queueDescriptor)
        // Cannot launch Music.app on Linux.
    }
}
