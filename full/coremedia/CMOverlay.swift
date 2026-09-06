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

        public var scrollDirection: TextDisplayFlags {
            TextDisplayFlags(rawValue: rawValue & kCMTextDisplayFlag_scrollDirectionMask)
        }
    }

    public struct FontFace: OptionSet, Hashable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let bold = FontFace(rawValue: 1 << 0)
        public static let italic = FontFace(rawValue: 1 << 1)
        public static let underline = FontFace(rawValue: 1 << 2)
        public static let all: FontFace = [.bold, .italic, .underline]
    }

    public struct ContentColorVolume: Hashable {
        public typealias RawValue = CMFormatDescription.Extensions.Value

        @frozen
        public struct ColorVolume: Hashable {
            public var green: Int32
            public var blue: Int32
            public var red: Int32

            public init(green: Int32, blue: Int32, red: Int32) {
                self.green = green
                self.blue = blue
                self.red = red
            }
        }

        @frozen
        public struct ColorPrimaries: Hashable {
            public var x: ColorVolume
            public var y: ColorVolume

            public init(x: ColorVolume, y: ColorVolume) {
                self.x = x
                self.y = y
            }
        }

        public var colorPrimaries: ColorPrimaries?
        public var minimumLuminance: UInt32?
        public var maximumLuminance: UInt32?
        public var averageLuminance: UInt32?

        public init(
            colorPrimaries: ColorPrimaries? = nil,
            minimumLuminance: UInt32? = nil,
            maximumLuminance: UInt32? = nil,
            averageLuminance: UInt32? = nil
        ) {
            self.colorPrimaries = colorPrimaries
            self.minimumLuminance = minimumLuminance
            self.maximumLuminance = maximumLuminance
            self.averageLuminance = averageLuminance
        }

        public var rawValue: CMFormatDescription.Extensions.Value {
            .number(Int(maximumLuminance ?? 0))
        }

        public init?(rawValue: CMFormatDescription.Extensions.Value) {
            _ = rawValue
            return nil
        }
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

    public static func qtTextColor(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat
    ) -> CMFormatDescription.Extensions.Value {
        cmTextColorValue(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static func mobile3GPPTextColor(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat
    ) -> CMFormatDescription.Extensions.Value {
        cmTextColorValue(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static func textDisplayFlags(
        _ textDisplayFlags: Set<TextDisplayFlags>
    ) -> CMFormatDescription.Extensions.Value {
        var raw: CMTextDisplayFlags = 0
        for flag in textDisplayFlags {
            raw |= flag.rawValue
        }
        var stored = Int32(bitPattern: raw)
        return CMFormatDescription.Extensions.Value(
            CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &stored)!
        )
    }

    public static func mpeg2VideoProfile(
        _ mpeg2VideoProfile: MPEG2VideoProfile
    ) -> CMFormatDescription.Extensions.Value {
        .number(Int(bitPattern: UInt(mpeg2VideoProfile.rawValue)))
    }

    public static func textRect(
        top: Int,
        left: Int,
        bottom: Int,
        right: Int
    ) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(
            cmCFDictionary([
                (kCMTextFormatDescriptionRect_Top, cmCFNumberFromNumeric(top)),
                (kCMTextFormatDescriptionRect_Left, cmCFNumberFromNumeric(left)),
                (kCMTextFormatDescriptionRect_Bottom, cmCFNumberFromNumeric(bottom)),
                (kCMTextFormatDescriptionRect_Right, cmCFNumberFromNumeric(right))
            ])
        )
    }

    public static func qtTextDefaultStyle(
        startChar: Int,
        height: Int,
        ascent: Int,
        localFontID: Int,
        fontFace: FontFace,
        fontSize: Int,
        foregroundColor: CMFormatDescription.Extensions.Value,
        defaultFontName: String?
    ) -> CMFormatDescription.Extensions.Value {
        var pairs: [(CFString, CFTypeRef)] = [
            (kCMTextFormatDescriptionStyle_StartChar, cmCFNumberFromNumeric(startChar)),
            (kCMTextFormatDescriptionStyle_Height, cmCFNumberFromNumeric(height)),
            (kCMTextFormatDescriptionStyle_Ascent, cmCFNumberFromNumeric(ascent)),
            (kCMTextFormatDescriptionStyle_Font, cmCFNumberFromNumeric(localFontID)),
            (kCMTextFormatDescriptionStyle_FontFace, cmCFNumberFromNumeric(Int(fontFace.rawValue))),
            (kCMTextFormatDescriptionStyle_FontSize, cmCFNumberFromNumeric(fontSize)),
        ]
        if let stored = foregroundColor.stored {
            pairs.append((kCMTextFormatDescriptionStyle_ForegroundColor, stored))
        }
        if let defaultFontName {
            pairs.append((kCMTextFormatDescriptionExtension_DefaultFontName, cmMakeCFString(defaultFontName)))
        }
        return CMFormatDescription.Extensions.Value(cmCFDictionary(pairs))
    }

    public static func mobile3GPPTextDefaultStyle(
        startChar: Int,
        endChar: Int,
        localFontID: Int,
        fontFace: FontFace,
        fontSize: Int,
        foregroundColor: CMFormatDescription.Extensions.Value
    ) -> CMFormatDescription.Extensions.Value {
        var pairs: [(CFString, CFTypeRef)] = [
            (kCMTextFormatDescriptionStyle_StartChar, cmCFNumberFromNumeric(startChar)),
            (kCMTextFormatDescriptionStyle_EndChar, cmCFNumberFromNumeric(endChar)),
            (kCMTextFormatDescriptionStyle_Font, cmCFNumberFromNumeric(localFontID)),
            (kCMTextFormatDescriptionStyle_FontFace, cmCFNumberFromNumeric(Int(fontFace.rawValue))),
            (kCMTextFormatDescriptionStyle_FontSize, cmCFNumberFromNumeric(fontSize))
        ]
        if let stored = foregroundColor.stored {
            pairs.append((kCMTextFormatDescriptionStyle_ForegroundColor, stored))
        }
        return CMFormatDescription.Extensions.Value(cmCFDictionary(pairs))
    }

    public enum CameraCalibrationDataLensCollection {
        public typealias RawValue = CFArray

        public enum LensRole: RawRepresentable, Hashable {
            public typealias RawValue = CFString
            case mono
            case left
            case right

            public init?(rawValue: CFString) {
                if CFEqual(rawValue, kCMFormatDescriptionCameraCalibrationLensRole_Mono) {
                    self = .mono
                } else if CFEqual(rawValue, kCMFormatDescriptionCameraCalibrationLensRole_Left) {
                    self = .left
                } else if CFEqual(rawValue, kCMFormatDescriptionCameraCalibrationLensRole_Right) {
                    self = .right
                } else {
                    return nil
                }
            }

            public var rawValue: CFString {
                switch self {
                case .mono: return kCMFormatDescriptionCameraCalibrationLensRole_Mono
                case .left: return kCMFormatDescriptionCameraCalibrationLensRole_Left
                case .right: return kCMFormatDescriptionCameraCalibrationLensRole_Right
                }
            }
        }

        public enum LensDomain: RawRepresentable, Hashable {
            public typealias RawValue = CFString
            case color

            public init?(rawValue: CFString) {
                if CFEqual(rawValue, kCMFormatDescriptionCameraCalibrationLensDomain_Color) {
                    self = .color
                } else {
                    return nil
                }
            }

            public var rawValue: CFString { kCMFormatDescriptionCameraCalibrationLensDomain_Color }
        }

        public enum AlgorithmKind: RawRepresentable, Hashable {
            public typealias RawValue = CFString
            case parametric

            public init?(rawValue: CFString) {
                if CFEqual(rawValue, kCMFormatDescriptionCameraCalibrationLensAlgorithmKind_ParametricLens) {
                    self = .parametric
                } else {
                    return nil
                }
            }

            public var rawValue: CFString {
                kCMFormatDescriptionCameraCalibrationLensAlgorithmKind_ParametricLens
            }
        }

        public enum ExtrinsicOriginSource: RawRepresentable, Hashable {
            public typealias RawValue = CFString
            case stereoCameraSystemBaseline

            public init?(rawValue: CFString) {
                if CFEqual(
                    rawValue,
                    kCMFormatDescriptionCameraCalibrationExtrinsicOriginSource_StereoCameraSystemBaseline
                ) {
                    self = .stereoCameraSystemBaseline
                } else {
                    return nil
                }
            }

            public var rawValue: CFString {
                kCMFormatDescriptionCameraCalibrationExtrinsicOriginSource_StereoCameraSystemBaseline
            }
        }

        public struct Calibration {
            public typealias RawValue = CFDictionary
            public var algorithmKind: AlgorithmKind
            public var identifier: Int32
            public var domain: LensDomain
            public var role: LensRole
            public var distortionCoefficients: SIMD4<Float>
            public var xFrameAdjustmentsPolynomial: SIMD3<Float>
            public var yFrameAdjustmentsPolynomial: SIMD3<Float>
            public var radialAngleLimit: Float
            public var intrinsicMatrixProjectionOffset: Float
            public var intrinsicMatrixReferenceDimensions: CGSize
            public var extrinsicOriginSource: ExtrinsicOriginSource
            public var extrinsicOrientationQuaternion: SIMD3<Float>

            public init(
                algorithmKind: AlgorithmKind,
                identifier: Int32,
                domain: LensDomain,
                role: LensRole,
                distortionCoefficients: SIMD4<Float> = .zero,
                xFrameAdjustmentsPolynomial: SIMD3<Float> = .zero,
                yFrameAdjustmentsPolynomial: SIMD3<Float> = .zero,
                radialAngleLimit: Float = 0,
                intrinsicMatrixProjectionOffset: Float = 0,
                intrinsicMatrixReferenceDimensions: CGSize = .zero,
                extrinsicOriginSource: ExtrinsicOriginSource = .stereoCameraSystemBaseline,
                extrinsicOrientationQuaternion: SIMD3<Float> = .zero
            ) {
                self.algorithmKind = algorithmKind
                self.identifier = identifier
                self.domain = domain
                self.role = role
                self.distortionCoefficients = distortionCoefficients
                self.xFrameAdjustmentsPolynomial = xFrameAdjustmentsPolynomial
                self.yFrameAdjustmentsPolynomial = yFrameAdjustmentsPolynomial
                self.radialAngleLimit = radialAngleLimit
                self.intrinsicMatrixProjectionOffset = intrinsicMatrixProjectionOffset
                self.intrinsicMatrixReferenceDimensions = intrinsicMatrixReferenceDimensions
                self.extrinsicOriginSource = extrinsicOriginSource
                self.extrinsicOrientationQuaternion = extrinsicOrientationQuaternion
            }

            public init?(rawValue: CFDictionary) {
                self.init(
                    algorithmKind: .parametric,
                    identifier: 0,
                    domain: .color,
                    role: .mono
                )
                _ = rawValue
            }

            public var rawValue: CFDictionary {
                cmCFDictionary([
                    (kCMFormatDescriptionCameraCalibration_LensIdentifier, cmCFNumberFromNumeric(Int(identifier))),
                    (kCMFormatDescriptionCameraCalibration_LensRole, role.rawValue),
                    (kCMFormatDescriptionCameraCalibration_LensDomain, domain.rawValue),
                    (kCMFormatDescriptionCameraCalibration_LensAlgorithmKind, algorithmKind.rawValue),
                    (
                        kCMFormatDescriptionCameraCalibration_ExtrinsicOriginSource,
                        extrinsicOriginSource.rawValue
                    )
                ])
            }
        }

        case mono(Calibration)
        case stereo(left: Calibration, right: Calibration)

        public init?(rawValue: CFArray) {
            let count = CFArrayGetCount(rawValue)
            if count == 1 {
                self = .mono(Calibration(algorithmKind: .parametric, identifier: 0, domain: .color, role: .mono))
            } else if count >= 2 {
                self = .stereo(
                    left: Calibration(algorithmKind: .parametric, identifier: 0, domain: .color, role: .left),
                    right: Calibration(algorithmKind: .parametric, identifier: 1, domain: .color, role: .right)
                )
            } else {
                return nil
            }
        }

        public var rawValue: CFArray {
            let calibrations: [Calibration]
            switch self {
            case .mono(let calibration):
                calibrations = [calibration]
            case .stereo(let left, let right):
                calibrations = [left, right]
            }
            let array = CFArrayCreateMutable(kCFAllocatorDefault, CFIndex(calibrations.count), nil)!
            for calibration in calibrations {
                CFArrayAppendValue(array, unsafeBitCast(calibration.rawValue, to: UnsafeRawPointer.self))
            }
            return array
        }
    }
}

private func cmTextColorValue(
    red: CGFloat,
    green: CGFloat,
    blue: CGFloat,
    alpha: CGFloat
) -> CMFormatDescription.Extensions.Value {
    CMFormatDescription.Extensions.Value(
        cmCFDictionary([
            (kCMTextFormatDescriptionColor_Red, cmCFNumberFromNumeric(red)),
            (kCMTextFormatDescriptionColor_Green, cmCFNumberFromNumeric(green)),
            (kCMTextFormatDescriptionColor_Blue, cmCFNumberFromNumeric(blue)),
            (kCMTextFormatDescriptionColor_Alpha, cmCFNumberFromNumeric(alpha))
        ])
    )
}

extension CMFormatDescription.Extensions {
    public struct Index: Comparable, Hashable, Sendable {
        public var rawValue: Int
        public init(_ rawValue: Int = 0) { self.rawValue = rawValue }
        public static func < (lhs: Index, rhs: Index) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public typealias Element = (key: Key, value: Value)

    public var startIndex: Index { Index(0) }
    public var endIndex: Index { Index(pairs.count) }

    public func index(after i: Index) -> Index { Index(i.rawValue + 1) }

    public subscript(position: Index) -> Element {
        let pair = pairs[position.rawValue]
        return (key: pair.0, value: pair.1)
    }

    public subscript(key: Key) -> Value? {
        get {
            pairs.first(where: { $0.0.rawValue == key.rawValue })?.1
        }
        set {
            if let index = pairs.firstIndex(where: { $0.0.rawValue == key.rawValue }) {
                if let newValue {
                    pairs[index] = (key, newValue)
                } else {
                    pairs.remove(at: index)
                }
            } else if let newValue {
                pairs.append((key, newValue))
            }
        }
    }

    public subscript(key: CFString) -> CFPropertyList? {
        get {
            let name = unsafeBitCast(key, to: NSString.self) as String
            return self[Key(rawValue: name)]?.stored
        }
        set {
            let name = unsafeBitCast(key, to: NSString.self) as String
            self[Key(rawValue: name)] = newValue.map { Value($0 as CFTypeRef) }
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(pairs.count)
        for (key, _) in pairs {
            hasher.combine(key.rawValue)
        }
    }
}

extension CMFormatDescription.Extensions: BidirectionalCollection {
    public func index(before i: Index) -> Index {
        Index(i.rawValue - 1)
    }
}

extension CMFormatDescription {
    public func presentationDimensions(
        usePixelAspectRatio: Bool = true,
        useCleanAperture: Bool = true
    ) -> CGSize {
        CMVideoFormatDescriptionGetPresentationDimensions(
            self,
            usePixelAspectRatio: usePixelAspectRatio,
            useCleanAperture: useCleanAperture
        )
    }

    public static var extensionKeysCommonWithImageBuffers: [Extensions.Key] {
        let array = CMVideoFormatDescriptionGetExtensionKeysCommonWithImageBuffers()
        let count = Int(CFArrayGetCount(array))
        var keys: [Extensions.Key] = []
        keys.reserveCapacity(count)
        for index in 0..<count {
            guard let pointer = CFArrayGetValueAtIndex(array, CFIndex(index)) else { continue }
            let string = unsafeBitCast(pointer, to: NSString.self) as String
            keys.append(Extensions.Key(rawValue: string))
        }
        return keys
    }

    public func fontName(localFontID: Int) throws -> String {
        var name: CFString?
        let status = CMTextFormatDescriptionGetFontName(
            self,
            localFontID: UInt16(clamping: localFontID),
            fontNameOut: &name
        )
        if status != 0 { throw Error.valueNotAvailable }
        guard let name else { throw Error.valueNotAvailable }
        return unsafeBitCast(name, to: NSString.self) as String
    }

    public func keyWithLocalID(_ localKeyID: UInt32) -> [String: CFPropertyList]? {
        guard let dictionary = CMMetadataFormatDescriptionGetKeyWithLocalID(self, localKeyID: localKeyID) else {
            return nil
        }
        let count = Int(CFDictionaryGetCount(dictionary))
        if count <= 0 { return [:] }
        var keys = Array<UnsafeRawPointer?>(repeating: nil, count: count)
        var values = Array<UnsafeRawPointer?>(repeating: nil, count: count)
        keys.withUnsafeMutableBufferPointer { keyBuf in
            values.withUnsafeMutableBufferPointer { valBuf in
                CFDictionaryGetKeysAndValues(dictionary, keyBuf.baseAddress, valBuf.baseAddress)
            }
        }
        var result: [String: CFPropertyList] = [:]
        for index in 0..<count {
            guard let keyPtr = keys[index], let valPtr = values[index] else { continue }
            let name = unsafeBitCast(keyPtr, to: NSString.self) as String
            result[name] = unsafeBitCast(valPtr, to: CFPropertyList.self)
        }
        return result
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
