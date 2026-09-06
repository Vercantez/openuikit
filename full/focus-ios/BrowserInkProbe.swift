// Ink census using the same runRealApp implementation as render_full. Only
// this diagnostic process enables missing-key logging; verification traps.
import Foundation
import OpenUIKit

func jsonText(_ v: JSONValue) -> String {
    switch v {
    case .null: return "null"
    case .bool(let b): return b ? "true" : "false"
    case .number(let d):
        // Integral values print without a fractional part, as JSONSerialization
        // does; anything else gets full precision so no layout digit is lost.
        if d == d.rounded(), abs(d) < 1e15 { return String(Int64(d)) }
        return String(d)
    case .string(let s):
        var out = "\""
        for c in s.unicodeScalars {
            switch c {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if c.value < 0x20 {
                    let hex = String(c.value, radix: 16)
                    out += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
                } else {
                    out.unicodeScalars.append(c)
                }
            }
        }
        return out + "\""
    case .array(let a): return "[" + a.map(jsonText).joined(separator: ",") + "]"
    case .object(let o):
        return "{" + o.keys.sorted().map { "\(jsonText(.string($0))):\(jsonText(o[$0]!))" }
            .joined(separator: ",") + "}"
    }
}

@main
struct BrowserInkProbe {
    @MainActor static func main() throws {
        let out = CommandLine.arguments[1]
        GlyphInkTable.logMisses = true
        let browser = realAppVariants.first { $0.name == "realapp_focus_browser_light" }!
        let result = runRealApp(browser, assets: FileManager.default.currentDirectoryPath + "/fixtures/realapp/assets")
        try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        for (name, bytes) in result.pngs {
            try Data(bytes).write(to: URL(fileURLWithPath: out + "/" + name))
        }
        try Data(jsonText(result.layout).utf8)
            .write(to: URL(fileURLWithPath: out + "/" + result.name + ".layout.json"))
        let keys = GlyphInkTable.missedKeys.sorted().joined(separator: "\n")
        try Data(keys.utf8).write(to: URL(fileURLWithPath: out + "/ink-misses.txt"))
        print("FOCUS_INK_CENSUS misses=\(GlyphInkTable.missedKeys.count)")
    }
}
