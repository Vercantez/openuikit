// UIKit's current CGContext on Apple toolchains (cg-unify phase 2,
// docs/agent_reports/cg-unify.md).
//
// UIKit hands app code a CoreGraphics `CGContext`
// (`UIGraphicsGetCurrentContext()`, `UIGraphicsImageRendererContext.cgContext`,
// `CALayer.render(in:)`). Where Apple's CoreGraphics exists the port hands out
// a REAL one, and the port's renderer keeps drawing everything UIKit itself
// draws. The two share one surface:
//
//   * The CGContext is a bitmap context over the Canvas's own premultiplied
//     RGBA8 backing (QuartzBackend keeps one; CGBitmapContext uses the same
//     layout). Drawing through the CGContext and drawing through the Canvas
//     land in the same pixels, in call order. Nothing is composited.
//   * Its base CTM is the Canvas CTM flipped into CoreGraphics' bottom-up
//     device space (MEASURED iOS 26.1, cgunifyprobe `## renderer context`:
//     ctm=[1 0 0 -1 0 2] for a 4x2 image at scale 1), clipped to the drawing
//     rect.
//   * UIKit's own drawing calls (UIRectFill, UIBezierPath fill/stroke/addClip,
//     UIImage.draw, UILabel.drawText) read the graphics state iOS keeps in the
//     CGContext -- CTM, clip, fill and stroke colour -- and then draw with the
//     port's rasterizer. So `cg.setFillColor(_:)` followed by `UIRectFill(_:)`,
//     and `cg.translateBy(…)` followed by `UIBezierPath.fill()`, behave as on
//     iOS (cgunifyprobe `## renderer context` rows are the simulator's).
//   * The context is made lazily, on the first request. A drawing session
//     whose code never asks for it runs exactly the port's previous path
//     (the gate's byte-checked scenes).
//   * A bitmap CGContext the app made itself (`UIGraphicsPushContext(ctx)`,
//     `layer.render(in: ctx)`) gets a Canvas over ITS memory when the layout is
//     the renderer's (8-bit RGBA, premultiplied-last); any other context gets
//     an offscreen Canvas composited into it when the session ends.
//
// Linux ELF and the Mach-O guest have no Apple CoreGraphics; there
// `CGContext` is the Canvas itself (UIGraphicsRenderer.swift).
#if canImport(CoreGraphics)
import CoreGraphics

// CoreGraphics SPI (exported by CoreGraphics.framework on iOS and macOS and
// listed in the SDK's .tbd): the current fill / stroke colour of a context,
// returned +0. UIKit keeps these in the CGContext; UIRectFill and
// UIBezierPath.fill after an app's `setFillColor(_:)` use them (MEASURED,
// cgunifyprobe `## renderer context`, pixel (2,0) is the CGContext's blue).
@_silgen_name("CGContextGetFillColorAsColor")
private func _CGContextGetFillColorAsColor(_ context: CGContext) -> Unmanaged<CGColor>?
@_silgen_name("CGContextGetStrokeColorAsColor")
private func _CGContextGetStrokeColorAsColor(_ context: CGContext) -> Unmanaged<CGColor>?

/// The CoreGraphics face of one drawing session's Canvas.
final class _UICoreGraphicsBridge {
    enum Surface {
        /// The context draws into the Canvas's own Quartz backing.
        case shared
        /// The context draws into a private buffer composited over the Canvas.
        case overlay(UnsafeMutableRawPointer, bytesPerRow: Int)
        /// An app-made context whose memory the Canvas draws into directly.
        case adopted
        /// An app-made context the Canvas's offscreen pixels are drawn into.
        case adoptedOffscreen
    }

    let context: CGContext
    let canvas: Canvas
    /// Pixel height of the surface: CoreGraphics' device space is bottom-up.
    let deviceHeight: CGFloat
    /// Device-space clip box the session started with.
    let baseClip: CGRect
    private let surface: Surface
    /// `UIBezierPath.addClip()` paths, each with the CoreGraphics clip box it
    /// left. A path applies to port drawing while the context's clip box is
    /// still inside that box (an app `restoreGState()` widens it again).
    private var uikitClips: [(path: Path, box: CGRect)] = []

    nonisolated(unsafe) private static var live: [ObjectIdentifier: _UICoreGraphicsBridge] = [:]

