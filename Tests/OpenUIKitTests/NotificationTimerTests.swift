// NotificationCenter + Timer tests. Owner: app-compat cluster (controls2).
//
// `Notification` now has Foundation identity whenever Foundation is visible.
// Apple builds also use Foundation's canonical center; native ELF retains
// OpenUIKit's strict selector-registry center. Timer still shadows Foundation's
// host-clock-independent implementation.

import XCTest
@testable import OpenUIKit

private typealias NotificationCenter = OpenUIKit.NotificationCenter
private typealias Timer = OpenUIKit.Timer

private let testName = Notification.Name("OpenUIKitTestNotification")
private let otherName = Notification.Name("OpenUIKitOtherNotification")

/// Foundation's block observer is `@Sendable`, while Notification and its
/// NSObjectProtocol token intentionally are not. Tests execute synchronously
/// on the main actor; this box makes that ownership explicit without noisy
/// capture diagnostics obscuring the semantic assertions.
private final class NotificationTestBox<Value>: @unchecked Sendable {
    var value: Value
    init(_ value: Value) { self.value = value }
}

@MainActor
final class NotificationCenterTests: XCTestCase {

    func testBlockObserverReceivesPostsAndUserInfo() {
        let center = NotificationCenter()
        let seen = NotificationTestBox<[Notification]>([])
        let token = center.addObserver(forName: testName, object: nil, queue: nil) {
            seen.value.append($0)
        }
        center.post(name: testName, object: nil, userInfo: ["k": 42])
        center.post(name: otherName, object: nil)
        XCTAssertEqual(seen.value.count, 1)
        XCTAssertEqual(seen.value.first?.name, testName)
        XCTAssertEqual(seen.value.first?.userInfo?["k"] as? Int, 42)
        center.removeObserver(token)
        center.post(name: testName, object: nil)
        XCTAssertEqual(seen.value.count, 1, "a removed observer hears nothing")
#if !canImport(Foundation) || !canImport(ObjectiveC)
        XCTAssertEqual(center._observerCount, 0)
#endif
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

    func testNotificationPreservesObjectAndUserInfoReferenceIdentity() {
        let center = NotificationCenter()
        let object = UIView()
        let payload = UIView()
        var receivedObject: AnyObject?
        var receivedPayload: AnyObject?
        let token = center.addObserver(
            forName: testName, object: nil, queue: OperationQueue.main
        ) { note in
            receivedObject = note.object as AnyObject?
            receivedPayload = note.userInfo?["payload"] as AnyObject?
        }

        center.post(name: testName, object: object, userInfo: ["payload": payload])

        XCTAssertTrue(receivedObject === object)
        XCTAssertTrue(receivedPayload === payload)
        center.removeObserver(token)
    }

    func testObjectFilterIsWeakAndDeadFilterIsReaped() {
        let center = NotificationCenter()
        var deliveries = 0
        weak var weakFilter: UIView?
        var token: NotificationToken?
        do {
            let filter = UIView()
            weakFilter = filter
            token = center.addObserver(forName: testName, object: filter, queue: nil) {
                _ in deliveries += 1
            }
            XCTAssertNotNil(weakFilter)
#if !canImport(Foundation) || !canImport(ObjectiveC)
            XCTAssertEqual(center._observerCount, 1)
#endif
        }
        XCTAssertNil(weakFilter, "the center must not retain an object filter")
        center.post(name: testName, object: nil)
        XCTAssertEqual(deliveries, 0)
#if !canImport(Foundation) || !canImport(ObjectiveC)
        XCTAssertEqual(center._observerCount, 0)
#endif
        withExtendedLifetime(token) {}
    }

#if !canImport(Foundation) || !canImport(ObjectiveC)
    /// The selector form goes through the same portable dispatch
    /// `UIControl.addTarget(_:action:for:)` uses (docs/OBJC_RUNTIME.md).
    func testSelectorObserver() {
        @MainActor
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
        @MainActor
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

    func testDuplicateSelectorRegistrationsAndExactRemoval() {
        @MainActor
        final class Watcher: SelectorDispatching {
            var hits = 0
            func perform(_ name: String, with sender: Any?) -> Bool {
                guard name == "note:" else { return false }
                guard sender is Notification else { return false }
                hits += 1
                return true
            }
        }

        let center = NotificationCenter()
        let watcher = Watcher()
        let filter = UIView()
        let otherFilter = UIView()
        center.addObserver(watcher, selector: .named("note:"),
                           name: testName, object: filter)
        center.addObserver(watcher, selector: .named("note:"),
                           name: testName, object: filter)
        center.post(name: testName, object: filter)
        XCTAssertEqual(watcher.hits, 2, "duplicate registrations each deliver")

        center.removeObserver(watcher, name: testName, object: otherFilter)
        center.post(name: testName, object: filter)
        XCTAssertEqual(watcher.hits, 4, "a nonidentical filter removes nothing")

        center.removeObserver(watcher, name: testName, object: filter)
        center.post(name: testName, object: filter)
        XCTAssertEqual(watcher.hits, 4)
        XCTAssertEqual(center._observerCount, 0)
    }

    func testSelectorMissReportsExactlyOnceThroughCentralDispatch() {
        @MainActor
        final class Watcher: SelectorDispatching {
            func perform(_ name: String, with sender: Any?) -> Bool { false }
        }

        let center = NotificationCenter()
        let watcher = Watcher()
        var misses: [String] = []
        let prior = SelectorDispatch.onUnresolved
        SelectorDispatch.onUnresolved = { _, name in misses.append(name) }
        defer { SelectorDispatch.onUnresolved = prior }

        center.addObserver(watcher, selector: .named("missing:"),
                           name: testName, object: nil)
        center.post(name: testName, object: nil)
        XCTAssertEqual(misses, ["missing:"])
    }
#endif

    /// The portable center snapshots before delivery. Foundation's native
    /// center instead suppresses an entry removed earlier in the same post;
    /// Apple builds intentionally inherit that authoritative behavior.
    func testReentrantRemovalDuringPost() {
        let center = NotificationCenter()
        var order: [Int] = []
        let second = NotificationTestBox<NotificationToken?>(nil)
        _ = center.addObserver(forName: testName, object: nil, queue: nil) { _ in
            order.append(1)
            if let token = second.value { center.removeObserver(token) }
        }
        second.value = center.addObserver(forName: testName, object: nil, queue: nil) { _ in
            order.append(2)
        }
        center.post(name: testName, object: nil)
#if canImport(Foundation) && canImport(ObjectiveC)
        XCTAssertEqual(order, [1], "Foundation suppresses the removed in-flight entry")
        center.post(name: testName, object: nil)
        XCTAssertEqual(order, [1, 1])
#else
        XCTAssertEqual(order, [1, 2], "the in-flight post still reaches observer 2")
        center.post(name: testName, object: nil)
        XCTAssertEqual(order, [1, 2, 1], "and observer 2 is gone next time")
#endif
    }

    func testReentrantAdditionWaitsUntilTheNextPost() {
        let center = NotificationCenter()
        var order: [String] = []
        let second = NotificationTestBox<NotificationToken?>(nil)
        let first = center.addObserver(forName: testName, object: nil, queue: nil) {
            _ in
            order.append("first")
            if second.value == nil {
                second.value = center.addObserver(
                    forName: testName, object: nil, queue: nil
                ) { _ in order.append("second") }
            }
        }

        center.post(name: testName, object: nil)
        XCTAssertEqual(order, ["first"])
        center.post(name: testName, object: nil)
        XCTAssertEqual(order, ["first", "first", "second"])
        center.removeObserver(first)
        if let token = second.value { center.removeObserver(token) }
    }

    /// The app lifecycle POSTS the UIKit notifications, which is the whole
    /// point of the type existing (docs/APP_COMPAT.md: ~90 uses).
    func testApplicationLifecyclePostsNotifications() {
        @MainActor
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

@MainActor
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

    func testOneShotCannotDeliverAgainFromAReentrantHostStep() {
        var deliveries = 0
        var callbackValidity: [Bool] = []
        let timer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { timer in
            deliveries += 1
            callbackValidity.append(timer.isValid)
            if deliveries < 4 {
                Timer._step(to: Timer.currentTime)
            }
        }

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(deliveries, 1, "a one-shot timer must be consumed before its callback")
        XCTAssertEqual(callbackValidity, [true], "Foundation keeps a one-shot valid during its callback")
        XCTAssertFalse(timer.isValid, "the one-shot invalidates after its callback returns")
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testTimerScheduledDuringReentrantStepWaitsForNextOutermostStep() {
        var events: [String] = []
        Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { outer in
            outer.invalidate()
            events.append("outer")
            Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { inner in
                inner.invalidate()
                events.append("inner")
            }
            Timer._step(to: Timer.currentTime)
            events.append("outer-returned")
        }

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(events, ["outer", "outer-returned"])
        XCTAssertTrue(Timer._hasScheduledTimers)

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(events, ["outer", "outer-returned", "inner"])
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testRepeatingTimerCannotRedeliverAnOccurrenceDuringAReentrantHostStep() {
        var deliveries = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0, repeats: true) { timer in
            deliveries += 1
            if deliveries == 1 {
                Timer._step(to: Timer.currentTime + 100)
            } else {
                timer.invalidate()
            }
        }

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(deliveries, 1, "a repeating occurrence may deliver only once per outer host turn")
        XCTAssertTrue(timer.isValid)

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(deliveries, 2, "the rescheduled occurrence becomes eligible on the next outer turn")
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testEarlierEqualDeadlineCallbackCannotMakeRepeaterDeliverTwiceFromOuterSnapshot() {
        var repeatingDeliveries = 0
        Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
            Timer._step(to: Timer.currentTime)
        }
        let repeating = Timer.scheduledTimer(withTimeInterval: 0, repeats: true) { timer in
            repeatingDeliveries += 1
            if repeatingDeliveries == 2 { timer.invalidate() }
        }

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(
            repeatingDeliveries, 1,
            "a nested step and its stale outer due snapshot are one host generation")
        XCTAssertTrue(repeating.isValid)

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(repeatingDeliveries, 2)
        XCTAssertFalse(repeating.isValid)
    }

    func testEarlierCallbackNestedFutureStepCannotDoubleDeliverPositiveRepeater() {
        var repeatingDeliveries = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            Timer._step(to: Timer.currentTime + 100)
        }
        let repeating = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            repeatingDeliveries += 1
            if repeatingDeliveries == 2 { timer.invalidate() }
        }

        Timer._step(to: 1)
        XCTAssertEqual(
            repeatingDeliveries, 1,
            "advancing recursively must not let the outer snapshot redeliver the occurrence")
        XCTAssertTrue(repeating.isValid)

        // The nested step advanced the host clock to 101, so the positive
        // repeater correctly rescheduled its next occurrence for 102.
        XCTAssertEqual(Timer._nextFireTime, 102)
        Timer._step(to: 102)
        XCTAssertEqual(repeatingDeliveries, 2)
        XCTAssertFalse(repeating.isValid)
    }

    func testEarlierCallbackCanPostponeLaterTimerFromOuterSnapshot() {
        var events: [String] = []
        var postponed: Timer!
        Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
            events.append("earlier")
            postponed.fireDate = 10
        }
        postponed = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
            events.append("postponed")
        }

        Timer._step(to: 0)
        XCTAssertEqual(events, ["earlier"])
        XCTAssertTrue(postponed.isValid)
        XCTAssertEqual(Timer._nextFireTime, 10)

        Timer._step(to: 10)
        XCTAssertEqual(events, ["earlier", "postponed"])
        XCTAssertFalse(postponed.isValid)
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testNestedFutureStepRevalidatesIdentityDeadlineAndGenerationTogether() {
        var events: [String] = []
        var postponed: Timer!
        var invalidated: Timer!

        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            events.append("driver")
            postponed.fireDate = 50
            invalidated.invalidate()
            Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
                events.append("new")
            }
            Timer._step(to: 100)
            events.append("driver-returned")
        }
        postponed = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            events.append("postponed")
            if events.filter({ $0 == "postponed" }).count == 2 {
                timer.invalidate()
            }
        }
        invalidated = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            events.append("invalidated")
        }

        Timer._step(to: 1)
        XCTAssertEqual(events, ["driver", "postponed", "driver-returned"])
        XCTAssertEqual(Timer.currentTime, 100)
        XCTAssertEqual(Timer._nextFireTime, 1)

        Timer._step(to: 100)
        XCTAssertEqual(events, ["driver", "postponed", "driver-returned", "new"])
        XCTAssertEqual(Timer._nextFireTime, 101)

        Timer._step(to: 101)
        XCTAssertEqual(
            events,
            ["driver", "postponed", "driver-returned", "new", "postponed"]
        )
        XCTAssertFalse(Timer._hasScheduledTimers)
    }

    func testEqualDeadlineZeroRepeatersStayFIFOAndFireOncePerOuterTurn() {
        var events: [String] = []
        Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { _ in
            events.append("driver")
            Timer._step(to: Timer.currentTime + 100)
        }
        let first = Timer.scheduledTimer(withTimeInterval: 0, repeats: true) { _ in
            events.append("first")
        }
        let second = Timer.scheduledTimer(withTimeInterval: 0, repeats: true) { _ in
            events.append("second")
        }

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(events, ["driver", "first", "second"])

        Timer._step(to: Timer.currentTime)
        XCTAssertEqual(events, ["driver", "first", "second", "first", "second"])
        first.invalidate()
        second.invalidate()
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
        @MainActor
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
