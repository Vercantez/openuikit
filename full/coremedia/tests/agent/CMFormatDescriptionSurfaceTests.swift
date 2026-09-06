import CoreFoundation
import CoreMedia

private func cmTestFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    precondition(bytes.count == 4)
    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}

private func cmTestDictionary(_ pairs: [(CFString, CFTypeRef)]) -> CFDictionary {
    var keyCB = kCFTypeDictionaryKeyCallBacks
    var valCB = kCFTypeDictionaryValueCallBacks
    let dict = CFDictionaryCreateMutable(
        kCFAllocatorDefault,
        CFIndex(pairs.count),
        &keyCB,
        &valCB
    )!
    for (key, value) in pairs {
        CFDictionarySetValue(
            dict,
            unsafeBitCast(key, to: UnsafeRawPointer.self),
            unsafeBitCast(value, to: UnsafeRawPointer.self)
        )
    }
    return dict
}

func testRemainingVideoCodecFourCCConstants() {
    let pairs: [(CMVideoCodecType, String)] = [
        (kCMVideoCodecType_422YpCbCr8, "2vuy"),
        (kCMVideoCodecType_Animation, "rle "),
        (kCMVideoCodecType_AppleProRes422HQ, "apch"),
        (kCMVideoCodecType_AppleProRes422LT, "apcs"),
        (kCMVideoCodecType_AppleProRes422Proxy, "apco"),
        (kCMVideoCodecType_AppleProRes4444, "ap4h"),
        (kCMVideoCodecType_AppleProRes4444XQ, "ap4x"),
        (kCMVideoCodecType_AppleProResRAW, "aprn"),
        (kCMVideoCodecType_AppleProResRAWHQ, "aprh"),
        (kCMVideoCodecType_Cinepak, "cvid"),
        (kCMVideoCodecType_DVCNTSC, "dvc "),
        (kCMVideoCodecType_DVCPAL, "dvcp"),
        (kCMVideoCodecType_DVCPROHD1080i50, "dvh5"),
        (kCMVideoCodecType_DVCPROHD1080i60, "dvh6"),
        (kCMVideoCodecType_DVCPROHD1080p25, "dvh2"),
        (kCMVideoCodecType_DVCPROHD1080p30, "dvh3"),
        (kCMVideoCodecType_DVCPROHD720p50, "dvhq"),
        (kCMVideoCodecType_DVCPROHD720p60, "dvhp"),
        (kCMVideoCodecType_DVCPro50NTSC, "dv5n"),
        (kCMVideoCodecType_DVCPro50PAL, "dv5p"),
        (kCMVideoCodecType_DVCProPAL, "dvpp"),
        (kCMVideoCodecType_DepthHEVC, "deph"),
        (kCMVideoCodecType_DisparityHEVC, "dish"),
        (kCMVideoCodecType_DolbyVisionHEVC, "dvh1"),
        (kCMVideoCodecType_H263, "h263"),
        (kCMVideoCodecType_HEVCWithAlpha, "muxa"),
        (kCMVideoCodecType_JPEG_OpenDML, "dmb1"),
        (kCMVideoCodecType_JPEG_XL, "jxlc"),
        (kCMVideoCodecType_MPEG1Video, "mp1v"),
        (kCMVideoCodecType_MPEG2Video, "mp2v"),
        (kCMVideoCodecType_MPEG4Video, "mp4v"),
        (kCMVideoCodecType_SorensonVideo, "SVQ1"),
        (kCMVideoCodecType_SorensonVideo3, "SVQ3"),
        (kCMVideoCodecType_VP9, "vp09"),
    ]
    for (value, literal) in pairs {
        precondition(value == cmTestFourCC(literal))
    }
}

