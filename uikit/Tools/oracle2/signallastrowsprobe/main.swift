// Signal-iOS last-four blocking-row oracle: UITab / UITabBarController.tabs,
// UINavigationBarDelegate (standalone bar and the controller-managed bar),
// NSIndexPath conveniences, UICornerConfiguration → layer state + pixels.
// Writes Documents/signal-last-rows.json and hands the driving script phase
// markers for render-server screenshots of the corner grid.
import UIKit
import ObjectiveC

var rows: [String: Any] = [:]
var seq = 0
func nextSeq() -> Int { seq += 1; return seq }
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func marker(_ name: String) {
    FileManager.default.createFile(atPath: NSHomeDirectory() + "/Documents/\(name).marker", contents: Data())
}
func waitAck(_ name: String, _ then: @escaping () -> Void) {
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(name).ack") { then(); return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { waitAck(name, then) }
}
func after(_ s: Double, _ f: @escaping () -> Void) { DispatchQueue.main.asyncAfter(deadline: .now() + s, execute: f) }
func tree(_ v: UIView, depth: Int = 0, max: Int = 3) -> [[String: Any]] {
    guard depth <= max else { return [] }
    var out: [[String: Any]] = [["depth": depth, "class": NSStringFromClass(type(of: v)), "frame": rect(v.frame), "hidden": v.isHidden]]
    for s in v.subviews { out += tree(s, depth: depth + 1, max: max) }
    return out
}
func obj(_ o: AnyObject?) -> String { o.map { String(describing: ObjectIdentifier($0)) } ?? "nil" }

// MARK: - Section A: UITab / tabs

final class TabDelegate: NSObject, UITabBarControllerDelegate {
    var log: [[String: Any]] = []
    var allow = true
    var allowTab = true
    func tabBarController(_ c: UITabBarController, shouldSelect vc: UIViewController) -> Bool {
        log.append(["n": nextSeq(), "event": "shouldSelect", "vc": vc.title ?? "", "selectedIndex": c.selectedIndex]); return allow
    }
    func tabBarController(_ c: UITabBarController, didSelect vc: UIViewController) {
        log.append(["n": nextSeq(), "event": "didSelect", "vc": vc.title ?? "", "selectedIndex": c.selectedIndex])
    }
    func tabBarController(_ c: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        log.append(["n": nextSeq(), "event": "shouldSelectTab", "tab": tab.identifier, "selectedIndex": c.selectedIndex]); return allowTab
    }
    func tabBarController(_ c: UITabBarController, didSelectTab tab: UITab, previousTab: UITab?) {
        log.append(["n": nextSeq(), "event": "didSelectTab", "tab": tab.identifier, "previous": previousTab?.identifier ?? "nil", "selectedIndex": c.selectedIndex])
    }
}

var providerCalls: [String: Int] = [:]
var providerTabArg: [String: Bool] = [:]
func describeTab(_ t: UITab, _ tbc: UITabBarController?) -> [String: Any] {
    [
        "identifier": t.identifier, "title": t.title, "hasImage": t.image != nil,
        "badgeValue": t.badgeValue ?? "nil", "subtitle": t.subtitle ?? "nil",
        "preferredPlacement": t.preferredPlacement.rawValue, "isHidden": t.isHidden,
        "isEnabled": t.isEnabled, "allowsHiding": t.allowsHiding, "hasVisiblePlacement": t.hasVisiblePlacement,
        "parent": obj(t.parent), "tabBarController": t.tabBarController.map { $0 === tbc ? "tbc" : "other" } ?? "nil",
        "viewControllerLoaded": t.viewController.map { "\(type(of: $0))" } ?? "nil",
        "vcTabIsSelf": t.viewController?.tab === t,
        "accessibilityValue": t.accessibilityValue ?? "nil",
        "class": NSStringFromClass(type(of: t)),
    ]
}
func describeTBC(_ tbc: UITabBarController, _ tabs: [UITab]) -> [String: Any] {
    var d: [String: Any] = [
        "viewControllers": tbc.viewControllers?.map { $0.title ?? "-" } ?? ["nil"],
        "viewControllersNil": tbc.viewControllers == nil,
        "tabs": tbc.tabs.map { $0.identifier },
        "tabsIdentity": tbc.tabs.map { t in tabs.firstIndex { $0 === t } ?? -1 },
        "tabBarItems": tbc.tabBar.items?.map { ["title": $0.title ?? "nil", "badge": $0.badgeValue ?? "nil", "hasImage": $0.image != nil, "tag": $0.tag] } ?? [],
        "tabBarItemsNil": tbc.tabBar.items == nil,
        "selectedIndex": tbc.selectedIndex,
        "selectedTab": tbc.selectedTab?.identifier ?? "nil",
        "selectedViewController": tbc.selectedViewController?.title ?? "nil",
        "selectedItemTitle": tbc.tabBar.selectedItem?.title ?? "nil",
        "providerCalls": providerCalls,
        "mode": tbc.mode.rawValue,
        "isTabBarHidden": tbc.isTabBarHidden,
        "sidebarHidden": tbc.sidebar.isHidden,
        "tabBarClass": NSStringFromClass(type(of: tbc.tabBar)),
        "tabBarFrame": rect(tbc.tabBar.frame),
    ]
    if let vcs = tbc.viewControllers {
        d["vcTabBarItemIsBarItem"] = vcs.enumerated().map { i, vc in
            tbc.tabBar.items.flatMap { i < $0.count ? $0[i] : nil }.map { $0 === vc.tabBarItem } ?? false
        }
        d["vcTab"] = vcs.map { $0.tab?.identifier ?? "nil" }
        d["vcTabViewControllerIsVC"] = vcs.map { $0.tab?.viewController === $0 }
    }
    return d
}

