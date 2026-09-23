// Foundation.Operation, BlockOperation and a scheduling OperationQueue for the
// Linux-hosted Mach-O guest (docs/agent_reports/guest-swift-modules.md).
//
// OperationQueue's identity is OpenUIKit's (the hidden-Foundation argument
// shim UIKit and NotificationCenter already speak, aliased by
// full/appshim/FoundationOpenUIKitAliases.swift); its scheduling state lives
// in a side table keyed by the queue object, so the one class stays the one
// class. Operations run on Dispatch: OperationQueue.main's on the main queue,
// every other queue's on a global queue, or on `underlyingQueue` when set.
//
// Contract measured on the iOS 26.1 simulator by
// uikit/Tools/oracle2/guestoperationprobe (transcript-ios26.1.txt), which the
// guest runs unchanged (uikit/Tools/guestprobes/GuestOperationProbe.probe.sh).
// Key-value observing is not available in the guest, so an asynchronous
// subclass's `didChangeValue(forKey: "isFinished")` is delivered to
// Operation's own will/didChangeValue(forKey:), which is how the queue learns
// the operation finished.

#if canImport(Darwin)
import Darwin
#endif
import Dispatch
import FoundationEssentials
import ObjectiveC
import OpenUIKit

extension Operation {
    public enum QueuePriority: Int, @unchecked Sendable {
        case veryLow = -8
        case low = -4
        case normal = 0
        case high = 4
        case veryHigh = 8
    }
}

open class Operation: NSObject, @unchecked Sendable {
    fileprivate let _lock = NSRecursiveLock()
    private var _executing = false
    private var _finished = false
    private var _cancelled = false
    private var _started = false
    private var _dependencies: [Operation] = []
    private var _completionBlock: (@Sendable () -> Void)?
    private var _name: String?
    private var _queuePriority: QueuePriority = .normal
    private var _qualityOfService: QualityOfService = .default
    private var _waiters: [DispatchSemaphore] = []
    fileprivate var _queues: [_OperationQueueState] = []
    fileprivate var _enqueueOrder = 0

    public override init() {
        super.init()
    }

    // MARK: state

    open var isCancelled: Bool { _lock.withLock { _cancelled } }
    open var isExecuting: Bool { _lock.withLock { _executing } }
    open var isFinished: Bool { _lock.withLock { _finished } }
    open var isConcurrent: Bool { isAsynchronous }
    open var isAsynchronous: Bool { false }

    open var isReady: Bool {
        let dependencies = _lock.withLock { _dependencies }
        return dependencies.allSatisfy { $0.isFinished }
    }

    open var name: String? {
        get { _lock.withLock { _name } }
        set { _lock.withLock { _name = newValue } }
    }

    open var queuePriority: QueuePriority {
        get { _lock.withLock { _queuePriority } }
        set { _lock.withLock { _queuePriority = newValue } }
    }

    open var qualityOfService: QualityOfService {
        get { _lock.withLock { _qualityOfService } }
        set { _lock.withLock { _qualityOfService = newValue } }
    }

    open var completionBlock: (@Sendable () -> Void)? {
        get { _lock.withLock { _completionBlock } }
        set { _lock.withLock { _completionBlock = newValue } }
    }

    open var dependencies: [Operation] { _lock.withLock { _dependencies } }

    open func addDependency(_ op: Operation) {
        _lock.withLock {
            if !_dependencies.contains(where: { $0 === op }) { _dependencies.append(op) }
        }
    }

    open func removeDependency(_ op: Operation) {
        _lock.withLock { _dependencies.removeAll { $0 === op } }
        _OperationQueueState.scheduleAll()
    }

    open func cancel() {
        _lock.withLock { _cancelled = true }
        // A cancelled operation is ready regardless of its dependencies.
        _OperationQueueState.scheduleAll()
    }

    // MARK: running

    open func main() {}

