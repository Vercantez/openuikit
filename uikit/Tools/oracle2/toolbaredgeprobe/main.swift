// The untouched (`.automatic`) bottom scroll-edge effect under a navigation
// controller's iOS 26 toolbar, over known colours, as the golden captures see
// it: the key window's drawHierarchy (afterScreenUpdates: NO, screen scale),
// the same route as Tools/oracle2/nnwgolden/LayoutDump.m.
//
// A full-screen UIScrollView (content 2400 pt, so it runs under the toolbar at
// rest) is filled with BACKDROP (white / gray = secondary-grouped
// 242,242,247 / black) and carries seven 20 pt colour columns at x 150–290:
// white, 242/242/247, 200 gray, 128 gray, black, red, systemBlue. The
// toolbar holds NetNewsWire's Feeds items (gear + text.pad.header run, flex,
// plus). Writes Documents/edge-<BACKDROP>.png and prints the bottom
// ScrollEdgeEffectView subtree (frames, alpha, hidden). iPhone 16 / iOS 26.1.
import UIKit

let columns: [(String, UIColor)] = [
    ("white", .white),
    ("gray242", UIColor(red: 242 / 255, green: 242 / 255, blue: 247 / 255, alpha: 1)),
    ("gray200", UIColor(white: 200 / 255, alpha: 1)),
    ("gray128", UIColor(white: 128 / 255, alpha: 1)),
    ("black", .black),
    ("red", UIColor(red: 1, green: 0, blue: 0, alpha: 1)),
    ("blue", UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1)),
]

final class VC: UIViewController {
    let scroll = UIScrollView()
    override func loadView() { view = scroll }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edge"
        let backdrop = ProcessInfo.processInfo.environment["BACKDROP"] ?? "white"
        scroll.backgroundColor = backdrop == "black" ? .black
            : backdrop == "gray" ? UIColor(red: 242 / 255, green: 242 / 255, blue: 247 / 255, alpha: 1) : .white
        scroll.contentSize = CGSize(width: 393, height: 2400)
        for (i, (_, color)) in columns.enumerated() {
            let v = UIView(frame: CGRect(x: 150 + 20 * CGFloat(i), y: 0, width: 20, height: 2400))
            v.backgroundColor = color
            scroll.addSubview(v)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isToolbarHidden = false
        super.viewWillAppear(animated)
    }
}

func r(_ f: CGRect) -> String { String(format: "[%.2f, %.2f, %.2f, %.2f]", f.minX, f.minY, f.width, f.height) }

func dumpEdge(_ v: UIView, in w: UIWindow, depth: Int, inside: Bool) {
    for s in v.subviews {
        let name = String(describing: type(of: s))
        let isEdge = inside || name.contains("ScrollEdgeEffect")
        let f = s.convert(s.bounds, to: w)
        if isEdge && f.maxY > 600 {
            print("FACT edge \(String(repeating: " ", count: depth))\(name) \(r(f)) alpha=\(s.alpha) hidden=\(s.isHidden) filters=\(s.layer.filters?.count ?? 0) bg=\(s.backgroundColor.map { "\($0)" } ?? "nil")")
        }
        dumpEdge(s, in: w, depth: depth + 1, inside: isEdge)
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let backdrop = ProcessInfo.processInfo.environment["BACKDROP"] ?? "white"
        let vc = VC()
        let gear = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: nil, action: nil)
        let activity = UIBarButtonItem(image: UIImage(systemName: "text.pad.header"), style: .plain, target: nil, action: nil)
        let add = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)
        vc.toolbarItems = [gear, activity, .flexibleSpace(), add]
        let nav = UINavigationController(rootViewController: vc)
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = nav
        w.makeKeyAndVisible()
        window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            print("FACT backdrop=\(backdrop) offset=\(vc.scroll.contentOffset) adjusted=\(vc.scroll.adjustedContentInset) bottomEffect=\(vc.scroll.bottomEdgeEffect.style) hidden=\(vc.scroll.bottomEdgeEffect.isHidden)")
            for (i, (name, _)) in columns.enumerated() { print("FACT column \(name) x=\(150 + 20 * i)..\(170 + 20 * i)") }
            dumpEdge(w, in: w, depth: 0, inside: false)
            let format = UIGraphicsImageRendererFormat(for: w.traitCollection)
            format.scale = w.screen.scale
            let png = UIGraphicsImageRenderer(bounds: w.bounds, format: format).pngData { _ in
                w.drawHierarchy(in: w.bounds, afterScreenUpdates: false)
            }
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try? png.write(to: docs.appendingPathComponent("edge-\(backdrop).png"))
            print("FACT wrote edge-\(backdrop).png \(png.count)")
            print("DONE")
            exit(0)
        }
        return true
    }
}