    /// A CGContext for the port's `canvas`, clipped to `clip` (user space).
    init?(canvas: Canvas, clip: CGRect?) {
        let bitmap = canvas.bitmap
        guard bitmap.width > 0, bitmap.height > 0,
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let data: UnsafeMutableRawPointer
        let bytesPerRow: Int
        if let shared = canvas._sharedPremultipliedBacking() {
            data = shared.data
            bytesPerRow = shared.bytesPerRow
            surface = .shared
        } else {
            bytesPerRow = bitmap.width * 4
            let byteCount = bytesPerRow * bitmap.height
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 16)
            buffer.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
            data = buffer
            surface = .overlay(buffer, bytesPerRow: bytesPerRow)
        }
        guard let context = CGContext(data: data, width: bitmap.width, height: bitmap.height,
                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            if case .overlay(let buffer, _) = surface { buffer.deallocate() }
            return nil
        }
        self.context = context
        self.canvas = canvas
        self.deviceHeight = CGFloat(bitmap.height)
        context.concatenate(canvas.ctm.concatenating(Self.flip(deviceHeight)))
        if let clip { context.clip(to: clip) }
        baseClip = context.boundingBoxOfClipPath.applying(context.ctm)
        Self.live[ObjectIdentifier(context)] = self
    }

    /// A Canvas for an app-made `context` (UIGraphicsPushContext,
    /// CALayer.render(in:)).
    init(adopting context: CGContext) {
        self.context = context
        let width = Swift.max(1, context.width), height = Swift.max(1, context.height)
        if let data = context.data, context.bitsPerComponent == 8, context.bitsPerPixel == 32,
           context.bitmapInfo.rawValue == CGImageAlphaInfo.premultipliedLast.rawValue,
           let space = context.colorSpace, space.model == .rgb,
           let canvas = Canvas(data: data, width: width, height: height, bitsPerComponent: 8,
                               bytesPerRow: context.bytesPerRow, space: space,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            self.canvas = canvas
            surface = .adopted
        } else {
            canvas = Canvas(bitmap: Bitmap(width: width, height: height), scale: 1)
            surface = .adoptedOffscreen
        }
        deviceHeight = CGFloat(height)
        baseClip = context.boundingBoxOfClipPath.applying(context.ctm)
        // The Canvas's user space is the device space; `draw` sets the CTM.
    }

    deinit {
        if case .overlay(let buffer, _) = surface { buffer.deallocate() }
    }

    /// Top-down (Canvas) <-> bottom-up (CoreGraphics) device space.
    static func flip(_ height: CGFloat) -> CGAffineTransform {
        CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: height)
    }

    /// The bridge the port made for `context`, if any.
    static func bridge(for context: CGContext) -> _UICoreGraphicsBridge? {
        live[ObjectIdentifier(context)]
    }

    /// CoreGraphics' pixels become visible in the Canvas bitmap.
    func flush() {
        switch surface {
        case .shared:
            canvas._syncSharedBackingToBitmap()
        case .overlay(let buffer, let bytesPerRow):
            compositeOverlay(buffer, bytesPerRow: bytesPerRow)
        case .adopted, .adoptedOffscreen:
            break
        }
    }

    /// Ends the session.
    func finish() {
        Self.live.removeValue(forKey: ObjectIdentifier(context))
        flush()
        if case .adoptedOffscreen = surface, let image = canvas.makeImage(),
           let cgImage = image._premultipliedCGImage() {
            context.saveGState()
            context.concatenate(context.ctm.inverted())
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            context.restoreGState()
        }
    }

    private func compositeOverlay(_ buffer: UnsafeMutableRawPointer, bytesPerRow: Int) {
        let width = canvas.bitmap.width, height = canvas.bitmap.height
        let overlay = Bitmap(width: width, height: height)
        let src = buffer.assumingMemoryBound(to: UInt8.self)
        var any = false
        for y in 0..<height {
            for x in 0..<width {
                let s = y * bytesPerRow + x * 4, d = (y * width + x) * 4
                let a = Int(src[s + 3])
                guard a > 0 else { continue }
                any = true
                overlay.pixels[d + 3] = UInt8(a)
                for c in 0..<3 {
                    overlay.pixels[d + c] = UInt8(Swift.min(255, (Int(src[s + c]) * 255 + a / 2) / a))
                }
                src[s] = 0; src[s + 1] = 0; src[s + 2] = 0; src[s + 3] = 0
            }
        }
        guard any else { return }
        canvas.save()
        canvas._setCTM(.identity)
        canvas.draw(overlay, in: CGRect(x: 0, y: 0, width: width, height: height), interpolate: false)
        canvas.restore()
    }

    // MARK: UIKit drawing reads the CGContext's graphics state

    var fillColor: CanvasColor? {
        _CGContextGetFillColorAsColor(context).map { CanvasColor($0.takeUnretainedValue()) }
    }
    var strokeColor: CanvasColor? {
        _CGContextGetStrokeColorAsColor(context).map { CanvasColor($0.takeUnretainedValue()) }
    }

    /// `UIBezierPath.addClip()`: CoreGraphics' clip, remembered for the port.
    func addClip(_ path: Path) {
        context.addPath(path._cgPath)
        context.clip()
        uikitClips.append((path, context.boundingBoxOfClipPath.applying(context.ctm)))
    }

    /// Runs one port drawing operation under the CGContext's CTM and clip.
    func draw(_ body: (Canvas) -> Void) {
        if case .overlay(let buffer, let bytesPerRow) = surface {
            // Keep call order: CoreGraphics' earlier pixels go down first.
            compositeOverlay(buffer, bytesPerRow: bytesPerRow)
        }
        canvas.save()
        let target = context.ctm.concatenating(Self.flip(deviceHeight))
        let box = context.boundingBoxOfClipPath.applying(context.ctm)
        uikitClips.removeAll { !Self.contains($0.box, box) }
        if !Self.contains(box, baseClip) {
            canvas._setCTM(.identity)
            canvas.clip(to: box.applying(Self.flip(deviceHeight)))
        }
        if target != canvas.ctm { canvas._setCTM(target) }
        for clip in uikitClips { canvas.clip(to: clip.path) }
        body(canvas)
        canvas.restore()
    }

    private static func contains(_ outer: CGRect, _ inner: CGRect) -> Bool {
        let e: CGFloat = 1e-6
        return inner.minX >= outer.minX - e && inner.minY >= outer.minY - e
            && inner.maxX <= outer.maxX + e && inner.maxY <= outer.maxY + e
    }
}

