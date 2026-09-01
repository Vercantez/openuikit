import Foundation
import XCTest
import CQuartz
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import OpenUIKit

@MainActor
final class UIImageCompatibilityTests: XCTestCase {
    func testEmptyInitializerHasZeroSize() {
        let image = UIImage()
        XCTAssertEqual(image.size, .zero)
        XCTAssertEqual(image.bitmap.width, 0)
        XCTAssertEqual(image.bitmap.height, 0)
    }

    func testFoundationDataInitializerUsesUIKitSpelling() {
        let source = Bitmap(width: 2, height: 1)
        source.pixels = [255, 0, 0, 255, 0, 255, 0, 128]
        let bytes = Data(source.pngData())

        let image = UIImage(data: bytes, scale: 2)
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.bitmap.pixels, source.pixels)
        XCTAssertEqual(image?.scale, 2)
        XCTAssertEqual(image?.size, CGSize(width: 1, height: 0.5))
    }

    func testCGImageInitializerIsZeroCopyAndPreservesMetadata() {
        let backing = Bitmap(width: 6, height: 4)
        let image = UIImage(cgImage: backing, scale: 2, orientation: .right)

        XCTAssertTrue(image.cgImage === backing)
        XCTAssertTrue(image.bitmap === backing)
        XCTAssertEqual(image.scale, 2)
        XCTAssertEqual(image.size, CGSize(width: 3, height: 2))
        XCTAssertEqual(image.imageOrientation, .right)
        XCTAssertEqual(image.withRenderingMode(.alwaysTemplate).imageOrientation,
                       .right)
        XCTAssertEqual(image.withTintColor(.red).imageOrientation, .right)
    }

    func testImageOrientationRawValuesMatchUIKit() {
        XCTAssertEqual(UIImage.Orientation.up.rawValue, 0)
        XCTAssertEqual(UIImage.Orientation.down.rawValue, 1)
        XCTAssertEqual(UIImage.Orientation.left.rawValue, 2)
        XCTAssertEqual(UIImage.Orientation.right.rawValue, 3)
        XCTAssertEqual(UIImage.Orientation.upMirrored.rawValue, 4)
        XCTAssertEqual(UIImage.Orientation.downMirrored.rawValue, 5)
        XCTAssertEqual(UIImage.Orientation.leftMirrored.rawValue, 6)
        XCTAssertEqual(UIImage.Orientation.rightMirrored.rawValue, 7)
    }

    func testCQuartzDecodesEveryGIFFrameAndDelay() {
        // Two 1x1 GIF89a frames with 0.10s and 0.20s graphic-control delays.
        let bytes: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00,
            0x00, 0x00, 0x00, 0xff, 0xff, 0xff,
            0x21, 0xf9, 0x04, 0x00, 0x0a, 0x00, 0x00, 0x00,
            0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
            0x02, 0x01, 0x4c, 0x00,
            0x21, 0xf9, 0x04, 0x00, 0x14, 0x00, 0x00, 0x00,
            0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
            0x02, 0x01, 0x4c, 0x00, 0x3b,
        ]
        var width: Int32 = 0
        var height: Int32 = 0
        var frameCount: Int32 = 0
        var delays: UnsafeMutablePointer<Int32>?
        let pixels = bytes.withUnsafeBufferPointer { buffer in
            QZImageDecodeGIFRGBA(
                buffer.baseAddress, buffer.count, &width, &height,
                &frameCount, &delays
            )
        }
        defer {
            QZImageFreeRGBA(pixels)
            QZImageFreeGIFDelays(delays)
        }
        XCTAssertNotNil(pixels)
        XCTAssertEqual(width, 1)
        XCTAssertEqual(height, 1)
        XCTAssertEqual(frameCount, 2)
        XCTAssertEqual(delays?[0], 100)
        XCTAssertEqual(delays?[1], 200)
        XCTAssertNotNil(UIImage(data: bytes))
    }

    func testDrawAtBlendModeNormalAppliesGlobalAlphaOnce() {
        let source = Bitmap(width: 1, height: 1)
        source.pixels = [240, 80, 20, 128]
        let image = UIImage(bitmap: source)
        let format = UIGraphicsImageRendererFormat(scale: 1)
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1),
                                                format: format).image { _ in
            image.draw(at: .zero, blendMode: .normal, alpha: 0.5)
        }

        // Drawing onto transparent output keeps straight RGB and multiplies
        // the source alpha by the one global image opacity.
        // Quartz's premultiply/unpremultiply round-trip produces red 239
        // here as well (real-iOS oracle BGRA [5,20,60,64]).
        XCTAssertEqual(rendered.bitmap.pixels, [239, 80, 20, 64])
    }

    func testBlendModeRawValuesMatchCoreGraphics() {
        XCTAssertEqual(OpenUIKit.CGBlendMode.normal.rawValue, 0)
        XCTAssertEqual(OpenUIKit.CGBlendMode.color.rawValue, 14)
        XCTAssertEqual(OpenUIKit.CGBlendMode.copy.rawValue, 17)
        XCTAssertEqual(OpenUIKit.CGBlendMode.plusLighter.rawValue, 27)
    }

#if canImport(CoreGraphics)
    func testBlendModeIsUnambiguousAlongsideCoreGraphics() {
        // This intentionally stays unqualified: a duplicate OpenUIKit enum
        // made this exact real-app import shape fail to compile on Darwin.
        let mode: CGBlendMode = .normal
        XCTAssertEqual(mode, CoreGraphics.CGBlendMode.normal)
    }
#endif
}
