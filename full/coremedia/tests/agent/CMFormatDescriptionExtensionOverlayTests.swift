import CoreFoundation
import CoreMedia
import Foundation

func testCMFormatDescriptionExtensionKeyRawValues() {
    let pairs: [(CMFormatDescription.Extensions.Key, String)] = [
        (.verbatimSampleDescription, "VerbatimSampleDescription"),
        (.sampleDescriptionExtensionAtoms, "SampleDescriptionExtensionAtoms"),
        (.metadataKeyTable, "MetadataKeyTable"),
        (.fieldCount, "FieldCount"),
        (.gammaLevel, "GammaLevel"),
        (.iccProfile, "ICCProfile"),
        (.bytesPerRow, "BytesPerRow"),
        (.fieldDetail, "FieldDetail"),
        (.yCbCrMatrix, "YCbCrMatrix"),
        (.defaultStyle, "DefaultStyle"),
        (.displayFlags, "DisplayFlags"),
        (.revisionLevel, "RevisionLevel"),
        (.colorPrimaries, "ColorPrimaries"),
        (.defaultTextBox, "DefaultTextBox"),
        (.fullRangeVideo, "FullRangeVideo"),
        (.projectionKind, "ProjectionKind"),
        (.spatialQuality, "SpatialQuality"),
        (.backgroundColor, "BackgroundColor"),
        (.defaultFontName, "DefaultFontName"),
        (.temporalQuality, "TemporalQuality"),
        (.viewPackingKind, "ViewPackingKind"),
        (.alphaChannelMode, "AlphaChannelMode"),
        (.bitsPerComponent, "BitsPerComponent"),
        (.transferFunction, "TransferFunction"),
        (.auxiliaryTypeInfo, "AuxiliaryTypeInfo"),
        (.textJustification, "TextJustification"),
        (.contentColorVolume, "ContentColorVolume"),
        (.hasAdditionalViews, "HasAdditionalViews"),
        (.logTransferFunction, "LogTransferFunction"),
        (.sourceReferenceName, "SourceReferenceName"),
        (.containsAlphaChannel, "ContainsAlphaChannel"),
        (.hasLeftStereoEyeView, "HasLeftStereoEyeView"),
        (.stereoCameraBaseline, "StereoCameraBaseline"),
        (.contentLightLevelInfo, "ContentLightLevelInfo"),
        (.hasRightStereoEyeView, "HasRightStereoEyeView"),
        (.horizontalFieldOfView, "HorizontalFieldOfView"),
        (.verticalJustification, "VerticalJustification"),
        (.chromaLocationTopField, "ChromaLocationTopField"),
        (.verbatimISOSampleEntry, "VerbatimISOSampleEntry"),
        (.horizontalJustification, "HorizontalJustification"),
        (.ambientViewingEnvironment, "AmbientViewingEnvironment"),
        (.chromaLocationBottomField, "ChromaLocationBottomField"),
        (.conformsToMPEG2VideoProfile, "ConformsToMPEG2VideoProfile"),
        (.masteringDisplayColorVolume, "MasteringDisplayColorVolume"),
        (.originalCompressionSettings, "OriginalCompressionSettings"),
        (.horizontalDisparityAdjustment, "HorizontalDisparityAdjustment"),
        (.protectedContentOriginalFormat, "ProtectedContentOriginalFormat"),
        (.alternativeTransferCharacteristics, "AlternativeTransferCharacteristics"),
        (.convertedFromExternalSphericalTags, "ConvertedFromExternalSphericalTags"),
        (.cameraCalibrationDataLensCollection, "CameraCalibrationDataLensCollection"),
        (.depth, "Depth"),
        (.vendor, "Vendor"),
        (.heroEye, "HeroEye"),
        (.version, "Version"),
        (.fontTable, "FontTable"),
    ]
    for (key, expected) in pairs {
        precondition(key.rawValue == expected)
        precondition(CMFormatDescription.Extensions.Key(rawValue: expected) == key)
    }
}

