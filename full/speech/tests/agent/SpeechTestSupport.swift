@_spi(OpenUIKitHost) import Speech
import Foundation

struct SpeechNeverResults<Element: Sendable>: Sendable, AsyncSequence {
    func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    struct AsyncIterator: AsyncIteratorProtocol {
        mutating func next() async -> Element? { nil }
    }
}

func speechRunAsync(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task.detached {
        await body()
        semaphore.signal()
    }
    precondition(
        semaphore.wait(timeout: .now() + 10) == .success,
        "async speech probe timed out"
    )
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

final class SpeechRecordingDelegate: NSObject, SFSpeechRecognitionTaskDelegate, @unchecked Sendable {
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
    private let lock = NSLock()
    private var available: Bool?

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        lock.lock()
        self.available = available
        lock.unlock()
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
    var seen: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        seen = status
    }
    precondition(seen == .authorized)
    precondition(SFSpeechRecognizer.authorizationStatus() == .authorized)
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
