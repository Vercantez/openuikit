// Materials — UIVisualEffectView / UIBlurEffect / UIGlassEffect / tab-bar
// glass (docs/MATERIALS.md, APP LADDER §4 row 3).
//
// Tab 1: one 200×120 effect over a uniform measured backdrop (yellow for
// classic blur, gray33 for systemMaterial / glass / clear). Tab 2: the
// Tabs-like coloured blocks so the iOS 26 tab-bar platter samples yellow.
//
// The same source is compiled twice: real UIKit (confprobe) and OpenUIKit
// (openhost --app Materials). Window 375×667 at scale 2 (iPhone SE).
import UIKit

@MainActor
public enum MaterialsApp {
    public static let windowSize = CGSize(width: 375, height: 667)

    static var tabBarController: UITabBarController?
    static var styles: MaterialsStylesViewController?

    public static func makeRoot() -> UIViewController {
        let styles = MaterialsStylesViewController()
        styles.tabBarItem = UITabBarItem(title: "Styles",
                                         image: UIImage(systemName: "calendar"),
                                         tag: 0)
        Self.styles = styles

        let bars = MaterialsBarViewController()
        bars.tabBarItem = UITabBarItem(title: "Bar",
                                       image: UIImage(systemName: "clock"),
                                       tag: 1)

        let tab = UITabBarController()
        tab.viewControllers = [styles, bars]
        tabBarController = tab
        return tab
    }

    public static func perform(_ action: String) {
        guard let tab = tabBarController else {
            print("Materials: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "select-tab-2":
            tab.selectedIndex = 1
        case "select-tab-1":
            tab.selectedIndex = 0
        case "set-light":
            styles?.showLight()
        case "set-dark":
            styles?.showDark()
        case "set-regular":
            styles?.showRegular()
        case "set-material":
            styles?.showMaterial()
        case "set-glass":
            styles?.showGlass()
        case "set-clear":
            styles?.showClear()
        default:
            print("Materials: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerMaterials: Void = register("Materials", windowSize: MaterialsApp.windowSize, makeRoot: MaterialsApp.makeRoot, perform: MaterialsApp.perform, scriptPath: "Sources/ConformanceApps/Materials/script.json") }
