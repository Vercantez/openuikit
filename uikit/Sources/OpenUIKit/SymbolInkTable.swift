// SymbolInkTable. Owner: image module.
//
// Vendored per-symbol coverage masks harvested from REAL iOS 26.1 the same
// way GlyphInkTable harvests text (Tools/oracle2/inkprobe /
// Tools/oracle2/symbolinkprobe): a UIImageView showing
// `UIImage(systemName:withConfiguration:)`, `UIColor.label` over opaque
// white, coverage = 255 − gray. Vector stand-ins could not reproduce SF
// Symbol ink (Tabs t1000 calendar blob at [91.5, 597.5, 22.5, 21] —
// docs/agent_reports/symbols-tabbar.md).
//
// MEASURED symbolinkprobe, iPhone SE 2x and iPhone 16 3x / iOS 26.1
// (`/tmp/symbolink-2x-symbols-harvest`, `/tmp/symbolink-3x-symbols-harvest`):
//   - unconfigured UIImage(systemName:) size calendar 21×17.5 at 2x
//     (42×35 px, CGImage 34×31 at ox,oy=4,2); byte-identical to
//     pointSize=17, weight=Regular, scale=Unspecified (73/73 names)
//   - tab-bar UIImageView.preferredSymbolConfiguration dumps
//     "pointSize=18, weight=Medium, scale=Large"; calendar 29×25
//     (58×50 px, 46×42 at 6,4) — byte-identical to the previous
//     tab-bar-only table
//   - nav-bar UIBarButtonItem UIImageView.preferred dumps
//     "textStyle=UICTFontTextStyleBody, weight=Medium, scale=Large";
//     body @ Large is 17 pt, and pointSize=17, weight=Medium, scale=Large
//     is byte-identical to that text-style configuration (73/73)
//   - 17 regular large (the brief's bar-button candidate) is a DISTINCT
//     mask: plus 45×43 vs 17 medium large 46×44
//   - 2x: two phase masks (integer vs half device-pixel view origin,
//     0 vs 0.25 pt); every 18/medium/large F0 vs F0.5 pair differed
//     (73/73). Tab-bar frames land on integer device pixels, so F0
//   - 3x: one mask per glyph (F0)
//   - opaque-label coverage is the stored channel (alignment-box crop)
//
// Keys: "name|pointSize|weight|scale|phase". Aliases (not stored):
//   default → 17|regular|unspecified
//   body|medium|large → 17|medium|large
// Guarded by the iOS cut. A harvested name at a harvested configuration
// whose key is missing from the resource fails loudly. Catalyst keeps
// the procedural vectors (tabbar_basic uses solid bitmaps).

public enum SymbolInkTable {
    private struct Table {
        var entries: [String: JSONValue]
        var names: Set<String>
        var configs: Set<String>
    }

    private static func loadTable(_ resource: String) -> Table? {
        guard let json = ResourceIO.loadJSONResource(resource),
              let e = json["entries"]?.objectValue else { return nil }
        var names = Set<String>()
        if let arr = json["names"]?.arrayValue {
            for v in arr {
                if let s = v.stringValue { names.insert(s) }
            }
        }
        var configs = Set<String>()
        if let arr = json["configurations"]?.arrayValue {
            for v in arr {
                if let key = v["key"]?.stringValue { configs.insert(key) }
            }
        }
        if configs.isEmpty {
            // MEASURED fallback if a truncated resource omits the list.
            configs = [
                "17|regular|unspecified",
                "17|regular|large",
                "17|medium|large",
                "18|medium|large",
            ]
        }
        return Table(entries: e, names: names, configs: configs)
    }

    private static var table2x: Table? = { loadTable("symbol_ink_ios.json") }()
    private static var table3x: Table? = { loadTable("symbol_ink_ios_3x.json") }()
    private static var cache: [String: (pw: Int, ph: Int, mask: GlyphInkMask)] = [:]

    /// Tab-bar configuration the first harvest measured.
    static func isTabBarConfiguration(_ configuration: UIImage.SymbolConfiguration?) -> Bool {
        guard let configuration else { return false }
        return configuration._pointSize == 18
            && configuration._weight == .medium
            && configuration._scale == .large
    }

    private static func table(scale: CGFloat) -> Table? {
        if scale == 3 { return table3x }
        if scale == 2 { return table2x }
        return nil
    }

    static func entries(scale: CGFloat) -> [String: JSONValue]? {
        table(scale: scale)?.entries
    }

