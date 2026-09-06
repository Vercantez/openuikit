import CoreFoundation
import Foundation

/// Linux starting implementation of Apple's public ColorSync module.
///
/// Real: ICC.1 profile parse/serialize, named matrix RGB/gray/Lab/XYZ
/// profiles, tag mutation, ICC Profile ID MD5, and 8-bit RGB matrix
/// transforms. Fail-closed: Apple CMM code fragments, display-device
/// profiles, and non-8-bit convert depths.

public var COLORSYNC_API_VERSION: Int { 0x10000000 }
public var icVersion4Number: Int { 0x04000000 }
public var icVersion4Point4Number: Int { 0x04400000 }

public func ColorSyncAPIVersion() -> UInt32 {
    UInt32(bitPattern: Int32(truncatingIfNeeded: COLORSYNC_API_VERSION))
}
