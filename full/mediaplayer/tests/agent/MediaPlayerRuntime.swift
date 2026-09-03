import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("MEDIAPLAYER_RUNTIME_FAIL: \(message)\n".utf8))
        exit(1)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    expect(actual == expected, "\(message): \(actual) != \(expected)")
}

// MARK: - Enums and option sets

expectEqual(MPError.Code.unknown.rawValue, 0, "MPError.unknown")
expectEqual(MPError.Code.requestTimedOut.rawValue, 7, "MPError.timeout")
expectEqual(MPMediaGrouping.podcastTitle.rawValue, 7, "grouping")
expectEqual(MPMediaLibraryAuthorizationStatus.denied.rawValue, 1, "auth")
expectEqual(MPRemoteCommandHandlerStatus.commandFailed.rawValue, 200, "handler")
expectEqual(MPNowPlayingPlaybackState.interrupted.rawValue, 4, "np state")
expectEqual(MPMovieControlStyle.default, .fullscreen, "movie default")
expect(MPMediaType.music.contains(.music), "music flag")
expect(MPMediaType.any.contains(.homeVideo), "any contains homeVideo")
expect(MPMediaPlaylistAttribute.genius.contains(.genius), "genius")
expect(MPMovieLoadState.playable.rawValue == 1, "load state")
expectEqual(MPMusicRepeatMode.all.rawValue, 3, "repeat")
expectEqual(MPShuffleType.collections.rawValue, 2, "shuffle")

// MARK: - Error

let err = MPError(.notSupported, userInfo: ["k": "v"])
expectEqual(MPError.errorDomain, MPErrorDomain, "domain")
expectEqual(err.errorCode, 5, "errorCode")
expectEqual(err.code, .notSupported, "code")
expect(err.errorUserInfo["k"] as? String == "v", "userInfo")
expect(MPError(.notSupported) == MPError(.notSupported), "eq")
expect(MPError(.notSupported) != MPError(.cancelled), "neq")
expect(MPError.Code.notSupported ~= err, "pattern")

// MARK: - Constants and notifications

expectEqual(MPMediaItemPropertyTitle, "title", "title key")
expectEqual(MPMediaItemPropertyArtist, "artist", "artist key")
expectEqual(MPNowPlayingInfoPropertyElapsedPlaybackTime, "MPNowPlayingInfoPropertyElapsedPlaybackTime", "elapsed")
expect(
    NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange.rawValue
        == "MPMusicPlayerControllerNowPlayingItemDidChangeNotification",
    "now playing note"
)
expect(
    NSNotification.Name.MPMediaLibraryDidChange.rawValue
        == "MPMediaLibraryDidChangeNotification",
    "library note"
)

// MARK: - Now playing

let center = MPNowPlayingInfoCenter.default()
expect(center === MPNowPlayingInfoCenter.default(), "center singleton")
expect(MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys.isEmpty, "no animated art")
center.nowPlayingInfo = [
    MPMediaItemPropertyTitle: "Track",
    MPNowPlayingInfoPropertyElapsedPlaybackTime: 12.5,
    MPNowPlayingInfoPropertyPlaybackRate: 1.0,
]
expect(center.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String == "Track", "np title")
expect(
    center.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double == 12.5,
    "elapsed stored"
)
center.playbackState = .playing
expectEqual(center.playbackState, .playing, "np playback")
center.nowPlayingInfo = nil
expect(center.nowPlayingInfo == nil, "np cleared")
center.playbackState = .stopped

let option = MPNowPlayingInfoLanguageOption(
    type: .audible,
    languageTag: "en",
    characteristics: [MPLanguageOptionCharacteristicIsMainProgramContent],
    displayName: "English",
    identifier: "en-audio"
)
expectEqual(option.languageTag, "en", "lang tag")
expect(!option.isAutomaticAudibleLanguageOption(), "not automatic")
let group = MPNowPlayingInfoLanguageOptionGroup(
    languageOptions: [option],
    defaultLanguageOption: option,
    allowEmptySelection: false
)
expectEqual(group.languageOptions.count, 1, "group count")

// MARK: - Remote commands

let commands = MPRemoteCommandCenter.shared()
expect(commands === MPRemoteCommandCenter.shared(), "command singleton")
expect(!commands.playCommand.isEnabled, "play starts disabled")
commands.playCommand.isEnabled = true
var playCount = 0
let token = commands.playCommand.addTarget { event in
    playCount += 1
    expect(event.command === commands.playCommand, "event command")
    return .success
}
let playEvent = MPRemoteCommandEvent(command: commands.playCommand, timestamp: 1)
expectEqual(commands.playCommand._openUIKit_deliver(playEvent), .success, "play deliver")
expectEqual(playCount, 1, "handler ran")
commands.playCommand.removeTarget(token)
expectEqual(commands.playCommand._openUIKit_deliver(playEvent), .commandFailed, "removed")
commands.playCommand.isEnabled = false
_ = commands.playCommand.addTarget { _ in .success }
expectEqual(commands.playCommand._openUIKit_deliver(playEvent), .commandFailed, "disabled")
commands.playCommand.removeTarget(nil)

