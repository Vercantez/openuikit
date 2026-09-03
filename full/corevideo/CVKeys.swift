import Foundation

public let kCVBufferPropagatedAttachmentsKey: CFString = _cvCFString("PropagatedAttachments")
public let kCVBufferNonPropagatedAttachmentsKey: CFString = _cvCFString("NonPropagatedAttachments")
public let kCVBufferMovieTimeKey: CFString = _cvCFString("MovieTime")
public let kCVBufferTimeValueKey: CFString = _cvCFString("TimeValue")
public let kCVBufferTimeScaleKey: CFString = _cvCFString("TimeScale")

public let kCVPixelBufferPixelFormatTypeKey: CFString = _cvCFString("PixelFormatType")
public let kCVPixelBufferMemoryAllocatorKey: CFString = _cvCFString("MemoryAllocator")
public let kCVPixelBufferWidthKey: CFString = _cvCFString("Width")
public let kCVPixelBufferHeightKey: CFString = _cvCFString("Height")
public let kCVPixelBufferExtendedPixelsLeftKey: CFString = _cvCFString("ExtendedPixelsLeft")
public let kCVPixelBufferExtendedPixelsTopKey: CFString = _cvCFString("ExtendedPixelsTop")
public let kCVPixelBufferExtendedPixelsRightKey: CFString = _cvCFString("ExtendedPixelsRight")
public let kCVPixelBufferExtendedPixelsBottomKey: CFString = _cvCFString("ExtendedPixelsBottom")
public let kCVPixelBufferBytesPerRowAlignmentKey: CFString = _cvCFString("BytesPerRowAlignment")
public let kCVPixelBufferCGBitmapContextCompatibilityKey: CFString =
    _cvCFString("CGBitmapContextCompatibility")
public let kCVPixelBufferCGImageCompatibilityKey: CFString = _cvCFString("CGImageCompatibility")
public let kCVPixelBufferOpenGLCompatibilityKey: CFString = _cvCFString("OpenGLCompatibility")
public let kCVPixelBufferPlaneAlignmentKey: CFString = _cvCFString("PlaneAlignment")
public let kCVPixelBufferIOSurfacePropertiesKey: CFString = _cvCFString("IOSurfaceProperties")
public let kCVPixelBufferOpenGLESCompatibilityKey: CFString = _cvCFString("OpenGLESCompatibility")
public let kCVPixelBufferMetalCompatibilityKey: CFString = _cvCFString("MetalCompatibility")
public let kCVPixelBufferOpenGLESTextureCacheCompatibilityKey: CFString =
    _cvCFString("OpenGLESTextureCacheCompatibility")
public let kCVPixelBufferIOSurfaceOpenGLESTextureCompatibilityKey: CFString =
    _cvCFString("IOSurfaceOpenGLESTextureCompatibility")
public let kCVPixelBufferIOSurfaceOpenGLESFBOCompatibilityKey: CFString =
    _cvCFString("IOSurfaceOpenGLESFBOCompatibility")
public let kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey: CFString =
    _cvCFString("IOSurfaceCoreAnimationCompatibility")
public let kCVPixelBufferIOSurfacePurgeableKey: CFString = _cvCFString("IOSurfacePurgeable")

public let kCVPixelBufferPoolMinimumBufferCountKey: CFString = _cvCFString("MinimumBufferCount")
public let kCVPixelBufferPoolMaximumBufferAgeKey: CFString = _cvCFString("MaximumBufferAge")
public let kCVPixelBufferPoolAllocationThresholdKey: CFString = _cvCFString("AllocationThreshold")
public let kCVPixelBufferPoolFreeBufferNotification: CFString =
    _cvCFString("CVPixelBufferPoolFreeBufferNotification")

public let kCVPixelBufferVersatileBayerKey_BayerPattern: CFString = _cvCFString("BayerPattern")
public let kCVPixelBufferProResRAWKey_BlackLevel: CFString = _cvCFString("ProResRAW_BlackLevel")
public let kCVPixelBufferProResRAWKey_WhiteLevel: CFString = _cvCFString("ProResRAW_WhiteLevel")
public let kCVPixelBufferProResRAWKey_WhiteBalanceCCT: CFString =
    _cvCFString("ProResRAW_WhiteBalanceCCT")
public let kCVPixelBufferProResRAWKey_WhiteBalanceRedFactor: CFString =
    _cvCFString("ProResRAW_WhiteBalanceRedFactor")
public let kCVPixelBufferProResRAWKey_WhiteBalanceBlueFactor: CFString =
    _cvCFString("ProResRAW_WhiteBalanceBlueFactor")
