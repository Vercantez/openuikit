import Foundation
import ReplayKit

private final class RecorderDelegateProbe: NSObject, RPScreenRecorderDelegate {}
private final class BroadcastDelegateProbe: NSObject, RPBroadcastControllerDelegate {}

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
precondition(RPSampleBufferType.audioApp != .audioMic)
_ = RPSampleBufferType.audioApp.hashValue
var sampleHasher = Hasher()
RPSampleBufferType.video.hash(into: &sampleHasher)

let errorCodes: [(RPRecordingErrorCode, Int)] = [
    (.unknown, -5800),
    (.userDeclined, -5801),
    (.disabled, -5802),
    (.failedToStart, -5803),
    (.failed, -5804),
    (.insufficientStorage, -5805),
    (.interrupted, -5806),
    (.contentResize, -5807),
    (.broadcastInvalidSession, -5808),
    (.systemDormancy, -5809),
    (.entitlements, -5810),
    (.activePhoneCall, -5811),
    (.failedToSave, -5812),
    (.carPlay, -5813),
    (.failedApplicationConnectionInvalid, -5814),
    (.failedApplicationConnectionInterrupted, -5815),
    (.failedNoMatchingApplicationContext, -5816),
    (.failedMediaServicesFailure, -5817),
    (.videoMixingFailure, -5818),
    (.broadcastSetupFailed, -5819),
    (.failedToObtainURL, -5820),
    (.failedIncorrectTimeStamps, -5821),
    (.failedToProcessFirstSample, -5822),
    (.failedAssetWriterFailedToSave, -5823),
    (.failedNoAssetWriter, -5824),
    (.failedAssetWriterInWrongState, -5825),
    (.failedAssetWriterExportFailed, -5826),
    (.failedToRemoveFile, -5827),
    (.failedAssetWriterExportCanceled, -5828),
    (.attemptToStopNonRecording, -5829),
    (.attemptToStartInRecordingState, -5830),
    (.photoFailure, -5831),
    (.recordingInvalidSession, -5832),
    (.failedToStartCaptureStack, -5833),
    (.invalidParameter, -5834),
    (.filePermissions, -5835),
    (.exportClipToURLInProgress, -5836),
    (.codeSuccessful, 0),
]
for (code, raw) in errorCodes {
    precondition(code.rawValue == raw)
    precondition(RPRecordingErrorCode(rawValue: raw) == code)
}
precondition(RPRecordingErrorCode.failed != .unknown)
_ = RPRecordingErrorCode.failed.hashValue
var errorHasher = Hasher()
RPRecordingErrorCode.failed.hash(into: &errorHasher)

let recorder = RPScreenRecorder.shared()
precondition(recorder === RPScreenRecorder.shared())
precondition(!recorder.isAvailable)
precondition(!recorder.isRecording)

recorder.isMicrophoneEnabled = true
recorder.isCameraEnabled = true
recorder.cameraPosition = .back
precondition(recorder.isMicrophoneEnabled)
precondition(recorder.isCameraEnabled)
precondition(recorder.cameraPosition == .back)
recorder.cameraPosition = .front
precondition(recorder.cameraPosition == .front)

private let recorderDelegate = RecorderDelegateProbe()
let recorderExistential: any RPScreenRecorderDelegate = recorderDelegate
recorder.delegate = recorderExistential
precondition(recorder.delegate === recorderDelegate)
recorderExistential.screenRecorderDidChangeAvailability(recorder)

recorder.startRecording { error in
    requireCode(error, .failedToStartCaptureStack)
}
recorder.startRecording(withMicrophoneEnabled: true) { error in
    requireCode(error, .failedToStartCaptureStack)
}
precondition(recorder.isMicrophoneEnabled)
precondition(!recorder.isRecording)

recorder.stopRecording(withOutput: URL(fileURLWithPath: "/tmp/out.mp4")) { error in
    requireCode(error, .attemptToStopNonRecording)
}

var discarded = false
recorder.discardRecording { discarded = true }
precondition(discarded)

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
let broadcastExistential: any RPBroadcastControllerDelegate = broadcastDelegate
controller.delegate = broadcastExistential
precondition(controller.delegate === broadcastDelegate)
broadcastExistential.broadcastController(controller, didFinishWithError: nil)
broadcastExistential.broadcastController(
    controller,
    didUpdateBroadcast: URL(fileURLWithPath: "/")
)
broadcastExistential.broadcastController(
    controller,
    didUpdateServiceInfo: ["k": NSString(string: "v")]
)
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
sample.finishBroadcastWithError(RPRecordingErrorCode.userDeclined)
sample.updateServiceInfo(["viewerCount": NSNumber(value: 3)])
sample.updateBroadcast(URL(string: "https://example.invalid/live")!)
precondition(sample.portableDidPause)
precondition(sample.portableDidResume)
precondition(sample.portableDidFinish)
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

print("REPLAYKIT_AGENT_RUNTIME_OK")