commands.likeCommand.localizedTitle = "Like"
commands.likeCommand.isActive = true
expectEqual(commands.likeCommand.localizedTitle, "Like", "like title")
expect(commands.likeCommand.isActive, "like active")
expectEqual(commands.skipForwardCommand.preferredIntervals.first?.intValue, 15, "skip interval")
commands.changeRepeatModeCommand.currentRepeatType = .all
expectEqual(commands.changeRepeatModeCommand.currentRepeatType, .all, "repeat cmd")
commands.ratingCommand.maximumRating = 5
let rateEvent = MPRatingCommandEvent(command: commands.ratingCommand, timestamp: 0, rating: 4)
expectEqual(rateEvent.rating, 4, "rating event")
let posEvent = MPChangePlaybackPositionCommandEvent(
    command: commands.changePlaybackPositionCommand,
    timestamp: 0,
    positionTime: 30
)
expectEqual(posEvent.positionTime, 30, "position event")

// MARK: - Media library / query / items

expectEqual(MPMediaLibrary.authorizationStatus(), .denied, "library denied")
var auth: MPMediaLibraryAuthorizationStatus = .notDetermined
MPMediaLibrary.requestAuthorization { auth = $0 }
expectEqual(auth, .denied, "request denied")
expect(MPMediaLibrary.default() === MPMediaLibrary.default(), "library singleton")
expectEqual(MPMediaLibrary.default().lastModifiedDate, Date.distantPast, "library date")

let item = MPMediaItem()
item._openUIKit_setValue("Song", forProperty: MPMediaItemPropertyTitle)
item._openUIKit_setValue("Artist", forProperty: MPMediaItemPropertyArtist)
item._openUIKit_setValue(NSNumber(value: 240.0), forProperty: MPMediaItemPropertyPlaybackDuration)
item._openUIKit_setValue(NSNumber(value: MPMediaType.music.rawValue), forProperty: MPMediaItemPropertyMediaType)
expectEqual(item.title, "Song", "item title")
expectEqual(item.artist, "Artist", "item artist")
expectEqual(item.playbackDuration, 240, "duration")
expect(item.mediaType.contains(.music), "item type")
expectEqual(item[MPMediaItemPropertyTitle] as? String, "Song", "subscript")
expectEqual(
    MPMediaItem.titleProperty(forGroupingType: .album),
    MPMediaItemPropertyAlbumTitle,
    "title property"
)
expectEqual(
    MPMediaItem.persistentIDProperty(forGroupingType: .artist),
    MPMediaItemPropertyArtistPersistentID,
    "pid property"
)
expect(MPMediaEntity.canFilter(byProperty: MPMediaItemPropertyTitle), "can filter title")
expect(!MPMediaEntity.canFilter(byProperty: "not-a-property"), "cannot filter junk")

let collection = MPMediaItemCollection(items: [item])
expectEqual(collection.count, 1, "collection count")
expect(collection.representativeItem === item, "representative")
expect(collection.mediaTypes.contains(.music), "collection types")

let query = MPMediaQuery.songs()
expectEqual(query.groupingType, .title, "songs grouping")
expect(query.items == nil, "empty library items")
expect(query.collections == nil, "empty library collections")
let albums = MPMediaQuery.albums()
expectEqual(albums.groupingType, .album, "albums grouping")
let predicate = MPMediaPropertyPredicate(
    value: "Artist",
    forProperty: MPMediaItemPropertyArtist,
    comparisonType: .contains
)
query.addFilterPredicate(predicate)
expect(query.filterPredicates?.contains(predicate) == true, "predicate added")
query.removeFilterPredicate(predicate)

let meta = MPMediaPlaylistCreationMetadata(name: "Workout")
meta.authorDisplayName = "User"
meta.descriptionText = "Runs"
expectEqual(meta.name, "Workout", "playlist meta")

let playlist = MPMediaPlaylist(items: [item])
expectEqual(playlist.count, 1, "playlist count")

var addFailed = false
let semaphore = DispatchSemaphore(value: 0)
Task {
    do {
        _ = try await MPMediaLibrary.default().addItem(withProductID: "id")
    } catch let error as MPError {
        addFailed = error.code == .notSupported
    } catch {
        addFailed = false
    }
    semaphore.signal()
}
_ = semaphore.wait(timeout: .now() + 5)
expect(addFailed, "addItem fail-closed")

// MARK: - Music player

