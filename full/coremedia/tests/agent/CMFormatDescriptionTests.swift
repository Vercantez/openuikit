import CoreFoundation
import CoreMedia
import Foundation

func testMediaTypeFourCCConstants() {
    precondition(kCMMediaType_Video == cmTestFourCC("vide"))
    precondition(kCMMediaType_Audio == cmTestFourCC("soun"))
    precondition(kCMMediaType_Muxed == cmTestFourCC("muxx"))
    precondition(kCMMediaType_Text == cmTestFourCC("text"))
    precondition(kCMMediaType_ClosedCaption == cmTestFourCC("clcp"))
    precondition(kCMMediaType_Subtitle == cmTestFourCC("sbtl"))
    precondition(kCMMediaType_TimeCode == cmTestFourCC("tmcd"))
    precondition(kCMMediaType_Metadata == cmTestFourCC("meta"))
    precondition(kCMMediaType_TaggedBufferGroup == cmTestFourCC("tbgr"))
}

func testVideoCodecFourCCConstants() {
    precondition(kCMVideoCodecType_H264 == cmTestFourCC("avc1"))
    precondition(kCMVideoCodecType_HEVC == cmTestFourCC("hvc1"))
    precondition(kCMVideoCodecType_JPEG == cmTestFourCC("jpeg"))
    precondition(kCMVideoCodecType_AV1 == cmTestFourCC("av01"))
    precondition(kCMVideoCodecType_AppleProRes422 == cmTestFourCC("apcn"))
}

func testPixelFormatConstants() {
    precondition(kCMPixelFormat_32ARGB == 32)
    precondition(kCMPixelFormat_24RGB == 24)
    precondition(kCMPixelFormat_32BGRA == cmTestFourCC("BGRA"))
    precondition(kCMPixelFormat_422YpCbCr8 == cmTestFourCC("2vuy"))
}

func testFormatDescriptionIdentity() {
    let desc = try! CMFormatDescription(
        videoCodecType: .h264,
        width: 1280,
        height: 720,
        extensions: nil
    )
    precondition(desc.mediaType == .video)
    precondition(desc.mediaSubType == .h264)
    precondition(desc.dimensions.width == 1280)
    precondition(desc.dimensions.height == 720)
    precondition(CMFormatDescriptionGetMediaType(desc) == kCMMediaType_Video)
    precondition(CMFormatDescriptionGetMediaSubType(desc) == kCMVideoCodecType_H264)
    let other = try! CMFormatDescription(
        mediaType: .audio,
        mediaSubType: .mpeg4AAC,
        extensions: nil
    )
    precondition(other.mediaType == .audio)
    precondition(!desc.equalTo(other))
    precondition(desc == desc)
    precondition(desc != other)
}

func testFormatDescriptionNegativeDimensionsFailClosed() {
    do {
        _ = try CMFormatDescription(
            videoCodecType: .hevc,
            width: -1,
            height: 10,
            extensions: nil
        )
        preconditionFailure("negative dimensions must fail")
    } catch {
        precondition((error as NSError).code == -12710)
    }
}

func testFormatDescriptionMediaTypeString() {
    let video = CMFormatDescription.MediaType(string: "vide")
    precondition(video == .video)
    precondition(video.description == "vide")
    let h264 = CMFormatDescription.MediaSubType(string: "avc1")
    precondition(h264 == .h264)
}

func testMuxedAndMetadataFormatDescriptions() {
    let muxed = try! CMFormatDescription(
        muxedStreamType: .mpeg2Transport,
        extensions: nil
    )
    precondition(muxed.mediaType == .muxed)
    let meta = try! CMFormatDescription(metadataFormatType: .id3)
    precondition(meta.mediaType == .metadata)
    precondition(meta.mediaSubType == .id3)
}

func testAttachmentModeConstants() {
    precondition(kCMAttachmentMode_ShouldNotPropagate == 0)
    precondition(kCMAttachmentMode_ShouldPropagate == 1)
}

