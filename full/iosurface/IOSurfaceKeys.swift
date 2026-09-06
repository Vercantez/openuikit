import Foundation

public struct IOSurfacePropertyKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let allocSize = IOSurfacePropertyKey(rawValue: "IOSurfaceAllocSize")
    public static let allocSizeKey = IOSurfacePropertyKey(rawValue: "IOSurfaceAllocSize")
    public static let width = IOSurfacePropertyKey(rawValue: "IOSurfaceWidth")
    public static let height = IOSurfacePropertyKey(rawValue: "IOSurfaceHeight")
    public static let bytesPerRow = IOSurfacePropertyKey(rawValue: "IOSurfaceBytesPerRow")
    public static let bytesPerElement = IOSurfacePropertyKey(rawValue: "IOSurfaceBytesPerElement")
    public static let elementWidth = IOSurfacePropertyKey(rawValue: "IOSurfaceElementWidth")
    public static let elementHeight = IOSurfacePropertyKey(rawValue: "IOSurfaceElementHeight")
    public static let offset = IOSurfacePropertyKey(rawValue: "IOSurfaceOffset")
    public static let planeInfo = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneInfo")
    public static let planeWidth = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneWidth")
    public static let planeHeight = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneHeight")
    public static let planeBytesPerRow = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneBytesPerRow")
    public static let planeOffset = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneOffset")
    public static let planeSize = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneSize")
    public static let planeBase = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneBase")
    public static let planeBytesPerElement = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneBytesPerElement")
    public static let planeElementWidth = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneElementWidth")
    public static let planeElementHeight = IOSurfacePropertyKey(rawValue: "IOSurfacePlaneElementHeight")
    public static let cacheMode = IOSurfacePropertyKey(rawValue: "IOSurfaceCacheMode")
    public static let pixelFormat = IOSurfacePropertyKey(rawValue: "IOSurfacePixelFormat")
    public static let pixelSizeCastingAllowed = IOSurfacePropertyKey(rawValue: "IOSurfacePixelSizeCastingAllowed")
    public static let name = IOSurfacePropertyKey(rawValue: "IOSurfaceName")
}

public let kIOSurfaceAllocSize: CFString = iosurfaceCFString(IOSurfacePropertyKey.allocSize.rawValue)
public let kIOSurfaceWidth: CFString = iosurfaceCFString(IOSurfacePropertyKey.width.rawValue)
public let kIOSurfaceHeight: CFString = iosurfaceCFString(IOSurfacePropertyKey.height.rawValue)
public let kIOSurfaceBytesPerRow: CFString = iosurfaceCFString(IOSurfacePropertyKey.bytesPerRow.rawValue)
public let kIOSurfaceBytesPerElement: CFString = iosurfaceCFString(IOSurfacePropertyKey.bytesPerElement.rawValue)
public let kIOSurfaceElementWidth: CFString = iosurfaceCFString(IOSurfacePropertyKey.elementWidth.rawValue)
public let kIOSurfaceElementHeight: CFString = iosurfaceCFString(IOSurfacePropertyKey.elementHeight.rawValue)
public let kIOSurfaceOffset: CFString = iosurfaceCFString(IOSurfacePropertyKey.offset.rawValue)
public let kIOSurfacePlaneInfo: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeInfo.rawValue)
public let kIOSurfacePlaneWidth: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeWidth.rawValue)
public let kIOSurfacePlaneHeight: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeHeight.rawValue)
public let kIOSurfacePlaneBytesPerRow: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeBytesPerRow.rawValue)
public let kIOSurfacePlaneOffset: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeOffset.rawValue)
public let kIOSurfacePlaneSize: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeSize.rawValue)
public let kIOSurfacePlaneBase: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeBase.rawValue)
public let kIOSurfacePlaneBytesPerElement: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeBytesPerElement.rawValue)
public let kIOSurfacePlaneElementWidth: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeElementWidth.rawValue)
public let kIOSurfacePlaneElementHeight: CFString = iosurfaceCFString(IOSurfacePropertyKey.planeElementHeight.rawValue)
public let kIOSurfaceCacheMode: CFString = iosurfaceCFString(IOSurfacePropertyKey.cacheMode.rawValue)
public let kIOSurfacePixelFormat: CFString = iosurfaceCFString(IOSurfacePropertyKey.pixelFormat.rawValue)
public let kIOSurfacePixelSizeCastingAllowed: CFString =
    iosurfaceCFString(IOSurfacePropertyKey.pixelSizeCastingAllowed.rawValue)
