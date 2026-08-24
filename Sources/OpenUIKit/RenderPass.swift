// View-hierarchy render traversal. Owner: view module.
// SKELETON with working basic traversal — view module must verify/complete:
// autoresizing, transform-about-center correctness, border ring geometry,
// hard-edge (non-AA) fills for rotated layers (see ARCHITECTURE.md),
// pixel-boundary behaviors validated against goldens.

public enum UIRenderer {
    /// Render a laid-out view hierarchy into a fresh bitmap.
    public static func render(_ root: UIView, scale: CGFloat) -> Bitmap {
        let w = Int((root.bounds.width * scale).rounded())
        let h = Int((root.bounds.height * scale).rounded())
        let bitmap = Bitmap(width: w, height: h)
        let canvas = Canvas(bitmap: bitmap, scale: scale)
        renderView(root, into: canvas)
        return bitmap
    }

    static func renderView(_ v: UIView, into c: Canvas) {
        if v.isHidden || v.alpha <= 0 { return }
        c.save()
        if v.alpha < 1 { c.beginTransparencyLayer(alpha: v.alpha) }

        let bounds = v.bounds
        let radius = v.layer.cornerRadius
        if v.clipsToBounds { c.clip(to: bounds, cornerRadius: radius) }

        if let bg = v.backgroundColor {
            let color = bg.resolvedCGColor(with: v.traitCollection)
            if color.alpha > 0 {
                c.fill(.roundedRect(bounds, cornerRadius: radius), color: color)
            }
        }
        v.drawContent(in: c, bounds: bounds)

        for sub in v.subviews {
            c.save()
            c.translate(x: sub.center.x, y: sub.center.y)
            c.concatenate(sub.transform)
            c.translate(x: -sub.bounds.midX, y: -sub.bounds.midY)
            renderView(sub, into: c)
            c.restore()
        }

        // CALayer draws its border ABOVE sublayers.
        if v.layer.borderWidth > 0, let bc = v.layer.borderColor, bc.alpha > 0 {
            let bw = v.layer.borderWidth
            var ring = Path.roundedRect(bounds, cornerRadius: radius)
            let innerRect = bounds.insetBy(dx: bw, dy: bw)
            if !innerRect.isNull && innerRect.width > 0 && innerRect.height > 0 {
                let innerRadius = Swift.max(0, radius - bw)
                ring.elements += Path.roundedRect(innerRect, cornerRadius: innerRadius).elements
                c.fill(ring, color: bc, evenOdd: true)
            } else {
                c.fill(ring, color: bc)
            }
        }

        if v.alpha < 1 { c.endTransparencyLayer() }
        c.restore()
    }
}
