import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

/// Linux-local unstarted URL. Darwin's pre-start `broadcastURL` is unobserved.
private let replayKitUnstartedBroadcastURL = URL(string: "replaykit://unstarted")!

public final class RPBroadcastConfiguration: NSObject, NSSecureCoding {
    public class var supportsSecureCoding: Bool { true }

    private let state = ReplayKitStateLock()
    private var storedClipDuration: TimeInterval = 0
    private var storedCompression: [String: any NSSecureCoding & NSObjectProtocol]?

    public override init() {
        super.init()
    }

    public var clipDuration: TimeInterval {
        get { state.withLock { storedClipDuration } }
        set { state.withLock { storedClipDuration = newValue } }
    }

    public var videoCompressionProperties: [String: any NSSecureCoding & NSObjectProtocol]? {
        get { state.withLock { storedCompression } }
        set { state.withLock { storedCompression = newValue } }
    }

    public required init?(coder: NSCoder) {
        guard ReplayKitArchive.hasMarker(coder) else { return nil }
        storedClipDuration = coder.decodeDouble(forKey: "clipDuration")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        ReplayKitArchive.encodeMarker(coder)
        coder.encode(clipDuration, forKey: "clipDuration")
    }
}

public protocol RPBroadcastControllerDelegate: NSObjectProtocol {
    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didFinishWithError error: (any Error)?
    )
    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateBroadcast broadcastURL: URL
    )
    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateServiceInfo serviceInfo: [String: any NSCoding & NSObjectProtocol]
    )
}

extension RPBroadcastControllerDelegate {
    public func broadcastController(
        _ broadcastController: RPBroadcastController,
        didFinishWithError error: (any Error)?
    ) {
        _ = broadcastController
        _ = error
    }

    public func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateBroadcast broadcastURL: URL
    ) {
        _ = broadcastController
        _ = broadcastURL
    }

    public func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateServiceInfo serviceInfo: [String: any NSCoding & NSObjectProtocol]
    ) {
        _ = broadcastController
        _ = serviceInfo
    }
}

public final class RPBroadcastController: NSObject {
    private let state = ReplayKitStateLock()
    private weak var storedDelegate: (any RPBroadcastControllerDelegate)?
    private var broadcastingFlag = false
    private var pausedFlag = false
    private var storedBroadcastURL = replayKitUnstartedBroadcastURL
    private var storedServiceInfo: [String: any NSCoding & NSObjectProtocol]?
    private var storedExtensionBundleID: String?

    public override init() {
        super.init()
    }

    public var isBroadcasting: Bool {
        state.withLock { broadcastingFlag }
    }

    public var isPaused: Bool {
        state.withLock { pausedFlag }
    }

    public var broadcastURL: URL {
        state.withLock { storedBroadcastURL }
    }

    public var serviceInfo: [String: any NSCoding & NSObjectProtocol]? {
        state.withLock { storedServiceInfo }
    }

    public var broadcastExtensionBundleID: String? {
        state.withLock { storedExtensionBundleID }
    }

    public weak var delegate: (any RPBroadcastControllerDelegate)? {
        get { state.withLock { storedDelegate } }
        set { state.withLock { storedDelegate = newValue } }
    }

    public func startBroadcast(handler: @escaping ((any Error)?) -> Void) {
        replayKitDeliverPrivate {
            handler(replayKitEntitlementError())
        }
    }

    public func pauseBroadcast() {
        state.withLock {
            if broadcastingFlag {
                pausedFlag = true
            }
        }
    }

    public func resumeBroadcast() {
        state.withLock {
            if broadcastingFlag {
                pausedFlag = false
            }
        }
    }

    public func finishBroadcast(handler: @escaping ((any Error)?) -> Void) {
        let active = state.withLock { broadcastingFlag }
        replayKitDeliverPrivate {
            if active {
                handler(nil)
            } else {
                handler(replayKitInvalidSessionError())
            }
        }
    }
}

open class RPBroadcastHandler: NSObject {
    private let state = ReplayKitStateLock()
    private var storedURL: URL?
    private var storedInfo: [String: any NSCoding & NSObjectProtocol] = [:]

    public override init() {
        super.init()
    }

    open func updateBroadcast(_ broadcastURL: URL) {
        state.withLock { storedURL = broadcastURL }
    }

    open func updateServiceInfo(_ serviceInfo: [String: any NSCoding & NSObjectProtocol]) {
        state.withLock { storedInfo = serviceInfo }
    }

    func hostBroadcastURL() -> URL? {
        state.withLock { storedURL }
    }

    func hostServiceInfoKeys() -> [String] {
        state.withLock { Array(storedInfo.keys).sorted() }
    }
}

open class RPBroadcastMP4ClipHandler: RPBroadcastHandler {
    open func processMP4Clip(
        with mp4ClipURL: URL?,
        setupInfo: [String: NSObject]?,
        finished: Bool
    ) {
        _ = mp4ClipURL
        _ = setupInfo
        _ = finished
    }

    open func finishedProcessingMP4Clip(
        withUpdatedBroadcastConfiguration broadcastConfiguration: RPBroadcastConfiguration?,
        error: (any Error)?
    ) {
        _ = broadcastConfiguration
        _ = error
    }
}

open class RPBroadcastSampleHandler: RPBroadcastHandler {
    private let finishLock = ReplayKitStateLock()
    private var storedFinishError: (any Error)?

    open func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        _ = setupInfo
    }

    open func broadcastPaused() {}

    open func broadcastResumed() {}

    open func broadcastFinished() {}

    open func broadcastAnnotated(withApplicationInfo applicationInfo: [AnyHashable: Any]) {
        _ = applicationInfo
    }

    open func finishBroadcastWithError(_ error: any Error) {
        finishLock.withLock { storedFinishError = error }
    }

    #if canImport(CoreMedia)
    open func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        _ = sampleBuffer
        _ = sampleBufferType
    }
    #endif

    func hostFinishError() -> (any Error)? {
        finishLock.withLock { storedFinishError }
    }
}

#if canImport(UIKit)
@MainActor
public protocol RPBroadcastActivityViewControllerDelegate: NSObjectProtocol {
    @MainActor
    func broadcastActivityViewController(
        _ broadcastActivityViewController: RPBroadcastActivityViewController,
        didFinishWith broadcastController: RPBroadcastController?,
        error: (any Error)?
    )
}

@MainActor
open class RPBroadcastActivityViewController: UIViewController {
    @MainActor
    public weak var delegate: (any RPBroadcastActivityViewControllerDelegate)?

    @MainActor
    public class func load(
        handler: @escaping (RPBroadcastActivityViewController?, (any Error)?) -> Void
    ) {
        replayKitDeliverPrivate {
            handler(nil, replayKitEntitlementError())
        }
    }

    @MainActor
    public class func load(
        withPreferredExtension preferredExtension: String?,
        handler: @escaping (RPBroadcastActivityViewController?, (any Error)?) -> Void
    ) {
        _ = preferredExtension
        load(handler: handler)
    }
}

@MainActor
open class RPSystemBroadcastPickerView: UIView {
    @MainActor
    public var preferredExtension: String?

    @MainActor
    public var showsMicrophoneButton: Bool = true

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
