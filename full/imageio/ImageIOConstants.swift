import Foundation

// CFString keys. Payloads that already shipped in ImageIO.swift, plus
// well-known dictionary wrappers and color-model strings, keep those
// identities. Remaining keys use the C identifier as a process-local
// value until an Apple oracle records the Darwin payload.

public let kCFErrorDomainCGImageMetadata: CFString = "kCFErrorDomainCGImageMetadata"

public let kCGComputeHDRStats: CFString = "kCGComputeHDRStats"

public let kCGImageAnimationDelayTime: CFString = "kCGImageAnimationDelayTime"

public let kCGImageAnimationLoopCount: CFString = "kCGImageAnimationLoopCount"

public let kCGImageAnimationStartIndex: CFString = "kCGImageAnimationStartIndex"

public let kCGImageAuxiliaryDataInfoColorSpace: CFString = "kCGImageAuxiliaryDataInfoColorSpace"

public let kCGImageAuxiliaryDataInfoData: CFString = "kCGImageAuxiliaryDataInfoData"

public let kCGImageAuxiliaryDataInfoDataDescription: CFString = "kCGImageAuxiliaryDataInfoDataDescription"

public let kCGImageAuxiliaryDataInfoMetadata: CFString = "kCGImageAuxiliaryDataInfoMetadata"

public let kCGImageAuxiliaryDataTypeDepth: CFString = "kCGImageAuxiliaryDataTypeDepth"

public let kCGImageAuxiliaryDataTypeDisparity: CFString = "kCGImageAuxiliaryDataTypeDisparity"

public let kCGImageAuxiliaryDataTypeHDRGainMap: CFString = "kCGImageAuxiliaryDataTypeHDRGainMap"

public let kCGImageAuxiliaryDataTypeISOGainMap: CFString = "kCGImageAuxiliaryDataTypeISOGainMap"

public let kCGImageAuxiliaryDataTypePortraitEffectsMatte: CFString = "kCGImageAuxiliaryDataTypePortraitEffectsMatte"

public let kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte: CFString = "kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte"

public let kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte: CFString = "kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte"

public let kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte: CFString = "kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte"

public let kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte: CFString = "kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte"

public let kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte: CFString = "kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte"

public let kCGImageDestinationBackgroundColor: CFString = "kCGImageDestinationBackgroundColor"

public let kCGImageDestinationDateTime: CFString = "kCGImageDestinationDateTime"

public let kCGImageDestinationEmbedThumbnail: CFString = "kCGImageDestinationEmbedThumbnail"

public let kCGImageDestinationEncodeAlternateColorSpace: CFString = "kCGImageDestinationEncodeAlternateColorSpace"

public let kCGImageDestinationEncodeBaseColorSpace: CFString = "kCGImageDestinationEncodeBaseColorSpace"

public let kCGImageDestinationEncodeBaseIsSDR: CFString = "kCGImageDestinationEncodeBaseIsSDR"

public let kCGImageDestinationEncodeBasePixelFormatRequest: CFString = "kCGImageDestinationEncodeBasePixelFormatRequest"

public let kCGImageDestinationEncodeGainMapPixelFormatRequest: CFString = "kCGImageDestinationEncodeGainMapPixelFormatRequest"

public let kCGImageDestinationEncodeGainMapSubsampleFactor: CFString = "kCGImageDestinationEncodeGainMapSubsampleFactor"

public let kCGImageDestinationEncodeGenerateGainMapWithBaseImage: CFString = "kCGImageDestinationEncodeGenerateGainMapWithBaseImage"

public let kCGImageDestinationEncodeIsBaseImage: CFString = "kCGImageDestinationEncodeIsBaseImage"

public let kCGImageDestinationEncodeRequest: CFString = "kCGImageDestinationEncodeRequest"

public let kCGImageDestinationEncodeRequestOptions: CFString = "kCGImageDestinationEncodeRequestOptions"

public let kCGImageDestinationEncodeToISOGainmap: CFString = "kCGImageDestinationEncodeToISOGainmap"

public let kCGImageDestinationEncodeToISOHDR: CFString = "kCGImageDestinationEncodeToISOHDR"

public let kCGImageDestinationEncodeToSDR: CFString = "kCGImageDestinationEncodeToSDR"

public let kCGImageDestinationEncodeTonemapMode: CFString = "kCGImageDestinationEncodeTonemapMode"

public let kCGImageDestinationImageMaxPixelSize: CFString = "kCGImageDestinationImageMaxPixelSize"

public let kCGImageDestinationLossyCompressionQuality: CFString = "kCGImageDestinationLossyCompressionQuality"

public let kCGImageDestinationMergeMetadata: CFString = "kCGImageDestinationMergeMetadata"

public let kCGImageDestinationMetadata: CFString = "kCGImageDestinationMetadata"

public let kCGImageDestinationOptimizeColorForSharing: CFString = "kCGImageDestinationOptimizeColorForSharing"

public let kCGImageDestinationOrientation: CFString = "kCGImageDestinationOrientation"

public let kCGImageDestinationPreserveGainMap: CFString = "kCGImageDestinationPreserveGainMap"

public let kCGImageMetadataEnumerateRecursively: CFString = "kCGImageMetadataEnumerateRecursively"

public let kCGImageMetadataNamespaceDublinCore: CFString = "http://purl.org/dc/elements/1.1/"

public let kCGImageMetadataNamespaceExif: CFString = "http://ns.adobe.com/exif/1.0/"

public let kCGImageMetadataNamespaceExifAux: CFString = "http://ns.adobe.com/exif/1.0/aux/"

public let kCGImageMetadataNamespaceExifEX: CFString = "http://cipa.jp/exif/1.0/"

public let kCGImageMetadataNamespaceIPTCCore: CFString = "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/"

public let kCGImageMetadataNamespaceIPTCExtension: CFString = "http://iptc.org/std/Iptc4xmpExt/2008-02-29/"

public let kCGImageMetadataNamespacePhotoshop: CFString = "http://ns.adobe.com/photoshop/1.0/"

public let kCGImageMetadataNamespaceTIFF: CFString = "http://ns.adobe.com/tiff/1.0/"

public let kCGImageMetadataNamespaceXMPBasic: CFString = "http://ns.adobe.com/xap/1.0/"

public let kCGImageMetadataNamespaceXMPRights: CFString = "http://ns.adobe.com/xap/1.0/rights/"

public let kCGImageMetadataPrefixDublinCore: CFString = "dc"

public let kCGImageMetadataPrefixExif: CFString = "exif"

public let kCGImageMetadataPrefixExifAux: CFString = "aux"

public let kCGImageMetadataPrefixExifEX: CFString = "exifEX"

public let kCGImageMetadataPrefixIPTCCore: CFString = "Iptc4xmpCore"

public let kCGImageMetadataPrefixIPTCExtension: CFString = "Iptc4xmpExt"

public let kCGImageMetadataPrefixPhotoshop: CFString = "photoshop"

public let kCGImageMetadataPrefixTIFF: CFString = "tiff"

public let kCGImageMetadataPrefixXMPBasic: CFString = "xmp"

public let kCGImageMetadataPrefixXMPRights: CFString = "xmpRights"

public let kCGImageMetadataShouldExcludeGPS: CFString = "kCGImageMetadataShouldExcludeGPS"

public let kCGImageMetadataShouldExcludeXMP: CFString = "kCGImageMetadataShouldExcludeXMP"

public let kCGImageProperty8BIMDictionary: CFString = "{8BIM}"

public let kCGImageProperty8BIMLayerNames: CFString = "kCGImageProperty8BIMLayerNames"

public let kCGImageProperty8BIMVersion: CFString = "kCGImageProperty8BIMVersion"

public let kCGImagePropertyAPNGCanvasPixelHeight: CFString = "kCGImagePropertyAPNGCanvasPixelHeight"

public let kCGImagePropertyAPNGCanvasPixelWidth: CFString = "kCGImagePropertyAPNGCanvasPixelWidth"

public let kCGImagePropertyAPNGDelayTime: CFString = "DelayTime"

public let kCGImagePropertyAPNGFrameInfoArray: CFString = "kCGImagePropertyAPNGFrameInfoArray"

public let kCGImagePropertyAPNGLoopCount: CFString = "LoopCount"

public let kCGImagePropertyAPNGUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyASTCBlockSize: CFString = "kCGImagePropertyASTCBlockSize"

public let kCGImagePropertyASTCBlockSize4x4: CFString = "kCGImagePropertyASTCBlockSize4x4"

public let kCGImagePropertyASTCBlockSize8x8: CFString = "kCGImagePropertyASTCBlockSize8x8"

public let kCGImagePropertyASTCEncoder: CFString = "kCGImagePropertyASTCEncoder"

public let kCGImagePropertyAVISDictionary: CFString = "{AVIS}"

public let kCGImagePropertyAuxiliaryData: CFString = "kCGImagePropertyAuxiliaryData"

public let kCGImagePropertyAuxiliaryDataType: CFString = "kCGImagePropertyAuxiliaryDataType"

public let kCGImagePropertyBCEncoder: CFString = "kCGImagePropertyBCEncoder"

public let kCGImagePropertyBCFormat: CFString = "kCGImagePropertyBCFormat"

public let kCGImagePropertyBytesPerRow: CFString = "kCGImagePropertyBytesPerRow"

public let kCGImagePropertyCIFFCameraSerialNumber: CFString = "kCGImagePropertyCIFFCameraSerialNumber"

public let kCGImagePropertyCIFFContinuousDrive: CFString = "kCGImagePropertyCIFFContinuousDrive"

public let kCGImagePropertyCIFFDescription: CFString = "kCGImagePropertyCIFFDescription"

public let kCGImagePropertyCIFFDictionary: CFString = "{CIFF}"

public let kCGImagePropertyCIFFFirmware: CFString = "kCGImagePropertyCIFFFirmware"

public let kCGImagePropertyCIFFFlashExposureComp: CFString = "kCGImagePropertyCIFFFlashExposureComp"

public let kCGImagePropertyCIFFFocusMode: CFString = "kCGImagePropertyCIFFFocusMode"

public let kCGImagePropertyCIFFImageFileName: CFString = "kCGImagePropertyCIFFImageFileName"

public let kCGImagePropertyCIFFImageName: CFString = "kCGImagePropertyCIFFImageName"

public let kCGImagePropertyCIFFImageSerialNumber: CFString = "kCGImagePropertyCIFFImageSerialNumber"

public let kCGImagePropertyCIFFLensMaxMM: CFString = "kCGImagePropertyCIFFLensMaxMM"

public let kCGImagePropertyCIFFLensMinMM: CFString = "kCGImagePropertyCIFFLensMinMM"

public let kCGImagePropertyCIFFLensModel: CFString = "kCGImagePropertyCIFFLensModel"

public let kCGImagePropertyCIFFMeasuredEV: CFString = "kCGImagePropertyCIFFMeasuredEV"

public let kCGImagePropertyCIFFMeteringMode: CFString = "kCGImagePropertyCIFFMeteringMode"

public let kCGImagePropertyCIFFOwnerName: CFString = "kCGImagePropertyCIFFOwnerName"

public let kCGImagePropertyCIFFRecordID: CFString = "kCGImagePropertyCIFFRecordID"

