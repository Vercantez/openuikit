import CoreImage
import Foundation

func testCIColorNamedColors() {
    precondition(CIColor.black.red == 0 && CIColor.black.alpha == 1)
    precondition(CIColor.white.red == 1 && CIColor.white.green == 1 && CIColor.white.blue == 1)
    precondition(CIColor.clear.alpha == 0)
    precondition(CIColor.red.red == 1 && CIColor.red.green == 0)
    precondition(CIColor.green.green == 1)
    precondition(CIColor.blue.blue == 1)
    precondition(CIColor.cyan.green == 1 && CIColor.cyan.blue == 1)
    precondition(CIColor.magenta.red == 1 && CIColor.magenta.blue == 1)
    precondition(CIColor.yellow.red == 1 && CIColor.yellow.green == 1)
    precondition(CIColor.gray.red == 0.5)
    precondition(CIColor.black.numberOfComponents == 4)
    let copy = CIColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 0.5)
    precondition(copy.red == 0.25 && copy.alpha == 0.5)
    let rgb = CIColor(red: 1, green: 0, blue: 0)
    precondition(rgb.alpha == 1)
}

func testCIColorStringRoundTrip() {
    let color = CIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
    let parsed = CIColor(string: color.stringRepresentation)
    precondition(abs(parsed.red - 0.2) < 0.01)
    precondition(abs(parsed.alpha - 0.8) < 0.01)
    let cg = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
    let fromCG = CIColor(cgColor: cg)
    precondition(fromCG.red == 1)
    let fromCG2 = CIColor(CGColor: cg)
    precondition(fromCG2.blue == 0)
    precondition(CIColor(coder: NSCoder()) == nil)
}

func testCIVectorComponents() {
    let v = CIVector(x: 1, y: 2, z: 3, w: 4)
    precondition(v.count == 4)
    precondition(v.x == 1 && v.y == 2 && v.z == 3 && v.w == 4)
    precondition(v.value(at: 0) == 1)
    precondition(v.value(at: 99) == 0)
    let p = CIVector(cgPoint: CGPoint(x: 5, y: 6))
    precondition(p.cgPointValue.x == 5 && p.cgPointValue.y == 6)
    let r = CIVector(cgRect: CGRect(x: 1, y: 2, width: 3, height: 4))
    precondition(r.cgRectValue.width == 3)
    let t = CIVector(cgAffineTransform: .identity)
    precondition(t.cgAffineTransformValue.a == 1)
    let parsed = CIVector(string: "[7 8]")
    precondition(parsed.x == 7 && parsed.y == 8)
    let yAlias = CIVector(x: 1, Y: 2)
    precondition(yAlias.y == 2)
    precondition(CIVector(coder: NSCoder()) == nil)
}

func testCIFormatConstants() {
    precondition(CIFormat.ARGB8.rawValue == 0)
    precondition(CIFormat.RGBAh.rawValue == 1)
    precondition(CIFormat.RGBA16.rawValue == 2)
    precondition(CIFormat.RGBAf.rawValue == 4)
    precondition(CIFormat.BGRA8.rawValue == 5)
    precondition(CIFormat.RGBA8.rawValue == 6)
    precondition(CIFormat.ABGR8.rawValue == 7)
    precondition(CIFormat.A8.rawValue == 11)
    precondition(CIFormat.RGBA8 != CIFormat.BGRA8)
    var hasher = Hasher()
    CIFormat.RGBA8.hash(into: &hasher)
    _ = CIFormat.RGBA8.hashValue
    _ = CIFormat(rawValue: 99)
}

