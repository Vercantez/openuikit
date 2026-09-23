// textviewinputprobe — the Apple side of Tests/OpenUIKitTests/TextViewTextInputTests
// and RxRowsTests. Runs the shared scenarios (Tests/OpenUIKitTests/
// TextViewTextInputScenario.swift and RxRowsScenario.swift, compiled here with
// -D OUK_ORACLE) inside a real app with a key window and writes
// Documents/transcript.txt; run.sh copies it to transcript-ios26.1.txt.
import UIKit

private func settle() { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2)) }

final class ProbeApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        // Crash probes: one launch each; run.sh records the exception reason.
        if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--crash=") }) {
            let sc = UISegmentedControl(items: ["a", "b", "c"])
            switch arg {
            case "--crash=setEnabled7": sc.setEnabled(false, forSegmentAt: 7)
            case "--crash=setEnabled-1": sc.setEnabled(false, forSegmentAt: -1)
            case "--crash=isEnabled7": print("NO CRASH isEnabledForSegment(at: 7)=\(sc.isEnabledForSegment(at: 7))")
            case "--crash=isEnabled-1": print("NO CRASH isEnabledForSegment(at: -1)=\(sc.isEnabledForSegment(at: -1))")
            default: break
            }
            print("NO CRASH \(arg)")
            exit(0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var out = ["# textviewinputprobe — iOS \(UIDevice.current.systemVersion)", "## textview"]
            out += OUKTextViewInputScenario.run(host: vc.view, settle: settle)
            out.append("## rxrows")
            out += OUKRxRowsScenario.run(host: vc.view, settle: settle)
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("transcript.txt")
            try? (out.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
            print(out.joined(separator: "\n"))
            exit(0)
        }
        return true
    }
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(ProbeApp.self))
