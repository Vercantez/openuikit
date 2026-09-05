// CFString keys. Payloads measured 2026-09-05 against Apple ImageIO
// (macOS 26.1 / ImageIO.framework) via /tmp/imageio-apple-oracle.swift.
// Nested keys use the short dictionary names Darwin stores (PixelWidth,
// DateTimeOriginal, {Exif}); option keys keep the C identifier when that
// is the runtime CFString (kCGImageSourceShouldCache, ThumbnailMaxPixelSize
// is kCGImageSourceThumbnailMaxPixelSize).

import Foundation

public let kCFErrorDomainCGImageMetadata: CFString = "kCFErrorDomainCGImageMetadata"

public let kCGComputeHDRStats: CFString = "kCGComputeHDRStats"

public let kCGImageAnimationDelayTime: CFString = "DelayTime"

public let kCGImageAnimationLoopCount: CFString = "LoopCount"

public let kCGImageAnimationStartIndex: CFString = "StartIndex"

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

public let kCGImageProperty8BIMLayerNames: CFString = "LayerNames"

public let kCGImageProperty8BIMVersion: CFString = "Version"

public let kCGImagePropertyAPNGCanvasPixelHeight: CFString = "CanvasPixelHeight"

public let kCGImagePropertyAPNGCanvasPixelWidth: CFString = "CanvasPixelWidth"

public let kCGImagePropertyAPNGDelayTime: CFString = "DelayTime"

public let kCGImagePropertyAPNGFrameInfoArray: CFString = "FrameInfo"

public let kCGImagePropertyAPNGLoopCount: CFString = "LoopCount"

public let kCGImagePropertyAPNGUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyASTCBlockSize: CFString = "kCGImagePropertyASTCBlockSize"

public let kCGImagePropertyASTCBlockSize4x4: CFString = "kCGImagePropertyASTCBlockSize4x4"

public let kCGImagePropertyASTCBlockSize8x8: CFString = "kCGImagePropertyASTCBlockSize8x8"

public let kCGImagePropertyASTCEncoder: CFString = "kCGImagePropertyASTCEncoder"

public let kCGImagePropertyAVISDictionary: CFString = "{AVIS}"

public let kCGImagePropertyAuxiliaryData: CFString = "AuxiliaryData"

public let kCGImagePropertyAuxiliaryDataType: CFString = "AuxiliaryDataType"

public let kCGImagePropertyBCEncoder: CFString = "kCGImagePropertyBCEncoder"

public let kCGImagePropertyBCFormat: CFString = "kCGImagePropertyBCFormat"

public let kCGImagePropertyBytesPerRow: CFString = "BytesPerRow"

public let kCGImagePropertyCIFFCameraSerialNumber: CFString = "CameraSerialNumber"

public let kCGImagePropertyCIFFContinuousDrive: CFString = "ContinuousDrive"

public let kCGImagePropertyCIFFDescription: CFString = "Description"

public let kCGImagePropertyCIFFDictionary: CFString = "{CIFF}"

public let kCGImagePropertyCIFFFirmware: CFString = "Firmware"

public let kCGImagePropertyCIFFFlashExposureComp: CFString = "FlashExposureComp"

public let kCGImagePropertyCIFFFocusMode: CFString = "FocusMode"

public let kCGImagePropertyCIFFImageFileName: CFString = "ImageFileName"

public let kCGImagePropertyCIFFImageName: CFString = "ImageName"

public let kCGImagePropertyCIFFImageSerialNumber: CFString = "ImageSerialNumber"

public let kCGImagePropertyCIFFLensMaxMM: CFString = "LensMaxMM"

public let kCGImagePropertyCIFFLensMinMM: CFString = "LensMinMM"

public let kCGImagePropertyCIFFLensModel: CFString = "LensModel"

public let kCGImagePropertyCIFFMeasuredEV: CFString = "MeasuredEV"

public let kCGImagePropertyCIFFMeteringMode: CFString = "MeteringMode"

public let kCGImagePropertyCIFFOwnerName: CFString = "OwnerName"

public let kCGImagePropertyCIFFRecordID: CFString = "RecordID"

public let kCGImagePropertyCIFFReleaseMethod: CFString = "ReleaseMethod"

public let kCGImagePropertyCIFFReleaseTiming: CFString = "ReleaseTiming"

public let kCGImagePropertyCIFFSelfTimingTime: CFString = "SelfTimingTime"

public let kCGImagePropertyCIFFShootingMode: CFString = "ShootingMode"

public let kCGImagePropertyCIFFWhiteBalanceIndex: CFString = "WhiteBalanceIndex"

public let kCGImagePropertyColorModel: CFString = "ColorModel"

public let kCGImagePropertyColorModelCMYK: CFString = "CMYK"

public let kCGImagePropertyColorModelGray: CFString = "Gray"

public let kCGImagePropertyColorModelLab: CFString = "Lab"

public let kCGImagePropertyColorModelRGB: CFString = "RGB"

public let kCGImagePropertyDNGActiveArea: CFString = "ActiveArea"

public let kCGImagePropertyDNGAnalogBalance: CFString = "AnalogBalance"

public let kCGImagePropertyDNGAntiAliasStrength: CFString = "AntiAliasStrength"

public let kCGImagePropertyDNGAsShotICCProfile: CFString = "AsShotICCProfile"

public let kCGImagePropertyDNGAsShotNeutral: CFString = "AsShotNeutral"

public let kCGImagePropertyDNGAsShotPreProfileMatrix: CFString = "AsShotPreProfileMatrix"

public let kCGImagePropertyDNGAsShotProfileName: CFString = "AsShotProfileName"

public let kCGImagePropertyDNGAsShotWhiteXY: CFString = "AsShotWhiteXY"

public let kCGImagePropertyDNGBackwardVersion: CFString = "DNGBackwardVersion"

public let kCGImagePropertyDNGBaselineExposure: CFString = "BaselineExposure"

public let kCGImagePropertyDNGBaselineExposureOffset: CFString = "BaselineExposureOffset"

public let kCGImagePropertyDNGBaselineNoise: CFString = "BaselineNoise"

public let kCGImagePropertyDNGBaselineSharpness: CFString = "BaselineSharpness"

public let kCGImagePropertyDNGBayerGreenSplit: CFString = "BayerGreenSplit"

public let kCGImagePropertyDNGBestQualityScale: CFString = "BestQualityScale"

public let kCGImagePropertyDNGBlackLevel: CFString = "BlackLevel"

public let kCGImagePropertyDNGBlackLevelDeltaH: CFString = "BlackLevelDeltaH"

public let kCGImagePropertyDNGBlackLevelDeltaV: CFString = "BlackLevelDeltaV"

public let kCGImagePropertyDNGBlackLevelRepeatDim: CFString = "BlackLevelRepeatDim"

public let kCGImagePropertyDNGCFALayout: CFString = "CFALayout"

public let kCGImagePropertyDNGCFAPlaneColor: CFString = "CFAPlaneColor"

public let kCGImagePropertyDNGCalibrationIlluminant1: CFString = "CalibrationIlluminant1"

public let kCGImagePropertyDNGCalibrationIlluminant2: CFString = "CalibrationIlluminant2"

public let kCGImagePropertyDNGCameraCalibration1: CFString = "CameraCalibration1"

public let kCGImagePropertyDNGCameraCalibration2: CFString = "CameraCalibration2"

public let kCGImagePropertyDNGCameraCalibrationSignature: CFString = "CameraCalibrationSignature"

public let kCGImagePropertyDNGCameraSerialNumber: CFString = "CameraSerialNumber"

public let kCGImagePropertyDNGChromaBlurRadius: CFString = "ChromaBlurRadius"

public let kCGImagePropertyDNGColorMatrix1: CFString = "ColorMatrix1"

public let kCGImagePropertyDNGColorMatrix2: CFString = "ColorMatrix2"

public let kCGImagePropertyDNGColorimetricReference: CFString = "ColorimetricReference"

public let kCGImagePropertyDNGCurrentICCProfile: CFString = "CurrentICCProfile"

public let kCGImagePropertyDNGCurrentPreProfileMatrix: CFString = "CurrentPreProfileMatrix"

public let kCGImagePropertyDNGDefaultBlackRender: CFString = "DefaultBlackRender"