public let kCGImagePropertyCIFFReleaseMethod: CFString = "kCGImagePropertyCIFFReleaseMethod"

public let kCGImagePropertyCIFFReleaseTiming: CFString = "kCGImagePropertyCIFFReleaseTiming"

public let kCGImagePropertyCIFFSelfTimingTime: CFString = "kCGImagePropertyCIFFSelfTimingTime"

public let kCGImagePropertyCIFFShootingMode: CFString = "kCGImagePropertyCIFFShootingMode"

public let kCGImagePropertyCIFFWhiteBalanceIndex: CFString = "kCGImagePropertyCIFFWhiteBalanceIndex"

public let kCGImagePropertyColorModel: CFString = "ColorModel"

public let kCGImagePropertyColorModelCMYK: CFString = "CMYK"

public let kCGImagePropertyColorModelGray: CFString = "Gray"

public let kCGImagePropertyColorModelLab: CFString = "Lab"

public let kCGImagePropertyColorModelRGB: CFString = "RGB"

public let kCGImagePropertyDNGActiveArea: CFString = "kCGImagePropertyDNGActiveArea"

public let kCGImagePropertyDNGAnalogBalance: CFString = "kCGImagePropertyDNGAnalogBalance"

public let kCGImagePropertyDNGAntiAliasStrength: CFString = "kCGImagePropertyDNGAntiAliasStrength"

public let kCGImagePropertyDNGAsShotICCProfile: CFString = "kCGImagePropertyDNGAsShotICCProfile"

public let kCGImagePropertyDNGAsShotNeutral: CFString = "kCGImagePropertyDNGAsShotNeutral"

public let kCGImagePropertyDNGAsShotPreProfileMatrix: CFString = "kCGImagePropertyDNGAsShotPreProfileMatrix"

public let kCGImagePropertyDNGAsShotProfileName: CFString = "kCGImagePropertyDNGAsShotProfileName"

public let kCGImagePropertyDNGAsShotWhiteXY: CFString = "kCGImagePropertyDNGAsShotWhiteXY"

public let kCGImagePropertyDNGBackwardVersion: CFString = "kCGImagePropertyDNGBackwardVersion"

public let kCGImagePropertyDNGBaselineExposure: CFString = "kCGImagePropertyDNGBaselineExposure"

public let kCGImagePropertyDNGBaselineExposureOffset: CFString = "kCGImagePropertyDNGBaselineExposureOffset"

public let kCGImagePropertyDNGBaselineNoise: CFString = "kCGImagePropertyDNGBaselineNoise"

public let kCGImagePropertyDNGBaselineSharpness: CFString = "kCGImagePropertyDNGBaselineSharpness"

public let kCGImagePropertyDNGBayerGreenSplit: CFString = "kCGImagePropertyDNGBayerGreenSplit"

public let kCGImagePropertyDNGBestQualityScale: CFString = "kCGImagePropertyDNGBestQualityScale"

public let kCGImagePropertyDNGBlackLevel: CFString = "kCGImagePropertyDNGBlackLevel"

public let kCGImagePropertyDNGBlackLevelDeltaH: CFString = "kCGImagePropertyDNGBlackLevelDeltaH"

public let kCGImagePropertyDNGBlackLevelDeltaV: CFString = "kCGImagePropertyDNGBlackLevelDeltaV"

public let kCGImagePropertyDNGBlackLevelRepeatDim: CFString = "kCGImagePropertyDNGBlackLevelRepeatDim"

public let kCGImagePropertyDNGCFALayout: CFString = "kCGImagePropertyDNGCFALayout"

public let kCGImagePropertyDNGCFAPlaneColor: CFString = "kCGImagePropertyDNGCFAPlaneColor"

public let kCGImagePropertyDNGCalibrationIlluminant1: CFString = "kCGImagePropertyDNGCalibrationIlluminant1"

public let kCGImagePropertyDNGCalibrationIlluminant2: CFString = "kCGImagePropertyDNGCalibrationIlluminant2"

public let kCGImagePropertyDNGCameraCalibration1: CFString = "kCGImagePropertyDNGCameraCalibration1"

public let kCGImagePropertyDNGCameraCalibration2: CFString = "kCGImagePropertyDNGCameraCalibration2"

public let kCGImagePropertyDNGCameraCalibrationSignature: CFString = "kCGImagePropertyDNGCameraCalibrationSignature"

public let kCGImagePropertyDNGCameraSerialNumber: CFString = "kCGImagePropertyDNGCameraSerialNumber"

public let kCGImagePropertyDNGChromaBlurRadius: CFString = "kCGImagePropertyDNGChromaBlurRadius"

public let kCGImagePropertyDNGColorMatrix1: CFString = "kCGImagePropertyDNGColorMatrix1"

public let kCGImagePropertyDNGColorMatrix2: CFString = "kCGImagePropertyDNGColorMatrix2"

public let kCGImagePropertyDNGColorimetricReference: CFString = "kCGImagePropertyDNGColorimetricReference"

public let kCGImagePropertyDNGCurrentICCProfile: CFString = "kCGImagePropertyDNGCurrentICCProfile"

public let kCGImagePropertyDNGCurrentPreProfileMatrix: CFString = "kCGImagePropertyDNGCurrentPreProfileMatrix"

public let kCGImagePropertyDNGDefaultBlackRender: CFString = "kCGImagePropertyDNGDefaultBlackRender"

public let kCGImagePropertyDNGDefaultCropOrigin: CFString = "kCGImagePropertyDNGDefaultCropOrigin"

public let kCGImagePropertyDNGDefaultCropSize: CFString = "kCGImagePropertyDNGDefaultCropSize"

public let kCGImagePropertyDNGDefaultScale: CFString = "kCGImagePropertyDNGDefaultScale"

public let kCGImagePropertyDNGDefaultUserCrop: CFString = "kCGImagePropertyDNGDefaultUserCrop"

public let kCGImagePropertyDNGDictionary: CFString = "{DNG}"

public let kCGImagePropertyDNGExtraCameraProfiles: CFString = "kCGImagePropertyDNGExtraCameraProfiles"

public let kCGImagePropertyDNGFixVignetteRadial: CFString = "kCGImagePropertyDNGFixVignetteRadial"

public let kCGImagePropertyDNGForwardMatrix1: CFString = "kCGImagePropertyDNGForwardMatrix1"

public let kCGImagePropertyDNGForwardMatrix2: CFString = "kCGImagePropertyDNGForwardMatrix2"

public let kCGImagePropertyDNGLensInfo: CFString = "kCGImagePropertyDNGLensInfo"

public let kCGImagePropertyDNGLinearResponseLimit: CFString = "kCGImagePropertyDNGLinearResponseLimit"

public let kCGImagePropertyDNGLinearizationTable: CFString = "kCGImagePropertyDNGLinearizationTable"

public let kCGImagePropertyDNGLocalizedCameraModel: CFString = "kCGImagePropertyDNGLocalizedCameraModel"

public let kCGImagePropertyDNGMakerNoteSafety: CFString = "kCGImagePropertyDNGMakerNoteSafety"

public let kCGImagePropertyDNGMaskedAreas: CFString = "kCGImagePropertyDNGMaskedAreas"

public let kCGImagePropertyDNGNewRawImageDigest: CFString = "kCGImagePropertyDNGNewRawImageDigest"

public let kCGImagePropertyDNGNoiseProfile: CFString = "kCGImagePropertyDNGNoiseProfile"

public let kCGImagePropertyDNGNoiseReductionApplied: CFString = "kCGImagePropertyDNGNoiseReductionApplied"

public let kCGImagePropertyDNGOpcodeList1: CFString = "kCGImagePropertyDNGOpcodeList1"

public let kCGImagePropertyDNGOpcodeList2: CFString = "kCGImagePropertyDNGOpcodeList2"

public let kCGImagePropertyDNGOpcodeList3: CFString = "kCGImagePropertyDNGOpcodeList3"

public let kCGImagePropertyDNGOriginalBestQualityFinalSize: CFString = "kCGImagePropertyDNGOriginalBestQualityFinalSize"

public let kCGImagePropertyDNGOriginalDefaultCropSize: CFString = "kCGImagePropertyDNGOriginalDefaultCropSize"

public let kCGImagePropertyDNGOriginalDefaultFinalSize: CFString = "kCGImagePropertyDNGOriginalDefaultFinalSize"

public let kCGImagePropertyDNGOriginalRawFileData: CFString = "kCGImagePropertyDNGOriginalRawFileData"

public let kCGImagePropertyDNGOriginalRawFileDigest: CFString = "kCGImagePropertyDNGOriginalRawFileDigest"

public let kCGImagePropertyDNGOriginalRawFileName: CFString = "kCGImagePropertyDNGOriginalRawFileName"

public let kCGImagePropertyDNGPreviewApplicationName: CFString = "kCGImagePropertyDNGPreviewApplicationName"

public let kCGImagePropertyDNGPreviewApplicationVersion: CFString = "kCGImagePropertyDNGPreviewApplicationVersion"

public let kCGImagePropertyDNGPreviewColorSpace: CFString = "kCGImagePropertyDNGPreviewColorSpace"

public let kCGImagePropertyDNGPreviewDateTime: CFString = "kCGImagePropertyDNGPreviewDateTime"

public let kCGImagePropertyDNGPreviewSettingsDigest: CFString = "kCGImagePropertyDNGPreviewSettingsDigest"

public let kCGImagePropertyDNGPreviewSettingsName: CFString = "kCGImagePropertyDNGPreviewSettingsName"

public let kCGImagePropertyDNGPrivateData: CFString = "kCGImagePropertyDNGPrivateData"

public let kCGImagePropertyDNGProfileCalibrationSignature: CFString = "kCGImagePropertyDNGProfileCalibrationSignature"

public let kCGImagePropertyDNGProfileCopyright: CFString = "kCGImagePropertyDNGProfileCopyright"

public let kCGImagePropertyDNGProfileEmbedPolicy: CFString = "kCGImagePropertyDNGProfileEmbedPolicy"

public let kCGImagePropertyDNGProfileHueSatMapData1: CFString = "kCGImagePropertyDNGProfileHueSatMapData1"

public let kCGImagePropertyDNGProfileHueSatMapData2: CFString = "kCGImagePropertyDNGProfileHueSatMapData2"

public let kCGImagePropertyDNGProfileHueSatMapDims: CFString = "kCGImagePropertyDNGProfileHueSatMapDims"

public let kCGImagePropertyDNGProfileHueSatMapEncoding: CFString = "kCGImagePropertyDNGProfileHueSatMapEncoding"

public let kCGImagePropertyDNGProfileLookTableData: CFString = "kCGImagePropertyDNGProfileLookTableData"

public let kCGImagePropertyDNGProfileLookTableDims: CFString = "kCGImagePropertyDNGProfileLookTableDims"

public let kCGImagePropertyDNGProfileLookTableEncoding: CFString = "kCGImagePropertyDNGProfileLookTableEncoding"

public let kCGImagePropertyDNGProfileName: CFString = "kCGImagePropertyDNGProfileName"

public let kCGImagePropertyDNGProfileToneCurve: CFString = "kCGImagePropertyDNGProfileToneCurve"

public let kCGImagePropertyDNGRawDataUniqueID: CFString = "kCGImagePropertyDNGRawDataUniqueID"

