import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

// --- MPEnumTests.swift ---

func testEnumRawValues() {
    precondition(MPChangeLanguageOptionSetting.none.rawValue == 0)
    precondition(MPChangeLanguageOptionSetting.nowPlayingItemOnly.rawValue == 1)
    precondition(MPChangeLanguageOptionSetting.permanent.rawValue == 2)
    precondition(MPChangeLanguageOptionSetting.none != .permanent)
    _ = MPChangeLanguageOptionSetting.none.hashValue
    var languageHasher = Hasher()
    MPChangeLanguageOptionSetting.permanent.hash(into: &languageHasher)
    _ = languageHasher.finalize()

    precondition(MPMediaGrouping.title.rawValue == 0)
    precondition(MPMediaGrouping.album.rawValue == 1)
    precondition(MPMediaGrouping.artist.rawValue == 2)
    precondition(MPMediaGrouping.albumArtist.rawValue == 3)
    precondition(MPMediaGrouping.composer.rawValue == 4)
    precondition(MPMediaGrouping.genre.rawValue == 5)
    precondition(MPMediaGrouping.playlist.rawValue == 6)
    precondition(MPMediaGrouping.podcastTitle.rawValue == 7)
    precondition(MPMediaGrouping.title != .album)
    _ = MPMediaGrouping.album.hashValue
    var groupingHasher = Hasher()
    MPMediaGrouping.genre.hash(into: &groupingHasher)
    _ = groupingHasher.finalize()

    precondition(MPMediaLibraryAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(MPMediaLibraryAuthorizationStatus.denied.rawValue == 1)
    precondition(MPMediaLibraryAuthorizationStatus.restricted.rawValue == 2)
    precondition(MPMediaLibraryAuthorizationStatus.authorized.rawValue == 3)
    precondition(MPMediaLibraryAuthorizationStatus.denied != .authorized)
    _ = MPMediaLibraryAuthorizationStatus.denied.hashValue
    var authHasher = Hasher()
    MPMediaLibraryAuthorizationStatus.authorized.hash(into: &authHasher)
    _ = authHasher.finalize()

    precondition(MPMediaPredicateComparison.equalTo.rawValue == 0)
    precondition(MPMediaPredicateComparison.contains.rawValue == 1)
    precondition(MPMediaPredicateComparison.equalTo != .contains)
    _ = MPMediaPredicateComparison.equalTo.hashValue
    var predicateHasher = Hasher()
    MPMediaPredicateComparison.contains.hash(into: &predicateHasher)
    _ = predicateHasher.finalize()

    precondition(MPMovieControlStyle.none.rawValue == 0)
    precondition(MPMovieControlStyle.embedded.rawValue == 1)
    precondition(MPMovieControlStyle.fullscreen.rawValue == 2)
    precondition(MPMovieControlStyle.none != .fullscreen)
    _ = MPMovieControlStyle.none.hashValue
    var controlHasher = Hasher()
    MPMovieControlStyle.embedded.hash(into: &controlHasher)
    _ = controlHasher.finalize()

    precondition(MPMovieFinishReason.playbackEnded.rawValue == 0)
    precondition(MPMovieFinishReason.playbackError.rawValue == 1)
    precondition(MPMovieFinishReason.userExited.rawValue == 2)
    precondition(MPMovieFinishReason.playbackEnded != .userExited)
    _ = MPMovieFinishReason.playbackEnded.hashValue
    var finishHasher = Hasher()
    MPMovieFinishReason.playbackError.hash(into: &finishHasher)
    _ = finishHasher.finalize()

    precondition(MPMoviePlaybackState.stopped.rawValue == 0)
    precondition(MPMoviePlaybackState.playing.rawValue == 1)
    precondition(MPMoviePlaybackState.paused.rawValue == 2)
    precondition(MPMoviePlaybackState.interrupted.rawValue == 3)
    precondition(MPMoviePlaybackState.seekingForward.rawValue == 4)
    precondition(MPMoviePlaybackState.seekingBackward.rawValue == 5)
    precondition(MPMoviePlaybackState.stopped != .playing)
    _ = MPMoviePlaybackState.stopped.hashValue
    var moviePlaybackHasher = Hasher()
    MPMoviePlaybackState.paused.hash(into: &moviePlaybackHasher)
    _ = moviePlaybackHasher.finalize()

    precondition(MPMovieRepeatMode.none.rawValue == 0)
    precondition(MPMovieRepeatMode.one.rawValue == 1)
    precondition(MPMovieRepeatMode.none != .one)
    _ = MPMovieRepeatMode.none.hashValue
    var movieRepeatHasher = Hasher()
    MPMovieRepeatMode.one.hash(into: &movieRepeatHasher)
    _ = movieRepeatHasher.finalize()

    precondition(MPMovieScalingMode.none.rawValue == 0)
    precondition(MPMovieScalingMode.aspectFit.rawValue == 1)
    precondition(MPMovieScalingMode.aspectFill.rawValue == 2)
    precondition(MPMovieScalingMode.fill.rawValue == 3)
    precondition(MPMovieScalingMode.none != .fill)
    _ = MPMovieScalingMode.none.hashValue
    var scalingHasher = Hasher()
    MPMovieScalingMode.fill.hash(into: &scalingHasher)
    _ = scalingHasher.finalize()

    precondition(MPMovieSourceType.unknown.rawValue == 0)
    precondition(MPMovieSourceType.file.rawValue == 1)
    precondition(MPMovieSourceType.streaming.rawValue == 2)
    precondition(MPMovieSourceType.unknown != .file)
    _ = MPMovieSourceType.unknown.hashValue
    var sourceHasher = Hasher()
    MPMovieSourceType.file.hash(into: &sourceHasher)
    _ = sourceHasher.finalize()

    precondition(MPMovieTimeOption.nearestKeyFrame.rawValue == 0)
    precondition(MPMovieTimeOption.exact.rawValue == 1)
    precondition(MPMovieTimeOption.exact != .nearestKeyFrame)
    _ = MPMovieTimeOption.exact.hashValue
    var timeHasher = Hasher()
    MPMovieTimeOption.nearestKeyFrame.hash(into: &timeHasher)
    _ = timeHasher.finalize()

    precondition(MPMusicPlaybackState.stopped.rawValue == 0)
    precondition(MPMusicPlaybackState.playing.rawValue == 1)
    precondition(MPMusicPlaybackState.paused.rawValue == 2)
    precondition(MPMusicPlaybackState.interrupted.rawValue == 3)
    precondition(MPMusicPlaybackState.seekingForward.rawValue == 4)
    precondition(MPMusicPlaybackState.seekingBackward.rawValue == 5)
    precondition(MPMusicPlaybackState.stopped != .playing)
    _ = MPMusicPlaybackState.stopped.hashValue
    var musicPlaybackHasher = Hasher()
    MPMusicPlaybackState.playing.hash(into: &musicPlaybackHasher)
    _ = musicPlaybackHasher.finalize()
    precondition(Set([MPMusicPlaybackState.stopped, .playing]).count == 2)

    precondition(MPMusicRepeatMode.default.rawValue == 0)
    precondition(MPMusicRepeatMode.none.rawValue == 1)
    precondition(MPMusicRepeatMode.one.rawValue == 2)
    precondition(MPMusicRepeatMode.all.rawValue == 3)
    precondition(MPMusicRepeatMode.none != .all)
    _ = MPMusicRepeatMode.none.hashValue
    var musicRepeatHasher = Hasher()
    MPMusicRepeatMode.all.hash(into: &musicRepeatHasher)
    _ = musicRepeatHasher.finalize()

    precondition(MPMusicShuffleMode.default.rawValue == 0)
    precondition(MPMusicShuffleMode.off.rawValue == 1)
    precondition(MPMusicShuffleMode.songs.rawValue == 2)
    precondition(MPMusicShuffleMode.albums.rawValue == 3)
    precondition(MPMusicShuffleMode.off != .songs)
    _ = MPMusicShuffleMode.off.hashValue
    var shuffleHasher = Hasher()
    MPMusicShuffleMode.songs.hash(into: &shuffleHasher)
    _ = shuffleHasher.finalize()

    precondition(MPNowPlayingInfoLanguageOptionType.audible.rawValue == 0)
    precondition(MPNowPlayingInfoLanguageOptionType.legible.rawValue == 1)
    precondition(MPNowPlayingInfoLanguageOptionType.audible != .legible)
    _ = MPNowPlayingInfoLanguageOptionType.audible.hashValue
    var optionTypeHasher = Hasher()
    MPNowPlayingInfoLanguageOptionType.legible.hash(into: &optionTypeHasher)
    _ = optionTypeHasher.finalize()

    precondition(MPNowPlayingInfoMediaType.none.rawValue == 0)
    precondition(MPNowPlayingInfoMediaType.audio.rawValue == 1)
    precondition(MPNowPlayingInfoMediaType.video.rawValue == 2)
    precondition(MPNowPlayingInfoMediaType.audio != .video)
    _ = MPNowPlayingInfoMediaType.audio.hashValue
    var mediaTypeHasher = Hasher()
    MPNowPlayingInfoMediaType.video.hash(into: &mediaTypeHasher)
    _ = mediaTypeHasher.finalize()

    precondition(MPNowPlayingPlaybackState.unknown.rawValue == 0)
    precondition(MPNowPlayingPlaybackState.playing.rawValue == 1)
    precondition(MPNowPlayingPlaybackState.paused.rawValue == 2)
    precondition(MPNowPlayingPlaybackState.stopped.rawValue == 3)
    precondition(MPNowPlayingPlaybackState.interrupted.rawValue == 4)
    precondition(MPNowPlayingPlaybackState.stopped != .playing)
    _ = MPNowPlayingPlaybackState.stopped.hashValue
    var nowPlayingHasher = Hasher()
    MPNowPlayingPlaybackState.paused.hash(into: &nowPlayingHasher)
    _ = nowPlayingHasher.finalize()

    precondition(MPRemoteCommandHandlerStatus.success.rawValue == 0)
    precondition(MPRemoteCommandHandlerStatus.noSuchContent.rawValue == 100)
    precondition(MPRemoteCommandHandlerStatus.noActionableNowPlayingItem.rawValue == 110)
    precondition(MPRemoteCommandHandlerStatus.deviceNotFound.rawValue == 120)
    precondition(MPRemoteCommandHandlerStatus.commandFailed.rawValue == 200)
    precondition(MPRemoteCommandHandlerStatus.success != .commandFailed)
    _ = MPRemoteCommandHandlerStatus.success.hashValue
    var handlerHasher = Hasher()
    MPRemoteCommandHandlerStatus.commandFailed.hash(into: &handlerHasher)
    _ = handlerHasher.finalize()

    precondition(MPRepeatType.off.rawValue == 0)
    precondition(MPRepeatType.one.rawValue == 1)
    precondition(MPRepeatType.all.rawValue == 2)
    precondition(MPRepeatType.off != .all)
    _ = MPRepeatType.off.hashValue
    var repeatHasher = Hasher()
    MPRepeatType.all.hash(into: &repeatHasher)
    _ = repeatHasher.finalize()

    precondition(MPSeekCommandEventType.beginSeeking.rawValue == 0)
    precondition(MPSeekCommandEventType.endSeeking.rawValue == 1)
    precondition(MPSeekCommandEventType.beginSeeking != .endSeeking)
    _ = MPSeekCommandEventType.beginSeeking.hashValue
    var seekHasher = Hasher()
    MPSeekCommandEventType.endSeeking.hash(into: &seekHasher)
    _ = seekHasher.finalize()

    precondition(MPShuffleType.off.rawValue == 0)
    precondition(MPShuffleType.items.rawValue == 1)
    precondition(MPShuffleType.collections.rawValue == 2)
    precondition(MPShuffleType.off != .items)
    _ = MPShuffleType.off.hashValue
    var shuffleTypeHasher = Hasher()
    MPShuffleType.items.hash(into: &shuffleTypeHasher)
    _ = shuffleTypeHasher.finalize()
}

func testOptionSetBits() {
    precondition(MPMediaType.music.rawValue == 1)
    precondition(MPMediaType.podcast.rawValue == 2)
    precondition(MPMediaType.audioBook.rawValue == 4)
    precondition(MPMediaType.audioITunesU.rawValue == 8)
    precondition(MPMediaType.anyAudio.rawValue == 255)
    precondition(MPMediaType.movie.rawValue == 256)
    precondition(MPMediaType.tvShow.rawValue == 512)
    precondition(MPMediaType.videoPodcast.rawValue == 1024)
    precondition(MPMediaType.musicVideo.rawValue == 2048)
    precondition(MPMediaType.videoITunesU.rawValue == 4096)
    precondition(MPMediaType.homeVideo.rawValue == 8192)
    precondition(MPMediaType.anyVideo.rawValue == 65280)
    precondition(MPMediaType.any.rawValue == ~UInt(0))
    precondition(MPMediaType.music.contains(.music))
    precondition(MPMediaType.anyAudio.contains(.podcast))
    precondition(!MPMediaType.music.contains(.movie))
    precondition(MPMediaType.music.union(.podcast).contains(.podcast))
    precondition(MPMediaType.music.intersection(.anyAudio) == .music)
    precondition(MPMediaType.music.isDisjoint(with: .movie))
    precondition(MPMediaType.anyAudio.isSuperset(of: .music))
    precondition(MPMediaType.music.isSubset(of: .anyAudio))
    precondition(MPMediaType.music.isStrictSubset(of: .anyAudio))
    precondition(MPMediaType.anyAudio.isStrictSuperset(of: .music))
    precondition(!MPMediaType.music.isEmpty)
    precondition(MPMediaType().isEmpty)
    precondition(MPMediaType.music != .movie)
    var types = MPMediaType.music
    _ = types.insert(.podcast)
    precondition(types.contains(.podcast))
    _ = types.remove(.podcast)
    _ = types.update(with: .audioBook)
    types.formUnion(.audioBook)
    types.formIntersection(.anyAudio)
    types.formSymmetricDifference(.music)
    types.subtract(.audioBook)
    _ = types.subtracting(.podcast)
    _ = types.symmetricDifference(.movie)
    let fromSeq = MPMediaType([.music, .podcast])
    precondition(fromSeq.contains(.music) && fromSeq.contains(.podcast))
    let lit: MPMediaType = [.music, .podcast]
    precondition(lit.contains(.podcast))
    _ = MPMediaType(rawValue: 1)

    precondition(MPMediaPlaylistAttribute.onTheGo.rawValue == 1)
    precondition(MPMediaPlaylistAttribute.smart.rawValue == 2)
    precondition(MPMediaPlaylistAttribute.genius.rawValue == 4)
    precondition(MPMediaPlaylistAttribute.smart.contains(.smart))
    precondition(MPMediaPlaylistAttribute.smart.union(.genius).contains(.genius))
    precondition(MPMediaPlaylistAttribute.smart.intersection(.genius).isEmpty)
    precondition(MPMediaPlaylistAttribute.smart.isDisjoint(with: .genius))
    precondition(MPMediaPlaylistAttribute([.smart, .genius]).isSuperset(of: .smart))
    precondition(MPMediaPlaylistAttribute.smart.isSubset(of: [.smart, .genius]))
    precondition(MPMediaPlaylistAttribute.smart.isStrictSubset(of: [.smart, .genius]))
    precondition(MPMediaPlaylistAttribute([.smart, .genius]).isStrictSuperset(of: .smart))
    precondition(MPMediaPlaylistAttribute().isEmpty)
    precondition(MPMediaPlaylistAttribute.smart != .genius)
    var playlist = MPMediaPlaylistAttribute.smart
    _ = playlist.insert(.genius)
    _ = playlist.remove(.genius)
    _ = playlist.update(with: .onTheGo)
    playlist.formUnion(.genius)
    playlist.formIntersection(.smart)
    playlist.formSymmetricDifference(.onTheGo)
    playlist.subtract(.smart)
    _ = playlist.subtracting(.genius)
    _ = playlist.symmetricDifference(.smart)
    _ = MPMediaPlaylistAttribute(rawValue: 1)

    precondition(MPMovieLoadState.playable.rawValue == 1)
    precondition(MPMovieLoadState.playthroughOK.rawValue == 2)
    precondition(MPMovieLoadState.stalled.rawValue == 4)
    precondition(MPMovieLoadState.playable.contains(.playable))
    precondition(MPMovieLoadState.playable.union(.stalled).contains(.stalled))
    precondition(MPMovieLoadState.playable.intersection(.stalled).isEmpty)
    precondition(MPMovieLoadState.playable.isDisjoint(with: .stalled))
    precondition(MPMovieLoadState([.playable, .stalled]).isSuperset(of: .playable))
    precondition(MPMovieLoadState.playable.isSubset(of: [.playable, .stalled]))
    precondition(MPMovieLoadState.playable.isStrictSubset(of: [.playable, .stalled]))
    precondition(MPMovieLoadState([.playable, .stalled]).isStrictSuperset(of: .playable))
    precondition(MPMovieLoadState().isEmpty)
    precondition(MPMovieLoadState.playable != .stalled)
    var load = MPMovieLoadState.playable
    _ = load.insert(.stalled)
    _ = load.remove(.stalled)
    _ = load.update(with: .playthroughOK)
    load.formUnion(.stalled)
    load.formIntersection(.playable)
    load.formSymmetricDifference(.playthroughOK)
    load.subtract(.playable)
    _ = load.subtracting(.stalled)
    _ = load.symmetricDifference(.playable)
    _ = MPMovieLoadState(rawValue: 1)

    precondition(MPMovieMediaTypeMask.video.rawValue == 1)
    precondition(MPMovieMediaTypeMask.audio.rawValue == 2)
    precondition(MPMovieMediaTypeMask.audio.contains(.audio))
    precondition(MPMovieMediaTypeMask.video.union(.audio).contains(.audio))
    precondition(MPMovieMediaTypeMask.video.intersection(.audio).isEmpty)
    precondition(MPMovieMediaTypeMask.video.isDisjoint(with: .audio))
    precondition(MPMovieMediaTypeMask([.video, .audio]).isSuperset(of: .video))
    precondition(MPMovieMediaTypeMask.video.isSubset(of: [.video, .audio]))
    precondition(MPMovieMediaTypeMask.video.isStrictSubset(of: [.video, .audio]))
    precondition(MPMovieMediaTypeMask([.video, .audio]).isStrictSuperset(of: .video))
    precondition(MPMovieMediaTypeMask().isEmpty)
    precondition(MPMovieMediaTypeMask.video != .audio)
    var mask = MPMovieMediaTypeMask.video
    _ = mask.insert(.audio)
    _ = mask.remove(.audio)
    _ = mask.update(with: .audio)
    mask.formUnion(.audio)
    mask.formIntersection(.video)
    mask.formSymmetricDifference(.audio)
    mask.subtract(.video)
    _ = mask.subtracting(.audio)
    _ = mask.symmetricDifference(.video)
    _ = MPMovieMediaTypeMask(rawValue: 1)
}

// --- MPErrorTests.swift ---

func testMPErrorCodes() {
    let codes: [(MPError.Code, Int)] = [
        (.unknown, 0),
        (.permissionDenied, 1),
        (.cloudServiceCapabilityMissing, 2),
        (.networkConnectionFailed, 3),
        (.notFound, 4),
        (.notSupported, 5),
        (.cancelled, 6),
        (.requestTimedOut, 7),
    ]
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        let error = MPError(code, userInfo: ["k": "v"])
        precondition(error.code == code)
        precondition(error.errorCode == raw)
        precondition(error.errorUserInfo["k"] as? String == "v")
        precondition(error == MPError(code))
        precondition(error != MPError(.unknown) || code == .unknown)
        precondition(code ~= error)
        let ns = error as NSError
        precondition(ns.domain == "MPErrorDomain")
        precondition(ns.code == raw)
        _ = error.localizedDescription
        _ = error.hashValue
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
        var codeHasher = Hasher()
        code.hash(into: &codeHasher)
        _ = codeHasher.finalize()
        _ = code.hashValue
    }
    precondition(MPError.errorDomain == "MPErrorDomain")
    precondition(MPErrorDomain == "MPErrorDomain")
    precondition(MPError.unknown == .unknown)
    precondition(MPError.permissionDenied == .permissionDenied)
    precondition(MPError.cloudServiceCapabilityMissing == .cloudServiceCapabilityMissing)
    precondition(MPError.networkConnectionFailed == .networkConnectionFailed)
    precondition(MPError.notFound == .notFound)
    precondition(MPError.notSupported == .notSupported)
    precondition(MPError.cancelled == .cancelled)
    precondition(MPError.requestTimedOut == .requestTimedOut)
    let mismatch = MPError(.notSupported)
    precondition(!(MPError.cancelled ~= mismatch))
    precondition(MPError.Code(rawValue: 5) == .notSupported)
    precondition(MPError.Code(rawValue: 99) == nil)
}

