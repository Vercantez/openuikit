import CoreFoundation
import Foundation

public protocol CMAttachmentBearerProtocol: AnyObject {
    var attachments: CMAttachmentBearerAttachments { get }
}

internal final class CMAttachmentStorage {
    var map: [String: CMAttachmentBearerAttachments.Value] = [:]
}

public struct CMAttachmentBearerAttachments {
    public enum Mode: RawRepresentable, Equatable, Hashable, Sendable {
        public typealias RawValue = CMAttachmentMode
        case shouldNotPropagate
        case shouldPropagate

        public init?(rawValue: CMAttachmentMode) {
            switch rawValue {
            case kCMAttachmentMode_ShouldNotPropagate:
                self = .shouldNotPropagate
            case kCMAttachmentMode_ShouldPropagate:
                self = .shouldPropagate
            default:
                return nil
            }
        }

        public var rawValue: CMAttachmentMode {
            switch self {
            case .shouldNotPropagate: return kCMAttachmentMode_ShouldNotPropagate
            case .shouldPropagate: return kCMAttachmentMode_ShouldPropagate
            }
        }
    }

    public enum Value {
        case shouldNotPropagate(Any)
        case shouldPropagate(Any)

        public var mode: Mode {
            switch self {
            case .shouldNotPropagate: return .shouldNotPropagate
            case .shouldPropagate: return .shouldPropagate
            }
        }

        public var value: Any {
            switch self {
            case .shouldNotPropagate(let value), .shouldPropagate(let value):
                return value
            }
        }
    }

    private let box: CMAttachmentStorage

    public init() {
        self.box = CMAttachmentStorage()
    }

    public subscript(key: String) -> Value? {
        get { box.map[key] }
        nonmutating set {
            if let newValue {
                box.map[key] = newValue
            } else {
                box.map.removeValue(forKey: key)
            }
        }
    }

    public var propagated: [String: Any] {
        var result: [String: Any] = [:]
        for (key, entry) in box.map where entry.mode == .shouldPropagate {
            result[key] = entry.value
        }
        return result
    }

    public var nonPropagated: [String: Any] {
        var result: [String: Any] = [:]
        for (key, entry) in box.map where entry.mode == .shouldNotPropagate {
            result[key] = entry.value
        }
        return result
    }

    public func merge(_ attachments: [String: Any], mode: Mode) {
        for (key, value) in attachments {
            switch mode {
            case .shouldPropagate:
                box.map[key] = .shouldPropagate(value)
            case .shouldNotPropagate:
                box.map[key] = .shouldNotPropagate(value)
            }
        }
    }

    public func removeAll() {
        box.map.removeAll()
    }
}

extension CMAttachmentBearerProtocol {
    public func propagateAttachments<T: CMAttachmentBearerProtocol>(to destination: T) {
        destination.attachments.merge(attachments.propagated, mode: .shouldPropagate)
    }
}

public final class CMFormatDescription: CMAttachmentBearerProtocol, @unchecked Sendable {
    public struct MediaType: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
        public typealias RawValue = UInt32
        public var rawValue: CMMediaType

        public init(rawValue: CMMediaType) {
            self.rawValue = rawValue
        }

        public init(string: String) {
            self.rawValue = string.count == 4 ? cmFourCC(string) : 0
        }

        public var description: String { cmFourCCString(rawValue) }