public let kCVPixelBufferProResRAWKey_ColorMatrix: CFString = _cvCFString("ProResRAW_ColorMatrix")
public let kCVPixelBufferProResRAWKey_GainFactor: CFString = _cvCFString("ProResRAW_GainFactor")
public let kCVPixelBufferProResRAWKey_RecommendedCrop: CFString =
    _cvCFString("ProResRAW_RecommendedCrop")
public let kCVPixelBufferProResRAWKey_SenselSitingOffsets: CFString =
    _cvCFString("ProResRAW_SenselSitingOffsets")
public let kCVPixelBufferProResRAWKey_MetadataExtension: CFString =
    _cvCFString("ProResRAW_MetadataExtension")

public let kCVImageBufferCGColorSpaceKey: CFString = _cvCFString("CVImageBufferCGColorSpace")
public let kCVImageBufferCleanApertureKey: CFString = _cvCFString("CVImageBufferCleanAperture")
public let kCVImageBufferCleanApertureWidthKey: CFString = _cvCFString("Width")
public let kCVImageBufferCleanApertureHeightKey: CFString = _cvCFString("Height")
public let kCVImageBufferCleanApertureHorizontalOffsetKey: CFString =
    _cvCFString("HorizontalOffset")
public let kCVImageBufferCleanApertureVerticalOffsetKey: CFString = _cvCFString("VerticalOffset")
public let kCVImageBufferPreferredCleanApertureKey: CFString =
    _cvCFString("CVImageBufferPreferredCleanAperture")
public let kCVImageBufferFieldCountKey: CFString = _cvCFString("CVImageBufferFieldCount")
public let kCVImageBufferFieldDetailKey: CFString = _cvCFString("CVImageBufferFieldDetail")
public let kCVImageBufferFieldDetailTemporalTopFirst: CFString = _cvCFString("TemporalTopFirst")
public let kCVImageBufferFieldDetailTemporalBottomFirst: CFString =
    _cvCFString("TemporalBottomFirst")
public let kCVImageBufferFieldDetailSpatialFirstLineEarly: CFString =
    _cvCFString("SpatialFirstLineEarly")
public let kCVImageBufferFieldDetailSpatialFirstLineLate: CFString =
    _cvCFString("SpatialFirstLineLate")
public let kCVImageBufferPixelAspectRatioKey: CFString =
    _cvCFString("CVImageBufferPixelAspectRatio")
public let kCVImageBufferPixelAspectRatioHorizontalSpacingKey: CFString =
    _cvCFString("HorizontalSpacing")
public let kCVImageBufferPixelAspectRatioVerticalSpacingKey: CFString =
    _cvCFString("VerticalSpacing")
public let kCVImageBufferDisplayDimensionsKey: CFString =
    _cvCFString("CVImageBufferDisplayDimensions")
public let kCVImageBufferDisplayWidthKey: CFString = _cvCFString("Width")
public let kCVImageBufferDisplayHeightKey: CFString = _cvCFString("Height")
public let kCVImageBufferGammaLevelKey: CFString = _cvCFString("CVImageBufferGammaLevel")
public let kCVImageBufferICCProfileKey: CFString = _cvCFString("CVImageBufferICCProfile")
public let kCVImageBufferYCbCrMatrixKey: CFString = _cvCFString("CVImageBufferYCbCrMatrix")
public let kCVImageBufferColorPrimariesKey: CFString = _cvCFString("CVImageBufferColorPrimaries")
public let kCVImageBufferTransferFunctionKey: CFString =
    _cvCFString("CVImageBufferTransferFunction")
public let kCVImageBufferChromaLocationTopFieldKey: CFString =
    _cvCFString("CVImageBufferChromaLocationTopField")
public let kCVImageBufferChromaLocationBottomFieldKey: CFString =
    _cvCFString("CVImageBufferChromaLocationBottomField")
public let kCVImageBufferChromaSubsamplingKey: CFString =
    _cvCFString("CVImageBufferChromaSubsampling")
public let kCVImageBufferAlphaChannelIsOpaque: CFString =
    _cvCFString("CVImageBufferAlphaChannelIsOpaque")
public let kCVImageBufferAlphaChannelModeKey: CFString =
    _cvCFString("CVImageBufferAlphaChannelMode")
public let kCVImageBufferAlphaChannelMode_StraightAlpha: CFString = _cvCFString("StraightAlpha")
public let kCVImageBufferAlphaChannelMode_PremultipliedAlpha: CFString =
    _cvCFString("PremultipliedAlpha")