public let kCGImagePropertyDNGDefaultCropOrigin: CFString = "DefaultCropOrigin"

public let kCGImagePropertyDNGDefaultCropSize: CFString = "DefaultCropSize"

public let kCGImagePropertyDNGDefaultScale: CFString = "DefaultScale"

public let kCGImagePropertyDNGDefaultUserCrop: CFString = "DefaultUserCrop"

public let kCGImagePropertyDNGDictionary: CFString = "{DNG}"

public let kCGImagePropertyDNGExtraCameraProfiles: CFString = "ExtraCameraProfiles"

public let kCGImagePropertyDNGFixVignetteRadial: CFString = "FixVignetteRadial"

public let kCGImagePropertyDNGForwardMatrix1: CFString = "ForwardMatrix1"

public let kCGImagePropertyDNGForwardMatrix2: CFString = "ForwardMatrix2"

public let kCGImagePropertyDNGLensInfo: CFString = "LensInfo"

public let kCGImagePropertyDNGLinearResponseLimit: CFString = "LinearResponseLimit"

public let kCGImagePropertyDNGLinearizationTable: CFString = "LinearizationTable"

public let kCGImagePropertyDNGLocalizedCameraModel: CFString = "LocalizedCameraModel"

public let kCGImagePropertyDNGMakerNoteSafety: CFString = "MakerNoteSafety"

public let kCGImagePropertyDNGMaskedAreas: CFString = "MaskedAreas"

public let kCGImagePropertyDNGNewRawImageDigest: CFString = "NewRawImageDigest"

public let kCGImagePropertyDNGNoiseProfile: CFString = "NoiseProfile"

public let kCGImagePropertyDNGNoiseReductionApplied: CFString = "NoiseReductionApplied"

public let kCGImagePropertyDNGOpcodeList1: CFString = "OpcodeList1"

public let kCGImagePropertyDNGOpcodeList2: CFString = "DNGOpcodeList2"

public let kCGImagePropertyDNGOpcodeList3: CFString = "DNGOpcodeList3"

public let kCGImagePropertyDNGOriginalBestQualityFinalSize: CFString = "OriginalBestQualityFinalSize"

public let kCGImagePropertyDNGOriginalDefaultCropSize: CFString = "OriginalDefaultCropSize"

public let kCGImagePropertyDNGOriginalDefaultFinalSize: CFString = "OriginalDefaultFinalSize"

public let kCGImagePropertyDNGOriginalRawFileData: CFString = "OriginalRawFileData"

public let kCGImagePropertyDNGOriginalRawFileDigest: CFString = "OriginalRawFileDigest"

public let kCGImagePropertyDNGOriginalRawFileName: CFString = "OriginalRawFileName"

public let kCGImagePropertyDNGPreviewApplicationName: CFString = "PreviewApplicationName"

public let kCGImagePropertyDNGPreviewApplicationVersion: CFString = "PreviewApplicationVersion"

public let kCGImagePropertyDNGPreviewColorSpace: CFString = "PreviewColorSpace"

public let kCGImagePropertyDNGPreviewDateTime: CFString = "PreviewDateTime"

public let kCGImagePropertyDNGPreviewSettingsDigest: CFString = "PreviewSettingsDigest"

public let kCGImagePropertyDNGPreviewSettingsName: CFString = "PreviewSettingsName"

public let kCGImagePropertyDNGPrivateData: CFString = "DNGPrivateData"

public let kCGImagePropertyDNGProfileCalibrationSignature: CFString = "ProfileCalibrationSignature"

public let kCGImagePropertyDNGProfileCopyright: CFString = "ProfileCopyright"

public let kCGImagePropertyDNGProfileEmbedPolicy: CFString = "ProfileEmbedPolicy"

public let kCGImagePropertyDNGProfileHueSatMapData1: CFString = "ProfileHueSatMapData1"

public let kCGImagePropertyDNGProfileHueSatMapData2: CFString = "ProfileHueSatMapData2"

public let kCGImagePropertyDNGProfileHueSatMapDims: CFString = "ProfileHueSatMapDims"

public let kCGImagePropertyDNGProfileHueSatMapEncoding: CFString = "ProfileHueSatMapEncoding"

public let kCGImagePropertyDNGProfileLookTableData: CFString = "ProfileLookTableData"

public let kCGImagePropertyDNGProfileLookTableDims: CFString = "ProfileLookTableDims"

public let kCGImagePropertyDNGProfileLookTableEncoding: CFString = "ProfileLookTableEncoding"

public let kCGImagePropertyDNGProfileName: CFString = "DNGProfileName"

public let kCGImagePropertyDNGProfileToneCurve: CFString = "ProfileToneCurve"

public let kCGImagePropertyDNGRawDataUniqueID: CFString = "DNGRawDataUniqueID"

public let kCGImagePropertyDNGRawImageDigest: CFString = "RawImageDigest"

public let kCGImagePropertyDNGRawToPreviewGain: CFString = "RawToPreviewGain"

public let kCGImagePropertyDNGReductionMatrix1: CFString = "ReductionMatrix1"

public let kCGImagePropertyDNGReductionMatrix2: CFString = "ReductionMatrix2"

public let kCGImagePropertyDNGRowInterleaveFactor: CFString = "RowInterleaveFactor"

public let kCGImagePropertyDNGShadowScale: CFString = "ShadowScale"

public let kCGImagePropertyDNGSubTileBlockSize: CFString = "SubTileBlockSize"

public let kCGImagePropertyDNGUniqueCameraModel: CFString = "UniqueCameraModel"

public let kCGImagePropertyDNGVersion: CFString = "DNGVersion"

public let kCGImagePropertyDNGWarpFisheye: CFString = "WarpFisheye"

public let kCGImagePropertyDNGWarpRectilinear: CFString = "WarpRectilinear"

public let kCGImagePropertyDNGWhiteLevel: CFString = "WhiteLevel"

public let kCGImagePropertyDPIHeight: CFString = "DPIHeight"

public let kCGImagePropertyDPIWidth: CFString = "DPIWidth"

public let kCGImagePropertyDepth: CFString = "Depth"

public let kCGImagePropertyEncoder: CFString = "kCGImagePropertyEncoder"

public let kCGImagePropertyExifApertureValue: CFString = "ApertureValue"

public let kCGImagePropertyExifAuxDictionary: CFString = "{ExifAux}"

public let kCGImagePropertyExifAuxFirmware: CFString = "Firmware"

public let kCGImagePropertyExifAuxFlashCompensation: CFString = "FlashCompensation"

public let kCGImagePropertyExifAuxImageNumber: CFString = "ImageNumber"

public let kCGImagePropertyExifAuxLensID: CFString = "LensID"

public let kCGImagePropertyExifAuxLensInfo: CFString = "LensInfo"

public let kCGImagePropertyExifAuxLensModel: CFString = "LensModel"

public let kCGImagePropertyExifAuxLensSerialNumber: CFString = "LensSerialNumber"

public let kCGImagePropertyExifAuxOwnerName: CFString = "OwnerName"

public let kCGImagePropertyExifAuxSerialNumber: CFString = "SerialNumber"

public let kCGImagePropertyExifBodySerialNumber: CFString = "BodySerialNumber"

public let kCGImagePropertyExifBrightnessValue: CFString = "BrightnessValue"

public let kCGImagePropertyExifCFAPattern: CFString = "CFAPattern"

public let kCGImagePropertyExifCameraOwnerName: CFString = "CameraOwnerName"

public let kCGImagePropertyExifColorSpace: CFString = "ColorSpace"

public let kCGImagePropertyExifComponentsConfiguration: CFString = "ComponentsConfiguration"

public let kCGImagePropertyExifCompositeImage: CFString = "CompositeImage"

public let kCGImagePropertyExifCompressedBitsPerPixel: CFString = "CompressedBitsPerPixel"

public let kCGImagePropertyExifContrast: CFString = "Contrast"

public let kCGImagePropertyExifCustomRendered: CFString = "CustomRendered"

public let kCGImagePropertyExifDateTimeDigitized: CFString = "DateTimeDigitized"

public let kCGImagePropertyExifDateTimeOriginal: CFString = "DateTimeOriginal"