        public static let video = MediaType(rawValue: kCMMediaType_Video)
        public static let audio = MediaType(rawValue: kCMMediaType_Audio)
        public static let muxed = MediaType(rawValue: kCMMediaType_Muxed)
        public static let text = MediaType(rawValue: kCMMediaType_Text)
        public static let closedCaption = MediaType(rawValue: kCMMediaType_ClosedCaption)
        public static let subtitle = MediaType(rawValue: kCMMediaType_Subtitle)
        public static let timeCode = MediaType(rawValue: kCMMediaType_TimeCode)
        public static let metadata = MediaType(rawValue: kCMMediaType_Metadata)
        public static let taggedBufferGroup = MediaType(rawValue: kCMMediaType_TaggedBufferGroup)
    }

    public struct MediaSubType: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
        public typealias RawValue = UInt32
        public var rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public init(string: String) {
            self.rawValue = string.count == 4 ? cmFourCC(string) : 0
        }

        public var description: String { cmFourCCString(rawValue) }

        public static let h264 = MediaSubType(rawValue: kCMVideoCodecType_H264)
        public static let hevc = MediaSubType(rawValue: kCMVideoCodecType_HEVC)
        public static let hevcWithAlpha = MediaSubType(rawValue: kCMVideoCodecType_HEVCWithAlpha)
        public static let jpeg = MediaSubType(rawValue: kCMVideoCodecType_JPEG)
        public static let jpeg_OpenDML = MediaSubType(rawValue: kCMVideoCodecType_JPEG_OpenDML)
        public static let mpeg4Video = MediaSubType(rawValue: kCMVideoCodecType_MPEG4Video)
        public static let mpeg2Video = MediaSubType(rawValue: kCMVideoCodecType_MPEG2Video)
        public static let mpeg1Video = MediaSubType(rawValue: kCMVideoCodecType_MPEG1Video)
        public static let h263 = MediaSubType(rawValue: kCMVideoCodecType_H263)
        public static let animation = MediaSubType(rawValue: kCMVideoCodecType_Animation)
        public static let cinepak = MediaSubType(rawValue: kCMVideoCodecType_Cinepak)
        public static let sorensonVideo = MediaSubType(rawValue: kCMVideoCodecType_SorensonVideo)
        public static let sorensonVideo3 = MediaSubType(rawValue: kCMVideoCodecType_SorensonVideo3)
        public static let proRes422 = MediaSubType(rawValue: kCMVideoCodecType_AppleProRes422)
        public static let proRes422HQ = MediaSubType(rawValue: kCMVideoCodecType_AppleProRes422HQ)
        public static let proRes422LT = MediaSubType(rawValue: kCMVideoCodecType_AppleProRes422LT)
        public static let proRes422Proxy = MediaSubType(rawValue: kCMVideoCodecType_AppleProRes422Proxy)
        public static let proRes4444 = MediaSubType(rawValue: kCMVideoCodecType_AppleProRes4444)
        public static let proRes4444XQ = MediaSubType(rawValue: kCMVideoCodecType_AppleProRes4444XQ)
        public static let proResRAW = MediaSubType(rawValue: kCMVideoCodecType_AppleProResRAW)
        public static let proResRAWHQ = MediaSubType(rawValue: kCMVideoCodecType_AppleProResRAWHQ)
        public static let dvcNTSC = MediaSubType(rawValue: kCMVideoCodecType_DVCNTSC)
        public static let dvcPAL = MediaSubType(rawValue: kCMVideoCodecType_DVCPAL)
        public static let dvcProPAL = MediaSubType(rawValue: kCMVideoCodecType_DVCProPAL)
        public static let dvcPro50NTSC = MediaSubType(rawValue: kCMVideoCodecType_DVCPro50NTSC)
        public static let dvcPro50PAL = MediaSubType(rawValue: kCMVideoCodecType_DVCPro50PAL)
        public static let dvcPROHD720p60 = MediaSubType(rawValue: kCMVideoCodecType_DVCPROHD720p60)
        public static let dvcPROHD720p50 = MediaSubType(rawValue: kCMVideoCodecType_DVCPROHD720p50)
        public static let dvcPROHD1080i60 = MediaSubType(rawValue: kCMVideoCodecType_DVCPROHD1080i60)
        public static let dvcPROHD1080i50 = MediaSubType(rawValue: kCMVideoCodecType_DVCPROHD1080i50)
        public static let dvcPROHD1080p30 = MediaSubType(rawValue: kCMVideoCodecType_DVCPROHD1080p30)
        public static let dvcPROHD1080p25 = MediaSubType(rawValue: kCMVideoCodecType_DVCPROHD1080p25)
        public static let pixelFormat_32ARGB = MediaSubType(rawValue: kCMPixelFormat_32ARGB)
        public static let pixelFormat_32BGRA = MediaSubType(rawValue: kCMPixelFormat_32BGRA)
        public static let pixelFormat_24RGB = MediaSubType(rawValue: kCMPixelFormat_24RGB)
        public static let pixelFormat_16BE555 = MediaSubType(rawValue: kCMPixelFormat_16BE555)
        public static let pixelFormat_16BE565 = MediaSubType(rawValue: kCMPixelFormat_16BE565)
        public static let pixelFormat_16LE555 = MediaSubType(rawValue: kCMPixelFormat_16LE555)
        public static let pixelFormat_16LE565 = MediaSubType(rawValue: kCMPixelFormat_16LE565)
        public static let pixelFormat_16LE5551 = MediaSubType(rawValue: kCMPixelFormat_16LE5551)
        public static let pixelFormat_422YpCbCr8 = MediaSubType(rawValue: kCMPixelFormat_422YpCbCr8)
        public static let pixelFormat_422YpCbCr8_yuvs = MediaSubType(rawValue: kCMPixelFormat_422YpCbCr8_yuvs)
        public static let pixelFormat_444YpCbCr8 = MediaSubType(rawValue: kCMPixelFormat_444YpCbCr8)
        public static let pixelFormat_4444YpCbCrA8 = MediaSubType(rawValue: kCMPixelFormat_4444YpCbCrA8)
        public static let pixelFormat_422YpCbCr16 = MediaSubType(rawValue: kCMPixelFormat_422YpCbCr16)
        public static let pixelFormat_422YpCbCr10 = MediaSubType(rawValue: kCMPixelFormat_422YpCbCr10)
        public static let pixelFormat_444YpCbCr10 = MediaSubType(rawValue: kCMPixelFormat_444YpCbCr10)
        public static let pixelFormat_8IndexedGray_WhiteIsZero = MediaSubType(
            rawValue: kCMPixelFormat_8IndexedGray_WhiteIsZero
        )
        public static let mpeg1System = MediaSubType(rawValue: kCMMuxedStreamType_MPEG1System)
        public static let mpeg2Transport = MediaSubType(rawValue: kCMMuxedStreamType_MPEG2Transport)
        public static let mpeg2Program = MediaSubType(rawValue: kCMMuxedStreamType_MPEG2Program)
        public static let dv = MediaSubType(rawValue: kCMMuxedStreamType_DV)
        public static let embeddedDeviceScreenRecording = MediaSubType(
            rawValue: kCMMuxedStreamType_EmbeddedDeviceScreenRecording
        )
        public static let cea608 = MediaSubType(rawValue: kCMClosedCaptionFormatType_CEA608)
        public static let cea708 = MediaSubType(rawValue: kCMClosedCaptionFormatType_CEA708)
        public static let atsc = MediaSubType(rawValue: kCMClosedCaptionFormatType_ATSC)
        public static let mobile3GPP = MediaSubType(rawValue: kCMSubtitleFormatType_3GText)
        public static let webVTT = MediaSubType(rawValue: kCMSubtitleFormatType_WebVTT)
        public static let qt = MediaSubType(rawValue: kCMTextFormatType_QTText)
        public static let timeCode32 = MediaSubType(rawValue: kCMTimeCodeFormatType_TimeCode32)
        public static let timeCode64 = MediaSubType(rawValue: kCMTimeCodeFormatType_TimeCode64)
        public static let counter32 = MediaSubType(rawValue: kCMTimeCodeFormatType_Counter32)
        public static let counter64 = MediaSubType(rawValue: kCMTimeCodeFormatType_Counter64)
        public static let icy = MediaSubType(rawValue: kCMMetadataFormatType_ICY)
        public static let id3 = MediaSubType(rawValue: kCMMetadataFormatType_ID3)
        public static let boxed = MediaSubType(rawValue: kCMMetadataFormatType_Boxed)
        public static let emsg = MediaSubType(rawValue: kCMMetadataFormatType_EMSG)
        public static let tbgr = MediaSubType(rawValue: kCMMediaType_TaggedBufferGroup)
        public static let aacLCProtected = MediaSubType(rawValue: kCMAudioCodecType_AAC_LCProtected)
        public static let aacAudibleProtected = MediaSubType(
            rawValue: kCMAudioCodecType_AAC_AudibleProtected
        )
        public static let linearPCM = MediaSubType(rawValue: cmFourCC("lpcm"))
        public static let mpeg4AAC = MediaSubType(rawValue: cmFourCC("aac "))
        public static let mpeg4AAC_HE = MediaSubType(rawValue: cmFourCC("aach"))
        public static let mpeg4AAC_LD = MediaSubType(rawValue: cmFourCC("aacl"))
        public static let mpeg4AAC_ELD = MediaSubType(rawValue: cmFourCC("aace"))
        public static let mpeg4AAC_ELD_SBR = MediaSubType(rawValue: cmFourCC("aacf"))
        public static let mpeg4AAC_ELD_V2 = MediaSubType(rawValue: cmFourCC("aacg"))
        public static let mpeg4AAC_HE_V2 = MediaSubType(rawValue: cmFourCC("aacp"))
        public static let mpeg4AAC_Spatial = MediaSubType(rawValue: cmFourCC("aacs"))
        public static let mpeg4CELP = MediaSubType(rawValue: cmFourCC("celp"))
        public static let mpeg4HVXC = MediaSubType(rawValue: cmFourCC("hvxc"))
        public static let mpeg4TwinVQ = MediaSubType(rawValue: cmFourCC("twvq"))
        public static let mpegLayer1 = MediaSubType(rawValue: cmFourCC(".mp1"))
        public static let mpegLayer2 = MediaSubType(rawValue: cmFourCC(".mp2"))
        public static let mpegLayer3 = MediaSubType(rawValue: cmFourCC(".mp3"))
        public static let appleLossless = MediaSubType(rawValue: cmFourCC("alac"))
        public static let flac = MediaSubType(rawValue: cmFourCC("flac"))
        public static let opus = MediaSubType(rawValue: cmFourCC("opus"))
        public static let ac3 = MediaSubType(rawValue: cmFourCC("ac-3"))
        public static let enhancedAC3 = MediaSubType(rawValue: cmFourCC("ec-3"))
        public static let iec60958AC3 = MediaSubType(rawValue: cmFourCC("cac3"))
        public static let amr = MediaSubType(rawValue: cmFourCC("samr"))
        public static let amr_WB = MediaSubType(rawValue: cmFourCC("sawb"))
        public static let iLBC = MediaSubType(rawValue: cmFourCC("ilbc"))
        public static let uLaw = MediaSubType(rawValue: cmFourCC("ulaw"))
        public static let aLaw = MediaSubType(rawValue: cmFourCC("alaw"))
        public static let appleIMA4 = MediaSubType(rawValue: cmFourCC("ima4"))
        public static let dviIntelIMA = MediaSubType(rawValue: 0x6D730011)
        public static let microsoftGSM = MediaSubType(rawValue: 0x6D730031)
        public static let aes3 = MediaSubType(rawValue: cmFourCC("aes3"))
        public static let midiStream = MediaSubType(rawValue: cmFourCC("midi"))
        public static let parameterValueStream = MediaSubType(rawValue: cmFourCC("apvs"))
        public static let mpegD_USAC = MediaSubType(rawValue: cmFourCC("usac"))
        public static let mace3 = MediaSubType(rawValue: cmFourCC("MAC3"))
        public static let mace6 = MediaSubType(rawValue: cmFourCC("MAC6"))
        public static let qDesign = MediaSubType(rawValue: cmFourCC("QDMC"))
        public static let qDesign2 = MediaSubType(rawValue: cmFourCC("QDM2"))
        public static let qualcomm = MediaSubType(rawValue: cmFourCC("Qclp"))
        public static let audible = MediaSubType(rawValue: cmFourCC("AUDB"))
        public static let timeCode = MediaSubType(rawValue: kCMTimeCodeFormatType_TimeCode32)
    }

    public struct Extensions: Equatable {
        public struct Key: RawRepresentable, Hashable, Sendable {
            public typealias RawValue = String
            public var rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }

            public static let formatName = Key(rawValue: "FormatName")
            public static let depth = Key(rawValue: "Depth")
            public static let vendor = Key(rawValue: "Vendor")
            public static let version = Key(rawValue: "Version")
            public static let revisionLevel = Key(rawValue: "RevisionLevel")
            public static let spatialQuality = Key(rawValue: "SpatialQuality")
            public static let temporalQuality = Key(rawValue: "TemporalQuality")
            public static let fieldCount = Key(rawValue: "FieldCount")
            public static let fieldDetail = Key(rawValue: "FieldDetail")
            public static let pixelAspectRatio = Key(rawValue: "PixelAspectRatio")
            public static let cleanAperture = Key(rawValue: "CleanAperture")
            public static let colorPrimaries = Key(rawValue: "ColorPrimaries")
            public static let transferFunction = Key(rawValue: "TransferFunction")
            public static let yCbCrMatrix = Key(rawValue: "YCbCrMatrix")
            public static let gammaLevel = Key(rawValue: "GammaLevel")
            public static let iccProfile = Key(rawValue: "ICCProfile")
            public static let bytesPerRow = Key(rawValue: "BytesPerRow")
            public static let bitsPerComponent = Key(rawValue: "BitsPerComponent")
            public static let fullRangeVideo = Key(rawValue: "FullRangeVideo")
            public static let containsAlphaChannel = Key(rawValue: "ContainsAlphaChannel")
            public static let alphaChannelMode = Key(rawValue: "AlphaChannelMode")
            public static let sampleDescriptionExtensionAtoms = Key(rawValue: "SampleDescriptionExtensionAtoms")
            public static let originalCompressionSettings = Key(rawValue: "OriginalCompressionSettings")
            public static let verbatimSampleDescription = Key(rawValue: "VerbatimSampleDescription")
            public static let verbatimImageDescription = Key(rawValue: "VerbatimImageDescription")
            public static let verbatimISOSampleEntry = Key(rawValue: "VerbatimISOSampleEntry")
            public static let metadataKeyTable = Key(rawValue: "MetadataKeyTable")
            public static let defaultStyle = Key(rawValue: "DefaultStyle")
            public static let displayFlags = Key(rawValue: "DisplayFlags")
            public static let defaultTextBox = Key(rawValue: "DefaultTextBox")
            public static let backgroundColor = Key(rawValue: "BackgroundColor")
            public static let defaultFontName = Key(rawValue: "DefaultFontName")
            public static let fontTable = Key(rawValue: "FontTable")
            public static let horizontalJustification = Key(rawValue: "HorizontalJustification")
            public static let verticalJustification = Key(rawValue: "VerticalJustification")
            public static let textJustification = Key(rawValue: "TextJustification")
            public static let projectionKind = Key(rawValue: "ProjectionKind")
            public static let viewPackingKind = Key(rawValue: "ViewPackingKind")
            public static let hasAdditionalViews = Key(rawValue: "HasAdditionalViews")
            public static let hasLeftStereoEyeView = Key(rawValue: "HasLeftStereoEyeView")
            public static let hasRightStereoEyeView = Key(rawValue: "HasRightStereoEyeView")
            public static let heroEye = Key(rawValue: "HeroEye")
            public static let stereoCameraBaseline = Key(rawValue: "StereoCameraBaseline")
            public static let horizontalDisparityAdjustment = Key(rawValue: "HorizontalDisparityAdjustment")
            public static let horizontalFieldOfView = Key(rawValue: "HorizontalFieldOfView")
            public static let ambientViewingEnvironment = Key(rawValue: "AmbientViewingEnvironment")
            public static let chromaLocationTopField = Key(rawValue: "ChromaLocationTopField")
            public static let chromaLocationBottomField = Key(rawValue: "ChromaLocationBottomField")
            public static let conformsToMPEG2VideoProfile = Key(rawValue: "ConformsToMPEG2VideoProfile")
            public static let masteringDisplayColorVolume = Key(rawValue: "MasteringDisplayColorVolume")
            public static let contentLightLevelInfo = Key(rawValue: "ContentLightLevelInfo")
            public static let contentColorVolume = Key(rawValue: "ContentColorVolume")
            public static let protectedContentOriginalFormat = Key(rawValue: "ProtectedContentOriginalFormat")
            public static let alternativeTransferCharacteristics = Key(
                rawValue: "AlternativeTransferCharacteristics"
            )
            public static let convertedFromExternalSphericalTags = Key(
                rawValue: "ConvertedFromExternalSphericalTags"
            )
            public static let cameraCalibrationDataLensCollection = Key(
                rawValue: "CameraCalibrationDataLensCollection"
            )
            public static let logTransferFunction = Key(rawValue: "LogTransferFunction")
            public static let auxiliaryTypeInfo = Key(rawValue: "AuxiliaryTypeInfo")
            public static let sourceReferenceName = Key(rawValue: "SourceReferenceName")
        }

        public struct Value: Hashable {
            public var stored: CFTypeRef?
            public var propertyListRepresentation: Any { stored as Any }
            public init(_ stored: CFTypeRef? = nil) { self.stored = stored }
            public static func == (lhs: Value, rhs: Value) -> Bool {
                switch (lhs.stored, rhs.stored) {
                case (nil, nil): return true
                case let (a?, b?): return CFEqual(a, b)
                default: return false
                }
            }
            public func hash(into hasher: inout Hasher) {
                if let stored {
                    hasher.combine(ObjectIdentifier(stored as AnyObject))
                } else {
                    hasher.combine(0)
                }
            }
        }

        public init() {}
        public init(base: CMFormatDescription.Extensions) { self = base }
    }

    public typealias T = CMFormatDescription

    public struct Error {
        public static let invalidParameter = cmNSError(code: -12710)
        public static let allocationFailed = cmNSError(code: -12711)
        public static let valueNotAvailable = cmNSError(code: -12718)
    }

    private static let processTypeID: CFTypeID = 0x434D_4644
    public static var typeID: CFTypeID { processTypeID }

    public private(set) var mediaType: MediaType
    public private(set) var mediaSubType: MediaSubType
    public private(set) var dimensions: CMVideoDimensions
    public var extensions: Extensions
    public var attachments = CMAttachmentBearerAttachments()
    internal var extraIdentity: Any? = nil
    internal var extensionStore: [String: CFTypeRef] = [:]
    internal var timeCodeFrameDuration: CMTime = .invalid
    internal var timeCodeFrameQuanta: UInt32 = 0
    internal var timeCodeFlagBits: UInt32 = 0
    internal var metadataIdentifiers: [CFString] = []
    internal var magicCookieBytes: Data? = nil

    public init(
        mediaType: MediaType,
        mediaSubType: MediaSubType,
        extensions: Extensions? = nil
    ) throws {
        self.mediaType = mediaType
        self.mediaSubType = mediaSubType
        self.dimensions = CMVideoDimensions()
        self.extensions = extensions ?? Extensions()
    }

    public init(
        videoCodecType: MediaSubType,
        width: Int,
        height: Int,
        extensions: Extensions? = nil
    ) throws {
        if width < 0 || height < 0 {
            throw Error.invalidParameter
        }
        self.mediaType = .video
        self.mediaSubType = videoCodecType
        self.dimensions = CMVideoDimensions(width: Int32(width), height: Int32(height))
        self.extensions = extensions ?? Extensions()
    }

    public init(muxedStreamType: MediaSubType, extensions: Extensions? = nil) throws {
        self.mediaType = .muxed
        self.mediaSubType = muxedStreamType
        self.dimensions = CMVideoDimensions()
        self.extensions = extensions ?? Extensions()
    }

    public init(metadataFormatType: MediaSubType) throws {
        self.mediaType = .metadata
        self.mediaSubType = metadataFormatType
        self.dimensions = CMVideoDimensions()
        self.extensions = Extensions()
    }

    public init(referencing object: CMFormatDescription) {
        self.mediaType = object.mediaType
        self.mediaSubType = object.mediaSubType
        self.dimensions = object.dimensions
        self.extensions = object.extensions
        self.attachments = object.attachments
        self.extensionStore = object.extensionStore
        self.extraIdentity = object.extraIdentity
        self.timeCodeFrameDuration = object.timeCodeFrameDuration
        self.timeCodeFrameQuanta = object.timeCodeFrameQuanta
        self.timeCodeFlagBits = object.timeCodeFlagBits
        self.metadataIdentifiers = object.metadataIdentifiers
        self.magicCookieBytes = object.magicCookieBytes
    }

    public func equalTo(
        _ otherFormatDescription: CMFormatDescription,
        extensionKeysToIgnore: [String] = [],
        sampleDescriptionExtensionAtomKeysToIgnore: [String] = []
    ) -> Bool {
        _ = (extensionKeysToIgnore, sampleDescriptionExtensionAtomKeysToIgnore)
        return mediaType == otherFormatDescription.mediaType
            && mediaSubType == otherFormatDescription.mediaSubType
            && dimensions == otherFormatDescription.dimensions
    }
}

