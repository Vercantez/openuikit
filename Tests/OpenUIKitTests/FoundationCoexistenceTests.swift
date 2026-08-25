// M15: `import Foundation` alongside `import OpenUIKit`.
//
// This file is the deliverable, not a description of it. It imports Foundation
// the way a real app's file does, uses UIKit and Foundation names side by side
// with NO disambiguating typealias anywhere, and asserts that the geometry the
// two modules exchange really is ONE type. Before M15 every test file in this
// directory carried four to six `private typealias CGRect = OpenUIKit.CGRect`
// lines; 151 of them are gone, and this file would not compile without the
// change (docs/APP_COMPAT.md "Foundation coexistence").
//
// The second half is the determinism guard: the library may import Foundation,
// but the render and layout path still must not read a wall clock, a locale or
// a random source, because byte-identical Linux renders depend on it
// (docs/PORTABILITY.md). That is enforced here by scanning the sources.

import XCTest
import Foundation
@testable import OpenUIKit

final class FoundationCoexistenceTests: XCTestCase {

    // MARK: - One type, not two

    /// The compile-time claim: `CGRect` names the SAME declaration whether you
    /// reached it through Foundation or through OpenUIKit.
    func testGeometryTypesAreFoundationsOwn() {
        XCTAssertTrue(OpenUIKit.CGRect.self == Foundation.CGRect.self)
        XCTAssertTrue(OpenUIKit.CGPoint.self == Foundation.CGPoint.self)
        XCTAssertTrue(OpenUIKit.CGSize.self == Foundation.CGSize.self)
        XCTAssertTrue(OpenUIKit.CGFloat.self == Foundation.CGFloat.self)
        XCTAssertTrue(OpenUIKit.IndexPath.self == Foundation.IndexPath.self)
        XCTAssertTrue(OpenUIKit.NSRange.self == Foundation.NSRange.self)
    }

    /// A rect built by Foundation-facing code goes straight into a UIView, and
    /// the rect that comes back out is usable as a Foundation value. This is
    /// the thing that used to be impossible.
    func testAFoundationRectRoundTripsThroughAView() {
        let coder = NSCoder.self          // the corpus's #1 collision (344 files)
        XCTAssertNotNil(coder)

        let frame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let view = UIView(frame: frame)
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(view.frame.insetBy(dx: 5, dy: 5),
                       CGRect(x: 15, y: 25, width: 90, height: 40))
        XCTAssertEqual(view.bounds.integral.width, 100)

        // NSValue is Foundation's; boxing a UIKit-produced rect must work.
        let boxed = NSValue(bytes: &view.frame.origin, objCType: "{CGPoint=dd}")
        XCTAssertNotNil(boxed)
    }

    /// `applying(_:)` is the one geometry member Foundation does not have, so
    /// OpenCoreGraphics adds it. Same numbers as before the switch.
    ///
    /// The `OpenUIKit.` qualification is the documented RESIDUE: Linux
    /// Foundation has no CGAffineTransform, so OpenUIKit keeps its own (one
    /// implementation for both platforms is what makes the rotation matrix
    /// byte-identical). On Darwin — the oracle platform only — Foundation
    /// re-exports CoreGraphics' and the two names collide. See
    /// Sources/OpenUIKit/FoundationTypes.swift.
    func testApplyingIsStillOurs() {
        let t = OpenUIKit.CGAffineTransform(translationX: 5, y: 7)
        XCTAssertEqual(CGPoint(x: 1, y: 2).applying(t), CGPoint(x: 6, y: 9))
        XCTAssertEqual(CGRect(x: 0, y: 0, width: 2, height: 2).applying(t),
                       CGRect(x: 5, y: 7, width: 2, height: 2))
        XCTAssertEqual(CGRect.null.applying(t), CGRect.null)
    }

    // MARK: - IndexPath: Foundation's storage, UIKit's spelling

    func testIndexPathIsFoundationsWithUIKitConveniences() {
        let ip = IndexPath(row: 3, section: 1)
        XCTAssertEqual(ip.count, 2)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 3)
        XCTAssertEqual(ip.section, 1)
        XCTAssertEqual(ip.row, 3)
        XCTAssertEqual(ip.item, 3, "UIKit spells the same slot `item` for collection views")
        XCTAssertEqual(IndexPath(item: 3, section: 1), ip)
        XCTAssertLessThan(IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1))
        XCTAssertLessThan(IndexPath(row: 9, section: 0), IndexPath(row: 0, section: 1))
    }

    /// A UIKit data source keyed by index path and a Foundation collection of
    /// index paths are now interchangeable.
    func testIndexPathCrossesTheModuleBoundary() {
        var byPath: [IndexPath: String] = [:]
        byPath[IndexPath(row: 0, section: 0)] = "a"
        let fromFoundation = IndexPath(indexes: [0, 0])
        XCTAssertEqual(byPath[fromFoundation], "a")
    }

    // MARK: - Determinism guard
    //
    // The library is allowed to import Foundation now. It is NOT allowed to
    // read a wall clock, a locale or a random source: openrender must produce
    // the same bytes on macOS and on Linux, from scripted timestamps only.

    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // OpenUIKitTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // repo root

    /// Symbols that would put non-determinism into the render or layout path.
    /// `Timer`'s own clock is `UIWindow.tick(timestamp:)`, which is why
    /// OpenUIKit keeps its own Timer instead of Foundation's (Timer.swift).
    private static let banned = [
        "Date(", "NSDate", "DateFormatter", "Calendar(", "Locale(",
        "gettimeofday", "clock_gettime", "mach_absolute_time",
        "CFAbsoluteTimeGetCurrent", "arc4random", "UUID(",
    ]

    func testRenderPathReadsNoWallClockLocaleOrRandomSource() throws {
        let fm = FileManager.default
        var offenders: [String] = []
        for module in ["Sources/OpenUIKit", "Sources/OpenCoreGraphics"] {
            let dir = Self.repoRoot.appendingPathComponent(module)
            guard let e = fm.enumerator(atPath: dir.path) else {
                return XCTFail("cannot enumerate \(module)")
            }
            for case let rel as String in e where rel.hasSuffix(".swift") {
                let path = dir.appendingPathComponent(rel)
                let text = try String(contentsOf: path, encoding: .utf8)
                for (n, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                    let line = rawLine.trimmingCharacters(in: .whitespaces)
                    // Comments are where these names get DISCUSSED; the rule
                    // is about code.
                    if line.hasPrefix("//") || line.hasPrefix("///") { continue }
                    for token in Self.banned where line.contains(token) {
                        offenders.append("\(module)/\(rel):\(n + 1): \(token) — \(line)")
                    }
                }
            }
        }
        XCTAssertEqual(offenders, [], """
            The render/layout path must stay deterministic — byte-identical \
            Linux renders depend on it (docs/PORTABILITY.md). Drive time \
            through UIWindow.tick(timestamp:) instead.
            """)
    }
}
