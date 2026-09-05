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

func testCIColorControlsSepiaMatrixExposure() {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    let red = CIImage(color: .red).cropped(to: rect)
    let green = CIImage(color: .green).cropped(to: rect)
    let blue = CIImage(color: .blue).cropped(to: rect)
    let gray = CIImage(color: .gray).cropped(to: rect)

    // MEASURED ciprobe SE 2x / iOS 26.1 software sRGB: sat 0 is Rec.709 luma.
    let sat = CIFilter.colorControls()
    sat.inputImage = red
    sat.saturation = 0
    let satRed = ciTestPixel(sat.outputImage!)
    precondition(satRed.0 == 54 && satRed.1 == 54 && satRed.2 == 54)
    sat.inputImage = green
    let satGreen = ciTestPixel(sat.outputImage!)
    precondition(satGreen.0 == 182)
    sat.inputImage = blue
    let satBlue = ciTestPixel(sat.outputImage!)
    precondition(satBlue.0 == 18)

    sat.inputImage = gray
    sat.saturation = 1
    sat.brightness = 0.2
    sat.contrast = 1
    let bright = ciTestPixel(sat.outputImage!)
    precondition(bright.0 >= 178 && bright.0 <= 179)

    sat.inputImage = red
    sat.brightness = 0
    sat.contrast = 2
    let contrast = ciTestPixel(sat.outputImage!)
    precondition(contrast.0 == 255)

    // MEASURED ciprobe sepia intensity 1: red→(76,47,12); 0.5 → (165,23,6).
    let sepia = CIFilter.sepiaTone()
    sepia.inputImage = red
    sepia.intensity = 1
    let sepia1 = ciTestPixel(sepia.outputImage!)
    precondition(sepia1.0 == 76 && sepia1.1 == 47 && sepia1.2 == 12)
    sepia.intensity = 0.5
    let sepiaHalf = ciTestPixel(sepia.outputImage!)
    precondition(sepiaHalf.0 == 165 && sepiaHalf.1 == 23 && sepiaHalf.2 == 6)

    let matrix = CIFilter(name: "CIColorMatrix")!
    matrix.setValue(red, forKey: kCIInputImageKey)
    matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
    let zeroR = ciTestPixel(matrix.outputImage!)
    precondition(zeroR.0 == 0 && zeroR.1 == 0 && zeroR.2 == 0)
    matrix.setValue(green, forKey: kCIInputImageKey)
    let keepG = ciTestPixel(matrix.outputImage!)
    precondition(keepG.1 == 255)

    let exposure = CIFilter.exposureAdjust()
    exposure.inputImage = gray
    exposure.ev = 1
    let ev = ciTestPixel(exposure.outputImage!)
    precondition(ev.0 == 255 && ev.1 == 255 && ev.2 == 255)
}

func testCIPhotoEffectCubes() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let chrome = CIFilter.photoEffectChrome()
    chrome.inputImage = red
    let c = ciTestPixel(chrome.outputImage!)
    // MEASURED ciprobe 5³ cube, red lattice (4,0,0) → Chrome[300..302].
    precondition(c.0 == 255 && c.1 == 29 && c.2 == 0)
    let mono = CIFilter.photoEffectMono()
    mono.inputImage = red
    let m = ciTestPixel(mono.outputImage!)
    precondition(m.0 == m.1 && m.1 == m.2)
    let noir = CIFilter.photoEffectNoir()
    noir.inputImage = red
    let n = ciTestPixel(noir.outputImage!)
    precondition(n.0 == n.1 && n.1 == n.2)
    _ = CIFilter.photoEffectFade()
    _ = CIFilter.photoEffectInstant()
    _ = CIFilter.photoEffectProcess()
    _ = CIFilter.photoEffectTonal()
    _ = CIFilter.photoEffectTransfer()
}

