// UILabel layout vs golden layout dumps — EXACT match required for every
// label scene (frame, intrinsicContentSize, sizeThatFits200).
import Foundation
import XCTest
@testable import OpenUIKit

@MainActor
final class LabelGoldenLayoutTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    static let labelScenes = [
        "label_basic", "label_sizes", "label_weights", "label_multiline",
        "label_truncate", "label_align", "label_mono_italic", "label_dark",
    ]

    func assertScene(_ name: String) throws {
        let scene = try TextTestSupport.loadJSON("fixtures/scenes/\(name).json")
        let golden = try TextTestSupport.loadJSON("golden/\(name).layout.json")
        let root = try XCTUnwrap(scene["root"] as? [String: Any])
        let subviews = (root["subviews"] as? [[String: Any]]) ?? []
        let goldViews = try XCTUnwrap(golden["views"] as? [[String: Any]])

        // The label scenes are flat: root + labels at paths "0", "1", ...
        for gold in goldViews {
            guard (gold["class"] as? String) == "UILabel",
                  let path = gold["path"] as? String, let index = Int(path) else { continue }
            let spec = subviews[index]
            XCTAssertEqual(spec["class"] as? String, "UILabel", "\(name) path \(path)")
            let label = TextTestSupport.makeLabel(spec)

            let goldFrame = try XCTUnwrap(gold["frame"] as? [Double])
            let frame = label.frame
            for (got, want) in zip([frame.origin.x, frame.origin.y,
                                    frame.width, frame.height], goldFrame) {
                XCTAssertEqual(got, want, accuracy: 0.001, "\(name) path \(path) frame")
            }
            if let goldIntrinsic = gold["intrinsic"] as? [Double] {
                let s = label.intrinsicContentSize
                XCTAssertEqual(s.width, goldIntrinsic[0], accuracy: 0.001,
                               "\(name) path \(path) intrinsic.width")
                XCTAssertEqual(s.height, goldIntrinsic[1], accuracy: 0.001,
                               "\(name) path \(path) intrinsic.height")
            }
            if let goldSTF = gold["sizeThatFits200"] as? [Double] {
                let s = label.sizeThatFits(CGSize(width: 200, height: .greatestFiniteMagnitude))
                XCTAssertEqual(s.width, goldSTF[0], accuracy: 0.001,
                               "\(name) path \(path) sizeThatFits200.width")
                XCTAssertEqual(s.height, goldSTF[1], accuracy: 0.001,
                               "\(name) path \(path) sizeThatFits200.height")
            }
        }
    }

    func testLabelBasic() throws { try assertScene("label_basic") }
    func testLabelSizes() throws { try assertScene("label_sizes") }
    func testLabelWeights() throws { try assertScene("label_weights") }
    func testLabelMultiline() throws { try assertScene("label_multiline") }
    func testLabelTruncate() throws { try assertScene("label_truncate") }
    func testLabelAlign() throws { try assertScene("label_align") }
    func testLabelMonoItalic() throws { try assertScene("label_mono_italic") }
    func testLabelDark() throws { try assertScene("label_dark") }

    // Attributed text (M12): the same exact-match rule over the attrtext_*
    // goldens — multi-run widths, per-line boxes with mixed fonts and
    // baseline offsets, paragraph line spacing, and the wrapped/capped
    // sizeThatFits200 measurements.
    func testAttrTextRuns() throws { try assertScene("attrtext_runs") }
    func testAttrTextParagraph() throws { try assertScene("attrtext_paragraph") }
    func testAttrTextKernBaseline() throws { try assertScene("attrtext_kern_baseline") }
    func testAttrTextUnderlineStrike() throws { try assertScene("attrtext_underline_strike") }
    func testAttrTextDark() throws { try assertScene("attrtext_dark") }
}