// --- MPMediaItemPropertyKeysTests.swift ---

func testMediaItemPropertyKeys() {
    let keys: [(String, String)] = [
        (MPMediaEntityPropertyPersistentID, "persistentID"),
        (MPMediaItemPropertyAlbumArtist, "albumArtist"),
        (MPMediaItemPropertyAlbumArtistPersistentID, "albumArtistPID"),
        (MPMediaItemPropertyAlbumPersistentID, "albumPID"),
        (MPMediaItemPropertyAlbumTitle, "albumTitle"),
        (MPMediaItemPropertyAlbumTrackCount, "albumTrackCount"),
        (MPMediaItemPropertyAlbumTrackNumber, "albumTrackNumber"),
        (MPMediaItemPropertyArtist, "artist"),
        (MPMediaItemPropertyArtistPersistentID, "artistPID"),
        (MPMediaItemPropertyArtwork, "artwork"),
        (MPMediaItemPropertyAssetURL, "assetURL"),
        (MPMediaItemPropertyBeatsPerMinute, "beatsPerMinute"),
        (MPMediaItemPropertyBookmarkTime, "bookmarkTime"),
        (MPMediaItemPropertyComments, "comments"),
        (MPMediaItemPropertyComposer, "composer"),
        (MPMediaItemPropertyComposerPersistentID, "composerPID"),
        (MPMediaItemPropertyDateAdded, "dateAdded"),
        (MPMediaItemPropertyDiscCount, "discCount"),
        (MPMediaItemPropertyDiscNumber, "discNumber"),
        (MPMediaItemPropertyGenre, "genre"),
        (MPMediaItemPropertyGenrePersistentID, "genrePID"),
        (MPMediaItemPropertyHasProtectedAsset, "hasProtectedAsset"),
        (MPMediaItemPropertyIsCloudItem, "isCloudItem"),
        (MPMediaItemPropertyIsCompilation, "isCompilation"),
        (MPMediaItemPropertyIsExplicit, "isExplicit"),
        (MPMediaItemPropertyIsPreorder, "isPreorder"),
        (MPMediaItemPropertyLastPlayedDate, "lastPlayedDate"),
        (MPMediaItemPropertyLyrics, "lyrics"),
        (MPMediaItemPropertyMediaType, "mediaType"),
        (MPMediaItemPropertyPersistentID, "persistentID"),
        (MPMediaItemPropertyPlayCount, "playCount"),
        (MPMediaItemPropertyPlaybackDuration, "playbackDuration"),
        (MPMediaItemPropertyPlaybackStoreID, "playbackStoreID"),
        (MPMediaItemPropertyPodcastPersistentID, "podcastPID"),
        (MPMediaItemPropertyPodcastTitle, "podcastTitle"),
        (MPMediaItemPropertyRating, "rating"),
        (MPMediaItemPropertyReleaseDate, "releaseDate"),
        (MPMediaItemPropertySkipCount, "skipCount"),
        (MPMediaItemPropertyTitle, "title"),
        (MPMediaItemPropertyUserGrouping, "userGrouping"),
        (MPMediaPlaylistPropertyAuthorDisplayName, "externalVendorDisplayName"),
        (MPMediaPlaylistPropertyCloudGlobalID, "cloudGlobalID"),
        (MPMediaPlaylistPropertyDescriptionText, "descriptionInfo"),
        (MPMediaPlaylistPropertyName, "name"),
        (MPMediaPlaylistPropertyPersistentID, "playlistPersistentID"),
        (MPMediaPlaylistPropertyPlaylistAttributes, "playlistAttributes"),
        (MPMediaPlaylistPropertySeedItems, "seedItems"),
    ]
    for (actual, expected) in keys {
        precondition(actual == expected)
    }
}

