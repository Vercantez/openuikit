// ADDITIVE Canvas extension: gamma-space text blending. Owner: text module
// (new capability file; does not modify the frozen Canvas contract or the
// rasterizer — it only adds an overload, as the contract permits).
//
// Real UIKit composites glyph coverage against the destination in a
// power-law space (exponent ~0.79 on normalized sRGB bytes; fitted from
// Catalyst oracle renders of colored text). For a text foreground color
// C with alpha a over destination D, per channel:
//
//     F   = D + a * (C - D)              (sRGB pre-composite of the color)
//     out = (D^g + (F^g - D^g) * cov)^(1/g)
//
// where cov is the TRUE glyph coverage. For the calibration case
// (black/white label text) this reduces exactly to the plain sRGB lerp
// that `drawMask(_:width:height:atPixelX:pixelY:color:)` performs with
// pre-distorted coverage, but for saturated colors (link blue, tint
// colors) the channels diverge; this overload reproduces the real thing.

extension Canvas {
    /// Draw an 8-bit TRUE-coverage mask with gamma-space blending.
    /// `origin` in device pixels, like the plain drawMask.
    ///
    /// Where the destination is transparent there is nothing to blend
    /// against; the coverage then accumulates into the alpha channel using
    /// the sRGB-effective coverage of the appropriate polarity
    /// (`darkCalibration`: glyph calibrated against a black background),
    /// matching how real UIKit label layers store glyph ink.
    public func drawMask(_ mask: [UInt8], width: Int, height: Int,
                         atPixelX x: Int, pixelY y: Int, color: CGColor,
                         blendGamma gamma: CGFloat, darkCalibration: Bool = false) {
        _drawMaskGamma(mask, width, height, x, y, color, gamma, darkCalibration)
    }

    func _drawMaskGamma(_ mask: [UInt8], _ w: Int, _ h: Int, _ ox: Int, _ oy: Int,
                        _ color: CGColor, _ gamma: CGFloat, _ darkCal: Bool) {
        guard color.alpha > 0, w > 0, h > 0 else { return }
        let lut = _GammaLUT.shared(gamma: gamma)
        let bw = bitmap.width
        let clip = state.clipMask
        let my0 = Swift.max(0, -oy), my1 = Swift.min(h, bitmap.height - oy)
        let mx0 = Swift.max(0, -ox), mx1 = Swift.min(w, bw - ox)
        guard my0 < my1, mx0 < mx1 else { return }
        let ca = color.alpha
        let src = [color.red, color.green, color.blue]
        // Forward map: true coverage -> the sRGB-effective source alpha the
        // layer stores over transparent destinations. The contrast of the
        // map is the COLOR's alpha (verified against oracle renders of both
        // the 0.847-alpha label color and fully-opaque tint colors).
        let caG = lut.toGamma(1 - ca)      // (1-ca)^g, light polarity
        let caDarkG = lut.toGamma(ca)      // ca^g, dark polarity
        for my in my0..<my1 {
            let yy = oy + my
            let maskRow = my * w
            let rowBase = yy * bw
            for mx in mx0..<mx1 {
                let mv = mask[maskRow + mx]
                if mv == 0 { continue }
                let xx = ox + mx
                var cov = CGFloat(mv) / 255
                if let m = clip {
                    let cv = m[rowBase + xx]
                    if cv == 0 { continue }
                    cov *= CGFloat(cv) / 255
                }
                if cov <= 0 { continue }
                let o = (rowBase + xx) * 4
                let da = CGFloat(bitmap.pixels[o + 3]) / 255
                // sRGB-effective source alpha over transparent destinations.
                let aSrc: CGFloat
                if darkCal {
                    aSrc = lut.fromGamma(caDarkG * cov)
                } else {
                    aSrc = 1 - lut.fromGamma(1 - (1 - caG) * cov)
                }
                let outA = aSrc + da * (1 - aSrc)
                if outA <= 0 {
                    bitmap.pixels[o] = 0; bitmap.pixels[o + 1] = 0
                    bitmap.pixels[o + 2] = 0; bitmap.pixels[o + 3] = 0
                    continue
                }
                if da >= 1 {
                    // Opaque destination: pure per-channel gamma blend.
                    for ch in 0..<3 {
                        let d = CGFloat(bitmap.pixels[o + ch]) / 255
                        let f = d + ca * (src[ch] - d)
                        let outG = lut.toGamma(d) + (lut.toGamma(f) - lut.toGamma(d)) * cov
                        let v = lut.fromGamma(outG)
                        bitmap.pixels[o + ch] = UInt8((v * 255).rounded().clamped(0, 255))
                    }
                } else if da <= 0 {
                    // Transparent destination: ink accumulates as colored alpha.
                    for ch in 0..<3 {
                        bitmap.pixels[o + ch] = UInt8((src[ch] * 255).rounded().clamped(0, 255))
                    }
                } else {
                    // Mixed: blend of the two regimes weighted by dst alpha.
                    for ch in 0..<3 {
                        let d = CGFloat(bitmap.pixels[o + ch]) / 255
                        let f = d + ca * (src[ch] - d)
                        let outG = lut.toGamma(d) + (lut.toGamma(f) - lut.toGamma(d)) * cov
                        let blended = lut.fromGamma(outG)
                        let v = (blended * da + src[ch] * aSrc * (1 - da)) / outA
                        bitmap.pixels[o + ch] = UInt8((v * 255).rounded().clamped(0, 255))
                    }
                }
                bitmap.pixels[o + 3] = UInt8((outA * 255).rounded().clamped(0, 255))
            }
        }
    }
}

