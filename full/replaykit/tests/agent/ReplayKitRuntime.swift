@_spi(OpenUIKitHost) import ReplayKit
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var error: (any Error)?

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(error: (any Error)?) {
        lock.lock()
        sawReturned = returned
        count += 1
        self.error = error
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int, error: (any Error)?) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, error)
    }
}

private final class CompletionQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        ReplayKitHostControl.enqueueCompletionProbe {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "completion queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func requireError(_ error: (any Error)?, _ code: RPRecordingErrorCode) {
    guard let error else {
        fatalError("expected fail-closed NSError")
    }
    let nsError = error as NSError
    precondition(type(of: nsError) == NSError.self)
    precondition(!String(reflecting: type(of: nsError)).hasPrefix("ReplayKit."))
    precondition(nsError.domain == RPRecordingErrorDomain)
    precondition(nsError.code == code.rawValue)
}

private func provePrivateErrorHandler(
    expected: RPRecordingErrorCode,
    start: @escaping (@escaping ((any Error)?) -> Void) -> Void
) {
    let blocker = CompletionQueueBlocker()
    let state = LockedState()
    blocker.occupy()
    start { error in
        state.noteCallback(error: error)
    }
    state.markReturned()
    precondition(state.snapshot().count == 0, "handler must not run inline")
    blocker.release()
    let drained = DispatchSemaphore(value: 0)
    ReplayKitHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    waitEvent(drained, "private completion queue did not drain")
    let after = state.snapshot()
    precondition(after.count == 1)
    precondition(after.sawReturned)
    requireError(after.error, expected)
}

private func assertEnums() {
    precondition(RPCameraPosition.front != .back)
    precondition(RPCameraPosition.front == .front)
    precondition(RPCameraPosition.front.rawValue == 1)
    precondition(RPCameraPosition.back.rawValue == 2)
    precondition(RPCameraPosition(rawValue: 1) == .front)
    precondition(RPCameraPosition(rawValue: 2) == .back)
    precondition(RPCameraPosition(rawValue: 0) == nil)
    precondition(RPCameraPosition.front.hashValue == RPCameraPosition.front.hashValue)
    precondition(RPCameraPosition.front.hashValue != RPCameraPosition.back.hashValue)
    var cameraHasher = Hasher()
    RPCameraPosition.front.hash(into: &cameraHasher)
    RPCameraPosition.back.hash(into: &cameraHasher)
    _ = cameraHasher.finalize()

    precondition(RPSampleBufferType.video != .audioApp)
    precondition(RPSampleBufferType.audioApp != .audioMic)
    precondition(RPSampleBufferType.video.rawValue == 1)
    precondition(RPSampleBufferType.audioApp.rawValue == 2)
    precondition(RPSampleBufferType.audioMic.rawValue == 3)
    precondition(RPSampleBufferType(rawValue: 1) == .video)
    precondition(RPSampleBufferType(rawValue: 99) == nil)
    precondition(RPSampleBufferType.video.hashValue != RPSampleBufferType.audioMic.hashValue)
    var sampleHasher = Hasher()
    RPSampleBufferType.video.hash(into: &sampleHasher)
    RPSampleBufferType.audioApp.hash(into: &sampleHasher)
    RPSampleBufferType.audioMic.hash(into: &sampleHasher)
    _ = sampleHasher.finalize()

    let recordingCases: [RPRecordingErrorCode] = [
        .codeSuccessful, .unknown, .userDeclined, .disabled, .failedToStart, .failed,
        .insufficientStorage, .interrupted, .contentResize, .broadcastInvalidSession,
        .systemDormancy, .entitlements, .activePhoneCall, .failedToSave, .carPlay,
        .failedApplicationConnectionInvalid, .failedApplicationConnectionInterrupted,
        .failedNoMatchingApplicationContext, .failedMediaServicesFailure,
        .videoMixingFailure, .broadcastSetupFailed, .failedToObtainURL,
        .failedIncorrectTimeStamps, .failedToProcessFirstSample,
        .failedAssetWriterFailedToSave, .failedNoAssetWriter,
        .failedAssetWriterInWrongState, .failedAssetWriterExportFailed,
        .failedToRemoveFile, .failedAssetWriterExportCanceled,
        .attemptToStopNonRecording, .attemptToStartInRecordingState, .photoFailure,
        .recordingInvalidSession, .failedToStartCaptureStack, .invalidParameter,
        .filePermissions, .exportClipToURLInProgress,
    ]
    precondition(recordingCases.count == 38)
    precondition(Set(recordingCases).count == 38)
    precondition(RPRecordingErrorCode.codeSuccessful.rawValue == 0)
    precondition(RPRecordingErrorCode.unknown.rawValue == -5800)
    precondition(RPRecordingErrorCode.exportClipToURLInProgress.rawValue == -5836)
    precondition(RPRecordingErrorCode.disabled.rawValue == -5802)
    precondition(RPRecordingErrorCode.entitlements.rawValue == -5810)
    precondition(RPRecordingErrorCode.attemptToStopNonRecording.rawValue == -5829)
    precondition(RPRecordingErrorCode(rawValue: -5800) == .unknown)
    precondition(RPRecordingErrorCode(rawValue: -1) == nil)
    precondition(RPRecordingErrorCode.unknown != .disabled)
    var errorHasher = Hasher()
    for item in recordingCases {
        item.hash(into: &errorHasher)
        _ = item.hashValue
        precondition(RPRecordingErrorCode(rawValue: item.rawValue) == item)
    }
    _ = errorHasher.finalize()
}

