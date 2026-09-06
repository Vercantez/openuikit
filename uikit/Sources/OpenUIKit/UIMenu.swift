// UIMenuElement / UIAction / UICommand / UIKeyCommand / UIMenu.
// Owner: menus module (M13 "menus & actions" cluster, docs/APP_COMPAT.md #3
// — 252 uses: UIKeyCommand 81, UIAction 69, UIMenu 49).
//
// This file is the DATA MODEL and the DISPATCH. Nothing here draws; the
// platter that shows a menu on screen lives in UIContextMenu.swift, and its
// metrics are measured (Tools/oracle2/menuprobe).
//
// WHY THE MODEL MATTERS ON ITS OWN: `UIAction` is how modern code-based UIKit
// wires a button at all (`UIButton(primaryAction:)`, `button.menu = ...`), so
// an app that never shows a menu still fails to compile without it. And
// `UIKeyCommand` is pure behaviour — it has no pixels, only routing.
//
// KEY-COMMAND ROUTING (UIKit's, reproduced):
//
//   1. The host turns a physical key press into
//      `window.performKeyCommand(input:modifierFlags:)` (openhost does this
//      from SDL_KEYDOWN; a test calls it directly).
//   2. The window walks the RESPONDER CHAIN from the first responder — the
//      M12 chain in UIResponder.swift — asking each responder for its
//      `keyCommands`.
//   3. The FIRST command whose `input` and `modifierFlags` match wins.
//   4. Its action is performed: a closure-built command calls its handler; a
//      selector-built one is sent to the responder that vended it, and if
//      that responder has no such method, up the rest of the chain — the
//      portable equivalent of UIKit's nil-targeted action.
//
// Matching is case-INSENSITIVE for letter inputs (UIKit matches "n" whether
// or not shift is held, and a command that WANTS shift declares
// `.shift` in its modifierFlags — verified against UIKit's documented
// behaviour, not measured, since key handling has no pixels).

#if canImport(Foundation)
import class Foundation.NSObject
#endif

// MARK: - Modifier flags

public struct UIKeyModifierFlags: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    /// UIKit's raw values.
    public static let alphaShift = UIKeyModifierFlags(rawValue: 1 << 16)
    public static let shift = UIKeyModifierFlags(rawValue: 1 << 17)
    public static let control = UIKeyModifierFlags(rawValue: 1 << 18)
    public static let alternate = UIKeyModifierFlags(rawValue: 1 << 19)
    public static let command = UIKeyModifierFlags(rawValue: 1 << 20)
    public static let numericPad = UIKeyModifierFlags(rawValue: 1 << 21)
}

// MARK: - UIMenuElement

/// Base class of everything that can appear in a menu. UIKit's hierarchy:
///
///     UIMenuElement
///       ├── UIAction
///       ├── UICommand ── UIKeyCommand
///       ├── UIMenu
///       └── UIDeferredMenuElement
@preconcurrency @MainActor
open class UIMenuElement: NSObject {
    public internal(set) var title: String
    public internal(set) var subtitle: String?
    public internal(set) var image: UIImage?

    init(title: String, subtitle: String?, image: UIImage?) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        super.init()
    }

    /// UIKit's on/off/mixed check state. `.on` draws a checkmark in the
    /// leading column (measured: the title inset moves 28 → 40 pt).
    public enum State: Int, Sendable { case off = 0, on = 1, mixed = 2 }

    public struct Attributes: OptionSet, Hashable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let disabled = Attributes(rawValue: 1 << 0)
        public static let destructive = Attributes(rawValue: 1 << 1)
        public static let hidden = Attributes(rawValue: 1 << 2)
        /// Declared for source compatibility; the menu here always dismisses
        /// on selection (docs/KNOWN_GAPS.md).
        public static let keepsMenuPresented = Attributes(rawValue: 1 << 3)
    }

    /// Attributes / state live on the base class so the renderer can ask any
    /// element for them without downcasting; UIKit declares them on the
    /// concrete subclasses.
    public internal(set) var attributes: Attributes = []
    public internal(set) var state: State = .off

    /// The elements this one contributes to a displayed menu. A leaf
    /// contributes itself; a `.displayInline` menu contributes its children;
    /// a deferred element contributes whatever its provider produced.
    var displayElements: [UIMenuElement] {
        attributes.contains(.hidden) ? [] : [self]
    }
}

// MARK: - UIAction

