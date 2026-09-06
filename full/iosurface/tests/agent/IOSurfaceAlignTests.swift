import Foundation
import IOSurface

func testPropertyMaximum() {
    precondition(IOSurfaceGetPropertyMaximum(kIOSurfaceWidth) == 16_384)
    precondition(IOSurfaceGetPropertyMaximum(kIOSurfaceHeight) == 16_384)
    precondition(IOSurfaceGetPropertyMaximum(kIOSurfaceCacheMode) == kIOSurfaceCopybackInnerCache)
}

func testPropertyAlignment() {
    precondition(IOSurfaceGetPropertyAlignment(kIOSurfaceWidth) == 1)
    precondition(IOSurfaceGetPropertyAlignment(kIOSurfaceBytesPerRow) == 16)
    precondition(IOSurfaceGetPropertyAlignment(kIOSurfaceAllocSize) == 16)
}

func testAlignProperty() {
    precondition(IOSurfaceAlignProperty(kIOSurfaceWidth, 7) == 7)
    precondition(IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, 1) == 16)
    precondition(IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, 16) == 16)
    precondition(IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, 17) == 32)
}

func testUnknownProperty() {
    let unknown = "IOSurfaceUnknownProbe" as NSString
    precondition(IOSurfaceGetPropertyMaximum(unknown) == 0)
    precondition(IOSurfaceGetPropertyAlignment(unknown) == 1)
    precondition(IOSurfaceAlignProperty(unknown, 11) == 11)
}
