import Foundation

open class MPRemoteCommandEvent: NSObject {
    public let timestamp: TimeInterval
    public let command: MPRemoteCommand

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0) {
        self.command = command
        self.timestamp = timestamp
    }
}

private final class MPRemoteHandlerToken: NSObject {
    let id: Int
    init(id: Int) { self.id = id }
}

open class MPRemoteCommand: NSObject {
    public var isEnabled: Bool = true
    private var handlers: [(Int, (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus)] = []
    private var nextID = 1
    private var targetActions: [(target: AnyObject, action: Selector)] = []

    public func addTarget(handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) -> Any {
        let id = nextID
        nextID += 1
        handlers.append((id, handler))
        return MPRemoteHandlerToken(id: id)
    }

    public func addTarget(_ target: Any, action: Selector) {
        guard let object = target as AnyObject? else { return }
        targetActions.append((object, action))
    }

    public func removeTarget(_ target: Any?) {
        if target == nil {
            handlers.removeAll()
            targetActions.removeAll()
            return
        }
        if let token = target as? MPRemoteHandlerToken {
            handlers.removeAll { $0.0 == token.id }
            return
        }
        if let object = target as AnyObject? {
            targetActions.removeAll { $0.target === object }
        }
    }

    public func removeTarget(_ target: Any, action: Selector?) {
        let object = target as AnyObject
        if let action {
            targetActions.removeAll { $0.target === object && $0.action == action }
        } else {
            targetActions.removeAll { $0.target === object }
        }
    }

    /// In-process dispatch. Apple never delivers events here; Linux has no
    /// Now Playing command center. Handlers and `addTarget(_:action:)` fire
    /// in registration order. MEASURED handler statuses: success=0,
    /// noSuchContent=100, noActionableNowPlayingItem=110, deviceNotFound=120,
    /// commandFailed=200 (`/tmp/mp_oracle.json`, iOS 26.1).
    @_spi(OpenUIKitHost)
    public func openuikit_invoke(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if !isEnabled {
            return .commandFailed
        }
        var status = MPRemoteCommandHandlerStatus.commandFailed
        var ran = false
        for (_, handler) in handlers {
            status = handler(event)
            ran = true
        }
        for pair in targetActions {
            ran = true
            if let object = pair.target as? NSObject {
                _ = object.perform(pair.action, with: event)
            }
        }
        if !ran {
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
    /// MEASURED empty at rest (`/tmp/mp_oracle.json`).
    public var supportedPlaybackRates: [NSNumber] = []
}

open class MPChangeRepeatModeCommand: MPRemoteCommand {
    public var currentRepeatType: MPRepeatType = .off
}

open class MPChangeShuffleModeCommand: MPRemoteCommand {
    public var currentShuffleType: MPShuffleType = .off
}

open class MPRatingCommand: MPRemoteCommand {
    /// MEASURED min=0 max=0 at rest (`/tmp/mp_oracle.json`).
    public var minimumRating: Float = 0
    public var maximumRating: Float = 0
}

open class MPSkipIntervalCommand: MPRemoteCommand {
    /// MEASURED preferredIntervals `[10]` (`/tmp/mp_oracle.json` iOS 26.1).
    public var preferredIntervals: [NSNumber] = [10]
}

open class MPChangePlaybackPositionCommandEvent: MPRemoteCommandEvent {
    public var positionTime: TimeInterval = 0

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0, positionTime: TimeInterval) {
        self.positionTime = positionTime
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangePlaybackRateCommandEvent: MPRemoteCommandEvent {
    public var playbackRate: Float = 1

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0, playbackRate: Float) {
        self.playbackRate = playbackRate
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangeRepeatModeCommandEvent: MPRemoteCommandEvent {
    public var repeatType: MPRepeatType = .off
    public var preservesRepeatMode: Bool = false

    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        repeatType: MPRepeatType,
        preservesRepeatMode: Bool
    ) {
        self.repeatType = repeatType
        self.preservesRepeatMode = preservesRepeatMode
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangeShuffleModeCommandEvent: MPRemoteCommandEvent {
    public var shuffleType: MPShuffleType = .off
    public var preservesShuffleMode: Bool = false

    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        shuffleType: MPShuffleType,
        preservesShuffleMode: Bool
    ) {
        self.shuffleType = shuffleType
        self.preservesShuffleMode = preservesShuffleMode
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangeLanguageOptionCommandEvent: MPRemoteCommandEvent {
    public var languageOption: MPNowPlayingInfoLanguageOption?
    public var setting: MPChangeLanguageOptionSetting = .none

    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        languageOption: MPNowPlayingInfoLanguageOption?,
        setting: MPChangeLanguageOptionSetting
    ) {
        self.languageOption = languageOption
        self.setting = setting
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPFeedbackCommandEvent: MPRemoteCommandEvent {
    public var isNegative: Bool = false

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0, isNegative: Bool) {
        self.isNegative = isNegative
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPRatingCommandEvent: MPRemoteCommandEvent {
    public var rating: Float = 0

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0, rating: Float) {
        self.rating = rating
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPSeekCommandEvent: MPRemoteCommandEvent {
    public var type: MPSeekCommandEventType = .beginSeeking

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0, type: MPSeekCommandEventType) {
        self.type = type
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPSkipIntervalCommandEvent: MPRemoteCommandEvent {
    public var interval: TimeInterval = 0

    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0, interval: TimeInterval) {
        self.interval = interval
        super.init(command: command, timestamp: timestamp)
    }
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
