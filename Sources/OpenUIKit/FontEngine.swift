// FontEngine. Owner: text module.
//
// Data-driven font metrics + string measurement, matching real UIKit exactly.
// Ground truth: Resources/font_metrics.json (dumped by the oracle from real
// UIKit) and Resources/font_kerning.json (pair kerning derived from the same
// CoreText measurement that produced the golden stringWidths; see below).
//
// Kerning model
// -------------
// SF is a variable font with an optical-size axis. Empirically (validated
// against every stringWidths entry in the golden table, residual < 1.5e-6 pt):
//   kern_pt(pair, size) = size * (text_em + t(size) * (display_em - text_em))
// where text_em / display_em are the per-pair kerning values (in em units) of
// the Text (size <= 17) and Display (size >= 28) optical faces, and t(size)
// is a single blend curve shared by ALL pairs and weights (t=0 for <=17,
// t=1 for >=28, tabulated in the JSON for the sizes in between, linearly
// interpolated elsewhere). Mono fonts have no kerning.

public struct FontMetrics {
    public var ascender: CGFloat = 0
    public var descender: CGFloat = 0
    public var lineHeight: CGFloat = 0
    public var capHeight: CGFloat = 0
    public var xHeight: CGFloat = 0
    public var leading: CGFloat = 0
}

/// Owner: text module. Data-driven font engine: metrics + string measurement
/// from Resources/font_metrics.json; glyph rasterization via CSTBTrueType.
public enum FontEngine {

    // MARK: - Table storage

    struct Entry {
        var pointSize: CGFloat = 0
        var ascender: CGFloat = 0
        var descender: CGFloat = 0
        var lineHeight: CGFloat = 0
        var capHeight: CGFloat = 0
        var xHeight: CGFloat = 0
        var leading: CGFloat = 0
        /// Advance per printable ASCII char (index = ascii - 32); 95 entries.
        var advances: [CGFloat] = []
    }

    struct Tables {
        /// family key ("system-regular", "mono-bold", "italic-regular") →
        /// entries sorted by pointSize.
        var families: [String: [Entry]] = [:]
        /// family key → pair key ((a-32)*95+(b-32)) → (textEm, displayEm).
        var kerning: [String: [Int: (CGFloat, CGFloat)]] = [:]
        /// Optical blend curve t(size), sorted by size; implicit (17,0), (28,1).
        var tCurve: [(size: CGFloat, t: CGFloat)] = []
    }

    static let tables: Tables = loadTables()

    static func loadTables() -> Tables {
        var t = Tables()
        if let json = ResourceIO.loadJSONResource("font_metrics.json"),
           let fonts = json["fonts"]?.arrayValue {
            for f in fonts {
                guard let obj = f.objectValue,
                      let id = obj["id"]?.stringValue,
                      let size = obj["pointSize"]?.doubleValue else { continue }
                var e = Entry()
                e.pointSize = size
                e.ascender = obj["ascender"]?.doubleValue ?? 0
                e.descender = obj["descender"]?.doubleValue ?? 0
                e.lineHeight = obj["lineHeight"]?.doubleValue ?? 0
                e.capHeight = obj["capHeight"]?.doubleValue ?? 0
                e.xHeight = obj["xHeight"]?.doubleValue ?? 0
                e.leading = obj["leading"]?.doubleValue ?? 0
                e.advances = [CGFloat](repeating: 0, count: 95)
                if let adv = obj["advances"]?.objectValue {
                    for (k, v) in adv {
                        let u = Array(k.unicodeScalars)
                        guard u.count == 1, u[0].value >= 32, u[0].value <= 126,
                              let d = v.doubleValue else { continue }
                        e.advances[Int(u[0].value) - 32] = d
                    }
                }
                // id = "<family>-<weight>-<size>"; family key strips the size.
                if let dash = id.lastIndex(of: "-") {
                    let fam = String(id[id.startIndex..<dash])
                    t.families[fam, default: []].append(e)
                }
            }
            for k in t.families.keys {
                t.families[k]?.sort { $0.pointSize < $1.pointSize }
            }
        }
        if let json = ResourceIO.loadJSONResource("font_kerning.json") {
            if let tm = json["t"]?.objectValue {
                for (k, v) in tm {
                    if let s = Double(k), let tv = v.doubleValue {
                        t.tCurve.append((s, tv))
                    }
                }
                t.tCurve.sort { $0.size < $1.size }
            }
            if let fams = json["families"]?.objectValue {
                for (fam, pairsV) in fams {
                    guard let pairs = pairsV.objectValue else { continue }
                    var m: [Int: (CGFloat, CGFloat)] = [:]
                    m.reserveCapacity(pairs.count)
                    for (pk, pv) in pairs {
                        let u = Array(pk.unicodeScalars)
                        guard u.count == 2,
                              u[0].value >= 32, u[0].value <= 126,
                              u[1].value >= 32, u[1].value <= 126,
                              let arr = pv.arrayValue, arr.count == 2,
                              let a = arr[0].doubleValue, let b = arr[1].doubleValue else { continue }
                        let key = (Int(u[0].value) - 32) * 95 + (Int(u[1].value) - 32)
                        m[key] = (a / 1e6, b / 1e6)
                    }
                    t.kerning[fam] = m
                }
            }
        }
        return t
    }

