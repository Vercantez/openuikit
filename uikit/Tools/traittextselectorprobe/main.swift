// Native iOS 26.1 oracle for the bounded Reminder trait/text/selector slice.
// This intentionally measures public UIKit behavior, not OpenUIKit.

import Darwin
import Foundation
import ObjectiveC
import UIKit

private let bundleIdentifier = "com.openuikit.traittextselectorprobe"

@MainActor
private final class Transcript {
    private var lines: [String] = []
    private var failures: [String] = []

    func fact(_ key: String, _ value: String) {
        lines.append("\(key)=\(value)")
    }

    func check(_ key: String, _ condition: @autoclosure () -> Bool) {
        let passed = condition()
        lines.append("\(key)=\(passed ? "true" : "false")")
        if !passed { failures.append(key) }
    }

    func finish() -> Int32 {
        var final = ["ORACLE_BEGIN"]
        final.append(contentsOf: lines)
        final.append("oracle.status=\(failures.isEmpty ? "PASS" : "FAIL")")
        if !failures.isEmpty {
            final.append("oracle.failures=\(failures.joined(separator: ","))")
        }
        final.append("ORACLE_END")
        let output = final.joined(separator: "\n") + "\n"
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0]
        try! output.write(
            to: documents.appendingPathComponent("traittextselectorprobe.txt"),
            atomically: true,
            encoding: .utf8
        )
        FileHandle.standardOutput.write(Data(output.utf8))
        fflush(stdout)
        return failures.isEmpty ? 0 : 1
    }
}

@MainActor
private final class DenyingTextFieldDelegate: NSObject, UITextFieldDelegate {
    var shouldEndCalls = 0
    var didEndCalls = 0

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        shouldEndCalls += 1
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        didEndCalls += 1
    }
}

@MainActor
private final class EndEditingSpyView: UIView {
    var receivedForces: [Bool] = []

    override func endEditing(_ force: Bool) -> Bool {
        receivedForces.append(force)
        return false
    }
}

