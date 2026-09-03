import Foundation

open class MPRemoteCommandEvent: NSObject {
    public let timestamp: TimeInterval
    public let command: MPRemoteCommand

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0) {
        self.command = command
        self.timestamp = timestamp
    }
}

open class MPRemoteCommand: NSObject {
    public var isEnabled: Bool = true
    private var handlers: [(MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus] = []

    public func addTarget(handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) -> Any {
        handlers.append(handler)
        return handlers.count
    }

    public func removeTarget(_ target: Any?) {
        _ = target
        if target == nil {
            handlers.removeAll()
        }
    }

    /// Host injection. Apple never delivers events here; Linux has no Now Playing command center.
    @_spi(OpenUIKitHost)
    public func openuikit_invoke(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        var status = MPRemoteCommandHandlerStatus.commandFailed
        for handler in handlers {
            status = handler(event)
        }
        if handlers.isEmpty {
            return .noActionableNowPlayingItem
        }
        return status
    }
}

open class MPFeedbackCommand: MPRemoteCommand {
    public var isActive: Bool = false
    public var localizedTitle: String = ""
    public var localizedShortTitle: String = ""
}

open class MPChangePlaybackPositionCommand: MPRemoteCommand {}

open class MPChangePlaybackRateCommand: MPRemoteCommand {
    public var supportedPlaybackRates: [NSNumber] = []
}

open class MPChangeRepeatModeCommand: MPRemoteCommand {
    public var currentRepeatType: MPRepeatType = .off
}

open class MPChangeShuffleModeCommand: MPRemoteCommand {
    public var currentShuffleType: MPShuffleType = .off
}

open class MPRatingCommand: MPRemoteCommand {
    public var minimumRating: Float = 0
    public var maximumRating: Float = 5
}

open class MPSkipIntervalCommand: MPRemoteCommand {
    public var preferredIntervals: [NSNumber] = [15]
}

open class MPChangePlaybackPositionCommandEvent: MPRemoteCommandEvent {
    public var positionTime: TimeInterval = 0
}

open class MPChangePlaybackRateCommandEvent: MPRemoteCommandEvent {
    public var playbackRate: Float = 1
}

open class MPChangeRepeatModeCommandEvent: MPRemoteCommandEvent {
    public var repeatType: MPRepeatType = .off
    public var preservesRepeatMode: Bool = false
}

open class MPChangeShuffleModeCommandEvent: MPRemoteCommandEvent {
    public var shuffleType: MPShuffleType = .off
    public var preservesShuffleMode: Bool = false
}

open class MPChangeLanguageOptionCommandEvent: MPRemoteCommandEvent {
    public var languageOption: MPNowPlayingInfoLanguageOption?
    public var setting: MPChangeLanguageOptionSetting = .none
}

open class MPFeedbackCommandEvent: MPRemoteCommandEvent {
    public var isNegative: Bool = false
}

open class MPRatingCommandEvent: MPRemoteCommandEvent {
    public var rating: Float = 0
}

open class MPSeekCommandEvent: MPRemoteCommandEvent {
    public var type: MPSeekCommandEventType = .beginSeeking
}

open class MPSkipIntervalCommandEvent: MPRemoteCommandEvent {
    public var interval: TimeInterval = 0
}

open class MPRemoteCommandCenter: NSObject {
    private static let sharedCenter = MPRemoteCommandCenter()

    public let bookmarkCommand = MPFeedbackCommand()
    public let changePlaybackPositionCommand = MPChangePlaybackPositionCommand()
    public let changePlaybackRateCommand = MPChangePlaybackRateCommand()
    public let changeRepeatModeCommand = MPChangeRepeatModeCommand()
    public let changeShuffleModeCommand = MPChangeShuffleModeCommand()
    public let disableLanguageOptionCommand = MPRemoteCommand()
    public let dislikeCommand = MPFeedbackCommand()
    public let enableLanguageOptionCommand = MPRemoteCommand()
    public let likeCommand = MPFeedbackCommand()
    public let nextTrackCommand = MPRemoteCommand()
    public let pauseCommand = MPRemoteCommand()
    public let playCommand = MPRemoteCommand()
    public let previousTrackCommand = MPRemoteCommand()
    public let ratingCommand = MPRatingCommand()
    public let seekBackwardCommand = MPRemoteCommand()
    public let seekForwardCommand = MPRemoteCommand()
    public let skipBackwardCommand = MPSkipIntervalCommand()
    public let skipForwardCommand = MPSkipIntervalCommand()
    public let stopCommand = MPRemoteCommand()
    public let togglePlayPauseCommand = MPRemoteCommand()

    public class func shared() -> MPRemoteCommandCenter { sharedCenter }
}
