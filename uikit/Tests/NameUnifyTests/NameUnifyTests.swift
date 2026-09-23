// Collection sugar for every name OpenUIKit shares with Foundation or the
// Objective-C runtime (docs/agent_reports/sugar-unify.md).
//
// A second declaration of a name, even a typealias of the very same type,
// stops Swift folding `[X]()` / `[K: X]()` into a type where both are
// visible: "cannot call value of non-function type '[X.Type]'" (MEASURED,
// two-module scratch experiment and this file before the change). App files
// import UIKit together with Foundation, so each name here must reach them
// through ONE declaration: OpenUIKit re-exports the Apple declaration instead
// of re-declaring it, and the UIKit shim adds no alias of its own.
// CoreGraphics / QuartzCore names are cg-unify's (agent/cg-unify-p4).
#if canImport(Darwin)
import Foundation
import UIKit
import XCTest

final class NameUnifyTests: XCTestCase {
    func testFoundationNamesFoldCollectionSugar() {
        var paths = [IndexPath](); var sets = [String: IndexSet]()
        var ranges = [NSRange](); var intervals = [TimeInterval]()
        var pointers = [NSRangePointer]()
        var coders = [NSCoder](); var bundles = [String: Bundle]()
        var nsPaths = [NSIndexPath]()
        var notes = [Notification](); var nsNotes = [NSNotification]()
        var centers = [NotificationCenter](); var queues = [OperationQueue]()
        var strings = [NSAttributedString](); var mutable = [String: NSMutableAttributedString]()
        var timers = [Timer](); var loops = [RunLoop]()
        paths.removeAll(); sets.removeAll(); ranges.removeAll(); intervals.removeAll()
        pointers.removeAll(); coders.removeAll(); bundles.removeAll(); nsPaths.removeAll()
        notes.removeAll(); nsNotes.removeAll(); centers.removeAll(); queues.removeAll()
        strings.removeAll(); mutable.removeAll(); timers.removeAll(); loops.removeAll()
        XCTAssertTrue(paths.isEmpty && notes.isEmpty && strings.isEmpty && timers.isEmpty)
    }

    func testSelectorFoldsCollectionSugar() {
        var selectors = [Selector](); var byName = [String: Selector]()
        selectors.removeAll(); byName.removeAll()
        XCTAssertTrue(selectors.isEmpty && byName.isEmpty)
    }

    /// The names are still the Apple types, whichever module spells them.
    func testNamesAreTheAppleTypes() {
        XCTAssertTrue(OpenUIKit.IndexPath.self == Foundation.IndexPath.self)
        XCTAssertTrue(OpenUIKit.NSCoder.self == Foundation.NSCoder.self)
        XCTAssertTrue(OpenUIKit.Notification.self == Foundation.Notification.self)
        XCTAssertTrue(OpenUIKit.NotificationCenter.self == Foundation.NotificationCenter.self)
        XCTAssertTrue(OpenUIKit.OperationQueue.self == Foundation.OperationQueue.self)
        XCTAssertTrue(OpenUIKit.Selector.self == ObjectiveC.Selector.self)
        XCTAssertTrue(OpenUIKit.NSAttributedString.self == Foundation.NSAttributedString.self)
        XCTAssertTrue(UIKit.Notification.self == Foundation.Notification.self)
    }

    /// No client-visible typealias re-declares a Foundation / Objective-C
    /// name: a future `public typealias X = Foundation.X` (or an alias named
    /// after an Objective-C class) in OpenUIKit or the UIKit shim fails here.
    /// Only the branches live on a Darwin build with Foundation count; the
    /// Foundation-hidden and Linux branches keep their own declarations.
    func testNoClientVisibleAliasOfAFoundationName() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        var offenders: [String] = []
        for module in ["OpenUIKit", "UIKitShim"] {
            let root = sources.appendingPathComponent(module)
            let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
            while let url = files?.nextObject() as? URL {
                guard url.pathExtension == "swift" else { continue }
                let text = try String(contentsOf: url, encoding: .utf8)
                for hit in AliasScanner.offendingAliases(in: text) {
                    offenders.append("\(module)/\(url.lastPathComponent):\(hit)")
                }
            }
        }
        XCTAssertEqual(offenders, [], "re-export the Apple declaration instead "
                       + "(`@_exported import <kind> Foundation.X`, one per file that uses it)")
    }

    func testScannerFlagsAnAliasAndSkipsDeadBranches() {
        let text = """
        public typealias NSRangePointer = Foundation.NSRangePointer
        #if !canImport(Foundation)
        public typealias Timer = _HostClockTimer
        #else
        public typealias NSNotification = _Box
        #endif
        #if os(Linux)
        public typealias Bundle = _Bundle
        #endif
        public typealias UIViewAlias = UIView
            public typealias Style = UIActivityIndicatorViewStyle
        """
        XCTAssertEqual(AliasScanner.offendingAliases(in: text).map { $0.name },
                       ["NSRangePointer", "NSNotification"])
    }
}

/// Finds top-level `public`/`open` typealiases that re-declare a Foundation or
/// Objective-C name, in `#if` branches that can be live on Darwin + Foundation.
enum AliasScanner {
    struct Hit: Equatable, CustomStringConvertible {
        let line: Int; let name: String
        var description: String { "\(line): \(name)" }
    }

