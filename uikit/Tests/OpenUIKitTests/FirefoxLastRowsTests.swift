// firefox-ios' last two blocking rows: UICommandAlternate and UIMenuBuilder.
//
// Every expectation is a row of Tools/oracle2/firefoxlastrowsprobe's
// transcripts (iPhone 16 and iPad A16, iOS 26.1 — identical on both), read
// off the JSON, not off the port. The README of the probe names each row.
import XCTest
@testable import OpenUIKit

/// Selector names of the probe's RootVC, spelled the portable way.
private enum Sel {
    static let base = Selector(("fireBase:"))
    static let altShift = Selector(("fireAltShift:"))
    static let altOption = Selector(("fireAltOption:"))
    static let direct = Selector(("fireDirect:"))
    static let newTab = Selector(("newTabKeyCommand:"))
    static let newPrivateTab = Selector(("newPrivateTabKeyCommand:"))
    static let closeTab = Selector(("closeTabKeyCommand:"))
    static let openSettings = Selector(("openSettingsKeyCommand:"))
    static let showDownloads = Selector(("showDownloadsKeyCommand:"))
    static let findInPage = Selector(("findInPageKeyCommand:"))
    static let reload = Selector(("reloadTabKeyCommand:"))
    static let goBack = Selector(("goBackKeyCommand:"))
    static let addBookmark = Selector(("addBookmarkKeyCommand:"))
    static let nextTab = Selector(("nextTabKeyCommand:"))
    static let neverInAMenu = Selector(("neverInAMenu:"))
}

/// The probe's RootVC: vends the phase's key commands, logs every fire with
/// its sender, and logs `validate(_:)`.
#if !os(Linux)
@MainActor
#endif
private final class RootVC: UIViewController, SelectorDispatching {
    var phase = "none"
    var fired: [(action: String, sender: Any?)] = []
    var validated: [UICommand] = []
    var buildLog: [String] = []

    var base: UIKeyCommand {
        UIKeyCommand(title: "Base", action: Sel.base, input: "j", modifierFlags: .command,
                     alternates: [UICommandAlternate(title: "Alt Shift", action: Sel.altShift, modifierFlags: .shift),
                                  UICommandAlternate(title: "Alt Option", action: Sel.altOption, modifierFlags: .alternate)])
    }
    var direct: UIKeyCommand {
        UIKeyCommand(title: "Direct", action: Sel.direct, input: "j", modifierFlags: [.command, .shift])
    }
    override var keyCommands: [UIKeyCommand]? {
        switch phase {
        case "A": return [base]
        case "B": return [base, direct]
        case "C": return [direct, base]
        default: return nil
        }
    }
    override func buildMenu(with builder: UIMenuBuilder) {
        buildLog.append("RootVC/" + (builder.system === UIMenuSystem.main ? "main" : "context"))
        super.buildMenu(with: builder)
    }
    override func validate(_ command: UICommand) { validated.append(command) }

    static let actions: ActionTable<RootVC> = [
        .action("fireBase:", RootVC.fireBase), .action("fireAltShift:", RootVC.fireAltShift),
        .action("fireAltOption:", RootVC.fireAltOption), .action("fireDirect:", RootVC.fireDirect),
        .action("newTabKeyCommand:", RootVC.newTab), .action("newPrivateTabKeyCommand:", RootVC.newPrivateTab),
        .action("closeTabKeyCommand:", RootVC.closeTab), .action("openSettingsKeyCommand:", RootVC.openSettings),
        .action("showDownloadsKeyCommand:", RootVC.showDownloads),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool { Self.actions.perform(name, on: self, with: sender) }
    func fireBase(_ s: Any?) { fired.append(("fireBase", s)) }
    func fireAltShift(_ s: Any?) { fired.append(("fireAltShift", s)) }
    func fireAltOption(_ s: Any?) { fired.append(("fireAltOption", s)) }
    func fireDirect(_ s: Any?) { fired.append(("fireDirect", s)) }
    func newTab(_ s: Any?) { fired.append(("newTab", s)) }
    func newPrivateTab(_ s: Any?) { fired.append(("newPrivateTab", s)) }
    func closeTab(_ s: Any?) { fired.append(("closeTab", s)) }
    func openSettings(_ s: Any?) { fired.append(("openSettings", s)) }
    func showDownloads(_ s: Any?) { fired.append(("showDownloads", s)) }
}

/// firefox's AppDelegate shape: `UIResponder, UIApplicationDelegate`, with
/// MenuBuilderHelper.mainMenu(for:) replayed verbatim (our selectors).
#if !os(Linux)
@MainActor
#endif
private final class FirefoxDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?? = nil
    var buildLog: [String] = []
    var lastBuilder: UIMenuBuilder?
    var replaysFirefox = true
    var beforeSteps: [String: Any] = [:]
    var afterSteps: [[String]] = []

