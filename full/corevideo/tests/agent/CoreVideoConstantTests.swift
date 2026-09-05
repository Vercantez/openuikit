import CoreVideo
import Foundation

func testPixelFormatFourCCs() {
    precondition(kCVPixelFormatType_1Monochrome == 1)
    precondition(kCVPixelFormatType_2Indexed == 2)
    precondition(kCVPixelFormatType_4Indexed == 4)
    precondition(kCVPixelFormatType_8Indexed == 8)
    precondition(kCVPixelFormatType_16BE555 == 16)
    precondition(kCVPixelFormatType_24RGB == 24)
    precondition(kCVPixelFormatType_32ARGB == 32)
    precondition(kCVPixelFormatType_1IndexedGray_WhiteIsZero == 0x21)
    precondition(kCVPixelFormatType_2IndexedGray_WhiteIsZero == 0x22)
    precondition(kCVPixelFormatType_4IndexedGray_WhiteIsZero == 0x24)
    precondition(kCVPixelFormatType_8IndexedGray_WhiteIsZero == 0x28)
    precondition(kCVPixelFormatType_16LE555 == 0x4C35_3535)
    precondition(kCVPixelFormatType_16LE5551 == 0x3535_3531)
    precondition(kCVPixelFormatType_16BE565 == 0x4235_3635)
    precondition(kCVPixelFormatType_16LE565 == 0x4C35_3635)
    precondition(kCVPixelFormatType_24BGR == 0x3234_4247)
    precondition(kCVPixelFormatType_32BGRA == 0x4247_5241)
    precondition(kCVPixelFormatType_32ABGR == 0x4142_4752)
    precondition(kCVPixelFormatType_32RGBA == 0x5247_4241)
    precondition(kCVPixelFormatType_64ARGB == 0x6236_3461)
    precondition(kCVPixelFormatType_64RGBALE == 0x6C36_3472)
    precondition(kCVPixelFormatType_48RGB == 0x6234_3872)
    precondition(kCVPixelFormatType_32AlphaGray == 0x6233_3261)
    precondition(kCVPixelFormatType_16Gray == 0x6231_3667)
    precondition(kCVPixelFormatType_30RGB == 0x5231_306B)
    precondition(kCVPixelFormatType_30RGB_r210 == 0x7232_3130)
    precondition(kCVPixelFormatType_422YpCbCr8 == 0x3276_7579)
    precondition(kCVPixelFormatType_4444YpCbCrA8 == 0x7634_3038)
    precondition(kCVPixelFormatType_4444YpCbCrA8R == 0x7234_3038)
    precondition(kCVPixelFormatType_4444AYpCbCr8 == 0x7934_3038)
    precondition(kCVPixelFormatType_4444AYpCbCr16 == 0x7934_3136)
    precondition(kCVPixelFormatType_4444AYpCbCrFloat == 0x7234_666C)
    precondition(kCVPixelFormatType_444YpCbCr8 == 0x7633_3038)
    precondition(kCVPixelFormatType_422YpCbCr16 == 0x7632_3136)
    precondition(kCVPixelFormatType_422YpCbCr10 == 0x7632_3130)
    precondition(kCVPixelFormatType_444YpCbCr10 == 0x7634_3130)
    precondition(kCVPixelFormatType_420YpCbCr8Planar == 0x7934_3230)
    precondition(kCVPixelFormatType_420YpCbCr8PlanarFullRange == 0x6634_3230)
    precondition(kCVPixelFormatType_422YpCbCr_4A_8BiPlanar == 0x6132_7679)
    precondition(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == 0x3432_3076)
    precondition(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == 0x3432_3066)
    precondition(kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange == 0x3432_3276)
    precondition(kCVPixelFormatType_422YpCbCr8BiPlanarFullRange == 0x3432_3266)
    precondition(kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange == 0x3434_3476)
    precondition(kCVPixelFormatType_444YpCbCr8BiPlanarFullRange == 0x3434_3466)
    precondition(kCVPixelFormatType_422YpCbCr8_yuvs == 0x7975_7673)
    precondition(kCVPixelFormatType_422YpCbCr8FullRange == 0x7975_7666)
    precondition(kCVPixelFormatType_OneComponent8 == 0x4C30_3038)
    precondition(kCVPixelFormatType_TwoComponent8 == 0x3243_3038)
    precondition(kCVPixelFormatType_30RGBLEPackedWideGamut == 0x7733_3072)
    precondition(kCVPixelFormatType_ARGB2101010LEPacked == 0x6C31_3072)
    precondition(kCVPixelFormatType_40ARGBLEWideGamut == 0x7734_3061)
    precondition(kCVPixelFormatType_40ARGBLEWideGamutPremultiplied == 0x7734_306D)
    precondition(kCVPixelFormatType_OneComponent10 == 0x4C30_3130)
    precondition(kCVPixelFormatType_OneComponent12 == 0x4C30_3132)
    precondition(kCVPixelFormatType_OneComponent16 == 0x4C30_3136)
    precondition(kCVPixelFormatType_TwoComponent16 == 0x3243_3136)
    precondition(kCVPixelFormatType_OneComponent16Half == 0x4C30_3068)
    precondition(kCVPixelFormatType_OneComponent32Float == 0x4C30_3066)
    precondition(kCVPixelFormatType_TwoComponent16Half == 0x3243_3068)
    precondition(kCVPixelFormatType_TwoComponent32Float == 0x3243_3066)
    precondition(kCVPixelFormatType_64RGBAHalf == 0x5247_6841)
    precondition(kCVPixelFormatType_128RGBAFloat == 0x5247_6641)
    precondition(kCVPixelFormatType_14Bayer_GRBG == 0x6772_6234)
    precondition(kCVPixelFormatType_14Bayer_RGGB == 0x7267_6734)
    precondition(kCVPixelFormatType_14Bayer_BGGR == 0x6267_6734)
    precondition(kCVPixelFormatType_14Bayer_GBRG == 0x6762_7234)
    precondition(kCVPixelFormatType_DisparityFloat16 == 0x6864_6973)
    precondition(kCVPixelFormatType_DisparityFloat32 == 0x6664_6973)
    precondition(kCVPixelFormatType_DepthFloat16 == 0x6864_6570)
    precondition(kCVPixelFormatType_DepthFloat32 == 0x6664_6570)
    precondition(kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange == 0x7834_3230)
    precondition(kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange == 0x7834_3232)
    precondition(kCVPixelFormatType_444YpCbCr10BiPlanarVideoRange == 0x7834_3434)
    precondition(kCVPixelFormatType_420YpCbCr10BiPlanarFullRange == 0x7866_3230)
    precondition(kCVPixelFormatType_422YpCbCr10BiPlanarFullRange == 0x7866_3232)
    precondition(kCVPixelFormatType_444YpCbCr10BiPlanarFullRange == 0x7866_3434)
    precondition(kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar == 0x7630_6138)
    precondition(kCVPixelFormatType_16VersatileBayer == 0x6270_3136)
    precondition(kCVPixelFormatType_96VersatileBayerPacked12 == 0x6274_7032)
    precondition(kCVPixelFormatType_64RGBA_DownscaledProResRAW == 0x6270_3634)
    precondition(kCVPixelFormatType_422YpCbCr16BiPlanarVideoRange == 0x7376_3232)
    precondition(kCVPixelFormatType_444YpCbCr16BiPlanarVideoRange == 0x7376_3434)
    precondition(kCVPixelFormatType_444YpCbCr16VideoRange_16A_TriPlanar == 0x7334_6173)
    precondition(kCVPixelFormatType_30RGBLE_8A_BiPlanar == 0x6233_6138)
    precondition(kCVPixelFormatType_Lossless_32BGRA == 0x2642_4741)
    precondition(kCVPixelFormatType_Lossless_64RGBAHalf == 0x2652_6841)
    precondition(kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange == 0x2638_7630)
    precondition(kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange == 0x2638_6630)
    precondition(kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange == 0x2678_7630)
    precondition(kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarVideoRange == 0x2678_7632)
    precondition(kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange == 0x2678_6630)
    precondition(kCVPixelFormatType_Lossless_30RGBLE_8A_BiPlanar == 0x2662_3338)
    precondition(kCVPixelFormatType_Lossless_30RGBLEPackedWideGamut == 0x2677_3372)
    precondition(kCVPixelFormatType_Lossy_32BGRA == 0x2D42_4741)
    precondition(kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange == 0x2D38_7630)
    precondition(kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange == 0x2D38_6630)
    precondition(kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange == 0x2D78_7630)
    precondition(kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarVideoRange == 0x2D78_7632)
}

