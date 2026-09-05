import CoreImage
import Foundation

func testCIFilterNameKeysAndAttributes() {
    let names = CIFilter.filterNames(inCategories: nil)
    for required in [
        "CIGaussianBlur", "CIColorControls", "CISepiaTone", "CIColorMatrix",
        "CIExposureAdjust", "CIVibrance", "CIHueAdjust", "CICrop",
        "CIAffineTransform", "CISourceOverCompositing", "CIQRCodeGenerator",
        "CICode128BarcodeGenerator", "CIPhotoEffectChrome", "CIPhotoEffectMono",
    ] {
        precondition(names.contains(required), required)
    }
    guard let gauss = CIFilter(name: "CIGaussianBlur") else {
        preconditionFailure("CIGaussianBlur registry")
    }
    precondition(gauss.name == "CIGaussianBlur")
    precondition(gauss.inputKeys.contains(kCIInputImageKey))
    precondition(gauss.inputKeys.contains(kCIInputRadiusKey))
    precondition(gauss.outputKeys.contains(kCIOutputImageKey))
    precondition(gauss.attributes[kCIAttributeFilterName] as? String == "CIGaussianBlur")
    precondition(gauss.attributes[kCIAttributeFilterDisplayName] as? String == "Gaussian Blur")
    let cats = gauss.attributes[kCIAttributeFilterCategories] as? [String] ?? []
    precondition(cats.contains(kCICategoryBlur))
    let radiusAttrs = gauss.attributes[kCIInputRadiusKey] as? [String: Any]
    precondition(radiusAttrs?[kCIAttributeClass] as? String == "NSNumber")
    precondition(radiusAttrs?[kCIAttributeType] as? String == kCIAttributeTypeDistance)
    precondition((radiusAttrs?[kCIAttributeDefault] as? NSNumber)?.floatValue == 10)
    gauss.setValue(CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4)), forKey: kCIInputImageKey)
    gauss.setValue(Float(2), forKey: kCIInputRadiusKey)
    precondition((gauss.value(forKey: kCIInputRadiusKey) as? Float) == 2)
    gauss.setDefaults()
    precondition((gauss.value(forKey: kCIInputRadiusKey) as? Float) == 10)

    let controls = CIFilter(name: "CIColorControls")!
    let keys = controls.inputKeys
    precondition(keys.contains(kCIInputSaturationKey))
    precondition(keys.contains(kCIInputBrightnessKey))
    precondition(keys.contains(kCIInputContrastKey))
    let sat = controls.attributes[kCIInputSaturationKey] as? [String: Any]
    precondition((sat?[kCIAttributeDefault] as? NSNumber)?.floatValue == 1)

    let matrix = CIFilter(name: "CIColorMatrix")!
    precondition(matrix.inputKeys.contains("inputRVector"))
    precondition(matrix.inputKeys.contains("inputBiasVector"))
    let crop = CIFilter(name: "CICrop")!
    precondition(crop.inputKeys.contains("inputRectangle"))
    let qr = CIFilter(name: "CIQRCodeGenerator")!
    precondition(qr.inputKeys.contains("inputMessage"))
    precondition(qr.inputKeys.contains("inputCorrectionLevel"))
    precondition(CIFilter.localizedName(forFilterName: "CIGaussianBlur") == "Gaussian Blur")
    precondition(CIFilter.localizedName(forCategory: kCICategoryBlur) == kCICategoryBlur)
    precondition(CIFilter(name: "CIDoesNotExist") == nil)
}

func testCIFilterBuiltinsProperties() {
    let blur = CIFilter.gaussianBlur()
    blur.inputImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
    blur.radius = 2
    precondition(blur.radius == 2)
    precondition(blur.name == "CIGaussianBlur")
    precondition(blur.outputImage != nil)

    let controls = CIFilter.colorControls()
    controls.saturation = 0
    controls.brightness = 0.1
    controls.contrast = 1.2
    precondition(controls.saturation == 0)
    precondition(abs(controls.brightness - 0.1) < 0.0001)
    precondition(abs(controls.contrast - 1.2) < 0.0001)

    let sepia = CIFilter.sepiaTone()
    sepia.intensity = 0.5
    precondition(sepia.intensity == 0.5)
    let exposure = CIFilter.exposureAdjust()
    exposure.ev = 1
    precondition(exposure.ev == 1)
    let vibrance = CIFilter.vibrance()
    vibrance.amount = 0.8
    precondition(abs(vibrance.amount - 0.8) < 0.0001)
    let hue = CIFilter.hueAdjust()
    hue.angle = Float.pi / 2
    precondition(abs(hue.angle - Float.pi / 2) < 0.0001)
    _ = CIFilter.colorMatrix()
    _ = CIFilter.crop()
    _ = CIFilter.affineTransform()
    _ = CIFilter.sourceOverCompositing()
    _ = CIFilter.photoEffectChrome()
    _ = CIFilter.photoEffectFade()
    _ = CIFilter.photoEffectInstant()
    _ = CIFilter.photoEffectMono()
    _ = CIFilter.photoEffectNoir()
    _ = CIFilter.photoEffectProcess()
    _ = CIFilter.photoEffectTonal()
    _ = CIFilter.photoEffectTransfer()
}

