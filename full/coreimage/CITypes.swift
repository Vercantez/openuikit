import Foundation

public typealias CIKernelROICallback = (Int32, CGRect) -> CGRect

/// Pixel format newtype. Integer payloads are the pinned `dotnet/macios`
/// `CIFormat` enum values (explicit raw values marked "same as value in old enum").
public struct CIFormat: Hashable, RawRepresentable, Sendable {
    public var rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let ARGB8 = CIFormat(rawValue: 0)
    public static let RGBAh = CIFormat(rawValue: 1)
    public static let RGBA16 = CIFormat(rawValue: 2)
    public static let RGBAf = CIFormat(rawValue: 4)
    public static let BGRA8 = CIFormat(rawValue: 5)
    public static let RGBA8 = CIFormat(rawValue: 6)
    public static let ABGR8 = CIFormat(rawValue: 7)
    public static let A8 = CIFormat(rawValue: 11)
    public static let A16 = CIFormat(rawValue: 12)
    public static let Ah = CIFormat(rawValue: 13)
    public static let Af = CIFormat(rawValue: 14)
    public static let R8 = CIFormat(rawValue: 15)
    public static let R16 = CIFormat(rawValue: 16)
    public static let Rh = CIFormat(rawValue: 17)
    public static let Rf = CIFormat(rawValue: 18)
    public static let RG8 = CIFormat(rawValue: 19)
    public static let RG16 = CIFormat(rawValue: 20)
    public static let RGh = CIFormat(rawValue: 21)
    public static let RGf = CIFormat(rawValue: 22)
    public static let L8 = CIFormat(rawValue: 23)
    public static let L16 = CIFormat(rawValue: 24)
    public static let Lh = CIFormat(rawValue: 25)
    public static let Lf = CIFormat(rawValue: 26)
    public static let LA8 = CIFormat(rawValue: 27)
    public static let LA16 = CIFormat(rawValue: 28)
    public static let LAh = CIFormat(rawValue: 29)
    public static let LAf = CIFormat(rawValue: 30)
    public static let RGB10 = CIFormat(rawValue: 31)
    public static let RGBX16 = CIFormat(rawValue: 32)
    public static let rgbXf = CIFormat(rawValue: 33)
    public static let rgbXh = CIFormat(rawValue: 34)
    public static let RGBX8 = CIFormat(rawValue: 35)
}

public struct CIContextOption: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let allowLowPower = CIContextOption(rawValue: "kCIContextAllowLowPower")
    public static let cvMetalTextureCache = CIContextOption(rawValue: "kCIContextCVMetalTextureCache")
    public static let cacheIntermediates = CIContextOption(rawValue: "kCIContextCacheIntermediates")
    public static let highQualityDownsample = CIContextOption(rawValue: "kCIContextHighQualityDownsample")
    public static let memoryTarget = CIContextOption(rawValue: "kCIContextMemoryLimit")
    public static let name = CIContextOption(rawValue: "kCIContextName")
    public static let outputColorSpace = CIContextOption(rawValue: "kCIContextOutputColorSpace")
    public static let outputPremultiplied = CIContextOption(rawValue: "kCIContextOutputPremultiplied")
    public static let priorityRequestLow = CIContextOption(rawValue: "kCIContextPriorityRequestLow")
    public static let useSoftwareRenderer = CIContextOption(rawValue: "kCIContextUseSoftwareRenderer")
    public static let workingColorSpace = CIContextOption(rawValue: "kCIContextWorkingColorSpace")
    public static let workingFormat = CIContextOption(rawValue: "kCIContextWorkingFormat")
}

