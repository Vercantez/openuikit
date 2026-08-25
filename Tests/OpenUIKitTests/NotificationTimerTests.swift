// NotificationCenter + Timer tests. Owner: app-compat cluster (controls2).
//
// Both types SHADOW Foundation's, so this file disambiguates them at file
// scope exactly the way an app that imports both would have to — that is the
// documented migration and it is worth exercising here.

import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGRect = OpenUIKit.CGRect
private typealias Notification = OpenUIKit.Notification
private typealias NotificationCenter = OpenUIKit.NotificationCenter
private typealias Timer = OpenUIKit.Timer

private let testName = Notification.Name("OpenUIKitTestNotification")
private let otherName = Notification.Name("OpenUIKitOtherNotification")

final class NotificationCenterTests: XCTestCase {

    func testBlockObserverReceivesPostsAndUserInfo() {
        let center = NotificationCenter()
        var seen: [Notification] = []
        let token = center.addObserver(forName: testName, object: nil, queue: nil) {
            seen.append($0)
        }
        center.post(name: testName, object: nil, userInfo: ["k": 42])
        center.post(name: otherName, object: nil)
        XCTAssertEqual(seen.count, 1)
        XCTAssertEqual(seen.first?.name, testName)
        XCTAssertEqual(seen.first?.userInfo?["k"] as? Int, 42)
        center.removeObserver(token)
        center.post(name: testName, object: nil)
        XCTAssertEqual(seen.count, 1, "a removed observer hears nothing")
        XCTAssertEqual(center._observerCount, 0)
    }

    func testNilNameObservesEverything() {
        let center = NotificationCenter()
        var count = 0
        center.addObserver(forName: nil, object: nil, queue: nil) { _ in count += 1 }
        center.post(name: testName, object: nil)
        center.post(name: otherName, object: nil)
        XCTAssertEqual(count, 2)
    }

    func testObjectFilterIsIdentity() {
        let center = NotificationCenter()
        let a = UIView()
        let b = UIView()
        var count = 0
        center.addObserver(forName: testName, object: a, queue: nil) { _ in count += 1 }
        center.post(name: testName, object: b)
        XCTAssertEqual(count, 0)
        center.post(name: testName, object: a)
        XCTAssertEqual(count, 1)
        center.post(name: testName, object: nil)
        XCTAssertEqual(count, 1, "a nil sender does not match a filtered observer")
    }

    /// The selector form goes through the same portable dispatch
    /// `UIControl.addTarget(_:action:for:)` uses (docs/OBJC_RUNTIME.md).
    func testSelectorObserver() {
        final class Watcher: SelectorDispatching {
            var received: [Notification] = []
            static let actions: ActionTable<Watcher> = [
                .action("noteFired:", Watcher.noteFired),
            ]
            func noteFired(_ note: Notification) { received.append(note) }
            func perform(_ name: String, with sender: Any?) -> Bool {
                Watcher.actions.perform(name, on: self, with: sender)
            }
        }
        let center = NotificationCenter()
        let w = Watcher()
        center.addObserver(w, selector: Selector.named("noteFired:"),
                           name: testName, object: nil)
        center.post(name: testName, object: nil, userInfo: ["x": "y"])
        XCTAssertEqual(w.received.count, 1)
        XCTAssertEqual(w.received.first?.userInfo?["x"] as? String, "y")
        center.removeObserver(w)
        center.post(name: testName, object: nil)
        XCTAssertEqual(w.received.count, 1)
    }

    func testDeallocatedSelectorObserverIsReaped() {
        final class Watcher: SelectorDispatching {
            func perform(_ name: String, with sender: Any?) -> Bool { true }
        }
        let center = NotificationCenter()
        do {
            let w = Watcher()
            center.addObserver(w, selector: Selector.named("x:"), name: testName, object: nil)
            XCTAssertEqual(center._observerCount, 1)
        }
        center.post(name: testName, object: nil)
        XCTAssertEqual(center._observerCount, 0)
    }

    /// Foundation snapshots the observer list before delivering; so do we,
    /// so an observer that unregisters mid-post does not perturb the pass.
    func testReentrantRemovalDuringPost() {
        let center = NotificationCenter()
        var order: [Int] = []
        var second: NotificationToken?
        _ = center.addObserver(forName: testName, object: nil, queue: nil) { _ in
            order.append(1)
            if let s = second { center.removeObserver(s) }
        }
        second = center.addObserver(forName: testName, object: nil, queue: nil) { _ in
            order.append(2)
        }
        center.post(name: testName, object: nil)
        XCTAssertEqual(order, [1, 2], "the in-flight post still reaches observer 2")
        center.post(name: testName, object: nil)
        XCTAssertEqual(order, [1, 2, 1], "and observer 2 is gone next time")
    }

