// LayoutProbe on REAL iOS: Auto Layout tie-break oracle.
//
// Why: the real-app screen (Tools/oracle2/realappprobe) showed a row with
// two labels of EQUAL content-hugging priority where real UIKit lets the
// leading label hug its content and stretches the trailing one, while
// OpenUIKit's Cassowary did the opposite (measured 2026-09-04: "Wi-Fi only"
// at x 127.667 on iOS vs 297 in the port). A tie has no LP-optimal answer;
// the engine's pivoting decides. This probe pins down UIKit's choice over
// the variations that could plausibly drive it: constraint order, subview
// order, label count, axis, and equal-priority compression.
//
// Output: <Documents>/layoutprobe.json = {"scenarios": [{"name", "views":
// [{"tag", "frame", "intrinsic"}]}]} then DONE.
// Run: scripts/layout_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        w.rootViewController = vc
        w.makeKeyAndVisible()
        var out: [[String: Any]] = []
        for (i, s) in layoutScenarios.enumerated() {
            let tagged = runLayoutScenario(s, in: vc.view, index: i)
            let views: [[String: Any]] = tagged.map { (tag, v) in
                let f = v.frame, i = v.intrinsicContentSize
                return ["tag": tag, "class": String(describing: type(of: v)),
                        "frame": [r3(f.origin.x), r3(f.origin.y), r3(f.width), r3(f.height)],
                        "intrinsic": [i.width == UIView.noIntrinsicMetric ? -1 : r3(i.width),
                                      i.height == UIView.noIntrinsicMetric ? -1 : r3(i.height)],
                        "hugH": r3(CGFloat(v.contentHuggingPriority(for: .horizontal).rawValue)),
                        "resistH": r3(CGFloat(v.contentCompressionResistancePriority(for: .horizontal).rawValue))]
            }
            out.append(["name": s.name, "views": views])
        }
        let data = try! JSONSerialization.data(withJSONObject: ["screen": ["scale": Double(UIScreen.main.scale)], "scenarios": out],
                                               options: [.sortedKeys, .prettyPrinted])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/layoutprobe.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
