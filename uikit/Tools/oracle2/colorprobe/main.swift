// ColorProbe on REAL iOS: resolves every semantic UIColor the port's
// Resources/system_colors.json carries (the keys are read from a copy of that
// file in the app bundle) for the light and dark styles and writes
// <Documents>/system_colors_ios.json in the same {"light": {name: [r,g,b,a]},
// "dark": {...}} shape. Why: system_colors.json was measured on Mac Catalyst,
// whose dark palette differs from iOS (systemBackground dark is #1E1E1E on
// Catalyst and #000000 on iOS; measured 2026-09-04 when the whole scene suite
// was first captured on the iOS 26.1 simulator).
// Run: scripts/color_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

func r6(_ v: CGFloat) -> Double { (Double(v) * 1_000_000).rounded() / 1_000_000 }

func resolve(_ name: String, style: UIUserInterfaceStyle) -> [Double]? {
    // Swift `UIColor.systemBackground` is ObjC `+[UIColor systemBackgroundColor]`.
    let sel = NSSelectorFromString(name + "Color")
    guard UIColor.responds(to: sel),
          let any = UIColor.perform(sel)?.takeUnretainedValue() as? UIColor else { return nil }
    let traits = UITraitCollection(userInterfaceStyle: style)
    let c = any.resolvedColor(with: traits)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard c.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
    return [r6(r), r6(g), r6(b), r6(a)]
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        w.rootViewController = UIViewController()
        w.makeKeyAndVisible()
        let src = Bundle.main.path(forResource: "system_colors", ofType: "json")!
        let table = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: src))) as! [String: Any]
        var names = Set<String>()
        for style in ["light", "dark"] { for k in (table[style] as? [String: Any] ?? [:]).keys { names.insert(k) } }
        var out: [String: Any] = [:]
        var missing: [String] = []
        for (styleName, style) in [("light", UIUserInterfaceStyle.light), ("dark", .dark)] {
            var m: [String: Any] = [:]
            for n in names.sorted() {
                if let v = resolve(n, style: style) { m[n] = v } else if styleName == "light" { missing.append(n) }
            }
            out[styleName] = m
        }
        out["missing"] = missing
        out["device"] = ["system": UIDevice.current.systemVersion, "model": UIDevice.current.model]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys, .prettyPrinted])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/system_colors_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
