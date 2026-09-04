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
