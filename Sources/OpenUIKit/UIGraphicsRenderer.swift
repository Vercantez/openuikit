// App-side drawing entry points. Owner: image/drawing module.
//
// Three pieces, all thin over machinery that already exists:
//
//  1. A CURRENT-CONTEXT stack. UIKit's drawing calls
//     (`UIBezierPath.fill()`, `UIColor.setFill()`, `UIRectFill`) act on an
//     implicit context; here that context IS an OpenCoreGraphics `Canvas`,
//     handed to app code by `UIGraphicsGetCurrentContext()`. The color
//     state UIKit keeps in the CGContext lives alongside it.
//  2. `UIGraphicsImageRenderer(size:)` / `image(actions:)` — renders into a
//     transparent (or opaque) offscreen Bitmap at the format's scale and
//     returns a `UIImage` at that scale.
//  3. `UIView.draw(_ rect:)` support: `UIView.drawContent` (the render
//     pipeline's per-view content hook) pushes the canvas and calls
//     `draw(bounds)`. A view whose `draw` override changes what it paints
//     calls `setNeedsDisplay()`, exactly like UIKit — that bumps
//     `contentVersion`, which is part of LayerBridge's content-cache key,
//     so the cached contents image is dropped and re-rendered.

/// One entry of the current-context stack: the surface plus the implicit
/// fill/stroke colors CG keeps in its graphics state.
final class UIGraphicsState {
    let canvas: Canvas
    var fillColor: CGColor = .black
    var strokeColor: CGColor = .black
    init(canvas: Canvas) { self.canvas = canvas }
}

public enum UIGraphics {
    static var stack: [UIGraphicsState] = []
    static var top: UIGraphicsState? { stack.last }

    /// Make `canvas` the current drawing context (UIGraphicsPushContext).
    public static func pushContext(_ canvas: Canvas) {
        stack.append(UIGraphicsState(canvas: canvas))
    }
    /// Pop the current drawing context (UIGraphicsPopContext).
    public static func popContext() {
        if !stack.isEmpty { stack.removeLast() }
    }
    /// The current drawing context, or nil outside a draw block.
    public static var currentContext: Canvas? { stack.last?.canvas }
}

/// UIKit's `UIGraphicsGetCurrentContext()`. The "CGContext" of OpenUIKit is
/// an OpenCoreGraphics `Canvas` (same drawing model: point user space,
/// CTM, clip, transparency layers).
public func UIGraphicsGetCurrentContext() -> Canvas? { UIGraphics.currentContext }
public func UIGraphicsPushContext(_ canvas: Canvas) { UIGraphics.pushContext(canvas) }
public func UIGraphicsPopContext() { UIGraphics.popContext() }

/// Current implicit fill / stroke colors (set by `UIColor.setFill()` /
/// `setStroke()`; black by default, like CG).
public func UIGraphicsCurrentFillColor() -> CGColor { UIGraphics.top?.fillColor ?? .black }
public func UIGraphicsCurrentStrokeColor() -> CGColor { UIGraphics.top?.strokeColor ?? .black }

extension UIColor {
    /// Set this color as the current context's fill color.
    public func setFill() {
        UIGraphics.top?.fillColor = resolvedCGColor(with: UITraitCollection.current)
    }
    /// Set this color as the current context's stroke color.
    public func setStroke() {
        UIGraphics.top?.strokeColor = resolvedCGColor(with: UITraitCollection.current)
    }
    /// Set this color as BOTH the fill and stroke color (UIKit's `set()`).
    public func set() { setFill(); setStroke() }
}

/// UIKit's `UIRectFill` — fill a rect with the current fill color.
public func UIRectFill(_ rect: CGRect) {
    UIGraphicsGetCurrentContext()?.fill(rect: rect, color: UIGraphicsCurrentFillColor())
}

// MARK: - UIGraphicsImageRenderer

