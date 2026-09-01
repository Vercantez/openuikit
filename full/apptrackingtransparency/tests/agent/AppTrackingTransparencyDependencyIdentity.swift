import AppTrackingTransparency
import Dispatch
import Foundation

/// Future clean-EC2 identity probe. Imports the real Foundation and Dispatch
/// modules (not module-local stand-ins) together with AppTrackingTransparency.
/// The isolated host gate does not compile this file.

private func requireDenied(
    _ status: ATTrackingManager.AuthorizationStatus,
    _ label: String
) {
    precondition(status == .denied, "\(label) must be denied, got \(status)")
    precondition(status != .authorized, "\(label) must not be authorized")
}

private func waitOrFail(_ semaphore: DispatchSemaphore, seconds: Int, _ label: String) {
    let result = semaphore.wait(timeout: .now() + .seconds(seconds))
    precondition(result == .success, "\(label) timed out")
}

private final class IdentityHitCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }

    func current() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

func proveFoundationNSObjectIdentity() {
    let manager = ATTrackingManager()
    let asObject: NSObject = manager
    precondition(asObject === manager)
    let objects: [NSObject] = [manager, ATTrackingManager()]
    precondition(objects[0] === manager)
    precondition(objects[1] !== manager)
    _ = asObject.description
    _ = (manager as NSObject).hash
}

func proveRequestReturnsBeforeDeniedCallback() {
    let callerLock = NSLock()
    let finished = DispatchSemaphore(value: 0)
    var returned = false
    var callbacks = 0
    var received: ATTrackingManager.AuthorizationStatus?

    callerLock.lock()
    ATTrackingManager.requestTrackingAuthorization { status in
        let acquired = callerLock.lock(before: Date().addingTimeInterval(5))
        precondition(
            acquired,
            "completion appears inline: could not acquire the caller lock"
        )
        precondition(
            returned,
            "completion ran before requestTrackingAuthorization returned"
        )
        callbacks += 1
        received = status
        callerLock.unlock()
        finished.signal()
    }
    returned = true
    callerLock.unlock()

    waitOrFail(finished, seconds: 5, "identity authorization callback")
    precondition(callbacks == 1)
    guard let received else {
        fatalError("completion did not deliver a status")
    }
    requireDenied(received, "identity callback")
}

func proveNestedCallbackDoesNotDeadlockOrReenterInline() {
    let outerDone = DispatchSemaphore(value: 0)
    let innerDone = DispatchSemaphore(value: 0)
    var outerCount = 0
    var innerCount = 0
    var outerStillRunning = false

    ATTrackingManager.requestTrackingAuthorization { status in
        requireDenied(status, "identity outer callback")
        outerStillRunning = true
        outerCount += 1
        ATTrackingManager.requestTrackingAuthorization { nested in
            requireDenied(nested, "identity nested callback")
            precondition(
                !outerStillRunning,
                "nested completion reentered the outer handler"
            )
            innerCount += 1
            innerDone.signal()
        }
        outerStillRunning = false
        outerDone.signal()
    }

    waitOrFail(outerDone, seconds: 5, "identity outer callback")
    waitOrFail(innerDone, seconds: 5, "identity nested callback")
    precondition(outerCount == 1)
    precondition(innerCount == 1)
}

func proveConcurrentCallbackAndAsyncRequests() {
    let total = 8
    let callbackHits = IdentityHitCounter()
    let asyncHits = IdentityHitCounter()
    let callbacksDone = DispatchSemaphore(value: 0)
    let asyncDone = DispatchSemaphore(value: 0)

    for _ in 0..<total {
        ATTrackingManager.requestTrackingAuthorization { status in
            requireDenied(status, "identity concurrent callback")
            if callbackHits.increment() == total {
                callbacksDone.signal()
            }
        }
    }

    for _ in 0..<total {
        Task {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            requireDenied(status, "identity concurrent async")
            if asyncHits.increment() == total {
                asyncDone.signal()
            }
        }
    }

    waitOrFail(callbacksDone, seconds: 10, "identity concurrent callbacks")
    waitOrFail(asyncDone, seconds: 10, "identity concurrent async")
    precondition(callbackHits.current() == total)
    precondition(asyncHits.current() == total)
}

func proveAsyncOverloadUsesCallbackPath() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    requireDenied(status, "identity async overload")
    precondition(status == ATTrackingManager.trackingAuthorizationStatus)
}

proveFoundationNSObjectIdentity()
proveRequestReturnsBeforeDeniedCallback()
proveNestedCallbackDoesNotDeadlockOrReenterInline()
proveConcurrentCallbackAndAsyncRequests()

let asyncFinished = DispatchSemaphore(value: 0)
Task {
    await proveAsyncOverloadUsesCallbackPath()
    asyncFinished.signal()
}
waitOrFail(asyncFinished, seconds: 5, "identity async overload")

print("APPTRACKINGTRANSPARENCY_DEPENDENCY_IDENTITY_OK")
