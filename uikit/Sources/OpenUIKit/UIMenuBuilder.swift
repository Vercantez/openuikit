// UIMenuSystem / UIMenuBuilder — the main-menu build that firefox-ios drives
// from `AppDelegate.buildMenu(with:)` (Client/Helpers/MenuBuilderHelper.swift:
// insertChild × 4, replace, remove, insertSibling × 3). Owner: menus module.
//
// Every rule in this file is MEASURED on iPhone 16 and iPad A16, iOS 26.1
// (Tools/oracle2/firefoxlastrowsprobe, transcripts ios-26.1-iphone16.json and
// ios-26.1-ipad-a16.json; the README lists each row):
//
//   WHEN the main system builds: on the FIRST hardware key event, walking
//   `UIApplication.shared` then its delegate (never the window, a view or a
//   controller). `setNeedsRebuild()` builds nothing itself and nothing within
//   the following 8 s; the build happens at the next consumer. A first
//   responder change and `setNeedsRevalidate()` trigger nothing. (One of
//   eight iPhone launches built at launch, 10 ms after didFinishLaunching
//   returned, before didBecomeActive; the condition was not isolated and the
//   other seven plus both iPad launches built lazily — the lazy rule is
//   what the port does.)
//
//   WHAT the default builder carries: root → application, file, edit,
//   format, view, window, help, with the children `_MenuNode.defaultMain`
//   spells out (identifiers, titles, inline flags and the key commands with
//   their selectors). Nil for `.autoFill .learn .lookup .openRecent .replace
//   .share`. Identical on iPhone and iPad.
//
//   WHAT the mutations do: `insertChild(atStartOf:)` puts the menu at index
//   0 of the parent's children; `atEndOf` appends; `insertSibling(after:)`
//   places it right after the sibling among the ROOT's (or any parent's)
//   children; `replace(menu:with:)` swaps the node in place, after which the
//   replaced identifier answers nil and the replacement is found by ITS
//   identifier; `remove(menu:)` deletes the node (`.font` gone from Format,
//   `.file` gone from the root). Every operation on an identifier that is
//   not in the tree is a silent no-op — remove, replace, insertSibling,
//   insertChild — and duplicate identifiers or the same menu object inserted
//   twice are accepted. `menu(for:)` returns a COPY (never the inserted
//   object), `command(for:)` finds commands by selector anywhere in the tree
//   (including UIKit's own `cut:`), `action(for:)` finds a UIAction by
//   identifier.
//
//   HOW the built menu acts: a key press no responder answers is matched
//   against the tree's key commands in order (alternates included) and
//   performed from the start responder — UIMenu.swift step 5.
//
// NOT MODELLED: the context system's default tree (the transcript's
// `builder.context.1.root` lists eight groups of private edit actions; this
// port's edit menu passes no system actions, so the context builder starts
// empty), `replaceChildren(ofMenu:from:)` beyond the obvious, and any
// drawing — no OpenUIKit host has a menu bar or a shortcut HUD.

#if canImport(Foundation)
import Foundation
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

// MARK: - UIMenuSystem

/// UIKit's command system to build or rebuild. `main` and `context` are the
/// two singletons (`UIMainMenuSystem` / `UIContextMenuSystem` on iOS;
/// `main === main`, `main !== context`).
@preconcurrency @MainActor
open class UIMenuSystem: NSObject {
    enum Kind { case main, context }
    let kind: Kind

    public static let main = UIMenuSystem(kind: .main)
    public static let context = UIMenuSystem(kind: .context)

    private init(kind: Kind) {
        self.kind = kind
        super.init()
    }

    /// Dirty flag. The first build is always pending.
    private(set) var _needsRebuild = true
    /// Store-only: MEASURED no `validate(_:)` traffic from it.
    private(set) var _needsRevalidate = false
    /// The last build's tree, or nil before the first build.
    private(set) var _builtRoot: _MenuNode?
    /// How many times this system has been built (tests read it).
    private(set) var _buildCount = 0