private func assertConstants() {
    precondition(RPRecordingErrorDomain == "RPRecordingErrorDomain")
    precondition(!RPRecordingErrorDomain.isEmpty)
    precondition(RPApplicationInfoBundleIdentifierKey == "RPApplicationInfoBundleIdentifierKey")
    precondition(RPVideoSampleOrientationKey == "RPVideoSampleOrientationKey")
    precondition(SCStreamErrorDomain == "SCStreamErrorDomain")
    precondition(RPRecordingErrorDomain != SCStreamErrorDomain)
    precondition(RPApplicationInfoBundleIdentifierKey != RPVideoSampleOrientationKey)
}

private func assertErrorSurface() {
    let disabled = replayKitProbeDisabled()
    requireError(disabled, .disabled)
    let entitlements = replayKitProbeEntitlements()
    requireError(entitlements, .entitlements)
}

private func replayKitProbeDisabled() -> NSError {
    let recorder = RPScreenRecorder.shared()
    var captured: (any Error)?
    let done = DispatchSemaphore(value: 0)
    recorder.startRecording { error in
        captured = error
        done.signal()
    }
    waitEvent(done, "startRecording did not complete")
    return captured! as NSError
}

private func replayKitProbeEntitlements() -> NSError {
    let controller = RPBroadcastController()
    var captured: (any Error)?
    let done = DispatchSemaphore(value: 0)
    controller.startBroadcast { error in
        captured = error
        done.signal()
    }
    waitEvent(done, "startBroadcast did not complete")
    return captured! as NSError
}