func testCIOptionNewtypes() {
    precondition(CIContextOption.useSoftwareRenderer.rawValue == "kCIContextUseSoftwareRenderer")
    precondition(CIContextOption.memoryTarget.rawValue == "kCIContextMemoryLimit")
    precondition(CIImageOption.colorSpace.rawValue == "kCIImageColorSpace")
    precondition(CIImageAutoAdjustmentOption.enhance.rawValue == "kCIImageAutoAdjustEnhance")
    precondition(CIDynamicRangeOption.standard.rawValue == "kCIDynamicRangeStandard")
    precondition(CIRAWDecoderVersion.none.rawValue == "CIRAWDecoderVersionNone")
    precondition(CIRAWDecoderVersion.version8 != CIRAWDecoderVersion.version7)
    precondition(CIRAWFilterOption.boostAmount.rawValue == "kCIInputBoostKey")
    precondition(CIImageRepresentationOption.depthImage.rawValue.contains("Depth"))
    _ = CIContextOption(rawValue: "custom")
    _ = CIImageOption(rawValue: "custom")
    _ = CIRAWFilterOption(rawValue: "custom")
    _ = CIRAWDecoderVersion(rawValue: "custom")
    _ = CIDynamicRangeOption(rawValue: "custom")
    _ = CIImageAutoAdjustmentOption(rawValue: "custom")
    _ = CIImageRepresentationOption(rawValue: "custom")
}

func testCIStringConstants() {
    precondition(kCIInputImageKey == "inputImage")
    precondition(kCIOutputImageKey == "outputImage")
    precondition(kCIInputRadiusKey == "inputRadius")
    precondition(kCIAttributeClass == "CIAttributeClass")
    precondition(kCICategoryGradient == "CICategoryGradient")
    precondition(CIDetectorTypeFace == "CIDetectorTypeFace")
    precondition(CIFeatureTypeQRCode == "CIFeatureTypeQRCode")
    precondition(kCISamplerFilterLinear == "CILinear")
    precondition(kCIUISetBasic == "CIUISetBasic")
}

func testCIEnums() {
    precondition(CIQRCodeDescriptor.ErrorCorrectionLevel.levelL.rawValue == 76)
    precondition(CIQRCodeDescriptor.ErrorCorrectionLevel.levelH.rawValue == 72)
    precondition(CIDataMatrixCodeDescriptor.ECCVersion.v200.rawValue == 200)
    precondition(CIRenderDestinationAlphaMode.premultiplied.rawValue == 1)
    precondition(CIQRCodeDescriptor.ErrorCorrectionLevel.levelM != .levelQ)
    _ = CIQRCodeDescriptor.ErrorCorrectionLevel(rawValue: 76)
    _ = CIDataMatrixCodeDescriptor.ECCVersion(rawValue: 0)
    _ = CIRenderDestinationAlphaMode(rawValue: 2)
    var hasher = Hasher()
    CIRenderDestinationAlphaMode.none.hash(into: &hasher)
    _ = CIRenderDestinationAlphaMode.none.hashValue
}

func testCIImageColorExtentCrop() {
    let image = CIImage(color: .red)
    precondition(image.extent.isInfinite)
    let cropped = image.cropped(to: CGRect(x: 0, y: 0, width: 8, height: 8))
    precondition(cropped.extent.width == 8)
    precondition(CIImage.empty().extent.isNull)
    precondition(CIImage.black.extent.isInfinite)
    precondition(CIImage.white.extent.isInfinite)
    let tagged = cropped.settingContentHeadroom(4)
    precondition(tagged.contentHeadroom == 4)
    let props = cropped.settingProperties(["a": 1])
    precondition(!props.properties.isEmpty)
}

func testCILinearGradientRender() {
    let filter = CIFilter.linearGradient()
    filter.color0 = .black
    filter.color1 = .white
    filter.point0 = CGPoint(x: 0, y: 0)
    filter.point1 = CGPoint(x: 8, y: 0)
    guard let image = filter.outputImage else {
        preconditionFailure("linear gradient must produce an image")
    }
    let context = CIContext()
    guard let bitmap = context.createCGImage(image, from: CGRect(x: 0, y: 0, width: 8, height: 1)) else {
        preconditionFailure("createCGImage must rasterize")
    }
    precondition(bitmap.width == 8)
    precondition(bitmap.height == 1)
    let left = bitmap.pixels[0]
    let right = bitmap.pixels[(7 * 4)]
    precondition(left < 40)
    precondition(right > 200)
    let smooth = CIFilter.smoothLinearGradient()
    precondition(smooth.outputImage != nil)
}

