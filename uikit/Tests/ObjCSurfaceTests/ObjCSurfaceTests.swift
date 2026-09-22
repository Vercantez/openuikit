// The Objective-C surface of UIFont, CALayer and CGColorRef (route b;
// docs/agent_reports/objc-surface.md).
//
// Before this change UIFont was a Swift struct: Objective-C had no UIFont
// class, so `@interface UIFont (Artsy)` did not compile ("cannot define
// category for undefined class 'UIFont'") and every `[UIFont …]` message was
// "receiver 'UIFont' for class message is a forward declaration" (eidolon pod
// census). CALayer had no Objective-C members (`property 'bounds' not found
// on object of type 'CALayer *'`) and Swift vtable slots an Objective-C
// subclass would crash on. These tests run the shared Objective-C scenario —
// the same .m the iOS 26.1 simulator ran for
// Tools/oracle2/objcsurfaceprobe/transcript-ios26.1.txt — and compare line
// for line, then check the Swift-side contract and the class layout.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitObjCSurfaceFixtures

private func oracleSection(_ name: String) throws -> [String] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/objcsurfaceprobe/transcript-ios26.1.txt")
    let text = try String(contentsOf: url, encoding: .utf8)
    var out: [String] = []
    var inSection = false
    for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
        if line.hasPrefix("## ") { inSection = (line == "## " + name); continue }
        if inSection && !line.isEmpty { out.append(line) }
    }
    return out
}

private final class Lines { var all: [String] = [] }

private func collect(_ scenario: (OUKSurfaceSink?, UnsafeMutableRawPointer?) -> Void) -> [String] {
    let box = Lines()
    let context = Unmanaged.passUnretained(box).toOpaque()
    scenario({ line, context in
        Unmanaged<Lines>.fromOpaque(context!).takeUnretainedValue().all.append(String(cString: line!))
    }, context)
    return box.all
}

/// The Swift vtable entries a class introduces, by symbol (Swift 5 stable
/// ABI type descriptor; the same reader as ObjCSubclassingTests).
private func introducedVTableEntries(_ cls: AnyClass) -> [String] {
    let metadata = unsafeBitCast(cls, to: UnsafeRawPointer.self)
    let descriptor = metadata.load(fromByteOffset: 64, as: UnsafeRawPointer.self)
    let flags = descriptor.load(as: UInt32.self)
    let kindSpecific = flags >> 16
    guard kindSpecific & 0x8000 != 0 else { return [] }
    var offset = 44
    if kindSpecific & 0x2000 != 0 { offset += 4 }
    switch kindSpecific & 0x3 {
    case 1: offset += 12
    case 2: offset += 4
    default: break
    }
    let vtableSize = Int(descriptor.load(fromByteOffset: offset + 4, as: UInt32.self))
    var names: [String] = []
    for i in 0..<vtableSize {
        let entry = descriptor + offset + 8 + i * 8
        let rel = entry.load(fromByteOffset: 4, as: Int32.self)
        let impl = entry + 4 + Int(rel)
        var info = Dl_info()
        if dladdr(impl, &info) != 0, let sym = info.dli_sname {
            names.append(String(cString: sym))
        } else {
            names.append("<unnamed slot \(i)>")
        }
    }
    return names
}

/// On the macOS host OpenUIKit's UIFont and CALayer keep their mangled Swift
/// runtime names, which objc4 prints as `OpenUIKit.<Name>`: the host process
/// already has a `UIFont` (the private UIFoundation framework, MEASURED:
/// "Class UIFont is implemented in both …UIFoundation… and …") and a
/// `CALayer` (QuartzCore). The Mach-O guest, where OpenUIKit is the only
/// UIKit, uses UIKit's names (scripts/objc_surface_guest_probe.sh).
private func hostRuntimeNamesAsUIKit(_ lines: [String]) -> [String] {
    lines.map { $0.replacingOccurrences(of: "OpenUIKit.", with: "") }
}

final class ObjCSurfaceTests: XCTestCase {
    private func assertMatchesOracle(_ section: String, _ ours: [String],
                                     file: StaticString = #filePath, line: UInt = #line) throws {
        let expected = try oracleSection(section)
        XCTAssertFalse(expected.isEmpty, "oracle section \(section) missing", file: file, line: line)
        for (i, (a, b)) in zip(ours, expected).enumerated() {
            XCTAssertEqual(a, b, "\(section) line \(i + 1)", file: file, line: line)
        }
        XCTAssertEqual(ours.count, expected.count,
                       "\(section) length\nours:\n\(ours.joined(separator: "\n"))", file: file, line: line)
    }

    @MainActor
    func testSuperclassesMatchIOS26_1() throws {
        try assertMatchesOracle("superclasses", hostRuntimeNamesAsUIKit(collect(OUKSurfaceSuperclassFacts)))
    }

    @MainActor
    func testFontScenarioMatchesIOS26_1() throws {
        try assertMatchesOracle("font", collect(OUKSurfaceFontScenario))
    }

    @MainActor
    func testLayerScenarioMatchesIOS26_1() throws {
        try assertMatchesOracle("layer", hostRuntimeNamesAsUIKit(collect(OUKSurfaceLayerScenario)))
    }

    @MainActor
    func testLayerSubclassScenarioMatchesIOS26_1() throws {
        try assertMatchesOracle("layersubclass", hostRuntimeNamesAsUIKit(collect(OUKSurfaceLayerSubclassScenario)))
    }

