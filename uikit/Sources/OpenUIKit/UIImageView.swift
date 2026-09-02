// UIImageView. Owner: image module.
//
// Geometry contract (verified against golden/imageview_modes.layout.json/.png):
//   - intrinsicContentSize / sizeThatFits = image point size.
//   - contentMode maps the image's POINT size into bounds exactly like
//     CALayer contentsGravity:
//       scaleToFill/redraw  -> bounds
//       scaleAspectFit      -> min-scale, centered letterbox
//       scaleAspectFill     -> max-scale, centered (overflows; view clips
//                              only when clipsToBounds is set)
//       center/edges/corners-> unscaled placement at image point size;
//                              centering offsets are NOT rounded (UIKit
//                              places contents at fractional half-point
//                              offsets; at scale 2 a half point is a whole
//                              device pixel, so goldens stay pixel-exact).
//   - Drawing samples bilinearly when scaling (CG default interpolation);
//     unscaled placements land source pixels exactly on destination pixels,
//     where bilinear degenerates to a lossless copy.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

/// Shared pre-allocation conversion for renderer, layer, image-view, and
/// procedural-image paths. Keeping the limit neutral avoids making generic
/// renderers depend semantically on UIImageView while ensuring every route
/// checks the same finite/range/overflow invariants before creating a Bitmap.
enum _UIBitmapAllocation {
    static func checkedPixelSize(
        for rect: CGRect,
        scale: CGFloat,
        maximumScale: CGFloat = 4,
        maximumDimension: CGFloat = 8192,
        maximumPixels: Int = 16_000_000
    ) -> (width: Int, height: Int)? {
        guard maximumDimension.isFinite, maximumDimension > 0,
              maximumPixels > 0,
              rect.origin.x.isFinite, rect.origin.y.isFinite,
              rect.width.isFinite, rect.height.isFinite,
              rect.width > 0, rect.height > 0,
              maximumScale.isFinite, maximumScale > 0,
              scale.isFinite, scale > 0,
              scale <= maximumScale else { return nil }
        let rawWidth = rect.width * scale
        let rawHeight = rect.height * scale
        guard rawWidth.isFinite, rawHeight.isFinite,
              rawWidth > 0, rawHeight > 0,
              rawWidth <= maximumDimension,
              rawHeight <= maximumDimension else { return nil }
        let width = Int(rawWidth.rounded())
        let height = Int(rawHeight.rounded())
        guard width > 0, height > 0,
              width <= Int(maximumDimension),
              height <= Int(maximumDimension),
              width <= maximumPixels / height else { return nil }
        return (width, height)
    }
}

@preconcurrency @MainActor
open class UIImageView: UIView {
    open var image: UIImage? {
        didSet {
            guard image !== oldValue else { return }
            setNeedsDisplay()
            setNeedsLayout()
        }
    }

    public init(image: UIImage?) {
        super.init(frame: CGRect(origin: .zero, size: image?.size ?? .zero))
        self.image = image
        // UIKit: image views do not receive touches by default.
        isUserInteractionEnabled = false
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
    }

    open override var intrinsicContentSize: CGSize {
        guard let image else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return image.size
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        image?.size ?? super.sizeThatFits(size)
    }

    /// Destination rect (in bounds coordinates, points) for an image of
    /// point size `imageSize` under `mode`. Pure function for testability.
    static func contentRect(imageSize s: CGSize, bounds: CGRect,
                            mode: UIViewContentMode) -> CGRect {
        let w = bounds.width, h = bounds.height
        let midX = bounds.minX + (w - s.width) / 2
        let midY = bounds.minY + (h - s.height) / 2
        let maxX = bounds.maxX - s.width
        let maxY = bounds.maxY - s.height
        switch mode {
        case .scaleToFill, .redraw:
            return bounds
        case .scaleAspectFit, .scaleAspectFill:
            guard s.width > 0, s.height > 0 else { return bounds }
            let sx = w / s.width, sy = h / s.height
            let f = mode == .scaleAspectFit ? Swift.min(sx, sy) : Swift.max(sx, sy)
            let sw = s.width * f, sh = s.height * f
            return CGRect(x: bounds.minX + (w - sw) / 2, y: bounds.minY + (h - sh) / 2,
                          width: sw, height: sh)
        case .center:
            return CGRect(x: midX, y: midY, width: s.width, height: s.height)
        case .top:
            return CGRect(x: midX, y: bounds.minY, width: s.width, height: s.height)
        case .bottom:
            return CGRect(x: midX, y: maxY, width: s.width, height: s.height)
        case .left:
            return CGRect(x: bounds.minX, y: midY, width: s.width, height: s.height)
        case .right:
            return CGRect(x: maxX, y: midY, width: s.width, height: s.height)
        case .topLeft:
            return CGRect(x: bounds.minX, y: bounds.minY, width: s.width, height: s.height)
        case .topRight:
            return CGRect(x: maxX, y: bounds.minY, width: s.width, height: s.height)
        case .bottomLeft:
            return CGRect(x: bounds.minX, y: maxY, width: s.width, height: s.height)
        case .bottomRight:
            return CGRect(x: maxX, y: maxY, width: s.width, height: s.height)
        }
    }

    open override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard let image, image.bitmap.width > 0, image.bitmap.height > 0 else { return }
        let rect = UIImageView.contentRect(imageSize: image.size, bounds: bounds,
                                           mode: contentMode)
        guard let destination = _UIBitmapAllocation.checkedPixelSize(
            for: rect,
            scale: canvas.scale
        ) else { return }
        let drawable = image._usesTemplateTint
            ? image._withTintColor(tintColor, renderingMode: .alwaysOriginal,
                                   traits: traitCollection)
            : image
        // Pre-resample to the destination's device pixel size with the
        // CG-compatible warped-weight filter (see UIImage.resampledBitmap).
        // For integer-aligned destinations Canvas.draw then degenerates to a
        // 1:1 blit, so the exact CG scaling profile reaches the surface.
        canvas.draw(drawable.resampledBitmap(width: destination.width,
                                             height: destination.height), in: rect,
                    interpolate: true)
    }
}