func testNotificationNames() {
    let names: [(NSNotification.Name, String)] = [
        (.MPMediaLibraryDidChange, "MPMediaLibraryDidChangeNotification"),
        (.MPMediaPlaybackIsPreparedToPlayDidChange, "MPMediaPlaybackIsPreparedToPlayDidChangeNotification"),
        (.MPMovieDurationAvailable, "MPMovieDurationAvailableNotification"),
        (.MPMovieMediaTypesAvailable, "MPMovieMediaTypesAvailableNotification"),
        (.MPMovieNaturalSizeAvailable, "MPMovieNaturalSizeAvailableNotification"),
        (.MPMoviePlayerDidEnterFullscreen, "MPMoviePlayerDidEnterFullscreenNotification"),
        (.MPMoviePlayerDidExitFullscreen, "MPMoviePlayerDidExitFullscreenNotification"),
        (.MPMoviePlayerIsAirPlayVideoActiveDidChange, "MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification"),
        (.MPMoviePlayerLoadStateDidChange, "MPMoviePlayerLoadStateDidChangeNotification"),
        (.MPMoviePlayerNowPlayingMovieDidChange, "MPMoviePlayerNowPlayingMovieDidChangeNotification"),
        (.MPMoviePlayerPlaybackDidFinish, "MPMoviePlayerPlaybackDidFinishNotification"),
        (.MPMoviePlayerPlaybackStateDidChange, "MPMoviePlayerPlaybackStateDidChangeNotification"),
        (.MPMoviePlayerReadyForDisplayDidChange, "MPMoviePlayerReadyForDisplayDidChangeNotification"),
        (.MPMoviePlayerScalingModeDidChange, "MPMoviePlayerScalingModeDidChangeNotification"),
        (.MPMoviePlayerThumbnailImageRequestDidFinish, "MPMoviePlayerThumbnailImageRequestDidFinishNotification"),
        (.MPMoviePlayerTimedMetadataUpdated, "MPMoviePlayerTimedMetadataUpdatedNotification"),
        (.MPMoviePlayerWillEnterFullscreen, "MPMoviePlayerWillEnterFullscreenNotification"),
        (.MPMoviePlayerWillExitFullscreen, "MPMoviePlayerWillExitFullscreenNotification"),
        (.MPMovieSourceTypeAvailable, "MPMovieSourceTypeAvailableNotification"),
        (.MPMusicPlayerControllerNowPlayingItemDidChange, "MPMusicPlayerControllerNowPlayingItemDidChangeNotification"),
        (.MPMusicPlayerControllerPlaybackStateDidChange, "MPMusicPlayerControllerPlaybackStateDidChangeNotification"),
        (.MPMusicPlayerControllerQueueDidChange, "MPMusicPlayerControllerQueueDidChangeNotification"),
        (.MPMusicPlayerControllerVolumeDidChange, "MPMusicPlayerControllerVolumeDidChangeNotification"),
        (.MPVolumeViewWirelessRouteActiveDidChange, "MPVolumeViewWirelessRouteActiveDidChangeNotification"),
        (.MPVolumeViewWirelessRoutesAvailableDidChange, "MPVolumeViewWirelessRoutesAvailableDidChangeNotification"),
    ]
    for (name, expected) in names {
        precondition(name.rawValue == expected)
    }
    precondition(
        MPMusicPlayerController.MPMediaPlaybackIsPreparedToPlayDidChange
            == .MPMediaPlaybackIsPreparedToPlayDidChange
    )
}

