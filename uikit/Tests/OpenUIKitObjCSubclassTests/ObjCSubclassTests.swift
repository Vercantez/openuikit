// The chain-rule gate (docs/agent_reports/objc-impl-chain1.md): an
// Objective-C subclass of every `@objc @implementation` class must be able
// to init / override / call super at runtime, because nothing at compile
// time catches a plain Swift class left in the middle of the chain.
import XCTest
import Foundation
import OpenUIKit
import OpenUIKitObjCSubclassProbe

final class ObjCSubclassTests: XCTestCase {
    @MainActor
    func testObjectiveCSubclassesOfUIViewAndUIWindow() {
        let lines = OUIObjCSubclassScenario()
        for line in lines { print(line) }
        let failures = lines.filter { $0.hasPrefix("FAIL") }
        XCTAssertEqual(failures, [], "Objective-C subclass checks failed")
        XCTAssertGreaterThanOrEqual(lines.count, 20, "the scenario ran every check")
    }

    /// Swift sees the Objective-C subclass as an OpenUIKit.UIView: casts,
    /// the Swift-side API on it, and Swift-declared members it inherits.
    @MainActor
    func testSwiftSeesTheObjectiveCSubclassAsAUIView() {
        let v = OUIObjCView(frame: CGRect(x: 1, y: 2, width: 3, height: 4), label: "swift")
        XCTAssertTrue((v as AnyObject) is UIView)
        XCTAssertEqual(v.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
        XCTAssertEqual(v.label, "swift")
        let w = OUIObjCWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        w.addSubview(v)
        w.layoutIfNeeded()
        XCTAssertEqual(v.objcLayouts, 1)
        XCTAssertEqual(w.objcLayouts, 1)
        XCTAssertTrue(v.window === w)
        // Swift-only (final) API of UIView on the ObjC subclass instance.
        v.transform = .identity
        XCTAssertEqual(v.contentMode, .scaleToFill)
        XCTAssertTrue(v.layer.owner === v)
        // The bridged trait collection round-trips as the Swift struct.
        XCTAssertEqual(v.traitCollection.displayScale, w.traitCollection.displayScale)
    }

    /// The runtime class names are UIKit's, and the chain is complete.
    func testRuntimeClassChain() {
        XCTAssertEqual(NSStringFromClass(UIWindow.self), "UIWindow")
        XCTAssertEqual(NSStringFromClass(UIView.self), "UIView")
        XCTAssertEqual(NSStringFromClass(UIResponder.self), "UIResponder")
        XCTAssertTrue(UIWindow.superclass() == UIView.self)
        XCTAssertTrue(UIView.superclass() == UIResponder.self)
        XCTAssertTrue(UIResponder.superclass() == NSObject.self)
    }
}
