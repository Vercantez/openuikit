// Objective-C UICollectionViewFlowLayout subclasses (eidolon-flowlayout).
//
// Eidolon's first screen is laid out by ARCollectionViewMasonryLayout 2.0.0,
// an Objective-C `UICollectionViewFlowLayout` subclass. The shared scenario
// (Tools/oracle2/flowlayoutprobe/scenario/OUKFlowLayoutScenario.m) drives a
// layout shaped like it — overriding prepareLayout,
// layoutAttributesForElementsInRect:, collectionViewContentSize,
// shouldInvalidateLayoutForBoundsChange: and invalidateLayout — in a
// collection view in a window, and records which overrides UIKit sends, in
// what order, and the cell frames that result. The iOS 26.1 simulator's
// answer is Tools/oracle2/flowlayoutprobe/transcript-ios26.1.txt; this test
// runs the same .m against OpenUIKit and compares section by section.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitFlowLayoutFixtures

/// The oracle trace split at its "-- N title" markers.
private func sections(_ lines: [String]) -> [(String, [String])] {
    var out: [(String, [String])] = []
    for line in lines {
        if line.hasPrefix("-- ") { out.append((line, [])); continue }
        if out.isEmpty { out.append(("", [])) }
        out[out.count - 1].1.append(line)
    }
    return out
}

private func oracleTrace() throws -> [String] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/flowlayoutprobe/transcript-ios26.1.txt")
    let text = try String(contentsOf: url, encoding: .utf8)
    var out: [String] = []
    var inTrace = false
    for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
        if line.hasPrefix("## ") { inTrace = line == "## trace"; continue }
        if inTrace && !line.isEmpty { out.append(line) }
    }
    return out
}

final class FlowLayoutObjCTests: XCTestCase {
    /// Sections whose OpenUIKit trace is known to differ from iOS 26.1, with
    /// the reason. Each is still compared (XCTExpectFailure), so fixing one
    /// fails here until it is removed from the list.
    static let open: [String: String] = [:]

    @MainActor
    func testMasonryShapedFlowLayoutSubclassMatchesIOS26_1() throws {
        let expected = sections(try oracleTrace())
        XCTAssertFalse(expected.isEmpty, "oracle transcript missing")
        let ours = sections(OUKRunFlowLayoutScenario())
        XCTAssertEqual(ours.map(\.0), expected.map(\.0), "section markers")
        for ((title, lines), (_, want)) in zip(ours, expected) {
            let check = {
                XCTAssertEqual(lines, want, "\(title)\nours:\n\(lines.joined(separator: "\n"))")
            }
            if let reason = Self.open[title] {
                XCTExpectFailure("open: \(reason)", strict: true) { check() }
            } else {
                check()
            }
        }
    }
}
#endif
