// Selector target-action tests (M12 app-compat). Covers the dispatch layer
// (UISelector.swift), UIControl.addTarget(_:action:for:) and
// UIGestureRecognizer(target:action:) -- including UIKit's weak-target
// semantics -- plus, on Darwin only, that genuine `@objc` + `#selector`
// source drives it.
import XCTest
@testable import OpenUIKit

#if canImport(ObjectiveC)
import struct Foundation.Data   // makes `@objc` legal; see SelectorApp.swift
#endif

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

// MARK: - A target written the way an app writes one

@MainActor
final class Recorder: SelectorDispatching {
    var log: [String] = []
    var lastSender: AnyObject?
    var lastEvent: UIEvent?

    static let actions: ActionTable<Recorder> = [
        .action("noArgs", Recorder.noArgs),
        .action("withSender:", Recorder.withSender),
        .action("withSenderAndEvent:event:", Recorder.withSenderAndEvent),
        .action("typedSender:", Recorder.typedSender),
    ]

    func perform(_ selectorName: String, with sender: Any?) -> Bool {
        Self.actions.perform(selectorName, on: self, with: sender)
    }
    func perform(_ selectorName: String, with sender: Any?, event: UIEvent?) -> Bool {
        Self.actions.perform(selectorName, on: self, with: sender, event: event)
    }

    func noArgs() { log.append("noArgs") }
    func withSender(_ sender: AnyObject) {
        log.append("withSender")
        lastSender = sender
    }
    func withSenderAndEvent(_ sender: AnyObject, _ event: UIEvent?) {
        log.append("withSenderAndEvent")
        lastSender = sender
        lastEvent = event
    }
    /// Sender typed as a concrete control: a mismatch must be a no-op.
    func typedSender(_ sender: UISwitch) { log.append("typedSender:\(sender.isOn)") }
}

// MARK: - The name -> method layer

@MainActor
final class SelectorNameTests: XCTestCase {
    func testActionNameAndArity() {
        XCTAssertEqual(Selector.named("tapped").actionName, "tapped")
        XCTAssertEqual(Selector.named("tapped").actionArity, 0)
        XCTAssertEqual(Selector.named("valueChanged:").actionArity, 1)
        XCTAssertEqual(Selector.named("handle:forEvent:").actionArity, 2)
    }

    func testStringLiteralAndExplicitInitAgree() {
        let a: Selector = "buttonTapped"
        XCTAssertEqual(a, Selector.named("buttonTapped"))
        XCTAssertNotEqual(a, Selector.named("buttonTapped:"))
    }
}

@MainActor
final class ActionTableTests: XCTestCase {
    func testDispatchesByArity() {
        let r = Recorder()
        let control = UIControl()
        XCTAssertTrue(r.perform("noArgs", with: control))
        XCTAssertTrue(r.perform("withSender:", with: control))
        XCTAssertTrue(r.lastSender === control)
        let event = UIEvent(timestamp: TimeInterval(3))
        XCTAssertTrue(r.perform("withSenderAndEvent:event:", with: control,
                                event: event))
        XCTAssertTrue(r.lastEvent === event)
        XCTAssertEqual(r.log, ["noArgs", "withSender", "withSenderAndEvent"])
    }

    func testUnknownSelectorReturnsFalse() {
        let r = Recorder()
        XCTAssertFalse(r.perform("nothingNamedThis", with: nil))
        XCTAssertEqual(r.log, [])
    }

    func testTypedSenderMismatchIsANoOp() {
        let r = Recorder()
        XCTAssertTrue(r.perform("typedSender:", with: UIButton(type: .system)))  // wrong type
        XCTAssertEqual(r.log, [])
        let s = UISwitch()
        s.setOn(true, animated: false)
        XCTAssertTrue(r.perform("typedSender:", with: s))
        XCTAssertEqual(r.log, ["typedSender:true"])
    }

    func testSelectorNamesAreDiscoverable() {
        XCTAssertEqual(Recorder.actions.selectorNames,
                       ["noArgs", "typedSender:", "withSender:",
                        "withSenderAndEvent:event:"])
    }
}

@MainActor
final class SelectorDispatchDeliveryTests: XCTestCase {
    override func tearDown() {
        SelectorDispatch.onUnresolved = nil
        super.tearDown()
    }

    func testUnresolvedIsReportedForUnknownName() {
        var reported: [String] = []
        SelectorDispatch.onUnresolved = { _, name in reported.append(name) }
        let r = Recorder()
        XCTAssertFalse(SelectorDispatch.send(Selector.named("nope"), to: r, sender: nil))
        XCTAssertEqual(reported, ["nope"])
    }

