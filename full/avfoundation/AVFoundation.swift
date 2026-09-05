import Dispatch
import Foundation
#if canImport(CoreMedia)
@_exported import CoreMedia
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreImage)
import CoreImage
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
#if canImport(OpenUIKit)
// The portable Foundation facade deliberately preserves OpenUIKit's
// Notification.Name identity instead of manufacturing a second copy.
import OpenUIKit
#endif

public enum AVFoundationPortableError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    case mediaServiceUnavailable
    case frameGenerationUnavailable(URL)
    case exportUnavailable(preset: String)
    case invalidOutput

    public var description: String {
        switch self {
        case .mediaServiceUnavailable:
            return "No host media service is installed"
        case .frameGenerationUnavailable(let url):
            return "Frame generation is unavailable for \(url.absoluteString)"
        case .exportUnavailable(let preset):
            return "Media export is unavailable for preset \(preset)"
        case .invalidOutput:
            return "The requested media output is invalid"
        }
    }
}

/// Process boundary for portable media behavior.
///
/// Player/session state is always functional. Decoding, rendering, and
/// transcoding are advertised only after a host installs the corresponding
/// SPI handler; otherwise those service-backed operations fail explicitly.
public enum AVFoundationPortable {
    public enum ServiceCapability: String, Sendable {
        case stateOnly
        case hostDriven
    }

    public enum PlayerEvent: Equatable, Sendable {
        case play(player: ObjectIdentifier, url: URL?)
        case pause(player: ObjectIdentifier)
        case seek(player: ObjectIdentifier, time: CMTime)
        case replaceItem(player: ObjectIdentifier, url: URL?)
        case muted(player: ObjectIdentifier, value: Bool)
    }

    public struct ExportRequest: Hashable, Sendable {
        public let sourceURL: URL
        public let outputURL: URL
        public let outputFileType: AVFileType
        public let presetName: String
        public let optimizeForNetworkUse: Bool

        public init(
            sourceURL: URL,
            outputURL: URL,
            outputFileType: AVFileType,
            presetName: String,
            optimizeForNetworkUse: Bool
        ) {
            self.sourceURL = sourceURL
            self.outputURL = outputURL
            self.outputFileType = outputFileType
            self.presetName = presetName
            self.optimizeForNetworkUse = optimizeForNetworkUse
        }
    }

    public typealias PlayerEventHandler = @Sendable (PlayerEvent) -> Void
    public typealias ExportHandler = @Sendable (ExportRequest) async throws -> Void
    public typealias FrameHandler = (
        _ sourceURL: URL,
        _ requestedTime: CMTime
    ) throws -> CGImage

    private static let stateLock = NSLock()
    nonisolated(unsafe) private static var playerEventHandler: PlayerEventHandler?
    nonisolated(unsafe) private static var exportHandler: ExportHandler?
    nonisolated(unsafe) private static var frameHandler: FrameHandler?

    public static var playbackCapability: ServiceCapability {
        stateLock.withLock {
            playerEventHandler == nil ? .stateOnly : .hostDriven
        }
    }

    public static var exportCapability: ServiceCapability {
        stateLock.withLock {
            exportHandler == nil ? .stateOnly : .hostDriven
        }
    }

    public static var frameGenerationCapability: ServiceCapability {
        stateLock.withLock {
            frameHandler == nil ? .stateOnly : .hostDriven
        }
    }

    @_spi(OpenUIKitHost)
    public static func _installPlayerEventHandler(
        _ handler: PlayerEventHandler?
    ) {
        stateLock.withLock { playerEventHandler = handler }
    }

    @_spi(OpenUIKitHost)
    public static func _installExportHandler(_ handler: ExportHandler?) {
        stateLock.withLock { exportHandler = handler }
    }

    @_spi(OpenUIKitHost)
    public static func _installFrameHandler(_ handler: FrameHandler?) {
        stateLock.withLock { frameHandler = handler }
    }

    @_spi(OpenUIKitHost)
    public static func _resetHostServices() {
        stateLock.withLock {
            playerEventHandler = nil
            exportHandler = nil
            frameHandler = nil
        }
    }

    static func emit(_ event: PlayerEvent) {
        let handler = stateLock.withLock { playerEventHandler }
        handler?(event)
    }

    static func exporter() -> ExportHandler? {
        stateLock.withLock { exportHandler }
    }

    static func frameGenerator() -> FrameHandler? {
        stateLock.withLock { frameHandler }
    }
}

