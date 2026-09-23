// Foundation.Thread (NSThread) and the pthread-backed locks next to it, for
// the Linux-hosted Mach-O guest. The guest's libSystem (machorun) runs every
// guest pthread on a real host thread and records the process's first thread
// at bootstrap, so pthread_main_np() is exact (machorun darwin/src/posix.c).
//
// Contract measured on the iOS 26.1 simulator by
// uikit/Tools/oracle2/guestfoundationprobe (transcript-ios26.1.txt), which the
// guest runs unchanged (uikit/Tools/guestprobes/GuestFoundationProbe.probe.sh):
//   - Thread.main is Thread.current on the main thread and is executing;
//     its name is "" (not nil); every other Thread starts with name nil,
//     stackSize 524288, threadPriority 0.5, qualityOfService .default (-1);
//     once started (and for adopted threads) a nil name reads "".
//   - A thread cancelled before start() finishes without running its body.
//   - Thread.current is one stable object per thread, including threads the
//     program did not create (dispatch workers), and never Thread.main off
//     the main thread.
//   - threadDictionary is one mutable dictionary per thread.
//   - isExecuting is true inside the body; isFinished flips after it returns;
//     cancel() only sets isCancelled.
//   - Thread.sleep(until:) with a past date returns at once.
// Not provided: run loops per thread (RunLoop is OpenUIKit's main-loop
// model), thread priorities/QoS applied to the host scheduler (stored only),
// and NSThread notifications.

#if canImport(Darwin)
import Darwin
#endif
import FoundationEssentials
import ObjectiveC

/// NSQualityOfService.
public enum QualityOfService: Int, @unchecked Sendable {
    case userInteractive = 0x21
    case userInitiated = 0x19
    case utility = 0x11
    case background = 0x09
    case `default` = -1
}

private enum _ThreadStatus {
    case initialized, executing, finished
}

// Not Sendable: NSThread is not NS_SWIFT_SENDABLE in the iOS 26.1 SDK.
open class Thread: NSObject {
    // One Thread per pthread, retained by the thread's TSD slot and released
    // by the key's destructor when the pthread exits.
    private static let _key: pthread_key_t = {
        var key = pthread_key_t()
        let rc = pthread_key_create(&key) { raw in
            Unmanaged<Thread>.fromOpaque(UnsafeRawPointer(raw)).release()
        }
        precondition(rc == 0, "Thread: pthread_key_create failed (\(rc))")
        return key
    }()

    private static let _mainThread = Thread(_existing: true)

    // An NSLock, not Synchronization.Atomic: build_full pins the facade's
    // Synchronization imports (EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS).
    private static let _multiThreadedLock = NSLock()
    nonisolated(unsafe) private static var _multiThreaded = false

    private let _lock = NSLock()
    private var _status: _ThreadStatus = .initialized
    private var _cancelled = false
    private var _name: String?
    private var _stackSize = 1 << 19
    private var _qualityOfService: QualityOfService = .default
    private var _threadPriority = 0.5
    private var _dictionary: NSMutableDictionary?
    private var _block: (@Sendable () -> Void)?
    private var _target: AnyObject?
    private var _selector: Selector?
    private var _argument: Any?
    private let _isMain: Bool

    /// A Thread object for a thread that is already running (the main thread,
    /// or a thread the program did not start through Thread).
    private init(_existing isMain: Bool) {
        _isMain = isMain
        super.init()
        _status = .executing
        _name = ""
    }

    public override init() {
        _isMain = false
        super.init()
    }

    public convenience init(block: @escaping @Sendable () -> Void) {
        self.init()
        _block = block
    }

    public convenience init(target: Any, selector: Selector, object argument: Any?) {
        self.init()
        _target = target as AnyObject
        _selector = selector
        _argument = argument
    }

    // MARK: identity

    open class var current: Thread {
        if pthread_main_np() != 0 { return _mainThread }
        if let raw = pthread_getspecific(_key) {
            return Unmanaged<Thread>.fromOpaque(UnsafeRawPointer(raw)).takeUnretainedValue()
        }
        let adopted = Thread(_existing: false)
        adopted._adoptCurrentPthread()
        return adopted
    }

    open class var main: Thread { _mainThread }

    open class var isMainThread: Bool { pthread_main_np() != 0 }

    open var isMainThread: Bool { _isMain }

    open class func isMultiThreaded() -> Bool {
        _multiThreadedLock.withLock { _multiThreaded }
    }

    private func _adoptCurrentPthread() {
        let raw = Unmanaged.passRetained(self).toOpaque()
        let rc = pthread_setspecific(Thread._key, raw)
        precondition(rc == 0, "Thread: pthread_setspecific failed (\(rc))")
    }

    // MARK: state

    open var name: String? {
        get { _lock.withLock { _name } }
        set { _lock.withLock { _name = newValue } }
    }

