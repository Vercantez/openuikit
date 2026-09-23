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
        XCTAssertGreaterThan(OpenUIKitRuntime.animationTime, 0.05)
    }
}
#endif
