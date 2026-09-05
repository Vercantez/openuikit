import Foundation
import VideoToolbox

func expect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("VIDEOTOOLBOX_RUNTIME_FAIL \(message)")
    }
}

func expectStatus(_ status: OSStatus, _ expected: OSStatus, _ message: String) {
    expect(status == expected, "\(message) got \(status) expected \(expected)")
}

let errorTable: [(String, OSStatus)] = VTHostAllErrorConstants()
expect(errorTable.count >= 40, "error table size")
for (name, value) in errorTable {
    expect(value != 0 || name.contains("Ok"), "nonzero \(name)")
}

expect(kVTPropertyNotSupportedErr == -12900, "kVTPropertyNotSupportedErr")
expect(kVTPropertyReadOnlyErr == -12901, "kVTPropertyReadOnlyErr")
expect(kVTParameterErr == -12902, "kVTParameterErr")
expect(kVTInvalidSessionErr == -12903, "kVTInvalidSessionErr")
expect(kVTAllocationFailedErr == -12904, "kVTAllocationFailedErr")
expect(kVTPixelTransferNotSupportedErr == -12905, "pixel transfer")
expect(kVTCouldNotFindVideoDecoderErr == -12906, "decoder missing")
expect(kVTCouldNotCreateInstanceErr == -12907, "instance")
expect(kVTCouldNotFindVideoEncoderErr == -12908, "encoder missing")
expect(kVTVideoDecoderBadDataErr == -12909, "bad data")
expect(kVTVideoDecoderUnsupportedDataFormatErr == -12910, "unsupported format")
expect(kVTVideoDecoderMalfunctionErr == -12911, "decoder malfunction")
expect(kVTVideoEncoderMalfunctionErr == -12912, "encoder malfunction")
expect(kVTVideoDecoderNotAvailableNowErr == -12913, "decoder not now")
expect(kVTImageRotationNotSupportedErr == -12914, "image rotation")
expect(kVTPixelRotationNotSupportedErr == -12914, "pixel rotation")
expect(kVTVideoEncoderNotAvailableNowErr == -12915, "encoder not now")
expect(kVTFormatDescriptionChangeNotSupportedErr == -12916, "format change")
expect(kVTInsufficientSourceColorDataErr == -12917, "color data")
expect(kVTCouldNotCreateColorCorrectionDataErr == -12918, "color correction create")
expect(kVTColorSyncTransformConvertFailedErr == -12919, "colorsync")
expect(kVTVideoDecoderAuthorizationErr == -12210, "decoder auth")
expect(kVTVideoEncoderAuthorizationErr == -12211, "encoder auth")
expect(kVTColorCorrectionPixelTransferFailedErr == -12212, "color xfer")
expect(kVTMultiPassStorageIdentifierMismatchErr == -12913, "multipass mismatch")
expect(kVTMultiPassStorageInvalidErr == -12214, "multipass invalid")
expect(kVTFrameSiloInvalidTimeStampErr == -12215, "silo ts")
expect(kVTFrameSiloInvalidTimeRangeErr == -12216, "silo range")
expect(kVTCouldNotFindTemporalFilterErr == -12217, "temporal")
expect(kVTPixelTransferNotPermittedErr == -12218, "xfer permitted")
expect(kVTColorCorrectionImageRotationFailedErr == -12219, "color rotate")
expect(kVTVideoDecoderRemovedErr == -17690, "decoder removed")
expect(kVTSessionMalfunctionErr == -17691, "session malfunction")
expect(kVTVideoDecoderNeedsRosettaErr == -17692, "decoder rosetta")
expect(kVTVideoEncoderNeedsRosettaErr == -17693, "encoder rosetta")
expect(kVTVideoDecoderReferenceMissingErr == -17694, "ref missing")
expect(kVTVideoDecoderCallbackMessagingErr == -17695, "callback messaging")
expect(kVTVideoDecoderUnknownErr == -17696, "decoder unknown")
expect(kVTExtensionDisabledErr == -17697, "ext disabled")
expect(kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr == -17698, "mv-hevc ids")
expect(kVTCouldNotOutputTaggedBufferGroupErr == -17699, "tagged group")
expect(kVTCouldNotFindExtensionErr == -19510, "extension")
expect(kVTExtensionConflictErr == -19511, "ext conflict")
expect(kVTVideoEncoderAutoWhiteBalanceNotLockedErr == -19512, "awb")

