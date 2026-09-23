// The second set of UIKit delegate protocols as @objc protocols
// (objc-protocols.md pattern). The shared Objective-C scenario
// Tools/oracle2/objcprotocolprobe2/scenario/OUKProtocols2Scenario.m ran inside
// a real iOS 26.1 simulator app (transcript-ios26.1.txt); here the same .m
// runs against OpenUIKit for each converted protocol and the lines are
// compared. The "## shapes" section (SDK name, required/optional, selector of
// every protocol method on iOS) is checked against the protocols OpenUIKit
// now exports: every selector OpenUIKit declares must be the SDK's, with the
// SDK's required/optional split.
#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitObjCProtocols2Fixtures

private func oracle() throws -> [String: [String]] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Tools/oracle2/objcprotocolprobe2/transcript-ios26.1.txt")
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
final class ObjCProtocols2Tests: XCTestCase {
    /// The protocols converted so far (the scenario compiles only these
    /// sections under OpenUIKit).
    static let converted: [(section: String, protocols: [String])] = [
        ("textfield", ["UITextFieldDelegate"]),
        ("picker", ["UIPickerViewDataSource", "UIPickerViewDelegate"]),
        ("searchbar", ["UISearchBarDelegate"]),
        ("", ["UISearchControllerDelegate", "UITabBarDelegate", "UIGestureRecognizerDelegate"]),
    ]

    private var savedCut: FontEngine.SystemFontCut = .macOS
    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
    }
    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    private func host() -> (UIWindow, UIView) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let vc = UIViewController()
        w.rootViewController = vc
        w.makeKeyAndVisible()
        return (w, vc.view)
    }

    func testConvertedSectionsMatchiOS() throws {
        let expected = try oracle()
        for (section, _) in Self.converted where !section.isEmpty {
            let (window, view) = host()
            let box = Lines()
            OUKProtocols2Run(section, Unmanaged.passUnretained(view).toOpaque(), { line, context in
                Unmanaged<Lines>.fromOpaque(context!).takeUnretainedValue().all.append(String(cString: line!))
            }, Unmanaged.passUnretained(box).toOpaque())
            XCTAssertEqual(box.all, expected[section] ?? ["<missing>"], "## \(section)")
            _ = window
        }
    }

    func testProtocolShapesAreTheSDKs() throws {
        let shapes = try oracle()["shapes"] ?? []
        for (_, protocols) in Self.converted {
            for name in protocols {
                let sdk = Set(shapes.filter { $0.hasPrefix(name + " ") })
                guard let proto = objc_getProtocol(name) else { return XCTFail("no protocol \(name)") }
                var ours: Set<String> = []
                for required in [true, false] {
                    var n: UInt32 = 0
                    guard let list = protocol_copyMethodDescriptionList(proto, required, true, &n) else { continue }
                    for i in 0..<Int(n) {
                        ours.insert("\(name) \(required ? "required" : "optional") \(NSStringFromSelector(list[i].name!))")
                    }
                    free(list)
                }
                XCTAssertFalse(ours.isEmpty, name)
                XCTAssertEqual(ours.subtracting(sdk), [], "\(name): not the SDK's")
            }
        }
    }
}
#endif
