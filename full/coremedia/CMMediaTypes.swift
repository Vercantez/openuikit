public var kCMMediaType_Video: CMMediaType { cmFourCC("vide") }
public var kCMMediaType_Audio: CMMediaType { cmFourCC("soun") }
public var kCMMediaType_Muxed: CMMediaType { cmFourCC("muxx") }
public var kCMMediaType_Text: CMMediaType { cmFourCC("text") }
public var kCMMediaType_ClosedCaption: CMMediaType { cmFourCC("clcp") }
public var kCMMediaType_Subtitle: CMMediaType { cmFourCC("sbtl") }
public var kCMMediaType_TimeCode: CMMediaType { cmFourCC("tmcd") }
public var kCMMediaType_Metadata: CMMediaType { cmFourCC("meta") }
public var kCMMediaType_TaggedBufferGroup: CMMediaType { cmFourCC("tbgr") }

public var kCMVideoCodecType_422YpCbCr8: CMVideoCodecType { cmFourCC("2vuy") }
public var kCMVideoCodecType_Animation: CMVideoCodecType { cmFourCC("rle ") }
public var kCMVideoCodecType_Cinepak: CMVideoCodecType { cmFourCC("cvid") }
public var kCMVideoCodecType_JPEG: CMVideoCodecType { cmFourCC("jpeg") }
public var kCMVideoCodecType_JPEG_OpenDML: CMVideoCodecType { cmFourCC("dmb1") }
public var kCMVideoCodecType_JPEG_XL: CMVideoCodecType { cmFourCC("jxlc") }
public var kCMVideoCodecType_SorensonVideo: CMVideoCodecType { cmFourCC("SVQ1") }
public var kCMVideoCodecType_SorensonVideo3: CMVideoCodecType { cmFourCC("SVQ3") }
public var kCMVideoCodecType_H263: CMVideoCodecType { cmFourCC("h263") }
public var kCMVideoCodecType_H264: CMVideoCodecType { cmFourCC("avc1") }
public var kCMVideoCodecType_HEVC: CMVideoCodecType { cmFourCC("hvc1") }
public var kCMVideoCodecType_HEVCWithAlpha: CMVideoCodecType { cmFourCC("muxa") }
public var kCMVideoCodecType_MPEG4Video: CMVideoCodecType { cmFourCC("mp4v") }
public var kCMVideoCodecType_MPEG2Video: CMVideoCodecType { cmFourCC("mp2v") }
public var kCMVideoCodecType_MPEG1Video: CMVideoCodecType { cmFourCC("mp1v") }
public var kCMVideoCodecType_VP9: CMVideoCodecType { cmFourCC("vp09") }
public var kCMVideoCodecType_AV1: CMVideoCodecType { cmFourCC("av01") }
public var kCMVideoCodecType_DVCNTSC: CMVideoCodecType { cmFourCC("dvc ") }
public var kCMVideoCodecType_DVCPAL: CMVideoCodecType { cmFourCC("dvcp") }
public var kCMVideoCodecType_DVCProPAL: CMVideoCodecType { cmFourCC("dvpp") }
public var kCMVideoCodecType_DVCPro50NTSC: CMVideoCodecType { cmFourCC("dv5n") }
public var kCMVideoCodecType_DVCPro50PAL: CMVideoCodecType { cmFourCC("dv5p") }
public var kCMVideoCodecType_DVCPROHD720p60: CMVideoCodecType { cmFourCC("dvhp") }
public var kCMVideoCodecType_DVCPROHD720p50: CMVideoCodecType { cmFourCC("dvhq") }
public var kCMVideoCodecType_DVCPROHD1080i60: CMVideoCodecType { cmFourCC("dvh6") }
public var kCMVideoCodecType_DVCPROHD1080i50: CMVideoCodecType { cmFourCC("dvh5") }
public var kCMVideoCodecType_DVCPROHD1080p30: CMVideoCodecType { cmFourCC("dvh3") }
public var kCMVideoCodecType_DVCPROHD1080p25: CMVideoCodecType { cmFourCC("dvh2") }
public var kCMVideoCodecType_AppleProRes4444XQ: CMVideoCodecType { cmFourCC("ap4x") }
public var kCMVideoCodecType_AppleProRes4444: CMVideoCodecType { cmFourCC("ap4h") }
public var kCMVideoCodecType_AppleProRes422HQ: CMVideoCodecType { cmFourCC("apch") }
public var kCMVideoCodecType_AppleProRes422: CMVideoCodecType { cmFourCC("apcn") }
public var kCMVideoCodecType_AppleProRes422LT: CMVideoCodecType { cmFourCC("apcs") }
public var kCMVideoCodecType_AppleProRes422Proxy: CMVideoCodecType { cmFourCC("apco") }
public var kCMVideoCodecType_AppleProResRAW: CMVideoCodecType { cmFourCC("aprn") }
public var kCMVideoCodecType_AppleProResRAWHQ: CMVideoCodecType { cmFourCC("aprh") }
public var kCMVideoCodecType_DolbyVisionHEVC: CMVideoCodecType { cmFourCC("dvh1") }
public var kCMVideoCodecType_DisparityHEVC: CMVideoCodecType { cmFourCC("dish") }
public var kCMVideoCodecType_DepthHEVC: CMVideoCodecType { cmFourCC("deph") }

