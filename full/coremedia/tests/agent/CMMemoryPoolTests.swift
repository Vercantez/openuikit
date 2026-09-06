import CoreFoundation
import CoreMedia
import Foundation

func testCMMemoryPoolCreateFlushInvalidate() {
    var seconds: Double = 1.5
    let number = CFNumberCreate(kCFAllocatorDefault, .doubleType, &seconds)!
    var keyCB = kCFTypeDictionaryKeyCallBacks
    var valCB = kCFTypeDictionaryValueCallBacks
    let options = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &keyCB, &valCB)!
    CFDictionarySetValue(
        options,
        unsafeBitCast(kCMMemoryPoolOption_AgeOutPeriod, to: UnsafeRawPointer.self),
        unsafeBitCast(number, to: UnsafeRawPointer.self)
    )
    let pool = CMMemoryPoolCreate(options: options)
    precondition(CMMemoryPoolGetTypeID() == CMMemoryPool.typeID)
    precondition(CMMemoryPoolGetTypeID() != 0)
    let allocator = CMMemoryPoolGetAllocator(pool)
    precondition(allocator === kCFAllocatorDefault)
    CMMemoryPoolFlush(pool)
    CMMemoryPoolInvalidate(pool)
    precondition(CMMemoryPoolGetAllocator(pool) === kCFAllocatorDefault)
    precondition(kCMMemoryPoolError_AllocationFailed == -12780)
    precondition(kCMMemoryPoolError_InvalidParameter == -12781)
    precondition(CFEqual(kCMMemoryPoolOption_AgeOutPeriod, cmMemoryPoolAgeOutKey()))
    let other = CMMemoryPoolCreate(options: nil)
    precondition(pool != other)
    precondition(pool == pool)
}

private func cmMemoryPoolAgeOutKey() -> CFString {
    "AgeOutPeriod".withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}