    /// The app lifecycle POSTS the UIKit notifications, which is the whole
    /// point of the type existing (docs/APP_COMPAT.md: ~90 uses).
    func testApplicationLifecyclePostsNotifications() {
        final class Delegate: UIApplicationDelegate {}
        let app = UIApplication.shared
        var heard: [String] = []
        var tokens: [NotificationToken] = []
        let names: [(Notification.Name, String)] = [
            (UIApplication.didBecomeActiveNotification, "active"),
            (UIApplication.willResignActiveNotification, "resign"),
            (UIApplication.didEnterBackgroundNotification, "background"),
            (UIApplication.willEnterForegroundNotification, "foreground"),
        ]
        for (name, tag) in names {
            tokens.append(NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: nil) { note in
                    XCTAssertTrue(note.object as AnyObject === app,
                                  "UIKit posts the application as the object")
                    heard.append(tag)
                })
        }
        defer { for t in tokens { NotificationCenter.default.removeObserver(t) } }
        let d = Delegate()
        app._hostLaunch(delegate: d)
        app._hostDidBecomeActive()
        app._hostDidEnterBackground()
        app._hostWillEnterForeground()
        app._hostDidBecomeActive()
        // didEnterBackground resigns active first, exactly like UIKit.
        XCTAssertEqual(heard, ["active", "resign", "background", "foreground", "active"])
    }
}

final class TimerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Timer._reset()
    }

    override func tearDown() {
        Timer._reset()
        super.tearDown()
    }

    func testOneShotFiresOnceWhenTheHostClockPasses() {
        var fired = 0
        let t = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in fired += 1 }
        XCTAssertTrue(Timer._hasScheduledTimers)
        XCTAssertEqual(Timer._nextFireTime, 0.5)
        Timer._step(to: 0.4)
        XCTAssertEqual(fired, 0, "not due yet")
        Timer._step(to: 0.5)
        XCTAssertEqual(fired, 1)
        XCTAssertFalse(t.isValid)
        Timer._step(to: 10)
        XCTAssertEqual(fired, 1)
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testRepeatingTimerSkipsMissedFiresInsteadOfBursting() {
        var fired = 0
        let t = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in fired += 1 }
        Timer._step(to: 0.1)
        XCTAssertEqual(fired, 1)
        // A one-second jump is FIVE missed periods; Foundation fires once and
        // reschedules into the future rather than replaying them.
        Timer._step(to: 1.0)
        XCTAssertEqual(fired, 2)
        XCTAssertEqual(t.fireDate, 1.1, accuracy: 1e-9)
        Timer._step(to: 1.1)
        XCTAssertEqual(fired, 3)
    }

    func testInvalidateStopsAndReleases() {
        var fired = 0
        let t = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in fired += 1 }
        Timer._step(to: 0.1)
        XCTAssertEqual(fired, 1)
        t.invalidate()
        XCTAssertFalse(t.isValid)
        Timer._step(to: 5)
        XCTAssertEqual(fired, 1)
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testUnscheduledTimerNeedsTheRunLoop() {
        var fired = 0
        let t = Timer(timeInterval: 0.2, repeats: false) { _ in fired += 1 }
        Timer._step(to: 1)
        XCTAssertEqual(fired, 0, "never added to a run loop")
        RunLoop.main.add(t, forMode: .common)
        // fireDate was computed at construction (clock 0), so it is due.
        Timer._step(to: 1.5)
        XCTAssertEqual(fired, 1)
    }

    func testSelectorForm() {
        final class Ticker: SelectorDispatching {
            var ticks = 0
            var lastUserInfo: Any?
            static let actions: ActionTable<Ticker> = [.action("tick:", Ticker.tick)]
            func tick(_ timer: Timer) { ticks += 1; lastUserInfo = timer.userInfo }
            func perform(_ name: String, with sender: Any?) -> Bool {
                Ticker.actions.perform(name, on: self, with: sender)
            }
        }
        let ticker = Ticker()
        Timer.scheduledTimer(timeInterval: 0.25, target: ticker,
                             selector: Selector.named("tick:"),
                             userInfo: "payload", repeats: true)
        Timer._step(to: 0.25)
        Timer._step(to: 0.5)
        XCTAssertEqual(ticker.ticks, 2)
        XCTAssertEqual(ticker.lastUserInfo as? String, "payload")
    }

    func testFireRunsOutOfSchedule() {
        var fired = 0
        let t = Timer.scheduledTimer(withTimeInterval: 100, repeats: false) { _ in fired += 1 }
        t.fire()
        XCTAssertEqual(fired, 1)
        XCTAssertFalse(t.isValid, "a one-shot invalidates after an explicit fire")
    }

    /// The whole point of the host clock: a window's tick is the run-loop
    /// turn, so `openhost`/`openrender` drive timers deterministically.
    func testWindowTickDrivesTimers() {
        var fired = 0
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in fired += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.tick(timestamp: 0.2)
        XCTAssertEqual(fired, 0)
        window.tick(timestamp: 0.31)
        XCTAssertEqual(fired, 1)
    }

    func testTwoTimersDueInOneTickFireInFireOrder() {
        var order: [String] = []
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in order.append("late") }
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in order.append("early") }
        Timer._step(to: 1.0)
        XCTAssertEqual(order, ["early", "late"])
    }
}
