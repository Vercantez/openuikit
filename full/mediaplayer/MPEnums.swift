import Foundation

// Linux Int enums. Case identity is tested; Darwin numeric ABI is unobserved.
// Option-set bits below match Apple public documentation and are Linux-local.

public enum MPChangeLanguageOptionSetting: Int, Sendable, Hashable {
    case none
    case nowPlayingItemOnly
    case permanent
}

public enum MPMediaGrouping: Int, Sendable, Hashable {
    case album
    case albumArtist
    case artist
    case composer
    case genre
    case playlist
    case podcastTitle
    case title
}

public enum MPMediaLibraryAuthorizationStatus: Int, Sendable, Hashable {
    case authorized
    case denied
    case notDetermined
    case restricted
}

public enum MPMediaPredicateComparison: Int, Sendable, Hashable {
    case contains
    case equalTo
}

public enum MPMovieControlStyle: Int, Sendable, Hashable {
    case embedded
    case fullscreen
    case none
}

public enum MPMovieFinishReason: Int, Sendable, Hashable {
    case playbackEnded
    case playbackError
    case userExited
}

public enum MPMoviePlaybackState: Int, Sendable, Hashable {
    case interrupted
    case paused
    case playing
    case seekingBackward
    case seekingForward
    case stopped
}

public enum MPMovieRepeatMode: Int, Sendable, Hashable {
    case none
    case one
}

public enum MPMovieScalingMode: Int, Sendable, Hashable {
    case aspectFill
    case aspectFit
    case fill
    case none
}

public enum MPMovieSourceType: Int, Sendable, Hashable {
    case file
    case streaming
    case unknown
}

public enum MPMovieTimeOption: Int, Sendable, Hashable {
    case exact
    case nearestKeyFrame
}

public enum MPMusicPlaybackState: Int, Sendable, Hashable {
    case interrupted
    case paused
    case playing
    case seekingBackward
    case seekingForward
    case stopped
}

public enum MPMusicRepeatMode: Int, Sendable, Hashable {
    case all
    case `default`
    case none
    case one
}

public enum MPMusicShuffleMode: Int, Sendable, Hashable {
    case albums
    case `default`
    case off
    case songs
}

public enum MPNowPlayingInfoLanguageOptionType: Int, Sendable, Hashable {
    case audible
    case legible
}

public enum MPNowPlayingInfoMediaType: Int, Sendable, Hashable {
    case audio
    case none
    case video
}

public enum MPNowPlayingPlaybackState: Int, Sendable, Hashable {
    case interrupted
    case paused
    case playing
    case stopped
    case unknown
}

public enum MPRemoteCommandHandlerStatus: Int, Sendable, Hashable {
    case commandFailed
    case deviceNotFound
    case noActionableNowPlayingItem
    case noSuchContent
    case success
}

public enum MPRepeatType: Int, Sendable, Hashable {
    case all
    case off
    case one
}

public enum MPSeekCommandEventType: Int, Sendable, Hashable {
    case beginSeeking
    case endSeeking
}

public enum MPShuffleType: Int, Sendable, Hashable {
    case collections
    case items
    case off
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
    public static let audio = MPMovieMediaTypeMask(rawValue: 1 << 0)
    public static let video = MPMovieMediaTypeMask(rawValue: 1 << 1)
}

public struct MPError: Error, Hashable {
    public enum Code: Int, Sendable, Hashable {

        case cancelled
        case cloudServiceCapabilityMissing
        case networkConnectionFailed
        case notFound
        case notSupported
        case permissionDenied
        case requestTimedOut
        case unknown

    }

    /// Linux-local domain string; Darwin `MPErrorDomain` bytes are unobserved.
    public static var errorDomain: String { "MPErrorDomain" }

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

