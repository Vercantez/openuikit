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

private final class CommandTarget: NSObject {
    var count = 0
    @objc func handle(_ event: MPRemoteCommandEvent) {
        count += 1
        _ = event
    }
}

private final class PickerSink: NSObject, MPMediaPickerControllerDelegate {
    var cancelled = 0
    var picked = 0
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        _ = mediaPicker
        cancelled += 1
    }
    func mediaPicker(
        _ mediaPicker: MPMediaPickerController,
        didPickMediaItems mediaItemCollection: MPMediaItemCollection
    ) {
        _ = mediaPicker
        _ = mediaItemCollection
        picked += 1
    }
}

private func exerciseEnums() {
    expect(MPMusicPlaybackState.stopped.rawValue == 0, "stopped")
    expect(MPMusicPlaybackState.playing.rawValue == 1, "playing")
    expect(MPMusicPlaybackState.paused.rawValue == 2, "paused")
    expect(MPMusicPlaybackState.interrupted.rawValue == 3, "interrupted")
    expect(MPMusicPlaybackState.seekingForward.rawValue == 4, "seekF")
    expect(MPMusicPlaybackState.seekingBackward.rawValue == 5, "seekB")
    expect(MPMusicRepeatMode.default.rawValue == 0, "rep def")
    expect(MPMusicRepeatMode.none.rawValue == 1, "rep none")
    expect(MPMusicRepeatMode.one.rawValue == 2, "rep one")
    expect(MPMusicRepeatMode.all.rawValue == 3, "rep all")
    expect(MPMusicShuffleMode.default.rawValue == 0, "sh def")
    expect(MPMusicShuffleMode.off.rawValue == 1, "sh off")
    expect(MPMusicShuffleMode.songs.rawValue == 2, "sh songs")
    expect(MPMusicShuffleMode.albums.rawValue == 3, "sh albums")
    expect(MPNowPlayingPlaybackState.unknown.rawValue == 0, "np unk")
    expect(MPNowPlayingPlaybackState.playing.rawValue == 1, "np play")
    expect(MPNowPlayingPlaybackState.paused.rawValue == 2, "np pause")
    expect(MPNowPlayingPlaybackState.stopped.rawValue == 3, "np stop")
    expect(MPNowPlayingPlaybackState.interrupted.rawValue == 4, "np int")
    expect(MPRemoteCommandHandlerStatus.success.rawValue == 0, "h0")
    expect(MPRemoteCommandHandlerStatus.noSuchContent.rawValue == 100, "h100")
    expect(MPRemoteCommandHandlerStatus.noActionableNowPlayingItem.rawValue == 110, "h110")
    expect(MPRemoteCommandHandlerStatus.deviceNotFound.rawValue == 120, "h120")
    expect(MPRemoteCommandHandlerStatus.commandFailed.rawValue == 200, "h200")
    expect(MPMediaGrouping.title.rawValue == 0, "g0")
    expect(MPMediaGrouping.album.rawValue == 1, "g1")
    expect(MPMediaGrouping.artist.rawValue == 2, "g2")
    expect(MPMediaGrouping.albumArtist.rawValue == 3, "g3")
    expect(MPMediaGrouping.composer.rawValue == 4, "g4")
    expect(MPMediaGrouping.genre.rawValue == 5, "g5")
    expect(MPMediaGrouping.playlist.rawValue == 6, "g6")
    expect(MPMediaGrouping.podcastTitle.rawValue == 7, "g7")
    expect(MPMediaLibraryAuthorizationStatus.notDetermined.rawValue == 0, "a0")
    expect(MPMediaLibraryAuthorizationStatus.denied.rawValue == 1, "a1")
    expect(MPMediaLibraryAuthorizationStatus.restricted.rawValue == 2, "a2")
    expect(MPMediaLibraryAuthorizationStatus.authorized.rawValue == 3, "a3")
    expect(MPError.Code.unknown.rawValue == 0, "e0")
    expect(MPError.Code.permissionDenied.rawValue == 1, "e1")
    expect(MPError.Code.cloudServiceCapabilityMissing.rawValue == 2, "e2")
    expect(MPError.Code.networkConnectionFailed.rawValue == 3, "e3")
    expect(MPError.Code.notFound.rawValue == 4, "e4")
    expect(MPError.Code.notSupported.rawValue == 5, "e5")
    expect(MPError.Code.cancelled.rawValue == 6, "e6")
    expect(MPError.Code.requestTimedOut.rawValue == 7, "e7")
    expect(MPRepeatType.off.rawValue == 0, "rt0")
    expect(MPRepeatType.one.rawValue == 1, "rt1")
    expect(MPRepeatType.all.rawValue == 2, "rt2")
    expect(MPShuffleType.off.rawValue == 0, "st0")
    expect(MPShuffleType.items.rawValue == 1, "st1")
    expect(MPShuffleType.collections.rawValue == 2, "st2")
    expect(MPSeekCommandEventType.beginSeeking.rawValue == 0, "sk0")
    expect(MPSeekCommandEventType.endSeeking.rawValue == 1, "sk1")
    expect(MPNowPlayingInfoMediaType.none.rawValue == 0, "mt0")
    expect(MPNowPlayingInfoMediaType.audio.rawValue == 1, "mt1")
    expect(MPNowPlayingInfoMediaType.video.rawValue == 2, "mt2")
    expect(MPNowPlayingInfoLanguageOptionType.audible.rawValue == 0, "lo0")
    expect(MPNowPlayingInfoLanguageOptionType.legible.rawValue == 1, "lo1")
    expect(MPChangeLanguageOptionSetting.none.rawValue == 0, "cl0")
    expect(MPChangeLanguageOptionSetting.nowPlayingItemOnly.rawValue == 1, "cl1")
    expect(MPChangeLanguageOptionSetting.permanent.rawValue == 2, "cl2")
    expect(MPMoviePlaybackState.stopped.rawValue == 0, "mv0")
    expect(MPMoviePlaybackState.playing.rawValue == 1, "mv1")
    expect(MPMovieControlStyle.none.rawValue == 0, "cs0")
    expect(MPMovieControlStyle.embedded.rawValue == 1, "cs1")
    expect(MPMovieControlStyle.fullscreen.rawValue == 2, "cs2")
    expect(MPMovieFinishReason.playbackEnded.rawValue == 0, "fr0")
    expect(MPMovieScalingMode.none.rawValue == 0, "sc0")
    expect(MPMovieScalingMode.aspectFit.rawValue == 1, "sc1")
    expect(MPMovieScalingMode.aspectFill.rawValue == 2, "sc2")
    expect(MPMovieScalingMode.fill.rawValue == 3, "sc3")
    expect(MPMovieSourceType.unknown.rawValue == 0, "src0")
    expect(MPMovieTimeOption.nearestKeyFrame.rawValue == 0, "to0")
    expect(MPMovieTimeOption.exact.rawValue == 1, "to1")
    expect(MPMovieRepeatMode.none.rawValue == 0, "mr0")
    expect(Set([MPMusicPlaybackState.stopped, .playing]).count == 2, "set")
    _ = MPMusicPlaybackState.stopped.hashValue
}

