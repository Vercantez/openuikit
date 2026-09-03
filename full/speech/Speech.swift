@_exported import Foundation

/// Linux host string for `SFSpeechErrorDomain`. Apple's payload is unobserved.
public let SFSpeechErrorDomain = "SFSpeechErrorDomain"

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

private let speechAuthorizationDispatch = DispatchQueue(
    label: "Speech.authorization.dispatch",
    qos: .utility
)
private let speechCallbackDispatch = DispatchQueue(
    label: "Speech.callback.dispatch",
    qos: .utility
)
private let speechAuthorizationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "Speech.authorization"
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    queue.underlyingQueue = speechAuthorizationDispatch
    return queue
}()

private let speechAuthorizationLock = NSLock()
private var speechAuthorizationStatusValue = SFSpeechRecognizerAuthorizationStatus.notDetermined

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

func speechFailClosedError(
    _ code: SFSpeechError.Code = .internalServiceError
) -> SFSpeechError {
    SFSpeechError(code, userInfo: [NSLocalizedDescriptionKey: "Speech services are unavailable on this Linux host"])
}

func speechDeliverOnQueue(_ queue: OperationQueue, _ body: @escaping () -> Void) {
    speechDeliverAsync(body)
    _ = queue
}

func speechDeliverAsync(_ body: @escaping () -> Void) {
    let once = SpeechOnceFlag()
    let work = SpeechUncheckedWork(body: body)
    speechCallbackDispatch.async {
        guard once.take() else { return }
        work.body()
    }
}

func speechDeliverAuthorization(_ body: @escaping () -> Void) {
    speechDeliverAsync(body)
}

/// Linux host-test control. Hidden from ordinary `import Speech` clients.
@_spi(OpenUIKitHost)
public enum SpeechHostControl {
    public static var authorizationQueue: OperationQueue { speechAuthorizationQueue }

    public static func enqueueAuthorizationProbe(_ body: @escaping @Sendable () -> Void) {
        speechCallbackDispatch.async(execute: body)
    }

    public static func resetAuthorizationStatusForTests() {
        speechStoreAuthorizationStatus(.notDetermined)
    }
}

public struct SpeechEmptyResults<Element: Sendable>: Sendable, AsyncSequence {
    public typealias Element = Element

    public struct AsyncIterator: AsyncIteratorProtocol {
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

        public static let audioReadFailed = Code(rawValue: 1)
        public static let internalServiceError = Code(rawValue: 2)
        public static let malformedSupplementalModel = Code(rawValue: 3)
        public static let missingParameter = Code(rawValue: 4)
        public static let timeout = Code(rawValue: 5)
        public static let undefinedTemplateClassName = Code(rawValue: 6)

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
        self.userInfo = userInfo
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