public let kCGImagePropertyDNGRawImageDigest: CFString = "kCGImagePropertyDNGRawImageDigest"

public let kCGImagePropertyDNGRawToPreviewGain: CFString = "kCGImagePropertyDNGRawToPreviewGain"

public let kCGImagePropertyDNGReductionMatrix1: CFString = "kCGImagePropertyDNGReductionMatrix1"

public let kCGImagePropertyDNGReductionMatrix2: CFString = "kCGImagePropertyDNGReductionMatrix2"

public let kCGImagePropertyDNGRowInterleaveFactor: CFString = "kCGImagePropertyDNGRowInterleaveFactor"

public let kCGImagePropertyDNGShadowScale: CFString = "kCGImagePropertyDNGShadowScale"

public let kCGImagePropertyDNGSubTileBlockSize: CFString = "kCGImagePropertyDNGSubTileBlockSize"

public let kCGImagePropertyDNGUniqueCameraModel: CFString = "kCGImagePropertyDNGUniqueCameraModel"

public let kCGImagePropertyDNGVersion: CFString = "kCGImagePropertyDNGVersion"

public let kCGImagePropertyDNGWarpFisheye: CFString = "kCGImagePropertyDNGWarpFisheye"

public let kCGImagePropertyDNGWarpRectilinear: CFString = "kCGImagePropertyDNGWarpRectilinear"

public let kCGImagePropertyDNGWhiteLevel: CFString = "kCGImagePropertyDNGWhiteLevel"

public let kCGImagePropertyDPIHeight: CFString = "DPIHeight"

public let kCGImagePropertyDPIWidth: CFString = "DPIWidth"

public let kCGImagePropertyDepth: CFString = "Depth"

public let kCGImagePropertyEncoder: CFString = "kCGImagePropertyEncoder"

public let kCGImagePropertyExifApertureValue: CFString = "kCGImagePropertyExifApertureValue"

public let kCGImagePropertyExifAuxDictionary: CFString = "{ExifAux}"

public let kCGImagePropertyExifAuxFirmware: CFString = "kCGImagePropertyExifAuxFirmware"

public let kCGImagePropertyExifAuxFlashCompensation: CFString = "kCGImagePropertyExifAuxFlashCompensation"

public let kCGImagePropertyExifAuxImageNumber: CFString = "kCGImagePropertyExifAuxImageNumber"

public let kCGImagePropertyExifAuxLensID: CFString = "kCGImagePropertyExifAuxLensID"

public let kCGImagePropertyExifAuxLensInfo: CFString = "kCGImagePropertyExifAuxLensInfo"

public let kCGImagePropertyExifAuxLensModel: CFString = "kCGImagePropertyExifAuxLensModel"

public let kCGImagePropertyExifAuxLensSerialNumber: CFString = "kCGImagePropertyExifAuxLensSerialNumber"

public let kCGImagePropertyExifAuxOwnerName: CFString = "kCGImagePropertyExifAuxOwnerName"

public let kCGImagePropertyExifAuxSerialNumber: CFString = "kCGImagePropertyExifAuxSerialNumber"

public let kCGImagePropertyExifBodySerialNumber: CFString = "kCGImagePropertyExifBodySerialNumber"

public let kCGImagePropertyExifBrightnessValue: CFString = "kCGImagePropertyExifBrightnessValue"

public let kCGImagePropertyExifCFAPattern: CFString = "kCGImagePropertyExifCFAPattern"

public let kCGImagePropertyExifCameraOwnerName: CFString = "kCGImagePropertyExifCameraOwnerName"

public let kCGImagePropertyExifColorSpace: CFString = "kCGImagePropertyExifColorSpace"

public let kCGImagePropertyExifComponentsConfiguration: CFString = "kCGImagePropertyExifComponentsConfiguration"

public let kCGImagePropertyExifCompositeImage: CFString = "kCGImagePropertyExifCompositeImage"

public let kCGImagePropertyExifCompressedBitsPerPixel: CFString = "kCGImagePropertyExifCompressedBitsPerPixel"

public let kCGImagePropertyExifContrast: CFString = "kCGImagePropertyExifContrast"

public let kCGImagePropertyExifCustomRendered: CFString = "kCGImagePropertyExifCustomRendered"

public let kCGImagePropertyExifDateTimeDigitized: CFString = "kCGImagePropertyExifDateTimeDigitized"

public let kCGImagePropertyExifDateTimeOriginal: CFString = "kCGImagePropertyExifDateTimeOriginal"

public let kCGImagePropertyExifDeviceSettingDescription: CFString = "kCGImagePropertyExifDeviceSettingDescription"

public let kCGImagePropertyExifDictionary: CFString = "{Exif}"

public let kCGImagePropertyExifDigitalZoomRatio: CFString = "kCGImagePropertyExifDigitalZoomRatio"

public let kCGImagePropertyExifExposureBiasValue: CFString = "kCGImagePropertyExifExposureBiasValue"

public let kCGImagePropertyExifExposureIndex: CFString = "kCGImagePropertyExifExposureIndex"

public let kCGImagePropertyExifExposureMode: CFString = "kCGImagePropertyExifExposureMode"

public let kCGImagePropertyExifExposureProgram: CFString = "kCGImagePropertyExifExposureProgram"

public let kCGImagePropertyExifExposureTime: CFString = "kCGImagePropertyExifExposureTime"

public let kCGImagePropertyExifFNumber: CFString = "kCGImagePropertyExifFNumber"

public let kCGImagePropertyExifFileSource: CFString = "kCGImagePropertyExifFileSource"

public let kCGImagePropertyExifFlash: CFString = "kCGImagePropertyExifFlash"

public let kCGImagePropertyExifFlashEnergy: CFString = "kCGImagePropertyExifFlashEnergy"

public let kCGImagePropertyExifFlashPixVersion: CFString = "kCGImagePropertyExifFlashPixVersion"

public let kCGImagePropertyExifFocalLenIn35mmFilm: CFString = "kCGImagePropertyExifFocalLenIn35mmFilm"

public let kCGImagePropertyExifFocalLength: CFString = "kCGImagePropertyExifFocalLength"

public let kCGImagePropertyExifFocalPlaneResolutionUnit: CFString = "kCGImagePropertyExifFocalPlaneResolutionUnit"

public let kCGImagePropertyExifFocalPlaneXResolution: CFString = "kCGImagePropertyExifFocalPlaneXResolution"

public let kCGImagePropertyExifFocalPlaneYResolution: CFString = "kCGImagePropertyExifFocalPlaneYResolution"

public let kCGImagePropertyExifGainControl: CFString = "kCGImagePropertyExifGainControl"

public let kCGImagePropertyExifGamma: CFString = "kCGImagePropertyExifGamma"

public let kCGImagePropertyExifISOSpeed: CFString = "kCGImagePropertyExifISOSpeed"

public let kCGImagePropertyExifISOSpeedLatitudeyyy: CFString = "kCGImagePropertyExifISOSpeedLatitudeyyy"

public let kCGImagePropertyExifISOSpeedLatitudezzz: CFString = "kCGImagePropertyExifISOSpeedLatitudezzz"

public let kCGImagePropertyExifISOSpeedRatings: CFString = "kCGImagePropertyExifISOSpeedRatings"

public let kCGImagePropertyExifImageUniqueID: CFString = "kCGImagePropertyExifImageUniqueID"

public let kCGImagePropertyExifLensMake: CFString = "kCGImagePropertyExifLensMake"

public let kCGImagePropertyExifLensModel: CFString = "kCGImagePropertyExifLensModel"

public let kCGImagePropertyExifLensSerialNumber: CFString = "kCGImagePropertyExifLensSerialNumber"

public let kCGImagePropertyExifLensSpecification: CFString = "kCGImagePropertyExifLensSpecification"

public let kCGImagePropertyExifLightSource: CFString = "kCGImagePropertyExifLightSource"

public let kCGImagePropertyExifMakerNote: CFString = "kCGImagePropertyExifMakerNote"

public let kCGImagePropertyExifMaxApertureValue: CFString = "kCGImagePropertyExifMaxApertureValue"

public let kCGImagePropertyExifMeteringMode: CFString = "kCGImagePropertyExifMeteringMode"

public let kCGImagePropertyExifOECF: CFString = "kCGImagePropertyExifOECF"

public let kCGImagePropertyExifOffsetTime: CFString = "kCGImagePropertyExifOffsetTime"

public let kCGImagePropertyExifOffsetTimeDigitized: CFString = "kCGImagePropertyExifOffsetTimeDigitized"

public let kCGImagePropertyExifOffsetTimeOriginal: CFString = "kCGImagePropertyExifOffsetTimeOriginal"

public let kCGImagePropertyExifPixelXDimension: CFString = "kCGImagePropertyExifPixelXDimension"

public let kCGImagePropertyExifPixelYDimension: CFString = "kCGImagePropertyExifPixelYDimension"

public let kCGImagePropertyExifRecommendedExposureIndex: CFString = "kCGImagePropertyExifRecommendedExposureIndex"

public let kCGImagePropertyExifRelatedSoundFile: CFString = "kCGImagePropertyExifRelatedSoundFile"

public let kCGImagePropertyExifSaturation: CFString = "kCGImagePropertyExifSaturation"

public let kCGImagePropertyExifSceneCaptureType: CFString = "kCGImagePropertyExifSceneCaptureType"

public let kCGImagePropertyExifSceneType: CFString = "kCGImagePropertyExifSceneType"

public let kCGImagePropertyExifSensingMethod: CFString = "kCGImagePropertyExifSensingMethod"

public let kCGImagePropertyExifSensitivityType: CFString = "kCGImagePropertyExifSensitivityType"

public let kCGImagePropertyExifSharpness: CFString = "kCGImagePropertyExifSharpness"

public let kCGImagePropertyExifShutterSpeedValue: CFString = "kCGImagePropertyExifShutterSpeedValue"

public let kCGImagePropertyExifSourceExposureTimesOfCompositeImage: CFString = "kCGImagePropertyExifSourceExposureTimesOfCompositeImage"

public let kCGImagePropertyExifSourceImageNumberOfCompositeImage: CFString = "kCGImagePropertyExifSourceImageNumberOfCompositeImage"

public let kCGImagePropertyExifSpatialFrequencyResponse: CFString = "kCGImagePropertyExifSpatialFrequencyResponse"

public let kCGImagePropertyExifSpectralSensitivity: CFString = "kCGImagePropertyExifSpectralSensitivity"

public let kCGImagePropertyExifStandardOutputSensitivity: CFString = "kCGImagePropertyExifStandardOutputSensitivity"

public let kCGImagePropertyExifSubjectArea: CFString = "kCGImagePropertyExifSubjectArea"

public let kCGImagePropertyExifSubjectDistRange: CFString = "kCGImagePropertyExifSubjectDistRange"

public let kCGImagePropertyExifSubjectDistance: CFString = "kCGImagePropertyExifSubjectDistance"

public let kCGImagePropertyExifSubjectLocation: CFString = "kCGImagePropertyExifSubjectLocation"

public let kCGImagePropertyExifSubsecTime: CFString = "kCGImagePropertyExifSubsecTime"

public let kCGImagePropertyExifSubsecTimeDigitized: CFString = "kCGImagePropertyExifSubsecTimeDigitized"

