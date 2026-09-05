import Foundation
import OpenCoreGraphics
#if canImport(OpenUIKitImageIO)
import OpenUIKitImageIO
#else
import ImageIO
#endif
#if canImport(CoreGraphics)
import class CoreGraphics.CGImage
import class CoreGraphics.CGContext
import class CoreGraphics.CGColorSpace
import class CoreGraphics.CGDataProvider
import struct CoreGraphics.CGBitmapInfo
import enum CoreGraphics.CGImageAlphaInfo
#endif

enum CIImageNode: @unchecked Sendable {
    case empty
    case color(CIColor, extent: CGRect)
    case bitmap(Bitmap, extent: CGRect)
    case blurred(CIImage, radius: CGFloat)
    case cropped(CIImage, CGRect)
    case transformed(CIImage, OpenCoreGraphics.CGAffineTransform)
}

public class CIImage: NSObject, @unchecked Sendable {
    let node: CIImageNode

    public var extent: CGRect {
        switch node {
        case .empty:
            return .null
        case .color(_, let extent), .bitmap(_, let extent):
            return extent
        case .blurred(let image, let radius):
            // MEASURED 2026-09-05, iPhone SE 2x / iOS 26.1 ciblurprobe:
            // CIGaussianBlur of a 32×32 opaque image expands extent by
            // 3 * inputRadius on each side (radius 1 → pad 3, radius 2 → 6,
            // radius 10 → 30).
            let pad = 3 * radius
            return image.extent.insetBy(dx: -pad, dy: -pad)
        case .cropped(_, let rect):
            return rect
        case .transformed(let image, let matrix):
            return ciTransformRect(image.extent, matrix)
        }
    }

    init(node: CIImageNode) {
        self.node = node
        super.init()
    }

    public class func empty() -> CIImage { CIImage(node: .empty) }

    public init(color: CIColor) {
        self.node = .color(color, extent: .infinite)
        super.init()
    }

    public init(bitmap: Bitmap) {
        let extent = CGRect(x: 0, y: 0, width: bitmap.width, height: bitmap.height)
        self.node = .bitmap(bitmap, extent: extent)
        super.init()
    }

    public init(cgImage image: CGImage) {
        if let bitmap = ciBitmap(from: image) {
            let extent = CGRect(x: 0, y: 0, width: bitmap.width, height: bitmap.height)
            self.node = .bitmap(bitmap, extent: extent)
        } else {
            self.node = .empty
        }
        super.init()
    }

    public convenience init(CGImage image: CGImage) {
        self.init(cgImage: image)
    }

    public convenience init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        self.init(cgImage: cg)
    }

    public func cropped(to rect: CGRect) -> CIImage {
        CIImage(node: .cropped(self, rect))
    }

    public func transformed(by matrix: OpenCoreGraphics.CGAffineTransform) -> CIImage {
        CIImage(node: .transformed(self, matrix))
    }

    func rasterize(from rect: CGRect) -> Bitmap? {
        let width = Int(rect.width.rounded(FloatingPointRoundingRule.towardZero))
        let height = Int(rect.height.rounded(FloatingPointRoundingRule.towardZero))
        guard width > 0, height > 0 else { return nil }
        switch node {
        case .empty:
            return Bitmap(width: width, height: height)
        case .color(let color, _):
            let bitmap = Bitmap(width: width, height: height)
            let r = ciByte(color.red), g = ciByte(color.green)
            let b = ciByte(color.blue), a = ciByte(color.alpha)
            for i in stride(from: 0, to: bitmap.pixels.count, by: 4) {
                bitmap.pixels[i] = r
                bitmap.pixels[i + 1] = g
                bitmap.pixels[i + 2] = b
                bitmap.pixels[i + 3] = a
            }
            return bitmap
        case .bitmap(let src, let extent):
            return ciResample(src, srcExtent: extent, dest: rect, width: width, height: height)
        case .blurred(let image, let radius):
            let pad = 3 * radius
            let expanded = image.extent.insetBy(dx: -pad, dy: -pad)
            guard let full = image.rasterize(from: expanded) else { return nil }
            ciGaussianBlur(full, radius: radius)
            return ciResample(
                full,
                srcExtent: expanded,
                dest: rect,
                width: width,
                height: height
            )
        case .cropped(let image, let crop):
            return image.rasterize(from: rect.intersection(crop))
        case .transformed(let image, let matrix):
            guard let src = image.rasterize(from: image.extent) else { return nil }
            return ciDrawTransformed(src, srcExtent: image.extent, matrix: matrix,
                                     dest: rect, width: width, height: height)
        }
    }
}

func ciByte(_ v: CGFloat) -> UInt8 {
    UInt8(min(255, max(0, (v * 255).rounded())))
}