public struct AVFileType: RawRepresentable, Hashable, Sendable,
    ExpressibleByStringLiteral
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let mp4 = AVFileType(rawValue: "public.mpeg-4")
    public static let mov = AVFileType(rawValue: "com.apple.quicktime-movie")
    public static let m4a = AVFileType(rawValue: "com.apple.m4a-audio")
}

open class AVAsset: NSObject, @unchecked Sendable {
    let loadState = AVAssetLoadState()

    public override init() {
        super.init()
    }

    public class func asset(with url: URL) -> AVAsset {
        AVURLAsset(url: url)
    }

    @_spi(OpenUIKitHost)
    public func _portableInjectDuration(_ seconds: Double) {
        loadState.injectedDuration = seconds
        loadState.markLoaded(["duration"])
    }
}

open class AVURLAsset: AVAsset, @unchecked Sendable {
    public let url: URL
    public let options: [String: Any]?

    public override init() {
        self.url = URL(fileURLWithPath: "/dev/null")
        self.options = nil
        super.init()
    }

    public init(url: URL, options: [String: Any]? = nil) {
        self.url = url
        self.options = options
        super.init()
    }
}

open class AVPlayerItem: NSObject, @unchecked Sendable {
    public let asset: AVAsset
    public var url: URL? { (asset as? AVURLAsset)?.url }
    private let itemLock = NSLock()
    private var storedTime: CMTime = .zero

    public override init() {
        self.asset = AVAsset()
        super.init()
    }

    public init(asset: AVAsset) {
        self.asset = asset
        super.init()
    }

    public convenience init(url: URL) {
        self.init(asset: AVURLAsset(url: url))
    }

    public convenience init(
        asset: AVAsset,
        automaticallyLoadedAssetKeys: [AVPartialAsyncProperty<AVAsset>]
    ) {
        self.init(asset: asset)
        _ = automaticallyLoadedAssetKeys
    }

    func _portableSetCurrentTime(_ time: CMTime) {
        itemLock.withLock { storedTime = time }
    }

    func _portableDurationSeconds() -> Double? {
        asset.loadState.injectedDuration
    }

    public func currentTime() -> CMTime {
        itemLock.withLock { storedTime }
    }
}

public extension Notification.Name {
    static let AVPlayerItemDidPlayToEndTime = Notification.Name(
        "AVPlayerItemDidPlayToEndTimeNotification"
    )
    static let AVPlayerItemFailedToPlayToEndTime = Notification.Name(
        "AVPlayerItemFailedToPlayToEndTimeNotification"
    )
    static let AVPlayerItemPlaybackStalled = Notification.Name(
        "AVPlayerItemPlaybackStalledNotification"
    )
}

public enum AVPlayerAudiovisualBackgroundPlaybackPolicy: Int, Sendable {
    case automatic = 1
    case pauses = 2
    case continuesIfPossible = 3
}

open class AVPlayer: NSObject, @unchecked Sendable {
    let playbackEngine = AVPlaybackEngine()

    public override init() {
        super.init()
        playbackEngine.owner = self
    }

    public init(playerItem item: AVPlayerItem?) {
        super.init()
        playbackEngine.owner = self
        playbackEngine.item = item
    }

    public convenience init(url URL: URL) {
        self.init(playerItem: AVPlayerItem(url: URL))
    }

    public var currentItem: AVPlayerItem? {
        playbackEngine.lock.withLock { playbackEngine.item }
    }

    public var rate: Float {
        get { playbackEngine.lock.withLock { playbackEngine.rate } }
        set {
            playbackEngine.lock.lock()
            playbackEngine.setRate(newValue)
            playbackEngine.lock.unlock()
        }
    }

    public var defaultRate: Float {
        get { playbackEngine.lock.withLock { playbackEngine.defaultRate } }
        set { playbackEngine.lock.withLock { playbackEngine.defaultRate = newValue } }
    }

    public var volume: Float {
        get { playbackEngine.lock.withLock { playbackEngine.volume } }
        set { playbackEngine.lock.withLock { playbackEngine.volume = newValue } }
    }

    public var isMuted: Bool {
        get { playbackEngine.lock.withLock { playbackEngine.muted } }
        set {
            playbackEngine.lock.withLock { playbackEngine.muted = newValue }
            AVFoundationPortable.emit(
                .muted(player: ObjectIdentifier(self), value: newValue)
            )
        }
    }

