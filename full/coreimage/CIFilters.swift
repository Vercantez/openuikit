import Foundation
#if canImport(Glibc)
import Glibc
#else
import func Darwin.cos
import func Darwin.sin
import func Darwin.pow
#endif

/// Named-filter evaluation and CIFilterBuiltins factories.
/// Color math is the sRGB-working-space formulas MEASURED iPhone SE 2x /
/// iOS 26.1 ciprobe (software renderer, kCIContextWorkingColorSpace = sRGB).

func ciApplyNamedFilter(_ name: String, inputs: [String: Any]) -> CIImage? {
    switch name {
    case "CILinearGradient", "CISmoothLinearGradient":
        let color0 = (inputs[kCIInputColor0Key] as? CIColor) ?? .black
        let color1 = (inputs[kCIInputColor1Key] as? CIColor) ?? .clear
        let point0 = ciPoint(inputs[kCIInputPoint0Key], fallback: .zero)
        let point1 = ciPoint(inputs[kCIInputPoint1Key], fallback: CGPoint(x: 0, y: 1))
        return CIImage(
            node: .gradient(
                color0: color0, color1: color1, point0: point0, point1: point1, extent: .infinite
            )
        )
    case "CIConstantColorGenerator":
        return CIImage(color: (inputs[kCIInputColorKey] as? CIColor) ?? .white)
    case "CIGaussianBlur":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .blurred(image, radius: ciScalar(inputs[kCIInputRadiusKey], 10)))
    case "CIColorControls":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .adjusted(image, .colorControls(
            saturation: ciScalar(inputs[kCIInputSaturationKey], 1),
            brightness: ciScalar(inputs[kCIInputBrightnessKey], 0),
            contrast: ciScalar(inputs[kCIInputContrastKey], 1)
        )))
    case "CISepiaTone":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .adjusted(image, .sepia(ciScalar(inputs[kCIInputIntensityKey], 1))))
    case "CIColorMatrix":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        let identR = CIVector(x: 1, y: 0, z: 0, w: 0)
        let identG = CIVector(x: 0, y: 1, z: 0, w: 0)
        let identB = CIVector(x: 0, y: 0, z: 1, w: 0)
        let identA = CIVector(x: 0, y: 0, z: 0, w: 1)
        let zero = CIVector(x: 0, y: 0, z: 0, w: 0)
        return CIImage(node: .adjusted(image, .matrix(
            r: (inputs["inputRVector"] as? CIVector) ?? identR,
            g: (inputs["inputGVector"] as? CIVector) ?? identG,
            b: (inputs["inputBVector"] as? CIVector) ?? identB,
            a: (inputs["inputAVector"] as? CIVector) ?? identA,
            bias: (inputs["inputBiasVector"] as? CIVector) ?? zero
        )))
    case "CIExposureAdjust":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .adjusted(image, .exposure(ciScalar(inputs[kCIInputEVKey], 0))))
    case "CIVibrance":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .adjusted(image, .vibrance(ciScalar(inputs[kCIInputAmountKey], 0))))
    case "CIHueAdjust":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .adjusted(image, .hue(ciScalar(inputs[kCIInputAngleKey], 0))))
    case "CICrop":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        let rect = (inputs["inputRectangle"] as? CIVector)?.cgRectValue
            ?? CGRect(x: 0, y: 0, width: 0, height: 0)
        return image.cropped(to: rect)
    case "CIAffineTransform":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        let t = (inputs[kCIInputTransformKey] as? CIVector)?.cgAffineTransformValue
            ?? .identity
        return image.transformed(by: t)
    case "CISourceOverCompositing":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        guard let bg = inputs[kCIInputBackgroundImageKey] as? CIImage else { return image }
        return image.composited(over: bg)
    case "CIQRCodeGenerator":
        let data = (inputs["inputMessage"] as? Data) ?? Data()
        let level = (inputs["inputCorrectionLevel"] as? String) ?? "M"
        guard let bitmap = ciEncodeQR(data, level: level) else { return nil }
        return CIImage(cgImage: bitmap)
    case "CICode128BarcodeGenerator":
        let data = (inputs["inputMessage"] as? Data) ?? Data()
        let quiet = Int(ciScalar(inputs["inputQuietSpace"], 10).rounded())
        let height = Int(ciScalar(inputs["inputBarcodeHeight"], 32).rounded())
        guard let bitmap = ciEncodeCode128(data, quiet: quiet, height: height) else { return nil }
        return CIImage(cgImage: bitmap)
    case "CIAztecCodeGenerator", "CIPDF417BarcodeGenerator":
        return nil
    case "CIPhotoEffectChrome", "CIPhotoEffectFade", "CIPhotoEffectInstant",
         "CIPhotoEffectMono", "CIPhotoEffectNoir", "CIPhotoEffectProcess",
         "CIPhotoEffectTonal", "CIPhotoEffectTransfer":
        guard let image = inputs[kCIInputImageKey] as? CIImage else { return nil }
        return CIImage(node: .adjusted(image, .photo(name)))
    default:
        return nil
    }
}

