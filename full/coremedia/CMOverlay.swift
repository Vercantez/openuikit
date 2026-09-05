import CoreFoundation
import Foundation

// Swift overlay nested types. CFString payloads come from the kCM* keys
// already interned in CMKeys.swift (suffix strings, CoreVideo color aliases).

extension CMFormatDescription {
    public struct EqualityMask: OptionSet, Hashable, Sendable {
        public let rawValue: CMAudioFormatDescriptionMask
        public init(rawValue: CMAudioFormatDescriptionMask) { self.rawValue = rawValue }
        public static let streamBasicDescription = EqualityMask(
            rawValue: kCMAudioFormatDescriptionMask_StreamBasicDescription
        )
        public static let magicCookie = EqualityMask(rawValue: kCMAudioFormatDescriptionMask_MagicCookie)
        public static let channelLayout = EqualityMask(rawValue: kCMAudioFormatDescriptionMask_ChannelLayout)
        public static let extensions = EqualityMask(rawValue: kCMAudioFormatDescriptionMask_Extensions)
        public static let all = EqualityMask(rawValue: kCMAudioFormatDescriptionMask_All)
    }

    public struct TimeCode: Hashable, Sendable {
        public struct Flag: OptionSet, Hashable, Sendable {
            public let rawValue: UInt32
            public init(rawValue: UInt32) { self.rawValue = rawValue }
            // Bit positions from the public CMTimeCode format flags in
            // CMFormatDescription.h (drop frame = 1<<0, 24-hour max = 1<<1,
            // negative times OK = 1<<2). Graph has names, not integers.
            public static let dropFrame = Flag(rawValue: 1 << 0)
            public static let twentyFourHourMax = Flag(rawValue: 1 << 1)
            public static let negTimesOK = Flag(rawValue: 1 << 2)
        }
    }

    public var timeCodeFlags: TimeCode.Flag { TimeCode.Flag(rawValue: 0) }

    public func equalTo(
        _ otherFormatDescription: CMFormatDescription,
        equalityMask: EqualityMask = .all
    ) -> (Bool, equalityMask: EqualityMask) {
        _ = equalityMask
        let equal = CMFormatDescriptionEqual(self, otherFormatDescription: otherFormatDescription)
        return (equal, equalityMask: equal ? .all : [])
    }
}

