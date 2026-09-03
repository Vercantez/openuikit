import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

private func expect(_ condition: Bool, _ message: String) {
    if !condition { fatalError(message) }
}

private func wait(_ semaphore: DispatchSemaphore, _ message: String) {
    expect(semaphore.wait(timeout: .now() + .seconds(5)) == .success, message)
}

private final class DefaultDataSource: NSObject, MPPlayableContentDataSource {
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 0
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return nil
    }
}

private final class OverrideDataSource: NSObject, MPPlayableContentDataSource {
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

private final class DefaultDelegate: NSObject, MPPlayableContentDelegate {}

private final class OverrideDelegate: NSObject, MPPlayableContentDelegate {
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

private func exerciseEnums() {
    expect(MPMusicPlaybackState.stopped != .playing, "playback states")
    expect(MPMusicRepeatMode.none != .all, "repeat")
    expect(MPMusicShuffleMode.off != .songs, "shuffle")
    expect(MPMediaGrouping.title != .album, "grouping")
    expect(MPMediaLibraryAuthorizationStatus.denied != .authorized, "auth")
    expect(MPMediaPredicateComparison.equalTo != .contains, "predicate")
    expect(MPMoviePlaybackState.stopped != .playing, "movie playback")
    expect(MPMovieControlStyle.none != .fullscreen, "control")
    expect(MPMovieFinishReason.playbackEnded != .userExited, "finish")
    expect(MPMovieRepeatMode.none != .one, "movie repeat")
    expect(MPMovieScalingMode.none != .fill, "scaling")
    expect(MPMovieSourceType.unknown != .file, "source")
    expect(MPMovieTimeOption.exact != .nearestKeyFrame, "time option")
    expect(MPNowPlayingPlaybackState.stopped != .playing, "now playing")
    expect(MPNowPlayingInfoMediaType.audio != .video, "media type")
    expect(MPNowPlayingInfoLanguageOptionType.audible != .legible, "lang")
    expect(MPRemoteCommandHandlerStatus.success != .commandFailed, "handler")
    expect(MPRepeatType.off != .all, "repeat type")
    expect(MPShuffleType.off != .items, "shuffle type")
    expect(MPSeekCommandEventType.beginSeeking != .endSeeking, "seek")
    expect(MPChangeLanguageOptionSetting.none != .permanent, "lang setting")
    expect(Set([MPError.Code.unknown, .notFound, .notSupported, .cancelled]).count == 4, "error cases")
}

private func exerciseOptionSets() {
    expect(MPMediaType.music.contains(.music), "music bit")
    expect(MPMediaType.anyAudio.contains(.podcast), "anyAudio")
    expect(!MPMediaType.music.contains(.movie), "music vs movie")
    expect(MPMediaType.music.union(.podcast).contains(.podcast), "union")
    expect(MPMediaPlaylistAttribute.smart.contains(.smart), "smart")
    expect(MPMovieLoadState.playable.contains(.playable), "load")
    expect(MPMovieMediaTypeMask.audio.contains(.audio), "mask")
    expect(MPMediaType().isEmpty, "empty")
}

private func exerciseErrors() {
    let error = MPError(.notSupported, userInfo: ["k": "v"])
    expect(error.code == .notSupported, "code")
    expect(error.errorCode == MPError.Code.notSupported.rawValue, "errorCode")
    expect(error == MPError(.notSupported), "equality ignores userInfo")
    expect(MPError.notSupported ~= error, "pattern match")
    expect(MPError.errorDomain == "MPErrorDomain", "linux-local domain")
    expect(!(MPError.cancelled ~= error), "mismatch")
}

private func exerciseLibraryAndQuery() {
    expect(MPMediaLibrary.authorizationStatus() == .denied, "denied")
    let sem = DispatchSemaphore(value: 0)
    var seen: MPMediaLibraryAuthorizationStatus?
    var returned = false
    MPMediaLibrary.requestAuthorization { status in
        expect(returned, "authorization hop")
        seen = status
        sem.signal()
    }
    returned = true
    wait(sem, "authorization")
    expect(seen == .denied, "callback denied")

    let songs = MPMediaQuery.songs()
    expect(songs.groupingType == .title, "songs grouping")
    expect(songs.items?.isEmpty == true, "empty items")
    let predicate = MPMediaPropertyPredicate(
        value: "Radiohead",
        forProperty: MPMediaItemPropertyArtist
    )
    expect(predicate.comparisonType == .equalTo, "equalTo default")
    songs.addFilterPredicate(predicate)
    expect(songs.filterPredicates?.contains(predicate) == true, "predicate stored")

    let item = MPMediaItem()
    expect(item.title == nil, "empty title")
    expect(item.mediaType.isEmpty, "empty type")
    expect(item.value(forProperty: MPMediaItemPropertyPersistentID) as? UInt64 == 0, "pid")
    expect(
        MPMediaItem.titleProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumTitle,
        "title property map"
    )

    let collection = MPMediaItemCollection(items: [item])
    expect(collection.count == 1, "collection count")
    expect(collection.representativeItem === item, "representative")
}

private func exercisePlayer() {
    let player = MPMusicPlayerController.applicationMusicPlayer
    expect(player.playbackState == .stopped, "initial stopped")
    player.play()
    expect(player.playbackState == .stopped, "play stays stopped")
    player.prepareToPlay()
    expect(!player.isPreparedToPlay, "not prepared")

    var returned = false
    let sem = DispatchSemaphore(value: 0)
    var sawError = false
    player.prepareToPlay { error in
        expect(returned, "prepare hop")
        expect(MPError.notSupported ~= (error ?? MPError(.unknown)), "prepare error")
        sawError = true
        sem.signal()
    }
    returned = true
    wait(sem, "prepare")
    expect(sawError, "saw error")

    let system = MPMusicPlayerController.systemMusicPlayer
    system.openToPlay(MPMusicPlayerStoreQueueDescriptor(storeIDs: ["1"]))
    expect(system.playbackState == .stopped, "openToPlay fail-closed")

    expect(!MPVolumeSettingsAlertIsVisible(), "volume alert")
    MPVolumeSettingsAlertShow()
    expect(!MPVolumeSettingsAlertIsVisible(), "still hidden")
    MPVolumeSettingsAlertHide()

    let center = MPNowPlayingInfoCenter.default()
    center.nowPlayingInfo = [MPNowPlayingInfoPropertyPlaybackRate: 1]
    expect(center.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Int == 1, "info")
    center.playbackState = .paused
    expect(center.playbackState == .paused, "center state")
    expect(MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys.isEmpty, "no artwork keys")

    let movie = MPMoviePlayerController(contentURL: URL(string: "file://tmp.m4v")!)
    movie?.play()
    expect(movie?.playbackState == .stopped, "movie stopped")
}

private func exerciseRemoteCommands() {
    let commands = MPRemoteCommandCenter.shared()
    commands.playCommand.isEnabled = true
    var invoked = false
    _ = commands.playCommand.addTarget { event in
        invoked = true
        _ = event
        return .success
    }
    let status = commands.playCommand.openuikit_invoke(
        MPRemoteCommandEvent(command: commands.playCommand)
    )
    expect(invoked, "handler ran")
    expect(status == .success, "success")
}

private func exercisePlayableContent() async {
    let manager = MPPlayableContentManager.shared()
    expect(!manager.context.endpointAvailable, "no endpoint")
    expect(manager.context.enforcedContentItemsCount == 0, "no limits")

    let defaults = DefaultDataSource()
    let override = OverrideDataSource()
    let asDefault: any MPPlayableContentDataSource = defaults
    let asOverride: any MPPlayableContentDataSource = override

    expect(asDefault.numberOfChildItems(at: IndexPath()) == 0, "default count")
    expect(asDefault.contentItem(at: IndexPath()) == nil, "default item")
    expect(!asDefault.childItemsDisplayPlaybackProgress(at: IndexPath(index: 0)), "default progress")
    do {
        try await asDefault.beginLoadingChildItems(at: IndexPath())
    } catch {
        fatalError("default begin should succeed empty")
    }
    do {
        _ = try await asDefault.contentItem(forIdentifier: "x")
        fatalError("default identifier should throw")
    } catch {
        expect(MPError.notFound ~= error, "default notFound")
    }

    expect(asOverride.numberOfChildItems(at: IndexPath()) == 1, "override count")
    expect(asOverride.contentItem(at: IndexPath(index: 0))?.isPlayable == true, "override item")
    expect(asOverride.childItemsDisplayPlaybackProgress(at: IndexPath(index: 1)), "override progress")
    try! await asOverride.beginLoadingChildItems(at: IndexPath(index: 2))
    expect(override.began.count == 1, "begin recorded")
    let fetched = try! await asOverride.contentItem(forIdentifier: "abc")
    expect(fetched.identifier == "abc", "fetched id")
    expect(override.identifiers == ["abc"], "identifier recorded")

    let defaultDelegate = DefaultDelegate()
    let overrideDelegate = OverrideDelegate()
    let anyDefault: any MPPlayableContentDelegate = defaultDelegate
    let anyOverride: any MPPlayableContentDelegate = overrideDelegate

    anyDefault.playableContentManager(manager, didUpdate: manager.context)
    anyOverride.playableContentManager(manager, didUpdate: manager.context)
    expect(overrideDelegate.updated == 1, "update override")

    let sem = DispatchSemaphore(value: 0)
    var defaultErr = false
    var returned = false
    anyDefault.playableContentManager(manager, initializePlaybackQueueWithCompletionHandler: { error in
        expect(returned, "default init hop")
        defaultErr = MPError.notSupported ~= (error ?? MPError(.unknown))
        sem.signal()
    })
    returned = true
    wait(sem, "default init queue")
    expect(defaultErr, "default fail-closed")

    anyOverride.playableContentManager(manager, initializePlaybackQueueWithCompletionHandler: { error in
        expect(error == nil, "override success")
    })
    expect(overrideDelegate.initQueue == 1, "init queue override")

    anyOverride.playableContentManager(
        manager,
        initializePlaybackQueueWithContentItems: nil,
        completionHandler: { _ in }
    )
    expect(overrideDelegate.initItems == 1, "init items override")

    try! await anyOverride.playableContentManager(
        manager,
        initiatePlaybackOfContentItemAt: IndexPath(index: 0)
    )
    expect(overrideDelegate.initiate == 1, "initiate override")

    do {
        try await anyDefault.playableContentManager(
            manager,
            initiatePlaybackOfContentItemAt: IndexPath(index: 0)
        )
        fatalError("default initiate should throw")
    } catch {
        expect(MPError.notSupported ~= error, "default initiate fail-closed")
    }

    let content = MPContentItem(identifier: "root")
    content.title = "Root"
    content.isContainer = true
    expect(content.identifier == "root", "id")
    expect(content.isContainer, "container")
}

private func run() async {
    exerciseEnums()
    exerciseOptionSets()
    exerciseErrors()
    exerciseLibraryAndQuery()
    exercisePlayer()
    exerciseRemoteCommands()
    await exercisePlayableContent()
    print("MEDIAPLAYER_AGENT_RUNTIME_OK")
}

let group = DispatchGroup()
group.enter()
Task {
    await run()
    group.leave()
}
group.wait()