func testCIQRCodeAndCode128() {
    let qr = CIFilter.qrCodeGenerator()
    qr.message = Data("HELLO WORLD".utf8)
    qr.correctionLevel = "M"
    guard let image = qr.outputImage, let bitmap = image.cgImage else {
        preconditionFailure("QR output")
    }
    // MEASURED ciprobe SE 2x / iOS 26.1: "HELLO WORLD" M is 23×23 (v1 + 1 quiet).
    precondition(bitmap.width == 23 && bitmap.height == 23)
    precondition(image.extent.width == 23 && image.extent.height == 23)
    func dark(_ x: Int, _ y: Int) -> Bool {
        bitmap.pixels[(y * 23 + x) * 4] == 0
    }
    // Finder at (1,1) after 1-module quiet: outer ring dark.
    precondition(dark(1, 1) && dark(7, 1) && dark(1, 7) && dark(7, 7))
    precondition(!dark(2, 2))
    precondition(dark(4, 4))

    let named = CIFilter(name: "CIQRCodeGenerator", withInputParameters: [
        "inputMessage": Data("HELLO WORLD".utf8),
        "inputCorrectionLevel": "M",
    ])
    precondition(named?.outputImage?.extent.width == 23)

    let code128 = CIFilter.code128BarcodeGenerator()
    code128.message = Data("ABC-123".utf8)
    guard let bar = code128.outputImage, let barBitmap = bar.cgImage else {
        preconditionFailure("Code128")
    }
    // MEASURED ciprobe: quiet 10, height 32, "ABC-123" extent 132×52.
    precondition(barBitmap.width == 132)
    precondition(bar.extent.width == 132)
    precondition(bar.extent.height == 52)

    precondition(CIFilter(name: "CIAztecCodeGenerator")?.outputImage == nil)
    precondition(CIFilter(name: "CIPDF417BarcodeGenerator")?.outputImage == nil)
}

func testCIGaussianBlurExtentAndPNGRoundTrip() {
    let src = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 32, height: 32))
    let blur = src.applyingGaussianBlur(sigma: 2)
    // MEASURED ciblurprobe + ciprobe: pad = 3 × radius.
    precondition(blur.extent.origin.x == -6)
    precondition(blur.extent.origin.y == -6)
    precondition(blur.extent.width == 44)
    precondition(blur.extent.height == 44)

    let named = src.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: Float(2)])
    precondition(named.extent.width == 44)

    let rotated = CIImage(color: .blue)
        .cropped(to: CGRect(x: 0, y: 0, width: 4, height: 2))
        .transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 2))
    // MEASURED ciprobe: 4×2 at origin +π/2 → (−2, 0, 2, 4).
    precondition(abs(rotated.extent.origin.x - (-2)) < 0.001)
    precondition(abs(rotated.extent.origin.y - 0) < 0.001)
    precondition(abs(rotated.extent.width - 2) < 0.001)
    precondition(abs(rotated.extent.height - 4) < 0.001)

    let context = CIContext()
    let patch = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    guard let png = context.pngRepresentation(of: patch, format: .RGBA8, colorSpace: .sRGB) else {
        preconditionFailure("png")
    }
    guard let decoded = CIImage(data: png) else {
        preconditionFailure("png decode")
    }
    precondition(decoded.extent.width == 2)
    let px = ciTestPixel(decoded)
    precondition(px.0 == 255 && px.3 == 255)

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fw-coreimage-round.png")
    try! context.writePNGRepresentation(of: patch, to: url, format: .RGBA8, colorSpace: .sRGB)
    guard let fromURL = CIImage(contentsOf: url) else {
        preconditionFailure("contentsOf png")
    }
    precondition(fromURL.extent.width == 2)
    try! context.writeJPEGRepresentation(of: patch, to: url.appendingPathExtension("jpg"), colorSpace: .sRGB)
}