func testMovieUserInfoKeys() {
    precondition(MPMoviePlayerFullscreenAnimationCurveUserInfoKey == "MPMoviePlayerFullscreenAnimationCurveUserInfoKey")
    precondition(MPMoviePlayerFullscreenAnimationDurationUserInfoKey == "MPMoviePlayerFullscreenAnimationDurationUserInfoKey")
    precondition(MPMoviePlayerPlaybackDidFinishReasonUserInfoKey == "MPMoviePlayerPlaybackDidFinishReasonUserInfoKey")
    precondition(MPMoviePlayerThumbnailErrorKey == "MPMoviePlayerThumbnailErrorKey")
    precondition(MPMoviePlayerThumbnailImageKey == "MPMoviePlayerThumbnailImageKey")
    precondition(MPMoviePlayerThumbnailTimeKey == "MPMoviePlayerThumbnailTimeKey")
    precondition(MPMoviePlayerTimedMetadataKeyDataType == "dataType")
    precondition(MPMoviePlayerTimedMetadataKeyInfo == "info")
    precondition(MPMoviePlayerTimedMetadataKeyLanguageCode == "languageCode")
    precondition(MPMoviePlayerTimedMetadataKeyMIMEType == "mimeType")
    precondition(MPMoviePlayerTimedMetadataKeyName == "name")
    precondition(MPMoviePlayerTimedMetadataUserInfoKey == "MPMoviePlayerTimedMetadataUserInfoKey")
}

// --- MPMediaItemTests.swift ---

func testMediaItemProperties() {
    let added = Date(timeIntervalSince1970: 100)
    let last = Date(timeIntervalSince1970: 200)
    let released = Date(timeIntervalSince1970: 50)
    let url = URL(string: "file:///tmp/song.m4a")!
    let pid: MPMediaEntityPersistentID = 11
    let item = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Karma Police",
        MPMediaItemPropertyArtist: "Radiohead",
        MPMediaItemPropertyAlbumTitle: "OK Computer",
        MPMediaItemPropertyAlbumArtist: "Radiohead",
        MPMediaItemPropertyComposer: "Yorke",
        MPMediaItemPropertyGenre: "Rock",
        MPMediaItemPropertyLyrics: "karma",
        MPMediaItemPropertyComments: "note",
        MPMediaItemPropertyPersistentID: pid,
        MPMediaItemPropertyAlbumPersistentID: UInt64(1),
        MPMediaItemPropertyAlbumArtistPersistentID: UInt64(2),
        MPMediaItemPropertyArtistPersistentID: UInt64(3),
        MPMediaItemPropertyComposerPersistentID: UInt64(4),
        MPMediaItemPropertyGenrePersistentID: UInt64(5),
        MPMediaItemPropertyPodcastPersistentID: UInt64(6),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyPlayCount: 4,
        MPMediaItemPropertySkipCount: 1,
        MPMediaItemPropertyRating: 5,
        MPMediaItemPropertyAlbumTrackNumber: 6,
        MPMediaItemPropertyAlbumTrackCount: 12,
        MPMediaItemPropertyDiscNumber: 1,
        MPMediaItemPropertyDiscCount: 1,
        MPMediaItemPropertyBeatsPerMinute: 75,
        MPMediaItemPropertyBookmarkTime: 1.5,
        MPMediaItemPropertyPlaybackDuration: 260.0,
        MPMediaItemPropertyIsCloudItem: false,
        MPMediaItemPropertyIsCompilation: false,
        MPMediaItemPropertyIsExplicit: false,
        MPMediaItemPropertyIsPreorder: false,
        MPMediaItemPropertyHasProtectedAsset: false,
        MPMediaItemPropertyDateAdded: added,
        MPMediaItemPropertyLastPlayedDate: last,
        MPMediaItemPropertyReleaseDate: released,
        MPMediaItemPropertyPlaybackStoreID: "store",
        MPMediaItemPropertyUserGrouping: "fav",
        MPMediaItemPropertyAssetURL: url,
    ])
    precondition(item.title == "Karma Police")
    precondition(item.artist == "Radiohead")
    precondition(item.albumTitle == "OK Computer")
    precondition(item.albumArtist == "Radiohead")
    precondition(item.composer == "Yorke")
    precondition(item.genre == "Rock")
    precondition(item.lyrics == "karma")
    precondition(item.comments == "note")
    precondition(item.persistentID == 11)
    precondition(item.albumPersistentID == 1)
    precondition(item.albumArtistPersistentID == 2)
    precondition(item.artistPersistentID == 3)
    precondition(item.composerPersistentID == 4)
    precondition(item.genrePersistentID == 5)
    precondition(item.podcastPersistentID == 6)
    precondition(item.mediaType.contains(.music))
    precondition(item.playCount == 4)
    precondition(item.skipCount == 1)
    precondition(item.rating == 5)
    precondition(item.albumTrackNumber == 6)
    precondition(item.albumTrackCount == 12)
    precondition(item.discNumber == 1)
    precondition(item.discCount == 1)
    precondition(item.beatsPerMinute == 75)
    precondition(item.bookmarkTime == 1.5)
    precondition(item.playbackDuration == 260)
    precondition(item.isCloudItem == false)
    precondition(item.isCompilation == false)
    precondition(item.isExplicitItem == false)
    precondition(item.isPreorder == false)
    precondition(item.hasProtectedAsset == false)
    precondition(item.dateAdded == added)
    precondition(item.lastPlayedDate == last)
    precondition(item.releaseDate == released)
    precondition(item.playbackStoreID == "store")
    precondition(item.userGrouping == "fav")
    precondition(item.assetURL == url)
    precondition(item.value(forProperty: MPMediaItemPropertyTitle) as? String == "Karma Police")
    precondition(item["title"] as? String == "Karma Police")
    var enumerated = 0
    item.enumerateValues(forProperties: [MPMediaItemPropertyTitle, MPMediaItemPropertyArtist]) { _, _, _ in
        enumerated += 1
    }
    precondition(enumerated == 2)
    let empty = MPMediaItem()
    precondition(empty.title == nil)
    precondition(empty.persistentID == 0)
    precondition(MPMediaEntity.supportsSecureCoding)
    let copy = empty.copy() as! MPMediaItem
    precondition(copy === empty)
}

func testMediaItemArtwork() {
    let image = UIImage(size: CGSize(width: 10, height: 8))
    let fromImage = MPMediaItemArtwork(image: image)
    precondition(fromImage.bounds.size.width == 10)
    precondition(fromImage.bounds.size.height == 8)
    precondition(fromImage.imageCropRect.size.width == 10)
    let art = MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 80)) { size in
        UIImage(size: size)
    }
    precondition(art.bounds.width == 100 && art.bounds.height == 80)
    let at50 = art.image(at: CGSize(width: 50, height: 40))
    precondition(at50?.size.width == 50 && at50?.size.height == 40)
    let item = MPMediaItem(hostProperties: [MPMediaItemPropertyArtwork: art])
    precondition(item.artwork === art)
    let content = MPContentItem(identifier: "art")
    content.artwork = art
    precondition(content.artwork === art)
}

func testMediaItemCollection() {
    let a = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "A",
        MPMediaItemPropertyMediaType: MPMediaType.music,
    ])
    let b = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "B",
        MPMediaItemPropertyMediaType: MPMediaType.podcast,
    ])
    let collection = MPMediaItemCollection(items: [a, b])
    precondition(collection.count == 2)
    precondition(collection.items.count == 2)
    precondition(collection.representativeItem === a)
    precondition(collection.mediaTypes.contains(.music))
    precondition(collection.mediaTypes.contains(.podcast))
    let section = MPMediaQuerySection(title: "R", range: NSRange(location: 0, length: 2))
    precondition(section.title == "R")
    precondition(section.range.length == 2)
}

