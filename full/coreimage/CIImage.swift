import Foundation
#if canImport(Glibc)
import Glibc
#else
import func Darwin.pow
#endif

enum CIColorOp: @unchecked Sendable {
    case sepia(CGFloat)
    case colorControls(saturation: CGFloat, brightness: CGFloat, contrast: CGFloat)
    case matrix(r: CIVector, g: CIVector, b: CIVector, a: CIVector, bias: CIVector)
    case exposure(CGFloat)
    case hue(CGFloat)
    case vibrance(CGFloat)
    case photo(String)
}

enum CIImageNode: @unchecked Sendable {
    case empty
    case color(CIColor, extent: CGRect)
    case gradient(color0: CIColor, color1: CIColor, point0: CGPoint, point1: CGPoint, extent: CGRect)
    case bitmap(CGImage, extent: CGRect)
    case cropped(CIImage, CGRect)
    case transformed(CIImage, CGAffineTransform)
    case composited(foreground: CIImage, background: CIImage)
    case tagged(CIImage)
    case premultiplied(CIImage)
    case unpremultiplied(CIImage)
    case alphaOne(CIImage, CGRect)
    case lab(CIImage, toLab: Bool)
    case colorMatched(CIImage, from: CGColorSpace, to: CGColorSpace)
    case adjusted(CIImage, CIColorOp)
    case blurred(CIImage, radius: CGFloat)
}

