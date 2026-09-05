import Foundation
import XCTest
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
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
