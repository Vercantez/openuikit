// Data-driven system color table. Owner: color module.
//
// Resolves UIKit semantic color names ("label", "systemBlue", ...) to concrete
// sRGB values using Resources/system_colors.json — ground truth dumped from
// real UIKit by the oracle (`oracle colors`). Format:
//   { "light": { name: [r, g, b, a], ... }, "dark": { ... } }
//
// Pure Swift, no Foundation: loading goes through ResourceIO + MiniJSON.

public enum SystemColors {
    /// Magenta — returned for unknown names so failures are loudly visible.
    static let missing = CGColor(red: 1, green: 0, blue: 1, alpha: 1)

    struct Table {
        var light: [String: CGColor] = [:]
        var dark: [String: CGColor] = [:]
    }

    /// Parsed + cached color table. `static let` gives us lazy, thread-safe,
    /// once-only initialization.
    static let table: Table = loadTable()
    /// The iOS palette (Resources/system_colors_ios.json, resolved on the
    /// iPhone 16 / iOS 26.1 simulator by Tools/oracle2/colorprobe on
    /// 2026-09-04). system_colors.json is Mac Catalyst's, and 10 light + 13
    /// dark names differ: `label` is opaque black/white on iOS (0.847 alpha
    /// on Catalyst), dark `systemBackground` is #000000 (#1E1E1E), dark
    /// `secondarySystemBackground` #1C1C1E (#323232), light
    /// `secondarySystemBackground` #F2F2F7 (#ECECEC), the grey labels are
    /// (60,60,67)/(235,235,245) tints, `separator` (84,84,88)@0.5 in dark.
    /// Empty when the file is absent; the Catalyst table then serves both.
    static let tableIOS: Table = loadTable(resource: "system_colors_ios.json")

    private static func loadTable(resource: String = "system_colors.json") -> Table {
        var t = Table()
        guard let json = ResourceIO.loadJSONResource(resource),
              let root = json.objectValue else {
            return t
        }
        t.light = parseStyle(root["light"])
        t.dark = parseStyle(root["dark"])
        return t
    }

    private static func parseStyle(_ value: JSONValue?) -> [String: CGColor] {
        guard let obj = value?.objectValue else { return [:] }
        var out: [String: CGColor] = [:]
        out.reserveCapacity(obj.count)
        for (name, comps) in obj {
            guard let a = comps.arrayValue, a.count == 4,
                  let r = a[0].doubleValue, let g = a[1].doubleValue,
                  let b = a[2].doubleValue, let al = a[3].doubleValue else { continue }
            out[name] = CGColor(red: CGFloat(r), green: CGFloat(g),
                                blue: CGFloat(b), alpha: CGFloat(al))
        }
        return out
    }

    /// Resolve a semantic color name for the given traits.
    /// `.unspecified` resolves as light. Unknown names resolve to magenta.
    static func resolve(_ name: String, traits: UITraitCollection) -> CGColor {
        let t = (OpenUIKitRuntime.systemFontCut == .iOS && !tableIOS.light.isEmpty)
            ? tableIOS : table
        let styleTable: [String: CGColor]
        switch traits.userInterfaceStyle {
        case .dark: styleTable = t.dark
        case .light, .unspecified: styleTable = t.light
        }
        return styleTable[name] ?? missing
    }

    /// Whether the measured palette carries `name`. `UINib` asks before
    /// turning an archived `UISystemColorName` into a semantic `UIColor`,
    /// so an unknown name is reported instead of resolving to magenta.
    static func isKnown(_ name: String) -> Bool {
        let t = (OpenUIKitRuntime.systemFontCut == .iOS && !tableIOS.light.isEmpty)
            ? tableIOS : table
        return t.light[name] != nil || t.dark[name] != nil
    }
}
