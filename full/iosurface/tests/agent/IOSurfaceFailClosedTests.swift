import Foundation
import IOSurface

func testMachPortFailClosed() {
    let surface = iosurfaceMakeBGRA(2, 1)
    precondition(IOSurfaceCreateMachPort(surface) == 0)
}

func testLookupFromMachPort() {
    precondition(IOSurfaceLookupFromMachPort(1) == nil)
    precondition(IOSurfaceLookupFromMachPort(0) == nil)
}

func testOwnershipIdentityFailClosed() {
    let surface = iosurfaceMakeBGRA(2, 1)
    let status = IOSurfaceSetOwnershipIdentity(
        surface,
        1,
        IOSurfaceMemoryLedgerTags.graphics.rawValue,
        IOSurfaceMemoryLedgerFlags.noFootprint.rawValue
    )
    precondition(status == 5)
    precondition(status != kIOSurfaceSuccess)
}