    static let history = UIMenu.Identifier("com.mozilla.firefox.menus.history")
    static let bookmarks = UIMenu.Identifier("com.mozilla.firefox.menus.bookmarks")
    static let tools = UIMenu.Identifier("com.mozilla.firefox.menus.tools")

    var appMenu: UIMenu!, fileMenu: UIMenu!, findMenu: UIMenu!, viewMenu: UIMenu!, historyMenu: UIMenu!

    override func buildMenu(with builder: UIMenuBuilder) {
        buildLog.append("AppDelegate/" + (builder.system === UIMenuSystem.main ? "main" : "context"))
        super.buildMenu(with: builder)
        guard builder.system === UIMenuSystem.main else { return }
        lastBuilder = builder
        guard replaysFirefox else { return }
        mainMenu(for: builder)
    }

    func topLevel(_ b: UIMenuBuilder) -> [String] {
        (b.menu(for: .root)?.children ?? []).map { ($0 as? UIMenu)?.identifier.rawValue ?? "<\($0.title)>" }
    }
    func childIds(_ b: UIMenuBuilder, _ id: UIMenu.Identifier) -> [String] {
        (b.menu(for: id)?.children ?? []).map { ($0 as? UIMenu)?.identifier.rawValue ?? "<\($0.title)>" }
    }

    func mainMenu(for builder: UIMenuBuilder) {
        let newPrivateTab = UICommandAlternate(title: "New Private Tab", action: Sel.newPrivateTab, modifierFlags: [.shift])
        appMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: "Settings", action: Sel.openSettings, input: ",", modifierFlags: [.command, .alternate], discoverabilityTitle: "Settings")])
        fileMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: "New Tab", action: Sel.newTab, input: "t", modifierFlags: .command, alternates: [newPrivateTab], discoverabilityTitle: "New Tab"),
            UIKeyCommand(title: "New Private Tab", action: Sel.newPrivateTab, input: "p", modifierFlags: [.command, .shift], discoverabilityTitle: "New Private Tab"),
            UIKeyCommand(title: "Close Tab", action: Sel.closeTab, input: "w", modifierFlags: .command, discoverabilityTitle: "Close Tab")])
        fileMenu.children.forEach { ($0 as? UIKeyCommand)?.wantsPriorityOverSystemBehavior = true }
        findMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: "Find", action: Sel.findInPage, input: "f", modifierFlags: .command, discoverabilityTitle: "Find")])
        viewMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: "Reload", action: Sel.reload, input: "r", modifierFlags: .command, discoverabilityTitle: "Reload")])
        historyMenu = UIMenu(title: "History", identifier: Self.history, options: .displayInline, children: [
            UIKeyCommand(title: "Back", action: Sel.goBack, input: "[", modifierFlags: .command, discoverabilityTitle: "Back")])
        let bookmarksMenu = UIMenu(title: "Bookmarks", identifier: Self.bookmarks, options: .displayInline, children: [
            UIKeyCommand(title: "Add Bookmark", action: Sel.addBookmark, input: "d", modifierFlags: .command, discoverabilityTitle: "Add Bookmark")])
        let toolsMenu = UIMenu(title: "Tools", identifier: Self.tools, options: .displayInline, children: [
            UIKeyCommand(title: "Downloads", action: Sel.showDownloads, input: "j", modifierFlags: .command, discoverabilityTitle: "Downloads")])
        let windowMenu = UIMenu(title: "Window", options: .displayInline, children: [
            UIKeyCommand(title: "Next Tab", action: Sel.nextTab, input: "\t", modifierFlags: [.control], discoverabilityTitle: "Next Tab")])
        let probeAction = UIAction(title: "Probe Action", identifier: UIAction.Identifier("com.openuikit.probe.action")) { _ in }

        beforeSteps = ["root": topLevel(builder), "application": childIds(builder, .application),
                       "file": childIds(builder, .file), "view": childIds(builder, .view),
                       "window": childIds(builder, .window), "edit": childIds(builder, .edit)]
        afterSteps = []
        builder.insertChild(appMenu, atStartOfMenu: .application)
        afterSteps.append(childIds(builder, .application))
        builder.insertChild(fileMenu, atStartOfMenu: .file)
        afterSteps.append(childIds(builder, .file))
        builder.replace(menu: .find, with: findMenu)
        afterSteps.append(childIds(builder, .edit))
        builder.remove(menu: .font)
        afterSteps.append(childIds(builder, .format))
        builder.insertChild(viewMenu, atStartOfMenu: .view)
        afterSteps.append(childIds(builder, .view))
        builder.insertSibling(historyMenu, afterMenu: .view)
        afterSteps.append(topLevel(builder))
        builder.insertSibling(bookmarksMenu, afterMenu: Self.history)
        builder.insertSibling(toolsMenu, afterMenu: Self.bookmarks)
        afterSteps.append(topLevel(builder))
        builder.insertChild(windowMenu, atStartOfMenu: .window)
        afterSteps.append(childIds(builder, .window))
        builder.insertChild(UIMenu(title: "Probe", identifier: UIMenu.Identifier("com.openuikit.probe.menu"),
                                   options: .displayInline, children: [probeAction]), atEndOfMenu: .help)
        afterSteps.append(childIds(builder, .help))
    }
}