    public var preventsDisplaySleepDuringVideoPlayback: Bool {
        get { playbackEngine.lock.withLock { playbackEngine.preventsDisplaySleep } }
        set {
            playbackEngine.lock.withLock { playbackEngine.preventsDisplaySleep = newValue }
        }
    }

    public var audiovisualBackgroundPlaybackPolicy:
        AVPlayerAudiovisualBackgroundPlaybackPolicy
    {
        get { playbackEngine.lock.withLock { playbackEngine.backgroundPolicy } }
        set {
            playbackEngine.lock.withLock { playbackEngine.backgroundPolicy = newValue }
        }
    }

    public func play() {
        // iOS 16+: play() applies defaultRate (Apple AVPlayer.play()).
        // Measured testAVPlayerStatusAndTimeControl: defaultRate 1 → rate 1.
        let url = playbackEngine.lock.withLock { () -> URL? in
            let playRate = playbackEngine.defaultRate == 0 ? 1 : playbackEngine.defaultRate
            playbackEngine.setRate(playRate)
            return playbackEngine.item?.url
        }
        AVFoundationPortable.emit(
            .play(player: ObjectIdentifier(self), url: url)
        )
    }

    public func pause() {
        playbackEngine.lock.withLock { playbackEngine.setRate(0) }
        AVFoundationPortable.emit(.pause(player: ObjectIdentifier(self)))
    }

    public func seek(to time: CMTime) {
        let applied = playbackEngine.lock.withLock { playbackEngine.seek(to: time) }
        guard applied else { return }
        AVFoundationPortable.emit(
            .seek(player: ObjectIdentifier(self), time: time)
        )
    }

    public func currentTime() -> CMTime {
        playbackEngine.lock.withLock { playbackEngine.currentTime() }
    }

    public func replaceCurrentItem(with item: AVPlayerItem?) {
        let url = playbackEngine.lock.withLock { () -> URL? in
            playbackEngine.item = item
            _ = playbackEngine.seek(to: .zero)
            playbackEngine.setRate(0)
            return item?.url
        }
        AVFoundationPortable.emit(
            .replaceItem(player: ObjectIdentifier(self), url: url)
        )
    }
}

open class AVAudioSession: NSObject, @unchecked Sendable {
    public struct Category: RawRepresentable, Hashable, Sendable,
        ExpressibleByStringLiteral
    {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }

        public static let ambient = Category(rawValue: "AVAudioSessionCategoryAmbient")
        public static let soloAmbient = Category(
            rawValue: "AVAudioSessionCategorySoloAmbient"
        )
        public static let playback = Category(rawValue: "AVAudioSessionCategoryPlayback")
        public static let record = Category(rawValue: "AVAudioSessionCategoryRecord")
        public static let playAndRecord = Category(
            rawValue: "AVAudioSessionCategoryPlayAndRecord"
        )
    }

    public struct CategoryOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let mixWithOthers = CategoryOptions(rawValue: 1 << 0)
        public static let duckOthers = CategoryOptions(rawValue: 1 << 1)
        public static let allowBluetooth = CategoryOptions(rawValue: 1 << 2)
        public static let defaultToSpeaker = CategoryOptions(rawValue: 1 << 3)
        public static let interruptSpokenAudioAndMixWithOthers = CategoryOptions(
            rawValue: 1 << 4
        )
        public static let allowBluetoothA2DP = CategoryOptions(rawValue: 1 << 5)
        public static let allowAirPlay = CategoryOptions(rawValue: 1 << 6)
    }

    public struct SetActiveOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let notifyOthersOnDeactivation = SetActiveOptions(
            rawValue: 1 << 0
        )
    }

    public struct State: Equatable, Sendable {
        public let category: Category
        public let categoryOptions: CategoryOptions
        public let isActive: Bool
    }

    private static let shared = AVAudioSession()
    private let stateLock = NSLock()
    private var storedCategory = Category.soloAmbient
    private var storedCategoryOptions: CategoryOptions = []
    private var storedActive = false

    public static func sharedInstance() -> AVAudioSession { shared }

    public var category: Category { stateLock.withLock { storedCategory } }
    public var categoryOptions: CategoryOptions {
        stateLock.withLock { storedCategoryOptions }
    }
    public var isOtherAudioPlaying: Bool { false }
    public var secondaryAudioShouldBeSilencedHint: Bool { false }

    public func setCategory(
        _ category: Category,
        options: CategoryOptions = []
    ) throws {
        stateLock.withLock {
            storedCategory = category
            storedCategoryOptions = options
        }
    }

    public func setActive(
        _ active: Bool,
        options: SetActiveOptions = []
    ) throws {
        _ = options
        stateLock.withLock { storedActive = active }
    }

    @_spi(OpenUIKitHost)
    public var _portableState: State {
        stateLock.withLock {
            State(
                category: storedCategory,
                categoryOptions: storedCategoryOptions,
                isActive: storedActive
            )
        }
    }
}

