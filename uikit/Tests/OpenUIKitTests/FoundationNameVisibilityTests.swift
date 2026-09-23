// Names OpenUIKit shares with Foundation must be visible ONCE on Apple
// toolchains. When the same type is reachable under two declarations (a
// re-declared typealias), Swift stops folding the collection-literal sugar
// `[String: NSAttributedString]()` into a type and type-checks it as a
// dictionary literal of metatypes instead — "cannot call value of non-function
// type '[AnyHashable : NSAttributedString.Type]'" (NetNewsWire
// ArticleStringFormatter.swift:20, NSAttributedString+Extensions.swift:152,
// :300). This file compiling is the test; the assertions pin the values.
#if canImport(ObjectiveC) && canImport(Foundation)
import Foundation
import UIKit
import XCTest

@MainActor
final class FoundationNameVisibilityTests: XCTestCase {
    func testCollectionSugarOverSharedFoundationNames() {
        var titles = [String: NSAttributedString]()
        var mutable = [String: NSMutableAttributedString]()
        var ranges = [(range: NSRange, depth: Int)]()
        var attributes = [NSAttributedString.Key: Any]()
        titles["a"] = NSAttributedString(string: "a")
        mutable["b"] = NSMutableAttributedString(string: "b")
        ranges.append((range: NSRange(location: 1, length: 2), depth: 0))
        attributes[.font] = UIFont.systemFont(ofSize: 12)
        XCTAssertEqual(titles["a"]?.string, "a")
        XCTAssertEqual(mutable["b"]?.string, "b")
        XCTAssertEqual(ranges.first?.range.length, 2)
        XCTAssertEqual(attributes.count, 1)
    }

    func testAttributedStringFromNSAttributedStringIsFoundationsInitializer() {
        // One candidate (Foundation's) where NSAttributedString is Foundation's
        // class (NetNewsWire ActivityLogView.swift:103).
        let converted = AttributedString(NSAttributedString(string: "log line"))
        XCTAssertEqual(String(converted.characters), "log line")
    }

    func testActivityTypeRawValueInitializer() {
        let type = UIActivity.ActivityType(rawValue: "com.ranchero.NetNewsWire.find")
        XCTAssertEqual(type.rawValue, "com.ranchero.NetNewsWire.find")
        XCTAssertEqual(type, UIActivity.ActivityType("com.ranchero.NetNewsWire.find"))
    }
}
#endif