    static let appleModules = ["Foundation", "FoundationEssentials", "ObjectiveC",
                               "CoreFoundation", "Dispatch", "Darwin"]
    /// Unified value-type / typealias names (not visible to NSClassFromString).
    static let unifiedNames: Set<String> = ["IndexPath", "IndexSet", "NSRange", "NSRangePointer",
                                            "TimeInterval", "Notification", "Selector"]

    static func offendingAliases(in text: String) -> [Hit] {
        var hits: [Hit] = []
        var stack: [(taken: Tri, current: Tri)] = []   // per #if: any-branch-live, this-branch-live
        for (index, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("#if ") {
                let c = Condition.evaluate(String(line.dropFirst(4)))
                stack.append((c, c))
            } else if line.hasPrefix("#elseif "), let top = stack.popLast() {
                let c = Condition.evaluate(String(line.dropFirst(8)))
                let live = top.taken.not.and(c)
                stack.append((top.taken.or(c), live))
            } else if line == "#else" || line.hasPrefix("#else "), let top = stack.popLast() {
                stack.append((.yes, top.taken.not))
            } else if line.hasPrefix("#endif") {
                _ = stack.popLast()
            } else if raw.hasPrefix("public typealias ") || raw.hasPrefix("open typealias ") {
                guard stack.allSatisfy({ $0.current != .no }) else { continue }
                let rest = line.split(separator: " ", maxSplits: 2)[2]
                let parts = rest.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let name = String(parts[0].trimmingCharacters(in: .whitespaces)
                    .prefix { $0.isLetter || $0.isNumber || $0 == "_" })
                let target = parts[1].trimmingCharacters(in: .whitespaces)
                let qualifiedApple = appleModules.contains { target.hasPrefix($0 + ".") }
                let objcClassName = isSystemClass(name)
                if qualifiedApple || objcClassName || unifiedNames.contains(name) {
                    hits.append(Hit(line: index + 1, name: name))
                }
            }
        }
        return hits
    }

    /// An Objective-C class from Foundation, CoreFoundation or the runtime
    /// itself (OpenUIKit's own `@objc(UIView)` etc. are registered too, but
    /// from this package's image; AppKit / UIFoundation names are not ours).
    static func isSystemClass(_ name: String) -> Bool {
        guard let cls = NSClassFromString(name), let image = class_getImageName(cls) else { return false }
        let path = String(cString: image)
        return path.contains("/Foundation.framework/") || path.contains("/CoreFoundation.framework/")
            || path.contains("libobjc")
    }
}

/// Three-valued `#if` logic for a Darwin build that has Foundation. Atoms it
/// cannot decide (os(iOS) vs os(macOS), compiler flags) are `.maybe`.
enum Tri: Equatable {
    case yes, no, maybe
    var not: Tri { self == .yes ? .no : self == .no ? .yes : .maybe }
    func and(_ o: Tri) -> Tri { self == .no || o == .no ? .no : self == .yes && o == .yes ? .yes : .maybe }
    func or(_ o: Tri) -> Tri { self == .yes || o == .yes ? .yes : self == .no && o == .no ? .no : .maybe }
}

enum Condition {
    static let present: Set<String> = ["Foundation", "ObjectiveC", "Darwin", "Dispatch",
                                       "CoreFoundation", "CoreGraphics", "QuartzCore"]
    static let absentOS: Set<String> = ["Linux", "Windows", "Android", "WASI", "FreeBSD", "OpenBSD"]

    static func evaluate(_ source: String) -> Tri {
        var tokens = tokenize(source)[...]
        return parseOr(&tokens)
    }

    private static func tokenize(_ s: String) -> [String] {
        var out: [String] = []; var word = ""; var chars = Array(s)[...]
        func flush() { if !word.isEmpty { out.append(word); word = "" } }
        while let c = chars.popFirst() {
            if c == "/" && chars.first == "/" { break }
            if c.isLetter || c.isNumber || c == "_" || c == "." { word.append(c); continue }
            flush()
            if (c == "&" || c == "|"), chars.first == c { chars.removeFirst(); out.append(String([c, c])) }
            else if "()!,<>=".contains(c) { out.append(String(c)) }
        }
        flush()
        return out
    }

    private static func parseOr(_ t: inout ArraySlice<String>) -> Tri {
        var v = parseAnd(&t)
        while t.first == "||" { t.removeFirst(); v = v.or(parseAnd(&t)) }
        return v
    }

    private static func parseAnd(_ t: inout ArraySlice<String>) -> Tri {
        var v = parseUnary(&t)
        while t.first == "&&" { t.removeFirst(); v = v.and(parseUnary(&t)) }
        return v
    }

    private static func parseUnary(_ t: inout ArraySlice<String>) -> Tri {
        guard let head = t.popFirst() else { return .maybe }
        if head == "!" { return parseUnary(&t).not }
        if head == "(" { let v = parseOr(&t); if t.first == ")" { t.removeFirst() }; return v }
        if head == "true" { return .yes }
        if head == "false" { return .no }
        guard t.first == "(" else { return .maybe }        // compilation flag
        t.removeFirst()
        var args: [String] = []; var depth = 1
        while let x = t.popFirst() {
            if x == "(" { depth += 1 } else if x == ")" { depth -= 1; if depth == 0 { break } }
            args.append(x)
        }
        let arg = args.first ?? ""
        switch head {
        case "canImport": return present.contains(arg) ? .yes : .maybe
        case "os": return absentOS.contains(arg) ? .no : .maybe
        default: return .maybe
        }
    }
}
#endif
