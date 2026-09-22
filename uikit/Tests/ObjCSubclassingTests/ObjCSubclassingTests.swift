// Objective-C subclasses of OpenUIKit classes (route b; docs/agent_reports/
// simplenote-objc-core.md).
//
// Before OPENUIKIT_OBJC_SUBCLASSING, `@interface OUKObjCView : UIView` did not
// compile (objc_subclassing_restricted on every generated interface), and
// with the restriction lifted the first `[[OUKObjCView alloc] init]` died on
// a null Swift vtable slot (simplenote-launch3 probe1). These tests run the
// shared Objective-C scenario — the same .m file the iOS 26.1 simulator ran
// for Tools/oracle2/objcsubclassprobe/transcript-ios26.1.txt — and compare
// the traces line for line, then check the structural rule that makes it
// work (no Swift vtable slot on the chain classes) directly on the metadata.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitObjCSubclassFixtures

/// Oracle transcript sections ("## superclasses", "## trace").
private func oracleSection(_ name: String) throws -> [String] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/objcsubclassprobe/transcript-ios26.1.txt")
    let text = try String(contentsOf: url, encoding: .utf8)
    var out: [String] = []
    var inSection = false
    for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
        if line.hasPrefix("## ") { inSection = (line == "## " + name); continue }
        if inSection && !line.isEmpty { out.append(line) }
    }
    return out
}

// MARK: - Swift type-descriptor reading (Swift 5 stable ABI)

