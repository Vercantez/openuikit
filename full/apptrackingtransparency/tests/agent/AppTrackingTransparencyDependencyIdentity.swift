@_spi(OpenUIKitHost) import AppTrackingTransparency
import Dispatch
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation and Dispatch modules and dylibs.
// 2. Build AppTrackingTransparency with those modules on `-I` / `-L`.
// 3. Link this file as a client that `import`s Foundation, Dispatch, and
//    AppTrackingTransparency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `APPTRACKINGTRANSPARENCY_DEPENDENCY_IDENTITY_OK` and that
//    `libAppTrackingTransparency.dylib` was loaded.

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback() {
        lock.lock()
        sawReturned = returned
        count += 1
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class CompletionQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        AppTrackingTransparencyHostControl.enqueueCompletionProbe {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "completion queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func assertNotAppTrackingType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("AppTrackingTransparency."))
}

private func assertFoundationAndDispatchIdentity() {
    let _: Foundation.NSObject.Type = NSObject.self
    let _: Foundation.NSLock.Type = NSLock.self
    let _: Dispatch.DispatchQueue.Type = DispatchQueue.self
    let _: Dispatch.DispatchSemaphore.Type = DispatchSemaphore.self
    let _: AppTrackingTransparency.ATTrackingManager.Type = ATTrackingManager.self
    let _: AppTrackingTransparency.ATTrackingManager.AuthorizationStatus.Type =
        ATTrackingManager.AuthorizationStatus.self

    precondition(!String(reflecting: NSObject.self).hasPrefix("AppTrackingTransparency."))
    precondition(!String(reflecting: DispatchQueue.self).hasPrefix("AppTrackingTransparency."))
    precondition(!String(reflecting: DispatchSemaphore.self).hasPrefix("AppTrackingTransparency."))
}

private func passFoundationValues() {
    let manager = ATTrackingManager()
    let asObject: NSObject = manager
    precondition(asObject === manager)
    assertNotAppTrackingType(asObject)
    precondition(type(of: manager) == ATTrackingManager.self)

    let status = ATTrackingManager.trackingAuthorizationStatus
    precondition(status == .denied)
    precondition(status.rawValue == 2)
    let boxed: NSNumber = NSNumber(value: status.rawValue)
    assertNotAppTrackingType(boxed)
    precondition(boxed.uintValue == 2)
}

private func proveNonInlineDeniedCallback() {
    let state = LockedState()
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    ATTrackingManager.requestTrackingAuthorization { status in
        state.noteCallback()
        precondition(status == .denied)
        precondition(type(of: status) == ATTrackingManager.AuthorizationStatus.self)
    }
    state.markReturned()
    let drained = DispatchSemaphore(value: 0)
    AppTrackingTransparencyHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "identity request callback did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.sawReturned)
    precondition(snapshot.count == 1)
}

private func exerciseConcurrentCallbackAndAsync() async {
    let group = DispatchGroup()
    for _ in 0..<4 {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            ATTrackingManager.requestTrackingAuthorization { status in
                precondition(status == .denied)
                group.leave()
            }
        }
    }

    await withTaskGroup(of: Void.self) { taskGroup in
        for _ in 0..<4 {
            taskGroup.addTask {
                let status = await ATTrackingManager.requestTrackingAuthorization()
                precondition(status == .denied)
            }
        }
        await taskGroup.waitForAll()
    }

    let waitResult = group.wait(timeout: .now() + eventTimeout)
    precondition(waitResult == .success, "identity mixed wait timed out")
}

func appTrackingTransparencyDependencyIdentityMain() async {
    assertFoundationAndDispatchIdentity()
    passFoundationValues()
    proveNonInlineDeniedCallback()
    await exerciseConcurrentCallbackAndAsync()
    print("APPTRACKINGTRANSPARENCY_DEPENDENCY_IDENTITY_OK")
}

let identitySemaphore = DispatchSemaphore(value: 0)
Task {
    await appTrackingTransparencyDependencyIdentityMain()
    identitySemaphore.signal()
}
identitySemaphore.wait()
