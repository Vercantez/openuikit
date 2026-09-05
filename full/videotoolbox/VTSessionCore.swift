import Foundation

enum VTObjectKind: Equatable {
    case compression
    case decompression
    case pixelTransfer
    case pixelRotation
    case frameSilo
    case multiPass
    case rawProcessing
    case motionEstimation
    case hdrMetadata
}

struct VTPropertySpec {
    var type: String
    var readWrite: String
    var serialized: Bool
    var minimum: Double?
    var maximum: Double?
    var allowed: [String]
    var documentation: String
}

enum LinuxVTPayload {
    case session(LinuxVTSession)
    case pixelBuffer(VTHostPixelBuffer)
    case sampleBuffer(VTHostSampleBuffer)
    case image(VTHostCGImage)
}

final class LinuxVTSession {
    let kind: VTObjectKind
    var properties: [String: String]
    var valid: Bool
    var width: Int32
    var height: Int32
    var codecType: UInt32
    var format: VTVideoFormatDescription?
    var destinationPixelFormat: UInt32
    var prepared: Bool
    var pendingEncode: Int
    var pendingDecode: Int
    var decodeCallback: VTDecompressionOutputCallback?
    var encodeCallback: VTCompressionOutputCallback?
    var frames: [VTHostSampleBuffer]
    var closed: Bool
    var progress: Double
    let asyncLock = NSCondition()
    var asyncOutstanding: Int = 0

    init(kind: VTObjectKind) {
        self.kind = kind
        self.properties = LinuxVTSession.defaultProperties(for: kind)
        self.valid = true
        self.width = 0
        self.height = 0
        self.codecType = 0
        self.format = nil
        self.destinationPixelFormat = kVTPixelFormat_32BGRA
        self.prepared = false
        self.pendingEncode = 0
        self.pendingDecode = 0
        self.frames = []
        self.closed = false
        self.progress = 0
    }

    static func defaultProperties(for kind: VTObjectKind) -> [String: String] {
        var values: [String: String] = [:]
        switch kind {
        case .compression:
            values[kVTCompressionPropertyKey_RealTime] = "false"
            values[kVTCompressionPropertyKey_AllowTemporalCompression] = "true"
            values[kVTCompressionPropertyKey_AllowFrameReordering] = "true"
            values[kVTCompressionPropertyKey_Quality] = "0.5"
            values[kVTCompressionPropertyKey_MaxKeyFrameInterval] = "30"
            values[kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder] = "false"
            values[kVTCompressionPropertyKey_NumberOfPendingFrames] = "0"
            values[kVTCompressionPropertyKey_PixelBufferPoolIsShared] = "false"
            values[kVTCompressionPropertyKey_ProfileLevel] = kVTProfileLevel_H264_Baseline_AutoLevel
            values[kVTCompressionPropertyKey_H264EntropyMode] = kVTH264EntropyMode_CAVLC
            values[kVTCompressionPropertyKey_ExpectedFrameRate] = "30"
            values[kVTCompressionPropertyKey_AverageBitRate] = "0"
        case .decompression:
            values[kVTDecompressionPropertyKey_RealTime] = "false"
            values[kVTDecompressionPropertyKey_ThreadCount] = "1"
            values[kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder] = "false"
            values[kVTDecompressionPropertyKey_NumberOfFramesBeingDecoded] = "0"
            values[kVTDecompressionPropertyKey_PixelBufferPoolIsShared] = "false"
            values[kVTDecompressionPropertyKey_FieldMode] = kVTDecompressionProperty_FieldMode_BothFields
            values[kVTDecompressionPropertyKey_DeinterlaceMode] = kVTDecompressionProperty_DeinterlaceMode_VerticalFilter
            values[kVTDecompressionPropertyKey_OnlyTheseFrames] = kVTDecompressionProperty_OnlyTheseFrames_AllFrames
            values[kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions] = "false"
            values[kVTDecompressionPropertyKey_ContentHasInterframeDependencies] = "false"
        case .pixelTransfer:
            values[kVTPixelTransferPropertyKey_ScalingMode] = kVTScalingMode_Normal
            values[kVTPixelTransferPropertyKey_DownsamplingMode] = kVTDownsamplingMode_Decimate
            values[kVTPixelTransferPropertyKey_RealTime] = "false"
        case .pixelRotation:
            values[kVTPixelRotationPropertyKey_Rotation] = kVTRotation_0
            values[kVTPixelRotationPropertyKey_FlipHorizontalOrientation] = "false"
            values[kVTPixelRotationPropertyKey_FlipVerticalOrientation] = "false"
        default:
            break
        }
        return values
    }
}