    func testUnresolvedIsReportedForNonDispatchingTarget() {
        var reported: [String] = []
        SelectorDispatch.onUnresolved = { _, name in reported.append(name) }
        let plain = UIView()
        XCTAssertFalse(SelectorDispatch.send(Selector.named("noArgs"), to: plain,
                                             sender: nil))
        XCTAssertEqual(reported, ["noArgs"])
    }

    func testDeallocatedTargetIsSilentlyDropped() {
        var reported: [String] = []
        SelectorDispatch.onUnresolved = { _, name in reported.append(name) }
        XCTAssertFalse(SelectorDispatch.send(Selector.named("noArgs"), to: nil,
                                             sender: nil))
        XCTAssertEqual(reported, [])
    }

    func testUIViewEndEditingBuiltinUsesMeasuredFalseArgument() {
        final class EndEditingProbe: UIView {
            var arguments: [Bool] = []
            override func endEditing(_ force: Bool) -> Bool {
                arguments.append(force)
                return false
            }
        }

        let view = EndEditingProbe()
        var unresolved = 0
        SelectorDispatch.onUnresolved = { _, _ in unresolved += 1 }
        XCTAssertTrue(SelectorDispatch.send(Selector.named("endEditing:"),
                                            to: view, sender: UITapGestureRecognizer()))
        XCTAssertEqual(view.arguments, [false])
        XCTAssertEqual(unresolved, 0,
                       "method resolution is independent of endEditing's result")
    }

    func testUIViewEndEditingBuiltinActuallyResignsSubtreeResponder() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        let container = UIView(frame: window.bounds)
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        window.addSubview(container)
        container.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())

        XCTAssertTrue(SelectorDispatch.send(Selector.named("endEditing:"),
                                            to: container,
                                            sender: UITapGestureRecognizer()))
        XCTAssertFalse(field.isFirstResponder)
    }

    func testRefusedEndEditingIsStillResolvedWithoutReportingAMiss() {
        final class RefusingDelegate: UITextFieldDelegate {
            var shouldEndCalls = 0
            func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
                shouldEndCalls += 1
                return false
            }
        }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        let container = UIView(frame: window.bounds)
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        let delegate = RefusingDelegate()
        field.delegate = delegate
        window.addSubview(container)
        container.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())
        var unresolved = 0
        SelectorDispatch.onUnresolved = { _, _ in unresolved += 1 }

        XCTAssertTrue(SelectorDispatch.send(Selector.named("endEditing:"),
                                            to: container,
                                            sender: UITapGestureRecognizer()))
        XCTAssertTrue(field.isFirstResponder)
        XCTAssertEqual(delegate.shouldEndCalls, 1)
        XCTAssertEqual(unresolved, 0)
    }
}

// MARK: - UIControl

@MainActor
final class ControlSelectorTargetTests: XCTestCase {
    override func tearDown() {
        SelectorDispatch.onUnresolved = nil
        super.tearDown()
    }

