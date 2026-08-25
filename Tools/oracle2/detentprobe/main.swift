// DetentProbe: real-iOS geometry of UISheetPresentationController DETENTS.
//
// OpenUIKit's sheet was a single fixed pageSheet (M11, measured). Real apps
// size the sheet with `detents` -- including `.custom { context in ... }`,
// which is how pocket-casts' options picker sizes itself to its content
// (docs/REAL_APP_TEST.md). This probe pins down the three numbers that
// implementation needs and that cannot be derived from the documentation:
//
//   1. what `context.maximumDetentValue` actually IS for a given container
//   2. where the sheet's top edge lands for a given detent height, i.e.
//      whether the detent measures the sheet or the visible content
//   3. how a returned value larger than the maximum, or smaller than the
//      minimum UIKit allows, is clamped
//
// It presents a `.formSheet` on an iPhone-sized window (where UIKit resolves
// formSheet to the same sheet as pageSheet) once per case and dumps the
// presented view's window-space frame.
//
// Output: <Documents>/detents_ios.json
// Run: scripts/detent_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

final class Content: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

enum Case {
    case large, medium
    case custom(CGFloat)
    var name: String {
        switch self {
        case .large: return "large"
        case .medium: return "medium"
        case .custom(let v): return "custom-\(v)"
        }
    }
}

let cases: [Case] = [
    .large, .medium,
    .custom(100), .custom(144), .custom(200), .custom(288), .custom(300),
    .custom(400), .custom(500), .custom(600), .custom(700),
    .custom(10_000),   // way over the maximum -- how is it clamped?
    .custom(10),       // way under -- is there a floor?
]

var results: [[String: Any]] = []

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var root: UIViewController!

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        root = UIViewController()
        root.view.backgroundColor = .darkGray
        w.rootViewController = root
        w.makeKeyAndVisible()
        window = w
        run(index: 0)
        return true
    }

    func run(index: Int) {
        guard index < cases.count else { finish(); return }
        let c = cases[index]
        let vc = Content()
        vc.modalPresentationStyle = .formSheet
        var captured: [String: Any] = ["case": c.name]
        if let sheet = vc.sheetPresentationController {
            switch c {
            case .large: sheet.detents = [.large()]
            case .medium: sheet.detents = [.medium()]
            case .custom(let v):
                sheet.detents = [.custom { ctx in
                    captured["maximumDetentValue"] = Double(ctx.maximumDetentValue)
                    captured["containerHSizeClass"] =
                        ctx.containerTraitCollection.horizontalSizeClass.rawValue
                    captured["containerVSizeClass"] =
                        ctx.containerTraitCollection.verticalSizeClass.rawValue
                    return v
                }]
            }
        }
        root.present(vc, animated: false) { [weak self] in
          // The sheet settles over a couple of frames even for a non-animated
          // present, so sample after it has come to rest.
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard let self, let w = self.window else { return }
            let pv = vc.presentationController?.presentedView ?? vc.view!
            let f = pv.convert(pv.bounds, to: w)
            captured["windowSize"] = [Double(w.bounds.width), Double(w.bounds.height)]
            captured["windowSafeArea"] = [Double(w.safeAreaInsets.top),
                                          Double(w.safeAreaInsets.left),
                                          Double(w.safeAreaInsets.bottom),
                                          Double(w.safeAreaInsets.right)]
            captured["presentedFrame"] = [Double(f.minX), Double(f.minY),
                                          Double(f.width), Double(f.height)]
            captured["cornerRadius"] = Double(pv.layer.cornerRadius)
            let cf = vc.view.convert(vc.view.bounds, to: w)
            captured["contentFrame"] = [Double(cf.minX), Double(cf.minY),
                                        Double(cf.width), Double(cf.height)]
            captured["contentSafeArea"] = [Double(vc.view.safeAreaInsets.top),
                                           Double(vc.view.safeAreaInsets.left),
                                           Double(vc.view.safeAreaInsets.bottom),
                                           Double(vc.view.safeAreaInsets.right)]
            results.append(captured)
            self.root.dismiss(animated: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.run(index: index + 1)
                }
            }
          }
        }
    }

    func finish() {
        let data = try! JSONSerialization.data(withJSONObject: ["cases": results],
                                               options: [.sortedKeys, .prettyPrinted])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/detents_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
    }
}
let delegateClassName = NSStringFromClass(AppDelegate.self)
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName)
