import Dispatch
import Foundation
import FoundationNetworking
import LinkPresentation

private final class LPLocked<Value>: @unchecked Sendable {
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
        self.value = value
        lock.unlock()
    }
}

private func lpAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = LPLocked<Result<T, Error>?>(nil)
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

private func lpOnMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(work)
        return
    }
    DispatchQueue.main.sync {
        MainActor.assumeIsolated(work)
    }
}

private func lpArchiveRoundTrip(_ value: LPLinkMetadata) -> LPLinkMetadata {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(
            withRootObject: value, requiringSecureCoding: true
        )
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: LPLinkMetadata.self, from: data
        ) else {
            preconditionFailure("expected restored LPLinkMetadata")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

func testLPErrorDomain() {
    precondition(LPErrorDomain == "LPErrorDomain")
    precondition(LPError.errorDomain == "LPErrorDomain")
    precondition(LPError.errorDomain == LPErrorDomain)
    precondition(LPError._nsErrorDomain == LPErrorDomain)
}

func testLPErrorCodes() {
    precondition(LPError.Code.unknown.rawValue == 1)
    precondition(LPError.Code.metadataFetchFailed.rawValue == 2)
    precondition(LPError.Code.metadataFetchCancelled.rawValue == 3)
    precondition(LPError.Code.metadataFetchTimedOut.rawValue == 4)
    precondition(LPError.Code.metadataFetchNotAllowed.rawValue == 5)
    precondition(LPError.unknown == .unknown)
    precondition(LPError.metadataFetchFailed == .metadataFetchFailed)
    precondition(LPError.metadataFetchCancelled == .metadataFetchCancelled)
    precondition(LPError.metadataFetchTimedOut == .metadataFetchTimedOut)
    precondition(LPError.metadataFetchNotAllowed == .metadataFetchNotAllowed)
    precondition(LPError.Code(rawValue: 1) == .unknown)
    precondition(LPError.Code(rawValue: 2) == .metadataFetchFailed)
    precondition(LPError.Code(rawValue: 3) == .metadataFetchCancelled)
    precondition(LPError.Code(rawValue: 4) == .metadataFetchTimedOut)
    precondition(LPError.Code(rawValue: 5) == .metadataFetchNotAllowed)
    precondition(LPError.Code(rawValue: 0) == nil)
    precondition(LPError.Code(rawValue: 6) == nil)
    precondition(LPError.Code.unknown.hashValue == LPError.Code.unknown.hashValue)
    var hasher = Hasher()
    LPError.Code.metadataFetchFailed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testLPErrorEqualityAndHash() {
    let empty = LPError(.unknown)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 1)
    precondition(empty.code == .unknown)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = LPError(.unknown, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(empty == LPError(.unknown))
    precondition(sentinel != empty)
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    LPError(.unknown).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testLPErrorPatternMatch() {
    let error: any Error = LPError(.metadataFetchFailed)
    precondition(LPError.Code.metadataFetchFailed ~= error)
    precondition(!(LPError.Code.unknown ~= error))
    do {
        throw LPError(.metadataFetchCancelled)
    } catch let error as LPError where error.code == .metadataFetchCancelled {
        ()
    } catch {
        preconditionFailure("expected Code.metadataFetchCancelled pattern match")
    }
}

func testLPErrorProtocolConformance() {
    func bridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
        E._nsErrorDomain
    }
    func errorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
        String(describing: C._ErrorType.self)
    }
    precondition(bridgedDomain(LPError.self) == LPErrorDomain)
    precondition(errorTypeName(LPError.Code.self) == String(describing: LPError.self))

    let error = LPError(.metadataFetchTimedOut)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue

    var seen: Set<Int> = []
    seen.insert(error.hashValue)
    seen.insert(LPError(.metadataFetchTimedOut).hashValue)
    precondition(seen.count == 1)
}

func testLPErrorInequality() {
    precondition(LPError(.unknown) != LPError(.metadataFetchFailed))
    precondition(LPError(.metadataFetchCancelled) != LPError(.metadataFetchTimedOut))
    precondition(LPError(.metadataFetchNotAllowed) != LPError(.unknown))
}

func testLPLinkMetadataStoresFields() {
    let metadata = LPLinkMetadata()
    precondition(metadata.title == nil)
    precondition(metadata.url == nil)
    precondition(metadata.originalURL == nil)
    precondition(metadata.remoteVideoURL == nil)

    let url = URL(string: "https://example.com/page")!
    let original = URL(string: "https://example.com/original")!
    let video = URL(string: "https://example.com/video.mp4")!
    metadata.title = "Example"
    metadata.url = url
    metadata.originalURL = original
    metadata.remoteVideoURL = video
    precondition(metadata.title == "Example")
    precondition(metadata.url == url)
    precondition(metadata.originalURL == original)
    precondition(metadata.remoteVideoURL == video)
}

func testLPLinkMetadataCopyAndSecureCoding() {
    let metadata = LPLinkMetadata()
    metadata.title = "copied"
    metadata.url = URL(string: "https://example.com/copied")
    metadata.originalURL = URL(string: "https://example.com/src")
    metadata.remoteVideoURL = URL(string: "https://example.com/v.mp4")

    guard let copied = metadata.copy() as? LPLinkMetadata else {
        preconditionFailure("copy must produce LPLinkMetadata")
    }
    precondition(copied !== metadata)
    precondition(copied.title == "copied")
    precondition(copied.url == metadata.url)
    precondition(copied.originalURL == metadata.originalURL)
    precondition(copied.remoteVideoURL == metadata.remoteVideoURL)
    copied.title = "mutated"
    precondition(metadata.title == "copied")

    let restored = lpArchiveRoundTrip(metadata)
    precondition(restored !== metadata)
    precondition(restored.title == "copied")
    precondition(restored.url == metadata.url)
    precondition(restored.originalURL == metadata.originalURL)
    precondition(restored.remoteVideoURL == metadata.remoteVideoURL)

    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "lp-malformed", requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(LPLinkMetadata(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed archive setup failed: \(error)")
    }
}

func testLPLinkViewInitsAndCopiedMetadata() {
    lpOnMain {
        let source = LPLinkMetadata()
        source.title = "view"
        source.url = URL(string: "https://example.com/view")
        let view = LPLinkView(metadata: source)
        precondition(view.metadata !== source)
        precondition(view.metadata.title == "view")
        source.title = "changed"
        precondition(view.metadata.title == "view")

        let replacement = LPLinkMetadata()
        replacement.title = "replaced"
        view.metadata = replacement
        replacement.title = "after-set"
        precondition(view.metadata.title == "replaced")

        let fromURL = URL(string: "https://example.com/from-url")!
        let urlView = LPLinkView(url: fromURL)
        precondition(urlView.metadata.originalURL == fromURL)
        precondition(urlView.metadata.url == nil)
        precondition(urlView.metadata.title == nil)

        let fromURLLabel = URL(string: "https://example.com/from-URL")!
        let labeled = LPLinkView(URL: fromURLLabel)
        precondition(labeled.metadata.originalURL == fromURLLabel)
        precondition(labeled.metadata.url == nil)
    }
}

func testLPMetadataProviderStoresFlagsAndFailClosesFetch() {
    let provider = LPMetadataProvider()
    precondition(provider.shouldFetchSubresources == false)
    precondition(provider.timeout == 0)
    provider.shouldFetchSubresources = true
    provider.timeout = 12
    precondition(provider.shouldFetchSubresources == true)
    precondition(provider.timeout == 12)
    provider.cancel()

    let url = URL(string: "https://example.com/fetch")!
    switch lpAwait({ try await provider.startFetchingMetadata(for: url) }) {
    case .success:
        preconditionFailure("Linux fetch must not invent Apple metadata")
    case .failure(let error):
        guard let typed = error as? LPError else {
            preconditionFailure("expected LPError")
        }
        precondition(typed.code == .metadataFetchFailed)
        precondition(typed.errorCode == 2)
        precondition((typed as NSError).domain == LPErrorDomain)
    }

    let request = URLRequest(url: url)
    switch lpAwait({ try await provider.startFetchingMetadata(for: request) }) {
    case .success:
        preconditionFailure("Linux request fetch must not invent Apple metadata")
    case .failure(let error):
        guard let typed = error as? LPError else {
            preconditionFailure("expected LPError from request fetch")
        }
        precondition(typed.code == .metadataFetchFailed)
    }
}