func ciApplyColorOp(_ op: CIColorOp, _ s: (CGFloat, CGFloat, CGFloat, CGFloat)) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    let r = s.0, g = s.1, b = s.2, a = s.3
    switch op {
    case .sepia(let intensity):
        // MEASURED ciprobe intensity 1 sRGB: red→(76,47,12), green→(196,176,124),
        // blue→(33,15,2). Intensity mixes with identity in working-space
        // values (red 0.5 → (165,23,6)).
        let sr = (76.0 / 255) * r + (196.0 / 255) * g + (33.0 / 255) * b
        let sg = (47.0 / 255) * r + (176.0 / 255) * g + (15.0 / 255) * b
        let sb = (12.0 / 255) * r + (124.0 / 255) * g + (2.0 / 255) * b
        let t = ciClamp01(intensity)
        return (
            ciClamp01(r * (1 - t) + CGFloat(sr) * t),
            ciClamp01(g * (1 - t) + CGFloat(sg) * t),
            ciClamp01(b * (1 - t) + CGFloat(sb) * t),
            a
        )
    case .colorControls(let saturation, let brightness, let contrast):
        // MEASURED ciprobe: sat 0 of RGB primaries is Rec.709 luma
        // (54, 182, 18); brightness is additive; contrast is
        // (c-0.5)*contrast+0.5. Order: saturation, contrast, brightness.
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        var rr = y + saturation * (r - y)
        var gg = y + saturation * (g - y)
        var bb = y + saturation * (b - y)
        rr = (rr - 0.5) * contrast + 0.5
        gg = (gg - 0.5) * contrast + 0.5
        bb = (bb - 0.5) * contrast + 0.5
        rr += brightness
        gg += brightness
        bb += brightness
        return (ciClamp01(rr), ciClamp01(gg), ciClamp01(bb), a)
    case .matrix(let rv, let gv, let bv, let av, let bias):
        let rr = r * rv.x + g * rv.y + b * rv.z + a * rv.w + bias.x
        let gg = r * gv.x + g * gv.y + b * gv.z + a * gv.w + bias.y
        let bb = r * bv.x + g * bv.y + b * bv.z + a * bv.w + bias.z
        let aa = r * av.x + g * av.y + b * av.z + a * av.w + bias.w
        return (ciClamp01(rr), ciClamp01(gg), ciClamp01(bb), ciClamp01(aa))
    case .exposure(let ev):
        // MEASURED ciprobe sRGB working space: gray 0.5, EV+1 → (255,255,255)
        // i.e. multiply in working-space values, then clamp.
        let scale = CGFloat(pow(2.0, Double(ev)))
        return (ciClamp01(r * scale), ciClamp01(g * scale), ciClamp01(b * scale), a)
    case .hue(let angle):
        // Chrominance rotation in Rec.709 Y / (R-Y, B-Y). MEASURED ciprobe
        // +π/2: red (255,0,0) → (0,90,0); +π: red → (0,108,108).
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let u = r - y
        let v = b - y
        let c = CGFloat(cos(Double(angle)))
        let s = CGFloat(sin(Double(angle)))
        let u2 = u * c - v * s
        let v2 = u * s + v * c
        return (ciClamp01(y + u2), ciClamp01(y - 0.509 * u2 - 0.194 * v2), ciClamp01(y + v2), a)
    case .vibrance(let amount):
        // MEASURED ciprobe amount 0.8: skin (0.76,0.57,0.45) → (208,143,103)/255.
        // scale = 1 + amount * (1 - max(r,g,b)); mix Rec.709 luma toward color.
        let mx = max(r, max(g, b))
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let scale = 1 + amount * (1 - mx)
        return (
            ciClamp01(y + scale * (r - y)),
            ciClamp01(y + scale * (g - y)),
            ciClamp01(y + scale * (b - y)),
            a
        )
    case .photo(let name):
        return ciPhotoCubeSample(name, r: r, g: g, b: b, a: a)
    }
}