public class UIGraphicsImageRendererFormat {
    /// Pixels per point of the rendered image. Defaults to
    /// `OpenUIKitRuntime.imageScreenScale` (UIKit uses the main screen's).
    public var scale: CGFloat
    /// When true the image starts filled with opaque black-alpha... i.e.
    /// UIKit's opaque format: the backing store has no transparency, and
    /// unpainted pixels stay opaque black. Default false.
    public var opaque: Bool

    public init(scale: CGFloat = OpenUIKitRuntime.imageScreenScale, opaque: Bool = false) {
        self.scale = scale > 0 ? scale : 1
        self.opaque = opaque
    }
    public static func `default`() -> UIGraphicsImageRendererFormat {
        UIGraphicsImageRendererFormat()
    }
    public static func preferred() -> UIGraphicsImageRendererFormat { `default`() }
}

/// The object handed to a `UIGraphicsImageRenderer` drawing block.
public class UIGraphicsImageRendererContext {
    /// The drawing surface (UIKit calls this `cgContext`).
    public let cgContext: Canvas
    public let format: UIGraphicsImageRendererFormat
    /// Bounds of the image being drawn, in points.
    public let currentImage: CGRect

    init(canvas: Canvas, format: UIGraphicsImageRendererFormat, bounds: CGRect) {
        self.cgContext = canvas
        self.format = format
        self.currentImage = bounds
    }

    public func fill(_ rect: CGRect) {
        cgContext.fill(rect: rect, color: UIGraphicsCurrentFillColor())
    }
    public func stroke(_ rect: CGRect) {
        cgContext.stroke(.rect(rect), color: UIGraphicsCurrentStrokeColor(), lineWidth: 1)
    }
}

/// UIKit's `UIGraphicsImageRenderer`: draw into an offscreen and get a
/// `UIImage` back.
public class UIGraphicsImageRenderer {
    public let size: CGSize
    public let format: UIGraphicsImageRendererFormat

    public init(size: CGSize, format: UIGraphicsImageRendererFormat = .default()) {
        self.size = size
        self.format = format
    }
    public convenience init(bounds: CGRect,
                            format: UIGraphicsImageRendererFormat = .default()) {
        self.init(size: bounds.size, format: format)
    }

    /// Run `actions` against a fresh offscreen context and return the result
    /// as a UIImage at the format's scale. A zero-area size yields a 1x1
    /// empty image rather than trapping (UIKit returns an empty image too).
    public func image(actions: (UIGraphicsImageRendererContext) -> Void) -> UIImage {
        let scale = format.scale
        let pw = Swift.max(0, Int((size.width * scale).rounded()))
        let ph = Swift.max(0, Int((size.height * scale).rounded()))
        let bitmap = Bitmap(width: Swift.max(1, pw), height: Swift.max(1, ph))
        if format.opaque {
            // Opaque format: start from opaque black, like a CGBitmapContext
            // with kCGImageAlphaNoneSkipLast cleared to black.
            var i = 3
            while i < bitmap.pixels.count { bitmap.pixels[i] = 255; i += 4 }
        }
        guard pw > 0, ph > 0 else { return UIImage(bitmap: bitmap, scale: scale) }
        let canvas = Canvas(bitmap: bitmap, scale: scale)
        UIGraphics.pushContext(canvas)
        actions(UIGraphicsImageRendererContext(
            canvas: canvas, format: format,
            bounds: CGRect(origin: .zero, size: size)))
        UIGraphics.popContext()
        return UIImage(bitmap: bitmap, scale: scale)
    }

    /// PNG data of `image(actions:)` (UIKit's `pngData(actions:)`).
    public func pngData(actions: (UIGraphicsImageRendererContext) -> Void) -> [UInt8] {
        image(actions: actions).pngData() ?? []
    }

    /// JPEG data of `image(actions:)`.
    public func jpegData(withCompressionQuality quality: CGFloat,
                         actions: (UIGraphicsImageRendererContext) -> Void) -> [UInt8] {
        image(actions: actions).jpegData(compressionQuality: quality) ?? []
    }
}
