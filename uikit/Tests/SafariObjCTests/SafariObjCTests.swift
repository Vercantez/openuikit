// SFSafariViewController from Objective-C (docs/agent_reports/safari-objc.md).
//
// Before this change NetNewsWire's SFSafariViewController+Extras.h/.m failed
// (7 errors on the iOS triple): `@import SafariServices;` exported neither
// Foundation (NS_ASSUME_NONNULL_BEGIN, nil, NSException unknown) nor
// `-initWithURL:`, and the Swift calls of the category
// (`SFSafariViewController.safeSafariViewController(url)`,
// WebViewController.swift:935, MainFeedCollectionViewController.swift:678)
// failed with it. The fixture below is the same .m the iOS 26.1 simulator ran
// for Tools/oracle2/safariobjcprobe/transcript-ios26.1.txt.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
import OpenUIKit
import SafariServices
import OpenUIKitSafariFixtures

private func oracle() throws -> [String] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/safariobjcprobe/transcript-ios26.1.txt")
    return try String(contentsOf: url, encoding: .utf8)
        .split(separator: "\n").map(String.init).filter { !$0.hasPrefix("#") }
}

private final class Lines { var all: [String] = [] }

final class SafariObjCTests: XCTestCase {
    @MainActor
    func testObjectiveCScenarioMatchesIOS26_1() throws {
        let box = Lines()
        OUKSafariScenario({ line, context in
            Unmanaged<Lines>.fromOpaque(context!).takeUnretainedValue().all.append(String(cString: line))
        }, Unmanaged.passUnretained(box).toOpaque())
        let expected = try oracle()
        for (i, (a, b)) in zip(box.all, expected).enumerated() {
            XCTAssertEqual(a, b, "line \(i + 1)")
        }
        XCTAssertEqual(box.all.count, expected.count, box.all.joined(separator: "\n"))
    }

    /// NetNewsWire's Swift call of its Objective-C category: the category's
    /// class method is on the Swift class, and returns it.
    @MainActor
    func testSwiftSeesTheCategoryOnTheSwiftClass() {
        let vc: SFSafariViewController? =
            SFSafariViewController.ouk_safeSafariViewController(URL(string: "https://netnewswire.com/")!)
        XCTAssertNotNil(vc)
        XCTAssertNil(SFSafariViewController.ouk_safeSafariViewController(URL(string: "mailto:a@b.c")!))
        vc?.modalPresentationStyle = .overFullScreen
        XCTAssertEqual(vc?.modalPresentationStyle, .overFullScreen)
    }

    /// Every method the Clang module declares is implemented by the Swift
    /// class (the header is a restatement of the generated one).
    func testDeclaredSelectorsExist() {
        for sel in ["initWithURL:", "initWithURL:configuration:", "configuration",
                    "dismissButtonStyle", "setDismissButtonStyle:"] {
            XCTAssertTrue(class_getInstanceMethod(SFSafariViewController.self, NSSelectorFromString(sel)) != nil, sel)
        }
        for sel in ["entersReaderIfAvailable", "setEntersReaderIfAvailable:", "barCollapsingEnabled",
                    "setBarCollapsingEnabled:", "init"] {
            XCTAssertTrue(class_getInstanceMethod(SFSafariViewController.Configuration.self,
                                                  NSSelectorFromString(sel)) != nil, sel)
        }
        XCTAssertEqual(NSStringFromClass(SFSafariViewController.Configuration.self), "SFSafariViewControllerConfiguration")
    }
}
#endif
