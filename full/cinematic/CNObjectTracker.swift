import Foundation

/// Apple ML object tracker. Linux reports `isSupported == false` and never
/// returns a successful track.
public class CNObjectTracker: @unchecked Sendable {
    public static var isSupported: Bool { false }

    private let commandQueue: any MTLCommandQueue
    private var tracking = false

    public init(commandQueue: any MTLCommandQueue) {
        self.commandQueue = commandQueue
    }

    public func findObject(at point: CGPoint, sourceImage: CVPixelBuffer) -> CNBoundsPrediction? {
        _ = point
        _ = sourceImage
        _ = commandQueue
        return nil
    }

    public func startTracking(
        at time: CMTime,
        within normalizedBounds: CGRect,
        sourceImage: CVPixelBuffer,
        sourceDisparity: CVPixelBuffer
    ) -> Bool {
        _ = time
        _ = normalizedBounds
        _ = sourceImage
        _ = sourceDisparity
        tracking = false
        return false
    }

    public func continueTracking(
        at time: CMTime,
        sourceImage: CVPixelBuffer,
        sourceDisparity: CVPixelBuffer
    ) -> CNBoundsPrediction? {
        _ = time
        _ = sourceImage
        _ = sourceDisparity
        return nil
    }

    public func resetDetectionTrack() {
        tracking = false
    }

    public func finishDetectionTrack() -> CNDetectionTrack {
        _ = tracking
        return CNCustomDetectionTrack(detections: [], smooth: false)
    }
}