public let kCGImagePropertyExifDeviceSettingDescription: CFString = "DeviceSettingDescription"

public let kCGImagePropertyExifDictionary: CFString = "{Exif}"

public let kCGImagePropertyExifDigitalZoomRatio: CFString = "DigitalZoomRatio"

public let kCGImagePropertyExifExposureBiasValue: CFString = "ExposureBiasValue"

public let kCGImagePropertyExifExposureIndex: CFString = "ExposureIndex"

public let kCGImagePropertyExifExposureMode: CFString = "ExposureMode"

public let kCGImagePropertyExifExposureProgram: CFString = "ExposureProgram"

public let kCGImagePropertyExifExposureTime: CFString = "ExposureTime"

public let kCGImagePropertyExifFNumber: CFString = "FNumber"

public let kCGImagePropertyExifFileSource: CFString = "FileSource"

public let kCGImagePropertyExifFlash: CFString = "Flash"

public let kCGImagePropertyExifFlashEnergy: CFString = "FlashEnergy"

public let kCGImagePropertyExifFlashPixVersion: CFString = "FlashPixVersion"

public let kCGImagePropertyExifFocalLenIn35mmFilm: CFString = "FocalLenIn35mmFilm"

public let kCGImagePropertyExifFocalLength: CFString = "FocalLength"

public let kCGImagePropertyExifFocalPlaneResolutionUnit: CFString = "FocalPlaneResolutionUnit"

public let kCGImagePropertyExifFocalPlaneXResolution: CFString = "FocalPlaneXResolution"

public let kCGImagePropertyExifFocalPlaneYResolution: CFString = "FocalPlaneYResolution"

public let kCGImagePropertyExifGainControl: CFString = "GainControl"

public let kCGImagePropertyExifGamma: CFString = "Gamma"

public let kCGImagePropertyExifISOSpeed: CFString = "ISOSpeed"

public let kCGImagePropertyExifISOSpeedLatitudeyyy: CFString = "ISOSpeedLatitudeyyy"

public let kCGImagePropertyExifISOSpeedLatitudezzz: CFString = "ISOSpeedLatitudezzz"

public let kCGImagePropertyExifISOSpeedRatings: CFString = "ISOSpeedRatings"

public let kCGImagePropertyExifImageUniqueID: CFString = "ImageUniqueID"

public let kCGImagePropertyExifLensMake: CFString = "LensMake"

public let kCGImagePropertyExifLensModel: CFString = "LensModel"

public let kCGImagePropertyExifLensSerialNumber: CFString = "LensSerialNumber"

public let kCGImagePropertyExifLensSpecification: CFString = "LensSpecification"

public let kCGImagePropertyExifLightSource: CFString = "LightSource"

public let kCGImagePropertyExifMakerNote: CFString = "MakerNote"

public let kCGImagePropertyExifMaxApertureValue: CFString = "MaxApertureValue"

public let kCGImagePropertyExifMeteringMode: CFString = "MeteringMode"

public let kCGImagePropertyExifOECF: CFString = "OECF"

public let kCGImagePropertyExifOffsetTime: CFString = "OffsetTime"

public let kCGImagePropertyExifOffsetTimeDigitized: CFString = "OffsetTimeDigitized"

public let kCGImagePropertyExifOffsetTimeOriginal: CFString = "OffsetTimeOriginal"

public let kCGImagePropertyExifPixelXDimension: CFString = "PixelXDimension"

public let kCGImagePropertyExifPixelYDimension: CFString = "PixelYDimension"

public let kCGImagePropertyExifRecommendedExposureIndex: CFString = "RecommendedExposureIndex"

public let kCGImagePropertyExifRelatedSoundFile: CFString = "RelatedSoundFile"

public let kCGImagePropertyExifSaturation: CFString = "Saturation"

public let kCGImagePropertyExifSceneCaptureType: CFString = "SceneCaptureType"

public let kCGImagePropertyExifSceneType: CFString = "SceneType"

public let kCGImagePropertyExifSensingMethod: CFString = "SensingMethod"

public let kCGImagePropertyExifSensitivityType: CFString = "SensitivityType"

public let kCGImagePropertyExifSharpness: CFString = "Sharpness"

public let kCGImagePropertyExifShutterSpeedValue: CFString = "ShutterSpeedValue"

public let kCGImagePropertyExifSourceExposureTimesOfCompositeImage: CFString = "SourceExposureTimesOfCompositeImage"

public let kCGImagePropertyExifSourceImageNumberOfCompositeImage: CFString = "SourceImageNumberOfCompositeImage"

public let kCGImagePropertyExifSpatialFrequencyResponse: CFString = "SpatialFrequencyResponse"

public let kCGImagePropertyExifSpectralSensitivity: CFString = "SpectralSensitivity"

public let kCGImagePropertyExifStandardOutputSensitivity: CFString = "StandardOutputSensitivity"

public let kCGImagePropertyExifSubjectArea: CFString = "SubjectArea"

public let kCGImagePropertyExifSubjectDistRange: CFString = "SubjectDistRange"

public let kCGImagePropertyExifSubjectDistance: CFString = "SubjectDistance"

public let kCGImagePropertyExifSubjectLocation: CFString = "SubjectLocation"

public let kCGImagePropertyExifSubsecTime: CFString = "SubsecTime"

public let kCGImagePropertyExifSubsecTimeDigitized: CFString = "SubsecTimeDigitized"

public let kCGImagePropertyExifSubsecTimeOrginal: CFString = "SubsecTimeOriginal"

public let kCGImagePropertyExifSubsecTimeOriginal: CFString = "SubsecTimeOriginal"

public let kCGImagePropertyExifUserComment: CFString = "UserComment"

public let kCGImagePropertyExifVersion: CFString = "ExifVersion"

public let kCGImagePropertyExifWhiteBalance: CFString = "WhiteBalance"

public let kCGImagePropertyFileContentsDictionary: CFString = "{FileContents}"

public let kCGImagePropertyFileSize: CFString = "FileSize"

public let kCGImagePropertyGIFCanvasPixelHeight: CFString = "CanvasPixelHeight"

public let kCGImagePropertyGIFCanvasPixelWidth: CFString = "CanvasPixelWidth"

public let kCGImagePropertyGIFDelayTime: CFString = "DelayTime"

public let kCGImagePropertyGIFDictionary: CFString = "{GIF}"

public let kCGImagePropertyGIFFrameInfoArray: CFString = "FrameInfo"

public let kCGImagePropertyGIFHasGlobalColorMap: CFString = "HasGlobalColorMap"

public let kCGImagePropertyGIFImageColorMap: CFString = "ImageColorMap"

public let kCGImagePropertyGIFLoopCount: CFString = "LoopCount"

public let kCGImagePropertyGIFUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyGPSAltitude: CFString = "Altitude"

public let kCGImagePropertyGPSAltitudeRef: CFString = "AltitudeRef"

public let kCGImagePropertyGPSAreaInformation: CFString = "AreaInformation"

public let kCGImagePropertyGPSDOP: CFString = "DOP"

public let kCGImagePropertyGPSDateStamp: CFString = "DateStamp"

public let kCGImagePropertyGPSDestBearing: CFString = "DestBearing"

public let kCGImagePropertyGPSDestBearingRef: CFString = "DestBearingRef"

public let kCGImagePropertyGPSDestDistance: CFString = "DestDistance"

public let kCGImagePropertyGPSDestDistanceRef: CFString = "DestDistanceRef"

public let kCGImagePropertyGPSDestLatitude: CFString = "DestLatitude"

public let kCGImagePropertyGPSDestLatitudeRef: CFString = "DestLatitudeRef"

public let kCGImagePropertyGPSDestLongitude: CFString = "DestLongitude"

public let kCGImagePropertyGPSDestLongitudeRef: CFString = "DestLongitudeRef"

public let kCGImagePropertyGPSDictionary: CFString = "{GPS}"

public let kCGImagePropertyGPSDifferental: CFString = "Differential"

public let kCGImagePropertyGPSHPositioningError: CFString = "HPositioningError"

public let kCGImagePropertyGPSImgDirection: CFString = "ImgDirection"

public let kCGImagePropertyGPSImgDirectionRef: CFString = "ImgDirectionRef"

