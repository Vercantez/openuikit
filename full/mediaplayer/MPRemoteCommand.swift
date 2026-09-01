import Foundation

private final class _MPRemoteCommandHandlerToken: NSObject {
    let uuid = UUID()
    let handler: (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus

    init(handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
        self.handler = handler
    }
}

/// Local command object. Linux has no Control Center, headset, or CarPlay
/// transport; handlers run only when `_openUIKit_deliver` is called.
open class MPRemoteCommand: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var _isEnabled = false
    private var handlers: [_MPRemoteCommandHandlerToken] = []

    public override init() {
        super.init()
    }

    open var isEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isEnabled
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isEnabled = newValue
        }
    }

    @discardableResult
    open func addTarget(
        handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) -> Any {
        let token = _MPRemoteCommandHandlerToken(handler: handler)
        lock.lock()
        handlers.append(token)
        lock.unlock()
        return token
    }

    open func removeTarget(_ target: Any?) {
        lock.lock()
        defer { lock.unlock() }
        if target == nil {
            handlers.removeAll()
            return
        }
        if let token = target as? _MPRemoteCommandHandlerToken {
            handlers.removeAll { $0.uuid == token.uuid }
        }
    }

    /// Deliver an in-process event to registered handlers. System remote
    /// events are not received on Linux.
    @_spi(OpenUIKitHost)
    public func _openUIKit_deliver(
        _ event: MPRemoteCommandEvent
    ) -> MPRemoteCommandHandlerStatus {
        lock.lock()
        let enabled = _isEnabled
        let snapshot = handlers
        lock.unlock()
        guard enabled else { return .commandFailed }
        guard !snapshot.isEmpty else { return .commandFailed }
        var status = MPRemoteCommandHandlerStatus.commandFailed
        for token in snapshot {
            status = token.handler(event)
        }
        return status
    }
}

open class MPChangePlaybackPositionCommand: MPRemoteCommand, @unchecked Sendable {}

open class MPChangePlaybackRateCommand: MPRemoteCommand, @unchecked Sendable {
    open var supportedPlaybackRates: [NSNumber] = []
}

open class MPChangeRepeatModeCommand: MPRemoteCommand, @unchecked Sendable {
    open var currentRepeatType: MPRepeatType = .off
}

open class MPChangeShuffleModeCommand: MPRemoteCommand, @unchecked Sendable {
    open var currentShuffleType: MPShuffleType = .off
}

open class MPFeedbackCommand: MPRemoteCommand, @unchecked Sendable {
    open var isActive = false
    open var localizedTitle = ""
    open var localizedShortTitle = ""
}

open class MPRatingCommand: MPRemoteCommand, @unchecked Sendable {
    open var minimumRating: Float = 0
    open var maximumRating: Float = 5
}

open class MPSkipIntervalCommand: MPRemoteCommand, @unchecked Sendable {
    open var preferredIntervals: [NSNumber] = [15]
}

open class MPRemoteCommandEvent: NSObject, @unchecked Sendable {
    public let command: MPRemoteCommand
    public let timestamp: TimeInterval

    @_spi(OpenUIKitHost)
    public init(command: MPRemoteCommand, timestamp: TimeInterval = 0) {
        self.command = command
        self.timestamp = timestamp
        super.init()
    }
}

open class MPChangeLanguageOptionCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let languageOption: MPNowPlayingInfoLanguageOption
    public let setting: MPChangeLanguageOptionSetting

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        languageOption: MPNowPlayingInfoLanguageOption,
        setting: MPChangeLanguageOptionSetting
    ) {
        self.languageOption = languageOption
        self.setting = setting
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangePlaybackPositionCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let positionTime: TimeInterval

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        positionTime: TimeInterval
    ) {
        self.positionTime = positionTime
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangePlaybackRateCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let playbackRate: Float

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        playbackRate: Float
    ) {
        self.playbackRate = playbackRate
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPChangeRepeatModeCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let preservesRepeatMode: Bool
    public let repeatType: MPRepeatType

    @_spi(OpenUIKitHost)
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

open class MPChangeShuffleModeCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let preservesShuffleMode: Bool
    public let shuffleType: MPShuffleType

    @_spi(OpenUIKitHost)
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

open class MPFeedbackCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let isNegative: Bool

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        isNegative: Bool
    ) {
        self.isNegative = isNegative
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPRatingCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let rating: Float

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        rating: Float
    ) {
        self.rating = rating
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPSeekCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let type: MPSeekCommandEventType

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        type: MPSeekCommandEventType
    ) {
        self.type = type
        super.init(command: command, timestamp: timestamp)
    }
}

open class MPSkipIntervalCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public let interval: TimeInterval

    @_spi(OpenUIKitHost)
    public init(
        command: MPRemoteCommand,
        timestamp: TimeInterval = 0,
        interval: TimeInterval
    ) {
        self.interval = interval
        super.init(command: command, timestamp: timestamp)
    }
}

/// Shared in-process command center used by VLC, Pocket Casts, and Telegram.
/// Commands never receive Apple remote-control events.
open class MPRemoteCommandCenter: NSObject, @unchecked Sendable {
    private static let _shared = MPRemoteCommandCenter()

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

    public override init() {
        super.init()
    }

    open class func shared() -> MPRemoteCommandCenter {
        _shared
    }
}
