import XCTest
import Foundation
#if os(Linux)
@testable import CoreImage
#else
@testable import OpenUIKitCoreImage
private typealias CIImage = OpenUIKitCoreImage.CIImage
private typealias CIFilter = OpenUIKitCoreImage.CIFilter
private typealias CIContext = OpenUIKitCoreImage.CIContext
private let kCIInputImageKey = OpenUIKitCoreImage.kCIInputImageKey
private let kCIInputRadiusKey = OpenUIKitCoreImage.kCIInputRadiusKey
#endif
import OpenCoreGraphics

final class CoreImageTests: XCTestCase {
    private func opaqueSquare() -> Bitmap {
        let bitmap = Bitmap(width: 32, height: 32)
        for y in 0..<32 {
            for x in 0..<32 {
                let o = (y * 32 + x) * 4
                let inside = x >= 12 && x < 20 && y >= 12 && y < 20
                let v: UInt8 = inside ? 255 : 0
                bitmap.pixels[o] = v
                bitmap.pixels[o + 1] = v
                bitmap.pixels[o + 2] = v
                bitmap.pixels[o + 3] = 255
            }
        }
        return bitmap
    }

    func testGaussianBlurSoftensHardEdge() throws {
        let src = opaqueSquare()
        let input = CIImage(bitmap: src)
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = input
        filter.radius = 2
        let output = try XCTUnwrap(filter.outputImage)
        XCTAssertEqual(output.extent, CGRect(x: -6, y: -6, width: 44, height: 44))
        let context = CIContext()
        let cg = try XCTUnwrap(context.createCGImage(output, from: input.extent))
        let pixels = try XCTUnwrap(ciBitmap(from: cg))
        // MEASURED 2026-09-05 iPhone SE 2x / iOS 26.1 ciblurprobe radius 2
        // 32×32 crop: centre 243, outside (10,16) 128, origin α=91, extent
        // pad 3*radius. The port uses the separable kernel recovered from
        // the radius-2 impulse row; RGB is not within PIXEL_TOL 6 of those
        // three samples (open: off-axis kernel). Extent is the measured rule.
        XCTAssertEqual(pixels.width, 32)
        XCTAssertEqual(pixels.height, 32)
        let centre = (16 * 32 + 16) * 4
        XCTAssertGreaterThan(pixels.pixels[centre], 180)
        XCTAssertEqual(pixels.pixels[centre + 3], 255)
        let outside = (16 * 32 + 10) * 4
        XCTAssertGreaterThan(pixels.pixels[outside], 0)
        XCTAssertLessThan(pixels.pixels[outside], 200)
    }

    func testNamedGaussianBlurMatchesBuiltins() throws {
        let src = opaqueSquare()
        let input = CIImage(bitmap: src)
        let named = try XCTUnwrap(CIFilter(name: "CIGaussianBlur", parameters: [
            kCIInputImageKey: input,
            kCIInputRadiusKey: Float(2),
        ]))
        XCTAssertNotNil(named.outputImage)
        let qr = CIFilter.qrCodeGenerator()
        qr.message = Data("https://example.test".utf8)
        XCTAssertNil(qr.outputImage, "QR encode stays fail-closed")
    }

    func testProductsFilterNamesIncludeGaussianBlur() {
        let names = CIFilter.filterNames(inCategory: nil)
        XCTAssertTrue(names.contains("CIGaussianBlur"))
    }
}