@MainActor
private final class TraitOrderController: UIViewController {
    var events: [String] = []
    var recordsLegacy = false

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if recordsLegacy { events.append("legacy") }
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

@MainActor
private func recordTextFacts(_ transcript: Transcript) {
    let textView = UITextView(frame: .zero)
    let initial: String? = textView.text
    transcript.check("text.initial.nonNil", initial != nil)
    transcript.check("text.initial.empty", initial == "")

    textView.text = "alpha"
    let assigned: String? = textView.text
    transcript.check("text.assigned.alpha", assigned == "alpha")

    textView.text = nil
    let reset: String? = textView.text
    transcript.check("text.afterNil.nonNil", reset != nil)
    transcript.check("text.afterNil.empty", reset == "")
    transcript.check("text.responds.get",
                     textView.responds(to: NSSelectorFromString("text")))
    transcript.check("text.responds.set",
                     textView.responds(to: NSSelectorFromString("setText:")))
}

@MainActor
private func recordEndEditingFacts(
    _ transcript: Transcript,
    hostView: UIView
) -> () -> Void {
    let selector = NSSelectorFromString("endEditing:")
    transcript.fact("end.selector", NSStringFromSelector(selector))
    transcript.check("end.instancesRespond", UIView.instancesRespond(to: selector))
    if let method = class_getInstanceMethod(UIView.self, selector) {
        transcript.check("end.method.present", true)
        transcript.fact(
            "end.method.encoding",
            method_getTypeEncoding(method).map(String.init(cString:)) ?? "<nil>"
        )
    } else {
        transcript.check("end.method.present", false)
        transcript.fact("end.method.encoding", "<nil>")
    }

    var directOnUIView = false
    var methodCount: UInt32 = 0
    if let methods = class_copyMethodList(UIView.self, &methodCount) {
        defer { free(methods) }
        for index in 0..<Int(methodCount)
        where method_getName(methods[index]) == selector {
            directOnUIView = true
        }
    }
    transcript.check("end.runtimeDirectOnUIView", directOnUIView)

    let container = UIView(frame: CGRect(x: 0, y: 0, width: 240, height: 100))
    let field = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
    let delegate = DenyingTextFieldDelegate()
    field.delegate = delegate
    container.addSubview(field)
    hostView.addSubview(container)
    transcript.check("end.direct.becomeFirst", field.becomeFirstResponder())
    transcript.check("end.direct.before.isFirst", field.isFirstResponder)

    transcript.check("end.direct.false.return", !container.endEditing(false))
    transcript.check("end.direct.false.isFirst", field.isFirstResponder)
    transcript.check("end.direct.false.shouldOnce", delegate.shouldEndCalls == 1)
    transcript.check("end.direct.false.didZero", delegate.didEndCalls == 0)

    transcript.check("end.direct.true.return", container.endEditing(true))
    transcript.check("end.direct.true.isFirst", field.isFirstResponder)
    transcript.check("end.direct.true.shouldTwice", delegate.shouldEndCalls == 2)
    transcript.check("end.direct.true.didZero", delegate.didEndCalls == 0)
    container.removeFromSuperview()
    transcript.check("end.none.return", UIView().endEditing(false))

    let actionContainer = UIView(frame: CGRect(x: 0, y: 0, width: 240, height: 100))
    let actionField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
    let actionDelegate = DenyingTextFieldDelegate()
    actionField.delegate = actionDelegate
    actionContainer.addSubview(actionField)
    hostView.addSubview(actionContainer)
    let actionSelector = #selector(UIView.endEditing)
    let recognizer = UITapGestureRecognizer(target: actionContainer,
                                            action: actionSelector)
    actionContainer.addGestureRecognizer(recognizer)
    transcript.fact("end.action.selector", NSStringFromSelector(actionSelector))
    transcript.check("end.action.becomeFirst", actionField.becomeFirstResponder())
    transcript.check("end.action.before.isFirst", actionField.isFirstResponder)
    transcript.check(
        "end.action.dispatched",
        UIApplication.shared.sendAction(
            actionSelector, to: actionContainer, from: recognizer, for: nil
        )
    )
    transcript.check("end.action.after.isFirst", actionField.isFirstResponder)
    transcript.check("end.action.shouldOnce", actionDelegate.shouldEndCalls == 1)
    transcript.check("end.action.didZero", actionDelegate.didEndCalls == 0)

    let spy = EndEditingSpyView(frame: .zero)
    let spyRecognizer = UITapGestureRecognizer(target: spy, action: actionSelector)
    spy.addGestureRecognizer(spyRecognizer)
    transcript.check(
        "end.spy.dispatched",
        UIApplication.shared.sendAction(
            actionSelector, to: spy, from: spyRecognizer, for: nil
        )
    )
    transcript.check("end.spy.calledOnce", spy.receivedForces == [false])

    return {
        transcript.check("end.action.delayed.isFirst", actionField.isFirstResponder)
        transcript.check("end.action.delayed.shouldOnce",
                         actionDelegate.shouldEndCalls == 1)
        transcript.check("end.action.delayed.didZero", actionDelegate.didEndCalls == 0)
        actionContainer.removeFromSuperview()
    }
}

@MainActor
private func attach(_ controller: UIViewController,
                    to parent: UIViewController) -> UIViewController {
    controller.view.frame = CGRect(x: 0, y: 120, width: 100, height: 100)
    parent.addChild(controller)
    parent.view.addSubview(controller.view)
    controller.didMove(toParent: parent)
    controller.traitOverrides.userInterfaceStyle = .light
    controller.updateTraitsIfNeeded()
    return controller
}

@MainActor
private func makeController(in parent: UIViewController) -> UIViewController {
    attach(UIViewController(), to: parent)
}

@MainActor
private func recordTraitFacts(_ transcript: Transcript, root: UIViewController) {
    let controller = TraitOrderController()
    _ = attach(controller, to: root)
    transcript.check("trait.initial.light",
                     controller.traitCollection.userInterfaceStyle == .light)
    controller.events.removeAll()

    var callbackCount = 0
    var callbackTransitions: [String] = []
    let registration = controller.registerForTraitChanges(
        [UITraitUserInterfaceStyle.self]
    ) { (environment: UIViewController, previous: UITraitCollection) in
        callbackCount += 1
        controller.events.append("handler")
        callbackTransitions.append(
            "\(previous.userInterfaceStyle.rawValue)>"
                + "\(environment.traitCollection.userInterfaceStyle.rawValue)"
        )
        transcript.check("trait.callback.\(callbackCount).same",
                         environment === controller)
        transcript.check("trait.callback.\(callbackCount).main", Thread.isMainThread)
    }
    transcript.check("trait.afterRegister.noInitial", callbackCount == 0)

    controller.recordsLegacy = true
    controller.traitOverrides.userInterfaceStyle = .dark
    transcript.check("trait.darkSetter.synchronous", callbackCount == 1)
    transcript.fact("trait.directStyle.order",
                    controller.events.joined(separator: ","))
    controller.recordsLegacy = false
    controller.updateTraitsIfNeeded()
    transcript.check("trait.darkUpdate.noDuplicate", callbackCount == 1)

    controller.traitOverrides.userInterfaceStyle = .dark
    controller.updateTraitsIfNeeded()
    transcript.check("trait.sameDark.silent", callbackCount == 1)

    controller.traitOverrides.horizontalSizeClass = .compact
    controller.updateTraitsIfNeeded()
    transcript.check("trait.unrelated.silent", callbackCount == 1)

    controller.traitOverrides.userInterfaceStyle = .light
    transcript.check("trait.lightSetter.synchronous", callbackCount == 2)
    controller.updateTraitsIfNeeded()
    transcript.check("trait.lightUpdate.noDuplicate", callbackCount == 2)
    transcript.fact("trait.transitions", callbackTransitions.joined(separator: ","))

    controller.unregisterForTraitChanges(registration)
    controller.traitOverrides.userInterfaceStyle = .dark
    controller.updateTraitsIfNeeded()
    transcript.check("trait.unregister.suppresses", callbackCount == 2)

    let droppedController = makeController(in: root)
    var droppedCount = 0
    var droppedRegistration: (any UITraitChangeRegistration)? =
        droppedController.registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (_: UIViewController, _: UITraitCollection) in droppedCount += 1
        }
    weak var weakDroppedToken = droppedRegistration as AnyObject?
    transcript.check("trait.dropped.beforeRelease.alive", weakDroppedToken != nil)
    droppedRegistration = nil
    transcript.check("trait.dropped.afterRelease.alive", weakDroppedToken != nil)
    droppedController.traitOverrides.userInterfaceStyle = .dark
    droppedController.updateTraitsIfNeeded()
    transcript.check("trait.dropped.change.delivered", droppedCount == 1)
    transcript.check("trait.dropped.afterChange.alive", weakDroppedToken != nil)
}

@main
@MainActor
private final class ProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = application
        _ = launchOptions
        precondition(Bundle.main.bundleIdentifier == bundleIdentifier)

        let root = UIViewController()
        root.view.backgroundColor = .white
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window

        DispatchQueue.main.async {
            let transcript = Transcript()
            let version = ProcessInfo.processInfo.operatingSystemVersion
            transcript.check("runtime.ios26_1", version.majorVersion == 26
                             && version.minorVersion == 1)
            transcript.check("runtime.main", Thread.isMainThread)
            recordTextFacts(transcript)
            let finishEndEditing = recordEndEditingFacts(transcript,
                                                         hostView: root.view)
            recordTraitFacts(transcript, root: root)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                finishEndEditing()
                let status = transcript.finish()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    Darwin.exit(status)
                }
            }
        }
        return true
    }
}