extension CMFormatDescription: Equatable {
    public static func == (lhs: CMFormatDescription, rhs: CMFormatDescription) -> Bool {
        lhs === rhs
    }
}

extension CMFormatDescription: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public func CMFormatDescriptionCreate(
    allocator: CFAllocator?,
    mediaType: CMMediaType,
    mediaSubType: FourCharCode,
    extensions: CFDictionary?,
    formatDescriptionOut: UnsafeMutablePointer<CMFormatDescription?>
) -> OSStatus {
    _ = allocator
    do {
        let desc = try CMFormatDescription(
            mediaType: CMFormatDescription.MediaType(rawValue: mediaType),
            mediaSubType: CMFormatDescription.MediaSubType(rawValue: mediaSubType),
            extensions: nil
        )
        if let extensions {
            desc.installExtensions(extensions)
        }
        formatDescriptionOut.pointee = desc
        return 0
    } catch {
        formatDescriptionOut.pointee = nil
        return kCMFormatDescriptionError_InvalidParameter
    }
}

public func CMFormatDescriptionEqual(
    _ formatDescription: CMFormatDescription?,
    otherFormatDescription: CMFormatDescription?
) -> Bool {
    guard let formatDescription, let otherFormatDescription else {
        return formatDescription == nil && otherFormatDescription == nil
    }
    return formatDescription.equalTo(otherFormatDescription)
}

