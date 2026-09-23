// App-side drawing entry points. Owner: image/drawing module.
//
// Three pieces, all thin over machinery that already exists:
//
//  1. A CURRENT-CONTEXT stack. UIKit's drawing calls
//     (`UIBezierPath.fill()`, `UIColor.setFill()`, `UIRectFill`) act on an
//     implicit context backed by an OpenCoreGraphics `Canvas`. App code gets
//     it from `UIGraphicsGetCurrentContext()`: an Apple `CGContext` over the
//     same pixels where CoreGraphics exists (UIGraphicsCoreGraphics.swift,
//     cg-unify), the Canvas itself elsewhere (`CGContext` = `Canvas`).
//  2. `UIGraphicsImageRenderer(size:)` / `image(actions:)` — renders into a
//     transparent (or opaque) offscreen Bitmap at the format's scale and
//     returns a `UIImage` at that scale.
//  3. `UIView.draw(_ rect:)` support: `UIView.drawContent` (the render
//     pipeline's per-view content hook) pushes the canvas and calls
//     `draw(bounds)`. A view whose `draw` override changes what it paints
//     calls `setNeedsDisplay()`, exactly like UIKit — that bumps
//     `contentVersion`, which is part of LayerBridge's content-cache key,
//     so the cached contents image is dropped and re-rendered.

#if canImport(CoreGraphics)
import class CoreGraphics.CGContext
#endif

/// One entry of the current-context stack: the surface plus the implicit
/// fill/stroke colors CG keeps in its graphics state.
final class UIGraphicsState {
    let canvas: Canvas
    /// Non-nil only for a legacy UIGraphicsBeginImageContext... entry.
    let imageScale: CGFloat?
    /// The rect a `draw(_:)` session is clipped to (user space).
    let clip: CGRect?
    var fillColor: CanvasColor = .black
    var strokeColor: CanvasColor = .black
    init(canvas: Canvas, imageScale: CGFloat? = nil, clip: CGRect? = nil) {
        self.canvas = canvas
        self.imageScale = imageScale
        self.clip = clip
    }
#if canImport(CoreGraphics)
    /// The session's CoreGraphics face, made on first request.
    var bridge: _UICoreGraphicsBridge?
    /// False for an entry that re-pushed another entry's context.
    var ownsBridge = true

    /// UIKit's CGContext for this entry (created lazily; the UIKit colour
    /// state set so far moves into it).
    var coreGraphicsContext: CGContext? {
        if bridge == nil, let made = _UICoreGraphicsBridge(canvas: canvas, clip: clip) {
            made.context.setFillColor(fillColor.cgColor)
            made.context.setStrokeColor(strokeColor.cgColor)
            bridge = made
        }
        return bridge?.context
    }
#endif
}

public enum UIGraphics {
    static var stack: [UIGraphicsState] = []
    static var top: UIGraphicsState? { stack.last }

    /// Make `canvas` the current drawing context (UIGraphicsPushContext).
    public static func pushContext(_ canvas: Canvas) {
        stack.append(UIGraphicsState(canvas: canvas))
    }
    /// A `draw(_:)` session: the context is clipped to `clip`.
    static func pushContext(_ canvas: Canvas, clip: CGRect) {
        stack.append(UIGraphicsState(canvas: canvas, clip: clip))
    }
    static func pushImageContext(_ canvas: Canvas, scale: CGFloat) {
        stack.append(UIGraphicsState(canvas: canvas, imageScale: scale))
    }
    /// Pop the current drawing context (UIGraphicsPopContext).
    public static func popContext() {
        guard let state = stack.popLast() else { return }
#if canImport(CoreGraphics)
        if state.ownsBridge, let bridge = state.bridge { bridge.finish() }
#else
        _ = state
#endif
    }
    /// The current drawing context's surface, or nil outside a draw block.
    public static var currentContext: Canvas? { stack.last?.canvas }

    /// Runs one UIKit drawing call on the current surface -- under the
    /// graphics state of UIKit's CGContext when app code holds it.
    static func draw(_ body: (Canvas) -> Void) {
        guard let state = top else { return }
#if canImport(CoreGraphics)
        if let bridge = state.bridge {
            bridge.draw(body)
            return
        }
#endif
        body(state.canvas)
    }

