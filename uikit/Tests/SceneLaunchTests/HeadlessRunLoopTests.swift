#if canImport(ObjectiveC) && canImport(Foundation)
import CoreFoundation
import Foundation
import XCTest
@testable import OpenUIKit

/// `UIApplicationDelegate.main()` runs the main CFRunLoop, as
/// UIApplicationMain does, and the loop carries a ticker for OpenUIKit's host
/// clock. Before, `main()` parked in dispatchMain(): Foundation Timers on the
/// main run loop (NetNewsWire's AccountRefreshTimer / ArticleStatusSyncTimer
/// once Timer is Foundation's) never fired, and neither did UIView animation
/// completions or navigation transitions, which advance only on host ticks.
@MainActor
final class HeadlessRunLoopTests: XCTestCase {
    func testTickerAdvancesTheHostClockInsideTheMainRunLoop() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.addSubview(view)
        let savedTime = OpenUIKitRuntime.animationTime
        OpenUIKitRuntime.animationTime = 0
        defer { OpenUIKitRuntime.animationTime = savedTime }

        var completed: [Bool] = []
        UIView.animate(withDuration: 0.05, animations: { view.alpha = 0 },
                       completion: { completed.append($0) })
        var foundationTimerFired = false
        let foundationTimer = Foundation.Timer(timeInterval: 0.02, repeats: false) { _ in
            foundationTimerFired = true
        }
        RunLoop.main.add(foundationTimer, forMode: .common)

        let ticker = UIApplication._installHeadlessTicker()
        defer { CFRunLoopTimerInvalidate(ticker) }
        let deadline = Date().addingTimeInterval(2)
        while (completed.isEmpty || !foundationTimerFired) && Date() < deadline {
            CFRunLoopRunInMode(.defaultMode, 0.02, false)
        }
        XCTAssertTrue(foundationTimerFired, "a Foundation Timer on the main run loop fires")
        XCTAssertEqual(completed, [true], "the host clock advanced past the animation's end")
        // The ticker counts frames (no wall clock in the library): the 0.05 s
        // animation ends exactly on frame 3, 3 / 60 = 0.05, and the loop
        // stops there. "Greater than" only held while the clock was the wall.
        XCTAssertGreaterThanOrEqual(OpenUIKitRuntime.animationTime, 0.05)
    }

    func testBundledOpenUIKitResourcesAreAdoptedOnlyWhenPresent() throws {
        let saved = OpenUIKitRuntime.resourceRoot
        defer { OpenUIKitRuntime.resourceRoot = saved }
        let fm = FileManager.default
        let app = fm.temporaryDirectory.appendingPathComponent("res-\(UUID().uuidString).app")
        try fm.createDirectory(at: app, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: app) }
        XCTAssertFalse(UIApplication._adoptBundledOpenUIKitResources(bundleResourcePath: app.path))
        XCTAssertEqual(OpenUIKitRuntime.resourceRoot, saved)
        let res = app.appendingPathComponent("OpenUIKit")
        try fm.createDirectory(at: res, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: res.appendingPathComponent("font_metrics.json"))
        XCTAssertTrue(UIApplication._adoptBundledOpenUIKitResources(bundleResourcePath: app.path))
        XCTAssertEqual(OpenUIKitRuntime.resourceRoot, res.path)
    }
}
#endif