expect(VTDecodeFrameFlags.enableAsynchronousDecompression.rawValue == kVTDecodeFrame_EnableAsynchronousDecompression, "decode flag")
expect(VTDecodeFrameFlags.doNotOutputFrame.rawValue == kVTDecodeFrame_DoNotOutputFrame, "do not output")
expect(VTDecodeFrameFlags.oneXRealTimePlayback.rawValue == kVTDecodeFrame_1xRealTimePlayback, "1x")
expect(VTDecodeFrameFlags.enableTemporalProcessing.rawValue == kVTDecodeFrame_EnableTemporalProcessing, "temporal")
expect(VTDecodeInfoFlags.asynchronous.rawValue == kVTDecodeInfo_Asynchronous, "info async")
expect(VTDecodeInfoFlags.frameDropped.rawValue == kVTDecodeInfo_FrameDropped, "info drop")
expect(VTDecodeInfoFlags.imageBufferModifiable.rawValue == kVTDecodeInfo_ImageBufferModifiable, "modifiable")
expect(VTDecodeInfoFlags.skippedLeadingFrameDropped.rawValue == kVTDecodeInfo_SkippedLeadingFrameDropped, "skipped")
expect(VTDecodeInfoFlags.frameInterrupted.rawValue == kVTDecodeInfo_FrameInterrupted, "interrupted")
expect(VTEncodeInfoFlags.asynchronous.rawValue == kVTEncodeInfo_Asynchronous, "enc async")
expect(VTEncodeInfoFlags.frameDropped.contains(.frameDropped), "encode flag")
expect(VTCompressionSessionOptionFlags.beginFinalPass.rawValue == kVTCompressionSessionBeginFinalPass, "begin pass")

let keys = VTHostAllPropertyKeys()
expect(keys.count >= 300, "key count \(keys.count)")
expect(Set(keys).count == keys.count, "keys unique")
for key in keys {
    expect(!key.isEmpty, "nonempty key")
}
expect(kVTCompressionPropertyKey_AverageBitRate != kVTCompressionPropertyKey_Quality, "keys distinct")
expect(kVTScalingMode_Trim == "kVTScalingMode_Trim", "trim payload")
expect(kVTScalingMode_Normal != kVTScalingMode_Letterbox, "scale modes")
expect(kVTProfileLevel_H264_Baseline_AutoLevel != kVTProfileLevel_HEVC_Main_AutoLevel, "profiles")
expect(kVTH264EntropyMode_CAVLC != kVTH264EntropyMode_CABAC, "entropy")
expect(kVTRotation_CW90 != kVTRotation_CCW90, "rotation")
expect(kVTAlphaChannelMode_StraightAlpha != kVTAlphaChannelMode_PremultipliedAlpha, "alpha")
expect(kVTHeroEye_Left != kVTHeroEye_Right, "hero")
expect(kVTCompressionPreset_HighQuality != kVTCompressionPreset_HighSpeed, "presets")
expect(kVTPropertyType_Boolean != kVTPropertyType_Number, "prop types")
expect(kVTPropertyReadWriteStatus_ReadOnly != kVTPropertyReadWriteStatus_ReadWrite, "rw")
expect(kVTVideoEncoderList_EncoderID != kVTVideoEncoderList_CodecType, "encoder list keys")
expect(kVTDecompressionProperty_OnlyTheseFrames_IFrames != kVTDecompressionProperty_OnlyTheseFrames_KeyFrames, "only frames")
expect(kVTDownsamplingMode_Decimate != kVTDownsamplingMode_Average, "downsample")
expect(kVTHDRMetadataInsertionMode_None != kVTHDRMetadataInsertionMode_Auto, "hdr mode")
expect(kVTProjectionKind_Rectilinear != kVTProjectionKind_Equirectangular, "projection")
expect(kVTViewPackingKind_SideBySide != kVTViewPackingKind_OverUnder, "packing")
expect(kVTRAWProcessingParameterValueType_Boolean != kVTRAWProcessingParameterValueType_Float, "raw types")
expect(kVTExtensionProperties_ExtensionIdentifierKey != kVTExtensionProperties_ExtensionNameKey, "ext keys")
expect(kVTDecodeFrameOptionKey_ContentAnalyzerRotation != kVTDecodeFrameOptionKey_ContentAnalyzerCropRectangle, "decode opts")
expect(kVTEncodeFrameOptionKey_ForceKeyFrame != kVTEncodeFrameOptionKey_ForceLTRRefresh, "encode opts")
expect(kVTSampleAttachmentKey_QualityMetrics != kVTSampleAttachmentKey_RequireLTRAcknowledgementToken, "attachments")
expect(
    kVTSampleAttachmentQualityMetricsKey_LumaMeanSquaredError
        != kVTSampleAttachmentQualityMetricsKey_ChromaBlueMeanSquaredError,
    "mse keys"
)