public let kCGImagePropertyExifSubsecTimeOrginal: CFString = "kCGImagePropertyExifSubsecTimeOrginal"

public let kCGImagePropertyExifSubsecTimeOriginal: CFString = "kCGImagePropertyExifSubsecTimeOriginal"

public let kCGImagePropertyExifUserComment: CFString = "kCGImagePropertyExifUserComment"

public let kCGImagePropertyExifVersion: CFString = "kCGImagePropertyExifVersion"

public let kCGImagePropertyExifWhiteBalance: CFString = "kCGImagePropertyExifWhiteBalance"

public let kCGImagePropertyFileContentsDictionary: CFString = "{FileContents}"

public let kCGImagePropertyFileSize: CFString = "kCGImagePropertyFileSize"

public let kCGImagePropertyGIFCanvasPixelHeight: CFString = "kCGImagePropertyGIFCanvasPixelHeight"

public let kCGImagePropertyGIFCanvasPixelWidth: CFString = "kCGImagePropertyGIFCanvasPixelWidth"

public let kCGImagePropertyGIFDelayTime: CFString = "DelayTime"

public let kCGImagePropertyGIFDictionary: CFString = "{GIF}"

public let kCGImagePropertyGIFFrameInfoArray: CFString = "kCGImagePropertyGIFFrameInfoArray"

public let kCGImagePropertyGIFHasGlobalColorMap: CFString = "kCGImagePropertyGIFHasGlobalColorMap"

public let kCGImagePropertyGIFImageColorMap: CFString = "kCGImagePropertyGIFImageColorMap"

public let kCGImagePropertyGIFLoopCount: CFString = "LoopCount"

public let kCGImagePropertyGIFUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyGPSAltitude: CFString = "kCGImagePropertyGPSAltitude"

public let kCGImagePropertyGPSAltitudeRef: CFString = "kCGImagePropertyGPSAltitudeRef"

public let kCGImagePropertyGPSAreaInformation: CFString = "kCGImagePropertyGPSAreaInformation"

public let kCGImagePropertyGPSDOP: CFString = "kCGImagePropertyGPSDOP"

public let kCGImagePropertyGPSDateStamp: CFString = "kCGImagePropertyGPSDateStamp"

public let kCGImagePropertyGPSDestBearing: CFString = "kCGImagePropertyGPSDestBearing"

public let kCGImagePropertyGPSDestBearingRef: CFString = "kCGImagePropertyGPSDestBearingRef"

public let kCGImagePropertyGPSDestDistance: CFString = "kCGImagePropertyGPSDestDistance"

public let kCGImagePropertyGPSDestDistanceRef: CFString = "kCGImagePropertyGPSDestDistanceRef"

public let kCGImagePropertyGPSDestLatitude: CFString = "kCGImagePropertyGPSDestLatitude"

public let kCGImagePropertyGPSDestLatitudeRef: CFString = "kCGImagePropertyGPSDestLatitudeRef"

public let kCGImagePropertyGPSDestLongitude: CFString = "kCGImagePropertyGPSDestLongitude"

public let kCGImagePropertyGPSDestLongitudeRef: CFString = "kCGImagePropertyGPSDestLongitudeRef"

public let kCGImagePropertyGPSDictionary: CFString = "{GPS}"

public let kCGImagePropertyGPSDifferental: CFString = "kCGImagePropertyGPSDifferental"

public let kCGImagePropertyGPSHPositioningError: CFString = "kCGImagePropertyGPSHPositioningError"

public let kCGImagePropertyGPSImgDirection: CFString = "kCGImagePropertyGPSImgDirection"

public let kCGImagePropertyGPSImgDirectionRef: CFString = "kCGImagePropertyGPSImgDirectionRef"

public let kCGImagePropertyGPSLatitude: CFString = "kCGImagePropertyGPSLatitude"

public let kCGImagePropertyGPSLatitudeRef: CFString = "kCGImagePropertyGPSLatitudeRef"

public let kCGImagePropertyGPSLongitude: CFString = "kCGImagePropertyGPSLongitude"

public let kCGImagePropertyGPSLongitudeRef: CFString = "kCGImagePropertyGPSLongitudeRef"

public let kCGImagePropertyGPSMapDatum: CFString = "kCGImagePropertyGPSMapDatum"

public let kCGImagePropertyGPSMeasureMode: CFString = "kCGImagePropertyGPSMeasureMode"

public let kCGImagePropertyGPSProcessingMethod: CFString = "kCGImagePropertyGPSProcessingMethod"

public let kCGImagePropertyGPSSatellites: CFString = "kCGImagePropertyGPSSatellites"

public let kCGImagePropertyGPSSpeed: CFString = "kCGImagePropertyGPSSpeed"

public let kCGImagePropertyGPSSpeedRef: CFString = "kCGImagePropertyGPSSpeedRef"

public let kCGImagePropertyGPSStatus: CFString = "kCGImagePropertyGPSStatus"

public let kCGImagePropertyGPSTimeStamp: CFString = "kCGImagePropertyGPSTimeStamp"

public let kCGImagePropertyGPSTrack: CFString = "kCGImagePropertyGPSTrack"

public let kCGImagePropertyGPSTrackRef: CFString = "kCGImagePropertyGPSTrackRef"

public let kCGImagePropertyGPSVersion: CFString = "kCGImagePropertyGPSVersion"

public let kCGImagePropertyGroupImageBaseline: CFString = "kCGImagePropertyGroupImageBaseline"

public let kCGImagePropertyGroupImageDisparityAdjustment: CFString = "kCGImagePropertyGroupImageDisparityAdjustment"

public let kCGImagePropertyGroupImageIndexLeft: CFString = "kCGImagePropertyGroupImageIndexLeft"

public let kCGImagePropertyGroupImageIndexMonoscopic: CFString = "kCGImagePropertyGroupImageIndexMonoscopic"

public let kCGImagePropertyGroupImageIndexRight: CFString = "kCGImagePropertyGroupImageIndexRight"

public let kCGImagePropertyGroupImageIsAlternateImage: CFString = "kCGImagePropertyGroupImageIsAlternateImage"

public let kCGImagePropertyGroupImageIsLeftImage: CFString = "kCGImagePropertyGroupImageIsLeftImage"

public let kCGImagePropertyGroupImageIsMonoscopicImage: CFString = "kCGImagePropertyGroupImageIsMonoscopicImage"

public let kCGImagePropertyGroupImageIsRightImage: CFString = "kCGImagePropertyGroupImageIsRightImage"

public let kCGImagePropertyGroupImageStereoAggressors: CFString = "kCGImagePropertyGroupImageStereoAggressors"

public let kCGImagePropertyGroupImagesAlternate: CFString = "kCGImagePropertyGroupImagesAlternate"

public let kCGImagePropertyGroupIndex: CFString = "kCGImagePropertyGroupIndex"

public let kCGImagePropertyGroupMonoscopicImageLocation: CFString = "kCGImagePropertyGroupMonoscopicImageLocation"

public let kCGImagePropertyGroupType: CFString = "kCGImagePropertyGroupType"

public let kCGImagePropertyGroupTypeAlternate: CFString = "kCGImagePropertyGroupTypeAlternate"

public let kCGImagePropertyGroupTypeStereoPair: CFString = "kCGImagePropertyGroupTypeStereoPair"

public let kCGImagePropertyGroups: CFString = "kCGImagePropertyGroups"

public let kCGImagePropertyHEICSCanvasPixelHeight: CFString = "kCGImagePropertyHEICSCanvasPixelHeight"

public let kCGImagePropertyHEICSCanvasPixelWidth: CFString = "kCGImagePropertyHEICSCanvasPixelWidth"

public let kCGImagePropertyHEICSDelayTime: CFString = "kCGImagePropertyHEICSDelayTime"

public let kCGImagePropertyHEICSDictionary: CFString = "{HEICS}"

public let kCGImagePropertyHEICSFrameInfoArray: CFString = "kCGImagePropertyHEICSFrameInfoArray"

public let kCGImagePropertyHEICSLoopCount: CFString = "kCGImagePropertyHEICSLoopCount"

public let kCGImagePropertyHEICSUnclampedDelayTime: CFString = "kCGImagePropertyHEICSUnclampedDelayTime"

public let kCGImagePropertyHEIFDictionary: CFString = "{HEIF}"

public let kCGImagePropertyHasAlpha: CFString = "HasAlpha"

public let kCGImagePropertyHeight: CFString = "kCGImagePropertyHeight"

public let kCGImagePropertyIPTCActionAdvised: CFString = "kCGImagePropertyIPTCActionAdvised"

public let kCGImagePropertyIPTCByline: CFString = "kCGImagePropertyIPTCByline"

public let kCGImagePropertyIPTCBylineTitle: CFString = "kCGImagePropertyIPTCBylineTitle"

public let kCGImagePropertyIPTCCaptionAbstract: CFString = "kCGImagePropertyIPTCCaptionAbstract"

public let kCGImagePropertyIPTCCategory: CFString = "kCGImagePropertyIPTCCategory"

public let kCGImagePropertyIPTCCity: CFString = "kCGImagePropertyIPTCCity"

public let kCGImagePropertyIPTCContact: CFString = "kCGImagePropertyIPTCContact"

public let kCGImagePropertyIPTCContactInfoAddress: CFString = "kCGImagePropertyIPTCContactInfoAddress"

public let kCGImagePropertyIPTCContactInfoCity: CFString = "kCGImagePropertyIPTCContactInfoCity"

public let kCGImagePropertyIPTCContactInfoCountry: CFString = "kCGImagePropertyIPTCContactInfoCountry"

public let kCGImagePropertyIPTCContactInfoEmails: CFString = "kCGImagePropertyIPTCContactInfoEmails"

public let kCGImagePropertyIPTCContactInfoPhones: CFString = "kCGImagePropertyIPTCContactInfoPhones"

public let kCGImagePropertyIPTCContactInfoPostalCode: CFString = "kCGImagePropertyIPTCContactInfoPostalCode"

public let kCGImagePropertyIPTCContactInfoStateProvince: CFString = "kCGImagePropertyIPTCContactInfoStateProvince"

public let kCGImagePropertyIPTCContactInfoWebURLs: CFString = "kCGImagePropertyIPTCContactInfoWebURLs"

public let kCGImagePropertyIPTCContentLocationCode: CFString = "kCGImagePropertyIPTCContentLocationCode"

public let kCGImagePropertyIPTCContentLocationName: CFString = "kCGImagePropertyIPTCContentLocationName"

public let kCGImagePropertyIPTCCopyrightNotice: CFString = "kCGImagePropertyIPTCCopyrightNotice"

public let kCGImagePropertyIPTCCountryPrimaryLocationCode: CFString = "kCGImagePropertyIPTCCountryPrimaryLocationCode"

public let kCGImagePropertyIPTCCountryPrimaryLocationName: CFString = "kCGImagePropertyIPTCCountryPrimaryLocationName"

public let kCGImagePropertyIPTCCreatorContactInfo: CFString = "kCGImagePropertyIPTCCreatorContactInfo"

public let kCGImagePropertyIPTCCredit: CFString = "kCGImagePropertyIPTCCredit"

