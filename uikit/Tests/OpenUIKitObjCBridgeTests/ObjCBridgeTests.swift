// Route (b) Objective-C selector bridge (simplenote-launch3). Each test sends
// the Objective-C SELECTOR through the runtime — `perform(_:)` /
// `responds(to:)` — so a bridge member that is only a Swift method with a
// misspelled `@objc(...)` name fails here instead of at an app's link.
#if canImport(ObjectiveC)
import Foundation
import CoreGraphics
import ObjectiveC
import XCTest
@testable import OpenUIKit
@testable import OpenUIKitObjCBridge
import OpenUIKitObjCSupport

final class ObjCBridgeTests: XCTestCase {
    /// UIImage.h's CGImage selectors (cg-unify; SDWebImage's
    /// `+imageWithCGImage:scale:orientation:` and `.CGImage`): the
    /// CoreGraphics image goes in and comes back as the same object.
    func testUIImageCGImageSelectors() throws {
        let context = try XCTUnwrap(CGContext(data: nil, width: 2, height: 1, bitsPerComponent: 8,
                                              bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let cgImage = try XCTUnwrap(context.makeImage())
        for selector in ["imageWithCGImage:", "imageWithCGImage:scale:orientation:"] {
            XCTAssertTrue(UIImage.responds(to: NSSelectorFromString(selector)), selector)
        }
        let viaSelector = UIImage.perform(NSSelectorFromString("imageWithCGImage:"), with: cgImage)?
            .takeUnretainedValue() as? UIImage
        let image = try XCTUnwrap(viaSelector)
        XCTAssertTrue(image.perform(NSSelectorFromString("CGImage"))?.takeUnretainedValue() === cgImage)
        XCTAssertEqual(image.size, CGSize(width: 2, height: 1))
        XCTAssertEqual(Array(image.bitmap.pixels.prefix(4)), [255, 0, 0, 255])
        let scaled = UIImage.__objc_image(cgImage: cgImage, scale: 2, orientation: 3)
        XCTAssertEqual(scaled.scale, 2)
        XCTAssertEqual(scaled.imageOrientation, .right)
        XCTAssertEqual(scaled.__objc_imageOrientation, 3)
    }

    @MainActor
    func testTableViewCellSelectorsReachTheSwiftMembers() {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "r")
        XCTAssertTrue(cell.responds(to: NSSelectorFromString("textLabel")))
        XCTAssertTrue(cell.responds(to: NSSelectorFromString("detailTextLabel")))
        let label = cell.perform(NSSelectorFromString("textLabel"))?.takeUnretainedValue() as? UILabel
        XCTAssertTrue(label === cell.textLabel, "the selector must return the same UILabel the Swift API returns")
        // iOS SDK raw values: UITableViewCellSelectionStyleNone = 0, Blue = 1, Gray = 2, Default = 3.
        // Key-value coding resolves `setSelectionStyle:` / `selectionStyle`
        // through the Objective-C runtime and unboxes the NSInteger.
        cell.setValue(0, forKey: "selectionStyle")
        XCTAssertEqual(cell.selectionStyle, .none)
        cell.selectionStyle = .blue
        XCTAssertEqual((cell.value(forKey: "selectionStyle") as? NSNumber)?.intValue, 1)
        cell.setValue(3, forKey: "accessoryType")
        XCTAssertEqual(cell.accessoryType, .checkmark)
    }

    @MainActor
    func testInitWithStyleReuseIdentifierMapsSDKRawValues() {
        // UITableViewCellStyleValue1 = 1 (UITableViewCell.h). The designated
        // initializer is UITableViewCell's own `@objc dynamic`
        // `initWithStyle:reuseIdentifier:` now (OPENUIKIT_OBJC_SUBCLASSING),
        // and CellStyle carries the SDK raw values.
        let cell = UITableViewCell(style: UITableViewCell.CellStyle(rawValue: 1)!, reuseIdentifier: "v1")
        XCTAssertEqual(cell.style, .value1)
        XCTAssertEqual(cell.reuseIdentifier, "v1")
        XCTAssertTrue(cell.responds(to: NSSelectorFromString("initWithStyle:reuseIdentifier:")))
    }

    func testIndexPathRowAndSectionCategory() {
        let path = NSIndexPath(indexes: [2, 7], length: 2)
        XCTAssertTrue(path.responds(to: NSSelectorFromString("row")))
        XCTAssertEqual((path.value(forKey: "row") as? NSNumber)?.intValue, 7)
        XCTAssertEqual((path.value(forKey: "section") as? NSNumber)?.intValue, 2)
        // A class method taking two NSIntegers: call its IMP with the C signature.
        let selector = NSSelectorFromString("indexPathForRow:inSection:")
        let method = class_getClassMethod(NSIndexPath.self, selector)
        XCTAssertNotNil(method)
        typealias Factory = @convention(c) (AnyClass, Selector, Int, Int) -> NSIndexPath
        let factory = unsafeBitCast(method_getImplementation(method!), to: Factory.self)
        let made = factory(NSIndexPath.self, selector, 4, 1)
        XCTAssertEqual(made.index(atPosition: 0), 1)
        XCTAssertEqual(made.index(atPosition: 1), 4)
    }

    @MainActor
    func testViewSelectorsForwardToOpenUIKit() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // `initWithFrame:` is UIView's own `@objc dynamic` initializer now
        // (OPENUIKIT_OBJC_SUBCLASSING), no longer a bridge twin.
        XCTAssertTrue(UIView.instancesRespond(to: NSSelectorFromString("initWithFrame:")))
        let child = UIView(frame: CGRect(x: 1, y: 2, width: 3, height: 4))
        XCTAssertEqual(child.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
        host.perform(NSSelectorFromString("addSubview:"), with: child)
        XCTAssertTrue(host.subviews.contains { $0 === child })
        XCTAssertTrue(child.superview === host)
        child.perform(NSSelectorFromString("removeFromSuperview"))
        XCTAssertNil(child.superview)
        XCTAssertTrue(host.responds(to: NSSelectorFromString("setFrame:")))
        XCTAssertTrue(host.responds(to: NSSelectorFromString("layoutSubviews")))
    }

    @MainActor
    func testNavigationControllerSelectors() {
        let root = UIViewController()
        XCTAssertTrue(UINavigationController.instancesRespond(to: NSSelectorFromString("initWithRootViewController:")))
        let nav = UINavigationController(rootViewController: root)
        XCTAssertTrue(nav.topViewController === root)
        let next = UIViewController()
        nav.perform(NSSelectorFromString("pushViewController:animated:"), with: next, with: false)
        XCTAssertTrue(nav.topViewController === next)
        XCTAssertEqual((nav.perform(NSSelectorFromString("viewControllers"))?.takeUnretainedValue() as? [UIViewController])?.count, 2)
    }

    /// simplenote-objc-core: the support header's C structs and protocols
    /// reach an app's Swift half through its bridging header, next to
    /// OpenUIKit's own Swift types of the same UIKit names. Distinct Swift
    /// names keep both usable (Simplenote's Swift half reported 13
    /// `ambiguous use of 'init(top:left:bottom:right:)'` and 8+8
    /// `'UITableViewDelegate'/'UITableViewDataSource' is ambiguous` without
    /// them), and NSDirectionalEdgeInsets now exists on the Swift side at all
    /// (SPTextField.h:13 stopped Simplenote's bridging-header precompile).
    func testSupportDeclarationsHaveDistinctSwiftNames() {
        let directional = NSDirectionalEdgeInsetsObjC(top: 1, leading: 2, bottom: 3, trailing: 4)
        XCTAssertEqual(directional.leading, 2)
        XCTAssertEqual(MemoryLayout<NSDirectionalEdgeInsetsObjC>.size, 4 * MemoryLayout<CGFloat>.size)
        let c = UIEdgeInsetsObjC(top: 1, left: 2, bottom: 3, right: 4)
        let swift = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)   // OpenUIKit's, unambiguous
        XCTAssertEqual(c.left, swift.left)
        XCTAssertEqual(NSStringFromProtocol(UITextViewDelegate.self), "UITextViewDelegate")
        // The table protocols are OpenUIKit's own @objc protocols now, under
        // UIKit's runtime names (objc-protocols.md).
        XCTAssertEqual(NSStringFromProtocol(UITableViewDelegate.self), "UITableViewDelegate")
        XCTAssertEqual(NSStringFromProtocol(UITableViewDataSource.self), "UITableViewDataSource")
    }