var compression: OpaquePointer?
let compressionStatus = VTCompressionSessionCreate(
    width: 1280,
    height: 720,
    codecType: kVTVideoCodecType_H264,
    sessionOut: &compression
)
expectStatus(compressionStatus, kVTCouldNotFindVideoEncoderErr, "h264 compression create")
expect(compression == nil, "compression session nil")

var jpegEncoder: OpaquePointer?
expectStatus(
    VTCompressionSessionCreate(
        width: 64,
        height: 64,
        codecType: kVTVideoCodecType_JPEG,
        sessionOut: &jpegEncoder
    ),
    kVTCouldNotFindVideoEncoderErr,
    "jpeg encoder unreachable"
)

var hevc: OpaquePointer?
expectStatus(
    VTCompressionSessionCreate(width: 1920, height: 1080, codecType: kVTVideoCodecType_HEVC, sessionOut: &hevc),
    kVTCouldNotFindVideoEncoderErr,
    "hevc encoder"
)

var badSize: OpaquePointer?
expectStatus(
    VTCompressionSessionCreate(width: 0, height: 720, codecType: kVTVideoCodecType_H264, sessionOut: &badSize),
    kVTParameterErr,
    "compression parameter"
)

expect(VTCompressionSessionEncodeFrame(nil) == kVTInvalidSessionErr, "encode nil")
expect(VTCompressionSessionCompleteFrames(nil) == kVTInvalidSessionErr, "complete nil")
expect(VTCompressionSessionPrepareToEncodeFrames(nil) == kVTInvalidSessionErr, "prepare nil")
expect(VTCompressionSessionGetPixelBufferPool(nil) == nil, "pool nil")
expect(VTCompressionSessionBeginPass(nil, flags: []) == kVTInvalidSessionErr, "begin pass nil")
var further = true
expect(VTCompressionSessionEndPass(nil, furtherPassesRequestedOut: &further) == kVTInvalidSessionErr, "end pass nil")
expect(!further, "further false")
expect(VTCompressionSessionGetTimeRangesForNextPass(nil) == kVTInvalidSessionErr, "next pass nil")
expect(VTCompressionSessionEncodeMultiImageFrame(nil) == kVTInvalidSessionErr, "multi image")
expect(VTCompressionSessionEncodeMultiImageFrameWithOutputHandler(nil) == kVTInvalidSessionErr, "multi image handler")

var missingFormat: OpaquePointer?
expectStatus(
    VTDecompressionSessionCreate(sessionOut: &missingFormat),
    kVTParameterErr,
    "decode create needs format"
)

var h264Decoder: OpaquePointer?
let h264Format = VTVideoFormatDescription(codecType: kVTVideoCodecType_H264, width: 1280, height: 720)
expectStatus(
    VTDecompressionSessionCreate(formatDescription: h264Format, outputCallback: nil, sessionOut: &h264Decoder),
    kVTCouldNotFindVideoDecoderErr,
    "h264 decoder missing"
)
expect(h264Decoder == nil, "h264 decoder nil")

var hevcDecoder: OpaquePointer?
expectStatus(
    VTDecompressionSessionCreate(
        formatDescription: VTVideoFormatDescription(codecType: kVTVideoCodecType_HEVC, width: 64, height: 64),
        outputCallback: nil,
        sessionOut: &hevcDecoder
    ),
    kVTCouldNotFindVideoDecoderErr,
    "hevc decoder missing"
)