func testCIContextRenderToBitmap() {
    let image = CIImage(color: CIColor(red: 1, green: 0, blue: 0, alpha: 1))
    let context = CIContext(options: [.useSoftwareRenderer: true])
    var bytes = [UInt8](repeating: 0, count: 16)
    bytes.withUnsafeMutableBytes { raw in
        context.render(
            image,
            toBitmap: raw.baseAddress!,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: .sRGB
        )
    }
    precondition(bytes[0] == 255)
    precondition(bytes[3] == 255)
    context.clearCaches()
    precondition(context.inputImageMaximumSize().width == 8192)
    precondition(context.workingFormat == .RGBA8)
}

func testCIFilterRegistry() {
    let names = CIFilter.filterNames(inCategory: kCICategoryGradient)
    precondition(names.contains("CILinearGradient"))
    precondition(CIFilter.filterNames(inCategories: nil).contains("CIConstantColorGenerator"))
    guard let filter = CIFilter(name: "CILinearGradient") else {
        preconditionFailure("registered linear gradient")
    }
    precondition(filter.name == "CILinearGradient")
    precondition(filter.outputImage != nil)
    precondition(CIFilter.localizedName(forCategory: kCICategoryBlur) == kCICategoryBlur)
    precondition(CIFilter.supportedRawCameraModels().isEmpty)
    precondition(CIFilter(name: "CIDoesNotExist") == nil)
}

func testCIDetectorFailClosed() {
    let context = CIContext()
    guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [
        CIDetectorAccuracy: CIDetectorAccuracyHigh,
    ]) else {
        preconditionFailure("face detector type is constructible")
    }
    let features = detector.features(in: CIImage(color: .white))
    precondition(features.isEmpty)
    precondition(CIDetector(ofType: "not-a-detector", context: nil) == nil)
}

func testCIBarcodeDescriptors() {
    let payload = Data([0x01, 0x02])
    guard let qr = CIQRCodeDescriptor(
        payload: payload,
        symbolVersion: 1,
        maskPattern: 0,
        errorCorrectionLevel: .levelL
    ) else {
        preconditionFailure("qr descriptor")
    }
    precondition(qr.symbolVersion == 1)
    precondition(CIQRCodeDescriptor(payload: payload, symbolVersion: 99, maskPattern: 0, errorCorrectionLevel: .levelL) == nil)
    guard let aztec = CIAztecCodeDescriptor(
        payload: payload,
        isCompact: true,
        layerCount: 1,
        dataCodewordCount: 1
    ) else {
        preconditionFailure("aztec")
    }
    precondition(aztec.isCompact)
    guard let pdf = CIPDF417CodeDescriptor(
        payload: payload,
        isCompact: false,
        rowCount: 2,
        columnCount: 3
    ) else {
        preconditionFailure("pdf417")
    }
    precondition(pdf.columnCount == 3)
    guard let matrix = CIDataMatrixCodeDescriptor(
        payload: payload,
        rowCount: 8,
        columnCount: 8,
        eccVersion: .v200
    ) else {
        preconditionFailure("datamatrix")
    }
    precondition(matrix.eccVersion == .v200)
}

func testCIFilterShapeRects() {
    let a = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 10, height: 10))
    let b = a.insetBy(x: 1, y: 1)
    precondition(b.extent.width == 8)
    let u = a.union(with: CGRect(x: 10, y: 0, width: 5, height: 10))
    precondition(u.extent.width == 15)
    let i = a.intersect(with: CGRect(x: 5, y: 5, width: 10, height: 10))
    precondition(i.extent.width == 5)
    let other = CIFilterShape(rect: CGRect(x: 8, y: 8, width: 4, height: 4))
    precondition(a.intersect(with: other).extent.width == 2)
    precondition(a.union(with: other).extent.width == 12)
}