func ciPhotoCubeSample(_ name: String, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    let cube: [UInt8]
    switch name {
    case "CIPhotoEffectChrome": cube = CIPhotoCube.Chrome
    case "CIPhotoEffectFade": cube = CIPhotoCube.Fade
    case "CIPhotoEffectInstant": cube = CIPhotoCube.Instant
    case "CIPhotoEffectMono": cube = CIPhotoCube.Mono
    case "CIPhotoEffectNoir": cube = CIPhotoCube.Noir
    case "CIPhotoEffectProcess": cube = CIPhotoCube.Process
    case "CIPhotoEffectTonal": cube = CIPhotoCube.Tonal
    case "CIPhotoEffectTransfer": cube = CIPhotoCube.Transfer
    default: return (r, g, b, a)
    }
    func lerp(_ t: CGFloat) -> (Int, Int, CGFloat) {
        let x = ciClamp01(t) * 4
        let i = min(3, Int(x.rounded(.down)))
        return (i, i + 1, x - CGFloat(i))
    }
    let (r0, r1, rt) = lerp(r)
    let (g0, g1, gt) = lerp(g)
    let (b0, b1, bt) = lerp(b)
    func cell(_ ri: Int, _ gi: Int, _ bi: Int) -> (CGFloat, CGFloat, CGFloat) {
        let idx = ((ri * 5 + gi) * 5 + bi) * 3
        return (
            CGFloat(cube[idx]) / 255,
            CGFloat(cube[idx + 1]) / 255,
            CGFloat(cube[idx + 2]) / 255
        )
    }
    func mix(_ a: (CGFloat, CGFloat, CGFloat), _ b: (CGFloat, CGFloat, CGFloat), _ t: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
    }
    let c000 = cell(r0, g0, b0), c001 = cell(r0, g0, b1)
    let c010 = cell(r0, g1, b0), c011 = cell(r0, g1, b1)
    let c100 = cell(r1, g0, b0), c101 = cell(r1, g0, b1)
    let c110 = cell(r1, g1, b0), c111 = cell(r1, g1, b1)
    let c00 = mix(c000, c001, bt), c01 = mix(c010, c011, bt)
    let c10 = mix(c100, c101, bt), c11 = mix(c110, c111, bt)
    let c0 = mix(c00, c01, gt), c1 = mix(c10, c11, gt)
    let o = mix(c0, c1, rt)
    return (o.0, o.1, o.2, a)
}