private func exerciseOptionSets() {
    expect(MPMediaType.music.rawValue == 1, "music")
    expect(MPMediaType.podcast.rawValue == 2, "podcast")
    expect(MPMediaType.audioBook.rawValue == 4, "abook")
    expect(MPMediaType.audioITunesU.rawValue == 8, "itunesu")
    expect(MPMediaType.anyAudio.rawValue == 255, "anyAudio")
    expect(MPMediaType.movie.rawValue == 256, "movie")
    expect(MPMediaType.tvShow.rawValue == 512, "tv")
    expect(MPMediaType.videoPodcast.rawValue == 1024, "vpod")
    expect(MPMediaType.musicVideo.rawValue == 2048, "mvid")
    expect(MPMediaType.videoITunesU.rawValue == 4096, "vitu")
    expect(MPMediaType.homeVideo.rawValue == 8192, "home")
    expect(MPMediaType.anyVideo.rawValue == 65280, "anyVideo")
    expect(MPMediaType.any.rawValue == ~UInt(0), "any")
    expect(MPMediaType.music.contains(.music), "contains")
    expect(MPMediaType.anyAudio.contains(.podcast), "anyAudio contains")
    expect(!MPMediaType.music.contains(.movie), "music vs movie")
    expect(MPMediaType.music.union(.podcast).contains(.podcast), "union")
    expect(MPMediaType.music.intersection(.anyAudio) == .music, "inter")
    expect(MPMediaType.music.isDisjoint(with: .movie), "disjoint")
    expect(MPMediaType.anyAudio.isSuperset(of: .music), "superset")
    expect(MPMediaType.music.isSubset(of: .anyAudio), "subset")
    expect(!MPMediaType.music.isEmpty, "not empty")
    expect(MPMediaType().isEmpty, "empty")
    var types = MPMediaType.music
    types.insert(.podcast)
    expect(types.contains(.podcast), "insert")
    _ = types.remove(.podcast)
    types.formUnion(.audioBook)
    types.formIntersection(.anyAudio)
    types.formSymmetricDifference(.music)
    types.subtract(.audioBook)
    expect(MPMediaPlaylistAttribute.onTheGo.rawValue == 1, "otg")
    expect(MPMediaPlaylistAttribute.smart.rawValue == 2, "smart")
    expect(MPMediaPlaylistAttribute.genius.rawValue == 4, "genius")
    expect(MPMovieLoadState.playable.rawValue == 1, "load")
    expect(MPMovieLoadState.playthroughOK.rawValue == 2, "pthru")
    expect(MPMovieLoadState.stalled.rawValue == 4, "stall")
    expect(MPMovieMediaTypeMask.video.rawValue == 1, "mask video")
    expect(MPMovieMediaTypeMask.audio.rawValue == 2, "mask audio")
    let fromSeq = MPMediaType([.music, .podcast])
    expect(fromSeq.contains(.music) && fromSeq.contains(.podcast), "seq")
    let lit: MPMediaType = [.music, .podcast]
    expect(lit.contains(.podcast), "literal")
}

private func exerciseErrors() {
    let error = MPError(.notSupported, userInfo: ["k": "v"])
    expect(error.code == .notSupported, "code")
    expect(error.errorCode == 5, "errorCode")
    expect(error == MPError(.notSupported), "equality ignores userInfo")
    expect(MPError.notSupported ~= error, "pattern match")
    expect(MPError.errorDomain == "MPErrorDomain", "domain")
    expect(MPErrorDomain == "MPErrorDomain", "let domain")
    expect(!(MPError.cancelled ~= error), "mismatch")
    let ns = error as NSError
    expect(ns.domain == "MPErrorDomain", "ns domain")
    expect(ns.code == 5, "ns code")
    _ = error.localizedDescription
    expect(MPError(.unknown).errorCode == 0, "unk")
    expect(MPError(.permissionDenied).errorCode == 1, "perm")
    expect(MPError(.cloudServiceCapabilityMissing).errorCode == 2, "cloud")
    expect(MPError(.networkConnectionFailed).errorCode == 3, "net")
    expect(MPError(.notFound).errorCode == 4, "nf")
    expect(MPError(.cancelled).errorCode == 6, "can")
    expect(MPError(.requestTimedOut).errorCode == 7, "to")
}

