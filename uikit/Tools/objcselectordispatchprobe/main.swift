// Native iOS 26.1 oracle for NSObject-root target/action behavior. This asks
// public UIKit directly; OpenUIKit is not linked into the oracle.

import Darwin
import Foundation
import ObjectiveC
import UIKit

private let bundleIdentifier = "com.openuikit.objcselectordispatchprobe"

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
        let documents = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]
        try! output.write(
            to: documents.appendingPathComponent("objcselectordispatchprobe.txt"),
            atomically: true,
            encoding: .utf8
        )
        FileHandle.standardOutput.write(Data(output.utf8))
        fflush(stdout)
        return failures.isEmpty ? 0 : 1
    }
}

@MainActor
private final class Target: UIViewController {
    var events: [String] = []
    weak var oneSender: UIDatePicker?
    weak var twoSender: UIDatePicker?
    var twoEventWasNil = false

    @objc func noArguments() { events.append("zero") }

    @objc func dateChanged(_ sender: UIDatePicker) {
        events.append("one")
        oneSender = sender
    }

    @objc func controlAction(_ sender: UIDatePicker, event: UIEvent?) {
        events.append("two")
        twoSender = sender
        twoEventWasNil = event == nil
    }
}

@MainActor
private func recordFacts(_ transcript: Transcript) {
    let picker = UIDatePicker()
    let target = Target()
    let alias = picker
    let other = UIDatePicker()
    let erasedPicker: Any = picker
    let erasedTarget: Any = target
    transcript.check("root.pickerNSObject",
                     erasedPicker is any NSObjectProtocol)
    transcript.check("root.controllerNSObject",
                     erasedTarget is any NSObjectProtocol)
    transcript.check("identity.setTwo", Set([picker, alias, other]).count == 2)

    let zero = #selector(Target.noArguments)
    let one = #selector(Target.dateChanged(_:))
    let two = #selector(Target.controlAction(_:event:))
    transcript.fact("selector.zero", NSStringFromSelector(zero))
    transcript.fact("selector.one", NSStringFromSelector(one))
    transcript.fact("selector.two", NSStringFromSelector(two))

    picker.addTarget(target, action: zero, for: .touchDown)
    picker.addTarget(target, action: one, for: .valueChanged)
    picker.addTarget(target, action: two, for: .touchUpInside)
    picker.sendActions(for: .touchDown)
    transcript.check("dispatch.zero", target.events == ["zero"])
    picker.sendActions(for: .valueChanged)
    transcript.check("dispatch.one", target.events == ["zero", "one"])
    picker.sendActions(for: .touchUpInside)
    transcript.check("dispatch.two", target.events == ["zero", "one", "two"])
    transcript.fact("dispatch.order", target.events.joined(separator: ","))
    transcript.check("dispatch.one.sender", target.oneSender === picker)
    transcript.check("dispatch.two.sender", target.twoSender === picker)
    transcript.check("dispatch.two.nilEvent", target.twoEventWasNil)

    let weakControl = UIControl()
    weak var weakTarget: Target?
    autoreleasepool {
        let disposable = Target()
        weakTarget = disposable
        weakControl.addTarget(
            disposable, action: #selector(Target.noArguments),
            for: .valueChanged
        )
        transcript.check("weak.beforeRelease", weakTarget != nil)
    }
    transcript.check("weak.afterRelease", weakTarget == nil)
    weakControl.sendActions(for: .valueChanged)
    transcript.check("weak.deadSendSafe", weakTarget == nil)
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
            recordFacts(transcript)
            let status = transcript.finish()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                Darwin.exit(status)
            }
        }
        return true
    }
}
