import Foundation
import ImageIO

func testSourceOptionKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO source option CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kCGImageSourceCreateThumbnailFromImageAlways, "kCGImageSourceCreateThumbnailFromImageAlways"),
        (kCGImageSourceCreateThumbnailFromImageIfAbsent, "kCGImageSourceCreateThumbnailFromImageIfAbsent"),
        (kCGImageSourceCreateThumbnailWithTransform, "kCGImageSourceCreateThumbnailWithTransform"),
        (kCGImageSourceDecodeRequest, "kCGImageSourceDecodeRequest"),
        (kCGImageSourceDecodeRequestOptions, "kCGImageSourceDecodeRequestOptions"),
        (kCGImageSourceDecodeToHDR, "kCGImageSourceDecodeToHDR"),
        (kCGImageSourceDecodeToSDR, "kCGImageSourceDecodeToSDR"),
        (kCGImageSourceGenerateImageSpecificLumaScaling, "kCGImageSourceGenerateImageSpecificLumaScaling"),
        (kCGImageSourceShouldAllowFloat, "kCGImageSourceShouldAllowFloat"),
        (kCGImageSourceShouldCache, "kCGImageSourceShouldCache"),
        (kCGImageSourceShouldCacheImmediately, "kCGImageSourceShouldCacheImmediately"),
        (kCGImageSourceSubsampleFactor, "kCGImageSourceSubsampleFactor"),
        (kCGImageSourceThumbnailMaxPixelSize, "kCGImageSourceThumbnailMaxPixelSize"),
        (kCGImageSourceTypeIdentifierHint, "kCGImageSourceTypeIdentifierHint"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 14, "count")
}
func testDestinationOptionKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO destination option CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kCGImageDestinationBackgroundColor, "kCGImageDestinationBackgroundColor"),
        (kCGImageDestinationDateTime, "kCGImageDestinationDateTime"),
        (kCGImageDestinationEmbedThumbnail, "kCGImageDestinationEmbedThumbnail"),
        (kCGImageDestinationEncodeAlternateColorSpace, "kCGImageDestinationEncodeAlternateColorSpace"),
        (kCGImageDestinationEncodeBaseColorSpace, "kCGImageDestinationEncodeBaseColorSpace"),
        (kCGImageDestinationEncodeBaseIsSDR, "kCGImageDestinationEncodeBaseIsSDR"),
        (kCGImageDestinationEncodeBasePixelFormatRequest, "kCGImageDestinationEncodeBasePixelFormatRequest"),
        (kCGImageDestinationEncodeGainMapPixelFormatRequest, "kCGImageDestinationEncodeGainMapPixelFormatRequest"),
        (kCGImageDestinationEncodeGainMapSubsampleFactor, "kCGImageDestinationEncodeGainMapSubsampleFactor"),
        (kCGImageDestinationEncodeGenerateGainMapWithBaseImage, "kCGImageDestinationEncodeGenerateGainMapWithBaseImage"),
        (kCGImageDestinationEncodeIsBaseImage, "kCGImageDestinationEncodeIsBaseImage"),
        (kCGImageDestinationEncodeRequest, "kCGImageDestinationEncodeRequest"),
        (kCGImageDestinationEncodeRequestOptions, "kCGImageDestinationEncodeRequestOptions"),
        (kCGImageDestinationEncodeToISOGainmap, "kCGImageDestinationEncodeToISOGainmap"),
        (kCGImageDestinationEncodeToISOHDR, "kCGImageDestinationEncodeToISOHDR"),
        (kCGImageDestinationEncodeToSDR, "kCGImageDestinationEncodeToSDR"),
        (kCGImageDestinationEncodeTonemapMode, "kCGImageDestinationEncodeTonemapMode"),
        (kCGImageDestinationImageMaxPixelSize, "kCGImageDestinationImageMaxPixelSize"),
        (kCGImageDestinationLossyCompressionQuality, "kCGImageDestinationLossyCompressionQuality"),
        (kCGImageDestinationMergeMetadata, "kCGImageDestinationMergeMetadata"),
        (kCGImageDestinationMetadata, "kCGImageDestinationMetadata"),
        (kCGImageDestinationOptimizeColorForSharing, "kCGImageDestinationOptimizeColorForSharing"),
        (kCGImageDestinationOrientation, "kCGImageDestinationOrientation"),
        (kCGImageDestinationPreserveGainMap, "kCGImageDestinationPreserveGainMap"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 24, "count")
}
func testMetadataKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO metadata namespace/prefix/option CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kCGImageMetadataEnumerateRecursively, "kCGImageMetadataEnumerateRecursively"),
        (kCGImageMetadataNamespaceDublinCore, "http://purl.org/dc/elements/1.1/"),
        (kCGImageMetadataNamespaceExif, "http://ns.adobe.com/exif/1.0/"),
        (kCGImageMetadataNamespaceExifAux, "http://ns.adobe.com/exif/1.0/aux/"),
        (kCGImageMetadataNamespaceExifEX, "http://cipa.jp/exif/1.0/"),
        (kCGImageMetadataNamespaceIPTCCore, "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/"),
        (kCGImageMetadataNamespaceIPTCExtension, "http://iptc.org/std/Iptc4xmpExt/2008-02-29/"),
        (kCGImageMetadataNamespacePhotoshop, "http://ns.adobe.com/photoshop/1.0/"),
        (kCGImageMetadataNamespaceTIFF, "http://ns.adobe.com/tiff/1.0/"),
        (kCGImageMetadataNamespaceXMPBasic, "http://ns.adobe.com/xap/1.0/"),
        (kCGImageMetadataNamespaceXMPRights, "http://ns.adobe.com/xap/1.0/rights/"),
        (kCGImageMetadataPrefixDublinCore, "dc"),
        (kCGImageMetadataPrefixExif, "exif"),
        (kCGImageMetadataPrefixExifAux, "aux"),
        (kCGImageMetadataPrefixExifEX, "exifEX"),
        (kCGImageMetadataPrefixIPTCCore, "Iptc4xmpCore"),
        (kCGImageMetadataPrefixIPTCExtension, "Iptc4xmpExt"),
        (kCGImageMetadataPrefixPhotoshop, "photoshop"),
        (kCGImageMetadataPrefixTIFF, "tiff"),
        (kCGImageMetadataPrefixXMPBasic, "xmp"),
        (kCGImageMetadataPrefixXMPRights, "xmpRights"),
        (kCGImageMetadataShouldExcludeGPS, "kCGImageMetadataShouldExcludeGPS"),
        (kCGImageMetadataShouldExcludeXMP, "kCGImageMetadataShouldExcludeXMP"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 23, "count")
}
func testAuxiliaryKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO auxiliary-data CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kCGImageAuxiliaryDataInfoColorSpace, "kCGImageAuxiliaryDataInfoColorSpace"),
        (kCGImageAuxiliaryDataInfoData, "kCGImageAuxiliaryDataInfoData"),
        (kCGImageAuxiliaryDataInfoDataDescription, "kCGImageAuxiliaryDataInfoDataDescription"),
        (kCGImageAuxiliaryDataInfoMetadata, "kCGImageAuxiliaryDataInfoMetadata"),
        (kCGImageAuxiliaryDataTypeDepth, "kCGImageAuxiliaryDataTypeDepth"),
        (kCGImageAuxiliaryDataTypeDisparity, "kCGImageAuxiliaryDataTypeDisparity"),
        (kCGImageAuxiliaryDataTypeHDRGainMap, "kCGImageAuxiliaryDataTypeHDRGainMap"),
        (kCGImageAuxiliaryDataTypeISOGainMap, "kCGImageAuxiliaryDataTypeISOGainMap"),
        (kCGImageAuxiliaryDataTypePortraitEffectsMatte, "kCGImageAuxiliaryDataTypePortraitEffectsMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 14, "count")
}
func testAnimationKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO animation CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kCGImageAnimationDelayTime, "DelayTime"),
        (kCGImageAnimationLoopCount, "LoopCount"),
        (kCGImageAnimationStartIndex, "StartIndex"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 3, "count")
}
func testIIOKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO kIIO* CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kIIOCameraExtrinsics_CoordinateSystemID, "CoordinateSystemID"),
        (kIIOCameraExtrinsics_Position, "Position"),
        (kIIOCameraExtrinsics_Rotation, "Rotation"),
        (kIIOCameraModelType_GenericPinhole, "GenericPinhole"),
        (kIIOCameraModelType_SimplifiedPinhole, "SimplifiedPinhole"),
        (kIIOCameraModel_Intrinsics, "Intrinsics"),
        (kIIOCameraModel_ModelType, "ModelType"),
        (kIIOMetadata_CameraExtrinsicsKey, "CameraExtrinsics"),
        (kIIOMetadata_CameraModelKey, "CameraModel"),
        (kIIOMonoscopicImageLocation_Center, "Center"),
        (kIIOMonoscopicImageLocation_Left, "Left"),
        (kIIOMonoscopicImageLocation_Right, "Right"),
        (kIIOMonoscopicImageLocation_Unspecified, "Unspecified"),
        (kIIOStereoAggressors_Severity, "Severity"),
        (kIIOStereoAggressors_SubTypeURI, "SubTypeURI"),
        (kIIOStereoAggressors_Type, "Type"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 16, "count")
}
func testMiscKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO remaining CFString payloads.
    let keys: [(CFString, CFString)] = [
        (kCFErrorDomainCGImageMetadata, "kCFErrorDomainCGImageMetadata"),
        (kCGComputeHDRStats, "kCGComputeHDRStats"),
        (kCGImageProviderPreferredTileHeight, "kCGImageProviderPreferredTileHeight"),
        (kCGImageProviderPreferredTileWidth, "kCGImageProviderPreferredTileWidth"),
    ]
    for (key, expected) in keys {
        imageioRequire(key == expected, expected)
    }
    imageioRequire(keys.count == 4, "count")
}