extension Bitmap {
    /// These straight-alpha pixels as a premultiplied sRGB CGImage (the
    /// layout UIKit's images report: MEASURED iOS 26.1 cgunifyprobe
    /// `## uiimage cgImage`, 8 bpc / 32 bpp, premultiplied-last).
    func _premultipliedCGImage() -> CGImage? {
        guard width > 0, height > 0, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeBufferPointer { src in
            var i = 0
            while i + 3 < src.count {
                let a = Int(src[i + 3])
                bytes[i + 3] = UInt8(a)
                if a == 255 {
                    bytes[i] = src[i]; bytes[i + 1] = src[i + 1]; bytes[i + 2] = src[i + 2]
                } else if a > 0 {
                    bytes[i] = UInt8((Int(src[i]) * a + 127) / 255)
                    bytes[i + 1] = UInt8((Int(src[i + 1]) * a + 127) / 255)
                    bytes[i + 2] = UInt8((Int(src[i + 2]) * a + 127) / 255)
                }
                i += 4
            }
        }
        guard let data = CFDataCreate(nil, bytes, bytes.count),
              let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: space,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true,
                       intent: .defaultIntent)
    }

    /// A CoreGraphics image's pixels, straight alpha, drawn 1:1 into sRGB.
    convenience init?(_ image: CGImage) {
        let width = image.width, height = image.height
        guard width > 0, height > 0, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var premultiplied = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = premultiplied.withUnsafeMutableBytes { raw in
            guard let context = CGContext(data: raw.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            context.setBlendMode(.copy)
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        self.init(width: width, height: height)
        var i = 0
        while i + 3 < premultiplied.count {
            let a = Int(premultiplied[i + 3])
            pixels[i + 3] = UInt8(a)
            if a == 255 {
                pixels[i] = premultiplied[i]; pixels[i + 1] = premultiplied[i + 1]
                pixels[i + 2] = premultiplied[i + 2]
            } else if a > 0 {
                pixels[i] = UInt8(Swift.min(255, (Int(premultiplied[i]) * 255 + a / 2) / a))
                pixels[i + 1] = UInt8(Swift.min(255, (Int(premultiplied[i + 1]) * 255 + a / 2) / a))
                pixels[i + 2] = UInt8(Swift.min(255, (Int(premultiplied[i + 2]) * 255 + a / 2) / a))
            }
            i += 4
        }
    }
}

extension Path {
    /// This path as a CoreGraphics path.
    var _cgPath: CGPath {
        let path = CGMutablePath()
        for element in elements {
            switch element {
            case .move(let p): path.move(to: p)
            case .line(let p): path.addLine(to: p)
            case .quad(let c, let p): path.addQuadCurve(to: p, control: c)
            case .cubic(let c1, let c2, let p): path.addCurve(to: p, control1: c1, control2: c2)
            case .close: path.closeSubpath()
            }
        }
        return path
    }

    /// A CoreGraphics path as the renderer's path.
    init(_ cgPath: CGPath) {
        var path = Path()
        cgPath.applyWithBlock { pointer in
            let element = pointer.pointee
            let p = element.points
            switch element.type {
            case .moveToPoint: path.move(to: p[0])
            case .addLineToPoint: path.addLine(to: p[0])
            case .addQuadCurveToPoint: path.addQuad(to: p[1], control: p[0])
            case .addCurveToPoint: path.addCurve(to: p[2], control1: p[0], control2: p[1])
            case .closeSubpath: path.close()
            @unknown default: break
            }
        }
        self = path
    }
}
#endif
