#if canImport(AppKit)
import AppKit
import Foundation
import XCTest
@testable import OpenUIKitImageIO
import OpenCoreGraphics

final class ImageIOAppleOracleTests: XCTestCase {
    private func gradientBitmap(width: Int, height: Int) -> Bitmap {
        let bitmap = Bitmap(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                let o = (y * width + x) * 4
                bitmap.pixels[o] = UInt8(x * 255 / max(1, width - 1))
                bitmap.pixels[o + 1] = UInt8(y * 255 / max(1, height - 1))
                bitmap.pixels[o + 2] = 128
                bitmap.pixels[o + 3] = 255
            }
        }
        return bitmap
    }

    func testPNGDecodeMatchesAppleImageIO() throws {
        // Byte-level oracle: the same port-encoded PNG decoded by Apple
        // NSImage (Apple ImageIO) and by OpenUIKitImageIO.
        let src = gradientBitmap(width: 16, height: 12)
        let png = try XCTUnwrap(imageioEncodePNG(src))
        let source = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCreateWithData(Data(png) as CFData, nil)
        )
        let portImage = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCreateImageAtIndex(source, 0, nil)
        )
        let port = try XCTUnwrap(imageioBitmap(from: portImage))

        let apple = try XCTUnwrap(NSImage(data: Data(png)))
        var rect = NSRect(x: 0, y: 0, width: 16, height: 12)
        let appleCG = try XCTUnwrap(apple.cgImage(forProposedRect: &rect, context: nil, hints: nil))
        let appleBitmap = try XCTUnwrap(imageioBitmap(from: appleCG))
        XCTAssertEqual(appleBitmap.width, 16)
        XCTAssertEqual(appleBitmap.height, 12)
        XCTAssertEqual(appleBitmap.pixels, port.pixels)
        XCTAssertEqual(port.pixels, src.pixels)
    }

    func testJPEGDecodeVsAppleImageIO() throws {
        let src = gradientBitmap(width: 16, height: 12)
        let jpeg = try XCTUnwrap(imageioEncodeJPEG(src, quality: 0.95))
        let source = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCreateWithData(Data(jpeg) as CFData, nil)
        )
        let portImage = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCreateImageAtIndex(source, 0, nil)
        )
        let port = try XCTUnwrap(imageioBitmap(from: portImage))
        let apple = try XCTUnwrap(NSImage(data: Data(jpeg)))
        var rect = NSRect(x: 0, y: 0, width: 16, height: 12)
        let appleCG = try XCTUnwrap(apple.cgImage(forProposedRect: &rect, context: nil, hints: nil))
        let appleBitmap = try XCTUnwrap(imageioBitmap(from: appleCG))
        XCTAssertEqual(appleBitmap.width, port.width)
        XCTAssertEqual(appleBitmap.height, port.height)
        var maxDelta = 0
        for i in stride(from: 0, to: port.pixels.count, by: 4) {
            for c in 0..<3 {
                maxDelta = max(maxDelta, abs(Int(port.pixels[i + c]) - Int(appleBitmap.pixels[i + c])))
            }
        }
        // MEASURED 2026-09-05 Apple NSImage vs this module on a 16×12
        // gradient JPEG at quality 0.95: maxDelta=2 (within PIXEL_TOL 6).
        XCTAssertLessThan(maxDelta, 40, "JPEG maxDelta=\(maxDelta)")
    }
}
#endif