    private func makeWindowAndControl() -> (UIWindow, UIControl) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let control = UIControl(frame: CGRect(x: 10, y: 10, width: 100, height: 40))
        window.addSubview(control)
        return (window, control)
    }

    func testTapFiresSelectorAction() {
        let (window, control) = makeWindowAndControl()
        let r = Recorder()
        control.addTarget(r, action: Selector.named("withSender:"), for: .touchUpInside)
        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 0)
        XCTAssertEqual(r.log, [])
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 30), timestamp: 0.1)
        XCTAssertEqual(r.log, ["withSender"])
        XCTAssertTrue(r.lastSender === control)
    }

    func testSwitchValueChangedFiresSelectorAction() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let sw = UISwitch()
        sw.frame = CGRect(x: 10, y: 10, width: 63, height: 28)
        sw.setOn(false, animated: false)
        window.addSubview(sw)
        let r = Recorder()
        sw.addTarget(r, action: Selector.named("typedSender:"), for: .valueChanged)
        window.sendTouch(.began, at: CGPoint(x: 40, y: 24), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 40, y: 24), timestamp: 0.05)
        XCTAssertTrue(sw.isOn)
        XCTAssertEqual(r.log, ["typedSender:true"])
    }

    func testEventIsForwardedToTwoArgumentActions() {
        let (window, control) = makeWindowAndControl()
        let r = Recorder()
        control.addTarget(r, action: Selector.named("withSenderAndEvent:event:"),
                          for: .touchDown)
        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 7)
        XCTAssertEqual(r.log, ["withSenderAndEvent"])
        XCTAssertEqual(r.lastEvent?.timestamp, 7)
    }

    func testTargetIsHeldWeakly() {
        let (_, control) = makeWindowAndControl()
        var r: Recorder? = Recorder()
        control.addTarget(r!, action: Selector.named("noArgs"), for: .touchUpInside)
        XCTAssertEqual(control.allControlEvents, .touchUpInside)
        r = nil
        // UIKit never keeps a target alive; the dead registration is pruned.
        XCTAssertEqual(control.allControlEvents, UIControl.Event())
        var reported = 0
        SelectorDispatch.onUnresolved = { _, _ in reported += 1 }
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(reported, 0)
    }

    /// `action: .named("…")` — implicit member syntax, the shortest portable
    /// spelling at a call site.
    func testImplicitMemberSpellingCompilesAndFires() {
        let (_, control) = makeWindowAndControl()
        let r = Recorder()
        control.addTarget(r, action: .named("noArgs"), for: .touchUpInside)
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(r.log, ["noArgs"])
    }

    func testRemoveTargetByTargetAndAction() {
        let (_, control) = makeWindowAndControl()
        let r = Recorder()
        control.addTarget(r, action: Selector.named("noArgs"), for: .touchUpInside)
        control.addTarget(r, action: Selector.named("withSender:"), for: .touchUpInside)
        control.removeTarget(r, action: Selector.named("noArgs"), for: .touchUpInside)
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(r.log, ["withSender"])
    }

    func testRemoveTargetNilActionRemovesAllForThoseEvents() {
        let (_, control) = makeWindowAndControl()
        let r = Recorder()
        control.addTarget(r, action: Selector.named("noArgs"), for: .touchUpInside)
        control.addTarget(r, action: Selector.named("withSender:"), for: .touchDown)
        control.removeTarget(nil, action: nil, for: .touchUpInside)
        control.sendActions(for: .allEvents)
        XCTAssertEqual(r.log, ["withSender"])
    }

    func testRemoveTargetKeepsUnnamedEventBits() {
        let (_, control) = makeWindowAndControl()
        let r = Recorder()
        control.addTarget(r, action: Selector.named("noArgs"),
                          for: [.touchDown, .touchUpInside])
        control.removeTarget(r, action: nil, for: .touchDown)
        control.sendActions(for: .touchDown)
        XCTAssertEqual(r.log, [])
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(r.log, ["noArgs"])
    }

    func testClosureRegistrationsSurviveSelectorRemoval() {
        let (_, control) = makeWindowAndControl()
        var closureFired = 0
        control.addTarget(for: .touchUpInside) { _, _ in closureFired += 1 }
        let r = Recorder()
        control.addTarget(r, action: Selector.named("noArgs"), for: .touchUpInside)
        control.removeTarget(nil, action: nil, for: .allEvents)
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(r.log, [])
        XCTAssertEqual(closureFired, 1)
    }

    func testUnresolvedSelectorIsReportedNotCrashing() {
        let (_, control) = makeWindowAndControl()
        var reported: [String] = []
        SelectorDispatch.onUnresolved = { _, name in reported.append(name) }
        let r = Recorder()
        control.addTarget(r, action: Selector.named("typoTapped"), for: .touchUpInside)
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(reported, ["typoTapped"])
    }
}

// MARK: - UIGestureRecognizer

@MainActor
final class GestureSelectorTargetTests: XCTestCase {
    func testRecognizedTapDispatchesFrameworkEndEditingActionWithoutRegistry() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        let container = UIView(frame: window.bounds)
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        window.addSubview(container)
        container.addSubview(field)
        container.addGestureRecognizer(
            UITapGestureRecognizer(target: container,
                                   action: Selector.named("endEditing:"))
        )
        XCTAssertTrue(field.becomeFirstResponder())

