import Dispatch
import Foundation

/// Apple's public AVKit error domain. The string matches the `NS_ERROR_ENUM`
/// constant name and the pinned `dotnet/macios` `[ErrorDomain ("AVKitErrorDomain")]`
/// annotation.
public let AVKitErrorDomain = "AVKitErrorDomain"

/// Linux has no AVKitCore runtime. The public macro is therefore false.
public var PLATFORM_SUPPORTS_AVKITCORE: Bool { false }

/// Bridged AVKit error.
///
/// The pinned API digester records a stored `_nsError: NSError` and
/// `init(_nsError:)`. Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`.
/// Raw values `unknown = -1000` and `pictureInPictureStartFailed = -1001`
/// match the pinned `dotnet/macios` `AVKitError` enum. Extra macios cases
/// (`contentRatingUnknown`, …) are absent from this seed's public graph and
/// are not declared.
@frozen
public struct AVKitError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = AVKitError

        case unknown = -1000
        case pictureInPictureStartFailed = -1001
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { AVKitErrorDomain }

    public static var unknown: Code { .unknown }
    public static var pictureInPictureStartFailed: Code { .pictureInPictureStartFailed }

    /// Foundation's `_BridgedStoredNSError` hash witnesses trap on Linux.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension AVAudioSession {
    public enum RouteSelection: Int, Sendable, Hashable {
        case none = 0
        case local = 1
        case external = 2
    }

    /// Isolated host: invoke the completion asynchronously, exactly once, with
    /// `(false, .none)`. Route hardware and AirPlay picking are unavailable.
    public func prepareRouteSelectionForPlayback(
        completionHandler: @escaping (Bool, AVAudioSession.RouteSelection) -> Void
    ) {
        DispatchQueue.avkitCallback.async {
            completionHandler(false, .none)
        }
    }
}

/// Capture-hardware event phase. Raw values follow the pinned `dotnet/macios`
/// `AVCaptureEventPhase` declaration order (`began = 0`, `ended = 1`,
/// `cancelled = 2`).
public enum AVCaptureEventPhase: UInt, Sendable, Hashable {
    case began = 0
    case ended = 1
    case cancelled = 2
}

/// Preferred display dynamic range. Raw values match pinned `dotnet/macios`
/// `AVDisplayDynamicRange`.
public enum AVDisplayDynamicRange: Int, Sendable, Hashable {
    case automatic = 0
    case standard = 1
    case constrainedHigh = 2
    case high = 3
}

/// Video-frame analysis kinds. Flag values match pinned `dotnet/macios`
/// `AVVideoFrameAnalysisType`.
public struct AVVideoFrameAnalysisType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let `default` = AVVideoFrameAnalysisType(rawValue: 1 << 0)
    public static let text = AVVideoFrameAnalysisType(rawValue: 1 << 1)
    public static let subject = AVVideoFrameAnalysisType(rawValue: 1 << 2)
    public static let visualSearch = AVVideoFrameAnalysisType(rawValue: 1 << 3)
    public static let machineReadableCode = AVVideoFrameAnalysisType(rawValue: 1 << 4)
}

/// Camera capture event delivered to `AVCaptureEventInteraction` handlers.
/// Isolated host never synthesizes hardware events.
open class AVCaptureEvent: NSObject {
    public private(set) var phase: AVCaptureEventPhase
    public private(set) var shouldPlaySound: Bool

    public override init() {
        self.phase = .ended
        self.shouldPlaySound = false
        super.init()
    }

    /// Sound playback requires capture hardware. Isolated host always returns false.
    open func play(_ sound: AVCaptureEventSound) -> Bool {
        _ = sound
        return false
    }
}

/// Named capture sounds. Loading a custom URL is fail-closed.
open class AVCaptureEventSound: NSObject {
    public let url: URL?

    public override init() {
        self.url = nil
        super.init()
    }

    public init(url: URL) throws {
        _ = url
        throw AVKitError(.unknown)
    }

    public convenience init(URL url: URL) throws {
        try self.init(url: url)
    }

    public static var beginVideoRecording: AVCaptureEventSound { AVCaptureEventSound() }
    public static var cameraShutter: AVCaptureEventSound { AVCaptureEventSound() }
    public static var endVideoRecording: AVCaptureEventSound { AVCaptureEventSound() }
}

/// Volume-button / capture-event interaction. Isolated host never delivers
/// hardware events to the stored handlers.
@MainActor
open class AVCaptureEventInteraction: NSObject {
    public static var defaultCaptureSoundDisabled = false
    public var isEnabled: Bool = true