func ciSampleBlurred(_ image: CIImage, radius: CGFloat, at point: CGPoint) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    guard radius > 0.05 else { return image.sample(at: point) }
    let support = max(1, Int((3 * radius).rounded(.up)))
    var kernel = Array(repeating: 0.0, count: support + 1)
    let g0 = (56.0 / 255.0).squareRoot()
    let proto = [56.0, 52, 43, 30, 17, 6, 2]
    for d in 0...support {
        let src = Double(d) * 2.0 / Double(radius)
        if src >= 6 {
            kernel[d] = 0
        } else {
            let lo = Int(src.rounded(.down))
            let hi = min(lo + 1, proto.count - 1)
            let t = src - Double(lo)
            let a = (proto[lo] / 255.0) / g0
            let b = (proto[hi] / 255.0) / g0
            kernel[d] = a + (b - a) * t
        }
    }
    var sum = kernel[0]
    for d in 1...support { sum += 2 * kernel[d] }
    if sum > 0 {
        for d in 0...support { kernel[d] /= sum }
    }
    var accR = 0.0, accG = 0.0, accB = 0.0, accA = 0.0
    for dy in -support...support {
        for dx in -support...support {
            let w = kernel[abs(dx)] * kernel[abs(dy)]
            let s = image.sample(at: CGPoint(x: point.x + CGFloat(dx), y: point.y + CGFloat(dy)))
            accR += Double(s.0) * w
            accG += Double(s.1) * w
            accB += Double(s.2) * w
            accA += Double(s.3) * w
        }
    }
    return (CGFloat(accR), CGFloat(accG), CGFloat(accB), CGFloat(accA))
}

func ciScalar(_ value: Any?, _ fallback: CGFloat) -> CGFloat {
    if let v = value as? CGFloat { return v }
    if let v = value as? Float { return CGFloat(v) }
    if let v = value as? Double { return CGFloat(v) }
    if let v = value as? Int { return CGFloat(v) }
    if let v = value as? NSNumber { return CGFloat(v.doubleValue) }
    return fallback
}

func ciInstallBuiltinFilters(_ registry: CIFilterRegistry) {
    let entries: [(String, String, [String], [String])] = [
        ("CIGaussianBlur", "Gaussian Blur", [kCICategoryBlur], [kCIInputImageKey, kCIInputRadiusKey]),
        ("CIColorControls", "Color Controls", [kCICategoryColorAdjustment], [kCIInputImageKey, kCIInputSaturationKey, kCIInputBrightnessKey, kCIInputContrastKey]),
        ("CISepiaTone", "Sepia Tone", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputIntensityKey]),
        ("CIColorMatrix", "Color Matrix", [kCICategoryColorAdjustment], [kCIInputImageKey, "inputRVector", "inputGVector", "inputBVector", "inputAVector", "inputBiasVector"]),
        ("CIExposureAdjust", "Exposure Adjust", [kCICategoryColorAdjustment], [kCIInputImageKey, kCIInputEVKey]),
        ("CIVibrance", "Vibrance", [kCICategoryColorAdjustment], [kCIInputImageKey, kCIInputAmountKey]),
        ("CIHueAdjust", "Hue Adjust", [kCICategoryColorAdjustment], [kCIInputImageKey, kCIInputAngleKey]),
        ("CICrop", "Crop", [kCICategoryGeometryAdjustment], [kCIInputImageKey, "inputRectangle"]),
        ("CIAffineTransform", "Affine Transform", [kCICategoryGeometryAdjustment], [kCIInputImageKey, kCIInputTransformKey]),
        ("CISourceOverCompositing", "Source Over", [kCICategoryCompositeOperation], [kCIInputImageKey, kCIInputBackgroundImageKey]),
        ("CIQRCodeGenerator", "QR Code Generator", [kCICategoryGenerator], ["inputMessage", "inputCorrectionLevel"]),
        ("CICode128BarcodeGenerator", "Code 128 Barcode Generator", [kCICategoryGenerator], ["inputMessage", "inputQuietSpace", "inputBarcodeHeight"]),
        ("CIAztecCodeGenerator", "Aztec Code Generator", [kCICategoryGenerator], ["inputMessage"]),
        ("CIPDF417BarcodeGenerator", "PDF417 Barcode Generator", [kCICategoryGenerator], ["inputMessage"]),
        ("CIPhotoEffectChrome", "Chrome", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectFade", "Fade", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectInstant", "Instant", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectMono", "Mono", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectNoir", "Noir", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectProcess", "Process", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectTonal", "Tonal", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
        ("CIPhotoEffectTransfer", "Transfer", [kCICategoryColorEffect], [kCIInputImageKey, kCIInputExtrapolateKey]),
    ]
    for (name, display, cats, keys) in entries {
        registry.registerBuiltin(
            name: name,
            display: display,
            categories: cats + [kCICategoryBuiltIn, kCICategoryStillImage],
            inputKeys: keys
        )
    }
}

