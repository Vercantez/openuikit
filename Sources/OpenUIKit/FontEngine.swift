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
        // Not in the table: U+2026 gets the exact label-context advance;
        // other non-ASCII falls back to the font file's default instance.
        if scalar.value == 0x2026 {
            return ellipsisAdvance(for: font)
        }
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

    // MARK: - Truncation ("tight") metrics — system font, from SFNS.ttf
    //
    // When a label truncates, real UIKit lays the line out with the font's
    // TIGHT tracking (trak table track -1) instead of the standard label
    // tracking. Verified against Catalyst UILabel renders: the truncated
    // line's per-glyph advance is tableAdvance + dTight(size), spaces
    // included, and the ellipsis advance in label context is
    // ellipsisUnits(size) (raw advance at opsz(size) + label tracking).
    // Values are font units (upem 2048) per point size; generated offline
    // from SFNS.ttf (hmtx+HVAR+trak) against the vendored metrics table.

    static let tightTable: [(size: CGFloat, ellUnits: CGFloat, dTightUnits: CGFloat)] = [
        (8, 1750, -77.33), (9, 1736, -78), (10, 1722, -78), (11, 1706, -74),
        (11.5, 1699, -73), (12, 1692, -72), (13, 1677, -69), (13.5, 1672, -69),
        (14, 1666, -68), (15, 1654, -66), (16, 1645, -65), (17, 1633, -65),
        (17.5, 1618.1, -59.33), (18, 1603.19, -53.66), (19, 1572.38, -41.33),
        (20, 1498.96, -30), (21, 1446.53, -32), (22, 1394.11, -34),
        (23, 1345.69, -37), (24, 1297.27, -40), (25, 1282.45, -36.5),
        (26, 1268.63, -34), (27, 1253.82, -30.5), (28, 1240, -28),
        (29, 1239, -27.5), (30, 1239, -28), (31, 1238, -27.5), (32, 1238, -28),
        (33, 1236, -27.25), (34, 1235, -27.5), (35, 1234, -27.75),
        (36, 1233, -28), (37, 1232, -27.5), (38, 1232, -28), (39, 1231, -27.5),
        (40, 1231, -28),
    ]

    static func tightEntry(at size: CGFloat) -> (ell: CGFloat, dTight: CGFloat) {
        let t = tightTable
        if size <= t[0].size { return (t[0].ellUnits, t[0].dTightUnits) }
        if size >= t[t.count - 1].size {
            return (t[t.count - 1].ellUnits, t[t.count - 1].dTightUnits)
        }
        for i in 1..<t.count where t[i].size >= size {
            let a = t[i - 1], b = t[i]
            let f = (size - a.size) / (b.size - a.size)
            return (a.ellUnits + (b.ellUnits - a.ellUnits) * f,
                    a.dTightUnits + (b.dTightUnits - a.dTightUnits) * f)
        }
        return (t[t.count - 1].ellUnits, t[t.count - 1].dTightUnits)
    }

    static func unitsToPoints(_ u: CGFloat, size: CGFloat) -> CGFloat {
        u * size / 2048
    }

    /// Ellipsis (U+2026) advance in label context. Exact for the system
    /// design (from the tight table); falls back to the font file's default
    /// instance advance otherwise.
    public static func ellipsisAdvance(for font: UIFont) -> CGFloat {
        if font.design == .default {
            return unitsToPoints(tightEntry(at: font.pointSize).ell, size: font.pointSize)
        }
        if let gf = GlyphRasterizer.font(for: font) {
            return gf.advancePoints(of: Unicode.Scalar(0x2026)!, pointSize: font.pointSize)
        }
        return 0
    }

    /// Per-glyph advance adjustment for tight (truncated) lines.
    public static func tightDelta(for font: UIFont) -> CGFloat {
        guard font.design == .default else { return 0 }
        return unitsToPoints(tightEntry(at: font.pointSize).dTight, size: font.pointSize)
    }

    /// Ellipsis width used by the truncation DECISION (empirically smaller
    /// than the drawn advance; fitted against Catalyst threshold sweeps).
    public static func ellipsisDecisionWidth(for font: UIFont, head: Bool) -> CGFloat {
        guard font.design == .default else { return ellipsisAdvance(for: font) }
        let e = tightEntry(at: font.pointSize)
        let u = e.ell - (head ? 55 : 123.5)
        return unitsToPoints(u, size: font.pointSize)
    }

    /// Width of `text` at tight tracking (advances + kerning + dTight/char).
    public static func measureTight(_ text: String, font: UIFont) -> CGFloat {
        let d = tightDelta(for: font)
        var total: CGFloat = 0
        var prev: Unicode.Scalar? = nil
        for ch in text.unicodeScalars {
            if let p = prev { total += kerning(p, ch, font: font) }
            total += advance(of: ch, font: font) + d
            prev = ch
        }
        return total
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