public func CMFormatDescriptionEqualIgnoringExtensionKeys(
    _ formatDescription: CMFormatDescription?,
    otherFormatDescription: CMFormatDescription?,
    extensionKeysToIgnore: CFArray?,
    sampleDescriptionExtensionAtomKeysToIgnore: CFArray?
) -> Bool {
    _ = (extensionKeysToIgnore, sampleDescriptionExtensionAtomKeysToIgnore)
    return CMFormatDescriptionEqual(formatDescription, otherFormatDescription: otherFormatDescription)
}

public func CMFormatDescriptionGetExtensions(_ desc: CMFormatDescription) -> CFDictionary? {
    desc.copyExtensions()
}

public func CMFormatDescriptionGetExtension(
    _ desc: CMFormatDescription,
    extensionKey: CFString
) -> CFPropertyList? {
    desc.extension(for: extensionKey)
}

public func CMVideoFormatDescriptionGetDimensions(_ videoDesc: CMVideoFormatDescription) -> CMVideoDimensions {
    videoDesc.dimensions
}

public func CMVideoFormatDescriptionCreate(
    allocator: CFAllocator?,
    codecType: CMVideoCodecType,
    width: Int32,
    height: Int32,
    extensions: CFDictionary?,
    formatDescriptionOut: UnsafeMutablePointer<CMVideoFormatDescription?>
) -> OSStatus {
    _ = allocator
    do {
        let desc = try CMFormatDescription(
            videoCodecType: CMFormatDescription.MediaSubType(rawValue: codecType),
            width: Int(width),
            height: Int(height),
            extensions: nil
        )
        if let extensions {
            desc.installExtensions(extensions)
        }
        formatDescriptionOut.pointee = desc
        return 0
    } catch {
        formatDescriptionOut.pointee = nil
        return kCMFormatDescriptionError_InvalidParameter
    }
}

