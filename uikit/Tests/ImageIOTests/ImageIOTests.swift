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

    func testUnknownBytesReturnInvalidSource() {
        // MEASURED 2026-09-05 Apple ImageIO: garbage still returns a source.
        let source = portCreateSource(Data([0, 1, 2, 3, 4]))
        XCTAssertNotNil(source)
        guard let source else { return }
#if os(Linux)
        XCTAssertEqual(CGImageSourceGetStatus(source), .statusInvalidData)
        XCTAssertNil(CGImageSourceGetType(source))
        XCTAssertEqual(CGImageSourceGetCount(source), 0)
#else
        XCTAssertEqual(OpenUIKitImageIO.CGImageSourceGetStatus(source), .statusInvalidData)
        XCTAssertNil(OpenUIKitImageIO.CGImageSourceGetType(source))
        XCTAssertEqual(OpenUIKitImageIO.CGImageSourceGetCount(source), 0)
#endif
    }

    func testIncrementalPNGStatus() throws {
        let src = gradientBitmap(width: 8, height: 4)
        let png = try XCTUnwrap(imageioEncodePNG(src))
#if os(Linux)
        let source = CGImageSourceCreateIncremental(nil)
        XCTAssertEqual(CGImageSourceGetStatus(source), .statusInvalidData)
        CGImageSourceUpdateData(source, Data(png.prefix(16)) as CFData, false)
        XCTAssertEqual(CGImageSourceGetType(source) as String?, "public.png")
        XCTAssertEqual(CGImageSourceGetStatus(source), .statusIncomplete)
        CGImageSourceUpdateData(source, Data(png) as CFData, true)
        XCTAssertEqual(CGImageSourceGetStatus(source), .statusComplete)
        XCTAssertNotNil(CGImageSourceCreateImageAtIndex(source, 0, nil))
#else
        let source = OpenUIKitImageIO.CGImageSourceCreateIncremental(nil)
        XCTAssertEqual(OpenUIKitImageIO.CGImageSourceGetStatus(source), .statusInvalidData)
        OpenUIKitImageIO.CGImageSourceUpdateData(source, Data(png.prefix(16)) as CFData, false)
        XCTAssertEqual(OpenUIKitImageIO.CGImageSourceGetType(source) as String?, "public.png")
        XCTAssertEqual(OpenUIKitImageIO.CGImageSourceGetStatus(source), .statusIncomplete)
        OpenUIKitImageIO.CGImageSourceUpdateData(source, Data(png) as CFData, true)
        XCTAssertEqual(OpenUIKitImageIO.CGImageSourceGetStatus(source), .statusComplete)
        XCTAssertNotNil(OpenUIKitImageIO.CGImageSourceCreateImageAtIndex(source, 0, nil))
#endif
    }

    func testPNGChunkProperties() throws {
        // MEASURED 2026-09-05 Apple ImageIO on this 2×1 RGB PNG
        // (IHDR, pHYs 5669 ppm, gAMA 45455, tEXt Title=Hello):
        // DPI 144, Gamma 0.45455, {PNG}.Title and {IPTC}.ObjectName = Hello.
        let png = Data(imageioProbePNGChunks)
        let source = try XCTUnwrap(portCreateSource(png))
        XCTAssertEqual(portSourceType(source), "public.png")
#if os(Linux)
        let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?)
#else
        let props = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
        )