var jpegDecoder: OpaquePointer?
expectStatus(
    VTDecompressionSessionCreate(
        formatDescription: VTVideoFormatDescription(codecType: kVTVideoCodecType_JPEG, width: 64, height: 64),
        outputCallback: nil,
        sessionOut: &jpegDecoder
    ),
    kVTCouldNotFindVideoDecoderErr,
    "jpeg decoder unreachable"
)

var sourceBGRA: OpaquePointer?
expectStatus(
    VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
    0,
    "source bgra"
)
expectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill source")
expect(VTHostPixelBufferGetWidth(sourceBGRA) == 4, "width")
expect(VTHostPixelBufferGetHeight(sourceBGRA) == 4, "height")
expect(VTHostPixelBufferGetPixelFormat(sourceBGRA) == kVTPixelFormat_32BGRA, "format")
expect(VTHostPixelBufferGetByte(sourceBGRA, x: 0, y: 0, channel: 0) == 10, "red byte")
expect(VTHostPixelBufferGetByte(sourceBGRA, x: 0, y: 0, channel: 1) == 20, "green byte")
expect(VTHostPixelBufferGetByte(sourceBGRA, x: 0, y: 0, channel: 2) == 30, "blue byte")

let bgraFormat = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
var decodedImage: OpaquePointer?
var decodedPTS = VTMediaTime.invalid
var decodedDuration = VTMediaTime.invalid
var callbackCount = 0
var decoder: OpaquePointer?
expectStatus(
    VTDecompressionSessionCreate(
        formatDescription: bgraFormat,
        destinationPixelFormat: kVTPixelFormat_32BGRA,
        outputCallback: { status, info, image, pts, duration, _ in
            expect(status == 0, "callback status")
            expect(info.contains(.imageBufferModifiable), "modifiable flag")
            decodedImage = image
            decodedPTS = pts
            decodedDuration = duration
            callbackCount += 1
        },
        sessionOut: &decoder
    ),
    0,
    "bgra decoder create"
)
expect(decoder != nil, "decoder session")

let pts = VTMediaTime(value: 1001, timescale: 30)
let duration = VTMediaTime(value: 1, timescale: 30)
var sample: OpaquePointer?
expectStatus(
    VTHostCreateSampleBuffer(
        format: bgraFormat,
        pixelBuffer: sourceBGRA,
        presentationTimeStamp: pts,
        duration: duration,
        sampleBufferOut: &sample
    ),
    0,
    "sample"
)

var infoFlags = VTDecodeInfoFlags(rawValue: 0)
expectStatus(
    VTDecompressionSessionDecodeFrame(
        decoder,
        sampleBuffer: sample,
        decodeFlags: [],
        sourceFrameRefCon: nil,
        infoFlagsOut: &infoFlags
    ),
    0,
    "decode passthrough"
)
expect(callbackCount == 1, "sync callback")
expect(decodedPTS == pts, "pts forwarded")
expect(decodedDuration == duration, "duration forwarded")
expect(decodedImage != nil, "decoded image")
expect(VTHostPixelBufferGetByte(decodedImage, x: 1, y: 1, channel: 0) == 10, "passthrough red")
expect(VTHostPixelBufferGetByte(decodedImage, x: 1, y: 1, channel: 2) == 30, "passthrough blue")

expect(VTDecompressionSessionCanAcceptFormatDescription(decoder, formatDescription: bgraFormat), "accept same")
expect(
    !VTDecompressionSessionCanAcceptFormatDescription(
        decoder,
        formatDescription: VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 8, height: 4)
    ),
    "reject size change"
)
expectStatus(
    VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions, value: "true"),
    0,
    "allow size change"
)
expect(
    VTDecompressionSessionCanAcceptFormatDescription(
        decoder,
        formatDescription: VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 8, height: 4)
    ),
    "accept size change after property"
)
expect(
    !VTDecompressionSessionCanAcceptFormatDescription(
        decoder,
        formatDescription: VTVideoFormatDescription(codecType: kVTVideoCodecType_H264, width: 4, height: 4)
    ),
    "reject other codec"
)