public func CMMuxedFormatDescriptionCreate(
    allocator: CFAllocator?,
    muxType: CMMuxedStreamType,
    extensions: CFDictionary?,
    formatDescriptionOut: UnsafeMutablePointer<CMMuxedFormatDescription?>
) -> OSStatus {
    _ = allocator
    do {
        let desc = try CMFormatDescription(
            muxedStreamType: CMFormatDescription.MediaSubType(rawValue: muxType),
            extensions: nil
        )
        if let extensions {
            desc.installExtensions(extensions)
        }
        formatDescriptionOut.pointee = desc
        return 0
    } catch {
        formatDescriptionOut.pointee = nil
        return kCMFormatDescriptionError_InvalidParameter
    }
}

extension CMFormatDescription {
    internal func installExtensions(_ dictionary: CFDictionary) {
        let count = Int(CFDictionaryGetCount(dictionary))
        if count <= 0 { return }
        var keys = Array<UnsafeRawPointer?>(repeating: nil, count: count)
        var values = Array<UnsafeRawPointer?>(repeating: nil, count: count)
        keys.withUnsafeMutableBufferPointer { keyBuf in
            values.withUnsafeMutableBufferPointer { valBuf in
                CFDictionaryGetKeysAndValues(dictionary, keyBuf.baseAddress, valBuf.baseAddress)
            }
        }
        for index in 0..<count {
            guard let keyPtr = keys[index], let valPtr = values[index] else { continue }
            let key = unsafeBitCast(keyPtr, to: CFString.self)
            let name = unsafeBitCast(key, to: NSString.self) as String
            extensionStore[name] = unsafeBitCast(valPtr, to: CFTypeRef.self)
        }
    }