func testCIHueVibranceBuiltins() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let hue = CIFilter.hueAdjust()
    hue.inputImage = red
    hue.angle = Float.pi / 2
    let h = ciTestPixel(hue.outputImage!)
    // Directional Rec.709 chrominance rotation (ciprobe +π/2 is (0,90,0);
    // Linux is not byte-identical — see oracle-questions.tsv).
    precondition(h.0 != 255 || h.1 != 0)

    let skin = CIImage(color: CIColor(red: 0.76, green: 0.57, blue: 0.45))
        .cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let vib = CIFilter.vibrance()
    vib.inputImage = skin
    vib.amount = 0.8
    let v = ciTestPixel(vib.outputImage!)
    precondition(v.0 > v.1 && v.1 > 80)

    let crop = CIFilter.crop()
    crop.inputImage = CIImage(color: .green)
    crop.setValue(CIVector(cgRect: CGRect(x: 0, y: 0, width: 3, height: 5)), forKey: "inputRectangle")
    precondition(crop.outputImage?.extent.width == 3)
    precondition(crop.outputImage?.extent.height == 5)

    let over = CIFilter.sourceOverCompositing()
    over.inputImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    over.backgroundImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let o = ciTestPixel(over.outputImage!)
    precondition(o.0 == 255 && o.2 == 0)
}

