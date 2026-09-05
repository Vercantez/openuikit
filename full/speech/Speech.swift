@_exported import Foundation

/// Linux host string for `SFSpeechErrorDomain`. Apple's payload is unobserved;
/// the C identifier is exported from Speech.tbd as `_SFSpeechErrorDomain`.
public let SFSpeechErrorDomain = "SFSpeechErrorDomain"

/// Documented domain for `SFSpeechRecognitionTask.error` codes 102 / 201 / 300 / 301.
/// Citation: [error](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/error).
/// The Darwin string payload is unobserved; this host uses the documented C name.
public let kLSRErrorDomain = "kLSRErrorDomain"

/// Documented domain for `SFSpeechRecognitionTask.error` assistant codes
/// 203 / 1100 / 1101 / 1107 / 1110 / 1700.
/// Citation: [error](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/error).
public let kAFAssistantErrorDomain = "kAFAssistantErrorDomain"

// MARK: - Fail-closed delivery

private struct SpeechUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

final class SpeechOnceFlag: @unchecked Sendable {
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

private let speechCallbackDispatch = DispatchQueue(
    label: "Speech.callback.dispatch",
    qos: .utility
)

private let speechAuthorizationLock = NSLock()
private var speechAuthorizationStatusValue = SFSpeechRecognizerAuthorizationStatus.notDetermined
private var speechAuthorizationDecision: SFSpeechRecognizerAuthorizationStatus?

func speechCurrentAuthorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
    speechAuthorizationLock.lock()
    defer { speechAuthorizationLock.unlock() }
    return speechAuthorizationStatusValue
}

func speechStoreAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) {
    speechAuthorizationLock.lock()
    speechAuthorizationStatusValue = status
    speechAuthorizationLock.unlock()
}

func speechTakeAuthorizationDecision() -> SFSpeechRecognizerAuthorizationStatus? {
    speechAuthorizationLock.lock()
    defer { speechAuthorizationLock.unlock() }
    return speechAuthorizationDecision
}

func speechFailClosedError(
    _ code: SFSpeechError.Code = .internalServiceError
) -> SFSpeechError {
    SFSpeechError(code, userInfo: [NSLocalizedDescriptionKey: "Speech services are unavailable on this Linux host"])
}

func speechLSRError(_ code: Int, description: String) -> NSError {
    NSError(
        domain: kLSRErrorDomain,
        code: code,
        userInfo: [NSLocalizedDescriptionKey: description]
    )
}

func speechAssistantError(_ code: Int, description: String) -> NSError {
    NSError(
        domain: kAFAssistantErrorDomain,
        code: code,
        userInfo: [NSLocalizedDescriptionKey: description]
    )
}

func speechDeliverOnQueue(_ queue: OperationQueue, _ body: @escaping () -> Void) {
    let once = SpeechOnceFlag()
    let work = SpeechUncheckedWork(body: body)
    queue.addOperation {
        guard once.take() else { return }
        work.body()
    }
}

func speechDeliverAsync(_ body: @escaping () -> Void) {
    let once = SpeechOnceFlag()
    let work = SpeechUncheckedWork(body: body)
    speechCallbackDispatch.async {
        guard once.take() else { return }
        work.body()
    }
}

func speechDeliverOnMain(_ body: @escaping () -> Void) {
    let once = SpeechOnceFlag()
    let work = SpeechUncheckedWork(body: body)
    DispatchQueue.main.async {
        guard once.take() else { return }
        work.body()
    }
}

/// Linux host-test control. Hidden from ordinary `import Speech` clients.
@_spi(OpenUIKitHost)
public enum SpeechHostControl {
    /// Documented LSR table: assets are not installed.
    public static let lsrAssetsNotInstalled = 102
    /// Documented LSR table: Siri or Dictation is disabled.
    public static let lsrSiriOrDictationDisabled = 201
    /// Documented LSR table: failed to initialize recognizer.
    public static let lsrRecognizerInitFailed = 300
    /// Documented LSR table: request was canceled.
    public static let lsrRequestCanceled = 301
    /// Documented assistant table: request is not authorized.
    public static let assistantRequestNotAuthorized = 1700

