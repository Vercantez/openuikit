import Foundation

public protocol RoomCaptureViewDelegate: AnyObject, NSCoding {
    func captureView(didPresent processedResult: CapturedRoom, error: (any Error)?)
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (any Error)?) -> Bool
}

extension RoomCaptureViewDelegate {
    public func captureView(didPresent processedResult: CapturedRoom, error: (any Error)?) {
        _ = processedResult
        _ = error
    }

    public func captureView(
        shouldPresent roomDataForProcessing: CapturedRoomData,
        error: (any Error)?
    ) -> Bool {
        _ = roomDataForProcessing
        _ = error
        return true
    }
}

/// Framework-provided scanning view. UIKit layout and AR rendering are
/// unavailable on Linux; construction stores frame and session only.
public class RoomCaptureView: NSObject {
    public var captureSession: RoomCaptureSession!
    public var isModelEnabled: Bool = false
    public weak var delegate: (any RoomCaptureViewDelegate)?

    public private(set) var frame: CGRect

    public override var description: String { "RoomCaptureView" }

    public init(frame: CGRect) {
        self.frame = frame
        self.captureSession = RoomCaptureSession()
        super.init()
    }

    public init(frame: CGRect, arSession: ARSession) {
        self.frame = frame
        self.captureSession = RoomCaptureSession(arSession: arSession)
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func layoutSubviews() {}

    public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        _ = previousTraitCollection
    }

    public var subviews: [UIView] { [] }
}
