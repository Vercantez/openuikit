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
//   3. The FIRST command whose `input` and `modifierFlags` match wins — or
//      whose ALTERNATE does (`UICommandAlternate`: the command's flags plus
//      the alternate's equal the press; MEASURED, see `UIKeyCommand._match`).
//   4. The start responder is sent `validate(_:)` with the resolved command,
//      then its action is performed: a closure-built command calls its
//      handler; a selector-built one is sent to the responder that vended
//      it, and if that responder has no such method, up the rest of the
//      chain — the portable equivalent of UIKit's nil-targeted action.
//   5. With no responder command, the MAIN MENU SYSTEM (UIMenuBuilder.swift:
//      built on the first key event from `UIResponder.buildMenu(with:)`) is
//      searched in tree order, and its command is performed from the start
//      responder the same way. MEASURED on iPhone 16 and iPad A16.
//
// Matching is case-INSENSITIVE for letter inputs (UIKit matches "n" whether
// or not shift is held, and a command that WANTS shift declares
// `.shift` in its modifierFlags — verified against UIKit's documented
// behaviour, not measured, since key handling has no pixels).

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
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

// MARK: - UICommandAlternate

/// An alternate action a command takes when extra modifier keys are held —
/// firefox-ios: `UIKeyCommand("t", .command, alternates: [UICommandAlternate(
/// "New Private Tab", newPrivateTabKeyCommand, .shift)])`, so Cmd-Shift-T
/// opens a private tab.
///
/// MEASURED (Tools/oracle2/firefoxlastrowsprobe `model.alternate`, iPhone
/// 16 + iPad A16, iOS 26.1): plain NSObject subclass; two alternates are
/// EQUAL (and hash equal) iff their `modifierFlags` are equal — title and
/// action do not take part; `copy()` returns self; a command's `alternates`
/// hands back the very objects it was given.
@preconcurrency @MainActor
open class UICommandAlternate: NSObject {
    public let title: String
    public let action: Selector
    public let modifierFlags: UIKeyModifierFlags

    public init(title: String, action: Selector, modifierFlags: UIKeyModifierFlags) {
        self.title = title
        self.action = action
        self.modifierFlags = modifierFlags
        super.init()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UICommandAlternate else { return false }
        return other.modifierFlags == modifierFlags
    }

    open override var hash: Int { modifierFlags.rawValue }
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
    /// Alternates that differ in modifier flags (UIKit's `alternates`).
    /// MEASURED: `[]` when none were given; the same objects otherwise.
    public let alternates: [UICommandAlternate]
    /// Closure form: when set, the command runs this instead of dispatching
    /// `action`. Not UIKit API — the portable escape hatch for code that
    /// cannot spell a selector (and the shape the tests use).
    let handler: ((UICommand) -> Void)?

    public init(title: String = "",
                image: UIImage? = nil,
                action: Selector,
                propertyList: Any? = nil,
                alternates: [UICommandAlternate] = [],
                discoverabilityTitle: String? = nil,
                attributes: UIMenuElement.Attributes = [],
                state: UIMenuElement.State = .off) {
        self.action = action
        self.propertyList = propertyList
        self.alternates = alternates
        self.discoverabilityTitle = discoverabilityTitle
        self.handler = nil
        super.init(title: title, subtitle: nil, image: image)
        self.attributes = attributes
        self.state = state
    }

    init(title: String, image: UIImage?, action: Selector,
         propertyList: Any?, alternates: [UICommandAlternate] = [],
         discoverabilityTitle: String?,
         attributes: UIMenuElement.Attributes, state: UIMenuElement.State,
         handler: ((UICommand) -> Void)?) {
        self.action = action
        self.propertyList = propertyList
        self.alternates = alternates
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
                alternates: [UICommandAlternate] = [],
                discoverabilityTitle: String? = nil,
                attributes: UIMenuElement.Attributes = [],
                state: UIMenuElement.State = .off) {
        self.input = input
        self.modifierFlags = modifierFlags
        super.init(title: title, image: image, action: action,
                   propertyList: propertyList, alternates: alternates,
                   discoverabilityTitle: discoverabilityTitle,
                   attributes: attributes, state: state, handler: nil)
    }