func testCIImageAccumulator() {
    guard let acc = CIImageAccumulator(extent: CGRect(x: 0, y: 0, width: 4, height: 4), format: .RGBA8) else {
        preconditionFailure("accumulator")
    }
    acc.setImage(CIImage(color: .blue))
    precondition(acc.image().extent.width == 4)
    acc.clear()
    precondition(acc.format == .RGBA8)
}

func testCIBlendKernelIdentity() {
    precondition(CIBlendKernel.sourceOver.name == "sourceOver")
    precondition(CIBlendKernel.multiply.name == "multiply")
    let fg = CIImage(color: CIColor(red: 1, green: 0, blue: 0, alpha: 1))
        .cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let bg = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(CIBlendKernel.sourceOver.apply(foreground: fg, background: bg) != nil)
    precondition(CIBlendKernel.multiply.apply(foreground: fg, background: bg) == nil)
    precondition(CIKernel(source: "kernel vec4 foo() { return vec4(1.0); }") == nil)
}

func testCIRAWFilterFailClosed() {
    precondition(CIRAWFilter(imageURL: URL(fileURLWithPath: "/tmp/none.dng")) == nil)
    precondition(CIRAWFilter.supportedCameraModels.isEmpty)
    precondition(CIImage(data: Data([0x00, 0x01])) == nil)
    precondition(CIImage(contentsOf: URL(fileURLWithPath: "/tmp/none.png")) == nil)
}

