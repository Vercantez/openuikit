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

    private static func loadTable() -> Table {
        var t = Table()
        guard let json = ResourceIO.loadJSONResource("system_colors.json"),
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
        let styleTable: [String: CGColor]
        switch traits.userInterfaceStyle {
        case .dark: styleTable = table.dark
        case .light, .unspecified: styleTable = table.light
        }
        return styleTable[name] ?? missing
    }
}
