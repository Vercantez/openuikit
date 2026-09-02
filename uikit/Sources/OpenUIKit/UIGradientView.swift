// UIGradientView — a UIView whose backing layer is a CAGradientLayer
// (scene-spec v2). Owner: view module.
//
// CAGradientLayer semantics reproduced here (validated against
// golden/gradient_*.png):
// - startPoint/endPoint are in the UNIT coordinate space of bounds
//   (iOS top-left geometry: (0.5, 0) = top center, (0.5, 1) = bottom
//   center — the defaults, giving a top→bottom gradient).
// - Pixels project onto the start→end axis in unit space; the gradient
//   clamps to the end colors outside [0, 1] (fills the whole bounds).
// - `locations` nil = evenly spaced stops.
// - Color interpolation does NOT happen in gamma-encoded sRGB (what
//   CGGradient over an sRGB stop space does). Fitting the golden ramps
//   shows CA's software renderer interpolates in a gamma-1.8 encoded
//   space whose linear primaries are a small mix away from linear sRGB —
//   consistent with a round trip through the Generic RGB (gamma 1.8)
//   profile class. The transform below (matrix + gamma, least-squares
//   fitted against golden/gradient_basic + gradient_multi, validated on
//   gradient_dark: max channel error < 3 counts on held-out data) is:
//     interp = (M · srgbLinear(c))^(1/1.7984)
//   Interpolation is linear in that space. Since Canvas's gradient
//   contract (both backends) lerps in gamma-encoded sRGB, drawContent
//   DENSIFIES each stop segment into short sRGB-linear-enough pieces
//   (24 subdivisions ⇒ piecewise-linear error ≪ 1 count).
// - The gradient is layer CONTENT: it draws above backgroundColor and is
//   clipped by cornerRadius only via masksToBounds (the render pass
//   applies that clip before drawContent).

@preconcurrency @MainActor
public final class UIGradientView: UIView {
    /// Gradient stop colors (≥ 2 for a visible ramp). Resolved against the
    /// view's traitCollection at draw time, like CAGradientLayer.colors
    /// containing dynamic-provider-resolved CGColors.
    public var colors: [UIColor] = []
    /// Stop locations (0–1, ascending), one per color; nil = evenly spaced.
    public var locations: [CGFloat]?
    public var startPoint = CGPoint(x: 0.5, y: 0)
    public var endPoint = CGPoint(x: 0.5, y: 1)

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard !bounds.isEmpty, colors.count >= 2 else { return }
        let traits = traitCollection
        let resolved = colors.map { $0.resolvedCGColor(with: traits) }
        let n = resolved.count
        var locs: [CGFloat]
        if let l = locations, l.count == n {
            locs = l.map { min(max($0, 0), 1) }
        } else {
            locs = (0..<n).map { CGFloat($0) / CGFloat(n - 1) }
        }
        let (dColors, dLocs) = _CAGradientColorSpace.densify(colors: resolved,
                                                             locations: locs)
        // CAGradientLayer projects pixels onto the start→end axis in UNIT
        // space (verified vs golden/gradient_basic view 3: a (0,0)→(1,1)
        // gradient on a non-square layer follows the unit-space diagonal,
        // not the point-space one). Scale user space to the unit square so
        // Canvas's user-space projection becomes the unit-space one.
        canvas.save()
        canvas.translate(x: bounds.minX, y: bounds.minY)
        canvas.concatenate(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        canvas.drawLinearGradient(colors: dColors, locations: dLocs,
                                  start: startPoint, end: endPoint,
                                  in: CGRect(x: 0, y: 0, width: 1, height: 1))
        canvas.restore()
    }
}

/// CAGradientLayer's interpolation colorspace, empirically calibrated
/// against the oracle (see the header comment).
enum _CAGradientColorSpace {
    static let gamma: CGFloat = 1.7984

    /// sRGB-linear → interpolation-linear (rows sum to 1: white-preserving).
    static let m: [CGFloat] = [
         0.97700,  0.02596, -0.00296,
        -0.01939,  1.05166, -0.03227,
        -0.00056, -0.00362,  1.00418,
    ]
    /// Exact inverse of `m` (precomputed).
    static let mInv: [CGFloat] = [
         1.02352887, -0.02524798,  0.00220569,
         0.01885940,  0.95122951,  0.03062712,
         0.00063875,  0.00341518,  0.99590590,
    ]