func testCVReturnCodes() {
    precondition(kCVReturnSuccess == 0)
    precondition(kCVReturnFirst == -6660)
    precondition(kCVReturnError == -6660)
    precondition(kCVReturnInvalidArgument == -6661)
    precondition(kCVReturnAllocationFailed == -6662)
    precondition(kCVReturnUnsupported == -6663)
    precondition(kCVReturnInvalidDisplay == -6670)
    precondition(kCVReturnDisplayLinkAlreadyRunning == -6671)
    precondition(kCVReturnDisplayLinkNotRunning == -6672)
    precondition(kCVReturnDisplayLinkCallbacksNotSet == -6673)
    precondition(kCVReturnInvalidPixelFormat == -6680)
    precondition(kCVReturnInvalidSize == -6681)
    precondition(kCVReturnInvalidPixelBufferAttributes == -6682)
    precondition(kCVReturnPixelBufferNotOpenGLCompatible == -6683)
    precondition(kCVReturnPixelBufferNotMetalCompatible == -6684)
    precondition(kCVReturnWouldExceedAllocationThreshold == -6689)
    precondition(kCVReturnPoolAllocationFailed == -6690)
    precondition(kCVReturnInvalidPoolAttributes == -6691)
    precondition(kCVReturnRetry == -6692)
    precondition(kCVReturnLast == -6699)
}

