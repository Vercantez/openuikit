// Key commands + UIAction dispatch (M13 "menus & actions").
//
// Key commands have no pixels — they are pure routing — so this is where
// they are gated. The contract under test is UIKit's, spelled out in the
// header of Sources/OpenUIKit/UIMenu.swift: the window walks the responder
// chain from the first responder, the first matching command wins, and its
// action is sent to the responder that vended it and then up the chain.
import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGRect = OpenUIKit.CGRect
private typealias CGPoint = OpenUIKit.CGPoint

/// A view controller that vends key commands and records what ran.
@MainActor
private final class CommandVC: UIViewController, SelectorDispatching {
    var log: [String] = []
    var commands: [UIKeyCommand] = []

    override var keyCommands: [UIKeyCommand]? { commands.isEmpty ? nil : commands }

    static let actions: ActionTable<CommandVC> = [
        .action("newItem", CommandVC.newItem),
        .action("save", CommandVC.save),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
    func newItem() { log.append("newItem") }
    func save() { log.append("save") }
}

/// A responder that implements an action nothing below it knows — the target
/// of an "up the chain" dispatch.
@MainActor
private final class HandlerVC: UIViewController, SelectorDispatching {
    var log: [String] = []
    static let actions: ActionTable<HandlerVC> = [.action("publish", HandlerVC.publish)]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
    func publish() { log.append("publish") }
}

@MainActor
final class KeyCommandTests: XCTestCase {

    private func makeWindow(root: UIViewController) -> UIWindow {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        w.rootViewController = root
        w.makeKeyAndVisible()
        return w
    }

    func testCommandOnTheRootControllerRuns() {
        let vc = CommandVC()
        vc.commands = [UIKeyCommand(input: "n", modifierFlags: .command,
                                    action: Selector(("newItem")))]
        let w = makeWindow(root: vc)
        XCTAssertTrue(w.performKeyCommand(input: "n", modifierFlags: .command))
        XCTAssertEqual(vc.log, ["newItem"])
    }

    func testModifiersMustMatchExactly() {
        let vc = CommandVC()
        vc.commands = [UIKeyCommand(input: "n", modifierFlags: .command,
                                    action: Selector(("newItem")))]
        let w = makeWindow(root: vc)
        XCTAssertFalse(w.performKeyCommand(input: "n", modifierFlags: []))
        XCTAssertFalse(w.performKeyCommand(input: "n",
                                           modifierFlags: [.command, .shift]))
        XCTAssertTrue(vc.log.isEmpty)
    }

    /// UIKit matches a letter input case-insensitively; SHIFT is expressed in
    /// modifierFlags, not by the letter's case.
    func testLetterMatchingIsCaseInsensitive() {
        let vc = CommandVC()
        vc.commands = [UIKeyCommand(input: "N", modifierFlags: .command,
                                    action: Selector(("newItem")))]
        let w = makeWindow(root: vc)
        XCTAssertTrue(w.performKeyCommand(input: "n", modifierFlags: .command))
        XCTAssertEqual(vc.log, ["newItem"])
    }

    /// The walk starts at the FIRST RESPONDER, so a focused text field's
    /// ancestors are reached — and a command found on an ancestor still runs.
    func testWalkStartsAtTheFirstResponderAndClimbs() {
        let vc = CommandVC()
        vc.commands = [UIKeyCommand(input: "s", modifierFlags: .command,
                                    action: Selector(("save")))]
        let w = makeWindow(root: vc)
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        vc.view.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(w.performKeyCommand(input: "s", modifierFlags: .command))
        XCTAssertEqual(vc.log, ["save"])
    }

    /// A command vended by a responder that does NOT implement its action is
    /// dispatched UP the chain (UIKit's nil-targeted action). The chain runs
    /// field -> child.view -> child -> handler.view -> handler, so the
    /// command is found on `child` and the method on `handler`.
    func testActionClimbsToTheResponderThatImplementsIt() {
        let handler = HandlerVC()
        let child = CommandVC()
        child.commands = [UIKeyCommand(input: "u", modifierFlags: .command,
                                       action: Selector(("publish")))]
        let w = makeWindow(root: handler)
        handler.addChild(child)
        handler.view.addSubview(child.view)
        child.didMove(toParent: handler)
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        child.view.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())

        XCTAssertTrue(w.performKeyCommand(input: "u", modifierFlags: .command))
        XCTAssertEqual(handler.log, ["publish"])
        XCTAssertTrue(child.log.isEmpty)

        // Nothing in the chain implements this one.
        child.commands = [UIKeyCommand(input: "k", modifierFlags: .command,
                                       action: Selector(("nobodyImplementsThis")))]
        XCTAssertFalse(w.performKeyCommand(input: "k", modifierFlags: .command))
    }

