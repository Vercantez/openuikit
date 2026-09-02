/// Graph-present option sets and enums. Named bit positions and enum raw
/// values are pinned to observations from the Xcode 26.1 iPhoneOS SDK.

@frozen
public struct AudioChannelBitmap: OptionSet, Sendable, Equatable, BitwiseCopyable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static var bit_Left: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 0) }
    public static var bit_Right: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 1) }
    public static var bit_Center: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 2) }
    public static var bit_LFEScreen: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 3) }
    public static var bit_LeftSurround: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 4) }
    public static var bit_RightSurround: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 5) }
    public static var bit_LeftCenter: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 6) }
    public static var bit_RightCenter: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 7) }
    public static var bit_CenterSurround: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 8) }
    public static var bit_LeftSurroundDirect: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 9) }
    public static var bit_RightSurroundDirect: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 10) }
    public static var bit_TopCenterSurround: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 11) }
    public static var bit_VerticalHeightLeft: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 12) }
    public static var bit_VerticalHeightCenter: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 13) }
    public static var bit_VerticalHeightRight: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 14) }
    public static var bit_TopBackLeft: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 15) }
    public static var bit_TopBackCenter: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 16) }
    public static var bit_TopBackRight: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 17) }
    public static var bit_LeftTopFront: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 12) }
    public static var bit_CenterTopFront: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 13) }
    public static var bit_RightTopFront: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 14) }
    public static var bit_LeftTopMiddle: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 21) }
    public static var bit_CenterTopMiddle: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 11) }
    public static var bit_RightTopMiddle: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 23) }
    public static var bit_LeftTopRear: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 24) }
    public static var bit_CenterTopRear: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 25) }
    public static var bit_RightTopRear: AudioChannelBitmap { AudioChannelBitmap(rawValue: 1 << 26) }
}

@frozen
@_alignment(4)
public enum AudioChannelCoordinateIndex: UInt32, Sendable, Equatable, Hashable, BitwiseCopyable {
    case coordinates_LeftRight = 0
    case coordinates_BackFront = 1
    case coordinates_DownUp = 2

    public static var coordinates_Azimuth: AudioChannelCoordinateIndex { .coordinates_LeftRight }
    public static var coordinates_Elevation: AudioChannelCoordinateIndex { .coordinates_BackFront }
    public static var coordinates_Distance: AudioChannelCoordinateIndex { .coordinates_DownUp }
}

@frozen
public struct AudioChannelFlags: OptionSet, Sendable, Equatable, BitwiseCopyable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static var rectangularCoordinates: AudioChannelFlags { AudioChannelFlags(rawValue: 1 << 0) }
    public static var sphericalCoordinates: AudioChannelFlags { AudioChannelFlags(rawValue: 1 << 1) }
    public static var meters: AudioChannelFlags { AudioChannelFlags(rawValue: 1 << 2) }
}

@frozen
public struct AudioTimeStampFlags: OptionSet, Sendable, Equatable, BitwiseCopyable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static var sampleTimeValid: AudioTimeStampFlags { AudioTimeStampFlags(rawValue: 1 << 0) }
    public static var hostTimeValid: AudioTimeStampFlags { AudioTimeStampFlags(rawValue: 1 << 1) }
    public static var rateScalarValid: AudioTimeStampFlags { AudioTimeStampFlags(rawValue: 1 << 2) }
    public static var wordClockTimeValid: AudioTimeStampFlags { AudioTimeStampFlags(rawValue: 1 << 3) }
    public static var smpteTimeValid: AudioTimeStampFlags { AudioTimeStampFlags(rawValue: 1 << 4) }
    public static var sampleHostTimeValid: AudioTimeStampFlags { [.sampleTimeValid, .hostTimeValid] }
}

@frozen
public struct SMPTETimeFlags: OptionSet, Sendable, Equatable, BitwiseCopyable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static var valid: SMPTETimeFlags { SMPTETimeFlags(rawValue: 1 << 0) }
    public static var running: SMPTETimeFlags { SMPTETimeFlags(rawValue: 1 << 1) }
}

@frozen
@_alignment(4)
public enum SMPTETimeType: UInt32, Sendable, Equatable, Hashable, BitwiseCopyable {
    case type24 = 0
    case type25 = 1
    case type30Drop = 2
    case type30 = 3
    case type2997 = 4
    case type2997Drop = 5
    case type60 = 6
    case type5994 = 7
    case type60Drop = 8
    case type5994Drop = 9
    case type50 = 10
    case type2398 = 11
}

@frozen
@_alignment(8)
public enum MPEG4ObjectID: Int, Sendable, Equatable, Hashable, BitwiseCopyable {
    case aac_Main = 1
    case AAC_LC = 2
    case AAC_SSR = 3
    case AAC_LTP = 4
    case AAC_SBR = 5
    case aac_Scalable = 6
    case twinVQ = 7
    case CELP = 8
    case HVXC = 9
}
