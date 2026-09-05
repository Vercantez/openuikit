// Tabs — the sixth CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A UITabBarController with three tabs (SF Symbol images + titles, one with
// a badge): tab 1 a UINavigationController whose root has a UISearchController
// in the navigation item (hidesSearchBarWhenScrolling default) over a
// plain table of 30 rows; tab 2 a UIToolbar (flexible space, three bar button
// items, one a system item) and a UIButton whose UIMenu is the primary
// action; tab 3 a scroll view. Nothing here is a fixture or a scene: the
// ONLY imports are UIKit and (through UIKit's own re-export, exactly as on
// iOS) Foundation.
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app Tabs`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/Tabs/script.json. Captures sit at
// rest after every step, so a difference is a LAYOUT or RENDER difference
// (tab-bar glass, badge, search-in-navbar, toolbar spacing), not a
// hit-test difference. See NavFlowApp.swift for why the interaction is a
// named action.
//
// "show-menu" is implemented (UIButton.performPrimaryAction) but is not in
// the script: a presented menu hangs on the WINDOW and would overlay later
// tab captures. The t1000 capture is the button with the menu attached.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation), the same
// device NavFlow uses (status bar hidden, window safe area [0, 0, 0, 0]).
import UIKit

@MainActor
public enum TabsApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The tab controller `perform(_:)` drives. Held strongly: the host's
    /// window owns the hierarchy, and this is the harness's handle.
    static var tabBarController: UITabBarController?

    public static func makeRoot() -> UIViewController {
        let search = TabsSearchViewController(style: .plain)
        let nav = UINavigationController(rootViewController: search)
        nav.tabBarItem = UITabBarItem(title: "Search",
                                       image: UIImage(systemName: "calendar"),
                                       tag: 0)

        let tools = TabsToolsViewController()
        tools.tabBarItem = UITabBarItem(title: "Tools",
                                         image: UIImage(systemName: "plus.circle.fill"),
                                         tag: 1)
        tools.tabBarItem?.badgeValue = "3"

        let scroll = TabsScrollViewController()
        scroll.tabBarItem = UITabBarItem(title: "Scroll",
                                         image: UIImage(systemName: "clock"),
                                         tag: 2)

        let tab = UITabBarController()
        tab.viewControllers = [nav, tools, scroll]
        tabBarController = tab
        return tab
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// (or key) would reach, so the two replays exercise the app, not the
    /// harness.
    public static func perform(_ action: String) {
        guard let tab = tabBarController else {
            print("Tabs: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "select-tab-2":
            tab.selectedIndex = 1
        case "select-tab-3":
            tab.selectedIndex = 2
        case "select-tab-1":
            tab.selectedIndex = 0
        case "focus-search":
            searchRoot()?.focusSearch()
        case "type-search":
            searchRoot()?.typeSearch()
        case "cancel-search":
            searchRoot()?.cancelSearch()
        case "scroll-200":
            searchRoot()?.scrollTable(to: 200)
        case "show-menu":
            toolsRoot()?.showMenu()
        default:
            print("Tabs: unknown action \"\(action)\"")
        }
    }

    static func searchRoot() -> TabsSearchViewController? {
        guard let tab = tabBarController,
              let nav = tab.viewControllers?.first as? UINavigationController else {
            return nil
        }
        return nav.viewControllers.first as? TabsSearchViewController
    }

    static func toolsRoot() -> TabsToolsViewController? {
        tabBarController?.viewControllers?[1] as? TabsToolsViewController
    }
}

extension ConformanceApps { static let _registerTabs: Void = register("Tabs", windowSize: TabsApp.windowSize, makeRoot: TabsApp.makeRoot, perform: TabsApp.perform, scriptPath: "Sources/ConformanceApps/Tabs/script.json") }