func testMediaItemCanFilterAndGroupingMaps() {
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyTitle))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaEntityPropertyPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumTitle))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtist))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyGenre))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyMediaType))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPlayCount))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAssetURL))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumArtist))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyAlbumArtistPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtistPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyComposer))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyComposerPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyDateAdded))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyGenrePersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyHasProtectedAsset))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsCloudItem))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsCompilation))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsExplicit))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyIsPreorder))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPodcastPersistentID))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyPodcastTitle))
    precondition(MPMediaItem.canFilter(byProperty: MPMediaItemPropertyRating))
    precondition(!MPMediaItem.canFilter(byProperty: MPMediaItemPropertyArtwork))
    precondition(!MPMediaItem.canFilter(byProperty: MPMediaItemPropertyLyrics))
    precondition(MPMediaEntity.canFilter(byProperty: MPMediaEntityPropertyPersistentID))
    precondition(!MPMediaEntity.canFilter(byProperty: MPMediaItemPropertyTitle))
    precondition(MPMediaItem.titleProperty(forGroupingType: .title) == MPMediaItemPropertyTitle)
    precondition(MPMediaItem.titleProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumTitle)
    precondition(MPMediaItem.titleProperty(forGroupingType: .artist) == MPMediaItemPropertyArtist)
    precondition(MPMediaItem.titleProperty(forGroupingType: .albumArtist) == MPMediaItemPropertyAlbumArtist)
    precondition(MPMediaItem.titleProperty(forGroupingType: .composer) == MPMediaItemPropertyComposer)
    precondition(MPMediaItem.titleProperty(forGroupingType: .genre) == MPMediaItemPropertyGenre)
    precondition(MPMediaItem.titleProperty(forGroupingType: .playlist) == MPMediaPlaylistPropertyName)
    precondition(MPMediaItem.titleProperty(forGroupingType: .podcastTitle) == MPMediaItemPropertyPodcastTitle)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .title) == MPMediaItemPropertyPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .album) == MPMediaItemPropertyAlbumPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .artist) == MPMediaItemPropertyArtistPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .albumArtist) == MPMediaItemPropertyAlbumArtistPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .composer) == MPMediaItemPropertyComposerPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .genre) == MPMediaItemPropertyGenrePersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .playlist) == MPMediaPlaylistPropertyPersistentID)
    precondition(MPMediaItem.persistentIDProperty(forGroupingType: .podcastTitle) == MPMediaItemPropertyPodcastPersistentID)
}

// --- MPMediaPickerTests.swift ---

final class MPMediaPickerSink: NSObject, MPMediaPickerControllerDelegate {
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

func testMediaPickerDefaults() {
    let sem = DispatchSemaphore(value: 0)
    Task { @MainActor in
        let picker = MPMediaPickerController(mediaTypes: .music)
        precondition(picker.mediaTypes == .music)
        precondition(!picker.allowsPickingMultipleItems)
        precondition(picker.showsCloudItems)
        precondition(picker.showsItemsWithProtectedAssets)
        precondition(picker.prompt == nil)
        let sink = MPMediaPickerSink()
        picker.delegate = sink
        let asDel: any MPMediaPickerControllerDelegate = sink
        asDel.mediaPickerDidCancel(picker)
        asDel.mediaPicker(picker, didPickMediaItems: MPMediaItemCollection(items: []))
        precondition(sink.cancelled == 1 && sink.picked == 1)
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
}

// --- MPMediaQueryTests.swift ---

func testLibraryAuthorization() {
    MPMediaLibrary.openuikit_resetLibrary()
    precondition(MPMediaLibrary.authorizationStatus() == .denied)
    precondition(MPMediaLibrary.default() === MPMediaLibrary.default())
    precondition(MPMediaLibrary.supportsSecureCoding)
    precondition(MPMediaLibrary.default().lastModifiedDate == Date(timeIntervalSince1970: 0))
    MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
    MPMediaLibrary.default().endGeneratingLibraryChangeNotifications()
    precondition(MPMediaQuery.songs().items == nil)

    let sem = DispatchSemaphore(value: 0)
    var seen: MPMediaLibraryAuthorizationStatus?
    var returned = false
    MPMediaLibrary.requestAuthorization { status in
        precondition(returned)
        seen = status
        sem.signal()
    }
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(seen == .denied)

    let addSem = DispatchSemaphore(value: 0)
    var addErr = false
    Task {
        do {
            _ = try await MPMediaLibrary.default().addItem(withProductID: "x")
            fatalError("addItem should fail")
        } catch {
            addErr = MPError.notSupported ~= error
            addSem.signal()
        }
    }
    precondition(addSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(addErr)
}

func testQueryPredicateGroupingFixture() {
    MPMediaLibrary.openuikit_resetLibrary()
    precondition(MPMediaQuery().groupingType == .title)
    precondition(MPMediaQuery.songs().groupingType == .title)
    precondition(MPMediaQuery.albums().groupingType == .album)
    precondition(MPMediaQuery.artists().groupingType == .artist)
    precondition(MPMediaQuery.composers().groupingType == .composer)
    precondition(MPMediaQuery.genres().groupingType == .genre)
    precondition(MPMediaQuery.playlists().groupingType == .playlist)
    precondition(MPMediaQuery.podcasts().groupingType == .podcastTitle)
    precondition(MPMediaQuery.songs().items == nil)

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
    precondition(MPMediaLibrary.authorizationStatus() == .authorized)
    precondition(MPMediaQuery.songs().items?.count == 3)

    let equal = MPMediaPropertyPredicate(value: "Radiohead", forProperty: MPMediaItemPropertyArtist)
    precondition(equal.property == MPMediaItemPropertyArtist)
    precondition(equal.comparisonType == .equalTo)
    let byArtist = MPMediaQuery(filterPredicates: [equal])
    precondition(byArtist.items?.count == 2)
    precondition(byArtist.filterPredicates?.contains(equal) == true)

    let contains = MPMediaPropertyPredicate(
        value: "Police",
        forProperty: MPMediaItemPropertyTitle,
        comparisonType: .contains
    )
    precondition(contains.comparisonType == .contains)
    let byTitle = MPMediaQuery(filterPredicates: [contains])
    precondition(byTitle.items?.count == 1)
    precondition(byTitle.items?.first?.title == "Karma Police")

    let albums = MPMediaQuery.albums()
    precondition(albums.collections?.count == 2)
    precondition(albums.itemSections == nil)
    precondition(albums.collectionSections == nil)

    let audiobooks = MPMediaQuery.audiobooks()
    precondition(audiobooks.filterPredicates?.isEmpty == false)
    let compilations = MPMediaQuery.compilations()
    precondition(compilations.filterPredicates?.isEmpty == false)
    audiobooks.addFilterPredicate(contains)
    audiobooks.removeFilterPredicate(contains)
    let copied = byArtist.copy() as! MPMediaQuery
    precondition(copied.groupingType == byArtist.groupingType)
    precondition(copied.filterPredicates?.count == byArtist.filterPredicates?.count)
    precondition(MPMediaQuery.supportsSecureCoding)
    precondition(MPMediaPredicate.supportsSecureCoding)

    MPMediaLibrary.openuikit_resetLibrary()
    precondition(MPMediaLibrary.authorizationStatus() == .denied)
    precondition(MPMediaQuery.songs().items == nil)
}

func testPlaylistFailClosed() {
    let meta = MPMediaPlaylistCreationMetadata(name: "Mix")
    meta.descriptionText = "x"
    meta.authorDisplayName = "me"
    precondition(meta.name == "Mix")
    precondition(meta.descriptionText == "x")
    precondition(meta.authorDisplayName == "me")
    let item = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "A"])
    let playlist = MPMediaPlaylist(items: [item])
    precondition(playlist.count == 1)
    precondition(playlist.name == nil)
    precondition(playlist.authorDisplayName == nil)
    precondition(playlist.cloudGlobalID == nil)
    precondition(playlist.descriptionText == nil)
    precondition(playlist.seedItems == nil)
    precondition(playlist.playlistAttributes.isEmpty)
    let addSem = DispatchSemaphore(value: 0)
    var addFailed = false
    Task {
        do {
            try await playlist.addItem(withProductID: "x")
            fatalError("playlist addItem should fail")
        } catch {
            addFailed = MPError.notSupported ~= error
        }
        do {
            try await playlist.add([item])
            fatalError("playlist add should fail")
        } catch {
            addFailed = addFailed && (MPError.notSupported ~= error)
            addSem.signal()
        }
    }
    precondition(addSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(addFailed)

    let getSem = DispatchSemaphore(value: 0)
    var getFailed = false
    Task {
        do {
            _ = try await MPMediaLibrary.default().getPlaylist(
                with: UUID(),
                creationMetadata: meta
            )
            fatalError("getPlaylist should fail")
        } catch {
            getFailed = MPError.notSupported ~= error
            getSem.signal()
        }
    }
    precondition(getSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(getFailed)
}

// --- MPMoviePlayerTests.swift ---

func testMoviePlayerFailClosed() {
    let movie = MPMoviePlayerController(contentURL: URL(string: "file://tmp.m4v")!)
    precondition(movie != nil)
    movie?.play()
    precondition(movie?.playbackState == .stopped)
    movie?.controlStyle = .none
    movie?.repeatMode = .one
    movie?.scalingMode = .fill
    movie?.setFullscreen(true, animated: false)
    precondition(movie?.isFullscreen == true)
    movie?.pause()
    movie?.stop()
    movie?.beginSeekingForward()
    movie?.beginSeekingBackward()
    movie?.endSeeking()
    movie?.prepareToPlay()
    precondition(movie?.isPreparedToPlay == false)
    movie?.cancelAllThumbnailImageRequests()
    movie?.requestThumbnailImages(atTimes: [0], timeOption: .exact)
    movie?.allowsAirPlay = true
    precondition(movie?.isAirPlayVideoActive == false)
    movie?.shouldAutoplay = true
    movie?.useApplicationAudioSession = false
    movie?.movieSourceType = .file
    movie?.endPlaybackTime = 10
    movie?.initialPlaybackTime = 1
    movie?.currentPlaybackRate = 1
    movie?.currentPlaybackTime = 0
    _ = movie?.duration
    _ = movie?.playableDuration
    _ = movie?.loadState
    _ = movie?.movieMediaTypes
    _ = movie?.readyForDisplay
    _ = movie?.timedMetadata
    _ = movie?.accessLog.events
    _ = movie?.accessLog.extendedLogData
    _ = movie?.accessLog.extendedLogDataStringEncoding
    _ = movie?.errorLog.events
    _ = movie?.errorLog.extendedLogData
    _ = movie?.errorLog.extendedLogDataStringEncoding
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

// --- MPMusicPlayerTests.swift ---

func testMusicPlayerStateMachine() {
    MPMediaLibrary.openuikit_resetLibrary()
    let player = MPMusicPlayerController.applicationMusicPlayer
    player.stop()
    player.setQueue(with: MPMediaItemCollection(items: []))
    precondition(player.playbackState == .stopped)
    precondition(player.repeatMode == .none)
    precondition(player.shuffleMode == .off)
    precondition(player.currentPlaybackRate == 0)
    precondition(player.currentPlaybackTime == 0)
    precondition(player.indexOfNowPlayingItem == 0)
    precondition(!player.isPreparedToPlay)
    player.play()
    precondition(player.playbackState == .stopped)
    player.prepareToPlay()
    precondition(!player.isPreparedToPlay)

    var returned = false
    let sem = DispatchSemaphore(value: 0)
    var sawError = false
    player.prepareToPlay { error in
        precondition(returned)
        precondition(MPError.notSupported ~= (error ?? MPError(.unknown)))
        sawError = true
        sem.signal()
    }
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(sawError)

    let a = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "One",
        MPMediaItemPropertyPersistentID: UInt64(1),
    ])
    let b = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Two",
        MPMediaItemPropertyPersistentID: UInt64(2),
    ])
    player.setQueue(with: MPMediaItemCollection(items: [a, b]))
    precondition(player.nowPlayingItem === a)
    player.play()
    precondition(player.playbackState == .playing)
    precondition(player.currentPlaybackRate == 1)
    precondition(player.isPreparedToPlay)
    player.pause()
    precondition(player.playbackState == .paused)
    player.play()
    player.beginSeekingForward()
    precondition(player.playbackState == .seekingForward)
    player.endSeeking()
    precondition(player.playbackState == .playing)
    player.beginSeekingBackward()
    precondition(player.playbackState == .seekingBackward)
    player.endSeeking()
    player.skipToNextItem()
    precondition(player.nowPlayingItem === b)
    precondition(player.indexOfNowPlayingItem == 1)
    player.skipToPreviousItem()
    precondition(player.nowPlayingItem === a)
    player.skipToBeginning()
    precondition(player.currentPlaybackTime == 0)
    player.stop()
    precondition(player.playbackState == .stopped)

