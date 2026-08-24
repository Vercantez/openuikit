import XCTest
@testable import OpenUIKit

private typealias CGRect = OpenUIKit.CGRect

final class LRunProbeTests: XCTestCase {
    func testLRunColumns() throws {
        guard GlyphFont(path: "/System/Library/Fonts/SFNS.ttf") != nil else {
            throw XCTSkip("no font")
        }
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 22))
        root.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 22))
        label.text = "llllllllllllllll"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        root.addSubview(label)
        root.layoutIfNeeded()
        let bmp = UIRenderer.render(root, scale: 2)
        var cols: [Int] = []
        for x in 0..<160 {
            var s = 0
            for y in 0..<bmp.height { s += 255 - Int(bmp.pixels[(y * bmp.width + x) * 4]) }
            cols.append(s)
        }
        print("ourcols:", cols)
    }
}

extension LRunProbeTests {
    func testLPhases() throws {
        guard let inst = GlyphRasterizer.font(for: .systemFont(ofSize: 17)) else {
            throw XCTSkip("no font")
        }
        let g = inst.glyphIndex(of: "l")
        for ph in 0..<4 {
            guard let bmp = inst.rasterizeSmoothed(glyph: g, devicePixelSize: 34, phaseX: ph) else { continue }
            var cols: [Int] = []
            for x in 0..<bmp.width {
                var s = 0
                for y in 0..<bmp.height { s += Int(bmp.mask[y * bmp.width + x]) }
                cols.append(s)
            }
            print("phase \(ph) offx \(bmp.offsetX):", cols)
        }
    }
}