func testCIColorControlsPixelFormula() {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    let red = CIImage(color: .red).cropped(to: rect)
    let green = CIImage(color: .green).cropped(to: rect)
    let blue = CIImage(color: .blue).cropped(to: rect)
    let gray = CIImage(color: .gray).cropped(to: rect)

    // Apple CIColorControls Rec.709 luma: Y = 0.2126 R + 0.7152 G + 0.0722 B
    // sat=0 of red → 0.2126*255 = 54.213 → 54
    let sat = CIFilter.colorControls()
    sat.inputImage = red
    sat.saturation = 0
    let satRed = ciTestPixel(sat.outputImage!)
    precondition(satRed.0 == 54 && satRed.1 == 54 && satRed.2 == 54)
    sat.inputImage = green
    let satGreen = ciTestPixel(sat.outputImage!)
    precondition(satGreen.0 == 182) // 0.7152*255 = 182.376
    sat.inputImage = blue
    let satBlue = ciTestPixel(sat.outputImage!)
    precondition(satBlue.0 == 18) // 0.0722*255 = 18.411

    // brightness is additive: gray 0.5 + 0.2 = 0.7 → 178.5 → 179? 0.7*255=178.5 → 179
    sat.inputImage = gray
    sat.saturation = 1
    sat.brightness = 0.2
    sat.contrast = 1
    let bright = ciTestPixel(sat.outputImage!)
    precondition(bright.0 == 179)

    // contrast 2 of red: (1-0.5)*2+0.5 = 1.5 → clamp 1 → 255
    sat.inputImage = red
    sat.brightness = 0
    sat.contrast = 2
    let contrast = ciTestPixel(sat.outputImage!)
    precondition(contrast.0 == 255)
}

func testCISepiaTonePixelFormula() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let sepia = CIFilter.sepiaTone()
    sepia.inputImage = red
    sepia.intensity = 1
    let sepia1 = ciTestPixel(sepia.outputImage!)
    // Apple CISepiaTone matrix on (1,0,0):
    // r=0.393 → 100.215 → 100; g=0.349 → 88.995 → 89; b=0.272 → 69.36 → 69
    precondition(sepia1.0 == 100 && sepia1.1 == 89 && sepia1.2 == 69)
    sepia.intensity = 0.5
    let sepiaHalf = ciTestPixel(sepia.outputImage!)
    // mix(identity, sepia, 0.5): r=0.6965→177.608→178; g=0.1745→44.498→44; b=0.136→34.68→35
    precondition(sepiaHalf.0 == 178 && sepiaHalf.1 == 44 && sepiaHalf.2 == 35)
}

func testCIColorMatrixAndExposurePixelFormula() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let green = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let gray = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))

    let matrix = CIFilter(name: "CIColorMatrix", withInputParameters: [
        kCIInputImageKey: red,
        "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
    ])!
    let zeroR = ciTestPixel(matrix.outputImage!)
    precondition(zeroR.0 == 0 && zeroR.1 == 0 && zeroR.2 == 0)
    matrix.setValue(green, forKey: kCIInputImageKey)
    let keepG = ciTestPixel(matrix.outputImage!)
    precondition(keepG.1 == 255)

    let exposure = CIFilter.exposureAdjust()
    exposure.inputImage = gray
    exposure.ev = 1
    let ev = ciTestPixel(exposure.outputImage!)
    // Apple CIExposureAdjust: 0.5 * 2^1 = 1 → (255,255,255)
    precondition(ev.0 == 255 && ev.1 == 255 && ev.2 == 255)
}

