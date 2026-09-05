// Diagnostic (kept out of the gate): compare the port's pen positions under
// the iOS cut with CoreText's, from Tools/oracle2/textprobe output.
// Run: TEXT_POSITIONS=/tmp/textprobe/text_positions_ios.json swift test --filter TextPositionProbe
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class TextPositionProbeTests: XCTestCase {
    struct Glyph: Decodable { let char: String; let x: Double; let advance: Double }
    struct Case: Decodable { let text: String; let family: String; let size: Double; let glyphs: [Glyph]; let lineWidth: Double; let labelWidth: Double }
    struct File: Decodable { let cases: [Case] }

    func testReportPenDrift() throws {
        guard let path = ProcessInfo.processInfo.environment["TEXT_POSITIONS"] else { throw XCTSkip("no TEXT_POSITIONS") }
        let file = try JSONDecoder().decode(File.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        var worst: [(String, Double)] = []
        for c in file.cases {
            let weightName = String(c.family.split(separator: "-")[1])
            let weights: [String: UIFont.Weight] = ["regular": .regular, "semibold": .semibold, "bold": .bold, "medium": .medium]
            let font = UIFont.systemFont(ofSize: CGFloat(c.size), weight: weights[weightName] ?? .regular)
            var pen: CGFloat = 0
            var prev: Unicode.Scalar? = nil
            var maxDx = 0.0
            var line: [String] = []
            var i = 0
            for ch in c.text.unicodeScalars {
                if let p = prev { pen += FontEngine.kerning(p, ch, font: font) }
                prev = ch
                if i < c.glyphs.count {
                    let g = c.glyphs[i]
                    let dx = Double(pen) - g.x
                    maxDx = max(maxDx, abs(dx))
                    let adv = FontEngine.advance(of: ch, font: font)
                    if abs(dx) > 0.02 || abs(Double(adv) - g.advance) > 0.02 {
                        line.append("\(g.char)@\(String(format: "%.3f", g.x)) ours \(String(format: "%.3f", Double(pen))) adv iOS \(g.advance) ours \(String(format: "%.3f", Double(adv)))")
                    }
                }
                pen += FontEngine.advance(of: ch, font: font)
                i += 1
            }
            let ourWidth = Double(pen)
            worst.append(("\(c.family) \(c.size) \"\(c.text)\": maxDx \(String(format: "%.3f", maxDx)) width iOS \(c.lineWidth) ours \(String(format: "%.3f", ourWidth)) label \(c.labelWidth)", maxDx))
            if !line.isEmpty { print("  ", c.family, c.size, c.text, "->", line.prefix(6).joined(separator: " | ")) }
        }
        for (s, _) in worst.sorted(by: { $0.1 > $1.1 }).prefix(30) { print("DRIFT", s) }
    }
}
