import Foundation
import IOSurface

func iosurfaceMakeBGRA(_ width: Int, _ height: Int) -> IOSurface {
    let properties: NSDictionary = [
        kIOSurfaceWidth: width,
        kIOSurfaceHeight: height,
        kIOSurfacePixelFormat: 0x4247_5241,
    ]
    guard let surface = IOSurfaceCreate(properties) else {
        preconditionFailure("IOSurfaceCreate BGRA \(width)x\(height)")
    }
    return surface
}

func testCreatePackedBGRA() {
    let surface = iosurfaceMakeBGRA(16, 8)
    precondition(IOSurfaceGetWidth(surface) == 16)
    precondition(IOSurfaceGetHeight(surface) == 8)
    precondition(IOSurfaceGetPixelFormat(surface) == 0x4247_5241)
    precondition(IOSurfaceGetBytesPerElement(surface) == 4)
    precondition(IOSurfaceGetBytesPerRow(surface) >= 16 * 4)
    precondition(IOSurfaceGetAllocSize(surface) >= IOSurfaceGetBytesPerRow(surface) * 8)
    precondition(IOSurfaceGetElementWidth(surface) == 1)
    precondition(IOSurfaceGetElementHeight(surface) == 1)
    precondition(IOSurfaceGetPlaneCount(surface) == 0)
}

func testCreateRequiresDimensions() {
    let empty: NSDictionary = [:]
    precondition(IOSurfaceCreate(empty) == nil)
    let widthOnly: NSDictionary = [kIOSurfaceWidth: 8]
    precondition(IOSurfaceCreate(widthOnly) == nil)
}

func testCreateFromAllocSize() {
    let properties: NSDictionary = [kIOSurfaceAllocSize: 64]
    guard let surface = IOSurfaceCreate(properties) else {
        preconditionFailure("alloc-size create")
    }
    precondition(IOSurfaceGetAllocSize(surface) >= 64)
    precondition(IOSurfaceGetWidth(surface) == 0)
    precondition(IOSurfaceGetHeight(surface) == 0)
}

func testCreateSwiftOverlay() {
    guard let surface = IOSurface(properties: [
        .width: 4,
        .height: 2,
        .pixelFormat: UInt32(0x5247_4241),
        .name: "probe",
        .bytesPerElement: 4,
        .elementWidth: 1,
        .elementHeight: 1,
        .pixelSizeCastingAllowed: false,
        .cacheMode: kIOSurfaceInhibitCache,
    ]) else {
        preconditionFailure("overlay create")
    }
    precondition(surface.width == 4)
    precondition(surface.height == 2)
    precondition(surface.pixelFormat == 0x5247_4241)
    precondition(surface.bytesPerElement == 4)
    precondition(surface.elementWidth == 1)
    precondition(surface.elementHeight == 1)
    precondition(surface.allowsPixelSizeCasting == false)
    precondition(surface.allocationSize >= surface.bytesPerRow * 2)
}

func testBytesPerRowAlignment() {
    let aligned = IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, 17)
    precondition(aligned % 16 == 0)
    precondition(aligned >= 17)
    let surface = iosurfaceMakeBGRA(3, 1)
    precondition(IOSurfaceGetBytesPerRow(surface) % 16 == 0)
}

func testPixelSizeCasting() {
    let surface = iosurfaceMakeBGRA(2, 2)
    precondition(IOSurfaceAllowsPixelSizeCasting(surface) == true)
    precondition(surface.allowsPixelSizeCasting == true)
}

func testElementSize() {
    let surface = iosurfaceMakeBGRA(8, 2)
    precondition(IOSurfaceGetElementWidth(surface) == 1)
    precondition(IOSurfaceGetElementHeight(surface) == 1)
}

func testTypeID() {
    precondition(IOSurfaceGetTypeID() != 0)
}

func testPixelFormat() {
    let surface = iosurfaceMakeBGRA(2, 2)
    precondition(IOSurfaceGetPixelFormat(surface) == surface.pixelFormat)
}

func testRejectOversized() {
    let properties: NSDictionary = [
        kIOSurfaceWidth: 100_000,
        kIOSurfaceHeight: 8,
    ]
    precondition(IOSurfaceCreate(properties) == nil)
}