private func exerciseConstants() {
    expect(MPMediaItemPropertyTitle == "title", "title")
    expect(MPMediaItemPropertyAlbumTitle == "albumTitle", "albumTitle")
    expect(MPMediaItemPropertyArtist == "artist", "artist")
    expect(MPMediaItemPropertyAlbumArtist == "albumArtist", "albumArtist")
    expect(MPMediaItemPropertyAlbumPersistentID == "albumPID", "albumPID")
    expect(MPMediaItemPropertyAlbumArtistPersistentID == "albumArtistPID", "albumArtistPID")
    expect(MPMediaItemPropertyArtistPersistentID == "artistPID", "artistPID")
    expect(MPMediaItemPropertyArtwork == "artwork", "artwork")
    expect(MPMediaItemPropertyAssetURL == "assetURL", "assetURL")
    expect(MPMediaItemPropertyPersistentID == "persistentID", "pid")
    expect(MPMediaEntityPropertyPersistentID == "persistentID", "epid")
    expect(MPMediaItemPropertyMediaType == "mediaType", "mediaType")
    expect(MPMediaItemPropertyPlaybackDuration == "playbackDuration", "dur")
    expect(MPMediaItemPropertyPlayCount == "playCount", "pc")
    expect(MPMediaItemPropertyGenre == "genre", "genre")
    expect(MPMediaItemPropertyComposer == "composer", "composer")
    expect(MPMediaItemPropertyLyrics == "lyrics", "lyrics")
    expect(MPMediaItemPropertyIsExplicit == "isExplicit", "explicit")
    expect(MPMediaItemPropertyIsCloudItem == "isCloudItem", "cloud")
    expect(MPMediaItemPropertyIsCompilation == "isCompilation", "comp")
    expect(MPMediaItemPropertyIsPreorder == "isPreorder", "pre")
    expect(MPMediaItemPropertyHasProtectedAsset == "hasProtectedAsset", "prot")
    expect(MPMediaItemPropertyPodcastTitle == "podcastTitle", "pod")
    expect(MPMediaItemPropertyPodcastPersistentID == "podcastPID", "podpid")
    expect(MPMediaItemPropertyComposerPersistentID == "composerPID", "compid")
    expect(MPMediaItemPropertyGenrePersistentID == "genrePID", "gpid")
    expect(MPMediaItemPropertyPlaybackStoreID == "playbackStoreID", "store")
    expect(MPMediaItemPropertyUserGrouping == "userGrouping", "ug")
    expect(MPMediaItemPropertyDateAdded == "dateAdded", "added")
    expect(MPMediaItemPropertyLastPlayedDate == "lastPlayedDate", "last")
    expect(MPMediaItemPropertyReleaseDate == "releaseDate", "rel")
    expect(MPMediaItemPropertyAlbumTrackCount == "albumTrackCount", "atc")
    expect(MPMediaItemPropertyAlbumTrackNumber == "albumTrackNumber", "atn")
    expect(MPMediaItemPropertyDiscCount == "discCount", "dc")
    expect(MPMediaItemPropertyDiscNumber == "discNumber", "dn")
    expect(MPMediaItemPropertyBeatsPerMinute == "beatsPerMinute", "bpm")
    expect(MPMediaItemPropertyBookmarkTime == "bookmarkTime", "bm")
    expect(MPMediaItemPropertyComments == "comments", "cmt")
    expect(MPMediaItemPropertyRating == "rating", "rat")
    expect(MPMediaItemPropertySkipCount == "skipCount", "skip")
    expect(MPMediaPlaylistPropertyName == "name", "pl name")
    expect(MPMediaPlaylistPropertyPersistentID == "playlistPersistentID", "pl pid")
    expect(MPMediaPlaylistPropertyAuthorDisplayName == "externalVendorDisplayName", "pl author")
    expect(MPMediaPlaylistPropertyDescriptionText == "descriptionInfo", "pl desc")
    expect(MPMediaPlaylistPropertyCloudGlobalID == "cloudGlobalID", "pl cloud")
    expect(MPMediaPlaylistPropertyPlaylistAttributes == "playlistAttributes", "pl attr")
    expect(MPMediaPlaylistPropertySeedItems == "seedItems", "pl seed")
    expect(MPNowPlayingInfoPropertyElapsedPlaybackTime == "MPNowPlayingInfoPropertyElapsedPlaybackTime", "elapsed")
    expect(MPNowPlayingInfoPropertyPlaybackRate == "MPNowPlayingInfoPropertyPlaybackRate", "rate")
    expect(MPNowPlayingInfoPropertyDefaultPlaybackRate == "MPNowPlayingInfoPropertyDefaultPlaybackRate", "def rate")
    expect(MPNowPlayingInfoPropertyPlaybackQueueIndex == "MPNowPlayingInfoPropertyPlaybackQueueIndex", "qidx")
    expect(MPNowPlayingInfoPropertyPlaybackQueueCount == "MPNowPlayingInfoPropertyPlaybackQueueCount", "qcnt")
    expect(MPNowPlayingInfoPropertyChapterNumber == "MPNowPlayingInfoPropertyChapterNumber", "ch")
    expect(MPNowPlayingInfoPropertyChapterCount == "MPNowPlayingInfoPropertyChapterCount", "chc")
    expect(MPNowPlayingInfoPropertyIsLiveStream == "MPNowPlayingInfoPropertyIsLiveStream", "live")
    expect(MPNowPlayingInfoPropertyCurrentLanguageOptions == "MPNowPlayingInfoPropertyCurrentLanguageOption", "lang opt singular")
    expect(MPNowPlayingInfoPropertyAvailableLanguageOptions == "MPNowPlayingInfoPropertyAvailableLanguageOptions", "avail")
    expect(MPNowPlayingInfoPropertyAssetURL == "MPNowPlayingInfoPropertyAssetURL", "np url")
    expect(MPNowPlayingInfoPropertyMediaType == "MPNowPlayingInfoPropertyMediaType", "np mt")
    expect(MPNowPlayingInfoPropertyPlaybackProgress == "MPNowPlayingInfoPropertyPlaybackProgress", "prog")
    expect(MPNowPlayingInfoPropertyCurrentPlaybackDate == "MPNowPlayingInfoPropertyCurrentPlaybackDate", "pdate")
    expect(MPNowPlayingInfoPropertyExternalContentIdentifier == "MPNowPlayingInfoPropertyExternalContentIdentifier", "ext")
    expect(MPNowPlayingInfoPropertyExternalUserProfileIdentifier == "MPNowPlayingInfoPropertyExternalUserProfileIdentifier", "prof")
    expect(MPNowPlayingInfoPropertyServiceIdentifier == "MPNowPlayingInfoPropertyServiceIdentifier", "svc")
    expect(MPNowPlayingInfoPropertyAdTimeRanges == "MPNowPlayingInfoPropertyAdTimeRanges", "ad")
    expect(MPNowPlayingInfoPropertyCreditsStartTime == "MPNowPlayingInfoPropertyCreditsStartTime", "cred")
    expect(MPNowPlayingInfoPropertyExcludeFromSuggestions == "MPNowPlayingInfoPropertyExcludeFromSuggestions", "excl")
    expect(MPNowPlayingInfoPropertyInternationalStandardRecordingCode == "MPNowPlayingInfoPropertyInternationalStandardRecordingCode", "isrc")
    expect(MPNowPlayingInfoProperty1x1AnimatedArtwork == "MPNowPlayingInfoProperty1x1AnimatedArtwork", "1x1")
    expect(MPNowPlayingInfoProperty3x4AnimatedArtwork == "MPNowPlayingInfoProperty3x4AnimatedArtwork", "3x4")
    expect(MPNowPlayingInfoCollectionIdentifier == "MPNowPlayingInfoCollectionIdentifier", "coll")
    expect(MPLanguageOptionCharacteristicIsMainProgramContent == "public.main-program-content", "main")
    expect(MPLanguageOptionCharacteristicIsAuxiliaryContent == "public.auxiliary-content", "aux")
    expect(MPLanguageOptionCharacteristicContainsOnlyForcedSubtitles == "public.subtitles.forced-only", "forced")
    expect(MPLanguageOptionCharacteristicTranscribesSpokenDialog == "public.accessibility.transcribes-spoken-dialog", "dialog")
    expect(MPLanguageOptionCharacteristicDescribesMusicAndSound == "public.accessibility.describes-music-and-sound", "music")
    expect(MPLanguageOptionCharacteristicEasyToRead == "public.easy-to-read", "easy")
    expect(MPLanguageOptionCharacteristicDescribesVideo == "public.accessibility.describes-video", "video")
    expect(MPLanguageOptionCharacteristicLanguageTranslation == "public.translation", "tr")
    expect(MPLanguageOptionCharacteristicDubbedTranslation == "public.translation.dubbed", "dub")
    expect(MPLanguageOptionCharacteristicVoiceOverTranslation == "public.translation.voice-over", "vo")
    expect(NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange.rawValue == "MPMusicPlayerControllerNowPlayingItemDidChangeNotification", "n1")
    expect(NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange.rawValue == "MPMusicPlayerControllerPlaybackStateDidChangeNotification", "n2")
    expect(NSNotification.Name.MPMusicPlayerControllerQueueDidChange.rawValue == "MPMusicPlayerControllerQueueDidChangeNotification", "n3")
    expect(NSNotification.Name.MPMusicPlayerControllerVolumeDidChange.rawValue == "MPMusicPlayerControllerVolumeDidChangeNotification", "n4")
    expect(NSNotification.Name.MPMediaLibraryDidChange.rawValue == "MPMediaLibraryDidChangeNotification", "n5")
    expect(NSNotification.Name.MPMediaPlaybackIsPreparedToPlayDidChange.rawValue == "MPMediaPlaybackIsPreparedToPlayDidChangeNotification", "n6")
    expect(NSNotification.Name.MPVolumeViewWirelessRouteActiveDidChange.rawValue == "MPVolumeViewWirelessRouteActiveDidChangeNotification", "n7")
    expect(NSNotification.Name.MPVolumeViewWirelessRoutesAvailableDidChange.rawValue == "MPVolumeViewWirelessRoutesAvailableDidChangeNotification", "n8")
    expect(NSNotification.Name.MPMoviePlayerPlaybackDidFinish.rawValue == "MPMoviePlayerPlaybackDidFinishNotification", "n9")
    expect(NSNotification.Name.MPMoviePlayerPlaybackStateDidChange.rawValue == "MPMoviePlayerPlaybackStateDidChangeNotification", "n10")
    expect(NSNotification.Name.MPMoviePlayerLoadStateDidChange.rawValue == "MPMoviePlayerLoadStateDidChangeNotification", "n11")
    expect(NSNotification.Name.MPMoviePlayerNowPlayingMovieDidChange.rawValue == "MPMoviePlayerNowPlayingMovieDidChangeNotification", "n12")
    expect(NSNotification.Name.MPMoviePlayerDidEnterFullscreen.rawValue == "MPMoviePlayerDidEnterFullscreenNotification", "n13")
    expect(NSNotification.Name.MPMoviePlayerDidExitFullscreen.rawValue == "MPMoviePlayerDidExitFullscreenNotification", "n14")
    expect(NSNotification.Name.MPMoviePlayerWillEnterFullscreen.rawValue == "MPMoviePlayerWillEnterFullscreenNotification", "n15")
    expect(NSNotification.Name.MPMoviePlayerWillExitFullscreen.rawValue == "MPMoviePlayerWillExitFullscreenNotification", "n16")
    expect(NSNotification.Name.MPMoviePlayerScalingModeDidChange.rawValue == "MPMoviePlayerScalingModeDidChangeNotification", "n17")
    expect(NSNotification.Name.MPMoviePlayerReadyForDisplayDidChange.rawValue == "MPMoviePlayerReadyForDisplayDidChangeNotification", "n18")
    expect(NSNotification.Name.MPMoviePlayerThumbnailImageRequestDidFinish.rawValue == "MPMoviePlayerThumbnailImageRequestDidFinishNotification", "n19")
    expect(NSNotification.Name.MPMoviePlayerTimedMetadataUpdated.rawValue == "MPMoviePlayerTimedMetadataUpdatedNotification", "n20")
    expect(NSNotification.Name.MPMoviePlayerIsAirPlayVideoActiveDidChange.rawValue == "MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification", "n21")
    expect(NSNotification.Name.MPMovieDurationAvailable.rawValue == "MPMovieDurationAvailableNotification", "n22")
    expect(NSNotification.Name.MPMovieMediaTypesAvailable.rawValue == "MPMovieMediaTypesAvailableNotification", "n23")
    expect(NSNotification.Name.MPMovieNaturalSizeAvailable.rawValue == "MPMovieNaturalSizeAvailableNotification", "n24")
    expect(NSNotification.Name.MPMovieSourceTypeAvailable.rawValue == "MPMovieSourceTypeAvailableNotification", "n25")
    expect(MPMoviePlayerPlaybackDidFinishReasonUserInfoKey == "MPMoviePlayerPlaybackDidFinishReasonUserInfoKey", "uk1")
    expect(MPMoviePlayerThumbnailErrorKey == "MPMoviePlayerThumbnailErrorKey", "uk2")
    expect(MPMoviePlayerThumbnailImageKey == "MPMoviePlayerThumbnailImageKey", "uk3")
    expect(MPMoviePlayerThumbnailTimeKey == "MPMoviePlayerThumbnailTimeKey", "uk4")
    expect(MPMoviePlayerTimedMetadataUserInfoKey == "MPMoviePlayerTimedMetadataUserInfoKey", "uk5")
    expect(MPMoviePlayerTimedMetadataKeyName == "name", "uk6")
    expect(MPMoviePlayerTimedMetadataKeyInfo == "info", "uk7")
    expect(MPMoviePlayerTimedMetadataKeyMIMEType == "mimeType", "uk8")
    expect(MPMoviePlayerTimedMetadataKeyDataType == "dataType", "uk9")
    expect(MPMoviePlayerTimedMetadataKeyLanguageCode == "languageCode", "uk10")
    expect(MPMoviePlayerFullscreenAnimationDurationUserInfoKey == "MPMoviePlayerFullscreenAnimationDurationUserInfoKey", "uk11")
    expect(MPMoviePlayerFullscreenAnimationCurveUserInfoKey == "MPMoviePlayerFullscreenAnimationCurveUserInfoKey", "uk12")
}

