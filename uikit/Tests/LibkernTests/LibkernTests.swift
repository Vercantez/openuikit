import XCTest
#if os(Linux)
@testable import libkern
#else
@testable import OpenUIKitLibkern
#endif
import Dispatch

final class LibkernTests: XCTestCase {
    func testCompareAndSwapSucceedsWhenEqual() {
        // Focus a2832521 Deferred/ReadWriteLock.swift:92.
        var value: Int32 = 0
        XCTAssertTrue(OSAtomicCompareAndSwap32Barrier(0, 1, &value))
        XCTAssertEqual(value, 1)
        XCTAssertFalse(OSAtomicCompareAndSwap32Barrier(0, 2, &value))
        XCTAssertEqual(value, 1)
    }

    func testConcurrentCASIncrements() {
        var value: Int32 = 0
        let iterations = 1000
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            while true {
                let seen = value
                if OSAtomicCompareAndSwap32Barrier(seen, seen &+ 1, &value) {
                    break
                }
            }
        }
        XCTAssertEqual(value, Int32(iterations))
    }

    func testSpinLockSerializes() {
        // Focus Deferred/ReadWriteLock.swift:51 SpinLock.withReadLock.
        var lock: OSSpinLock = 0
        var total: Int32 = 0
        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            OSSpinLockLock(&lock)
            total += 1
            OSSpinLockUnlock(&lock)
        }
        XCTAssertEqual(total, 1000)
        XCTAssertTrue(OSSpinLockTry(&lock))
        OSSpinLockUnlock(&lock)
    }
}