public class CIImage: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    let node: CIImageNode
    private var storedProperties: [String: Any] = [:]
    private var storedURL: URL?
    var storedCGImage: CGImage?
    var storedColorSpace: CGColorSpace?
    var storedHeadroom: Float = 1
    var storedAverageLight: Float = 1
    var opaqueFlag: Bool = false
    var nearestSampling: Bool = true
    var premultiplied: Bool = false
    var storedGainMap: CIImage?
    var highQualityDownsample: Bool = false

    public var extent: CGRect {
        switch node {
        case .empty:
            return .null
        case .color(_, let extent), .gradient(_, _, _, _, let extent), .bitmap(_, let extent):
            return extent
        case .cropped(_, let rect):
            return rect
        case .transformed(let image, let matrix):
            return matrix.applying(to: image.extent)
        case .composited(let foreground, let background):
            return foreground.extent.union(background.extent)
        case .tagged(let image), .adjusted(let image, _),
             .premultiplied(let image), .unpremultiplied(let image),
             .lab(let image, _), .colorMatched(let image, _, _):
            return image.extent
        case .alphaOne(let image, _):
            return image.extent
        case .blurred(let image, let radius):
            // Apple CIGaussianBlur support is a 3σ kernel: the output extent is
            // the input extent inset by −3×inputRadius on each edge.
            let pad = 3 * radius
            return image.extent.insetBy(dx: -pad, dy: -pad)
        }
    }

    public var colorSpace: CGColorSpace? { storedColorSpace ?? .sRGB }
    public var contentAverageLightLevel: Float { storedAverageLight }
    public var contentHeadroom: Float { storedHeadroom }
    public var isOpaque: Bool { opaqueFlag }
    public var properties: [String: Any] { storedProperties }
    public var url: URL? { storedURL }
    public var cgImage: CGImage? { storedCGImage }

    init(node: CIImageNode) {
        self.node = node
        super.init()
        if case .color(let color, _) = node {
            opaqueFlag = color.alpha >= 1
        }
    }

    public class func empty() -> CIImage {
        CIImage(node: .empty)
    }

    public init(color: CIColor) {
        self.node = .color(color, extent: .infinite)
        self.opaqueFlag = color.alpha >= 1
        super.init()
    }

    public init(cgImage image: CGImage) {
        let extent = CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
        self.node = .bitmap(image, extent: extent)
        self.storedCGImage = image
        super.init()
    }

    public convenience init(CGImage image: CGImage) {
        self.init(cgImage: image)
    }

    public init(cgImage image: CGImage, options: [CIImageOption: Any]? = nil) {
        let extent = CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
        self.node = .bitmap(image, extent: extent)
        self.storedCGImage = image
        super.init()
        applyOptions(options)
    }

    public convenience init(CGImage image: CGImage, options: [CIImageOption: Any]? = nil) {
        self.init(cgImage: image, options: options)
    }

    public init(
        bitmapData data: Data,
        bytesPerRow: Int,
        size: CGSize,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) {
        let width = max(0, Int(size.width.rounded(.down)))
        let height = max(0, Int(size.height.rounded(.down)))
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        if format == .RGBA8, bytesPerRow >= width * 4 {
            data.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return }
                for y in 0..<height {
                    let src = base.advanced(by: y * bytesPerRow)
                    let dst = y * width * 4
                    let row = min(width * 4, bytesPerRow, raw.count - y * bytesPerRow)
                    if row > 0 {
                        pixels.replaceSubrange(dst..<(dst + row), with: UnsafeRawBufferPointer(start: src, count: row))
                    }
                }
            }
        }
        let bitmap = CGImage(width: width, height: height, pixels: pixels)
        self.node = .bitmap(bitmap, extent: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        self.storedCGImage = bitmap
        self.storedColorSpace = colorSpace
        super.init()
    }

    public convenience init?(data: Data) {
        self.init(data: data, options: nil)
    }

    public init?(data: Data, options: [CIImageOption: Any]? = nil) {
        guard let bitmap = ciDecodeImage(data) else { return nil }
        let extent = CGRect(x: 0, y: 0, width: CGFloat(bitmap.width), height: CGFloat(bitmap.height))
        self.node = .bitmap(bitmap, extent: extent)
        self.storedCGImage = bitmap
        super.init()
        applyOptions(options)
    }

    public convenience init?(contentsOf url: URL) {
        self.init(contentsOf: url, options: nil)
    }

    public convenience init?(contentsOfURL url: URL) {
        self.init(contentsOf: url, options: nil)
    }

    public convenience init?(contentsOf url: URL, options: [CIImageOption: Any]? = nil) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(data: data, options: options)
        storedURL = url
    }

    public convenience init?(contentsOfURL url: URL, options: [CIImageOption: Any]? = nil) {
        self.init(contentsOf: url, options: options)
    }

    public init(
        imageProvider provider: Any,
        size width: Int,
        _ height: Int,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        options: [CIImageOption: Any]? = nil
    ) {
        let w = max(0, width)
        let h = max(0, height)
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let rowBytes = max(w * 4, 0)
        if w > 0, h > 0, rowBytes > 0 {
            pixels.withUnsafeMutableBytes { raw in
                guard let base = raw.baseAddress else { return }
                (provider as? NSObject)?.provideImageData(
                    base,
                    bytesPerRow: rowBytes,
                    origin: 0,
                    0,
                    size: w,
                    h,
                    userInfo: options?[CIImageOption.providerUserInfo]
                )
            }
        }
        let bitmap = CGImage(width: w, height: h, pixels: pixels)
        self.node = .bitmap(bitmap, extent: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
        self.storedCGImage = bitmap
        self.storedColorSpace = colorSpace
        super.init()
        applyOptions(options)
        _ = format
    }

    public init(texture name: UInt32, size: CGSize, flipped: Bool, colorSpace: CGColorSpace?) {
        _ = (name, flipped)
        let width = max(0, Int(size.width.rounded(.down)))
        let height = max(0, Int(size.height.rounded(.down)))
        let bitmap = CGImage(width: width, height: height)
        self.node = .bitmap(bitmap, extent: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        self.storedCGImage = bitmap
        self.storedColorSpace = colorSpace
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public static var black: CIImage { CIImage(color: .black) }
    public static var white: CIImage { CIImage(color: .white) }
    public static var gray: CIImage { CIImage(color: .gray) }
    public static var red: CIImage { CIImage(color: .red) }
    public static var green: CIImage { CIImage(color: .green) }
    public static var blue: CIImage { CIImage(color: .blue) }
    public static var cyan: CIImage { CIImage(color: .cyan) }
    public static var magenta: CIImage { CIImage(color: .magenta) }
    public static var yellow: CIImage { CIImage(color: .yellow) }
    public static var clear: CIImage { CIImage(color: .clear) }

    public func cropped(to rect: CGRect) -> CIImage {
        if extent.isInfinite || extent.isNull {
            return CIImage(node: .cropped(self, rect))
        }
        return CIImage(node: .cropped(self, rect.intersection(extent)))
    }

    public func clamped(to rect: CGRect) -> CIImage {
        cropped(to: rect)
    }

    public func clampedToExtent() -> CIImage {
        clamped(to: extent)
    }

    public func transformed(by matrix: CGAffineTransform) -> CIImage {
        CIImage(node: .transformed(self, matrix))
    }

    public func transformed(by matrix: CGAffineTransform, highQualityDownsample: Bool) -> CIImage {
        let image = transformed(by: matrix)
        image.highQualityDownsample = highQualityDownsample
        return image
    }

    public func composited(over dest: CIImage) -> CIImage {
        CIImage(node: .composited(foreground: self, background: dest))
    }

    public func samplingLinear() -> CIImage {
        let image = CIImage(node: .tagged(self))
        image.nearestSampling = false
        return image
    }

    public func samplingNearest() -> CIImage {
        let image = CIImage(node: .tagged(self))
        image.nearestSampling = true
        return image
    }

    public func premultiplyingAlpha() -> CIImage {
        let image = CIImage(node: .premultiplied(self))
        image.premultiplied = true
        return image
    }

    public func unpremultiplyingAlpha() -> CIImage {
        let image = CIImage(node: .unpremultiplied(self))
        image.premultiplied = false
        return image
    }

    public func settingAlphaOne(in extent: CGRect) -> CIImage {
        let image = CIImage(node: .alphaOne(self, extent))
        image.opaqueFlag = true
        return image
    }

    public func settingProperties(_ properties: [AnyHashable: Any]) -> CIImage {
        let image = CIImage(node: .tagged(self))
        var copied: [String: Any] = [:]
        for (key, value) in properties {
            copied[String(describing: key)] = value
        }
        image.storedProperties = copied
        return image
    }

    public func settingContentHeadroom(_ headroom: Float) -> CIImage {
        let image = CIImage(node: .tagged(self))
        image.storedHeadroom = headroom
        return image
    }

    public func settingContentAverageLightLevel(_ average: Float) -> CIImage {
        let image = CIImage(node: .tagged(self))
        image.storedAverageLight = average
        return image
    }

    public func insertingIntermediate() -> CIImage { CIImage(node: .tagged(self)) }
    public func insertingIntermediate(cache: Bool) -> CIImage {
        _ = cache
        return insertingIntermediate()
    }
    public func insertingTiledIntermediate() -> CIImage { insertingIntermediate() }

    public func convertingLabToWorkingSpace() -> CIImage {
        CIImage(node: .lab(self, toLab: false))
    }

    public func convertingWorkingSpaceToLab() -> CIImage {
        CIImage(node: .lab(self, toLab: true))
    }

    public func matchedToWorkingSpace(from colorSpace: CGColorSpace) -> CIImage? {
        let image = CIImage(node: .colorMatched(self, from: colorSpace, to: .sRGB))
        image.storedColorSpace = .sRGB
        return image
    }

    public func matchedFromWorkingSpace(to colorSpace: CGColorSpace) -> CIImage? {
        let image = CIImage(node: .colorMatched(self, from: .sRGB, to: colorSpace))
        image.storedColorSpace = colorSpace
        return image
    }

    public func applyingGainMap(_ gainmap: CIImage) -> CIImage {
        let image = CIImage(node: .tagged(self))
        image.storedGainMap = gainmap
        return image
    }

    public func applyingGainMap(_ gainmap: CIImage, headroom: Float) -> CIImage {
        _ = gainmap
        return settingContentHeadroom(headroom)
    }

    public func applyingGaussianBlur(sigma: Double) -> CIImage {
        CIImage(node: .blurred(self, radius: CGFloat(sigma)))
    }

    public func applyingFilter(_ filterName: String) -> CIImage {
        applyingFilter(filterName, parameters: [:])
    }

    public func applyingFilter(_ filterName: String, parameters params: [String: Any]) -> CIImage {
        guard let filter = CIFilter(name: filterName, withInputParameters: params) else {
            return self
        }
        filter.setInputImage(self)
        return filter.outputImage ?? self
    }

    public func autoAdjustmentFilters() -> [CIFilter] { [] }
    public func autoAdjustmentFilters(options: [CIImageAutoAdjustmentOption: Any]? = nil) -> [CIFilter] {
        _ = options
        return []
    }

    public func oriented(_ orientation: CGImagePropertyOrientation) -> CIImage {
        transformed(by: orientationTransform(for: orientation))
    }

    public func oriented(forExifOrientation orientation: Int32) -> CIImage {
        let value = CGImagePropertyOrientation(rawValue: UInt32(orientation)) ?? .up
        return oriented(value)
    }

    public func orientationTransform(for orientation: CGImagePropertyOrientation) -> CGAffineTransform {
        switch orientation {
        case .up:
            return .identity
        case .down:
            return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        case .left:
            return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0)
        case .right:
            return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: 0)
        case .upMirrored:
            return CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
        case .downMirrored:
            return CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        case .leftMirrored:
            return CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: 0, ty: 0)
        case .rightMirrored:
            return CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        }
    }

    public func orientationTransform(forExifOrientation orientation: Int32) -> CGAffineTransform {
        orientationTransform(for: CGImagePropertyOrientation(rawValue: UInt32(orientation)) ?? .up)
    }

    public func regionOfInterest(for image: CIImage, in rect: CGRect) -> CGRect {
        _ = image
        return rect
    }

    private func applyOptions(_ options: [CIImageOption: Any]?) {
        guard let options else { return }
        if options[CIImageOption.nearestSampling] != nil {
            nearestSampling = true
        }
        if let space = options[CIImageOption.colorSpace] as? CGColorSpace {
            storedColorSpace = space
        }
    }

    /// Sample this image at a point in extent coordinates for software rendering.
    func sample(at point: CGPoint) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        sample(at: point, nearest: nearestSampling)
    }

    func sample(at point: CGPoint, nearest: Bool) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        switch node {
        case .empty:
            return (0, 0, 0, 0)
        case .color(let color, _):
            return (color.red, color.green, color.blue, color.alpha)
        case .gradient(let color0, let color1, let point0, let point1, _):
            return ciSampleLinearGradient(
                point: point,
                color0: color0,
                color1: color1,
                point0: point0,
                point1: point1
            )
        case .bitmap(let bitmap, let extent):
            return ciSampleBitmap(bitmap, extent: extent, point: point, nearest: nearest)
        case .cropped(let image, let rect):
            if !rect.contains(point) { return (0, 0, 0, 0) }
            return image.sample(at: point, nearest: nearest)
        case .transformed(let image, let matrix):
            return image.sample(at: matrix.inverted().applying(to: point), nearest: nearest)
        case .composited(let foreground, let background):
            let src = foreground.sample(at: point, nearest: nearest)
            let dst = background.sample(at: point, nearest: nearest)
            let a = src.3 + dst.3 * (1 - src.3)
            guard a > 0 else { return (0, 0, 0, 0) }
            let r = (src.0 * src.3 + dst.0 * dst.3 * (1 - src.3)) / a
            let g = (src.1 * src.3 + dst.1 * dst.3 * (1 - src.3)) / a
            let b = (src.2 * src.3 + dst.2 * dst.3 * (1 - src.3)) / a
            return (r, g, b, a)
        case .tagged(let image):
            return image.sample(at: point, nearest: nearestSampling)
        case .premultiplied(let image):
            let s = image.sample(at: point, nearest: nearest)
            return (s.0 * s.3, s.1 * s.3, s.2 * s.3, s.3)
        case .unpremultiplied(let image):
            let s = image.sample(at: point, nearest: nearest)
            guard s.3 > 0 else { return (0, 0, 0, 0) }
            return (s.0 / s.3, s.1 / s.3, s.2 / s.3, s.3)
        case .alphaOne(let image, let rect):
            var s = image.sample(at: point, nearest: nearest)
            if rect.isInfinite || rect.contains(point) {
                s.3 = 1
            }
            return s
        case .lab(let image, let toLab):
            let s = image.sample(at: point, nearest: nearest)
            return toLab ? ciWorkingToLab(s) : ciLabToWorking(s)
        case .colorMatched(let image, let from, let to):
            let s = image.sample(at: point, nearest: nearest)
            return ciMatchWorkingColor(s, from: from, to: to)
        case .adjusted(let image, let op):
            return ciApplyColorOp(op, image.sample(at: point, nearest: nearest))
        case .blurred(let image, let radius):
            return ciSampleBlurred(image, radius: radius, at: point)
        }
    }
}