public var kCMPixelFormat_32ARGB: CMPixelFormatType { 32 }
public var kCMPixelFormat_32BGRA: CMPixelFormatType { cmFourCC("BGRA") }
public var kCMPixelFormat_24RGB: CMPixelFormatType { 24 }
public var kCMPixelFormat_16BE555: CMPixelFormatType { 16 }
public var kCMPixelFormat_16BE565: CMPixelFormatType { cmFourCC("B565") }
public var kCMPixelFormat_16LE555: CMPixelFormatType { cmFourCC("L555") }
public var kCMPixelFormat_16LE565: CMPixelFormatType { cmFourCC("L565") }
public var kCMPixelFormat_16LE5551: CMPixelFormatType { cmFourCC("5551") }
public var kCMPixelFormat_422YpCbCr8: CMPixelFormatType { cmFourCC("2vuy") }
public var kCMPixelFormat_422YpCbCr8_yuvs: CMPixelFormatType { cmFourCC("yuvs") }
public var kCMPixelFormat_444YpCbCr8: CMPixelFormatType { cmFourCC("v308") }
public var kCMPixelFormat_4444YpCbCrA8: CMPixelFormatType { cmFourCC("v408") }
public var kCMPixelFormat_422YpCbCr16: CMPixelFormatType { cmFourCC("v216") }
public var kCMPixelFormat_422YpCbCr10: CMPixelFormatType { cmFourCC("v210") }
public var kCMPixelFormat_444YpCbCr10: CMPixelFormatType { cmFourCC("v410") }
public var kCMPixelFormat_8IndexedGray_WhiteIsZero: CMPixelFormatType { 40 }

public var kCMAudioCodecType_AAC_LCProtected: CMAudioCodecType { cmFourCC("paac") }
public var kCMAudioCodecType_AAC_AudibleProtected: CMAudioCodecType { cmFourCC("aaac") }

public var kCMMuxedStreamType_MPEG1System: CMMuxedStreamType { cmFourCC("mp1s") }
public var kCMMuxedStreamType_MPEG2Transport: CMMuxedStreamType { cmFourCC("mp2t") }
public var kCMMuxedStreamType_MPEG2Program: CMMuxedStreamType { cmFourCC("mp2p") }
public var kCMMuxedStreamType_DV: CMMuxedStreamType { cmFourCC("dv  ") }
public var kCMMuxedStreamType_EmbeddedDeviceScreenRecording: CMMuxedStreamType { cmFourCC("isr ") }

public var kCMClosedCaptionFormatType_CEA608: CMClosedCaptionFormatType { cmFourCC("c608") }
public var kCMClosedCaptionFormatType_CEA708: CMClosedCaptionFormatType { cmFourCC("c708") }
public var kCMClosedCaptionFormatType_ATSC: CMClosedCaptionFormatType { cmFourCC("atcc") }

public var kCMSubtitleFormatType_3GText: CMSubtitleFormatType { cmFourCC("tx3g") }
public var kCMSubtitleFormatType_WebVTT: CMSubtitleFormatType { cmFourCC("wvtt") }