func testCMFormatDescriptionExtensionsBidirectionalIndex() {
    var extensions = CMFormatDescription.Extensions()
    extensions[.formatName] = .string("H.264")
    extensions[.vendor] = .vendor(.apple)
    precondition(extensions.startIndex.rawValue == 0)
    precondition(extensions.endIndex.rawValue == 2)
    let after = extensions.index(after: extensions.startIndex)
    precondition(after.rawValue == 1)
    precondition(extensions.index(before: extensions.endIndex).rawValue == 1)
    let first = extensions[extensions.startIndex]
    precondition(first.key == .formatName)
    precondition(extensions[.formatName] != nil)
    var hasher = Hasher()
    extensions.hash(into: &hasher)
    _ = hasher.finalize()
    let copy = CMFormatDescription.Extensions(base: extensions)
    precondition(copy == extensions)
    let empty = CMFormatDescription.Extensions(base: nil as CFDictionary?)
    precondition(empty.startIndex.rawValue == 0)
}

func testCMFormatDescriptionValueFactoriesAndPresentation() {
    let color = CMFormatDescription.Extensions.Value.qtTextColor(red: 1, green: 0, blue: 0, alpha: 1)
    let gppColor = CMFormatDescription.Extensions.Value.mobile3GPPTextColor(red: 0, green: 1, blue: 0, alpha: 1)
    _ = color
    _ = gppColor
    let flags = CMFormatDescription.Extensions.Value.textDisplayFlags(Set([.scrollIn, .scrollOut]))
    _ = flags
    let profile = CMFormatDescription.Extensions.Value.mpeg2VideoProfile(.hdv_720p30)
    _ = profile
    let rect = CMFormatDescription.Extensions.Value.textRect(top: 1, left: 2, bottom: 3, right: 4)
    _ = rect
    let style = CMFormatDescription.Extensions.Value.qtTextDefaultStyle(
        startChar: 0,
        height: 20,
        ascent: 16,
        localFontID: 1,
        fontFace: [.bold],
        fontSize: 18,
        foregroundColor: color,
        defaultFontName: "LinuxSans"
    )
    _ = style
    let gppStyle = CMFormatDescription.Extensions.Value.mobile3GPPTextDefaultStyle(
        startChar: 0,
        endChar: 4,
        localFontID: 1,
        fontFace: [.italic],
        fontSize: 12,
        foregroundColor: gppColor
    )
    _ = gppStyle
    var desc: CMFormatDescription?
    precondition(
        CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_H264,
            width: 100,
            height: 80,
            extensions: nil,
            formatDescriptionOut: &desc
        ) == 0
    )
    let presented = desc!.presentationDimensions(usePixelAspectRatio: false, useCleanAperture: false)
    precondition(presented.width == 100)
    precondition(presented.height == 80)
    let keys = CMFormatDescription.extensionKeysCommonWithImageBuffers
    precondition(!keys.isEmpty)
    precondition(keys.contains(.formatName) || keys.contains(CMFormatDescription.Extensions.Key(rawValue: "FormatName")))
}

func testCMFormatDescriptionFontNameAndLocalKey() {
    let fontName = "LinuxSans".withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
    var keyCB = kCFTypeDictionaryKeyCallBacks
    var valCB = kCFTypeDictionaryValueCallBacks
    let extensions = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &keyCB, &valCB)!
    CFDictionarySetValue(
        extensions,
        unsafeBitCast(kCMTextFormatDescriptionExtension_DefaultFontName, to: UnsafeRawPointer.self),
        unsafeBitCast(fontName, to: UnsafeRawPointer.self)
    )
    var desc: CMFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Text,
            mediaSubType: kCMTextFormatType_QTText,
            extensions: extensions,
            formatDescriptionOut: &desc
        ) == 0
    )
    let name = try! desc!.fontName(localFontID: 3)
    precondition(name == "LinuxSans")
    precondition(desc!.keyWithLocalID(1) == nil)
}