// MARK: - UICommandAlternate

#if !os(Linux)
@MainActor
#endif
final class CommandAlternateTests: XCTestCase {

    private func window(_ root: UIViewController) -> UIWindow {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        w.rootViewController = root
        w.makeKeyAndVisible()
        return w
    }

    override func setUp() {
        super.setUp()
        // Each test starts from an unbuilt main system, like a fresh process.
        UIMenuSystem.main._resetForTesting()
        UIApplication.shared._hostLaunch(delegate: FirefoxDelegate())
    }

    /// `model.alternate`: title/action/flags read back; equal iff flags equal.
    func testModel() {
        let a1 = UICommandAlternate(title: "One", action: Sel.altShift, modifierFlags: .shift)
        let a1b = UICommandAlternate(title: "Other title, same flags", action: Sel.base, modifierFlags: .shift)
        let a2 = UICommandAlternate(title: "Two", action: Sel.altOption, modifierFlags: [.alternate, .shift])
        XCTAssertEqual(a1.title, "One")
        XCTAssertEqual(a1.action.actionName, "fireAltShift:")
        XCTAssertEqual(a1.modifierFlags.rawValue, 131072)
        XCTAssertEqual(a2.modifierFlags.rawValue, 655360)
        XCTAssertTrue(a1 == a1b, "equal iff modifierFlags equal")
        XCTAssertTrue(a1.isEqual(a1b))
        XCTAssertFalse(a1 == a2)
        XCTAssertEqual(a1.hash, a1b.hash)

        let kc = UIKeyCommand(title: "KC", action: Sel.base, input: "j", modifierFlags: .command, alternates: [a1, a2])
        XCTAssertEqual(kc.alternates.count, 2)
        XCTAssertTrue(kc.alternates[0] === a1)
        XCTAssertTrue(kc.alternates[1] === a2)
        XCTAssertEqual(UIKeyCommand(title: "x", action: Sel.base, input: "x").alternates.count, 0)
        let cmd = UICommand(title: "Cmd", action: Sel.base, alternates: [a2])
        XCTAssertEqual(cmd.alternates.count, 1)
        XCTAssertTrue(cmd.alternates[0] === a2)
    }

