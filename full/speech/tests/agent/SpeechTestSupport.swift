@_spi(OpenUIKitHost) import Speech
import Foundation

let speechEventTimeout = DispatchTimeInterval.seconds(5)

func speechWait(_ semaphore: DispatchSemaphore, _ message: String) {
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
        if semaphore.wait(timeout: .now() + 0.01) == .success {
            return
        }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
    }
    preconditionFailure(message)
}

func speechWaitAsync(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await body()
        semaphore.signal()
    }
    speechWait(semaphore, "async speech probe timed out")
}

func speechRequireAssistantUnauthorized(_ error: (any Error)?) {
    let nsError = error as NSError?
    precondition(nsError?.domain == kAFAssistantErrorDomain)
    precondition(nsError?.code == SpeechHostControl.assistantRequestNotAuthorized)
}

func speechRequireLSR(_ error: (any Error)?, code: Int) {
    let nsError = error as NSError?
    precondition(nsError?.domain == kLSRErrorDomain)
    precondition(nsError?.code == code)
}

func speechHash<T: Hashable>(_ value: T) -> Int {
    var hasher = Hasher()
    value.hash(into: &hasher)
    return hasher.finalize()
}

final class SpeechLockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var status: SFSpeechRecognizerAuthorizationStatus?
    private var onMain = false

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(_ status: SFSpeechRecognizerAuthorizationStatus, onMain: Bool) {
        lock.lock()
        sawReturned = returned
        count += 1
        self.status = status
        self.onMain = onMain
        lock.unlock()
    }

    func snapshot() -> (
        sawReturned: Bool,
        count: Int,
        status: SFSpeechRecognizerAuthorizationStatus?,
        onMain: Bool
    ) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, status, onMain)
    }
}

final class SpeechRecordingDelegate: NSObject, SFSpeechRecognitionTaskDelegate, @unchecked Sendable {
    let finished = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var success: Bool?
    private var cancelled = false
    private var detected = false
    private var hypothesized = 0
    private var finishedRecognition: SFSpeechRecognitionResult?
    private var finishedAudio = false
    private var processedDuration: TimeInterval = 0

    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        detected = true
        lock.unlock()
    }

    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didHypothesizeTranscription transcription: SFTranscription
    ) {
        lock.lock()
        hypothesized += 1
        _ = transcription
        lock.unlock()
    }

    func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        lock.lock()
        finishedRecognition = recognitionResult
        lock.unlock()
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didProcessAudioDuration duration: TimeInterval) {
        lock.lock()
        processedDuration = duration
        lock.unlock()
    }

    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        finishedAudio = true
        lock.unlock()
    }

    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        lock.lock()
        success = successfully
        lock.unlock()
        finished.signal()
    }

    func snapshot() -> (
        success: Bool?,
        cancelled: Bool,
        detected: Bool,
        hypothesized: Int,
        result: SFSpeechRecognitionResult?,
        finishedAudio: Bool,
        duration: TimeInterval
    ) {
        lock.lock()
        defer { lock.unlock() }
        return (success, cancelled, detected, hypothesized, finishedRecognition, finishedAudio, processedDuration)
    }
}

final class SpeechAvailabilityDelegate: NSObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    let changed = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var available: Bool?

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        lock.lock()
        self.available = available
        lock.unlock()
        changed.signal()
    }

    func snapshot() -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        return available
    }
}

func speechAuthorizeForTests() {
    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    let finished = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        precondition(status == .authorized)
        finished.signal()
    }
    speechWait(finished, "authorization did not complete")
}

func speechRegisterEnglishScript(
    results: [SpeechScriptedResult],
    supportsOnDeviceRecognition: Bool = true
) {
    SpeechHostControl.registerScriptedRecognizer(
        locale: Locale(identifier: "en-US"),
        results: results,
        supportsOnDeviceRecognition: supportsOnDeviceRecognition
    )
}