func testCMFormatDescriptionCameraCalibrationOverlay() {
    typealias LensCollection = CMFormatDescription.Extensions.Value.CameraCalibrationDataLensCollection
    let role = LensCollection.LensRole.mono
    precondition(CFEqual(role.rawValue, kCMFormatDescriptionCameraCalibrationLensRole_Mono))
    precondition(
        LensCollection.LensRole(rawValue: role.rawValue)
            == .mono
    )
    let left = LensCollection.LensRole.left
    let right = LensCollection.LensRole.right
    precondition(left != right)
    let domain = LensCollection.LensDomain.color
    precondition(CFEqual(domain.rawValue, kCMFormatDescriptionCameraCalibrationLensDomain_Color))
    let kind = LensCollection.AlgorithmKind.parametric
    precondition(
        CFEqual(kind.rawValue, kCMFormatDescriptionCameraCalibrationLensAlgorithmKind_ParametricLens)
    )
    let origin = LensCollection.ExtrinsicOriginSource.stereoCameraSystemBaseline
    precondition(
        CFEqual(
            origin.rawValue,
            kCMFormatDescriptionCameraCalibrationExtrinsicOriginSource_StereoCameraSystemBaseline
        )
    )
    let calibration = LensCollection.Calibration(
        algorithmKind: .parametric,
        identifier: 7,
        domain: .color,
        role: .mono,
        distortionCoefficients: SIMD4<Float>(1, 2, 3, 4),
        xFrameAdjustmentsPolynomial: SIMD3<Float>(0, 1, 0),
        yFrameAdjustmentsPolynomial: SIMD3<Float>(1, 0, 0),
        radialAngleLimit: 90,
        intrinsicMatrixProjectionOffset: 0.5,
        intrinsicMatrixReferenceDimensions: CGSize(width: 1920, height: 1080),
        extrinsicOriginSource: .stereoCameraSystemBaseline,
        extrinsicOrientationQuaternion: SIMD3<Float>(0, 0, 1)
    )
    precondition(calibration.identifier == 7)
    precondition(calibration.algorithmKind == .parametric)
    precondition(calibration.role == .mono)
    precondition(calibration.radialAngleLimit == 90)
    precondition(calibration.intrinsicMatrixReferenceDimensions.width == 1920)
    precondition(calibration.distortionCoefficients.x == 1)
    precondition(calibration.xFrameAdjustmentsPolynomial.y == 1)
    precondition(calibration.yFrameAdjustmentsPolynomial.x == 1)
    precondition(calibration.extrinsicOrientationQuaternion.z == 1)
    precondition(calibration.intrinsicMatrixProjectionOffset == 0.5)
    let fromDict = LensCollection.Calibration(
        rawValue: calibration.rawValue
    )
    precondition(fromDict != nil)
    let mono = LensCollection.mono(calibration)
    switch mono {
    case .mono(let stored):
        precondition(stored.identifier == 7)
    case .stereo:
        preconditionFailure("expected mono")
    }
    let stereo = LensCollection.stereo(
        left: calibration,
        right: calibration
    )
    _ = stereo.rawValue
    var hasher = Hasher()
    role.hash(into: &hasher)
    domain.hash(into: &hasher)
    kind.hash(into: &hasher)
    origin.hash(into: &hasher)
    _ = hasher.finalize()
    _ = role.hashValue
}

func testCMFormatDescriptionContentColorVolumeOverlay() {
    let volume = CMFormatDescription.Extensions.Value.ContentColorVolume.ColorVolume(
        green: 1,
        blue: 2,
        red: 3
    )
    precondition(volume.green == 1 && volume.blue == 2 && volume.red == 3)
    let primaries = CMFormatDescription.Extensions.Value.ContentColorVolume.ColorPrimaries(
        x: volume,
        y: volume
    )
    precondition(primaries.x.red == 3)
    precondition(primaries.y.blue == 2)
    let content = CMFormatDescription.Extensions.Value.ContentColorVolume(
        colorPrimaries: primaries,
        minimumLuminance: 1,
        maximumLuminance: 1000,
        averageLuminance: 100
    )
    precondition(content.minimumLuminance == 1)
    precondition(content.maximumLuminance == 1000)
    precondition(content.averageLuminance == 100)
    _ = content.rawValue
}
