// The UIKit Objective-C selectors Eidolon's CocoaPods send (FLKAutoLayout,
// ORStackView, Artsy+UILabels, Artsy-UIButtons, SDWebImage,
// NJKWebViewProgress, XNGMarkdownParser), run through the shared scenario
// Tools/oracle2/podsurfaceprobe/scenario/OUKPodSurfaceScenario.m and compared
// line for line with what the same .m printed against Apple's UIKit on the
// iOS 26.1 simulator (transcript-ios26.1.txt). Before this change the
// scenario did not compile against OpenUIKit (e.g. "property
// 'translatesAutoresizingMaskIntoConstraints' not found on object of type
// 'UIView *'", "use of undeclared identifier 'NSUnderlineStyleAttributeName'").
#if canImport(ObjectiveC)
import Foundation
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitPodSurfaceFixtures

private func oracle() throws -> [String: [String]] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/podsurfaceprobe/transcript-ios26.1.txt")
    var sections: [String: [String]] = [:]
    var current: String?
    for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init) {
        if line.hasPrefix("## ") { current = String(line.dropFirst(3)); sections[current!] = []; continue }
        if let current, !line.isEmpty { sections[current]!.append(line) }
    }
    return sections
}

private final class Lines { var all: [String] = [] }

@MainActor
final class PodSurfaceTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut = .macOS

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        // The oracle is a bare process: no application delegate.
        savedDelegate = UIApplication.shared.delegate
        UIApplication.shared.delegate = nil
    }

    private var savedDelegate: UIApplicationDelegate?

    override func tearDown() {
        UIApplication.shared.delegate = savedDelegate
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    /// UIControl.State is the C UIControlState (UIControl.h raw values), so
    /// Swift hands it straight to an Objective-C pod API typed UIControlState.
    /// Before the unification this did not compile (two option sets).
    func testUIControlStateIsTheObjectiveCType() {
        XCTAssertEqual(OUKPodSurfaceStateRawValue(.normal), 0)
        XCTAssertEqual(OUKPodSurfaceStateRawValue([.highlighted, .selected]), 0b101)
        XCTAssertEqual(OUKPodSurfaceStateRawValue(.disabled), 2)
        XCTAssertEqual(UIControl.State.focused.rawValue, 8)
        XCTAssertEqual(UIControl.State.application.rawValue, 0x00FF_0000)
    }

    func testEverySectionMatchesiOS() throws {
        let expected = try oracle()
        var compared = 0
        while let cName = OUKPodSurfaceSection(Int32(compared)) {
            let section = String(cString: cName)
            let box = Lines()
            OUKPodSurfaceRun(cName, { line, context in
                Unmanaged<Lines>.fromOpaque(context!).takeUnretainedValue().all.append(String(cString: line!))
            }, Unmanaged.passUnretained(box).toOpaque())
            XCTAssertEqual(box.all, expected[section] ?? ["<missing section>"], "## \(section)")
            compared += 1
        }
        XCTAssertEqual(compared, expected.count)
    }
}
#endif
