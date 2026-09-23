// UIApplication.sendAction(_:to:from:for:) with a Selector, as NetNewsWire
// RSCore UIResponder+RSCore.swift:27 uses it (nil target, a method every
// UIResponder has through an extension). iPhone 16 / iOS 26.1, run.sh.
import UIKit

nonisolated(unsafe) var hits: [String] = []

extension UIResponder {
    @objc func probeFind(sender: AnyObject?) {
        hits.append("\(type(of: self)) sender=\(sender.map { "\(type(of: $0))" } ?? "nil")")
    }
}

final class Target: NSObject {
    @objc func ping(_ sender: Any?) { hits.append("Target.ping sender=\(sender.map { "\(type(of: $0))" } ?? "nil")") }
}

final class RootVC: UIViewController {
    let field = UITextField(frame: CGRect(x: 20, y: 100, width: 200, height: 40))
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(field)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let app = UIApplication.shared
        func run(_ label: String, _ body: () -> Bool) {
            hits = []
            let r = body()
            print("FACT \(label) returned=\(r) hits=\(hits)")
        }
        run("nil target, no first responder") { app.sendAction(#selector(UIResponder.probeFind(sender:)), to: nil, from: nil, for: nil) }
        run("nil target, sender=field, no first responder") { app.sendAction(#selector(UIResponder.probeFind(sender:)), to: nil, from: field, for: nil) }
        _ = field.becomeFirstResponder()
        print("FACT field.isFirstResponder=\(field.isFirstResponder)")
        run("nil target, field first responder") { app.sendAction(#selector(UIResponder.probeFind(sender:)), to: nil, from: nil, for: nil) }
        _ = field.resignFirstResponder()
        let t = Target()
        run("explicit target") { app.sendAction(#selector(Target.ping(_:)), to: t, from: self, for: nil) }
        run("nil target, nobody implements") { app.sendAction(NSSelectorFromString("noSuchAction:"), to: nil, from: nil, for: nil) }
        run("explicit target that does not implement") { app.sendAction(NSSelectorFromString("noSuchAction:"), to: t, from: nil, for: nil) }
        print("DONE")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exit(0) }
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = RootVC()
        w.makeKeyAndVisible()
        window = w
        return true
    }
}