func testCMFormatDescriptionMediaSubTypeTable() {
    precondition(CMFormatDescription.MediaSubType.h264.rawValue == kCMVideoCodecType_H264)
    precondition(CMFormatDescription.MediaSubType.hevc.rawValue == kCMVideoCodecType_HEVC)
    precondition(CMFormatDescription.MediaSubType.hevcWithAlpha.rawValue == kCMVideoCodecType_HEVCWithAlpha)
    precondition(CMFormatDescription.MediaSubType.jpeg.rawValue == kCMVideoCodecType_JPEG)
    precondition(CMFormatDescription.MediaSubType.jpeg_OpenDML.rawValue == kCMVideoCodecType_JPEG_OpenDML)
    precondition(CMFormatDescription.MediaSubType.mpeg4Video.rawValue == kCMVideoCodecType_MPEG4Video)
    precondition(CMFormatDescription.MediaSubType.mpeg2Video.rawValue == kCMVideoCodecType_MPEG2Video)
    precondition(CMFormatDescription.MediaSubType.mpeg1Video.rawValue == kCMVideoCodecType_MPEG1Video)
    precondition(CMFormatDescription.MediaSubType.h263.rawValue == kCMVideoCodecType_H263)
    precondition(CMFormatDescription.MediaSubType.animation.rawValue == kCMVideoCodecType_Animation)
    precondition(CMFormatDescription.MediaSubType.cinepak.rawValue == kCMVideoCodecType_Cinepak)
    precondition(CMFormatDescription.MediaSubType.sorensonVideo.rawValue == kCMVideoCodecType_SorensonVideo)
    precondition(CMFormatDescription.MediaSubType.sorensonVideo3.rawValue == kCMVideoCodecType_SorensonVideo3)
    precondition(CMFormatDescription.MediaSubType.proRes422.rawValue == kCMVideoCodecType_AppleProRes422)
    precondition(CMFormatDescription.MediaSubType.proRes422HQ.rawValue == kCMVideoCodecType_AppleProRes422HQ)
    precondition(CMFormatDescription.MediaSubType.proRes422LT.rawValue == kCMVideoCodecType_AppleProRes422LT)
    precondition(CMFormatDescription.MediaSubType.proRes422Proxy.rawValue == kCMVideoCodecType_AppleProRes422Proxy)
    precondition(CMFormatDescription.MediaSubType.proRes4444.rawValue == kCMVideoCodecType_AppleProRes4444)
    precondition(CMFormatDescription.MediaSubType.proRes4444XQ.rawValue == kCMVideoCodecType_AppleProRes4444XQ)
    precondition(CMFormatDescription.MediaSubType.proResRAW.rawValue == kCMVideoCodecType_AppleProResRAW)
    precondition(CMFormatDescription.MediaSubType.proResRAWHQ.rawValue == kCMVideoCodecType_AppleProResRAWHQ)
    precondition(CMFormatDescription.MediaSubType.dvcNTSC.rawValue == kCMVideoCodecType_DVCNTSC)
    precondition(CMFormatDescription.MediaSubType.dvcPAL.rawValue == kCMVideoCodecType_DVCPAL)
    precondition(CMFormatDescription.MediaSubType.dvcProPAL.rawValue == kCMVideoCodecType_DVCProPAL)
    precondition(CMFormatDescription.MediaSubType.dvcPro50NTSC.rawValue == kCMVideoCodecType_DVCPro50NTSC)
    precondition(CMFormatDescription.MediaSubType.dvcPro50PAL.rawValue == kCMVideoCodecType_DVCPro50PAL)
    precondition(CMFormatDescription.MediaSubType.dvcPROHD720p60.rawValue == kCMVideoCodecType_DVCPROHD720p60)
    precondition(CMFormatDescription.MediaSubType.dvcPROHD720p50.rawValue == kCMVideoCodecType_DVCPROHD720p50)
    precondition(CMFormatDescription.MediaSubType.dvcPROHD1080i60.rawValue == kCMVideoCodecType_DVCPROHD1080i60)
    precondition(CMFormatDescription.MediaSubType.dvcPROHD1080i50.rawValue == kCMVideoCodecType_DVCPROHD1080i50)
    precondition(CMFormatDescription.MediaSubType.dvcPROHD1080p30.rawValue == kCMVideoCodecType_DVCPROHD1080p30)
    precondition(CMFormatDescription.MediaSubType.dvcPROHD1080p25.rawValue == kCMVideoCodecType_DVCPROHD1080p25)
    precondition(CMFormatDescription.MediaSubType.mpeg1System.rawValue == kCMMuxedStreamType_MPEG1System)
    precondition(CMFormatDescription.MediaSubType.mpeg2Transport.rawValue == kCMMuxedStreamType_MPEG2Transport)
    precondition(CMFormatDescription.MediaSubType.mpeg2Program.rawValue == kCMMuxedStreamType_MPEG2Program)
    precondition(CMFormatDescription.MediaSubType.dv.rawValue == kCMMuxedStreamType_DV)
    precondition(CMFormatDescription.MediaSubType.cea608.rawValue == kCMClosedCaptionFormatType_CEA608)
    precondition(CMFormatDescription.MediaSubType.cea708.rawValue == kCMClosedCaptionFormatType_CEA708)
    precondition(CMFormatDescription.MediaSubType.atsc.rawValue == kCMClosedCaptionFormatType_ATSC)
    precondition(CMFormatDescription.MediaSubType.timeCode32.rawValue == kCMTimeCodeFormatType_TimeCode32)
    precondition(CMFormatDescription.MediaSubType.timeCode64.rawValue == kCMTimeCodeFormatType_TimeCode64)
    precondition(CMFormatDescription.MediaSubType.counter32.rawValue == kCMTimeCodeFormatType_Counter32)
    precondition(CMFormatDescription.MediaSubType.counter64.rawValue == kCMTimeCodeFormatType_Counter64)
    precondition(CMFormatDescription.MediaSubType.icy.rawValue == kCMMetadataFormatType_ICY)
    precondition(CMFormatDescription.MediaSubType.id3.rawValue == kCMMetadataFormatType_ID3)
    precondition(CMFormatDescription.MediaSubType.boxed.rawValue == kCMMetadataFormatType_Boxed)
    precondition(CMFormatDescription.MediaSubType.emsg.rawValue == kCMMetadataFormatType_EMSG)
    precondition(CMFormatDescription.MediaSubType.linearPCM.rawValue == cmTestFourCC("lpcm"))
    precondition(CMFormatDescription.MediaSubType.mpeg4AAC.rawValue == cmTestFourCC("aac "))
    precondition(CMFormatDescription.MediaSubType.appleLossless.rawValue == cmTestFourCC("alac"))
    precondition(CMFormatDescription.MediaType.video.rawValue == kCMMediaType_Video)
    precondition(CMFormatDescription.MediaType.audio.rawValue == kCMMediaType_Audio)
    precondition(CMFormatDescription.MediaType.muxed.rawValue == kCMMediaType_Muxed)
    precondition(CMFormatDescription.MediaType.text.rawValue == kCMMediaType_Text)
    precondition(CMFormatDescription.MediaType.closedCaption.rawValue == kCMMediaType_ClosedCaption)
    precondition(CMFormatDescription.MediaType.subtitle.rawValue == kCMMediaType_Subtitle)
    precondition(CMFormatDescription.MediaType.timeCode.rawValue == kCMMediaType_TimeCode)
    precondition(CMFormatDescription.MediaType.metadata.rawValue == kCMMediaType_Metadata)
    precondition(CMFormatDescription.MediaType.taggedBufferGroup.rawValue == kCMMediaType_TaggedBufferGroup)
    let extra: [(CMFormatDescription.MediaSubType, UInt32)] = [
        (.midiStream, cmTestFourCC("midi")),
        (.mobile3GPP, kCMSubtitleFormatType_3GText),
        (.mpegD_USAC, cmTestFourCC("usac")),
        (.mpegLayer1, cmTestFourCC(".mp1")),
        (.mpegLayer2, cmTestFourCC(".mp2")),
        (.mpegLayer3, cmTestFourCC(".mp3")),
        (.dviIntelIMA, 0x6D730011),
        (.enhancedAC3, cmTestFourCC("ec-3")),
        (.iec60958AC3, cmTestFourCC("cac3")),
        (.mpeg4AAC_HE, cmTestFourCC("aach")),
        (.mpeg4AAC_LD, cmTestFourCC("aacl")),
        (.mpeg4TwinVQ, cmTestFourCC("twvq")),
        (.mpeg4AAC_ELD, cmTestFourCC("aace")),
        (.microsoftGSM, 0x6D730031),
        (.mpeg4AAC_HE_V2, cmTestFourCC("aacp")),
        (.mpeg4AAC_ELD_V2, cmTestFourCC("aacg")),
        (.mpeg4AAC_ELD_SBR, cmTestFourCC("aacf")),
        (.mpeg4AAC_Spatial, cmTestFourCC("aacs")),
        (.pixelFormat_24RGB, kCMPixelFormat_24RGB),
        (.pixelFormat_32ARGB, kCMPixelFormat_32ARGB),
        (.pixelFormat_32BGRA, kCMPixelFormat_32BGRA),
        (.aacAudibleProtected, kCMAudioCodecType_AAC_AudibleProtected),
        (.pixelFormat_16BE555, kCMPixelFormat_16BE555),
        (.pixelFormat_16BE565, kCMPixelFormat_16BE565),
        (.pixelFormat_16LE555, kCMPixelFormat_16LE555),
        (.pixelFormat_16LE565, kCMPixelFormat_16LE565),
        (.parameterValueStream, cmTestFourCC("apvs")),
        (.pixelFormat_16LE5551, kCMPixelFormat_16LE5551),
        (.pixelFormat_422YpCbCr8, kCMPixelFormat_422YpCbCr8),
        (.pixelFormat_444YpCbCr8, kCMPixelFormat_444YpCbCr8),
        (.pixelFormat_422YpCbCr10, kCMPixelFormat_422YpCbCr10),
        (.pixelFormat_422YpCbCr16, kCMPixelFormat_422YpCbCr16),
        (.pixelFormat_444YpCbCr10, kCMPixelFormat_444YpCbCr10),
        (.pixelFormat_4444YpCbCrA8, kCMPixelFormat_4444YpCbCrA8),
        (.pixelFormat_422YpCbCr8_yuvs, kCMPixelFormat_422YpCbCr8_yuvs),
        (.embeddedDeviceScreenRecording, kCMMuxedStreamType_EmbeddedDeviceScreenRecording),
        (.qt, kCMTextFormatType_QTText),
        (.pixelFormat_8IndexedGray_WhiteIsZero, kCMPixelFormat_8IndexedGray_WhiteIsZero),
        (.ac3, cmTestFourCC("ac-3")),
        (.amr, cmTestFourCC("samr")),
        (.aLaw, cmTestFourCC("alaw")),
        (.aes3, cmTestFourCC("aes3")),
        (.flac, cmTestFourCC("flac")),
        (.iLBC, cmTestFourCC("ilbc")),
        (.opus, cmTestFourCC("opus")),
        (.tbgr, kCMMediaType_TaggedBufferGroup),
        (.uLaw, cmTestFourCC("ulaw")),
        (.mace3, cmTestFourCC("MAC3")),
        (.mace6, cmTestFourCC("MAC6")),
        (.amr_WB, cmTestFourCC("sawb")),
        (.webVTT, kCMSubtitleFormatType_WebVTT),
        (.audible, cmTestFourCC("AUDB")),
        (.qDesign, cmTestFourCC("QDMC")),
        (.qDesign2, cmTestFourCC("QDM2")),
        (.qualcomm, cmTestFourCC("Qclp")),
        (.timeCode, kCMTimeCodeFormatType_TimeCode32),
        (.appleIMA4, cmTestFourCC("ima4")),
        (.mpeg4CELP, cmTestFourCC("celp")),
        (.mpeg4HVXC, cmTestFourCC("hvxc")),
        (.aacLCProtected, kCMAudioCodecType_AAC_LCProtected),
        (.mpeg2Transport, kCMMuxedStreamType_MPEG2Transport),
        (.id3, kCMMetadataFormatType_ID3),
        (.hevc, kCMVideoCodecType_HEVC),
        (.h264, kCMVideoCodecType_H264),
        (.jpeg, kCMVideoCodecType_JPEG),
    ]
    for (subtype, expected) in extra {
        precondition(subtype.rawValue == expected)
        precondition(CMFormatDescription.MediaSubType(rawValue: expected).rawValue == expected)
    }
}