    /// Phase A: Cmd-J → base; Cmd-Shift-J / Cmd-Alt-J → the alternates with a
    /// SYNTHESIZED sender; Cmd-Ctrl-J, Cmd-Shift-Alt-J and plain J → nothing.
    func testAlternateModifiersSelectTheAlternateAction() {
        let vc = RootVC(); vc.phase = "A"
        let w = window(vc)

        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: .command))
        XCTAssertEqual(vc.fired.map(\.action), ["fireBase"])
        let baseSender = vc.fired[0].sender as? UIKeyCommand
        XCTAssertEqual(baseSender?.title, "Base")
        XCTAssertEqual(baseSender?.alternates.count, 2)

        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: [.command, .shift]))
        XCTAssertEqual(vc.fired.map(\.action), ["fireBase", "fireAltShift"])
        let altSender = vc.fired[1].sender as? UIKeyCommand
        XCTAssertEqual(altSender?.title, "Alt Shift")
        XCTAssertEqual(altSender?.action.actionName, "fireAltShift:")
        XCTAssertEqual(altSender?.input, "j")
        XCTAssertEqual(altSender?.modifierFlags.rawValue, 1179648)
        XCTAssertEqual(altSender?.alternates.count, 0)

        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: [.command, .alternate]))
        XCTAssertEqual(vc.fired.last?.action, "fireAltOption")
        XCTAssertEqual((vc.fired.last?.sender as? UIKeyCommand)?.modifierFlags.rawValue, 1572864)

        XCTAssertFalse(w.performKeyCommand(input: "j", modifierFlags: [.command, .control]))
        XCTAssertFalse(w.performKeyCommand(input: "j", modifierFlags: [.command, .shift, .alternate]))
        XCTAssertFalse(w.performKeyCommand(input: "j", modifierFlags: []))
        XCTAssertEqual(vc.fired.count, 3)
    }

    /// Phases B/C: `keyCommands` order decides between an earlier command's
    /// alternate and a later direct match for the same press.
    func testListOrderDecidesBetweenAlternateAndDirectMatch() {
        let vc = RootVC()
        let w = window(vc)
        vc.phase = "B"
        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: [.command, .shift]))
        XCTAssertEqual(vc.fired.last?.action, "fireAltShift")
        vc.phase = "C"
        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: [.command, .shift]))
        XCTAssertEqual(vc.fired.last?.action, "fireDirect")
        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: .command))
        XCTAssertEqual(vc.fired.last?.action, "fireBase")
    }

    /// `validate` events: once per performed press, on the start responder,
    /// with the resolved command (the synthesized one for an alternate).
    func testValidateIsSentOnceWithTheResolvedCommand() {
        let vc = RootVC(); vc.phase = "A"
        let w = window(vc)
        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: [.command, .shift]))
        XCTAssertEqual(vc.validated.count, 1)
        XCTAssertEqual(vc.validated.first?.title, "Alt Shift")
        XCTAssertTrue(vc.validated.first === (vc.fired.first?.sender as AnyObject))
        XCTAssertFalse(w.performKeyCommand(input: "j", modifierFlags: [.command, .control]))
        XCTAssertEqual(vc.validated.count, 1, "an unmatched press validates nothing")
    }
}

// MARK: - UIMenuBuilder

#if !os(Linux)
@MainActor
#endif
final class MenuBuilderTests: XCTestCase {

    private var delegate: FirefoxDelegate!

    private func window(_ root: UIViewController) -> UIWindow {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        w.rootViewController = root
        w.makeKeyAndVisible()
        return w
    }

    override func setUp() {
        super.setUp()
        UIMenuSystem.main._resetForTesting()
        delegate = FirefoxDelegate()
        UIApplication.shared._hostLaunch(delegate: delegate)
    }

    /// Timeline rows: no build at launch or on becoming active; the FIRST key
    /// event builds, application then delegate, never the controller; a
    /// second key event does not rebuild.
    func testMainSystemBuildsOnTheFirstKeyEventFromTheApplication() {
        let vc = RootVC()
        let w = window(vc)
        UIApplication.shared._hostDidBecomeActive()
        XCTAssertEqual(delegate.buildLog, [])
        XCTAssertEqual(UIMenuSystem.main._buildCount, 0)

        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        XCTAssertEqual(delegate.buildLog, ["AppDelegate/main"])
        XCTAssertEqual(vc.buildLog, [], "the main walk starts at the application, not at a controller")
        XCTAssertEqual(UIMenuSystem.main._buildCount, 1)
        XCTAssertTrue(delegate.lastBuilder?.system === UIMenuSystem.main)

        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        XCTAssertEqual(UIMenuSystem.main._buildCount, 1)
    }

    /// `setNeedsRebuild` builds nothing itself; the next key event rebuilds.
    /// `setNeedsRevalidate` validates nothing.
    func testSetNeedsRebuildIsDeferredToTheNextKeyEvent() {
        let vc = RootVC()
        let w = window(vc)
        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        XCTAssertEqual(UIMenuSystem.main._buildCount, 1)
        UIMenuSystem.main.setNeedsRebuild()
        XCTAssertEqual(UIMenuSystem.main._buildCount, 1, "no build inside the call")
        XCTAssertEqual(delegate.buildLog.count, 1)
        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        XCTAssertEqual(UIMenuSystem.main._buildCount, 2)
        XCTAssertEqual(delegate.buildLog, ["AppDelegate/main", "AppDelegate/main"])

        UIMenuSystem.main.setNeedsRevalidate()
        XCTAssertEqual(vc.validated.count, 0)
        XCTAssertTrue(UIMenuSystem.main === UIMenuSystem.main)
        XCTAssertFalse(UIMenuSystem.main === UIMenuSystem.context)
    }

