import Foundation

/// CarPlay / playable-content tree node. Artwork stays omitted until UIKit exists.
open class MPContentItem: NSObject {
    public let identifier: String
    public var isContainer: Bool = false
    public var isExplicitContent: Bool = false
    public var isPlayable: Bool = false
    public var playbackProgress: Float = 0
    public var isStreamingContent: Bool = false
    public var subtitle: String?
    public var title: String?

    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
}

open class MPPlayableContentManagerContext: NSObject {
    /// Linux has no CarPlay endpoint.
    public var contentLimitsEnabled: Bool { false }
    public var contentLimitsEnforced: Bool { false }
    public var endpointAvailable: Bool { false }
    public var enforcedContentItemsCount: Int { 0 }
    public var enforcedContentTreeDepth: Int { 0 }
}

/// Optional Objective-C datasource methods are protocol requirements with
/// extension defaults so existential dispatch honors conformer overrides.
public protocol MPPlayableContentDataSource: NSObjectProtocol {
    func numberOfChildItems(at indexPath: IndexPath) -> Int
    func contentItem(at indexPath: IndexPath) -> MPContentItem?
    func beginLoadingChildItems(at indexPath: IndexPath) async throws
    func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool
    func contentItem(forIdentifier identifier: String) async throws -> MPContentItem
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
        throw MPError(.notFound)
    }
}

public protocol MPPlayableContentDelegate: NSObjectProtocol {
    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        didUpdate context: MPPlayableContentManagerContext
    )
    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithCompletionHandler completionHandler: @escaping ((any Error)?) -> Void
    )
    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithContentItems contentItems: [Any]?,
        completionHandler: @escaping ((any Error)?) -> Void
    )
    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initiatePlaybackOfContentItemAt indexPath: IndexPath
    ) async throws
}

extension MPPlayableContentDelegate {
    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        didUpdate context: MPPlayableContentManagerContext
    ) {
        _ = contentManager
        _ = context
    }

    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithCompletionHandler completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        DispatchQueue.global(qos: .utility).async {
            completionHandler(MPError(.notSupported))
        }
    }

    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithContentItems contentItems: [Any]?,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        _ = contentItems
        DispatchQueue.global(qos: .utility).async {
            completionHandler(MPError(.notSupported))
        }
    }

    public func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initiatePlaybackOfContentItemAt indexPath: IndexPath
    ) async throws {
        _ = contentManager
        _ = indexPath
        throw MPError(.notSupported)
    }
}

open class MPPlayableContentManager: NSObject {
    private static let sharedManager = MPPlayableContentManager()

    public private(set) var context = MPPlayableContentManagerContext()
    public weak var dataSource: (any MPPlayableContentDataSource)?
    public weak var delegate: (any MPPlayableContentDelegate)?
    public var nowPlayingIdentifiers: [String] = []
    private var updateDepth = 0

    public class func shared() -> Self {
        sharedManager as! Self
    }

    public func beginUpdates() {
        updateDepth += 1
    }

    public func endUpdates() {
        if updateDepth > 0 {
            updateDepth -= 1
        }
    }

    public func reloadData() {
        // No CarPlay tree. Datasource is retained for host queries only.
    }
}