    /// Trigger a rebuild of this system at a suitable time. MEASURED: nothing
    /// happens inside the call; the next consumer builds.
    open func setNeedsRebuild() { _needsRebuild = true }

    /// Trigger a revalidate at a suitable time. MEASURED: no observable
    /// effect on iPhone or iPad; kept as state.
    open func setNeedsRevalidate() { _needsRevalidate = true }

    /// Build now, asking every responder from `start` up the chain — the
    /// walk UIKit does itself (a responder that skips `super` does not stop
    /// it). Main: `UIApplication.shared` → delegate. Context: the
    /// interaction's view → … → delegate.
    func _rebuild(startingAt start: UIResponder) {
        let builder = _MenuTreeBuilder(system: self,
                                       root: kind == .main ? _MenuNode.defaultMain() : _MenuNode.emptyRoot())
        for responder in start._responderChain {
            responder.buildMenu(with: builder)
        }
        _builtRoot = builder.root
        _needsRebuild = false
        _needsRevalidate = false
        _buildCount += 1
    }

    /// The main system's lazy build (UIWindow.performKeyCommand calls it).
    func _buildMainIfNeeded() {
        guard kind == .main, _needsRebuild else { return }
        _rebuild(startingAt: UIApplication.shared)
    }

    /// The first key command in the built main menu answering a press,
    /// resolved through alternates (`UIKeyCommand._match`). Tree order.
    func _mainMenuKeyCommand(input: String, modifierFlags: UIKeyModifierFlags) -> UIKeyCommand? {
        guard kind == .main, let root = _builtRoot else { return nil }
        for command in root.allKeyCommands() where !command.attributes.contains(.disabled) {
            if let match = command._match(input: input, modifierFlags: modifierFlags) {
                return match
            }
        }
        return nil
    }

    /// HOST API (not UIKit): the current menu of this system, built on demand
    /// for the main system. A desktop host with a menu bar reads it here.
    public func _currentMenu() -> UIMenu? {
        _buildMainIfNeeded()
        return _builtRoot?.materialize()
    }

    /// Back to the never-built state (tests share the singleton).
    func _resetForTesting() {
        _needsRebuild = true
        _needsRevalidate = false
        _builtRoot = nil
        _buildCount = 0
    }
}

// MARK: - UIMenuBuilder

/// UIKit's `UIMenuBuilder` — access and mutation of a menu hierarchy while
/// a system is being built.
@preconcurrency @MainActor
public protocol UIMenuBuilder: AnyObject {
    /// Which system is being built (`UIMenuSystem.main` / `.context`).
    var system: UIMenuSystem { get }
    func menu(for identifier: UIMenu.Identifier) -> UIMenu?
    func action(for identifier: UIAction.Identifier) -> UIAction?
    func command(for action: Selector, propertyList: Any?) -> UICommand?
    func replace(menu replacedIdentifier: UIMenu.Identifier, with replacementMenu: UIMenu)
    func replaceChildren(ofMenu parentIdentifier: UIMenu.Identifier,
                         from childrenBlock: ([UIMenuElement]) -> [UIMenuElement])
    func insertSibling(_ siblingMenu: UIMenu, beforeMenu siblingIdentifier: UIMenu.Identifier)
    func insertSibling(_ siblingMenu: UIMenu, afterMenu siblingIdentifier: UIMenu.Identifier)
    func insertChild(_ childMenu: UIMenu, atStartOfMenu parentIdentifier: UIMenu.Identifier)
    func insertChild(_ childMenu: UIMenu, atEndOfMenu parentIdentifier: UIMenu.Identifier)
    func remove(menu removedIdentifier: UIMenu.Identifier)
}

extension UIMenuBuilder {
    /// UIKit's Swift refinement defaults `propertyList` to nil.
    public func command(for action: Selector) -> UICommand? {
        command(for: action, propertyList: nil)
    }
}

// MARK: - The tree

