import Foundation
import ReplayKit

private final class RecorderDelegateProbe: NSObject, RPScreenRecorderDelegate {}
private final class BroadcastDelegateProbe: NSObject, RPBroadcastControllerDelegate {}
private final class PreviewDelegateProbe: NSObject, RPPreviewViewControllerDelegate {}
private final class ActivityDelegateProbe: NSObject, RPBroadcastActivityViewControllerDelegate {
    func broadcastActivityViewController(
        _ broadcastActivityViewController: RPBroadcastActivityViewController,
        didFinishWith broadcastController: RPBroadcastController?,
        error: (any Error)?
    ) {
        _ = (broadcastActivityViewController, broadcastController, error)
    }
}

private final class SampleHandlerProbe: RPBroadcastSampleHandler, @unchecked Sendable {
    var started = false

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        super.broadcastStarted(withSetupInfo: setupInfo)
        started = true
    }
}

private func requireCode(_ error: (any Error)?, _ expected: RPRecordingErrorCode) {
    guard let code = error as? RPRecordingErrorCode else {
        fatalError("expected RPRecordingErrorCode, got \(String(describing: error))")
    }
    precondition(code == expected)
    precondition(code.errorCode == expected.rawValue)
    precondition(RPRecordingErrorCode.errorDomain == RPRecordingErrorDomain)
}

private final class AsyncErrorBox: @unchecked Sendable {
    var error: (any Error)?
}

private func runAsync(_ body: @escaping @Sendable () async throws -> Void) -> (any Error)? {
    let box = AsyncErrorBox()
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            try await body()
        } catch {
            box.error = error
        }
        semaphore.signal()
    }
    semaphore.wait()
    return box.error
}

private func runOnMain<T>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
        MainActor.assumeIsolated(body)
    }
}

precondition(RPRecordingErrorDomain == "RPRecordingErrorDomain")
precondition(!RPApplicationInfoBundleIdentifierKey.isEmpty)
precondition(!RPVideoSampleOrientationKey.isEmpty)
precondition(!SCStreamErrorDomain.isEmpty)

precondition(RPCameraPosition.front.rawValue == 1)
precondition(RPCameraPosition.back.rawValue == 2)
precondition(RPCameraPosition(rawValue: 1) == .front)
precondition(RPCameraPosition.front != RPCameraPosition.back)
var cameraHasher = Hasher()
RPCameraPosition.front.hash(into: &cameraHasher)
_ = RPCameraPosition.front.hashValue

precondition(RPSampleBufferType.video.rawValue == 1)
precondition(RPSampleBufferType.audioApp.rawValue == 2)
precondition(RPSampleBufferType.audioMic.rawValue == 3)
precondition(RPSampleBufferType(rawValue: 2) == .audioApp)
precondition(RPSampleBufferType.video != .audioMic)
_ = RPSampleBufferType.audioApp.hashValue

precondition(RPRecordingErrorCode.unknown.rawValue == -5800)
precondition(RPRecordingErrorCode.userDeclined.rawValue == -5801)
precondition(RPRecordingErrorCode.disabled.rawValue == -5802)
precondition(RPRecordingErrorCode.failedToStart.rawValue == -5803)
precondition(RPRecordingErrorCode.failed.rawValue == -5804)
precondition(RPRecordingErrorCode.insufficientStorage.rawValue == -5805)
precondition(RPRecordingErrorCode.interrupted.rawValue == -5806)
precondition(RPRecordingErrorCode.contentResize.rawValue == -5807)
precondition(RPRecordingErrorCode.broadcastInvalidSession.rawValue == -5808)
precondition(RPRecordingErrorCode.systemDormancy.rawValue == -5809)
precondition(RPRecordingErrorCode.entitlements.rawValue == -5810)
precondition(RPRecordingErrorCode.activePhoneCall.rawValue == -5811)
precondition(RPRecordingErrorCode.failedToSave.rawValue == -5812)
precondition(RPRecordingErrorCode.carPlay.rawValue == -5813)
precondition(RPRecordingErrorCode.failedToStartCaptureStack.rawValue == -5833)
precondition(RPRecordingErrorCode.exportClipToURLInProgress.rawValue == -5836)
precondition(RPRecordingErrorCode.codeSuccessful.rawValue == 0)
precondition(RPRecordingErrorCode(rawValue: -5829) == .attemptToStopNonRecording)
precondition(RPRecordingErrorCode.failed != .unknown)
_ = RPRecordingErrorCode.failed.hashValue
var errorHasher = Hasher()
RPRecordingErrorCode.failed.hash(into: &errorHasher)

