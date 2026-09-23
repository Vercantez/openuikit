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
        let expected = try oracle(sections: ["color", "layer", "transform", "path", "bitmap context", "imageio"])
        let actual = cgUnifyTypesTranscript()
        XCTAssertFalse(expected.isEmpty)
        for (index, pair) in zip(expected, actual).enumerated() where pair.0 != pair.1 {
            XCTFail("line \(index): expected \(pair.0)\n                 got \(pair.1)")
        }
        XCTAssertEqual(actual.count, expected.count)
    }

    /// UIKit's current context is a CoreGraphics `CGContext` over the port's
    /// pixels: UIKit calls and CGContext calls interleave in order and share
    /// the CTM, clip and fill colour; `draw(_:)` gets one through
    /// `CALayer.render(in:)`; UIImage <-> CGImage round-trips (phase 2).
    /// Before phase 2 the scenario did not compile (`UIGraphicsGetCurrentContext()`
    /// returned `Canvas`, UIImage had no `cgImage`).
    @MainActor
    func testDrawingTranscriptMatchesIOS26_1() throws {
        let saved = CanvasBackendSelection.current
        defer { CanvasBackendSelection.current = saved }
        for backend in [RenderBackend.quartz, .swift] {
            CanvasBackendSelection.current = backend
            let expected = try oracle(sections: ["renderer context", "draw(_:)", "uiimage cgImage"])
            let actual = cgUnifyDrawingTranscript()
            XCTAssertFalse(expected.isEmpty)
            for (index, pair) in zip(expected, actual).enumerated() where pair.0 != pair.1 {
                XCTFail("\(backend) line \(index): expected \(pair.0)\n                 got \(pair.1)")
            }
            XCTAssertEqual(actual.count, expected.count, "\(backend)")
        }
    }

    /// A session whose code never asks for the CGContext keeps the port's
    /// exact pixels, and asking for it without drawing changes none.
    @MainActor
    func testUnusedCoreGraphicsContextLeavesPixelsUnchanged() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        func draw(_ askForContext: Bool) -> [UInt8] {
            UIGraphicsImageRenderer(size: CGSize(width: 9, height: 7), format: format).image { _ in
                if askForContext { _ = UIGraphicsGetCurrentContext() }
                UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 0.7).setFill()
                UIBezierPath(ovalIn: CGRect(x: 0.5, y: 0.25, width: 7.3, height: 5.9)).fill()
                UIColor.black.setStroke()
                UIBezierPath(roundedRect: CGRect(x: 1, y: 1, width: 6, height: 4), cornerRadius: 1.5).stroke()
            }.bitmap.pixels
        }
        XCTAssertEqual(draw(true), draw(false))
    }

    /// An app-made bitmap context: UIKit drawing and `render(in:)` land in
    /// the app's own memory, under its CTM.
    @MainActor
    func testUIKitDrawsIntoAppBitmapContext() throws {
        let ctx = try XCTUnwrap(CGContext(data: nil, width: 4, height: 2, bitsPerComponent: 8,
                                          bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        // UIKit coordinates: flip as UIGraphicsImageRenderer does.
        ctx.translateBy(x: 0, y: 2)
        ctx.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(ctx)
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        UIGraphicsPopContext()
        ctx.setFillColor(UIColor.blue.cgColor)
        ctx.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        view.backgroundColor = .green
        ctx.translateBy(x: 2, y: 1)
        view.layer.render(in: ctx)
        let image = try XCTUnwrap(ctx.makeImage())
        let px = cgUnifyPixels(image)
        XCTAssertEqual(cgUnifyRow(px, width: 4, y: 0), "255,0,0,255 0,0,255,255 0,0,0,0 0,0,0,0")
        XCTAssertEqual(cgUnifyRow(px, width: 4, y: 1), "0,0,0,0 0,0,0,0 0,255,0,255 0,0,0,0")
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