    internal func copyExtensions() -> CFDictionary? {
        if extensionStore.isEmpty { return nil }
        var pairs: [(CFString, CFTypeRef)] = []
        for (name, value) in extensionStore {
            pairs.append((cmMakeCFString(name), value))
        }
        return cmCFDictionary(pairs)
    }

    internal func `extension`(for key: CFString) -> CFPropertyList? {
        let name = unsafeBitCast(key, to: NSString.self) as String
        return extensionStore[name]
    }
}

public func CMFormatDescriptionGetMediaType(_ desc: CMFormatDescription) -> CMMediaType {
    desc.mediaType.rawValue
}

public func CMFormatDescriptionGetMediaSubType(_ desc: CMFormatDescription) -> UInt32 {
    desc.mediaSubType.rawValue
}

public func CMFormatDescriptionGetTypeID() -> CFTypeID {
    CMFormatDescription.typeID
}

internal func cmFourCCString(_ value: UInt32) -> String {
    let bytes: [UInt8] = [
        UInt8((value >> 24) & 0xff),
        UInt8((value >> 16) & 0xff),
        UInt8((value >> 8) & 0xff),
        UInt8(value & 0xff)
    ]
    return String(bytes: bytes, encoding: .ascii) ?? String(value)
}

internal func cmCFNumberFromNumeric<T: Numeric>(_ value: T) -> CFNumber {
    var stored = Double("\(value)") ?? 0
    return CFNumberCreate(kCFAllocatorDefault, .doubleType, &stored)!
}