public let kCVImageBufferContentLightLevelInfoKey: CFString =
    _cvCFString("CVImageBufferContentLightLevelInfo")
public let kCVImageBufferMasteringDisplayColorVolumeKey: CFString =
    _cvCFString("CVImageBufferMasteringDisplayColorVolume")
public let kCVImageBufferAmbientViewingEnvironmentKey: CFString =
    _cvCFString("CVImageBufferAmbientViewingEnvironment")
public let kCVImageBufferLogTransferFunctionKey: CFString =
    _cvCFString("CVImageBufferLogTransferFunction")
public let kCVImageBufferRegionOfInterestKey: CFString =
    _cvCFString("CVImageBufferRegionOfInterest")
public let kCVImageBufferSceneIlluminationKey: CFString =
    _cvCFString("CVImageBufferSceneIllumination")
public let kCVImageBufferDisplayMaskRectangleKey: CFString =
    _cvCFString("CVImageBufferDisplayMaskRectangle")
public let kCVImageBufferDisplayMaskRectangleStereoLeftKey: CFString =
    _cvCFString("CVImageBufferDisplayMaskRectangleStereoLeft")
public let kCVImageBufferDisplayMaskRectangleStereoRightKey: CFString =
    _cvCFString("CVImageBufferDisplayMaskRectangleStereoRight")
public let kCVImageBufferDisplayMaskRectangle_ReferenceRasterWidthKey: CFString =
    _cvCFString("ReferenceRasterWidth")
public let kCVImageBufferDisplayMaskRectangle_ReferenceRasterHeightKey: CFString =
    _cvCFString("ReferenceRasterHeight")
public let kCVImageBufferDisplayMaskRectangle_RectangleLeftKey: CFString =
    _cvCFString("RectangleLeft")
public let kCVImageBufferDisplayMaskRectangle_RectangleWidthKey: CFString =
    _cvCFString("RectangleWidth")
public let kCVImageBufferDisplayMaskRectangle_RectangleTopKey: CFString =
    _cvCFString("RectangleTop")
public let kCVImageBufferDisplayMaskRectangle_RectangleHeightKey: CFString =
    _cvCFString("RectangleHeight")
public let kCVImageBufferDisplayMaskRectangle_LeftEdgePointsKey: CFString =
    _cvCFString("LeftEdgePoints")
public let kCVImageBufferDisplayMaskRectangle_RightEdgePointsKey: CFString =
    _cvCFString("RightEdgePoints")

public let kCVImageBufferChromaLocation_Left: CFString = _cvCFString("Left")
public let kCVImageBufferChromaLocation_Center: CFString = _cvCFString("Center")
public let kCVImageBufferChromaLocation_TopLeft: CFString = _cvCFString("TopLeft")
public let kCVImageBufferChromaLocation_Top: CFString = _cvCFString("Top")
public let kCVImageBufferChromaLocation_BottomLeft: CFString = _cvCFString("BottomLeft")
public let kCVImageBufferChromaLocation_Bottom: CFString = _cvCFString("Bottom")
public let kCVImageBufferChromaLocation_DV420: CFString = _cvCFString("DV420")

public let kCVImageBufferChromaSubsampling_420: CFString = _cvCFString("4:2:0")
public let kCVImageBufferChromaSubsampling_422: CFString = _cvCFString("4:2:2")
public let kCVImageBufferChromaSubsampling_411: CFString = _cvCFString("4:1:1")

public let kCVImageBufferColorPrimaries_ITU_R_709_2: CFString = _cvCFString("ITU_R_709_2")
public let kCVImageBufferColorPrimaries_EBU_3213: CFString = _cvCFString("EBU_3213")
public let kCVImageBufferColorPrimaries_SMPTE_C: CFString = _cvCFString("SMPTE_C")
public let kCVImageBufferColorPrimaries_P22: CFString = _cvCFString("P22")
public let kCVImageBufferColorPrimaries_DCI_P3: CFString = _cvCFString("DCI_P3")
public let kCVImageBufferColorPrimaries_P3_D65: CFString = _cvCFString("P3_D65")
public let kCVImageBufferColorPrimaries_ITU_R_2020: CFString = _cvCFString("ITU_R_2020")

public let kCVImageBufferTransferFunction_ITU_R_709_2: CFString = _cvCFString("ITU_R_709_2")
public let kCVImageBufferTransferFunction_SMPTE_240M_1995: CFString =
    _cvCFString("SMPTE_240M_1995")