func ciSampleLinearGradient(
    point: CGPoint,
    color0: CIColor,
    color1: CIColor,
    point0: CGPoint,
    point1: CGPoint
) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    let dx = point1.x - point0.x
    let dy = point1.y - point0.y
    let denominator = dx * dx + dy * dy
    let raw: CGFloat
    if denominator == 0 {
        raw = 0
    } else {
        raw = ((point.x - point0.x) * dx + (point.y - point0.y) * dy) / denominator
    }
    let t = ciClamp01(raw)
    let inverse = 1 - t
    return (
        color0.red * inverse + color1.red * t,
        color0.green * inverse + color1.green * t,
        color0.blue * inverse + color1.blue * t,
        color0.alpha * inverse + color1.alpha * t
    )
}

func ciSampleBitmap(
    _ bitmap: CGImage,
    extent: CGRect,
    point: CGPoint,
    nearest: Bool
) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    guard bitmap.width > 0, bitmap.height > 0, !extent.isNull, extent.width > 0, extent.height > 0 else {
        return (0, 0, 0, 0)
    }
    let u = (point.x - extent.minX) / extent.width
    let v = (point.y - extent.minY) / extent.height
    func pixel(_ x: Int, _ y: Int) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let sx = min(bitmap.width - 1, max(0, x))
        let sy = min(bitmap.height - 1, max(0, y))
        let offset = (sy * bitmap.width + sx) * 4
        guard offset + 3 < bitmap.pixels.count else { return (0, 0, 0, 0) }
        return (
            CGFloat(bitmap.pixels[offset]) / 255,
            CGFloat(bitmap.pixels[offset + 1]) / 255,
            CGFloat(bitmap.pixels[offset + 2]) / 255,
            CGFloat(bitmap.pixels[offset + 3]) / 255
        )
    }
    if nearest {
        let x = Int((u * CGFloat(bitmap.width)).rounded(.down))
        let y = Int(((1 - v) * CGFloat(bitmap.height)).rounded(.down))
        return pixel(x, y)
    }
    let fx = u * CGFloat(bitmap.width) - 0.5
    let fy = (1 - v) * CGFloat(bitmap.height) - 0.5
    let x0 = Int(floor(Double(fx)))
    let y0 = Int(floor(Double(fy)))
    let tx = fx - CGFloat(x0)
    let ty = fy - CGFloat(y0)
    let p00 = pixel(x0, y0)
    let p10 = pixel(x0 + 1, y0)
    let p01 = pixel(x0, y0 + 1)
    let p11 = pixel(x0 + 1, y0 + 1)
    func mix(
        _ a: (CGFloat, CGFloat, CGFloat, CGFloat),
        _ b: (CGFloat, CGFloat, CGFloat, CGFloat),
        _ t: CGFloat
    ) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        (
            a.0 + (b.0 - a.0) * t,
            a.1 + (b.1 - a.1) * t,
            a.2 + (b.2 - a.2) * t,
            a.3 + (b.3 - a.3) * t
        )
    }
    return mix(mix(p00, p10, tx), mix(p01, p11, tx), ty)
}