public let kCGImagePropertyIPTCDateCreated: CFString = "kCGImagePropertyIPTCDateCreated"

public let kCGImagePropertyIPTCDictionary: CFString = "{IPTC}"

public let kCGImagePropertyIPTCDigitalCreationDate: CFString = "kCGImagePropertyIPTCDigitalCreationDate"

public let kCGImagePropertyIPTCDigitalCreationTime: CFString = "kCGImagePropertyIPTCDigitalCreationTime"

public let kCGImagePropertyIPTCEditStatus: CFString = "kCGImagePropertyIPTCEditStatus"

public let kCGImagePropertyIPTCEditorialUpdate: CFString = "kCGImagePropertyIPTCEditorialUpdate"

public let kCGImagePropertyIPTCExpirationDate: CFString = "kCGImagePropertyIPTCExpirationDate"

public let kCGImagePropertyIPTCExpirationTime: CFString = "kCGImagePropertyIPTCExpirationTime"

public let kCGImagePropertyIPTCExtAboutCvTerm: CFString = "kCGImagePropertyIPTCExtAboutCvTerm"

public let kCGImagePropertyIPTCExtAboutCvTermCvId: CFString = "kCGImagePropertyIPTCExtAboutCvTermCvId"

public let kCGImagePropertyIPTCExtAboutCvTermId: CFString = "kCGImagePropertyIPTCExtAboutCvTermId"

public let kCGImagePropertyIPTCExtAboutCvTermName: CFString = "kCGImagePropertyIPTCExtAboutCvTermName"

public let kCGImagePropertyIPTCExtAboutCvTermRefinedAbout: CFString = "kCGImagePropertyIPTCExtAboutCvTermRefinedAbout"

public let kCGImagePropertyIPTCExtAddlModelInfo: CFString = "kCGImagePropertyIPTCExtAddlModelInfo"

public let kCGImagePropertyIPTCExtArtworkCircaDateCreated: CFString = "kCGImagePropertyIPTCExtArtworkCircaDateCreated"

public let kCGImagePropertyIPTCExtArtworkContentDescription: CFString = "kCGImagePropertyIPTCExtArtworkContentDescription"

public let kCGImagePropertyIPTCExtArtworkContributionDescription: CFString = "kCGImagePropertyIPTCExtArtworkContributionDescription"

public let kCGImagePropertyIPTCExtArtworkCopyrightNotice: CFString = "kCGImagePropertyIPTCExtArtworkCopyrightNotice"

public let kCGImagePropertyIPTCExtArtworkCopyrightOwnerID: CFString = "kCGImagePropertyIPTCExtArtworkCopyrightOwnerID"

public let kCGImagePropertyIPTCExtArtworkCopyrightOwnerName: CFString = "kCGImagePropertyIPTCExtArtworkCopyrightOwnerName"

public let kCGImagePropertyIPTCExtArtworkCreator: CFString = "kCGImagePropertyIPTCExtArtworkCreator"

public let kCGImagePropertyIPTCExtArtworkCreatorID: CFString = "kCGImagePropertyIPTCExtArtworkCreatorID"

public let kCGImagePropertyIPTCExtArtworkDateCreated: CFString = "kCGImagePropertyIPTCExtArtworkDateCreated"

public let kCGImagePropertyIPTCExtArtworkLicensorID: CFString = "kCGImagePropertyIPTCExtArtworkLicensorID"

public let kCGImagePropertyIPTCExtArtworkLicensorName: CFString = "kCGImagePropertyIPTCExtArtworkLicensorName"

public let kCGImagePropertyIPTCExtArtworkOrObject: CFString = "kCGImagePropertyIPTCExtArtworkOrObject"

public let kCGImagePropertyIPTCExtArtworkPhysicalDescription: CFString = "kCGImagePropertyIPTCExtArtworkPhysicalDescription"

public let kCGImagePropertyIPTCExtArtworkSource: CFString = "kCGImagePropertyIPTCExtArtworkSource"

public let kCGImagePropertyIPTCExtArtworkSourceInvURL: CFString = "kCGImagePropertyIPTCExtArtworkSourceInvURL"

public let kCGImagePropertyIPTCExtArtworkSourceInventoryNo: CFString = "kCGImagePropertyIPTCExtArtworkSourceInventoryNo"

public let kCGImagePropertyIPTCExtArtworkStylePeriod: CFString = "kCGImagePropertyIPTCExtArtworkStylePeriod"

public let kCGImagePropertyIPTCExtArtworkTitle: CFString = "kCGImagePropertyIPTCExtArtworkTitle"

public let kCGImagePropertyIPTCExtAudioBitrate: CFString = "kCGImagePropertyIPTCExtAudioBitrate"

public let kCGImagePropertyIPTCExtAudioBitrateMode: CFString = "kCGImagePropertyIPTCExtAudioBitrateMode"

public let kCGImagePropertyIPTCExtAudioChannelCount: CFString = "kCGImagePropertyIPTCExtAudioChannelCount"

public let kCGImagePropertyIPTCExtCircaDateCreated: CFString = "kCGImagePropertyIPTCExtCircaDateCreated"

public let kCGImagePropertyIPTCExtContainerFormat: CFString = "kCGImagePropertyIPTCExtContainerFormat"

public let kCGImagePropertyIPTCExtContainerFormatIdentifier: CFString = "kCGImagePropertyIPTCExtContainerFormatIdentifier"

public let kCGImagePropertyIPTCExtContainerFormatName: CFString = "kCGImagePropertyIPTCExtContainerFormatName"

public let kCGImagePropertyIPTCExtContributor: CFString = "kCGImagePropertyIPTCExtContributor"

public let kCGImagePropertyIPTCExtContributorIdentifier: CFString = "kCGImagePropertyIPTCExtContributorIdentifier"

public let kCGImagePropertyIPTCExtContributorName: CFString = "kCGImagePropertyIPTCExtContributorName"

public let kCGImagePropertyIPTCExtContributorRole: CFString = "kCGImagePropertyIPTCExtContributorRole"

public let kCGImagePropertyIPTCExtControlledVocabularyTerm: CFString = "kCGImagePropertyIPTCExtControlledVocabularyTerm"

public let kCGImagePropertyIPTCExtCopyrightYear: CFString = "kCGImagePropertyIPTCExtCopyrightYear"

public let kCGImagePropertyIPTCExtCreator: CFString = "kCGImagePropertyIPTCExtCreator"

public let kCGImagePropertyIPTCExtCreatorIdentifier: CFString = "kCGImagePropertyIPTCExtCreatorIdentifier"

public let kCGImagePropertyIPTCExtCreatorName: CFString = "kCGImagePropertyIPTCExtCreatorName"

public let kCGImagePropertyIPTCExtCreatorRole: CFString = "kCGImagePropertyIPTCExtCreatorRole"

public let kCGImagePropertyIPTCExtDataOnScreen: CFString = "kCGImagePropertyIPTCExtDataOnScreen"

public let kCGImagePropertyIPTCExtDataOnScreenRegion: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegion"

public let kCGImagePropertyIPTCExtDataOnScreenRegionD: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionD"

public let kCGImagePropertyIPTCExtDataOnScreenRegionH: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionH"

public let kCGImagePropertyIPTCExtDataOnScreenRegionText: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionText"

public let kCGImagePropertyIPTCExtDataOnScreenRegionUnit: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionUnit"

public let kCGImagePropertyIPTCExtDataOnScreenRegionW: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionW"

public let kCGImagePropertyIPTCExtDataOnScreenRegionX: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionX"

public let kCGImagePropertyIPTCExtDataOnScreenRegionY: CFString = "kCGImagePropertyIPTCExtDataOnScreenRegionY"

public let kCGImagePropertyIPTCExtDigitalImageGUID: CFString = "kCGImagePropertyIPTCExtDigitalImageGUID"

public let kCGImagePropertyIPTCExtDigitalSourceFileType: CFString = "kCGImagePropertyIPTCExtDigitalSourceFileType"

public let kCGImagePropertyIPTCExtDigitalSourceType: CFString = "kCGImagePropertyIPTCExtDigitalSourceType"

public let kCGImagePropertyIPTCExtDopesheet: CFString = "kCGImagePropertyIPTCExtDopesheet"

public let kCGImagePropertyIPTCExtDopesheetLink: CFString = "kCGImagePropertyIPTCExtDopesheetLink"

public let kCGImagePropertyIPTCExtDopesheetLinkLink: CFString = "kCGImagePropertyIPTCExtDopesheetLinkLink"

public let kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier: CFString = "kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier"

public let kCGImagePropertyIPTCExtEmbdEncRightsExpr: CFString = "kCGImagePropertyIPTCExtEmbdEncRightsExpr"

public let kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr: CFString = "kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr"

public let kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID: CFString = "kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID"

public let kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType: CFString = "kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType"

public let kCGImagePropertyIPTCExtEpisode: CFString = "kCGImagePropertyIPTCExtEpisode"

public let kCGImagePropertyIPTCExtEpisodeIdentifier: CFString = "kCGImagePropertyIPTCExtEpisodeIdentifier"

public let kCGImagePropertyIPTCExtEpisodeName: CFString = "kCGImagePropertyIPTCExtEpisodeName"

public let kCGImagePropertyIPTCExtEpisodeNumber: CFString = "kCGImagePropertyIPTCExtEpisodeNumber"

public let kCGImagePropertyIPTCExtEvent: CFString = "kCGImagePropertyIPTCExtEvent"

public let kCGImagePropertyIPTCExtExternalMetadataLink: CFString = "kCGImagePropertyIPTCExtExternalMetadataLink"

public let kCGImagePropertyIPTCExtFeedIdentifier: CFString = "kCGImagePropertyIPTCExtFeedIdentifier"

public let kCGImagePropertyIPTCExtGenre: CFString = "kCGImagePropertyIPTCExtGenre"

public let kCGImagePropertyIPTCExtGenreCvId: CFString = "kCGImagePropertyIPTCExtGenreCvId"

public let kCGImagePropertyIPTCExtGenreCvTermId: CFString = "kCGImagePropertyIPTCExtGenreCvTermId"

public let kCGImagePropertyIPTCExtGenreCvTermName: CFString = "kCGImagePropertyIPTCExtGenreCvTermName"

public let kCGImagePropertyIPTCExtGenreCvTermRefinedAbout: CFString = "kCGImagePropertyIPTCExtGenreCvTermRefinedAbout"

public let kCGImagePropertyIPTCExtHeadline: CFString = "kCGImagePropertyIPTCExtHeadline"

public let kCGImagePropertyIPTCExtIPTCLastEdited: CFString = "kCGImagePropertyIPTCExtIPTCLastEdited"

public let kCGImagePropertyIPTCExtLinkedEncRightsExpr: CFString = "kCGImagePropertyIPTCExtLinkedEncRightsExpr"

public let kCGImagePropertyIPTCExtLinkedEncodedRightsExpr: CFString = "kCGImagePropertyIPTCExtLinkedEncodedRightsExpr"

public let kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID: CFString = "kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID"

public let kCGImagePropertyIPTCExtLinkedEncodedRightsExprType: CFString = "kCGImagePropertyIPTCExtLinkedEncodedRightsExprType"

public let kCGImagePropertyIPTCExtLocationCity: CFString = "kCGImagePropertyIPTCExtLocationCity"