    private let primaryHandler: ((AVCaptureEvent) -> Void)?
    private let secondaryHandler: ((AVCaptureEvent) -> Void)?

    public init(handler: @escaping (AVCaptureEvent) -> Void) {
        self.primaryHandler = handler
        self.secondaryHandler = nil
        super.init()
    }

    public convenience init(eventHandler handler: @escaping (AVCaptureEvent) -> Void) {
        self.init(handler: handler)
    }

    public init(
        primary primaryHandler: @escaping (AVCaptureEvent) -> Void,
        secondary secondaryHandler: @escaping (AVCaptureEvent) -> Void
    ) {
        self.primaryHandler = primaryHandler
        self.secondaryHandler = secondaryHandler
        super.init()
    }

    public convenience init(
        primaryEventHandler primaryHandler: @escaping (AVCaptureEvent) -> Void,
        secondaryEventHandler secondaryHandler: @escaping (AVCaptureEvent) -> Void
    ) {
        self.init(primary: primaryHandler, secondary: secondaryHandler)
    }
}

/// Input-route picker. `present()` does not become presented on Linux.
@MainActor
open class AVInputPickerInteraction: NSObject {
    public var audioSession: AVAudioSession
    public weak var delegate: (any AVInputPickerInteraction.Delegate)?
    public private(set) var isPresented: Bool = false

    public override init() {
        self.audioSession = AVAudioSession()
        super.init()
    }

    public init(audioSession: AVAudioSession?) {
        self.audioSession = audioSession ?? AVAudioSession()
        super.init()
    }

    public func present() {
        // No input-picker UI exists on the isolated host.
        isPresented = false
        delegate?.inputPickerInteractionWillBeginPresenting(self)
        delegate?.inputPickerInteractionDidEndPresenting(self)
    }

    public func dismiss() {
        isPresented = false
        delegate?.inputPickerInteractionWillBeginDismissing(self)
        delegate?.inputPickerInteractionDidEndDismissing(self)
    }

    public protocol Delegate: NSObjectProtocol {
        func inputPickerInteractionDidEndDismissing(_ inputPickerInteraction: AVInputPickerInteraction)
        func inputPickerInteractionDidEndPresenting(_ inputPickerInteraction: AVInputPickerInteraction)
        func inputPickerInteractionWillBeginDismissing(_ inputPickerInteraction: AVInputPickerInteraction)
        func inputPickerInteractionWillBeginPresenting(_ inputPickerInteraction: AVInputPickerInteraction)
    }
}

extension AVInputPickerInteraction.Delegate {
    public func inputPickerInteractionDidEndDismissing(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
    }
    public func inputPickerInteractionDidEndPresenting(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
    }
    public func inputPickerInteractionWillBeginDismissing(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
    }
    public func inputPickerInteractionWillBeginPresenting(_ inputPickerInteraction: AVInputPickerInteraction) {
        _ = inputPickerInteraction
    }
}

/// Interstitial range attached to an `AVPlayerItem`. Time-range identity is
/// stored; playback gap insertion is not performed.
open class AVInterstitialTimeRange: NSObject, NSCoding {
    public let timeRange: CMTimeRange

    public init(timeRange: CMTimeRange) {
        self.timeRange = timeRange
        super.init()
    }

    public required init?(coder: NSCoder) {
        let startValue = coder.decodeInt64(forKey: "start.value")
        let startScale = Int32(truncatingIfNeeded: coder.decodeInt64(forKey: "start.timescale"))
        let durationValue = coder.decodeInt64(forKey: "duration.value")
        let durationScale = Int32(truncatingIfNeeded: coder.decodeInt64(forKey: "duration.timescale"))
        guard startScale != 0, durationScale != 0 else { return nil }
        self.timeRange = CMTimeRange(
            start: CMTime(value: startValue, timescale: startScale),
            duration: CMTime(value: durationValue, timescale: durationScale)
        )
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(timeRange.start.value, forKey: "start.value")
        coder.encode(Int64(timeRange.start.timescale), forKey: "start.timescale")
        coder.encode(timeRange.duration.value, forKey: "duration.value")
        coder.encode(Int64(timeRange.duration.timescale), forKey: "duration.timescale")
    }
}

/// Playback speed token. Rate and localized name are stored; applying a speed
/// does not start media.
open class AVPlaybackSpeed: NSObject {
    public let rate: Float
    public let localizedName: String