    open var stackSize: Int {
        get { _lock.withLock { _stackSize } }
        set { _lock.withLock { _stackSize = newValue } }
    }

    open var qualityOfService: QualityOfService {
        get { _lock.withLock { _qualityOfService } }
        set { _lock.withLock { _qualityOfService = newValue } }
    }

    open var threadPriority: Double {
        get { _lock.withLock { _threadPriority } }
        set { _lock.withLock { _threadPriority = newValue } }
    }

    open class func threadPriority() -> Double { current.threadPriority }

    open class func setThreadPriority(_ p: Double) -> Bool {
        current.threadPriority = p
        return true
    }

    open var isExecuting: Bool { _lock.withLock { _status == .executing } }
    open var isFinished: Bool { _lock.withLock { _status == .finished } }
    open var isCancelled: Bool { _lock.withLock { _cancelled } }

    open func cancel() {
        _lock.withLock { _cancelled = true }
    }

    open var threadDictionary: NSMutableDictionary {
        _lock.withLock {
            if let dictionary = _dictionary { return dictionary }
            let dictionary = NSMutableDictionary()
            _dictionary = dictionary
            return dictionary
        }
    }

    // MARK: running

    /// The body a started thread runs. Subclasses override it; the default
    /// runs the block or sends the selector to the target.
    open func main() {
        let (block, target, selector, argument) = _lock.withLock {
            (_block, _target, _selector, _argument)
        }
        if let block {
            block()
        } else if let target, let selector {
            _ = target.perform(selector, with: argument)
        }
    }

    open func start() {
        let stackSize = _lock.withLock { () -> Int? in
            precondition(_status == .initialized && !_isMain,
                         "*** -[NSThread start]: attempt to start the thread again")
            // Measured: a thread cancelled before start finishes without
            // running its body; a started thread's nil name reads "".
            if _name == nil { _name = "" }
            if _cancelled {
                _status = .finished
                return nil
            }
            _status = .executing
            return _stackSize
        }
        guard let stackSize else { return }
        Thread._multiThreadedLock.withLock { Thread._multiThreaded = true }
        var attributes = pthread_attr_t()
        pthread_attr_init(&attributes)
        defer { pthread_attr_destroy(&attributes) }
        pthread_attr_setdetachstate(&attributes, PTHREAD_CREATE_DETACHED)
        if stackSize > 0 {
            _ = pthread_attr_setstacksize(&attributes, stackSize)
        }
        let context = Unmanaged.passRetained(self).toOpaque()
        var handle: pthread_t?
        let rc = pthread_create(&handle, &attributes, { raw in
            let thread = Unmanaged<Thread>.fromOpaque(UnsafeRawPointer(raw)).takeUnretainedValue()
            // The TSD slot now owns the +1 passed to pthread_create.
            let rc = pthread_setspecific(Thread._key, raw)
            precondition(rc == 0, "Thread: pthread_setspecific failed (\(rc))")
            thread.main()
            thread._lock.withLock {
                thread._status = .finished
                thread._block = nil
                thread._target = nil
                thread._argument = nil
            }
            return nil
        }, context)
        if rc != 0 {
            Unmanaged<Thread>.fromOpaque(context).release()
            _lock.withLock { _status = .initialized }
            preconditionFailure("*** -[NSThread start]: pthread_create failed (\(rc))")
        }
    }

    open class func detachNewThread(_ block: @escaping @Sendable () -> Void) {
        Thread(block: block).start()
    }

    open class func detachNewThreadSelector(
        _ selector: Selector, toTarget target: Any, with argument: Any?
    ) {
        Thread(target: target, selector: selector, object: argument).start()
    }

    // MARK: sleeping and exiting

    open class func sleep(until date: Date) {
        var remaining = date.timeIntervalSinceNow
        while remaining > 0 {
            _sleep(remaining)
            remaining = date.timeIntervalSinceNow
        }
    }

    open class func sleep(forTimeInterval interval: TimeInterval) {
        guard interval > 0 else { return }
        sleep(until: Date(timeIntervalSinceNow: interval))
    }

    private static func _sleep(_ interval: TimeInterval) {
        let clamped = min(interval, TimeInterval(Int32.max))
        var request = timespec(tv_sec: Int(clamped),
                               tv_nsec: Int((clamped - clamped.rounded(.down)) * 1_000_000_000))
        var left = timespec()
        while nanosleep(&request, &left) != 0 && errno == EINTR {
            request = left
        }
    }

    open class func exit() {
        let thread = current
        thread._lock.withLock { thread._status = .finished }
        pthread_exit(nil)
    }

    // MARK: call stacks

    open class var callStackReturnAddresses: [NSNumber] {
        _callStack().addresses.map { NSNumber(value: UInt(bitPattern: $0)) }
    }

    open class var callStackSymbols: [String] {
        _callStack().symbols
    }

