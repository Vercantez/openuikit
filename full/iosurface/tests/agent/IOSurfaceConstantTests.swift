import Foundation
import IOSurface

func testCacheModeConstants() {
    precondition(kIOSurfaceDefaultCache == 0)
    precondition(kIOSurfaceInhibitCache == 1)
    precondition(kIOSurfaceWriteThruCache == 2)
    precondition(kIOSurfaceCopybackCache == 3)
    precondition(kIOSurfaceWriteCombineCache == 4)
    precondition(kIOSurfaceCopybackInnerCache == 5)
}

func testMapCacheConstants() {
    precondition(kIOSurfaceMapCacheShift == 8)
    precondition(kIOSurfaceMapDefaultCache == 0)
    precondition(kIOSurfaceMapInhibitCache == 1 << 8)
    precondition(kIOSurfaceMapWriteThruCache == 2 << 8)
    precondition(kIOSurfaceMapCopybackCache == 3 << 8)
    precondition(kIOSurfaceMapWriteCombineCache == 4 << 8)
    precondition(kIOSurfaceMapCopybackInnerCache == 5 << 8)
}

func testSuccessConstant() {
    precondition(kIOSurfaceSuccess == 0)
}

func testCFStringKeys() {
    precondition((kIOSurfaceAllocSize as String) == "IOSurfaceAllocSize")
    precondition((kIOSurfaceWidth as String) == "IOSurfaceWidth")
    precondition((kIOSurfaceHeight as String) == "IOSurfaceHeight")
    precondition((kIOSurfaceBytesPerRow as String) == "IOSurfaceBytesPerRow")
    precondition((kIOSurfaceBytesPerElement as String) == "IOSurfaceBytesPerElement")
    precondition((kIOSurfaceElementWidth as String) == "IOSurfaceElementWidth")
    precondition((kIOSurfaceElementHeight as String) == "IOSurfaceElementHeight")
    precondition((kIOSurfaceOffset as String) == "IOSurfaceOffset")
    precondition((kIOSurfaceCacheMode as String) == "IOSurfaceCacheMode")
    precondition((kIOSurfacePixelFormat as String) == "IOSurfacePixelFormat")
    precondition((kIOSurfacePixelSizeCastingAllowed as String) == "IOSurfacePixelSizeCastingAllowed")
    precondition((kIOSurfaceName as String) == "IOSurfaceName")
    precondition((kIOSurfaceColorSpace as String) == "IOSurfaceColorSpace")
    precondition((kIOSurfaceICCProfile as String) == "IOSurfaceICCProfile")
    precondition((kIOSurfaceIsGlobal as String) == "IOSurfaceIsGlobal")
    precondition((kIOSurfaceContentHeadroom as String) == "IOSurfaceContentHeadroom")
    precondition((kIOSurfaceSubsampling as String) == "IOSurfaceSubsampling")
}

func testPlaneCFStringKeys() {
    precondition((kIOSurfacePlaneInfo as String) == "IOSurfacePlaneInfo")
    precondition((kIOSurfacePlaneWidth as String) == "IOSurfacePlaneWidth")
    precondition((kIOSurfacePlaneHeight as String) == "IOSurfacePlaneHeight")
    precondition((kIOSurfacePlaneBytesPerRow as String) == "IOSurfacePlaneBytesPerRow")
    precondition((kIOSurfacePlaneOffset as String) == "IOSurfacePlaneOffset")
    precondition((kIOSurfacePlaneSize as String) == "IOSurfacePlaneSize")
    precondition((kIOSurfacePlaneBase as String) == "IOSurfacePlaneBase")
    precondition((kIOSurfacePlaneBytesPerElement as String) == "IOSurfacePlaneBytesPerElement")
    precondition((kIOSurfacePlaneElementWidth as String) == "IOSurfacePlaneElementWidth")
    precondition((kIOSurfacePlaneElementHeight as String) == "IOSurfacePlaneElementHeight")
    precondition((kIOSurfacePlaneBitsPerElement as String) == "IOSurfacePlaneBitsPerElement")
    precondition((kIOSurfacePlaneComponentNames as String) == "IOSurfacePlaneComponentNames")
    precondition((kIOSurfacePlaneComponentTypes as String) == "IOSurfacePlaneComponentTypes")
    precondition((kIOSurfacePlaneComponentRanges as String) == "IOSurfacePlaneComponentRanges")
    precondition((kIOSurfacePlaneComponentBitDepths as String) == "IOSurfacePlaneComponentBitDepths")
    precondition((kIOSurfacePlaneComponentBitOffsets as String) == "IOSurfacePlaneComponentBitOffsets")
}