    /// Runs `main()` synchronously on the calling thread, as NSOperation's
    /// default start does; a cancelled operation finishes without running it.
    open func start() {
        let proceed = _lock.withLock { () -> Bool in
            precondition(!_started || _cancelled,
                         "*** -[NSOperation start]: receiver has already started")
            _started = true
            if _cancelled { return false }
            _executing = true
            return true
        }
        if proceed { main() }
        _lock.withLock { _executing = false }
        _markFinished()
    }

    fileprivate func _markFinished() {
        let (block, waiters) = _lock.withLock { () -> ((@Sendable () -> Void)?, [DispatchSemaphore]) in
            guard !_finished else { return (nil, []) }
            _finished = true
            let saved = (_completionBlock, _waiters)
            _waiters = []
            return saved
        }
        // Leave the queue before waking waiters: a waiter that then reads
        // operationCount must not still see this operation (measured 0).
        _OperationQueueState.operationDidFinish(self)
        if let block { DispatchQueue.global().async(execute: block) }
        for waiter in waiters { waiter.signal() }
    }

    open func waitUntilFinished() {
        let waiter = _lock.withLock { () -> DispatchSemaphore? in
            if _finished { return nil }
            let semaphore = DispatchSemaphore(value: 0)
            _waiters.append(semaphore)
            return semaphore
        }
        waiter?.wait()
    }

    // MARK: key-value notifications from asynchronous subclasses

    open func willChangeValue(forKey key: String) {}

    /// An asynchronous subclass reports completion with
    /// `didChangeValue(forKey: "isFinished")` after its overridden isFinished
    /// turns true.
    open func didChangeValue(forKey key: String) {
        switch key {
        case "isFinished", "finished":
            // Dynamic dispatch: an asynchronous subclass's own isFinished.
            if isFinished { _markFinished() }
        case "isReady", "ready":
            _OperationQueueState.scheduleAll()
        default:
            break
        }
    }
}

open class BlockOperation: Operation, @unchecked Sendable {
    private var _blocks: [@Sendable () -> Void] = []

    public override init() {
        super.init()
    }

    public convenience init(block: @escaping @Sendable () -> Void) {
        self.init()
        _blocks = [block]
    }

    open func addExecutionBlock(_ block: @escaping @Sendable () -> Void) {
        _lock.withLock {
            precondition(!isExecuting && !isFinished,
                         "*** -[NSBlockOperation addExecutionBlock:]: blocks cannot be added after the operation has started executing or finished")
            _blocks.append(block)
        }
    }

    open var executionBlocks: [@Sendable () -> Void] { _lock.withLock { _blocks } }

    open override func main() {
        let blocks = _lock.withLock { _blocks }
        guard let first = blocks.first else { return }
        if blocks.count == 1 { first(); return }
        // NSBlockOperation runs its blocks concurrently and finishes after all.
        let group = DispatchGroup()
        for block in blocks.dropFirst() {
            group.enter()
            DispatchQueue.global().async {
                block()
                group.leave()
            }
        }
        first()
        group.wait()
    }
}

// MARK: - OperationQueue scheduling

final class _OperationQueueState: @unchecked Sendable {
    private static let registryLock = NSLock()
    nonisolated(unsafe) private static var registry: [ObjectIdentifier: _OperationQueueState] = [:]

    weak var queue: OperationQueue?
    let isMain: Bool
    let lock = NSRecursiveLock()
    var pending: [Operation] = []
    var running: [Operation] = []
    var maxConcurrent = OperationQueue.defaultMaxConcurrentOperationCount
    var suspended = false
    var qualityOfService: QualityOfService = .default
    var underlying: DispatchQueue?
    var nextOrder = 0

    private init(queue: OperationQueue, isMain: Bool) {
        self.queue = queue
        self.isMain = isMain
        if isMain { maxConcurrent = 1 }
    }

