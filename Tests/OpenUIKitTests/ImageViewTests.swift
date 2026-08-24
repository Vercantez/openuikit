// Image-module tests: UIImage model, UIImageView contentMode geometry, and
// the CG-compatible warped-weight resampler (validated against oracle edge
// profiles — see UIImage.resampledBitmap).
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

private func solidBitmap(width: Int, height: Int, r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) -> Bitmap {
    let bmp = Bitmap(width: width, height: height)
    for i in stride(from: 0, to: bmp.pixels.count, by: 4) {
        bmp.pixels[i] = r; bmp.pixels[i + 1] = g; bmp.pixels[i + 2] = b; bmp.pixels[i + 3] = a
    }
    return bmp
}

final class ImageViewTests: XCTestCase {

    // MARK: UIImage

    func testImagePointSizeIsPixelSizeOverScale() {
        let img = UIImage(bitmap: Bitmap(width: 80, height: 60), scale: 2)
        XCTAssertEqual(img.size.width, 40)
        XCTAssertEqual(img.size.height, 30)
        XCTAssertEqual(img.scale, 2)
    }

    func testImageViewIntrinsicSizeMatchesImagePointSize() {
        let iv = UIImageView()
        XCTAssertEqual(iv.intrinsicContentSize.width, UIView.noIntrinsicMetric)
        XCTAssertEqual(iv.intrinsicContentSize.height, UIView.noIntrinsicMetric)
        iv.image = UIImage(bitmap: Bitmap(width: 80, height: 80), scale: 2)
        XCTAssertEqual(iv.intrinsicContentSize, CGSize(width: 40, height: 40))
        XCTAssertEqual(iv.sizeThatFits(CGSize(width: 200, height: 200)),
                       CGSize(width: 40, height: 40))
    }

    func testInitWithImageSizesFrameToImage() {
        let iv = UIImageView(image: UIImage(bitmap: Bitmap(width: 30, height: 30), scale: 1))
        XCTAssertEqual(iv.frame, CGRect(x: 0, y: 0, width: 30, height: 30))
    }

    // MARK: contentMode geometry (values mirror golden/imageview_modes)

    private func rect(_ mode: UIViewContentMode, image: CGSize, bounds: CGRect) -> CGRect {
        UIImageView.contentRect(imageSize: image, bounds: bounds, mode: mode)
    }

    func testScaleToFillUsesBounds() {
        let b = CGRect(x: 0, y: 0, width: 100, height: 60)
        XCTAssertEqual(rect(.scaleToFill, image: CGSize(width: 40, height: 40), bounds: b), b)
        XCTAssertEqual(rect(.redraw, image: CGSize(width: 40, height: 40), bounds: b), b)
    }

    func testAspectFitLetterboxesAndCenters() {
        // 40x40 in 100x60 -> min scale 1.5 -> 60x60 centered horizontally.
        let r = rect(.scaleAspectFit, image: CGSize(width: 40, height: 40),
                     bounds: CGRect(x: 0, y: 0, width: 100, height: 60))
        XCTAssertEqual(r, CGRect(x: 20, y: 0, width: 60, height: 60))
    }

    func testAspectFillOverflowsCentered() {
        // 40x80 in 100x60 -> max scale 2.5 -> 100x200, y centered = -70.
        let r = rect(.scaleAspectFill, image: CGSize(width: 40, height: 80),
                     bounds: CGRect(x: 0, y: 0, width: 100, height: 60))
        XCTAssertEqual(r, CGRect(x: 0, y: -70, width: 100, height: 200))
    }

    func testCenterIsUnscaledEvenWhenLarger() {
        // 80x80 in 100x60 -> (10, -10) unscaled (no rounding needed here).
        let r = rect(.center, image: CGSize(width: 80, height: 80),
                     bounds: CGRect(x: 0, y: 0, width: 100, height: 60))
        XCTAssertEqual(r, CGRect(x: 10, y: -10, width: 80, height: 80))
    }

    func testHalfPointCenteringIsNotRounded() {
        // Odd difference: (100-25)/2 = 37.5 — UIKit keeps the half point
        // (a whole device pixel at scale 2).
        let r = rect(.center, image: CGSize(width: 25, height: 25),
                     bounds: CGRect(x: 0, y: 0, width: 100, height: 60))
        XCTAssertEqual(r.origin.x, 37.5)
        XCTAssertEqual(r.origin.y, 17.5)
    }

    func testEdgeAndCornerPlacements() {
        let img = CGSize(width: 30, height: 30)
        let b = CGRect(x: 0, y: 0, width: 60, height: 60)
        XCTAssertEqual(rect(.topLeft, image: img, bounds: b).origin, CGPoint(x: 0, y: 0))
        XCTAssertEqual(rect(.top, image: img, bounds: b).origin, CGPoint(x: 15, y: 0))
        XCTAssertEqual(rect(.topRight, image: img, bounds: b).origin, CGPoint(x: 30, y: 0))
        XCTAssertEqual(rect(.left, image: img, bounds: b).origin, CGPoint(x: 0, y: 15))
        XCTAssertEqual(rect(.right, image: img, bounds: b).origin, CGPoint(x: 30, y: 15))
        XCTAssertEqual(rect(.bottomLeft, image: img, bounds: b).origin, CGPoint(x: 0, y: 30))
        XCTAssertEqual(rect(.bottom, image: img, bounds: b).origin, CGPoint(x: 15, y: 30))
        XCTAssertEqual(rect(.bottomRight, image: img, bounds: b).origin, CGPoint(x: 30, y: 30))
        for m: UIViewContentMode in [.topLeft, .top, .topRight, .left, .right,
                                     .bottomLeft, .bottom, .bottomRight] {
            XCTAssertEqual(rect(m, image: img, bounds: b).size, img)
        }
    }