public var kCMMetadataFormatType_ICY: CMMetadataFormatType { cmFourCC("icy ") }
public var kCMMetadataFormatType_ID3: CMMetadataFormatType { cmFourCC("id3 ") }
public var kCMMetadataFormatType_Boxed: CMMetadataFormatType { cmFourCC("mebx") }
public var kCMMetadataFormatType_EMSG: CMMetadataFormatType { cmFourCC("emsg") }

public var kCMTimeCodeFormatType_TimeCode32: CMTimeCodeFormatType { cmFourCC("tmcd") }
public var kCMTimeCodeFormatType_TimeCode64: CMTimeCodeFormatType { cmFourCC("tc64") }
public var kCMTimeCodeFormatType_Counter32: CMTimeCodeFormatType { cmFourCC("cn32") }
public var kCMTimeCodeFormatType_Counter64: CMTimeCodeFormatType { cmFourCC("cn64") }

public var kCMTextFormatType_QTText: CMTextFormatType { cmFourCC("text") }
public var kCMTextFormatType_3GText: CMTextFormatType { cmFourCC("tx3g") }

public var kCMTimeCodeFlag_DropFrame: UInt32 { 1 << 0 }
public var kCMTimeCodeFlag_24HourMax: UInt32 { 1 << 1 }
public var kCMTimeCodeFlag_NegTimesOK: UInt32 { 1 << 2 }

/// FourCC payloads for packing / projection match the public `CMFormatDescription.h`
/// character literals (`'none'`, `'side'`, `'over'`, `'rect'`, `'equi'`, `'hequ'`,
/// `'fish'`, `'prim'`). Stereo view bits are 1<<0 / 1<<1. Graph does not record
/// the integers; see `oracle-questions.tsv`.
public enum CMPackingType: UInt64, Hashable, Sendable {
    case none = 0x6E6F6E65
    case sideBySide = 0x73696465
    case overUnder = 0x6F766572
}

public enum CMProjectionType: UInt64, Hashable, Sendable {
    case rectangular = 0x72656374
    case equirectangular = 0x65717569
    case halfEquirectangular = 0x68657175
    case fisheye = 0x66697368
    case parametricImmersive = 0x7072696D
}

public struct CMStereoViewComponents: OptionSet, Hashable, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public static let leftEye = CMStereoViewComponents(rawValue: 1 << 0)
    public static let rightEye = CMStereoViewComponents(rawValue: 1 << 1)
}

public struct CMStereoViewInterpretationOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public static let stereoOrderReversed = CMStereoViewInterpretationOptions(rawValue: 1 << 0)
    public static let additionalViews = CMStereoViewInterpretationOptions(rawValue: 1 << 1)
}

public var kCMPackingType_None: UInt64 { CMPackingType.none.rawValue }
public var kCMPackingType_SideBySide: UInt64 { CMPackingType.sideBySide.rawValue }
public var kCMPackingType_OverUnder: UInt64 { CMPackingType.overUnder.rawValue }
public var kCMProjectionType_Rectangular: UInt64 { CMProjectionType.rectangular.rawValue }
public var kCMProjectionType_Equirectangular: UInt64 { CMProjectionType.equirectangular.rawValue }
public var kCMProjectionType_HalfEquirectangular: UInt64 { CMProjectionType.halfEquirectangular.rawValue }
public var kCMProjectionType_Fisheye: UInt64 { CMProjectionType.fisheye.rawValue }
public var kCMProjectionType_ParametricImmersive: UInt64 { CMProjectionType.parametricImmersive.rawValue }
public var kCMStereoView_LeftEye: UInt64 { CMStereoViewComponents.leftEye.rawValue }
public var kCMStereoView_RightEye: UInt64 { CMStereoViewComponents.rightEye.rawValue }
public var kCMStereoViewInterpretation_StereoOrderReversed: UInt64 {
    CMStereoViewInterpretationOptions.stereoOrderReversed.rawValue
}
public var kCMStereoViewInterpretation_AdditionalViews: UInt64 {
    CMStereoViewInterpretationOptions.additionalViews.rawValue
}