let vtObjectLock = NSLock()
var vtObjectTable: [UInt: LinuxVTPayload] = [:]
var vtNextObjectID: UInt = 1

func vtStore(_ payload: LinuxVTPayload) -> OpaquePointer {
    vtObjectLock.lock()
    defer { vtObjectLock.unlock() }
    vtNextObjectID += 1
    let identifier = vtNextObjectID
    vtObjectTable[identifier] = payload
    return OpaquePointer(bitPattern: Int(identifier))!
}

func vtLookup(_ pointer: OpaquePointer?) -> LinuxVTPayload? {
    guard let pointer else { return nil }
    let identifier = UInt(bitPattern: pointer)
    vtObjectLock.lock()
    defer { vtObjectLock.unlock() }
    return vtObjectTable[identifier]
}

func vtLookupSession(_ pointer: OpaquePointer?) -> LinuxVTSession? {
    guard case .session(let session)? = vtLookup(pointer) else { return nil }
    return session
}

func vtLookupPixelBuffer(_ pointer: OpaquePointer?) -> VTHostPixelBuffer? {
    guard case .pixelBuffer(let buffer)? = vtLookup(pointer) else { return nil }
    return buffer
}

func vtLookupSampleBuffer(_ pointer: OpaquePointer?) -> VTHostSampleBuffer? {
    guard case .sampleBuffer(let buffer)? = vtLookup(pointer) else { return nil }
    return buffer
}

func vtRemoveObject(_ pointer: OpaquePointer?) {
    guard let pointer else { return }
    let identifier = UInt(bitPattern: pointer)
    vtObjectLock.lock()
    vtObjectTable[identifier] = nil
    vtObjectLock.unlock()
}

func vtBooleanValue(_ text: String) -> Bool? {
    switch text.lowercased() {
    case "true", "yes", "1":
        return true
    case "false", "no", "0":
        return false
    default:
        return nil
    }
}

func vtPropertyCatalog(for kind: VTObjectKind) -> [String: VTPropertySpec] {
    switch kind {
    case .compression:
        return vtCompressionPropertyCatalog()
    case .decompression:
        return vtDecompressionPropertyCatalog()
    case .pixelTransfer:
        return vtPixelTransferPropertyCatalog()
    case .pixelRotation:
        return vtPixelRotationPropertyCatalog()
    default:
        return [:]
    }
}

func vtNumberSpec(_ documentation: String, min: Double? = nil, max: Double? = nil, readOnly: Bool = false) -> VTPropertySpec {
    VTPropertySpec(
        type: kVTPropertyType_Number,
        readWrite: readOnly ? kVTPropertyReadWriteStatus_ReadOnly : kVTPropertyReadWriteStatus_ReadWrite,
        serialized: !readOnly,
        minimum: min,
        maximum: max,
        allowed: [],
        documentation: documentation
    )
}

func vtBooleanSpec(_ documentation: String, readOnly: Bool = false) -> VTPropertySpec {
    VTPropertySpec(
        type: kVTPropertyType_Boolean,
        readWrite: readOnly ? kVTPropertyReadWriteStatus_ReadOnly : kVTPropertyReadWriteStatus_ReadWrite,
        serialized: !readOnly,
        minimum: nil,
        maximum: nil,
        allowed: ["true", "false"],
        documentation: documentation
    )
}

func vtEnumSpec(_ documentation: String, allowed: [String], readOnly: Bool = false) -> VTPropertySpec {
    VTPropertySpec(
        type: kVTPropertyType_Enumeration,
        readWrite: readOnly ? kVTPropertyReadWriteStatus_ReadOnly : kVTPropertyReadWriteStatus_ReadWrite,
        serialized: !readOnly,
        minimum: nil,
        maximum: nil,
        allowed: allowed,
        documentation: documentation
    )
}