func testFeatureFlags() {
    precondition(COREVIDEO_TRUE == true)
    precondition(COREVIDEO_FALSE == false)
    precondition(COREVIDEO_DECLARE_NULLABILITY == true)
    precondition(COREVIDEO_USE_DERIVED_ENUMS_FOR_CONSTANTS == true)
    precondition(COREVIDEO_INCLUDED_IOSURFACE_HEADER_FILE == 0)
    precondition(COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API == 0)
    precondition(COREVIDEO_USE_IOSURFACEREF == false)
    precondition(COREVIDEO_SUPPORTS_COLORSPACE == false)
    precondition(COREVIDEO_SUPPORTS_DIRECT3D == false)
    precondition(COREVIDEO_SUPPORTS_DISPLAYLINK == false)
    precondition(COREVIDEO_SUPPORTS_GLES_TEX_IMAGE_IOSURFACE == false)
    precondition(COREVIDEO_SUPPORTS_IOSURFACE == false)
    precondition(COREVIDEO_SUPPORTS_IOSURFACE_PREFETCH == false)
    precondition(COREVIDEO_SUPPORTS_METAL == false)
    precondition(COREVIDEO_SUPPORTS_OPENGL == false)
    precondition(COREVIDEO_SUPPORTS_OPENGLES == false)
    precondition(COREVIDEO_SUPPORTS_PERMANENT_ALLOCATOR == false)
    precondition(COREVIDEO_SUPPORTS_PREFETCH == false)
}

func testBayerPatternConstants() {
    precondition(kCVVersatileBayer_BayerPattern_RGGB == 0)
    precondition(kCVVersatileBayer_BayerPattern_GRBG == 1)
    precondition(kCVVersatileBayer_BayerPattern_GBRG == 2)
    precondition(kCVVersatileBayer_BayerPattern_BGGR == 3)
}

