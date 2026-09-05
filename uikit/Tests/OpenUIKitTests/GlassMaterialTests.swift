// iOS 26 liquid-glass mix. MEASURED glass_toolbar_se_{white,black},
// iPhone SE 3rd gen 2x / iOS 26.1: interiors (253,253,253) / (220,220,220).
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class GlassMaterialTests: XCTestCase {

    private func px(_ b: Bitmap, _ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
        let o = (y * b.width + x) * 4
        return (Int(b.pixels[o]), Int(b.pixels[o + 1]), Int(b.pixels[o + 2]), Int(b.pixels[o + 3]))
    }

    private func renderGlass(over color: UIColor, cut: FontEngine.SystemFontCut) -> Bitmap {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = cut
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                      displayScale: 2)
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        root.backgroundColor = color
        let glass = UIView(frame: CGRect(x: 20, y: 16, width: 60, height: 48))
        glass.isOpaque = false
        glass._usesIOSGlass = true
        glass.layer.cornerRadius = 24
        glass.backgroundColor = .white
        root.addSubview(glass)
        return UIRenderer.render(root, scale: 2)
    }

    func testIOSMixOverWhiteIs253() {
        let bmp = renderGlass(over: .white, cut: .iOS)
        // Glyph-free interior, away from the 1 pt ring. Centre of the 60×48
        // platter at 2x is (50, 40) pt → (100, 80) px.
        let p = px(bmp, 100, 80)
        XCTAssertEqual(p.a, 255)
        XCTAssertLessThanOrEqual(abs(p.r - 253), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.g - 253), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.b - 253), 2, "\(p)")
    }

    func testIOSMixOverBlackIs220() {
        // Focus Done over the unpainted bar; same mix, glass_toolbar_se_black.
        let bmp = renderGlass(over: .black, cut: .iOS)
        let p = px(bmp, 100, 80)
        XCTAssertEqual(p.a, 255)
        XCTAssertLessThanOrEqual(abs(p.r - 220), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.g - 220), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.b - 220), 2, "\(p)")
    }

    func testDarkFloatingGlassMixOverBlackIs57() {
        // MEASURED /tmp/sheetfill_dark medium_black, SE 2x / iOS 26.1:
        // α=203/255, T=57/203 over black → 57.
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark,
                                                      displayScale: 2)
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        root.overrideUserInterfaceStyle = .dark
        root.backgroundColor = .black
        let glass = UIView(frame: CGRect(x: 20, y: 16, width: 60, height: 48))
        glass.isOpaque = false
        glass._usesIOSGlass = true
        glass._usesIOSDarkGlass = true
        glass.layer.cornerRadius = 24
        root.addSubview(glass)
        let bmp = UIRenderer.render(root, scale: 2)
        let p = px(bmp, 100, 80)
        XCTAssertEqual(p.a, 255)
        XCTAssertLessThanOrEqual(abs(p.r - 57), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.g - 57), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.b - 57), 2, "\(p)")
    }

    func testCatalystKeepsTheFlatFill() {
        let bmp = renderGlass(over: .black, cut: .macOS)
        let p = px(bmp, 100, 80)
        XCTAssertEqual(p.a, 255)
        XCTAssertLessThanOrEqual(abs(p.r - 255), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.g - 255), 2, "\(p)")
        XCTAssertLessThanOrEqual(abs(p.b - 255), 2, "\(p)")
    }

    func testDonePlatterIsNotGlass() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let item = UIBarButtonItem(title: "Done", style: .done, target: nil, action: nil)
        let v = _UIBarButtonItemView(item: item)
        v.applyColors()
        XCTAssertFalse(v.platter._usesIOSGlass)
    }

    func testPlainPlatterIsGlass() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let item = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: nil)
        let v = _UIBarButtonItemView(item: item)
        v.applyColors()
        XCTAssertTrue(v.platter._usesIOSGlass)
    }

    func testIsolatedImageItemsDoNotShareAPlatter() {
        // MEASURED realapp_hackers_feed_light, iPhone 16 @3x: settings
        // `[277, 0, 44, 44]` and search `[333, 0, 44, 44]` (gap 12, not the
        // grouped 8) — two platters.
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let img = UIImage(bitmap: Bitmap(width: 66, height: 66), scale: 3)
        let aItem = UIBarButtonItem(image: img)
        let bItem = UIBarButtonItem(image: img)
        aItem._isolatesPlatter = true
        bItem._isolatesPlatter = true
        let a = _UIBarButtonItemView(item: aItem)
        let b = _UIBarButtonItemView(item: bItem)
        a.frame = CGRect(x: 277, y: 0, width: 44, height: 44)
        b.frame = CGRect(x: 333, y: 0, width: 44, height: 44)
        XCTAssertEqual(_UIBarItemLayout.gapBefore([a, b], 1), 12)
        XCTAssertEqual(_UIBarItemLayout.sharedPlatterFrames([a, b]), [])
        XCTAssertFalse(a._platterHiddenByGroup)
        XCTAssertFalse(b._platterHiddenByGroup)
    }
}