func vtCompressionPropertyCatalog() -> [String: VTPropertySpec] {
    [
        kVTCompressionPropertyKey_NumberOfPendingFrames: vtNumberSpec("Pending encode count", min: 0, readOnly: true),
        kVTCompressionPropertyKey_PixelBufferPoolIsShared: vtBooleanSpec("Pool sharing", readOnly: true),
        kVTCompressionPropertyKey_VideoEncoderPixelBufferAttributes: vtEnumSpec("Encoder pool attributes", allowed: [], readOnly: true),
        kVTCompressionPropertyKey_MaxKeyFrameInterval: vtNumberSpec("GOP size", min: 0),
        kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: vtNumberSpec("GOP duration seconds", min: 0),
        kVTCompressionPropertyKey_AllowTemporalCompression: vtBooleanSpec("Allow P/B frames"),
        kVTCompressionPropertyKey_AllowFrameReordering: vtBooleanSpec("Allow B frames"),
        kVTCompressionPropertyKey_AllowOpenGOP: vtBooleanSpec("Allow open GOP"),
        kVTCompressionPropertyKey_AverageBitRate: vtNumberSpec("Average bits/sec", min: 0),
        kVTCompressionPropertyKey_DataRateLimits: vtNumberSpec("Data rate limits"),
        kVTCompressionPropertyKey_Quality: vtNumberSpec("Quality 0...1", min: 0, max: 1),
        kVTCompressionPropertyKey_TargetQualityForAlpha: vtNumberSpec("Alpha quality 0...1", min: 0, max: 1),
        kVTCompressionPropertyKey_MoreFramesBeforeStart: vtBooleanSpec("Prime before start"),
        kVTCompressionPropertyKey_MoreFramesAfterEnd: vtBooleanSpec("Prime after end"),
        kVTCompressionPropertyKey_ProfileLevel: vtEnumSpec("Profile and level", allowed: vtProfileLevelValues()),
        kVTCompressionPropertyKey_H264EntropyMode: vtEnumSpec("H.264 entropy", allowed: [kVTH264EntropyMode_CAVLC, kVTH264EntropyMode_CABAC]),
        kVTCompressionPropertyKey_Depth: vtNumberSpec("Bits per sample", min: 8, max: 16),
        kVTCompressionPropertyKey_PreserveAlphaChannel: vtBooleanSpec("Preserve alpha"),
        kVTCompressionPropertyKey_MaxFrameDelayCount: vtNumberSpec("Max delayed frames", min: 0),
        kVTCompressionPropertyKey_MaxH264SliceBytes: vtNumberSpec("Max slice bytes", min: 0),
        kVTCompressionPropertyKey_RealTime: vtBooleanSpec("Realtime encode"),
        kVTCompressionPropertyKey_MaximizePowerEfficiency: vtBooleanSpec("Power efficiency"),
        kVTCompressionPropertyKey_SourceFrameCount: vtNumberSpec("Known source frames", min: 0),
        kVTCompressionPropertyKey_ExpectedFrameRate: vtNumberSpec("Expected fps", min: 0),
        kVTCompressionPropertyKey_MaximumRealTimeFrameRate: vtNumberSpec("Max realtime fps", min: 0),
        kVTCompressionPropertyKey_BaseLayerFrameRateFraction: vtNumberSpec("Base layer fps fraction", min: 0, max: 1),
        kVTCompressionPropertyKey_ExpectedDuration: vtNumberSpec("Expected duration", min: 0),
        kVTCompressionPropertyKey_BaseLayerFrameRate: vtNumberSpec("Base layer fps", min: 0),
        kVTCompressionPropertyKey_ReferenceBufferCount: vtNumberSpec("Reference buffers", min: 0),
        kVTCompressionPropertyKey_CalculateMeanSquaredError: vtBooleanSpec("Compute MSE"),
        kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder: vtBooleanSpec("Hardware encoder in use", readOnly: true),
        kVTCompressionPropertyKey_CleanAperture: vtEnumSpec("Clean aperture", allowed: []),
        kVTCompressionPropertyKey_PixelAspectRatio: vtEnumSpec("Pixel aspect", allowed: []),
        kVTCompressionPropertyKey_FieldCount: vtNumberSpec("1 progressive or 2 interlaced", min: 1, max: 2),
        kVTCompressionPropertyKey_FieldDetail: vtEnumSpec("Field detail", allowed: ["TemporalTopFirst", "TemporalBottomFirst", "SpatialFirstLineEarly", "SpatialFirstLineLate"]),
        kVTCompressionPropertyKey_AspectRatio16x9: vtBooleanSpec("Force 16:9"),
        kVTCompressionPropertyKey_ProgressiveScan: vtBooleanSpec("Progressive scan"),
        kVTCompressionPropertyKey_ColorPrimaries: vtEnumSpec("Color primaries", allowed: ["ITU_R_709_2", "EBU_3213", "SMPTE_C", "P22"]),
        kVTCompressionPropertyKey_TransferFunction: vtEnumSpec("Transfer function", allowed: ["ITU_R_709_2", "SMPTE_240M_1995", "UseGamma"]),
        kVTCompressionPropertyKey_YCbCrMatrix: vtEnumSpec("YCbCr matrix", allowed: ["ITU_R_709_2", "ITU_R_601_4", "SMPTE_240M_1995"]),
        kVTCompressionPropertyKey_ICCProfile: vtEnumSpec("ICC profile", allowed: []),
        kVTCompressionPropertyKey_AlphaChannelMode: vtEnumSpec("Alpha mode", allowed: [kVTAlphaChannelMode_StraightAlpha, kVTAlphaChannelMode_PremultipliedAlpha]),
        kVTCompressionPropertyKey_GammaLevel: vtNumberSpec("Gamma", min: 0),
        kVTCompressionPropertyKey_MasteringDisplayColorVolume: vtEnumSpec("MDCV", allowed: []),
        kVTCompressionPropertyKey_ContentLightLevelInfo: vtEnumSpec("CLLI", allowed: []),
        kVTCompressionPropertyKey_PixelTransferProperties: vtEnumSpec("Nested pixel transfer", allowed: []),
        kVTCompressionPropertyKey_MultiPassStorage: vtEnumSpec("Multipass storage", allowed: []),
        kVTCompressionPropertyKey_EncoderID: vtEnumSpec("Encoder identifier", allowed: [], readOnly: true),
        kVTCompressionPropertyKey_RecommendedParallelizationLimit: vtNumberSpec("Parallel limit", min: 1, readOnly: true),
        kVTCompressionPropertyKey_RecommendedParallelizedSubdivisionMinimumFrameCount: vtNumberSpec("Min frames per job", min: 1, readOnly: true),
        kVTCompressionPropertyKey_RecommendedParallelizedSubdivisionMinimumDuration: vtNumberSpec("Min duration per job", min: 0, readOnly: true),
        kVTCompressionPropertyKey_UsingGPURegistryID: vtNumberSpec("GPU registry id", readOnly: true),
        kVTCompressionPropertyKey_HDRMetadataInsertionMode: vtEnumSpec("HDR insertion", allowed: [kVTHDRMetadataInsertionMode_None, kVTHDRMetadataInsertionMode_Auto, kVTHDRMetadataInsertionMode_RequestSDRRangePreservation]),
        kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality: vtBooleanSpec("Prefer speed"),
        kVTCompressionPropertyKey_ConstantBitRate: vtNumberSpec("CBR bits/sec", min: 0),
        kVTCompressionPropertyKey_EstimatedAverageBytesPerFrame: vtNumberSpec("Estimated bytes/frame", min: 0, readOnly: true),
        kVTCompressionPropertyKey_PreserveDynamicHDRMetadata: vtBooleanSpec("Preserve HDR10+"),
        kVTCompressionPropertyKey_BaseLayerBitRateFraction: vtNumberSpec("Base layer bitrate fraction", min: 0, max: 1),
        kVTCompressionPropertyKey_EnableLTR: vtBooleanSpec("Long-term references"),
        kVTCompressionPropertyKey_MaxAllowedFrameQP: vtNumberSpec("Max QP", min: 0, max: 51),
        kVTCompressionPropertyKey_MinAllowedFrameQP: vtNumberSpec("Min QP", min: 0, max: 51),
        kVTCompressionPropertyKey_SupportsBaseFrameQP: vtBooleanSpec("Supports base QP", readOnly: true),
        kVTCompressionPropertyKey_OutputBitDepth: vtNumberSpec("Output bit depth", min: 8, max: 16),
        kVTCompressionPropertyKey_ProjectionKind: vtEnumSpec("Projection", allowed: [kVTProjectionKind_Rectilinear, kVTProjectionKind_Equirectangular, kVTProjectionKind_HalfEquirectangular, kVTProjectionKind_ParametricImmersive]),
        kVTCompressionPropertyKey_ViewPackingKind: vtEnumSpec("View packing", allowed: [kVTViewPackingKind_SideBySide, kVTViewPackingKind_OverUnder]),
        kVTCompressionPropertyKey_SuggestedLookAheadFrameCount: vtNumberSpec("Lookahead frames", min: 0),
        kVTCompressionPropertyKey_SpatialAdaptiveQPLevel: vtNumberSpec("Spatial AQ", min: 0),
        kVTCompressionPropertyKey_MVHEVCVideoLayerIDs: vtEnumSpec("MV-HEVC layer IDs", allowed: []),
        kVTCompressionPropertyKey_MVHEVCViewIDs: vtEnumSpec("MV-HEVC view IDs", allowed: []),
        kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs: vtEnumSpec("MV-HEVC L/R view IDs", allowed: []),
        kVTCompressionPropertyKey_HeroEye: vtEnumSpec("Hero eye", allowed: [kVTHeroEye_Left, kVTHeroEye_Right]),
        kVTCompressionPropertyKey_StereoCameraBaseline: vtNumberSpec("Stereo baseline", min: 0),
        kVTCompressionPropertyKey_HorizontalDisparityAdjustment: vtNumberSpec("Disparity adjustment"),
        kVTCompressionPropertyKey_HasLeftStereoEyeView: vtBooleanSpec("Has left eye"),
        kVTCompressionPropertyKey_HasRightStereoEyeView: vtBooleanSpec("Has right eye"),
        kVTCompressionPropertyKey_HorizontalFieldOfView: vtNumberSpec("HFOV", min: 0),
        kVTCompressionPropertyKey_VariableBitRate: vtNumberSpec("VBR bits/sec", min: 0),
        kVTCompressionPropertyKey_VBVMaxBitRate: vtNumberSpec("VBV max bitrate", min: 0),
        kVTCompressionPropertyKey_VBVBufferDuration: vtNumberSpec("VBV duration", min: 0),
        kVTCompressionPropertyKey_VBVInitialDelayPercentage: vtNumberSpec("VBV initial delay", min: 0, max: 100),
        kVTCompressionPropertyKey_CameraCalibrationDataLensCollection: vtEnumSpec("Lens collection", allowed: []),
        kVTCompressionPropertyKey_SupportedPresetDictionaries: vtEnumSpec("Presets", allowed: [kVTCompressionPreset_HighQuality, kVTCompressionPreset_Balanced, kVTCompressionPreset_HighSpeed, kVTCompressionPreset_VideoConferencing], readOnly: true),
    ]
}

