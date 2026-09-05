import Foundation

// Raw values MEASURED /tmp/mp_oracle.json, iPhone SE 3rd gen 2x / iOS 26.1
// (com.openuikit.mporacle, OpenUIKit-2x-fw-mediaplayer).

public enum MPChangeLanguageOptionSetting: Int, Sendable, Hashable {
    case none = 0
    case nowPlayingItemOnly = 1
    case permanent = 2
}

public enum MPMediaGrouping: Int, Sendable, Hashable {
    case title = 0
    case album = 1
    case artist = 2
    case albumArtist = 3
    case composer = 4
    case genre = 5
    case playlist = 6
    case podcastTitle = 7
}

public enum MPMediaLibraryAuthorizationStatus: Int, Sendable, Hashable {
    case notDetermined = 0
    case denied = 1
    case restricted = 2
    case authorized = 3
}

public enum MPMediaPredicateComparison: Int, Sendable, Hashable {
    case equalTo = 0
    case contains = 1
}

public enum MPMovieControlStyle: Int, Sendable, Hashable {
    case none = 0
    case embedded = 1
    case fullscreen = 2
}

public enum MPMovieFinishReason: Int, Sendable, Hashable {
    case playbackEnded = 0
    case playbackError = 1
    case userExited = 2
}

public enum MPMoviePlaybackState: Int, Sendable, Hashable {
    case stopped = 0
    case playing = 1
    case paused = 2
    case interrupted = 3
    case seekingForward = 4
    case seekingBackward = 5
}

public enum MPMovieRepeatMode: Int, Sendable, Hashable {
    case none = 0
    case one = 1
}

public enum MPMovieScalingMode: Int, Sendable, Hashable {
    case none = 0
    case aspectFit = 1
    case aspectFill = 2
    case fill = 3
}

public enum MPMovieSourceType: Int, Sendable, Hashable {
    case unknown = 0
    case file = 1
    case streaming = 2
}

public enum MPMovieTimeOption: Int, Sendable, Hashable {
    case nearestKeyFrame = 0
    case exact = 1
}

public enum MPMusicPlaybackState: Int, Sendable, Hashable {
    case stopped = 0
    case playing = 1
    case paused = 2
    case interrupted = 3
    case seekingForward = 4
    case seekingBackward = 5
}

public enum MPMusicRepeatMode: Int, Sendable, Hashable {
    case `default` = 0
    case none = 1
    case one = 2
    case all = 3
}

public enum MPMusicShuffleMode: Int, Sendable, Hashable {
    case `default` = 0
    case off = 1
    case songs = 2
    case albums = 3
}

public enum MPNowPlayingInfoLanguageOptionType: UInt, Sendable, Hashable {
    case audible = 0
    case legible = 1
}

public enum MPNowPlayingInfoMediaType: UInt, Sendable, Hashable {
    case none = 0
    case audio = 1
    case video = 2
}

public enum MPNowPlayingPlaybackState: UInt, Sendable, Hashable {
    case unknown = 0
    case playing = 1
    case paused = 2
    case stopped = 3
    case interrupted = 4
}

public enum MPRemoteCommandHandlerStatus: Int, Sendable, Hashable {
    case success = 0
    case noSuchContent = 100
    case noActionableNowPlayingItem = 110
    case deviceNotFound = 120
    case commandFailed = 200
}

public enum MPRepeatType: Int, Sendable, Hashable {
    case off = 0
    case one = 1
    case all = 2
}

public enum MPSeekCommandEventType: UInt, Sendable, Hashable {
    case beginSeeking = 0
    case endSeeking = 1
}

public enum MPShuffleType: Int, Sendable, Hashable {
    case off = 0
    case items = 1
    case collections = 2
}

public struct MPMediaType: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
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
    public static let any = MPMediaType(rawValue: ~UInt(0))
}

public struct MPMediaPlaylistAttribute: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let onTheGo = MPMediaPlaylistAttribute(rawValue: 1 << 0)
    public static let smart = MPMediaPlaylistAttribute(rawValue: 1 << 1)
    public static let genius = MPMediaPlaylistAttribute(rawValue: 1 << 2)
}

public struct MPMovieLoadState: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let playable = MPMovieLoadState(rawValue: 1 << 0)
    public static let playthroughOK = MPMovieLoadState(rawValue: 1 << 1)
    public static let stalled = MPMovieLoadState(rawValue: 1 << 2)
}

public struct MPMovieMediaTypeMask: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    // MEASURED /tmp/mp_oracle.json iOS 26.1: video=1, audio=2.
    public static let video = MPMovieMediaTypeMask(rawValue: 1 << 0)
    public static let audio = MPMovieMediaTypeMask(rawValue: 1 << 1)
}

public struct MPError: Error, Hashable, CustomNSError {
    public enum Code: Int, Sendable, Hashable {
        case unknown = 0
        case permissionDenied = 1
        case cloudServiceCapabilityMissing = 2
        case networkConnectionFailed = 3
        case notFound = 4
        case notSupported = 5
        case cancelled = 6
        case requestTimedOut = 7
    }

    /// MEASURED /tmp/mp_oracle.json iOS 26.1: domain bytes `MPErrorDomain`.
    public static var errorDomain: String { MPErrorDomain }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var permissionDenied: Code { .permissionDenied }
    public static var cloudServiceCapabilityMissing: Code { .cloudServiceCapabilityMissing }
    public static var networkConnectionFailed: Code { .networkConnectionFailed }
    public static var notFound: Code { .notFound }
    public static var notSupported: Code { .notSupported }
    public static var cancelled: Code { .cancelled }
    public static var requestTimedOut: Code { .requestTimedOut }

    public static func == (lhs: MPError, rhs: MPError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

public func ~= (match: MPError.Code, error: any Error) -> Bool {
    (error as? MPError)?.code == match
}

public typealias MPMediaEntityPersistentID = UInt64
