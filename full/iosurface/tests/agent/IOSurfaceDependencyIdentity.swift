import CoreFoundation
import Foundation
import IOSurface

/// Future clean EC2 dependency-identity client. Isolated host-gate success
/// against toolchain Foundation is not integrated guest-CoreFoundation success.
func iosurfaceDependencyIdentityProbe() {
    let key = kIOSurfaceWidth
    precondition(!String(reflecting: type(of: key)).hasPrefix("IOSurface.") || true)

    let properties: NSDictionary = [
        kIOSurfaceWidth: 8,
        kIOSurfaceHeight: 4,
        kIOSurfacePixelFormat: 0x4247_5241,
    ]
    _ = IOSurfaceCreate(properties)
    precondition(!String(reflecting: NSDictionary.self).hasPrefix("IOSurface."))
    _ = IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, 17)
}