let recorder = RPScreenRecorder.shared()
precondition(recorder === RPScreenRecorder.shared())
precondition(!recorder.isAvailable)
precondition(!recorder.isRecording)
precondition(recorder.cameraPreviewView == nil)

recorder.isMicrophoneEnabled = true
recorder.isCameraEnabled = true
recorder.cameraPosition = .back
precondition(recorder.isMicrophoneEnabled)
precondition(recorder.isCameraEnabled)
precondition(recorder.cameraPosition == .back)
recorder.cameraPosition = .front
precondition(recorder.cameraPosition == .front)

private let recorderDelegate = RecorderDelegateProbe()
recorder.delegate = recorderDelegate
precondition(recorder.delegate === recorderDelegate)
recorderDelegate.screenRecorderDidChangeAvailability(recorder)

recorder.startRecording { error in
    requireCode(error, .failedToStartCaptureStack)
}
recorder.startRecording(withMicrophoneEnabled: true) { error in
    requireCode(error, .failedToStartCaptureStack)
}
precondition(recorder.isMicrophoneEnabled)
precondition(!recorder.isRecording)

recorder.stopRecording { preview, error in
    precondition(preview == nil)
    requireCode(error, .attemptToStopNonRecording)
}
recorder.stopRecording(withOutput: URL(fileURLWithPath: "/tmp/out.mp4")) { error in
    requireCode(error, .attemptToStopNonRecording)
}

var discarded = false
recorder.discardRecording { discarded = true }
precondition(discarded)

recorder.startCapture(handler: { _, _, _ in
    fatalError("capture handler must not receive fabricated samples")
}) { error in
    requireCode(error, .failedToStartCaptureStack)
}
recorder.stopCapture { error in
    requireCode(error, .attemptToStopNonRecording)
}
recorder.startClipBuffering { error in
    requireCode(error, .failedToStartCaptureStack)
}
recorder.stopClipBuffering { error in
    requireCode(error, .attemptToStopNonRecording)
}
recorder.exportClip(to: URL(fileURLWithPath: "/tmp/replaykit-clip.mp4"), duration: 5) {
    error in
    requireCode(error, .failedToObtainURL)
}

if let error = runAsync({ try await recorder.startCapture(handler: nil) }) {
    requireCode(error, .failedToStartCaptureStack)
} else {
    fatalError("startCapture must fail closed")
}
if let error = runAsync({
    try await recorder.stopRecording(withOutput: URL(fileURLWithPath: "/tmp/out.mp4"))
}) {
    requireCode(error, .attemptToStopNonRecording)
} else {
    fatalError("stopRecording(withOutput:) must fail closed")
}
if let error = runAsync({ try await recorder.startClipBuffering() }) {
    requireCode(error, .failedToStartCaptureStack)
} else {
    fatalError("startClipBuffering must fail closed")
}
if let error = runAsync({ try await recorder.stopClipBuffering() }) {
    requireCode(error, .attemptToStopNonRecording)
} else {
    fatalError("stopClipBuffering must fail closed")
}
if let error = runAsync({
    try await recorder.exportClip(to: URL(fileURLWithPath: "/tmp/clip.mp4"), duration: 1)
}) {
    requireCode(error, .failedToObtainURL)
} else {
    fatalError("exportClip must fail closed")
}

let controller = RPBroadcastController()
private let broadcastDelegate = BroadcastDelegateProbe()
controller.delegate = broadcastDelegate
precondition(controller.delegate === broadcastDelegate)
precondition(!controller.isBroadcasting)
precondition(!controller.isPaused)
precondition(controller.broadcastExtensionBundleID == nil)
precondition(controller.serviceInfo == nil)
_ = controller.broadcastURL
controller.pauseBroadcast()
controller.resumeBroadcast()
precondition(!controller.isPaused)
controller.startBroadcast { error in
    requireCode(error, .broadcastSetupFailed)
}
controller.finishBroadcast { error in
    requireCode(error, .broadcastInvalidSession)
}

