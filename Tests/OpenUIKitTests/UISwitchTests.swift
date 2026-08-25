// Controls-module tests: UISwitch metrics and chrome, validated against
// golden/switch_onoff.{png,layout.json} (Catalyst iOS 26.1 ground truth).
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

@MainActor
final class UISwitchTests: XCTestCase {

    private func px(_ b: Bitmap, _ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int, a: Int) {
        let o = (y * b.width + x) * 4
        return (Int(b.pixels[o]), Int(b.pixels[o + 1]), Int(b.pixels[o + 2]), Int(b.pixels[o + 3]))
    }

    // MARK: metrics (golden layout dump: frame 63x28, intrinsic 61x28)

    func testDefaultSizeIsForced() {
        let s = UISwitch()
        XCTAssertEqual(s.frame.size, CGSize(width: 63, height: 28))
    }

    func testFrameSizeIsForcedOriginPreserved() {
        let s = UISwitch(frame: CGRect(x: 20, y: 20, width: 0, height: 0))
        XCTAssertEqual(s.frame, CGRect(x: 20, y: 20, width: 63, height: 28))
        let big = UISwitch(frame: CGRect(x: 5, y: 7, width: 300, height: 300))
        XCTAssertEqual(big.frame, CGRect(x: 5, y: 7, width: 63, height: 28))
    }

    func testSettingFrameLaterIsForcedBackOnLayout() {
        // Scene pipeline path: applyCommon sets frame after init, then the
        // container is laid out.
        let s = UISwitch()
        s.frame = CGRect(x: 100, y: 20, width: 0, height: 0)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 160))
        host.addSubview(s)
        host.layoutIfNeeded()
        XCTAssertEqual(s.frame, CGRect(x: 100, y: 20, width: 63, height: 28))
    }

    func testIntrinsicAndSizeThatFits() {
        let s = UISwitch()
        XCTAssertEqual(s.intrinsicContentSize, CGSize(width: 61, height: 28))
        XCTAssertEqual(s.sizeThatFits(.zero), CGSize(width: 63, height: 28))
    }

    func testSetOn() {
        let s = UISwitch()
        XCTAssertFalse(s.isOn)
        s.setOn(true, animated: false)
        XCTAssertTrue(s.isOn)
    }

    // MARK: chrome (golden pixels, light style, scale 2)

    private func renderSwitch(on: Bool, onTint: UIColor? = nil,
                              style: UIUserInterfaceStyle = .light) -> Bitmap {
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: style, displayScale: 2)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        let s = UISwitch(frame: CGRect(x: 5, y: 5, width: 0, height: 0))
        s.isOn = on
        s.onTintColor = onTint
        host.addSubview(s)
        host.layoutIfNeeded()
        return UIRenderer.render(host, scale: 2)
    }

    func testOnTrackIsSystemBlueByDefault() {
        // Golden on-track fill is exactly systemBlue light (0, 136, 255).
        let b = renderSwitch(on: true)
        let track = px(b, 30, 40) // interior track pixel left of the thumb
        XCTAssertEqual(track.r, 0)
        XCTAssertEqual(track.g, 136)
        XCTAssertEqual(track.b, 255)
        XCTAssertEqual(track.a, 255)
        // Thumb sits on the right: white interior.
        let thumb = px(b, 100, 40)
        XCTAssertEqual(thumb.r, 255)
        XCTAssertEqual(thumb.g, 255)
        XCTAssertEqual(thumb.b, 255)
    }

    func testOffTrackIsTranslucentBlackAndThumbOnLeft() {
        // Golden off-track (over transparent background) is (0, 0, 0, 66).
        let b = renderSwitch(on: false)
        let track = px(b, 110, 40) // interior track pixel right of the thumb
        XCTAssertEqual(track.r, 0)
        XCTAssertEqual(track.g, 0)
        XCTAssertEqual(track.b, 0)
        XCTAssertEqual(track.a, 66)
        let thumb = px(b, 30, 40)
        XCTAssertEqual(thumb.r, 255)
        XCTAssertEqual(thumb.a, 255)
    }

    func testOffTrackDarkIsTranslucentWhite() {
        // Oracle probe (off switch over pure black / pure white, dark style):
        // un-composited dark off-track is white at alpha 63/255.
        let b = renderSwitch(on: false, style: .dark)
        defer { UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 2) }
        let track = px(b, 110, 40)
        XCTAssertEqual(track.r, 255)
        XCTAssertEqual(track.g, 255)
        XCTAssertEqual(track.b, 255)
        XCTAssertEqual(track.a, 63)
    }

    func testOnTintColorIsUsed() {
        let b = renderSwitch(on: true, onTint: .systemOrange)
        // systemOrange light = (255, 141, 40)
        let track = px(b, 30, 40)
        XCTAssertEqual(track.r, 255)
        XCTAssertEqual(track.g, 141)
        XCTAssertEqual(track.b, 40)
    }

    func testOutsideTrackCornerIsTransparent() {
        let b = renderSwitch(on: true)
        // Switch frame is (5,5,63,28) pts -> px (10,10)-(136,66); the pill
        // corner leaves the bitmap corner of that rect empty.
        let corner = px(b, 12, 12)
        XCTAssertEqual(corner.a, 0)
    }
}