@preconcurrency @MainActor
open class UIAction: UIMenuElement {
    public struct Identifier: Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.rawValue = value }
    }

    public let identifier: Identifier
    public var discoverabilityTitle: String?
    /// UIKit's `UIActionHandler`.
    public let handler: (UIAction) -> Void
    /// The object that presented the menu, set just before the handler runs
    /// (UIKit sets `sender` on the action).
    public internal(set) var sender: Any?

    public init(title: String = "",
                subtitle: String? = nil,
                image: UIImage? = nil,
                identifier: Identifier? = nil,
                discoverabilityTitle: String? = nil,
                attributes: UIMenuElement.Attributes = [],
                state: UIMenuElement.State = .off,
                handler: @escaping (UIAction) -> Void) {
        // UIKit derives an identifier from the title when none is given.
        self.identifier = identifier ?? Identifier(title)
        self.discoverabilityTitle = discoverabilityTitle
        self.handler = handler
        super.init(title: title, subtitle: subtitle, image: image)
        self.attributes = attributes
        self.state = state
    }

    /// UIKit's `performWithSender(_:target:)` — used by the menu platter and
    /// by `UIButton`'s primary action.
    public func performWithSender(_ sender: Any?, target: Any?) {
        guard !attributes.contains(.disabled) else { return }
        self.sender = sender
        handler(self)
    }
}

// MARK: - UICommand / UIKeyCommand

/// A selector-dispatched menu element. UIKit's `UICommand` is the parent of
/// `UIKeyCommand`; both send `action` through the responder chain.
@preconcurrency @MainActor
open class UICommand: UIMenuElement {
    public let action: Selector
    /// UIKit's arbitrary payload; passed to the action as the sender's
    /// `propertyList` when the target wants it.
    public let propertyList: Any?
    public var discoverabilityTitle: String?
    /// Closure form: when set, the command runs this instead of dispatching
    /// `action`. Not UIKit API — the portable escape hatch for code that
    /// cannot spell a selector (and the shape the tests use).
    let handler: ((UICommand) -> Void)?

    public init(title: String = "",
                image: UIImage? = nil,
                action: Selector,
                propertyList: Any? = nil,
                discoverabilityTitle: String? = nil,
                attributes: UIMenuElement.Attributes = [],
                state: UIMenuElement.State = .off) {
        self.action = action
        self.propertyList = propertyList
        self.discoverabilityTitle = discoverabilityTitle
        self.handler = nil
        super.init(title: title, subtitle: nil, image: image)
        self.attributes = attributes
        self.state = state
    }

    init(title: String, image: UIImage?, action: Selector,
         propertyList: Any?, discoverabilityTitle: String?,
         attributes: UIMenuElement.Attributes, state: UIMenuElement.State,
         handler: ((UICommand) -> Void)?) {
        self.action = action
        self.propertyList = propertyList
        self.discoverabilityTitle = discoverabilityTitle
        self.handler = handler
        super.init(title: title, subtitle: nil, image: image)
        self.attributes = attributes
        self.state = state
    }
}

@preconcurrency @MainActor
public final class UIKeyCommand: UICommand {
    /// The characters the key produces ("n", "\r", or one of the
    /// `UIKeyCommand.input*` constants). Optional like UIKit's
    /// `input` so Focus AutocompleteTextField.swift:101 `guard let input =
    /// sender.input` compiles. MEASURED Blockzilla 2026-09-06.
    public let input: String?
    public let modifierFlags: UIKeyModifierFlags
    /// UIKit iOS 15. Focus AutocompleteTextField.swift:94.
    public var wantsPriorityOverSystemBehavior = false

    public init(title: String = "",
                image: UIImage? = nil,
                action: Selector,
                input: String,
                modifierFlags: UIKeyModifierFlags = [],
                propertyList: Any? = nil,
                alternates: [UICommand] = [],
                discoverabilityTitle: String? = nil,
                attributes: UIMenuElement.Attributes = [],
                state: UIMenuElement.State = .off) {
        self.input = input
        self.modifierFlags = modifierFlags
        super.init(title: title, image: image, action: action,
                   propertyList: propertyList,
                   discoverabilityTitle: discoverabilityTitle,
                   attributes: attributes, state: state, handler: nil)
    }

    /// UIKit's older factory, and the shape most corpus code uses.
    public convenience init(input: String, modifierFlags: UIKeyModifierFlags,
                            action: Selector, discoverabilityTitle: String? = nil) {
        self.init(title: discoverabilityTitle ?? "", image: nil, action: action,
                  input: input, modifierFlags: modifierFlags,
                  discoverabilityTitle: discoverabilityTitle)
    }