/// A mutable menu node: the builder's private copy of a `UIMenu`. UIKit's
/// `UIMenu.children` is immutable, and MEASURED `menu(for:)` never returns
/// the inserted object, so the builder keeps its own tree and materializes
/// fresh `UIMenu`s on demand.
@preconcurrency @MainActor
final class _MenuNode {
    var title: String
    var subtitle: String?
    var image: UIImage?
    var identifier: UIMenu.Identifier
    var options: UIMenu.Options
    var attributes: UIMenuElement.Attributes
    var state: UIMenuElement.State
    var children: [Child]

    enum Child {
        case menu(_MenuNode)
        case element(UIMenuElement)
    }

    init(title: String = "", subtitle: String? = nil, image: UIImage? = nil,
         identifier: UIMenu.Identifier, options: UIMenu.Options = [],
         attributes: UIMenuElement.Attributes = [], state: UIMenuElement.State = .off,
         children: [Child] = []) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.identifier = identifier
        self.options = options
        self.attributes = attributes
        self.state = state
        self.children = children
    }

    /// Deep copy of a UIMenu into node form (nested menus become nodes so
    /// they are addressable by identifier; leaves are kept by reference).
    convenience init(copying menu: UIMenu) {
        self.init(title: menu.title, subtitle: menu.subtitle, image: menu.image,
                  identifier: menu.identifier, options: menu.options,
                  attributes: menu.attributes, state: menu.state,
                  children: menu.children.map(Child.wrap))
    }

    /// A fresh UIMenu for this subtree.
    func materialize() -> UIMenu {
        let menu = UIMenu(title: title, subtitle: subtitle, image: image,
                          identifier: identifier, options: options,
                          children: children.map { $0.materialize() })
        menu.attributes = attributes
        menu.state = state
        return menu
    }

    /// Depth-first search for a menu node by identifier, with its parent
    /// and index in the parent's children (nil parent for the root).
    func find(_ id: UIMenu.Identifier) -> (parent: _MenuNode?, index: Int, node: _MenuNode)? {
        if identifier == id { return (nil, 0, self) }
        for (i, child) in children.enumerated() {
            guard case .menu(let node) = child else { continue }
            if node.identifier == id { return (self, i, node) }
            if let hit = node.find(id) { return hit }
        }
        return nil
    }

    /// Every leaf element in tree order (menus are descended, not listed).
    func allLeaves() -> [UIMenuElement] {
        children.flatMap { child -> [UIMenuElement] in
            switch child {
            case .menu(let node): return node.allLeaves()
            case .element(let element): return [element]
            }
        }
    }

    func allKeyCommands() -> [UIKeyCommand] {
        allLeaves().compactMap { $0 as? UIKeyCommand }
    }

    static func emptyRoot() -> _MenuNode {
        _MenuNode(identifier: .root)
    }
}

extension _MenuNode.Child {
    static func wrap(_ element: UIMenuElement) -> _MenuNode.Child {
        if let menu = element as? UIMenu { return .menu(_MenuNode(copying: menu)) }
        return .element(element)
    }

    func materialize() -> UIMenuElement {
        switch self {
        case .menu(let node): return node.materialize()
        case .element(let element): return element
        }
    }
}

// MARK: - The builder

@preconcurrency @MainActor
final class _MenuTreeBuilder: UIMenuBuilder {
    public let system: UIMenuSystem
    let root: _MenuNode

    init(system: UIMenuSystem, root: _MenuNode) {
        self.system = system
        self.root = root
    }

    func menu(for identifier: UIMenu.Identifier) -> UIMenu? {
        root.find(identifier)?.node.materialize()
    }

    func action(for identifier: UIAction.Identifier) -> UIAction? {
        root.allLeaves().lazy.compactMap { $0 as? UIAction }.first { $0.identifier == identifier }
    }

    func command(for action: Selector, propertyList: Any?) -> UICommand? {
        root.allLeaves().lazy.compactMap { $0 as? UICommand }.first { command in
            guard command.action.actionName == action.actionName else { return false }
            return _propertyListsMatch(command.propertyList, propertyList)
        }
    }

