// Batch D oracle (NetNewsWire rows): UISlider.TrackConfiguration (iOS 26),
// UIView.animate(springDuration:…) with every default, UIScene notification
// names, registerForTraitChanges(_:target:action:). iPhone 16 / iOS 26.1.
import UIKit

nonisolated(unsafe) var traitHits: [String] = []

final class RootVC: UIViewController {
    @objc func sizeCategoryChanged(_ env: UITraitEnvironment, previous: UITraitCollection) {
        traitHits.append("action env=\(type(of: env)) prev=\(previous.preferredContentSizeCategory.rawValue) now=\(env.traitCollection.preferredContentSizeCategory.rawValue)")
    }
    @objc func noArgs() { traitHits.append("noArgs") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Slider track configuration
        let s = UISlider(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        print("FACT slider.trackConfiguration default=\(s.trackConfiguration == nil ? "nil" : "set")")
        let cfg = UISlider.TrackConfiguration(allowsTickValuesOnly: true, numberOfTicks: 6)
        print("FACT cfg allowsTickValuesOnly=\(cfg.allowsTickValuesOnly) ticks=\(cfg.ticks.count) values=\(cfg.ticks.map { $0.position }) neutralValue=\(cfg.neutralValue) enabledRange=\(cfg.enabledRange)")
        s.minimumValue = 0; s.maximumValue = 5
        s.trackConfiguration = cfg
        for v: Float in [0.4, 0.6, 2.49, 2.51, 5] {
            s.value = v
            print("FACT slider(0...5, 6 ticks, tickOnly) set \(v) -> value=\(s.value)")
        }
        let c3 = UISlider.TrackConfiguration(allowsTickValuesOnly: true, numberOfTicks: 3)
        print("FACT cfg3 values=\(c3.ticks.map { $0.position })")
        // Spring animate with every default
        let v = UIView(frame: .zero)
        view.addSubview(v)
        v.alpha = 1
        var completed = "not yet"
        UIView.animate {
            v.alpha = 0
        } completion: { finished in completed = "finished=\(finished)" }
        print("FACT animate{} model alpha after call=\(v.alpha) presentation=\(v.layer.presentation()?.opacity ?? -1)")
        let anim = v.layer.animation(forKey: "opacity")
        print("FACT animate{} animation=\(anim.map { "\(type(of: $0))" } ?? "nil") duration=\((anim as? CASpringAnimation)?.settlingDuration ?? anim?.duration ?? -1) perceptual=\((anim as? CASpringAnimation)?.perceptualDuration ?? -1) damping=\((anim as? CASpringAnimation)?.damping ?? -1) stiffness=\((anim as? CASpringAnimation)?.stiffness ?? -1) mass=\((anim as? CASpringAnimation)?.mass ?? -1)")
        // Scene notification names
        print("FACT scene names didEnterBackground=\(UIScene.didEnterBackgroundNotification.rawValue) willEnterForeground=\(UIScene.willEnterForegroundNotification.rawValue) didActivate=\(UIScene.didActivateNotification.rawValue) willDeactivate=\(UIScene.willDeactivateNotification.rawValue) willConnect=\(UIScene.willConnectNotification.rawValue) didDisconnect=\(UIScene.didDisconnectNotification.rawValue)")
        // Trait registration with target/action
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self], target: self, action: #selector(sizeCategoryChanged(_:previous:)))
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self], target: self, action: #selector(noArgs))
        traitOverrides.preferredContentSizeCategory = .extraExtraLarge
        view.setNeedsLayout(); view.layoutIfNeeded()
        print("FACT trait action sync after override+layout: \(traitHits)")
        DispatchQueue.main.async {
            print("FACT trait action next turn: \(traitHits)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                print("FACT animate{} completion after 1s: \(completed)")
                print("DONE")
                exit(0)
            }
        }
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
