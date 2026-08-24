import XCTest
@testable import OpenUIKit

private typealias CGRect = OpenUIKit.CGRect

final class ScenePipelineProbeTests: XCTestCase {
    func testHRender() throws {
        guard GlyphFont(path: "/System/Library/Fonts/SFNS.ttf") != nil else {
            throw XCTSkip("no font")
        }
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        root.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 40, height: 20))
        label.text = "H"
        label.font = .systemFont(ofSize: 17)
        root.addSubview(label)
        root.layoutIfNeeded()
        let bmp = UIRenderer.render(root, scale: 2)
        // baseline should be dev y = 2*(10 + 0 + 16) = 52; stem row = 45
        for y in [40, 45] {
            var vals: [Int] = []
            for x in 18..<34 { vals.append(Int(bmp.pixels[(y * bmp.width + x) * 4])) }
            print("row\(y):", vals)
        }
    }
}