internal func cmCFNumberDouble(_ value: CFTypeRef?) -> Double? {
    guard let value else { return nil }
    var result: Double = 0
    if CFNumberGetValue(unsafeBitCast(value, to: CFNumber.self), .doubleType, &result) {
        return result
    }
    return nil
}

internal func cmCFNumberDouble(_ value: UnsafeRawPointer?) -> Double? {
    guard let value else { return nil }
    return cmCFNumberDouble(unsafeBitCast(value, to: CFTypeRef.self))
}

extension CMFormatDescription {
    public var timeCodeFlags: TimeCode.Flag { TimeCode.Flag(rawValue: timeCodeFlagBits) }

    public func cleanAperture(originIsAtTopLeft: Bool) -> CGRect {
        CMVideoFormatDescriptionGetCleanAperture(self, originIsAtTopLeft: originIsAtTopLeft)
    }

    public func displayFlags() throws -> Extensions.Value.TextDisplayFlags {
        var flags: CMTextDisplayFlags = 0
        let status = CMTextFormatDescriptionGetDisplayFlags(self, displayFlagsOut: &flags)
        if status != 0 { throw Error.valueNotAvailable }
        return Extensions.Value.TextDisplayFlags(rawValue: flags)
    }

    public func justification() throws -> (
        horizontal: Extensions.Value.TextJustification,
        vertical: Extensions.Value.TextJustification
    ) {
        var horizontal: CMTextJustificationValue = 0
        var vertical: CMTextJustificationValue = 0
        let status = CMTextFormatDescriptionGetJustification(
            self,
            horizontalOut: &horizontal,
            verticalOut: &vertical
        )
        if status != 0 { throw Error.valueNotAvailable }
        return (
            horizontal: Extensions.Value.TextJustification(rawValue: horizontal),
            vertical: Extensions.Value.TextJustification(rawValue: vertical)
        )
    }