func vtDecompressionPropertyCatalog() -> [String: VTPropertySpec] {
    [
        kVTDecompressionPropertyKey_PixelBufferPool: vtEnumSpec("Output pool", allowed: [], readOnly: true),
        kVTDecompressionPropertyKey_PixelBufferPoolIsShared: vtBooleanSpec("Pool sharing", readOnly: true),
        kVTDecompressionPropertyKey_OutputPoolRequestedMinimumBufferCount: vtNumberSpec("Min pool buffers", min: 0),
        kVTDecompressionPropertyKey_NumberOfFramesBeingDecoded: vtNumberSpec("In-flight frames", min: 0, readOnly: true),
        kVTDecompressionPropertyKey_MinOutputPresentationTimeStampOfFramesBeingDecoded: vtNumberSpec("Min PTS", readOnly: true),
        kVTDecompressionPropertyKey_MaxOutputPresentationTimeStampOfFramesBeingDecoded: vtNumberSpec("Max PTS", readOnly: true),
        kVTDecompressionPropertyKey_ContentHasInterframeDependencies: vtBooleanSpec("Interframe dependencies", readOnly: true),
        kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder: vtBooleanSpec("Hardware decoder in use", readOnly: true),
        kVTDecompressionPropertyKey_RealTime: vtBooleanSpec("Realtime decode"),
        kVTDecompressionPropertyKey_MaximizePowerEfficiency: vtBooleanSpec("Power efficiency"),
        kVTDecompressionPropertyKey_ThreadCount: vtNumberSpec("Decoder threads", min: 1, max: 64),
        kVTDecompressionPropertyKey_FieldMode: vtEnumSpec("Field mode", allowed: [
            kVTDecompressionProperty_FieldMode_BothFields,
            kVTDecompressionProperty_FieldMode_TopFieldOnly,
            kVTDecompressionProperty_FieldMode_BottomFieldOnly,
            kVTDecompressionProperty_FieldMode_SingleField,
            kVTDecompressionProperty_FieldMode_DeinterlaceFields,
        ]),
        kVTDecompressionPropertyKey_DeinterlaceMode: vtEnumSpec("Deinterlace", allowed: [
            kVTDecompressionProperty_DeinterlaceMode_VerticalFilter,
            kVTDecompressionProperty_DeinterlaceMode_Temporal,
        ]),
        kVTDecompressionPropertyKey_ReducedResolutionDecode: vtEnumSpec("Reduced resolution", allowed: []),
        kVTDecompressionPropertyKey_ReducedCoefficientDecode: vtNumberSpec("Reduced coefficients", min: 0, max: 1),
        kVTDecompressionPropertyKey_ReducedFrameDelivery: vtNumberSpec("Frame delivery fraction", min: 0, max: 1),
        kVTDecompressionPropertyKey_OnlyTheseFrames: vtEnumSpec("Frame filter", allowed: [
            kVTDecompressionProperty_OnlyTheseFrames_AllFrames,
            kVTDecompressionProperty_OnlyTheseFrames_NonDroppableFrames,
            kVTDecompressionProperty_OnlyTheseFrames_IFrames,
            kVTDecompressionProperty_OnlyTheseFrames_KeyFrames,
        ]),
        kVTDecompressionProperty_TemporalLevelLimit: vtNumberSpec("Temporal level limit", min: 0),
        kVTDecompressionPropertyKey_SuggestedQualityOfServiceTiers: vtEnumSpec("QoS tiers", allowed: [], readOnly: true),
        kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByQuality: vtEnumSpec("Formats by quality", allowed: [], readOnly: true),
        kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByPerformance: vtEnumSpec("Formats by speed", allowed: [], readOnly: true),
        kVTDecompressionPropertyKey_PixelFormatsWithReducedResolutionSupport: vtEnumSpec("Reduced-res formats", allowed: [], readOnly: true),
        kVTDecompressionPropertyKey_UsingGPURegistryID: vtNumberSpec("GPU registry id", readOnly: true),
        kVTDecompressionPropertyKey_PixelTransferProperties: vtEnumSpec("Nested pixel transfer", allowed: []),
        kVTDecompressionPropertyKey_PropagatePerFrameHDRDisplayMetadata: vtBooleanSpec("Propagate HDR"),
        kVTDecompressionPropertyKey_GeneratePerFrameHDRDisplayMetadata: vtBooleanSpec("Generate HDR"),
        kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions: vtBooleanSpec("Allow size change"),
        kVTDecompressionPropertyKey_DecoderProducesRAWOutput: vtBooleanSpec("RAW output", readOnly: true),
        kVTDecompressionPropertyKey_RequestRAWOutput: vtBooleanSpec("Request RAW"),
        kVTDecompressionPropertyKey_RequestedMVHEVCVideoLayerIDs: vtEnumSpec("Requested MV-HEVC layers", allowed: []),
    ]
}

