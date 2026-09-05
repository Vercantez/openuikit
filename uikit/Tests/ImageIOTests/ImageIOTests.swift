import XCTest
import Foundation
#if os(Linux)
@testable import ImageIO
#else
@testable import OpenUIKitImageIO
#endif
import OpenCoreGraphics

#if os(Linux)
private func portCreateSource(_ data: Data) -> CGImageSource? {
    CGImageSourceCreateWithData(data as CFData, nil)
}
private func portSourceCount(_ source: CGImageSource) -> Int {
    CGImageSourceGetCount(source)
}
private func portSourceType(_ source: CGImageSource) -> String? {
    CGImageSourceGetType(source) as String?
}
private func portImageAt(_ source: CGImageSource, _ index: Int) -> CGImage? {
    CGImageSourceCreateImageAtIndex(source, index, nil)
}
private func portCreateDestination(
    _ data: NSMutableData,
    _ type: CFString,
    _ count: Int
) -> CGImageDestination? {
    CGImageDestinationCreateWithData(data as CFMutableData, type, count, nil)
}
#else
private func portCreateSource(_ data: Data) -> OpenUIKitImageIO.CGImageSource? {
    OpenUIKitImageIO.CGImageSourceCreateWithData(data as CFData, nil)
}
private func portSourceCount(_ source: OpenUIKitImageIO.CGImageSource) -> Int {
    OpenUIKitImageIO.CGImageSourceGetCount(source)
}
private func portSourceType(_ source: OpenUIKitImageIO.CGImageSource) -> String? {
    OpenUIKitImageIO.CGImageSourceGetType(source) as String?
}
private func portImageAt(_ source: OpenUIKitImageIO.CGImageSource, _ index: Int) -> CGImage? {
    OpenUIKitImageIO.CGImageSourceCreateImageAtIndex(source, index, nil)
}
private func portCreateDestination(
    _ data: NSMutableData,
    _ type: CFString,
    _ count: Int
) -> OpenUIKitImageIO.CGImageDestination? {
    OpenUIKitImageIO.CGImageDestinationCreateWithData(data as CFMutableData, type, count, nil)
}
#endif

final class ImageIOTests: XCTestCase {
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

    func testPNGRoundTripPixelsAreIdentical() throws {
        let src = gradientBitmap(width: 16, height: 12)
        let png = try XCTUnwrap(imageioEncodePNG(src))
        let source = try XCTUnwrap(portCreateSource(Data(png)))
        XCTAssertEqual(portSourceCount(source), 1)
        XCTAssertEqual(portSourceType(source), "public.png")
        let image = try XCTUnwrap(portImageAt(source, 0))
        let back = try XCTUnwrap(imageioBitmap(from: image))
        XCTAssertEqual(back.width, 16)
        XCTAssertEqual(back.height, 12)
        XCTAssertEqual(back.pixels, src.pixels)
    }

    func testJPEGDecodeMatchesPortEncoder() throws {
        let src = gradientBitmap(width: 16, height: 12)
        let jpeg = try XCTUnwrap(imageioEncodeJPEG(src, quality: 0.95))
        XCTAssertEqual(Array(jpeg.prefix(2)), [0xFF, 0xD8])
        let source = try XCTUnwrap(portCreateSource(Data(jpeg)))
        let image = try XCTUnwrap(portImageAt(source, 0))
        let back = try XCTUnwrap(imageioBitmap(from: image))
        XCTAssertEqual(back.width, 16)
        XCTAssertEqual(back.height, 12)
        var maxDelta = 0
        for i in stride(from: 0, to: back.pixels.count, by: 4) {
            for c in 0..<3 {
                maxDelta = max(maxDelta, abs(Int(back.pixels[i + c]) - Int(src.pixels[i + c])))
            }
            XCTAssertEqual(back.pixels[i + 3], 255)
        }
        XCTAssertLessThan(maxDelta, 24)
    }

    func testDestinationPNGFinalize() throws {
        let src = gradientBitmap(width: 8, height: 4)
        let png = try XCTUnwrap(imageioEncodePNG(src))
        let source = try XCTUnwrap(portCreateSource(Data(png)))
        let image = try XCTUnwrap(portImageAt(source, 0))
        let data = NSMutableData()
#if os(Linux)
        let dest = try XCTUnwrap(portCreateDestination(data, kUTTypePNG, 1))
#else
        let dest = try XCTUnwrap(portCreateDestination(data, OpenUIKitImageIO.kUTTypePNG, 1))
#endif
#if os(Linux)
        CGImageDestinationAddImage(dest, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(dest))
#else
        OpenUIKitImageIO.CGImageDestinationAddImage(dest, image, nil)
        XCTAssertTrue(OpenUIKitImageIO.CGImageDestinationFinalize(dest))
#endif
        XCTAssertGreaterThan(data.length, 8)
        let round = try XCTUnwrap(portCreateSource(data as Data))
        let backImage = try XCTUnwrap(portImageAt(round, 0))
        let back = try XCTUnwrap(imageioBitmap(from: backImage))
        XCTAssertEqual(back.pixels, src.pixels)
    }

    func testUnknownBytesFailClosed() {
        XCTAssertNil(portCreateSource(Data([0, 1, 2, 3, 4])))
    }
}