    let system = MPMusicPlayerController.systemMusicPlayer
    system.openToPlay(MPMusicPlayerStoreQueueDescriptor(storeIDs: ["1"]))
    precondition(system.playbackState == .stopped)
    precondition(
        (MPMusicPlayerController.iPodMusicPlayer as AnyObject)
            === (MPMusicPlayerController.systemMusicPlayer as AnyObject)
    )
    _ = MPMusicPlayerController.applicationQueuePlayer.repeatMode
}

func testMusicPlayerNotifications() {
    let player = MPMusicPlayerController.applicationMusicPlayer
    let a = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "One"])
    let b = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "Two"])
    player.setQueue(with: MPMediaItemCollection(items: [a, b]))
    final class NoteBox: @unchecked Sendable {
        var stateNotes = 0
        var itemNotes = 0
    }
    let box = NoteBox()
    let nc = NotificationCenter.default
    let s1 = nc.addObserver(
        forName: .MPMusicPlayerControllerPlaybackStateDidChange,
        object: player,
        queue: nil
    ) { _ in box.stateNotes += 1 }
    let s2 = nc.addObserver(
        forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
        object: player,
        queue: nil
    ) { _ in box.itemNotes += 1 }
    player.play()
    precondition(box.stateNotes == 0)
    player.beginGeneratingPlaybackNotifications()
    player.play()
    player.skipToNextItem()
    player.stop()
    player.endGeneratingPlaybackNotifications()
    nc.removeObserver(s1)
    nc.removeObserver(s2)
    precondition(box.stateNotes > 0)
    precondition(box.itemNotes > 0)
}

func testMusicPlayerQueueDescriptors() {
    let a = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "One"])
    let b = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "Two"])
    let player = MPMusicPlayerController.applicationMusicPlayer
    let desc = MPMusicPlayerMediaItemQueueDescriptor(
        itemCollection: MPMediaItemCollection(items: [a, b])
    )
    desc.startItem = a
    desc.setStartTime(1, for: a)
    desc.setEndTime(2, for: a)
    precondition(desc.itemCollection.count == 2)
    player.setQueue(with: desc)
    player.append(desc)
    player.prepend(desc)
    player.setQueue(with: MPMediaQuery.songs())
    let qdesc = MPMusicPlayerMediaItemQueueDescriptor(query: MPMediaQuery.songs())
    precondition(qdesc.query.groupingType == .title)
    let store = MPMusicPlayerStoreQueueDescriptor(storeIDs: ["x"])
    store.startItemID = "x"
    store.setStartTime(0, forItemWithStoreID: "x")
    store.setEndTime(1, forItemWithStoreID: "x")
    precondition(store.storeIDs == ["x"])
    player.setQueue(with: store)
    precondition(MPMusicPlayerPlayParameters(dictionary: [:]) == nil)
    let params = MPMusicPlayerPlayParameters(dictionary: ["id": "1"])
    precondition(params != nil)
    precondition(params?.dictionary["id"] as? String == "1")
    let pq = MPMusicPlayerPlayParametersQueueDescriptor(playParametersQueue: [params!])
    pq.startItemPlayParameters = params
    pq.setStartTime(0, forItemWith: params!)
    pq.setEndTime(1, forItemWith: params!)
    precondition(pq.playParametersQueue.count == 1)
    let mutable = MPMusicPlayerControllerMutableQueue()
    mutable.insert(desc, after: a)
    mutable.remove(a)
    _ = mutable.items
    let queue = MPMusicPlayerControllerQueue()
    precondition(queue.items.isEmpty)

    let txSem = DispatchSemaphore(value: 0)
    var txFailed = false
    Task {
        do {
            _ = try await MPMusicPlayerController.applicationQueuePlayer.perform { queue in
                queue.insert(desc, after: nil)
            }
            fatalError("queue transaction should fail closed")
        } catch {
            txFailed = MPError.notSupported ~= error
            txSem.signal()
        }
    }
    precondition(txSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(txFailed)
}

// --- MPNowPlayingInfoKeysTests.swift ---