func vtPixelTransferPropertyCatalog() -> [String: VTPropertySpec] {
    [
        kVTPixelTransferPropertyKey_ScalingMode: vtEnumSpec("Scaling mode", allowed: [
            kVTScalingMode_Normal,
            kVTScalingMode_CropSourceToCleanAperture,
            kVTScalingMode_Letterbox,
            kVTScalingMode_Trim,
        ]),
        kVTPixelTransferPropertyKey_DestinationCleanAperture: vtEnumSpec("Destination clean aperture", allowed: []),
        kVTPixelTransferPropertyKey_DestinationPixelAspectRatio: vtEnumSpec("Destination PAR", allowed: []),
        kVTPixelTransferPropertyKey_DownsamplingMode: vtEnumSpec("Chroma downsample", allowed: [kVTDownsamplingMode_Decimate, kVTDownsamplingMode_Average]),
        kVTPixelTransferPropertyKey_DestinationColorPrimaries: vtEnumSpec("Dest primaries", allowed: ["ITU_R_709_2", "EBU_3213", "SMPTE_C", "P22"]),
        kVTPixelTransferPropertyKey_DestinationTransferFunction: vtEnumSpec("Dest transfer", allowed: ["ITU_R_709_2", "SMPTE_240M_1995", "UseGamma"]),
        kVTPixelTransferPropertyKey_DestinationICCProfile: vtEnumSpec("Dest ICC", allowed: []),
        kVTPixelTransferPropertyKey_DestinationYCbCrMatrix: vtEnumSpec("Dest YCbCr", allowed: ["ITU_R_709_2", "ITU_R_601_4", "SMPTE_240M_1995"]),
        kVTPixelTransferPropertyKey_RealTime: vtBooleanSpec("Realtime transfer"),
    ]
}

