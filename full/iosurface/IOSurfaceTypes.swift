import Foundation

/// Pixel-component channel names. Raw values match IOSurfaceTypes.h.
public enum IOSurfaceComponentName: Int32, Hashable, Sendable {
    case unknown = 0
    case alpha = 1
    case red = 2
    case green = 3
    case blue = 4
    case luma = 5
    case chromaRed = 6
    case chromaBlue = 7
}

/// Numeric encoding of a plane component. Raw values match IOSurfaceTypes.h.
public enum IOSurfaceComponentType: Int32, Hashable, Sendable {
    case unknown = 0
    case unsignedInteger = 1
    case signedInteger = 2
    case float = 3
    case signedNormalized = 4
}

/// Sample range of a plane component. Raw values match IOSurfaceTypes.h.
public enum IOSurfaceComponentRange: Int32, Hashable, Sendable {
    case unknown = 0
    case fullRange = 1
    case videoRange = 2
    case wideRange = 3
}

/// Chroma subsampling. Raw values match IOSurfaceTypes.h.
public enum IOSurfaceSubsampling: Int32, Hashable, Sendable {
    case subsamplingUnknown = 0
    case subsamplingNone = 1
    case subsampling422 = 2
    case subsampling420 = 3
    case subsampling411 = 4
}

/// Ledger tags for IOSurfaceSetOwnershipIdentity. Raw values match IOSurfaceTypes.h.
public enum IOSurfaceMemoryLedgerTags: Int32, Hashable, Sendable {
    case `default` = 0x0000_0001
    case network = 0x0000_0002
    case media = 0x0000_0003
    case graphics = 0x0000_0004
    case neural = 0x0000_0005
}

/// Lock flags. `readOnly` skips the seed bump on unlock; `avoidSync` is a
/// no-op on Linux (there is no GPU command stream to wait for).
public struct IOSurfaceLockOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let readOnly = IOSurfaceLockOptions(rawValue: 0x0000_0001)
    public static let avoidSync = IOSurfaceLockOptions(rawValue: 0x0000_0002)
}

/// Ledger option flags. Ownership APIs that consume these remain fail-closed.
public struct IOSurfaceMemoryLedgerFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let noFootprint = IOSurfaceMemoryLedgerFlags(rawValue: 1 << 0)
}

/// Purgeability state machine. `keepCurrent` is query-only.
public struct IOSurfacePurgeabilityState: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let purgeableVolatile = IOSurfacePurgeabilityState(rawValue: 1)
    public static let purgeableEmpty = IOSurfacePurgeabilityState(rawValue: 2)
    public static let purgeableKeepCurrent = IOSurfacePurgeabilityState(rawValue: 3)
}

public typealias IOSurfaceID = UInt32

/// CPU cache modes from IOSurfaceTypes.h (`kIOSurfaceDefaultCache` family).
public var kIOSurfaceDefaultCache: Int { 0 }
public var kIOSurfaceInhibitCache: Int { 1 }
public var kIOSurfaceWriteThruCache: Int { 2 }
public var kIOSurfaceCopybackCache: Int { 3 }
public var kIOSurfaceWriteCombineCache: Int { 4 }
public var kIOSurfaceCopybackInnerCache: Int { 5 }

public var kIOSurfaceMapCacheShift: Int { 8 }
public var kIOSurfaceMapDefaultCache: Int { kIOSurfaceDefaultCache << kIOSurfaceMapCacheShift }
public var kIOSurfaceMapInhibitCache: Int { kIOSurfaceInhibitCache << kIOSurfaceMapCacheShift }
public var kIOSurfaceMapWriteThruCache: Int { kIOSurfaceWriteThruCache << kIOSurfaceMapCacheShift }
public var kIOSurfaceMapCopybackCache: Int { kIOSurfaceCopybackCache << kIOSurfaceMapCacheShift }
public var kIOSurfaceMapWriteCombineCache: Int { kIOSurfaceWriteCombineCache << kIOSurfaceMapCacheShift }
public var kIOSurfaceMapCopybackInnerCache: Int { kIOSurfaceCopybackInnerCache << kIOSurfaceMapCacheShift }

/// `KERN_SUCCESS`. IOSurface lock / purgeable APIs return this on Linux.
public var kIOSurfaceSuccess: Int32 { iosurfaceKERNSuccess }