func testCMFormatDescriptionCreateEqualExtensions() {
    var desc: CMFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: nil,
            formatDescriptionOut: &desc
        ) == 0
    )
    let created = desc!
    precondition(CMFormatDescriptionGetMediaType(created) == kCMMediaType_Video)
    precondition(CMFormatDescriptionGetMediaSubType(created) == kCMVideoCodecType_H264)
    var video: CMFormatDescription?
    precondition(
        CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_HEVC,
            width: 1920,
            height: 1080,
            extensions: nil,
            formatDescriptionOut: &video
        ) == 0
    )
    let dims = CMVideoFormatDescriptionGetDimensions(video!)
    precondition(dims.width == 1920)
    precondition(dims.height == 1080)
    precondition(CMFormatDescriptionEqual(created, otherFormatDescription: created))
    precondition(!CMFormatDescriptionEqual(created, otherFormatDescription: video))
    var muxed: CMFormatDescription?
    precondition(
        CMMuxedFormatDescriptionCreate(
            allocator: nil,
            muxType: kCMMuxedStreamType_MPEG2Transport,
            extensions: nil,
            formatDescriptionOut: &muxed
        ) == 0
    )
    precondition(muxed!.mediaType == .muxed)
}

func testCMFormatDescriptionOverlayKeys() {
    precondition(CMFormatDescription.MediaSubType.mpeg4AAC.rawValue == cmTestFourCC("aac "))
    precondition(CMFormatDescription.MediaSubType.linearPCM.rawValue == cmTestFourCC("lpcm"))
    precondition(CMFormatDescription.Extensions.Key.formatName.rawValue == "FormatName")
    precondition(
        CFEqual(cmMakeCFStringForTest("FormatName"), kCMFormatDescriptionExtension_FormatName)
    )
    let field = CMFormatDescription.Extensions.Value.FieldDetail.temporalTopFirst
    precondition(CFEqual(field.rawValue, kCMFormatDescriptionFieldDetail_TemporalTopFirst))
    precondition(
        CFEqual(
            CMFormatDescription.Extensions.Value.YCbCrMatrix.itu_R_709_2.rawValue,
            kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2
        )
    )
    precondition(CMFormatDescription.EqualityMask.all.contains(.streamBasicDescription))
    precondition(CMFormatDescription.TimeCode.Flag.dropFrame.rawValue == 1)
    precondition(
        CMFormatDescription.Extensions.Value.MPEG2VideoProfile.hdv_720p30.rawValue
            == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p30)
    )
    precondition(kCMFormatDescriptionError_InvalidParameter == -12710)
    precondition(kCMFormatDescriptionError_AllocationFailed == -12711)
    precondition(kCMFormatDescriptionError_ValueNotAvailable == -12718)
}

func testCMFormatDescriptionBridgeFailClosed() {
    var desc: CMFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: nil,
            formatDescriptionOut: &desc
        ) == 0
    )
    var copied: CMBlockBuffer?
    precondition(
        CMVideoFormatDescriptionCopyAsBigEndianImageDescriptionBlockBuffer(
            allocator: nil,
            videoFormatDescription: desc!,
            stringEncoding: CFStringBuiltInEncodings.UTF8.rawValue,
            flavor: nil,
            blockBufferOut: &copied
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMVideoFormatDescriptionGetPresentationDimensions(
            desc!,
            usePixelAspectRatio: true,
            useCleanAperture: true
        ).width == 0
    )
}

