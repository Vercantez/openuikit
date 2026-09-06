// libkern atomics used by mozilla-mobile/focus-ios a2832521 vendored
// Deferred/ReadWriteLock.swift: OSAtomicCompareAndSwap32Barrier (5 calls),
// OSSpinLockLock/Unlock (2 each), OS_SPINLOCK_INIT.
//
// Darwin Foundation re-exports Darwin.libkern; Linux corelibs and the guest
// do not. A global mutex makes CAS / spinlock atomic (correct, not lock-free).
// 1000 concurrent successful CASes end at 1000 (LibkernTests).

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

public typealias OSSpinLock = Int32
public let OS_SPINLOCK_INIT: OSSpinLock = 0

private let _osatomicMutex: UnsafeMutablePointer<pthread_mutex_t> = {
    let pointer = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    pthread_mutex_init(pointer, nil)
    return pointer
}()

private func _withOSAtomicLock<T>(_ body: () -> T) -> T {
    pthread_mutex_lock(_osatomicMutex)
    defer { pthread_mutex_unlock(_osatomicMutex) }
    return body()
}

public func OSAtomicCompareAndSwap32Barrier(
    _ oldValue: Int32,
    _ newValue: Int32,
    _ theValue: UnsafeMutablePointer<Int32>
) -> Bool {
    _withOSAtomicLock {
        if theValue.pointee == oldValue {
            theValue.pointee = newValue
            return true
        }
        return false
    }
}

public func OSAtomicCompareAndSwap32(
    _ oldValue: Int32,
    _ newValue: Int32,
    _ theValue: UnsafeMutablePointer<Int32>
) -> Bool {
    OSAtomicCompareAndSwap32Barrier(oldValue, newValue, theValue)
}

public func OSSpinLockLock(_ lock: UnsafeMutablePointer<OSSpinLock>) {
    while !OSAtomicCompareAndSwap32Barrier(0, 1, lock) {
        // spin
    }
}

public func OSSpinLockUnlock(_ lock: UnsafeMutablePointer<OSSpinLock>) {
    _withOSAtomicLock { lock.pointee = 0 }
}

public func OSSpinLockTry(_ lock: UnsafeMutablePointer<OSSpinLock>) -> Bool {
    OSAtomicCompareAndSwap32Barrier(0, 1, lock)
}
