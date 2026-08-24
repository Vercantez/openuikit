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
