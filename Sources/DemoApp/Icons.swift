// DemoApp icon set. Owner: demo app (M7.5).
//
// iOS-Settings-style icon tiles: a 29x29 rounded-rect color chip with a
// white glyph. There are no SF Symbols in the portable stack, so each glyph
// is drawn directly with Canvas paths in `drawContent` — chunky, centered
// silhouettes tuned to read at 29pt like the real Settings icons do.
//
// Same rules as OpenUIKit: no Foundation. Trig comes from rotation
// transforms (CGAffineTransform(rotationAngle:)), not libm.

import OpenUIKit

// MARK: - Path helpers

/// (cos a, sin a) without libm: rotate the unit x vector.
private func unitVector(_ angle: CGFloat) -> CGPoint {
    CGPoint(x: 1, y: 0).applying(CGAffineTransform(rotationAngle: angle))
}

private func circlePath(_ center: CGPoint, _ r: CGFloat) -> Path {
    .roundedRect(CGRect(x: center.x - r, y: center.y - r,
                        width: 2 * r, height: 2 * r), cornerRadius: r)
}

private func polylinePath(_ pts: [CGPoint], close: Bool = false) -> Path {
    var p = Path()
    guard let first = pts.first else { return p }
    p.move(to: first)
    for pt in pts.dropFirst() { p.addLine(to: pt) }
    if close { p.close() }
    return p
}

/// Open circular arc from `a0` to `a1` (radians, y-down screen coords),
/// approximated with cubic segments (max quarter-circle per segment).
private func arcPath(center: CGPoint, radius r: CGFloat,
                     from a0: CGFloat, to a1: CGFloat) -> Path {
    var p = Path()
    let total = a1 - a0
    let segments = max(1, Int((total.magnitude / (.pi / 2)).rounded(.up)))
    let delta = total / CGFloat(segments)
    let quarter = unitVector(delta / 4)
    let k = (4.0 / 3.0) * (quarter.y / quarter.x) // 4/3 · tan(Δ/4)
    var a = a0
    let u0 = unitVector(a)
    p.move(to: CGPoint(x: center.x + r * u0.x, y: center.y + r * u0.y))
    for _ in 0..<segments {
        let b = a + delta
        let ua = unitVector(a), ub = unitVector(b)
        let p0 = CGPoint(x: center.x + r * ua.x, y: center.y + r * ua.y)
        let p3 = CGPoint(x: center.x + r * ub.x, y: center.y + r * ub.y)
        let c1 = CGPoint(x: p0.x - k * r * ua.y, y: p0.y + k * r * ua.x)
        let c2 = CGPoint(x: p3.x + k * r * ub.y, y: p3.y - k * r * ub.x)
        p.addCurve(to: p3, control1: c1, control2: c2)
        a = b
    }
    return p
}

private func rotatedRect(center: CGPoint, width: CGFloat, height: CGFloat,
                         angle: CGFloat, cornerRadius: CGFloat = 0) -> Path {
    let r = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
    let t = CGAffineTransform(rotationAngle: angle)
        .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
    return Path.roundedRect(r, cornerRadius: cornerRadius).applying(t)
}

// MARK: - Icon glyphs

/// The DemoApp icon vocabulary (drawn in a 29x29 tile space).
public enum IconGlyph {
    case airplane, wifi, bluetooth, cellular, battery
    case bell, speaker, moon, hourglass
    case gear, toggles, sun, grid, person, shield, info
}

