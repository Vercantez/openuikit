import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class UISplitViewWidthTests: XCTestCase {
    // Replay the real iOS state stream, not a duplicate of the resolver formula.
    // Each initial row creates a new split; later rows mutate that same split.
    func testMeasuredWidthAndAppearanceMatrix() throws {
        let oldCut = OpenUIKitRuntime.systemFontCut
        let oldTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
            displayScale: 2, horizontalSizeClass: .regular, userInterfaceIdiom: .pad)
        defer {
            OpenUIKitRuntime.systemFontCut = oldCut
            UITraitCollection.current = oldTraits
        }
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        var matched = 0, total = 0
        for profile in ["main", "boundary", "primary", "supplementary", "secondary", "resize"] {
            let data = try Data(contentsOf: root.appendingPathComponent("Tools/oracle2/splitwidthprobe/ios26.1-\(profile).json"))
            let document = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let samples = try XCTUnwrap(document["samples"] as? [[String: Any]])
            var split: UISplitViewController!
            var window: UIWindow!
            for row in samples {
                let phase = try XCTUnwrap(row["phase"] as? String)
                let requested = try XCTUnwrap(row["requestedMode"] as? Int)
                let width = try XCTUnwrap(row["boundsWidth"] as? Double)
                let mode = try XCTUnwrap(UISplitViewController.DisplayMode(rawValue: requested))
                if phase == "initial" {
                    split = UISplitViewController(style: .tripleColumn)
                    let minima = try XCTUnwrap(row["minima"] as? [Double])
                    split.minimumPrimaryColumnWidth = minima[0]
                    split.minimumSupplementaryColumnWidth = minima[1]
                    split.minimumSecondaryColumnWidth = minima[2]
                    for column in [UISplitViewController.Column.primary, .supplementary, .secondary] {
                        split.setViewController(UIViewController(), for: column)
                    }
                    split.preferredDisplayMode = mode
                    let host = UIViewController()
                    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
                    window.rootViewController = host
                    host.addChild(split)
                    host.view.addSubview(split.view)
                    split.view.frame = CGRect(x: 0, y: 0, width: width, height: 700)
                    split.didMove(toParent: host)
                    split.beginAppearanceTransition(true, animated: false)
                    split.endAppearanceTransition()
                } else if phase == "resized.immediate" || phase == "requested.resized.immediate" {
                    split.view.frame.size.width = width
                    split.view.setNeedsLayout()
                    split.view.layoutIfNeeded()
                } else if phase == "mounted.immediate" {
                    split.preferredDisplayMode = .secondaryOnly
                    split.preferredDisplayMode = mode
                    split.view.layoutIfNeeded()
                }
                let expected = try XCTUnwrap(row["displayMode"] as? Int)
                let behavior = try XCTUnwrap(row["splitBehavior"] as? Int)
                let matches = split.displayMode.rawValue == expected && split.splitBehavior.rawValue == behavior
                total += 1
                if matches { matched += 1 }
                XCTAssertEqual(split.displayMode.rawValue, expected, "\(profile) \(width) request=\(requested) \(phase)")
                XCTAssertEqual(split.splitBehavior.rawValue, behavior, "\(profile) \(width) request=\(requested) \(phase)")
                XCTAssertEqual(split.preferredDisplayMode, mode)
                XCTAssertFalse(split.isCollapsed)
                withExtendedLifetime(window) {}
            }
        }
        print("SPLIT_WIDTH_MATCHED \(matched)/\(total) mode-and-behavior observations")
    }
}