public let kCGImagePropertyGPSLatitude: CFString = "Latitude"

public let kCGImagePropertyGPSLatitudeRef: CFString = "LatitudeRef"

public let kCGImagePropertyGPSLongitude: CFString = "Longitude"

public let kCGImagePropertyGPSLongitudeRef: CFString = "LongitudeRef"

public let kCGImagePropertyGPSMapDatum: CFString = "MapDatum"

public let kCGImagePropertyGPSMeasureMode: CFString = "MeasureMode"

public let kCGImagePropertyGPSProcessingMethod: CFString = "ProcessingMethod"

public let kCGImagePropertyGPSSatellites: CFString = "Satellites"

public let kCGImagePropertyGPSSpeed: CFString = "Speed"

public let kCGImagePropertyGPSSpeedRef: CFString = "SpeedRef"

public let kCGImagePropertyGPSStatus: CFString = "Status"

public let kCGImagePropertyGPSTimeStamp: CFString = "TimeStamp"

public let kCGImagePropertyGPSTrack: CFString = "Track"

public let kCGImagePropertyGPSTrackRef: CFString = "TrackRef"

public let kCGImagePropertyGPSVersion: CFString = "GPSVersion"

public let kCGImagePropertyGroupImageBaseline: CFString = "GroupImageBaseline"

public let kCGImagePropertyGroupImageDisparityAdjustment: CFString = "GroupImageDisparityAdjustment"

public let kCGImagePropertyGroupImageIndexLeft: CFString = "GroupImageIndexLeft"

public let kCGImagePropertyGroupImageIndexMonoscopic: CFString = "GroupImageIndexMonoscopic"

public let kCGImagePropertyGroupImageIndexRight: CFString = "GroupImageIndexRight"

public let kCGImagePropertyGroupImageIsAlternateImage: CFString = "GroupImageIsAlternateImage"

public let kCGImagePropertyGroupImageIsLeftImage: CFString = "GroupImageIsLeftImage"

public let kCGImagePropertyGroupImageIsMonoscopicImage: CFString = "GroupImageIsMonoscopicImage"

public let kCGImagePropertyGroupImageIsRightImage: CFString = "GroupImageIsRightImage"

public let kCGImagePropertyGroupImageStereoAggressors: CFString = "GroupImageStereoAggressors"

public let kCGImagePropertyGroupImagesAlternate: CFString = "GroupImages"

public let kCGImagePropertyGroupIndex: CFString = "GroupIndex"

public let kCGImagePropertyGroupMonoscopicImageLocation: CFString = "GroupImageIndexMonoscopicImageLocation"

public let kCGImagePropertyGroupType: CFString = "GroupType"

public let kCGImagePropertyGroupTypeAlternate: CFString = "Alternate"

public let kCGImagePropertyGroupTypeStereoPair: CFString = "StereoPair"

public let kCGImagePropertyGroups: CFString = "{Groups}"

public let kCGImagePropertyHEICSCanvasPixelHeight: CFString = "CanvasPixelHeight"

public let kCGImagePropertyHEICSCanvasPixelWidth: CFString = "CanvasPixelWidth"

public let kCGImagePropertyHEICSDelayTime: CFString = "DelayTime"

public let kCGImagePropertyHEICSDictionary: CFString = "{HEICS}"

public let kCGImagePropertyHEICSFrameInfoArray: CFString = "FrameInfo"

public let kCGImagePropertyHEICSLoopCount: CFString = "LoopCount"

public let kCGImagePropertyHEICSUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyHEIFDictionary: CFString = "{HEIF}"

public let kCGImagePropertyHasAlpha: CFString = "HasAlpha"

public let kCGImagePropertyHeight: CFString = "Height"

public let kCGImagePropertyIPTCActionAdvised: CFString = "ActionAdvised"

public let kCGImagePropertyIPTCByline: CFString = "Byline"

public let kCGImagePropertyIPTCBylineTitle: CFString = "BylineTitle"

public let kCGImagePropertyIPTCCaptionAbstract: CFString = "Caption/Abstract"

public let kCGImagePropertyIPTCCategory: CFString = "Category"

public let kCGImagePropertyIPTCCity: CFString = "City"

public let kCGImagePropertyIPTCContact: CFString = "Contact"

public let kCGImagePropertyIPTCContactInfoAddress: CFString = "CiAdrExtadr"

public let kCGImagePropertyIPTCContactInfoCity: CFString = "CiAdrCity"

public let kCGImagePropertyIPTCContactInfoCountry: CFString = "CiAdrCtry"

public let kCGImagePropertyIPTCContactInfoEmails: CFString = "CiEmailWork"

public let kCGImagePropertyIPTCContactInfoPhones: CFString = "CiTelWork"

public let kCGImagePropertyIPTCContactInfoPostalCode: CFString = "CiAdrPcode"

public let kCGImagePropertyIPTCContactInfoStateProvince: CFString = "CiAdrRegion"

public let kCGImagePropertyIPTCContactInfoWebURLs: CFString = "CiUrlWork"

public let kCGImagePropertyIPTCContentLocationCode: CFString = "ContentLocationCode"

public let kCGImagePropertyIPTCContentLocationName: CFString = "ContentLocationName"

public let kCGImagePropertyIPTCCopyrightNotice: CFString = "CopyrightNotice"

public let kCGImagePropertyIPTCCountryPrimaryLocationCode: CFString = "Country/PrimaryLocationCode"

public let kCGImagePropertyIPTCCountryPrimaryLocationName: CFString = "Country/PrimaryLocationName"

public let kCGImagePropertyIPTCCreatorContactInfo: CFString = "CreatorContactInfo"

public let kCGImagePropertyIPTCCredit: CFString = "Credit"

public let kCGImagePropertyIPTCDateCreated: CFString = "DateCreated"

public let kCGImagePropertyIPTCDictionary: CFString = "{IPTC}"

public let kCGImagePropertyIPTCDigitalCreationDate: CFString = "DigitalCreationDate"

public let kCGImagePropertyIPTCDigitalCreationTime: CFString = "DigitalCreationTime"

public let kCGImagePropertyIPTCEditStatus: CFString = "EditStatus"

public let kCGImagePropertyIPTCEditorialUpdate: CFString = "EditorialUpdate"

public let kCGImagePropertyIPTCExpirationDate: CFString = "ExpirationDate"

public let kCGImagePropertyIPTCExpirationTime: CFString = "ExpirationTime"

public let kCGImagePropertyIPTCExtAboutCvTerm: CFString = "AboutCvTerm"

public let kCGImagePropertyIPTCExtAboutCvTermCvId: CFString = "AboutCvTermCvId"

public let kCGImagePropertyIPTCExtAboutCvTermId: CFString = "AboutCvTermId"

public let kCGImagePropertyIPTCExtAboutCvTermName: CFString = "AboutCvTermName"

public let kCGImagePropertyIPTCExtAboutCvTermRefinedAbout: CFString = "AboutCvTermRefinedAbout"

public let kCGImagePropertyIPTCExtAddlModelInfo: CFString = "AddlModelInfo"

public let kCGImagePropertyIPTCExtArtworkCircaDateCreated: CFString = "ArtworkCircaDateCreated"

public let kCGImagePropertyIPTCExtArtworkContentDescription: CFString = "ArtworkContentDescription"

public let kCGImagePropertyIPTCExtArtworkContributionDescription: CFString = "ArtworkContributionDescription"

public let kCGImagePropertyIPTCExtArtworkCopyrightNotice: CFString = "ArtworkCopyrightNotice"

public let kCGImagePropertyIPTCExtArtworkCopyrightOwnerID: CFString = "ArtworkCopyrightOwnerID"

public let kCGImagePropertyIPTCExtArtworkCopyrightOwnerName: CFString = "ArtworkCopyrightOwnerName"

public let kCGImagePropertyIPTCExtArtworkCreator: CFString = "ArtworkCreator"

public let kCGImagePropertyIPTCExtArtworkCreatorID: CFString = "ArtworkCreatorID"

public let kCGImagePropertyIPTCExtArtworkDateCreated: CFString = "ArtworkDateCreated"

public let kCGImagePropertyIPTCExtArtworkLicensorID: CFString = "ArtworkLicensorID"