    // MARK: - Lookup

    static func familyKey(for font: UIFont) -> String {
        switch font.design {
        case .monospaced:
            // The table only carries mono-regular and mono-bold.
            switch font.weight {
            case .semibold, .bold, .heavy, .black: return "mono-bold"
            default: return "mono-regular"
            }
        case .italic:
            return "italic-regular"
        case .default:
            return "system-" + font.weight.name
        }
    }

    /// Exact entry for sizes present in the table; otherwise the two adjacent
    /// integer-size entries with a linear interpolation factor.
    /// SF switches optical family with size, so only neighbor entries are
    /// blended — the switch stays sharp.
    static func neighbors(for font: UIFont) -> (Entry, Entry, CGFloat)? {
        guard let list = tables.families[familyKey(for: font)], !list.isEmpty else { return nil }
        let s = font.pointSize
        // Exact match (also covers the fractional sizes vendored in the table).
        if let e = list.first(where: { abs($0.pointSize - s) < 1e-9 }) { return (e, e, 0) }
        // Adjacent integer entries.
        let lo = (s.rounded(.down))
        let hi = (s.rounded(.up))
        let le = list.last(where: { abs($0.pointSize - lo) < 1e-9 && $0.pointSize.rounded() == $0.pointSize })
        let he = list.first(where: { abs($0.pointSize - hi) < 1e-9 && $0.pointSize.rounded() == $0.pointSize })
        if let le, let he {
            return (le, he, hi > lo ? (s - lo) / (hi - lo) : 0)
        }
        // Out of table range: scale the nearest entry proportionally (metrics
        // are linear in size within a face).
        let nearest = s < list[0].pointSize ? list[0] : list[list.count - 1]
        var e = nearest
        let f = s / nearest.pointSize
        e.pointSize = s
        e.ascender *= f; e.descender *= f; e.lineHeight *= f
        e.capHeight *= f; e.xHeight *= f; e.leading *= f
        e.advances = nearest.advances.map { $0 * f }
        return (e, e, 0)
    }

    public static func metrics(for font: UIFont) -> FontMetrics {
        guard let (a, b, f) = neighbors(for: font) else {
            // Fallback approximation if the table is unavailable.
            return FontMetrics(ascender: font.pointSize * 0.966796875,
                               descender: -font.pointSize * 0.2109375,
                               lineHeight: (font.pointSize * 1.177734375).rounded(),
                               capHeight: font.pointSize * 0.7046,
                               xHeight: font.pointSize * 0.5264,
                               leading: 0)
        }
        func lerp(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * f }
        return FontMetrics(ascender: lerp(a.ascender, b.ascender),
                           descender: lerp(a.descender, b.descender),
                           lineHeight: lerp(a.lineHeight, b.lineHeight),
                           capHeight: lerp(a.capHeight, b.capHeight),
                           xHeight: lerp(a.xHeight, b.xHeight),
                           leading: lerp(a.leading, b.leading))
    }

