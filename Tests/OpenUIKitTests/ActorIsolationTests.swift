// Actor-isolation tests (M15 app-compat, docs/APP_COMPAT.md punch list #3).
//
// These are mostly a COMPILE-TIME contract: the point of annotating the UI
// classes `@MainActor` is that real app source -- which is written against
// real UIKit's isolation -- type-checks. Everything in this file is spelled
// the way an app spells it (`@MainActor` closure properties, `@MainActor`
// initializers, `nonisolated` helpers), so if the isolation ever regresses
// the target stops building rather than silently changing behaviour.
//
// The runtime assertions exist so the file is a real test and not just a
// build artifact; the interesting failures are the ones the compiler catches.
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

// MARK: - A model type shaped exactly like a real app's

/// Modelled on pocket-casts' `OptionAction` (Sources/RealAppProbe/Vendored):
/// a plain, NON-isolated class that stores a `@MainActor` closure and is
/// constructed from main-actor code. This is the shape that did not compile
/// before this milestone.
final class IsolatedAction {
    let label: String
    let action: @MainActor () -> Void

    @MainActor
    init(label: String, action: @escaping @MainActor () -> Void) {
        self.label = label
        self.action = action
    }
}

// MARK: - App-shaped view code

@MainActor
final class ProbeView: UIView {
    var taps = 0

    /// A `@MainActor` method on a UIView subclass -- what apps write.
    @MainActor
    func handleTap() { taps += 1 }

    /// A `nonisolated` override on a `@MainActor` class. Apps use this for
    /// identity/description helpers, and it only compiles if the base class
    /// is isolated in the first place.
    nonisolated var probeDescription: String { "ProbeView" }
}

@MainActor
final class ActorIsolationTests: XCTestCase {

    /// The headline: a `@MainActor` closure stored on a nonisolated model and
    /// invoked straight from a touch handler, with no `await` and no hop --
    /// exactly what real UIKit allows and what OpenUIKit rejected before M15.
    func testMainActorClosureCallableFromTouchHandling() {
        var fired = 0
        let item = IsolatedAction(label: "tap me") { fired += 1 }

        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        button.addTarget(for: .touchUpInside) { _, _ in item.action() }

        button.sendActions(for: .touchUpInside)
        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(fired, 2)
        XCTAssertEqual(item.label, "tap me")
    }

    /// A `@MainActor` method on a UIView subclass, reached through the real
    /// event path rather than called directly.
    func testMainActorMethodOnViewSubclass() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let view = ProbeView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(view)

        view.handleTap()
        XCTAssertEqual(view.taps, 1)
        XCTAssertEqual(view.probeDescription, "ProbeView")
    }

    /// Delegate protocols are `@MainActor` too (real UIKit annotates them),
    /// so a `@MainActor` conformer's methods satisfy their requirements
    /// without a `nonisolated` escape hatch.
    func testDelegateProtocolIsIsolated() {
        final class Delegate: NSObjectLike, UIScrollViewDelegate {
            var offsets: [CGFloat] = []
            func scrollViewDidScroll(_ scrollView: UIScrollView) {
                offsets.append(scrollView.contentOffset.y)
            }
        }
        let d = Delegate()
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        sv.contentSize = CGSize(width: 100, height: 400)
        sv.delegate = d
        sv.contentOffset = CGPoint(x: 0, y: 30)
        XCTAssertEqual(d.offsets, [30])
    }

    /// The other half of the contract: the text engine's glyph entry point is
    /// `nonisolated static`, so glyph rasterization is still legal off the
    /// main actor. If someone drops that annotation, this stops compiling.
    func testGlyphPainterStaysNonisolated() {
        nonisolated func paintOffMainActor() -> Bool {
            let bitmap = Bitmap(width: 80, height: 40)
            let canvas = Canvas(bitmap: bitmap, scale: 2)
            UILabel.drawGlyphLine("Hi", at: CGPoint(x: 2, y: 14), in: canvas,
                                  font: UIFont.systemFont(ofSize: 12), dark: false,
                                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 1),
                                  glyphFont: nil)
            return bitmap.pixels.contains { $0 != 0 }
        }
        XCTAssertTrue(paintOffMainActor(), "glyph run drew nothing")
    }

    /// `MainActor.assumeIsolated` is the ONLY boundary crossing in the
    /// library (Timer / NotificationCenter delivery). Prove the two paths it
    /// guards actually deliver.
    func testAssumeIsolatedDeliveryPaths() {
        final class Observer: SelectorDispatching {
            var hits: [String] = []
            static let actions: ActionTable<Observer> = [
                .action("timerFired:", Observer.timerFired),
                .action("noteFired:", Observer.noteFired),
            ]
            func perform(_ name: String, with sender: Any?) -> Bool {
                Self.actions.perform(name, on: self, with: sender)
            }
            func timerFired(_ sender: AnyObject) { hits.append("timer") }
            func noteFired(_ sender: AnyObject) { hits.append("note") }
        }

        let observer = Observer()

        let timer = Timer(timeInterval: 1, target: observer,
                          selector: Selector.named("timerFired:"),
                          userInfo: nil, repeats: false)
        timer.fire()

        let name = OpenUIKit.Notification.Name(rawValue: "OpenUIKitActorIsolationProbe")
        NotificationCenter.default.addObserver(observer,
                                               selector: Selector.named("noteFired:"),
                                               name: name, object: nil)
        NotificationCenter.default.post(name: name, object: nil)
        NotificationCenter.default.removeObserver(observer, name: name, object: nil)

        XCTAssertEqual(observer.hits, ["timer", "note"])
    }
}

/// OpenUIKit has no `NSObject`, and a delegate conformer does not need one --
/// this empty base only exists so the nested `Delegate` above reads like app
/// source (`class Delegate: NSObject, UIScrollViewDelegate`).
@MainActor
class NSObjectLike {}