    /// Makes CoreGraphics' pixels visible in the current surface's bitmap.
    static func flushCurrent() {
#if canImport(CoreGraphics)
        top?.bridge?.flush()
#endif
    }
}

#if canImport(CoreGraphics)
/// UIKit's `UIGraphicsGetCurrentContext()`: CoreGraphics' own `CGContext`,
/// drawing into the current surface (UIGraphicsCoreGraphics.swift).
public func UIGraphicsGetCurrentContext() -> CGContext? { UIGraphics.top?.coreGraphicsContext }

/// UIKit's `UIGraphicsPushContext(_:)`. A context the port made re-enters
/// its own surface; an app-made bitmap context is drawn into directly.
public func UIGraphicsPushContext(_ context: CGContext) {
    if let bridge = _UICoreGraphicsBridge.bridge(for: context) {
        let state = UIGraphicsState(canvas: bridge.canvas)
        state.bridge = bridge
        state.ownsBridge = false
        UIGraphics.stack.append(state)
    } else {
        let bridge = _UICoreGraphicsBridge(adopting: context)
        let state = UIGraphicsState(canvas: bridge.canvas)
        state.bridge = bridge
        UIGraphics.stack.append(state)
    }
}
#else
/// Without Apple's CoreGraphics the CGContext of OpenUIKit is the
/// OpenCoreGraphics `Canvas` (same drawing model: point user space, CTM,
/// clip, transparency layers).
public typealias CGContext = Canvas

/// UIKit's `UIGraphicsGetCurrentContext()`.
public func UIGraphicsGetCurrentContext() -> CGContext? { UIGraphics.currentContext }
public func UIGraphicsPushContext(_ canvas: Canvas) { UIGraphics.pushContext(canvas) }
#endif
public func UIGraphicsPopContext() { UIGraphics.popContext() }

/// Current implicit fill / stroke colors (set by `UIColor.setFill()` /
/// `setStroke()`, or by the CGContext's own setters; black by default,
/// like CG).
public func UIGraphicsCurrentFillColor() -> CanvasColor {
#if canImport(CoreGraphics)
    if let color = UIGraphics.top?.bridge?.fillColor { return color }
#endif
    return UIGraphics.top?.fillColor ?? .black
}
public func UIGraphicsCurrentStrokeColor() -> CanvasColor {
#if canImport(CoreGraphics)
    if let color = UIGraphics.top?.bridge?.strokeColor { return color }
#endif
    return UIGraphics.top?.strokeColor ?? .black
}

extension UIColor {
    /// Set this color as the current context's fill color.
    public func setFill() {
        UIGraphics.top?.fillColor = resolvedCGColor(with: UITraitCollection.current)
#if canImport(CoreGraphics)
        UIGraphics.top?.bridge?.context.setFillColor(_cgColorObject(with: .current))
#endif
    }
    /// Set this color as the current context's stroke color.
    public func setStroke() {
        UIGraphics.top?.strokeColor = resolvedCGColor(with: UITraitCollection.current)
#if canImport(CoreGraphics)
        UIGraphics.top?.bridge?.context.setStrokeColor(_cgColorObject(with: .current))
#endif
    }
    /// Set this color as BOTH the fill and stroke color (UIKit's `set()`).
    public func set() { setFill(); setStroke() }
}

/// UIKit's `UIRectFill` — fill a rect with the current fill color.
public func UIRectFill(_ rect: CGRect) {
    UIGraphics.draw { $0.fill(rect: rect, color: UIGraphicsCurrentFillColor()) }
}

// MARK: - Legacy image-context API

/// Begin a bitmap image context and make it current. A scale of zero selects
/// the screen scale, matching UIKit; a positive scale is used verbatim.
public func UIGraphicsBeginImageContextWithOptions(_ size: CGSize, _ opaque: Bool,
                                                    _ scale: CGFloat) {
    let resolvedScale = scale > 0 ? scale : OpenUIKitRuntime.imageScreenScale
    let pw = Swift.max(0, Int((size.width * resolvedScale).rounded()))
    let ph = Swift.max(0, Int((size.height * resolvedScale).rounded()))
    // Canvas requires a real surface. Keep UIKit's harmless zero-size
    // behavior by using a transparent 1x1 backing for a degenerate request.
    let bitmap = Bitmap(width: Swift.max(1, pw), height: Swift.max(1, ph))
    if opaque {
        var i = 3
        while i < bitmap.pixels.count { bitmap.pixels[i] = 255; i += 4 }
    }
    UIGraphics.pushImageContext(Canvas(bitmap: bitmap, scale: resolvedScale),
                                scale: resolvedScale)
}