var tapTrace: [String: Any] = [:]
/// Simulate a user tap on tab `index`: the legacy UITabBarDelegate entry if
/// the controller still implements it, else the first UIControl in the bar
/// tree whose class name mentions a tab button.
func tap(_ tbc: UITabBarController, _ index: Int) {
    let sel = #selector(UITabBarDelegate.tabBar(_:didSelect:))
    tapTrace["respondsToLegacyEntry"] = tbc.responds(to: sel)
    if tbc.responds(to: sel), let item = tbc.tabBar.items?[index] {
        tapTrace["path"] = "legacyDelegateEntry"
        tbc.tabBar(tbc.tabBar, didSelect: item); return
    }
    var found: [UIControl] = []
    func walk(_ v: UIView) {
        for s in v.subviews {
            if let c = s as? UIControl, NSStringFromClass(type(of: c)).lowercased().contains("tab") { found.append(c) }
            walk(s)
        }
    }
    walk(tbc.view)
    tapTrace["controls"] = found.map { NSStringFromClass(type(of: $0)) }
    if index < found.count {
        tapTrace["path"] = "sendActions:" + NSStringFromClass(type(of: found[index]))
        found[index].sendActions(for: .touchUpInside)
    } else { tapTrace["path"] = "none" }
}

final class NamedNav: UINavigationController {}