public let kCVImageBufferTransferFunction_UseGamma: CFString = _cvCFString("UseGamma")
public let kCVImageBufferTransferFunction_ITU_R_2020: CFString = _cvCFString("ITU_R_2020")
public let kCVImageBufferTransferFunction_SMPTE_ST_428_1: CFString = _cvCFString("SMPTE_ST_428_1")
public let kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ: CFString =
    _cvCFString("SMPTE_ST_2084_PQ")
public let kCVImageBufferTransferFunction_ITU_R_2100_HLG: CFString =
    _cvCFString("ITU_R_2100_HLG")
public let kCVImageBufferTransferFunction_Linear: CFString = _cvCFString("Linear")
public let kCVImageBufferTransferFunction_sRGB: CFString = _cvCFString("IEC_sRGB")
public let kCVImageBufferLogTransferFunction_AppleLog: CFString = _cvCFString("Apple Log")
public let kCVImageBufferLogTransferFunction_AppleLog2: CFString = _cvCFString("Apple Log 2")

public let kCVImageBufferYCbCrMatrix_ITU_R_709_2: CFString = _cvCFString("ITU_R_709_2")
public let kCVImageBufferYCbCrMatrix_ITU_R_601_4: CFString = _cvCFString("ITU_R_601_4")
public let kCVImageBufferYCbCrMatrix_SMPTE_240M_1995: CFString = _cvCFString("SMPTE_240M_1995")
public let kCVImageBufferYCbCrMatrix_ITU_R_2020: CFString = _cvCFString("ITU_R_2020")
public let kCVImageBufferYCbCrMatrix_DCI_P3: CFString = _cvCFString("DCI_P3")
public let kCVImageBufferYCbCrMatrix_P3_D65: CFString = _cvCFString("P3_D65")

public let kCVPixelFormatName: CFString = _cvCFString("Name")
public let kCVPixelFormatConstant: CFString = _cvCFString("PixelFormat")
public let kCVPixelFormatCodecType: CFString = _cvCFString("CodecType")
public let kCVPixelFormatFourCC: CFString = _cvCFString("FourCC")
public let kCVPixelFormatPlanes: CFString = _cvCFString("Planes")
public let kCVPixelFormatBlockWidth: CFString = _cvCFString("BlockWidth")
public let kCVPixelFormatBlockHeight: CFString = _cvCFString("BlockHeight")
public let kCVPixelFormatBitsPerBlock: CFString = _cvCFString("BitsPerBlock")
public let kCVPixelFormatBlockHorizontalAlignment: CFString =
    _cvCFString("BlockHorizontalAlignment")
public let kCVPixelFormatBlockVerticalAlignment: CFString = _cvCFString("BlockVerticalAlignment")
public let kCVPixelFormatBitsPerComponent: CFString = _cvCFString("BitsPerComponent")
public let kCVPixelFormatHorizontalSubsampling: CFString = _cvCFString("HorizontalSubsampling")
public let kCVPixelFormatVerticalSubsampling: CFString = _cvCFString("VerticalSubsampling")
public let kCVPixelFormatOpenGLFormat: CFString = _cvCFString("OpenGLFormat")
public let kCVPixelFormatOpenGLType: CFString = _cvCFString("OpenGLType")
public let kCVPixelFormatOpenGLInternalFormat: CFString = _cvCFString("OpenGLInternalFormat")
public let kCVPixelFormatCGBitmapInfo: CFString = _cvCFString("CGBitmapInfo")
public let kCVPixelFormatQDCompatibility: CFString = _cvCFString("QDCompatibility")
public let kCVPixelFormatCGBitmapContextCompatibility: CFString =
    _cvCFString("CGBitmapContextCompatibility")
public let kCVPixelFormatCGImageCompatibility: CFString = _cvCFString("CGImageCompatibility")
public let kCVPixelFormatOpenGLCompatibility: CFString = _cvCFString("OpenGLCompatibility")
public let kCVPixelFormatOpenGLESCompatibility: CFString = _cvCFString("OpenGLESCompatibility")
public let kCVPixelFormatFillExtendedPixelsCallback: CFString =
    _cvCFString("FillExtendedPixelsCallback")