private func exerciseLibraryAndQuery() {
    MPMediaLibrary.openuikit_resetLibrary()
    expect(MPMediaLibrary.authorizationStatus() == .denied, "denied")
    expect(MPMediaLibrary.default() === MPMediaLibrary.default(), "shared")
    expect(MPMediaQuery.songs().items == nil, "unauthorized items nil")
    expect(MPMediaQuery().groupingType == .title, "default grouping")
    expect(MPMediaQuery.songs().groupingType == .title, "songs")
    expect(MPMediaQuery.albums().groupingType == .album, "albums")
    expect(MPMediaQuery.artists().groupingType == .artist, "artists")
    expect(MPMediaQuery.composers().groupingType == .composer, "composers")
    expect(MPMediaQuery.genres().groupingType == .genre, "genres")
    expect(MPMediaQuery.playlists().groupingType == .playlist, "playlists")
    expect(MPMediaQuery.podcasts().groupingType == .podcastTitle, "podcasts")
    expect(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyTitle), "filter title")
    expect(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPersistentID), "filter pid")
    expect(!MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtwork), "no filter artwork")
    expect(!MPMediaItem.canFilter(byProperty: MPMediaItemPropertyLyrics), "no filter lyrics")
    expect(MPMediaEntity.canFilter(byProperty: MPMediaEntityPropertyPersistentID), "entity pid")
    expect(!MPMediaEntity.canFilter(byProperty: MPMediaItemPropertyTitle), "entity title")
    expect(
        MPMediaItem.titleProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumTitle,
        "title map"
    )
    expect(
        MPMediaItem.persistentIDProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumPersistentID,
        "pid map"
    )
    expect(MPMediaItem.titleProperty(forGroupingType: .title) == "title", "title title")
    expect(MPMediaItem.persistentIDProperty(forGroupingType: .title) == "persistentID", "title pid")
    expect(MPMediaItem.titleProperty(forGroupingType: .artist) == "artist", "artist title")
    expect(MPMediaItem.titleProperty(forGroupingType: .albumArtist) == "albumArtist", "aa")
    expect(MPMediaItem.titleProperty(forGroupingType: .composer) == "composer", "comp t")
    expect(MPMediaItem.titleProperty(forGroupingType: .genre) == "genre", "genre t")
    expect(MPMediaItem.titleProperty(forGroupingType: .playlist) == "name", "pl t")
    expect(MPMediaItem.titleProperty(forGroupingType: .podcastTitle) == "podcastTitle", "pod t")

    let a = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Karma Police",
        MPMediaItemPropertyArtist: "Radiohead",
        MPMediaItemPropertyAlbumTitle: "OK Computer",
        MPMediaItemPropertyPersistentID: UInt64(11),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyPlayCount: 4,
        MPMediaItemPropertyGenre: "Rock",
    ])
    let b = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Paranoid Android",
        MPMediaItemPropertyArtist: "Radiohead",
        MPMediaItemPropertyAlbumTitle: "OK Computer",
        MPMediaItemPropertyPersistentID: UInt64(12),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyGenre: "Rock",
    ])
    let c = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Yesterday",
        MPMediaItemPropertyArtist: "The Beatles",
        MPMediaItemPropertyAlbumTitle: "Help!",
        MPMediaItemPropertyPersistentID: UInt64(21),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyGenre: "Pop",
        MPMediaItemPropertyIsCompilation: false,
    ])
    MPMediaLibrary.openuikit_loadFixtureLibrary([a, b, c])
    expect(MPMediaLibrary.authorizationStatus() == .authorized, "fixture auth")
    expect(MPMediaQuery.songs().items?.count == 3, "3 songs")
    let byArtist = MPMediaQuery(filterPredicates: [
        MPMediaPropertyPredicate(value: "Radiohead", forProperty: MPMediaItemPropertyArtist)
    ])
    expect(byArtist.items?.count == 2, "artist equalTo")
    let contains = MPMediaPropertyPredicate(
        value: "Police",
        forProperty: MPMediaItemPropertyTitle,
        comparisonType: .contains
    )
    expect(contains.comparisonType == .contains, "contains type")
    let byTitle = MPMediaQuery(filterPredicates: [contains])
    expect(byTitle.items?.count == 1, "contains")
    expect(byTitle.items?.first?.title == "Karma Police", "title")
    let albums = MPMediaQuery.albums()
    expect(albums.collections?.count == 2, "2 albums")
    expect(a.value(forProperty: MPMediaItemPropertyTitle) as? String == "Karma Police", "value")
    expect(a["title"] as? String == "Karma Police", "subscript")
    expect(a.artist == "Radiohead", "artist getter")
    expect(a.persistentID == 11, "pid getter")
    expect(a.mediaType.contains(.music), "mediaType")
    var enumerated = 0
    a.enumerateValues(forProperties: [MPMediaItemPropertyTitle, MPMediaItemPropertyArtist]) { _, _, _ in
        enumerated += 1
    }
    expect(enumerated == 2, "enumerate")
    let collection = MPMediaItemCollection(items: [a, b])
    expect(collection.count == 2, "count")
    expect(collection.representativeItem === a, "rep")
    expect(collection.mediaTypes.contains(.music), "types")
    let audiobooks = MPMediaQuery.audiobooks()
    expect(audiobooks.filterPredicates?.isEmpty == false, "audiobooks pred")
    let compilations = MPMediaQuery.compilations()
    expect(compilations.filterPredicates?.isEmpty == false, "comp pred")
    audiobooks.addFilterPredicate(contains)
    audiobooks.removeFilterPredicate(contains)
    let copied = byArtist.copy() as! MPMediaQuery
    expect(copied.filterPredicates?.count == byArtist.filterPredicates?.count, "copy")
    let playlistMeta = MPMediaPlaylistCreationMetadata(name: "Mix")
    playlistMeta.descriptionText = "x"
    expect(playlistMeta.name == "Mix", "meta")
    let playlist = MPMediaPlaylist(items: [a])
    expect(playlist.count == 1, "pl")
    MPMediaLibrary.openuikit_resetLibrary()
    expect(MPMediaLibrary.authorizationStatus() == .denied, "reset")
    expect(MPMediaQuery.songs().items == nil, "reset nil")

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
}

