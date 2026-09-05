import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

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