extension CIFilter {
    public static func gaussianBlur() -> CIGaussianBlur { CIGaussianBlur() }
    public static func colorControls() -> CIColorControls { CIColorControls() }
    public static func sepiaTone() -> CISepiaTone { CISepiaTone() }
    public static func colorMatrix() -> CIColorMatrix { CIColorMatrix() }
    public static func exposureAdjust() -> CIExposureAdjust { CIExposureAdjust() }
    public static func vibrance() -> CIVibrance { CIVibrance() }
    public static func hueAdjust() -> CIHueAdjust { CIHueAdjust() }
    public static func crop() -> CICrop { CICrop() }
    public static func affineTransform() -> CIAffineTransform { CIAffineTransform() }
    public static func sourceOverCompositing() -> CISourceOverCompositing { CISourceOverCompositing() }
    public static func qrCodeGenerator() -> CIQRCodeGenerator { CIQRCodeGenerator() }
    public static func code128BarcodeGenerator() -> CICode128BarcodeGenerator { CICode128BarcodeGenerator() }
    public static func photoEffectChrome() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectChrome") }
    public static func photoEffectFade() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectFade") }
    public static func photoEffectInstant() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectInstant") }
    public static func photoEffectMono() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectMono") }
    public static func photoEffectNoir() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectNoir") }
    public static func photoEffectProcess() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectProcess") }
    public static func photoEffectTonal() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectTonal") }
    public static func photoEffectTransfer() -> CIPhotoEffect { CIPhotoEffect(effect: "CIPhotoEffectTransfer") }
}

