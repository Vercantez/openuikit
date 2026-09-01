import XCTest
import OpenCoreGraphics

final class BitmapContextTests: XCTestCase {
    func testCGImageBytesPerRowDescribesItsPackedRGBAStorage() throws {
        let image = Bitmap(width: 3, height: 2)
        XCTAssertEqual(image.bytesPerRow, 12)
        XCTAssertEqual(image.pixels.count, image.bytesPerRow * image.height)

        var paddedStorage = [UInt8](repeating: 0, count: 16)
        let snapshot = try paddedStorage.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(OpenCoreGraphics.Canvas(
                data: bytes.baseAddress,
                width: 1,
                height: 2,
                bitsPerComponent: 8,
                bytesPerRow: 8,
                space: OpenCoreGraphics.CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            return try XCTUnwrap(context.makeImage())
        }
        XCTAssertEqual(snapshot.bytesPerRow, 4,
                       "the immutable CGImage snapshot reports its compact stride, not the source context padding")
        XCTAssertEqual(snapshot.pixels.count,
                       snapshot.bytesPerRow * snapshot.height)
    }

    func testOwnedDeviceRGBContextMakesIndependentImageSnapshot() throws {
        let space = OpenCoreGraphics.CGColorSpaceCreateDeviceRGB()
        let context = try XCTUnwrap(OpenCoreGraphics.Canvas(
            data: nil,
            width: 2,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 8,
            space: space,
            bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
        ))

        context.fill(
            rect: CGRect(x: 0, y: 0, width: 1, height: 1),
            color: CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        )
        let image = try XCTUnwrap(context.makeImage())
        XCTAssertEqual(image.width, 2)
        XCTAssertEqual(image.height, 1)
        XCTAssertEqual(Array(image.pixels.prefix(4)), [255, 0, 0, 255])

        context.fill(
            rect: CGRect(x: 0, y: 0, width: 1, height: 1),
            color: .black
        )
        XCTAssertEqual(Array(image.pixels.prefix(4)), [255, 0, 0, 255])
    }

    func testCallerOwnedPremultipliedBackingIsLiveAndSnapshotted() throws {
        var storage: [UInt8] = [1, 2, 3, 4, 9, 9, 9, 9]
        let image = try storage.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(OpenCoreGraphics.Canvas(
                data: bytes.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 8,
                space: OpenCoreGraphics.CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            XCTAssertEqual(Array(bytes.prefix(4)), [1, 2, 3, 4])
            for index in 0..<4 { bytes[index] = 0 }
            context.fill(
                rect: CGRect(x: 0, y: 0, width: 1, height: 1),
                color: CGColor(red: 0, green: 1, blue: 0, alpha: 0.5)
            )
            return try XCTUnwrap(context.makeImage())
        }

        XCTAssertEqual(storage[3], 128)
        XCTAssertGreaterThanOrEqual(storage[1], 127)
        XCTAssertEqual(Array(image.pixels.prefix(4)), [0, 255, 0, 128])
        XCTAssertEqual(Array(storage.suffix(4)), [9, 9, 9, 9])
    }

    func testUnsupportedBitmapContractsFailClosed() {
        let space = OpenCoreGraphics.CGColorSpaceCreateDeviceRGB()
        XCTAssertNil(OpenCoreGraphics.Canvas(
            data: nil, width: 1, height: 1, bitsPerComponent: 16,
            bytesPerRow: 4, space: space,
            bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        XCTAssertNil(OpenCoreGraphics.Canvas(
            data: nil, width: 2, height: 1, bitsPerComponent: 8,
            bytesPerRow: 4, space: space,
            bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        XCTAssertNil(OpenCoreGraphics.Canvas(
            data: nil, width: 1, height: 1, bitsPerComponent: 8,
            bytesPerRow: 4, space: space,
            bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.none.rawValue
        ))
        XCTAssertNil(OpenCoreGraphics.Canvas(
            data: nil, width: 1, height: 1, bitsPerComponent: 8,
            bytesPerRow: 4, space: space,
            bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue | 0x2000
        ))
        XCTAssertNil(OpenCoreGraphics.Canvas(
            data: nil, width: .max, height: 1, bitsPerComponent: 8,
            bytesPerRow: .max, space: space,
            bitmapInfo: OpenCoreGraphics.CGImageAlphaInfo.premultipliedLast.rawValue
        ))
    }
}