    /// The closure form runs its handler and needs no selector table.
    func testClosureCommand() {
        var ran = 0
        let vc = CommandVC()
        vc.commands = [UIKeyCommand(input: "b", modifierFlags: [.command]) { _ in ran += 1 }]
        let w = makeWindow(root: vc)
        XCTAssertTrue(w.performKeyCommand(input: "b", modifierFlags: .command))
        XCTAssertEqual(ran, 1)
    }

    func testDisabledCommandIsSkipped() {
        let vc = CommandVC()
        let c = UIKeyCommand(title: "New", action: Selector(("newItem")),
                             input: "n", modifierFlags: .command,
                             attributes: .disabled)
        vc.commands = [c]
        let w = makeWindow(root: vc)
        XCTAssertFalse(w.performKeyCommand(input: "n", modifierFlags: .command))
        XCTAssertTrue(vc.log.isEmpty)
    }

    func testUnmatchedPressReportsFalseSoTheHostCanFallThrough() {
        let vc = CommandVC()
        let w = makeWindow(root: vc)
        XCTAssertFalse(w.performKeyCommand(input: "z", modifierFlags: .command))
    }

    /// Special keys use UIKit's own input constants, so a host that produces
    /// them needs no mapping table of its own.
    func testSpecialKeyInputs() {
        let vc = CommandVC()
        var ran = 0
        vc.commands = [UIKeyCommand(input: UIKeyCommand.inputUpArrow) { _ in ran += 1 }]
        let w = makeWindow(root: vc)
        XCTAssertTrue(w.performKeyCommand(input: UIKeyCommand.inputUpArrow))
        XCTAssertEqual(ran, 1)
    }
}

// MARK: - UIAction / UIMenu model

@MainActor
final class ActionModelTests: XCTestCase {

    func testActionIdentifierDefaultsToItsTitle() {
        let a = UIAction(title: "Copy") { _ in }
        XCTAssertEqual(a.identifier.rawValue, "Copy")
    }

    func testActionRunsWithItsSender() {
        var seen: Any?
        let a = UIAction(title: "Copy") { action in seen = action.sender }
        let button = UIButton(type: .custom)
        a.performWithSender(button, target: nil)
        XCTAssertTrue(seen as AnyObject === button)
    }

    func testDisabledActionDoesNotRun() {
        var ran = false
        let a = UIAction(title: "Copy", attributes: .disabled) { _ in ran = true }
        a.performWithSender(nil, target: nil)
        XCTAssertFalse(ran)
    }

    func testControlAddAction() {
        var ran = 0
        let control = UIControl()
        let a = UIAction(title: "Tap") { _ in ran += 1 }
        control.addAction(a, for: .touchUpInside)
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(ran, 1)
        control.removeAction(a, for: .touchUpInside)
        control.sendActions(for: .touchUpInside)
        XCTAssertEqual(ran, 1)
    }

    func testButtonPrimaryActionSetsTheTitleAndRuns() {
        var ran = 0
        let button = UIButton(type: .system,
                              primaryAction: UIAction(title: "Send") { _ in ran += 1 })
        XCTAssertEqual(button.currentTitle, "Send")
        button.performPrimaryAction()
        XCTAssertEqual(ran, 1)
    }

    /// `showsMenuAsPrimaryAction`: a tap presents the menu and sends NO
    /// touchUpInside (UIKit's rule).
    func testMenuAsPrimaryActionPresentsInsteadOfFiring() {
        var tapped = 0
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 10, y: 10, width: 100, height: 44)
        button.addTarget(for: .touchUpInside) { _, _ in tapped += 1 }
        button.menu = UIMenu(children: [UIAction(title: "Copy") { _ in }])
        button.showsMenuAsPrimaryAction = true
        w.addSubview(button)
        w.makeKeyAndVisible()
        button.performPrimaryAction()
        XCTAssertEqual(tapped, 0)
        XCTAssertNotNil(_UIMenuPresentation.active)
        _UIMenuPresentation.active?.dismiss()
        XCTAssertNil(_UIMenuPresentation.active)
    }

    /// Choosing a row runs the action and takes the menu down.
    func testSelectingARowRunsTheActionAndDismisses() {
        var ran = 0
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let source = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 44))
        w.addSubview(source)
        w.makeKeyAndVisible()
        let menu = UIMenu(children: [UIAction(title: "Copy") { _ in ran += 1 }])
        let p = _UIMenuPresentation.present(menu, from: source)
        XCTAssertNotNil(p)
        p?.select(menu.children[0])
        XCTAssertEqual(ran, 1)
        XCTAssertNil(_UIMenuPresentation.active)
    }

    /// A submenu row swaps the platter for the submenu's.
    func testSubmenuRowOpensTheSubmenu() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let source = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 44))
        w.addSubview(source)
        w.makeKeyAndVisible()
        let sub = UIMenu(title: "More", children: [UIAction(title: "Alpha") { _ in }])
        let menu = UIMenu(children: [UIAction(title: "Copy") { _ in }, sub])
        let p = _UIMenuPresentation.present(menu, from: source)
        p?.select(sub)
        XCTAssertTrue(_UIMenuPresentation.active?.menu === sub)
        _UIMenuPresentation.active?.dismiss()
    }

    func testMenuSectionsSplitOnInlineChildren() {
        let menu = UIMenu(children: [
            UIAction(title: "A") { _ in },
            UIMenu(options: .displayInline, children: [UIAction(title: "B") { _ in }]),
            UIAction(title: "C") { _ in },
        ])
        let sections = menu.sections
        XCTAssertEqual(sections.count, 3)
        XCTAssertEqual(sections.map { $0.map(\.title) }, [["A"], ["B"], ["C"]])
    }

    func testReplacingChildrenKeepsIdentityAndOptions() {
        let menu = UIMenu(title: "T", options: .displayInline,
                          children: [UIAction(title: "A") { _ in }])
        let updated = menu.replacingChildren([UIAction(title: "B") { _ in }])
        XCTAssertEqual(updated.title, "T")
        XCTAssertEqual(updated.identifier, menu.identifier)
        XCTAssertTrue(updated.options.contains(.displayInline))
        XCTAssertEqual(updated.children.map(\.title), ["B"])
    }
}