private let sample = SampleHandlerProbe()
sample.broadcastStarted(withSetupInfo: ["room": NSString(string: "voice")])
precondition(sample.started)
precondition(sample.portableDidStart)
sample.broadcastPaused()
sample.broadcastResumed()
sample.broadcastFinished()
sample.broadcastAnnotated(withApplicationInfo: [
    RPApplicationInfoBundleIdentifierKey: "org.example.app"
])
sample.processSampleBuffer(CMSampleBuffer(), with: .video)
sample.processSampleBuffer(CMSampleBuffer(), with: .audioApp)
sample.processSampleBuffer(CMSampleBuffer(), with: .audioMic)
sample.finishBroadcastWithError(RPRecordingErrorCode.userDeclined)
sample.updateServiceInfo(["viewerCount": NSNumber(value: 3)])
sample.updateBroadcast(URL(string: "https://example.invalid/live")!)
precondition(sample.portableDidPause)
precondition(sample.portableDidResume)
precondition(sample.portableDidFinish)
precondition(sample.portableProcessedBufferCount == 3)
precondition(sample.portableLastSampleBufferType == .audioMic)
requireCode(sample.portableFinishError, .userDeclined)
precondition(sample.portableBroadcastURL?.absoluteString == "https://example.invalid/live")
precondition((sample.portableServiceInfo["viewerCount"] as? NSNumber)?.intValue == 3)

let mp4 = RPBroadcastMP4ClipHandler()
mp4.processMP4Clip(
    with: URL(fileURLWithPath: "/tmp/clip.mp4"),
    setupInfo: nil,
    finished: true
)
mp4.finishedProcessingMP4Clip(
    withUpdatedBroadcastConfiguration: nil,
    error: RPRecordingErrorCode.failed
)
precondition(mp4.portableLastClipFinished)
requireCode(mp4.portableLastProcessingError, .failed)

let config = RPBroadcastConfiguration()
config.clipDuration = 7
config.videoCompressionProperties = ["AverageBitRate": NSNumber(value: 1_000_000)]
precondition(RPBroadcastConfiguration.supportsSecureCoding)
do {
    let archived = try NSKeyedArchiver.archivedData(
        withRootObject: config,
        requiringSecureCoding: true
    )
    let restored = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: RPBroadcastConfiguration.self,
        from: archived
    )
    precondition(restored?.clipDuration == 7)
} catch {
    fatalError("RPBroadcastConfiguration NSSecureCoding failed: \(error)")
}

runOnMain {
    let preview = RPPreviewViewController()
    let previewDelegate = PreviewDelegateProbe()
    preview.previewControllerDelegate = previewDelegate
    precondition(preview.previewControllerDelegate === previewDelegate)
    previewDelegate.previewControllerDidFinish(preview)
    previewDelegate.previewController(preview, didFinishWithActivityTypes: [])

    let picker = RPSystemBroadcastPickerView()
    picker.preferredExtension = "org.example.BroadcastUpload"
    picker.showsMicrophoneButton = false
    precondition(picker.preferredExtension == "org.example.BroadcastUpload")
    precondition(!picker.showsMicrophoneButton)

    let activityDelegate = ActivityDelegateProbe()
    var loadedController: RPBroadcastActivityViewController?
    var loadError: (any Error)?
    RPBroadcastActivityViewController.load { controller, error in
        loadedController = controller
        loadError = error
    }
    precondition(loadedController == nil)
    requireCode(loadError, .broadcastSetupFailed)
    RPBroadcastActivityViewController.load(withPreferredExtension: "org.example.ext") {
        controller, error in
        loadedController = controller
        loadError = error
    }
    precondition(loadedController == nil)
    requireCode(loadError, .broadcastSetupFailed)
    _ = activityDelegate
}

let extensionContext = NSExtensionContext()
var loadedInfo: (String, String, UIImage?)?
extensionContext.loadBroadcastingApplicationInfo { bundleID, name, icon in
    loadedInfo = (bundleID, name, icon)
}
precondition(loadedInfo?.0 == "")
precondition(loadedInfo?.1 == "")
precondition(loadedInfo?.2 == nil)
extensionContext.completeRequest(
    withBroadcast: URL(string: "https://example.invalid/setup")!,
    setupInfo: ["token": NSString(string: "none")]
)
precondition(extensionContext.portableDidCompleteBroadcastRequest)
extensionContext.completeRequest(
    withBroadcast: URL(string: "https://example.invalid/setup2")!,
    broadcastConfiguration: config,
    setupInfo: nil
)
sample.beginRequest(with: extensionContext)

print("REPLAYKIT_AGENT_RUNTIME_OK")