func testNowPlayingInfoPropertyKeys() {
    let keys: [(String, String)] = [
        (MPNowPlayingInfoCollectionIdentifier, "MPNowPlayingInfoCollectionIdentifier"),
        (MPNowPlayingInfoProperty1x1AnimatedArtwork, "MPNowPlayingInfoProperty1x1AnimatedArtwork"),
        (MPNowPlayingInfoProperty3x4AnimatedArtwork, "MPNowPlayingInfoProperty3x4AnimatedArtwork"),
        (MPNowPlayingInfoPropertyAdTimeRanges, "MPNowPlayingInfoPropertyAdTimeRanges"),
        (MPNowPlayingInfoPropertyAssetURL, "MPNowPlayingInfoPropertyAssetURL"),
        (MPNowPlayingInfoPropertyAvailableLanguageOptions, "MPNowPlayingInfoPropertyAvailableLanguageOptions"),
        (MPNowPlayingInfoPropertyChapterCount, "MPNowPlayingInfoPropertyChapterCount"),
        (MPNowPlayingInfoPropertyChapterNumber, "MPNowPlayingInfoPropertyChapterNumber"),
        (MPNowPlayingInfoPropertyCreditsStartTime, "MPNowPlayingInfoPropertyCreditsStartTime"),
        (MPNowPlayingInfoPropertyCurrentLanguageOptions, "MPNowPlayingInfoPropertyCurrentLanguageOption"),
        (MPNowPlayingInfoPropertyCurrentPlaybackDate, "MPNowPlayingInfoPropertyCurrentPlaybackDate"),
        (MPNowPlayingInfoPropertyDefaultPlaybackRate, "MPNowPlayingInfoPropertyDefaultPlaybackRate"),
        (MPNowPlayingInfoPropertyElapsedPlaybackTime, "MPNowPlayingInfoPropertyElapsedPlaybackTime"),
        (MPNowPlayingInfoPropertyExcludeFromSuggestions, "MPNowPlayingInfoPropertyExcludeFromSuggestions"),
        (MPNowPlayingInfoPropertyExternalContentIdentifier, "MPNowPlayingInfoPropertyExternalContentIdentifier"),
        (MPNowPlayingInfoPropertyExternalUserProfileIdentifier, "MPNowPlayingInfoPropertyExternalUserProfileIdentifier"),
        (MPNowPlayingInfoPropertyInternationalStandardRecordingCode, "MPNowPlayingInfoPropertyInternationalStandardRecordingCode"),
        (MPNowPlayingInfoPropertyIsLiveStream, "MPNowPlayingInfoPropertyIsLiveStream"),
        (MPNowPlayingInfoPropertyMediaType, "MPNowPlayingInfoPropertyMediaType"),
        (MPNowPlayingInfoPropertyPlaybackProgress, "MPNowPlayingInfoPropertyPlaybackProgress"),
        (MPNowPlayingInfoPropertyPlaybackQueueCount, "MPNowPlayingInfoPropertyPlaybackQueueCount"),
        (MPNowPlayingInfoPropertyPlaybackQueueIndex, "MPNowPlayingInfoPropertyPlaybackQueueIndex"),
        (MPNowPlayingInfoPropertyPlaybackRate, "MPNowPlayingInfoPropertyPlaybackRate"),
        (MPNowPlayingInfoPropertyServiceIdentifier, "MPNowPlayingInfoPropertyServiceIdentifier"),
    ]
    for (actual, expected) in keys {
        precondition(actual == expected)
    }
}

func testLanguageOptionCharacteristics() {
    precondition(MPLanguageOptionCharacteristicContainsOnlyForcedSubtitles == "public.subtitles.forced-only")
    precondition(MPLanguageOptionCharacteristicDescribesMusicAndSound == "public.accessibility.describes-music-and-sound")
    precondition(MPLanguageOptionCharacteristicDescribesVideo == "public.accessibility.describes-video")
    precondition(MPLanguageOptionCharacteristicDubbedTranslation == "public.translation.dubbed")
    precondition(MPLanguageOptionCharacteristicEasyToRead == "public.easy-to-read")
    precondition(MPLanguageOptionCharacteristicIsAuxiliaryContent == "public.auxiliary-content")
    precondition(MPLanguageOptionCharacteristicIsMainProgramContent == "public.main-program-content")
    precondition(MPLanguageOptionCharacteristicLanguageTranslation == "public.translation")
    precondition(MPLanguageOptionCharacteristicTranscribesSpokenDialog == "public.accessibility.transcribes-spoken-dialog")
    precondition(MPLanguageOptionCharacteristicVoiceOverTranslation == "public.translation.voice-over")
}

func testNowPlayingInfoCenter() {
    let center = MPNowPlayingInfoCenter.default()
    precondition(center === MPNowPlayingInfoCenter.default())
    center.nowPlayingInfo = [
        MPNowPlayingInfoPropertyPlaybackRate: 1,
        MPMediaItemPropertyTitle: "Song",
        MPNowPlayingInfoPropertyElapsedPlaybackTime: 12,
    ]
    precondition(center.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Int == 1)
    precondition(center.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String == "Song")
    center.playbackState = .paused
    precondition(center.playbackState == .paused)
    precondition(
        MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys == [MPNowPlayingInfoProperty3x4AnimatedArtwork]
    )
}

func testNowPlayingInfoLanguageOption() {
    let lang = MPNowPlayingInfoLanguageOption(
        type: .audible,
        languageTag: "en",
        characteristics: [MPLanguageOptionCharacteristicIsMainProgramContent],
        displayName: "English",
        identifier: "en-aud"
    )
    precondition(lang.languageOptionType == .audible)
    precondition(lang.languageTag == "en")
    precondition(lang.displayName == "English")
    precondition(lang.identifier == "en-aud")
    precondition(lang.languageOptionCharacteristics == [MPLanguageOptionCharacteristicIsMainProgramContent])
    precondition(!lang.isAutomaticAudibleLanguageOption())
    precondition(!lang.isAutomaticLegibleLanguageOption())
    let group = MPNowPlayingInfoLanguageOptionGroup(
        languageOptions: [lang],
        defaultLanguageOption: lang,
        allowEmptySelection: false
    )
    precondition(group.languageOptions.count == 1)
    precondition(group.defaultLanguageOption === lang)
    precondition(group.allowEmptySelection == false)
}

// --- MPNowPlayingSessionTests.swift ---

final class MPNowPlayingSessionSink: NSObject, MPNowPlayingSessionDelegate {
    var active = 0
    var canBecome = 0

    func nowPlayingSessionDidChangeActive(_ nowPlayingSession: MPNowPlayingSession) {
        _ = nowPlayingSession
        active += 1
    }

    func nowPlayingSessionDidChangeCanBecomeActive(_ nowPlayingSession: MPNowPlayingSession) {
        _ = nowPlayingSession
        canBecome += 1
    }
}

func testNowPlayingSessionFailClosed() {
    let session = MPNowPlayingSession()
    precondition(!session.canBecomeActive)
    precondition(!session.isActive)
    _ = session.nowPlayingInfoCenter
    _ = session.remoteCommandCenter
    session.automaticallyPublishesNowPlayingInfo = true
    let sink = MPNowPlayingSessionSink()
    session.delegate = sink
    let asDel: any MPNowPlayingSessionDelegate = sink
    asDel.nowPlayingSessionDidChangeActive(session)
    asDel.nowPlayingSessionDidChangeCanBecomeActive(session)
    precondition(sink.active == 1 && sink.canBecome == 1)
    let sem = DispatchSemaphore(value: 0)
    var became = true
    var returned = false
    session.becomeActiveIfPossible { ok in
        precondition(returned)
        became = ok
        sem.signal()
    }
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(became == false)
    precondition(!session.isActive)
}

// --- MPPlayableContentTests.swift ---

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

// --- MPRemoteCommandTests.swift ---

final class MPRemoteCommandSelectorTarget: NSObject {
    var count = 0
    func handle(_ event: MPRemoteCommandEvent) {
        count += 1
        _ = event
    }
}

func mpExerciseRemoteCommand(_ command: MPRemoteCommand) {
    command.removeTarget(nil)
    command.isEnabled = true
    var ran = false
    let token = command.addTarget { event in
        ran = true
        _ = event
        return .success
    }
    let status = command.openuikit_invoke(MPRemoteCommandEvent(command: command))
    precondition(ran)
    precondition(status == .success)
    command.removeTarget(token)
    command.isEnabled = false
    let disabled = command.openuikit_invoke(MPRemoteCommandEvent(command: command))
    precondition(disabled == .commandFailed)
    command.isEnabled = true
    let empty = command.openuikit_invoke(MPRemoteCommandEvent(command: command))
    precondition(empty == .noActionableNowPlayingItem)
}

func testPlayCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.playCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testPauseCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.pauseCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testStopCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.stopCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testTogglePlayPauseCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.togglePlayPauseCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testNextTrackCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.nextTrackCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testPreviousTrackCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.previousTrackCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testLikeCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.likeCommand
    precondition(command.isEnabled)
    command.isActive = true
    command.localizedTitle = "Title"
    command.localizedShortTitle = "T"
    precondition(command.isActive)
    precondition(command.localizedTitle == "Title")
    precondition(command.localizedShortTitle == "T")
    mpExerciseRemoteCommand(command)
}

func testDislikeCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.dislikeCommand
    precondition(command.isEnabled)
    command.isActive = true
    command.localizedTitle = "Title"
    command.localizedShortTitle = "T"
    precondition(command.isActive)
    precondition(command.localizedTitle == "Title")
    precondition(command.localizedShortTitle == "T")
    mpExerciseRemoteCommand(command)
}

func testBookmarkCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.bookmarkCommand
    precondition(command.isEnabled)
    command.isActive = true
    command.localizedTitle = "Title"
    command.localizedShortTitle = "T"
    precondition(command.isActive)
    precondition(command.localizedTitle == "Title")
    precondition(command.localizedShortTitle == "T")
    mpExerciseRemoteCommand(command)
}

func testSkipForwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.skipForwardCommand
    precondition(command.isEnabled)
    precondition(command.preferredIntervals.first?.doubleValue == 10)
    mpExerciseRemoteCommand(command)
}

func testSkipBackwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.skipBackwardCommand
    precondition(command.isEnabled)
    precondition(command.preferredIntervals.first?.doubleValue == 10)
    mpExerciseRemoteCommand(command)
}

func testSeekForwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.seekForwardCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testSeekBackwardCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.seekBackwardCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testRatingCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.ratingCommand
    precondition(command.isEnabled)
    precondition(command.minimumRating == 0)
    precondition(command.maximumRating == 0)
    mpExerciseRemoteCommand(command)
}

func testChangePlaybackPositionCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.changePlaybackPositionCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testChangePlaybackRateCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.changePlaybackRateCommand
    precondition(command.isEnabled)
    precondition(command.supportedPlaybackRates.isEmpty)
    mpExerciseRemoteCommand(command)
}

func testChangeRepeatModeCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.changeRepeatModeCommand
    precondition(command.isEnabled)
    precondition(command.currentRepeatType == .off)
    mpExerciseRemoteCommand(command)
}

func testChangeShuffleModeCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.changeShuffleModeCommand
    precondition(command.isEnabled)
    precondition(command.currentShuffleType == .off)
    mpExerciseRemoteCommand(command)
}

func testEnableLanguageOptionCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.enableLanguageOptionCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testDisableLanguageOptionCommand() {
    let commands = MPRemoteCommandCenter.shared()
    let command = commands.disableLanguageOptionCommand
    precondition(command.isEnabled)
    mpExerciseRemoteCommand(command)
}

func testRemoteCommandCenterShared() {
    precondition(MPRemoteCommandCenter.shared() === MPRemoteCommandCenter.shared())
}

func testRemoteCommandEvents() {
    let commands = MPRemoteCommandCenter.shared()
    let pos = MPChangePlaybackPositionCommandEvent(
        command: commands.changePlaybackPositionCommand,
        positionTime: 12
    )
    precondition(pos.positionTime == 12)
    let rate = MPChangePlaybackRateCommandEvent(
        command: commands.changePlaybackRateCommand,
        playbackRate: 1.5
    )
    precondition(rate.playbackRate == 1.5)
    let rep = MPChangeRepeatModeCommandEvent(
        command: commands.changeRepeatModeCommand,
        repeatType: .all,
        preservesRepeatMode: true
    )
    precondition(rep.repeatType == .all && rep.preservesRepeatMode)
    let shu = MPChangeShuffleModeCommandEvent(
        command: commands.changeShuffleModeCommand,
        shuffleType: .items,
        preservesShuffleMode: false
    )
    precondition(shu.shuffleType == .items)
    let lang = MPNowPlayingInfoLanguageOption(
        type: .legible, languageTag: "en", characteristics: nil,
        displayName: "EN", identifier: "en"
    )
    let langEv = MPChangeLanguageOptionCommandEvent(
        command: commands.enableLanguageOptionCommand,
        languageOption: lang,
        setting: .nowPlayingItemOnly
    )
    precondition(langEv.setting == .nowPlayingItemOnly)
    precondition(langEv.languageOption === lang)
    let fb = MPFeedbackCommandEvent(command: commands.likeCommand, isNegative: true)
    precondition(fb.isNegative)
    let rating = MPRatingCommandEvent(command: commands.ratingCommand, rating: 4)
    precondition(rating.rating == 4)
    let seek = MPSeekCommandEvent(command: commands.seekForwardCommand, type: .endSeeking)
    precondition(seek.type == .endSeeking)
    let skip = MPSkipIntervalCommandEvent(command: commands.skipForwardCommand, interval: 10)
    precondition(skip.interval == 10)
    precondition(skip.command === commands.skipForwardCommand)
    _ = skip.timestamp

    let target = MPRemoteCommandSelectorTarget()
    let selector = Selector("handle:")
    commands.pauseCommand.removeTarget(nil)
    commands.pauseCommand.addTarget(target, action: selector)
    let invoked = commands.pauseCommand.openuikit_invoke(MPRemoteCommandEvent(command: commands.pauseCommand))
    precondition(invoked == .commandFailed)
    commands.pauseCommand.removeTarget(target, action: selector)
    let empty = commands.pauseCommand.openuikit_invoke(MPRemoteCommandEvent(command: commands.pauseCommand))
    precondition(empty == .noActionableNowPlayingItem)
}


// --- MPVolumeViewTests.swift ---

func testVolumeSettingsAlert() {
    precondition(!MPVolumeSettingsAlertIsVisible())
    MPVolumeSettingsAlertShow()
    precondition(!MPVolumeSettingsAlertIsVisible())
    MPVolumeSettingsAlertHide()
    precondition(!MPVolumeSettingsAlertIsVisible())
}

func testVolumeViewFailClosed() {
    let sem = DispatchSemaphore(value: 0)
    var failed = false
    Task { @MainActor in
        let vol = MPVolumeView()
        precondition(vol.frame == .zero)
        precondition(!vol.showsRouteButton)
        precondition(vol.showsVolumeSlider)
        precondition(!vol.isWirelessRouteActive)
        precondition(!vol.areWirelessRoutesAvailable)
        precondition(vol.volumeSliderRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 44)) == .zero)
        precondition(vol.routeButtonRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 44)) == .zero)
        precondition(vol.volumeThumbRect(forBounds: .zero, volumeSliderRect: .zero, value: 0) == .zero)
        precondition(vol.maximumVolumeSliderImage(for: .normal) == nil)
        precondition(vol.minimumVolumeSliderImage(for: .normal) == nil)
        precondition(vol.routeButtonImage(for: .normal) == nil)
        precondition(vol.volumeThumbImage(for: .normal) == nil)
        vol.setMaximumVolumeSliderImage(nil, for: .normal)
        vol.setMinimumVolumeSliderImage(nil, for: .normal)
        vol.setRouteButtonImage(nil, for: .highlighted)
        vol.setVolumeThumbImage(nil, for: .selected)
        vol.volumeWarningSliderImage = nil
        let sized = MPVolumeView(frame: CGRect(x: 10, y: 20, width: 300, height: 40))
        precondition(sized.frame.width == 300)
        failed = false
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    _ = failed
}

private func mpRunFocusedTests() {
    testEnumRawValues()
    testOptionSetBits()
    testMPErrorCodes()
    testMediaItemPropertyKeys()
    testNotificationNames()
    testMovieUserInfoKeys()
    testMediaItemProperties()
    testMediaItemArtwork()
    testMediaItemCollection()
    testMediaItemCanFilterAndGroupingMaps()
    testMediaPickerDefaults()
    testLibraryAuthorization()
    testQueryPredicateGroupingFixture()
    testPlaylistFailClosed()
    testMoviePlayerFailClosed()
    testMusicPlayerStateMachine()
    testMusicPlayerNotifications()
    testMusicPlayerQueueDescriptors()
    testNowPlayingInfoPropertyKeys()
    testLanguageOptionCharacteristics()
    testNowPlayingInfoCenter()
    testNowPlayingInfoLanguageOption()
    testNowPlayingSessionFailClosed()
    testContentItemProperties()
    testPlayableContentFailClosed()
    testPlayCommand()
    testPauseCommand()
    testStopCommand()
    testTogglePlayPauseCommand()
    testNextTrackCommand()
    testPreviousTrackCommand()
    testLikeCommand()
    testDislikeCommand()
    testBookmarkCommand()
    testSkipForwardCommand()
    testSkipBackwardCommand()
    testSeekForwardCommand()
    testSeekBackwardCommand()
    testRatingCommand()
    testChangePlaybackPositionCommand()
    testChangePlaybackRateCommand()
    testChangeRepeatModeCommand()
    testChangeShuffleModeCommand()
    testEnableLanguageOptionCommand()
    testDisableLanguageOptionCommand()
    testRemoteCommandCenterShared()
    testRemoteCommandEvents()
    testVolumeSettingsAlert()
    testVolumeViewFailClosed()
}

print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
let mpGroup = DispatchGroup()
mpGroup.enter()
Task {
    mpRunFocusedTests()
    mpGroup.leave()
}
while mpGroup.wait(timeout: .now() + .milliseconds(50)) == .timedOut {
    _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
}
print("MEDIAPLAYER_AGENT_RUNTIME_OK")
