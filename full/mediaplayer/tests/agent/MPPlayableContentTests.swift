import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

final class MPPlayableDefaultDataSource: NSObject, MPPlayableContentDataSource {
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 0
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return nil
    }
}

final class MPPlayableOverrideDataSource: NSObject, MPPlayableContentDataSource {
    var began: [IndexPath] = []
    var progress: [IndexPath] = []
    var identifiers: [String] = []

    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        indexPath.count == 0 ? 1 : 0
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        let item = MPContentItem(identifier: "item-\(indexPath.description)")
        item.title = "Child"
        item.isPlayable = true
        return item
    }

    func beginLoadingChildItems(at indexPath: IndexPath) async throws {
        began.append(indexPath)
    }

    func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        progress.append(indexPath)
        return true
    }

    func contentItem(forIdentifier identifier: String) async throws -> MPContentItem {
        identifiers.append(identifier)
        return MPContentItem(identifier: identifier)
    }
}

final class MPPlayableDefaultDelegate: NSObject, MPPlayableContentDelegate {}

final class MPPlayableOverrideDelegate: NSObject, MPPlayableContentDelegate {
    var updated = 0
    var initQueue = 0
    var initItems = 0
    var initiate = 0

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        didUpdate context: MPPlayableContentManagerContext
    ) {
        _ = contentManager
        _ = context
        updated += 1
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithCompletionHandler completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        initQueue += 1
        completionHandler(nil)
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithContentItems contentItems: [Any]?,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        _ = contentItems
        initItems += 1
        completionHandler(nil)
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initiatePlaybackOfContentItemAt indexPath: IndexPath
    ) async throws {
        _ = contentManager
        _ = indexPath
        initiate += 1
    }
}

func testContentItemProperties() {
    let content = MPContentItem(identifier: "root")
    content.title = "Root"
    content.subtitle = "Sub"
    content.isContainer = true
    content.isExplicitContent = true
    content.isStreamingContent = true
    content.isPlayable = true
    content.playbackProgress = 0.5
    precondition(content.identifier == "root")
    precondition(content.title == "Root")
    precondition(content.subtitle == "Sub")
    precondition(content.isContainer)
    precondition(content.isExplicitContent)
    precondition(content.isStreamingContent)
    precondition(content.isPlayable)
    precondition(content.playbackProgress == 0.5)
}

func testPlayableContentFailClosed() {
    let manager = MPPlayableContentManager.shared()
    precondition(!manager.context.endpointAvailable)
    precondition(manager.context.enforcedContentItemsCount == 0)
    precondition(!manager.context.contentLimitsEnabled)
    precondition(!manager.context.contentLimitsEnforced)
    precondition(manager.context.enforcedContentTreeDepth == 0)
    manager.beginUpdates()
    manager.endUpdates()
    manager.reloadData()
    manager.nowPlayingIdentifiers = ["a"]
    precondition(manager.nowPlayingIdentifiers == ["a"])

    let defaults = MPPlayableDefaultDataSource()
    let override = MPPlayableOverrideDataSource()
    let asDefault: any MPPlayableContentDataSource = defaults
    let asOverride: any MPPlayableContentDataSource = override
    precondition(asDefault.numberOfChildItems(at: IndexPath()) == 0)
    precondition(asDefault.contentItem(at: IndexPath()) == nil)
    precondition(!asDefault.childItemsDisplayPlaybackProgress(at: IndexPath(index: 0)))

    let loadSem = DispatchSemaphore(value: 0)
    Task {
        try! await asDefault.beginLoadingChildItems(at: IndexPath())
        do {
            _ = try await asDefault.contentItem(forIdentifier: "x")
            fatalError("default identifier should throw")
        } catch {
            precondition(MPError.notFound ~= error)
        }
        precondition(asOverride.numberOfChildItems(at: IndexPath()) == 1)
        precondition(asOverride.contentItem(at: IndexPath(index: 0))?.isPlayable == true)
        precondition(asOverride.childItemsDisplayPlaybackProgress(at: IndexPath(index: 1)))
        try! await asOverride.beginLoadingChildItems(at: IndexPath(index: 2))
        precondition(override.began.count == 1)
        let fetched = try! await asOverride.contentItem(forIdentifier: "abc")
        precondition(fetched.identifier == "abc")
        precondition(override.identifiers == ["abc"])
        loadSem.signal()
    }
    precondition(loadSem.wait(timeout: .now() + .seconds(5)) == .success)

    let defaultDelegate = MPPlayableDefaultDelegate()
    let overrideDelegate = MPPlayableOverrideDelegate()
    let anyDefault: any MPPlayableContentDelegate = defaultDelegate
    let anyOverride: any MPPlayableContentDelegate = overrideDelegate
    anyDefault.playableContentManager(manager, didUpdate: manager.context)
    anyOverride.playableContentManager(manager, didUpdate: manager.context)
    precondition(overrideDelegate.updated == 1)

    let sem = DispatchSemaphore(value: 0)
    var defaultErr = false
    var returned = false
    anyDefault.playableContentManager(manager, initializePlaybackQueueWithCompletionHandler: { error in
        precondition(returned)
        defaultErr = MPError.notSupported ~= (error ?? MPError(.unknown))
        sem.signal()
    })
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(defaultErr)

    anyOverride.playableContentManager(manager, initializePlaybackQueueWithCompletionHandler: { error in
        precondition(error == nil)
    })
    precondition(overrideDelegate.initQueue == 1)
    anyOverride.playableContentManager(
        manager,
        initializePlaybackQueueWithContentItems: nil,
        completionHandler: { _ in }
    )
    precondition(overrideDelegate.initItems == 1)

    let initSem = DispatchSemaphore(value: 0)
    Task {
        try! await anyOverride.playableContentManager(
            manager,
            initiatePlaybackOfContentItemAt: IndexPath(index: 0)
        )
        precondition(overrideDelegate.initiate == 1)
        do {
            try await anyDefault.playableContentManager(
                manager,
                initiatePlaybackOfContentItemAt: IndexPath(index: 0)
            )
            fatalError("default initiate should throw")
        } catch {
            precondition(MPError.notSupported ~= error)
        }
        initSem.signal()
    }
    precondition(initSem.wait(timeout: .now() + .seconds(5)) == .success)
}