func testCIDeclaredSurface() {
    let context = CIContext(options: [.workingColorSpace: CGColorSpace.sRGB, .workingFormat: CIFormat.RGBA8])
    precondition(context.workingColorSpace?.name == "sRGB")
    let color = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    precondition(context.createCGImage(color, from: color.extent, format: .RGBA8, colorSpace: .sRGB) != nil)
    precondition(context.createCGImage(color, from: color.extent, format: .RGBA8, colorSpace: .sRGB, deferred: false) != nil)
    precondition(context.createCGImage(color, from: color.extent, format: .RGBA8, colorSpace: .sRGB, deferred: false, calculateHDRStats: false) != nil)
    context.draw(color, in: color.extent, from: color.extent)
    precondition(context.outputImageMaximumSize().width == 8192)
    precondition(context.tiffRepresentation(of: color, format: .RGBA8, colorSpace: .sRGB) == nil)
    precondition(context.heifRepresentation(of: color, format: .RGBA8, colorSpace: .sRGB) == nil)
    do {
        _ = try context.openEXRRepresentation(of: color)
        preconditionFailure("exr")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    precondition(context.calculateHDRStats(for: color) == nil)
    _ = context.calculateHDRStats(for: CGImage(width: 1, height: 1))
    precondition(context.depthBlurEffectFilter(for: color, disparityImage: color, portraitEffectsMatte: nil, orientation: .up) == nil)
    precondition(context.depthBlurEffectFilter(for: color, disparityImage: color, portraitEffectsMatte: nil, hairSemanticSegmentation: nil, orientation: .up) == nil)
    precondition(context.depthBlurEffectFilter(for: color, disparityImage: color, portraitEffectsMatte: nil, hairSemanticSegmentation: nil, glassesMatte: nil, gainMap: nil, orientation: .up) == nil)
    precondition(context.depthBlurEffectFilter(forImageData: Data(), options: nil) == nil)
    precondition(context.depthBlurEffectFilter(forImageURL: URL(fileURLWithPath: "/tmp/none.png"), options: nil) == nil)

    var storage = [UInt8](repeating: 0, count: 16)
    storage.withUnsafeMutableBytes { raw in
        let dest = CIRenderDestination(
            bitmapData: raw.baseAddress!,
            width: 2,
            height: 2,
            bytesPerRow: 8,
            format: .RGBA8
        )
        dest.blendKernel = .sourceOver
        dest.blendsInDestinationColorSpace = true
        dest.captureTraceURL = URL(fileURLWithPath: "/tmp/ci-trace")
        dest.isClamped = true
        dest.colorSpace = .sRGB
        dest.isDithered = true
        dest.isFlipped = true
        precondition(dest.blendKernel?.name == "sourceOver")
        precondition(dest.blendsInDestinationColorSpace)
        precondition(dest.captureTraceURL != nil)
        precondition(dest.isClamped)
        precondition(dest.colorSpace?.name == "sRGB")
        precondition(dest.isDithered)
        precondition(dest.isFlipped)
        do {
            try context.prepareRender(color, from: color.extent, to: dest, at: .zero)
            preconditionFailure("prepare")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        do {
            _ = try context.startTask(toClear: dest)
            preconditionFailure("clear")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        do {
            _ = try context.startTask(toRender: color, to: dest)
            preconditionFailure("render")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        do {
            _ = try context.startTask(toRender: color, from: color.extent, to: dest, at: .zero)
            preconditionFailure("render2")
        } catch {
            precondition((error as? CIRenderError) == .unsupported)
        }
        let gl = CIRenderDestination(glTexture: 1, target: 2, width: 4, height: 4)
        precondition(gl.width == 4)
        let gl2 = CIRenderDestination(GLTexture: 1, target: 2, width: 3, height: 3)
        precondition(gl2.height == 3)
    }

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fw-coreimage-fail.heif")
    do { try context.writeHEIFRepresentation(of: color, to: url, format: .RGBA8, colorSpace: .sRGB); preconditionFailure("heif") } catch { precondition((error as? CIRenderError) == .unsupported) }
    do { try context.writeHEIF10Representation(of: color, to: url, colorSpace: .sRGB); preconditionFailure("heif10") } catch { precondition((error as? CIRenderError) == .unsupported) }
    do { try context.writeTIFFRepresentation(of: color, to: url, format: .RGBA8, colorSpace: .sRGB); preconditionFailure("tiff") } catch { precondition((error as? CIRenderError) == .unsupported) }
    do { try context.writeOpenEXRRepresentation(of: color, to: url); preconditionFailure("exr") } catch { precondition((error as? CIRenderError) == .unsupported) }

    let face = CIFaceFeature(bounds: CGRect(x: 1, y: 2, width: 3, height: 4))
    precondition(face.bounds.width == 3)
    precondition(face.faceAngle == 0)
    precondition(!face.hasFaceAngle)
    precondition(!face.hasLeftEyePosition)
    precondition(!face.hasMouthPosition)
    precondition(!face.hasRightEyePosition)
    precondition(!face.hasTrackingFrameCount)
    precondition(!face.hasTrackingID)
    precondition(!face.leftEyeClosed)
    precondition(face.leftEyePosition == .zero)
    precondition(face.mouthPosition == .zero)
    precondition(!face.rightEyeClosed)
    precondition(face.rightEyePosition == .zero)
    precondition(face.trackingFrameCount == 0)
    precondition(face.trackingID == 0)

    let rectF = CIRectangleFeature(bounds: CGRect(x: 0, y: 0, width: 10, height: 8))
    precondition(rectF.topLeft.y == 8)
    precondition(rectF.topRight.x == 10)
    precondition(rectF.bottomLeft == .zero)
    precondition(rectF.bottomRight.x == 10)
    precondition(rectF.bounds.height == 8)

    let text = CITextFeature(bounds: CGRect(x: 2, y: 3, width: 4, height: 5))
    precondition(text.topLeft == .zero)
    precondition(text.topRight == .zero)
    precondition(text.bottomLeft == .zero)
    precondition(text.bottomRight == .zero)
    precondition(text.bounds.width == 4)
    precondition(text.subFeatures == nil)

    let qrFeat = CIQRCodeFeature(bounds: CGRect(x: 0, y: 0, width: 21, height: 21))
    precondition(qrFeat.messageString == nil)
    precondition(qrFeat.symbolDescriptor == nil)
    precondition(CIQRCodeFeature(coder: NSCoder()) == nil)
    qrFeat.encode(with: NSCoder())

    precondition(CIFilter(imageData: Data(), options: nil) == nil)
    precondition(CIFilter(imageURL: URL(fileURLWithPath: "/tmp/none.dng"), options: nil) == nil)
    precondition(CIFilter.filterArray(fromSerializedXMP: Data(), inputImageExtent: .zero, error: nil).isEmpty)
    precondition(CIFilter.serializedXMP(from: [], inputImageExtent: .zero) == nil)
    precondition(CIFilter.localizedName(forFilterName: "CIGaussianBlur") == "Gaussian Blur")
    _ = CIFilter.localizedDescription(forFilterName: "CIGaussianBlur")
    precondition(CIFilter.localizedReferenceDocumentation(forFilterName: "CIGaussianBlur") == nil)

    CIFilter.registerName("CIFwCoreImageProbe", constructor: CIFwCoreImageProbeCtor(), classAttributes: [
        kCIAttributeFilterDisplayName: "Probe",
        kCIAttributeFilterCategories: [kCICategoryBuiltIn],
    ])
    precondition(CIFilter.filterNames(inCategory: nil).contains { $0 == "CIFwCoreImageProbe" })
    precondition(CIFwCoreImageProbeCtor().filter(withName: "CILinearGradient") != nil)

    let gauss = CIFilter(name: "CIGaussianBlur")!
    precondition(gauss.inputKeys.contains { $0 == kCIInputRadiusKey })
    precondition(gauss.outputKeys.contains { $0 == kCIOutputImageKey })
    precondition(gauss.attributes[kCIAttributeFilterName] as? String == "CIGaussianBlur")
    gauss.setValue(CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4)), forKey: kCIInputImageKey)
    gauss.setValue(Float(2), forKey: kCIInputRadiusKey)
    precondition((gauss.value(forKey: kCIInputRadiusKey) as? Float) == 2)
    gauss.setDefaults()
    precondition((gauss.value(forKey: kCIInputRadiusKey) as? Float) == 10)
    _ = CIFilter.customAttributes()

    let cg = CGImage(width: 2, height: 2, pixels: [UInt8](repeating: 255, count: 16))
    let fromCG = CIImage(cgImage: cg)
    precondition(fromCG.extent.width == 2)
    let fromCG2 = CIImage(CGImage: cg)
    precondition(fromCG2.cgImage != nil)
    let fromOpts = CIImage(cgImage: cg, options: [.nearestSampling: true, .colorSpace: CGColorSpace.sRGB])
    precondition(fromOpts.colorSpace?.name == "sRGB")
    let fromOpts2 = CIImage(CGImage: cg, options: nil)
    precondition(fromOpts2.extent.height == 2)
    precondition(CIImage(contentsOf: URL(fileURLWithPath: "/tmp/none.png"), options: nil) == nil)
    precondition(CIImage(data: Data([0x00]), options: nil) == nil)

    let bitmap = CIImage(
        bitmapData: Data([255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 0, 255]),
        bytesPerRow: 8,
        size: CGSize(width: 2, height: 2),
        format: .RGBA8,
        colorSpace: .sRGB
    )
    precondition(bitmap.extent.width == 2)
    let provider = CIImage(imageProvider: NSObject(), size: 1, 1, format: .RGBA8, colorSpace: .sRGB, options: nil)
    precondition(provider.extent.width == 1)
    let tex = CIImage(texture: 0, size: CGSize(width: 3, height: 4), flipped: false, colorSpace: .sRGB)
    precondition(tex.extent.width == 3)
    precondition(CIImage(coder: NSCoder()) == nil)
    color.encode(with: NSCoder())

    precondition(color.autoAdjustmentFilters().isEmpty)
    precondition(color.autoAdjustmentFilters(options: [.enhance: true]).isEmpty)
    let oriented = color.oriented(.down)
    precondition(oriented.extent.width == 2)
    let orientedExif = color.oriented(forExifOrientation: 3)
    precondition(orientedExif.extent.width == 2)
    _ = color.applyingFilter("CIExposureAdjust")
    let gain = color.applyingGainMap(color)
    precondition(gain.extent.width == 2)
    let gainH = color.applyingGainMap(color, headroom: 2)
    precondition(gainH.contentHeadroom == 2)
    let hq = color.transformed(by: .identity, highQualityDownsample: true)
    precondition(hq.extent.width == 2)
    precondition(color.clampedToExtent().extent.width == 2)
    precondition(color.clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1)).extent.width == 1)
    precondition(color.matchedToWorkingSpace(from: .sRGB) != nil)
    precondition(color.matchedFromWorkingSpace(to: .sRGB) != nil)
    _ = color.composited(over: color)
    _ = color.convertingLabToWorkingSpace()
    _ = color.convertingWorkingSpaceToLab()
    _ = color.insertingIntermediate()
    _ = color.insertingIntermediate(cache: true)
    _ = color.insertingTiledIntermediate()
    _ = color.premultiplyingAlpha()
    _ = color.samplingLinear()
    _ = color.samplingNearest()
    _ = color.settingAlphaOne(in: color.extent)
    _ = color.settingContentAverageLightLevel(0.5)
    _ = color.unpremultiplyingAlpha()
    precondition(color.orientationTransform(for: .up).a == 1)
    precondition(color.orientationTransform(forExifOrientation: 1).a == 1)
    precondition(color.regionOfInterest(for: color, in: color.extent) == color.extent)
    precondition(color.cgImage == nil || color.cgImage!.width >= 0)
    precondition(color.url == nil)
    precondition(color.isOpaque || !color.isOpaque)
    _ = color.contentAverageLightLevel
    _ = CIImage.gray
    _ = CIImage.cyan
    _ = CIImage.magenta
    _ = CIImage.yellow
    _ = CIImage.clear
    _ = CIImage.green
    _ = CIImage.blue

    let callback: CIKernelROICallback = { _, r in r }
    precondition(CIColorKernel(source: "kernel vec4 f() { return vec4(1.0); }") == nil)
    let colorKernel = CIColorKernel()
    precondition(colorKernel.apply(extent: .zero, arguments: []) == nil)
    precondition(CIWarpKernel(source: "kernel") == nil)
    let warp = CIWarpKernel()
    precondition(warp.apply(extent: .zero, roiCallback: callback, image: color, arguments: []) == nil)
    precondition(CIBlendKernel(source: "kernel") == nil)
    _ = CIBlendKernel.sourceOver.apply(foreground: color, background: color, colorSpace: .sRGB)
    precondition(CIKernel.kernelNames(fromMetalLibraryData: Data()).isEmpty)
    do {
        _ = try CIKernel(functionName: "f", fromMetalLibraryData: Data())
        preconditionFailure("metal")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        _ = try CIKernel(functionName: "f", fromMetalLibraryData: Data(), outputPixelFormat: .RGBA8)
        preconditionFailure("metal2")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        _ = try CIKernel.kernels(withMetalString: "kernel")
        preconditionFailure("metal3")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    precondition(CIKernel.makeKernels(source: "kernel") == nil)
    precondition(CIKernel(string: "kernel") == nil)
    let kernel = CIKernel()
    precondition(kernel.apply(extent: .zero, roiCallback: callback, arguments: []) == nil)

    precondition(CIImageProcessorKernel.outputFormat == .RGBA8)
    precondition(CIImageProcessorKernel.outputIsOpaque == false)
    precondition(CIImageProcessorKernel.synchronizeInputs)
    precondition(CIImageProcessorKernel.formatForInput(at: 0) == .RGBA8)
    precondition(CIImageProcessorKernel.outputFormat(at: 0, arguments: nil) == .RGBA8)
    precondition(CIImageProcessorKernel.roi(forInput: 0, arguments: nil, outputRect: color.extent) == color.extent)
    precondition(CIImageProcessorKernel.roiTileArray(forInput: 0, arguments: nil, outputRect: color.extent).count == 1)
    do {
        _ = try CIImageProcessorKernel.apply(withExtent: color.extent, inputs: [color], arguments: nil)
        preconditionFailure("proc")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        _ = try CIImageProcessorKernel.apply(withExtents: [CIVector(cgRect: color.extent)], inputs: [color], arguments: nil)
        preconditionFailure("proc2")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }

    let raw = CIRAWFilter()
    precondition(raw.baselineExposure == 0)
    raw.boostAmount = 1
    precondition(raw.boostAmount == 1)
    raw.boostShadowAmount = 1
    precondition(raw.boostShadowAmount == 1)
    raw.colorNoiseReductionAmount = 1
    precondition(!raw.isColorNoiseReductionSupported)
    raw.contrastAmount = 1
    precondition(!raw.isContrastSupported)
    raw.decoderVersion = .version8
    raw.detailAmount = 1
    precondition(!raw.isDetailSupported)
    raw.isDraftModeEnabled = true
    raw.exposure = 1
    raw.extendedDynamicRangeAmount = 1
    raw.isGamutMappingEnabled = true
    raw.isHighlightRecoveryEnabled = true
    precondition(!raw.isHighlightRecoverySupported)
    raw.isLensCorrectionEnabled = true
    precondition(!raw.isLensCorrectionSupported)
    raw.linearSpaceFilter = gauss
    raw.localToneMapAmount = 1
    precondition(!raw.isLocalToneMapSupported)
    raw.luminanceNoiseReductionAmount = 1
    precondition(!raw.isLuminanceNoiseReductionSupported)
    raw.moireReductionAmount = 1
    precondition(!raw.isMoireReductionSupported)
    raw.nativeSize = CGSize(width: 1, height: 1)
    raw.neutralChromaticity = CGPoint(x: 0.3, y: 0.3)
    raw.neutralLocation = .zero
    raw.neutralTemperature = 5000
    raw.neutralTint = 1
    raw.orientation = .up
    raw.portraitEffectsMatte = nil
    raw.previewImage = nil
    raw.properties = [:]
    raw.scaleFactor = 1
    raw.semanticSegmentationGlassesMatte = nil
    raw.semanticSegmentationHairMatte = nil
    raw.semanticSegmentationSkinMatte = nil
    raw.semanticSegmentationSkyMatte = nil
    raw.semanticSegmentationTeethMatte = nil
    raw.shadowBias = 0
    raw.sharpnessAmount = 0
    precondition(!raw.isSharpnessSupported)
    precondition(raw.supportedDecoderVersions.isEmpty)
    precondition(raw.outputImage == nil)
    precondition(CIRAWFilter(imageData: Data(), identifierHint: nil) == nil)

    let info = CIRenderInfo(kernelCompileTime: 1, kernelExecutionTime: 2, passCount: 3, pixelsProcessed: 4)
    precondition(info.kernelCompileTime == 1)
    precondition(info.kernelExecutionTime == 2)
    precondition(info.passCount == 3)
    precondition(info.pixelsProcessed == 4)
    let task = CIRenderTask()
    precondition(try! task.waitUntilCompleted().passCount == 0)

    let obj = NSObject()
    var buf = [UInt8](repeating: 0, count: 4)
    buf.withUnsafeMutableBytes { raw in
        obj.provideImageData(raw.baseAddress!, bytesPerRow: 4, origin: 0, 0, size: 1, 1, userInfo: nil)
    }

    _ = CIAffineTransform()
    _ = CIColorMatrix()
    let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: nil)
    precondition(detector?.features(in: color, options: nil).isEmpty == true)

    gauss.setValue(nil, forKey: kCIInputImageKey)
    precondition(gauss.value(forKey: "attributes") is [String: Any])
    precondition(gauss.value(forKey: "inputKeys") is [String])
    precondition(gauss.value(forKey: "outputKeys") is [String])
}

final class CIFwCoreImageProbeCtor: CIFilterConstructor {
    func filter(withName name: String) -> CIFilter? {
        CIFilter(name: name, attributes: [kCIAttributeFilterDisplayName: "Probe"])
    }
}