public let kCGImagePropertyIPTCExtArtworkLicensorName: CFString = "ArtworkLicensorName"

public let kCGImagePropertyIPTCExtArtworkOrObject: CFString = "ArtworkOrObject"

public let kCGImagePropertyIPTCExtArtworkPhysicalDescription: CFString = "ArtworkPhysicalDescription"

public let kCGImagePropertyIPTCExtArtworkSource: CFString = "ArtworkSource"

public let kCGImagePropertyIPTCExtArtworkSourceInvURL: CFString = "ArtworkSourceInvURL"

public let kCGImagePropertyIPTCExtArtworkSourceInventoryNo: CFString = "ArtworkSourceInventoryNo"

public let kCGImagePropertyIPTCExtArtworkStylePeriod: CFString = "ArtworkStylePeriod"

public let kCGImagePropertyIPTCExtArtworkTitle: CFString = "ArtworkTitle"

public let kCGImagePropertyIPTCExtAudioBitrate: CFString = "AudioBitrate"

public let kCGImagePropertyIPTCExtAudioBitrateMode: CFString = "AudioBitrateMode"

public let kCGImagePropertyIPTCExtAudioChannelCount: CFString = "AudioChannelCount"

public let kCGImagePropertyIPTCExtCircaDateCreated: CFString = "CircaDateCreated"

public let kCGImagePropertyIPTCExtContainerFormat: CFString = "ContainerFormat"

public let kCGImagePropertyIPTCExtContainerFormatIdentifier: CFString = "ContainerFormatIdentifier"

public let kCGImagePropertyIPTCExtContainerFormatName: CFString = "ContainerFormatName"

public let kCGImagePropertyIPTCExtContributor: CFString = "Contributor"

public let kCGImagePropertyIPTCExtContributorIdentifier: CFString = "ContributorIdentifier"

public let kCGImagePropertyIPTCExtContributorName: CFString = "ContributorName"

public let kCGImagePropertyIPTCExtContributorRole: CFString = "ContributorRole"

public let kCGImagePropertyIPTCExtControlledVocabularyTerm: CFString = "ControlledVocabularyTerm"

public let kCGImagePropertyIPTCExtCopyrightYear: CFString = "CopyrightYear"

public let kCGImagePropertyIPTCExtCreator: CFString = "Creator"

public let kCGImagePropertyIPTCExtCreatorIdentifier: CFString = "CreatorIdentifier"

public let kCGImagePropertyIPTCExtCreatorName: CFString = "CreatorName"

public let kCGImagePropertyIPTCExtCreatorRole: CFString = "CreatorRole"

public let kCGImagePropertyIPTCExtDataOnScreen: CFString = "DataOnScreen"

public let kCGImagePropertyIPTCExtDataOnScreenRegion: CFString = "DataOnScreenRegion"

public let kCGImagePropertyIPTCExtDataOnScreenRegionD: CFString = "DataOnScreenRegionD"

public let kCGImagePropertyIPTCExtDataOnScreenRegionH: CFString = "DataOnScreenRegionH"

public let kCGImagePropertyIPTCExtDataOnScreenRegionText: CFString = "DataOnScreenRegionText"

public let kCGImagePropertyIPTCExtDataOnScreenRegionUnit: CFString = "DataOnScreenRegionUnit"

public let kCGImagePropertyIPTCExtDataOnScreenRegionW: CFString = "DataOnScreenRegionW"

public let kCGImagePropertyIPTCExtDataOnScreenRegionX: CFString = "DataOnScreenRegionX"

public let kCGImagePropertyIPTCExtDataOnScreenRegionY: CFString = "DataOnScreenRegionY"

public let kCGImagePropertyIPTCExtDigitalImageGUID: CFString = "DigitalImageGUID"

public let kCGImagePropertyIPTCExtDigitalSourceFileType: CFString = "DigitalSourceFileType"

public let kCGImagePropertyIPTCExtDigitalSourceType: CFString = "DigitalSourceType"

public let kCGImagePropertyIPTCExtDopesheet: CFString = "Dopesheet"

public let kCGImagePropertyIPTCExtDopesheetLink: CFString = "DopesheetLink"

public let kCGImagePropertyIPTCExtDopesheetLinkLink: CFString = "DopesheetLinkLink"

public let kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier: CFString = "DopesheetLinkLinkQualifier"

public let kCGImagePropertyIPTCExtEmbdEncRightsExpr: CFString = "EmbdEncRightsExpr"

public let kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr: CFString = "EmbeddedEncodedRightsExpr"

public let kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID: CFString = "EmbeddedEncodedRightsExprLangID"

public let kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType: CFString = "EmbeddedEncodedRightsExprType"

public let kCGImagePropertyIPTCExtEpisode: CFString = "Episode"

public let kCGImagePropertyIPTCExtEpisodeIdentifier: CFString = "EpisodeIdentifier"

public let kCGImagePropertyIPTCExtEpisodeName: CFString = "EpisodeName"

public let kCGImagePropertyIPTCExtEpisodeNumber: CFString = "EpisodeNumber"

public let kCGImagePropertyIPTCExtEvent: CFString = "Event"

public let kCGImagePropertyIPTCExtExternalMetadataLink: CFString = "ExternalMetadataLink"

public let kCGImagePropertyIPTCExtFeedIdentifier: CFString = "FeedIdentifier"

public let kCGImagePropertyIPTCExtGenre: CFString = "Genre"

public let kCGImagePropertyIPTCExtGenreCvId: CFString = "GenreCvId"

public let kCGImagePropertyIPTCExtGenreCvTermId: CFString = "GenreCvTermId"

public let kCGImagePropertyIPTCExtGenreCvTermName: CFString = "GenreCvTermName"

public let kCGImagePropertyIPTCExtGenreCvTermRefinedAbout: CFString = "GenreCvTermRefinedAbout"

public let kCGImagePropertyIPTCExtHeadline: CFString = "Headline"

public let kCGImagePropertyIPTCExtIPTCLastEdited: CFString = "IPTCLastEdited"

public let kCGImagePropertyIPTCExtLinkedEncRightsExpr: CFString = "LinkedEncRightsExpr"

public let kCGImagePropertyIPTCExtLinkedEncodedRightsExpr: CFString = "LinkedEncodedRightsExpr"

public let kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID: CFString = "LinkedEncodedRightsExprLangID"

public let kCGImagePropertyIPTCExtLinkedEncodedRightsExprType: CFString = "LinkedEncodedRightsExprType"

public let kCGImagePropertyIPTCExtLocationCity: CFString = "City"

public let kCGImagePropertyIPTCExtLocationCountryCode: CFString = "CountryCode"

public let kCGImagePropertyIPTCExtLocationCountryName: CFString = "CountryName"

public let kCGImagePropertyIPTCExtLocationCreated: CFString = "LocationCreated"

public let kCGImagePropertyIPTCExtLocationGPSAltitude: CFString = "GPSAltitude"

public let kCGImagePropertyIPTCExtLocationGPSLatitude: CFString = "GPSLatitude"

public let kCGImagePropertyIPTCExtLocationGPSLongitude: CFString = "GPSLongitude"

public let kCGImagePropertyIPTCExtLocationIdentifier: CFString = "Identifier"

public let kCGImagePropertyIPTCExtLocationLocationId: CFString = "LocationId"

public let kCGImagePropertyIPTCExtLocationLocationName: CFString = "LocationName"

public let kCGImagePropertyIPTCExtLocationProvinceState: CFString = "ProvinceState"

public let kCGImagePropertyIPTCExtLocationShown: CFString = "LocationShown"

public let kCGImagePropertyIPTCExtLocationSublocation: CFString = "Sublocation"

public let kCGImagePropertyIPTCExtLocationWorldRegion: CFString = "WorldRegion"

public let kCGImagePropertyIPTCExtMaxAvailHeight: CFString = "MaxAvailHeight"

public let kCGImagePropertyIPTCExtMaxAvailWidth: CFString = "MaxAvailWidth"

public let kCGImagePropertyIPTCExtModelAge: CFString = "ModelAge"

public let kCGImagePropertyIPTCExtOrganisationInImageCode: CFString = "OrganisationInImageCode"

