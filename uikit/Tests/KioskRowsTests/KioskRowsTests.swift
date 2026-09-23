// The UIKit rows Eidolon's Kiosk target and its remaining Objective-C pods
// need (docs/agent_reports/eidolon-kiosk.md), run through the shared scenario
// Tools/oracle2/kioskrowsprobe/scenario/OUKKioskRowsScenario.m and compared
// line for line with what the same .m printed against Apple's UIKit inside a
// UIApplicationMain app on the iOS 26.1 simulator (transcript-ios26.1.txt),
// plus the Swift spellings Kiosk uses (this target compiles in Swift 4 mode,
// as Kiosk does). Before this change the scenario did not compile against
// OpenUIKit ("property 'toolbar' not found on object of type
// 'UINavigationController *'", "use of undeclared identifier 'UIBezierPath'",
// "'init' is unavailable", …), and Kiosk's `isIdleTimerDisabled`,
// `preferredMaxLayoutWidth`, `setTitleShadowColor(_:for:)`,
// `clearsOnBeginEditing`, `scrollRangeToVisible(_:)`, NSObject
// `awakeFromNib` / `prepareForInterfaceBuilder` overrides and
// `self.init(title:message:preferredStyle:)` did not type-check.
#if canImport(ObjectiveC)
import Foundation
import XCTest
@testable import OpenUIKit
import OpenUIKitObjCBridge
import OpenUIKitKioskRowsFixtures

private let uikitRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

private func oracle() throws -> [String: [String]] {
    let url = uikitRoot.appendingPathComponent("Tools/oracle2/kioskrowsprobe/transcript-ios26.1.txt")
    var sections: [String: [String]] = [:]
    var current: String?
    for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init) {
        if line.hasPrefix("## ") { current = String(line.dropFirst(3)); sections[current!] = []; continue }
        if let current, !line.isEmpty { sections[current]!.append(line) }
    }
    return sections
}

private final class Lines { var all: [String] = [] }

// Kiosk's shapes, compiled in Swift 4 mode.
final class KioskCountdownManagerShape: NSObject {
    var awakened = 0
    override func awakeFromNib() {
        super.awakeFromNib()
        awakened += 1
    }
}

final class KioskKeypadShape: UIView {
    var prepared = false
    override func prepareForInterfaceBuilder() { prepared = true }
}

extension UIAlertController {
    class func kioskShapedAlert() -> UIAlertController {
        return self.init(title: "Your details have been sent", message: nil, preferredStyle: .alert)
    }
}

final class KioskAlertSubclass: UIAlertController {}

@MainActor
final class KioskRowsTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut = .macOS
    private var window: UIWindow?

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        window = nil
        super.tearDown()
    }

    /// The oracle ran inside UIApplicationMain with a key window.
    private func makeKeyWindow() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        w.rootViewController = UIViewController()
        w.makeKeyAndVisible()
        window = w
    }

    func testEverySectionMatchesiOS() throws {
        makeKeyWindow()
        let font = uikitRoot.appendingPathComponent(
            "Sources/EidolonPods/Pods/Artsy-OSSUIFonts/Pod/Assets/EBGaramond12-Regular.ttf").path
        OUKKioskRowsSetFontPath(font)
        let expected = try oracle()
        var compared = 0
        while let cName = OUKKioskRowsSection(Int32(compared)) {
            let section = String(cString: cName)
            let box = Lines()
            OUKKioskRowsRun(cName, { line, context in
                Unmanaged<Lines>.fromOpaque(context!).takeUnretainedValue().all.append(String(cString: line!))
            }, Unmanaged.passUnretained(box).toOpaque())
            var want = expected[section] ?? ["<missing section>"]
#if os(macOS)
            // The second CTFontManagerRegisterGraphicsFont is answered by the
            // HOST's CoreText, not by OpenUIKit: macOS 26 accepts it (MEASURED
            // here, "again=YES error=0"); iOS 26.1 refuses it with 305.
            want = want.map { $0 == "again=NO error=305" ? "again=YES error=0" : $0 }
#endif
            XCTAssertEqual(box.all, want, "## \(section)")
            compared += 1
        }
        XCTAssertEqual(compared, expected.count)
    }

    func testKioskSwiftSpellings() {
        // AppDelegate.swift:23
        UIApplication.shared.isIdleTimerDisabled = true
        XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)
        UIApplication.shared.isIdleTimerDisabled = false
        // HelpViewController.swift:164, SaleArtworkDetailsViewController.swift:117
        let label = UILabel()
        XCTAssertEqual(label.preferredMaxLayoutWidth, 0)
        label.preferredMaxLayoutWidth = 120
        XCTAssertEqual(label.preferredMaxLayoutWidth, 120)
        // Button.swift:9-11
        let button = UIButton(type: .custom)
        button.setTitleShadowColor(UIColor.clear, for: .normal)
        XCTAssertTrue(button.titleShadowColor(for: .highlighted) === UIColor.clear || button.titleShadowColor(for: .highlighted) == UIColor.clear)
        // TextField.swift:104
        let field = UITextField()
        XCTAssertFalse(field.clearsOnBeginEditing)
        field.clearsOnBeginEditing = true
        XCTAssertTrue(field.clearsOnBeginEditing)
        // ListingsCountdownManager.swift:28 / KeypadContainerView.swift:17
        let manager = KioskCountdownManagerShape()
        manager.awakeFromNib()
        XCTAssertEqual(manager.awakened, 1)
        let keypad = KioskKeypadShape()
        keypad.prepareForInterfaceBuilder()
        XCTAssertTrue(keypad.prepared)
        // BidderDetailsRetrieval.swift:60: self.init through the metatype
        let alert = KioskAlertSubclass.kioskShapedAlert()
        XCTAssertTrue(alert is KioskAlertSubclass)
        XCTAssertEqual(alert.title, "Your details have been sent")
        XCTAssertEqual(alert.preferredStyle, .alert)
    }

    /// The nib loader's message reaches an NSObject custom object's
    /// awakeFromNib (NibDecoder.sendAwakeFromNib).
    func testNibLoaderAwakesAnNSObject() {
        let manager = KioskCountdownManagerShape()
        NibDecoder.sendAwakeFromNib(manager)
        XCTAssertEqual(manager.awakened, 1)
    }
}
#endif