public final class CIGaussianBlur: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var radius: Float {
        get { (inputs[kCIInputRadiusKey] as? Float) ?? 10 }
        set { setValue(newValue, forKey: kCIInputRadiusKey) }
    }
    public override init() {
        super.init(name: "CIGaussianBlur", attributes: CIFilterRegistry.shared.attributes(for: "CIGaussianBlur"))
        inputs[kCIInputRadiusKey] = Float(10)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIColorControls: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var saturation: Float {
        get { (inputs[kCIInputSaturationKey] as? Float) ?? 1 }
        set { setValue(newValue, forKey: kCIInputSaturationKey) }
    }
    public var brightness: Float {
        get { (inputs[kCIInputBrightnessKey] as? Float) ?? 0 }
        set { setValue(newValue, forKey: kCIInputBrightnessKey) }
    }
    public var contrast: Float {
        get { (inputs[kCIInputContrastKey] as? Float) ?? 1 }
        set { setValue(newValue, forKey: kCIInputContrastKey) }
    }
    public override init() {
        super.init(name: "CIColorControls", attributes: CIFilterRegistry.shared.attributes(for: "CIColorControls"))
        inputs[kCIInputSaturationKey] = Float(1)
        inputs[kCIInputBrightnessKey] = Float(0)
        inputs[kCIInputContrastKey] = Float(1)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CISepiaTone: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var intensity: Float {
        get { (inputs[kCIInputIntensityKey] as? Float) ?? 1 }
        set { setValue(newValue, forKey: kCIInputIntensityKey) }
    }
    public override init() {
        super.init(name: "CISepiaTone", attributes: CIFilterRegistry.shared.attributes(for: "CISepiaTone"))
        inputs[kCIInputIntensityKey] = Float(1)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIColorMatrix: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public override init() {
        super.init(name: "CIColorMatrix", attributes: CIFilterRegistry.shared.attributes(for: "CIColorMatrix"))
        inputs["inputRVector"] = CIVector(x: 1, y: 0, z: 0, w: 0)
        inputs["inputGVector"] = CIVector(x: 0, y: 1, z: 0, w: 0)
        inputs["inputBVector"] = CIVector(x: 0, y: 0, z: 1, w: 0)
        inputs["inputAVector"] = CIVector(x: 0, y: 0, z: 0, w: 1)
        inputs["inputBiasVector"] = CIVector(x: 0, y: 0, z: 0, w: 0)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIExposureAdjust: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var ev: Float {
        get { (inputs[kCIInputEVKey] as? Float) ?? 0 }
        set { setValue(newValue, forKey: kCIInputEVKey) }
    }
    public override init() {
        super.init(name: "CIExposureAdjust", attributes: CIFilterRegistry.shared.attributes(for: "CIExposureAdjust"))
        inputs[kCIInputEVKey] = Float(0)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIVibrance: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var amount: Float {
        get { (inputs[kCIInputAmountKey] as? Float) ?? 0 }
        set { setValue(newValue, forKey: kCIInputAmountKey) }
    }
    public override init() {
        super.init(name: "CIVibrance", attributes: CIFilterRegistry.shared.attributes(for: "CIVibrance"))
        inputs[kCIInputAmountKey] = Float(0)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIHueAdjust: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var angle: Float {
        get { (inputs[kCIInputAngleKey] as? Float) ?? 0 }
        set { setValue(newValue, forKey: kCIInputAngleKey) }
    }
    public override init() {
        super.init(name: "CIHueAdjust", attributes: CIFilterRegistry.shared.attributes(for: "CIHueAdjust"))
        inputs[kCIInputAngleKey] = Float(0)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CICrop: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public override init() {
        super.init(name: "CICrop", attributes: CIFilterRegistry.shared.attributes(for: "CICrop"))
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIAffineTransform: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public override init() {
        super.init(name: "CIAffineTransform", attributes: CIFilterRegistry.shared.attributes(for: "CIAffineTransform"))
        inputs[kCIInputTransformKey] = CIVector(cgAffineTransform: .identity)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CISourceOverCompositing: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public var backgroundImage: CIImage? {
        get { inputs[kCIInputBackgroundImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputBackgroundImageKey) }
    }
    public override init() {
        super.init(name: "CISourceOverCompositing", attributes: CIFilterRegistry.shared.attributes(for: "CISourceOverCompositing"))
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIQRCodeGenerator: CIFilter, @unchecked Sendable {
    public var message: Data {
        get { (inputs["inputMessage"] as? Data) ?? Data() }
        set { setValue(newValue, forKey: "inputMessage") }
    }
    public var correctionLevel: String {
        get { (inputs["inputCorrectionLevel"] as? String) ?? "M" }
        set { setValue(newValue, forKey: "inputCorrectionLevel") }
    }
    public override init() {
        super.init(name: "CIQRCodeGenerator", attributes: CIFilterRegistry.shared.attributes(for: "CIQRCodeGenerator"))
        inputs["inputCorrectionLevel"] = "M"
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CICode128BarcodeGenerator: CIFilter, @unchecked Sendable {
    public var message: Data {
        get { (inputs["inputMessage"] as? Data) ?? Data() }
        set { setValue(newValue, forKey: "inputMessage") }
    }
    public override init() {
        super.init(name: "CICode128BarcodeGenerator", attributes: CIFilterRegistry.shared.attributes(for: "CICode128BarcodeGenerator"))
        inputs["inputQuietSpace"] = Float(10)
        inputs["inputBarcodeHeight"] = Float(32)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class CIPhotoEffect: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }
    public init(effect: String) {
        super.init(name: effect, attributes: CIFilterRegistry.shared.attributes(for: effect))
        inputs[kCIInputExtrapolateKey] = Float(0)
    }
    public override init() {
        super.init(
            name: "CIPhotoEffectMono",
            attributes: CIFilterRegistry.shared.attributes(for: "CIPhotoEffectMono")
        )
        inputs[kCIInputExtrapolateKey] = Float(0)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
