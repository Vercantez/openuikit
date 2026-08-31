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

        print("OPEN_DISPATCH_MACHO_OK async-main=drained taskgroup=8 detached=42 global=17 main=23 after=29 scheduler=immediate,delayed,cancelled,receive-on vouchers=null")
    }
}