func vtPixelRotationPropertyCatalog() -> [String: VTPropertySpec] {
    [
        kVTPixelRotationPropertyKey_Rotation: vtEnumSpec("Rotation", allowed: [kVTRotation_0, kVTRotation_CW90, kVTRotation_180, kVTRotation_CCW90]),
        kVTPixelRotationPropertyKey_FlipHorizontalOrientation: vtBooleanSpec("Flip horizontal"),
        kVTPixelRotationPropertyKey_FlipVerticalOrientation: vtBooleanSpec("Flip vertical"),
    ]
}

func vtProfileLevelValues() -> [String] {
    [
        kVTProfileLevel_HEVC_Main_AutoLevel,
        kVTProfileLevel_HEVC_Main10_AutoLevel,
        kVTProfileLevel_HEVC_Main42210_AutoLevel,
        kVTProfileLevel_HEVC_Monochrome_AutoLevel,
        kVTProfileLevel_HEVC_Monochrome10_AutoLevel,
        kVTProfileLevel_H264_Baseline_1_3,
        kVTProfileLevel_H264_Baseline_3_0,
        kVTProfileLevel_H264_Baseline_3_1,
        kVTProfileLevel_H264_Baseline_3_2,
        kVTProfileLevel_H264_Baseline_4_0,
        kVTProfileLevel_H264_Baseline_4_1,
        kVTProfileLevel_H264_Baseline_4_2,
        kVTProfileLevel_H264_Baseline_5_0,
        kVTProfileLevel_H264_Baseline_5_1,
        kVTProfileLevel_H264_Baseline_5_2,
        kVTProfileLevel_H264_Baseline_AutoLevel,
        kVTProfileLevel_H264_Main_3_0,
        kVTProfileLevel_H264_Main_3_1,
        kVTProfileLevel_H264_Main_3_2,
        kVTProfileLevel_H264_Main_4_0,
        kVTProfileLevel_H264_Main_4_1,
        kVTProfileLevel_H264_Main_4_2,
        kVTProfileLevel_H264_Main_5_0,
        kVTProfileLevel_H264_Main_5_1,
        kVTProfileLevel_H264_Main_5_2,
        kVTProfileLevel_H264_Main_AutoLevel,
        kVTProfileLevel_H264_Extended_5_0,
        kVTProfileLevel_H264_Extended_AutoLevel,
        kVTProfileLevel_H264_High_3_0,
        kVTProfileLevel_H264_High_3_1,
        kVTProfileLevel_H264_High_3_2,
        kVTProfileLevel_H264_High_4_0,
        kVTProfileLevel_H264_High_4_1,
        kVTProfileLevel_H264_High_4_2,
        kVTProfileLevel_H264_High_5_0,
        kVTProfileLevel_H264_High_5_1,
        kVTProfileLevel_H264_High_5_2,
        kVTProfileLevel_H264_High_AutoLevel,
        kVTProfileLevel_H264_ConstrainedBaseline_AutoLevel,
        kVTProfileLevel_H264_ConstrainedHigh_AutoLevel,
        kVTProfileLevel_MP4V_Simple_L0,
        kVTProfileLevel_MP4V_Simple_L1,
        kVTProfileLevel_MP4V_Simple_L2,
        kVTProfileLevel_MP4V_Simple_L3,
        kVTProfileLevel_MP4V_Main_L2,
        kVTProfileLevel_MP4V_Main_L3,
        kVTProfileLevel_MP4V_Main_L4,
        kVTProfileLevel_MP4V_AdvancedSimple_L0,
        kVTProfileLevel_MP4V_AdvancedSimple_L1,
        kVTProfileLevel_MP4V_AdvancedSimple_L2,
        kVTProfileLevel_MP4V_AdvancedSimple_L3,
        kVTProfileLevel_MP4V_AdvancedSimple_L4,
        kVTProfileLevel_H263_Profile0_Level10,
        kVTProfileLevel_H263_Profile0_Level45,
        kVTProfileLevel_H263_Profile3_Level45,
    ]
}

