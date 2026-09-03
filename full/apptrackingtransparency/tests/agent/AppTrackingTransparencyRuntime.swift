@_spi(OpenUIKitHost) import AppTrackingTransparency
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var lastStatus: ATTrackingManager.AuthorizationStatus?

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(_ status: ATTrackingManager.AuthorizationStatus) {
        lock.lock()
        sawReturned = returned
        count += 1
        lastStatus = status
        lock.unlock()
    }

    func snapshot() -> (
        sawReturned: Bool,
        count: Int,
        lastStatus: ATTrackingManager.AuthorizationStatus?
    ) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, lastStatus)
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    func current() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

/// Occupy the SPI-exposed Linux completion queue until `release` so later `async`
/// completions cannot run. `occupy` returns only after the blocker is running.
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

private func drainCompletionQueue() {
    let drained = DispatchSemaphore(value: 0)
    AppTrackingTransparencyHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    waitEvent(drained, "completion queue did not drain")
}

private func exerciseAuthorizationStatus() {
    typealias Status = ATTrackingManager.AuthorizationStatus

    let expected: [(Status, UInt)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.authorized, 3),
    ]
    for (status, raw) in expected {
        precondition(status.rawValue == raw)
        precondition(Status(rawValue: raw) == status)
    }
    precondition(Status(rawValue: 4) == nil)
    precondition(Status(rawValue: 99) == nil)

    precondition(Status.notDetermined != Status.denied)
    precondition(Status.restricted != Status.authorized)
    precondition(!(Status.denied != Status.denied))
    precondition(Status.denied == Status(rawValue: 2))

    var hasher = Hasher()
    Status.denied.hash(into: &hasher)
    Status.authorized.hash(into: &hasher)
    _ = hasher.finalize()

    var set: Set<Status> = []
    for status in [Status.notDetermined, .restricted, .denied, .authorized] {
        set.insert(status)
    }
    precondition(set.count == 4)
    precondition(set.contains(.denied))
    precondition(set.contains(.authorized))
}

private func exerciseManagerIdentity() {
    let manager = ATTrackingManager()
    let asObject: NSObject = manager
    precondition(asObject === manager)
    precondition(type(of: manager) == ATTrackingManager.self)

    precondition(ATTrackingManager.trackingAuthorizationStatus == .denied)
    precondition(ATTrackingManager.trackingAuthorizationStatus.rawValue == 2)
    precondition(ATTrackingManager.trackingAuthorizationStatus != .authorized)
    precondition(ATTrackingManager.trackingAuthorizationStatus != .notDetermined)
    precondition(ATTrackingManager.trackingAuthorizationStatus != .restricted)
}

private func proveRequestCallback() {
    let state = LockedState()
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    ATTrackingManager.requestTrackingAuthorization { status in
        state.noteCallback(status)
        precondition(status == .denied)
        precondition(status != .authorized)
    }
    state.markReturned()
    let drained = DispatchSemaphore(value: 0)
    AppTrackingTransparencyHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "request callback did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.sawReturned, "callback did not observe returned=true")
    precondition(snapshot.count == 1)
    precondition(snapshot.lastStatus == .denied)
    precondition(ATTrackingManager.trackingAuthorizationStatus == .denied)
}

private func proveNestedCallbackDoesNotDeadlock() {
    let finished = DispatchSemaphore(value: 0)
    let innerCount = LockedCounter()
    ATTrackingManager.requestTrackingAuthorization { outer in
        precondition(outer == .denied)
        ATTrackingManager.requestTrackingAuthorization { inner in
            precondition(inner == .denied)
            innerCount.increment()
            finished.signal()
        }
    }
    waitEvent(finished, "nested request did not complete")
    precondition(innerCount.current() == 1)
}

private func exerciseConcurrentCallbacks() {
    let iterations = 8
    let group = DispatchGroup()
    let count = LockedCounter()

    for _ in 0..<iterations {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            ATTrackingManager.requestTrackingAuthorization { status in
                precondition(status == .denied)
                count.increment()
                group.leave()
            }
        }
    }

    let waitResult = group.wait(timeout: .now() + eventTimeout)
    precondition(waitResult == .success, "concurrent callbacks timed out")
    precondition(count.current() == iterations)
}

private func exerciseAsyncOverlay() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    precondition(status == .denied)
    precondition(status.rawValue == 2)
    precondition(ATTrackingManager.trackingAuthorizationStatus == .denied)

    await withTaskGroup(of: ATTrackingManager.AuthorizationStatus.self) { group in
        for _ in 0..<4 {
            group.addTask {
                await ATTrackingManager.requestTrackingAuthorization()
            }
        }
        var seen = 0
        for await result in group {
            precondition(result == .denied)
            seen += 1
        }
        precondition(seen == 4)
    }
}

private func exerciseMixedCallbackAndAsync() async {
    let group = DispatchGroup()
    let callbackCount = LockedCounter()
    let asyncCount = LockedCounter()

    for _ in 0..<4 {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            ATTrackingManager.requestTrackingAuthorization { status in
                precondition(status == .denied)
                callbackCount.increment()
                group.leave()
            }
        }
    }

    await withTaskGroup(of: Void.self) { taskGroup in
        for _ in 0..<4 {
            taskGroup.addTask {
                let status = await ATTrackingManager.requestTrackingAuthorization()
                precondition(status == .denied)
                asyncCount.increment()
            }
        }
        await taskGroup.waitForAll()
    }

    let waitResult = group.wait(timeout: .now() + eventTimeout)
    precondition(waitResult == .success, "mixed callback wait timed out")
    precondition(callbackCount.current() == 4)
    precondition(asyncCount.current() == 4)
}

func appTrackingTransparencyRuntimeMain() async {
    exerciseAuthorizationStatus()
    exerciseManagerIdentity()
    proveRequestCallback()
    proveNestedCallbackDoesNotDeadlock()
    exerciseConcurrentCallbacks()
    await exerciseAsyncOverlay()
    await exerciseMixedCallbackAndAsync()
    drainCompletionQueue()
    print("APPTRACKINGTRANSPARENCY_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await appTrackingTransparencyRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()