public let kCGImagePropertyIPTCExtLocationCountryCode: CFString = "kCGImagePropertyIPTCExtLocationCountryCode"

public let kCGImagePropertyIPTCExtLocationCountryName: CFString = "kCGImagePropertyIPTCExtLocationCountryName"

public let kCGImagePropertyIPTCExtLocationCreated: CFString = "kCGImagePropertyIPTCExtLocationCreated"

public let kCGImagePropertyIPTCExtLocationGPSAltitude: CFString = "kCGImagePropertyIPTCExtLocationGPSAltitude"

public let kCGImagePropertyIPTCExtLocationGPSLatitude: CFString = "kCGImagePropertyIPTCExtLocationGPSLatitude"

public let kCGImagePropertyIPTCExtLocationGPSLongitude: CFString = "kCGImagePropertyIPTCExtLocationGPSLongitude"

public let kCGImagePropertyIPTCExtLocationIdentifier: CFString = "kCGImagePropertyIPTCExtLocationIdentifier"

public let kCGImagePropertyIPTCExtLocationLocationId: CFString = "kCGImagePropertyIPTCExtLocationLocationId"

public let kCGImagePropertyIPTCExtLocationLocationName: CFString = "kCGImagePropertyIPTCExtLocationLocationName"

public let kCGImagePropertyIPTCExtLocationProvinceState: CFString = "kCGImagePropertyIPTCExtLocationProvinceState"

public let kCGImagePropertyIPTCExtLocationShown: CFString = "kCGImagePropertyIPTCExtLocationShown"

public let kCGImagePropertyIPTCExtLocationSublocation: CFString = "kCGImagePropertyIPTCExtLocationSublocation"

public let kCGImagePropertyIPTCExtLocationWorldRegion: CFString = "kCGImagePropertyIPTCExtLocationWorldRegion"

public let kCGImagePropertyIPTCExtMaxAvailHeight: CFString = "kCGImagePropertyIPTCExtMaxAvailHeight"

public let kCGImagePropertyIPTCExtMaxAvailWidth: CFString = "kCGImagePropertyIPTCExtMaxAvailWidth"

public let kCGImagePropertyIPTCExtModelAge: CFString = "kCGImagePropertyIPTCExtModelAge"

public let kCGImagePropertyIPTCExtOrganisationInImageCode: CFString = "kCGImagePropertyIPTCExtOrganisationInImageCode"

public let kCGImagePropertyIPTCExtOrganisationInImageName: CFString = "kCGImagePropertyIPTCExtOrganisationInImageName"

public let kCGImagePropertyIPTCExtPersonHeard: CFString = "kCGImagePropertyIPTCExtPersonHeard"

public let kCGImagePropertyIPTCExtPersonHeardIdentifier: CFString = "kCGImagePropertyIPTCExtPersonHeardIdentifier"

public let kCGImagePropertyIPTCExtPersonHeardName: CFString = "kCGImagePropertyIPTCExtPersonHeardName"

public let kCGImagePropertyIPTCExtPersonInImage: CFString = "kCGImagePropertyIPTCExtPersonInImage"

public let kCGImagePropertyIPTCExtPersonInImageCharacteristic: CFString = "kCGImagePropertyIPTCExtPersonInImageCharacteristic"

public let kCGImagePropertyIPTCExtPersonInImageCvTermCvId: CFString = "kCGImagePropertyIPTCExtPersonInImageCvTermCvId"

public let kCGImagePropertyIPTCExtPersonInImageCvTermId: CFString = "kCGImagePropertyIPTCExtPersonInImageCvTermId"

public let kCGImagePropertyIPTCExtPersonInImageCvTermName: CFString = "kCGImagePropertyIPTCExtPersonInImageCvTermName"

public let kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout: CFString = "kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout"

public let kCGImagePropertyIPTCExtPersonInImageDescription: CFString = "kCGImagePropertyIPTCExtPersonInImageDescription"

public let kCGImagePropertyIPTCExtPersonInImageId: CFString = "kCGImagePropertyIPTCExtPersonInImageId"

public let kCGImagePropertyIPTCExtPersonInImageName: CFString = "kCGImagePropertyIPTCExtPersonInImageName"

public let kCGImagePropertyIPTCExtPersonInImageWDetails: CFString = "kCGImagePropertyIPTCExtPersonInImageWDetails"

public let kCGImagePropertyIPTCExtProductInImage: CFString = "kCGImagePropertyIPTCExtProductInImage"

public let kCGImagePropertyIPTCExtProductInImageDescription: CFString = "kCGImagePropertyIPTCExtProductInImageDescription"

public let kCGImagePropertyIPTCExtProductInImageGTIN: CFString = "kCGImagePropertyIPTCExtProductInImageGTIN"

public let kCGImagePropertyIPTCExtProductInImageName: CFString = "kCGImagePropertyIPTCExtProductInImageName"

public let kCGImagePropertyIPTCExtPublicationEvent: CFString = "kCGImagePropertyIPTCExtPublicationEvent"

public let kCGImagePropertyIPTCExtPublicationEventDate: CFString = "kCGImagePropertyIPTCExtPublicationEventDate"

public let kCGImagePropertyIPTCExtPublicationEventIdentifier: CFString = "kCGImagePropertyIPTCExtPublicationEventIdentifier"

public let kCGImagePropertyIPTCExtPublicationEventName: CFString = "kCGImagePropertyIPTCExtPublicationEventName"

public let kCGImagePropertyIPTCExtRating: CFString = "kCGImagePropertyIPTCExtRating"

public let kCGImagePropertyIPTCExtRatingRatingRegion: CFString = "kCGImagePropertyIPTCExtRatingRatingRegion"

public let kCGImagePropertyIPTCExtRatingRegionCity: CFString = "kCGImagePropertyIPTCExtRatingRegionCity"

public let kCGImagePropertyIPTCExtRatingRegionCountryCode: CFString = "kCGImagePropertyIPTCExtRatingRegionCountryCode"

public let kCGImagePropertyIPTCExtRatingRegionCountryName: CFString = "kCGImagePropertyIPTCExtRatingRegionCountryName"

public let kCGImagePropertyIPTCExtRatingRegionGPSAltitude: CFString = "kCGImagePropertyIPTCExtRatingRegionGPSAltitude"

public let kCGImagePropertyIPTCExtRatingRegionGPSLatitude: CFString = "kCGImagePropertyIPTCExtRatingRegionGPSLatitude"

public let kCGImagePropertyIPTCExtRatingRegionGPSLongitude: CFString = "kCGImagePropertyIPTCExtRatingRegionGPSLongitude"

public let kCGImagePropertyIPTCExtRatingRegionIdentifier: CFString = "kCGImagePropertyIPTCExtRatingRegionIdentifier"

public let kCGImagePropertyIPTCExtRatingRegionLocationId: CFString = "kCGImagePropertyIPTCExtRatingRegionLocationId"

public let kCGImagePropertyIPTCExtRatingRegionLocationName: CFString = "kCGImagePropertyIPTCExtRatingRegionLocationName"

public let kCGImagePropertyIPTCExtRatingRegionProvinceState: CFString = "kCGImagePropertyIPTCExtRatingRegionProvinceState"

public let kCGImagePropertyIPTCExtRatingRegionSublocation: CFString = "kCGImagePropertyIPTCExtRatingRegionSublocation"

public let kCGImagePropertyIPTCExtRatingRegionWorldRegion: CFString = "kCGImagePropertyIPTCExtRatingRegionWorldRegion"

public let kCGImagePropertyIPTCExtRatingScaleMaxValue: CFString = "kCGImagePropertyIPTCExtRatingScaleMaxValue"

public let kCGImagePropertyIPTCExtRatingScaleMinValue: CFString = "kCGImagePropertyIPTCExtRatingScaleMinValue"

public let kCGImagePropertyIPTCExtRatingSourceLink: CFString = "kCGImagePropertyIPTCExtRatingSourceLink"

public let kCGImagePropertyIPTCExtRatingValue: CFString = "kCGImagePropertyIPTCExtRatingValue"

public let kCGImagePropertyIPTCExtRatingValueLogoLink: CFString = "kCGImagePropertyIPTCExtRatingValueLogoLink"

public let kCGImagePropertyIPTCExtRegistryEntryRole: CFString = "kCGImagePropertyIPTCExtRegistryEntryRole"

public let kCGImagePropertyIPTCExtRegistryID: CFString = "kCGImagePropertyIPTCExtRegistryID"

public let kCGImagePropertyIPTCExtRegistryItemID: CFString = "kCGImagePropertyIPTCExtRegistryItemID"

public let kCGImagePropertyIPTCExtRegistryOrganisationID: CFString = "kCGImagePropertyIPTCExtRegistryOrganisationID"

public let kCGImagePropertyIPTCExtReleaseReady: CFString = "kCGImagePropertyIPTCExtReleaseReady"

public let kCGImagePropertyIPTCExtSeason: CFString = "kCGImagePropertyIPTCExtSeason"

public let kCGImagePropertyIPTCExtSeasonIdentifier: CFString = "kCGImagePropertyIPTCExtSeasonIdentifier"

public let kCGImagePropertyIPTCExtSeasonName: CFString = "kCGImagePropertyIPTCExtSeasonName"

public let kCGImagePropertyIPTCExtSeasonNumber: CFString = "kCGImagePropertyIPTCExtSeasonNumber"

public let kCGImagePropertyIPTCExtSeries: CFString = "kCGImagePropertyIPTCExtSeries"

public let kCGImagePropertyIPTCExtSeriesIdentifier: CFString = "kCGImagePropertyIPTCExtSeriesIdentifier"

public let kCGImagePropertyIPTCExtSeriesName: CFString = "kCGImagePropertyIPTCExtSeriesName"

public let kCGImagePropertyIPTCExtShownEvent: CFString = "kCGImagePropertyIPTCExtShownEvent"

public let kCGImagePropertyIPTCExtShownEventIdentifier: CFString = "kCGImagePropertyIPTCExtShownEventIdentifier"

public let kCGImagePropertyIPTCExtShownEventName: CFString = "kCGImagePropertyIPTCExtShownEventName"

public let kCGImagePropertyIPTCExtStorylineIdentifier: CFString = "kCGImagePropertyIPTCExtStorylineIdentifier"

public let kCGImagePropertyIPTCExtStreamReady: CFString = "kCGImagePropertyIPTCExtStreamReady"

public let kCGImagePropertyIPTCExtStylePeriod: CFString = "kCGImagePropertyIPTCExtStylePeriod"

public let kCGImagePropertyIPTCExtSupplyChainSource: CFString = "kCGImagePropertyIPTCExtSupplyChainSource"

public let kCGImagePropertyIPTCExtSupplyChainSourceIdentifier: CFString = "kCGImagePropertyIPTCExtSupplyChainSourceIdentifier"

public let kCGImagePropertyIPTCExtSupplyChainSourceName: CFString = "kCGImagePropertyIPTCExtSupplyChainSourceName"

public let kCGImagePropertyIPTCExtTemporalCoverage: CFString = "kCGImagePropertyIPTCExtTemporalCoverage"

public let kCGImagePropertyIPTCExtTemporalCoverageFrom: CFString = "kCGImagePropertyIPTCExtTemporalCoverageFrom"

