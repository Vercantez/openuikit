// A navigation controller's iOS 26 toolbar holding NetNewsWire's Feeds items
// (MainFeedCollectionViewController's storyboard "Toolbar Items" plus the
// Current Activity button it inserts at index 1): Settings (title + "gear"),
// "text.pad.header", a flexible space, Add (title + "plus"). Variant B mixes a
// title-only item. The navigation bar carries a title + image item too. Prints the toolbar's frame, the child's safe area, and
// every view under the navigation controller's view that draws the items:
// window frames, label texts and image sizes. iPhone 16 / iOS 26.1.
import UIKit

func r(_ f: CGRect) -> String {
    String(format: "[%.2f, %.2f, %.2f, %.2f]", f.minX, f.minY, f.width, f.height)
}

final class VC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Feeds"
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isToolbarHidden = false
        super.viewWillAppear(animated)
    }
}

func items(_ variant: String) -> [UIBarButtonItem] {
    let flex = UIBarButtonItem.flexibleSpace()
    if variant == "B" {
        return [UIBarButtonItem(title: "Edit", style: .plain, target: nil, action: nil), flex,
                UIBarButtonItem(title: "Add", image: UIImage(systemName: "plus"), target: nil, action: nil)]
    }
    let settings = UIBarButtonItem(title: "Settings", image: UIImage(systemName: "gear"), target: nil, action: nil)
    let activity = UIBarButtonItem(image: UIImage(systemName: "text.pad.header"), style: .plain, target: nil, action: nil)
    // the storyboard's flexible space archives UIHidesSharedBG = true
    flex.hidesSharedBackground = true
    let add = UIBarButtonItem(title: "Add", image: UIImage(systemName: "plus"), target: nil, action: nil)
    return [settings, activity, flex, add]
}

func dump(_ v: UIView, in window: UIWindow, depth: Int) {
    for s in v.subviews {
        let name = String(describing: type(of: s))
        var extra = ""
        if let l = s as? UILabel { extra += " text=\(l.text ?? "nil") font=\(l.font.pointSize)" }
        if let iv = s as? UIImageView, let img = iv.image {
            extra += " image=\(img.size) symbol=\(img.isSymbolImage) intrinsic=\(iv.intrinsicContentSize)"
            extra += " preferred=\(iv.preferredSymbolConfiguration.map { "\($0)" } ?? "nil")"
            extra += " imageConfig=\(img.symbolConfiguration.map { "\($0)" } ?? "nil")"
            extra += " contentMode=\(iv.contentMode.rawValue) tint=\(iv.tintColor.map { "\($0)" } ?? "nil")"
        }
        if let b = s as? UIButton { extra += " title=\(b.currentTitle ?? "nil") image=\(b.currentImage?.size ?? .zero)" }
        let f = s.convert(s.bounds, to: window)
        let navBarContent = f.minY >= 50 && f.maxY <= 110 && (name.contains("Button") || s is UILabel || s is UIImageView)
        if f.minY > 700 || name.contains("Toolbar") || name.contains("FloatingBar") || navBarContent {
            print("FACT view \(String(repeating: " ", count: depth))\(name) \(r(f)) hidden=\(s.isHidden) alpha=\(s.alpha)\(extra)")
        }
        if depth < 24 { dump(s, in: window, depth: depth + 1) }
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let variant = ProcessInfo.processInfo.environment["VARIANT"] ?? "A"
        let vc = VC()
        vc.toolbarItems = items(variant)
        // A navigation-bar item with both a title and an image (the same
        // question for the top bar).
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Filter", image: UIImage(systemName: "line.3.horizontal.decrease"), target: nil, action: nil)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = nav
        w.makeKeyAndVisible()
        window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("FACT variant=\(variant) toolbar=\(r(nav.toolbar.frame)) hidden=\(nav.toolbar.isHidden) inWindow=\(nav.toolbar.window != nil) superview=\(nav.toolbar.superview.map { "\(type(of: $0))" } ?? "nil")")
            print("FACT child safeArea=\(vc.view.safeAreaInsets) frame=\(r(vc.view.frame))")
            for (i, item) in (vc.toolbarItems ?? []).enumerated() {
                print("FACT item\(i) title=\(item.title ?? "nil") image=\(item.image != nil) hidesSharedBackground=\(item.hidesSharedBackground) sharesBackground=\(item.sharesBackground)")
            }
            dump(nav.view, in: w, depth: 0)
            print("DONE")
            exit(0)
        }
        return true
    }
}