    /// `builder.main.defaults.*`: the identifiers the default builder carries.
    func testDefaultBuilderCarriesTheMeasuredIdentifiers() {
        delegate.replaysFirefox = false
        let w = window(RootVC())
        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        guard let b = delegate.lastBuilder else { return XCTFail("no build") }

        XCTAssertEqual(delegate.topLevel(b), ["com.apple.menu.application", "com.apple.menu.file", "com.apple.menu.edit",
                                              "com.apple.menu.format", "com.apple.menu.view", "com.apple.menu.window", "com.apple.menu.help"])
        XCTAssertEqual(delegate.childIds(b, .application), ["com.apple.menu.about", "com.apple.menu.preferences", "com.apple.menu.services",
                                                            "com.apple.menu.hide", "com.apple.menu.quit"])
        XCTAssertEqual(delegate.childIds(b, .file), ["com.apple.menu.new-item", "com.apple.menu.open", "com.apple.menu.close",
                                                     "com.apple.menu.document", "com.apple.menu.print"])
        XCTAssertEqual(delegate.childIds(b, .edit), ["com.apple.menu.undo-redo", "com.apple.menu.standard-edit", "com.apple.menu.find",
                                                     "com.apple.menu.spelling", "com.apple.menu.substitutions", "com.apple.menu.transformations",
                                                     "com.apple.command.speech"])
        XCTAssertEqual(delegate.childIds(b, .view), ["com.apple.menu.toolbar", "com.apple.menu.sidebar", "com.apple.menu.fullscreen"])
        XCTAssertEqual(delegate.childIds(b, .window), ["com.apple.menu.minimize-and-zoom", "com.apple.menu.bring-all-to-front"])
        XCTAssertEqual(delegate.childIds(b, .format), ["com.apple.menu.font", "com.apple.menu.text"])
        for id in [UIMenu.Identifier.autoFill, .learn, .lookup, .openRecent, .replace, .share] {
            XCTAssertNil(b.menu(for: id), id.rawValue)
        }
        // Contents: File > Close is Cmd-W performClose:, Edit > undo-redo has
        // Undo ⌘Z / Redo ⌘⇧Z, Help is a single ⌘? showHelp:, Delete is a
        // destructive UICommand, Paste and Match Style is ⌘⌥⇧V.
        let close = b.menu(for: .close)?.children.first as? UIKeyCommand
        XCTAssertEqual(close?.title, "Close"); XCTAssertEqual(close?.input, "w")
        XCTAssertEqual(close?.modifierFlags, .command); XCTAssertEqual(close?.action.actionName, "performClose:")
        let undoRedo = b.menu(for: .undoRedo)?.children.compactMap { $0 as? UIKeyCommand }
        XCTAssertEqual(undoRedo?.map(\.title), ["Undo", "Redo"])
        XCTAssertEqual(undoRedo?.map { $0.modifierFlags.rawValue }, [1048576, 1179648])
        let help = b.menu(for: .help)?.children.first as? UIKeyCommand
        XCTAssertEqual(help?.input, "?"); XCTAssertEqual(help?.action.actionName, "showHelp:"); XCTAssertEqual(help?.title, "")
        let standard = b.menu(for: .standardEdit)?.children ?? []
        XCTAssertEqual(standard.map(\.title), ["Cut", "Copy", "Paste", "Paste and Match Style", "Delete", "Select All"])
        XCTAssertEqual((standard[3] as? UIKeyCommand)?.modifierFlags.rawValue, 1703936)
        XCTAssertTrue(standard[4] is UICommand && !(standard[4] is UIKeyCommand))
        XCTAssertEqual(standard[4].attributes, .destructive)
        XCTAssertEqual(b.menu(for: .sidebar)?.children.compactMap { $0 as? UIKeyCommand }.first?.modifierFlags.rawValue, 1310720)
        XCTAssertEqual(b.menu(for: .preferences)?.children.first?.title.hasSuffix(" Settings…"), true)
        XCTAssertEqual(b.menu(for: .root)?.identifier, .root)
        XCTAssertEqual(b.menu(for: .root)?.title, "")
        XCTAssertEqual(b.menu(for: .services)?.options, [])
        XCTAssertEqual(b.menu(for: .about)?.options, .displayInline)
        XCTAssertEqual(b.command(for: Selector(("cut:")))?.title, "Cut")
    }