// MARK: - UIContextMenuInteraction

@MainActor
private final class ContextDelegate: UIContextMenuInteractionDelegate {
    var willDisplay = 0
    var willEnd = 0
    let menu: UIMenu
    init(menu: UIMenu) { self.menu = menu }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint)
        -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in self.menu }
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) { willDisplay += 1 }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) { willEnd += 1 }
}

@MainActor
final class ContextMenuInteractionTests: XCTestCase {

    func testLongPressPresentsTheConfiguredMenu() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let view = UIView(frame: CGRect(x: 20, y: 40, width: 120, height: 60))
        w.addSubview(view)
        w.makeKeyAndVisible()
        let menu = UIMenu(children: [UIAction(title: "Copy") { _ in }])
        let delegate = ContextDelegate(menu: menu)
        let interaction = UIContextMenuInteraction(delegate: delegate)
        view.addInteraction(interaction)
        XCTAssertEqual(view.interactions.count, 1)

        // Hold past UIKit's 0.5 s long-press duration on the host clock.
        w.sendTouch(.began, at: CGPoint(x: 60, y: 60), timestamp: 0)
        w.tick(timestamp: 0.6)
        XCTAssertNotNil(_UIMenuPresentation.active)
        XCTAssertEqual(delegate.willDisplay, 1)

        interaction.dismissMenu()
        XCTAssertNil(_UIMenuPresentation.active)
        XCTAssertEqual(delegate.willEnd, 1)
        view.removeInteraction(interaction)
        XCTAssertTrue(view.interactions.isEmpty)
    }

    /// A real tap on a row runs it; a real tap outside takes the menu down
    /// (UIKit). Both go through the window's touch pipeline, not a shortcut.
    func testTapsOnAndOutsideThePlatter() {
        var ran = 0
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 600))
        let source = UIView(frame: CGRect(x: 40, y: 120, width: 100, height: 44))
        w.addSubview(source)
        w.makeKeyAndVisible()
        let menu = UIMenu(children: [UIAction(title: "Copy") { _ in ran += 1 }])
        _UIMenuPresentation.present(menu, from: source)
        w.layoutIfNeeded()

        // Outside the platter (which spans (40,120)-(290,182)).
        w.sendTouch(.began, at: CGPoint(x: 350, y: 500), timestamp: 0)
        w.sendTouch(.ended, at: CGPoint(x: 350, y: 500), timestamp: 0.05)
        XCTAssertNil(_UIMenuPresentation.active)
        XCTAssertEqual(ran, 0)

        _UIMenuPresentation.present(menu, from: source)
        w.layoutIfNeeded()
        // The first row's centre: platter top 120 + 10 padding + 21.
        w.sendTouch(.began, at: CGPoint(x: 150, y: 151), timestamp: 1)
        w.sendTouch(.ended, at: CGPoint(x: 150, y: 151), timestamp: 1.05)
        XCTAssertEqual(ran, 1)
        XCTAssertNil(_UIMenuPresentation.active)
    }

    func testConfigurationWithoutAMenuPresentsNothing() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let view = UIView(frame: CGRect(x: 20, y: 40, width: 120, height: 60))
        w.addSubview(view)
        w.makeKeyAndVisible()
        let config = UIContextMenuConfiguration()
        XCTAssertNil(config.resolvedMenu())
    }
}