    /// Closure form (not UIKit API — see `UICommand.handler`).
    public init(input: String, modifierFlags: UIKeyModifierFlags = [],
                title: String = "", handler: @escaping (UICommand) -> Void) {
        self.input = input
        self.modifierFlags = modifierFlags
        // Double parens: a runtime-built selector name, not a #selector.
        super.init(title: title, image: nil, action: Selector(("_openUIKitKeyCommandHandler")),
                   propertyList: nil, discoverabilityTitle: nil,
                   attributes: [], state: .off, handler: handler)
    }

    /// UIKit's special-key inputs. The values are UIKit's own (UTF-16
    /// private-use code points for the arrows, control characters for the
    /// rest), so a host that already produces them matches without mapping.
    public static let inputUpArrow = "\u{F700}"
    public static let inputDownArrow = "\u{F701}"
    public static let inputLeftArrow = "\u{F702}"
    public static let inputRightArrow = "\u{F703}"
    public static let inputEscape = "\u{1B}"
    public static let inputDelete = "\u{8}"
    public static let inputReturn = "\r"
    public static let inputTab = "\t"
    public static let inputPageUp = "\u{F72C}"
    public static let inputPageDown = "\u{F72D}"
    public static let inputHome = "\u{F729}"
    public static let inputEnd = "\u{F72B}"

    /// Whether this command answers a key press. Letter inputs compare
    /// case-insensitively (see the file header).
    public func matches(input other: String, modifierFlags flags: UIKeyModifierFlags) -> Bool {
        guard modifierFlags == flags else { return false }
        guard let input else { return false }
        if input == other { return true }
        return input.lowercased() == other.lowercased()
    }
}

// MARK: - UIMenu

@preconcurrency @MainActor
open class UIMenu: UIMenuElement {
    public struct Identifier: Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.rawValue = value }
        /// A few of UIKit's standard identifiers, for source compatibility.
        public static let root = Identifier("com.apple.menu.root")
        public static let application = Identifier("com.apple.menu.application")
        public static let file = Identifier("com.apple.menu.file")
        public static let edit = Identifier("com.apple.menu.edit")
        public static let view = Identifier("com.apple.menu.view")
        public static let window = Identifier("com.apple.menu.window")
        public static let help = Identifier("com.apple.menu.help")
    }

    public struct Options: OptionSet, Hashable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        /// Children are spliced into the PARENT menu as a separated section
        /// instead of opening a submenu (measured: a 21 pt gap between
        /// sections — see UIContextMenu.swift).
        public static let displayInline = Options(rawValue: 1 << 0)
        public static let destructive = Options(rawValue: 1 << 1)
        /// Declared for source compatibility; not modelled.
        public static let singleSelection = Options(rawValue: 1 << 5)
        public static let displayAsPalette = Options(rawValue: 1 << 7)
    }

    public let identifier: Identifier
    public let options: Options
    public private(set) var children: [UIMenuElement]

    public init(title: String = "",
                subtitle: String? = nil,
                image: UIImage? = nil,
                identifier: Identifier? = nil,
                options: Options = [],
                children: [UIMenuElement] = []) {
        self.identifier = identifier ?? Identifier(title)
        self.options = options
        self.children = children
        super.init(title: title, subtitle: subtitle, image: image)
        if options.contains(.destructive) { attributes.insert(.destructive) }
    }

    /// UIKit's immutable-update helper.
    public func replacingChildren(_ newChildren: [UIMenuElement]) -> UIMenu {
        UIMenu(title: title, subtitle: subtitle, image: image,
               identifier: identifier, options: options, children: newChildren)
    }

    override var displayElements: [UIMenuElement] {
        guard !attributes.contains(.hidden) else { return [] }
        // A .displayInline menu is not a row: its children ARE rows of the
        // parent, as one section.
        return options.contains(.displayInline) ? resolvedChildren : [self]
    }

    /// `children` with deferred elements resolved and hidden ones dropped —
    /// what the platter actually lays out.
    var resolvedChildren: [UIMenuElement] {
        children.flatMap { $0.displayElements }
    }

    /// The rows of this menu grouped into SECTIONS. A `.displayInline` child
    /// starts (and ends) a section; everything else accumulates into the
    /// current one.
    var sections: [[UIMenuElement]] {
        var out: [[UIMenuElement]] = []
        var current: [UIMenuElement] = []
        for child in children {
            if let sub = child as? UIMenu, sub.options.contains(.displayInline) {
                if !current.isEmpty { out.append(current); current = [] }
                let inlineRows = sub.resolvedChildren
                if !inlineRows.isEmpty { out.append(inlineRows) }
            } else {
                current.append(contentsOf: child.displayElements)
            }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }
}

