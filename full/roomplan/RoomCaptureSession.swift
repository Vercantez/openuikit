import Foundation

/// An object that manages the room-scanning process.
public class RoomCaptureSession {
    public struct Configuration {
        /// Default is `true` per the pinned symbol-graph documentation.
        public var isCoachingEnabled: Bool

        public init() {
            self.isCoachingEnabled = true
        }
    }

    public enum CaptureError: Swift.Error, LocalizedError, Equatable, Hashable, Sendable {
        case exceedSceneSizeLimit
        case worldTrackingFailure
        case invalidARConfiguration
        case deviceTooHot
        case deviceNotSupported
        case internalError

        public var errorDescription: String? {
            switch self {
            case .exceedSceneSizeLimit:
                return "The scene size grew past the framework's limitations."
            case .worldTrackingFailure:
                return "The underlying ARKit session failed."
            case .invalidARConfiguration:
                return "The ARKit session ran an unsupported configuration."
            case .deviceTooHot:
                return "Device thermal metrics surpassed the framework's limitations."
            case .deviceNotSupported:
                return "The framework doesn't support the user's device."
            case .internalError:
                return "The framework encountered an unexpected error case."
            }
        }
    }

    public enum Instruction: Equatable, Hashable, Sendable {
        case moveCloseToWall
        case moveAwayFromWall
        case slowDown
        case turnOnLight
        case normal
        case lowTexture
    }

    /// LiDAR is required. Linux never reports support.
    public static var isSupported: Bool { false }

    public weak var delegate: (any RoomCaptureSessionDelegate)?
    public var arSession: ARSession {
        didSet {
            arSessionReplacedByClient = true
        }
    }

    private var arSessionReplacedByClient = false
    private var isRunning = false

    public init() {
        self.arSession = ARSession()
    }

    public init(arSession: ARSession? = nil) {
        self.arSession = arSession ?? ARSession()
    }

    /// Never starts a scan on Linux. Delivers `didEndWith` on the caller
    /// thread so tests can observe the fail-closed error without a run loop.
    public func run(configuration: Configuration) {
        _ = configuration
        isRunning = false
        let data = CapturedRoomData()
        let error: CaptureError
        if arSessionReplacedByClient {
            error = .invalidARConfiguration
        } else {
            error = .deviceNotSupported
        }
        delegate?.captureSession(self, didEndWith: data, error: error)
    }

    public func stop() {
        stop(pauseARSession: true)
    }

    public func stop(pauseARSession: Bool = true) {
        _ = pauseARSession
        guard isRunning else { return }
        isRunning = false
        delegate?.captureSession(self, didEndWith: CapturedRoomData(), error: nil)
    }
}

public protocol RoomCaptureSessionDelegate: AnyObject {
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom)
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom)
    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom)
    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom)
    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction)
    func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration)
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?)
}

extension RoomCaptureSessionDelegate {
    public func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        _ = session
        _ = room
    }

    public func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        _ = session
        _ = room
    }

    public func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        _ = session
        _ = room
    }

    public func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        _ = session
        _ = room
    }

    public func captureSession(
        _ session: RoomCaptureSession,
        didProvide instruction: RoomCaptureSession.Instruction
    ) {
        _ = session
        _ = instruction
    }

    public func captureSession(
        _ session: RoomCaptureSession,
        didStartWith configuration: RoomCaptureSession.Configuration
    ) {
        _ = session
        _ = configuration
    }

    public func captureSession(
        _ session: RoomCaptureSession,
        didEndWith data: CapturedRoomData,
        error: (any Error)?
    ) {
        _ = session
        _ = data
        _ = error
    }
}
