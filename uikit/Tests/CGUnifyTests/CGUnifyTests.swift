// cg-unify: OpenUIKit's CoreGraphics types are CoreGraphics' own on Apple
// toolchains, and `import UIKit` re-exports CoreGraphics and ImageIO as
// Apple's does (docs/agent_reports/cg-unify.md).
//
// The scenario (Tools/oracle2/cgunifyprobe/scenario) is the same Swift the
// iOS 26.1 simulator ran against Apple's UIKit; its transcript is
// Tools/oracle2/cgunifyprobe/transcript-ios26.1.txt. Before cg-unify the
// fixture did not compile (`CGContext`, `CGImageSourceCreateWithData`,
// `UIColor(cgColor:)` unknown through `import UIKit`; CGColor had no
// `colorSpace`), so these tests failed at build time.
#if canImport(CoreGraphics)
import XCTest
import CoreGraphics
import UIKit
import OpenUIKitCGUnifyFixtures

final class CGUnifyTests: XCTestCase {
    private static var transcriptURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Tools/oracle2/cgunifyprobe/transcript-ios26.1.txt")
    }

    /// The oracle's lines for the named `## section`s, in order.
    private func oracle(sections: [String]) throws -> [String] {
        let text = try String(contentsOf: Self.transcriptURL, encoding: .utf8)
        var out: [String] = []
        var keep = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("## ") { keep = sections.contains(String(line.dropFirst(3))) }
            if keep, !line.isEmpty { out.append(line) }
        }
        return out
    }

    @MainActor
    func testTypesTranscriptMatchesIOS26_1() throws {
        let expected = try oracle(sections: ["color", "layer", "transform", "bitmap context", "imageio"])
        let actual = cgUnifyTypesTranscript()
        XCTAssertFalse(expected.isEmpty)
        for (index, pair) in zip(expected, actual).enumerated() where pair.0 != pair.1 {
            XCTFail("line \(index): expected \(pair.0)\n                 got \(pair.1)")
        }
        XCTAssertEqual(actual.count, expected.count)
    }

    /// The port's public names are CoreGraphics' own types, not look-alikes.
    func testPortNamesAreCoreGraphicsTypes() {
        XCTAssertTrue(OpenUIKit.CGColor.self == CoreGraphics.CGColor.self)
        XCTAssertTrue(OpenUIKit.CGColorSpace.self == CoreGraphics.CGColorSpace.self)
        XCTAssertTrue(OpenUIKit.CGAffineTransform.self == CoreGraphics.CGAffineTransform.self)
        XCTAssertTrue(OpenUIKit.CGImageAlphaInfo.self == CoreGraphics.CGImageAlphaInfo.self)
        XCTAssertTrue(OpenUIKit.CGLineCap.self == CoreGraphics.CGLineCap.self)
        XCTAssertTrue(OpenUIKit.CGLineJoin.self == CoreGraphics.CGLineJoin.self)
        XCTAssertTrue(OpenUIKit.CGBlendMode.self == CoreGraphics.CGBlendMode.self)
        let view = UIView()
        view.transform = CoreGraphics.CGAffineTransform(rotationAngle: 0.5)
        XCTAssertEqual(view.transform, CGAffineTransform(rotationAngle: 0.5))
    }

    /// The renderer's value colour round-trips every model the port produces.
    func testCanvasColorRoundTripKeepsModel() {
        let gray = CanvasColor(gray: 0.25, alpha: 0.5)
        XCTAssertEqual(CanvasColor(gray.cgColor), gray)
        XCTAssertTrue(CanvasColor(gray.cgColor).isGrayModel)
        let rgb = CanvasColor(red: 1.2, green: -0.1, blue: 0.5, alpha: 1)
        XCTAssertEqual(CanvasColor(rgb.cgColor), rgb)
        XCTAssertFalse(CanvasColor(rgb.cgColor).isGrayModel)
        // Another colour space goes through CoreGraphics' sRGB conversion.
        let p3 = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
                         components: [1, 0, 0, 1])!
        let converted = CanvasColor(p3)
        XCTAssertGreaterThan(converted.red, 1.0)
        XCTAssertLessThan(converted.green, 0)
    }
}
#endif