public struct CIImageOption: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let applyCleanAperture = CIImageOption(rawValue: "kCIImageApplyCleanAperture")
    public static let applyOrientationProperty = CIImageOption(rawValue: "kCIImageApplyOrientationProperty")
    public static let auxiliaryDepth = CIImageOption(rawValue: "kCIImageAuxiliaryDepth")
    public static let auxiliaryDisparity = CIImageOption(rawValue: "kCIImageAuxiliaryDisparity")
    public static let auxiliaryHDRGainMap = CIImageOption(rawValue: "kCIImageAuxiliaryHDRGainMap")
    public static let auxiliaryPortraitEffectsMatte = CIImageOption(rawValue: "kCIImageAuxiliaryPortraitEffectsMatte")
    public static let auxiliarySemanticSegmentationGlassesMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationGlassesMatte")
    public static let auxiliarySemanticSegmentationHairMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationHairMatte")
    public static let auxiliarySemanticSegmentationSkinMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationSkinMatte")
    public static let auxiliarySemanticSegmentationSkyMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationSkyMatte")
    public static let auxiliarySemanticSegmentationTeethMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationTeethMatte")
    public static let cacheImmediately = CIImageOption(rawValue: "kCIImageCacheImmediately")
    public static let colorSpace = CIImageOption(rawValue: "kCIImageColorSpace")
    public static let contentAverageLightLevel = CIImageOption(rawValue: "kCIImageContentAverageLightLevel")
    public static let contentHeadroom = CIImageOption(rawValue: "kCIImageContentHeadroom")
    public static let expandToHDR = CIImageOption(rawValue: "kCIImageExpandToHDR")
    public static let nearestSampling = CIImageOption(rawValue: "kCIImageNearestSampling")
    public static let properties = CIImageOption(rawValue: "kCIImageProperties")
    public static let providerTileSize = CIImageOption(rawValue: "kCIImageProviderTileSize")
    public static let providerUserInfo = CIImageOption(rawValue: "kCIImageProviderUserInfo")
    public static let toneMapHDRtoSDR = CIImageOption(rawValue: "kCIImageToneMapHDRtoSDR")
}

public struct CIImageAutoAdjustmentOption: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let crop = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustCrop")
    public static let enhance = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustEnhance")
    public static let features = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustFeatures")
    public static let level = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustLevel")
    public static let redEye = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustRedEye")
}

public struct CIImageRepresentationOption: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let avDepthData = CIImageRepresentationOption(rawValue: "kCIImageRepresentationAVDepthData")
    public static let avPortraitEffectsMatte = CIImageRepresentationOption(rawValue: "kCIImageRepresentationAVPortraitEffectsMatte")
    public static let avSemanticSegmentationMattes = CIImageRepresentationOption(rawValue: "kCIImageRepresentationAVSemanticSegmentationMattes")
    public static let depthImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationDepthImage")
    public static let disparityImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationDisparityImage")
    public static let hdrGainMapAsRGB = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRGainMapAsRGB")
    public static let hdrGainMapImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRGainMapImage")
    public static let hdrImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRImage")
    public static let portraitEffectsMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationPortraitEffectsMatteImage")
    public static let semanticSegmentationGlassesMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationGlassesMatteImage")
    public static let semanticSegmentationHairMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationHairMatteImage")
    public static let semanticSegmentationSkinMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationSkinMatteImage")
    public static let semanticSegmentationSkyMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationSkyMatteImage")
    public static let semanticSegmentationTeethMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationTeethMatteImage")
}

public struct CIDynamicRangeOption: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let constrainedHigh = CIDynamicRangeOption(rawValue: "kCIDynamicRangeConstrainedHigh")
    public static let high = CIDynamicRangeOption(rawValue: "kCIDynamicRangeHigh")
    public static let standard = CIDynamicRangeOption(rawValue: "kCIDynamicRangeStandard")
}

public struct CIRAWDecoderVersion: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let none = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersionNone")
    public static let version6 = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion6")
    public static let version6DNG = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion6DNG")
    public static let version7 = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion7")
    public static let version7DNG = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion7DNG")
    public static let version8 = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion8")
    public static let version8DNG = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion8DNG")
    public static let version9 = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion9")
    public static let version9DNG = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion9DNG")
}