public let kCGImagePropertyIPTCExtOrganisationInImageName: CFString = "OrganisationInImageName"

public let kCGImagePropertyIPTCExtPersonHeard: CFString = "PersonHeard"

public let kCGImagePropertyIPTCExtPersonHeardIdentifier: CFString = "PersonHeardIdentifier"

public let kCGImagePropertyIPTCExtPersonHeardName: CFString = "PersonHeardName"

public let kCGImagePropertyIPTCExtPersonInImage: CFString = "PersonInImage"

public let kCGImagePropertyIPTCExtPersonInImageCharacteristic: CFString = "PersonInImageCharacteristic"

public let kCGImagePropertyIPTCExtPersonInImageCvTermCvId: CFString = "PersonInImageCvTermCvId"

public let kCGImagePropertyIPTCExtPersonInImageCvTermId: CFString = "PersonInImageCvTermId"

public let kCGImagePropertyIPTCExtPersonInImageCvTermName: CFString = "PersonInImageCvTermName"

public let kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout: CFString = "PersonInImageCvTermRefinedAbout"

public let kCGImagePropertyIPTCExtPersonInImageDescription: CFString = "PersonInImageDescription"

public let kCGImagePropertyIPTCExtPersonInImageId: CFString = "PersonInImageId"

public let kCGImagePropertyIPTCExtPersonInImageName: CFString = "PersonInImageName"

public let kCGImagePropertyIPTCExtPersonInImageWDetails: CFString = "PersonInImageWDetails"

public let kCGImagePropertyIPTCExtProductInImage: CFString = "ProductInImage"

public let kCGImagePropertyIPTCExtProductInImageDescription: CFString = "ProductInImageDescription"

public let kCGImagePropertyIPTCExtProductInImageGTIN: CFString = "ProductInImageGTIN"

public let kCGImagePropertyIPTCExtProductInImageName: CFString = "ProductInImageName"

public let kCGImagePropertyIPTCExtPublicationEvent: CFString = "PublicationEvent"

public let kCGImagePropertyIPTCExtPublicationEventDate: CFString = "PublicationEventDate"

public let kCGImagePropertyIPTCExtPublicationEventIdentifier: CFString = "PublicationEventIdentifier"

public let kCGImagePropertyIPTCExtPublicationEventName: CFString = "PublicationEventName"

public let kCGImagePropertyIPTCExtRating: CFString = "Rating"

public let kCGImagePropertyIPTCExtRatingRatingRegion: CFString = "RatingRatingRegion"

public let kCGImagePropertyIPTCExtRatingRegionCity: CFString = "RatingRegionCity"

public let kCGImagePropertyIPTCExtRatingRegionCountryCode: CFString = "RatingRegionCountryCode"

public let kCGImagePropertyIPTCExtRatingRegionCountryName: CFString = "RatingRegionCountryName"

public let kCGImagePropertyIPTCExtRatingRegionGPSAltitude: CFString = "RatingRegionGPSAltitude"

public let kCGImagePropertyIPTCExtRatingRegionGPSLatitude: CFString = "RatingRegionGPSLatitude"

public let kCGImagePropertyIPTCExtRatingRegionGPSLongitude: CFString = "RatingRegionGPSLongitude"

public let kCGImagePropertyIPTCExtRatingRegionIdentifier: CFString = "RatingRegionIdentifier"

public let kCGImagePropertyIPTCExtRatingRegionLocationId: CFString = "RatingRegionLocationId"

public let kCGImagePropertyIPTCExtRatingRegionLocationName: CFString = "RatingRegionLocationName"

public let kCGImagePropertyIPTCExtRatingRegionProvinceState: CFString = "RatingRegionProvinceState"

public let kCGImagePropertyIPTCExtRatingRegionSublocation: CFString = "RatingRegionSublocation"

public let kCGImagePropertyIPTCExtRatingRegionWorldRegion: CFString = "RatingRegionWorldRegion"

public let kCGImagePropertyIPTCExtRatingScaleMaxValue: CFString = "RatingScaleMaxValue"

public let kCGImagePropertyIPTCExtRatingScaleMinValue: CFString = "RatingScaleMinValue"

public let kCGImagePropertyIPTCExtRatingSourceLink: CFString = "RatingSourceLink"

public let kCGImagePropertyIPTCExtRatingValue: CFString = "RatingValue"

public let kCGImagePropertyIPTCExtRatingValueLogoLink: CFString = "RatingValueLogoLink"

public let kCGImagePropertyIPTCExtRegistryEntryRole: CFString = "RegistryEntryRole"

public let kCGImagePropertyIPTCExtRegistryID: CFString = "RegistryID"

public let kCGImagePropertyIPTCExtRegistryItemID: CFString = "RegistryItemID"

public let kCGImagePropertyIPTCExtRegistryOrganisationID: CFString = "RegistryOrganisationID"

public let kCGImagePropertyIPTCExtReleaseReady: CFString = "ReleaseReady"

public let kCGImagePropertyIPTCExtSeason: CFString = "Season"

public let kCGImagePropertyIPTCExtSeasonIdentifier: CFString = "SeasonIdentifier"

public let kCGImagePropertyIPTCExtSeasonName: CFString = "SeasonName"

public let kCGImagePropertyIPTCExtSeasonNumber: CFString = "SeasonNumber"

public let kCGImagePropertyIPTCExtSeries: CFString = "Series"

public let kCGImagePropertyIPTCExtSeriesIdentifier: CFString = "SeriesIdentifier"

public let kCGImagePropertyIPTCExtSeriesName: CFString = "SeriesName"

public let kCGImagePropertyIPTCExtShownEvent: CFString = "ShownEvent"

public let kCGImagePropertyIPTCExtShownEventIdentifier: CFString = "ShownEventIdentifier"

public let kCGImagePropertyIPTCExtShownEventName: CFString = "ShownEventName"

public let kCGImagePropertyIPTCExtStorylineIdentifier: CFString = "StorylineIdentifier"

public let kCGImagePropertyIPTCExtStreamReady: CFString = "StreamReady"

public let kCGImagePropertyIPTCExtStylePeriod: CFString = "StylePeriod"

public let kCGImagePropertyIPTCExtSupplyChainSource: CFString = "SupplyChainSource"

public let kCGImagePropertyIPTCExtSupplyChainSourceIdentifier: CFString = "SupplyChainSourceIdentifier"

public let kCGImagePropertyIPTCExtSupplyChainSourceName: CFString = "SupplyChainSourceName"

public let kCGImagePropertyIPTCExtTemporalCoverage: CFString = "TemporalCoverage"

public let kCGImagePropertyIPTCExtTemporalCoverageFrom: CFString = "TemporalCoverageFrom"

public let kCGImagePropertyIPTCExtTemporalCoverageTo: CFString = "TemporalCoverageTo"

public let kCGImagePropertyIPTCExtTranscript: CFString = "Transcript"

public let kCGImagePropertyIPTCExtTranscriptLink: CFString = "TranscriptLink"

public let kCGImagePropertyIPTCExtTranscriptLinkLink: CFString = "TranscriptLinkLink"

public let kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier: CFString = "TranscriptLinkLinkQualifier"

public let kCGImagePropertyIPTCExtVideoBitrate: CFString = "VideoBitrate"

public let kCGImagePropertyIPTCExtVideoBitrateMode: CFString = "VideoBitrateMode"

public let kCGImagePropertyIPTCExtVideoDisplayAspectRatio: CFString = "VideoDisplayAspectRatio"

public let kCGImagePropertyIPTCExtVideoEncodingProfile: CFString = "VideoEncodingProfile"

public let kCGImagePropertyIPTCExtVideoShotType: CFString = "VideoShotType"

public let kCGImagePropertyIPTCExtVideoShotTypeIdentifier: CFString = "VideoShotTypeIdentifier"

public let kCGImagePropertyIPTCExtVideoShotTypeName: CFString = "VideoShotTypeName"

public let kCGImagePropertyIPTCExtVideoStreamsCount: CFString = "VideoStreamsCount"

public let kCGImagePropertyIPTCExtVisualColor: CFString = "VisualColor"

public let kCGImagePropertyIPTCExtWorkflowTag: CFString = "WorkflowTag"

