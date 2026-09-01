import Foundation

#if canImport(CoreMedia)
import CoreMedia
#endif

/// Deprecated MP4-clip configuration object. Properties are stored locally;
/// they never configure an Apple broadcast encoder on Linux.
open class RPBroadcastConfiguration: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    open var clipDuration: TimeInterval = 0
    open var videoCompressionProperties: [String: any NSSecureCoding & NSObjectProtocol]?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        clipDuration = coder.decodeDouble(forKey: "clipDuration")
        videoCompressionProperties =
            coder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self],
                               forKey: "videoCompressionProperties")
            as? [String: any NSSecureCoding & NSObjectProtocol]
    }

    open func encode(with coder: NSCoder) {
        coder.encode(clipDuration, forKey: "clipDuration")
        coder.encode(videoCompressionProperties as NSDictionary?,
                     forKey: "videoCompressionProperties")
    }
}

public protocol RPBroadcastControllerDelegate: NSObjectProtocol {
    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didFinishWithError error: (any Error)?
    )

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateServiceInfo serviceInfo: [String: any NSCoding & NSObjectProtocol]
    )

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateBroadcast broadcastURL: URL
    )
}

public extension RPBroadcastControllerDelegate {
    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didFinishWithError error: (any Error)?
    ) {
        _ = (broadcastController, error)
    }

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateServiceInfo serviceInfo: [String: any NSCoding & NSObjectProtocol]
    ) {
        _ = (broadcastController, serviceInfo)
    }

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateBroadcast broadcastURL: URL
    ) {
        _ = (broadcastController, broadcastURL)
    }
}

/// In-app broadcast session object. Linux has no ReplayKit daemon or
/// broadcast-upload extension host, so the controller stays idle.
open class RPBroadcastController: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var paused = false
    private weak var storedDelegate: RPBroadcastControllerDelegate?
    private var storedServiceInfo: [String: any NSCoding & NSObjectProtocol]?
    private var storedBroadcastURL = URL(fileURLWithPath: "/")

    public override init() {
        super.init()
    }

    open weak var delegate: RPBroadcastControllerDelegate? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedDelegate
        }
        set {
            lock.lock()
            storedDelegate = newValue
            lock.unlock()
        }
    }

    open var isBroadcasting: Bool { false }

    open var isPaused: Bool {
        lock.lock()
        defer { lock.unlock() }
        return paused
    }

    open var broadcastURL: URL {
        lock.lock()
        defer { lock.unlock() }
        return storedBroadcastURL
    }

    open var serviceInfo: [String: any NSCoding & NSObjectProtocol]? {
        lock.lock()
        defer { lock.unlock() }
        return storedServiceInfo
    }

    open var broadcastExtensionBundleID: String? { nil }

    open func startBroadcast(handler: @escaping ((any Error)?) -> Void) {
        handler(replayKitUnavailableError(.broadcastSetupFailed))
    }

    open func pauseBroadcast() {
        lock.lock()
        paused = false
        lock.unlock()
    }

    open func resumeBroadcast() {
        lock.lock()
        paused = false
        lock.unlock()
    }

    open func finishBroadcast(handler: @escaping ((any Error)?) -> Void) {
        handler(replayKitUnavailableError(.broadcastInvalidSession))
    }
}

/// Base class for ReplayKit broadcast-upload extensions.
///
/// `updateServiceInfo` and `updateBroadcast` record values in-process so a
/// subclass can observe them. They do not deliver IPC to a host app.
open class RPBroadcastHandler: NSObject, @unchecked Sendable {
    public private(set) var portableServiceInfo: [String: any NSCoding & NSObjectProtocol] = [:]
    public private(set) var portableBroadcastURL: URL?

    public override init() {
        super.init()
    }

    open func updateServiceInfo(_ serviceInfo: [String: any NSCoding & NSObjectProtocol]) {
        portableServiceInfo = serviceInfo
    }

    open func updateBroadcast(_ broadcastURL: URL) {
        portableBroadcastURL = broadcastURL
    }
}

/// Deprecated MP4 clip handler. Overrides are no-ops besides recording the
/// last finish error; no clip is uploaded.
open class RPBroadcastMP4ClipHandler: RPBroadcastHandler, @unchecked Sendable {
    public private(set) var portableLastClipURL: URL?
    public private(set) var portableLastClipFinished = false
    public private(set) var portableLastProcessingError: (any Error)?

    open func processMP4Clip(
        with mp4ClipURL: URL?,
        setupInfo: [String: NSObject]?,
        finished: Bool
    ) {
        portableLastClipURL = mp4ClipURL
        portableLastClipFinished = finished
        _ = setupInfo
    }

    open func finishedProcessingMP4Clip(
        withUpdatedBroadcastConfiguration broadcastConfiguration: RPBroadcastConfiguration?,
        error: (any Error)?
    ) {
        portableLastProcessingError = error
        _ = broadcastConfiguration
    }
}

/// Sample-buffer broadcast handler subclassed by upload extensions.
///
/// Lifecycle methods are empty defaults. `processSampleBuffer` is compiled
/// only against real CoreMedia and never claims that frames were encoded or
/// sent. `finishBroadcastWithError` stores the error locally instead of
/// talking to `RPDaemon`.
open class RPBroadcastSampleHandler: RPBroadcastHandler, @unchecked Sendable {
    public private(set) var portableDidStart = false
    public private(set) var portableDidPause = false
    public private(set) var portableDidResume = false
    public private(set) var portableDidFinish = false
    public private(set) var portableLastSetupInfo: [String: NSObject]?
    public private(set) var portableLastApplicationInfo: [AnyHashable: Any] = [:]
    public private(set) var portableLastSampleBufferType: RPSampleBufferType?
    public private(set) var portableFinishError: (any Error)?

    open func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        portableLastSetupInfo = setupInfo
        portableDidStart = true
    }

    open func broadcastPaused() {
        portableDidPause = true
    }

    open func broadcastResumed() {
        portableDidResume = true
    }

    open func broadcastFinished() {
        portableDidFinish = true
    }

    open func broadcastAnnotated(withApplicationInfo applicationInfo: [AnyHashable: Any]) {
        portableLastApplicationInfo = applicationInfo
    }

    #if canImport(CoreMedia)
    open func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        _ = sampleBuffer
        portableLastSampleBufferType = sampleBufferType
    }
    #endif

    open func finishBroadcastWithError(_ error: any Error) {
        portableFinishError = error
    }
}
