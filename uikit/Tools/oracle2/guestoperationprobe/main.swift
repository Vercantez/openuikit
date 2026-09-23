// guestoperationprobe -- Operation / BlockOperation / OperationQueue, the
// Apple side (run.sh, iOS 26.1 simulator) and the guest side
// (Tools/guestprobes/GuestOperationProbe.probe.sh) of the same program.
import Foundation

final class Log: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String] = []
    func add(_ s: String) { lock.lock(); items.append(s); lock.unlock() }
    var all: [String] { lock.lock(); defer { lock.unlock() }; return items }
    var joined: String { all.joined(separator: ",") }
}

final class Plain: Operation, @unchecked Sendable {
    let log: Log
    let tag: String
    init(_ tag: String, _ log: Log) { self.tag = tag; self.log = log; super.init() }
    override func main() { log.add("\(tag)\(isExecuting ? "+" : "-")\(Thread.isMainThread ? "M" : "")") }
}

/// The corpus's asynchronous-operation pattern (WordPress AsyncOperation,
/// wikipedia AsyncOperation): own state, will/didChangeValue(forKey:).
final class Async: Operation, @unchecked Sendable {
    private let lock = NSLock()
    private var _executing = false
    private var _finished = false
    let log: Log
    init(_ log: Log) { self.log = log; super.init() }
    override var isAsynchronous: Bool { true }
    override var isExecuting: Bool { lock.lock(); defer { lock.unlock() }; return _executing }
    override var isFinished: Bool { lock.lock(); defer { lock.unlock() }; return _finished }
    override func start() {
        if isCancelled { finish(); return }
        willChangeValue(forKey: "isExecuting")
        lock.lock(); _executing = true; lock.unlock()
        didChangeValue(forKey: "isExecuting")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            self.log.add("async-work")
            self.finish()
        }
    }
    func finish() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        lock.lock(); _executing = false; _finished = true; lock.unlock()
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
}

func say(_ items: Any...) { print(items.map { "\($0)" }.joined(separator: " ")) }