func tabsSection(_ window: UIWindow, _ done: @escaping () -> Void) {
    var out: [String: Any] = [:]
    var persistent: [String: UIViewController] = [:]
    func makeTab(_ id: String, _ title: String, fresh: Bool = false) -> UITab {
        let vc = NamedNav(rootViewController: UIViewController()); vc.title = title
        persistent[id] = vc
        return UITab(title: title, image: UIImage(systemName: "star"), identifier: id) { tab in
            providerCalls[id, default: 0] += 1
            providerTabArg[id] = tab.identifier == id
            if fresh { let f = NamedNav(rootViewController: UIViewController()); f.title = title + "#\(providerCalls[id]!)"; return f }
            return persistent[id]!
        }
    }
    let t1 = makeTab("chats", "Chats"), t2 = makeTab("calls", "Calls"), t3 = makeTab("stories", "Stories")
    let t4 = makeTab("fresh", "Fresh", fresh: true)
    let all = [t1, t2, t3, t4]
    out["fresh.tab"] = describeTab(t1, nil)
    out["fresh.tab.viewControllerAccessCalledProvider"] = providerCalls["chats"] ?? 0
    out["fresh.tab.vcAfterAccess"] = t1.viewController.map { $0.title ?? "" } ?? "nil"
    out["fresh.tab.callsAfterAccess"] = providerCalls["chats"] ?? 0
    t1.badgeValue = "3"
    t1.accessibilityValue = "3 unread"
    out["fresh.tab.afterBadge"] = describeTab(t1, nil)

    let tbc = UITabBarController()
    let d = TabDelegate(); tbc.delegate = d
    out["tbc.beforeTabs"] = describeTBC(tbc, all)
    tbc.tabs = [t1, t2, t3]
    out["tbc.afterTabsSet.unloaded"] = describeTBC(tbc, all)
    out["tbc.afterTabsSet.t1"] = describeTab(t1, tbc)
    out["tbc.afterTabsSet.log"] = d.log; d.log = []
    window.rootViewController = tbc
    window.makeKeyAndVisible()
    after(0.6) {
        out["tbc.shown"] = describeTBC(tbc, all)
        out["tbc.shown.t1"] = describeTab(t1, tbc)
        out["tbc.shown.log"] = d.log; d.log = []
        out["tbc.shown.tree"] = tree(tbc.view, max: 2)
        out["tbc.shown.tabBarItemTitle"] = tbc.tabBar.items?.first?.title ?? "nil"
        out["tbc.shown.tabBarItemImageIsTabImage"] = tbc.tabBar.items?.first?.image === t1.image
        out["tbc.shown.vc1TabBarItemBadge"] = persistent["chats"]?.tabBarItem.badgeValue ?? "nil"
        out["tbc.shown.providerTabArgIsSelf"] = providerTabArg
        // Badge propagation both ways.
        t2.badgeValue = "7"
        out["badge.tabToItem"] = ["tabBarItem": tbc.tabBar.items?[1].badgeValue ?? "nil", "vcItem": persistent["calls"]?.tabBarItem.badgeValue ?? "nil"]
        persistent["calls"]?.tabBarItem.badgeValue = "9"
        out["badge.itemToTab"] = ["tab": t2.badgeValue ?? "nil", "tabBarItem": tbc.tabBar.items?[1].badgeValue ?? "nil"]
        t2.badgeValue = nil
        out["badge.tabNilToItem"] = ["tabBarItem": tbc.tabBar.items?[1].badgeValue ?? "nil", "vcItem": persistent["calls"]?.tabBarItem.badgeValue ?? "nil"]
        t2.title = "Calls2"
        out["title.tabToItem"] = ["tabBarItem": tbc.tabBar.items?[1].title ?? "nil", "vcItem": persistent["calls"]?.tabBarItem.title ?? "nil", "vcTitle": persistent["calls"]?.title ?? "nil"]
        t2.title = "Calls"
        // Programmatic selection.
        tbc.selectedTab = t2
        after(0.3) {
            out["select.selectedTab=t2"] = describeTBC(tbc, all)
            out["select.selectedTab=t2.log"] = d.log; d.log = []
            tbc.selectedIndex = 2
            after(0.3) {
                out["select.selectedIndex=2"] = describeTBC(tbc, all)
                out["select.selectedIndex=2.log"] = d.log; d.log = []
                tbc.selectedViewController = persistent["chats"]
                after(0.3) {
                    out["select.selectedViewController=chats"] = describeTBC(tbc, all)
                    out["select.selectedViewController=chats.log"] = d.log; d.log = []
                    // Simulated user tap: the legacy UITabBarDelegate entry.
                    tap(tbc, 1)
                    after(0.3) {
                        out["tap.legacyDelegateEntry.item1"] = describeTBC(tbc, all)
                        out["tap.trace"] = tapTrace
                        out["tap.legacyDelegateEntry.item1.log"] = d.log; d.log = []
                        // Reselect the same item.
                        tap(tbc, 1)
                        out["tap.reselect.log"] = d.log; d.log = []
                        d.allowTab = false
                        tap(tbc, 2)
                        after(0.3) {
                            out["tap.vetoedByShouldSelectTab"] = describeTBC(tbc, all)
                            out["tap.vetoedByShouldSelectTab.log"] = d.log; d.log = []
                            d.allowTab = true; d.allow = false
                            tap(tbc, 2)
                            after(0.3) {
                                out["tap.vetoedByLegacyShouldSelect"] = describeTBC(tbc, all)
                                out["tap.vetoedByLegacyShouldSelect.log"] = d.log; d.log = []
                                d.allow = true
                                // Signal's hide-stories flow: replace tabs with a subset, then restore.
                                tbc.selectedTab = t3
                                after(0.2) {
                                    d.log = []
                                    tbc.tabs = [t1, t2]
                                    after(0.3) {
                                        out["tabs.subset"] = describeTBC(tbc, all)
                                        out["tabs.subset.log"] = d.log; d.log = []
                                        out["tabs.subset.t3"] = describeTab(t3, tbc)
                                        tbc.tabs = [t1, t2, t3, t4]
                                        after(0.3) {
                                            out["tabs.restored"] = describeTBC(tbc, all)
                                            out["tabs.restored.log"] = d.log; d.log = []
                                            out["tabs.restored.t3vcSame"] = t3.viewController === persistent["stories"]
                                            let freshVC = t4.viewController
                                            tbc.tabs = [t1, t2]
                                            tbc.tabs = [t1, t2, t3, t4]
                                            after(0.3) {
                                                out["tabs.freshProviderReplace"] = ["calls": providerCalls["fresh"] ?? 0, "sameVC": t4.viewController === freshVC, "vcTitle": t4.viewController?.title ?? "nil"]
                                                // Legacy API after tabs: which wins.
                                                let la = UIViewController(); la.title = "LegacyA"; la.tabBarItem = UITabBarItem(title: "LA", image: nil, tag: 10)
                                                let lb = UIViewController(); lb.title = "LegacyB"
                                                d.log = []
                                                tbc.viewControllers = [la, lb]
                                                after(0.3) {
                                                    var l = describeTBC(tbc, all)
                                                    l["tabClasses"] = tbc.tabs.map { NSStringFromClass(type(of: $0)) }
                                                    l["tabIdentifiers"] = tbc.tabs.map { $0.identifier }
                                                    l["tabTitles"] = tbc.tabs.map { $0.title }
                                                    l["laTab"] = la.tab.map { $0.identifier } ?? "nil"
                                                    l["t1TabBarController"] = t1.tabBarController == nil ? "nil" : "set"
                                                    out["legacy.viewControllersAfterTabs"] = l
                                                    out["legacy.viewControllersAfterTabs.log"] = d.log; d.log = []
                                                    tbc.tabs = [t1, t2, t3]
                                                    after(0.3) {
                                                        out["legacy.tabsAfterViewControllers"] = describeTBC(tbc, all)
                                                        out["legacy.tabsAfterViewControllers.laParent"] = la.parent == nil ? "nil" : "tbc"
                                                        // A fresh controller: legacy first, then read tabs.
                                                        let tbc2 = UITabBarController()
                                                        let a = UIViewController(); a.title = "A"; a.tabBarItem = UITabBarItem(title: "AA", image: nil, tag: 1); a.tabBarItem.badgeValue = "2"
                                                        let b = UIViewController(); b.title = "B"
                                                        tbc2.viewControllers = [a, b]
                                                        out["legacy.freshController.tabs"] = ["count": tbc2.tabs.count, "classes": tbc2.tabs.map { NSStringFromClass(type(of: $0)) }, "identifiers": tbc2.tabs.map { $0.identifier }, "titles": tbc2.tabs.map { $0.title }, "badges": tbc2.tabs.map { $0.badgeValue ?? "nil" }, "selectedTab": tbc2.selectedTab?.identifier ?? "nil", "aTab": a.tab?.identifier ?? "nil"]
                                                        tbc2.loadViewIfNeeded()
                                                        out["legacy.freshController.loaded.tabs"] = ["count": tbc2.tabs.count, "identifiers": tbc2.tabs.map { $0.identifier }, "selectedTab": tbc2.selectedTab?.identifier ?? "nil", "items": tbc2.tabBar.items?.map { $0.title ?? "nil" } ?? []]
                                                        // Empty tabs.
                                                        tbc.tabs = []
                                                        after(0.2) {
                                                            out["tabs.empty"] = describeTBC(tbc, all)
                                                            rows["tabs"] = out
                                                            done()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Section B: UINavigationBarDelegate

final class BarDelegate: NSObject, UINavigationBarDelegate {
    var log: [[String: Any]] = []
    var allowPush = true, allowPop = true
    var position: UIBarPosition = .any
    weak var bar: UINavigationBar?
    func row(_ e: String, _ item: UINavigationItem?, _ b: UINavigationBar) -> [String: Any] {
        ["n": nextSeq(), "event": e, "item": item?.title ?? "nil", "items": b.items?.map { $0.title ?? "nil" } ?? ["nil"], "top": b.topItem?.title ?? "nil"]
    }
    func navigationBar(_ b: UINavigationBar, shouldPush item: UINavigationItem) -> Bool { log.append(row("shouldPush", item, b)); return allowPush }
    func navigationBar(_ b: UINavigationBar, didPush item: UINavigationItem) { log.append(row("didPush", item, b)) }
    func navigationBar(_ b: UINavigationBar, shouldPop item: UINavigationItem) -> Bool { log.append(row("shouldPop", item, b)); return allowPop }
    func navigationBar(_ b: UINavigationBar, didPop item: UINavigationItem) { log.append(row("didPop", item, b)) }
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        log.append(["n": nextSeq(), "event": "position(for:)", "isBar": (bar as AnyObject) === self.bar, "barPosition": bar.barPosition.rawValue]); return position
    }
}

final class ProbeNav: UINavigationController, UINavigationBarDelegate {
    var log: [[String: Any]] = []
    var allowPop = true
    func row(_ e: String, _ item: UINavigationItem, _ b: UINavigationBar) -> [String: Any] {
        ["n": nextSeq(), "event": e, "item": item.title ?? "nil", "itemIsTopVCItem": topViewController?.navigationItem === item,
         "vcs": viewControllers.map { $0.title ?? "-" }, "barItems": b.items?.map { $0.title ?? "nil" } ?? [], "barIsOwn": b === navigationBar]
    }
    func navigationBar(_ b: UINavigationBar, shouldPop item: UINavigationItem) -> Bool { log.append(row("shouldPop", item, b)); return allowPop }
    func navigationBar(_ b: UINavigationBar, didPop item: UINavigationItem) { log.append(row("didPop", item, b)) }
    func navigationBar(_ b: UINavigationBar, shouldPush item: UINavigationItem) -> Bool { log.append(row("shouldPush", item, b)); return true }
    func navigationBar(_ b: UINavigationBar, didPush item: UINavigationItem) { log.append(row("didPush", item, b)) }
}

func findBackControl(_ v: UIView) -> UIControl? {
    for s in v.subviews {
        let n = NSStringFromClass(type(of: s))
        if let c = s as? UIControl, n.contains("BackButton") || n.contains("ButtonBarButton") { return c }
        if let c = findBackControl(s) { return c }
    }
    return nil
}
func controls(_ v: UIView) -> [String] {
    var out: [String] = []
    for s in v.subviews {
        if s is UIControl { out.append(NSStringFromClass(type(of: s))) }
        out += controls(s)
    }
    return out
}

func navSection(_ window: UIWindow, _ done: @escaping () -> Void) {
    var out: [String: Any] = [:]
    let host = UIViewController(); host.view.backgroundColor = .white
    window.rootViewController = host
    let bar = UINavigationBar(frame: CGRect(x: 0, y: 100, width: 393, height: 44))
    let d = BarDelegate(); d.bar = bar; d.position = .topAttached
    out["delegateDefault"] = bar.delegate == nil ? "nil" : "set"
    bar.delegate = d
    out["delegateIsWeakProperty"] = bar.delegate === d
    out["barPositionDetached"] = bar.barPosition.rawValue
    out["log.afterSetDelegate"] = d.log; d.log = []
    host.view.addSubview(bar)
    out["log.afterAdd"] = d.log; d.log = []
    out["barPositionAttached"] = bar.barPosition.rawValue
    let a = UINavigationItem(title: "A"), b = UINavigationItem(title: "B"), c = UINavigationItem(title: "C"), e = UINavigationItem(title: "E")
    bar.pushItem(a, animated: false)
    out["log.push.A"] = d.log; d.log = []
    bar.pushItem(b, animated: false)
    out["log.push.B"] = d.log; d.log = []
    out["items.afterPushes"] = bar.items?.map { $0.title ?? "" } ?? []
    d.allowPush = false
    bar.pushItem(c, animated: false)
    out["log.push.C.vetoed"] = d.log; d.log = []
    out["items.afterVetoedPush"] = bar.items?.map { $0.title ?? "" } ?? []
    d.allowPush = true
    bar.pushItem(c, animated: true)
    out["log.push.C.animated.sync"] = d.log; d.log = []
    after(0.6) {
        out["log.push.C.animated.later"] = d.log; d.log = []
        d.allowPop = false
        let r1 = bar.popItem(animated: false)
        out["pop.vetoed"] = ["returned": r1?.title ?? "nil", "items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
        d.allowPop = true
        let r2 = bar.popItem(animated: false)
        out["pop.allowed"] = ["returned": r2?.title ?? "nil", "items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
        let r3 = bar.popItem(animated: true)
        out["pop.animated.sync"] = ["returned": r3?.title ?? "nil", "items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
        after(0.6) {
            out["pop.animated.later"] = ["items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
            let r4 = bar.popItem(animated: false)
            out["pop.lastItem"] = ["returned": r4?.title ?? "nil", "items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
            let r5 = bar.popItem(animated: false)
            out["pop.empty"] = ["returned": r5?.title ?? "nil", "log": d.log]; d.log = []
            bar.setItems([a, b, c], animated: false)
            out["setItems.ABC"] = ["items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
            bar.setItems([a, b], animated: true)
            out["setItems.AB.animated.sync"] = ["items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
            after(0.6) {
                out["setItems.AB.animated.later"] = d.log; d.log = []
                bar.setItems([a, b, e], animated: true)
                out["setItems.ABE.animated.sync"] = ["items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
                after(0.6) {
                    out["setItems.ABE.animated.later"] = d.log; d.log = []
                    d.allowPop = false
                    bar.setItems([a], animated: false)
                    out["setItems.A.popVetoed"] = ["items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
                    d.allowPop = true
                    bar.setItems(nil, animated: false)
                    out["setItems.nil"] = ["items": bar.items?.map { $0.title ?? "" } ?? ["nil"], "itemsNil": bar.items == nil, "log": d.log]; d.log = []
                    // Back button on a standalone bar with two items: tap the control.
                    bar.setItems([a, b], animated: false); d.log = []
                    bar.layoutIfNeeded()
                    out["standalone.controls"] = controls(bar)
                    if let back = findBackControl(bar) {
                        out["standalone.backControl"] = NSStringFromClass(type(of: back))
                        back.sendActions(for: .touchUpInside)
                    }
                    after(0.6) {
                        out["standalone.backTap"] = ["items": bar.items?.map { $0.title ?? "" } ?? [], "log": d.log]; d.log = []
                        bar.removeFromSuperview()
                        controllerNav(window, &out, done)
                    }
                }
            }
        }
    }
}

func controllerNav(_ window: UIWindow, _ outRef: inout [String: Any], _ done: @escaping () -> Void) {
    var out = outRef
    let root = UIViewController(); root.title = "Root"
    let nav = ProbeNav(rootViewController: root)
    window.rootViewController = nav
    after(0.4) {
        out["controller.barDelegateIsNav"] = nav.navigationBar.delegate === nav
        out["controller.barDelegateClass"] = nav.navigationBar.delegate.map { NSStringFromClass(type(of: $0)) } ?? "nil"
        out["controller.log.afterRoot"] = nav.log; nav.log = []
        let second = UIViewController(); second.title = "Second"
        nav.pushViewController(second, animated: false)
        after(0.4) {
            out["controller.log.afterPush"] = nav.log; nav.log = []
            out["controller.controls"] = controls(nav.navigationBar)
            // Programmatic pop: does shouldPop fire, and with which item?
            nav.allowPop = true
            _ = nav.popViewController(animated: false)
            after(0.4) {
                out["controller.programmaticPop"] = ["log": nav.log, "vcs": nav.viewControllers.map { $0.title ?? "" }, "barItems": nav.navigationBar.items?.map { $0.title ?? "" } ?? []]; nav.log = []
                nav.pushViewController(second, animated: false)
                after(0.4) {
                    nav.log = []
                    // Back button tap with the delegate vetoing.
                    nav.allowPop = false
                    let back = findBackControl(nav.navigationBar)
                    out["controller.backControl"] = back.map { NSStringFromClass(type(of: $0)) } ?? "nil"
                    back?.sendActions(for: .touchUpInside)
                    after(0.8) {
                        out["controller.backTap.vetoed"] = ["log": nav.log, "vcs": nav.viewControllers.map { $0.title ?? "" }, "barItems": nav.navigationBar.items?.map { $0.title ?? "" } ?? [], "topVC": nav.topViewController?.title ?? ""]; nav.log = []
                        nav.allowPop = true
                        back?.sendActions(for: .touchUpInside)
                        after(0.8) {
                            out["controller.backTap.allowed"] = ["log": nav.log, "vcs": nav.viewControllers.map { $0.title ?? "" }, "barItems": nav.navigationBar.items?.map { $0.title ?? "" } ?? [], "topVC": nav.topViewController?.title ?? ""]; nav.log = []
                            // Direct popItem on a controller-managed bar: MEASURED to raise
                            // (+[NSException raise:format:] from -[UINavigationBar
                            // popNavigationItemAnimated:], crash report probe-2026-09-10-034730),
                            // so it is recorded here rather than exercised.
                            out["controller.barPopItem"] = "raises NSException (measured crash in -[UINavigationBar popNavigationItemAnimated:])"
                            rows["nav"] = out
                            done()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Section C: NSIndexPath

func indexPathSection() {
    let i = NSIndexPath(item: 3, section: 1)
    let r = NSIndexPath(row: 4, section: 2)
    let ip = i as IndexPath
    let ipr = r as IndexPath
    let back = IndexPath(item: 5, section: 6) as NSIndexPath
    rows["indexPath"] = [
        "item.length": i.length, "item.section": i.section, "item.item": i.item, "item.row": i.row,
        "item.index0": i.index(atPosition: 0), "item.index1": i.index(atPosition: 1),
        "row.length": r.length, "row.section": r.section, "row.row": r.row, "row.item": r.item,
        "bridged.item": [ip.section, ip.item, ip.row, ip.count],
        "bridged.row": [ipr.section, ipr.item, ipr.row, ipr.count],
        "roundTrip": [back.section, back.item, back.row, back.length],
        "equalToIndexPath": ip == IndexPath(item: 3, section: 1),
        "isEqualNS": i.isEqual(NSIndexPath(row: 3, section: 1)),
        "description": i.description,
        "class": NSStringFromClass(type(of: i)),
        "layoutAttributesIndexPath": { () -> [Int] in
            let a = UICollectionViewLayoutAttributes(forCellWith: NSIndexPath(item: 7, section: 0) as IndexPath)
            return [a.indexPath.section, a.indexPath.item]
        }(),
    ]
}

// MARK: - Section D: UICornerConfiguration

struct CornerCase {
    let name: String
    let size: CGSize
    let config: UICornerConfiguration?
    let control: (radius: CGFloat, curve: CALayerCornerCurve)?
}

func layerCornerState(_ l: CALayer) -> [String: Any] {
    var d: [String: Any] = ["cornerRadius": Double(l.cornerRadius), "cornerCurve": l.cornerCurve.rawValue, "maskedCorners": l.maskedCorners.rawValue, "masksToBounds": l.masksToBounds, "class": NSStringFromClass(type(of: l))]
    // Enumerate CALayer property names mentioning corners or radii, read the ones present.
    var cls: AnyClass? = type(of: l)
    var names: [String] = []
    while let c = cls {
        var count: UInt32 = 0
        if let props = class_copyPropertyList(c, &count) {
            for i in 0..<Int(count) {
                let n = String(cString: property_getName(props[i]))
                if n.lowercased().contains("corner") || n.lowercased().contains("radii") { names.append(n) }
            }
            free(props)
        }
        if c == CALayer.self { break }
        cls = class_getSuperclass(c)
    }
    d["cornerProperties"] = names
    for n in names where n != "cornerRadius" && n != "cornerCurve" && n != "maskedCorners" {
        if let v = l.value(forKey: n) { d["prop." + n] = String(describing: v) } else { d["prop." + n] = "nil" }
    }
    return d
}

var cornerViews: [(CornerCase, UIView)] = []
func cornerSection(_ window: UIWindow, _ done: @escaping () -> Void) {
    let host = UIViewController(); host.view.backgroundColor = .white
    window.rootViewController = host
    let fresh = UIView()
    var out: [String: Any] = ["default.description": fresh.cornerConfiguration.description,
                              "default.layer": layerCornerState(fresh.layer),
                              "scale": Double(UIScreen.main.scale)]
    let cases: [CornerCase] = [
        CornerCase(name: "uniform.fixed8.100x40", size: CGSize(width: 100, height: 40), config: .uniformCorners(radius: .fixed(8)), control: nil),
        CornerCase(name: "control.radius8.circular.100x40", size: CGSize(width: 100, height: 40), config: nil, control: (8, .circular)),
        CornerCase(name: "control.radius8.continuous.100x40", size: CGSize(width: 100, height: 40), config: nil, control: (8, .continuous)),
        CornerCase(name: "corners.fixed12.60x60", size: CGSize(width: 60, height: 60), config: .corners(radius: .fixed(12)), control: nil),
        CornerCase(name: "control.radius12.circular.60x60", size: CGSize(width: 60, height: 60), config: nil, control: (12, .circular)),
        CornerCase(name: "control.radius12.continuous.60x60", size: CGSize(width: 60, height: 60), config: nil, control: (12, .continuous)),
        CornerCase(name: "capsule.100x40", size: CGSize(width: 100, height: 40), config: .capsule(), control: nil),
        CornerCase(name: "control.radius20.circular.100x40", size: CGSize(width: 100, height: 40), config: nil, control: (20, .circular)),
        CornerCase(name: "control.radius20.continuous.100x40", size: CGSize(width: 100, height: 40), config: nil, control: (20, .continuous)),
        CornerCase(name: "capsule.60x100", size: CGSize(width: 60, height: 100), config: .capsule(), control: nil),
        CornerCase(name: "capsule.max10.100x40", size: CGSize(width: 100, height: 40), config: .capsule(maximumRadius: 10), control: nil),
        CornerCase(name: "uniform.fixed40.100x40.oversized", size: CGSize(width: 100, height: 40), config: .uniformCorners(radius: .fixed(40)), control: nil),
        CornerCase(name: "control.radius40.circular.100x40", size: CGSize(width: 100, height: 40), config: nil, control: (40, .circular)),
        CornerCase(name: "corners.tl10.tr0.bl20.br30.120x80", size: CGSize(width: 120, height: 80), config: .corners(topLeftRadius: .fixed(10), topRightRadius: .fixed(0), bottomLeftRadius: .fixed(20), bottomRightRadius: .fixed(30)), control: nil),
        CornerCase(name: "corners.tl10.nil.nil.nil.120x80", size: CGSize(width: 120, height: 80), config: .corners(topLeftRadius: .fixed(10), topRightRadius: nil, bottomLeftRadius: nil, bottomRightRadius: nil), control: nil),
        CornerCase(name: "uniformEdges.top16.bottom4.100x60", size: CGSize(width: 100, height: 60), config: .uniformEdges(topRadius: .fixed(16), bottomRadius: .fixed(4)), control: nil),
        CornerCase(name: "uniformTop16.100x60", size: CGSize(width: 100, height: 60), config: .uniformTopRadius(.fixed(16)), control: nil),
        CornerCase(name: "uniform.concentricMin8.100x60", size: CGSize(width: 100, height: 60), config: .uniformCorners(radius: .containerConcentric(minimum: 8)), control: nil),
        CornerCase(name: "uniform.fixed8.thenLayer2.100x40", size: CGSize(width: 100, height: 40), config: .uniformCorners(radius: .fixed(8)), control: nil),
        CornerCase(name: "capsule.resize.100x40to200x60", size: CGSize(width: 100, height: 40), config: .capsule(), control: nil),
    ]
    var x: CGFloat = 16, y: CGFloat = 80, rowH: CGFloat = 0
    for c in cases {
        if x + c.size.width > 393 - 16 { x = 16; y += rowH + 16; rowH = 0 }
        let v = UIView(frame: CGRect(origin: CGPoint(x: x, y: y), size: c.size))
        v.backgroundColor = .red
        if c.name.hasPrefix("uniform.concentricMin8") {
            // A container with its own configuration, the probe view inset 4 pt.
            let container = UIView(frame: CGRect(x: x - 4, y: y - 4, width: c.size.width + 8, height: c.size.height + 8))
            container.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            container.cornerConfiguration = .uniformCorners(radius: .fixed(20))
            host.view.addSubview(container)
            v.frame = CGRect(x: 4, y: 4, width: c.size.width, height: c.size.height)
            container.addSubview(v)
        } else {
            host.view.addSubview(v)
        }
        if let cfg = c.config { v.cornerConfiguration = cfg }
        if let ctl = c.control { v.layer.cornerRadius = ctl.radius; v.layer.cornerCurve = ctl.curve }
        if c.name.hasPrefix("uniform.fixed8.thenLayer2") { v.layer.cornerRadius = 2 }
        cornerViews.append((c, v))
        x += c.size.width + 16; rowH = max(rowH, c.size.height)
    }
    host.view.layoutIfNeeded()
    after(0.5) {
        var table: [String: Any] = [:]
        for (c, v) in cornerViews {
            var d = layerCornerState(v.layer)
            d["frame"] = rect(v.convert(v.bounds, to: window))
            d["configDescription"] = v.cornerConfiguration.description
            table[c.name] = d
        }
        out["cases"] = table
        marker("corners1")
        waitAck("corners1") {
            for (c, v) in cornerViews where c.name.hasPrefix("capsule.resize") {
                v.frame = CGRect(origin: v.frame.origin, size: CGSize(width: 200, height: 60))
            }
            for (c, v) in cornerViews where c.name == "uniform.fixed8.100x40" {
                out["mutate.fixed8.thenLayerRadius30"] = "set"
                v.layer.cornerRadius = 30
                _ = c
            }
            after(0.5) {
                var t2: [String: Any] = [:]
                for (c, v) in cornerViews where c.name.hasPrefix("capsule.resize") || c.name == "uniform.fixed8.100x40" {
                    var d = layerCornerState(v.layer); d["frame"] = rect(v.convert(v.bounds, to: window)); d["configDescription"] = v.cornerConfiguration.description
                    t2[c.name] = d
                }
                out["after"] = t2
                marker("corners2")
                waitAck("corners2") {
                    rows["corners"] = out
                    done()
                }
            }
        }
    }
}

// MARK: - Driver

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        rows["device"] = ["idiom": UIDevice.current.userInterfaceIdiom.rawValue, "screen": rect(UIScreen.main.bounds), "scale": Double(UIScreen.main.scale), "system": UIDevice.current.systemVersion]
        indexPathSection()
        tabsSection(w) {
            navSection(w) {
                cornerSection(w) {
                    let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
                    try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/signal-last-rows.json"))
                    marker("done")
                }
            }
        }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
