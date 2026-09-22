// UIKit members ios-oss Library needs (pass 3), against the iOS 26.1
// transcripts of Tools/oracle2/swiftuia11yprobe (`uikit.*`) and
// iososslibraryprobe (docs/agent_reports/ios-oss-launch3-*.json).
import XCTest
import Foundation
@testable import OpenUIKit
#if canImport(AppKit)
import UIKit
#endif

@MainActor
final class IosOssLibraryMembersTests: XCTestCase {
    // uikit.* — the port used 1 << n in declaration order before.
    func testAccessibilityTraitRawValues() {
        let pairs: [(UIAccessibilityTraits, UInt64)] = [
            (.button, 1), (.link, 2), (.image, 4), (.selected, 8), (.playsSound, 16), (.keyboardKey, 32),
            (.staticText, 64), (.summaryElement, 128), (.notEnabled, 256), (.updatesFrequently, 512),
            (.searchField, 1024), (.startsMediaSession, 2048), (.adjustable, 4096),
            (.allowsDirectInteraction, 8192), (.causesPageTurn, 16384), (.tabBar, 32768), (.header, 65536),
            (.supportsZoom, 70_368_744_177_664), (.toggleButton, 9_007_199_254_740_992),
        ]
        for (trait, raw) in pairs { XCTAssertEqual(trait.rawValue, raw) }
    }

    // view.*ContentSizeCategory=nil; set .medium reads back.
    func testContentSizeCategoryLimits() {
        let v = UIView()
        XCTAssertNil(v.maximumContentSizeCategory)
        XCTAssertNil(v.minimumContentSizeCategory)
        v.maximumContentSizeCategory = .medium
        XCTAssertEqual(v.maximumContentSizeCategory, .medium)
        XCTAssertNil(UIView().maximumContentSizeCategory, "per-object storage")
    }

    // vc.shouldAutomaticallyForwardAppearanceMethods=true
    func testShouldAutomaticallyForwardAppearanceMethodsDefault() {
        XCTAssertTrue(UIViewController().shouldAutomaticallyForwardAppearanceMethods)
        final class Manual: UIViewController {
            override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }
        }
        XCTAssertFalse(Manual().shouldAutomaticallyForwardAppearanceMethods)
    }

    final class RecordingLabel: UILabel {
        var rects: [CGRect] = []
        var inset: CGFloat = 0
        override func drawText(in rect: CGRect) {
            rects.append(rect)
            super.drawText(in: rect.insetBy(dx: inset, dy: 0))
        }
    }

    private func ink(_ label: UILabel) -> (minX: Int, maxX: Int)? {
        let bitmap = Bitmap(width: Int(label.bounds.width) * 2, height: Int(label.bounds.height) * 2)
        let canvas = Canvas(bitmap: bitmap, scale: 2)
        label.drawContent(in: canvas, bounds: label.bounds)
        var minX = Int.max, maxX = -1
        for y in 0..<bitmap.height { for x in 0..<bitmap.width where bitmap.pixels[(y * bitmap.width + x) * 4 + 3] > 0 {
            minX = min(minX, x); maxX = max(maxX, x)
        } }
        return maxX < 0 ? nil : (minX, maxX)
    }

    // label.*.drawTextRects=[(0, 0, 120, 40)]: drawing calls drawText(in:)
    // once with the bounds, and the subclass's rect is where text goes.
    func testDrawTextInRectIsTheDrawingHook() throws {
        let plain = RecordingLabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        plain.text = "Hi"
        plain.textAlignment = .left
        let base = try XCTUnwrap(ink(plain))
        XCTAssertEqual(plain.rects, [CGRect(x: 0, y: 0, width: 120, height: 40)])
        let inset = RecordingLabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        inset.text = "Hi"
        inset.textAlignment = .left
        inset.inset = 10
        let moved = try XCTUnwrap(ink(inset))
        XCTAssertEqual(Double(moved.minX - base.minX), 20, accuracy: 1, "10 pt inset at 2x (±1 px glyph edge coverage)")
    }

    final class Provider: UIActivityItemProvider, @unchecked Sendable {
        override func activityViewController(_ activityViewController: UIActivityViewController,
                                             itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            "custom"
        }
        override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            "placeholder-override"
        }
    }

    func testActivityItemProviderMethodsAreOverridable() {
        let p = Provider(placeholderItem: "p")
        let vc = UIActivityViewController(activityItems: [p], applicationActivities: nil)
        XCTAssertEqual(p.activityViewController(vc, itemForActivityType: nil) as? String, "custom")
        XCTAssertEqual(p.activityViewControllerPlaceholderItem(vc) as? String, "placeholder-override")
    }

#if canImport(AppKit)
    // unAuthorizationStatus.raws=[0...4]; `import UIKit` alone names it on iOS.
    func testUIKitReexportsUserNotifications() {
        let s: UIKit.UNAuthorizationStatus = .authorized
        XCTAssertEqual(s.rawValue, 2)
    }
#endif
}