    /// UIColor is NSObject-derived now (simplenote-objc-core), so the color
    /// surface an Objective-C app uses exists: SDK selectors, sent through
    /// the runtime, reaching OpenUIKit's own colors and properties.
    @MainActor
    func testColorSelectorsReachOpenUIKit() throws {
        let clear = UIColor.perform(NSSelectorFromString("clearColor"))?.takeUnretainedValue() as? UIColor
        XCTAssertEqual(clear, UIColor.clear)
        let label = UIColor.perform(NSSelectorFromString("labelColor"))?.takeUnretainedValue() as? UIColor
        XCTAssertTrue(label === UIColor.label)
        let sel = NSSelectorFromString("colorWithRed:green:blue:alpha:")
        let method = try XCTUnwrap(class_getClassMethod(UIColor.self, sel))
        typealias Factory = @convention(c) (AnyClass, Selector, CGFloat, CGFloat, CGFloat, CGFloat) -> UIColor
        let made = unsafeBitCast(method_getImplementation(method), to: Factory.self)(UIColor.self, sel, 1, 0, 0, 1)
        XCTAssertEqual(made, UIColor(red: 1, green: 0, blue: 0, alpha: 1))

        let view = UIView(frame: .zero)
        view.perform(NSSelectorFromString("setBackgroundColor:"), with: UIColor.red)
        XCTAssertEqual(view.backgroundColor, .red)
        let labelView = UILabel()
        labelView.perform(NSSelectorFromString("setTextColor:"), with: UIColor.blue)
        XCTAssertEqual(labelView.textColor, .blue)
        XCTAssertTrue(UIView.instancesRespond(to: NSSelectorFromString("setTintColor:")))  // native @objc
    }

    @MainActor
    func testApplicationSharedSelector() {
        let app = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication
        XCTAssertTrue(app === UIApplication.shared)
    }
}
#endif