/// CIE L*a*b* (D65) packed as (L/100, (a+128)/255, (b+128)/255, alpha).
/// Apple's on-device Lab encoding is not in the public Filter Reference.
func ciWorkingToLab(
    _ s: (CGFloat, CGFloat, CGFloat, CGFloat)
) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    let r = ciPiecewiseSRGBToLin(s.0)
    let g = ciPiecewiseSRGBToLin(s.1)
    let b = ciPiecewiseSRGBToLin(s.2)
    let x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    let y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    let z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    func f(_ t: CGFloat) -> CGFloat {
        t > 0.008856 ? CGFloat(pow(Double(t), 1.0 / 3.0)) : (7.787 * t + 16.0 / 116.0)
    }
    let fx = f(x / 0.95047)
    let fy = f(y / 1.0)
    let fz = f(z / 1.08883)
    let L = 116 * fy - 16
    let a = 500 * (fx - fy)
    let bLab = 200 * (fy - fz)
    return (L / 100, (a + 128) / 255, (bLab + 128) / 255, s.3)
}

func ciLabToWorking(
    _ s: (CGFloat, CGFloat, CGFloat, CGFloat)
) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    let L = s.0 * 100
    let a = s.1 * 255 - 128
    let bLab = s.2 * 255 - 128
    let fy = (L + 16) / 116
    let fx = a / 500 + fy
    let fz = fy - bLab / 200
    func finv(_ t: CGFloat) -> CGFloat {
        let t3 = t * t * t
        return t3 > 0.008856 ? t3 : (t - 16.0 / 116.0) / 7.787
    }
    let x = 0.95047 * finv(fx)
    let y = 1.0 * finv(fy)
    let z = 1.08883 * finv(fz)
    let r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    let g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
    let b = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    return (
        ciClamp01(ciPiecewiseLinToSRGB(r)),
        ciClamp01(ciPiecewiseLinToSRGB(g)),
        ciClamp01(ciPiecewiseLinToSRGB(b)),
        s.3
    )
}