    /// `builder.main.1.steps`: firefox's MenuBuilderHelper sequence, step by step.
    func testFirefoxSequenceMutatesTheTreeAsMeasured() {
        let w = window(RootVC())
        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        guard let b = delegate.lastBuilder else { return XCTFail("no build") }
        let d = delegate!
        let steps = d.afterSteps
        XCTAssertEqual(steps.count, 9)
        // 1. insertChild(app, atStartOf: .application) — index 0, dynamic id.
        XCTAssertEqual(steps[0].first, d.appMenu.identifier.rawValue)
        XCTAssertTrue(steps[0][0].hasPrefix("com.apple.menu.dynamic."))
        XCTAssertEqual(Array(steps[0].dropFirst()), d.beforeSteps["application"] as? [String])
        // 2. insertChild(file, atStartOf: .file)
        XCTAssertEqual(steps[1], [d.fileMenu.identifier.rawValue] + (d.beforeSteps["file"] as! [String]))
        // 3. replace(.find, with: findMenu) — in place, .find gone.
        XCTAssertEqual(steps[2], ["com.apple.menu.undo-redo", "com.apple.menu.standard-edit", d.findMenu.identifier.rawValue,
                                  "com.apple.menu.spelling", "com.apple.menu.substitutions", "com.apple.menu.transformations",
                                  "com.apple.command.speech"])
        // 4. remove(.font) — Format keeps Text only.
        XCTAssertEqual(steps[3], ["com.apple.menu.text"])
        // 5. insertChild(view, atStartOf: .view)
        XCTAssertEqual(steps[4], [d.viewMenu.identifier.rawValue, "com.apple.menu.toolbar", "com.apple.menu.sidebar", "com.apple.menu.fullscreen"])
        // 6. insertSibling(history, after: .view)
        XCTAssertEqual(steps[5], ["com.apple.menu.application", "com.apple.menu.file", "com.apple.menu.edit", "com.apple.menu.format",
                                  "com.apple.menu.view", "com.mozilla.firefox.menus.history", "com.apple.menu.window", "com.apple.menu.help"])
        // 7-8. bookmarks after history, tools after bookmarks
        XCTAssertEqual(steps[6], ["com.apple.menu.application", "com.apple.menu.file", "com.apple.menu.edit", "com.apple.menu.format",
                                  "com.apple.menu.view", "com.mozilla.firefox.menus.history", "com.mozilla.firefox.menus.bookmarks",
                                  "com.mozilla.firefox.menus.tools", "com.apple.menu.window", "com.apple.menu.help"])
        // 9. insertChild(window, atStartOf: .window)
        XCTAssertEqual(steps[7].dropFirst().map { $0 }, ["com.apple.menu.minimize-and-zoom", "com.apple.menu.bring-all-to-front"])
        // 10. insertChild(probe, atEndOf: .help) — after the ⌘? command.
        XCTAssertEqual(steps[8], ["<>", "com.openuikit.probe.menu"])

        // `builder.main.1.steps.lookups`
        XCTAssertNil(b.menu(for: .find))
        XCTAssertFalse(b.menu(for: d.findMenu.identifier) === d.findMenu, "menu(for:) returns a copy")
        XCTAssertEqual(b.menu(for: d.findMenu.identifier)?.title, "")
        XCTAssertNil(b.menu(for: .font))
        XCTAssertFalse(b.menu(for: FirefoxDelegate.history) === d.historyMenu)
        XCTAssertEqual(b.menu(for: FirefoxDelegate.history)?.title, "History")
        XCTAssertFalse(b.menu(for: d.fileMenu.identifier) === d.fileMenu)
        XCTAssertEqual(b.command(for: Sel.newTab)?.title, "New Tab")
        XCTAssertTrue(b.command(for: Sel.newTab) is UIKeyCommand)
        XCTAssertEqual((b.command(for: Sel.newPrivateTab) as? UIKeyCommand)?.input, "p")
        XCTAssertEqual(b.command(for: Sel.reload, propertyList: nil)?.title, "Reload")
        XCTAssertNil(b.command(for: Sel.neverInAMenu))
        XCTAssertEqual(b.command(for: Selector(("cut:")))?.title, "Cut")
        XCTAssertEqual(b.action(for: UIAction.Identifier("com.openuikit.probe.action"))?.title, "Probe Action")
        XCTAssertNil(b.action(for: UIAction.Identifier("com.openuikit.nope")))
        XCTAssertEqual(b.menu(for: .root)?.children.count, 10)
        // The inserted key command keeps its alternate through the copy.
        XCTAssertEqual((b.command(for: Sel.newTab) as? UIKeyCommand)?.alternates.count, 1)
    }