    public static func enqueueAuthorizationProbe(_ body: @escaping @Sendable () -> Void) {
        DispatchQueue.main.async(execute: body)
    }

    public static func resetAuthorizationStatusForTests() {
        speechAuthorizationLock.lock()
        speechAuthorizationStatusValue = .notDetermined
        speechAuthorizationDecision = nil
        speechAuthorizationLock.unlock()
    }

    /// Installs the status `requestAuthorization` stores when status is still
    /// `.notDetermined`. Without a hook the host fail-closes to `.denied`
    /// (no TCC prompt).
    public static func installAuthorizationDecision(
        _ status: SFSpeechRecognizerAuthorizationStatus
    ) {
        speechAuthorizationLock.lock()
        speechAuthorizationDecision = status
        speechAuthorizationLock.unlock()
    }

    public static func resetScriptedRecognizers() {
        SpeechScriptStore.shared.reset()
    }

    public static func registerScriptedRecognizer(
        locale: Locale,
        results: [SpeechScriptedResult],
        supportsOnDeviceRecognition: Bool = true
    ) {
        SpeechScriptStore.shared.register(
            locale: locale,
            results: results,
            supportsOnDeviceRecognition: supportsOnDeviceRecognition
        )
    }
}

@_spi(OpenUIKitHost)
public struct SpeechScriptedSegment: Sendable {
    public var substring: String
    public var timestamp: TimeInterval
    public var duration: TimeInterval
    public var confidence: Float
    public var alternativeSubstrings: [String]

    public init(
        substring: String,
        timestamp: TimeInterval,
        duration: TimeInterval,
        confidence: Float,
        alternativeSubstrings: [String] = []
    ) {
        self.substring = substring
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
        self.alternativeSubstrings = alternativeSubstrings
    }
}

@_spi(OpenUIKitHost)
public struct SpeechScriptedResult: Sendable {
    public var formattedString: String
    public var segments: [SpeechScriptedSegment]
    public var alternativeFormattedStrings: [String]
    public var isFinal: Bool
    public var speakingRate: Double
    public var averagePauseDuration: TimeInterval
    public var speechDuration: TimeInterval
    public var speechStartTimestamp: TimeInterval

    public init(
        formattedString: String,
        segments: [SpeechScriptedSegment] = [],
        alternativeFormattedStrings: [String] = [],
        isFinal: Bool = true,
        speakingRate: Double = 0,
        averagePauseDuration: TimeInterval = 0,
        speechDuration: TimeInterval = 0,
        speechStartTimestamp: TimeInterval = 0
    ) {
        self.formattedString = formattedString
        self.segments = segments
        self.alternativeFormattedStrings = alternativeFormattedStrings
        self.isFinal = isFinal
        self.speakingRate = speakingRate
        self.averagePauseDuration = averagePauseDuration
        self.speechDuration = speechDuration
        self.speechStartTimestamp = speechStartTimestamp
    }
}

struct SpeechScriptedRecognizer: Sendable {
    var results: [SpeechScriptedResult]
    var supportsOnDeviceRecognition: Bool
}

final class SpeechScriptStore: @unchecked Sendable {
    static let shared = SpeechScriptStore()

    private let lock = NSLock()
    private var scripts: [String: SpeechScriptedRecognizer] = [:]
    private var liveRecognizers: [WeakRecognizer] = []

    private struct WeakRecognizer {
        weak var value: SFSpeechRecognizer?
    }

    func reset() {
        let snapshot: [SFSpeechRecognizer]
        lock.lock()
        scripts = [:]
        snapshot = liveRecognizers.compactMap(\.value)
        liveRecognizers = snapshot.map { WeakRecognizer(value: $0) }
        lock.unlock()
        for recognizer in snapshot {
            recognizer.hostAvailabilityDidChange(false)
        }
    }

    func register(
        locale: Locale,
        results: [SpeechScriptedResult],
        supportsOnDeviceRecognition: Bool
    ) {
        let key = SpeechDocumentedLocales.canonicalIdentifier(locale)
        let script = SpeechScriptedRecognizer(
            results: results,
            supportsOnDeviceRecognition: supportsOnDeviceRecognition
        )
        let snapshot: [SFSpeechRecognizer]
        lock.lock()
        scripts[key] = script
        snapshot = liveRecognizers.compactMap(\.value)
        liveRecognizers = snapshot.map { WeakRecognizer(value: $0) }
        lock.unlock()
        for recognizer in snapshot where SpeechDocumentedLocales.canonicalIdentifier(recognizer.locale) == key {
            recognizer.supportsOnDeviceRecognition = supportsOnDeviceRecognition
            recognizer.hostAvailabilityDidChange(true)
        }
    }

