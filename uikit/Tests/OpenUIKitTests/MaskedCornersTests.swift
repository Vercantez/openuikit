import XCTest
@testable import OpenUIKit

private typealias CACornerMask = OpenUIKit.CACornerMask
private typealias CALayer = OpenUIKit.CALayer
private typealias CAGradientLayer = OpenUIKit.CAGradientLayer

#if !os(Linux)
@MainActor
#endif
final class MaskedCornersTests: XCTestCase {
    private func alpha(_ bitmap: Bitmap, _ x: Int, _ y: Int) -> Int {
        Int(bitmap.pixels[(y * bitmap.width + x) * 4 + 3])
    }

    private func render(_ corners: CACornerMask, clips: Bool = false)
        -> (pass: Bitmap, layers: Bitmap) {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        root.backgroundColor = .red
        root.layer.cornerRadius = 10
        root.layer.maskedCorners = corners
        root.clipsToBounds = clips
        return (UIRenderer.renderPassRender(root, scale: 1),
                LayerBridge.render(root, scale: 1))
    }

    private func assertCorners(
        _ bitmap: Bitmap,
        rounded: (minXMinY: Bool, maxXMinY: Bool,
                  minXMaxY: Bool, maxXMaxY: Bool),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let samples = [
            (1, 1, rounded.minXMinY, "minX/minY"),
            (38, 1, rounded.maxXMinY, "maxX/minY"),
            (1, 38, rounded.minXMaxY, "minX/maxY"),
            (38, 38, rounded.maxXMaxY, "maxX/maxY"),
        ]
        for (x, y, isRounded, name) in samples {
            XCTAssertEqual(alpha(bitmap, x, y), isRounded ? 0 : 255,
                           "unexpected \(name) corner", file: file, line: line)
        }
        XCTAssertEqual(alpha(bitmap, 20, 20), 255, file: file, line: line)
    }

    func testRawValuesDefaultAndUnknownBitNormalization() {
        XCTAssertEqual(CACornerMask.layerMinXMinYCorner.rawValue, 1)
        XCTAssertEqual(CACornerMask.layerMaxXMinYCorner.rawValue, 2)
        XCTAssertEqual(CACornerMask.layerMinXMaxYCorner.rawValue, 4)
        XCTAssertEqual(CACornerMask.layerMaxXMaxYCorner.rawValue, 8)

        let layer = CALayer()
        XCTAssertEqual(layer.maskedCorners.rawValue, 15)
        layer.maskedCorners = [
            .layerMinXMinYCorner,
            CACornerMask(rawValue: 128),
        ]
        XCTAssertEqual(layer.maskedCorners, .layerMinXMinYCorner,
                       "iOS 26 discards unknown bits when assigning the property")
        layer.maskedCorners = CACornerMask(rawValue: 0xff)
        XCTAssertEqual(layer.maskedCorners.rawValue, 15)
    }

    func testEachMaskRoundsItsNamedUIKitCornerInBothCompositors() {
        let cases: [(CACornerMask, (Bool, Bool, Bool, Bool))] = [
            ([], (false, false, false, false)),
            (.layerMinXMinYCorner, (true, false, false, false)),
            (.layerMaxXMinYCorner, (false, true, false, false)),
            (.layerMinXMaxYCorner, (false, false, true, false)),
            (.layerMaxXMaxYCorner, (false, false, false, true)),
            ([.layerMinXMinYCorner, .layerMaxXMinYCorner,
              .layerMinXMaxYCorner, .layerMaxXMaxYCorner],
             (true, true, true, true)),
        ]
        for (mask, expected) in cases {
            let images = render(mask)
            let rounded = (minXMinY: expected.0, maxXMinY: expected.1,
                           minXMaxY: expected.2, maxXMaxY: expected.3)
            assertCorners(images.pass, rounded: rounded)
            assertCorners(images.layers, rounded: rounded)
        }
    }