@main
struct GuestOperationProbe {
    static func main() {
        print("guestoperationprobe v1")
        // A fresh operation.
        let fresh = BlockOperation { }
        say("op.new", "ready=\(fresh.isReady)", "executing=\(fresh.isExecuting)", "finished=\(fresh.isFinished)",
            "cancelled=\(fresh.isCancelled)", "async=\(fresh.isAsynchronous)", "concurrent=\(fresh.isConcurrent)",
            "priority=\(fresh.queuePriority.rawValue)", "qos=\(fresh.qualityOfService.rawValue)",
            "name=\(String(describing: fresh.name))", "blocks=\(fresh.executionBlocks.count)")

        // start() runs main synchronously on the calling thread.
        let log0 = Log()
        let direct = Plain("direct", log0)
        direct.start()
        say("op.start.direct", log0.joined, "finished=\(direct.isFinished)", "executing=\(direct.isExecuting)")

        // Cancelled before start: main is skipped, the op finishes, completionBlock runs.
        let log1 = Log()
        let cancelled = Plain("cancelled", log1)
        let completion = DispatchSemaphore(value: 0)
        cancelled.completionBlock = { log1.add("completion"); completion.signal() }
        cancelled.cancel()
        say("op.cancelled.beforeStart", "ready=\(cancelled.isReady)", "finished=\(cancelled.isFinished)")
        cancelled.start()
        _ = completion.wait(timeout: .now() + 5)
        say("op.cancelled.started", log1.joined, "finished=\(cancelled.isFinished)", "cancelled=\(cancelled.isCancelled)")

        // A serial queue runs in order; dependencies reorder.
        let queue = OperationQueue()
        say("queue.new", "max=\(queue.maxConcurrentOperationCount)", "suspended=\(queue.isSuspended)",
            "count=\(queue.operationCount)", "namePrefix=\(queue.name?.hasPrefix("NSOperationQueue 0x") ?? false)",
            "mainName=\(OperationQueue.main.name ?? "nil")",
            "default=\(OperationQueue.defaultMaxConcurrentOperationCount)")
        queue.maxConcurrentOperationCount = 1
        let log2 = Log()
        let a = Plain("a", log2), b = Plain("b", log2), c = Plain("c", log2)
        a.addDependency(c)
        say("op.dependency", "aReady=\(a.isReady)", "deps=\(a.dependencies.count)")
        queue.addOperations([a, b, c], waitUntilFinished: true)
        say("queue.serial.dependency", log2.joined, "count=\(queue.operationCount)",
            "aReady=\(a.isReady)", "allFinished=\([a, b, c].allSatisfy { $0.isFinished })")

        // Suspended queue: priority decides the order once resumed (serial).
        let log3 = Log()
        queue.isSuspended = true
        let low = Plain("low", log3); low.queuePriority = .low
        let normal = Plain("normal", log3)
        let high = Plain("high", log3); high.queuePriority = .veryHigh
        queue.addOperation(low); queue.addOperation(normal); queue.addOperation(high)
        say("queue.suspended", "count=\(queue.operationCount)", "ran=\(log3.all.count)")
        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()
        say("queue.priority", log3.joined)

        // Block operations, addOperation(block), barrier.
        let log4 = Log()
        let blocks = BlockOperation { log4.add("b1") }
        blocks.addExecutionBlock { log4.add("b2") }
        blocks.addExecutionBlock { log4.add("b3") }
        say("blockop.blocks", blocks.executionBlocks.count)
        let concurrent = OperationQueue()
        concurrent.addOperation(blocks)
        blocks.waitUntilFinished()
        say("blockop.ran", log4.all.sorted().joined(separator: ","))
        let log5 = Log()
        let serial = OperationQueue()
        serial.maxConcurrentOperationCount = 1
        serial.addOperation { log5.add("x") }
        serial.addBarrierBlock { log5.add("barrier") }
        serial.addOperation { log5.add("y") }
        serial.waitUntilAllOperationsAreFinished()
        say("queue.barrier", log5.joined)

        // Asynchronous subclass driven by will/didChangeValue(forKey:).
        let log6 = Log()
        let async = Async(log6)
        let after = BlockOperation { log6.add("after") }
        after.addDependency(async)
        concurrent.addOperations([async, after], waitUntilFinished: true)
        say("op.async", log6.joined, "finished=\(async.isFinished)", "afterFinished=\(after.isFinished)")

        // cancelAllOperations on a suspended queue.
        let log7 = Log()
        let held = OperationQueue()
        held.isSuspended = true
        let h1 = Plain("h1", log7), h2 = Plain("h2", log7)
        held.addOperations([h1, h2], waitUntilFinished: false)
        held.cancelAllOperations()
        say("queue.cancelAll.suspended", "count=\(held.operationCount)", "cancelled=\(h1.isCancelled && h2.isCancelled)")
        held.isSuspended = false
        held.waitUntilAllOperationsAreFinished()
        say("queue.cancelAll.resumed", "ran=\(log7.joined.isEmpty ? "none" : log7.joined)", "count=\(held.operationCount)",
            "finished=\(h1.isFinished && h2.isFinished)")

        // Work does not run on the main thread; underlyingQueue.
        let log8 = Log()
        let bg = OperationQueue()
        bg.addOperation { log8.add("main=\(Thread.isMainThread)") }
        bg.waitUntilAllOperationsAreFinished()
        say("queue.thread", log8.joined, "underlying=\(bg.underlyingQueue == nil ? "nil" : "set")",
            "mainUnderlying=\(OperationQueue.main.underlyingQueue == nil ? "nil" : "set")",
            "mainMax=\(OperationQueue.main.maxConcurrentOperationCount)")
        let custom = DispatchQueue(label: "guest.probe.underlying")
        let key = DispatchSpecificKey<String>()
        custom.setSpecific(key: key, value: "custom")
        let log9 = Log()
        let viaCustom = OperationQueue()
        viaCustom.underlyingQueue = custom
        viaCustom.addOperation { log9.add("specific=\(DispatchQueue.getSpecific(key: key) ?? "nil")") }
        viaCustom.waitUntilAllOperationsAreFinished()
        say("queue.underlying", log9.joined)
        print("guestoperationprobe done")
    }
}