    func replace(menu replacedIdentifier: UIMenu.Identifier, with replacementMenu: UIMenu) {
        guard let hit = root.find(replacedIdentifier), let parent = hit.parent else { return }
        parent.children[hit.index] = .menu(_MenuNode(copying: replacementMenu))
    }

    func replaceChildren(ofMenu parentIdentifier: UIMenu.Identifier,
                         from childrenBlock: ([UIMenuElement]) -> [UIMenuElement]) {
        guard let hit = root.find(parentIdentifier) else { return }
        let current = hit.node.children.map { $0.materialize() }
        hit.node.children = childrenBlock(current).map(_MenuNode.Child.wrap)
    }

    func insertSibling(_ siblingMenu: UIMenu, beforeMenu siblingIdentifier: UIMenu.Identifier) {
        guard let hit = root.find(siblingIdentifier), let parent = hit.parent else { return }
        parent.children.insert(.menu(_MenuNode(copying: siblingMenu)), at: hit.index)
    }

    func insertSibling(_ siblingMenu: UIMenu, afterMenu siblingIdentifier: UIMenu.Identifier) {
        guard let hit = root.find(siblingIdentifier), let parent = hit.parent else { return }
        parent.children.insert(.menu(_MenuNode(copying: siblingMenu)), at: hit.index + 1)
    }

    func insertChild(_ childMenu: UIMenu, atStartOfMenu parentIdentifier: UIMenu.Identifier) {
        guard let hit = root.find(parentIdentifier) else { return }
        hit.node.children.insert(.menu(_MenuNode(copying: childMenu)), at: 0)
    }

    func insertChild(_ childMenu: UIMenu, atEndOfMenu parentIdentifier: UIMenu.Identifier) {
        guard let hit = root.find(parentIdentifier) else { return }
        hit.node.children.append(.menu(_MenuNode(copying: childMenu)))
    }

    func remove(menu removedIdentifier: UIMenu.Identifier) {
        guard let hit = root.find(removedIdentifier), let parent = hit.parent else { return }
        parent.children.remove(at: hit.index)
    }

    /// UIKit distinguishes commands with the same selector by property list;
    /// with no plist on either side they match. Beyond `nil`/`nil` and two
    /// hashable values, compare by description (the port has no NSObject
    /// `isEqual` bridge for arbitrary plists).
    private func _propertyListsMatch(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (nil, _), (_, nil): return false
        case (let x as AnyHashable, let y as AnyHashable): return x == y
        case (let x?, let y?): return String(describing: x) == String(describing: y)
        }
    }
}

// MARK: - The default main menu (MEASURED)

extension _MenuNode {
    /// The application menu's title. MEASURED: the bundle name
    /// (`FirefoxLastRowsProbe`); the Preferences item reads
    /// "<name> Settings…".
    static var applicationName: String {
        #if canImport(Foundation)
        let info = Bundle.main.infoDictionary ?? [:]
        if let s = info["CFBundleDisplayName"] as? String, !s.isEmpty { return s }
        if let s = info["CFBundleName"] as? String, !s.isEmpty { return s }
        return ProcessInfo.processInfo.processName
        #else
        return ""
        #endif
    }

    private static func key(_ title: String, _ selector: String, _ input: String,
                            _ flags: UIKeyModifierFlags) -> Child {
        .element(UIKeyCommand(title: title, action: Selector.named(selector),
                              input: input, modifierFlags: flags))
    }

    private static func cmd(_ title: String, _ selector: String,
                            attributes: UIMenuElement.Attributes = []) -> Child {
        .element(UICommand(title: title, action: Selector.named(selector), attributes: attributes))
    }

    private static func inline(_ id: UIMenu.Identifier, _ title: String = "",
                               _ children: [Child] = []) -> Child {
        .menu(_MenuNode(title: title, identifier: id, options: .displayInline, children: children))
    }

    private static func submenu(_ id: UIMenu.Identifier, _ title: String,
                                _ children: [Child] = []) -> Child {
        .menu(_MenuNode(title: title, identifier: id, children: children))
    }