let appPlayer = MPMusicPlayerController.applicationMusicPlayer
let systemPlayer = MPMusicPlayerController.systemMusicPlayer
expect(appPlayer !== (systemPlayer as MPMusicPlayerController), "distinct players")
expect(MPMusicPlayerController.iPodMusicPlayer === (systemPlayer as MPMusicPlayerController), "iPod alias")
expectEqual(appPlayer.playbackState, .stopped, "stopped")
expect(!appPlayer.isPreparedToPlay, "not prepared")
appPlayer.play()
expectEqual(appPlayer.playbackState, .stopped, "play inert")
appPlayer.setQueue(with: collection)
expect(appPlayer.nowPlayingItem === item, "queue now playing")
appPlayer.currentPlaybackTime = 9
appPlayer.skipToBeginning()
expectEqual(appPlayer.currentPlaybackTime, 0, "skip beginning")
var prepareError: Error?
appPlayer.prepareToPlay { prepareError = $0 }
expect((prepareError as? MPError)?.code == .notSupported, "prepare fail-closed")

let storeQueue = MPMusicPlayerStoreQueueDescriptor(storeIDs: ["s1", "s2"])
storeQueue.startItemID = "s1"
appPlayer.setQueue(with: storeQueue)
expect(appPlayer.nowPlayingItem == nil, "store queue has no items")
systemPlayer.openToPlay(storeQueue)

let params = MPMusicPlayerPlayParameters(dictionary: ["kind": "song"])
expect(params?.dictionary["kind"] as? String == "song", "play params")
let paramQueue = MPMusicPlayerPlayParametersQueueDescriptor(
    playParametersQueue: [params!]
)
appPlayer.append(paramQueue)

let queuePlayer = MPMusicPlayerController.applicationQueuePlayer
var txFailed = false
let txSema = DispatchSemaphore(value: 0)
Task {
    do {
        _ = try await queuePlayer.perform { _ in }
    } catch let error as MPError {
        txFailed = error.code == .notSupported
    } catch {
        txFailed = false
    }
    txSema.signal()
}
_ = txSema.wait(timeout: .now() + 5)
expect(txFailed, "queue transaction fail-closed")

// MARK: - Content / playable content

let content = MPContentItem(identifier: "ep1")
content.title = "Episode"
content.isPlayable = true
content.playbackProgress = 0.25
expectEqual(content.identifier, "ep1", "content id")
expectEqual(content.playbackProgress, 0.25, "progress")
expect(!MPPlayableContentManager.shared().context.endpointAvailable, "no carplay")
MPPlayableContentManager.shared().nowPlayingIdentifiers = ["ep1"]
expectEqual(MPPlayableContentManager.shared().nowPlayingIdentifiers, ["ep1"], "ids")

expect(!MPVolumeSettingsAlertIsVisible(), "no volume alert")
MPVolumeSettingsAlertShow()
expect(!MPVolumeSettingsAlertIsVisible(), "show still hidden")
MPVolumeSettingsAlertHide()

// MARK: - Existential witness dispatch (optional ObjC callbacks)

final class OverridingPlayableDataSource: NSObject, MPPlayableContentDataSource {
    let child = MPContentItem(identifier: "child")
    var beganLoading = false
    var progressAsked = false
    var identifierAsked: String?

    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 1
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return child
    }

    func beginLoadingChildItems(at indexPath: IndexPath) async throws {
        _ = indexPath
        beganLoading = true
    }

    func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        _ = indexPath
        progressAsked = true
        return true
    }

    func contentItem(forIdentifier identifier: String) async throws -> MPContentItem {
        identifierAsked = identifier
        return child
    }
}

final class DefaultPlayableDataSource: NSObject, MPPlayableContentDataSource {
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 0
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return nil
    }
}

final class OverridingPlayableDelegate: NSObject, MPPlayableContentDelegate {
    var didUpdate = false
    var queueWithoutItems = false
    var queueWithItems: [Any]?
    var initiated: IndexPath?

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        didUpdate context: MPPlayableContentManagerContext
    ) {
        _ = (contentManager, context)
        didUpdate = true
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithCompletionHandler completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        queueWithoutItems = true
        completionHandler(nil)
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithContentItems contentItems: [Any]?,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        queueWithItems = contentItems
        completionHandler(nil)
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initiatePlaybackOfContentItemAt indexPath: IndexPath
    ) async throws {
        initiated = indexPath
    }
}

final class DefaultPlayableDelegate: NSObject, MPPlayableContentDelegate {}

