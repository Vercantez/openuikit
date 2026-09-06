import Foundation
import IOSurface

func testSurfaceIDAndLookup() {
    let surface = iosurfaceMakeBGRA(4, 2)
    let id = IOSurfaceGetID(surface)
    precondition(id == surface.surfaceID)
    precondition(id != 0)
    let found = IOSurfaceLookup(id)
    precondition(found === surface)
}

func testLookupUnknown() {
    precondition(IOSurfaceLookup(0xFFFF_FFFE) == nil)
}

func testGetID() {
    let first = iosurfaceMakeBGRA(2, 1)
    let second = iosurfaceMakeBGRA(2, 1)
    precondition(IOSurfaceGetID(first) != IOSurfaceGetID(second))
}
