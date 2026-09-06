import CoreFoundation
import Foundation

/// Linux `CMMemoryPool` is a thin wrapper around `CFAllocatorGetDefault()`.
/// `kCFAllocatorDefault` is a NULL synonym on this CoreFoundation and cannot
/// be returned as a non-optional `CFAllocator`. Blocks are not cached: `Flush`
/// is a documented no-op because there is no aged-out slab to recycle.
/// `AgeOutPeriod` is stored at create time but does not change allocation.
/// After `Invalidate`, `GetAllocator` still returns the process default
/// allocator; callers must not assume Apple's unique-pool allocator.

public final class CMMemoryPool: Hashable, @unchecked Sendable {
    private static let processTypeID: CFTypeID = 0x434D_4D50
    public static var typeID: CFTypeID { processTypeID }

    fileprivate let lock = CMUnfairLock()
    fileprivate var valid = true
    fileprivate var ageOutPeriod: CFTimeInterval = 0

    public init(options: CFDictionary? = nil) {
        if let options {
            if let raw = cmCFDictionaryValue(options, key: kCMMemoryPoolOption_AgeOutPeriod) {
                var seconds: Double = 0
                if CFNumberGetValue(unsafeBitCast(raw, to: CFNumber.self), .doubleType, &seconds) {
                    self.ageOutPeriod = seconds
                }
            }
        }
    }

    public static func == (lhs: CMMemoryPool, rhs: CMMemoryPool) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// Graph and API digester omit the integers. Values follow the public
/// `CMMemoryPool.h` enumeration immediately after `CMSimpleQueue` (-12773).
public var kCMMemoryPoolError_AllocationFailed: OSStatus { -12780 }
public var kCMMemoryPoolError_InvalidParameter: OSStatus { -12781 }

public func CMMemoryPoolGetTypeID() -> CFTypeID {
    CMMemoryPool.typeID
}

public func CMMemoryPoolCreate(options: CFDictionary?) -> CMMemoryPool {
    CMMemoryPool(options: options)
}

public func CMMemoryPoolGetAllocator(_ pool: CMMemoryPool) -> CFAllocator {
    _ = pool
    if let allocator = kCFAllocatorDefault {
        return allocator
    }
    if let allocator = kCFAllocatorSystemDefault {
        return allocator
    }
    return CFAllocatorGetDefault()!.takeUnretainedValue()
}

public func CMMemoryPoolFlush(_ pool: CMMemoryPool) {
    _ = pool.lock.locked { pool.valid && pool.ageOutPeriod >= 0 }
}

public func CMMemoryPoolInvalidate(_ pool: CMMemoryPool) {
    pool.lock.locked { pool.valid = false }
}