/// Power-law lookup tables for the text blend (built once per gamma).
final class _GammaLUT {
    let gamma: CGFloat
    /// x^gamma and x^(1/gamma) sampled on 1025 points over [0, 1].
    private var up: [CGFloat] = []
    private var down: [CGFloat] = []

    private static var cached: _GammaLUT?
    static func shared(gamma: CGFloat) -> _GammaLUT {
        if let c = cached, c.gamma == gamma { return c }
        let l = _GammaLUT(gamma: gamma)
        cached = l
        return l
    }

    init(gamma: CGFloat) {
        self.gamma = gamma
        up.reserveCapacity(1025)
        down.reserveCapacity(1025)
        for i in 0...1024 {
            let x = CGFloat(i) / 1024
            up.append(_GammaLUT.pow(x, gamma))
            down.append(_GammaLUT.pow(x, 1 / gamma))
        }
    }

    @inline(__always) private func sample(_ t: [CGFloat], _ x: CGFloat) -> CGFloat {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        let f = x * 1024
        let i = Int(f)
        let r = f - CGFloat(i)
        return t[i] + (t[i + 1] - t[i]) * r
    }
    @inline(__always) func toGamma(_ x: CGFloat) -> CGFloat { sample(up, x) }
    @inline(__always) func fromGamma(_ x: CGFloat) -> CGFloat { sample(down, x) }

    /// x^p for x in [0,1], p in (0,4): exp(p * ln x) with pure-Swift series.
    static func pow(_ x: CGFloat, _ p: CGFloat) -> CGFloat {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        return exp(p * ln(x))
    }
    static func ln(_ x0: CGFloat) -> CGFloat {
        // Normalize x = m * 2^k with m in [0.5, 1).
        var x = x0
        var k = 0
        while x < 0.5 { x *= 2; k -= 1 }
        while x >= 1 { x /= 2; k += 1 }
        let z = (x - 1) / (x + 1)  // in [-1/3, 0)
        let z2 = z * z
        var term = z
        var sum: CGFloat = 0
        var n: CGFloat = 1
        for _ in 0..<12 {
            sum += term / n
            term *= z2
            n += 2
        }
        return 2 * sum + CGFloat(k) * 0.6931471805599453
    }
    static func exp(_ x: CGFloat) -> CGFloat {
        let k = (x * 1.4426950408889634).rounded()
        let r = x - k * 0.6931471805599453
        var term: CGFloat = 1
        var sum: CGFloat = 1
        for i in 1...14 {
            term *= r / CGFloat(i)
            sum += term
        }
        var p = sum
        var n = Int(k)
        while n > 0 { p *= 2; n -= 1 }
        while n < 0 { p /= 2; n += 1 }
        return p
    }
}