public let kCGImagePropertyIPTCExtWorkflowTagCvId: CFString = "WorkflowTagCvId"

public let kCGImagePropertyIPTCExtWorkflowTagCvTermId: CFString = "WorkflowTagCvTermId"

public let kCGImagePropertyIPTCExtWorkflowTagCvTermName: CFString = "WorkflowTagCvTermName"

public let kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout: CFString = "WorkflowTagCvTermRefinedAbout"

public let kCGImagePropertyIPTCFixtureIdentifier: CFString = "FixtureIdentifier"

public let kCGImagePropertyIPTCHeadline: CFString = "Headline"

public let kCGImagePropertyIPTCImageOrientation: CFString = "ImageOrientation"

public let kCGImagePropertyIPTCImageType: CFString = "ImageType"

public let kCGImagePropertyIPTCKeywords: CFString = "Keywords"

public let kCGImagePropertyIPTCLanguageIdentifier: CFString = "LanguageIdentifier"

public let kCGImagePropertyIPTCObjectAttributeReference: CFString = "ObjectAttributeReference"

public let kCGImagePropertyIPTCObjectCycle: CFString = "ObjectCycle"

public let kCGImagePropertyIPTCObjectName: CFString = "ObjectName"

public let kCGImagePropertyIPTCObjectTypeReference: CFString = "ObjectTypeReference"

public let kCGImagePropertyIPTCOriginalTransmissionReference: CFString = "OriginalTransmissionReference"

public let kCGImagePropertyIPTCOriginatingProgram: CFString = "OriginatingProgram"

public let kCGImagePropertyIPTCProgramVersion: CFString = "ProgramVersion"

public let kCGImagePropertyIPTCProvinceState: CFString = "Province/State"

public let kCGImagePropertyIPTCReferenceDate: CFString = "ReferenceDate"

public let kCGImagePropertyIPTCReferenceNumber: CFString = "ReferenceNumber"

public let kCGImagePropertyIPTCReferenceService: CFString = "ReferenceService"

public let kCGImagePropertyIPTCReleaseDate: CFString = "ReleaseDate"

public let kCGImagePropertyIPTCReleaseTime: CFString = "ReleaseTime"

public let kCGImagePropertyIPTCRightsUsageTerms: CFString = "UsageTerms"

public let kCGImagePropertyIPTCScene: CFString = "Scene"

public let kCGImagePropertyIPTCSource: CFString = "Source"

public let kCGImagePropertyIPTCSpecialInstructions: CFString = "SpecialInstructions"

public let kCGImagePropertyIPTCStarRating: CFString = "StarRating"

public let kCGImagePropertyIPTCSubLocation: CFString = "SubLocation"

public let kCGImagePropertyIPTCSubjectReference: CFString = "SubjectReference"

public let kCGImagePropertyIPTCSupplementalCategory: CFString = "SupplementalCategory"

public let kCGImagePropertyIPTCTimeCreated: CFString = "TimeCreated"

public let kCGImagePropertyIPTCUrgency: CFString = "Urgency"

public let kCGImagePropertyIPTCWriterEditor: CFString = "Writer/Editor"

public let kCGImagePropertyImageCount: CFString = "ImageCount"

public let kCGImagePropertyImageIndex: CFString = "ImageIndex"

public let kCGImagePropertyImages: CFString = "Images"

public let kCGImagePropertyIsFloat: CFString = "IsFloat"

public let kCGImagePropertyIsIndexed: CFString = "IsIndexed"

public let kCGImagePropertyJFIFDensityUnit: CFString = "DensityUnit"

public let kCGImagePropertyJFIFDictionary: CFString = "{JFIF}"

public let kCGImagePropertyJFIFIsProgressive: CFString = "IsProgressive"

public let kCGImagePropertyJFIFVersion: CFString = "JFIFVersion"

public let kCGImagePropertyJFIFXDensity: CFString = "XDensity"

public let kCGImagePropertyJFIFYDensity: CFString = "YDensity"

public let kCGImagePropertyMakerAppleDictionary: CFString = "{MakerApple}"

public let kCGImagePropertyMakerCanonAspectRatioInfo: CFString = "AspectRatioInfo"

public let kCGImagePropertyMakerCanonCameraSerialNumber: CFString = "CameraSerialNumber"

public let kCGImagePropertyMakerCanonContinuousDrive: CFString = "ContinuousDrive"

public let kCGImagePropertyMakerCanonDictionary: CFString = "{MakerCanon}"

public let kCGImagePropertyMakerCanonFirmware: CFString = "Firmware"

public let kCGImagePropertyMakerCanonFlashExposureComp: CFString = "FlashExposureComp"

public let kCGImagePropertyMakerCanonImageSerialNumber: CFString = "ImageSerialNumber"

public let kCGImagePropertyMakerCanonLensModel: CFString = "LensModel"

public let kCGImagePropertyMakerCanonOwnerName: CFString = "OwnerName"

public let kCGImagePropertyMakerFujiDictionary: CFString = "{MakerFuji}"

public let kCGImagePropertyMakerMinoltaDictionary: CFString = "{MakerMinolta}"

public let kCGImagePropertyMakerNikonCameraSerialNumber: CFString = "CameraSerialNumber"

public let kCGImagePropertyMakerNikonColorMode: CFString = "ColorMode"

public let kCGImagePropertyMakerNikonDictionary: CFString = "{MakerNikon}"

public let kCGImagePropertyMakerNikonDigitalZoom: CFString = "DigitalZoom"

public let kCGImagePropertyMakerNikonFlashExposureComp: CFString = "FlashExposureComp"

public let kCGImagePropertyMakerNikonFlashSetting: CFString = "FlashSetting"

public let kCGImagePropertyMakerNikonFocusDistance: CFString = "FocusDistance"

public let kCGImagePropertyMakerNikonFocusMode: CFString = "FocusMode"

public let kCGImagePropertyMakerNikonISOSelection: CFString = "ISOSelection"

public let kCGImagePropertyMakerNikonISOSetting: CFString = "ISOSetting"

public let kCGImagePropertyMakerNikonImageAdjustment: CFString = "ImageAdjustment"

public let kCGImagePropertyMakerNikonLensAdapter: CFString = "LensAdapter"

public let kCGImagePropertyMakerNikonLensInfo: CFString = "LensInfo"

public let kCGImagePropertyMakerNikonLensType: CFString = "LensType"

public let kCGImagePropertyMakerNikonQuality: CFString = "Quality"

public let kCGImagePropertyMakerNikonSharpenMode: CFString = "SharpenMode"

public let kCGImagePropertyMakerNikonShootingMode: CFString = "ShootingMode"

public let kCGImagePropertyMakerNikonShutterCount: CFString = "ShutterCount"

public let kCGImagePropertyMakerNikonWhiteBalanceMode: CFString = "WhiteBalanceMode"

public let kCGImagePropertyMakerOlympusDictionary: CFString = "{MakerOlympus}"

public let kCGImagePropertyMakerPentaxDictionary: CFString = "{MakerPentax}"

public let kCGImagePropertyNamedColorSpace: CFString = "NamedColorSpace"

public let kCGImagePropertyOpenEXRAspectRatio: CFString = "AspectRatio"

public let kCGImagePropertyOpenEXRCompression: CFString = "Compression"

public let kCGImagePropertyOpenEXRDictionary: CFString = "{EXR}"

public let kCGImagePropertyOrientation: CFString = "Orientation"

public let kCGImagePropertyPNGAuthor: CFString = "Author"

public let kCGImagePropertyPNGChromaticities: CFString = "Chromaticities"

public let kCGImagePropertyPNGComment: CFString = "Comment"

public let kCGImagePropertyPNGCompressionFilter: CFString = "kCGImagePropertyPNGCompressionFilter"

public let kCGImagePropertyPNGCopyright: CFString = "Copyright"

public let kCGImagePropertyPNGCreationTime: CFString = "Creation Time"

public let kCGImagePropertyPNGDescription: CFString = "Description"

public let kCGImagePropertyPNGDictionary: CFString = "{PNG}"

public let kCGImagePropertyPNGDisclaimer: CFString = "Disclaimer"

public let kCGImagePropertyPNGGamma: CFString = "Gamma"