func ciTransformRect(_ r: CGRect, _ matrix: OpenCoreGraphics.CGAffineTransform) -> CGRect {
    let corners = [
        CGPoint(x: r.minX, y: r.minY).applying(matrix),
        CGPoint(x: r.maxX, y: r.minY).applying(matrix),
        CGPoint(x: r.minX, y: r.maxY).applying(matrix),
        CGPoint(x: r.maxX, y: r.maxY).applying(matrix),
    ]
    let xs = corners.map { $0.x }
    let ys = corners.map { $0.y }
    let minX: CGFloat = xs.min() ?? 0
    let maxX: CGFloat = xs.max() ?? 0
    let minY: CGFloat = ys.min() ?? 0
    let maxY: CGFloat = ys.max() ?? 0
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

func ciResample(
    _ src: Bitmap,
    srcExtent: CGRect,
    dest: CGRect,
    width: Int,
    height: Int
) -> Bitmap {
    let out = Bitmap(width: width, height: height)
    guard src.width > 0, src.height > 0, srcExtent.width > 0, srcExtent.height > 0 else {
        return out
    }
    for y in 0..<height {
        for x in 0..<width {
            let px = dest.minX + CGFloat(x) + 0.5
            let py = dest.minY + CGFloat(y) + 0.5
            let u = (px - srcExtent.minX) / srcExtent.width * CGFloat(src.width)
            let v = (py - srcExtent.minY) / srcExtent.height * CGFloat(src.height)
            let sx = Int(u.rounded(FloatingPointRoundingRule.down))
            let sy = Int(v.rounded(FloatingPointRoundingRule.down))
            guard sx >= 0, sy >= 0, sx < src.width, sy < src.height else { continue }
            let si = (sy * src.width + sx) * 4
            let di = (y * width + x) * 4
            out.pixels[di] = src.pixels[si]
            out.pixels[di + 1] = src.pixels[si + 1]
            out.pixels[di + 2] = src.pixels[si + 2]
            out.pixels[di + 3] = src.pixels[si + 3]
        }
    }
    return out
}

func ciDrawTransformed(
    _ src: Bitmap,
    srcExtent: CGRect,
    matrix: OpenCoreGraphics.CGAffineTransform,
    dest: CGRect,
    width: Int,
    height: Int
) -> Bitmap {
    let inv = matrix.inverted()
    let out = Bitmap(width: width, height: height)
    guard src.width > 0, src.height > 0, srcExtent.width > 0, srcExtent.height > 0 else {
        return out
    }
    for y in 0..<height {
        for x in 0..<width {
            let p = CGPoint(x: dest.minX + CGFloat(x) + 0.5, y: dest.minY + CGFloat(y) + 0.5)
            let q = p.applying(inv)
            let u = (q.x - srcExtent.minX) / srcExtent.width * CGFloat(src.width)
            let v = (q.y - srcExtent.minY) / srcExtent.height * CGFloat(src.height)
            let sx = Int(u.rounded(FloatingPointRoundingRule.down))
            let sy = Int(v.rounded(FloatingPointRoundingRule.down))
            guard sx >= 0, sy >= 0, sx < src.width, sy < src.height else { continue }
            let si = (sy * src.width + sx) * 4
            let di = (y * width + x) * 4
            out.pixels[di] = src.pixels[si]
            out.pixels[di + 1] = src.pixels[si + 1]
            out.pixels[di + 2] = src.pixels[si + 2]
            out.pixels[di + 3] = src.pixels[si + 3]
        }
    }
    return out
}

/// MEASURED 2026-09-05 iPhone SE 2x / iOS 26.1 ciblurprobe impulse:
/// one white pixel at (16,16) in a 32×32 opaque-black field, radius 2,
/// row y=16 RGB = 0×10, then 2,6,17,30,43,52,56,52,43,30,17,6,2 (peak 56).
/// Support is 3*radius (same as the extent pad). The 1D taps are recovered
/// from the axis of that 2D impulse assuming a separable kernel:
/// g(0)=sqrt(56/255), g(d)=(axis[d]/255)/g(0). Other radii stretch this
/// prototype so the last tap sits at 3*radius.
func ciGaussianBlur(_ img: Bitmap, radius: CGFloat) {
    guard radius > 0.05, img.width > 0, img.height > 0 else { return }
    let support = max(1, Int((3 * radius).rounded(FloatingPointRoundingRule.up)))
    var kernel = Array(repeating: 0.0, count: support + 1)
    let g0 = (56.0 / 255.0).squareRoot()
    let proto = [56.0, 52, 43, 30, 17, 6, 2]
    for d in 0...support {
        let src = Double(d) * 2.0 / Double(radius)
        let taps: Double
        if src >= 6 {
            taps = 0
        } else {
            let lo = Int(src.rounded(.down))
            let hi = min(lo + 1, proto.count - 1)
            let t = src - Double(lo)
            let a = (proto[lo] / 255.0) / g0
            let b = (proto[hi] / 255.0) / g0
            taps = a + (b - a) * t
        }
        kernel[d] = taps
    }
    var sum = kernel[0]
    for d in 1...support { sum += 2 * kernel[d] }
    if sum > 0 {
        for d in 0...support { kernel[d] /= sum }
    }
    var channels: [[CGFloat]] = (0..<4).map { _ in
        Array(repeating: 0, count: img.width * img.height)
    }
    for i in 0..<(img.width * img.height) {
        let o = i * 4
        for c in 0..<4 { channels[c][i] = CGFloat(img.pixels[o + c]) / 255 }
    }
    for c in 0..<4 {
        ciSeparableConvolve(&channels[c], img.width, img.height, kernel: kernel)
    }
    for i in 0..<(img.width * img.height) {
        let o = i * 4
        for c in 0..<4 { img.pixels[o + c] = ciByte(channels[c][i]) }
    }
}

private func ciSeparableConvolve(
    _ img: inout [CGFloat],
    _ w: Int,
    _ h: Int,
    kernel: [Double]
) {
    let support = kernel.count - 1
    var tmp = Array(repeating: CGFloat(0), count: img.count)
    func clampi(_ v: Int, _ lo: Int, _ hi: Int) -> Int { min(hi, max(lo, v)) }
    img.withUnsafeBufferPointer { src in
        tmp.withUnsafeMutableBufferPointer { dst in
            for y in 0..<h {
                let row = y * w
                for x in 0..<w {
                    var acc = Double(src[row + x]) * kernel[0]
                    for d in 1...support {
                        acc += Double(src[row + clampi(x - d, 0, w - 1)]) * kernel[d]
                        acc += Double(src[row + clampi(x + d, 0, w - 1)]) * kernel[d]
                    }
                    dst[row + x] = CGFloat(acc)
                }
            }
        }
    }
    tmp.withUnsafeBufferPointer { src in
        img.withUnsafeMutableBufferPointer { dst in
            for x in 0..<w {
                for y in 0..<h {
                    var acc = Double(src[y * w + x]) * kernel[0]
                    for d in 1...support {
                        acc += Double(src[clampi(y - d, 0, h - 1) * w + x]) * kernel[d]
                        acc += Double(src[clampi(y + d, 0, h - 1) * w + x]) * kernel[d]
                    }
                    dst[y * w + x] = CGFloat(acc)
                }
            }
        }
    }
}

func ciBitmap(from image: CGImage) -> Bitmap? {
#if canImport(CoreGraphics)
    let width = image.width
    let height = image.height
    guard width > 0, height > 0 else { return nil }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let space = CoreGraphics.CGColorSpace(name: CoreGraphics.CGColorSpace.sRGB) else { return nil }
    guard let ctx = CoreGraphics.CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: space,
        bitmapInfo: CoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    ciUnpremultiply(&pixels)
    let bitmap = Bitmap(width: width, height: height)
    bitmap.pixels = pixels
    return bitmap
#else
    let bitmap = Bitmap(width: image.width, height: image.height)
    bitmap.pixels = image.rgba
    return bitmap
#endif
}

func ciMakeCGImage(_ bitmap: Bitmap) -> CGImage? {
#if canImport(CoreGraphics)
    let width = bitmap.width
    let height = bitmap.height
    guard width > 0, height > 0 else { return nil }
    let count = width * height * 4
    var premul = bitmap.pixels
    ciPremultiply(&premul)
    let data = CFDataCreate(nil, premul, count)!
    guard let provider = CoreGraphics.CGDataProvider(data: data) else { return nil }
    guard let space = CoreGraphics.CGColorSpace(name: CoreGraphics.CGColorSpace.sRGB) else { return nil }
    return CoreGraphics.CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: space,
        bitmapInfo: CoreGraphics.CGBitmapInfo(
            rawValue: CoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
#else
    return CGImage(width: bitmap.width, height: bitmap.height, rgba: bitmap.pixels)
#endif
}

func ciPremultiply(_ pixels: inout [UInt8]) {
    for i in stride(from: 0, to: pixels.count, by: 4) {
        let a = Int(pixels[i + 3])
        if a == 255 || a == 0 { continue }
        for c in 0..<3 {
            pixels[i + c] = UInt8((Int(pixels[i + c]) * a + 127) / 255)
        }
    }
}

func ciUnpremultiply(_ pixels: inout [UInt8]) {
    for i in stride(from: 0, to: pixels.count, by: 4) {
        let a = Int(pixels[i + 3])
        if a > 0 && a < 255 {
            for c in 0..<3 {
                pixels[i + c] = UInt8(min(255, (Int(pixels[i + c]) * 255 + a / 2) / a))
            }
        }
    }
}
