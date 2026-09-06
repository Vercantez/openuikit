import CoreImage
import Foundation

func testCIRAWFilterPropertyStateMachine() {
    let raw = CIRAWFilter()
    precondition(raw.name == "CIRAWFilter")
    precondition(raw.outputImage == nil)
    precondition(CIRAWFilter.supportedCameraModels.isEmpty)
    precondition(raw.supportedDecoderVersions.isEmpty)
    precondition(raw.nativeSize == .zero)
    precondition(raw.decoderVersion == .none)
    precondition(!raw.isColorNoiseReductionSupported)
    precondition(!raw.isContrastSupported)
    precondition(!raw.isDetailSupported)
    precondition(!raw.isHighlightRecoverySupported)
    precondition(!raw.isLensCorrectionSupported)
    precondition(!raw.isLocalToneMapSupported)
    precondition(!raw.isLuminanceNoiseReductionSupported)
    precondition(!raw.isMoireReductionSupported)
    precondition(!raw.isSharpnessSupported)

    raw.baselineExposure = -0.5
    precondition(raw.baselineExposure == -0.5)
    raw.boostAmount = 1.5
    precondition(raw.boostAmount == 1)
    raw.boostAmount = -1
    precondition(raw.boostAmount == 0)
    raw.boostShadowAmount = 0.25
    precondition(raw.boostShadowAmount == 0.25)
    raw.colorNoiseReductionAmount = 0.3
    precondition(raw.colorNoiseReductionAmount == 0.3)
    raw.contrastAmount = 0.4
    precondition(raw.contrastAmount == 0.4)
    raw.decoderVersion = .version8
    precondition(raw.decoderVersion == .version8)
    raw.detailAmount = 0.5
    precondition(raw.detailAmount == 0.5)
    raw.isDraftModeEnabled = true
    precondition(raw.isDraftModeEnabled)
    raw.exposure = 1.25
    precondition(raw.exposure == 1.25)
    raw.extendedDynamicRangeAmount = 0.6
    precondition(raw.extendedDynamicRangeAmount == 0.6)
    raw.isGamutMappingEnabled = true
    precondition(raw.isGamutMappingEnabled)
    raw.isHighlightRecoveryEnabled = true
    precondition(raw.isHighlightRecoveryEnabled)
    raw.isLensCorrectionEnabled = true
    precondition(raw.isLensCorrectionEnabled)
    raw.linearSpaceFilter = CIFilter(name: "CIExposureAdjust")
    precondition(raw.linearSpaceFilter?.name == "CIExposureAdjust")
    raw.localToneMapAmount = 0.7
    precondition(raw.localToneMapAmount == 0.7)
    raw.luminanceNoiseReductionAmount = 0.8
    precondition(raw.luminanceNoiseReductionAmount == 0.8)
    raw.moireReductionAmount = 0.9
    precondition(raw.moireReductionAmount == 0.9)
    raw.nativeSize = CGSize(width: 4032, height: 3024)
    precondition(raw.nativeSize.width == 4032)
    raw.neutralChromaticity = CGPoint(x: 0.33, y: 0.33)
    precondition(raw.neutralChromaticity.x == 0.33)
    raw.neutralLocation = CGPoint(x: 10, y: 20)
    precondition(raw.neutralLocation.y == 20)
    raw.neutralTemperature = 5200
    precondition(raw.neutralTemperature == 5200)
    raw.neutralTint = 8
    precondition(raw.neutralTint == 8)
    raw.orientation = .right
    precondition(raw.orientation == .right)
    let matte = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    raw.portraitEffectsMatte = matte
    precondition(raw.portraitEffectsMatte?.extent.width == 1)
    raw.previewImage = matte
    precondition(raw.previewImage != nil)
    raw.properties = ["LensModel": "none"]
    precondition(raw.properties["LensModel"] as? String == "none")
    raw.scaleFactor = -2
    precondition(raw.scaleFactor == 0)
    raw.scaleFactor = 0.5
    precondition(raw.scaleFactor == 0.5)
    raw.semanticSegmentationGlassesMatte = matte
    raw.semanticSegmentationHairMatte = matte
    raw.semanticSegmentationSkinMatte = matte
    raw.semanticSegmentationSkyMatte = matte
    raw.semanticSegmentationTeethMatte = matte
    precondition(raw.semanticSegmentationGlassesMatte != nil)
    precondition(raw.semanticSegmentationHairMatte != nil)
    precondition(raw.semanticSegmentationSkinMatte != nil)
    precondition(raw.semanticSegmentationSkyMatte != nil)
    precondition(raw.semanticSegmentationTeethMatte != nil)
    raw.shadowBias = -1
    precondition(raw.shadowBias == -1)
    raw.sharpnessAmount = 0.15
    precondition(raw.sharpnessAmount == 0.15)

    precondition(CIRAWFilter(imageURL: URL(fileURLWithPath: "/tmp/none.dng")) == nil)
    precondition(CIRAWFilter(imageData: Data([0x00]), identifierHint: "cr2") == nil)
}
