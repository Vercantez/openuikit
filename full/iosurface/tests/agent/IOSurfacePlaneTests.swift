import Foundation
import IOSurface

func testNonplanarPlaneQueries() {
    let surface = iosurfaceMakeBGRA(8, 4)
    precondition(IOSurfaceGetPlaneCount(surface) == 0)
    precondition(IOSurfaceGetWidthOfPlane(surface, 0) == 8)
    precondition(IOSurfaceGetHeightOfPlane(surface, 0) == 4)
    precondition(IOSurfaceGetBytesPerRowOfPlane(surface, 0) == IOSurfaceGetBytesPerRow(surface))
    precondition(IOSurfaceGetBytesPerElementOfPlane(surface, 0) == 4)
    precondition(IOSurfaceGetElementWidthOfPlane(surface, 0) == 1)
    precondition(IOSurfaceGetElementHeightOfPlane(surface, 0) == 1)
    precondition(IOSurfaceGetBaseAddressOfPlane(surface, 0) == IOSurfaceGetBaseAddress(surface))
    precondition(surface.widthOfPlane(at: 0) == 8)
    precondition(surface.heightOfPlane(at: 0) == 4)
    precondition(surface.bytesPerRowOfPlane(at: 0) == surface.bytesPerRow)
    precondition(surface.bytesPerElementOfPlane(at: 0) == 4)
    precondition(surface.elementWidthOfPlane(at: 0) == 1)
    precondition(surface.elementHeightOfPlane(at: 0) == 1)
    precondition(surface.baseAddressOfPlane(at: 0) == surface.baseAddress)
}

func testBiplanar420() {
    let properties: NSDictionary = [
        kIOSurfaceWidth: 32,
        kIOSurfaceHeight: 16,
        kIOSurfacePixelFormat: 0x3432_3076,
    ]
    guard let surface = IOSurfaceCreate(properties) else {
        preconditionFailure("420v create")
    }
    precondition(IOSurfaceGetPlaneCount(surface) == 2)
    precondition(IOSurfaceGetWidthOfPlane(surface, 0) == 32)
    precondition(IOSurfaceGetHeightOfPlane(surface, 0) == 16)
    precondition(IOSurfaceGetWidthOfPlane(surface, 1) == 16)
    precondition(IOSurfaceGetHeightOfPlane(surface, 1) == 8)
    precondition(IOSurfaceGetSubsampling(surface) == .subsampling420)
    precondition(IOSurfaceGetNumberOfComponentsOfPlane(surface, 0) == 1)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 0, 0) == .luma)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 1, 0) == .chromaBlue)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 1, 1) == .chromaRed)
    let y = IOSurfaceGetBaseAddressOfPlane(surface, 0)
    let uv = IOSurfaceGetBaseAddressOfPlane(surface, 1)
    precondition(uv != y)
}

func testComponentQueriesBGRA() {
    let surface = iosurfaceMakeBGRA(2, 2)
    precondition(IOSurfaceGetNumberOfComponentsOfPlane(surface, 0) == 4)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 0, 0) == .blue)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 0, 1) == .green)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 0, 2) == .red)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 0, 3) == .alpha)
    precondition(IOSurfaceGetTypeOfComponentOfPlane(surface, 0, 0) == .unsignedInteger)
    precondition(IOSurfaceGetRangeOfComponentOfPlane(surface, 0, 0) == .fullRange)
    precondition(IOSurfaceGetBitDepthOfComponentOfPlane(surface, 0, 0) == 8)
    precondition(IOSurfaceGetBitOffsetOfComponentOfPlane(surface, 0, 0) == 0)
    precondition(IOSurfaceGetBitOffsetOfComponentOfPlane(surface, 0, 1) == 8)
    precondition(IOSurfaceGetSubsampling(surface) == .subsamplingNone)
}

func testCPlaneAPI() {
    let surface = iosurfaceMakeBGRA(4, 2)
    precondition(surface.planeCount == 0)
    precondition(IOSurfaceGetBaseAddress(surface) == surface.baseAddress)
}

func testExplicitPlaneInfo() {
    let plane0: NSDictionary = [
        kIOSurfacePlaneWidth: 8,
        kIOSurfacePlaneHeight: 4,
        kIOSurfacePlaneBytesPerElement: 1,
        kIOSurfacePlaneComponentNames: [IOSurfaceComponentName.luma.rawValue] as NSArray,
        kIOSurfacePlaneComponentTypes: [IOSurfaceComponentType.unsignedInteger.rawValue] as NSArray,
        kIOSurfacePlaneComponentRanges: [IOSurfaceComponentRange.videoRange.rawValue] as NSArray,
        kIOSurfacePlaneComponentBitDepths: [8] as NSArray,
        kIOSurfacePlaneComponentBitOffsets: [0] as NSArray,
    ]
    let properties: NSDictionary = [
        kIOSurfaceWidth: 8,
        kIOSurfaceHeight: 4,
        kIOSurfacePlaneInfo: [plane0] as NSArray,
    ]
    guard let surface = IOSurfaceCreate(properties) else {
        preconditionFailure("explicit plane")
    }
    precondition(IOSurfaceGetNumberOfComponentsOfPlane(surface, 0) == 1)
    precondition(IOSurfaceGetNameOfComponentOfPlane(surface, 0, 0) == .luma)
    precondition(IOSurfaceGetTypeOfComponentOfPlane(surface, 0, 0) == .unsignedInteger)
    precondition(IOSurfaceGetRangeOfComponentOfPlane(surface, 0, 0) == .videoRange)
}