public let kIOSurfaceName: CFString = iosurfaceCFString(IOSurfacePropertyKey.name.rawValue)
public let kIOSurfaceColorSpace: CFString = iosurfaceCFString("IOSurfaceColorSpace")
public let kIOSurfaceICCProfile: CFString = iosurfaceCFString("IOSurfaceICCProfile")
public let kIOSurfaceIsGlobal: CFString = iosurfaceCFString("IOSurfaceIsGlobal")
public let kIOSurfaceContentHeadroom: CFString = iosurfaceCFString("IOSurfaceContentHeadroom")
public let kIOSurfaceSubsampling: CFString = iosurfaceCFString("IOSurfaceSubsampling")
public let kIOSurfacePlaneBitsPerElement: CFString = iosurfaceCFString("IOSurfacePlaneBitsPerElement")
public let kIOSurfacePlaneComponentNames: CFString = iosurfaceCFString("IOSurfacePlaneComponentNames")
public let kIOSurfacePlaneComponentTypes: CFString = iosurfaceCFString("IOSurfacePlaneComponentTypes")
public let kIOSurfacePlaneComponentRanges: CFString = iosurfaceCFString("IOSurfacePlaneComponentRanges")
public let kIOSurfacePlaneComponentBitDepths: CFString =
    iosurfaceCFString("IOSurfacePlaneComponentBitDepths")
public let kIOSurfacePlaneComponentBitOffsets: CFString =
    iosurfaceCFString("IOSurfacePlaneComponentBitOffsets")

let iosurfaceLinuxMaxDimension = 16_384
let iosurfaceBytesPerRowAlignment = 16
let iosurfaceAllocAlignment = 16

func iosurfacePropertyAlignment(_ property: String) -> Int {
    switch property {
    case IOSurfacePropertyKey.bytesPerRow.rawValue,
         IOSurfacePropertyKey.planeBytesPerRow.rawValue:
        return iosurfaceBytesPerRowAlignment
    case IOSurfacePropertyKey.allocSize.rawValue,
         IOSurfacePropertyKey.offset.rawValue,
         IOSurfacePropertyKey.planeOffset.rawValue,
         IOSurfacePropertyKey.planeSize.rawValue,
         IOSurfacePropertyKey.planeBase.rawValue:
        return iosurfaceAllocAlignment
    default:
        return 1
    }
}

func iosurfacePropertyMaximum(_ property: String) -> Int {
    switch property {
    case IOSurfacePropertyKey.width.rawValue, IOSurfacePropertyKey.height.rawValue,
         IOSurfacePropertyKey.planeWidth.rawValue, IOSurfacePropertyKey.planeHeight.rawValue:
        return iosurfaceLinuxMaxDimension
    case IOSurfacePropertyKey.bytesPerElement.rawValue,
         IOSurfacePropertyKey.planeBytesPerElement.rawValue:
        return 16
    case IOSurfacePropertyKey.elementWidth.rawValue, IOSurfacePropertyKey.elementHeight.rawValue,
         IOSurfacePropertyKey.planeElementWidth.rawValue,
         IOSurfacePropertyKey.planeElementHeight.rawValue:
        return 16
    case IOSurfacePropertyKey.bytesPerRow.rawValue, IOSurfacePropertyKey.planeBytesPerRow.rawValue:
        return iosurfaceLinuxMaxDimension * 16
    case IOSurfacePropertyKey.allocSize.rawValue, IOSurfacePropertyKey.planeSize.rawValue:
        return iosurfaceLinuxMaxDimension * iosurfaceLinuxMaxDimension * 16
    case IOSurfacePropertyKey.offset.rawValue, IOSurfacePropertyKey.planeOffset.rawValue,
         IOSurfacePropertyKey.planeBase.rawValue:
        return iosurfaceLinuxMaxDimension * iosurfaceLinuxMaxDimension * 16
    case IOSurfacePropertyKey.cacheMode.rawValue:
        return kIOSurfaceCopybackInnerCache
    case IOSurfacePropertyKey.pixelFormat.rawValue:
        return Int(UInt32.max)
    default:
        return 0
    }
}