/// The Swift vtable entries a class INTRODUCES, from its nominal type
/// descriptor. An entry is a slot Swift reads at a fixed offset from the
/// receiver's isa; a statically emitted Objective-C subclass has no such
/// region, so every class an Objective-C app may subclass must introduce
/// none (or only the documented, dispatch-guarded ones).
private func introducedVTableEntries(_ cls: AnyClass) -> [String] {
    let metadata = unsafeBitCast(cls, to: UnsafeRawPointer.self)
    // objc_class (5 words) + Flags, InstanceAddressPoint, InstanceSize,
    // InstanceAlignMask/Reserved, ClassSize, ClassAddressPoint (24 bytes).
    let descriptor = metadata.load(fromByteOffset: 64, as: UnsafeRawPointer.self)
    let flags = descriptor.load(as: UInt32.self)
    let kindSpecific = flags >> 16
    let hasVTable = kindSpecific & 0x8000 != 0
    guard hasVTable else { return [] }
    // TargetClassDescriptor: flags + 10 more 32-bit fields = 44 bytes, then
    // trailing objects in order.
    var offset = 44
    if kindSpecific & 0x2000 != 0 { offset += 4 }          // resilient superclass
    switch kindSpecific & 0x3 {                              // metadata initialization
    case 1: offset += 12                                      // singleton
    case 2: offset += 4                                       // foreign
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

final class ObjCSubclassingTests: XCTestCase {
    @MainActor
    func testObjectiveCSubclassTraceMatchesIOS26_1() throws {
        let expected = try oracleSection("trace")
        XCTAssertFalse(expected.isEmpty, "oracle transcript missing")
        let ours = OUKRunSubclassScenarios()
        for (i, (a, b)) in zip(ours, expected).enumerated() {
            XCTAssertEqual(a, b, "trace line \(i + 1)")
        }
        XCTAssertEqual(ours.count, expected.count, "trace length\nours:\n\(ours.joined(separator: "\n"))")
    }

    @MainActor
    func testConvertedTypesHaveUIKitsSuperclasses() throws {
        XCTAssertEqual(OUKSuperclassFacts(), try oracleSection("superclasses"))
    }

    @MainActor
    func testObjectiveCInstanceIsASwiftUIView() {
        let view = OUKMakeObjCView()
        let asView = view as? UIView
        XCTAssertNotNil(asView, "an Objective-C subclass instance must cast to OpenUIKit.UIView")
        XCTAssertEqual(asView?.frame, CGRect(x: 0, y: 0, width: 10, height: 10))
        // Swift-side dispatch of the @objc dynamic override points reaches
        // the Objective-C override.
        asView?.setNeedsLayout()
        asView?.layoutIfNeeded()
        XCTAssertEqual((view as AnyObject).value(forKey: "layoutCount") as? Int, 1)
        XCTAssertEqual(asView?.sizeThatFits(.zero), CGSize(width: 77, height: 33))
        // Swift-only (final) API on the same instance.
        XCTAssertTrue(asView?._responderChain.first === asView)
        XCTAssertTrue(asView?.traitCollection is UITraitCollection)
    }

    @MainActor
    func testSwiftSubclassStillOverrides() {
        final class SwiftView: UIView {
            var log: [String] = []
            override init(frame: CGRect) {
                super.init(frame: frame)
                log.append("init(frame:) \(frame.size.width)")
            }
            required init?(coder: NSCoder) { fatalError() }
            override func layoutSubviews() {
                super.layoutSubviews()
                log.append("layoutSubviews")
            }
            override func sizeThatFits(_ size: CGSize) -> CGSize { CGSize(width: 12, height: 34) }
        }
        // -init from Objective-C (and UIView() from Swift) goes through the
        // `initWithFrame:` message, so the Swift override runs.
        let viaInit = SwiftView()
        XCTAssertEqual(viaInit.log, ["init(frame:) 0.0"])
        let v = SwiftView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        v.layoutIfNeeded()
        v.layoutIfNeeded()
        v.sizeToFit()
        XCTAssertEqual(v.log, ["init(frame:) 20.0", "layoutSubviews"])
        XCTAssertEqual(v.bounds.size, CGSize(width: 12, height: 34))
        // Objective-C sees the Swift override through the runtime.
        let imp = class_getMethodImplementation(SwiftView.self, NSSelectorFromString("layoutSubviews"))
        XCTAssertNotEqual(imp, class_getMethodImplementation(UIView.self, NSSelectorFromString("layoutSubviews")))
    }

    /// The structural rule. A class listed here may be subclassed from
    /// Objective-C only while it introduces no Swift vtable slot except the
    /// allowlisted ones, whose OpenUIKit call sites go through a
    /// `_hasSwiftVTable` guard (ObjCSubclassing.swift).
    func testChainClassesIntroduceNoSwiftVTableSlots() {
        // Members whose signature cannot be Objective-C (Swift protocols,
        // Swift option sets, non-NSObject classes) and that apps override,
        // so they stay `open` Swift members. Each OpenUIKit call site goes
        // through a `_…Dispatch` helper (ObjCSubclassing.swift).
        let allowed: [String: Set<String>] = [
            "UIResponder": ["buildMenu"],
            "UIViewController": [
                "supportedInterfaceOrientations",
                "preferredContentSizeDidChange",
                "systemLayoutFittingSizeDidChange",
                "C4size", // size(forChildContentContainer:withParentContainerSize:)
                "viewWillTransition",
                "willTransition",
                "popoverPresentation", // popoverPresentationController (mangled with a substitution)
                "transitionCoordinator",
            ],
        ]
        let chain: [(String, AnyClass)] = [
            ("UIResponder", UIResponder.self),
            ("UIView", UIView.self),
            ("UIControl", UIControl.self),
            ("UIScrollView", UIScrollView.self),
            ("UITableView", UITableView.self),
            ("UITextView", UITextView.self),
            ("UITextField", UITextField.self),
            ("UITableViewCell", UITableViewCell.self),
            ("UIViewController", UIViewController.self),
            ("UINavigationController", UINavigationController.self),
            ("UITableViewController", UITableViewController.self),
        ]
        for (name, cls) in chain {
            let entries = introducedVTableEntries(cls)
            let unexpected = entries.filter { sym in
                !(allowed[name] ?? []).contains { sym.contains($0) }
            }
            XCTAssertEqual(unexpected, [], "\(name) introduces Swift vtable slots")
            for member in allowed[name] ?? [] {
                XCTAssertEqual(entries.filter { $0.contains(member) }.count, 1,
                               "\(name).\(member): exactly one slot (a getter-only property or a method)")
            }
        }
    }

    /// Every chain class carries UIKit's Objective-C class name, so NIBs and
    /// NSClassFromString find it, and so its header entry is subclassable.
    func testChainClassesUseUIKitRuntimeNames() {
        let chain: [(String, AnyClass)] = [
            ("UIResponder", UIResponder.self), ("UIView", UIView.self), ("UIControl", UIControl.self),
            ("UIScrollView", UIScrollView.self), ("UITableView", UITableView.self),
            ("UITextView", UITextView.self), ("UITextField", UITextField.self),
            ("UITableViewCell", UITableViewCell.self), ("UIViewController", UIViewController.self),
            ("UINavigationController", UINavigationController.self),
            ("UITableViewController", UITableViewController.self),
        ]
        for (name, cls) in chain {
            XCTAssertEqual(NSStringFromClass(cls), name)
            XCTAssertTrue(NSClassFromString(name) === cls, name)
        }
    }

    /// A bridge twin (OpenUIKitObjCBridge category) with the same selector as
    /// a class's own `@objc` member would REPLACE it at runtime and turn the
    /// Swift-side message send into recursion. Categories show up as
    /// duplicate selectors in class_copyMethodList.
    func testNoSelectorIsImplementedTwice() {
        let classes: [AnyClass] = [UIResponder.self, UIView.self, UIControl.self, UIScrollView.self,
                                   UITableView.self, UITextView.self, UITextField.self,
                                   UITableViewCell.self, UIViewController.self,
                                   UINavigationController.self, UITableViewController.self]
        for cls: AnyClass in classes {
            var count: UInt32 = 0
            guard let list = class_copyMethodList(cls, &count) else { continue }
            defer { free(list) }
            var seen: [String: Int] = [:]
            for i in 0..<Int(count) { seen[NSStringFromSelector(method_getName(list[i])), default: 0] += 1 }
            let dupes = seen.filter { $0.value > 1 }.keys.sorted()
            XCTAssertEqual(dupes, [], "\(cls): selectors implemented twice")
        }
    }
}
#endif