    private static func _callStack() -> (addresses: [Int], symbols: [String]) {
        var frames = [UnsafeMutableRawPointer?](repeating: nil, count: 128)
        let count = Int(backtrace(&frames, Int32(frames.count)))
        guard count > 0 else { return ([], []) }
        var symbols: [String] = []
        if let names = backtrace_symbols(&frames, Int32(count)) {
            for index in 0..<count {
                symbols.append(names[index].map { String(cString: $0) } ?? "")
            }
            free(names)
        }
        let addresses = frames[0..<count].map { Int(bitPattern: $0) }
        return (addresses, symbols)
    }
}

/// NSRecursiveLock: a pthread recursive mutex.
open class NSRecursiveLock: NSObject, NSLocking, @unchecked Sendable {
    private let _mutex: UnsafeMutablePointer<pthread_mutex_t>
    open var name: String?

    public override init() {
        _mutex = .allocate(capacity: 1)
        _mutex.initialize(to: pthread_mutex_t())
        var attributes = pthread_mutexattr_t()
        pthread_mutexattr_init(&attributes)
        pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(_mutex, &attributes)
        pthread_mutexattr_destroy(&attributes)
        super.init()
    }

    deinit {
        pthread_mutex_destroy(_mutex)
        _mutex.deinitialize(count: 1)
        _mutex.deallocate()
    }

    open func lock() { pthread_mutex_lock(_mutex) }
    open func unlock() { pthread_mutex_unlock(_mutex) }
    open func `try`() -> Bool { pthread_mutex_trylock(_mutex) == 0 }

    open func lock(before limit: Date) -> Bool {
        repeat {
            if self.try() { return true }
            sched_yield()
        } while Date() < limit
        return false
    }
}

/// NSCondition: a mutex and its condition variable.
open class NSCondition: NSObject, NSLocking, @unchecked Sendable {
    private let _mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let _cond: UnsafeMutablePointer<pthread_cond_t>
    open var name: String?

    public override init() {
        _mutex = .allocate(capacity: 1)
        _mutex.initialize(to: pthread_mutex_t())
        pthread_mutex_init(_mutex, nil)
        _cond = .allocate(capacity: 1)
        _cond.initialize(to: pthread_cond_t())
        pthread_cond_init(_cond, nil)
        super.init()
    }

    deinit {
        pthread_cond_destroy(_cond)
        pthread_mutex_destroy(_mutex)
        _cond.deinitialize(count: 1)
        _cond.deallocate()
        _mutex.deinitialize(count: 1)
        _mutex.deallocate()
    }

    open func lock() { pthread_mutex_lock(_mutex) }
    open func unlock() { pthread_mutex_unlock(_mutex) }
    open func wait() { pthread_cond_wait(_cond, _mutex) }

    open func wait(until limit: Date) -> Bool {
        let seconds = limit.timeIntervalSince1970
        guard seconds > 0 else { return false }
        var deadline = timespec(tv_sec: Int(seconds),
                                tv_nsec: Int((seconds - seconds.rounded(.down)) * 1_000_000_000))
        return pthread_cond_timedwait(_cond, _mutex, &deadline) == 0
    }

    open func signal() { pthread_cond_signal(_cond) }
    open func broadcast() { pthread_cond_broadcast(_cond) }
}

/// NSConditionLock: a lock that can be taken only when its condition matches.
open class NSConditionLock: NSObject, NSLocking, @unchecked Sendable {
    private let _cond = NSCondition()
    private var _value: Int
    private var _owner: pthread_t?
    open var name: String?

    public convenience override init() { self.init(condition: 0) }

    public init(condition: Int) {
        _value = condition
        super.init()
    }

    open var condition: Int { _value }

    open func lock() { _ = lock(before: .distantFuture) }

    open func unlock() {
        _cond.lock()
        _owner = nil
        _cond.broadcast()
        _cond.unlock()
    }

    open func lock(whenCondition condition: Int) {
        _ = lock(whenCondition: condition, before: .distantFuture)
    }

    open func `try`() -> Bool { lock(before: Date(timeIntervalSinceNow: 0)) }

    open func tryLock(whenCondition condition: Int) -> Bool {
        lock(whenCondition: condition, before: Date(timeIntervalSinceNow: 0))
    }

    open func unlock(withCondition condition: Int) {
        _cond.lock()
        _owner = nil
        _value = condition
        _cond.broadcast()
        _cond.unlock()
    }

    open func lock(before limit: Date) -> Bool {
        _cond.lock()
        while _owner != nil {
            if !_cond.wait(until: limit) { _cond.unlock(); return false }
        }
        _owner = pthread_self()
        _cond.unlock()
        return true
    }

    open func lock(whenCondition condition: Int, before limit: Date) -> Bool {
        _cond.lock()
        while _owner != nil || _value != condition {
            if !_cond.wait(until: limit) { _cond.unlock(); return false }
        }
        _owner = pthread_self()
        _cond.unlock()
        return true
    }
}
