// Selector target-action demo app. Owner: demo app (M12 app-compat).
//
// Every control and gesture on this screen is wired the way a real UIKit app
// wires them -- `addTarget(_:action:for:)` and
// `UITapGestureRecognizer(target:action:)` -- and NOT with closures. It is the
// end-to-end proof for docs/OBJC_RUNTIME.md's selector path.
//
// Hosted by `openhost --app selectors`; driven headlessly by
// scripts/selector_interaction.json.
//
// One thing here is not verbatim UIKit, and it is the honest cost of the
// feature (see docs/OBJC_RUNTIME.md "What an app author must change"):
//
//   * On Darwin the actions are `@objc` and the selectors are `#selector(...)`
//     -- literally UIKit source.
//   * Off Darwin neither `@objc` nor `#selector` compiles at all, so the same
//     selectors are spelled `Selector.named("incrementTapped")`. That spelling
//     compiles on Darwin too, so an app that wants ONE source for both
//     platforms writes it everywhere and never writes `@objc` -- the call
//     sites below are identical either way.
//   * Either way the target must supply the name -> method table, because
//     without an ObjC runtime nothing else can. That is the `ActionTable`
//     below plus the two-line `SelectorDispatching` conformance.
//
// Two Darwin-only details, both documented in docs/OBJC_RUNTIME.md:
//
//   * `@objc` is only legal when the Foundation module is loaded. A *scoped*
//     import (`import struct Foundation.Data`) satisfies that without pulling
//     CoreGraphics' `CGSize`/`CGRect` in to collide with OpenUIKit's. A plain
//     `import Foundation` does collide.
//   * An `@objc` method's parameters must be ObjC-representable, and
//     OpenUIKit's classes are pure Swift, so a 1-argument action's sender is
//     typed `AnyObject` (ObjC `id`) and downcast. Real UIKit apps write
//     `@objc func tapped(_ sender: UIButton)`; here that must be
//     `@objc func tapped(_ sender: AnyObject)`.

import OpenUIKit
#if canImport(ObjectiveC)
import struct Foundation.Data     // makes `@objc` legal; see header
#endif

public enum SelectorApp {
    /// Same iPhone-ish portrait window as the other demo apps.
    public static let windowSize = CGSize(width: 390, height: 780)

    public static func makeRootViewController() -> UINavigationController {
        UINavigationController(rootViewController: SelectorDemoViewController())
    }
}

// MARK: - The selectors

#if canImport(ObjectiveC)
/// Darwin: genuine `#selector`. The `@objc` methods exist so `#selector` can
/// name them; they forward to the implementations, which is also what the
/// ActionTable dispatches to, so both platforms run the same code.
extension SelectorDemoViewController {
    @objc func incrementTapped() { increment() }
    @objc func resetTapped(_ sender: AnyObject) { reset(sender as! UIButton) }
    @objc func enabledChanged(_ sender: AnyObject) { enabledDidChange(sender as! UISwitch) }
    @objc func handleTap(_ recognizer: AnyObject) {
        tapped(recognizer as! UITapGestureRecognizer)
    }
    @objc func handleLongPress(_ recognizer: AnyObject) {
        longPressed(recognizer as! UILongPressGestureRecognizer)
    }
}

enum Sel {
    static let increment = #selector(SelectorDemoViewController.incrementTapped)
    static let reset = #selector(SelectorDemoViewController.resetTapped(_:))
    static let enabled = #selector(SelectorDemoViewController.enabledChanged(_:))
    static let tap = #selector(SelectorDemoViewController.handleTap(_:))
    static let longPress = #selector(SelectorDemoViewController.handleLongPress(_:))
}
#else
/// Off Darwin: the same selector names, spelled portably.
enum Sel {
    static let increment = Selector.named("incrementTapped")
    static let reset = Selector.named("resetTapped:")
    static let enabled = Selector.named("enabledChanged:")
    static let tap = Selector.named("handleTap:")
    static let longPress = Selector.named("handleLongPress:")
}
#endif

// MARK: - The screen

public final class SelectorDemoViewController: UIViewController, SelectorDispatching {
    // The name -> method table. This is what replaces objc_msgSend; it is the
    // only boilerplate a selector-driven OpenUIKit app writes.
    static let actions: ActionTable<SelectorDemoViewController> = [
        .action("incrementTapped", SelectorDemoViewController.increment),
        .action("resetTapped:", SelectorDemoViewController.reset),
        .action("enabledChanged:", SelectorDemoViewController.enabledDidChange),
        .action("handleTap:", SelectorDemoViewController.tapped),
        .action("handleLongPress:", SelectorDemoViewController.longPressed),
    ]

    public func perform(_ selectorName: String, with sender: Any?) -> Bool {
        Self.actions.perform(selectorName, on: self, with: sender)
    }

    // MARK: State

    public private(set) var count = 0
    public private(set) var lastAction = "—"

    // MARK: Views