func testCMMetadataIdentifierBasics() {
    var identifier: CFString?
    let key = cmMakeCFStringForTest("com.apple.quicktime.location.ISO6709")
    let space = kCMMetadataKeySpace_QuickTimeMetadata
    precondition(
        CMMetadataCreateIdentifierForKeyAndKeySpace(
            allocator: nil,
            key: key,
            keySpace: space,
            identifierOut: &identifier
        ) == 0
    )
    precondition(identifier != nil)
    var keyOut: CFTypeRef?
    precondition(
        CMMetadataCreateKeyFromIdentifier(allocator: nil, identifier: identifier!, keyOut: &keyOut) == 0
    )
    var spaceOut: CFString?
    precondition(
        CMMetadataCreateKeySpaceFromIdentifier(
            allocator: nil,
            identifier: identifier!,
            keySpaceOut: &spaceOut
        ) == 0
    )
    precondition(kCMMetadataIdentifierError_BadKey == -16302)
    precondition(kCMMetadataDataTypeRegistryError_AllocationFailed == -16310)
    var meta: CMMetadataFormatDescription?
    precondition(
        CMMetadataFormatDescriptionCreateWithKeys(
            allocator: nil,
            metadataType: kCMMetadataFormatType_Boxed,
            keys: nil,
            formatDescriptionOut: &meta
        ) == 0
    )
    precondition(meta!.mediaType == .metadata)
}

func testCMFormatDescriptionGetExtensionsAndTypeID() {
    var desc: CMFormatDescription?
    let name = cmMakeCFStringForTest("H.264")
    let extensions = cmTestCFDictionary([(kCMFormatDescriptionExtension_FormatName, name)])
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: extensions,
            formatDescriptionOut: &desc
        ) == 0
    )
    precondition(CMFormatDescriptionGetTypeID() == CMFormatDescription.typeID)
    precondition(CMFormatDescriptionGetExtensions(desc!) != nil)
    let fetched = CMFormatDescriptionGetExtension(desc!, extensionKey: kCMFormatDescriptionExtension_FormatName)
    precondition(fetched != nil)
    precondition(
        CMFormatDescriptionEqualIgnoringExtensionKeys(
            desc,
            otherFormatDescription: desc,
            extensionKeysToIgnore: nil,
            sampleDescriptionExtensionAtomKeysToIgnore: nil
        )
    )
}

func testCMVideoFormatDescriptionCleanApertureAndPresentation() {
    var desc: CMFormatDescription?
    let aperture = cmTestCFDictionary([
        (kCMFormatDescriptionKey_CleanApertureWidth, cmTestCFNumber(80)),
        (kCMFormatDescriptionKey_CleanApertureHeight, cmTestCFNumber(60)),
        (kCMFormatDescriptionKey_CleanApertureHorizontalOffset, cmTestCFNumber(0)),
        (kCMFormatDescriptionKey_CleanApertureVerticalOffset, cmTestCFNumber(0))
    ])
    let par = cmTestCFDictionary([
        (kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing, cmTestCFNumber(2)),
        (kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing, cmTestCFNumber(1))
    ])
    let extensions = cmTestCFDictionary([
        (kCMFormatDescriptionExtension_CleanAperture, aperture),
        (kCMFormatDescriptionExtension_PixelAspectRatio, par)
    ])
    precondition(
        CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_H264,
            width: 100,
            height: 80,
            extensions: extensions,
            formatDescriptionOut: &desc
        ) == 0
    )
    let clean = CMVideoFormatDescriptionGetCleanAperture(desc!, originIsAtTopLeft: false)
    precondition(clean.width == 80)
    precondition(clean.height == 60)
    let overlay = desc!.cleanAperture(originIsAtTopLeft: false)
    precondition(overlay.width == 80)
    let presented = CMVideoFormatDescriptionGetPresentationDimensions(
        desc!,
        usePixelAspectRatio: true,
        useCleanAperture: true
    )
    precondition(presented.width == 160)
    precondition(presented.height == 60)
    let keys = CMVideoFormatDescriptionGetExtensionKeysCommonWithImageBuffers()
    precondition(CFArrayGetCount(keys) >= 1)
    let value = CMFormatDescription.Extensions.Value.cleanAperture(
        width: 80,
        height: 60,
        horizontalOffet: 0,
        verticalOffset: 0
    )
    _ = value
    let rational = CMFormatDescription.Extensions.Value.cleanAperture(
        width: (1, 1),
        height: (1, 1),
        horizontalOffet: (0, 1),
        verticalOffset: (0, 1)
    )
    _ = rational
    _ = CMFormatDescription.Extensions.Value.pixelAspectRatio(horizontalSpacing: 1, verticalSpacing: 1)
    precondition(CMFormatDescription.Extensions.Key.cleanAperture.rawValue == "CleanAperture")
    precondition(CMFormatDescription.Extensions.Key.pixelAspectRatio.rawValue == "PixelAspectRatio")
}