        window.sendTouch(.began, at: CGPoint(x: 260, y: 80), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 260, y: 80), timestamp: 0.05)

        XCTAssertFalse(field.isFirstResponder)
    }

    func testTapRecognizerInitTargetActionFires() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(view)
        let r = Recorder()
        let tap = UITapGestureRecognizer(target: r, action: Selector.named("withSender:"))
        view.addGestureRecognizer(tap)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.05)
        XCTAssertEqual(r.log, ["withSender"])
        XCTAssertTrue(r.lastSender === tap)
    }

    func testAddAndRemoveTargetOnRecognizer() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(view)
        let r = Recorder()
        let tap = UITapGestureRecognizer()
        tap.addTarget(r, action: Selector.named("noArgs"))
        view.addGestureRecognizer(tap)
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.05)
        XCTAssertEqual(r.log, ["noArgs"])

        tap.removeTarget(r, action: Selector.named("noArgs"))
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 1.0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 1.05)
        XCTAssertEqual(r.log, ["noArgs"])
    }

    func testRecognizerTargetIsHeldWeakly() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(view)
        var r: Recorder? = Recorder()
        let tap = UITapGestureRecognizer(target: r!, action: Selector.named("noArgs"))
        view.addGestureRecognizer(tap)
        weak var weakR = r
        r = nil
        XCTAssertNil(weakR, "the recognizer must not retain its target")
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.05)
    }
}

// MARK: - The demo screen, wired entirely with selectors

@MainActor
final class SelectorDemoAppTests: XCTestCase {
    /// The demo app lives in the DemoApp target, which the test target does
    /// not link; this reproduces its wiring against the same machinery so the
    /// scripted `openhost --app selectors` run has a unit-test twin.
    @MainActor
    final class Screen: SelectorDispatching {
        let button = UIButton(type: .system)
        let toggle = UISwitch()
        let panel = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        var count = 0
        var last = ""

        static let actions: ActionTable<Screen> = [
            .action("incrementTapped", Screen.increment),
            .action("enabledChanged:", Screen.enabledDidChange),
            .action("handleTap:", Screen.tapped),
        ]
        func perform(_ name: String, with sender: Any?) -> Bool {
            Self.actions.perform(name, on: self, with: sender)
        }

        func increment() { count += 1; last = "incrementTapped" }
        func enabledDidChange(_ sender: UISwitch) {
            last = "enabledChanged:\(sender.isOn)"
        }
        func tapped(_ g: UITapGestureRecognizer) { count += 1; last = "handleTap:" }

        init(in window: UIWindow) {
            button.setTitle("Increment", for: .normal)
            button.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
            button.addTarget(self, action: Selector.named("incrementTapped"),
                             for: .touchUpInside)
            window.addSubview(button)

            toggle.frame = CGRect(x: 0, y: 60, width: 63, height: 28)
            toggle.setOn(false, animated: false)
            toggle.addTarget(self, action: Selector.named("enabledChanged:"),
                             for: .valueChanged)
            window.addSubview(toggle)

            panel.frame = CGRect(x: 0, y: 120, width: 200, height: 100)
            panel.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: Selector.named("handleTap:")))
            window.addSubview(panel)
        }
    }

    func testEveryControlOnTheScreenFiresThroughSelectors() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 400))
        let screen = Screen(in: window)

        window.sendTouch(.began, at: CGPoint(x: 60, y: 22), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 60, y: 22), timestamp: 0.05)
        XCTAssertEqual(screen.count, 1)
        XCTAssertEqual(screen.last, "incrementTapped")

        window.sendTouch(.began, at: CGPoint(x: 30, y: 74), timestamp: 0.5)
        window.sendTouch(.ended, at: CGPoint(x: 30, y: 74), timestamp: 0.55)
        XCTAssertTrue(screen.toggle.isOn)
        XCTAssertEqual(screen.last, "enabledChanged:true")

        window.sendTouch(.began, at: CGPoint(x: 100, y: 170), timestamp: 1.0)
        window.sendTouch(.ended, at: CGPoint(x: 100, y: 170), timestamp: 1.05)
        XCTAssertEqual(screen.count, 2)
        XCTAssertEqual(screen.last, "handleTap:")
    }
}

// MARK: - Genuine #selector source (Darwin only)

#if canImport(ObjectiveC)
/// On Darwin `Selector` IS the platform's ObjC selector, so this file's
/// `#selector(...)` expressions are the real thing -- the same expressions a
/// UIKit app writes. Off Darwin neither `@objc` nor `#selector` compiles at
/// all (docs/OBJC_RUNTIME.md), which is why this block is conditional.
@MainActor
final class GenuineObjCSelectorTests: XCTestCase {
    @MainActor
    final class Target: SelectorDispatching {
        var log: [String] = []
        @objc func buttonTapped() { log.append("buttonTapped") }
        @objc func valueChanged(_ sender: AnyObject) { log.append("valueChanged") }

