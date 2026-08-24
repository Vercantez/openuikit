// GlyphSmoothing. Owner: text module.
//
// CoreGraphics font-smoothing emulation, fitted against real Catalyst
// UIKit glyph renders (per size 10...34, all quarter-pixel phases):
// the smoothed glyph is a SHARP layer (plain 4x box-downsampled coverage,
// slightly attenuated) source-over a HALO layer (Gaussian-blurred coverage,
// sigma 1.0 device px, gained):
//
//     smoothed = a*sharp + g*halo - a*sharp*g*halo
//
// with a and g interpolated per point size. This reproduces the stepped
// edge ramps and stem darkening CG produces (a pure linear filter cannot).

enum GlyphSmoothing {
    /// Gaussian sigma for the halo layer, in 4x supersamples (1.0 device px).
    static let haloSigma: CGFloat = 4.0
    static let haloRadius = 10

    /// (pointSize, haloGain, sharpAlpha) — fitted per size, interpolated.
    static let params: [(size: CGFloat, gain: CGFloat, alpha: CGFloat)] = [
        (10, 0.45, 0.82), (12, 0.52, 0.83), (14, 0.55, 0.86), (17, 0.55, 0.875),
        (20, 0.60, 0.925), (24, 0.65, 0.95), (28, 0.65, 0.95), (34, 0.70, 0.95),
    ]

    static func gainAlpha(for size: CGFloat) -> (CGFloat, CGFloat) {
        let t = params
        if size <= t[0].size { return (t[0].gain, t[0].alpha) }
        if size >= t[t.count - 1].size {
            return (t[t.count - 1].gain, t[t.count - 1].alpha)
        }
        for i in 1..<t.count where t[i].size >= size {
            let a = t[i - 1], b = t[i]
            let f = (size - a.size) / (b.size - a.size)
            return (a.gain + (b.gain - a.gain) * f, a.alpha + (b.alpha - a.alpha) * f)
        }
        return (t[t.count - 1].gain, t[t.count - 1].alpha)
    }

    /// Normalized Gaussian taps for the halo blur (radius `haloRadius`).
    static let gaussTaps: [Float] = {
        var taps = [Float](repeating: 0, count: haloRadius * 2 + 1)
        var sum: Float = 0
        for i in -haloRadius...haloRadius {
            let x = Float(i)
            let s = Float(haloSigma)
            let v = Float(exponential(-Double(x * x) / Double(2 * s * s)))
            taps[i + haloRadius] = v
            sum += v
        }
        for i in 0..<taps.count { taps[i] /= sum }
        return taps
    }()

    /// exp() without Foundation (small-range Padé/series is plenty here).
    static func exponential(_ x: Double) -> Double {
        // x in [-12.5, 0] for our taps; use exp(x) = 2^k * exp(r)
        if x == 0 { return 1 }
        let k = (x * 1.4426950408889634).rounded()
        let r = x - k * 0.6931471805599453
        var term = 1.0
        var sum = 1.0
        for i in 1...12 {
            term *= r / Double(i)
            sum += term
        }
        var p = sum
        var n = Int(k)
        while n > 0 { p *= 2; n -= 1 }
        while n < 0 { p /= 2; n += 1 }
        return p
    }
}