public let AVAssetExportPresetLowQuality = "AVAssetExportPresetLowQuality"
public let AVAssetExportPresetMediumQuality = "AVAssetExportPresetMediumQuality"
public let AVAssetExportPresetHighestQuality = "AVAssetExportPresetHighestQuality"
public let AVAssetExportPreset1280x720 = "AVAssetExportPreset1280x720"
public let AVAssetExportPreset1920x1080 = "AVAssetExportPreset1920x1080"
public let AVAssetExportPresetPassthrough = "AVAssetExportPresetPassthrough"

open class AVAssetExportSession: NSObject, @unchecked Sendable {
    public enum Status: Int, Sendable {
        case unknown = 0
        case waiting = 1
        case exporting = 2
        case completed = 3
        case failed = 4
        case cancelled = 5
    }

    public let asset: AVAsset
    public let presetName: String
    public var outputURL: URL?
    public var outputFileType: AVFileType?
    public var shouldOptimizeForNetworkUse = false

    private let stateLock = NSLock()
    private var storedStatus = Status.unknown
    private var storedError: Error?
    private var cancelled = false

    public var status: Status { stateLock.withLock { storedStatus } }
    public var error: Error? { stateLock.withLock { storedError } }
    public var progress: Float { status == .completed ? 1 : 0 }

    public init?(asset: AVAsset, presetName: String) {
        guard !presetName.isEmpty else { return nil }
        self.asset = asset
        self.presetName = presetName
        super.init()
    }

    public func cancelExport() {
        stateLock.withLock {
            cancelled = true
            storedStatus = .cancelled
        }
    }

    public func export(to outputURL: URL, as fileType: AVFileType) async throws {
        guard let sourceURL = (asset as? AVURLAsset)?.url,
              outputURL.isFileURL else {
            let failure = AVFoundationPortableError.invalidOutput
            stateLock.withLock {
                storedStatus = .failed
                storedError = failure
            }
            throw failure
        }
        guard let handler = AVFoundationPortable.exporter() else {
            let failure = AVFoundationPortableError.exportUnavailable(
                preset: presetName
            )
            stateLock.withLock {
                storedStatus = .failed
                storedError = failure
            }
            throw failure
        }

        self.outputURL = outputURL
        outputFileType = fileType
        stateLock.withLock { storedStatus = .exporting }
        do {
            try await handler(
                AVFoundationPortable.ExportRequest(
                    sourceURL: sourceURL,
                    outputURL: outputURL,
                    outputFileType: fileType,
                    presetName: presetName,
                    optimizeForNetworkUse: shouldOptimizeForNetworkUse
                )
            )
            let wasCancelled = stateLock.withLock { cancelled }
            guard !wasCancelled else {
                throw CancellationError()
            }
            stateLock.withLock { storedStatus = .completed }
        } catch {
            stateLock.withLock {
                if storedStatus != .cancelled { storedStatus = .failed }
                storedError = error
            }
            throw error
        }
    }
}

open class AVAssetImageGenerator: NSObject, @unchecked Sendable {
    public let asset: AVAsset
    public var appliesPreferredTrackTransform = false

    public init(asset: AVAsset) {
        self.asset = asset
        super.init()
    }

    public func generateCGImageAsynchronously(
        for requestedTime: CMTime,
        completionHandler handler: @escaping (
            _ image: CGImage?,
            _ actualTime: CMTime,
            _ error: Error?
        ) -> Void
    ) {
        guard let url = (asset as? AVURLAsset)?.url else {
            handler(nil, .invalid, AVFoundationPortableError.invalidOutput)
            return
        }
        guard let generator = AVFoundationPortable.frameGenerator() else {
            handler(
                nil,
                .invalid,
                AVFoundationPortableError.frameGenerationUnavailable(url)
            )
            return
        }
        do {
            handler(try generator(url, requestedTime), requestedTime, nil)
        } catch {
            handler(nil, .invalid, error)
        }
    }
}
