import Foundation
import IOSurface

func testLockUnlockSeed() {
    let surface = iosurfaceMakeBGRA(4, 2)
    let before = IOSurfaceGetSeed(surface)
    var seed: UInt32 = 0xFFFF_FFFF
    precondition(IOSurfaceLock(surface, [], &seed) == kIOSurfaceSuccess)
    precondition(seed == before)
    surface.baseAddress.storeBytes(of: UInt32(0xAABB_CCDD), as: UInt32.self)
    precondition(IOSurfaceUnlock(surface, [], &seed) == kIOSurfaceSuccess)
    precondition(seed == before &+ 1)
    precondition(IOSurfaceGetSeed(surface) == seed)
    precondition(surface.baseAddress.load(as: UInt32.self) == 0xAABB_CCDD)
}

func testReadOnlyLockDoesNotBumpSeed() {
    let surface = iosurfaceMakeBGRA(2, 2)
    let before = surface.seed
    precondition(surface.lock(options: .readOnly, seed: nil) == kIOSurfaceSuccess)
    precondition(surface.unlock(options: .readOnly, seed: nil) == kIOSurfaceSuccess)
    precondition(surface.seed == before)
}

func testLockAvoidSync() {
    let surface = iosurfaceMakeBGRA(2, 1)
    precondition(IOSurfaceLock(surface, .avoidSync, nil) == kIOSurfaceSuccess)
    precondition(IOSurfaceUnlock(surface, .avoidSync, nil) == kIOSurfaceSuccess)
}

func testCLockAPI() {
    let surface = iosurfaceMakeBGRA(2, 1)
    var seed: UInt32 = 0
    precondition(surface.lock(options: [], seed: &seed) == kIOSurfaceSuccess)
    precondition(surface.unlock(options: [], seed: &seed) == kIOSurfaceSuccess)
}

func testNestedWriteLocks() {
    let surface = iosurfaceMakeBGRA(2, 1)
    let before = surface.seed
    precondition(surface.lock(options: [], seed: nil) == kIOSurfaceSuccess)
    precondition(surface.lock(options: [], seed: nil) == kIOSurfaceSuccess)
    precondition(surface.unlock(options: [], seed: nil) == kIOSurfaceSuccess)
    precondition(surface.seed == before)
    precondition(surface.unlock(options: [], seed: nil) == kIOSurfaceSuccess)
    precondition(surface.seed == before &+ 1)
}
