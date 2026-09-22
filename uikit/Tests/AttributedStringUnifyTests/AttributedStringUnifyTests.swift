// With Foundation and the Objective-C runtime (the Apple toolchain), OpenUIKit's
// attributed strings ARE Foundation's and OpenUIKit.NSTextStorage is an Objective-C
// subclass of Foundation's NSMutableAttributedString
// (docs/agent_reports/attrstring-unify.md).
//
// Before: `OpenUIKit.NSAttributedString` was a separate Swift class. A file
// importing Foundation and UIKit saw two NSAttributedStrings (Kickstarter
// Library, 12 files), a `Formatter` override could not name the one Foundation
// uses, and `@interface X : NSTextStorage` had no interface to subclass
// (Simplenote's bridging header). This target did not compile.
//
// The traces are compared line for line with the iOS 26.1 simulator's
// (Tools/oracle2/textstorageprobe/transcript-ios26.1.txt), which ran the same
// Objective-C scenario against Apple's UIKit.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
import UIKit
@testable import OpenUIKit
import OpenUIKitTextStorageFixtures

private func transcript() throws -> String {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/textstorageprobe/transcript-ios26.1.txt")
    return try String(contentsOf: url, encoding: .utf8)
}

/// Lines of one "## name" section (sub-sections "### ..." stay in).
private func oracleSection(_ name: String) throws -> [String] {
    var out: [String] = []
    var inSection = false
    for line in try transcript().components(separatedBy: "\n") {
        if line.hasPrefix("## ") { inSection = (line == "## " + name); continue }
        if inSection && !line.isEmpty { out.append(line) }
    }
    return out
}

/// The scenario's trace printed the way main.m prints it, split into lines
/// (a run's string may contain "\n").
private func printed(_ trace: [String]) -> [String] {
    trace.map { $0.replacingOccurrences(of: "## ", with: "### ") }
        .joined(separator: "\n")
        .components(separatedBy: "\n")
        .filter { !$0.isEmpty }
}

/// The measured behaviour OpenUIKit does not reproduce: attribute FIXING.
/// iOS's NSTextStorage substitutes fonts (a default Helvetica 12 on runs
/// without NSFont, fallback fonts over characters the font lacks) and fixes
/// lazily as edits read attributes. OpenUIKit has no UIFont object to insert
/// and resolves fallback fonts at layout time, so its fixAttributes(in:) does
/// nothing. The observable consequences, and nothing else, are tolerated:
///  (1) in the base NSTextStorage blocks, iOS's mask may carry an extra
///      `attr` bit (the fix's own setAttributes: during processEditing, or a
///      lazy fix inside begin/endEditing; the transcript's "### edit masks
///      with and without a covering font" shows the lazy one happens even
///      when the font covers every character, so it is not modelled);
///  (2) the backing-store subclass sees one more `prim setAttributes:` right
///      after `sub fixAttributesInRange:` (the fix writing NSFont back).
/// NSFont values themselves are not printed by the scenario.
private let lazyFixingBlocks: Set<String> = ["### base NSTextStorage", "### edit masks (base NSTextStorage)"]

private func withoutFixWrites(_ ios: [String]) -> [String] {
    var out: [String] = []
    var prevWasFix = false
    for line in ios {
        if prevWasFix, line.hasPrefix("  prim setAttributes:") { prevWasFix = false; continue }  // (2)
        prevWasFix = line.hasPrefix("  sub fixAttributesInRange:")
        out.append(line)
    }
    return out
}

/// Compares line by line; returns the lines accepted under divergence (1).
@discardableResult
private func assertLines(_ ours: [String], _ expected: [String], tolerateFixingBits: Bool = false,
                         file: StaticString = #filePath, line: UInt = #line) -> [String] {
    XCTAssertFalse(expected.isEmpty, "oracle transcript missing", file: file, line: line)
    var block = ""
    var tolerated: [String] = []
    for i in 0..<Swift.max(ours.count, expected.count) {
        let o = i < ours.count ? ours[i] : "<missing>"
        let e = i < expected.count ? expected[i] : "<missing>"
        if e.hasPrefix("### ") { block = e }
        if o == e { continue }
        if tolerateFixingBits, lazyFixingBlocks.contains(block),
           o.contains("mask=chars"),
           o.replacingOccurrences(of: "mask=chars", with: "mask=attr|chars") == e {
            tolerated.append(e)
            continue
        }
        XCTFail("line \(i + 1):\n  iOS 26.1:  \(e)\n  OpenUIKit: \(o)", file: file, line: line)
        return tolerated
    }
    return tolerated
}

// MARK: - Kickstarter's shape: Foundation API taking UIKit's NSAttributedString