    public init(rate: Float, localizedName: String) {
        self.rate = rate
        self.localizedName = localizedName
        super.init()
    }

    public var localizedNumericName: String {
        String(rate)
    }

    public static var systemDefaultSpeeds: [AVPlaybackSpeed] {
        [
            AVPlaybackSpeed(rate: 0.5, localizedName: "0.5×"),
            AVPlaybackSpeed(rate: 1.0, localizedName: "1×"),
            AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×"),
            AVPlaybackSpeed(rate: 2.0, localizedName: "2×"),
        ]
    }
}

/// Picture in Picture controller. Isolated host reports unsupported and keeps
/// every session inactive. `startPictureInPicture()` does not become active
/// and does not invent a start-failed delegate callback (timing unobserved).
open class AVPictureInPictureController: NSObject {
    public weak var delegate: (any AVPictureInPictureControllerDelegate)?
    public var canStartPictureInPictureAutomaticallyFromInline = false
    public var requiresLinearPlayback = false
    public var contentSource: AVPictureInPictureController.ContentSource?
    public private(set) var playerLayer: AVPlayerLayer
    public private(set) var isPictureInPictureActive = false
    public private(set) var isPictureInPicturePossible = false
    public private(set) var isPictureInPictureSuspended = false

    public class func isPictureInPictureSupported() -> Bool { false }

    public class var pictureInPictureButtonStartImage: UIImage { UIImage() }
    public class var pictureInPictureButtonStopImage: UIImage { UIImage() }

    public class func pictureInPictureButtonStartImage(
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIImage {
        _ = traitCollection
        return UIImage()
    }

    public class func pictureInPictureButtonStopImage(
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIImage {
        _ = traitCollection
        return UIImage()
    }

    public init(contentSource: AVPictureInPictureController.ContentSource) {
        self.contentSource = contentSource
        self.playerLayer = contentSource.playerLayer ?? AVPlayerLayer()
        super.init()
    }

    public convenience init?(playerLayer: AVPlayerLayer) {
        self.init(contentSource: ContentSource(playerLayer: playerLayer))
    }

    public func invalidatePlaybackState() {}

    public func startPictureInPicture() {
        // Hardware / system PiP is unavailable. Stay inactive.
        isPictureInPictureActive = false
        isPictureInPicturePossible = false
    }

    public func stopPictureInPicture() {
        isPictureInPictureActive = false
    }

    open class ContentSource: NSObject {
        public private(set) var playerLayer: AVPlayerLayer?
        public private(set) var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
        public private(set) weak var sampleBufferPlaybackDelegate:
            (any AVPictureInPictureSampleBufferPlaybackDelegate)?
        public private(set) weak var activeVideoCallSourceView: UIView?
        public private(set) var activeVideoCallContentViewController:
            AVPictureInPictureVideoCallViewController

        public init(playerLayer: AVPlayerLayer) {
            self.playerLayer = playerLayer
            self.activeVideoCallContentViewController =
                AVPictureInPictureVideoCallViewController()
            super.init()
        }

        public init(
            sampleBufferDisplayLayer: AVSampleBufferDisplayLayer,
            playbackDelegate: any AVPictureInPictureSampleBufferPlaybackDelegate
        ) {
            self.sampleBufferDisplayLayer = sampleBufferDisplayLayer
            self.sampleBufferPlaybackDelegate = playbackDelegate
            self.activeVideoCallContentViewController =
                AVPictureInPictureVideoCallViewController()
            super.init()
        }

        public init(
            activeVideoCallSourceView sourceView: UIView,
            contentViewController: AVPictureInPictureVideoCallViewController
        ) {
            self.activeVideoCallSourceView = sourceView
            self.activeVideoCallContentViewController = contentViewController
            super.init()
        }
    }
}

open class AVPictureInPictureVideoCallViewController: UIViewController {
    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public protocol AVPictureInPictureControllerDelegate: NSObjectProtocol {
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    )
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController
    ) async -> Bool
    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    )
    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    )
    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    )
    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    )
}

extension AVPictureInPictureControllerDelegate {
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        _ = (pictureInPictureController, error)
    }

    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController
    ) async -> Bool {
        _ = pictureInPictureController
        return false
    }

    public func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
    }

    public func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
    }

    public func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
    }

    public func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        _ = pictureInPictureController
    }
}

public protocol AVPictureInPictureSampleBufferPlaybackDelegate: NSObjectProtocol {
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    )
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    )
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime
    ) async
    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool
    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool
    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange
}

