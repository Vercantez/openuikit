import AppTrackingTransparency
import Dispatch
import Foundation

func requireDenied(_ status: ATTrackingManager.AuthorizationStatus, _ label: String) {
    precondition(
        status == .denied,
        "\(label) must be denied, got \(status)"
    )
    precondition(status != .authorized, "\(label) must not be authorized")
    precondition(status != .notDetermined, "\(label) must not be pending")
    precondition(status != .restricted, "\(label) uses denied, not restricted")
}

func waitOrFail(_ semaphore: DispatchSemaphore, seconds: Int, _ label: String) {
    let result = semaphore.wait(timeout: .now() + .seconds(seconds))
    precondition(result == .success, "\(label) timed out")
}

func testAuthorizationStatusSurface() {
    let notDetermined = ATTrackingManager.AuthorizationStatus.notDetermined
    let restricted = ATTrackingManager.AuthorizationStatus.restricted
    let denied = ATTrackingManager.AuthorizationStatus.denied
    let authorized = ATTrackingManager.AuthorizationStatus.authorized

    precondition(notDetermined.rawValue == 0)
    precondition(restricted.rawValue == 1)
    precondition(denied.rawValue == 2)
    precondition(authorized.rawValue == 3)

    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 0) == .notDetermined)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 1) == .restricted)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 2) == .denied)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 3) == .authorized)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 4) == nil)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 99) == nil)

    precondition(denied == .denied)
    precondition(denied != .authorized)
    precondition(denied != .restricted)
    precondition(denied != .notDetermined)
    precondition(!(denied != .denied))
    precondition(authorized != denied)

    var hasher = Hasher()
    denied.hash(into: &hasher)
    var hasher2 = Hasher()
    ATTrackingManager.AuthorizationStatus.denied.hash(into: &hasher2)
    precondition(hasher.finalize() == hasher2.finalize())

    let hashValue = denied.hashValue
    precondition(hashValue == ATTrackingManager.AuthorizationStatus.denied.hashValue)
    precondition(hashValue != authorized.hashValue)

    let unique = Set([notDetermined, restricted, denied, authorized, .denied])
    precondition(unique.count == 4)
}

func testTrackingAuthorizationStatusFailClosed() {
    let status = ATTrackingManager.trackingAuthorizationStatus
    requireDenied(status, "trackingAuthorizationStatus")
    precondition(status.rawValue == 2)
}

/// Proves `requestTrackingAuthorization` returns before the handler runs, then
/// the handler receives `.denied` exactly once.
func testRequestReturnsBeforeDeniedCallback() {
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

    waitOrFail(finished, seconds: 5, "authorization callback")
    precondition(callbacks == 1, "completion must run exactly once")
    guard let received else {
        fatalError("completion did not deliver a status")
    }
    requireDenied(received, "requestTrackingAuthorization callback")
    precondition(received == ATTrackingManager.trackingAuthorizationStatus)
}

func testNestedCallbackDoesNotDeadlock() {
    let outerDone = DispatchSemaphore(value: 0)
    let innerDone = DispatchSemaphore(value: 0)
    var outerCount = 0
    var innerCount = 0

    ATTrackingManager.requestTrackingAuthorization { status in
        requireDenied(status, "outer callback")
        outerCount += 1
        ATTrackingManager.requestTrackingAuthorization { nested in
            requireDenied(nested, "nested callback")
            innerCount += 1
            innerDone.signal()
        }
        outerDone.signal()
    }

    waitOrFail(outerDone, seconds: 5, "outer authorization callback")
    waitOrFail(innerDone, seconds: 5, "nested authorization callback")
    precondition(outerCount == 1)
    precondition(innerCount == 1)
}

private final class AuthorizationHitCounter: @unchecked Sendable {
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

func testConcurrentCallbackAndAsyncRequests() {
    let total = 8
    let callbackHits = AuthorizationHitCounter()
    let asyncHits = AuthorizationHitCounter()
    let callbacksDone = DispatchSemaphore(value: 0)
    let asyncDone = DispatchSemaphore(value: 0)

    for _ in 0..<total {
        ATTrackingManager.requestTrackingAuthorization { status in
            requireDenied(status, "concurrent callback")
            if callbackHits.increment() == total {
                callbacksDone.signal()
            }
        }
    }

    for _ in 0..<total {
        Task {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            requireDenied(status, "concurrent async")
            if asyncHits.increment() == total {
                asyncDone.signal()
            }
        }
    }

    waitOrFail(callbacksDone, seconds: 10, "concurrent callback requests")
    waitOrFail(asyncDone, seconds: 10, "concurrent async requests")
    precondition(callbackHits.current() == total)
    precondition(asyncHits.current() == total)
}

func testRequestTrackingAuthorizationAsyncFailClosed() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    requireDenied(status, "requestTrackingAuthorization async")
    precondition(status == ATTrackingManager.trackingAuthorizationStatus)
}

func testManagerIdentity() {
    let manager: NSObject = ATTrackingManager()
    _ = String(describing: manager)
}

testAuthorizationStatusSurface()
testTrackingAuthorizationStatusFailClosed()
testRequestReturnsBeforeDeniedCallback()
testNestedCallbackDoesNotDeadlock()
testConcurrentCallbackAndAsyncRequests()
testManagerIdentity()

let semaphore = DispatchSemaphore(value: 0)
Task {
    await testRequestTrackingAuthorizationAsyncFailClosed()
    semaphore.signal()
}
waitOrFail(semaphore, seconds: 5, "async overload")

print("APPTRACKINGTRANSPARENCY_AGENT_RUNTIME_OK")
