import CoreFoundation
import Foundation

/// C `ColorSyncAlphaInfo` imported as a Swift struct with UInt32 raw values
/// matching ColorSyncTransform.h (`kColorSyncAlphaNone = 0` … SkipFirst = 6).
public struct ColorSyncAlphaInfo: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var kColorSyncAlphaNone: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 0) }
public var kColorSyncAlphaPremultipliedLast: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 1) }
public var kColorSyncAlphaPremultipliedFirst: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 2) }
public var kColorSyncAlphaLast: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 3) }
public var kColorSyncAlphaFirst: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 4) }
public var kColorSyncAlphaNoneSkipLast: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 5) }
public var kColorSyncAlphaNoneSkipFirst: ColorSyncAlphaInfo { ColorSyncAlphaInfo(rawValue: 6) }

public var kColorSyncAlphaInfoMask: Int { 0x1F }
public var kColorSyncByteOrderMask: Int { 0x7000 }
public var kColorSyncByteOrderDefault: Int { 0 << 12 }
public var kColorSyncByteOrder16Little: Int { 1 << 12 }
public var kColorSyncByteOrder32Little: Int { 2 << 12 }
public var kColorSyncByteOrder16Big: Int { 3 << 12 }
public var kColorSyncByteOrder32Big: Int { 4 << 12 }

/// C `ColorSyncDataDepth` (`kColorSync1BitGamut = 1` … `kColorSync10BitInteger = 8`).
public struct ColorSyncDataDepth: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var kColorSync1BitGamut: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 1) }
public var kColorSync8BitInteger: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 2) }
public var kColorSync16BitInteger: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 3) }
public var kColorSync16BitFloat: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 4) }
public var kColorSync32BitInteger: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 5) }
public var kColorSync32BitNamedColorIndex: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 6) }
public var kColorSync32BitFloat: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 7) }
public var kColorSync10BitInteger: ColorSyncDataDepth { ColorSyncDataDepth(rawValue: 8) }

public typealias ColorSyncDataLayout = UInt32

public var COLORSYNC_MD5_LENGTH: Int32 { 16 }

public struct ColorSyncMD5: Sendable {
    public var digest: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    public init(
        digest: (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        )
    ) {
        self.digest = digest
    }

    public init() {
        self.init(digest: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    }
}

func _csMD5FromBytes(_ bytes: [UInt8]) -> ColorSyncMD5 {
    precondition(bytes.count == 16)
    return ColorSyncMD5(digest: (
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11],
        bytes[12], bytes[13], bytes[14], bytes[15]
    ))
}

func _csMD5Bytes(_ value: ColorSyncMD5) -> [UInt8] {
    [
        value.digest.0, value.digest.1, value.digest.2, value.digest.3,
        value.digest.4, value.digest.5, value.digest.6, value.digest.7,
        value.digest.8, value.digest.9, value.digest.10, value.digest.11,
        value.digest.12, value.digest.13, value.digest.14, value.digest.15
    ]
}

func _csMD5IsZero(_ value: ColorSyncMD5) -> Bool {
    _csMD5Bytes(value).allSatisfy { $0 == 0 }
}

public typealias ColorSyncProfileIterateCallback = (CFDictionary?, UnsafeMutableRawPointer?) -> Bool

let _csProfileTypeID: CFTypeID = 0x4353_0001
let _csTransformTypeID: CFTypeID = 0x4353_0002