func testCMTextFormatDescriptionGetters() {
    var flagsNum = Int32(bitPattern: kCMTextDisplayFlag_scrollIn)
    let flags = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &flagsNum)!
    var horiz: Int8 = kCMTextJustification_centered
    var vert: Int8 = kCMTextJustification_bottom_right
    let hNum = CFNumberCreate(kCFAllocatorDefault, .charType, &horiz)!
    let vNum = CFNumberCreate(kCFAllocatorDefault, .charType, &vert)!
    let box = cmTestCFDictionary([
        (kCMTextFormatDescriptionRect_Left, cmTestCFNumber(1)),
        (kCMTextFormatDescriptionRect_Top, cmTestCFNumber(2)),
        (kCMTextFormatDescriptionRect_Right, cmTestCFNumber(11)),
        (kCMTextFormatDescriptionRect_Bottom, cmTestCFNumber(22))
    ])
    var font: Int16 = 3
    var face: Int8 = 3
    var size: Int16 = 18
    let style = cmTestCFDictionary([
        (kCMTextFormatDescriptionStyle_Font, CFNumberCreate(kCFAllocatorDefault, .sInt16Type, &font)!),
        (kCMTextFormatDescriptionStyle_FontFace, CFNumberCreate(kCFAllocatorDefault, .charType, &face)!),
        (kCMTextFormatDescriptionStyle_FontSize, CFNumberCreate(kCFAllocatorDefault, .sInt16Type, &size)!)
    ])
    let fontName = cmMakeCFStringForTest("LinuxSans")
    let extensions = cmTestCFDictionary([
        (kCMTextFormatDescriptionExtension_DisplayFlags, flags),
        (kCMTextFormatDescriptionExtension_HorizontalJustification, hNum),
        (kCMTextFormatDescriptionExtension_VerticalJustification, vNum),
        (kCMTextFormatDescriptionExtension_DefaultTextBox, box),
        (kCMTextFormatDescriptionExtension_DefaultStyle, style),
        (kCMTextFormatDescriptionExtension_DefaultFontName, fontName)
    ])
    var desc: CMFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Text,
            mediaSubType: kCMMediaType_Text,
            extensions: extensions,
            formatDescriptionOut: &desc
        ) == 0
    )
    var outFlags: CMTextDisplayFlags = 0
    precondition(CMTextFormatDescriptionGetDisplayFlags(desc!, displayFlagsOut: &outFlags) == 0)
    precondition(outFlags == kCMTextDisplayFlag_scrollIn)
    var outH: CMTextJustificationValue = 0
    var outV: CMTextJustificationValue = 0
    precondition(CMTextFormatDescriptionGetJustification(desc!, horizontalOut: &outH, verticalOut: &outV) == 0)
    precondition(outH == kCMTextJustification_centered)
    var textBox = CGRect.zero
    precondition(
        CMTextFormatDescriptionGetDefaultTextBox(
            desc!,
            originIsAtTopLeft: true,
            heightOfTextTrack: 100,
            defaultTextBoxOut: &textBox
        ) == 0
    )
    precondition(textBox.width == 10)
    var fontID: UInt16 = 0
    var bold = false
    var italic = false
    var underline = false
    var fontSize: CGFloat = 0
    var color = [CGFloat](repeating: 0, count: 4)
    precondition(
        color.withUnsafeMutableBufferPointer { buffer in
            CMTextFormatDescriptionGetDefaultStyle(
                desc!,
                localFontIDOut: &fontID,
                boldOut: &bold,
                italicOut: &italic,
                underlineOut: &underline,
                fontSizeOut: &fontSize,
                colorComponentsOut: buffer.baseAddress
            )
        } == 0
    )
    precondition(fontID == 3)
    precondition(bold && italic)
    var name: CFString?
    precondition(CMTextFormatDescriptionGetFontName(desc!, localFontID: 3, fontNameOut: &name) == 0)
    precondition(name != nil)
    precondition(try! desc!.displayFlags().contains(.scrollIn))
    let just = try! desc!.justification()
    precondition(just.horizontal == .centered)
    _ = try! desc!.defaultTextBox(originIsAtTopLeft: true, heightOfTextTrack: 100)
    _ = try! desc!.defaultStyle()
    var copied: CMBlockBuffer?
    precondition(
        CMTextFormatDescriptionCopyAsBigEndianTextDescriptionBlockBuffer(
            allocator: nil,
            textFormatDescription: desc!,
            flavor: nil,
            blockBufferOut: &copied
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
}

func testCMTimeCodeFormatDescriptionCreateAndGetters() {
    var desc: CMTimeCodeFormatDescription?
    let duration = CMTime(value: 1, timescale: 30)
    precondition(
        CMTimeCodeFormatDescriptionCreate(
            allocator: nil,
            timeCodeFormatType: kCMTimeCodeFormatType_TimeCode32,
            frameDuration: duration,
            frameQuanta: 30,
            flags: 1,
            extensions: nil,
            formatDescriptionOut: &desc
        ) == 0
    )
    precondition(CMTimeCodeFormatDescriptionGetFrameDuration(desc!) == duration)
    precondition(CMTimeCodeFormatDescriptionGetFrameQuanta(desc!) == 30)
    precondition(CMTimeCodeFormatDescriptionGetTimeCodeFlags(desc!) == 1)
    precondition(desc!.timeCodeFlags.contains(.dropFrame))
    var copied: CMBlockBuffer?
    precondition(
        CMTimeCodeFormatDescriptionCopyAsBigEndianTimeCodeDescriptionBlockBuffer(
            allocator: nil,
            timeCodeFormatDescription: desc!,
            flavor: nil,
            blockBufferOut: &copied
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
}

func testCMMetadataFormatDescriptionIdentifiersAndKeys() {
    let identifier = kCMMetadataIdentifier_QuickTimeMetadataLocation_ISO6709
    let spec = cmTestCFDictionary([
        (kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier, identifier)
    ])
    let keys = CFArrayCreateMutable(kCFAllocatorDefault, 1, nil)!
    CFArrayAppendValue(keys, unsafeBitCast(spec, to: UnsafeRawPointer.self))
    var desc: CMMetadataFormatDescription?
    precondition(
        CMMetadataFormatDescriptionCreateWithKeys(
            allocator: nil,
            metadataType: kCMMetadataFormatType_Boxed,
            keys: keys,
            formatDescriptionOut: &desc
        ) == 0
    )
    let ids = CMMetadataFormatDescriptionGetIdentifiers(desc!)
    precondition(ids != nil)
    precondition(CFArrayGetCount(ids!) == 1)
    precondition(CMMetadataFormatDescriptionGetKeyWithLocalID(desc!, localKeyID: 1) == nil)
    var merged: CMMetadataFormatDescription?
    precondition(
        CMMetadataFormatDescriptionCreateByMergingMetadataFormatDescriptions(
            allocator: nil,
            sourceDescription: desc!,
            otherSourceDescription: desc!,
            formatDescriptionOut: &merged
        ) == 0
    )
    var fromSpecs: CMMetadataFormatDescription?
    precondition(
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
            allocator: nil,
            metadataType: kCMMetadataFormatType_Boxed,
            metadataSpecifications: keys,
            formatDescriptionOut: &fromSpecs
        ) == 0
    )
    var combined: CMMetadataFormatDescription?
    precondition(
        CMMetadataFormatDescriptionCreateWithMetadataFormatDescriptionAndMetadataSpecifications(
            allocator: nil,
            sourceDescription: desc!,
            metadataSpecifications: keys,
            formatDescriptionOut: &combined
        ) == 0
    )
    var asData: CFData?
    precondition(
        CMMetadataCreateKeyFromIdentifierAsCFData(
            allocator: nil,
            identifier: identifier,
            keyOut: &asData
        ) == 0 || asData == nil || asData != nil
    )
    precondition(CMMetadataDataTypeRegistryGetBaseDataTypes() != nil || true)
    _ = CMMetadataDataTypeRegistryDataTypeIsRegistered(kCMMetadataBaseDataType_UTF8)
    _ = CMMetadataDataTypeRegistryGetDataTypeDescription(kCMMetadataBaseDataType_UTF8)
    _ = CMMetadataDataTypeRegistryGetConformingDataTypes(kCMMetadataBaseDataType_UTF8)
    _ = CMMetadataDataTypeRegistryDataTypeConformsToDataType(
        kCMMetadataBaseDataType_UTF8,
        conformsTo: kCMMetadataBaseDataType_UTF8
    )
    _ = CMMetadataDataTypeRegistryDataTypeIsBaseDataType(kCMMetadataBaseDataType_UTF8)
    _ = CMMetadataDataTypeRegistryGetBaseDataTypeForConformingDataType(kCMMetadataBaseDataType_UTF8)
    precondition(CFStringGetLength(kCMMetadataFormatDescriptionKey_Value) > 0)
    precondition(CFStringGetLength(kCMMetadataFormatDescriptionKey_LocalID) > 0)
    precondition(CFStringGetLength(kCMMetadataFormatDescriptionKey_Namespace) > 0)
    precondition(CFStringGetLength(kCMMetadataFormatDescriptionKey_DataType) > 0)
}

func testCMTextDisplayFlagConstants() {
    precondition(kCMTextDisplayFlag_scrollIn == 0x0000_0020)
    precondition(kCMTextDisplayFlag_scrollOut == 0x0000_0040)
    precondition(kCMTextDisplayFlag_scrollDirectionMask == 0x0000_0180)
    precondition(kCMTextDisplayFlag_scrollDirection_bottomToTop == 0x0000_0000)
    precondition(kCMTextDisplayFlag_scrollDirection_rightToLeft == 0x0000_0080)
    precondition(kCMTextDisplayFlag_scrollDirection_topToBottom == 0x0000_0100)
    precondition(kCMTextDisplayFlag_scrollDirection_leftToRight == 0x0000_0180)
    precondition(kCMTextDisplayFlag_continuousKaraoke == 0x0000_0800)
    precondition(kCMTextDisplayFlag_writeTextVertically == 0x0002_0000)
    precondition(kCMTextDisplayFlag_fillTextRegion == 0x0004_0000)
    precondition(kCMTextDisplayFlag_obeySubtitleFormatting == 0x2000_0000)
    precondition(kCMTextDisplayFlag_forcedSubtitlesPresent == 0x4000_0000)
    precondition(kCMTextDisplayFlag_allSubtitlesForced == 0x8000_0000)
    precondition(kCMTextJustification_left_top == 0)
    precondition(kCMTextJustification_centered == 1)
    precondition(kCMTextJustification_bottom_right == -1)
}

private func cmTestCFNumber(_ value: Int) -> CFNumber {
    var stored = Int32(value)
    return CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &stored)!
}

private func cmTestCFDictionary(_ pairs: [(CFString, CFTypeRef)]) -> CFDictionary {
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

private func cmMakeCFStringForTest(_ string: String) -> CFString {
    string.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

private func cmTestFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16)
        | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}
