import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

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
