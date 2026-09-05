// SymbolInkTable. Owner: image module.
//
// Vendored per-symbol coverage masks harvested from REAL iOS 26.1 the same
// way GlyphInkTable harvests text (Tools/oracle2/inkprobe): a UIImageView
// showing `UIImage(systemName:withConfiguration:)` at the tab bar's
// preferred configuration, `UIColor.label` over opaque white, coverage =
// 255 − gray. Vector stand-ins could not reproduce SF Symbol ink (Tabs
// t1000 calendar blob at [91.5, 597.5, 22.5, 21]; t2000 selected
// clock.fill at [264, 598.5, 19, 19] — docs/agent_reports/tabs-cells.md).
//
// MEASURED /tmp/symbolinkprobe, iPhone SE 2x and iPhone 16 3x / iOS 26.1:
//   - every tab UIImageView.preferredSymbolConfiguration dumps
//     "pointSize=18, weight=Medium, scale=Large"
//   - at that triple, SE 2x alignment boxes: calendar 29×25 (58×50 px,
//     CGImage 46×42 padded ox,oy=6,4); clock / clock.fill /
//     plus.circle.fill 27.5×27.5 (55×55 px, 47×47 at 4,4)
//   - iPhone 16 3x: calendar still 29×25 (87×75 px, 69×63 at 9,6);
//     clock 82/3 pt (82×82 px, 70×70 at 6,6)
//   - calendar.fill / gear.fill / magnifyingglass.fill are nil
//   - opaque label coverage is byte-identical in light and dark
//   - 2x: two phase masks (integer vs half device-pixel view origin);
//     tab-bar frames land on integer device pixels (calendar abs y 595.5
//     → 1191 px), so the F0 mask is the one the bar draws
//   - 3x: one mask per glyph (same as iOS text at 3x)
//
// Guarded by the iOS cut + that exact configuration. Catalyst keeps the
// procedural vectors (tabbar_basic uses solid bitmaps, not symbols).

public enum SymbolInkTable {
    private static var entries2x: [String: JSONValue]? = {
        guard let json = ResourceIO.loadJSONResource("symbol_ink_ios.json"),
              let e = json["entries"]?.objectValue else { return nil }
        return e
    }()
    private static var entries3x: [String: JSONValue]? = {
        guard let json = ResourceIO.loadJSONResource("symbol_ink_ios_3x.json"),
              let e = json["entries"]?.objectValue else { return nil }
        return e
    }()
    private static var cache: [String: (pw: Int, ph: Int, mask: GlyphInkMask)] = [:]

    /// Tab-bar configuration the table was harvested at.
    static func isTabBarConfiguration(_ configuration: UIImage.SymbolConfiguration?) -> Bool {
        guard let configuration else { return false }
        return configuration._pointSize == 18
            && configuration._weight == .medium
            && configuration._scale == .large
    }

    static func entries(scale: CGFloat) -> [String: JSONValue]? {
        if scale == 3 { return entries3x }
        if scale == 2 { return entries2x }
        return nil
    }

    /// True-coverage template (black RGB, alpha = harvested coverage)
    /// for `name` at the tab-bar configuration, or nil to keep the
    /// procedural stand-in.
    static func stampTemplate(name: String,
                              configuration: UIImage.SymbolConfiguration?,
                              scale: CGFloat) -> UIImage? {
        guard OpenUIKitRuntime.systemFontCut == .iOS,
              isTabBarConfiguration(configuration),
              let e = entries(scale: scale) else { return nil }
        let cacheKey = "\(Int(scale))|\(name)"
        let packed: (pw: Int, ph: Int, mask: GlyphInkMask)
        if let hit = cache[cacheKey] {
            packed = hit
        } else {
            guard let obj = e[name]?.objectValue,
                  let pw = obj["pw"]?.doubleValue, let ph = obj["ph"]?.doubleValue,
                  let w = obj["w"]?.doubleValue, let h = obj["h"]?.doubleValue,
                  let ox = obj["ox"]?.doubleValue, let oy = obj["oy"]?.doubleValue,
                  let hex = obj["m"]?.stringValue,
                  let bytes = GlyphInkTable.hexDecode(hex),
                  bytes.count == Int(w) * Int(h),
                  pw > 0, ph > 0 else { return nil }
            let mask = GlyphInkMask(width: Int(w), height: Int(h),
                                    ox: Int(ox), oy: Int(oy), mask: bytes)
            packed = (Int(pw), Int(ph), mask)
            cache[cacheKey] = packed
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
