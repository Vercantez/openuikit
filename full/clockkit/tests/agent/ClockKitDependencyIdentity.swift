import Dispatch
import Foundation
import UIKit
import ClockKit

/// Future clean EC2 client: import real Foundation, UIKit, and ClockKit
/// together, pass a Foundation.URL, inspect NSError, prove non-inline
/// exactly-once completion plus async failure, and exercise open-method
/// override dispatch. Does not define local types named after first-party
/// dependency types.
///
/// Isolated `tests/acceptance/test_host.sh` does not compile this file.
/// A later clean EC2 run should:
/// 1. Build guest Foundation and UIKit modules and dylibs first.
/// 2. Build ClockKit with those `-I` and `-L` paths.
/// 3. Link this client against ClockKit and its dependencies.
/// 4. Run with `LD_LIBRARY_PATH` and confirm `libClockKit.dylib` loaded.
/// No local Docker.

private final class IdentityCallbackBox: @unchecked Sendable {
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

private final class IdentityAsyncBox: @unchecked Sendable {
    var error: (any Error)?
    var succeeded = false
}

private final class IdentityWatchFaceLibrary: CLKWatchFaceLibrary, @unchecked Sendable {
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

private func identityExpect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func inspectNSError(_ error: any Error, _ label: String) -> NSError {
    let nsError = error as NSError
    identityExpect(!nsError.domain.isEmpty, "\(label): NSError domain")
    identityExpect(
        nsError.domain == CLKWatchFaceLibrary.ErrorDomain,
        "\(label): domain \(nsError.domain)"
    )
    let existential: any Error = error
    identityExpect(
        (existential as? CLKWatchFaceLibrary.ErrorCode) == .faceNotAvailable
            || nsError.domain == CLKWatchFaceLibrary.ErrorDomain,
        "\(label): existential Error remains inspectable as NSError"
    )
    return nsError
}

private func deliverOnce(_ library: CLKWatchFaceLibrary, at url: Foundation.URL) -> NSError {
    let box = IdentityCallbackBox(caller: Thread.current)
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
    box.lock.unlock()
    identityExpect(!inline, "dependency identity: completion must not run inline")
    let waitResult = finished.wait(timeout: .now() + 2)
    identityExpect(waitResult == .success, "dependency identity: completion timed out")
    Thread.sleep(forTimeInterval: 0.05)
    box.lock.lock()
    let calls = box.calls
    let error = box.error
    box.lock.unlock()
    identityExpect(calls == 1, "dependency identity: completion must run exactly once")
    guard let error else {
        fatalError("dependency identity: addWatchFace succeeded")
    }
    return inspectNSError(error, "callback")
}

private func asyncFailure(_ library: CLKWatchFaceLibrary, at url: Foundation.URL) -> NSError {
    let box = IdentityAsyncBox()
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
    identityExpect(waitResult == .success, "dependency identity: async timed out")
    identityExpect(!box.succeeded, "dependency identity: async must fail closed")
    guard let error = box.error else {
        fatalError("dependency identity: async produced no error")
    }
    return inspectNSError(error, "async")
}

let uiKitColor = UIColor(white: 1, alpha: 1)
identityExpect(uiKitColor !== UIColor(white: 0, alpha: 1), "UIKit.UIColor identity")

let fileURL: Foundation.URL = Foundation.URL(
    fileURLWithPath: "/tmp/clockkit-dependency-identity.watchface"
)
identityExpect(fileURL.isFileURL, "Foundation.URL must be a real file URL")

let subclass = IdentityWatchFaceLibrary()
let asBase: CLKWatchFaceLibrary = subclass
let callbackError = deliverOnce(asBase, at: fileURL)
identityExpect(subclass.overrideCount == 1, "open addWatchFace override dispatch")
let asyncError = asyncFailure(subclass, at: fileURL)
identityExpect(subclass.overrideCount == 2, "async overlay must share the open completion path")
identityExpect(
    callbackError.domain == asyncError.domain,
    "callback and async fail-closed domains must match"
)

print("CLOCKKIT_DEPENDENCY_IDENTITY_OK")
