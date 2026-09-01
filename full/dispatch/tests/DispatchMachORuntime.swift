import Combine
import Dispatch
import Foundation
import Synchronization

private final class CancellableBox: @unchecked Sendable {
    var value: AnyCancellable?
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError("DispatchMachORuntime: \(message)") }
}

private enum ExpectedSyncError: Error {
    case value
}

@main
private enum DispatchMachORuntime {
    static func main() async {
        let values = await withTaskGroup(of: Int.self) { group in
            for value in 1 ... 8 {
                group.addTask { value * value }
            }
            var result: [Int] = []
            for await value in group { result.append(value) }
            return result
        }
        require(values.count == 8, "task-group result count")
        require(values.reduce(0, +) == 204, "task-group result values")

        let detached = await Task.detached { 41 + 1 }.value
        require(detached == 42, "detached task result")

        let globalValue = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: 17)
            }
        }
        require(globalValue == 17, "portable Dispatch global callback")

        let mainValue = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume(returning: 23)
            }
        }
        require(mainValue == 23, "portable Dispatch main callback")

        let timerStarted = DispatchTime.now().uptimeNanoseconds
        let timerValue = await withCheckedContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(2)) {
                continuation.resume(returning: 29)
            }
        }
        require(timerValue == 29, "portable Dispatch delayed callback")
        require(DispatchTime.now().uptimeNanoseconds >= timerStarted, "monotonic time")

        let serial = DispatchQueue(
            label: "org.openui.dispatch.runtime.serial",
            qos: .utility
        )
        let serialValues = Mutex<[Int]>([])
        serial.async { serialValues.withLock { $0.append(1) } }
        let syncValue = serial.sync {
            serialValues.withLock { $0.append(2) }
            return 43
        }
        require(syncValue == 43, "custom serial queue sync return value")
        require(
            serialValues.withLock { $0 } == [1, 2],
            "custom serial queue ordering"
        )

        do {
            _ = try serial.sync { () throws -> Int in
                throw ExpectedSyncError.value
            }
            fatalError("DispatchMachORuntime: throwing sync returned")
        } catch ExpectedSyncError.value {
            // The error crossed the synchronous C callback without crossing
            // the C ABI itself.
        } catch {
            fatalError("DispatchMachORuntime: wrong throwing sync error")
        }

        let concurrent = DispatchQueue(
            label: "org.openui.dispatch.runtime.concurrent",
            attributes: .concurrent
        )
        let concurrentCount = Mutex(0)
        for _ in 0 ..< 16 {
            concurrent.async { concurrentCount.withLock { $0 += 1 } }
        }
        let barrierCount = concurrent.sync(flags: .barrier) {
            concurrentCount.withLock { value -> Int in
                value += 1
                return value
            }
        }
        require(barrierCount == 17, "concurrent barrier did not drain prior work")

        let targeted = DispatchQueue(
            label: "org.openui.dispatch.runtime.targeted",
            target: serial
        )
        let targetedValue = targeted.sync { 44 }
        require(targetedValue == 44, "custom queue target execution")

        let pressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: serial
        )
        let pressureRaw = await withCheckedContinuation { continuation in
            pressureSource.setEventHandler {
                continuation.resume(returning: pressureSource.data.rawValue)
            }
            pressureSource.activate()
        }
        require(
            pressureRaw == DispatchSource.MemoryPressureEvent.critical.rawValue,
            "critical host memory-pressure event"
        )
        require(
            pressureSource.mask == [.warning, .critical],
            "memory-pressure event mask"
        )
        let pressureCancelled = await withCheckedContinuation { continuation in
            pressureSource.setCancelHandler { continuation.resume(returning: true) }
            pressureSource.cancel()
        }
        require(pressureCancelled && pressureSource.isCancelled, "source cancellation")

        let oneShot = DispatchSource.makeTimerSource(queue: serial)
        let sourceTimerValue = await withCheckedContinuation { continuation in
            oneShot.schedule(deadline: .now() + .milliseconds(2))
            oneShot.setEventHandler { continuation.resume(returning: 47) }
            oneShot.resume()
        }
        require(sourceTimerValue == 47 && oneShot.data == 1, "one-shot source timer")
        oneShot.cancel()

        let cancelledSourceFired = Mutex(false)
        let cancelledSource = DispatchSource.makeTimerSource(queue: serial)
        cancelledSource.schedule(deadline: .now() + .milliseconds(10))
        cancelledSource.setEventHandler {
            cancelledSourceFired.withLock { $0 = true }
        }
        cancelledSource.resume()
        cancelledSource.cancel()
        await withCheckedContinuation { continuation in
            serial.asyncAfter(deadline: .now() + .milliseconds(20)) {
                continuation.resume()
            }
        }
        require(
            !cancelledSourceFired.withLock { $0 },
            "cancelled Dispatch source timer callback"
        )

        let scheduler = DispatchQueue.global(qos: .utility)
        let scheduledValue = await withCheckedContinuation { continuation in
            scheduler.schedule {
                continuation.resume(returning: 31)
            }
        }
        require(scheduledValue == 31, "OpenCombine immediate scheduler callback")

        let delayedValue = await withCheckedContinuation { continuation in
            scheduler.schedule(
                after: scheduler.now.advanced(by: .milliseconds(2)),
                tolerance: .nanoseconds(0),
                options: nil
            ) {
                continuation.resume(returning: 37)
            }
        }
        require(delayedValue == 37, "OpenCombine delayed scheduler callback")

        let cancelledTimerFired = Mutex(false)
        let repeating = scheduler.schedule(
            after: scheduler.now.advanced(by: .milliseconds(10)),
            interval: .milliseconds(1),
            tolerance: .nanoseconds(0),
            options: nil
        ) {
            cancelledTimerFired.withLock { $0 = true }
        }
        repeating.cancel()
        repeating.cancel()
        await withCheckedContinuation { continuation in
            scheduler.asyncAfter(deadline: .now() + .milliseconds(20)) {
                continuation.resume()
            }
        }
        require(
            !cancelledTimerFired.withLock { $0 },
            "cancelled repeating scheduler callback"
        )

        let subject = PassthroughSubject<Int, Never>()
        let cancellable = CancellableBox()
        let receivedValue = await withCheckedContinuation { continuation in
            cancellable.value = subject
                .receive(on: scheduler)
                .sink { value in
                    continuation.resume(returning: value)
                }
            subject.send(41)
        }
        require(receivedValue == 41, "OpenCombine receive(on:) delivery")
        cancellable.value?.cancel()

        print("OPEN_DISPATCH_MACHO_OK async-main=drained taskgroup=8 detached=42 global=17 main=23 after=29 custom=serial,concurrent,targeted sync=ordered,barrier,rethrows sources=memory-pressure,timer,cancelled scheduler=immediate,delayed,cancelled,receive-on vouchers=null")
    }
}
