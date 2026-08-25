// Showcase app entry point. Owner: demo app (M10).
//
// `openhost --app showcase` boots the M10 app framework end to end: a
// UITabBarController over three independent UINavigationController stacks —
//
//   Settings  the M7.5 Settings app, with prefersLargeTitles ON: the bar is
//             transparent, the 34 pt title sits over the scroll view's
//             116 pt top inset and collapses into the inline title as the
//             list scrolls up. Its profile card presents the profile editor
//             as a pageSheet.
//   Tasks     the M10 table version of the Tasks app (insetGrouped
//             UITableView, dequeued cells, animated cross-section moves).
//   Text      the M8 text-input form (UITextField / UITextView).
//
// Each tab keeps its own stack and its own state: UITabBarController swaps
// the selected child's VIEW but never unloads the others, so scroll
// positions, in-flight edits, pushed screens and control values all survive
// a round trip through another tab.
//
// The tab bar is the iOS 26 floating platter: it owns the bottom 72 pt of
// the window and is transparent around the platter, so content scrolls
// underneath it. Nothing reserves that space automatically, so each root
// controller is handed an `extraBottomInset` of `UITabBar.barHeight` for its
// scroll insets and floating chrome.

import OpenUIKit

/// A screen that can reserve room for chrome it does not own.
///
/// The showcase app's tab bar floats over the bottom 72 pt of EVERY screen in
/// every stack — pushed detail screens included — and nothing reserves that
/// space automatically (there is no safe-area model in the portable core).
/// Controllers that anchor content to the bottom, or that scroll, adopt this
/// so a container can hand the inset down.
@MainActor
public protocol BottomInsetAdjustable: AnyObject {
    var extraBottomInset: CGFloat { get set }
}

@MainActor
public enum ShowcaseApp {
    /// iPhone-16-ish portrait: tall enough for the large title to have room
    /// to collapse above a scrollable list AND for the floating tab bar.
    public static let windowSize = CGSize(width: 390, height: 844)

    /// Icon point size inside a tab bar item.
    static let tabIconSize: CGFloat = 26

    public static func makeRootViewController() -> UITabBarController {
        let inset = UITabBar.barHeight

        let settings = SettingsRootViewController()
        settings.extraBottomInset = inset
        let settingsNav = UINavigationController(rootViewController: settings)
        // iOS 26 large titles for this stack only (Tasks/Text keep the
        // classic 64 pt bar, so one run exercises both bar modes).
        settingsNav.navigationBar.prefersLargeTitles = true
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings", image: iconImage(.gear, size: tabIconSize), tag: 0)

        let tasks = TasksRootViewController()
        tasks.extraBottomInset = inset
        let tasksNav = UINavigationController(rootViewController: tasks)
        tasksNav.tabBarItem = UITabBarItem(
            title: "Tasks", image: iconImage(.checklist, size: tabIconSize), tag: 1)

        let text = TextDemoRootViewController()
        let textNav = UINavigationController(rootViewController: text)
        textNav.tabBarItem = UITabBarItem(
            title: "Text", image: iconImage(.textLines, size: tabIconSize), tag: 2)

        let tabs = UITabBarController()
        tabs.setViewControllers([settingsNav, tasksNav, textNav], animated: false)
        tabs.selectedIndex = 0
        return tabs
    }
}
