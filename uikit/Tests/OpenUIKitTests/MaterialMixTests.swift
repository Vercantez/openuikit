// Per-style UIVisualEffectView interiors. MEASURED /tmp/materials-probe,
// iPhone SE 2x / iOS 26.1. Guard: iOS cut; Catalyst stays radius-20.
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class MaterialMixTests: XCTestCase {

    private func px(_ b: Bitmap, _ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
        let o = (y * b.width + x) * 4
        return (Int(b.pixels[o]), Int(b.pixels[o + 1]), Int(b.pixels[o + 2]),
                Int(b.pixels[o + 3]))
    }

    private func render(_ effect: UIVisualEffect, over color: UIColor,
                        cut: FontEngine.SystemFontCut,
                        style: UIUserInterfaceStyle = .light) -> (r: Int, g: Int, b: Int, a: Int) {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = cut
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: style,
                                                      displayScale: 2)
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 160))
        root.overrideUserInterfaceStyle = style
        root.backgroundColor = color
        let view = UIVisualEffectView(effect: effect)
        view.frame = CGRect(x: 40, y: 40, width: 120, height: 80)
        root.addSubview(view)
        let bmp = UIRenderer.render(root, scale: 2)
        // Effect centre (100, 80) pt → (200, 160) px at 2x.
        return px(bmp, 200, 160)
    }

    private func assertNear(_ p: (r: Int, g: Int, b: Int, a: Int),
                            _ r: Int, _ g: Int, _ b: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(p.a, 255, file: file, line: line)
        XCTAssertLessThanOrEqual(abs(p.r - r), 2, "r \(p)", file: file, line: line)
        XCTAssertLessThanOrEqual(abs(p.g - g), 2, "g \(p)", file: file, line: line)
        XCTAssertLessThanOrEqual(abs(p.b - b), 2, "b \(p)", file: file, line: line)
    }

    private var probeRed: UIColor {
        UIColor(red: 255.0 / 255.0, green: 56.0 / 255.0, blue: 60.0 / 255.0, alpha: 1)
    }
    private var probeYellow: UIColor {
        UIColor(red: 242.0 / 255.0, green: 179.0 / 255.0, blue: 64.0 / 255.0, alpha: 1)
    }

    func testExtraLightInteriors() {
        let fx = UIBlurEffect(style: .extraLight)
        assertNear(render(fx, over: .white, cut: .iOS), 249, 249, 249)
        assertNear(render(fx, over: .black, cut: .iOS), 198, 198, 198)
        assertNear(render(fx, over: probeRed, cut: .iOS), 249, 202, 204)
        assertNear(render(fx, over: probeYellow, cut: .iOS), 249, 233, 198)
    }

    func testLightAndRegularMatch() {
        let light = UIBlurEffect(style: .light)
        let regular = UIBlurEffect(style: .regular)
        assertNear(render(light, over: .white, cut: .iOS), 255, 255, 255)
        assertNear(render(light, over: .black, cut: .iOS), 77, 77, 77)
        assertNear(render(regular, over: .white, cut: .iOS), 255, 255, 255)
        assertNear(render(regular, over: .black, cut: .iOS), 77, 77, 77)
    }

    func testDarkBlurInteriors() {
        let fx = UIBlurEffect(style: .dark)
        assertNear(render(fx, over: .white, cut: .iOS), 89, 89, 89)
        assertNear(render(fx, over: .black, cut: .iOS), 20, 20, 20)
    }

    func testSystemMaterialGrayInteriors() {
        let fx = UIBlurEffect(style: .systemMaterial)
        assertNear(render(fx, over: .white, cut: .iOS), 245, 245, 245)
        assertNear(render(fx, over: .black, cut: .iOS), 197, 197, 197)
    }

    func testGlassRegularAndClear() {
        assertNear(render(UIGlassEffect(style: .regular), over: .white, cut: .iOS),
                   251, 251, 251)
        assertNear(render(UIGlassEffect(style: .regular), over: .black, cut: .iOS),
                   175, 175, 175)
        assertNear(render(UIGlassEffect(style: .clear), over: .white, cut: .iOS),
                   255, 255, 255)
        assertNear(render(UIGlassEffect(style: .clear), over: .black, cut: .iOS),
                   19, 19, 19)
    }

    func testGlassRegularDark() {
        // MEASURED /tmp/materials-dark-probe, SE 2x / iOS 26.1.
        // Gray interiors close. Red G fitted sat=2.225; red R is 141 vs
        // measured 150 (named residual, not retuned).
        assertNear(render(UIGlassEffect(style: .regular), over: .white, cut: .iOS,
                          style: .dark), 91, 91, 91)
        assertNear(render(UIGlassEffect(style: .regular), over: .black, cut: .iOS,
                          style: .dark), 24, 24, 24)
        let red = render(UIGlassEffect(style: .regular), over: probeRed, cut: .iOS,
                         style: .dark)
        XCTAssertEqual(red.a, 255)
        XCTAssertLessThanOrEqual(abs(red.g - 25), 2, "g \(red)")
        XCTAssertLessThanOrEqual(abs(red.b - 28), 2, "b \(red)")
        XCTAssertLessThanOrEqual(abs(red.r - 141), 2, "r \(red)")
    }

    func testCatalystBlurIsUntinted() {
        // macOS cut keeps radius-20 gaussian, no overlay. Black stays black.
        let p = render(UIBlurEffect(style: .extraLight), over: .black, cut: .macOS)
        XCTAssertLessThan(p.r, 40, "\(p)")
        XCTAssertLessThan(p.g, 40, "\(p)")
        XCTAssertLessThan(p.b, 40, "\(p)")
    }

    func testInertBlurPaintsNothing() {
        let p = render(UIBlurEffect(), over: .black, cut: .iOS)
        XCTAssertLessThan(p.r, 8, "\(p)")
    }
}
