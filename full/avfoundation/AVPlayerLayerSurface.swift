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