/// UIKit's `UIGraphicsBeginImageContext(_:)`: a transparent context at scale
/// 1. iOS 26.1 (iososswallsprobe lens.imageContext.*): a 1×1 request yields a
/// 1×1 image at scale 1.0 whose untouched pixel is (0,0,0,0).
public func UIGraphicsBeginImageContext(_ size: CGSize) {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
}

// MARK: - CGContext fill-colour state on the canvas
//
// UIKit hands app code a CGContext; OpenUIKit's is the Canvas. These are the
// CGContext spellings of the implicit fill colour the context stack already
// keeps (`UIColor.setFill()` writes the same slot). iOS 26.1: a fresh image
// context fills with opaque black (lens.imageContext.defaultFillPixel
// 0,0,0,255); after `setFillColor(red)` the pixel reads red.
extension Canvas {
    private var _graphicsState: UIGraphicsState? {
        UIGraphics.stack.last { $0.canvas === self }
    }

    /// CGContext's `setFillColor(_:)`. Recorded in this canvas's entry of
    /// the current-context stack; a canvas that is not on the stack keeps no
    /// colour state and the call is ignored.
    public func setFillColor(_ color: CGColor) {
        _graphicsState?.fillColor = CanvasColor(color)
    }

    /// CGContext's `setStrokeColor(_:)` (same storage rule).
    public func setStrokeColor(_ color: CGColor) {
        _graphicsState?.strokeColor = CanvasColor(color)
    }

    /// CGContext's `fill(_:)` with the current fill colour (black by default).
    public func fill(_ rect: CGRect) {
        fill(rect: rect, color: _graphicsState?.fillColor ?? .black)
    }
}

/// Snapshot the current legacy image context. Contexts installed with
/// UIGraphicsPushContext are not image contexts and therefore return nil.
public func UIGraphicsGetImageFromCurrentImageContext() -> UIImage? {
    guard let state = UIGraphics.top, let scale = state.imageScale else { return nil }
    UIGraphics.flushCurrent()
    let source = state.canvas.bitmap
    let snapshot = Bitmap(width: source.width, height: source.height)
    snapshot.pixels = source.pixels
    return UIImage(bitmap: snapshot, scale: scale)
}

/// End the current legacy image context and restore the previous context.
public func UIGraphicsEndImageContext() { UIGraphics.popContext() }

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
    /// The drawing surface.
    let canvas: Canvas
    public let format: UIGraphicsImageRendererFormat
    /// Bounds of the image being drawn, in points.
    public let currentImage: CGRect

    init(canvas: Canvas, format: UIGraphicsImageRendererFormat, bounds: CGRect) {
        self.canvas = canvas
        self.format = format
        self.currentImage = bounds
    }

    /// UIKit's `cgContext`: the renderer's current context (an Apple
    /// `CGContext` where CoreGraphics exists; cgunifyprobe: `cgContext ===
    /// UIGraphicsGetCurrentContext()` inside the block).
    public var cgContext: CGContext {
#if canImport(CoreGraphics)
        if let state = UIGraphics.stack.last(where: { $0.canvas === canvas }),
           let context = state.coreGraphicsContext {
            return context
        }
        return _UICoreGraphicsBridge(canvas: canvas, clip: nil)!.context
#else
        return canvas
#endif
    }

    public func fill(_ rect: CGRect) {
        UIGraphics.draw { $0.fill(rect: rect, color: UIGraphicsCurrentFillColor()) }
    }
    public func stroke(_ rect: CGRect) {
        UIGraphics.draw {
            $0.stroke(.rect(rect), color: UIGraphicsCurrentStrokeColor(), lineWidth: 1)
        }
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
