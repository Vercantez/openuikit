// Tests for the fixture module (Tools/oracle + golden/): guard against the
// oracle dark-mode regression where `layer.render(in:)` on an unwindowed view
// hierarchy resolved dynamic colors with the LIGHT trait collection even for
// scenes with "style": "dark", producing light-mode goldens.
//
// The oracle now resolves every color eagerly against the scene's trait
// collection (see Tools/oracle/main.swift, colorOrDie). These tests verify the
// checked-in dark goldens actually contain dark-table colors, so a future
// golden regeneration with a broken oracle fails CI instead of silently
// shipping light-mode ground truth.
//
// Tests MAY use Foundation/Apple frameworks (only the library targets may not).

import Foundation
import XCTest

#if canImport(CoreGraphics) && canImport(ImageIO)
import CoreGraphics
import ImageIO

#if !os(Linux)
@MainActor
#endif
final class GoldenDarkModeTests: XCTestCase {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // OpenUIKitTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // repo root

    /// Decoded RGBA8 (non-premultiplied, sRGB) pixels.
    private struct RGBAImage {
        var width: Int
        var height: Int
        var pixels: [UInt8] // 4 bytes per pixel

        func at(_ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
            let o = (y * width + x) * 4
            return (Int(pixels[o]), Int(pixels[o + 1]), Int(pixels[o + 2]), Int(pixels[o + 3]))
        }
    }

    private func loadPNG(_ relativePath: String) throws -> RGBAImage {
        let url = Self.repoRoot.appendingPathComponent(relativePath)
        let data = try Data(contentsOf: url)
        let src = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil),
                                "cannot open \(relativePath)")
        let img = try XCTUnwrap(CGImageSourceCreateImageAtIndex(src, 0, nil))
        let w = img.width, h = img.height
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let ctx = try XCTUnwrap(CGContext(
            data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        // Un-premultiply.
        for i in stride(from: 0, to: buf.count, by: 4) {
            let a = Int(buf[i + 3])
            if a > 0 && a < 255 {
                for c in 0..<3 {
                    buf[i + c] = UInt8(min(255, (Int(buf[i + c]) * 255 + a / 2) / a))
                }
            }
        }
        return RGBAImage(width: w, height: h, pixels: buf)
    }

    private func loadColorTable(style: String) throws -> [String: [Int]] {
        let url = Self.repoRoot.appendingPathComponent("golden/system_colors.json")
        let obj = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let table = try XCTUnwrap(obj[style] as? [String: [Double]])
        return table.mapValues { $0.map { Int(($0 * 255).rounded()) } }
    }

    private func assertPixel(_ img: RGBAImage, x: Int, y: Int, equals want: [Int],
                             tolerance: Int, _ what: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        let got = img.at(x, y)
        let gotArr = [got.r, got.g, got.b, got.a]
        for (g, w) in zip(gotArr, want) where abs(g - w) > tolerance {
            XCTFail("\(what): pixel(\(x),\(y)) = \(gotArr), want \(want) ±\(tolerance)",
                    file: file, line: line)
            return
        }
    }

    /// golden/boxes_dark.png must contain the DARK system-color table values.
    /// Box layout (scene points → *2 px): secondarySystemBackground at
    /// (16,16,120,60), systemBlue at (16,92), systemFill at (152,16),
    /// systemGray4 at (152,92).
    func testBoxesDarkGoldenUsesDarkColors() throws {
        let img = try loadPNG("golden/boxes_dark.png")
        XCTAssertEqual(img.width, 640)
        XCTAssertEqual(img.height, 480)
        let dark = try loadColorTable(style: "dark")
        let light = try loadColorTable(style: "light")

        // Box centers in pixels (point * 2 + half box).
        let checks: [(String, Int, Int)] = [
            ("secondarySystemBackground", (16 + 60) * 2, (16 + 30) * 2),
            ("systemBlue", (16 + 60) * 2, (92 + 30) * 2),
            ("systemGray4", (152 + 60) * 2, (92 + 30) * 2),
        ]
        for (name, x, y) in checks {
            let want = try XCTUnwrap(dark[name])
            assertPixel(img, x: x, y: y, equals: want, tolerance: 2, "dark \(name)")
            // And explicitly NOT the light value (the historical bug).
            let lightVal = try XCTUnwrap(light[name])
            let got = img.at(x, y)
            XCTAssertFalse(
                abs(got.r - lightVal[0]) <= 2 && abs(got.g - lightVal[1]) <= 2
                    && abs(got.b - lightVal[2]) <= 2 && abs(got.a - lightVal[3]) <= 2,
                "dark golden for \(name) matches the LIGHT table — oracle dark-mode bug is back")
        }

        // systemFill: translucent over transparent root; alpha differs light(51)/dark(92).
        let fill = img.at((152 + 60) * 2, (16 + 30) * 2)
        let wantFill = try XCTUnwrap(dark["systemFill"])
        XCTAssertEqual(fill.a, wantFill[3], accuracy: 2, "dark systemFill alpha")
    }

    /// golden/label_dark.png: dark-mode label ink must be light (white-ish),
    /// never black (the light-mode `.label` color).
    func testLabelDarkGoldenInkIsLight() throws {
        let img = try loadPNG("golden/label_dark.png")
        var lightInk = 0, darkInk = 0
        for y in 0..<img.height {
            for x in 0..<img.width {
                let p = img.at(x, y)
                guard p.a >= 150 else { continue } // ignore AA fringe + transparent bg
                if p.r >= 200 && p.g >= 200 && p.b >= 200 { lightInk += 1 }
                if p.r <= 60 && p.g <= 60 && p.b <= 60 { darkInk += 1 }
            }
        }
        XCTAssertGreaterThan(lightInk, 500, "expected substantial white text ink in dark golden")
        XCTAssertEqual(darkInk, 0, "black ink found — golden was rendered with light-mode label color")
    }
}
#endif
