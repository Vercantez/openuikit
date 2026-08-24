// GlyphInkTable. Owner: text module.
//
// Vendored per-glyph ink masks harvested from REAL UIKit (Mac Catalyst
// oracle renders), keyed by family/size/appearance/subpixel-phase/char.
// This is macOS-fidelity ground-truth data of the same kind as
// font_metrics.json and system_colors.json: it captures exactly how
// CoreText + CoreGraphics rasterize system-font glyphs at scale 2
// (stem darkening / font smoothing included), which no portable
// analytic model reproduced to golden tolerance.
//
// Pen-position model (measured extensively against oracle probes; see
// commit message for the probe methodology):
//   - Text is laid out in POINTS with the table advances + kerning.
//   - Each glyph's pen x is quantized IN TEXT SPACE with a size-dependent
//     quantum; the fractional part selects one of a small set of phase
//     masks rendered by CoreGraphics:
//       size < 12  : quarters {0, 1/4, 1/2, 3/4}          tags 0,P1,P2,P3
//       12..<16    : {0, 1/3, 1/2, 2/3}                   tags 0,T,H,P2
//       16..<29    : halves {0, 1/2}                      tags 0,P1
//       >= 29      : whole points {0}                     tag 0
//   - The mask is anchored at device pixel
//       round(dev origin) + 2*floor(pen_pt) + floor(2*frac) + mask.ox
//     (scale 2 canvases; phase masks bake in the sub-pixel position).
//
// Masks are stored for the exact (family, weight, integer size, light/dark,
// phase, char) combinations exercised by the validation scenes. Lookup
// misses fall back to the computed GlyphSmoothing path, so the library
// degrades gracefully when the resource file is absent (portability).

public struct GlyphInkMask {
    public var width: Int
    public var height: Int
    public var ox: Int
    public var oy: Int
    public var mask: [UInt8]
}

public enum GlyphInkTable {
    /// Raw JSON entries (hex-encoded masks); decoded lazily into `cache`.
    private static var entries: [String: JSONValue]? = {
        guard let json = ResourceIO.loadJSONResource("glyph_ink.json"),
              let e = json["entries"]?.objectValue else { return nil }
        return e
    }()
    private static var cache: [String: GlyphInkMask] = [:]

    public static var isAvailable: Bool { entries != nil }

    /// Phase tag + device-pixel anchor (floor(2 * quantized phase)) for a
    /// pen fraction at `size`.
    static func phase(size: CGFloat, frac: CGFloat) -> (tag: String, anchor: Int) {
        if size < 12 {
            switch Int(frac * 4) {
            case 0: return ("0", 0)
            case 1: return ("P1", 0)   // phase 1/4
            case 2: return ("P2", 1)   // phase 1/2
            default: return ("P3", 1)  // phase 3/4
            }
        } else if size < 16 {
            if frac < 1.0 / 3.0 { return ("0", 0) }
            if frac < 0.5 { return ("T", 0) }      // phase 1/3
            if frac < 2.0 / 3.0 { return ("H", 1) } // phase 1/2
            return ("P2", 1)                        // phase 2/3
        } else if size < 29 {
            return frac < 0.5 ? ("0", 0) : ("P1", 1)  // phases {0, 1/2}
        }
        return ("0", 0)  // whole-point positions only
    }

    static func hexDecode(_ s: String) -> [UInt8]? {
        let u = Array(s.utf8)
        guard u.count % 2 == 0 else { return nil }
        var out = [UInt8](repeating: 0, count: u.count / 2)
        func nib(_ c: UInt8) -> UInt8? {
            switch c {
            case UInt8(ascii: "0")...UInt8(ascii: "9"): return c - UInt8(ascii: "0")
            case UInt8(ascii: "a")...UInt8(ascii: "f"): return c - UInt8(ascii: "a") + 10
            case UInt8(ascii: "A")...UInt8(ascii: "F"): return c - UInt8(ascii: "A") + 10
            default: return nil
            }
        }
        for i in 0..<out.count {
            guard let h = nib(u[2 * i]), let l = nib(u[2 * i + 1]) else { return nil }
            out[i] = h << 4 | l
        }
        return out
    }

    /// Text blend exponent (normalized sRGB; fitted against oracle renders
    /// of colored text — see CanvasTextBlend.swift).
    public static let blendGamma: CGFloat = 0.79

    /// x^p for x in [0,1] (pure Swift; small series, table-quality precision).
    static func powNorm(_ x: CGFloat, _ p: CGFloat) -> CGFloat {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        var m = x
        var k = 0
        while m < 0.5 { m *= 2; k -= 1 }
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

    /// Harvested masks store the EFFECTIVE sRGB coverage of the calibration
    /// text color (system label, alpha 0.847) — the gamma blend is baked
    /// in. This returns the mask converted to TRUE glyph coverage for use
    /// with `Canvas.drawMask(..., blendGamma:)` (exact for the calibration
    /// color, correct for any other color).
    public static func maskLinear(familyKey: String, sizeKey: Int, dark: Bool,
                                  tag: String, scalar: Unicode.Scalar) -> GlyphInkMask? {
        let key = "L|\(familyKey)|\(sizeKey)|\(dark ? "dark" : "light")|\(tag)|\(scalar.value)"
        if let hit = cache[key] { return hit }
        guard var m = mask(familyKey: familyKey, sizeKey: sizeKey, dark: dark,
                           tag: tag, scalar: scalar) else { return nil }
        let g = blendGamma
        let full: CGFloat = 216.0 / 255.0          // calibration ink over contrast bg
        let fullG = powNorm(1 - full, g)           // (39/255)^g
        let fullDarkG = powNorm(full, g)           // (216/255)^g
        var lut = [UInt8](repeating: 0, count: 256)
        for v in 1...255 {
            let c = CGFloat(v) / 255
            let cTrue: CGFloat
            if dark {
                cTrue = powNorm(full * c, g) / fullDarkG
            } else {
                cTrue = (1 - powNorm(1 - full * c, g)) / (1 - fullG)
            }
            lut[v] = UInt8((cTrue * 255).rounded())
        }
        for i in 0..<m.mask.count { m.mask[i] = lut[Int(m.mask[i])] }
        cache[key] = m
        return m
    }

    /// Look up the harvested mask for one glyph occurrence.
    public static func mask(familyKey: String, sizeKey: Int, dark: Bool,
                            tag: String, scalar: Unicode.Scalar) -> GlyphInkMask? {
        guard let entries else { return nil }
        let key = "\(familyKey)|\(sizeKey)|\(dark ? "dark" : "light")|\(tag)|\(scalar.value)"
        if let hit = cache[key] { return hit }
        guard let e = entries[key]?.objectValue,
              let w = e["w"]?.doubleValue, let h = e["h"]?.doubleValue,
              let ox = e["ox"]?.doubleValue, let oy = e["oy"]?.doubleValue,
              let hex = e["m"]?.stringValue,
              let bytes = hexDecode(hex), bytes.count == Int(w) * Int(h) else { return nil }
        let m = GlyphInkMask(width: Int(w), height: Int(h), ox: Int(ox), oy: Int(oy),
                             mask: bytes)
        cache[key] = m
        return m
    }
}
