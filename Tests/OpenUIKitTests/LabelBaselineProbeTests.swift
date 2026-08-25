// Text-module diagnostic: where does a label's glyph ink land vertically?
import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGRect = OpenUIKit.CGRect

@MainActor
final class LabelBaselineProbeTests: XCTestCase {

    func testProbeBaseline() throws {
        guard GlyphFont(path: "/System/Library/Fonts/SFNS.ttf") != nil else {
            throw XCTSkip("system font unavailable")
        }
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        root.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 22))
        label.text = "HOHOxo"
        label.font = .systemFont(ofSize: 17)
        root.addSubview(label)
        root.layoutIfNeeded()
        let bmp = UIRenderer.render(root, scale: 2)
        // column 24 vertical profile (left stem of H)
        var prof: [Double] = []
        for y in 25..<60 {
            let px = bmp.pixels[(y * bmp.width + 24) * 4]
            prof.append(Double(px))
        }
        print("col24 rows25-59:", prof.map { Int($0) })
        let m = FontEngine.metrics(for: label.font)
        print("ascender", m.ascender, "lineHeight", m.lineHeight,
              "labelLineHeight", FontEngine.labelLineHeight(for: label.font))
    }
}
