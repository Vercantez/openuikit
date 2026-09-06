import Dispatch
import Foundation
#if canImport(QuartzCore)
import QuartzCore
#endif

/// Video layer. Subclasses `CALayer` when QuartzCore is importable; otherwise
/// the host lookalike in `AVHostLookalikes.swift`. No frames are decoded.
open class AVPlayerLayer: CALayer, @unchecked Sendable {
    private let layerLock = NSLock()
    private var storedPlayer: AVPlayer?
    // Apple default is AVLayerVideoGravityResizeAspect (AVPlayerLayer.videoGravity).
    // Measured testAVPlayerLayerVideoGravity: playerLayer(with:) starts at
    // resizeAspect; isReadyForDisplay is false (no decoded frame on Linux).
    private var storedGravity = AVLayerVideoGravity.resizeAspect

    public override init() {
        super.init()
    }

#if canImport(QuartzCore)
    public override init(layer: Any) {
        super.init(layer: layer)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
#endif

    public init(player: AVPlayer?) {
        storedPlayer = player
        super.init()
    }

    public class func playerLayer(with player: AVPlayer?) -> AVPlayerLayer {
        AVPlayerLayer(player: player)
    }

    public var player: AVPlayer? {
        get { layerLock.withLock { storedPlayer } }
        set { layerLock.withLock { storedPlayer = newValue } }
    }

    public var videoGravity: AVLayerVideoGravity {
        get { layerLock.withLock { storedGravity } }
        set { layerLock.withLock { storedGravity = newValue } }
    }

    /// False on Linux: no decoded frame exists (Apple: first frame ready for display).
    public var isReadyForDisplay: Bool { false }

    public var videoRect: CGRect { bounds }

    public var pixelBufferAttributes: [String: Any]? {
        get { nil }
        set { _ = newValue }
    }

    public func copyDisplayedPixelBuffer() -> CVPixelBuffer? { nil }

    public func displayedReadOnlyPixelBuffer() -> CVReadOnlyPixelBuffer? { nil }
}

/// Sample-buffer display layer. Subclasses `CALayer` like `AVPlayerLayer`.
/// Linux has no decoder: enqueue fail-closes with `AVError.decoderNotFound`.
open class AVSampleBufferDisplayLayer: CALayer, AVQueuedSampleBufferRendering, @unchecked Sendable {
    private let layerLock = NSLock()
    private var storedGravity = AVLayerVideoGravity.resizeAspect
    private var storedControlTimebase: CMTimebase?
    private var storedPreventsCapture = false
    private var storedPreventsDisplaySleep = true
    private var storedStatus = AVQueuedSampleBufferRenderingStatus.unknown
    private var storedError: (any Error)?
    private var storedRequiresFlush = false
    private var storedReadyRequest: (() -> Void)?
    private let storedRenderer = AVSampleBufferVideoRenderer()
    private let storedTimebase = CMTimebase()

    public override init() {
        super.init()
    }

#if canImport(QuartzCore)
    public override init(layer: Any) {
        super.init(layer: layer)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
#endif

    public var videoGravity: AVLayerVideoGravity {
        get { layerLock.withLock { storedGravity } }
        set { layerLock.withLock { storedGravity = newValue } }
    }

    public var isReadyForDisplay: Bool { false }
    public var isReadyForMoreMediaData: Bool { false }
    public var hasSufficientMediaDataForReliablePlaybackStart: Bool { false }
    public var isOutputObscuredDueToInsufficientExternalProtection: Bool { false }

    public var status: AVQueuedSampleBufferRenderingStatus {
        layerLock.withLock { storedStatus }
    }
    public var error: (any Error)? {
        layerLock.withLock { storedError }
    }
    public var requiresFlushToResumeDecoding: Bool {
        layerLock.withLock { storedRequiresFlush }
    }

    public var controlTimebase: CMTimebase? {
        get { layerLock.withLock { storedControlTimebase } }
        set { layerLock.withLock { storedControlTimebase = newValue } }
    }
    public var timebase: CMTimebase { storedTimebase }
    public var sampleBufferRenderer: AVSampleBufferVideoRenderer { storedRenderer }

    public var preventsCapture: Bool {
        get { layerLock.withLock { storedPreventsCapture } }
        set { layerLock.withLock { storedPreventsCapture = newValue } }
    }
    public var preventsDisplaySleepDuringVideoPlayback: Bool {
        get { layerLock.withLock { storedPreventsDisplaySleep } }
        set { layerLock.withLock { storedPreventsDisplaySleep = newValue } }
    }

    public func enqueue(_ sampleBuffer: CMSampleBuffer) {
        _ = sampleBuffer
        layerLock.lock()
        storedStatus = .failed
        storedError = AVError(.decoderNotFound)
        storedRequiresFlush = true
        layerLock.unlock()
    }

    public func flush() {
        layerLock.lock()
        storedRequiresFlush = false
        layerLock.unlock()
    }

    public func flushAndRemoveImage() {
        flush()
    }

    public func requestMediaDataWhenReady(on queue: DispatchQueue, using block: @escaping () -> Void) {
        _ = queue
        layerLock.lock()
        storedReadyRequest = block
        layerLock.unlock()
    }

    public func stopRequestingMediaData() {
        layerLock.lock()
        storedReadyRequest = nil
        layerLock.unlock()
    }
}