/// Draw `glyph` in `color` into a 29x29-normalized tile space. `tileColor`
/// is the opaque backing color, used by glyphs that carve a bite out of
/// their silhouette (.moon).
func drawIconGlyph(_ glyph: IconGlyph, in canvas: Canvas, bounds: CGRect,
                   color: CGColor,
                   tileColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)) {
    // Normalize to the 29x29 design space.
    canvas.save()
    defer { canvas.restore() }
    canvas.translate(x: bounds.minX, y: bounds.minY)
    let s = min(bounds.width, bounds.height) / 29
    canvas.concatenate(CGAffineTransform(scaleX: s, y: s))
    let c = CGPoint(x: 14.5, y: 14.5)

    switch glyph {
    case .airplane:
        // Nose-up plane silhouette (wings mid, tail fins low).
        let pts: [CGPoint] = [
            CGPoint(x: 14.5, y: 3.6), CGPoint(x: 16.1, y: 6.2),
            CGPoint(x: 16.1, y: 11.2), CGPoint(x: 25.4, y: 16.6),
            CGPoint(x: 25.4, y: 18.6), CGPoint(x: 16.1, y: 15.9),
            CGPoint(x: 16.1, y: 20.6), CGPoint(x: 19.4, y: 22.9),
            CGPoint(x: 19.4, y: 24.6), CGPoint(x: 14.5, y: 23.2),
            CGPoint(x: 9.6, y: 24.6), CGPoint(x: 9.6, y: 22.9),
            CGPoint(x: 12.9, y: 20.6), CGPoint(x: 12.9, y: 15.9),
            CGPoint(x: 3.6, y: 18.6), CGPoint(x: 3.6, y: 16.6),
            CGPoint(x: 12.9, y: 11.2), CGPoint(x: 12.9, y: 6.2),
        ]
        canvas.fill(polylinePath(pts, close: true), color: color)
    case .wifi:
        let base = CGPoint(x: 14.5, y: 20.0)
        canvas.fill(circlePath(base, 2.4), color: color)
        for r in [6.8, 11.2] as [CGFloat] {
            canvas.stroke(arcPath(center: base, radius: r,
                                  from: -.pi * 0.78, to: -.pi * 0.22),
                          color: color, lineWidth: 2.6)
        }
    case .bluetooth:
        let p = polylinePath([
            CGPoint(x: 9.5, y: 9.7), CGPoint(x: 19.3, y: 18.7),
            CGPoint(x: 14.5, y: 23.4), CGPoint(x: 14.5, y: 5.6),
            CGPoint(x: 19.3, y: 10.3), CGPoint(x: 9.5, y: 19.3),
        ])
        canvas.stroke(p, color: color, lineWidth: 2.1)
    case .cellular:
        // Four ascending rounded bars.
        let heights: [CGFloat] = [7, 11, 15, 19]
        for (i, h) in heights.enumerated() {
            let x = 4.7 + CGFloat(i) * 5.3
            canvas.fill(.roundedRect(CGRect(x: x, y: 24 - h, width: 3.7, height: h),
                                     cornerRadius: 1.5), color: color)
        }
    case .battery:
        canvas.stroke(.roundedRect(CGRect(x: 4.4, y: 9.8, width: 17.4, height: 9.4),
                                   cornerRadius: 3), color: color, lineWidth: 1.8)
        canvas.fill(.roundedRect(CGRect(x: 23.2, y: 12.6, width: 2.2, height: 3.8),
                                 cornerRadius: 1.1), color: color)
        canvas.fill(.roundedRect(CGRect(x: 6.6, y: 12.0, width: 9.5, height: 5),
                                 cornerRadius: 1.4), color: color)
    case .bell:
        var dome = Path()
        dome.move(to: CGPoint(x: 8.0, y: 19.4))
        dome.addCurve(to: CGPoint(x: 14.5, y: 6.8),
                      control1: CGPoint(x: 8.0, y: 11.4),
                      control2: CGPoint(x: 10.4, y: 6.8))
        dome.addCurve(to: CGPoint(x: 21.0, y: 19.4),
                      control1: CGPoint(x: 18.6, y: 6.8),
                      control2: CGPoint(x: 21.0, y: 11.4))
        dome.close()
        canvas.fill(dome, color: color)
        canvas.fill(.roundedRect(CGRect(x: 6.2, y: 18.6, width: 16.6, height: 2.6),
                                 cornerRadius: 1.3), color: color)
        canvas.fill(circlePath(CGPoint(x: 14.5, y: 23.4), 2.0), color: color)
    case .speaker:
        canvas.fill(polylinePath([
            CGPoint(x: 5.4, y: 11.6), CGPoint(x: 9.6, y: 11.6),
            CGPoint(x: 14.6, y: 7.2), CGPoint(x: 14.6, y: 21.8),
            CGPoint(x: 9.6, y: 17.4), CGPoint(x: 5.4, y: 17.4),
        ], close: true), color: color)
        for r in [4.2, 7.2] as [CGFloat] {
            canvas.stroke(arcPath(center: CGPoint(x: 16.4, y: 14.5), radius: r,
                                  from: -.pi * 0.28, to: .pi * 0.28),
                          color: color, lineWidth: 2.0)
        }
    case .moon:
        // Crescent: white disc with the "bite" disc painted back in the
        // tile color (the glyph only ever sits on an opaque tile).
        canvas.fill(circlePath(CGPoint(x: 14, y: 15), 8.2), color: color)
        canvas.fill(circlePath(CGPoint(x: 20.2, y: 9.6), 7.6), color: tileColor)
    case .hourglass:
        canvas.fill(.roundedRect(CGRect(x: 8.2, y: 5.6, width: 12.6, height: 2.2),
                                 cornerRadius: 1.1), color: color)
        canvas.fill(.roundedRect(CGRect(x: 8.2, y: 21.2, width: 12.6, height: 2.2),
                                 cornerRadius: 1.1), color: color)
        canvas.fill(polylinePath([
            CGPoint(x: 9.6, y: 7.8), CGPoint(x: 19.4, y: 7.8),
            CGPoint(x: 14.5, y: 14.5),
        ], close: true), color: color)
        canvas.fill(polylinePath([
            CGPoint(x: 9.6, y: 21.2), CGPoint(x: 19.4, y: 21.2),
            CGPoint(x: 14.5, y: 14.5),
        ], close: true), color: color)
    case .gear:
        // Annulus + 8 teeth.
        var ring = circlePath(c, 7.6)
        ring.elements.append(contentsOf: circlePath(c, 3.4).elements)
        canvas.fill(ring, color: color, evenOdd: true)
        for i in 0..<8 {
            let a = CGFloat(i) * .pi / 4
            let u = unitVector(a)
            let center = CGPoint(x: c.x + 8.4 * u.x, y: c.y + 8.4 * u.y)
            canvas.fill(rotatedRect(center: center, width: 3.2, height: 4.4,
                                    angle: a, cornerRadius: 1.0), color: color)
        }
    case .toggles:
        canvas.stroke(.roundedRect(CGRect(x: 5.6, y: 6.8, width: 17.8, height: 6.6),
                                   cornerRadius: 3.3), color: color, lineWidth: 1.7)
        canvas.fill(circlePath(CGPoint(x: 9.4, y: 10.1), 2.0), color: color)
        canvas.stroke(.roundedRect(CGRect(x: 5.6, y: 15.6, width: 17.8, height: 6.6),
                                   cornerRadius: 3.3), color: color, lineWidth: 1.7)
        canvas.fill(circlePath(CGPoint(x: 19.6, y: 18.9), 2.0), color: color)
    case .sun:
        canvas.fill(circlePath(c, 4.6), color: color)
        for i in 0..<8 {
            let a = CGFloat(i) * .pi / 4
            let u = unitVector(a)
            let center = CGPoint(x: c.x + 8.6 * u.x, y: c.y + 8.6 * u.y)
            canvas.fill(rotatedRect(center: center, width: 3.4, height: 1.9,
                                    angle: a, cornerRadius: 0.95), color: color)
        }
    case .grid:
        for (x, y) in [(5.8, 5.8), (15.6, 5.8), (5.8, 15.6), (15.6, 15.6)] {
            canvas.fill(.roundedRect(CGRect(x: CGFloat(x), y: CGFloat(y),
                                            width: 7.6, height: 7.6),
                                     cornerRadius: 2.2), color: color)
        }
    case .person:
        canvas.stroke(circlePath(c, 8.9), color: color, lineWidth: 1.7)
        canvas.fill(circlePath(CGPoint(x: 14.5, y: 10.2), 2.1), color: color)
        canvas.stroke(polylinePath([CGPoint(x: 9.8, y: 14.1),
                                    CGPoint(x: 19.2, y: 14.1)]),
                      color: color, lineWidth: 1.7)
        canvas.stroke(polylinePath([CGPoint(x: 14.5, y: 13.2),
                                    CGPoint(x: 14.5, y: 16.4)]),
                      color: color, lineWidth: 1.7)
        canvas.stroke(polylinePath([CGPoint(x: 11.6, y: 20.4),
                                    CGPoint(x: 14.5, y: 16.4),
                                    CGPoint(x: 17.4, y: 20.4)]),
                      color: color, lineWidth: 1.7)
    case .shield:
        var p = Path()
        p.move(to: CGPoint(x: 14.5, y: 5.4))
        p.addCurve(to: CGPoint(x: 22.4, y: 8.6),
                   control1: CGPoint(x: 17.2, y: 6.8),
                   control2: CGPoint(x: 20.2, y: 8.2))
        p.addCurve(to: CGPoint(x: 14.5, y: 24.0),
                   control1: CGPoint(x: 22.4, y: 16.4),
                   control2: CGPoint(x: 19.4, y: 21.6))
        p.addCurve(to: CGPoint(x: 6.6, y: 8.6),
                   control1: CGPoint(x: 9.6, y: 21.6),
                   control2: CGPoint(x: 6.6, y: 16.4))
        p.addCurve(to: CGPoint(x: 14.5, y: 5.4),
                   control1: CGPoint(x: 8.8, y: 8.2),
                   control2: CGPoint(x: 11.8, y: 6.8))
        p.close()
        canvas.fill(p, color: color)
    case .info:
        canvas.stroke(circlePath(c, 8.9), color: color, lineWidth: 1.7)
        canvas.fill(circlePath(CGPoint(x: 14.5, y: 9.9), 1.5), color: color)
        canvas.fill(.roundedRect(CGRect(x: 13.2, y: 12.6, width: 2.6, height: 8.0),
                                 cornerRadius: 1.3), color: color)
    }
}

// MARK: - Icon tile

/// The 29x29 rounded color chip with a white glyph — the leading element of
/// a Settings row.
public final class IconTile: UIView {
    public static let tileSize = CGSize(width: 29, height: 29)
    let glyph: IconGlyph

    public init(glyph: IconGlyph, color: UIColor) {
        self.glyph = glyph
        super.init(frame: CGRect(origin: .zero, size: IconTile.tileSize))
        backgroundColor = color
        layer.cornerRadius = 6.5
        clipsToBounds = true
        isUserInteractionEnabled = false
        isOpaque = false
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let tile = (backgroundColor ?? .black).resolvedCGColor(with: traitCollection)
        drawIconGlyph(glyph, in: canvas, bounds: bounds, color: white,
                      tileColor: tile)
    }
}
