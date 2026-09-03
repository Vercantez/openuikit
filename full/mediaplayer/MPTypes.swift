import Foundation

public enum MPChangeLanguageOptionSetting: Int, Hashable, Sendable {
    case none = 0
    case nowPlayingItemOnly = 1
    case permanent = 2
}

public enum MPMediaGrouping: Int, Hashable, Sendable {
    case title = 0
    case album = 1
    case artist = 2
    case albumArtist = 3
    case composer = 4
    case genre = 5
    case playlist = 6
    case podcastTitle = 7
}

public enum MPMediaLibraryAuthorizationStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case denied = 1
    case restricted = 2
    case authorized = 3
}

public struct MPMediaPlaylistAttribute: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let onTheGo = MPMediaPlaylistAttribute(rawValue: 1 << 0)
    public static let smart = MPMediaPlaylistAttribute(rawValue: 1 << 1)
    public static let genius = MPMediaPlaylistAttribute(rawValue: 1 << 2)
}

public enum MPMediaPredicateComparison: Int, Hashable, Sendable {
    case equalTo = 0
    case contains = 1
}

public struct MPMediaType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let music = MPMediaType(rawValue: 1 << 0)
    public static let podcast = MPMediaType(rawValue: 1 << 1)
    public static let audioBook = MPMediaType(rawValue: 1 << 2)
    public static let audioITunesU = MPMediaType(rawValue: 1 << 3)
    public static let anyAudio = MPMediaType(rawValue: 0x00ff)
    public static let movie = MPMediaType(rawValue: 1 << 8)
    public static let tvShow = MPMediaType(rawValue: 1 << 9)
    public static let videoPodcast = MPMediaType(rawValue: 1 << 10)
    public static let musicVideo = MPMediaType(rawValue: 1 << 11)
    public static let videoITunesU = MPMediaType(rawValue: 1 << 12)
    public static let homeVideo = MPMediaType(rawValue: 1 << 13)
    public static let anyVideo = MPMediaType(rawValue: 0xff00)
    public static let any = MPMediaType(rawValue: UInt.max)
}

public enum MPMovieControlStyle: Int, Hashable, Sendable {
    case none = 0
    case embedded = 1
    case fullscreen = 2

    public static var `default`: MPMovieControlStyle { .fullscreen }
}

public enum MPMovieFinishReason: Int, Hashable, Sendable {
    case playbackEnded = 0
    case playbackError = 1
    case userExited = 2
}

public struct MPMovieLoadState: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let playable = MPMovieLoadState(rawValue: 1 << 0)
    public static let playthroughOK = MPMovieLoadState(rawValue: 1 << 1)
    public static let stalled = MPMovieLoadState(rawValue: 1 << 2)
}

public struct MPMovieMediaTypeMask: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let video = MPMovieMediaTypeMask(rawValue: 1 << 0)
    public static let audio = MPMovieMediaTypeMask(rawValue: 1 << 1)
}

public enum MPMoviePlaybackState: Int, Hashable, Sendable {
    case stopped = 0
    case playing = 1
    case paused = 2
    case interrupted = 3
    case seekingForward = 4
    case seekingBackward = 5
}

public enum MPMovieRepeatMode: Int, Hashable, Sendable {
    case none = 0
    case one = 1
}

public enum MPMovieScalingMode: Int, Hashable, Sendable {
    case none = 0
    case aspectFit = 1
    case aspectFill = 2
    case fill = 3
}

public enum MPMovieSourceType: Int, Hashable, Sendable {
    case unknown = 0
    case file = 1
    case streaming = 2
}

public enum MPMovieTimeOption: Int, Hashable, Sendable {
    case nearestKeyFrame = 0
    case exact = 1
}

public enum MPMusicPlaybackState: Int, Hashable, Sendable {
    case stopped = 0
    case playing = 1
    case paused = 2
    case interrupted = 3
    case seekingForward = 4
    case seekingBackward = 5
}

public enum MPMusicRepeatMode: Int, Hashable, Sendable {
    case `default` = 0
    case none = 1
    case one = 2
    case all = 3
}

public enum MPMusicShuffleMode: Int, Hashable, Sendable {
    case `default` = 0
    case off = 1
    case songs = 2
    case albums = 3
}

public enum MPNowPlayingInfoLanguageOptionType: UInt, Hashable, Sendable {
    case audible = 0
    case legible = 1
}

public enum MPNowPlayingInfoMediaType: UInt, Hashable, Sendable {
    case none = 0
    case audio = 1
    case video = 2
}

public enum MPNowPlayingPlaybackState: UInt, Hashable, Sendable {
    case unknown = 0
    case playing = 1
    case paused = 2
    case stopped = 3
    case interrupted = 4
}

public enum MPRemoteCommandHandlerStatus: Int, Hashable, Sendable {
    case success = 0
    case noSuchContent = 100
    case noActionableNowPlayingItem = 110
    case deviceNotFound = 120
    case commandFailed = 200
}

public enum MPRepeatType: Int, Hashable, Sendable {
    case off = 0
    case one = 1
    case all = 2
}

public enum MPSeekCommandEventType: UInt, Hashable, Sendable {
    case beginSeeking = 0
    case endSeeking = 1
}

public enum MPShuffleType: Int, Hashable, Sendable {
    case off = 0
    case items = 1
    case collections = 2
}