func vtValidateProperty(kind: VTObjectKind, key: String, value: String) -> OSStatus {
    let catalog = vtPropertyCatalog(for: kind)
    guard let spec = catalog[key] else {
        return kVTPropertyNotSupportedErr
    }
    if spec.readWrite == kVTPropertyReadWriteStatus_ReadOnly {
        return kVTPropertyReadOnlyErr
    }
    switch spec.type {
    case kVTPropertyType_Boolean:
        return vtBooleanValue(value) == nil ? kVTParameterErr : 0
    case kVTPropertyType_Number:
        guard let number = Double(value) else { return kVTParameterErr }
        if let minimum = spec.minimum, number < minimum { return kVTParameterErr }
        if let maximum = spec.maximum, number > maximum { return kVTParameterErr }
        return 0
    case kVTPropertyType_Enumeration:
        if spec.allowed.isEmpty {
            return value.isEmpty ? kVTParameterErr : 0
        }
        if spec.allowed.contains(value) {
            return 0
        }
        return kVTParameterErr
    default:
        return 0
    }
}

func vtSupportedPropertyDictionary(for session: LinuxVTSession) -> [String: String] {
    var dump: [String: String] = [:]
    for (key, spec) in vtPropertyCatalog(for: session.kind) {
        var parts = [
            "\(kVTPropertyTypeKey)=\(spec.type)",
            "\(kVTPropertyReadWriteStatusKey)=\(spec.readWrite)",
            "\(kVTPropertyShouldBeSerializedKey)=\(spec.serialized ? "true" : "false")",
            "\(kVTPropertyDocumentationKey)=\(spec.documentation)",
        ]
        if let minimum = spec.minimum {
            parts.append("\(kVTPropertySupportedValueMinimumKey)=\(minimum)")
        }
        if let maximum = spec.maximum {
            parts.append("\(kVTPropertySupportedValueMaximumKey)=\(maximum)")
        }
        if !spec.allowed.isEmpty {
            parts.append("\(kVTPropertySupportedValueListKey)=\(spec.allowed.joined(separator: ","))")
        }
        dump[key] = parts.joined(separator: ";")
    }
    return dump
}

func vtCopySerializable(_ session: LinuxVTSession) -> [String: String] {
    let catalog = vtPropertyCatalog(for: session.kind)
    var result: [String: String] = [:]
    for (key, value) in session.properties {
        if catalog[key]?.serialized != false {
            result[key] = value
        }
    }
    return result
}