func testBufferAndPixelBufferKeys() {
    precondition((kCVBufferPropagatedAttachmentsKey as String) == "PropagatedAttachments")
    precondition((kCVBufferNonPropagatedAttachmentsKey as String) == "NonPropagatedAttachments")
    precondition((kCVBufferMovieTimeKey as String) == "MovieTime")
    precondition((kCVBufferTimeValueKey as String) == "TimeValue")
    precondition((kCVBufferTimeScaleKey as String) == "TimeScale")
    precondition((kCVPixelBufferPixelFormatTypeKey as String) == "PixelFormatType")
    precondition((kCVPixelBufferMemoryAllocatorKey as String) == "MemoryAllocator")
    precondition((kCVPixelBufferWidthKey as String) == "Width")
    precondition((kCVPixelBufferHeightKey as String) == "Height")
    precondition((kCVPixelBufferExtendedPixelsLeftKey as String) == "ExtendedPixelsLeft")
    precondition((kCVPixelBufferExtendedPixelsTopKey as String) == "ExtendedPixelsTop")
    precondition((kCVPixelBufferExtendedPixelsRightKey as String) == "ExtendedPixelsRight")
    precondition((kCVPixelBufferExtendedPixelsBottomKey as String) == "ExtendedPixelsBottom")
    precondition((kCVPixelBufferBytesPerRowAlignmentKey as String) == "BytesPerRowAlignment")
    precondition((kCVPixelBufferCGBitmapContextCompatibilityKey as String) == "CGBitmapContextCompatibility")
    precondition((kCVPixelBufferCGImageCompatibilityKey as String) == "CGImageCompatibility")
    precondition((kCVPixelBufferOpenGLCompatibilityKey as String) == "OpenGLCompatibility")
    precondition((kCVPixelBufferPlaneAlignmentKey as String) == "PlaneAlignment")
    precondition((kCVPixelBufferIOSurfacePropertiesKey as String) == "IOSurfaceProperties")
    precondition((kCVPixelBufferOpenGLESCompatibilityKey as String) == "OpenGLESCompatibility")
    precondition((kCVPixelBufferMetalCompatibilityKey as String) == "MetalCompatibility")
    precondition(
        (kCVPixelBufferOpenGLESTextureCacheCompatibilityKey as String)
            == "OpenGLESTextureCacheCompatibility"
    )
    precondition(
        (kCVPixelBufferIOSurfaceOpenGLESTextureCompatibilityKey as String)
            == "IOSurfaceOpenGLESTextureCompatibility"
    )
    precondition(
        (kCVPixelBufferIOSurfaceOpenGLESFBOCompatibilityKey as String)
            == "IOSurfaceOpenGLESFBOCompatibility"
    )
    precondition(
        (kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey as String)
            == "IOSurfaceCoreAnimationCompatibility"
    )
    precondition((kCVPixelBufferIOSurfacePurgeableKey as String) == "IOSurfacePurgeable")
    precondition((kCVPixelBufferPoolMinimumBufferCountKey as String) == "MinimumBufferCount")
    precondition((kCVPixelBufferPoolMaximumBufferAgeKey as String) == "MaximumBufferAge")
    precondition((kCVPixelBufferPoolAllocationThresholdKey as String) == "AllocationThreshold")
    precondition(
        (kCVPixelBufferPoolFreeBufferNotification as String)
            == "CVPixelBufferPoolFreeBufferNotification"
    )
    precondition((kCVPixelBufferVersatileBayerKey_BayerPattern as String) == "BayerPattern")
    precondition((kCVPixelBufferProResRAWKey_BlackLevel as String) == "ProResRAW_BlackLevel")
    precondition((kCVPixelBufferProResRAWKey_WhiteLevel as String) == "ProResRAW_WhiteLevel")
    precondition((kCVPixelBufferProResRAWKey_WhiteBalanceCCT as String) == "ProResRAW_WhiteBalanceCCT")
    precondition(
        (kCVPixelBufferProResRAWKey_WhiteBalanceRedFactor as String)
            == "ProResRAW_WhiteBalanceRedFactor"
    )
    precondition(
        (kCVPixelBufferProResRAWKey_WhiteBalanceBlueFactor as String)
            == "ProResRAW_WhiteBalanceBlueFactor"
    )
    precondition((kCVPixelBufferProResRAWKey_ColorMatrix as String) == "ProResRAW_ColorMatrix")
    precondition((kCVPixelBufferProResRAWKey_GainFactor as String) == "ProResRAW_GainFactor")
    precondition(
        (kCVPixelBufferProResRAWKey_RecommendedCrop as String) == "ProResRAW_RecommendedCrop"
    )
    precondition(
        (kCVPixelBufferProResRAWKey_SenselSitingOffsets as String) == "ProResRAW_SenselSitingOffsets"
    )
    precondition(
        (kCVPixelBufferProResRAWKey_MetadataExtension as String) == "ProResRAW_MetadataExtension"
    )
}