    static func of(_ queue: OperationQueue) -> _OperationQueueState {
        registryLock.withLock {
            let key = ObjectIdentifier(queue)
            if let state = registry[key], state.queue === queue { return state }
            let state = _OperationQueueState(queue: queue, isMain: queue === OperationQueue.main)
            registry[key] = state
            return state
        }
    }

    static func scheduleAll() {
        let states = registryLock.withLock { Array(registry.values) }
        for state in states { state.schedule() }
    }

    static func operationDidFinish(_ op: Operation) {
        let queues = op._lock.withLock { op._queues }
        for state in queues {
            state.lock.withLock { state.running.removeAll { $0 === op } }
        }
        scheduleAll()
    }

    func add(_ op: Operation) {
        op._lock.withLock {
            precondition(!op.isExecuting && !op.isFinished && op._queues.isEmpty,
                         "*** -[NSOperationQueue addOperation:]: operation is finished, is executing or is already enqueued")
            op._queues.append(self)
        }
        lock.withLock {
            op._enqueueOrder = nextOrder
            nextOrder += 1
            pending.append(op)
        }
        schedule()
    }

    func schedule() {
        var launch: [Operation] = []
        lock.withLock {
            guard !suspended else { return }
            while maxConcurrent < 0 || running.count + launch.count < maxConcurrent {
                let ready = pending.filter { $0.isCancelled || $0.isReady }
                guard let next = ready.max(by: {
                    ($0.queuePriority.rawValue, -$0._enqueueOrder) < ($1.queuePriority.rawValue, -$1._enqueueOrder)
                }) else { break }
                pending.removeAll { $0 === next }
                running.append(next)
                launch.append(next)
            }
        }
        for op in launch {
            let target = underlying ?? (isMain ? DispatchQueue.main : DispatchQueue.global())
            target.async {
                op.start()
            }
        }
    }

    var operations: [Operation] { lock.withLock { running + pending } }
}

public extension OperationQueue {
    static let defaultMaxConcurrentOperationCount = -1

    func addOperation(_ op: Operation) {
        _OperationQueueState.of(self).add(op)
    }

    func addOperation(_ block: @escaping @Sendable () -> Void) {
        addOperation(BlockOperation(block: block))
    }

    func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        for op in ops { addOperation(op) }
        if wait { for op in ops { op.waitUntilFinished() } }
    }

    /// Runs after every operation enqueued before it, and before any enqueued after.
    func addBarrierBlock(_ barrier: @escaping @Sendable () -> Void) {
        let op = BlockOperation(block: barrier)
        for earlier in operations { op.addDependency(earlier) }
        addOperation(op)
    }

    var operations: [Operation] { _OperationQueueState.of(self).operations }
    var operationCount: Int { operations.count }

    var maxConcurrentOperationCount: Int {
        get { let s = _OperationQueueState.of(self); return s.lock.withLock { s.maxConcurrent } }
        set {
            let s = _OperationQueueState.of(self)
            s.lock.withLock { s.maxConcurrent = newValue }
            s.schedule()
        }
    }

    var isSuspended: Bool {
        get { let s = _OperationQueueState.of(self); return s.lock.withLock { s.suspended } }
        set {
            let s = _OperationQueueState.of(self)
            s.lock.withLock { s.suspended = newValue }
            s.schedule()
        }
    }

    var qualityOfService: QualityOfService {
        get { let s = _OperationQueueState.of(self); return s.lock.withLock { s.qualityOfService } }
        set { let s = _OperationQueueState.of(self); s.lock.withLock { s.qualityOfService = newValue } }
    }

    var underlyingQueue: DispatchQueue? {
        get {
            let s = _OperationQueueState.of(self)
            return s.isMain ? DispatchQueue.main : s.lock.withLock { s.underlying }
        }
        set { let s = _OperationQueueState.of(self); s.lock.withLock { s.underlying = newValue } }
    }

    func cancelAllOperations() {
        for op in operations { op.cancel() }
    }

    func waitUntilAllOperationsAreFinished() {
        for op in operations { op.waitUntilFinished() }
    }
}
