import Foundation
import IOSurface

func testUseCount() {
    let surface = iosurfaceMakeBGRA(2, 2)
    precondition(surface.localUseCount == 0)
    precondition(surface.isInUse == false)
    surface.incrementUseCount()
    precondition(surface.localUseCount == 1)
    precondition(surface.isInUse == true)
    surface.decrementUseCount()
    precondition(surface.localUseCount == 0)
    precondition(surface.isInUse == false)
}

func testCUseCountAPI() {
    let surface = iosurfaceMakeBGRA(2, 1)
    precondition(IOSurfaceGetUseCount(surface) == 0)
    IOSurfaceIncrementUseCount(surface)
    IOSurfaceIncrementUseCount(surface)
    precondition(IOSurfaceGetUseCount(surface) == 2)
    IOSurfaceDecrementUseCount(surface)
    precondition(IOSurfaceGetUseCount(surface) == 1)
    IOSurfaceDecrementUseCount(surface)
    precondition(IOSurfaceGetUseCount(surface) == 0)
}

func testIsInUseWhenLocked() {
    let surface = iosurfaceMakeBGRA(2, 1)
    precondition(IOSurfaceIsInUse(surface) == false)
    precondition(IOSurfaceLock(surface, [], nil) == kIOSurfaceSuccess)
    precondition(IOSurfaceIsInUse(surface) == true)
    precondition(IOSurfaceUnlock(surface, [], nil) == kIOSurfaceSuccess)
    precondition(IOSurfaceIsInUse(surface) == false)
}

func testDecrementDoesNotWrap() {
    let surface = iosurfaceMakeBGRA(1, 1)
    surface.decrementUseCount()
    precondition(surface.localUseCount == 0)
}
