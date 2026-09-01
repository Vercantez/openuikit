import Foundation

open class MPContentItem: NSObject, @unchecked Sendable {
    public let identifier: String
    open var title: String?
    open var subtitle: String?
    open var artwork: MPMediaItemArtwork?
    open var playbackProgress: Float = 0
    open var isContainer = false
    open var isPlayable = false
    open var isStreamingContent = false
    open var isExplicitContent = false

    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
}

open class MPPlayableContentManagerContext: NSObject, @unchecked Sendable {
    /// CarPlay / playable-content endpoints are not present on Linux.
    open var contentLimitsEnabled: Bool { false }
    open var contentLimitsEnforced: Bool { false }
    open var endpointAvailable: Bool { false }
    open var enforcedContentItemsCount: Int { 0 }
    open var enforcedContentTreeDepth: Int { 0 }
}

public protocol MPPlayableContentDataSource: NSObjectProtocol {
    func numberOfChildItems(at indexPath: IndexPath) -> Int
    func contentItem(at indexPath: IndexPath) -> MPContentItem?
}

extension MPPlayableContentDataSource {
    public func beginLoadingChildItems(at indexPath: IndexPath) async throws {
        _ = indexPath
    }

    public func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        _ = indexPath
        return false
    }

    public func contentItem(forIdentifier identifier: String) async throws -> MPContentItem {
        _ = identifier
        throw _mpNotSupportedError()
    }
}

public protocol MPPlayableContentDelegate: NSObjectProtocol {}

extension MPPlayableContentDelegate {
    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        didUpdate context: MPPlayableContentManagerContext
    ) {
        _ = (contentManager, context)
    }

    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithCompletionHandler completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        completionHandler(_mpNotSupportedError())
    }

    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithContentItems contentItems: [Any]?,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (contentManager, contentItems)
        completionHandler(_mpNotSupportedError())
    }

    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initiatePlaybackOfContentItemAt indexPath: IndexPath
    ) async throws {
        _ = (contentManager, indexPath)
        throw _mpNotSupportedError()
    }
}

/// CarPlay playable-content coordinator. The shared instance exists so apps
/// can assign a data source, but `context.endpointAvailable` is always false
/// and playback-queue initialization fails closed.
open class MPPlayableContentManager: NSObject, @unchecked Sendable {
    private static let _shared = MPPlayableContentManager()
    private let _context = MPPlayableContentManagerContext()

    open weak var dataSource: (any MPPlayableContentDataSource)?
    open weak var delegate: (any MPPlayableContentDelegate)?
    open var nowPlayingIdentifiers: [String] = []
    open var context: MPPlayableContentManagerContext { _context }

    public override init() {
        super.init()
    }

    open class func shared() -> Self {
        unsafeDowncast(_shared, to: Self.self)
    }

    open func reloadData() {}
    open func beginUpdates() {}
    open func endUpdates() {}
}

open class MPTimedMetadata: NSObject, @unchecked Sendable {
    open var key: String!
    open var keyspace: String!
    open var timestamp: TimeInterval = 0
    open var value: Any!
    open var allMetadata: [AnyHashable: Any]!

    public override init() {
        super.init()
    }
}