func ciPiecewiseSRGBToLin(_ c: CGFloat) -> CGFloat {
    let c = Double(max(0, c))
    if c <= 0.04045 { return CGFloat(c / 12.92) }
    return CGFloat(pow((c + 0.055) / 1.055, 2.4))
}

func ciPiecewiseLinToSRGB(_ c: CGFloat) -> CGFloat {
    let c = Double(max(0, c))
    if c <= 0.0031308 { return CGFloat(12.92 * c) }
    return CGFloat(1.055 * pow(c, 1.0 / 2.4) - 0.055)
}

func ciMatchWorkingColor(
    _ s: (CGFloat, CGFloat, CGFloat, CGFloat),
    from: CGColorSpace,
    to: CGColorSpace
) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    if from.name == to.name { return s }
    if from.name == "sRGB", to.name == "genericRGBLinear" {
        return (ciPiecewiseSRGBToLin(s.0), ciPiecewiseSRGBToLin(s.1), ciPiecewiseSRGBToLin(s.2), s.3)
    }
    if from.name == "genericRGBLinear", to.name == "sRGB" {
        return (
            ciClamp01(ciPiecewiseLinToSRGB(s.0)),
            ciClamp01(ciPiecewiseLinToSRGB(s.1)),
            ciClamp01(ciPiecewiseLinToSRGB(s.2)),
            s.3
        )
    }
    // No ColorSync ICC profiles on isolated Linux; unknown spaces stay identity.
    return s
}