    static func weightKey(_ weight: UIImage.SymbolWeight) -> String {
        switch weight {
        case .unspecified: return "unspecified"
        case .ultraLight: return "ultraLight"
        case .thin: return "thin"
        case .light: return "light"
        case .regular: return "regular"
        case .medium: return "medium"
        case .semibold: return "semibold"
        case .bold: return "bold"
        case .heavy: return "heavy"
        case .black: return "black"
        }
    }

    static func scaleKey(_ scale: UIImage.SymbolScale) -> String {
        switch scale {
        case .unspecified: return "unspecified"
        case .small: return "small"
        case .medium: return "medium"
        case .large: return "large"
        }
    }

    /// MEASURED: unconfigured UIImage(systemName:) == 17|regular|unspecified
    /// (73/73 names, symbolinkprobe SE 2x / iPhone 16 3x / iOS 26.1).
    static func configurationKey(_ configuration: UIImage.SymbolConfiguration?) -> String? {
        guard let configuration else { return "17|regular|unspecified" }
        let size = configuration._pointSize
        let rounded = size.rounded()
        guard size.isFinite, size > 0, abs(size - rounded) < 0.001 else { return nil }
        let pt = String(Int(rounded))
        return pt + "|" + weightKey(configuration._weight)
            + "|" + scaleKey(configuration._scale)
    }

    /// UIImage rasterization is at origin 0. Tab-bar frames land on integer
    /// device pixels (calendar abs y 595.5 → 1191 px at 2x), so F0.
    static func phaseKey(scale: CGFloat) -> String {
        _ = scale
        return "F0"
    }

    static func lookupKey(name: String,
                          configuration: UIImage.SymbolConfiguration?,
                          scale: CGFloat) -> String? {
        guard let cfg = configurationKey(configuration) else { return nil }
        return name + "|" + cfg + "|" + phaseKey(scale: scale)
    }

    /// True-coverage template (black RGB, alpha = harvested coverage)
    /// for `name` at a harvested configuration, or nil to keep the
    /// procedural stand-in / fail closed.
    ///
    /// A name that is in the harvest list at a harvested configuration
    /// whose key is missing from the resource fails loudly — a silent
    /// miss would stamp the wrong (procedural) silhouette.
    static func stampTemplate(name: String,
                              configuration: UIImage.SymbolConfiguration?,
                              scale: CGFloat) -> UIImage? {
        guard OpenUIKitRuntime.systemFontCut == .iOS,
              let table = table(scale: scale) else { return nil }
        guard let key = lookupKey(name: name, configuration: configuration,
                                   scale: scale) else { return nil }
        let cacheKey = String(Int(scale)) + "|" + key
        let packed: (pw: Int, ph: Int, mask: GlyphInkMask)
        if let hit = cache[cacheKey] {
            packed = hit
        } else if let obj = table.entries[key]?.objectValue,
                  let pw = obj["pw"]?.doubleValue, let ph = obj["ph"]?.doubleValue,
                  let w = obj["w"]?.doubleValue, let h = obj["h"]?.doubleValue,
                  let ox = obj["ox"]?.doubleValue, let oy = obj["oy"]?.doubleValue,
                  let hex = obj["m"]?.stringValue,
                  let bytes = GlyphInkTable.hexDecode(hex),
                  bytes.count == Int(w) * Int(h),
                  pw > 0, ph > 0 {
            let mask = GlyphInkMask(width: Int(w), height: Int(h),
                                    ox: Int(ox), oy: Int(oy), mask: bytes)
            packed = (Int(pw), Int(ph), mask)
            cache[cacheKey] = packed
        } else {
            if table.names.contains(name),
               let cfg = configurationKey(configuration),
               table.configs.contains(cfg) {
                preconditionFailure("SymbolInkTable missing key: " + key)
            }
            return nil
        }
        let bitmap = Bitmap(width: packed.pw, height: packed.ph)
        let mask = packed.mask
        var row = 0
        while row < mask.height {
            var col = 0
            while col < mask.width {
                let cov = mask.mask[row * mask.width + col]
                if cov > 0 {
                    let x = mask.ox + col
                    let y = mask.oy + row
                    if x >= 0, y >= 0, x < packed.pw, y < packed.ph {
                        let p = (y * packed.pw + x) * 4
                        bitmap.pixels[p + 3] = cov
                    }
                }
                col += 1
            }
            row += 1
        }
        return UIImage(bitmap: bitmap, scale: scale)
    }
}