func testPropertyKeys() {
    precondition(IOSurfacePropertyKey.allocSize.rawValue == "IOSurfaceAllocSize")
    precondition(IOSurfacePropertyKey.allocSizeKey.rawValue == "IOSurfaceAllocSize")
    precondition(IOSurfacePropertyKey.width.rawValue == "IOSurfaceWidth")
    precondition(IOSurfacePropertyKey.height.rawValue == "IOSurfaceHeight")
    precondition(IOSurfacePropertyKey.bytesPerRow.rawValue == "IOSurfaceBytesPerRow")
    precondition(IOSurfacePropertyKey.bytesPerElement.rawValue == "IOSurfaceBytesPerElement")
    precondition(IOSurfacePropertyKey.elementWidth.rawValue == "IOSurfaceElementWidth")
    precondition(IOSurfacePropertyKey.elementHeight.rawValue == "IOSurfaceElementHeight")
    precondition(IOSurfacePropertyKey.offset.rawValue == "IOSurfaceOffset")
    precondition(IOSurfacePropertyKey.planeInfo.rawValue == "IOSurfacePlaneInfo")
    precondition(IOSurfacePropertyKey.planeWidth.rawValue == "IOSurfacePlaneWidth")
    precondition(IOSurfacePropertyKey.planeHeight.rawValue == "IOSurfacePlaneHeight")
    precondition(IOSurfacePropertyKey.planeBytesPerRow.rawValue == "IOSurfacePlaneBytesPerRow")
    precondition(IOSurfacePropertyKey.planeOffset.rawValue == "IOSurfacePlaneOffset")
    precondition(IOSurfacePropertyKey.planeSize.rawValue == "IOSurfacePlaneSize")
    precondition(IOSurfacePropertyKey.planeBase.rawValue == "IOSurfacePlaneBase")
    precondition(IOSurfacePropertyKey.planeBytesPerElement.rawValue == "IOSurfacePlaneBytesPerElement")
    precondition(IOSurfacePropertyKey.planeElementWidth.rawValue == "IOSurfacePlaneElementWidth")
    precondition(IOSurfacePropertyKey.planeElementHeight.rawValue == "IOSurfacePlaneElementHeight")
    precondition(IOSurfacePropertyKey.cacheMode.rawValue == "IOSurfaceCacheMode")
    precondition(IOSurfacePropertyKey.pixelFormat.rawValue == "IOSurfacePixelFormat")
    precondition(IOSurfacePropertyKey.pixelSizeCastingAllowed.rawValue == "IOSurfacePixelSizeCastingAllowed")
    precondition(IOSurfacePropertyKey.name.rawValue == "IOSurfaceName")
    precondition(IOSurfacePropertyKey(rawValue: "IOSurfaceWidth") == .width)
}

func testPropertyKeyHashable() {
    precondition(IOSurfacePropertyKey.width != .height)
    var hasher = Hasher()
    IOSurfacePropertyKey.width.hash(into: &hasher)
    _ = IOSurfacePropertyKey.height.hashValue
}

func testIOSurfaceIDTypealias() {
    let id: IOSurfaceID = 7
    precondition(id == UInt32(7))
}