    /// `model.autoIdentifier`: a menu without an identifier is
    /// `com.apple.menu.dynamic.…`, never its title, and unique.
    func testMenuWithoutIdentifierGetsADynamicOne() {
        let a = UIMenu(title: "Titled"), b = UIMenu(), c = UIMenu(title: "Titled")
        XCTAssertTrue(a.identifier.rawValue.hasPrefix("com.apple.menu.dynamic."))
        XCTAssertTrue(b.identifier.rawValue.hasPrefix("com.apple.menu.dynamic."))
        XCTAssertNotEqual(a.identifier, c.identifier)
        XCTAssertEqual(UIMenu(title: "X", identifier: .file).identifier, .file)
    }

    /// `edge.steps`: unknown identifiers are silent no-ops; duplicates and
    /// re-inserted objects are accepted; a removed top-level menu is nil.
    func testEdgeCasesAreSilentNoOps() {
        delegate.replaysFirefox = false
        let w = window(RootVC())
        _ = w.performKeyCommand(input: "q", modifierFlags: [.command, .control, .alternate])
        guard let b = delegate.lastBuilder else { return XCTFail("no build") }
        let missing = UIMenu.Identifier("com.openuikit.missing")
        let before = delegate.topLevel(b)
        b.remove(menu: missing)
        b.replace(menu: missing, with: UIMenu(title: "R", options: .displayInline))
        b.insertSibling(UIMenu(title: "S", options: .displayInline), afterMenu: missing)
        b.insertSibling(UIMenu(title: "S", options: .displayInline), beforeMenu: missing)
        b.insertChild(UIMenu(title: "C", options: .displayInline), atStartOfMenu: missing)
        b.insertChild(UIMenu(title: "C", options: .displayInline), atEndOfMenu: missing)
        XCTAssertEqual(delegate.topLevel(b), before)
        XCTAssertEqual(b.menu(for: .edit)?.children.count, 7)

        b.replace(menu: .find, with: UIMenu(title: "F1", options: .displayInline))
        b.replace(menu: .find, with: UIMenu(title: "F2", options: .displayInline))
        XCTAssertNil(b.menu(for: .find))
        XCTAssertEqual(b.menu(for: .edit)?.children[2].title, "F1", "the second replace of a gone identifier does nothing")

        b.remove(menu: .file)
        XCTAssertNil(b.menu(for: .file))
        XCTAssertEqual(delegate.topLevel(b), ["com.apple.menu.application", "com.apple.menu.edit", "com.apple.menu.format",
                                              "com.apple.menu.view", "com.apple.menu.window", "com.apple.menu.help"])

        let dup = UIMenu.Identifier("com.openuikit.dup")
        b.insertChild(UIMenu(title: "D1", identifier: dup, options: .displayInline), atStartOfMenu: .edit)
        b.insertChild(UIMenu(title: "D2", identifier: dup, options: .displayInline), atEndOfMenu: .edit)
        XCTAssertEqual(b.menu(for: .edit)?.children.count, 9)
        let twice = UIMenu(title: "Twice", options: .displayInline)
        b.insertChild(twice, atStartOfMenu: .view)
        b.insertChild(twice, atEndOfMenu: .window)
        XCTAssertEqual(b.menu(for: .view)?.children.first?.title, "Twice")
        XCTAssertEqual(b.menu(for: .window)?.children.last?.title, "Twice")
    }

