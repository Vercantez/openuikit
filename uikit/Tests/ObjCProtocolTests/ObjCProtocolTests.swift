// UIKit's delegate / data-source protocols as `@objc` protocols with
// `optional` requirements on the Apple toolchain
// (docs/agent_reports/objc-protocols.md).
//
// Before this change they were Swift protocols with default implementations:
// Swift code that writes `dataSource.numberOfSections?(tableView)` or
// `delegate?.scrollViewDidScroll?(scrollView)` did not compile (NetNewsWire's
// RSCore and ImageScrollView), an `@objc protocol X: UIScrollViewDelegate`
// was rejected, and an Objective-C class could not adopt them. The scenario
// below is the same .m the iOS 26.1 simulator ran for
// Tools/oracle2/objcprotocolprobe/transcript-ios26.1.txt: Objective-C classes
// adopting the protocols with different subsets of the optional methods.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitObjCProtocolFixtures

private func oracleSection(_ name: String) throws -> [String] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/objcprotocolprobe/transcript-ios26.1.txt")
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

/// The oracle ran on an iPhone 16 (iOS cut, 3x); the scenario runs with the
/// same font cut and display scale, as the other iOS-measured tests do.
@MainActor
private func collect(_ scenario: (OUKProtocolSink?, UnsafeMutableRawPointer?) -> Void) -> [String] {
    let savedCut = OpenUIKitRuntime.systemFontCut
    let savedTraits = UITraitCollection.current
    OpenUIKitRuntime.systemFontCut = .iOS
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light, displayScale: 3)
    defer {
        OpenUIKitRuntime.systemFontCut = savedCut
        UITraitCollection.current = savedTraits
    }
    let box = Lines()
    scenario({ line, context in
        Unmanaged<Lines>.fromOpaque(context!).takeUnretainedValue().all.append(String(cString: line!))
    }, Unmanaged.passUnretained(box).toOpaque())
    return box.all
}

// NetNewsWire's shapes, verbatim (RSCore UITableView+RSCore.swift:18,
// UICollectionView+RSCore.swift:19, iOS/Article/ImageScrollView.swift:11-37).
@objc protocol ImageScrollViewDelegate: UIScrollViewDelegate {
    func imageScrollViewDidTapToDismiss()
}

@MainActor
private final class ImageScrollViewLike: UIScrollView, UIScrollViewDelegate {
    @objc weak var imageScrollViewDelegate: ImageScrollViewDelegate?
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        imageScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
}

@MainActor
private final class ForwardTarget: NSObject, ImageScrollViewDelegate {
    var scrolled = 0
    func imageScrollViewDidTapToDismiss() {}
    func scrollViewDidScroll(_ scrollView: UIScrollView) { scrolled += 1 }
}

@MainActor
private final class RequiredOnlySource: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell(style: .default, reuseIdentifier: nil)
    }
}

final class ObjCProtocolTests: XCTestCase {
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
    func testScrollScenarioMatchesIOS26_1() throws {
        try assertMatchesOracle("scroll", collect(OUKProtocolScrollScenario))
    }

    @MainActor
    func testTableScenarioMatchesIOS26_1() throws {
        try assertMatchesOracle("table", collect(OUKProtocolTableScenario))
    }

    /// UIKit's runtime names and SDK selectors, so one protocol serves an
    /// app's Swift and Objective-C halves.
    func testProtocolsCarryUIKitNamesAndSDKSelectors() {
        XCTAssertEqual(NSStringFromProtocol(UIScrollViewDelegate.self), "UIScrollViewDelegate")
        XCTAssertEqual(NSStringFromProtocol(UITableViewDataSource.self), "UITableViewDataSource")
        XCTAssertEqual(NSStringFromProtocol(UITableViewDelegate.self), "UITableViewDelegate")
        XCTAssertEqual(NSStringFromProtocol(UICollectionViewDataSource.self), "UICollectionViewDataSource")
        XCTAssertEqual(NSStringFromProtocol(UICollectionViewDelegate.self), "UICollectionViewDelegate")
        XCTAssertTrue(protocol_conformsToProtocol(UITableViewDelegate.self, UIScrollViewDelegate.self))
        func required(_ p: Protocol, _ sel: String, isRequired: Bool) -> Bool {
            protocol_getMethodDescription(p, NSSelectorFromString(sel), isRequired, true).name != nil
        }
        // The SDK's required/optional split (UITableView.h, UICollectionView.h).
        XCTAssertTrue(required(UITableViewDataSource.self, "tableView:numberOfRowsInSection:", isRequired: true))
        XCTAssertTrue(required(UITableViewDataSource.self, "tableView:cellForRowAtIndexPath:", isRequired: true))
        XCTAssertTrue(required(UITableViewDataSource.self, "numberOfSectionsInTableView:", isRequired: false))
        XCTAssertTrue(required(UITableViewDelegate.self, "tableView:heightForRowAtIndexPath:", isRequired: false))
        XCTAssertTrue(required(UITableViewDelegate.self, "tableView:editingStyleForRowAtIndexPath:", isRequired: false))
        XCTAssertTrue(required(UICollectionViewDataSource.self, "collectionView:cellForItemAtIndexPath:", isRequired: true))
        XCTAssertTrue(required(UICollectionViewDataSource.self, "numberOfSectionsInCollectionView:", isRequired: false))
        XCTAssertTrue(required(UIScrollViewDelegate.self, "viewForZoomingInScrollView:", isRequired: false))
        XCTAssertTrue(required(UIScrollViewDelegate.self, "scrollViewDidEndZooming:withView:atScale:", isRequired: false))
    }

    /// NetNewsWire's call shapes compile and behave: an optional requirement
    /// read as a function value, and forwarding through an @objc protocol that
    /// refines UIScrollViewDelegate.
    @MainActor
    func testNetNewsWireShapes() {
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), style: .plain)
        let source = RequiredOnlySource()
        table.dataSource = source
        let dataSource: UITableViewDataSource? = table.dataSource
        // RSCore UITableView+RSCore.swift:18: absent → nil.
        XCTAssertNil(dataSource?.numberOfSections)
        let scroll = ImageScrollViewLike(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        scroll.contentSize = CGSize(width: 50, height: 500)
        let target = ForwardTarget()
        scroll.imageScrollViewDelegate = target
        scroll.delegate = scroll
        scroll.contentOffset = CGPoint(x: 0, y: 20)
        XCTAssertEqual(target.scrolled, 1)
    }
}
#endif
