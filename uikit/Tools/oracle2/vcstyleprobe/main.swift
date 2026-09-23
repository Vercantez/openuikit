// UIViewController.overrideUserInterfaceStyle (NetNewsWire
// WebViewController.swift:940, MainFeedCollectionViewController.swift:683,
// set on an SFSafariViewController before presenting). iPhone 16 / iOS 26.1.
import UIKit

func s(_ st: UIUserInterfaceStyle) -> String {
    switch st { case .light: return "light"; case .dark: return "dark"; case .unspecified: return "unspecified"; @unknown default: return "?" }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        let root = UIViewController()
        w.rootViewController = root
        w.makeKeyAndVisible()
        window = w

        let vc = UIViewController()
        print("FACT default override=\(s(vc.overrideUserInterfaceStyle)) isViewLoaded=\(vc.isViewLoaded)")
        vc.overrideUserInterfaceStyle = .dark
        print("FACT after set (unloaded): override=\(s(vc.overrideUserInterfaceStyle)) isViewLoaded=\(vc.isViewLoaded) vc.trait=\(s(vc.traitCollection.userInterfaceStyle))")
        let sub = UIView()
        vc.view.addSubview(sub)
        print("FACT loaded, detached: view.override=\(s(vc.view.overrideUserInterfaceStyle)) view.trait=\(s(vc.view.traitCollection.userInterfaceStyle)) sub.trait=\(s(sub.traitCollection.userInterfaceStyle)) vc.trait=\(s(vc.traitCollection.userInterfaceStyle))")
        let child = UIViewController()
        vc.addChild(child); vc.view.addSubview(child.view); child.didMove(toParent: vc)
        print("FACT child: child.override=\(s(child.overrideUserInterfaceStyle)) child.trait=\(s(child.traitCollection.userInterfaceStyle)) child.view.trait=\(s(child.view.traitCollection.userInterfaceStyle))")
        root.addChild(vc); root.view.addSubview(vc.view); vc.didMove(toParent: root)
        print("FACT in window: root.trait=\(s(root.traitCollection.userInterfaceStyle)) vc.trait=\(s(vc.traitCollection.userInterfaceStyle)) vc.view.trait=\(s(vc.view.traitCollection.userInterfaceStyle)) sub.trait=\(s(sub.traitCollection.userInterfaceStyle))")
        vc.overrideUserInterfaceStyle = .unspecified
        print("FACT reset: vc.trait=\(s(vc.traitCollection.userInterfaceStyle)) sub.trait=\(s(sub.traitCollection.userInterfaceStyle))")
        let v2 = UIViewController()
        _ = v2.view
        v2.view.overrideUserInterfaceStyle = .dark
        print("FACT view override only: vc.override=\(s(v2.overrideUserInterfaceStyle)) vc.trait=\(s(v2.traitCollection.userInterfaceStyle))")
        print("DONE")
        exit(0)
    }
}