public let kCGImagePropertyPNGInterlaceType: CFString = "InterlaceType"

public let kCGImagePropertyPNGModificationTime: CFString = "ModificationTime"

public let kCGImagePropertyPNGPixelsAspectRatio: CFString = "PixelAspectRatio"

public let kCGImagePropertyPNGSoftware: CFString = "Software"

public let kCGImagePropertyPNGSource: CFString = "Source"

public let kCGImagePropertyPNGTitle: CFString = "Title"

public let kCGImagePropertyPNGTransparency: CFString = "kCGImagePropertyPNGTransparency"

public let kCGImagePropertyPNGWarning: CFString = "Warning"

public let kCGImagePropertyPNGXPixelsPerMeter: CFString = "XPixelsPerMeter"

public let kCGImagePropertyPNGYPixelsPerMeter: CFString = "YPixelsPerMeter"

public let kCGImagePropertyPNGsRGBIntent: CFString = "sRGBIntent"

public let kCGImagePropertyPVREncoder: CFString = "kCGImagePropertyPVREncoder"

public let kCGImagePropertyPixelFormat: CFString = "PixelFormat"

public let kCGImagePropertyPixelHeight: CFString = "PixelHeight"

public let kCGImagePropertyPixelWidth: CFString = "PixelWidth"

public let kCGImagePropertyPrimaryImage: CFString = "PrimaryImage"

public let kCGImagePropertyProfileName: CFString = "ProfileName"

public let kCGImagePropertyRawDictionary: CFString = "{Raw}"

public let kCGImagePropertyTGACompression: CFString = "Compression"

public let kCGImagePropertyTGADictionary: CFString = "{TGA}"

public let kCGImagePropertyTIFFArtist: CFString = "Artist"

public let kCGImagePropertyTIFFCompression: CFString = "Compression"

public let kCGImagePropertyTIFFCopyright: CFString = "Copyright"

public let kCGImagePropertyTIFFDateTime: CFString = "DateTime"

public let kCGImagePropertyTIFFDictionary: CFString = "{TIFF}"

public let kCGImagePropertyTIFFDocumentName: CFString = "DocumentName"

public let kCGImagePropertyTIFFHostComputer: CFString = "HostComputer"

public let kCGImagePropertyTIFFImageDescription: CFString = "ImageDescription"

public let kCGImagePropertyTIFFMake: CFString = "Make"

public let kCGImagePropertyTIFFModel: CFString = "Model"

public let kCGImagePropertyTIFFOrientation: CFString = "Orientation"

public let kCGImagePropertyTIFFPhotometricInterpretation: CFString = "PhotometricInterpretation"

public let kCGImagePropertyTIFFPrimaryChromaticities: CFString = "PrimaryChromaticities"

public let kCGImagePropertyTIFFResolutionUnit: CFString = "ResolutionUnit"

public let kCGImagePropertyTIFFSoftware: CFString = "Software"

public let kCGImagePropertyTIFFTileLength: CFString = "TileLength"

public let kCGImagePropertyTIFFTileWidth: CFString = "TileWidth"

public let kCGImagePropertyTIFFTransferFunction: CFString = "TransferFunction"

public let kCGImagePropertyTIFFWhitePoint: CFString = "WhitePoint"

public let kCGImagePropertyTIFFXPosition: CFString = "XPosition"

public let kCGImagePropertyTIFFXResolution: CFString = "XResolution"

public let kCGImagePropertyTIFFYPosition: CFString = "YPosition"

public let kCGImagePropertyTIFFYResolution: CFString = "YResolution"

public let kCGImagePropertyThumbnailImages: CFString = "ThumbnailImages"

public let kCGImagePropertyWebPCanvasPixelHeight: CFString = "CanvasPixelHeight"

public let kCGImagePropertyWebPCanvasPixelWidth: CFString = "CanvasPixelWidth"

public let kCGImagePropertyWebPDelayTime: CFString = "DelayTime"

public let kCGImagePropertyWebPDictionary: CFString = "{WebP}"

public let kCGImagePropertyWebPFrameInfoArray: CFString = "FrameInfo"

public let kCGImagePropertyWebPLoopCount: CFString = "LoopCount"

public let kCGImagePropertyWebPUnclampedDelayTime: CFString = "UnclampedDelayTime"

public let kCGImagePropertyWidth: CFString = "Width"

public let kCGImageProviderPreferredTileHeight: CFString = "kCGImageProviderPreferredTileHeight"

public let kCGImageProviderPreferredTileWidth: CFString = "kCGImageProviderPreferredTileWidth"

public let kCGImageSourceCreateThumbnailFromImageAlways: CFString = "kCGImageSourceCreateThumbnailFromImageAlways"

public let kCGImageSourceCreateThumbnailFromImageIfAbsent: CFString = "kCGImageSourceCreateThumbnailFromImageIfAbsent"

public let kCGImageSourceCreateThumbnailWithTransform: CFString = "kCGImageSourceCreateThumbnailWithTransform"

public let kCGImageSourceDecodeRequest: CFString = "kCGImageSourceDecodeRequest"

public let kCGImageSourceDecodeRequestOptions: CFString = "kCGImageSourceDecodeRequestOptions"

public let kCGImageSourceDecodeToHDR: CFString = "kCGImageSourceDecodeToHDR"

public let kCGImageSourceDecodeToSDR: CFString = "kCGImageSourceDecodeToSDR"

public let kCGImageSourceGenerateImageSpecificLumaScaling: CFString = "kCGImageSourceGenerateImageSpecificLumaScaling"

public let kCGImageSourceShouldAllowFloat: CFString = "kCGImageSourceShouldAllowFloat"

public let kCGImageSourceShouldCache: CFString = "kCGImageSourceShouldCache"

public let kCGImageSourceShouldCacheImmediately: CFString = "kCGImageSourceShouldCacheImmediately"

public let kCGImageSourceSubsampleFactor: CFString = "kCGImageSourceSubsampleFactor"

public let kCGImageSourceThumbnailMaxPixelSize: CFString = "kCGImageSourceThumbnailMaxPixelSize"

public let kCGImageSourceTypeIdentifierHint: CFString = "kCGImageSourceTypeIdentifierHint"

public let kIIOCameraExtrinsics_CoordinateSystemID: CFString = "CoordinateSystemID"

public let kIIOCameraExtrinsics_Position: CFString = "Position"

public let kIIOCameraExtrinsics_Rotation: CFString = "Rotation"

public let kIIOCameraModelType_GenericPinhole: CFString = "GenericPinhole"

public let kIIOCameraModelType_SimplifiedPinhole: CFString = "SimplifiedPinhole"

public let kIIOCameraModel_Intrinsics: CFString = "Intrinsics"

public let kIIOCameraModel_ModelType: CFString = "ModelType"

public let kIIOMetadata_CameraExtrinsicsKey: CFString = "CameraExtrinsics"

public let kIIOMetadata_CameraModelKey: CFString = "CameraModel"

public let kIIOMonoscopicImageLocation_Center: CFString = "Center"

public let kIIOMonoscopicImageLocation_Left: CFString = "Left"

public let kIIOMonoscopicImageLocation_Right: CFString = "Right"

public let kIIOMonoscopicImageLocation_Unspecified: CFString = "Unspecified"

public let kIIOStereoAggressors_Severity: CFString = "Severity"

public let kIIOStereoAggressors_SubTypeURI: CFString = "SubTypeURI"

public let kIIOStereoAggressors_Type: CFString = "Type"

// PNG filter bitmask macros. Measured 2026-09-05 Apple ImageIO:
// NONE=8 SUB=16 UP=32 AVG=64 PAETH=128 NO_FILTERS=0 IIO_HAS_IOSURFACE=1.
public let IIO_HAS_IOSURFACE: Int32 = 1

public let IMAGEIO_PNG_FILTER_AVG: Int32 = 64

public let IMAGEIO_PNG_FILTER_NONE: Int32 = 8

public let IMAGEIO_PNG_FILTER_PAETH: Int32 = 128

public let IMAGEIO_PNG_FILTER_SUB: Int32 = 16

public let IMAGEIO_PNG_FILTER_UP: Int32 = 32

public let IMAGEIO_PNG_NO_FILTERS: Int32 = 0
