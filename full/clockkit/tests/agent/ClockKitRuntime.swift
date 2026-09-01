import Dispatch
import Foundation
import ClockKit

private final class CallbackBox: @unchecked Sendable {
    let lock = NSLock()
    let caller: Thread
    var calls = 0
    var error: (any Error)?
    var returned = false
    var ranOnCallerBeforeReturn = false

    init(caller: Thread) {
        self.caller = caller
    }
}

private final class AsyncErrorBox: @unchecked Sendable {
    var error: (any Error)?
    var succeeded = false
}

private final class RecordingWatchFaceLibrary: CLKWatchFaceLibrary, @unchecked Sendable {
    private let lock = NSLock()
    private var invocations = 0

    var overrideCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return invocations
    }

    override func addWatchFace(
        at fileURL: URL,
        completionHandler handler: @escaping ((any Error)?) -> Void
    ) {
        lock.lock()
        invocations += 1
        lock.unlock()
        super.addWatchFace(at: fileURL, completionHandler: handler)
    }
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func expectFailClosed(_ error: (any Error)?, _ label: String) {
    guard let error else {
        fatalError("\(label): expected fail-closed error, got success")
    }
    if let code = error as? CLKWatchFaceLibrary.ErrorCode {
        expect(code == .faceNotAvailable, "\(label): Linux sentinel \(code)")
    }
    let nsError = error as NSError
    expect(
        nsError.domain == CLKWatchFaceLibrary.ErrorDomain,
        "\(label): NSError domain \(nsError.domain)"
    )
    expect(!nsError.domain.isEmpty, "\(label): NSError domain must be nonempty")
}

private func addWatchFaceDelivered(
    _ library: CLKWatchFaceLibrary,
    at url: URL
) -> (any Error)? {
    let box = CallbackBox(caller: Thread.current)
    let finished = DispatchSemaphore(value: 0)
    library.addWatchFace(at: url) { error in
        box.lock.lock()
        if !box.returned && Thread.current === box.caller {
            box.ranOnCallerBeforeReturn = true
        }
        box.calls += 1
        box.error = error
        box.lock.unlock()
        finished.signal()
    }
    box.lock.lock()
    box.returned = true
    let inline = box.ranOnCallerBeforeReturn
    let callsAfterReturn = box.calls
    box.lock.unlock()
    expect(!inline, "addWatchFace completion must not run inline on the caller")
    if callsAfterReturn == 0 {
        let waitResult = finished.wait(timeout: .now() + 2)
        expect(waitResult == .success, "addWatchFace completion timed out")
    }
    Thread.sleep(forTimeInterval: 0.05)
    box.lock.lock()
    let calls = box.calls
    let error = box.error
    box.lock.unlock()
    expect(calls == 1, "addWatchFace completion must run exactly once, got \(calls)")
    return error
}

private func addWatchFaceAsync(_ library: CLKWatchFaceLibrary, at url: URL) -> (any Error)? {
    let box = AsyncErrorBox()
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            try await library.addWatchFace(at: url)
            box.succeeded = true
        } catch {
            box.error = error
        }
        semaphore.signal()
    }
    let waitResult = semaphore.wait(timeout: .now() + 2)
    expect(waitResult == .success, "async addWatchFace timed out")
    expect(!box.succeeded, "async addWatchFace must not succeed")
    return box.error
}

private func exerciseErrorCodeIdentity() {
    let codes: [CLKWatchFaceLibrary.ErrorCode] = [
        .notFileURL,
        .invalidFile,
        .permissionDenied,
        .faceNotAvailable,
        .noURL,
    ]
    for code in codes {
        expect(
            CLKWatchFaceLibrary.ErrorCode(rawValue: code.rawValue) == code,
            "init(rawValue:) round-trip for \(code)"
        )
    }
    expect(CLKWatchFaceLibrary.ErrorCode.notFileURL != .invalidFile, "notFileURL != invalidFile")
    expect(CLKWatchFaceLibrary.ErrorCode.faceNotAvailable == .faceNotAvailable, "equality")

    var hasher = Hasher()
    CLKWatchFaceLibrary.ErrorCode.permissionDenied.hash(into: &hasher)
    let hashValue = CLKWatchFaceLibrary.ErrorCode.permissionDenied.hashValue
    expect(
        hashValue == CLKWatchFaceLibrary.ErrorCode.permissionDenied.hashValue,
        "hashValue is stable"
    )
    _ = hasher.finalize()

    let unique = Set(codes)
    expect(unique.count == codes.count, "ErrorCode hash/equality must distinguish cases")
}

private func exerciseFailClosedAdds() {
    expect(!CLKWatchFaceLibrary.ErrorDomain.isEmpty, "ErrorDomain is a nonempty class string")
    expect(
        CLKWatchFaceLibrary.ErrorCode.errorDomain == CLKWatchFaceLibrary.ErrorDomain,
        "CustomNSError uses CLKWatchFaceLibrary.ErrorDomain"
    )

    let library = CLKWatchFaceLibrary()
    let https = URL(string: "https://example.invalid/face.watchface")!
    expectFailClosed(addWatchFaceDelivered(library, at: https), "https completion")
    expectFailClosed(addWatchFaceAsync(library, at: https), "https async")

    let fileURL = URL(fileURLWithPath: "/tmp/clockkit-runtime-\(UUID().uuidString).watchface")
    expectFailClosed(addWatchFaceDelivered(library, at: fileURL), "file completion")
    expectFailClosed(addWatchFaceAsync(library, at: fileURL), "file async")

    let subclass = RecordingWatchFaceLibrary()
    let asBase: CLKWatchFaceLibrary = subclass
    expectFailClosed(addWatchFaceDelivered(asBase, at: fileURL), "subclass dynamic dispatch")
    expect(subclass.overrideCount == 1, "open addWatchFace must dispatch to the subclass override")
}

exerciseErrorCodeIdentity()
exerciseFailClosedAdds()
print("CLOCKKIT_AGENT_RUNTIME_OK")