    /// One color's interpolation-space representation (RGB; alpha is
    /// carried through linearly outside this conversion).
    static func encode(_ c: CGColor) -> (CGFloat, CGFloat, CGFloat) {
        let lr = srgbToLinear(c.red), lg = srgbToLinear(c.green), lb = srgbToLinear(c.blue)
        func row(_ i: Int) -> CGFloat {
            max(0, m[i] * lr + m[i + 1] * lg + m[i + 2] * lb)
        }
        let inv = 1 / gamma
        return (pow(row(0), inv), pow(row(3), inv), pow(row(6), inv))
    }

    static func decode(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, alpha: CGFloat) -> CGColor {
        let jr = pow(max(0, r), gamma), jg = pow(max(0, g), gamma), jb = pow(max(0, b), gamma)
        func row(_ i: Int) -> CGFloat {
            max(0, mInv[i] * jr + mInv[i + 1] * jg + mInv[i + 2] * jb)
        }
        return CGColor(red: linearToSRGB(row(0)), green: linearToSRGB(row(3)),
                       blue: linearToSRGB(row(6)), alpha: alpha)
    }

    /// Convert CA-space stops into a densified gamma-sRGB stop list that
    /// piecewise-linearly approximates CA's interpolation (for Canvas's
    /// sRGB-lerp gradient contract). 24 subdivisions per segment.
    static func densify(colors: [CGColor], locations: [CGFloat])
        -> ([CGColor], [CGFloat]) {
        let enc = colors.map { encode($0) }
        var outColors: [CGColor] = [colors[0]]
        var outLocs: [CGFloat] = [locations[0]]
        let sub = 24
        for i in 1..<colors.count {
            let (r0, g0, b0) = enc[i - 1], (r1, g1, b1) = enc[i]
            let a0 = colors[i - 1].alpha, a1 = colors[i].alpha
            let l0 = locations[i - 1], l1 = locations[i]
            if l1 <= l0 { continue }
            // Identical endpoints need no interior samples.
            let flat = r0 == r1 && g0 == g1 && b0 == b1 && a0 == a1
            if !flat {
                for k in 1..<sub {
                    let u = CGFloat(k) / CGFloat(sub)
                    outColors.append(decode(r0 + (r1 - r0) * u,
                                            g0 + (g1 - g0) * u,
                                            b0 + (b1 - b0) * u,
                                            alpha: a0 + (a1 - a0) * u))
                    outLocs.append(l0 + (l1 - l0) * u)
                }
            }
            outColors.append(colors[i])
            outLocs.append(l1)
        }
        return (outColors, outLocs)
    }

    // MARK: Pure-Swift transfer math (no Foundation)

    static func srgbToLinear(_ c: CGFloat) -> CGFloat {
        let v = min(max(c, 0), 1)
        return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    static func linearToSRGB(_ l: CGFloat) -> CGFloat {
        let v = min(max(l, 0), 1)
        return v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055
    }

    /// x^p for x in (0, 4), p in (0, 4) — ln/exp series (pure Swift, same
    /// construction as GlyphInkTable.powNorm but without the [0,1] clamp).
    static func pow(_ x: CGFloat, _ p: CGFloat) -> CGFloat {
        if x <= 0 { return 0 }
        if x == 1 { return 1 }
        var m = x
        var k = 0
        while m < 0.5 { m *= 2; k -= 1 }
        while m >= 1 { m /= 2; k += 1 }
        let z = (m - 1) / (m + 1)
        let z2 = z * z
        var term = z
        var lnsum: CGFloat = 0
        var n: CGFloat = 1
        for _ in 0..<12 { lnsum += term / n; term *= z2; n += 2 }
        let lnx = 2 * lnsum + CGFloat(k) * 0.6931471805599453
        let e = p * lnx
        let kk = (e * 1.4426950408889634).rounded()
        let r = e - kk * 0.6931471805599453
        var t: CGFloat = 1
        var s: CGFloat = 1
        for i in 1...14 { t *= r / CGFloat(i); s += t }
        var out = s
        var ki = Int(kk)
        while ki > 0 { out *= 2; ki -= 1 }
        while ki < 0 { out /= 2; ki += 1 }
        return out
    }
}