func testCIMacrosAndFailClosedCodecs() {
    precondition(COREIMAGE_SUPPORTS_IOSURFACE == 0)
    precondition(COREIMAGE_SUPPORTS_OPENGLES == 0)
    precondition(UNIFIED_CORE_IMAGE == 1)
    let context = CIContext()
    let image = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    let png = context.pngRepresentation(of: image, format: .RGBA8, colorSpace: .sRGB)
    precondition(png != nil)
    let pngBytes = [UInt8](png!)
    precondition(pngBytes.count >= 4)
    precondition(pngBytes[0] == 0x89 && pngBytes[1] == 0x50 && pngBytes[2] == 0x4E && pngBytes[3] == 0x47)
    let jpeg = context.jpegRepresentation(of: image, colorSpace: .sRGB)
    precondition(jpeg != nil)
    let jpegBytes = [UInt8](jpeg!)
    precondition(jpegBytes.count >= 2 && jpegBytes[0] == 0xFF && jpegBytes[1] == 0xD8)
    do {
        _ = try context.heif10Representation(of: image, colorSpace: .sRGB)
        preconditionFailure("heif must fail closed")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
}

func testCISamplerAndRenderDestination() {
    let image = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    let sampler = CISampler(image: image)
    precondition(sampler.extent.width == 2)
    var storage = [UInt8](repeating: 0, count: 16)
    storage.withUnsafeMutableBytes { raw in
        let dest = CIRenderDestination(
            bitmapData: raw.baseAddress!,
            width: 2,
            height: 2,
            bytesPerRow: 8,
            format: .RGBA8
        )
        precondition(dest.width == 2)
        dest.alphaMode = .premultiplied
        precondition(dest.alphaMode == .premultiplied)
    }
}

func testCGAffineTransformLookalike() {
    let t = CGAffineTransform(translationX: 3, y: 4)
    let p = t.applying(to: CGPoint.zero)
    precondition(p.x == 3 && p.y == 4)
    let s = CGAffineTransform(scaleX: 2, y: 3)
    precondition(s.a == 2 && s.d == 3)
    let ident = CGAffineTransform.identity.concatenating(.identity)
    precondition(ident.a == 1)
    let face = CIFaceFeature(bounds: CGRect(x: 1, y: 2, width: 3, height: 4))
    precondition(face.type == CIFeatureTypeFace)
    precondition(!face.hasSmile)
}

func testCIAllStringConstants() {
    let values: [(String, String)] = [
        ("CIDetectorAccuracy", CIDetectorAccuracy),
        ("CIDetectorAccuracyHigh", CIDetectorAccuracyHigh),
        ("CIDetectorAccuracyLow", CIDetectorAccuracyLow),
        ("CIDetectorAspectRatio", CIDetectorAspectRatio),
        ("CIDetectorEyeBlink", CIDetectorEyeBlink),
        ("CIDetectorFocalLength", CIDetectorFocalLength),
        ("CIDetectorImageOrientation", CIDetectorImageOrientation),
        ("CIDetectorMaxFeatureCount", CIDetectorMaxFeatureCount),
        ("CIDetectorMinFeatureSize", CIDetectorMinFeatureSize),
        ("CIDetectorNumberOfAngles", CIDetectorNumberOfAngles),
        ("CIDetectorReturnSubFeatures", CIDetectorReturnSubFeatures),
        ("CIDetectorSmile", CIDetectorSmile),
        ("CIDetectorTracking", CIDetectorTracking),
        ("CIDetectorTypeFace", CIDetectorTypeFace),
        ("CIDetectorTypeQRCode", CIDetectorTypeQRCode),
        ("CIDetectorTypeRectangle", CIDetectorTypeRectangle),
        ("CIDetectorTypeText", CIDetectorTypeText),
        ("CIFeatureTypeFace", CIFeatureTypeFace),
        ("CIFeatureTypeQRCode", CIFeatureTypeQRCode),
        ("CIFeatureTypeRectangle", CIFeatureTypeRectangle),
        ("CIFeatureTypeText", CIFeatureTypeText),
        ("kCIAttributeClass", kCIAttributeClass),
        ("kCIAttributeDefault", kCIAttributeDefault),
        ("kCIAttributeDescription", kCIAttributeDescription),
        ("kCIAttributeDisplayName", kCIAttributeDisplayName),
        ("kCIAttributeFilterAvailable_Mac", kCIAttributeFilterAvailable_Mac),
        ("kCIAttributeFilterAvailable_iOS", kCIAttributeFilterAvailable_iOS),
        ("kCIAttributeFilterCategories", kCIAttributeFilterCategories),
        ("kCIAttributeFilterDisplayName", kCIAttributeFilterDisplayName),
        ("kCIAttributeFilterName", kCIAttributeFilterName),
        ("kCIAttributeIdentity", kCIAttributeIdentity),
        ("kCIAttributeMax", kCIAttributeMax),
        ("kCIAttributeMin", kCIAttributeMin),
        ("kCIAttributeName", kCIAttributeName),
        ("kCIAttributeReferenceDocumentation", kCIAttributeReferenceDocumentation),
        ("kCIAttributeSliderMax", kCIAttributeSliderMax),
        ("kCIAttributeSliderMin", kCIAttributeSliderMin),
        ("kCIAttributeType", kCIAttributeType),
        ("kCIAttributeTypeAngle", kCIAttributeTypeAngle),
        ("kCIAttributeTypeBoolean", kCIAttributeTypeBoolean),
        ("kCIAttributeTypeColor", kCIAttributeTypeColor),
        ("kCIAttributeTypeCount", kCIAttributeTypeCount),
        ("kCIAttributeTypeDistance", kCIAttributeTypeDistance),
        ("kCIAttributeTypeGradient", kCIAttributeTypeGradient),
        ("kCIAttributeTypeImage", kCIAttributeTypeImage),
        ("kCIAttributeTypeInteger", kCIAttributeTypeInteger),
        ("kCIAttributeTypeOffset", kCIAttributeTypeOffset),
        ("kCIAttributeTypeOpaqueColor", kCIAttributeTypeOpaqueColor),
        ("kCIAttributeTypePosition", kCIAttributeTypePosition),
        ("kCIAttributeTypePosition3", kCIAttributeTypePosition3),
        ("kCIAttributeTypeRectangle", kCIAttributeTypeRectangle),
        ("kCIAttributeTypeScalar", kCIAttributeTypeScalar),
        ("kCIAttributeTypeTime", kCIAttributeTypeTime),
        ("kCIAttributeTypeTransform", kCIAttributeTypeTransform),
        ("kCICategoryBlur", kCICategoryBlur),
        ("kCICategoryBuiltIn", kCICategoryBuiltIn),
        ("kCICategoryColorAdjustment", kCICategoryColorAdjustment),
        ("kCICategoryColorEffect", kCICategoryColorEffect),
        ("kCICategoryCompositeOperation", kCICategoryCompositeOperation),
        ("kCICategoryDistortionEffect", kCICategoryDistortionEffect),
        ("kCICategoryFilterGenerator", kCICategoryFilterGenerator),
        ("kCICategoryGenerator", kCICategoryGenerator),
        ("kCICategoryGeometryAdjustment", kCICategoryGeometryAdjustment),
        ("kCICategoryGradient", kCICategoryGradient),
        ("kCICategoryHalftoneEffect", kCICategoryHalftoneEffect),
        ("kCICategoryHighDynamicRange", kCICategoryHighDynamicRange),
        ("kCICategoryInterlaced", kCICategoryInterlaced),
        ("kCICategoryNonSquarePixels", kCICategoryNonSquarePixels),
        ("kCICategoryReduction", kCICategoryReduction),
        ("kCICategorySharpen", kCICategorySharpen),
        ("kCICategoryStillImage", kCICategoryStillImage),
        ("kCICategoryStylize", kCICategoryStylize),
        ("kCICategoryTileEffect", kCICategoryTileEffect),
        ("kCICategoryTransition", kCICategoryTransition),
        ("kCICategoryVideo", kCICategoryVideo),
        ("kCIInputAmountKey", kCIInputAmountKey),
        ("kCIInputAngleKey", kCIInputAngleKey),
        ("kCIInputAspectRatioKey", kCIInputAspectRatioKey),
        ("kCIInputBackgroundImageKey", kCIInputBackgroundImageKey),
        ("kCIInputBacksideImageKey", kCIInputBacksideImageKey),
        ("kCIInputBiasKey", kCIInputBiasKey),
        ("kCIInputBiasVectorKey", kCIInputBiasVectorKey),
        ("kCIInputBrightnessKey", kCIInputBrightnessKey),
        ("kCIInputCenterKey", kCIInputCenterKey),
        ("kCIInputColor0Key", kCIInputColor0Key),
        ("kCIInputColor1Key", kCIInputColor1Key),
        ("kCIInputColorKey", kCIInputColorKey),
        ("kCIInputColorSpaceKey", kCIInputColorSpaceKey),
        ("kCIInputContrastKey", kCIInputContrastKey),
        ("kCIInputCountKey", kCIInputCountKey),
        ("kCIInputDepthImageKey", kCIInputDepthImageKey),
        ("kCIInputDisparityImageKey", kCIInputDisparityImageKey),
        ("kCIInputEVKey", kCIInputEVKey),
        ("kCIInputExtentKey", kCIInputExtentKey),
        ("kCIInputExtrapolateKey", kCIInputExtrapolateKey),
        ("kCIInputGradientImageKey", kCIInputGradientImageKey),
        ("kCIInputImageKey", kCIInputImageKey),
        ("kCIInputIntensityKey", kCIInputIntensityKey),
        ("kCIInputMaskImageKey", kCIInputMaskImageKey),
        ("kCIInputMatteImageKey", kCIInputMatteImageKey),
        ("kCIInputPaletteImageKey", kCIInputPaletteImageKey),
        ("kCIInputPerceptualKey", kCIInputPerceptualKey),
        ("kCIInputPoint0Key", kCIInputPoint0Key),
        ("kCIInputPoint1Key", kCIInputPoint1Key),
        ("kCIInputRadius0Key", kCIInputRadius0Key),
        ("kCIInputRadius1Key", kCIInputRadius1Key),
        ("kCIInputRadiusKey", kCIInputRadiusKey),
        ("kCIInputRefractionKey", kCIInputRefractionKey),
        ("kCIInputSaturationKey", kCIInputSaturationKey),
        ("kCIInputScaleKey", kCIInputScaleKey),
        ("kCIInputShadingImageKey", kCIInputShadingImageKey),
        ("kCIInputSharpnessKey", kCIInputSharpnessKey),
        ("kCIInputTargetImageKey", kCIInputTargetImageKey),
        ("kCIInputThresholdKey", kCIInputThresholdKey),
        ("kCIInputTimeKey", kCIInputTimeKey),
        ("kCIInputTransformKey", kCIInputTransformKey),
        ("kCIInputVersionKey", kCIInputVersionKey),
        ("kCIInputWeightsKey", kCIInputWeightsKey),
        ("kCIInputWidthKey", kCIInputWidthKey),
        ("kCIOutputImageKey", kCIOutputImageKey),
        ("kCISamplerAffineMatrix", kCISamplerAffineMatrix),
        ("kCISamplerColorSpace", kCISamplerColorSpace),
        ("kCISamplerFilterLinear", kCISamplerFilterLinear),
        ("kCISamplerFilterMode", kCISamplerFilterMode),
        ("kCISamplerFilterNearest", kCISamplerFilterNearest),
        ("kCISamplerWrapBlack", kCISamplerWrapBlack),
        ("kCISamplerWrapClamp", kCISamplerWrapClamp),
        ("kCISamplerWrapMode", kCISamplerWrapMode),
        ("kCIUIParameterSet", kCIUIParameterSet),
        ("kCIUISetAdvanced", kCIUISetAdvanced),
        ("kCIUISetBasic", kCIUISetBasic),
        ("kCIUISetDevelopment", kCIUISetDevelopment),
        ("kCIUISetIntermediate", kCIUISetIntermediate),
    ]
    precondition(values.count == 133)
    var seen = Set<String>()
    for (name, value) in values {
        precondition(!value.isEmpty, name)
        precondition(seen.insert(name).inserted, name)
    }
}

func testCIAllOptionStatics() {
    let context: [CIContextOption] = [
        .allowLowPower, .cvMetalTextureCache, .cacheIntermediates, .highQualityDownsample,
        .memoryTarget, .name, .outputColorSpace, .outputPremultiplied, .priorityRequestLow,
        .useSoftwareRenderer, .workingColorSpace, .workingFormat,
    ]
    precondition(Set(context.map(\.rawValue)).count == context.count)
    let formats: [CIFormat] = [
        .ARGB8, .RGBAh, .RGBA16, .RGBAf, .BGRA8, .RGBA8, .ABGR8,
        .A8, .A16, .Ah, .Af, .R8, .R16, .Rh, .Rf, .RG8, .RG16, .RGh, .RGf,
        .L8, .L16, .Lh, .Lf, .LA8, .LA16, .LAh, .LAf, .RGB10, .RGBX16, .rgbXf, .rgbXh, .RGBX8,
    ]
    precondition(Set(formats.map(\.rawValue)).count == formats.count)
    let blend: [CIBlendKernel] = [
        .clear, .color, .colorBurn, .colorDodge, .componentAdd, .componentMax, .componentMin,
        .componentMultiply, .darken, .darkerColor, .destination, .destinationAtop, .destinationIn,
        .destinationOut, .destinationOver, .difference, .divide, .exclusion, .exclusiveOr,
        .hardLight, .hardMix, .hue, .lighten, .lighterColor, .linearBurn, .linearDodge,
        .linearLight, .luminosity, .multiply, .overlay, .pinLight, .saturation, .screen,
        .softLight, .source, .sourceAtop, .sourceIn, .sourceOut, .sourceOver, .subtract, .vividLight,
    ]
    precondition(Set(blend.map(\.name)).count == blend.count)
    let raw: [CIRAWDecoderVersion] = [
        .none, .version6, .version6DNG, .version7, .version7DNG, .version8, .version8DNG, .version9, .version9DNG,
    ]
    precondition(Set(raw.map(\.rawValue)).count == raw.count)
    let imageOpts: [CIImageOption] = [
        .applyCleanAperture, .applyOrientationProperty, .auxiliaryDepth, .auxiliaryDisparity,
        .auxiliaryHDRGainMap, .auxiliaryPortraitEffectsMatte, .auxiliarySemanticSegmentationGlassesMatte,
        .auxiliarySemanticSegmentationHairMatte, .auxiliarySemanticSegmentationSkinMatte,
        .auxiliarySemanticSegmentationSkyMatte, .auxiliarySemanticSegmentationTeethMatte,
        .cacheImmediately, .colorSpace, .contentAverageLightLevel, .contentHeadroom, .expandToHDR,
        .nearestSampling, .properties, .providerTileSize, .providerUserInfo, .toneMapHDRtoSDR,
    ]
    precondition(Set(imageOpts.map(\.rawValue)).count == imageOpts.count)
    let auto: [CIImageAutoAdjustmentOption] = [.crop, .enhance, .features, .level, .redEye]
    precondition(Set(auto.map(\.rawValue)).count == auto.count)
    let rep: [CIImageRepresentationOption] = [
        .avDepthData, .avPortraitEffectsMatte, .avSemanticSegmentationMattes, .depthImage,
        .disparityImage, .hdrGainMapAsRGB, .hdrGainMapImage, .hdrImage, .portraitEffectsMatteImage,
        .semanticSegmentationGlassesMatteImage, .semanticSegmentationHairMatteImage,
        .semanticSegmentationSkinMatteImage, .semanticSegmentationSkyMatteImage,
        .semanticSegmentationTeethMatteImage,
    ]
    precondition(Set(rep.map(\.rawValue)).count == rep.count)
    let dyn: [CIDynamicRangeOption] = [.constrainedHigh, .high, .standard]
    precondition(Set(dyn.map(\.rawValue)).count == dyn.count)
    let rawOpts: [CIRAWFilterOption] = [
        .activeKeys, .allowDraftMode, .baselineExposure, .boostAmount, .boostShadowAmount,
        .colorNoiseReductionAmount, .decoderVersion, .disableGamutMap, .enableChromaticNoiseTracking,
        .ciInputEnableEDRModeKey, .enableSharpening, .enableVendorLensCorrection, .ignoreImageOrientation,
        .imageOrientation, .linearSpaceFilter, .ciInputLocalToneMapAmountKey, .luminanceNoiseReductionAmount,
        .moireAmount, .neutralChromaticityX, .neutralChromaticityY, .neutralLocation, .neutralTemperature,
        .neutralTint, .noiseReductionAmount, .noiseReductionContrastAmount, .noiseReductionDetailAmount,
        .noiseReductionSharpnessAmount, .scaleFactor, .outputNativeSize, .propertiesKey,
        .supportedDecoderVersions,
    ]
    precondition(Set(rawOpts.map(\.rawValue)).count == rawOpts.count)
}

func ciTestPixel(_ image: CIImage, rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> (UInt8, UInt8, UInt8, UInt8) {
    let context = CIContext()
    guard let bitmap = context.createCGImage(image, from: rect) else {
        preconditionFailure("createCGImage")
    }
    precondition(bitmap.pixels.count >= 4)
    return (bitmap.pixels[0], bitmap.pixels[1], bitmap.pixels[2], bitmap.pixels[3])
}