    // MARK: - Measurement

    /// Advance of a single character (kerning-free), interpolated like metrics.
    public static func advance(of scalar: Unicode.Scalar, font: UIFont) -> CGFloat {
        if scalar.value >= 32, scalar.value <= 126, let (a, b, f) = neighbors(for: font) {
            let i = Int(scalar.value) - 32
            return a.advances[i] + (b.advances[i] - a.advances[i]) * f
        }
        // Not in the table (non-ASCII, e.g. U+2026 ellipsis): fall back to the
        // glyph rasterizer's em-mapped advance when a font file is available.
        if let gf = GlyphRasterizer.font(for: font) {
            return gf.advancePoints(of: scalar, pointSize: font.pointSize)
        }
        return 0
    }

    /// Optical blend factor for kerning at `size` (0 = Text face, 1 = Display).
    static func opticalBlend(at size: CGFloat) -> CGFloat {
        if size <= 17 { return 0 }
        if size >= 28 { return 1 }
        var prev: (size: CGFloat, t: CGFloat) = (17, 0)
        for p in tables.tCurve {
            if abs(p.size - size) < 1e-9 { return p.t }
            if p.size > size {
                return prev.t + (p.t - prev.t) * (size - prev.size) / (p.size - prev.size)
            }
            prev = p
        }
        return prev.t + (1 - prev.t) * (size - prev.size) / (28 - prev.size)
    }

    /// Pair kerning in points for `a` followed by `b`.
    public static func kerning(_ a: Unicode.Scalar, _ b: Unicode.Scalar, font: UIFont) -> CGFloat {
        guard a.value >= 32, a.value <= 126, b.value >= 32, b.value <= 126,
              let pairs = tables.kerning[familyKey(for: font)] else { return 0 }
        let key = (Int(a.value) - 32) * 95 + (Int(b.value) - 32)
        guard let (te, de) = pairs[key] else { return 0 }
        return font.pointSize * (te + opticalBlend(at: font.pointSize) * (de - te))
    }

    /// Width of a single-line string in points (advances + pair kerning),
    /// matching real UIKit's measurement of the same string.
    public static func measure(_ text: String, font: UIFont) -> CGFloat {
        var total: CGFloat = 0
        var prev: Unicode.Scalar? = nil
        for ch in text.unicodeScalars {
            if let p = prev { total += kerning(p, ch, font: font) }
            total += advance(of: ch, font: font)
            prev = ch
        }
        return total
    }

    // MARK: - Label line height

    /// Height real UIKit gives one line of a UILabel. Verified against the
    /// oracle for every size 8...40 (plus fractional sizes): it is the
    /// UIFont lineHeight, plus one extra point for sizes in three bands —
    /// [10,12), [15,17), [19,22) — where the optical face's layout line
    /// height exceeds the rounded UIFont value. Identical for all weights,
    /// mono and italic.
    public static func labelLineHeight(for font: UIFont) -> CGFloat {
        let lh = metrics(for: font).lineHeight
        let s = font.pointSize
        let bonus: CGFloat =
            ((s >= 10 && s < 12) || (s >= 15 && s < 17) || (s >= 19 && s < 22)) ? 1 : 0
        return lh + bonus
    }

    // MARK: - Pixel rounding helpers

    /// Ceil to the device pixel grid (1/scale points), with an epsilon so
    /// values that are exactly on the grid do not get bumped up.
    public static func ceilToPixel(_ v: CGFloat, scale: CGFloat) -> CGFloat {
        (v * scale - 1e-6).rounded(.up) / scale
    }

    /// Round to the device pixel grid (half rounds up, like UIKit).
    public static func roundToPixel(_ v: CGFloat, scale: CGFloat) -> CGFloat {
        (v * scale).rounded(.toNearestOrAwayFromZero) / scale
    }
}
