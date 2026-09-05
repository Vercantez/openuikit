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
// misses on the Catalyst cut fall back to the computed GlyphSmoothing path
// (needs an outline font). Under the iOS cut, a hit draws the harvested
// mask with no font file; a miss with no outline font fails with
// OPENUIKIT_IOS_INK_MISS and the exact key (Linux trial 2026-09-05: blank
// labels when SFNS was absent). OPENUIKIT_INK_LOG still records misses
// without aborting so a harvest run can collect keys.

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

    /// Window-server variant masks (glyph_ink_window.json): real UIKit
    /// rasterizes label text darker/crisper when the layer is composited by
    /// the render server (scenes captured via `drawHierarchy` in a real
    /// `UIWindow`, oracle2) than in offscreen `layer.render` captures.
    /// Harvested with the same probe methodology as `glyph_ink.json`, from
    /// the same scene files, rendered by oracle2 instead of oracle1.
    private static var windowEntries: [String: JSONValue]? = {
        guard let json = ResourceIO.loadJSONResource("glyph_ink_window.json"),
              let e = json["entries"]?.objectValue else { return nil }
        return e
    }()
    private static var cache: [String: GlyphInkMask] = [:]

    /// The iOS table (Resources/glyph_ink_ios.json): masks harvested from
    /// real iOS 26.1 on a 2x device (iPhone SE 3rd gen) by
    /// Tools/oracle2/inkprobe (SIM_DEVICE=2x scripts/ink_probe_sim.sh)
    /// through a real UILabel, calibration "opaque" — each mask IS
    /// the coverage of an opaque label colour (no gamma LUT), and oy is
    /// relative to round(2 * (top + (labelHeight - lineHeight) / 2 +
    /// ascender)), which UILabel's iOS path reproduces. Selected under the
    /// iOS font cut; absent, the Catalyst tables serve as before.
    ///
    /// 18 pt semibold (69 keys): MEASURED guest 4284aa2d
    /// `OPENUIKIT_IOS_INK_MISS: I|system-semibold|18|light|F0.0|83` after 12
    /// realapp PNGs. OPENUIKIT_INK_LOG of the 13 screens named those keys as
    /// SimpleActionView picker rows (`UIFont.font(ofSize: 18, weight:
    /// .semibold, scalingWith: .headline)` — "Select Episodes" S). Harvest
    /// `SIM_DEVICE=2x` `OpenUIKit-2x-guest-trial2` / iOS 26.1, 69/69,
    /// skipped []. Table 6152 → 6221. Second harvest of the remaining
    /// OPENUIKIT_INK_LOG `I|` keys from the 13-screen scale-2 run (372
    /// asked, 369 masks, 3 skipped U+00A0 "no ink") → **6590**.
    /// Ledger itself dumps 17/13 only; 13 pt bold R is picker
    /// `OptionsPickerRootController` "ROW ACTION".
    private static var iosEntries: [String: JSONValue]? = {
        guard let json = ResourceIO.loadJSONResource("glyph_ink_ios.json"),
              let e = json["entries"]?.objectValue else { return nil }
        return e
    }()
    public static var usesIOSTable: Bool {
        OpenUIKitRuntime.systemFontCut == .iOS && iosEntries != nil
    }
    /// The 3x table (Resources/glyph_ink_ios_3x.json), harvested on the
    /// iPhone 16 at its native scale (SIMCTL_CHILD_INK_SCALE=3). MEASURED
    /// 2026-09-04 (24-step pen sweeps through UILabel AND through
    /// CTLineDraw, 13/17/24 pt, regular/semibold/bold): on a 3x device the
    /// glyph origin snaps to the WHOLE device pixel — one mask per glyph,
    /// anchor floor(3 * phase) — where the 2x device keeps quarter-point
    /// phases below 17 pt. (Moving the LABEL's frame by fractions does show
    /// quarter-pixel phases, but Auto Layout pins label frames to the pixel
    /// grid under the iOS cut, so the pen rule is the one that renders.)
    private static var iosEntries3x: [String: JSONValue]? = {
        guard let json = ResourceIO.loadJSONResource("glyph_ink_ios_3x.json"),
              let e = json["entries"]?.objectValue else { return nil }
        return e
    }()
    static func iosEntries(scale: CGFloat) -> [String: JSONValue]? {
        if scale == 3 { return iosEntries3x }
        if scale == 2 { return iosEntries }
        return nil
    }
    /// True when the iOS cut is active and a table for `scale` is vendored.
    public static func hasIOSTable(scale: CGFloat) -> Bool {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return false }
        // A miss-logging run (OPENUIKIT_INK_LOG) needs the lookups to happen
        // even before a table for this scale exists, so the harvest learns
        // its keys.
        if logMisses && (scale == 2 || scale == 3) { return true }
        return iosEntries(scale: scale) != nil
    }
    /// iOS pen phases. MEASURED 2026-09-04 (inkprobe sweep on iOS 26.1):
    /// real iOS renders a DIFFERENT mask at every 1/8 pt of pen position —
    /// 8 distinct masks per glyph at 13, 17 and 24 pt alike — i.e. glyph
    /// origins are quantized to quarter device pixels at 2x, not to
    /// Catalyst's size-dependent {0, 1/4, 1/3, 1/2, 2/3, 3/4} sets. The tag
    /// is "F<k/8>" and the anchor floor(2 * phase), as the probe writes it.
    static func phaseIOS(size: CGFloat, frac: CGFloat, scale: CGFloat) -> (tag: String, anchor: Int) {
        if scale == 3 {
            // Whole device pixels at 3x (see iosEntries3x); the epsilon keeps
            // an exact third (3 * 0.3333.. = 0.9999..) on the pixel it lands on.
            return ("F0.0", Swift.min(2, Int((frac * 3 + 1e-6).rounded(.down))))
        }
        // MEASURED 2026-09-04 (inkprobe pen sweeps THROUGH UILABEL on the
        // iPhone SE 3rd gen, 2x, iOS 26.1 — the device the table is
        // harvested on): glyph origins snap to QUARTER points up to 16 pt
        // (4 masks per point at 10-16 pt, regular and bold) and to HALF
        // points from 17 pt (one mask per half point at 17-34 pt, regular
        // and semibold). Floor onto the grid; the anchor is floor(2 * phase).
        if size < 17 {
            let k = Int((frac * 4).rounded(.down)) & 3
            return ("F\(Double(k) / 4)", (2 * k) / 4)
        }
        return frac < 0.5 ? ("F0.0", 0) : ("F0.5", 1)
    }
    /// True-coverage mask from the iOS table (nil = not harvested).
    public static func maskIOS(familyKey: String, sizeKey: Int, dark: Bool,
                               tag: String, scalar: Unicode.Scalar,
                               scale: CGFloat) -> GlyphInkMask? {
        let key = iosMaskKey(familyKey: familyKey, sizeKey: sizeKey, dark: dark,
                             tag: tag, scalar: scalar, scale: scale)
        guard let e = iosEntries(scale: scale) else {
            if logMisses { missedKeys.insert(key) }
            return nil
        }
        let tableKey = "\(familyKey)|\(sizeKey)|\(dark ? "dark" : "light")|\(tag)|\(scalar.value)"
        if let m = decode(e[tableKey]?.objectValue, cacheKey: key) { return m }
        if logMisses { missedKeys.insert(key) }
        return nil
    }

    /// Key written by OPENUIKIT_IOS_INK_MISS / OPENUIKIT_INK_LOG for one
    /// iOS-cut glyph. Prefix `I|` is the 2x table, `I3|` the 3x table.
    /// MEASURED Linux trial 2026-09-05: without SFNS the previous path
    /// returned a blank label; this string is what to harvest.
    public static func iosMaskKey(familyKey: String, sizeKey: Int, dark: Bool,
                                  tag: String, scalar: Unicode.Scalar,
                                  scale: CGFloat) -> String {
        let prefix = scale == 3 ? "I3|" : "I|"
        return "\(prefix)\(familyKey)|\(sizeKey)|\(dark ? "dark" : "light")|\(tag)|\(scalar.value)"
    }

    /// Abort with the exact missing iOS ink key so a Linux agent knows what
    /// to harvest rather than shipping blank labels. Skipped when
    /// OPENUIKIT_INK_LOG is collecting keys (logMisses).
    public static func missingIOSInk(_ key: String) -> Never {
        fatalError("OPENUIKIT_IOS_INK_MISS: \(key) — no outline font; harvest this (family|size|appearance|phase|scalar) into Resources/glyph_ink_ios.json (2x, prefix I|) or glyph_ink_ios_3x.json (3x, prefix I3|)")
    }

    /// When true (host renders a window-server-composited hierarchy, e.g. a
    /// scene marked `"window": true`), glyph lookups prefer the window-
    /// variant masks and fall back to the offscreen table per glyph.
    public static var windowCompositing = false

    /// Harvest-coverage diagnostics: when enabled, every table lookup that
    /// misses is recorded ("W|<key>" window-table miss, "O|<key>" offscreen
    /// miss). openrender dumps this when OPENUIKIT_INK_LOG is set, so a
    /// harvest run knows exactly which (family,size,style,phase,char) cells
    /// the current scenes need.
    public static var logMisses = false
    public private(set) static var missedKeys: Set<String> = []

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
        let win = windowCompositing && windowEntries != nil
        let key = "\(win ? "WL" : "L")|\(familyKey)|\(sizeKey)|\(dark ? "dark" : "light")|\(tag)|\(scalar.value)"
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

    /// Look up the harvested mask for one glyph occurrence. When
    /// `windowCompositing` is set, the window-variant table is preferred and
    /// the offscreen table is the per-glyph fallback.
    public static func mask(familyKey: String, sizeKey: Int, dark: Bool,
                            tag: String, scalar: Unicode.Scalar) -> GlyphInkMask? {
        let key = "\(familyKey)|\(sizeKey)|\(dark ? "dark" : "light")|\(tag)|\(scalar.value)"
        if windowCompositing {
            if let w = windowEntries,
               let m = decode(w[key]?.objectValue, cacheKey: "W|" + key) {
                return m
            }
            if logMisses { missedKeys.insert("W|" + key) }
        }
        guard let entries,
              let m = decode(entries[key]?.objectValue, cacheKey: key) else {
            if logMisses { missedKeys.insert("O|" + key) }
            return nil
        }
        return m
    }

    private static func decode(_ e: [String: JSONValue]?, cacheKey: String) -> GlyphInkMask? {
        if let hit = cache[cacheKey] { return hit }
        guard let e,
              let w = e["w"]?.doubleValue, let h = e["h"]?.doubleValue,
              let ox = e["ox"]?.doubleValue, let oy = e["oy"]?.doubleValue,
              let hex = e["m"]?.stringValue,
              let bytes = hexDecode(hex), bytes.count == Int(w) * Int(h) else { return nil }
        let m = GlyphInkMask(width: Int(w), height: Int(h), ox: Int(ox), oy: Int(oy),
                             mask: bytes)
        cache[cacheKey] = m
        return m
    }
}