    /// `builder.main.defaults.root` of the transcript, node for node. The
    /// modifier sums: 1048576 = ⌘, 1179648 = ⌘⇧, 1310720 = ⌘⌃, 1572864 = ⌘⌥,
    /// 1703936 = ⌘⌥⇧.
    static func defaultMain() -> _MenuNode {
        let name = applicationName
        let application = submenu(.application, name, [
            inline(.about),
            inline(.preferences, "", [key(name + " Settings…", "orderFrontPreferencesPanel:", ",", .command)]),
            submenu(.services, "Services"),
            inline(.hide),
            inline(.quit),
        ])
        let file = submenu(.file, "File", [
            inline(.newItem),
            inline(.open),
            inline(.close, "", [key("Close", "performClose:", "w", .command)]),
            inline(.document),
            inline(.print),
        ])
        let edit = submenu(.edit, "Edit", [
            inline(.undoRedo, "", [key("Undo", "undo:", "z", .command),
                                   key("Redo", "redo:", "z", [.command, .shift])]),
            inline(.standardEdit, "", [key("Cut", "cut:", "x", .command),
                                       key("Copy", "copy:", "c", .command),
                                       key("Paste", "paste:", "v", .command),
                                       key("Paste and Match Style", "pasteAndMatchStyle:", "v", [.command, .alternate, .shift]),
                                       cmd("Delete", "delete:", attributes: .destructive),
                                       key("Select All", "selectAll:", "a", .command)]),
            submenu(.find, "Find", [
                inline(.findPanel, "", [key("Find", "find:", "f", .command),
                                        key("Find & Replace", "findAndReplace:", "f", [.command, .alternate]),
                                        key("Find Next", "findNext:", "g", .command),
                                        key("Find Previous", "findPrevious:", "g", [.command, .shift])]),
                key("Use Selection for Find", "useSelectionForFind:", "e", .command),
            ]),
            submenu(.spelling, "Spelling and Grammar", [inline(.spellingPanel), inline(.spellingOptions)]),
            submenu(.substitutions, "Substitutions", [inline(.substitutionsPanel), inline(.substitutionOptions)]),
            submenu(.transformations, "Transformations"),
            submenu(.speech, "Speech"),
        ])
        let format = submenu(.format, "Format", [
            submenu(.font, "Font", [
                inline(.textStyle, "Text Style", [key("Bold", "toggleBoldface:", "b", .command),
                                                  key("Italic", "toggleItalics:", "i", .command),
                                                  key("Underline", "toggleUnderline:", "u", .command)]),
                inline(.textSize, "", [key("Bigger", "increaseSize:", "+", .command),
                                       key("Smaller", "decreaseSize:", "-", .command)]),
                inline(.textColor),
                inline(.textStylePasteboard),
            ]),
            submenu(.text, "Text", [
                inline(.alignment, "", [key("Align Left", "alignLeft:", "{", .command),
                                        key("Center", "alignCenter:", "|", .command),
                                        cmd("Justify", "alignJustified:"),
                                        key("Align Right", "alignRight:", "}", .command)]),
                submenu(.writingDirection, "Writing Direction", [cmd("Default", "makeTextWritingDirectionNatural:"),
                                                                 cmd("Right to Left", "makeTextWritingDirectionRightToLeft:"),
                                                                 cmd("Left to Right", "makeTextWritingDirectionLeftToRight:")]),
            ]),
        ])
        let view = submenu(.view, "View", [
            inline(.toolbar, "", [cmd("Customize Toolbar…", "runToolbarCustomizationPalette:")]),
            inline(.sidebar, "", [key("Show Sidebar", "toggleSidebar:", "s", [.command, .control])]),
            inline(.fullscreen),
        ])
        let window = submenu(.window, "Window", [inline(.minimizeAndZoom), inline(.bringAllToFront)])
        let help = submenu(.help, "Help", [key("", "showHelp:", "?", .command)])
        return _MenuNode(identifier: .root, children: [application, file, edit, format, view, window, help])
    }
}