private func assertScreenRecorder() {
    let first = RPScreenRecorder.shared()
    let second = RPScreenRecorder.shared()
    precondition(first === second)
    precondition(!first.isAvailable)
    precondition(!first.isRecording)
    precondition(!first.isCameraEnabled)
    precondition(!first.isMicrophoneEnabled)
    precondition(first.cameraPosition == .front)

    first.isCameraEnabled = true
    first.isMicrophoneEnabled = true
    first.cameraPosition = .back
    precondition(first.isCameraEnabled)
    precondition(first.isMicrophoneEnabled)
    precondition(first.cameraPosition == .back)
    precondition(!first.isAvailable)
    precondition(!first.isRecording)

    first.isCameraEnabled = false
    first.isMicrophoneEnabled = false
    first.cameraPosition = .front

    let probe = RecorderAvailabilityProbe()
    first.delegate = probe
    precondition(first.delegate === probe)
    precondition(probe.changes == 0)

    provePrivateErrorHandler(expected: .disabled) { handler in
        first.startRecording(handler: handler)
    }
    precondition(!first.isRecording)

    provePrivateErrorHandler(expected: .disabled) { handler in
        first.startRecording(withMicrophoneEnabled: true, handler: handler)
    }
    precondition(first.isMicrophoneEnabled)
    precondition(!first.isRecording)
    first.isMicrophoneEnabled = false

    provePrivateErrorHandler(expected: .disabled) { handler in
        first.startClipBuffering(completionHandler: handler)
    }
    provePrivateErrorHandler(expected: .disabled) { handler in
        first.stopClipBuffering(completionHandler: handler)
    }
    provePrivateErrorHandler(expected: .disabled) { handler in
        first.stopCapture(handler: handler)
    }

    let discarded = DispatchSemaphore(value: 0)
    let discardState = LockedState()
    let discardBlocker = CompletionQueueBlocker()
    discardBlocker.occupy()
    first.discardRecording {
        discardState.noteCallback(error: nil)
        discarded.signal()
    }
    discardState.markReturned()
    precondition(discardState.snapshot().count == 0, "discardRecording must not run inline")
    discardBlocker.release()
    waitEvent(discarded, "discardRecording did not complete")
    precondition(discardState.snapshot().count == 1)
    precondition(discardState.snapshot().sawReturned)

    let exportDone = DispatchSemaphore(value: 0)
    var exportError: (any Error)?
    Task {
        do {
            try await first.exportClip(
                to: URL(fileURLWithPath: "/tmp/replaykit-clip.mp4"),
                duration: 5
            )
        } catch {
            exportError = error
        }
        exportDone.signal()
    }
    waitEvent(exportDone, "exportClip did not complete")
    requireError(exportError, .disabled)

    let stopDone = DispatchSemaphore(value: 0)
    var stopError: (any Error)?
    Task {
        do {
            try await first.stopRecording(withOutput: URL(fileURLWithPath: "/tmp/replaykit-out.mp4"))
        } catch {
            stopError = error
        }
        stopDone.signal()
    }
    waitEvent(stopDone, "stopRecording(withOutput:) did not complete")
    requireError(stopError, .attemptToStopNonRecording)
}

private func assertBroadcastController() {
    let controller = RPBroadcastController()
    precondition(!controller.isBroadcasting)
    precondition(!controller.isPaused)
    precondition(controller.broadcastURL.absoluteString == "replaykit://unstarted")
    precondition(controller.serviceInfo == nil)
    precondition(controller.broadcastExtensionBundleID == nil)

    let probe = BroadcastFinishProbe()
    controller.delegate = probe
    precondition(controller.delegate === probe)
    let existential: any RPBroadcastControllerDelegate = probe
    existential.broadcastController(controller, didFinishWithError: nil)
    existential.broadcastController(
        controller,
        didUpdateBroadcast: URL(string: "https://example.invalid/broadcast")!
    )
    existential.broadcastController(
        controller,
        didUpdateServiceInfo: ["bundle": "id" as NSString]
    )
    precondition(probe.finishCount == 1)
    precondition(probe.urlCount == 1)
    precondition(probe.infoCount == 1)

    provePrivateErrorHandler(expected: .entitlements) { handler in
        controller.startBroadcast(handler: handler)
    }
    precondition(!controller.isBroadcasting)
    controller.pauseBroadcast()
    controller.resumeBroadcast()
    precondition(!controller.isPaused)

    provePrivateErrorHandler(expected: .broadcastInvalidSession) { handler in
        controller.finishBroadcast(handler: handler)
    }
    precondition(!controller.isBroadcasting)
}

private func assertBroadcastConfiguration() {
    let configuration = RPBroadcastConfiguration()
    precondition(configuration.clipDuration == 0)
    configuration.clipDuration = 7.5
    precondition(configuration.clipDuration == 7.5)
    configuration.videoCompressionProperties = ["ProfileLevel": "main" as NSString]
    precondition(configuration.videoCompressionProperties?["ProfileLevel"] as? NSString == "main")

    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: configuration,
            requiringSecureCoding: true
        )
        guard let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: RPBroadcastConfiguration.self,
            from: data
        ) else {
            fatalError("unarchive produced nil RPBroadcastConfiguration")
        }
        precondition(decoded.clipDuration == 7.5)
    } catch {
        fatalError("archive round-trip failed: \(error)")
    }
}

