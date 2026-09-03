@_exported import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

// MARK: - String constants
//
// Darwin NSString payloads were not measured on device. Linux uses the public
// identifier spelling as a source-compatible fallback. The RPRecordingErrorDomain
// spelling matches the pinned-independent-bindings ErrorDomain attribute
// (`dotnet-macios` `ReplayKit/RPEnums.cs`). Coverage records these rows as
// `declared`, not Apple-observed bytes.

public let RPRecordingErrorDomain = "RPRecordingErrorDomain"
public let RPApplicationInfoBundleIdentifierKey = "RPApplicationInfoBundleIdentifierKey"
public let RPVideoSampleOrientationKey = "RPVideoSampleOrientationKey"
public let SCStreamErrorDomain = "SCStreamErrorDomain"

// MARK: - Public enums
//
// Explicit raw values follow pinned-independent-bindings
// (`dotnet-macios` `src/ReplayKit/RPEnums.cs`: Video/Front start at 1;
// RPRecordingError unknown starts at -5800; codeSuccessful is 0, matching the
// binding's `None`). Isolated tests exercise constructibility, inequality,
// hashing, and rawValue round-trip. They do not claim an on-device Darwin dump.

public enum RPCameraPosition: Int, Sendable, Equatable, Hashable {
    case front = 1
    case back = 2
}

public enum RPSampleBufferType: Int, Sendable, Equatable, Hashable {
    case video = 1
    case audioApp = 2
    case audioMic = 3
}

public enum RPRecordingErrorCode: Int, Sendable, Equatable, Hashable {
    case codeSuccessful = 0
    case unknown = -5800
    case userDeclined = -5801
    case disabled = -5802
    case failedToStart = -5803
    case failed = -5804
    case insufficientStorage = -5805
    case interrupted = -5806
    case contentResize = -5807
    case broadcastInvalidSession = -5808
    case systemDormancy = -5809
    case entitlements = -5810
    case activePhoneCall = -5811
    case failedToSave = -5812
    case carPlay = -5813
    case failedApplicationConnectionInvalid = -5814
    case failedApplicationConnectionInterrupted = -5815
    case failedNoMatchingApplicationContext = -5816
    case failedMediaServicesFailure = -5817
    case videoMixingFailure = -5818
    case broadcastSetupFailed = -5819
    case failedToObtainURL = -5820
    case failedIncorrectTimeStamps = -5821
    case failedToProcessFirstSample = -5822
    case failedAssetWriterFailedToSave = -5823
    case failedNoAssetWriter = -5824
    case failedAssetWriterInWrongState = -5825
    case failedAssetWriterExportFailed = -5826
    case failedToRemoveFile = -5827
    case failedAssetWriterExportCanceled = -5828
    case attemptToStopNonRecording = -5829
    case attemptToStartInRecordingState = -5830
    case photoFailure = -5831
    case recordingInvalidSession = -5832
    case failedToStartCaptureStack = -5833
    case invalidParameter = -5834
    case filePermissions = -5835
    case exportClipToURLInProgress = -5836
}

func replayKitError(
    _ code: RPRecordingErrorCode,
    description: String
) -> NSError {
    NSError(
        domain: RPRecordingErrorDomain,
        code: code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: description]
    )
}

func replayKitDisabledError() -> NSError {
    replayKitError(
        .disabled,
        description: "ReplayKit capture, broadcast, and Apple recording services are unavailable on this Linux host"
    )
}

func replayKitEntitlementError() -> NSError {
    replayKitError(
        .entitlements,
        description: "ReplayKit broadcast entitlements and Apple broadcast services are unavailable on this Linux host"
    )
}

func replayKitInvalidSessionError() -> NSError {
    replayKitError(
        .broadcastInvalidSession,
        description: "ReplayKit broadcast session is not active"
    )
}

func replayKitNotRecordingError() -> NSError {
    replayKitError(
        .attemptToStopNonRecording,
        description: "ReplayKit is not recording"
    )
}

// MARK: - Host delivery

final class ReplayKitStateLock {
    private let lock = NSLock()

    func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

final class ReplayKitUncheckedWork: @unchecked Sendable {
    let body: () -> Void

    init(body: @escaping () -> Void) {
        self.body = body
    }
}

final class ReplayKitOnceFlag {
    private let lock = NSLock()
    private var delivered = false

    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if delivered {
            return false
        }
        delivered = true
        return true
    }
}

let replayKitPrivateQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "ReplayKit.completion"
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

func replayKitDeliver(on queue: OperationQueue, _ body: @escaping () -> Void) {
    let once = ReplayKitOnceFlag()
    let work = ReplayKitUncheckedWork(body: body)
    queue.addOperation {
        guard once.take() else { return }
        work.body()
    }
}

func replayKitDeliverPrivate(_ body: @escaping () -> Void) {
    replayKitDeliver(on: replayKitPrivateQueue, body)
}

enum ReplayKitArchive {
    static let markerKey = "OpenUIKit.ReplayKit.archive"

    static func encodeMarker(_ coder: NSCoder) {
        coder.encode(true, forKey: markerKey)
    }

    static func hasMarker(_ coder: NSCoder) -> Bool {
        coder.containsValue(forKey: markerKey) && coder.decodeBool(forKey: markerKey)
    }
}

/// Linux host-test control. Hidden from ordinary `import ReplayKit` clients.
@_spi(OpenUIKitHost)
public enum ReplayKitHostControl {
    public static var completionQueue: OperationQueue { replayKitPrivateQueue }

    public static func enqueueCompletionProbe(_ body: @escaping () -> Void) {
        replayKitDeliverPrivate(body)
    }

    public static func enqueueCompletionProbe(
        on queue: OperationQueue,
        _ body: @escaping () -> Void
    ) {
        replayKitDeliver(on: queue, body)
    }

    public static func handlerBroadcastURL(_ handler: RPBroadcastHandler) -> URL? {
        handler.hostBroadcastURL()
    }

    public static func handlerServiceInfoKeys(_ handler: RPBroadcastHandler) -> [String] {
        handler.hostServiceInfoKeys()
    }

    public static func sampleHandlerFinishError(_ handler: RPBroadcastSampleHandler) -> (any Error)? {
        handler.hostFinishError()
    }
}

#if canImport(UIKit)
extension NSExtensionContext {
    public func completeRequest(
        withBroadcast broadcastURL: URL,
        broadcastConfiguration: RPBroadcastConfiguration,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        _ = broadcastURL
        _ = broadcastConfiguration
        _ = setupInfo
    }

    public func completeRequest(
        withBroadcast broadcastURL: URL,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        _ = broadcastURL
        _ = setupInfo
    }

    public func loadBroadcastingApplicationInfo(
        completion handler: @escaping (String, String, UIImage?) -> Void
    ) {
        replayKitDeliverPrivate {
            handler("", "", nil)
        }
    }
}
#endif