    // MARK: warped-weight resampler (oracle ground truth)

    /// Magnified black/white edge must reproduce real CG's dyadic staircase.
    /// Oracle probe: 8px row [255 x4, 0 x4] scaled 20x -> device cols 60..99:
    /// 255 x11, 239 x3, 223 x2, 191 x3, 128 x2, 64 x3, 32 x2, 16 x3, 0...
    func testResampleEdgeProfileMatchesOracleAt20x() {
        let src = Bitmap(width: 8, height: 1)
        for x in 0..<8 {
            let v: UInt8 = x < 4 ? 255 : 0
            for c in 0..<3 { src.pixels[x * 4 + c] = v }
            src.pixels[x * 4 + 3] = 255
        }
        let out = UIImage(bitmap: src, scale: 1).resampledBitmap(width: 160, height: 1)
        let expected: [UInt8] = [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                                 239, 239, 239, 223, 223, 191, 191, 191, 128, 128,
                                 64, 64, 64, 32, 32, 16, 16, 16, 0, 0, 0]
        let got = (60..<92).map { out.pixels[$0 * 4] }
        XCTAssertEqual(got, expected)
    }

    /// Oracle at 1.5x: the pixels adjacent to a tile edge blend only 1/16.
    func testResampleEdgeProfileMatchesOracleAt1_5x() {
        let src = Bitmap(width: 80, height: 1)
        for x in 0..<80 {
            let v: UInt8 = (x / 16) % 2 == 0 ? 255 : 0
            for c in 0..<3 { src.pixels[x * 4 + c] = v }
            src.pixels[x * 4 + 3] = 255
        }
        let out = UIImage(bitmap: src, scale: 1).resampledBitmap(width: 120, height: 1)
        // Black->white boundary at src 32 -> dest 48: cols 47, 48 = 16, 239.
        XCTAssertEqual(out.pixels[47 * 4], 16)
        XCTAssertEqual(out.pixels[48 * 4], 239)
        XCTAssertEqual(out.pixels[46 * 4], 0)
        XCTAssertEqual(out.pixels[49 * 4], 255)
    }

    func testResampleIdentityReturnsSameBitmap() {
        let src = solidBitmap(width: 10, height: 10, r: 1, g: 2, b: 3)
        let img = UIImage(bitmap: src, scale: 2)
        XCTAssertTrue(img.resampledBitmap(width: 10, height: 10) === src)
    }

    // MARK: rendering

    func testCenterModeUnscaledBlitIsExact() {
        // 30x30pt solid at scale 2, topLeft in a 60x60 view: device pixels
        // 0..59 are image color, the rest transparent-over-background.
        let img = UIImage(bitmap: solidBitmap(width: 60, height: 60, r: 25, g: 113, b: 194), scale: 2)
        let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        iv.image = img
        iv.contentMode = .topLeft
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        root.backgroundColor = .white
        root.addSubview(iv)
        let bmp = UIRenderer.render(root, scale: 2)
        func px(_ x: Int, _ y: Int) -> [UInt8] {
            let o = (y * bmp.width + x) * 4
            return [bmp.pixels[o], bmp.pixels[o + 1], bmp.pixels[o + 2], bmp.pixels[o + 3]]
        }
        XCTAssertEqual(px(0, 0), [25, 113, 194, 255])
        XCTAssertEqual(px(59, 59), [25, 113, 194, 255])
        XCTAssertEqual(px(60, 60), [255, 255, 255, 255])
        XCTAssertEqual(px(119, 0), [255, 255, 255, 255])
    }

    func testAspectFillClipsToBoundsWhenSet() {
        // 20x40pt image in a 40x20 view, aspectFill -> scale 2 -> 40x80,
        // vertically centered at y=-30; with clipsToBounds the overflow must
        // not paint outside the view.
        let img = UIImage(bitmap: solidBitmap(width: 20, height: 40, r: 224, g: 49, b: 49), scale: 1)
        let iv = UIImageView(frame: CGRect(x: 10, y: 10, width: 40, height: 20))
        iv.image = img
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        root.backgroundColor = .white
        root.addSubview(iv)
        let bmp = UIRenderer.render(root, scale: 1)
        func red(_ x: Int, _ y: Int) -> Bool { bmp.pixels[(y * bmp.width + x) * 4] == 224 }
        XCTAssertTrue(red(30, 20))    // inside the view
        XCTAssertFalse(red(30, 5))    // above the view: clipped
        XCTAssertFalse(red(30, 35))   // below the view: clipped
    }
}
