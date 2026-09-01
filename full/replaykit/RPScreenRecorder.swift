import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreMedia)
import CoreMedia
#endif

public protocol RPScreenRecorderDelegate: NSObjectProtocol {
    #if canImport(UIKit)
    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWithError error: any Error,
        previewViewController: RPPreviewViewController?
    )

    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    )
    #endif

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder)
}

public extension RPScreenRecorderDelegate {
    #if canImport(UIKit)
    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWithError error: any Error,
        previewViewController: RPPreviewViewController?
    ) {
        _ = (screenRecorder, error, previewViewController)
    }

    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    ) {
        _ = (screenRecorder, previewViewController, error)
    }
    #endif

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        _ = screenRecorder
    }
}

/// Shared screen recorder. Without a ReplayKit capture stack, availability
/// stays false and every start path fails closed. Camera preview, sample
/// capture, and preview-controller stop APIs are compiled only against real
/// UIKit and CoreMedia types.
open class RPScreenRecorder: NSObject, @unchecked Sendable {
    private static let sharedRecorder = RPScreenRecorder()

    private let lock = NSLock()
    private var microphoneEnabled = false
    private var cameraEnabled = false
    private var storedCameraPosition = RPCameraPosition.front
    private weak var storedDelegate: RPScreenRecorderDelegate?

    private override init() {
        super.init()
    }

    open class func shared() -> RPScreenRecorder {
        sharedRecorder
    }

    open weak var delegate: RPScreenRecorderDelegate? {
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

    open var isAvailable: Bool { false }

    open var isRecording: Bool { false }

    open var isMicrophoneEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return microphoneEnabled
        }
        set {
            lock.lock()
            microphoneEnabled = newValue
            lock.unlock()
        }
    }

    open var isCameraEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return cameraEnabled
        }
        set {
            lock.lock()
            cameraEnabled = newValue
            lock.unlock()
        }
    }

    open var cameraPosition: RPCameraPosition {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedCameraPosition
        }
        set {
            lock.lock()
            storedCameraPosition = newValue
            lock.unlock()
        }
    }

    #if canImport(UIKit)
    open var cameraPreviewView: UIView? { nil }
    #endif

    open func startRecording(handler: (((any Error)?) -> Void)? = nil) {
        handler?(replayKitUnavailableError(.failedToStartCaptureStack))
    }

    open func startRecording(
        withMicrophoneEnabled microphoneEnabled: Bool,
        handler: (((any Error)?) -> Void)? = nil
    ) {
        isMicrophoneEnabled = microphoneEnabled
        startRecording(handler: handler)
    }

    #if canImport(UIKit)
    open func stopRecording(
        handler: ((RPPreviewViewController?, (any Error)?) -> Void)? = nil
    ) {
        handler?(nil, replayKitUnavailableError(.attemptToStopNonRecording))
    }
    #endif

    open func stopRecording(
        withOutput url: URL,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = url
        completionHandler?(replayKitUnavailableError(.attemptToStopNonRecording))
    }

    open func stopRecording(withOutput url: URL) async throws {
        _ = url
        throw replayKitUnavailableError(.attemptToStopNonRecording)
    }

    open func discardRecording(handler: @escaping () -> Void) {
        handler()
    }

    #if canImport(CoreMedia)
    open func startCapture(
        handler captureHandler: (
            (CMSampleBuffer, RPSampleBufferType, (any Error)?) -> Void
        )?,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = captureHandler
        completionHandler?(replayKitUnavailableError(.failedToStartCaptureStack))
    }

    open func startCapture(
        handler captureHandler: (
            (CMSampleBuffer, RPSampleBufferType, (any Error)?) -> Void
        )?
    ) async throws {
        _ = captureHandler
        throw replayKitUnavailableError(.failedToStartCaptureStack)
    }
    #endif

    open func stopCapture(handler: (((any Error)?) -> Void)? = nil) {
        handler?(replayKitUnavailableError(.attemptToStopNonRecording))
    }

    open func startClipBuffering(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        completionHandler?(replayKitUnavailableError(.failedToStartCaptureStack))
    }

    open func startClipBuffering() async throws {
        throw replayKitUnavailableError(.failedToStartCaptureStack)
    }

    open func stopClipBuffering(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        completionHandler?(replayKitUnavailableError(.attemptToStopNonRecording))
    }

    open func stopClipBuffering() async throws {
        throw replayKitUnavailableError(.attemptToStopNonRecording)
    }

    open func exportClip(
        to url: URL,
        duration: TimeInterval,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = (url, duration)
        completionHandler?(replayKitUnavailableError(.failedToObtainURL))
    }

    open func exportClip(to url: URL, duration: TimeInterval) async throws {
        _ = (url, duration)
        throw replayKitUnavailableError(.failedToObtainURL)
    }
}