    func script(for locale: Locale) -> SpeechScriptedRecognizer? {
        let key = SpeechDocumentedLocales.canonicalIdentifier(locale)
        lock.lock()
        defer { lock.unlock() }
        return scripts[key]
    }

    func track(_ recognizer: SFSpeechRecognizer) {
        lock.lock()
        liveRecognizers.append(WeakRecognizer(value: recognizer))
        lock.unlock()
    }
}

public struct SpeechEmptyResults<Element: Sendable>: Sendable, AsyncSequence {
    public typealias Element = Element

    public init() {}

    public struct AsyncIterator: AsyncIteratorProtocol {
        public init() {}
        public mutating func next() async throws -> Element? { nil }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}

// MARK: - SFSpeechError

public struct SFSpeechError: Error, Hashable, CustomNSError {
    public struct Code: RawRepresentable, Hashable, Sendable {
        public var rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Pinned `dotnet/macios` `SFSpeechErrorCode` (Xcode 26).
        public static let internalServiceError = Code(rawValue: 1)
        public static let audioReadFailed = Code(rawValue: 2)
        public static let undefinedTemplateClassName = Code(rawValue: 7)
        public static let malformedSupplementalModel = Code(rawValue: 8)
        public static let timeout = Code(rawValue: 12)
        public static let missingParameter = Code(rawValue: 13)

        /// Analyzer-era codes. Apple integer payloads are unobserved.
        public static let audioDisordered = Code(rawValue: 1001)
        public static let moduleOutputFailed = Code(rawValue: 1002)
        public static let insufficientResources = Code(rawValue: 1003)
        public static let unexpectedAudioFormat = Code(rawValue: 1004)
        public static let assetLocaleNotAllocated = Code(rawValue: 1005)
        public static let incompatibleAudioFormats = Code(rawValue: 1006)
        public static let tooManyAssetLocalesAllocated = Code(rawValue: 1007)
        public static let cannotAllocateUnsupportedLocale = Code(rawValue: 1008)
        public static let noModel = Code(rawValue: 1009)
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var info = userInfo
        if info[NSLocalizedDescriptionKey] == nil {
            info[NSLocalizedDescriptionKey] = "Speech error \(code.rawValue)"
        }
        self.userInfo = info
    }

    public static var errorDomain: String { SFSpeechErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var audioReadFailed: Code { .audioReadFailed }
    public static var internalServiceError: Code { .internalServiceError }
    public static var malformedSupplementalModel: Code { .malformedSupplementalModel }
    public static var missingParameter: Code { .missingParameter }
    public static var timeout: Code { .timeout }
    public static var undefinedTemplateClassName: Code { .undefinedTemplateClassName }

    public static func == (lhs: SFSpeechError, rhs: SFSpeechError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

// MARK: - Classic enumerations

public enum SFSpeechRecognitionTaskHint: Int, Sendable, Hashable {
    case unspecified = 0
    case dictation = 1
    case search = 2
    case confirmation = 3
}

/// Citation: [SFSpeechRecognitionTaskState](https://developer.apple.com/documentation/speech/sfspeechrecognitiontaskstate)
/// and the Xcode 26 header comments recorded in the pinned macios wiki:
/// starting = recognition has not yet begun; running = in progress;
/// finishing = no more audio, results may still arrive;
/// canceling = no more results, recording may not have stopped;
/// completed = no more results, recording stopped.
public enum SFSpeechRecognitionTaskState: Int, Sendable, Hashable {
    case starting = 0
    case running = 1
    case finishing = 2
    case canceling = 3
    case completed = 4
}

public enum SFSpeechRecognizerAuthorizationStatus: Int, Sendable, Hashable {
    case notDetermined = 0
    case denied = 1
    case restricted = 2
    case authorized = 3
}
