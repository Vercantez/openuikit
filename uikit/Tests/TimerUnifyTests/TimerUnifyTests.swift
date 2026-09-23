// Timer / RunLoop unification (docs/agent_reports/timer-unify.md).
//
// Before this change OpenUIKit declared its own `Timer` and `RunLoop`, so a
// file importing UIKit and Foundation — every app file that names a timer —
// failed with "'Timer' is ambiguous for type lookup in this context"
// (NetNewsWire CurrentActivityViewModel.swift:27, ArticleStatusSyncTimer.swift:20
// and :80). The shapes below are NetNewsWire's, verbatim in kind: a stored
// `Timer?`, Foundation's selector scheduling with `#selector`, and an
// `@objc` target taking `Timer?`.
#if canImport(Darwin)
import Foundation
import UIKit
import XCTest
import OpenUIKit

@MainActor
private final class ArticleStatusSyncTimerLike: NSObject {
    private var internalTimer: Timer?
    private(set) var fired = 0

    func start() {
        internalTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self,
                                             selector: #selector(timedRefresh(_:)),
                                             userInfo: nil, repeats: false)
    }

    @objc func timedRefresh(_ sender: Timer?) {
        fired += 1
        internalTimer = nil
    }
}

final class TimerUnifyTests: XCTestCase {
    /// One type: OpenUIKit's names are Foundation's wherever Foundation exists.
    func testUIKitAndFoundationNameOneTimer() {
        XCTAssertTrue(OpenUIKit.Timer.self == Foundation.Timer.self)
        XCTAssertTrue(OpenUIKit.RunLoop.self == Foundation.RunLoop.self)
        XCTAssertTrue(UIKit.Timer.self == Foundation.Timer.self)
        // Collection sugar still folds into a type with UIKit and Foundation
        // both visible (a re-declared alias can stop `[X]()` from parsing).
        var timers = [Timer]()
        var byName = [String: Timer]()
        var loops = [RunLoop]()
        timers.removeAll(); byName.removeAll(); loops.removeAll()
        XCTAssertTrue(timers.isEmpty && byName.isEmpty && loops.isEmpty)
    }

    /// A Foundation timer an app schedules fires on Foundation's run loop.
    @MainActor
    func testAppTimerFiresOnFoundationsRunLoop() {
        let sync = ArticleStatusSyncTimerLike()
        sync.start()
        let deadline = Date(timeIntervalSinceNow: 2)
        while sync.fired == 0, Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        XCTAssertEqual(sync.fired, 1)
    }

    /// OpenUIKit's own work stays on the host clock: a host-clock timer
    /// fires when `UIWindow.tick(timestamp:)` passes its fire date and never
    /// otherwise — the determinism the scripted renders rely on.
    @MainActor
    func testHostClockTimerStillFollowsTheScriptedClock() {
        _HostClockTimer._reset()
        defer { _HostClockTimer._reset() }
        var fired = 0
        _HostClockTimer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in fired += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.tick(timestamp: 0.5)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertEqual(fired, 0, "wall-clock time and Foundation's run loop do not fire it")
        window.tick(timestamp: 1.0)
        XCTAssertEqual(fired, 1)
    }
}
#endif