/// Kickstarter Library NumberFormatter.swift:14 overrides Foundation's
/// Formatter method; before, OpenUIKit's NSAttributedString was a different
/// type and this was "method does not override".
private final class AttributedNumberFormatter: Formatter {
    override func string(for obj: Any?) -> String? { (obj as? Int).map(String.init) }
    override func attributedString(for obj: Any,
                                   withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil)
        -> NSAttributedString? {
        guard let s = string(for: obj) else { return nil }
        return NSAttributedString(string: s, attributes: [.font: UIFont.systemFont(ofSize: 12)])
    }
}

final class AttributedStringUnifyTests: XCTestCase {

    // MARK: Type identity

    func testUIKitAttributedStringTypesAreFoundations() {
        XCTAssertTrue(OpenUIKit.NSAttributedString.self == Foundation.NSAttributedString.self)
        XCTAssertTrue(OpenUIKit.NSMutableAttributedString.self == Foundation.NSMutableAttributedString.self)
        // Unqualified in a file importing Foundation and UIKit: one type.
        let s: NSAttributedString = Foundation.NSAttributedString(string: "x")
        let u: UIKit.NSAttributedString = s
        XCTAssertEqual(u.length, 1)
        XCTAssertEqual(NSAttributedString.Key.font.rawValue, "NSFont")
        XCTAssertEqual(NSAttributedString.Key.foregroundColor.rawValue, "NSColor")
        XCTAssertEqual(NSAttributedString.Key.attachment.rawValue, "NSAttachment")
    }

    func testFoundationFormatterOverrideTakesUIKitAttributedString() {
        let f: Formatter = AttributedNumberFormatter()
        let a = f.attributedString(for: 42, withDefaultAttributes: nil)
        XCTAssertEqual(a?.string, "42")
        XCTAssertEqual(a?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont,
                       UIFont.systemFont(ofSize: 12))
    }

    func testTextStorageSubclassesFoundationsMutableAttributedString() throws {
        let cls: AnyClass = OpenUIKit.NSTextStorage.self
        let superclass = try XCTUnwrap(class_getSuperclass(cls))
        XCTAssertTrue(superclass == Foundation.NSMutableAttributedString.self)
        let ts = OpenUIKit.NSTextStorage(string: "abc")
        XCTAssertTrue((ts as AnyObject) is Foundation.NSMutableAttributedString)
        // UITextView's storage is one, and is what attributedText reads.
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        tv.text = "abc"
        tv.textStorage.replaceCharacters(in: NSRange(location: 3, length: 0), with: "d")
        XCTAssertEqual(tv.text, "abcd")
        XCTAssertEqual(tv.attributedText?.length, 4)
    }

    /// The simplenote-objc-core rule: a class an Objective-C app subclasses
    /// must introduce no Swift vtable slot, except the four AppKit-typed
    /// initializers of the macOS host (NSTextStorage.swift), which OpenUIKit
    /// never calls.
    func testTextStorageIntroducesNoSwiftVTableSlot() {
        let metadata = unsafeBitCast(OpenUIKit.NSTextStorage.self as AnyClass, to: UnsafeRawPointer.self)
        let descriptor = metadata.load(fromByteOffset: 64, as: UnsafeRawPointer.self)
        let flags = descriptor.load(as: UInt32.self)
        let kindSpecific = flags >> 16
        var names: [String] = []
        if kindSpecific & 0x8000 != 0 {
            var offset = 44
            if kindSpecific & 0x2000 != 0 { offset += 4 }
            switch kindSpecific & 0x3 {
            case 1: offset += 12
            case 2: offset += 4
            default: break
            }
            let vtableSize = Int(descriptor.load(fromByteOffset: offset + 4, as: UInt32.self))
            for i in 0..<vtableSize {
                let entry = descriptor + offset + 8 + i * 8
                let rel = entry.load(fromByteOffset: 4, as: Int32.self)
                var info = Dl_info()
                if dladdr(entry + 4 + Int(rel), &info) != 0, let sym = info.dli_sname {
                    names.append(String(cString: sym))
                } else {
                    names.append("<unnamed slot \(i)>")
                }
            }
        }
#if canImport(AppKit)
        let allowed = ["pasteboardPropertyList", "html", "url", "data"]
        XCTAssertEqual(names.count, allowed.count, "\(names)")
        for n in names {
            XCTAssertTrue(allowed.contains { n.contains("C" + $0) || n.contains($0) }, n)
        }
#else
        XCTAssertEqual(names, [])
#endif
    }

    // MARK: iOS 26.1 traces

    func testAttributedStringTraceMatchesIOS26_1() throws {
        assertLines(printed(OUKRunAttributedStringScenarios()), try oracleSection("attributed"))
    }

    func testTextStorageTraceMatchesIOS26_1() throws {
        let expected = withoutFixWrites(try oracleSection("textstorage"))
        var ours = printed(OUKRunTextStorageScenarios())
#if canImport(AppKit)
        // The macOS host's runtime name (AppKit's NSTextStorage is loaded in
        // the same process; NSTextStorage.swift). The iOS triple uses UIKit's.
        ours = ours.map { $0.replacingOccurrences(of: "OUKTextStorage", with: "NSTextStorage") }
#endif
        let tolerated = assertLines(ours, expected,
                                    tolerateFixingBits: true)
        // The tolerance is narrow: print what it accepted, and pin the count.
        print("tolerated (attribute fixing):\n" + tolerated.joined(separator: "\n"))
        XCTAssertEqual(tolerated.count, 9, "\(tolerated)")
    }