var black: OpaquePointer?
expectStatus(VTDecompressionSessionCopyBlackPixelBuffer(decoder, pixelBufferOut: &black), 0, "black")
expect(VTHostPixelBufferGetByte(black, x: 0, y: 0, channel: 0) == 0, "black r")
expectStatus(VTDecompressionSessionFinishDelayedFrames(decoder), 0, "finish delayed")
expectStatus(VTDecompressionSessionWaitForAsynchronousFrames(decoder), 0, "wait idle")

var dropInfo = VTDecodeInfoFlags(rawValue: 0)
expectStatus(
    VTDecompressionSessionDecodeFrame(
        decoder,
        sampleBuffer: sample,
        decodeFlags: .doNotOutputFrame,
        sourceFrameRefCon: nil,
        infoFlagsOut: &dropInfo
    ),
    0,
    "drop"
)
expect(dropInfo.contains(.frameDropped), "dropped flag")
expect(callbackCount == 1, "no extra callback")

var asyncInfo = VTDecodeInfoFlags(rawValue: 0)
expectStatus(
    VTDecompressionSessionDecodeFrame(
        decoder,
        sampleBuffer: sample,
        decodeFlags: .enableAsynchronousDecompression,
        sourceFrameRefCon: nil,
        infoFlagsOut: &asyncInfo
    ),
    0,
    "async decode"
)
expect(asyncInfo.contains(.asynchronous), "async info")
expectStatus(VTDecompressionSessionWaitForAsynchronousFrames(decoder), 0, "wait async")
expect(callbackCount == 2, "async callback delivered")

var handlerInfo = VTDecodeInfoFlags(rawValue: 0)
var handlerCalled = false
expectStatus(
    VTDecompressionSessionDecodeFrameWithOutputHandler(
        decoder,
        sampleBuffer: sample,
        decodeFlags: [],
        infoFlagsOut: &handlerInfo,
        outputHandler: { status, _, image, _, _, _ in
            expect(status == 0, "handler status")
            expect(image != nil, "handler image")
            handlerCalled = true
        }
    ),
    0,
    "output handler"
)
expect(handlerCalled, "handler called")

var supported: [String: String] = [:]
expectStatus(VTSessionCopySupportedPropertyDictionary(decoder, propertiesOut: &supported), 0, "decomp supported")
expect(supported[kVTDecompressionPropertyKey_RealTime] != nil, "realtime in catalog")
expect(supported[kVTDecompressionPropertyKey_ThreadCount]?.contains(kVTPropertyType_Number) == true, "thread type")
expectStatus(VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, value: "4"), 0, "set threads")
var copied: String?
expectStatus(
    VTSessionCopyProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, valueOut: &copied),
    0,
    "copy threads"
)
expect(copied == "4", "thread value")
expectStatus(
    VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, value: "0"),
    kVTParameterErr,
    "thread range"
)
expectStatus(
    VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder, value: "true"),
    kVTPropertyReadOnlyErr,
    "hw decoder readonly"
)
expectStatus(
    VTSessionSetProperty(decoder, key: "not-a-real-key", value: "x"),
    kVTPropertyNotSupportedErr,
    "unknown key"
)

expect(VTDecompressionSessionDecodeFrameWithMultiImageCapableOutputHandler(nil) == kVTInvalidSessionErr, "multi")
expect(VTDecompressionSessionDecodeFrameWithOptions(nil) == kVTInvalidSessionErr, "opts nil")
expect(VTDecompressionSessionDecodeFrameWithOptionsAndOutputHandler(nil) == kVTInvalidSessionErr, "opts handler nil")
expect(VTDecompressionSessionSetMultiImageCallback(decoder) == kVTPropertyNotSupportedErr, "multi callback")
VTDecompressionSessionInvalidate(decoder)
expect(VTDecompressionSessionFinishDelayedFrames(decoder) == kVTInvalidSessionErr, "invalid after invalidate")

expect(VTIsHardwareDecodeSupported(kVTVideoCodecType_H264) == false, "hardware decode")
expect(VTIsHardwareDecodeSupported(kVTPixelFormat_32BGRA) == false, "no hw for bgra")
expect(VTIsStereoMVHEVCDecodeSupported() == false, "mv-hevc decode")
expect(VTIsStereoMVHEVCEncodeSupported() == false, "mv-hevc encode")

var encoders: [String] = ["sentinel"]
expectStatus(VTCopyVideoEncoderList(&encoders), 0, "encoder list status")
expect(encoders.isEmpty, "encoder list empty")

