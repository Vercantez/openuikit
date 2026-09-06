import Foundation

/// Camera versus scanner. Apple `NS_OPTIONS` values `0x00000001` /
/// `0x00000002` imported as a Swift enum with a failable `UInt`
/// raw-value initializer.
public enum ICDeviceType: UInt, Equatable, Hashable, Sendable {
    case camera = 0x00000001
    case scanner = 0x00000002
}

/// Device-type browse mask. Same bit values as `ICDeviceType`.
public enum ICDeviceTypeMask: UInt, Equatable, Hashable, Sendable {
    case camera = 0x00000001
    case scanner = 0x00000002
}

/// Transport location class. Apple values `0x00000100` … `0x00000800`.
public enum ICDeviceLocationType: UInt, Equatable, Hashable, Sendable {
    case local = 0x00000100
    case shared = 0x00000200
    case bonjour = 0x00000400
    case bluetooth = 0x00000800
}

/// Location browse mask, including remote (`0x0000FE00`).
public enum ICDeviceLocationTypeMask: UInt, Equatable, Hashable, Sendable {
    case local = 0x00000100
    case shared = 0x00000200
    case bonjour = 0x00000400
    case bluetooth = 0x00000800
    case remote = 0x0000FE00
}

/// EXIF orientation tag values 1…8, matching the EXIF specification
/// and the pinned ImageCaptureCore overlay.
public enum ICEXIFOrientationType: UInt, Equatable, Hashable, Sendable {
    case orientation1 = 1
    case orientation2 = 2
    case orientation3 = 3
    case orientation4 = 4
    case orientation5 = 5
    case orientation6 = 6
    case orientation7 = 7
    case orientation8 = 8
}

/// HEIF presentation. Sequential `NSUInteger` cases starting at 1 as
/// recorded by the Xcode 26 header translator (`ConvertedAssets = 1`,
/// `OriginalAssets = 2`).
public enum ICMediaPresentation: UInt, Equatable, Hashable, Sendable {
    case convertedAssets = 1
    case originalAssets = 2
}

/// Bases for nested ImageCaptureCore error codes. Values match Apple's
/// `ImageCaptureConstants.h` and the pinned dotnet-macios `Defs.cs`.
public enum ICReturnCodeOffset: Int, Equatable, Hashable, Sendable {
    case thumbnailOffset = -21000
    case metadataOffset = -21050
    case downloadOffset = -21100
    case deleteOffset = -21150
    case exFATOffset = -21200
    case ptpOffset = -21250
    case systemOffset = -21300
    case deviceOffset = -21350
    case deviceConnection = -21400
    case objectOffset = -21450
}