    /// `menuOnly` presses: shortcuts that live only in the built main menu
    /// fire through the chain from the start responder; the alternate on
    /// Cmd-T; firefox's Close Tab at the start of File beats UIKit's Close;
    /// a responder's own command beats the menu's for the same press.
    func testMainMenuShortcutsFireWhenNoResponderVendsThem() {
        let vc = RootVC()
        let w = window(vc)

        XCTAssertTrue(w.performKeyCommand(input: "t", modifierFlags: .command))
        XCTAssertEqual(vc.fired.last?.action, "newTab")
        let newTab = vc.fired.last?.sender as? UIKeyCommand
        XCTAssertEqual(newTab?.title, "New Tab")
        XCTAssertEqual(newTab?.alternates.count, 1)

        XCTAssertTrue(w.performKeyCommand(input: "t", modifierFlags: [.command, .shift]))
        XCTAssertEqual(vc.fired.last?.action, "newPrivateTab")
        let alt = vc.fired.last?.sender as? UIKeyCommand
        XCTAssertEqual(alt?.title, "New Private Tab")
        XCTAssertEqual(alt?.input, "t")
        XCTAssertEqual(alt?.modifierFlags.rawValue, 1179648)
        XCTAssertEqual(alt?.alternates.count, 0)
        XCTAssertEqual(alt?.action.actionName, "newPrivateTabKeyCommand:")

        XCTAssertFalse(w.performKeyCommand(input: "t", modifierFlags: [.command, .alternate]))
        XCTAssertTrue(w.performKeyCommand(input: "p", modifierFlags: [.command, .shift]))
        XCTAssertEqual(vc.fired.last?.action, "newPrivateTab")
        XCTAssertEqual((vc.fired.last?.sender as? UIKeyCommand)?.input, "p")
        XCTAssertTrue(w.performKeyCommand(input: "w", modifierFlags: .command))
        XCTAssertEqual(vc.fired.last?.action, "closeTab")
        XCTAssertTrue(w.performKeyCommand(input: ",", modifierFlags: [.command, .alternate]))
        XCTAssertEqual(vc.fired.last?.action, "openSettings")
        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: .command))
        XCTAssertEqual(vc.fired.last?.action, "showDownloads")
        // validate once per performed press, on the start responder.
        XCTAssertEqual(vc.validated.map(\.title), ["New Tab", "New Private Tab", "New Private Tab", "Close Tab", "Settings", "Downloads"])

        vc.phase = "A"
        XCTAssertTrue(w.performKeyCommand(input: "j", modifierFlags: .command))
        XCTAssertEqual(vc.fired.last?.action, "fireBase", "a responder's command beats the menu's")
        // Nothing in the chain implements UIKit's own File > Close.
        delegate.replaysFirefox = false
        UIMenuSystem.main.setNeedsRebuild()
        vc.phase = "none"
        XCTAssertFalse(w.performKeyCommand(input: "w", modifierFlags: .command))
    }

    /// The host-facing menu: built on demand, firefox's rows present.
    func testCurrentMenuBuildsOnDemand() {
        _ = window(RootVC())
        XCTAssertEqual(UIMenuSystem.main._buildCount, 0)
        let root = UIMenuSystem.main._currentMenu()
        XCTAssertEqual(UIMenuSystem.main._buildCount, 1)
        XCTAssertEqual(root?.children.count, 10)
        XCTAssertEqual((root?.children[5] as? UIMenu)?.identifier, FirefoxDelegate.history)
    }

    /// `presentEditMenu` rows: the CONTEXT system is built from the source
    /// view up to the app delegate before the delegate's menuFor, and an
    /// override that skips `super` does not stop the walk.
    func testEditMenuPresentationBuildsTheContextSystemUpTheChain() {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return }
        final class LoggingView: UIView {
            var log: [String] = []
            var callsSuper = true
            override func buildMenu(with builder: UIMenuBuilder) {
                log.append("view/" + (builder.system === UIMenuSystem.context ? "context" : "main"))
                if callsSuper { super.buildMenu(with: builder) }
            }
        }
        let vc = RootVC()
        _ = window(vc)
        let view = LoggingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        vc.view.addSubview(view)
        let interaction = UIEditMenuInteraction(delegate: nil)
        view.addInteraction(interaction)
        view.callsSuper = false
        interaction.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: 10, y: 10)))
        XCTAssertEqual(view.log, ["view/context"])
        XCTAssertEqual(vc.buildLog, ["RootVC/context"])
        XCTAssertEqual(delegate.buildLog, ["AppDelegate/context"])
        XCTAssertEqual(UIMenuSystem.main._buildCount, 0, "the main system is untouched")
    }
}