extension CMFormatDescription.Extensions.Value {
    public struct FieldDetail: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let temporalTopFirst = FieldDetail(
            rawValue: kCMFormatDescriptionFieldDetail_TemporalTopFirst
        )
        public static let temporalBottomFirst = FieldDetail(
            rawValue: kCMFormatDescriptionFieldDetail_TemporalBottomFirst
        )
        public static let spatialFirstLineLate = FieldDetail(
            rawValue: kCMFormatDescriptionFieldDetail_SpatialFirstLineLate
        )
        public static let spatialFirstLineEarly = FieldDetail(
            rawValue: kCMFormatDescriptionFieldDetail_SpatialFirstLineEarly
        )
        public static func == (lhs: FieldDetail, rhs: FieldDetail) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct YCbCrMatrix: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let itu_R_2020 = YCbCrMatrix(rawValue: kCMFormatDescriptionYCbCrMatrix_ITU_R_2020)
        public static let itu_R_601_4 = YCbCrMatrix(rawValue: kCMFormatDescriptionYCbCrMatrix_ITU_R_601_4)
        public static let itu_R_709_2 = YCbCrMatrix(rawValue: kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2)
        public static let smpted_240M_1995 = YCbCrMatrix(
            rawValue: kCMFormatDescriptionYCbCrMatrix_SMPTE_240M_1995
        )
        public static func == (lhs: YCbCrMatrix, rhs: YCbCrMatrix) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct ChromaLocation: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let bottomLeft = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_BottomLeft)
        public static let top = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_Top)
        public static let left = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_Left)
        public static let dv420 = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_DV420)
        public static let bottom = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_Bottom)
        public static let center = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_Center)
        public static let topLeft = ChromaLocation(rawValue: kCMFormatDescriptionChromaLocation_TopLeft)
        public static func == (lhs: ChromaLocation, rhs: ChromaLocation) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct ColorPrimaries: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let itu_R_2020 = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_ITU_R_2020)
        public static let itu_R_709_2 = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_ITU_R_709_2)
        public static let p22 = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_P22)
        public static let dci_P3 = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_DCI_P3)
        public static let p3_D65 = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_P3_D65)
        public static let smpte_C = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_SMPTE_C)
        public static let ebu_3213 = ColorPrimaries(rawValue: kCMFormatDescriptionColorPrimaries_EBU_3213)
        public static func == (lhs: ColorPrimaries, rhs: ColorPrimaries) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct TransferFunction: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let itu_R_2020 = TransferFunction(
            rawValue: kCMFormatDescriptionTransferFunction_ITU_R_2020
        )
        public static let itu_R_709_2 = TransferFunction(
            rawValue: kCMFormatDescriptionTransferFunction_ITU_R_709_2
        )
        public static let itu_R_2100_HLG = TransferFunction(
            rawValue: kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG
        )
        public static let smpte_ST_428_1 = TransferFunction(
            rawValue: kCMFormatDescriptionTransferFunction_SMPTE_ST_428_1
        )
        public static let smpte_240M_1995 = TransferFunction(
            rawValue: kCMFormatDescriptionTransferFunction_SMPTE_240M_1995
        )
        public static let smpte_ST_2084_PQ = TransferFunction(
            rawValue: kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ
        )
        public static let linear = TransferFunction(rawValue: kCMFormatDescriptionTransferFunction_Linear)
        public static let useGamma = TransferFunction(rawValue: kCMFormatDescriptionTransferFunction_UseGamma)
        public static let sRGB = TransferFunction(rawValue: kCMFormatDescriptionTransferFunction_sRGB)
        public static func == (lhs: TransferFunction, rhs: TransferFunction) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct ProjectionKind: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let rectilinear = ProjectionKind(
            rawValue: kCMFormatDescriptionProjectionKind_Rectilinear
        )
        public static let equirectangular = ProjectionKind(
            rawValue: kCMFormatDescriptionProjectionKind_Equirectangular
        )
        public static let appleImmersiveVideo = ProjectionKind(
            rawValue: kCMFormatDescriptionProjectionKind_AppleImmersiveVideo
        )
        public static let halfEquirectangular = ProjectionKind(
            rawValue: kCMFormatDescriptionProjectionKind_HalfEquirectangular
        )
        public static let parametricImmersive = ProjectionKind(
            rawValue: kCMFormatDescriptionProjectionKind_ParametricImmersive
        )
        public static func == (lhs: ProjectionKind, rhs: ProjectionKind) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct ViewPackingKind: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let sideBySide = ViewPackingKind(
            rawValue: kCMFormatDescriptionViewPackingKind_SideBySide
        )
        public static let overUnder = ViewPackingKind(
            rawValue: kCMFormatDescriptionViewPackingKind_OverUnder
        )
        public static func == (lhs: ViewPackingKind, rhs: ViewPackingKind) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct AlphaChannelMode: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let premultipliedAlpha = AlphaChannelMode(
            rawValue: kCMFormatDescriptionAlphaChannelMode_PremultipliedAlpha
        )
        public static let straightAlpha = AlphaChannelMode(
            rawValue: kCMFormatDescriptionAlphaChannelMode_StraightAlpha
        )
        public static func == (lhs: AlphaChannelMode, rhs: AlphaChannelMode) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct LogTransferFunction: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let appleLog = LogTransferFunction(
            rawValue: kCMFormatDescriptionLogTransferFunction_AppleLog
        )
        public static func == (lhs: LogTransferFunction, rhs: LogTransferFunction) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct Vendor: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let apple = Vendor(rawValue: kCMFormatDescriptionVendor_Apple)
        public static func == (lhs: Vendor, rhs: Vendor) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct HeroEye: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let left = HeroEye(rawValue: kCMFormatDescriptionHeroEye_Left)
        public static let right = HeroEye(rawValue: kCMFormatDescriptionHeroEye_Right)
        public static func == (lhs: HeroEye, rhs: HeroEye) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }

    public struct MPEG2VideoProfile: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = UInt32
        public var rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
        public static let hdv_720p24 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p24))
        public static let hdv_720p25 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p25))
        public static let hdv_720p30 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p30))
        public static let hdv_720p50 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p50))
        public static let hdv_720p60 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p60))
        public static let hdv_1080i50 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080i50))
        public static let hdv_1080i60 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080i60))
        public static let hdv_1080p24 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080p24))
        public static let hdv_1080p25 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080p25))
        public static let hdv_1080p30 = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080p30))
        public static let xdcam_HD_540p = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_540p)
        )
        public static let xdcam_HD422_540p = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_540p)
        )
        public static let xdcam_EX_720p24_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p24_VBR35)
        )
        public static let xdcam_EX_720p25_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p25_VBR35)
        )
        public static let xdcam_EX_720p30_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p30_VBR35)
        )
        public static let xdcam_EX_720p50_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p50_VBR35)
        )
        public static let xdcam_EX_720p60_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p60_VBR35)
        )
        public static let xdcam_EX_1080i50_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080i50_VBR35)
        )
        public static let xdcam_EX_1080i60_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080i60_VBR35)
        )
        public static let xdcam_EX_1080p24_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080p24_VBR35)
        )
        public static let xdcam_EX_1080p25_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080p25_VBR35)
        )
        public static let xdcam_EX_1080p30_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080p30_VBR35)
        )
        public static let xdcam_HD_1080i50_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080i50_VBR35)
        )
        public static let xdcam_HD_1080i60_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080i60_VBR35)
        )
        public static let xdcam_HD_1080p24_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080p24_VBR35)
        )
        public static let xdcam_HD_1080p25_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080p25_VBR35)
        )
        public static let xdcam_HD_1080p30_VBR35 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080p30_VBR35)
        )
        public static let xdcam_HD422_720p24_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p24_CBR50)
        )
        public static let xdcam_HD422_720p25_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p25_CBR50)
        )
        public static let xdcam_HD422_720p30_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p30_CBR50)
        )
        public static let xdcam_HD422_720p50_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p50_CBR50)
        )
        public static let xdcam_HD422_720p60_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p60_CBR50)
        )
        public static let xdcam_HD422_1080i50_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080i50_CBR50)
        )
        public static let xdcam_HD422_1080i60_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080i60_CBR50)
        )
        public static let xdcam_HD422_1080p24_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080p24_CBR50)
        )
        public static let xdcam_HD422_1080p25_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080p25_CBR50)
        )
        public static let xdcam_HD422_1080p30_CBR50 = MPEG2VideoProfile(
            rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080p30_CBR50)
        )
        public static let xf = MPEG2VideoProfile(rawValue: UInt32(bitPattern: kCMMPEG2VideoProfile_XF))
    }

    public struct TextJustification: RawRepresentable, Hashable, Sendable {
        public typealias RawValue = CMTextJustificationValue
        public var rawValue: CMTextJustificationValue
        public init(rawValue: CMTextJustificationValue) { self.rawValue = rawValue }
        public static let left = TextJustification(rawValue: kCMTextJustification_left_top)
        public static let top = TextJustification(rawValue: kCMTextJustification_left_top)
        public static let centered = TextJustification(rawValue: kCMTextJustification_centered)
        public static let right = TextJustification(rawValue: kCMTextJustification_bottom_right)
        public static let bottom = TextJustification(rawValue: kCMTextJustification_bottom_right)
    }

    public struct TextDisplayFlags: OptionSet, Hashable, Sendable {
        public let rawValue: CMTextDisplayFlags
        public init(rawValue: CMTextDisplayFlags) { self.rawValue = rawValue }
        public static let scrollIn = TextDisplayFlags(rawValue: kCMTextDisplayFlag_scrollIn)
        public static let scrollOut = TextDisplayFlags(rawValue: kCMTextDisplayFlag_scrollOut)
        public static let scrollDirectionMask = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_scrollDirectionMask
        )
        public static let scrollDirection_bottomToTop = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_scrollDirection_bottomToTop
        )
        public static let scrollDirection_rightToLeft = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_scrollDirection_rightToLeft
        )
        public static let scrollDirection_topToBottom = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_scrollDirection_topToBottom
        )
        public static let scrollDirection_leftToRight = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_scrollDirection_leftToRight
        )
        public static let continuousKaraoke = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_continuousKaraoke
        )
        public static let writeTextVertically = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_writeTextVertically
        )
        public static let fillTextRegion = TextDisplayFlags(rawValue: kCMTextDisplayFlag_fillTextRegion)
        public static let obeySubtitleFormatting = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_obeySubtitleFormatting
        )
        public static let forcedSubtitlesPresent = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_forcedSubtitlesPresent
        )
        public static let allSubtitlesForced = TextDisplayFlags(
            rawValue: kCMTextDisplayFlag_allSubtitlesForced
        )
    }

    public struct FontFace: OptionSet, Hashable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let bold = FontFace(rawValue: 1 << 0)
        public static let italic = FontFace(rawValue: 1 << 1)
        public static let underline = FontFace(rawValue: 1 << 2)
        public static let all: FontFace = [.bold, .italic, .underline]
    }

    public static func fieldDetail(_ fieldDetail: FieldDetail) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(fieldDetail.rawValue)
    }
    public static func yCbCrMatrix(_ matrix: YCbCrMatrix) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(matrix.rawValue)
    }
    public static func colorPrimaries(_ primaries: ColorPrimaries) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(primaries.rawValue)
    }
    public static func transferFunction(_ function: TransferFunction) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(function.rawValue)
    }
    public static func chromaLocation(_ location: ChromaLocation) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(location.rawValue)
    }
    public static func projectionKind(_ kind: ProjectionKind) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(kind.rawValue)
    }
    public static func viewPackingKind(_ kind: ViewPackingKind) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(kind.rawValue)
    }
    public static func alphaChannelMode(_ mode: AlphaChannelMode) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(mode.rawValue)
    }
    public static func logTransferFunction(
        _ function: LogTransferFunction
    ) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(function.rawValue)
    }
    public static func vendor(_ vendor: Vendor) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(vendor.rawValue)
    }
    public static func heroEye(_ eye: HeroEye) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(eye.rawValue)
    }
    public static func string(_ string: String) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(cmMakeCFString(string))
    }
    public static func number(_ number: Int) -> CMFormatDescription.Extensions.Value {
        var value = Int64(number)
        return CMFormatDescription.Extensions.Value(
            CFNumberCreate(kCFAllocatorDefault, .sInt64Type, &value)!
        )
    }
    public static func data(_ data: Data) -> CMFormatDescription.Extensions.Value {
        data.withUnsafeBytes { bytes in
            CMFormatDescription.Extensions.Value(
                CFDataCreate(kCFAllocatorDefault, bytes.bindMemory(to: UInt8.self).baseAddress, CFIndex(data.count))!
            )
        }
    }
}