        static let actions: ActionTable<Target> = [
            .action("buttonTapped", Target.buttonTapped),
            .action("valueChanged:", Target.valueChangedImpl),
        ]
        func valueChangedImpl(_ sender: AnyObject) { valueChanged(sender) }
        func perform(_ name: String, with sender: Any?) -> Bool {
            Self.actions.perform(name, on: self, with: sender)
        }
    }

    /// Deliberately has no SelectorDispatching conformance. This is the shape
    /// of an unchanged UIKit controller: UIResponder's NSObject root and its
    /// @objc methods are the complete dispatch table.
    @MainActor
    final class RuntimeTarget: UIViewController {
        var log: [String] = []
        weak var picker: UIDatePicker?
        weak var sender: AnyObject?
        weak var event: AnyObject?

        @objc func noArguments() { log.append("runtime-0") }

        @objc func dateChanged(_ sender: UIDatePicker) {
            log.append("runtime-1")
            picker = sender
        }

        @objc func controlAction(_ sender: AnyObject, event: AnyObject?) {
            log.append("runtime-2")
            self.sender = sender
            self.event = event
        }
    }

    /// A runtime method wins when a target also supplies the portable table.
    /// The table remains the fallback for selectors absent from ObjC metadata.
    @MainActor
    final class DualPathTarget: UIViewController, SelectorDispatching {
        var log: [String] = []

        @objc func runtimeAction() { log.append("runtime") }

        func perform(_ name: String, with sender: Any?) -> Bool {
            _ = sender
            guard name == "portableAction" || name == "runtimeAction" else {
                return false
            }
            log.append("registry:\(name)")
            return true
        }
    }

    func testSelectorExpressionsProduceObjCNames() {
        XCTAssertEqual(#selector(Target.buttonTapped).actionName, "buttonTapped")
        XCTAssertEqual(#selector(Target.valueChanged(_:)).actionName,
                       "valueChanged:")
    }

    func testSelectorExpressionEqualsItsStringSpelling() {
        // The portable spelling and `#selector` are the same value, which is
        // what lets one source compile on both platforms.
        XCTAssertEqual(#selector(Target.buttonTapped), Selector.named("buttonTapped"))
        XCTAssertEqual(#selector(Target.valueChanged(_:)),
                       Selector.named("valueChanged:"))
    }

    func testGenuineUIKitSourceDrivesAControl() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 10, y: 10, width: 100, height: 40)
        window.addSubview(button)
        let target = Target()

        // Verbatim UIKit.
        button.addTarget(target, action: #selector(Target.buttonTapped),
                         for: .touchUpInside)

        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 30), timestamp: 0.1)
        XCTAssertEqual(target.log, ["buttonTapped"])
    }

    func testGenuineUIKitSourceDrivesAGestureRecognizer() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(view)
        let target = Target()
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: target,
                                   action: #selector(Target.valueChanged(_:))))
        window.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.05)
        XCTAssertEqual(target.log, ["valueChanged"])
    }

    func testNSObjectRuntimeDispatchesZeroOneAndTwoArgumentActions() {
        let target = RuntimeTarget()
        let picker = UIDatePicker()
        let event = UIEvent(timestamp: 17)

        picker.addTarget(target, action: #selector(RuntimeTarget.noArguments),
                         for: .touchDown)
        picker.addTarget(target, action: #selector(RuntimeTarget.dateChanged(_:)),
                         for: .valueChanged)
        picker.addTarget(
            target,
            action: #selector(RuntimeTarget.controlAction(_:event:)),
            for: .touchUpInside
        )

        picker.sendActions(for: .touchDown)
        picker.sendActions(for: .valueChanged)
        picker.sendActions(for: .touchUpInside, with: event)

        XCTAssertEqual(target.log, ["runtime-0", "runtime-1", "runtime-2"])
        XCTAssertTrue(target.picker === picker)
        XCTAssertTrue(target.sender === picker)
        XCTAssertTrue(target.event === event)
    }

    func testRuntimePrecedesRegistryAndRegistryRemainsFallback() {
        let target = DualPathTarget()
        XCTAssertTrue(SelectorDispatch.send(
            #selector(DualPathTarget.runtimeAction), to: target, sender: nil
        ))
        XCTAssertEqual(target.log, ["runtime"])

        XCTAssertTrue(SelectorDispatch.send(
            .named("portableAction"), to: target, sender: nil
        ))
        XCTAssertEqual(target.log, ["runtime", "registry:portableAction"])
    }
}
#endif
