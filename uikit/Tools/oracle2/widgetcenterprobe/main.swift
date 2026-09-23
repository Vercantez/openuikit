// WidgetCenter surface used by NetNewsWire Shared/Widget/WidgetDataEncoder.swift
// (`WidgetCenter.shared.reloadTimelines(ofKind:)`), for an app with NO widget
// extension installed -- the state the port models. Run as an app on the
// iPhone 16 / iOS 26.1 simulator.
import UIKit
import WidgetKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let c = WidgetCenter.shared
        print("shared identical=\(c === WidgetCenter.shared)")
        c.reloadTimelines(ofKind: "com.ranchero.NetNewsWire.UnreadWidget")
        print("reloadTimelines(ofKind:) returned")
        c.reloadAllTimelines()
        print("reloadAllTimelines() returned")
        c.getCurrentConfigurations { result in
            switch result {
            case .success(let infos): print("getCurrentConfigurations success count=\(infos.count) main=\(Thread.isMainThread)")
            case .failure(let e as NSError): print("getCurrentConfigurations failure domain=\(e.domain) code=\(e.code)")
            }
            Task {
                let infos = try? await WidgetCenter.shared.currentConfigurations()
                print("async currentConfigurations count=\(infos.map { "\($0.count)" } ?? "threw")")
                exit(0)
            }
        }
        return true
    }
}