func runAsync(_ name: String, _ body: @escaping () async throws -> Void) {
    let sema = DispatchSemaphore(value: 0)
    var caught: Error?
    Task {
        do {
            try await body()
        } catch {
            caught = error
        }
        sema.signal()
    }
    expect(sema.wait(timeout: .now() + 5) == .success, "\(name) timeout")
    if let caught {
        FileHandle.standardError.write(
            Data("MEDIAPLAYER_RUNTIME_FAIL: \(name): \(caught)\n".utf8)
        )
        exit(1)
    }
}

let overridingSource = OverridingPlayableDataSource()
let defaultSource = DefaultPlayableDataSource()
let overridingDelegate = OverridingPlayableDelegate()
let defaultDelegate = DefaultPlayableDelegate()
let manager = MPPlayableContentManager.shared()
manager.dataSource = overridingSource
manager.delegate = overridingDelegate

let sourceWitness: any MPPlayableContentDataSource = manager.dataSource!
let delegateWitness: any MPPlayableContentDelegate = manager.delegate!
let defaultSourceWitness: any MPPlayableContentDataSource = defaultSource
let defaultDelegateWitness: any MPPlayableContentDelegate = defaultDelegate
let childPath = IndexPath(indexes: [0, 1])

expectEqual(sourceWitness.numberOfChildItems(at: childPath), 1, "override child count")
expect(sourceWitness.contentItem(at: childPath) === overridingSource.child, "override contentItem(at:)")
expect(sourceWitness.childItemsDisplayPlaybackProgress(at: childPath), "override progress")
expect(overridingSource.progressAsked, "progress override ran")
expect(!defaultSourceWitness.childItemsDisplayPlaybackProgress(at: childPath), "default progress")
expect(defaultSourceWitness.contentItem(at: childPath) == nil, "default contentItem(at:)")
expectEqual(defaultSourceWitness.numberOfChildItems(at: childPath), 0, "default child count")

runAsync("datasource overrides") {
    try await sourceWitness.beginLoadingChildItems(at: childPath)
    expect(overridingSource.beganLoading, "beginLoading override ran")
    let fetched = try await sourceWitness.contentItem(forIdentifier: "child")
    expect(fetched === overridingSource.child, "override contentItem(forIdentifier:)")
    expectEqual(overridingSource.identifierAsked, "child", "identifier override ran")
}

runAsync("datasource default fail-closed") {
    try await defaultSourceWitness.beginLoadingChildItems(at: childPath)
    do {
        _ = try await defaultSourceWitness.contentItem(forIdentifier: "missing")
        expect(false, "default contentItem(forIdentifier:) must fail closed")
    } catch let error as MPError {
        expectEqual(error.code, .notSupported, "default identifier notSupported")
    }
}

delegateWitness.playableContentManager(manager, didUpdate: manager.context)
expect(overridingDelegate.didUpdate, "didUpdate override ran")
defaultDelegateWitness.playableContentManager(manager, didUpdate: manager.context)

var overrideQueueError: (any Error)? = MPError(.unknown)
delegateWitness.playableContentManager(
    manager,
    initializePlaybackQueueWithCompletionHandler: { overrideQueueError = $0 }
)
expect(overridingDelegate.queueWithoutItems, "queue completion override ran")
expect(overrideQueueError == nil, "override queue completion")

var defaultQueueError: (any Error)?
defaultDelegateWitness.playableContentManager(
    manager,
    initializePlaybackQueueWithCompletionHandler: { defaultQueueError = $0 }
)
expect((defaultQueueError as? MPError)?.code == .notSupported, "default queue fail-closed")

let seedItems: [Any] = [overridingSource.child]
var overrideItemsError: (any Error)? = MPError(.unknown)
delegateWitness.playableContentManager(
    manager,
    initializePlaybackQueueWithContentItems: seedItems,
    completionHandler: { overrideItemsError = $0 }
)
expectEqual(overridingDelegate.queueWithItems?.count, 1, "queue items override ran")
expect(overrideItemsError == nil, "override items completion")

var defaultItemsError: (any Error)?
defaultDelegateWitness.playableContentManager(
    manager,
    initializePlaybackQueueWithContentItems: seedItems,
    completionHandler: { defaultItemsError = $0 }
)
expect((defaultItemsError as? MPError)?.code == .notSupported, "default items fail-closed")

runAsync("delegate initiate override") {
    try await delegateWitness.playableContentManager(
        manager,
        initiatePlaybackOfContentItemAt: childPath
    )
    expectEqual(overridingDelegate.initiated, childPath, "initiate override ran")
}

runAsync("delegate initiate default fail-closed") {
    do {
        try await defaultDelegateWitness.playableContentManager(
            manager,
            initiatePlaybackOfContentItemAt: childPath
        )
        expect(false, "default initiatePlayback must fail closed")
    } catch let error as MPError {
        expectEqual(error.code, .notSupported, "default initiate notSupported")
    }
}

print("MEDIAPLAYER_AGENT_RUNTIME_OK")