    @MainActor
    func testCGColorScenarioMatchesIOS26_1() throws {
        try assertMatchesOracle("cgcolor", collect(OUKSurfaceColorScenario))
    }

    /// Swift source compatibility: the factories, `withSize`, and value
    /// equality/hashing where apps rely on them (Set / Dictionary keys,
    /// `==` between two separately built fonts), as measured on iOS 26.1.
    func testSwiftValueSemantics() {
        let a = UIFont.systemFont(ofSize: 17)
        let b = UIFont.systemFont(ofSize: 17)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertEqual(Set([a, b, UIFont.systemFont(ofSize: 18)]).count, 2)
        XCTAssertEqual(UIFont.systemFont(ofSize: 18).withSize(17), a)
        XCTAssertEqual(UIFont.systemFont(ofSize: 17, weight: .regular), a)
        XCTAssertNotEqual(UIFont.boldSystemFont(ofSize: 17), .systemFont(ofSize: 17, weight: .bold))
        XCTAssertNotEqual(UIFont.boldSystemFont(ofSize: 17), .systemFont(ofSize: 17, weight: .semibold))
        XCTAssertEqual(UIFont.boldSystemFont(ofSize: 17).fontName, ".SFUI-Semibold")
        XCTAssertEqual(UIFont.italicSystemFont(ofSize: 17).fontName, ".SFUI-RegularItalic")
        XCTAssertNotEqual(UIFont.preferredFont(forTextStyle: .body), a)
        // A struct copy used to be independent; a class instance is immutable,
        // so the same guarantee holds.
        var c = a
        c = c.withSize(30)
        XCTAssertEqual(a.pointSize, 17)
        XCTAssertEqual(c.pointSize, 30)
        let byFont: [UIFont: String] = [a: "body"]
        XCTAssertEqual(byFont[b], "body")
    }

    /// UIFont is an NSObject class Objective-C can name, and a category
    /// compiled against `@interface UIFont` attaches to OpenUIKit's class.
    func testUIFontIsAnObjectiveCClass() {
        XCTAssertTrue(class_getSuperclass(UIFont.self) === NSObject.self)
        XCTAssertEqual(NSStringFromClass(UIFont.self), "OpenUIKit.UIFont", "host runtime name (see above)")
        let meta: AnyClass = object_getClass(UIFont.self)!
        XCTAssertTrue(class_respondsToSelector(meta, NSSelectorFromString("ouk_serifFontWithSize:")),
                      "the scenario's Objective-C category is attached to OpenUIKit's UIFont")
        XCTAssertTrue(class_respondsToSelector(meta, NSSelectorFromString("systemFontOfSize:")))
    }

    /// Kickstarter Library's attribute literals: heterogeneous values typed
    /// `[NSAttributedString.Key: Any]` need an object UIFont.
    func testFontIsAnObjectAttributeValue() {
        let attributes: [OpenUIKit.NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.red,
        ]
        XCTAssertEqual(attributes[.font] as? UIFont, .systemFont(ofSize: 12))
        XCTAssertTrue((attributes[.font] as AnyObject) is NSObject)
    }

    /// The structural rule for Objective-C subclassing (simplenote-objc-core):
    /// a class an Objective-C app subclasses must introduce no Swift vtable
    /// slot. Before this change every CALayer `public var` accessor,
    /// `init(owner:)` and `layoutSublayers` was one.
    func testCALayerIntroducesNoSwiftVTableSlots() {
        XCTAssertEqual(introducedVTableEntries(CALayer.self), [])
    }

    /// A bridge or surface twin must not repeat a selector the class already
    /// implements: the category method would replace the native one and
    /// call itself (simplenote-objc-core). objc4 keeps both entries in the
    /// method list, so a duplicate shows up there.
    func testNoTwinShadowsANativeSelector() {
        let classes: [AnyClass] = [UIFont.self, CALayer.self, UIColor.self, UIView.self, UIControl.self,
                                   UIButton.self, UILabel.self, UIImage.self, UIScreen.self,
                                   UIVisualEffectView.self, UIBlurEffect.self, NSLayoutConstraint.self,
                                   UIApplication.self, UITextField.self, UITextView.self,
                                   UIAlertAction.self, UIAlertController.self, UIBarButtonItem.self,
                                   NSIndexPath.self]
        for cls in classes {
            for target in [cls, object_getClass(cls)!] {
                var count: UInt32 = 0
                guard let methods = class_copyMethodList(target, &count) else { continue }
                defer { free(methods) }
                var seen: [String: Int] = [:]
                for i in 0..<Int(count) { seen[NSStringFromSelector(method_getName(methods[i])), default: 0] += 1 }
                XCTAssertEqual(seen.filter { $0.value > 1 }.keys.sorted(), [],
                               "\(NSStringFromClass(target)): selectors implemented twice")
            }
        }
    }

    /// UIFont is final: its one slot is its own designated initializer, which
    /// Swift calls statically; nothing reads it through an Objective-C
    /// subclass (UIKit apps do not subclass UIFont).
    func testUIFontIsFinal() {
        XCTAssertEqual(introducedVTableEntries(UIFont.self).count, 1)
        XCTAssertTrue(introducedVTableEntries(UIFont.self).allSatisfy { $0.contains("6UIFontC9pointSize") })
    }
}
#endif