func testImageBufferKeys() {
    precondition((kCVImageBufferCGColorSpaceKey as String) == "CVImageBufferCGColorSpace")
    precondition((kCVImageBufferCleanApertureKey as String) == "CVImageBufferCleanAperture")
    precondition((kCVImageBufferCleanApertureWidthKey as String) == "Width")
    precondition((kCVImageBufferCleanApertureHeightKey as String) == "Height")
    precondition((kCVImageBufferCleanApertureHorizontalOffsetKey as String) == "HorizontalOffset")
    precondition((kCVImageBufferCleanApertureVerticalOffsetKey as String) == "VerticalOffset")
    precondition(
        (kCVImageBufferPreferredCleanApertureKey as String) == "CVImageBufferPreferredCleanAperture"
    )
    precondition((kCVImageBufferFieldCountKey as String) == "CVImageBufferFieldCount")
    precondition((kCVImageBufferFieldDetailKey as String) == "CVImageBufferFieldDetail")
    precondition((kCVImageBufferFieldDetailTemporalTopFirst as String) == "TemporalTopFirst")
    precondition((kCVImageBufferFieldDetailTemporalBottomFirst as String) == "TemporalBottomFirst")
    precondition((kCVImageBufferFieldDetailSpatialFirstLineEarly as String) == "SpatialFirstLineEarly")
    precondition((kCVImageBufferFieldDetailSpatialFirstLineLate as String) == "SpatialFirstLineLate")
    precondition((kCVImageBufferPixelAspectRatioKey as String) == "CVImageBufferPixelAspectRatio")
    precondition((kCVImageBufferPixelAspectRatioHorizontalSpacingKey as String) == "HorizontalSpacing")
    precondition((kCVImageBufferPixelAspectRatioVerticalSpacingKey as String) == "VerticalSpacing")
    precondition((kCVImageBufferDisplayDimensionsKey as String) == "CVImageBufferDisplayDimensions")
    precondition((kCVImageBufferDisplayWidthKey as String) == "Width")
    precondition((kCVImageBufferDisplayHeightKey as String) == "Height")
    precondition((kCVImageBufferGammaLevelKey as String) == "CVImageBufferGammaLevel")
    precondition((kCVImageBufferICCProfileKey as String) == "CVImageBufferICCProfile")
    precondition((kCVImageBufferYCbCrMatrixKey as String) == "CVImageBufferYCbCrMatrix")
    precondition((kCVImageBufferColorPrimariesKey as String) == "CVImageBufferColorPrimaries")
    precondition((kCVImageBufferTransferFunctionKey as String) == "CVImageBufferTransferFunction")
    precondition(
        (kCVImageBufferChromaLocationTopFieldKey as String) == "CVImageBufferChromaLocationTopField"
    )
    precondition(
        (kCVImageBufferChromaLocationBottomFieldKey as String)
            == "CVImageBufferChromaLocationBottomField"
    )
    precondition((kCVImageBufferChromaSubsamplingKey as String) == "CVImageBufferChromaSubsampling")
    precondition((kCVImageBufferAlphaChannelIsOpaque as String) == "CVImageBufferAlphaChannelIsOpaque")
    precondition((kCVImageBufferAlphaChannelModeKey as String) == "CVImageBufferAlphaChannelMode")
    precondition((kCVImageBufferAlphaChannelMode_StraightAlpha as String) == "StraightAlpha")
    precondition((kCVImageBufferAlphaChannelMode_PremultipliedAlpha as String) == "PremultipliedAlpha")
    precondition(
        (kCVImageBufferContentLightLevelInfoKey as String) == "CVImageBufferContentLightLevelInfo"
    )
    precondition(
        (kCVImageBufferMasteringDisplayColorVolumeKey as String)
            == "CVImageBufferMasteringDisplayColorVolume"
    )
    precondition(
        (kCVImageBufferAmbientViewingEnvironmentKey as String)
            == "CVImageBufferAmbientViewingEnvironment"
    )
    precondition(
        (kCVImageBufferLogTransferFunctionKey as String) == "CVImageBufferLogTransferFunction"
    )
    precondition((kCVImageBufferRegionOfInterestKey as String) == "CVImageBufferRegionOfInterest")
    precondition((kCVImageBufferSceneIlluminationKey as String) == "CVImageBufferSceneIllumination")
    precondition(
        (kCVImageBufferDisplayMaskRectangleKey as String) == "CVImageBufferDisplayMaskRectangle"
    )
    precondition(
        (kCVImageBufferDisplayMaskRectangleStereoLeftKey as String)
            == "CVImageBufferDisplayMaskRectangleStereoLeft"
    )
    precondition(
        (kCVImageBufferDisplayMaskRectangleStereoRightKey as String)
            == "CVImageBufferDisplayMaskRectangleStereoRight"
    )
    precondition(
        (kCVImageBufferDisplayMaskRectangle_ReferenceRasterWidthKey as String)
            == "ReferenceRasterWidth"
    )
    precondition(
        (kCVImageBufferDisplayMaskRectangle_ReferenceRasterHeightKey as String)
            == "ReferenceRasterHeight"
    )
    precondition((kCVImageBufferDisplayMaskRectangle_RectangleLeftKey as String) == "RectangleLeft")
    precondition((kCVImageBufferDisplayMaskRectangle_RectangleWidthKey as String) == "RectangleWidth")
    precondition((kCVImageBufferDisplayMaskRectangle_RectangleTopKey as String) == "RectangleTop")
    precondition(
        (kCVImageBufferDisplayMaskRectangle_RectangleHeightKey as String) == "RectangleHeight"
    )
    precondition((kCVImageBufferDisplayMaskRectangle_LeftEdgePointsKey as String) == "LeftEdgePoints")
    precondition(
        (kCVImageBufferDisplayMaskRectangle_RightEdgePointsKey as String) == "RightEdgePoints"
    )
    precondition((kCVImageBufferChromaLocation_Left as String) == "Left")
    precondition((kCVImageBufferChromaLocation_Center as String) == "Center")
    precondition((kCVImageBufferChromaLocation_TopLeft as String) == "TopLeft")
    precondition((kCVImageBufferChromaLocation_Top as String) == "Top")
    precondition((kCVImageBufferChromaLocation_BottomLeft as String) == "BottomLeft")
    precondition((kCVImageBufferChromaLocation_Bottom as String) == "Bottom")
    precondition((kCVImageBufferChromaLocation_DV420 as String) == "DV420")
    precondition((kCVImageBufferChromaSubsampling_420 as String) == "4:2:0")
    precondition((kCVImageBufferChromaSubsampling_422 as String) == "4:2:2")
    precondition((kCVImageBufferChromaSubsampling_411 as String) == "4:1:1")
    precondition((kCVImageBufferColorPrimaries_ITU_R_709_2 as String) == "ITU_R_709_2")
    precondition((kCVImageBufferColorPrimaries_EBU_3213 as String) == "EBU_3213")
    precondition((kCVImageBufferColorPrimaries_SMPTE_C as String) == "SMPTE_C")
    precondition((kCVImageBufferColorPrimaries_P22 as String) == "P22")
    precondition((kCVImageBufferColorPrimaries_DCI_P3 as String) == "DCI_P3")
    precondition((kCVImageBufferColorPrimaries_P3_D65 as String) == "P3_D65")
    precondition((kCVImageBufferColorPrimaries_ITU_R_2020 as String) == "ITU_R_2020")
    precondition((kCVImageBufferTransferFunction_ITU_R_709_2 as String) == "ITU_R_709_2")
    precondition((kCVImageBufferTransferFunction_SMPTE_240M_1995 as String) == "SMPTE_240M_1995")
    precondition((kCVImageBufferTransferFunction_UseGamma as String) == "UseGamma")
    precondition((kCVImageBufferTransferFunction_ITU_R_2020 as String) == "ITU_R_2020")
    precondition((kCVImageBufferTransferFunction_SMPTE_ST_428_1 as String) == "SMPTE_ST_428_1")
    precondition((kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ as String) == "SMPTE_ST_2084_PQ")
    precondition((kCVImageBufferTransferFunction_ITU_R_2100_HLG as String) == "ITU_R_2100_HLG")
    precondition((kCVImageBufferTransferFunction_Linear as String) == "Linear")
    precondition((kCVImageBufferTransferFunction_sRGB as String) == "IEC_sRGB")
    precondition((kCVImageBufferLogTransferFunction_AppleLog as String) == "Apple Log")
    precondition((kCVImageBufferLogTransferFunction_AppleLog2 as String) == "Apple Log 2")
    precondition((kCVImageBufferYCbCrMatrix_ITU_R_709_2 as String) == "ITU_R_709_2")
    precondition((kCVImageBufferYCbCrMatrix_ITU_R_601_4 as String) == "ITU_R_601_4")
    precondition((kCVImageBufferYCbCrMatrix_SMPTE_240M_1995 as String) == "SMPTE_240M_1995")
    precondition((kCVImageBufferYCbCrMatrix_ITU_R_2020 as String) == "ITU_R_2020")
    precondition((kCVImageBufferYCbCrMatrix_DCI_P3 as String) == "DCI_P3")
    precondition((kCVImageBufferYCbCrMatrix_P3_D65 as String) == "P3_D65")
}