private func exerciseArtwork() {
    let image = UIImage(size: CGSize(width: 10, height: 8))
    let fromImage = MPMediaItemArtwork(image: image)
    expect(fromImage.bounds.size.width == 10, "fromImage w")
    expect(fromImage.bounds.size.height == 8, "fromImage h")
    expect(fromImage.imageCropRect.size.width == 10, "crop")
    let art = MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 80)) { size in
        UIImage(size: size)
    }
    expect(art.bounds.width == 100 && art.bounds.height == 80, "bounds")
    let at50 = art.image(at: CGSize(width: 50, height: 40))
    expect(at50?.size.width == 50 && at50?.size.height == 40, "image at")
    let item = MPMediaItem(hostProperties: [MPMediaItemPropertyArtwork: art])
    expect(item.artwork === art, "item artwork")
    let content = MPContentItem(identifier: "x")
    content.artwork = art
    expect(content.artwork === art, "content artwork")
}

private func exercisePlayer() {
    MPMediaLibrary.openuikit_resetLibrary()
    let player = MPMusicPlayerController.applicationMusicPlayer
    player.stop()
    player.setQueue(with: MPMediaItemCollection(items: []))
    expect(player.playbackState == .stopped, "initial stopped")
    expect(player.repeatMode == .none, "repeat none")
    expect(player.shuffleMode == .off, "shuffle off")
    expect(player.currentPlaybackRate == 0, "rate 0")
    expect(player.indexOfNowPlayingItem == 0, "idx 0")
    player.play()
    expect(player.playbackState == .stopped, "empty play stays stopped")
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

    let a = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "One", MPMediaItemPropertyPersistentID: UInt64(1)])
    let b = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "Two", MPMediaItemPropertyPersistentID: UInt64(2)])
    player.setQueue(with: MPMediaItemCollection(items: [a, b]))
    expect(player.nowPlayingItem === a, "first")
    var stateNotes = 0
    var itemNotes = 0
    let nc = NotificationCenter.default
    let s1 = nc.addObserver(
        forName: .MPMusicPlayerControllerPlaybackStateDidChange,
        object: player,
        queue: nil
    ) { _ in stateNotes += 1 }
    let s2 = nc.addObserver(
        forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
        object: player,
        queue: nil
    ) { _ in itemNotes += 1 }
    player.beginGeneratingPlaybackNotifications()
    player.play()
    expect(player.playbackState == .playing, "playing")
    expect(player.currentPlaybackRate == 1, "rate 1")
    expect(player.isPreparedToPlay, "prepared")
    player.pause()
    expect(player.playbackState == .paused, "paused")
    player.play()
    player.skipToNextItem()
    expect(player.nowPlayingItem === b, "next")
    expect(player.indexOfNowPlayingItem == 1, "idx 1")
    player.skipToPreviousItem()
    expect(player.nowPlayingItem === a, "prev")
    player.skipToBeginning()
    expect(player.currentPlaybackTime == 0, "begin")
    player.stop()
    expect(player.playbackState == .stopped, "stopped")
    player.endGeneratingPlaybackNotifications()
    nc.removeObserver(s1)
    nc.removeObserver(s2)
    expect(stateNotes > 0, "state notes")
    expect(itemNotes > 0, "item notes")

    let system = MPMusicPlayerController.systemMusicPlayer
    system.openToPlay(MPMusicPlayerStoreQueueDescriptor(storeIDs: ["1"]))
    expect(system.playbackState == .stopped, "openToPlay empty")
    expect(MPMusicPlayerController.iPodMusicPlayer === MPMusicPlayerController.systemMusicPlayer as AnyObject, "ipod")
    _ = MPMusicPlayerController.applicationQueuePlayer.repeatMode

    let desc = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: [a, b]))
    desc.startItem = a
    desc.setStartTime(1, for: a)
    desc.setEndTime(2, for: a)
    player.setQueue(with: desc)
    player.append(desc)
    player.prepend(desc)
    let qdesc = MPMusicPlayerMediaItemQueueDescriptor(query: MPMediaQuery.songs())
    expect(qdesc.query.groupingType == .title, "qdesc")
    let store = MPMusicPlayerStoreQueueDescriptor(storeIDs: ["x"])
    store.startItemID = "x"
    store.setStartTime(0, forItemWithStoreID: "x")
    store.setEndTime(1, forItemWithStoreID: "x")
    expect(store.storeIDs == ["x"], "store")
    let params = MPMusicPlayerPlayParameters(dictionary: ["id": "1"])
    expect(params != nil, "params")
    let pq = MPMusicPlayerPlayParametersQueueDescriptor(playParametersQueue: [params!])
    pq.startItemPlayParameters = params
    pq.setStartTime(0, forItemWith: params!)
    pq.setEndTime(1, forItemWith: params!)
    expect(pq.playParametersQueue.count == 1, "pq")
    let mutable = MPMusicPlayerControllerMutableQueue()
    mutable.insert(desc, after: a)
    mutable.remove(a)
    _ = mutable.items

    expect(!MPVolumeSettingsAlertIsVisible(), "volume alert")
    MPVolumeSettingsAlertShow()
    expect(!MPVolumeSettingsAlertIsVisible(), "still hidden")
    MPVolumeSettingsAlertHide()

    let center = MPNowPlayingInfoCenter.default()
    center.nowPlayingInfo = [
        MPNowPlayingInfoPropertyPlaybackRate: 1,
        MPMediaItemPropertyTitle: "Song",
        MPNowPlayingInfoPropertyElapsedPlaybackTime: 12,
    ]
    expect(center.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Int == 1, "info")
    expect(center.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String == "Song", "title key")
    center.playbackState = .paused
    expect(center.playbackState == .paused, "center state")
    expect(
        MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys == [MPNowPlayingInfoProperty3x4AnimatedArtwork],
        "artwork keys"
    )
    let lang = MPNowPlayingInfoLanguageOption(
        type: .audible,
        languageTag: "en",
        characteristics: [MPLanguageOptionCharacteristicIsMainProgramContent],
        displayName: "English",
        identifier: "en-aud"
    )
    expect(lang.languageTag == "en", "tag")
    expect(!lang.isAutomaticAudibleLanguageOption(), "auto a")
    expect(!lang.isAutomaticLegibleLanguageOption(), "auto l")
    let group = MPNowPlayingInfoLanguageOptionGroup(
        languageOptions: [lang],
        defaultLanguageOption: lang,
        allowEmptySelection: false
    )
    expect(group.languageOptions.count == 1, "group")
    expect(group.allowEmptySelection == false, "empty sel")
    let session = MPNowPlayingSession()
    expect(!session.canBecomeActive, "session")
    expect(!session.isActive, "inactive")
    _ = session.nowPlayingInfoCenter
    _ = session.remoteCommandCenter
    session.automaticallyPublishesNowPlayingInfo = true

    let movie = MPMoviePlayerController(contentURL: URL(string: "file://tmp.m4v")!)
    movie?.play()
    expect(movie?.playbackState == .stopped, "movie stopped")
    movie?.controlStyle = .none
    movie?.repeatMode = .one
    movie?.scalingMode = .fill
    movie?.setFullscreen(true, animated: false)
    expect(movie?.isFullscreen == true, "fs")
    movie?.pause()
    movie?.stop()
    movie?.beginSeekingForward()
    movie?.beginSeekingBackward()
    movie?.endSeeking()
    movie?.cancelAllThumbnailImageRequests()
    movie?.requestThumbnailImages(atTimes: [0], timeOption: .exact)
    _ = movie?.accessLog.events
    _ = movie?.errorLog.events
    _ = movie?.timedMetadata
    let timed = MPTimedMetadata()
    _ = timed.key
    _ = timed.keyspace
    _ = timed.timestamp
    _ = timed.value
    _ = timed.allMetadata
    let accessEvent = MPMovieAccessLogEvent()
    _ = accessEvent.URI
    _ = accessEvent.durationWatched
    _ = accessEvent.indicatedBitrate
    _ = accessEvent.observedBitrate
    _ = accessEvent.numberOfBytesTransferred
    _ = accessEvent.numberOfDroppedVideoFrames
    _ = accessEvent.numberOfSegmentsDownloaded
    _ = accessEvent.numberOfServerAddressChanges
    _ = accessEvent.numberOfStalls
    _ = accessEvent.playbackSessionID
    _ = accessEvent.playbackStartDate
    _ = accessEvent.playbackStartOffset
    _ = accessEvent.segmentsDownloadedDuration
    _ = accessEvent.serverAddress
    let errEvent = MPMovieErrorLogEvent()
    _ = errEvent.URI
    _ = errEvent.date
    _ = errEvent.errorComment
    _ = errEvent.errorDomain
    _ = errEvent.errorStatusCode
    _ = errEvent.playbackSessionID
    _ = errEvent.serverAddress
}