extension AVPictureInPictureSampleBufferPlaybackDelegate {
    public func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        _ = pictureInPictureController
        return true
    }
}

/// Player view controller. Stores overlay state; does not decode or present
/// full-screen video on the isolated host.
@MainActor
open class AVPlayerViewController: UIViewController {
    public static var mediaCharacteristicsForSupportedCustomMediaSelectionSchemes:
        [AVMediaCharacteristic]
    {
        []
    }

    public weak var delegate: (any AVPlayerViewControllerDelegate)?
    public var player: AVPlayer?
    public var allowsPictureInPicturePlayback = false
    public var allowsVideoFrameAnalysis = false
    public var canStartPictureInPictureAutomaticallyFromInline = false
    public var entersFullScreenWhenPlaybackBegins = false
    public var exitsFullScreenWhenPlaybackEnds = false
    public var pixelBufferAttributes: [String: Any]?
    public var preferredDisplayDynamicRange: AVDisplayDynamicRange = .automatic
    public var requiresLinearPlayback = false
    public var showsPlaybackControls = true
    public var showsTimecodes = false
    public var speeds: [AVPlaybackSpeed] = AVPlaybackSpeed.systemDefaultSpeeds
    public var updatesNowPlayingInfoCenter = false
    public var videoFrameAnalysisTypes: AVVideoFrameAnalysisType = .default
    public var videoGravity: AVLayerVideoGravity = .resizeAspect
    public private(set) var selectedSpeed: AVPlaybackSpeed?
    public private(set) var isReadyForDisplay = false
    public private(set) var contentOverlayView: UIView? = UIView(frame: .zero)
    public private(set) var videoBounds: CGRect = .zero
    public private(set) var toggleLookupAction: UIAction = UIAction()

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func selectSpeed(_ speed: AVPlaybackSpeed) {
        selectedSpeed = speed
    }
}

public protocol AVPlayerViewControllerDelegate: NSObjectProtocol {
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        didPresent interstitial: AVInterstitialTimeRange
    )
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        failedToStartPictureInPictureWithError error: any Error
    )
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForFullScreenExitWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    )
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    )
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    )
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    )
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willPresent interstitial: AVInterstitialTimeRange
    )
    func playerViewControllerDidStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    )
    func playerViewControllerDidStopPictureInPicture(
        _ playerViewController: AVPlayerViewController
    )
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
        _ playerViewController: AVPlayerViewController
    ) -> Bool
    func playerViewControllerWillStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    )
    func playerViewControllerWillStopPictureInPicture(
        _ playerViewController: AVPlayerViewController
    )
}

extension AVPlayerViewControllerDelegate {
    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        didPresent interstitial: AVInterstitialTimeRange
    ) {
        _ = (playerViewController, interstitial)
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        _ = (playerViewController, error)
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForFullScreenExitWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        _ = playerViewController
        completionHandler(false)
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        _ = playerViewController
        completionHandler(false)
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
        _ = (playerViewController, coordinator)
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
        _ = (playerViewController, coordinator)
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willPresent interstitial: AVInterstitialTimeRange
    ) {
        _ = (playerViewController, interstitial)
    }

    public func playerViewControllerDidStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
    }

    public func playerViewControllerDidStopPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
    }

    public func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
        _ playerViewController: AVPlayerViewController
    ) -> Bool {
        _ = playerViewController
        return false
    }

    public func playerViewControllerWillStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
    }

    public func playerViewControllerWillStopPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        _ = playerViewController
    }
}

/// Route picker view. Isolated host does not present AirPlay / route sheets.
@MainActor
open class AVRoutePickerView: UIView {
    public var activeTintColor: UIColor! = .white
    public var customRoutingController: AVCustomRoutingController?
    public weak var delegate: (any AVRoutePickerViewDelegate)?
    public var prioritizesVideoDevices = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public protocol AVRoutePickerViewDelegate: NSObjectProtocol {
    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView)
    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView)
}

extension AVRoutePickerViewDelegate {
    public func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        _ = routePickerView
    }
    public func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        _ = routePickerView
    }
}

enum AVKitHostAvailability {
    static let callbackQueue: DispatchQueue = {
        DispatchQueue(label: "com.apple.avkit.AVKit.callback")
    }()
}

extension DispatchQueue {
    fileprivate static var avkitCallback: DispatchQueue {
        AVKitHostAvailability.callbackQueue
    }
}
