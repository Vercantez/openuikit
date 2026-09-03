import Dispatch
import Foundation
import ClockKit

private final class CallbackBox: @unchecked Sendable {
    var count = 0
    var domain: String?
    var code: Int?
    var secondCall = false
}

private final class OverrideLibrary: CLKWatchFaceLibrary {
    var overrideCount = 0

    override func addWatchFace(
        at fileURL: URL,
        completionHandler handler: @escaping (Error?) -> Void
    ) {
        overrideCount += 1
        super.addWatchFace(at: fileURL, completionHandler: handler)
    }
}

private func wait(_ semaphore: DispatchSemaphore, _ label: String) {
    if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
        fatalError("timed out waiting for \(label)")
    }
}

private func nsError(_ error: Error?) -> NSError {
    guard let error else {
        fatalError("expected NSError, got success")
    }
    return error as NSError
}

// MARK: - Error domain and codes 1...5

precondition(CLKWatchFaceLibrary.ErrorDomain == "CLKWatchFaceLibraryErrorDomain")

let expected: [(CLKWatchFaceLibrary.ErrorCode, Int)] = [
    (.notFileURL, 1),
    (.invalidFile, 2),
    (.permissionDenied, 3),
    (.faceNotAvailable, 4),
    (.noURL, 5),
]
for (code, raw) in expected {
    precondition(code.rawValue == raw)
    precondition(CLKWatchFaceLibrary.ErrorCode(rawValue: raw) == code)
}
precondition(CLKWatchFaceLibrary.ErrorCode(rawValue: 0) == nil)
precondition(CLKWatchFaceLibrary.ErrorCode(rawValue: 6) == nil)
precondition(CLKWatchFaceLibrary.ErrorCode(rawValue: -1) == nil)

// MARK: - Synthesized Equatable / Hashable

precondition(CLKWatchFaceLibrary.ErrorCode.notFileURL != .invalidFile)
precondition(!(CLKWatchFaceLibrary.ErrorCode.notFileURL != .notFileURL))
precondition(CLKWatchFaceLibrary.ErrorCode.notFileURL == .notFileURL)

var hasher = Hasher()
CLKWatchFaceLibrary.ErrorCode.permissionDenied.hash(into: &hasher)
let hashed = hasher.finalize()
precondition(
    CLKWatchFaceLibrary.ErrorCode.permissionDenied.hashValue
        == CLKWatchFaceLibrary.ErrorCode.permissionDenied.hashValue
)
precondition(Set(expected.map(\.0)).count == 5)
_ = hashed

// MARK: - NSObject identity

private let library = CLKWatchFaceLibrary()
precondition((library as NSObject) === library)
precondition(library.hash == (library as NSObject).hash)

// MARK: - Observed non-file URL: non-inline, exactly once, code 1

private let nonFile = URL(string: "https://example.invalid/face.watchface")!
private let box = CallbackBox()
private let done = DispatchSemaphore(value: 0)

precondition(Thread.isMainThread)
library.addWatchFace(at: nonFile) { error in
    precondition(!Thread.isMainThread, "non-file completion must not run on the calling thread")
    if box.count == 0 {
        let ns = nsError(error)
        box.domain = ns.domain
        box.code = ns.code
    } else {
        box.secondCall = true
    }
    box.count += 1
    done.signal()
}
wait(done, "non-file completion")

precondition(box.count == 1, "completion must run exactly once")
precondition(!box.secondCall)
precondition(box.domain == CLKWatchFaceLibrary.ErrorDomain)
precondition(box.code == CLKWatchFaceLibrary.ErrorCode.notFileURL.rawValue)
precondition(box.code == 1)

// A second non-file request also completes exactly once (no coalescing).
private let done2 = DispatchSemaphore(value: 0)
private let secondBox = CallbackBox()
library.addWatchFace(at: URL(string: "clockkit://not-a-file")!) { error in
    precondition(!Thread.isMainThread)
    secondBox.count += 1
    let ns = nsError(error)
    secondBox.domain = ns.domain
    secondBox.code = ns.code
    done2.signal()
}
wait(done2, "second non-file completion")
precondition(secondBox.count == 1)
precondition(secondBox.domain == "CLKWatchFaceLibraryErrorDomain")
precondition(secondBox.code == 1)

// MARK: - Async overlay shares the completion-handler path

private let asyncDone = DispatchSemaphore(value: 0)
private let asyncBox = CallbackBox()
Task {
    do {
        try await library.addWatchFace(at: nonFile)
        asyncBox.count = -1
    } catch {
        let ns = error as NSError
        asyncBox.domain = ns.domain
        asyncBox.code = ns.code
        asyncBox.count = 1
    }
    asyncDone.signal()
}
wait(asyncDone, "async overlay")
precondition(asyncBox.count == 1)
precondition(asyncBox.domain == CLKWatchFaceLibrary.ErrorDomain)
precondition(asyncBox.code == 1)

// MARK: - Subclass override dispatch

private let overrideLib = OverrideLibrary()
private let overrideDone = DispatchSemaphore(value: 0)
(overrideLib as CLKWatchFaceLibrary).addWatchFace(at: nonFile) { error in
    precondition(!Thread.isMainThread)
    let ns = nsError(error)
    precondition(ns.code == 1)
    overrideDone.signal()
}
wait(overrideDone, "subclass override")
precondition(overrideLib.overrideCount == 1)

private let overrideAsyncDone = DispatchSemaphore(value: 0)
Task {
    do {
        try await (overrideLib as CLKWatchFaceLibrary).addWatchFace(at: nonFile)
        fatalError("async overlay must not succeed")
    } catch {
        precondition((error as NSError).code == 1)
    }
    overrideAsyncDone.signal()
}
wait(overrideAsyncDone, "subclass async overlay")
precondition(overrideLib.overrideCount == 2)

// MARK: - Linux never-success for a file URL (host policy, not Apple-observed)

private let fileURL = URL(fileURLWithPath: "/tmp/openuikit-clockkit-missing.watchface")
precondition(fileURL.isFileURL)
private let fileDone = DispatchSemaphore(value: 0)
private let fileBox = CallbackBox()
library.addWatchFace(at: fileURL) { error in
    precondition(!Thread.isMainThread)
    let ns = nsError(error)
    fileBox.domain = ns.domain
    fileBox.code = ns.code
    fileBox.count += 1
    fileDone.signal()
}
wait(fileDone, "file URL fail-closed")
precondition(fileBox.count == 1)
precondition(fileBox.domain == CLKWatchFaceLibrary.ErrorDomain)
precondition(fileBox.code == CLKWatchFaceLibrary.ErrorCode.faceNotAvailable.rawValue)

print("CLOCKKIT_AGENT_RUNTIME_OK")