extension CMFormatDescription.Extensions {
    public struct Index: Comparable, Hashable, Sendable {
        public var rawValue: Int
        public init(_ rawValue: Int = 0) { self.rawValue = rawValue }
        public static func < (lhs: Index, rhs: Index) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public typealias Element = (key: Key, value: Value)
    public typealias SubSequence = ArraySlice<Element>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<[(key: Key, value: Value)]>

    public var startIndex: Index { Index(0) }
    public var endIndex: Index { Index(0) }

    public func index(after i: Index) -> Index { Index(i.rawValue + 1) }

    public subscript(position: Index) -> Element {
        (key: .formatName, value: Value())
    }

    public subscript(key: Key) -> Value? {
        get { nil }
        set { _ = newValue }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(0)
    }
}

extension CMSampleBuffer {
    public struct AttachmentKey: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let displayEmptyMediaImmediately = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_DisplayEmptyMediaImmediately
        )
        public static let permanentEmptyMedia = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_PermanentEmptyMedia
        )
        public static let emptyMedia = AttachmentKey(rawValue: kCMSampleBufferAttachmentKey_EmptyMedia)
        public static let forceKeyFrame = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_ForceKeyFrame
        )
        public static let resumeOutput = AttachmentKey(rawValue: kCMSampleBufferAttachmentKey_ResumeOutput)
        public static let transitionID = AttachmentKey(rawValue: kCMSampleBufferAttachmentKey_TransitionID)
        public static let speedMultiplier = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_SpeedMultiplier
        )
        public static let trimDurationAtEnd = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_TrimDurationAtEnd
        )
        public static let drainAfterDecoding = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_DrainAfterDecoding
        )
        public static let droppedFrameReason = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_DroppedFrameReason
        )
        public static let sampleReferenceURL = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_SampleReferenceURL
        )
        public static let trimDurationAtStart = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_TrimDurationAtStart
        )
        public static let cameraIntrinsicMatrix = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix
        )
        public static let gradualDecoderRefresh = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_GradualDecoderRefresh
        )
        public static let droppedFrameReasonInfo = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_DroppedFrameReasonInfo
        )
        public static let sampleReferenceByteOffset = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_SampleReferenceByteOffset
        )
        public static let endsPreviousSampleDuration = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_EndsPreviousSampleDuration
        )
        public static let resetDecoderBeforeDecoding = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_ResetDecoderBeforeDecoding
        )
        public static let postNotificationWhenConsumed = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_PostNotificationWhenConsumed
        )
        public static let fillDiscontinuitiesWithSilence = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_FillDiscontinuitiesWithSilence
        )
        public static let stillImageLensStabilizationInfo = AttachmentKey(
            rawValue: kCMSampleBufferAttachmentKey_StillImageLensStabilizationInfo
        )
        public static let reverse = AttachmentKey(rawValue: kCMSampleBufferAttachmentKey_Reverse)
        public static func == (lhs: AttachmentKey, rhs: AttachmentKey) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(unsafeBitCast(rawValue, to: NSString.self) as String)
        }
    }
}
