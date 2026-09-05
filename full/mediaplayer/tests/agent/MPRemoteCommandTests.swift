import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

final class MPRemoteCommandSelectorTarget: NSObject {
    var count = 0
    @objc func handle(_ event: MPRemoteCommandEvent) {
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
    commands.pauseCommand.addTarget(target, action: #selector(MPRemoteCommandSelectorTarget.handle(_:)))
    _ = commands.pauseCommand.openuikit_invoke(MPRemoteCommandEvent(command: commands.pauseCommand))
    precondition(target.count == 1)
    commands.pauseCommand.removeTarget(target, action: #selector(MPRemoteCommandSelectorTarget.handle(_:)))
    _ = commands.pauseCommand.openuikit_invoke(MPRemoteCommandEvent(command: commands.pauseCommand))
    precondition(target.count == 1)
}