public let kCVPixelFormatBlackBlock: CFString = _cvCFString("BlackBlock")
public let kCVPixelFormatContainsAlpha: CFString = _cvCFString("ContainsAlpha")
public let kCVPixelFormatContainsYCbCr: CFString = _cvCFString("ContainsYCbCr")
public let kCVPixelFormatContainsRGB: CFString = _cvCFString("ContainsRGB")
public let kCVPixelFormatContainsGrayscale: CFString = _cvCFString("ContainsGrayscale")
public let kCVPixelFormatContainsSenselArray: CFString = _cvCFString("ContainsSenselArray")
public let kCVPixelFormatComponentRange: CFString = _cvCFString("ComponentRange")
public let kCVPixelFormatComponentRange_VideoRange: CFString = _cvCFString("VideoRange")
public let kCVPixelFormatComponentRange_FullRange: CFString = _cvCFString("FullRange")
public let kCVPixelFormatComponentRange_WideRange: CFString = _cvCFString("WideRange")

public let kCVMetalBufferCacheMaximumBufferAgeKey: CFString = _cvCFString("CacheMaximumBufferAge")
public let kCVMetalTextureCacheMaximumTextureAgeKey: CFString =
    _cvCFString("CacheMaximumTextureAge")
public let kCVMetalTextureUsage: CFString = _cvCFString("Usage")
public let kCVMetalTextureStorageMode: CFString = _cvCFString("StorageMode")
public let kCVOpenGLESTextureCacheMaximumTextureAgeKey: CFString =
    _cvCFString("CacheMaximumTextureAge")

private let _cvPrimaries: [(CFString, Int32)] = [
    (kCVImageBufferColorPrimaries_ITU_R_709_2, 1),
    (kCVImageBufferColorPrimaries_EBU_3213, 5),
    (kCVImageBufferColorPrimaries_SMPTE_C, 6),
    (kCVImageBufferColorPrimaries_ITU_R_2020, 9),
    (kCVImageBufferColorPrimaries_DCI_P3, 11),
    (kCVImageBufferColorPrimaries_P3_D65, 12),
    (kCVImageBufferColorPrimaries_P22, 1),
]

private let _cvTransfer: [(CFString, Int32)] = [
    (kCVImageBufferTransferFunction_ITU_R_709_2, 1),
    (kCVImageBufferTransferFunction_SMPTE_240M_1995, 7),
    (kCVImageBufferTransferFunction_ITU_R_2020, 14),
    (kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ, 16),
    (kCVImageBufferTransferFunction_SMPTE_ST_428_1, 17),
    (kCVImageBufferTransferFunction_ITU_R_2100_HLG, 18),
    (kCVImageBufferTransferFunction_Linear, 8),
    (kCVImageBufferTransferFunction_sRGB, 13),
]

private let _cvMatrix: [(CFString, Int32)] = [
    (kCVImageBufferYCbCrMatrix_ITU_R_709_2, 1),
    (kCVImageBufferYCbCrMatrix_ITU_R_601_4, 6),
    (kCVImageBufferYCbCrMatrix_SMPTE_240M_1995, 7),
    (kCVImageBufferYCbCrMatrix_ITU_R_2020, 9),
]

private func _cvCodePoint(for string: CFString?, table: [(CFString, Int32)]) -> Int32 {
    guard let string else { return 0 }
    for (name, code) in table where name.isEqual(to: string as String) {
        return code
    }
    return 0
}

private func _cvString(for code: Int32, table: [(CFString, Int32)]) -> Unmanaged<CFString>? {
    for (name, value) in table where value == code {
        return Unmanaged.passUnretained(name)
    }
    return nil
}

public func CVColorPrimariesGetIntegerCodePointForString(_ colorPrimariesString: CFString?) -> Int32 {
    _cvCodePoint(for: colorPrimariesString, table: _cvPrimaries)
}

public func CVColorPrimariesGetStringForIntegerCodePoint(
    _ colorPrimariesCodePoint: Int32
) -> Unmanaged<CFString>? {
    _cvString(for: colorPrimariesCodePoint, table: _cvPrimaries)
}

public func CVTransferFunctionGetIntegerCodePointForString(
    _ transferFunctionString: CFString?
) -> Int32 {
    _cvCodePoint(for: transferFunctionString, table: _cvTransfer)
}

public func CVTransferFunctionGetStringForIntegerCodePoint(
    _ transferFunctionCodePoint: Int32
) -> Unmanaged<CFString>? {
    _cvString(for: transferFunctionCodePoint, table: _cvTransfer)
}

public func CVYCbCrMatrixGetIntegerCodePointForString(_ yCbCrMatrixString: CFString?) -> Int32 {
    _cvCodePoint(for: yCbCrMatrixString, table: _cvMatrix)
}

public func CVYCbCrMatrixGetStringForIntegerCodePoint(
    _ yCbCrMatrixCodePoint: Int32
) -> Unmanaged<CFString>? {
    _cvString(for: yCbCrMatrixCodePoint, table: _cvMatrix)
}