// MARK: - UIDeferredMenuElement

/// UIKit builds these children when the menu is about to be shown.
///
/// HONEST LIMIT: UIKit's provider is asynchronous — it hands you a completion
/// block you may call later, and UIKit shows a spinner meanwhile. There is no
/// run loop here to come back to, so a provider that completes SYNCHRONOUSLY
/// works exactly like UIKit's and one that does not contributes nothing (no
/// spinner, no late splice). Recorded in docs/KNOWN_GAPS.md.
@preconcurrency @MainActor
public final class UIDeferredMenuElement: UIMenuElement {
    private let provider: (@escaping ([UIMenuElement]) -> Void) -> Void
    private var resolved: [UIMenuElement]?
    /// UIKit's `uncachedProvider` re-asks every time; the cached form asks once.
    private let caches: Bool

    public init(_ elementProvider: @escaping (@escaping ([UIMenuElement]) -> Void) -> Void) {
        self.provider = elementProvider
        self.caches = true
        super.init(title: "", subtitle: nil, image: nil)
    }

    public static func uncached(
        _ elementProvider: @escaping (@escaping ([UIMenuElement]) -> Void) -> Void
    ) -> UIDeferredMenuElement {
        let e = UIDeferredMenuElement(elementProvider, caches: false)
        return e
    }

    private init(_ elementProvider: @escaping (@escaping ([UIMenuElement]) -> Void) -> Void,
                 caches: Bool) {
        self.provider = elementProvider
        self.caches = caches
        super.init(title: "", subtitle: nil, image: nil)
    }

    override var displayElements: [UIMenuElement] {
        if caches, let resolved { return resolved }
        var out: [UIMenuElement] = []
        provider { elements in out = elements }
        if caches { resolved = out }
        return out.flatMap { $0.displayElements }
    }
}

// MARK: - Key-command routing through the responder chain

extension UIResponder {
    /// (`keyCommands` itself is declared in UIResponder.swift — an
    /// overridable property cannot live in an extension.)

    /// Find the first command in the chain matching a key press, and the
    /// responder that vended it.
    func _findKeyCommand(input: String, modifierFlags: UIKeyModifierFlags)
        -> (command: UIKeyCommand, responder: UIResponder)? {
        for responder in _responderChain {
            for c in responder.keyCommands ?? []
            where !c.attributes.contains(.disabled)
                && c.matches(input: input, modifierFlags: modifierFlags) {
                return (c, responder)
            }
        }
        return nil
    }

    /// Perform a command found on this chain. Closure commands run their
    /// handler; selector commands go to the vending responder first and then
    /// up the chain (UIKit's nil-target walk).
    @discardableResult
    func _perform(_ command: UICommand, from responder: UIResponder) -> Bool {
        if let handler = command.handler {
            handler(command)
            return true
        }
        for r in responder._responderChain {
            if SelectorDispatch.trySend(command.action, to: r, sender: command) {
                return true
            }
        }
        // Nothing in the chain implements it — report it the same way a
        // missed control action is reported (openhost/tests install a hook).
        SelectorDispatch.onUnresolved?(responder, command.action.actionName)
        return false
    }
}

extension UIWindow {
    /// HOST ENTRY POINT for hardware keys. Returns true when a key command
    /// consumed the press — a host that gets false should fall through to
    /// text input (`sendText`) exactly like UIKit does.
    ///
    /// The walk starts at the first responder. With nothing focused it
    /// starts at the ROOT VIEW CONTROLLER instead of at the window, so an
    /// app's global commands work before anything takes focus — the same
    /// fallback `UIApplication.sendAction(_:to:from:for:)` already uses for
    /// nil-targeted actions, and the behaviour apps expect from UIKit (whose
    /// private default first responder is the root controller).
    @discardableResult
    public func performKeyCommand(input: String,
                                  modifierFlags: UIKeyModifierFlags = []) -> Bool {
        let start: UIResponder = firstResponder ?? rootViewController ?? self
        guard let (command, responder) = start._findKeyCommand(input: input,
                                                               modifierFlags: modifierFlags)
        else { return false }
        return responder._perform(command, from: responder)
    }
}