    let countLabel = UILabel()
    let statusLabel = UILabel()
    let incrementButton = UIButton(type: .system)
    let resetButton = UIButton(type: .system)
    let enabledSwitch = UISwitch()
    let panel = UIView()
    let panelLabel = UILabel()

    public override init() { super.init() }

    public override func viewDidLoad() {
        title = "Target-Action"
        view.backgroundColor = .systemGroupedBackground

        let margin: CGFloat = 20
        let width = view.bounds.width - 2 * margin
        var y: CGFloat = 24

        // Counter card ------------------------------------------------------
        let card = UIView(frame: CGRect(x: margin, y: y, width: width, height: 96))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.autoresizingMask = [.flexibleWidth]
        view.addSubview(card)

        countLabel.font = .systemFont(ofSize: 34, weight: .bold)
        countLabel.textColor = .label
        countLabel.textAlignment = .center
        countLabel.frame = CGRect(x: 0, y: 14, width: width, height: 41)
        countLabel.autoresizingMask = [.flexibleWidth]
        card.addSubview(countLabel)

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.frame = CGRect(x: 0, y: 58, width: width, height: 18)
        statusLabel.autoresizingMask = [.flexibleWidth]
        card.addSubview(statusLabel)
        y = card.frame.maxY + 22

        // Buttons -----------------------------------------------------------
        incrementButton.setTitle("Increment", for: .normal)
        incrementButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        incrementButton.backgroundColor = .secondarySystemGroupedBackground
        incrementButton.layer.cornerRadius = 12
        incrementButton.frame = CGRect(x: margin, y: y,
                                       width: (width - 12) / 2, height: 48)
        // Real UIKit, verbatim.
        incrementButton.addTarget(self, action: Sel.increment, for: .touchUpInside)
        view.addSubview(incrementButton)

        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        resetButton.backgroundColor = .secondarySystemGroupedBackground
        resetButton.layer.cornerRadius = 12
        resetButton.frame = CGRect(x: margin + (width - 12) / 2 + 12, y: y,
                                   width: (width - 12) / 2, height: 48)
        resetButton.addTarget(self, action: Sel.reset, for: .touchUpInside)
        view.addSubview(resetButton)
        y += 48 + 22

        // Switch row --------------------------------------------------------
        let row = UIView(frame: CGRect(x: margin, y: y, width: width, height: 52))
        row.backgroundColor = .secondarySystemGroupedBackground
        row.layer.cornerRadius = 12
        row.autoresizingMask = [.flexibleWidth]
        view.addSubview(row)

        let rowLabel = UILabel()
        rowLabel.text = "Counting Enabled"
        rowLabel.font = .systemFont(ofSize: 17)
        rowLabel.textColor = .label
        rowLabel.frame = CGRect(x: 16, y: 15, width: width - 100, height: 22)
        row.addSubview(rowLabel)

        enabledSwitch.setOn(true, animated: false)
        enabledSwitch.frame = CGRect(x: width - 16 - 63, y: 12, width: 63, height: 28)
        enabledSwitch.addTarget(self, action: Sel.enabled, for: .valueChanged)
        row.addSubview(enabledSwitch)
        y = row.frame.maxY + 22

        // Gesture panel -----------------------------------------------------
        panel.frame = CGRect(x: margin, y: y, width: width, height: 120)
        panel.backgroundColor = .secondarySystemGroupedBackground
        panel.layer.cornerRadius = 12
        panel.autoresizingMask = [.flexibleWidth]
        // UIKit's own recognizer construction.
        panel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: Sel.tap))
        let press = UILongPressGestureRecognizer()
        press.addTarget(self, action: Sel.longPress)
        panel.addGestureRecognizer(press)
        view.addSubview(panel)

        panelLabel.text = "Tap or long-press"
        panelLabel.font = .systemFont(ofSize: 15)
        panelLabel.textColor = .secondaryLabel
        panelLabel.textAlignment = .center
        panelLabel.numberOfLines = 0
        panelLabel.frame = CGRect(x: 12, y: 44, width: width - 24, height: 32)
        panelLabel.autoresizingMask = [.flexibleWidth]
        panel.addSubview(panelLabel)

        refresh()
    }

    // MARK: Actions (the implementations both platforms dispatch to)

    func increment() {
        guard enabledSwitch.isOn else {
            note("increment ignored (disabled)")
            return
        }
        count += 1
        note("incrementTapped")
    }

    func reset(_ sender: UIButton) {
        count = 0
        note("resetTapped: \(sender === resetButton ? "Reset" : "?")")
    }

    func enabledDidChange(_ sender: UISwitch) {
        note("enabledChanged: \(sender.isOn ? "on" : "off")")
    }

    func tapped(_ recognizer: UITapGestureRecognizer) {
        count += 1
        note("handleTap:")
        panelLabel.text = "Tapped"
    }

    func longPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        count += 10
        note("handleLongPress:")
        panelLabel.text = "Long-pressed"
    }

    func note(_ text: String) {
        lastAction = text
        refresh()
    }

    func refresh() {
        countLabel.text = "\(count)"
        statusLabel.text = "last action: \(lastAction)"
    }
}
