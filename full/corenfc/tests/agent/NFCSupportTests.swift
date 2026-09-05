import Dispatch
import Foundation
@_spi(OpenUIKitHost) import CoreNFC

final class NFCLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        self.value = value
    }
}

func nfcAwait<T>(_ body: @escaping @Sendable () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = NFCLocked<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    semaphore.wait()
    guard let result = box.load() else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

func nfcWait<T>(_ body: (@escaping (T) -> Void) -> Void) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = NFCLocked<T?>(nil)
    body { value in
        box.store(value)
        semaphore.signal()
    }
    semaphore.wait()
    guard let value = box.load() else {
        preconditionFailure("callback did not complete")
    }
    return value
}

func nfcSpinUntil(_ predicate: () -> Bool) {
    let deadline = Date().addingTimeInterval(2)
    while !predicate() {
        precondition(Date() < deadline, "timed out waiting for fail-closed callback")
        Thread.sleep(forTimeInterval: 0.01)
    }
}

func nfcHostTag() -> CoreNFCHostNDEFTag {
    CoreNFCHostNDEFTag()
}

func nfcReaderError(_ error: any Error) -> NFCReaderError {
    if let reader = error as? NFCReaderError {
        return reader
    }
    let nsError = error as NSError
    precondition(nsError.domain == NFCErrorDomain, "expected NFCErrorDomain, got \(nsError.domain)")
    guard let code = NFCReaderError.Code(rawValue: nsError.code) else {
        preconditionFailure("unexpected NFC error code \(nsError.code)")
    }
    return NFCReaderError(code, userInfo: nsError.userInfo)
}

func nfcExpectUnsupported(_ result: Result<some Any, Error>) {
    switch result {
    case .success:
        preconditionFailure("hardware path must fail closed")
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    }
}

func nfcExpectReaderCode(_ result: Result<some Any, Error>, _ code: NFCReaderError.Code) {
    switch result {
    case .success:
        preconditionFailure("hardware path must fail closed")
    case .failure(let error):
        precondition(nfcReaderError(error).code == code)
    }
}

final class NFCRecordingNDEFDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    let lock = NSLock()
    var invalidation: (any Error)?
    var detectedMessages: [NFCNDEFMessage]?
    var detectedTags: [any NFCNDEFTag]?
    var becameActive = false

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        lock.lock()
        invalidation = error
        lock.unlock()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        lock.lock()
        detectedMessages = messages
        lock.unlock()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        lock.lock()
        detectedTags = tags
        lock.unlock()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        lock.lock()
        becameActive = true
        lock.unlock()
    }
}

final class NFCRecordingTagDelegate: NSObject, NFCTagReaderSessionDelegate {
    let lock = NSLock()
    var invalidation: (any Error)?
    var detected: [NFCTag]?
    var becameActive = false

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
        lock.lock()
        invalidation = error
        lock.unlock()
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        lock.lock()
        detected = tags
        lock.unlock()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        lock.lock()
        becameActive = true
        lock.unlock()
    }
}

final class NFCRecordingVASDelegate: NSObject, NFCVASReaderSessionDelegate {
    var invalidation: (any Error)?
    var responses: [NFCVASResponse]?
    var becameActive = false

    func readerSession(_ session: NFCVASReaderSession, didInvalidateWithError error: any Error) {
        invalidation = error
    }

    func readerSession(_ session: NFCVASReaderSession, didReceive responses: [NFCVASResponse]) {
        self.responses = responses
    }

    func readerSessionDidBecomeActive(_ session: NFCVASReaderSession) {
        becameActive = true
    }
}

final class NFCDefaultNDEFDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        _ = error
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        _ = messages
    }
}

final class NFCDefaultVASDelegate: NSObject, NFCVASReaderSessionDelegate {
    func readerSession(_ session: NFCVASReaderSession, didInvalidateWithError error: any Error) {
        _ = error
    }

    func readerSession(_ session: NFCVASReaderSession, didReceive responses: [NFCVASResponse]) {
        _ = responses
    }
}