private func exerciseRemoteCommands() {
    let commands = MPRemoteCommandCenter.shared()
    expect(commands === MPRemoteCommandCenter.shared(), "shared")
    expect(commands.playCommand.isEnabled, "play enabled")
    expect(commands.pauseCommand.isEnabled, "pause")
    expect(commands.stopCommand.isEnabled, "stop")
    expect(commands.togglePlayPauseCommand.isEnabled, "toggle")
    expect(commands.nextTrackCommand.isEnabled, "next")
    expect(commands.previousTrackCommand.isEnabled, "prev")
    expect(commands.likeCommand.isEnabled, "like")
    expect(commands.dislikeCommand.isEnabled, "dislike")
    expect(commands.bookmarkCommand.isEnabled, "bookmark")
    expect(commands.skipForwardCommand.preferredIntervals.first?.doubleValue == 10, "skip fwd 10")
    expect(commands.skipBackwardCommand.preferredIntervals.first?.doubleValue == 10, "skip back 10")
    expect(commands.ratingCommand.minimumRating == 0, "rating min")
    expect(commands.ratingCommand.maximumRating == 0, "rating max")
    expect(commands.changeRepeatModeCommand.currentRepeatType == .off, "repeat")
    expect(commands.changeShuffleModeCommand.currentShuffleType == .off, "shuffle")
    expect(commands.changePlaybackRateCommand.supportedPlaybackRates.isEmpty, "rates")
    commands.likeCommand.isActive = true
    commands.likeCommand.localizedTitle = "Like"
    commands.likeCommand.localizedShortTitle = "L"
    expect(commands.likeCommand.isActive, "active")
    _ = commands.enableLanguageOptionCommand
    _ = commands.disableLanguageOptionCommand
    _ = commands.seekForwardCommand
    _ = commands.seekBackwardCommand
    _ = commands.changePlaybackPositionCommand
    _ = commands.ratingCommand

    var invoked = false
    let token = commands.playCommand.addTarget { event in
        invoked = true
        _ = event
        return .success
    }
    let status = commands.playCommand.openuikit_invoke(
        MPRemoteCommandEvent(command: commands.playCommand)
    )
    expect(invoked, "handler ran")
    expect(status == .success, "success")
    commands.playCommand.removeTarget(token)
    let empty = commands.playCommand.openuikit_invoke(
        MPRemoteCommandEvent(command: commands.playCommand)
    )
    expect(empty == .noActionableNowPlayingItem, "no handler")

    let target = CommandTarget()
    commands.pauseCommand.addTarget(target, action: #selector(CommandTarget.handle(_:)))
    _ = commands.pauseCommand.openuikit_invoke(MPRemoteCommandEvent(command: commands.pauseCommand))
    expect(target.count == 1, "selector fired")
    commands.pauseCommand.removeTarget(target, action: #selector(CommandTarget.handle(_:)))
    _ = commands.pauseCommand.openuikit_invoke(MPRemoteCommandEvent(command: commands.pauseCommand))
    expect(target.count == 1, "removed")

    let pos = MPChangePlaybackPositionCommandEvent(
        command: commands.changePlaybackPositionCommand,
        positionTime: 12
    )
    expect(pos.positionTime == 12, "pos")
    let rate = MPChangePlaybackRateCommandEvent(
        command: commands.changePlaybackRateCommand,
        playbackRate: 1.5
    )
    expect(rate.playbackRate == 1.5, "rate ev")
    let rep = MPChangeRepeatModeCommandEvent(
        command: commands.changeRepeatModeCommand,
        repeatType: .all,
        preservesRepeatMode: true
    )
    expect(rep.repeatType == .all && rep.preservesRepeatMode, "rep ev")
    let shu = MPChangeShuffleModeCommandEvent(
        command: commands.changeShuffleModeCommand,
        shuffleType: .items,
        preservesShuffleMode: false
    )
    expect(shu.shuffleType == .items, "shu ev")
    let lang = MPNowPlayingInfoLanguageOption(
        type: .legible, languageTag: "en", characteristics: nil,
        displayName: "EN", identifier: "en"
    )
    let langEv = MPChangeLanguageOptionCommandEvent(
        command: commands.enableLanguageOptionCommand,
        languageOption: lang,
        setting: .nowPlayingItemOnly
    )
    expect(langEv.setting == .nowPlayingItemOnly, "lang ev")
    let fb = MPFeedbackCommandEvent(command: commands.likeCommand, isNegative: true)
    expect(fb.isNegative, "neg")
    let rating = MPRatingCommandEvent(command: commands.ratingCommand, rating: 4)
    expect(rating.rating == 4, "rating ev")
    let seek = MPSeekCommandEvent(command: commands.seekForwardCommand, type: .endSeeking)
    expect(seek.type == .endSeeking, "seek")
    let skip = MPSkipIntervalCommandEvent(command: commands.skipForwardCommand, interval: 10)
    expect(skip.interval == 10, "skip ev")
    _ = skip.command
    _ = skip.timestamp
}

private func exerciseChrome() async {
    await MainActor.run {
        let vol = MPVolumeView()
        expect(vol.frame == .zero, "default frame")
        expect(!vol.showsRouteButton, "route false")
        expect(vol.showsVolumeSlider, "slider true")
        expect(!vol.isWirelessRouteActive, "wireless")
        expect(!vol.areWirelessRoutesAvailable, "routes")
        expect(vol.volumeSliderRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 44)) == .zero, "slider rect")
        expect(vol.routeButtonRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 44)) == .zero, "route rect")
        expect(vol.volumeThumbRect(forBounds: .zero, volumeSliderRect: .zero, value: 0) == .zero, "thumb")
        expect(vol.maximumVolumeSliderImage(for: .normal) == nil, "max img")
        expect(vol.minimumVolumeSliderImage(for: .normal) == nil, "min img")
        expect(vol.routeButtonImage(for: .normal) == nil, "route img")
        expect(vol.volumeThumbImage(for: .normal) == nil, "thumb img")
        vol.setMaximumVolumeSliderImage(nil, for: .normal)
        vol.setMinimumVolumeSliderImage(nil, for: .normal)
        vol.setRouteButtonImage(nil, for: .highlighted)
        vol.setVolumeThumbImage(nil, for: .selected)
        vol.volumeWarningSliderImage = nil
        let sized = MPVolumeView(frame: CGRect(x: 10, y: 20, width: 300, height: 40))
        expect(sized.frame.width == 300, "init frame")

        let picker = MPMediaPickerController(mediaTypes: .music)
        expect(picker.mediaTypes == .music, "types")
        expect(!picker.allowsPickingMultipleItems, "multi")
        expect(picker.showsCloudItems, "cloud")
        expect(picker.showsItemsWithProtectedAssets, "protected")
        expect(picker.prompt == nil, "prompt")
        let sink = PickerSink()
        picker.delegate = sink
        let asDel: any MPMediaPickerControllerDelegate = sink
        asDel.mediaPickerDidCancel(picker)
        asDel.mediaPicker(picker, didPickMediaItems: MPMediaItemCollection(items: []))
        expect(sink.cancelled == 1 && sink.picked == 1, "delegate")
    }
}