var encoderID: String?
var encoderProps: [String: String] = ["x": "y"]
expectStatus(
    VTCopySupportedPropertyDictionaryForEncoder(
        width: 64,
        height: 64,
        codecType: kVTVideoCodecType_H264,
        encoderIdentifierOut: &encoderID,
        propertiesOut: &encoderProps
    ),
    kVTCouldNotFindVideoEncoderErr,
    "encoder dictionary"
)
expect(encoderID == nil, "encoder id nil")
expect(encoderProps.isEmpty, "encoder props empty")

var transfer: OpaquePointer?
expectStatus(VTPixelTransferSessionCreate(sessionOut: &transfer), 0, "pixel transfer create")
expect(transfer != nil, "pixel transfer session")
expectStatus(
    VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim),
    0,
    "set scaling"
)
copied = nil
expectStatus(
    VTSessionCopyProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, valueOut: &copied),
    0,
    "copy scaling"
)
expect(copied == kVTScalingMode_Trim, "copied scaling mode")
expectStatus(
    VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: "not-a-mode"),
    kVTParameterErr,
    "bad scaling"
)
var dump: [String: String] = [:]
expectStatus(VTSessionCopySerializableProperties(transfer, propertiesOut: &dump), 0, "serializable")
expect(dump[kVTPixelTransferPropertyKey_ScalingMode] == kVTScalingMode_Trim, "dump")
var catalog: [String: String] = [:]
expectStatus(VTSessionCopySupportedPropertyDictionary(transfer, propertiesOut: &catalog), 0, "xfer catalog")
expect(catalog[kVTPixelTransferPropertyKey_ScalingMode]?.contains(kVTPropertyType_Enumeration) == true, "enum type")

var destRGBA: OpaquePointer?
expectStatus(
    VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32RGBA, pixelBufferOut: &destRGBA),
    0,
    "dest rgba"
)
expectStatus(VTPixelTransferSessionTransferImage(transfer, source: sourceBGRA, destination: destRGBA), 0, "xfer")
expect(VTHostPixelBufferGetByte(destRGBA, x: 0, y: 0, channel: 0) == 10, "rgba red after convert")
expect(VTHostPixelBufferGetByte(destRGBA, x: 0, y: 0, channel: 2) == 30, "rgba blue after convert")

var destSmall: OpaquePointer?
expectStatus(
    VTHostCreatePixelBuffer(width: 2, height: 2, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &destSmall),
    0,
    "dest small"
)
expectStatus(
    VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Normal),
    0,
    "normal scale"
)
expectStatus(VTPixelTransferSessionTransferImage(transfer, source: sourceBGRA, destination: destSmall), 0, "scale")
expect(VTHostPixelBufferGetWidth(destSmall) == 2, "scaled width")

var letterbox: OpaquePointer?
expectStatus(
    VTHostCreatePixelBuffer(width: 8, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &letterbox),
    0,
    "letterbox dest"
)
expectStatus(
    VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Letterbox),
    0,
    "letterbox mode"
)
expectStatus(VTPixelTransferSessionTransferImage(transfer, source: sourceBGRA, destination: letterbox), 0, "letterbox")
expect(VTHostPixelBufferGetByte(letterbox, x: 0, y: 0, channel: 0) == 0, "letterbox pad")

expect(
    VTPixelTransferSessionTransferImage(transfer, source: nil, destination: nil) == kVTPixelTransferNotSupportedErr,
    "xfer missing buffers"
)
expect(VTPixelTransferSessionGetTypeID() == 0, "xfer typeid")
VTPixelTransferSessionInvalidate(transfer)
expect(VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim) == kVTInvalidSessionErr, "invalid after invalidate")

var rotation: OpaquePointer?
expectStatus(VTPixelRotationSessionCreate(sessionOut: &rotation), 0, "rotation create")
expectStatus(
    VTSessionSetProperty(rotation, key: kVTPixelRotationPropertyKey_Rotation, value: kVTRotation_CW90),
    0,
    "set rot"
)
var rotated: OpaquePointer?
expectStatus(
    VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &rotated),
    0,
    "rot dest square"
)
expectStatus(VTPixelRotationSessionRotateImage(rotation, source: sourceBGRA, destination: rotated), 0, "rotate 90")
expect(
    VTPixelRotationSessionRotateImage(rotation, source: nil, destination: nil) == kVTPixelRotationNotSupportedErr,
    "rotate missing"
)
expect(VTPixelRotationSessionGetTypeID() == 0, "rot typeid")
VTPixelRotationSessionInvalidate(rotation)