    /// Oracle-only section "### layout manager ordering": notifications and
    /// delegate callbacks first, then the layout manager.
    @MainActor
    func testLayoutManagerProcessEditingOrderMatchesIOS26_1() throws {
        nonisolated final class LM: OpenUIKit.NSLayoutManager {
            var log: ((String) -> Void)?
            override func processEditing(for textStorage: OpenUIKit.NSTextStorage,
                                         edited editMask: OpenUIKit.NSTextStorage.EditActions,
                                         range newCharRange: NSRange,
                                         changeInLength delta: Int,
                                         invalidatedRange invalidatedCharRange: NSRange) {
                log?("  layoutManager processEditing mask=\(editMask.rawValue) range={\(newCharRange.location), \(newCharRange.length)} delta=\(delta) invalidated={\(invalidatedCharRange.location), \(invalidatedCharRange.length)}")
                super.processEditing(for: textStorage, edited: editMask, range: newCharRange,
                                     changeInLength: delta, invalidatedRange: invalidatedCharRange)
            }
        }
        nonisolated final class Delegate: NSObject, OpenUIKit.NSTextStorageDelegate {
            var log: ((String) -> Void)?
            func textStorage(_ ts: OpenUIKit.NSTextStorage, willProcessEditing m: OpenUIKit.NSTextStorage.EditActions,
                             range r: NSRange, changeInLength d: Int) {
                log?("  delegate will {\(r.location), \(r.length)}")
            }
            func textStorage(_ ts: OpenUIKit.NSTextStorage, didProcessEditing m: OpenUIKit.NSTextStorage.EditActions,
                             range r: NSRange, changeInLength d: Int) {
                log?("  delegate did {\(r.location), \(r.length)}")
            }
        }
        var lines: [String] = []
        let ts = OpenUIKit.NSTextStorage()
        let d = Delegate()
        d.log = { lines.append($0) }
        ts.delegate = d
        let lm = LM()
        lm.log = { lines.append($0) }
        lm.addTextContainer(OpenUIKit.NSTextContainer(size: CGSize(width: 200, height: 1000)))
        ts.addLayoutManager(lm)
        lines.append("after addLayoutManager: layoutManagers=\(ts.layoutManagers.count) lm.textStorage==ts \(lm.textStorage === ts ? 1 : 0)")
        let nc = NotificationCenter.default
        let w = nc.addObserver(forName: OpenUIKit.NSTextStorage.willProcessEditingNotification, object: ts, queue: nil) { _ in lines.append("  note will") }
        let dd = nc.addObserver(forName: OpenUIKit.NSTextStorage.didProcessEditingNotification, object: ts, queue: nil) { _ in lines.append("  note did") }
        lines.append("replace {0,0} \"Hello\"")
        ts.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Hello")
        lines.append("addAttribute {1,2}")
        ts.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 1, length: 2))
        lines.append("removeLayoutManager")
        ts.removeLayoutManager(lm)
        lines.append("after removeLayoutManager: layoutManagers=\(ts.layoutManagers.count) lm.textStorage=\(lm.textStorage == nil ? "nil" : "set")")
        ts.replaceCharacters(in: NSRange(location: 0, length: 0), with: "X")
        nc.removeObserver(w)
        nc.removeObserver(dd)

        // iOS's base storage reports mask=3 for the first edit's layout
        // manager call because font fixing added `attr` (the documented
        // divergence); OpenUIKit reports the character edit alone (2).
        let oracle = try oracleSection("oracle-only")
        guard let start = oracle.firstIndex(of: "### layout manager ordering"),
              let end = oracle.firstIndex(of: "### UITextView") else {
            return XCTFail("oracle section missing")
        }
        let expected = oracle[(start + 1)..<end].map {
            $0.replacingOccurrences(of: "mask=3 range={0, 5} delta=5", with: "mask=2 range={0, 5} delta=5")
        }
        assertLines(lines, Array(expected))
    }

    // MARK: Objective-C subclass, driven from Swift

    func testObjectiveCSubclassIsANSTextStorage() {
        let obj = OUKMakeObjCTextStorage()
        let ts = obj as? OpenUIKit.NSTextStorage
        XCTAssertNotNil(ts)
        ts?.replaceCharacters(in: NSRange(location: 0, length: 0), with: "hi")
        XCTAssertEqual(ts?.string, "hi")
        XCTAssertEqual(ts?.fixesAttributesLazily, false)
        XCTAssertEqual(OpenUIKit.NSTextStorage().fixesAttributesLazily, true)
    }
}
#endif
