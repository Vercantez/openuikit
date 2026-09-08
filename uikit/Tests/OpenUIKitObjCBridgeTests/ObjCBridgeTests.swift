// Route (b) Objective-C selector bridge (simplenote-launch3). Each test sends
// the Objective-C SELECTOR through the runtime — `perform(_:)` /
// `responds(to:)` — so a bridge member that is only a Swift method with a
// misspelled `@objc(...)` name fails here instead of at an app's link.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
@testable import OpenUIKit
@testable import OpenUIKitObjCBridge

final class ObjCBridgeTests: XCTestCase {
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
        // UITableViewCellStyleValue1 = 1 (UITableViewCell.h)
        let cell = UITableViewCell(__objcStyle: 1, reuseIdentifier: "v1")
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
        let child = UIView(__objcFrame: CGRect(x: 1, y: 2, width: 3, height: 4))
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
        let nav = UINavigationController(__objcRoot: root)
        XCTAssertTrue(nav.topViewController === root)
        let next = UIViewController()
        nav.perform(NSSelectorFromString("pushViewController:animated:"), with: next, with: false)
        XCTAssertTrue(nav.topViewController === next)
        XCTAssertEqual((nav.perform(NSSelectorFromString("viewControllers"))?.takeUnretainedValue() as? [UIViewController])?.count, 2)
    }

    @MainActor
    func testApplicationSharedSelector() {
        let app = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication
        XCTAssertTrue(app === UIApplication.shared)
    }
}
#endif