var image: OpaquePointer?
expectStatus(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: nil, imageOut: &image), kVTParameterErr, "cgimage nil")
var image2: OpaquePointer?
expectStatus(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: sourceBGRA, imageOut: &image2), 0, "cgimage")
expect(VTHostCGImageGetWidth(image2) == 4, "cg width")
expect(VTHostCGImageGetHeight(image2) == 4, "cg height")
expect(VTHostCGImageGetByte(image2, offset: 0) == 10, "cg red")
expect(VTHostCGImageGetByte(image2, offset: 1) == 20, "cg green")
expect(VTHostCGImageGetByte(image2, offset: 2) == 30, "cg blue")
let fakeBuffer = OpaquePointer(bitPattern: 0x11)!
var image3: OpaquePointer?
expectStatus(
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer: fakeBuffer, imageOut: &image3),
    kVTParameterErr,
    "cgimage unknown pointer"
)

var silo: OpaquePointer?
expectStatus(VTFrameSiloCreate(siloOut: &silo), 0, "frame silo")
expect(silo != nil, "silo session")
var sample2: OpaquePointer?
expectStatus(
    VTHostCreateSampleBuffer(
        format: bgraFormat,
        pixelBuffer: sourceBGRA,
        presentationTimeStamp: VTMediaTime(value: 2, timescale: 1),
        duration: VTMediaTime.zero,
        sampleBufferOut: &sample2
    ),
    0,
    "sample2"
)
expectStatus(VTFrameSiloAddSampleBuffer(silo, sampleBuffer: sample), 0, "add sample")
expectStatus(VTFrameSiloAddSampleBuffer(silo, sampleBuffer: sample2), 0, "add sample2")
expectStatus(VTFrameSiloSetTimeRangesForNextPass(silo), 0, "silo ranges")
var progress = -1.0
expectStatus(VTFrameSiloGetProgressOfCurrentPass(silo, progressOut: &progress), 0, "progress")
var visited = 0
expectStatus(
    VTFrameSiloCallFunctionForEachSampleBuffer(silo) { pointer in
        visited += 1
        expect(VTHostSampleBufferGetPresentationTimeStamp(pointer).isValid, "silo pts")
        return 0
    },
    0,
    "foreach"
)
expect(visited == 2, "visited \(visited)")
expectStatus(VTFrameSiloGetProgressOfCurrentPass(silo, progressOut: &progress), 0, "progress after")
expect(progress == 1, "complete pass")
expect(VTFrameSiloCallFunctionForEachSampleBuffer(nil) == kVTInvalidSessionErr, "foreach nil")

var storage: OpaquePointer?
expectStatus(VTMultiPassStorageCreate(storageOut: &storage), 0, "multipass")
expectStatus(VTMultiPassStorageClose(storage), 0, "multipass close")
expectStatus(VTMultiPassStorageClose(nil), kVTInvalidSessionErr, "multipass nil")

var raw: OpaquePointer?
expectStatus(VTRAWProcessingSessionCreate(sessionOut: &raw), kVTCouldNotFindExtensionErr, "raw")
VTRAWProcessingSessionInvalidate(raw)
expect(VTRAWProcessingSessionGetTypeID() == 0, "raw typeid")
expect(VTRAWProcessingSessionCompleteFrames(nil) == kVTInvalidSessionErr, "raw complete")
expect(VTRAWProcessingSessionProcessFrame(nil) == kVTInvalidSessionErr, "raw process")
var rawParams: [String: String] = ["a": "b"]
expect(VTRAWProcessingSessionCopyProcessingParameters(nil, parametersOut: &rawParams) == kVTInvalidSessionErr, "raw copy")
expect(VTRAWProcessingSessionSetProcessingParameters(nil, parameters: ["k": "v"]) == kVTInvalidSessionErr, "raw set")
expect(VTRAWProcessingSessionSetParameterChangedHandler(nil) == kVTInvalidSessionErr, "raw handler")
expect(VTRAWProcessingSessionSetParameterChangedHander(nil) == kVTInvalidSessionErr, "raw hander typo")