func testCIHueVibrancePixelFormula() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let hue = CIFilter.hueAdjust()
    hue.inputImage = red
    hue.angle = 0
    let ident = ciTestPixel(hue.outputImage!)
    precondition(ident.0 == 255 && ident.1 == 0 && ident.2 == 0)
    let viaName = red.applyingFilter("CIHueAdjust")
    precondition(viaName.extent.width == 1)
    hue.angle = Float.pi / 2
    let rotated = ciTestPixel(hue.outputImage!)
    // Rec.709 Y=0.2126, U=0.7874, V=-0.2126; +π/2 → (108, 0, 255)
    precondition(rotated.0 == 108 && rotated.1 == 0 && rotated.2 == 255)

    let skin = CIImage(color: CIColor(red: 0.76, green: 0.57, blue: 0.45))
        .cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let vib = CIFilter.vibrance()
    vib.inputImage = skin
    vib.amount = 0.8
    let v = ciTestPixel(vib.outputImage!)
    // Y=0.60173, scale=1.192 → (202, 144, 107)
    precondition(v.0 == 202 && v.1 == 144 && v.2 == 107)
}

func testCIGaussianBlurExtentAndConstantRaster() {
    let src = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 32, height: 32))
    let blur = src.applyingGaussianBlur(sigma: 2)
    precondition(blur.extent.origin.x == -6)
    precondition(blur.extent.origin.y == -6)
    precondition(blur.extent.width == 44)
    precondition(blur.extent.height == 44)
    let named = src.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: Float(2)])
    precondition(named.extent.width == 44)
    // Gaussian of a constant field is the constant (hand-computed interior raster).
    let interior = ciTestPixel(named, rect: CGRect(x: 16, y: 16, width: 1, height: 1))
    precondition(interior.0 == 255 && interior.1 == 0 && interior.2 == 0 && interior.3 == 255)
}

func testCICropAffineAndSourceOverFilters() {
    let crop = CIFilter.crop()
    crop.inputImage = CIImage(color: .green)
    crop.setValue(CIVector(cgRect: CGRect(x: 0, y: 0, width: 3, height: 5)), forKey: "inputRectangle")
    precondition(crop.outputImage?.extent.width == 3)
    precondition(crop.outputImage?.extent.height == 5)

    let affine = CIFilter.affineTransform()
    affine.inputImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
    affine.setValue(CIVector(cgAffineTransform: CGAffineTransform(translationX: 3, y: 4)), forKey: kCIInputTransformKey)
    precondition(affine.outputImage?.extent.origin.x == 3)
    precondition(affine.outputImage?.extent.origin.y == 4)

    let over = CIFilter.sourceOverCompositing()
    over.inputImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    over.backgroundImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let o = ciTestPixel(over.outputImage!)
    precondition(o.0 == 255 && o.2 == 0)
}

func testCIPhotoEffectCubes() {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let chrome = CIFilter.photoEffectChrome()
    chrome.inputImage = red
    let c = ciTestPixel(chrome.outputImage!)
    // 5³ lattice sample at (4,0,0) of the Chrome cube (last r-plane, g=0, b=0).
    precondition(c.0 == 255 && c.1 == 29 && c.2 == 0)
    let mono = CIFilter.photoEffectMono()
    mono.inputImage = red
    let m = ciTestPixel(mono.outputImage!)
    precondition(m.0 == m.1 && m.1 == m.2)
    let noir = CIFilter.photoEffectNoir()
    noir.inputImage = red
    let n = ciTestPixel(noir.outputImage!)
    precondition(n.0 == n.1 && n.1 == n.2)
    precondition(CIFilter.localizedDescription(forFilterName: "CIPhotoEffectChrome") == nil)
}

func testCIFilterRegisterName() {
    CIFilter.registerName("CIFwCoreImageProbe", constructor: CIFwCoreImageProbeCtor(), classAttributes: [
        kCIAttributeFilterDisplayName: "Probe",
        kCIAttributeFilterCategories: [kCICategoryBuiltIn],
    ])
    precondition(CIFilter.filterNames(inCategory: nil).contains("CIFwCoreImageProbe"))
    precondition(CIFwCoreImageProbeCtor().filter(withName: "CILinearGradient") != nil)
    _ = CIFilter.customAttributes()
}

final class CIFwCoreImageProbeCtor: CIFilterConstructor {
    func filter(withName name: String) -> CIFilter? {
        CIFilter(name: name, attributes: [kCIAttributeFilterDisplayName: "Probe"])
    }
}
