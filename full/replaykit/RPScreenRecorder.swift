import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

public protocol RPScreenRecorderDelegate: NSObjectProtocol {
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder)
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
}

extension RPScreenRecorderDelegate {
    public func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        _ = screenRecorder
    }

    #if canImport(UIKit)
    public func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWithError error: any Error,
        previewViewController: RPPreviewViewController?
    ) {
        _ = screenRecorder
        _ = error
        _ = previewViewController
    }

    public func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    ) {
        _ = screenRecorder
        _ = previewViewController
        _ = error
    }
    #endif
}

public final class RPScreenRecorder: NSObject {
    private static let sharedInstance = RPScreenRecorder()

    private let state = ReplayKitStateLock()
    private weak var storedDelegate: (any RPScreenRecorderDelegate)?
    private var recordingFlag = false
    private var cameraEnabledFlag = false
    private var microphoneEnabledFlag = false
    private var storedCameraPosition = RPCameraPosition.front
    private var clipBufferingFlag = false

    private override init() {
        super.init()
    }

    public class func shared() -> RPScreenRecorder {
        sharedInstance
    }

    public var isAvailable: Bool { false }

    public var isRecording: Bool {
        state.withLock { recordingFlag }
    }

    public var isCameraEnabled: Bool {
        get { state.withLock { cameraEnabledFlag } }
        set { state.withLock { cameraEnabledFlag = newValue } }
    }

    public var isMicrophoneEnabled: Bool {
        get { state.withLock { microphoneEnabledFlag } }
        set { state.withLock { microphoneEnabledFlag = newValue } }
    }

    public var cameraPosition: RPCameraPosition {
        get { state.withLock { storedCameraPosition } }
        set { state.withLock { storedCameraPosition = newValue } }
    }

    public weak var delegate: (any RPScreenRecorderDelegate)? {
        get { state.withLock { storedDelegate } }
        set { state.withLock { storedDelegate = newValue } }
    }

    #if canImport(UIKit)
    public var cameraPreviewView: UIView? { nil }
    #endif

    public func startRecording(handler: (((any Error)?) -> Void)? = nil) {
        replayKitDeliverPrivate {
            handler?(replayKitDisabledError())
        }
    }

    public func startRecording(
        withMicrophoneEnabled microphoneEnabled: Bool,
        handler: (((any Error)?) -> Void)? = nil
    ) {
        state.withLock { microphoneEnabledFlag = microphoneEnabled }
        startRecording(handler: handler)
    }

    public func stopRecording(withOutput url: URL) async throws {
        _ = url
        throw replayKitNotRecordingError()
    }

    public func discardRecording(handler: @escaping () -> Void) {
        replayKitDeliverPrivate(handler)
    }

    public func startClipBuffering(completionHandler: (((any Error)?) -> Void)? = nil) {
        replayKitDeliverPrivate {
            completionHandler?(replayKitDisabledError())
        }
    }

    public func stopClipBuffering(completionHandler: (((any Error)?) -> Void)? = nil) {
        let buffering = state.withLock { clipBufferingFlag }
        replayKitDeliverPrivate {
            if buffering {
                completionHandler?(nil)
            } else {
                completionHandler?(replayKitDisabledError())
            }
        }
    }

    public func exportClip(to url: URL, duration: TimeInterval) async throws {
        _ = url
        _ = duration
        throw replayKitDisabledError()
    }

    public func stopCapture(handler: (((any Error)?) -> Void)? = nil) {
        replayKitDeliverPrivate {
            handler?(replayKitDisabledError())
        }
    }

    #if canImport(CoreMedia)
    public func startCapture(
        handler captureHandler: ((CMSampleBuffer, RPSampleBufferType, (any Error)?) -> Void)?
    ) async throws {
        _ = captureHandler
        throw replayKitDisabledError()
    }
    #endif

    #if canImport(UIKit)
    public func stopRecording(
        handler: ((RPPreviewViewController?, (any Error)?) -> Void)? = nil
    ) {
        replayKitDeliverPrivate {
            handler?(nil, replayKitNotRecordingError())
        }
    }
    #endif
}

#if canImport(UIKit)
@MainActor
public protocol RPPreviewViewControllerDelegate: NSObjectProtocol {
    @MainActor
    func previewControllerDidFinish(_ previewController: RPPreviewViewController)

    @MainActor
    func previewController(
        _ previewController: RPPreviewViewController,
        didFinishWithActivityTypes activityTypes: Set<String>
    )
}

extension RPPreviewViewControllerDelegate {
    @MainActor
    public func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        _ = previewController
    }

    @MainActor
    public func previewController(
        _ previewController: RPPreviewViewController,
        didFinishWithActivityTypes activityTypes: Set<String>
    ) {
        _ = previewController
        _ = activityTypes
    }
}

@MainActor
open class RPPreviewViewController: UIViewController {
    @MainActor
    public weak var previewControllerDelegate: (any RPPreviewViewControllerDelegate)?

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