private func assertBroadcastHandlers() {
    let handler = RPBroadcastHandler()
    let url = URL(string: "https://example.invalid/stream")!
    handler.updateBroadcast(url)
    precondition(ReplayKitHostControl.handlerBroadcastURL(handler) == url)
    handler.updateServiceInfo(["app": "demo" as NSString])
    precondition(ReplayKitHostControl.handlerServiceInfoKeys(handler) == ["app"])

    let mp4 = RPBroadcastMP4ClipHandler()
    mp4.processMP4Clip(with: nil, setupInfo: nil, finished: true)
    mp4.finishedProcessingMP4Clip(withUpdatedBroadcastConfiguration: nil, error: nil)

    let sample: RPBroadcastSampleHandler = SampleOverride()
    sample.broadcastStarted(withSetupInfo: nil)
    sample.broadcastPaused()
    sample.broadcastResumed()
    sample.broadcastFinished()
    sample.broadcastAnnotated(withApplicationInfo: [RPApplicationInfoBundleIdentifierKey: "demo.bundle"])
    let finish = NSError(
        domain: RPRecordingErrorDomain,
        code: RPRecordingErrorCode.disabled.rawValue,
        userInfo: nil
    )
    sample.finishBroadcastWithError(finish)
    let stored = ReplayKitHostControl.sampleHandlerFinishError(sample)
    requireError(stored, .disabled)
    let override = sample as! SampleOverride
    precondition(override.started)
    precondition(override.paused)
    precondition(override.resumed)
    precondition(override.finished)
    precondition(override.annotated)
}

private func assertDelegates() {
    let recorder = RPScreenRecorder.shared()
    let overriding = RecorderAvailabilityProbe()
    let asExistential: any RPScreenRecorderDelegate = overriding
    asExistential.screenRecorderDidChangeAvailability(recorder)
    precondition(overriding.changes == 1)

    let defaultOnly = DefaultRecorderDelegate()
    let defaultExistential: any RPScreenRecorderDelegate = defaultOnly
    defaultExistential.screenRecorderDidChangeAvailability(recorder)
}

private final class RecorderAvailabilityProbe: NSObject, RPScreenRecorderDelegate {
    var changes = 0

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        _ = screenRecorder
        changes += 1
    }
}

private final class DefaultRecorderDelegate: NSObject, RPScreenRecorderDelegate {}

private final class BroadcastFinishProbe: NSObject, RPBroadcastControllerDelegate {
    var finishCount = 0
    var urlCount = 0
    var infoCount = 0

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didFinishWithError error: (any Error)?
    ) {
        _ = broadcastController
        _ = error
        finishCount += 1
    }

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateBroadcast broadcastURL: URL
    ) {
        _ = broadcastController
        _ = broadcastURL
        urlCount += 1
    }

    func broadcastController(
        _ broadcastController: RPBroadcastController,
        didUpdateServiceInfo serviceInfo: [String: any NSCoding & NSObjectProtocol]
    ) {
        _ = broadcastController
        _ = serviceInfo
        infoCount += 1
    }
}

private final class SampleOverride: RPBroadcastSampleHandler {
    var started = false
    var paused = false
    var resumed = false
    var finished = false
    var annotated = false

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        _ = setupInfo
        started = true
    }

    override func broadcastPaused() {
        paused = true
    }

    override func broadcastResumed() {
        resumed = true
    }

    override func broadcastFinished() {
        finished = true
    }

    override func broadcastAnnotated(withApplicationInfo applicationInfo: [AnyHashable: Any]) {
        _ = applicationInfo
        annotated = true
    }
}

func replayKitRuntimeMain() {
    assertEnums()
    assertConstants()
    assertErrorSurface()
    assertScreenRecorder()
    assertBroadcastController()
    assertBroadcastConfiguration()
    assertBroadcastHandlers()
    assertDelegates()
    print("REPLAYKIT_AGENT_RUNTIME_OK")
}

replayKitRuntimeMain()