    func testMaskedCornersAlsoShapeMasksToBoundsClip() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        root.backgroundColor = .white
        let parent = UIView(frame: CGRect(x: 2, y: 2, width: 40, height: 40))
        parent.layer.cornerRadius = 10
        parent.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
        ]
        parent.clipsToBounds = true
        let child = UIView(frame: parent.bounds)
        child.backgroundColor = .red
        parent.addSubview(child)
        root.addSubview(parent)

        for bitmap in [UIRenderer.renderPassRender(root, scale: 1),
                       LayerBridge.render(root, scale: 1)] {
            XCTAssertEqual(alpha(bitmap, 3, 3), 255)
            let topLeft = (3 * bitmap.width + 3) * 4
            XCTAssertEqual(Array(bitmap.pixels[topLeft..<(topLeft + 3)]), [255, 255, 255])
            let bottomLeft = (40 * bitmap.width + 3) * 4
            XCTAssertEqual(Array(bitmap.pixels[bottomLeft..<(bottomLeft + 3)]), [255, 0, 0])
        }
    }

    func testLegacyLayerRenderRoundsAllCornersLikeIOS26() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.backgroundColor = .red
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = .layerMinXMinYCorner
        let bitmap = Bitmap(width: 40, height: 40)
        view.layer.render(in: Canvas(bitmap: bitmap, scale: 1))
        assertCorners(bitmap, rounded: (true, true, true, true))

        // The legacy behavior applies recursively to explicit sublayers too.
        // A real iOS 26.1 CALayer hierarchy produced four rounded corners
        // when only the child's minX/minY bit was set.
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let child = CALayer()
        child.frame = parent.bounds
        child.backgroundColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        child.cornerRadius = 10
        child.maskedCorners = .layerMinXMinYCorner
        parent.layer.addSublayer(child)
        let nested = Bitmap(width: 40, height: 40)
        parent.layer.render(in: Canvas(bitmap: nested, scale: 1))
        assertCorners(nested, rounded: (true, true, true, true))
    }

    func testExplicitGradientUsesTheSameSelectiveCornerPath() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let gradient = CAGradientLayer()
        gradient.frame = root.bounds
        gradient.colors = [CGColor(red: 1, green: 0, blue: 0, alpha: 1),
                           CGColor(red: 1, green: 0, blue: 0, alpha: 1)]
        gradient.cornerRadius = 10
        gradient.maskedCorners = .layerMinXMinYCorner
        root.layer.addSublayer(gradient)

        let rounded = (minXMinY: true, maxXMinY: false,
                       minXMaxY: false, maxXMaxY: false)
        assertCorners(UIRenderer.renderPassRender(root, scale: 1),
                      rounded: rounded)
        assertCorners(LayerBridge.render(root, scale: 1), rounded: rounded)
    }

    func testSelectiveBorderAndShadowStayInCompositorParity() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 60))
        root.backgroundColor = .white
        let card = UIView(frame: CGRect(x: 15, y: 10, width: 40, height: 36))
        card.backgroundColor = .blue
        card.layer.cornerRadius = 10
        card.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
        ]
        card.layer.borderWidth = 2
        card.layer.borderColor = CGColor.black
        card.layer.shadowColor = CGColor.black
        card.layer.shadowOpacity = 0.7
        card.layer.shadowRadius = 3
        card.layer.shadowOffset = CGSize(width: 1, height: 2)
        root.addSubview(card)

        let pass = UIRenderer.renderPassRender(root, scale: 2)
        let layers = LayerBridge.render(root, scale: 2)
        XCTAssertEqual(pass.width, layers.width)
        XCTAssertEqual(pass.height, layers.height)
        var total = 0
        for i in pass.pixels.indices {
            total += abs(Int(pass.pixels[i]) - Int(layers.pixels[i]))
        }
        let mean = Double(total) / Double(pass.pixels.count)
        XCTAssertLessThan(mean, 0.6)
    }
}
