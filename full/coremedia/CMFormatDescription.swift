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
        public static let appleLossless = MediaSubType(rawValue: cmFourCC("alac"))
        public static let flac = MediaSubType(rawValue: cmFourCC("flac"))
        public static let opus = MediaSubType(rawValue: cmFourCC("opus"))
        public static let ac3 = MediaSubType(rawValue: cmFourCC("ac-3"))
        public static let enhancedAC3 = MediaSubType(rawValue: cmFourCC("ec-3"))
    }

    public struct Extensions: Equatable {
        public init() {}
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