public let kCGImagePropertyIPTCExtTemporalCoverageTo: CFString = "kCGImagePropertyIPTCExtTemporalCoverageTo"

public let kCGImagePropertyIPTCExtTranscript: CFString = "kCGImagePropertyIPTCExtTranscript"

public let kCGImagePropertyIPTCExtTranscriptLink: CFString = "kCGImagePropertyIPTCExtTranscriptLink"

public let kCGImagePropertyIPTCExtTranscriptLinkLink: CFString = "kCGImagePropertyIPTCExtTranscriptLinkLink"

public let kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier: CFString = "kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier"

public let kCGImagePropertyIPTCExtVideoBitrate: CFString = "kCGImagePropertyIPTCExtVideoBitrate"

public let kCGImagePropertyIPTCExtVideoBitrateMode: CFString = "kCGImagePropertyIPTCExtVideoBitrateMode"

public let kCGImagePropertyIPTCExtVideoDisplayAspectRatio: CFString = "kCGImagePropertyIPTCExtVideoDisplayAspectRatio"

public let kCGImagePropertyIPTCExtVideoEncodingProfile: CFString = "kCGImagePropertyIPTCExtVideoEncodingProfile"

public let kCGImagePropertyIPTCExtVideoShotType: CFString = "kCGImagePropertyIPTCExtVideoShotType"

public let kCGImagePropertyIPTCExtVideoShotTypeIdentifier: CFString = "kCGImagePropertyIPTCExtVideoShotTypeIdentifier"

public let kCGImagePropertyIPTCExtVideoShotTypeName: CFString = "kCGImagePropertyIPTCExtVideoShotTypeName"

public let kCGImagePropertyIPTCExtVideoStreamsCount: CFString = "kCGImagePropertyIPTCExtVideoStreamsCount"

public let kCGImagePropertyIPTCExtVisualColor: CFString = "kCGImagePropertyIPTCExtVisualColor"

public let kCGImagePropertyIPTCExtWorkflowTag: CFString = "kCGImagePropertyIPTCExtWorkflowTag"

public let kCGImagePropertyIPTCExtWorkflowTagCvId: CFString = "kCGImagePropertyIPTCExtWorkflowTagCvId"

public let kCGImagePropertyIPTCExtWorkflowTagCvTermId: CFString = "kCGImagePropertyIPTCExtWorkflowTagCvTermId"

public let kCGImagePropertyIPTCExtWorkflowTagCvTermName: CFString = "kCGImagePropertyIPTCExtWorkflowTagCvTermName"

public let kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout: CFString = "kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout"

public let kCGImagePropertyIPTCFixtureIdentifier: CFString = "kCGImagePropertyIPTCFixtureIdentifier"

public let kCGImagePropertyIPTCHeadline: CFString = "kCGImagePropertyIPTCHeadline"

public let kCGImagePropertyIPTCImageOrientation: CFString = "kCGImagePropertyIPTCImageOrientation"

public let kCGImagePropertyIPTCImageType: CFString = "kCGImagePropertyIPTCImageType"

public let kCGImagePropertyIPTCKeywords: CFString = "kCGImagePropertyIPTCKeywords"

public let kCGImagePropertyIPTCLanguageIdentifier: CFString = "kCGImagePropertyIPTCLanguageIdentifier"

public let kCGImagePropertyIPTCObjectAttributeReference: CFString = "kCGImagePropertyIPTCObjectAttributeReference"

public let kCGImagePropertyIPTCObjectCycle: CFString = "kCGImagePropertyIPTCObjectCycle"

public let kCGImagePropertyIPTCObjectName: CFString = "kCGImagePropertyIPTCObjectName"

public let kCGImagePropertyIPTCObjectTypeReference: CFString = "kCGImagePropertyIPTCObjectTypeReference"

public let kCGImagePropertyIPTCOriginalTransmissionReference: CFString = "kCGImagePropertyIPTCOriginalTransmissionReference"

public let kCGImagePropertyIPTCOriginatingProgram: CFString = "kCGImagePropertyIPTCOriginatingProgram"

public let kCGImagePropertyIPTCProgramVersion: CFString = "kCGImagePropertyIPTCProgramVersion"

public let kCGImagePropertyIPTCProvinceState: CFString = "kCGImagePropertyIPTCProvinceState"

public let kCGImagePropertyIPTCReferenceDate: CFString = "kCGImagePropertyIPTCReferenceDate"

public let kCGImagePropertyIPTCReferenceNumber: CFString = "kCGImagePropertyIPTCReferenceNumber"

public let kCGImagePropertyIPTCReferenceService: CFString = "kCGImagePropertyIPTCReferenceService"

public let kCGImagePropertyIPTCReleaseDate: CFString = "kCGImagePropertyIPTCReleaseDate"

public let kCGImagePropertyIPTCReleaseTime: CFString = "kCGImagePropertyIPTCReleaseTime"

public let kCGImagePropertyIPTCRightsUsageTerms: CFString = "kCGImagePropertyIPTCRightsUsageTerms"

public let kCGImagePropertyIPTCScene: CFString = "kCGImagePropertyIPTCScene"

public let kCGImagePropertyIPTCSource: CFString = "kCGImagePropertyIPTCSource"

public let kCGImagePropertyIPTCSpecialInstructions: CFString = "kCGImagePropertyIPTCSpecialInstructions"

public let kCGImagePropertyIPTCStarRating: CFString = "kCGImagePropertyIPTCStarRating"

public let kCGImagePropertyIPTCSubLocation: CFString = "kCGImagePropertyIPTCSubLocation"

public let kCGImagePropertyIPTCSubjectReference: CFString = "kCGImagePropertyIPTCSubjectReference"

public let kCGImagePropertyIPTCSupplementalCategory: CFString = "kCGImagePropertyIPTCSupplementalCategory"

public let kCGImagePropertyIPTCTimeCreated: CFString = "kCGImagePropertyIPTCTimeCreated"

public let kCGImagePropertyIPTCUrgency: CFString = "kCGImagePropertyIPTCUrgency"

public let kCGImagePropertyIPTCWriterEditor: CFString = "kCGImagePropertyIPTCWriterEditor"

public let kCGImagePropertyImageCount: CFString = "kCGImagePropertyImageCount"

public let kCGImagePropertyImageIndex: CFString = "kCGImagePropertyImageIndex"

public let kCGImagePropertyImages: CFString = "kCGImagePropertyImages"

public let kCGImagePropertyIsFloat: CFString = "kCGImagePropertyIsFloat"

public let kCGImagePropertyIsIndexed: CFString = "kCGImagePropertyIsIndexed"

public let kCGImagePropertyJFIFDensityUnit: CFString = "kCGImagePropertyJFIFDensityUnit"

public let kCGImagePropertyJFIFDictionary: CFString = "{JFIF}"

public let kCGImagePropertyJFIFIsProgressive: CFString = "IsProgressive"

public let kCGImagePropertyJFIFVersion: CFString = "kCGImagePropertyJFIFVersion"

public let kCGImagePropertyJFIFXDensity: CFString = "kCGImagePropertyJFIFXDensity"

public let kCGImagePropertyJFIFYDensity: CFString = "kCGImagePropertyJFIFYDensity"

public let kCGImagePropertyMakerAppleDictionary: CFString = "{MakerApple}"

public let kCGImagePropertyMakerCanonAspectRatioInfo: CFString = "kCGImagePropertyMakerCanonAspectRatioInfo"

public let kCGImagePropertyMakerCanonCameraSerialNumber: CFString = "kCGImagePropertyMakerCanonCameraSerialNumber"

public let kCGImagePropertyMakerCanonContinuousDrive: CFString = "kCGImagePropertyMakerCanonContinuousDrive"

public let kCGImagePropertyMakerCanonDictionary: CFString = "{MakerCanon}"

public let kCGImagePropertyMakerCanonFirmware: CFString = "kCGImagePropertyMakerCanonFirmware"

public let kCGImagePropertyMakerCanonFlashExposureComp: CFString = "kCGImagePropertyMakerCanonFlashExposureComp"

public let kCGImagePropertyMakerCanonImageSerialNumber: CFString = "kCGImagePropertyMakerCanonImageSerialNumber"

public let kCGImagePropertyMakerCanonLensModel: CFString = "kCGImagePropertyMakerCanonLensModel"

public let kCGImagePropertyMakerCanonOwnerName: CFString = "kCGImagePropertyMakerCanonOwnerName"

public let kCGImagePropertyMakerFujiDictionary: CFString = "{MakerFuji}"

public let kCGImagePropertyMakerMinoltaDictionary: CFString = "{MakerMinolta}"

public let kCGImagePropertyMakerNikonCameraSerialNumber: CFString = "kCGImagePropertyMakerNikonCameraSerialNumber"

public let kCGImagePropertyMakerNikonColorMode: CFString = "kCGImagePropertyMakerNikonColorMode"

public let kCGImagePropertyMakerNikonDictionary: CFString = "{MakerNikon}"

public let kCGImagePropertyMakerNikonDigitalZoom: CFString = "kCGImagePropertyMakerNikonDigitalZoom"

public let kCGImagePropertyMakerNikonFlashExposureComp: CFString = "kCGImagePropertyMakerNikonFlashExposureComp"

public let kCGImagePropertyMakerNikonFlashSetting: CFString = "kCGImagePropertyMakerNikonFlashSetting"

public let kCGImagePropertyMakerNikonFocusDistance: CFString = "kCGImagePropertyMakerNikonFocusDistance"

public let kCGImagePropertyMakerNikonFocusMode: CFString = "kCGImagePropertyMakerNikonFocusMode"

public let kCGImagePropertyMakerNikonISOSelection: CFString = "kCGImagePropertyMakerNikonISOSelection"

public let kCGImagePropertyMakerNikonISOSetting: CFString = "kCGImagePropertyMakerNikonISOSetting"

public let kCGImagePropertyMakerNikonImageAdjustment: CFString = "kCGImagePropertyMakerNikonImageAdjustment"

public let kCGImagePropertyMakerNikonLensAdapter: CFString = "kCGImagePropertyMakerNikonLensAdapter"

public let kCGImagePropertyMakerNikonLensInfo: CFString = "kCGImagePropertyMakerNikonLensInfo"

public let kCGImagePropertyMakerNikonLensType: CFString = "kCGImagePropertyMakerNikonLensType"

public let kCGImagePropertyMakerNikonQuality: CFString = "kCGImagePropertyMakerNikonQuality"

public let kCGImagePropertyMakerNikonSharpenMode: CFString = "kCGImagePropertyMakerNikonSharpenMode"

public let kCGImagePropertyMakerNikonShootingMode: CFString = "kCGImagePropertyMakerNikonShootingMode"

public let kCGImagePropertyMakerNikonShutterCount: CFString = "kCGImagePropertyMakerNikonShutterCount"

public let kCGImagePropertyMakerNikonWhiteBalanceMode: CFString = "kCGImagePropertyMakerNikonWhiteBalanceMode"

public let kCGImagePropertyMakerOlympusDictionary: CFString = "{MakerOlympus}"

public let kCGImagePropertyMakerPentaxDictionary: CFString = "{MakerPentax}"