func testPixelFormatDescriptionKeys() {
    precondition((kCVPixelFormatName as String) == "Name")
    precondition((kCVPixelFormatConstant as String) == "PixelFormat")
    precondition((kCVPixelFormatCodecType as String) == "CodecType")
    precondition((kCVPixelFormatFourCC as String) == "FourCC")
    precondition((kCVPixelFormatPlanes as String) == "Planes")
    precondition((kCVPixelFormatBlockWidth as String) == "BlockWidth")
    precondition((kCVPixelFormatBlockHeight as String) == "BlockHeight")
    precondition((kCVPixelFormatBitsPerBlock as String) == "BitsPerBlock")
    precondition((kCVPixelFormatBlockHorizontalAlignment as String) == "BlockHorizontalAlignment")
    precondition((kCVPixelFormatBlockVerticalAlignment as String) == "BlockVerticalAlignment")
    precondition((kCVPixelFormatBitsPerComponent as String) == "BitsPerComponent")
    precondition((kCVPixelFormatHorizontalSubsampling as String) == "HorizontalSubsampling")
    precondition((kCVPixelFormatVerticalSubsampling as String) == "VerticalSubsampling")
    precondition((kCVPixelFormatOpenGLFormat as String) == "OpenGLFormat")
    precondition((kCVPixelFormatOpenGLType as String) == "OpenGLType")
    precondition((kCVPixelFormatOpenGLInternalFormat as String) == "OpenGLInternalFormat")
    precondition((kCVPixelFormatCGBitmapInfo as String) == "CGBitmapInfo")
    precondition((kCVPixelFormatQDCompatibility as String) == "QDCompatibility")
    precondition(
        (kCVPixelFormatCGBitmapContextCompatibility as String) == "CGBitmapContextCompatibility"
    )
    precondition((kCVPixelFormatCGImageCompatibility as String) == "CGImageCompatibility")
    precondition((kCVPixelFormatOpenGLCompatibility as String) == "OpenGLCompatibility")
    precondition((kCVPixelFormatOpenGLESCompatibility as String) == "OpenGLESCompatibility")
    precondition((kCVPixelFormatFillExtendedPixelsCallback as String) == "FillExtendedPixelsCallback")
    precondition((kCVPixelFormatBlackBlock as String) == "BlackBlock")
    precondition((kCVPixelFormatContainsAlpha as String) == "ContainsAlpha")
    precondition((kCVPixelFormatContainsYCbCr as String) == "ContainsYCbCr")
    precondition((kCVPixelFormatContainsRGB as String) == "ContainsRGB")
    precondition((kCVPixelFormatContainsGrayscale as String) == "ContainsGrayscale")
    precondition((kCVPixelFormatContainsSenselArray as String) == "ContainsSenselArray")
    precondition((kCVPixelFormatComponentRange as String) == "ComponentRange")
    precondition((kCVPixelFormatComponentRange_VideoRange as String) == "VideoRange")
    precondition((kCVPixelFormatComponentRange_FullRange as String) == "FullRange")
    precondition((kCVPixelFormatComponentRange_WideRange as String) == "WideRange")
}

func testMetalAndOpenGLKeys() {
    precondition((kCVMetalBufferCacheMaximumBufferAgeKey as String) == "CacheMaximumBufferAge")
    precondition((kCVMetalTextureCacheMaximumTextureAgeKey as String) == "CacheMaximumTextureAge")
    precondition((kCVMetalTextureUsage as String) == "Usage")
    precondition((kCVMetalTextureStorageMode as String) == "StorageMode")
    precondition((kCVOpenGLESTextureCacheMaximumTextureAgeKey as String) == "CacheMaximumTextureAge")
}

func testTimeConstants() {
    precondition(kCVZeroTime.timeValue == 0 && kCVZeroTime.timeScale == 1)
    precondition(kCVIndefiniteTime.flagOptions.contains(.isIndefinite))
    precondition(kCVZeroTime == CVTime.zero)
    precondition(kCVIndefiniteTime == CVTime.indefinite)
}