#endif
        XCTAssertEqual((props["PixelWidth"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((props["PixelHeight"] as? NSNumber)?.intValue, 1)
        XCTAssertEqual((props["DPIWidth"] as? NSNumber)?.doubleValue, 144)
        let pngDict = try XCTUnwrap(props["{PNG}"] as? NSDictionary)
        XCTAssertEqual(pngDict["Title"] as? String, "Hello")
        XCTAssertEqual(
            (pngDict["Gamma"] as? NSNumber)?.doubleValue ?? -1,
            0.45455,
            accuracy: 0.00001
        )
        XCTAssertEqual((pngDict["XPixelsPerMeter"] as? NSNumber)?.intValue, 5669)
        let iptc = try XCTUnwrap(props["{IPTC}"] as? NSDictionary)
        XCTAssertEqual(iptc["ObjectName"] as? String, "Hello")
    }

    func testThumbnailMaxPixelRounding() throws {
        // MEASURED 2026-09-05: 16×12 maxPixel 8 → 8×6 (half-to-even, no upscale).
        let src = gradientBitmap(width: 16, height: 12)
        let png = try XCTUnwrap(imageioEncodePNG(src))
        let source = try XCTUnwrap(portCreateSource(Data(png)))
        let options: [String: Any] = [
            "kCGImageSourceCreateThumbnailFromImageAlways": true,
            "kCGImageSourceThumbnailMaxPixelSize": 8,
        ]
#if os(Linux)
        let thumb = try XCTUnwrap(
            CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        )
#else
        let thumb = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCreateThumbnailAtIndex(
                source, 0, options as CFDictionary
            )
        )
#endif
        XCTAssertEqual(thumb.width, 8)
        XCTAssertEqual(thumb.height, 6)
    }

    func testGIFLoopCountFromNetscape() throws {
        // MEASURED 2026-09-05: NETSCAPE loop field 3 → LoopCount 4.
        let gif: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
            0x21, 0xFF, 0x0B,
            0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
            0x03, 0x01, 0x03, 0x00, 0x00,
            0x3B,
        ]
        let source = try XCTUnwrap(portCreateSource(Data(gif)))
        XCTAssertEqual(portSourceType(source), "com.compuserve.gif")
#if os(Linux)
        let props = try XCTUnwrap(CGImageSourceCopyProperties(source, nil) as NSDictionary?)
#else
        let props = try XCTUnwrap(
            OpenUIKitImageIO.CGImageSourceCopyProperties(source, nil) as NSDictionary?
        )
#endif
        let gifDict = try XCTUnwrap(props["{GIF}"] as? NSDictionary)
        XCTAssertEqual((gifDict["LoopCount"] as? NSNumber)?.intValue, 4)
    }

    func testXMPRoundtrip() throws {
#if os(Linux)
        let metadata = CGImageMetadataCreateMutable()
        XCTAssertTrue(
            CGImageMetadataSetValueWithPath(metadata, nil, "exif:UserComment" as CFString, "hello")
        )
        let xmp = try XCTUnwrap(CGImageMetadataCreateXMPData(metadata, nil) as Data?)
        let parsed = try XCTUnwrap(CGImageMetadataCreateFromXMPData(xmp as CFData))
        XCTAssertEqual(
            CGImageMetadataCopyStringValueWithPath(parsed, nil, "exif:UserComment" as CFString)
                as String?,
            "hello"
        )
#else
        let metadata = OpenUIKitImageIO.CGImageMetadataCreateMutable()
        XCTAssertTrue(
            OpenUIKitImageIO.CGImageMetadataSetValueWithPath(
                metadata, nil, "exif:UserComment" as CFString, "hello"
            )
        )
        let xmp = try XCTUnwrap(
            OpenUIKitImageIO.CGImageMetadataCreateXMPData(metadata, nil) as Data?
        )
        let parsed = try XCTUnwrap(
            OpenUIKitImageIO.CGImageMetadataCreateFromXMPData(xmp as CFData)
        )
        XCTAssertEqual(
            OpenUIKitImageIO.CGImageMetadataCopyStringValueWithPath(
                parsed, nil, "exif:UserComment" as CFString
            ) as String?,
            "hello"
        )
#endif
    }

    func testCopyTypeIdentifiers() {
#if os(Linux)
        let source = CGImageSourceCopyTypeIdentifiers() as? [Any]
        let dest = CGImageDestinationCopyTypeIdentifiers() as? [Any]
#else
        let source = OpenUIKitImageIO.CGImageSourceCopyTypeIdentifiers() as? [Any]
        let dest = OpenUIKitImageIO.CGImageDestinationCopyTypeIdentifiers() as? [Any]
#endif
        let sourceStrings = source?.map { String(describing: $0) } ?? []
        let destStrings = dest?.map { String(describing: $0) } ?? []
        XCTAssertTrue(sourceStrings.contains("public.png"))
        XCTAssertTrue(sourceStrings.contains("public.jpeg"))
        XCTAssertTrue(sourceStrings.contains("com.compuserve.gif"))
        XCTAssertTrue(destStrings.contains("public.png"))
        XCTAssertTrue(destStrings.contains("public.jpeg"))
    }

    func testPropertyKeyPayloads() {
#if os(Linux)
        XCTAssertEqual(kCGImagePropertyPixelWidth as String, "PixelWidth")
        XCTAssertEqual(kCGImagePropertyPNGDictionary as String, "{PNG}")
        XCTAssertEqual(kCGImagePropertyExifDictionary as String, "{Exif}")
        XCTAssertEqual(kCGImagePropertyGPSDictionary as String, "{GPS}")
        XCTAssertEqual(kCGImageSourceShouldCache as String, "kCGImageSourceShouldCache")
        XCTAssertEqual(
            kCGImageSourceThumbnailMaxPixelSize as String,
            "kCGImageSourceThumbnailMaxPixelSize"
        )
        XCTAssertEqual(kUTTypePNG as String, "public.png")
        XCTAssertEqual(kUTTypeJPEG as String, "public.jpeg")
        XCTAssertEqual(kUTTypeGIF as String, "com.compuserve.gif")
#else
        XCTAssertEqual(OpenUIKitImageIO.kCGImagePropertyPixelWidth as String, "PixelWidth")
        XCTAssertEqual(OpenUIKitImageIO.kCGImagePropertyPNGDictionary as String, "{PNG}")
        XCTAssertEqual(OpenUIKitImageIO.kCGImagePropertyExifDictionary as String, "{Exif}")
        XCTAssertEqual(OpenUIKitImageIO.kCGImagePropertyGPSDictionary as String, "{GPS}")
        XCTAssertEqual(
            OpenUIKitImageIO.kCGImageSourceShouldCache as String,
            "kCGImageSourceShouldCache"
        )
        XCTAssertEqual(
            OpenUIKitImageIO.kCGImageSourceThumbnailMaxPixelSize as String,
            "kCGImageSourceThumbnailMaxPixelSize"
        )
        XCTAssertEqual(OpenUIKitImageIO.kUTTypePNG as String, "public.png")
        XCTAssertEqual(OpenUIKitImageIO.kUTTypeJPEG as String, "public.jpeg")
        XCTAssertEqual(OpenUIKitImageIO.kUTTypeGIF as String, "com.compuserve.gif")
#endif
    }
}

/// MEASURED 2026-09-05 fixture: 2×1 RGB PNG, pHYs 5669 ppm, gAMA 45455, Title=Hello.
private let imageioProbePNGChunks: [UInt8] = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 2, 0, 0, 0, 1, 8, 2, 0, 0, 0,
    123, 64, 232, 221, 0, 0, 0, 9, 112, 72, 89, 115, 0, 0, 22, 37, 0, 0, 22, 37, 1, 73, 82, 36, 240,
    0, 0, 0, 4, 103, 65, 77, 65, 0, 0, 177, 143, 11, 252, 97, 5, 0, 0, 0, 11, 116, 69, 88, 116, 84,
    105, 116, 108, 101, 0, 72, 101, 108, 108, 111, 205, 207, 192, 207, 0, 0, 0, 18, 73, 68, 65,
    84, 120, 1, 1, 7, 0, 248, 255, 0, 255, 0, 0, 0, 255, 0, 7, 255, 1, 255, 197, 14, 226, 106, 0, 0,
    0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]
