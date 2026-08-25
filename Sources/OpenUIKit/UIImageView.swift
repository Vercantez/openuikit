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

@MainActor
open class UIImageView: UIView {
    open var image: UIImage?

    public init(image: UIImage?) {
        super.init(frame: CGRect(origin: .zero, size: image?.size ?? .zero))
        self.image = image
        // UIKit: image views do not receive touches by default.
        isUserInteractionEnabled = false
    }

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
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
        guard rect.width > 0, rect.height > 0 else { return }
        // Pre-resample to the destination's device pixel size with the
        // CG-compatible warped-weight filter (see UIImage.resampledBitmap).
        // For integer-aligned destinations Canvas.draw then degenerates to a
        // 1:1 blit, so the exact CG scaling profile reaches the surface.
        let dw = Int((rect.width * canvas.scale).rounded())
        let dh = Int((rect.height * canvas.scale).rounded())
        guard dw > 0, dh > 0 else { return }
        canvas.draw(image.resampledBitmap(width: dw, height: dh), in: rect,
                    interpolate: true)
    }
}