func testCMFormatDescriptionExtensionsCollection() {
    var extensions = CMFormatDescription.Extensions()
    extensions[.formatName] = .string("avc1")
    precondition(extensions[.formatName] != nil)
    precondition(extensions.startIndex.rawValue == 0)
    precondition(extensions.endIndex.rawValue == 1)
    let first = extensions[extensions.startIndex]
    precondition(first.key.rawValue == "FormatName")
    let depth = 24 as Int32
    var stored = depth
    let cfNumber = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &stored)!
    let fromDict = CMFormatDescription.Extensions(
        base: cmTestDictionary([(kCMFormatDescriptionExtension_Depth, cfNumber)])
    )
    precondition(fromDict.endIndex.rawValue == 1)
    let flags = CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollIn.union(.scrollOut)
    precondition(flags.contains(.scrollIn))
    precondition(flags.scrollDirection.rawValue == 0)
    precondition(
        CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollDirectionMask.rawValue
            == kCMTextDisplayFlag_scrollDirectionMask
    )
    precondition(
        CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollDirection_bottomToTop.rawValue
            == kCMTextDisplayFlag_scrollDirection_bottomToTop
    )
    precondition(
        CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollDirection_rightToLeft.rawValue
            == kCMTextDisplayFlag_scrollDirection_rightToLeft
    )
    precondition(
        CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollDirection_topToBottom.rawValue
            == kCMTextDisplayFlag_scrollDirection_topToBottom
    )
    precondition(
        CMFormatDescription.Extensions.Value.TextDisplayFlags.scrollDirection_leftToRight.rawValue
            == kCMTextDisplayFlag_scrollDirection_leftToRight
    )
    let next = extensions.index(after: extensions.startIndex)
    precondition(next.rawValue == 1)
    var hasher = Hasher()
    extensions.hash(into: &hasher)
    next.hash(into: &hasher)
    let firstValue = first.value
    firstValue.hash(into: &hasher)
    _ = hasher.finalize()
    _ = extensions.hashValue
    _ = next.hashValue
    _ = firstValue.hashValue
    let volume = CMFormatDescription.Extensions.Value.ContentColorVolume.ColorVolume(
        green: 1,
        blue: 2,
        red: 3
    )
    precondition(volume.green == 1)
    let primaries = CMFormatDescription.Extensions.Value.ContentColorVolume.ColorPrimaries(
        x: volume,
        y: volume
    )
    precondition(primaries.x.red == 3)
    var colorHasher = Hasher()
    volume.hash(into: &colorHasher)
    primaries.hash(into: &colorHasher)
    _ = volume.hashValue
    _ = primaries.hashValue
    let face: CMFormatDescription.Extensions.Value.FontFace = [.bold, .italic]
    precondition(face.contains(.bold))
    precondition(face.contains(.italic))
    precondition(CMFormatDescription.Extensions.Value.FontFace.underline.rawValue == 1 << 2)
    precondition(face.rawValue != 0)
    precondition(CMFormatDescription.TimeCode.Flag.dropFrame.rawValue == 1)
    let mask: CMFormatDescription.EqualityMask = [.magicCookie, .extensions]
    precondition(mask.contains(.magicCookie))
    precondition(!mask.contains(.channelLayout))
}
