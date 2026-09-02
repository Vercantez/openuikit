// Literal-UIKit Foundation-hidden ARM64 Mach-O runtime micro-oracle. This is
// compiled by a Linux Swift 6.2.4 host and executed on Linux through machorun.
#if canImport(Foundation)
#error("the guest must not see the Foundation umbrella")
#endif
#if !canImport(FoundationEssentials)
#error("the guest requires the pinned FoundationEssentials provider")
#endif
#if !canImport(ObjectiveC)
#error("the guest requires the staged ObjectiveC module")
#endif

import UIKit

@MainActor
private final class RuntimeTarget: UIViewController {
    var events: [String] = []
    weak var oneSender: UIDatePicker?
    weak var twoSender: UIButton?
    weak var twoEvent: AnyObject?

    @objc func noArguments() { events.append("zero") }

    @objc func dateChanged(_ sender: UIDatePicker) {
        events.append("one")
        oneSender = sender
    }

    @objc func controlAction(_ sender: UIButton, event: AnyObject?) {
        events.append("two")
        twoSender = sender
        twoEvent = event
    }
}

@MainActor
private final class DualPathTarget: UIViewController, SelectorDispatching {
    var events: [String] = []

    @objc func runtimeAction() { events.append("runtime") }

    func perform(_ name: String, with sender: Any?) -> Bool {
        _ = sender
        guard name == "portableAction" || name == "runtimeAction" else {
            return false
        }
        events.append("registry:\(name)")
        return true
    }
}

@MainActor
private final class EndEditingSpy: UIView {
    var forces: [Bool] = []
    override func endEditing(_ force: Bool) -> Bool {
        forces.append(force)
        return false
    }
}

@main
private struct GuestMain {
    @MainActor
    static func main() {
        var failures: [String] = []
        func check(_ name: String, _ condition: @autoclosure () -> Bool) {
            let passed = condition()
            print("\(name)=\(passed ? "true" : "false")")
            if !passed { failures.append(name) }
        }

        print("GUEST_BEGIN")
        let picker = UIDatePicker()
        let alias = picker
        let other = UIDatePicker()
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 10, y: 10, width: 100, height: 40)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.addSubview(button)
        let target = RuntimeTarget()
        let erasedPicker: Any = picker
        let erasedTarget: Any = target
        check("root.pickerNSObject", erasedPicker is NSObjectProtocol)
        check("root.controllerNSObject", erasedTarget is NSObjectProtocol)
        check("identity.setTwo", Set([picker, alias, other]).count == 2)

        let zero = #selector(RuntimeTarget.noArguments)
        let one = #selector(RuntimeTarget.dateChanged(_:))
        let two = #selector(RuntimeTarget.controlAction(_:event:))
        check("runtime.respondsZero", target.responds(to: zero))
        check("runtime.respondsOne", target.responds(to: one))
        check("runtime.respondsTwo", target.responds(to: two))
        picker.addTarget(target, action: zero, for: .touchDown)
        picker.addTarget(target, action: one, for: .valueChanged)
        var closureEvent: UIEvent?
        _ = button.addTarget(for: .touchUpInside) { _, event in
            closureEvent = event
        }
        button.addTarget(target, action: two, for: .touchUpInside)
        picker.sendActions(for: .touchDown)
        picker.sendActions(for: .valueChanged)
        window.sendTouch(.began, at: CGPoint(x: 50, y: 30), timestamp: 16)
        window.sendTouch(.ended, at: CGPoint(x: 50, y: 30), timestamp: 17)
        check("runtime.order", target.events == ["zero", "one", "two"])
        check("runtime.oneSender", target.oneSender === picker)
        check("runtime.twoSender", target.twoSender === button)
        check("runtime.twoEvent", target.twoEvent === closureEvent)
        check("runtime.twoEventTimestamp", closureEvent?.timestamp == 17)

        let dual = DualPathTarget()
        check("precedence.runtimeSend", SelectorDispatch.send(
            #selector(DualPathTarget.runtimeAction), to: dual, sender: nil
        ))
        check("precedence.runtimeWon", dual.events == ["runtime"])
        check("fallback.registrySend", SelectorDispatch.send(
            .named("portableAction"), to: dual, sender: nil
        ))
        check("fallback.registryWon",
              dual.events == ["runtime", "registry:portableAction"])

        let spy = EndEditingSpy()
        check("builtin.resolved", SelectorDispatch.send(
            #selector(UIView.endEditing), to: spy, sender: picker
        ))
        check("builtin.falseOnce", spy.forces == [false])

        let weakControl = UIControl()
        weak var weakTarget: RuntimeTarget?
        func registerDisposableTarget() {
            let disposable = RuntimeTarget()
            weakTarget = disposable
            weakControl.addTarget(
                disposable, action: #selector(RuntimeTarget.noArguments),
                for: .valueChanged
            )
            check("weak.beforeRelease", weakTarget != nil)
        }
        registerDisposableTarget()
        check("weak.afterRelease", weakTarget == nil)
        weakControl.sendActions(for: .valueChanged)
        check("weak.deadSendSafe", weakTarget == nil)

        print("guest.status=\(failures.isEmpty ? "PASS" : "FAIL")")
        if !failures.isEmpty {
            print("guest.failures=\(failures.joined(separator: ","))")
        }
        print("GUEST_END")
        precondition(failures.isEmpty)
    }
}