public struct CIRAWFilterOption: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let activeKeys = CIRAWFilterOption(rawValue: "kCIActiveKeys")
    public static let allowDraftMode = CIRAWFilterOption(rawValue: "kCIInputAllowDraftModeKey")
    public static let baselineExposure = CIRAWFilterOption(rawValue: "kCIInputBaselineExposureKey")
    public static let boostAmount = CIRAWFilterOption(rawValue: "kCIInputBoostKey")
    public static let boostShadowAmount = CIRAWFilterOption(rawValue: "kCIInputBoostShadowAmountKey")
    public static let colorNoiseReductionAmount = CIRAWFilterOption(rawValue: "kCIInputColorNoiseReductionAmountKey")
    public static let decoderVersion = CIRAWFilterOption(rawValue: "kCIInputDecoderVersionKey")
    public static let disableGamutMap = CIRAWFilterOption(rawValue: "kCIInputDisableGamutMapKey")
    public static let enableChromaticNoiseTracking = CIRAWFilterOption(rawValue: "kCIInputEnableChromaticNoiseTrackingKey")
    public static let ciInputEnableEDRModeKey = CIRAWFilterOption(rawValue: "kCIInputEnableEDRModeKey")
    public static let enableSharpening = CIRAWFilterOption(rawValue: "kCIInputEnableSharpeningKey")
    public static let enableVendorLensCorrection = CIRAWFilterOption(rawValue: "kCIInputEnableVendorLensCorrectionKey")
    public static let ignoreImageOrientation = CIRAWFilterOption(rawValue: "kCIInputIgnoreImageOrientationKey")
    public static let imageOrientation = CIRAWFilterOption(rawValue: "kCIInputImageOrientationKey")
    public static let linearSpaceFilter = CIRAWFilterOption(rawValue: "kCIInputLinearSpaceFilter")
    public static let ciInputLocalToneMapAmountKey = CIRAWFilterOption(rawValue: "kCIInputLocalToneMapAmountKey")
    public static let luminanceNoiseReductionAmount = CIRAWFilterOption(rawValue: "kCIInputLuminanceNoiseReductionAmountKey")
    public static let moireAmount = CIRAWFilterOption(rawValue: "kCIInputMoireAmountKey")
    public static let neutralChromaticityX = CIRAWFilterOption(rawValue: "kCIInputNeutralChromaticityXKey")
    public static let neutralChromaticityY = CIRAWFilterOption(rawValue: "kCIInputNeutralChromaticityYKey")
    public static let neutralLocation = CIRAWFilterOption(rawValue: "kCIInputNeutralLocationKey")
    public static let neutralTemperature = CIRAWFilterOption(rawValue: "kCIInputNeutralTemperatureKey")
    public static let neutralTint = CIRAWFilterOption(rawValue: "kCIInputNeutralTintKey")
    public static let noiseReductionAmount = CIRAWFilterOption(rawValue: "kCIInputNoiseReductionAmountKey")
    public static let noiseReductionContrastAmount = CIRAWFilterOption(rawValue: "kCIInputNoiseReductionContrastAmountKey")
    public static let noiseReductionDetailAmount = CIRAWFilterOption(rawValue: "kCIInputNoiseReductionDetailAmountKey")
    public static let noiseReductionSharpnessAmount = CIRAWFilterOption(rawValue: "kCIInputNoiseReductionSharpnessAmountKey")
    public static let scaleFactor = CIRAWFilterOption(rawValue: "kCIInputScaleFactorKey")
    public static let outputNativeSize = CIRAWFilterOption(rawValue: "kCIOutputNativeSizeKey")
    public static let propertiesKey = CIRAWFilterOption(rawValue: "kCIPropertiesKey")
    public static let supportedDecoderVersions = CIRAWFilterOption(rawValue: "kCISupportedDecoderVersionsKey")
}

public typealias NSErrorPointer = UnsafeMutablePointer<NSError?>?

public enum CIRenderDestinationAlphaMode: UInt, Hashable, Sendable {
    case none = 0
    case premultiplied = 1
    case unpremultiplied = 2
}

/// Fail-closed software-renderer error used by throwing Core Image APIs.
public enum CIRenderError: Error, Equatable {
    case unsupported
    case invalidArgument
    case unknown
}