    /// UIKit's resolution of ONE press against this command. MEASURED
    /// (firefoxlastrowsprobe, phases A/B/C, iPhone 16 + iPad A16):
    ///
    ///   - the command's own flags → the command itself is the sender;
    ///   - otherwise the first alternate whose flags UNIONED with the
    ///     command's equal the pressed flags → the alternate's action fires,
    ///     and the sender is a NEW `UIKeyCommand` carrying the alternate's
    ///     title and action, this command's input, the pressed flags and no
    ///     alternates (`title = "Alt Shift"; input j; modifierFlags 1179648;
    ///     alternates 0` for a Cmd-J command with a `.shift` alternate);
    ///   - extra modifiers no alternate declares (Cmd-Ctrl-J, Cmd-Shift-Alt-J
    ///     with only `.shift` and `.alternate` alternates) match nothing.
    func _match(input other: String, modifierFlags flags: UIKeyModifierFlags) -> UIKeyCommand? {
        guard let input, input == other || input.lowercased() == other.lowercased()
        else { return nil }
        if modifierFlags == flags { return self }
        for alternate in alternates where modifierFlags.union(alternate.modifierFlags) == flags {
            return UIKeyCommand(title: alternate.title, image: image, action: alternate.action,
                                input: input, modifierFlags: flags, propertyList: propertyList,
                                attributes: attributes, state: state)
        }
        return nil
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
        /// UIKit's standard identifiers. Every raw string is MEASURED
        /// (Tools/oracle2/firefoxlastrowsprobe `identifier.raw`, iOS 26.1):
        /// note `newScene` == `newItem` and `speech` under `com.apple.command`.
        public static let root = Identifier("com.apple.menu.root")
        public static let application = Identifier("com.apple.menu.application")
        public static let file = Identifier("com.apple.menu.file")
        public static let edit = Identifier("com.apple.menu.edit")
        public static let view = Identifier("com.apple.menu.view")
        public static let window = Identifier("com.apple.menu.window")
        public static let help = Identifier("com.apple.menu.help")
        public static let about = Identifier("com.apple.menu.about")
        public static let preferences = Identifier("com.apple.menu.preferences")
        public static let services = Identifier("com.apple.menu.services")
        public static let hide = Identifier("com.apple.menu.hide")
        public static let quit = Identifier("com.apple.menu.quit")
        public static let newItem = Identifier("com.apple.menu.new-item")
        public static let newScene = Identifier("com.apple.menu.new-item")
        public static let open = Identifier("com.apple.menu.open")
        public static let openRecent = Identifier("com.apple.menu.open-recent")
        public static let close = Identifier("com.apple.menu.close")
        public static let print = Identifier("com.apple.menu.print")
        public static let document = Identifier("com.apple.menu.document")
        public static let undoRedo = Identifier("com.apple.menu.undo-redo")
        public static let standardEdit = Identifier("com.apple.menu.standard-edit")
        public static let find = Identifier("com.apple.menu.find")
        public static let findPanel = Identifier("com.apple.menu.find-panel")
        public static let replace = Identifier("com.apple.menu.replace")
        public static let share = Identifier("com.apple.menu.share")
        public static let textStyle = Identifier("com.apple.menu.text-style")
        public static let spelling = Identifier("com.apple.menu.spelling")
        public static let spellingPanel = Identifier("com.apple.menu.spelling-panel")
        public static let spellingOptions = Identifier("com.apple.menu.spelling-options")
        public static let substitutions = Identifier("com.apple.menu.substitutions")
        public static let substitutionsPanel = Identifier("com.apple.menu.substitutions-panel")
        public static let substitutionOptions = Identifier("com.apple.menu.substitution-options")
        public static let transformations = Identifier("com.apple.menu.transformations")
        public static let speech = Identifier("com.apple.command.speech")
        public static let lookup = Identifier("com.apple.menu.lookup")
        public static let learn = Identifier("com.apple.menu.learn")
        public static let format = Identifier("com.apple.menu.format")
        public static let autoFill = Identifier("com.apple.menu.autofill")
        public static let font = Identifier("com.apple.menu.font")
        public static let textSize = Identifier("com.apple.menu.text-size")
        public static let textColor = Identifier("com.apple.menu.text-color")
        public static let textStylePasteboard = Identifier("com.apple.menu.text-style-pasteboard")
        public static let text = Identifier("com.apple.menu.text")
        public static let writingDirection = Identifier("com.apple.menu.writing-direction")
        public static let alignment = Identifier("com.apple.menu.alignment")
        public static let toolbar = Identifier("com.apple.menu.toolbar")
        public static let sidebar = Identifier("com.apple.menu.sidebar")
        public static let fullscreen = Identifier("com.apple.menu.fullscreen")
        public static let minimizeAndZoom = Identifier("com.apple.menu.minimize-and-zoom")
        public static let bringAllToFront = Identifier("com.apple.menu.bring-all-to-front")

        /// MEASURED: a menu built without an identifier gets
        /// `com.apple.menu.dynamic.<UUID>`, never its title. The suffix here
        /// is a process counter rather than a UUID — unique is what code can
        /// observe (firefox's `insertSibling(_:afterMenu:)` chain relies on
        /// its OWN identifiers being found, and on auto ones not colliding).
        static var _dynamicCounter = 0
        static func _dynamic() -> Identifier {
            _dynamicCounter += 1
            return Identifier("com.apple.menu.dynamic." + String(_dynamicCounter))
        }
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
        self.identifier = identifier ?? Identifier._dynamic()
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
    /// responder that vended it. The command returned is the SENDER UIKit
    /// would pass: the vended command itself, or (for a press carrying an
    /// alternate's modifiers) the synthesized alternate — see
    /// `UIKeyCommand._match`. MEASURED order: `keyCommands` order within a
    /// responder decides between a command's alternate and a later command
    /// that matches the same press directly (phases B/C).
    func _findKeyCommand(input: String, modifierFlags: UIKeyModifierFlags)
        -> (command: UIKeyCommand, responder: UIResponder)? {
        for responder in _responderChain {
            for c in responder.keyCommands ?? [] where !c.attributes.contains(.disabled) {
                if let match = c._match(input: input, modifierFlags: modifierFlags) {
                    return (match, responder)
                }
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
        // MEASURED (firefoxlastrowsprobe, 7 of 8 launches on iPhone 16 and
        // both on iPad A16): the main menu system is built by the FIRST
        // hardware key event, not at launch — `buildMenu(with:)` reached the
        // application and then its delegate 5.9 s in, inside the first press.
        UIMenuSystem.main._buildMainIfNeeded()
        let start: UIResponder = firstResponder ?? rootViewController ?? self
        if let (command, responder) = start._findKeyCommand(input: input,
                                                            modifierFlags: modifierFlags) {
            // MEASURED: `validate(_:)` is sent once, to the responder the walk
            // starts from, with the resolved command, right before the action.
            start.validate(command)
            return responder._perform(command, from: responder)
        }
        // MEASURED: a shortcut that lives only in the built main menu (firefox
        // never returns its commands from `keyCommands`) still fires — Cmd-T
        // → newTab, Cmd-Shift-T → the .shift alternate, Cmd-W → firefox's
        // Close Tab inserted at the START of File ahead of UIKit's own Close.
        // A responder's command beats a menu command for the same press
        // (Cmd-J: `Base` won over Tools > Downloads).
        guard let command = UIMenuSystem.main._mainMenuKeyCommand(input: input,
                                                                  modifierFlags: modifierFlags)
        else { return false }
        start.validate(command)
        return start._perform(command, from: start)
    }
}
