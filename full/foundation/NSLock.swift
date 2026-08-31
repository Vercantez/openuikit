// Foundation locking primitives backed by the Darwin/libSystem unfair-lock
// implementation already shipped in the guest runtime.

import FoundationEssentials
import os

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation.NSLock requires the ObjectiveC NSObject substrate")
#endif

public protocol NSLocking: AnyObject {
    func lock()
    func unlock()
}

public final class NSLock: NSObject, NSLocking, @unchecked Sendable {
    private var storage = os_unfair_lock()

    public var name: String?

    public override init() {
        name = nil
        super.init()
    }

    public func lock() {
        os_unfair_lock_lock(&storage)
    }

    public func unlock() {
        os_unfair_lock_unlock(&storage)
    }

    public func `try`() -> Bool {
        os_unfair_lock_trylock(&storage)
    }

    public func lock(before limit: Date) -> Bool {
        repeat {
            if self.try() {
                return true
            }
            sched_yield()
        } while Date() < limit
        return false
    }
}

public extension NSLocking {
    func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
        lock()
        defer { unlock() }
        return try body()
    }
}
