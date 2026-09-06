import Foundation
import IOSurface

func testPurgeableKeepCurrent() {
    let surface = iosurfaceMakeBGRA(2, 2)
    var old = IOSurfacePurgeabilityState.purgeableEmpty
    precondition(surface.setPurgeable(.purgeableVolatile, oldState: &old) == kIOSurfaceSuccess)
    precondition(old == [])
    var again = IOSurfacePurgeabilityState()
    precondition(surface.setPurgeable(.purgeableKeepCurrent, oldState: &again) == kIOSurfaceSuccess)
    precondition(again == .purgeableVolatile)
}

func testPurgeableEmptyZeros() {
    let surface = iosurfaceMakeBGRA(2, 1)
    _ = surface.lock(options: [], seed: nil)
    surface.baseAddress.storeBytes(of: UInt32(0x1111_1111), as: UInt32.self)
    _ = surface.unlock(options: [], seed: nil)
    var old = IOSurfacePurgeabilityState()
    precondition(surface.setPurgeable(.purgeableEmpty, oldState: &old) == kIOSurfaceSuccess)
    precondition(surface.baseAddress.load(as: UInt32.self) == 0)
}

func testPurgeableVolatile() {
    let surface = iosurfaceMakeBGRA(2, 1)
    precondition(surface.setPurgeable(.purgeableVolatile, oldState: nil) == kIOSurfaceSuccess)
}

func testCPurgeableAPI() {
    let surface = iosurfaceMakeBGRA(2, 1)
    var old: UInt32 = 99
    precondition(
        IOSurfaceSetPurgeable(surface, IOSurfacePurgeabilityState.purgeableVolatile.rawValue, &old)
            == kIOSurfaceSuccess
    )
    precondition(old == 0)
    precondition(
        IOSurfaceSetPurgeable(surface, IOSurfacePurgeabilityState.purgeableKeepCurrent.rawValue, &old)
            == kIOSurfaceSuccess
    )
    precondition(old == IOSurfacePurgeabilityState.purgeableVolatile.rawValue)
}
