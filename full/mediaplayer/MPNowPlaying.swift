import Foundation

/// In-process now-playing metadata. Setting `nowPlayingInfo` stores a copy in
/// this process; it does not publish to Control Center, the lock screen,
/// CarPlay, or any Apple now-playing daemon.
open class MPNowPlayingInfoCenter: NSObject, @unchecked Sendable {
    private static let _default = MPNowPlayingInfoCenter()
    private let lock = NSLock()
    private var _nowPlayingInfo: [String: Any]?
    private var _playbackState: MPNowPlayingPlaybackState = .unknown

    public override init() {
        super.init()
    }

    open class func `default`() -> MPNowPlayingInfoCenter {
        _default
    }

    /// Animated artwork is not rendered on Linux.
    open class var supportedAnimatedArtworkKeys: [String] { [] }

    open var nowPlayingInfo: [String: Any]? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _nowPlayingInfo
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            if let newValue {
                _nowPlayingInfo = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key, $0.value) })
            } else {
                _nowPlayingInfo = nil
            }
        }
    }

    open var playbackState: MPNowPlayingPlaybackState {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _playbackState
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _playbackState = newValue
        }
    }
}

open class MPNowPlayingInfoLanguageOption: NSObject, @unchecked Sendable {
    public let languageOptionType: MPNowPlayingInfoLanguageOptionType
    public let languageTag: String?
    public let languageOptionCharacteristics: [String]?
    public let displayName: String?
    public let identifier: String?

    public init(
        type languageOptionType: MPNowPlayingInfoLanguageOptionType,
        languageTag: String,
        characteristics languageOptionCharacteristics: [String]?,
        displayName: String,
        identifier: String
    ) {
        self.languageOptionType = languageOptionType
        self.languageTag = languageTag
        self.languageOptionCharacteristics = languageOptionCharacteristics
        self.displayName = displayName
        self.identifier = identifier
        super.init()
    }

    open func isAutomaticAudibleLanguageOption() -> Bool { false }

    open func isAutomaticLegibleLanguageOption() -> Bool { false }
}

open class MPNowPlayingInfoLanguageOptionGroup: NSObject, @unchecked Sendable {
    public let languageOptions: [MPNowPlayingInfoLanguageOption]
    public let defaultLanguageOption: MPNowPlayingInfoLanguageOption?
    public let allowEmptySelection: Bool

    public init(
        languageOptions: [MPNowPlayingInfoLanguageOption],
        defaultLanguageOption: MPNowPlayingInfoLanguageOption?,
        allowEmptySelection: Bool
    ) {
        self.languageOptions = languageOptions
        self.defaultLanguageOption = defaultLanguageOption
        self.allowEmptySelection = allowEmptySelection
        super.init()
    }
}