    public func defaultTextBox(originIsAtTopLeft: Bool, heightOfTextTrack: CGFloat) throws -> CGRect {
        var box = CGRect.zero
        let status = CMTextFormatDescriptionGetDefaultTextBox(
            self,
            originIsAtTopLeft: originIsAtTopLeft,
            heightOfTextTrack: heightOfTextTrack,
            defaultTextBoxOut: &box
        )
        if status != 0 { throw Error.valueNotAvailable }
        return box
    }

    public func defaultStyle() throws -> (
        localFontID: Int,
        bold: Bool,
        italic: Bool,
        underline: Bool,
        fontSize: CGFloat,
        colorComponents: [CGFloat]
    ) {
        var fontID: UInt16 = 0
        var bold = false
        var italic = false
        var underline = false
        var fontSize: CGFloat = 0
        var color = [CGFloat](repeating: 0, count: 4)
        let status = color.withUnsafeMutableBufferPointer { buffer in
            CMTextFormatDescriptionGetDefaultStyle(
                self,
                localFontIDOut: &fontID,
                boldOut: &bold,
                italicOut: &italic,
                underlineOut: &underline,
                fontSizeOut: &fontSize,
                colorComponentsOut: buffer.baseAddress
            )
        }
        if status != 0 { throw Error.valueNotAvailable }
        return (Int(fontID), bold, italic, underline, fontSize, color)
    }
}

extension CMFormatDescription.Extensions.Value {
    public static func pixelAspectRatio<Horizontal: Numeric, Vertical: Numeric>(
        horizontalSpacing: Horizontal,
        verticalSpacing: Vertical
    ) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(
            cmCFDictionary([
                (kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing, cmCFNumberFromNumeric(horizontalSpacing)),
                (kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing, cmCFNumberFromNumeric(verticalSpacing))
            ])
        )
    }

    public static func cleanAperture<Width: Numeric, Height: Numeric, Horizontal: Numeric, Vertical: Numeric>(
        width: Width,
        height: Height,
        horizontalOffet: Horizontal,
        verticalOffset: Vertical
    ) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(
            cmCFDictionary([
                (kCMFormatDescriptionKey_CleanApertureWidth, cmCFNumberFromNumeric(width)),
                (kCMFormatDescriptionKey_CleanApertureHeight, cmCFNumberFromNumeric(height)),
                (kCMFormatDescriptionKey_CleanApertureHorizontalOffset, cmCFNumberFromNumeric(horizontalOffet)),
                (kCMFormatDescriptionKey_CleanApertureVerticalOffset, cmCFNumberFromNumeric(verticalOffset))
            ])
        )
    }

    public static func cleanAperture(
        width: (numerator: Int, denominator: Int),
        height: (numerator: Int, denominator: Int),
        horizontalOffet: (numerator: Int, denominator: Int),
        verticalOffset: (numerator: Int, denominator: Int)
    ) -> CMFormatDescription.Extensions.Value {
        func pair(_ key: CFString, _ value: (Int, Int)) -> (CFString, CFTypeRef) {
            (key, cmCFDictionary([
                (cmMakeCFString("numerator"), cmCFNumberFromNumeric(value.0)),
                (cmMakeCFString("denominator"), cmCFNumberFromNumeric(value.1))
            ]))
        }
        return CMFormatDescription.Extensions.Value(
            cmCFDictionary([
                pair(kCMFormatDescriptionKey_CleanApertureWidthRational, width),
                pair(kCMFormatDescriptionKey_CleanApertureHeightRational, height),
                pair(kCMFormatDescriptionKey_CleanApertureHorizontalOffsetRational, horizontalOffet),
                pair(kCMFormatDescriptionKey_CleanApertureVerticalOffsetRational, verticalOffset)
            ])
        )
    }

    public static func textJustification(
        _ justification: TextJustification
    ) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(cmCFNumberFromNumeric(Int(justification.rawValue)))
    }

    public static func fontTable(_ table: CFDictionary) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(table)
    }

    public static func sourceReferenceName(value: String, langCode: Int) -> CMFormatDescription.Extensions.Value {
        CMFormatDescription.Extensions.Value(
            cmCFDictionary([
                (cmMakeCFString("value"), cmMakeCFString(value)),
                (cmMakeCFString("langCode"), cmCFNumberFromNumeric(langCode))
            ])
        )
    }
}