var motion: OpaquePointer?
expectStatus(VTMotionEstimationSessionCreate(sessionOut: &motion), kVTCouldNotFindTemporalFilterErr, "motion")
VTMotionEstimationSessionInvalidate(motion)
expect(VTMotionEstimationSessionGetTypeID() == 0, "motion typeid")

var hdr: OpaquePointer?
expectStatus(
    VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 24, sessionOut: &hdr),
    kVTAllocationFailedErr,
    "hdr"
)
expectStatus(
    VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 0, sessionOut: &hdr),
    kVTParameterErr,
    "hdr fps"
)
VTHDRPerFrameMetadataGenerationSessionInvalidate(hdr)
expect(VTHDRPerFrameMetadataGenerationSessionGetTypeID() == 0, "hdr typeid")

var extProps: [String: String] = ["x": "y"]
expectStatus(VTCopyVideoDecoderExtensionProperties(&extProps), kVTCouldNotFindExtensionErr, "decoder ext")
expect(extProps.isEmpty, "decoder ext empty")
expectStatus(VTCopyRAWProcessorExtensionProperties(&extProps), kVTCouldNotFindExtensionErr, "raw ext")
VTRegisterProfessionalVideoWorkflowVideoDecoders()
VTRegisterProfessionalVideoWorkflowVideoEncoders()
VTRegisterSupplementalVideoDecoderIfAvailable(kVTVideoCodecType_H264)

_ = VTSessionRef.self
_ = VTFrameSiloRef.self
_ = VTMultiPassStorageRef.self
_ = VTCompressionSessionRef.self
_ = VTDecompressionSessionRef.self
_ = VTPixelRotationSessionRef.self
_ = VTPixelTransferSessionRef.self
_ = VTRAWProcessingSessionRef.self
_ = VTMotionEstimationSessionRef.self
_ = VTHDRPerFrameMetadataGenerationSessionRef.self
_ = OSStatus.self

expect(kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder != kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder, "enc spec")
expect(kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder != kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder, "dec spec")
expect(kVTDecompressionResolutionKey_Width != kVTDecompressionResolutionKey_Height, "res keys")
expect(kVTMultiPassStorageCreationOption_DoNotDelete.count > 0, "multipass option")
expect(kVTMotionEstimationSessionCreationOption_Label != kVTMotionEstimationSessionCreationOption_MotionVectorSize, "me opts")
expect(kVTCameraCalibrationLensRole_Left != kVTCameraCalibrationLensRole_Right, "lens role")
expect(kVTCompressionPropertyCameraCalibrationKey_LensIdentifier != kVTCompressionPropertyCameraCalibrationKey_LensRole, "calib")
expect(kVTHDRPerFrameMetadataGenerationHDRFormatType_DolbyVision != kVTHDRPerFrameMetadataGenerationOptionsKey_HDRFormats, "hdr gen")
expect(kVTVideoEncoderListOption_IncludeStandardDefinitionDVEncoders.count > 0, "dv option")
expect(kVTPixelTransferPropertyKey_DestinationColorPrimaries != kVTPixelTransferPropertyKey_DestinationYCbCrMatrix, "dest color")
expect(kVTPixelRotationPropertyKey_FlipHorizontalOrientation != kVTPixelRotationPropertyKey_FlipVerticalOrientation, "flip")
expect(kVTRAWProcessingPropertyKey_MetalDeviceRegistryID != kVTRAWProcessingPropertyKey_OutputColorAttachments, "raw props")
expect(kVTRAWProcessingParameter_Key != kVTRAWProcessingParameter_Name, "raw params")
expect(kVTRAWProcessingParameterListElement_Label != kVTRAWProcessingParameterListElement_ListElementID, "raw list")
expect(kVTVideoEncoderSpecification_EnableLowLatencyRateControl != kVTVideoEncoderSpecification_EncoderID, "llrc")
expect(kVTCompressionPropertyKey_UsingGPURegistryID != kVTDecompressionPropertyKey_UsingGPURegistryID, "gpu ids")

print("VIDEOTOOLBOX_AGENT_RUNTIME_OK")