public let kCGImagePropertyNamedColorSpace: CFString = "kCGImagePropertyNamedColorSpace"

public let kCGImagePropertyOpenEXRAspectRatio: CFString = "kCGImagePropertyOpenEXRAspectRatio"

public let kCGImagePropertyOpenEXRCompression: CFString = "kCGImagePropertyOpenEXRCompression"

public let kCGImagePropertyOpenEXRDictionary: CFString = "{OpenEXR}"

public let kCGImagePropertyOrientation: CFString = "Orientation"

public let kCGImagePropertyPNGAuthor: CFString = "kCGImagePropertyPNGAuthor"

public let kCGImagePropertyPNGChromaticities: CFString = "kCGImagePropertyPNGChromaticities"

public let kCGImagePropertyPNGComment: CFString = "kCGImagePropertyPNGComment"

public let kCGImagePropertyPNGCompressionFilter: CFString = "kCGImagePropertyPNGCompressionFilter"

public let kCGImagePropertyPNGCopyright: CFString = "kCGImagePropertyPNGCopyright"

public let kCGImagePropertyPNGCreationTime: CFString = "kCGImagePropertyPNGCreationTime"

public let kCGImagePropertyPNGDescription: CFString = "kCGImagePropertyPNGDescription"

public let kCGImagePropertyPNGDictionary: CFString = "{PNG}"

public let kCGImagePropertyPNGDisclaimer: CFString = "kCGImagePropertyPNGDisclaimer"

public let kCGImagePropertyPNGGamma: CFString = "kCGImagePropertyPNGGamma"

public let kCGImagePropertyPNGInterlaceType: CFString = "kCGImagePropertyPNGInterlaceType"

public let kCGImagePropertyPNGModificationTime: CFString = "kCGImagePropertyPNGModificationTime"

public let kCGImagePropertyPNGPixelsAspectRatio: CFString = "kCGImagePropertyPNGPixelsAspectRatio"

public let kCGImagePropertyPNGSoftware: CFString = "kCGImagePropertyPNGSoftware"

public let kCGImagePropertyPNGSource: CFString = "kCGImagePropertyPNGSource"

public let kCGImagePropertyPNGTitle: CFString = "kCGImagePropertyPNGTitle"

public let kCGImagePropertyPNGTransparency: CFString = "kCGImagePropertyPNGTransparency"

public let kCGImagePropertyPNGWarning: CFString = "kCGImagePropertyPNGWarning"

public let kCGImagePropertyPNGXPixelsPerMeter: CFString = "kCGImagePropertyPNGXPixelsPerMeter"

public let kCGImagePropertyPNGYPixelsPerMeter: CFString = "kCGImagePropertyPNGYPixelsPerMeter"

public let kCGImagePropertyPNGsRGBIntent: CFString = "kCGImagePropertyPNGsRGBIntent"

public let kCGImagePropertyPVREncoder: CFString = "kCGImagePropertyPVREncoder"

public let kCGImagePropertyPixelFormat: CFString = "PixelFormat"

public let kCGImagePropertyPixelHeight: CFString = "PixelHeight"

public let kCGImagePropertyPixelWidth: CFString = "PixelWidth"

public let kCGImagePropertyPrimaryImage: CFString = "kCGImagePropertyPrimaryImage"

public let kCGImagePropertyProfileName: CFString = "ProfileName"

public let kCGImagePropertyRawDictionary: CFString = "{Raw}"

public let kCGImagePropertyTGACompression: CFString = "kCGImagePropertyTGACompression"

public let kCGImagePropertyTGADictionary: CFString = "{TGA}"

public let kCGImagePropertyTIFFArtist: CFString = "kCGImagePropertyTIFFArtist"

public let kCGImagePropertyTIFFCompression: CFString = "kCGImagePropertyTIFFCompression"

public let kCGImagePropertyTIFFCopyright: CFString = "kCGImagePropertyTIFFCopyright"

public let kCGImagePropertyTIFFDateTime: CFString = "kCGImagePropertyTIFFDateTime"

public let kCGImagePropertyTIFFDictionary: CFString = "{TIFF}"

public let kCGImagePropertyTIFFDocumentName: CFString = "kCGImagePropertyTIFFDocumentName"

public let kCGImagePropertyTIFFHostComputer: CFString = "kCGImagePropertyTIFFHostComputer"

public let kCGImagePropertyTIFFImageDescription: CFString = "kCGImagePropertyTIFFImageDescription"

public let kCGImagePropertyTIFFMake: CFString = "kCGImagePropertyTIFFMake"

public let kCGImagePropertyTIFFModel: CFString = "kCGImagePropertyTIFFModel"

public let kCGImagePropertyTIFFOrientation: CFString = "kCGImagePropertyTIFFOrientation"

public let kCGImagePropertyTIFFPhotometricInterpretation: CFString = "kCGImagePropertyTIFFPhotometricInterpretation"

public let kCGImagePropertyTIFFPrimaryChromaticities: CFString = "kCGImagePropertyTIFFPrimaryChromaticities"

public let kCGImagePropertyTIFFResolutionUnit: CFString = "kCGImagePropertyTIFFResolutionUnit"

public let kCGImagePropertyTIFFSoftware: CFString = "kCGImagePropertyTIFFSoftware"

public let kCGImagePropertyTIFFTileLength: CFString = "kCGImagePropertyTIFFTileLength"

public let kCGImagePropertyTIFFTileWidth: CFString = "kCGImagePropertyTIFFTileWidth"

public let kCGImagePropertyTIFFTransferFunction: CFString = "kCGImagePropertyTIFFTransferFunction"

public let kCGImagePropertyTIFFWhitePoint: CFString = "kCGImagePropertyTIFFWhitePoint"

public let kCGImagePropertyTIFFXPosition: CFString = "kCGImagePropertyTIFFXPosition"

public let kCGImagePropertyTIFFXResolution: CFString = "kCGImagePropertyTIFFXResolution"

public let kCGImagePropertyTIFFYPosition: CFString = "kCGImagePropertyTIFFYPosition"

public let kCGImagePropertyTIFFYResolution: CFString = "kCGImagePropertyTIFFYResolution"

public let kCGImagePropertyThumbnailImages: CFString = "kCGImagePropertyThumbnailImages"

public let kCGImagePropertyWebPCanvasPixelHeight: CFString = "kCGImagePropertyWebPCanvasPixelHeight"

public let kCGImagePropertyWebPCanvasPixelWidth: CFString = "kCGImagePropertyWebPCanvasPixelWidth"

public let kCGImagePropertyWebPDelayTime: CFString = "DelayTime"

public let kCGImagePropertyWebPDictionary: CFString = "{WebP}"

public let kCGImagePropertyWebPFrameInfoArray: CFString = "kCGImagePropertyWebPFrameInfoArray"

public let kCGImagePropertyWebPLoopCount: CFString = "LoopCount"

public let kCGImagePropertyWebPUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyWidth: CFString = "kCGImagePropertyWidth"

public let kCGImageProviderPreferredTileHeight: CFString = "kCGImageProviderPreferredTileHeight"

public let kCGImageProviderPreferredTileWidth: CFString = "kCGImageProviderPreferredTileWidth"

public let kCGImageSourceCreateThumbnailFromImageAlways: CFString = "CreateThumbnailFromImageAlways"

public let kCGImageSourceCreateThumbnailFromImageIfAbsent: CFString = "CreateThumbnailFromImageIfAbsent"

public let kCGImageSourceCreateThumbnailWithTransform: CFString = "CreateThumbnailWithTransform"

public let kCGImageSourceDecodeRequest: CFString = "kCGImageSourceDecodeRequest"

public let kCGImageSourceDecodeRequestOptions: CFString = "kCGImageSourceDecodeRequestOptions"

public let kCGImageSourceDecodeToHDR: CFString = "kCGImageSourceDecodeToHDR"

public let kCGImageSourceDecodeToSDR: CFString = "kCGImageSourceDecodeToSDR"

public let kCGImageSourceGenerateImageSpecificLumaScaling: CFString = "kCGImageSourceGenerateImageSpecificLumaScaling"

public let kCGImageSourceShouldAllowFloat: CFString = "kCGImageSourceShouldAllowFloat"

public let kCGImageSourceShouldCache: CFString = "ShouldCache"

public let kCGImageSourceShouldCacheImmediately: CFString = "ShouldCacheImmediately"

public let kCGImageSourceSubsampleFactor: CFString = "kCGImageSourceSubsampleFactor"

public let kCGImageSourceThumbnailMaxPixelSize: CFString = "ThumbnailMaxPixelSize"

public let kCGImageSourceTypeIdentifierHint: CFString = "kCGImageSourceTypeIdentifierHint"

public let kIIOCameraExtrinsics_CoordinateSystemID: CFString = "kIIOCameraExtrinsics_CoordinateSystemID"

public let kIIOCameraExtrinsics_Position: CFString = "kIIOCameraExtrinsics_Position"

public let kIIOCameraExtrinsics_Rotation: CFString = "kIIOCameraExtrinsics_Rotation"

public let kIIOCameraModelType_GenericPinhole: CFString = "kIIOCameraModelType_GenericPinhole"

public let kIIOCameraModelType_SimplifiedPinhole: CFString = "kIIOCameraModelType_SimplifiedPinhole"

public let kIIOCameraModel_Intrinsics: CFString = "kIIOCameraModel_Intrinsics"

public let kIIOCameraModel_ModelType: CFString = "kIIOCameraModel_ModelType"

public let kIIOMetadata_CameraExtrinsicsKey: CFString = "kIIOMetadata_CameraExtrinsicsKey"

public let kIIOMetadata_CameraModelKey: CFString = "kIIOMetadata_CameraModelKey"

public let kIIOMonoscopicImageLocation_Center: CFString = "kIIOMonoscopicImageLocation_Center"

public let kIIOMonoscopicImageLocation_Left: CFString = "kIIOMonoscopicImageLocation_Left"

public let kIIOMonoscopicImageLocation_Right: CFString = "kIIOMonoscopicImageLocation_Right"

public let kIIOMonoscopicImageLocation_Unspecified: CFString = "kIIOMonoscopicImageLocation_Unspecified"

public let kIIOStereoAggressors_Severity: CFString = "kIIOStereoAggressors_Severity"

public let kIIOStereoAggressors_SubTypeURI: CFString = "kIIOStereoAggressors_SubTypeURI"

public let kIIOStereoAggressors_Type: CFString = "kIIOStereoAggressors_Type"

public let IIO_HAS_IOSURFACE: CFString = "IIO_HAS_IOSURFACE"

public let IMAGEIO_PNG_FILTER_AVG: CFString = "IMAGEIO_PNG_FILTER_AVG"

public let IMAGEIO_PNG_FILTER_NONE: CFString = "IMAGEIO_PNG_FILTER_NONE"

public let IMAGEIO_PNG_FILTER_PAETH: CFString = "IMAGEIO_PNG_FILTER_PAETH"

public let IMAGEIO_PNG_FILTER_SUB: CFString = "IMAGEIO_PNG_FILTER_SUB"

public let IMAGEIO_PNG_FILTER_UP: CFString = "IMAGEIO_PNG_FILTER_UP"

public let IMAGEIO_PNG_NO_FILTERS: CFString = "IMAGEIO_PNG_NO_FILTERS"