private func exercisePlayableContent() async {
    let manager = MPPlayableContentManager.shared()
    expect(!manager.context.endpointAvailable, "no endpoint")
    expect(manager.context.enforcedContentItemsCount == 0, "no limits")
    expect(!manager.context.contentLimitsEnabled, "limits")
    expect(!manager.context.contentLimitsEnforced, "enforced")
    expect(manager.context.enforcedContentTreeDepth == 0, "depth")
    manager.beginUpdates()
    manager.endUpdates()
    manager.reloadData()
    manager.nowPlayingIdentifiers = ["a"]
    expect(manager.nowPlayingIdentifiers == ["a"], "ids")

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
    content.subtitle = "Sub"
    content.isContainer = true
    content.isExplicitContent = true
    content.isStreamingContent = true
    content.playbackProgress = 0.5
    expect(content.identifier == "root", "id")
    expect(content.isContainer, "container")
    expect(content.isExplicitContent, "explicit")
    expect(content.isStreamingContent, "stream")
    expect(content.playbackProgress == 0.5, "progress")
    expect(content.subtitle == "Sub", "sub")
}

private func run() async {
    exerciseEnums()
    exerciseOptionSets()
    exerciseErrors()
    exerciseConstants()
    exerciseLibraryAndQuery()
    exerciseArtwork()
    exercisePlayer()
    exerciseRemoteCommands()
    await exerciseChrome()
    await exercisePlayableContent()
    print("MEDIAPLAYER_AGENT_RUNTIME_OK")
}

let group = DispatchGroup()
group.enter()
Task {
    await run()
    group.leave()
}
while group.wait(timeout: .now() + .milliseconds(50)) == .timedOut {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
}
