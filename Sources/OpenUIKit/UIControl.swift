// UIControl. Owner: controls/event module (M7).
//
// UIKit's control base: state (enabled/highlighted/selected), target-action
// dispatch, and touch tracking (beginTracking/continueTracking/endTracking/
// cancelTracking) driven by the UIResponder touch entry points UIWindow
// delivers to the hit-test view.
//
// Two registration forms, both UIKit-shaped:
//
//   addTarget(for: .touchUpInside) { control, event in ... }   // closures
//   addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
//
// The closure form returns a token for removal and is the better Swift API.
// The selector form is real UIKit's, and reaches the method through the
// target's `SelectorDispatching` table (see UISelector.swift) rather than
// through `objc_msgSend`. Targets are held **weakly**, as in UIKit.
//
// `sendActions(for:)` invokes every registration whose event set intersects
// the sent events (UIKit semantics).

@preconcurrency @MainActor
open class UIControl: UIView {
    // MARK: State

    /// UIControl.State option set (UIKit raw values).
    public struct State: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let normal = State([])
        public static let highlighted = State(rawValue: 1 << 0)
        public static let disabled = State(rawValue: 1 << 1)
        public static let selected = State(rawValue: 1 << 2)
    }

    /// UIControl.Event option set (UIKit raw values).
    public struct Event: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let touchDown = Event(rawValue: 1 << 0)
        public static let touchDownRepeat = Event(rawValue: 1 << 1)
        public static let touchDragInside = Event(rawValue: 1 << 2)
        public static let touchDragOutside = Event(rawValue: 1 << 3)
        public static let touchDragEnter = Event(rawValue: 1 << 4)
        public static let touchDragExit = Event(rawValue: 1 << 5)
        public static let touchUpInside = Event(rawValue: 1 << 6)
        public static let touchUpOutside = Event(rawValue: 1 << 7)
        public static let touchCancel = Event(rawValue: 1 << 8)
        public static let valueChanged = Event(rawValue: 1 << 12)
        public static let primaryActionTriggered = Event(rawValue: 1 << 13)
        // Text-field editing events (UIKit raw values; text-input module).
        public static let editingDidBegin = Event(rawValue: 1 << 16)
        public static let editingChanged = Event(rawValue: 1 << 17)
        public static let editingDidEnd = Event(rawValue: 1 << 18)
        public static let editingDidEndOnExit = Event(rawValue: 1 << 19)
        public static let allTouchEvents = Event(rawValue: 0x0000_0FFF)
        public static let allEditingEvents = Event(rawValue: 0x000F_0000)
        public static let allEvents = Event(rawValue: 0xFFFF_FFFF)
    }

    open var isEnabled: Bool = true {
        didSet { if isEnabled != oldValue { stateDidChange() } }
    }
    open var isSelected: Bool = false {
        didSet { if isSelected != oldValue { stateDidChange() } }
    }
    open var isHighlighted: Bool = false {
        didSet { if isHighlighted != oldValue { stateDidChange() } }
    }

    open var state: State {
        var s: State = .normal
        if !isEnabled { s.insert(.disabled) }
        if isHighlighted { s.insert(.highlighted) }
        if isSelected { s.insert(.selected) }
        return s
    }

    /// Hook for subclasses: any of enabled/selected/highlighted changed.
    open func stateDidChange() {
        setNeedsLayout()
    }

    // MARK: Tracking state

    public internal(set) var isTracking = false
    public internal(set) var isTouchInside = false

    // MARK: Target-action

    public typealias ActionHandler = (UIControl, UIEvent?) -> Void

    struct Target {
        let token: Int
        var events: Event
        /// Closure registration (`addTarget(for:_:)`).
        let handler: ActionHandler?
        /// Selector registration (`addTarget(_:action:for:)`). Weak, as in
        /// UIKit: a control never keeps its target alive.
        weak var target: AnyObject?
        let action: Selector?
    }
    var targets: [Target] = []
    private var nextToken = 0

    /// Register `handler` for every control event in `controlEvents`.
    /// Returns a token for `removeTarget(_:)`.
    @discardableResult
    public func addTarget(for controlEvents: Event,
                          _ handler: @escaping ActionHandler) -> Int {
        nextToken += 1
        targets.append(Target(token: nextToken, events: controlEvents,
                              handler: handler, target: nil, action: nil))
        return nextToken
    }

    /// Remove a closure registration by the token `addTarget(for:_:)` returned.
    public func removeTarget(_ token: Int) {
        targets.removeAll { $0.token == token }
    }

    // MARK: Target-action (selector based -- UIKit's own signatures)

    /// UIKit's `addTarget(_:action:for:)`. `target` is held weakly and must
    /// conform to ``SelectorDispatching``; `action` is a selector whose name
    /// that conformance knows.
    ///
    ///     button.addTarget(self, action: #selector(buttonTapped),
    ///                      for: .touchUpInside)
    public func addTarget(_ target: AnyObject, action: Selector,
                          for controlEvents: Event) {
        nextToken += 1
        targets.append(Target(token: nextToken, events: controlEvents,
                              handler: nil, target: target, action: action))
    }

    /// UIKit's `removeTarget(_:action:for:)`. `nil` matches any target /
    /// any action; only the named event bits are unregistered, and a
    /// registration keeps any bits that were not named.
    public func removeTarget(_ target: AnyObject?, action: Selector?,
                             for controlEvents: Event) {
        for i in targets.indices.reversed() {
            let t = targets[i]
            guard t.handler == nil else { continue }   // closures unaffected
            if let target, t.target !== target { continue }
            if let action, t.action != action { continue }
            let remaining = t.events.subtracting(controlEvents)
            if remaining.isEmpty { targets.remove(at: i) }
            else { targets[i].events = remaining }
        }
    }

    /// Drop selector registrations whose weak target has deallocated (UIKit
    /// does this implicitly; we do it lazily, before each send).
    func pruneDeadTargets() {
        targets.removeAll { $0.handler == nil && $0.target == nil }
    }

    public var allControlEvents: Event {
        pruneDeadTargets()
        return targets.reduce(Event()) { $0.union($1.events) }
    }

    public func sendActions(for controlEvents: Event, with event: UIEvent? = nil) {
        pruneDeadTargets()
        for t in targets where !t.events.intersection(controlEvents).isEmpty {
            if let handler = t.handler {
                handler(self, event)
            } else if let action = t.action {
                SelectorDispatch.send(action, to: t.target, sender: self,
                                      event: event)
            }
        }
    }

    // MARK: UIAction registration (M13 — menus & actions cluster)

    /// UIKit's `addAction(_:for:)`. Modern code-based UIKit wires controls
    /// this way instead of with a selector, which is why `UIAction` alone is
    /// worth 69 uses in the census (docs/APP_COMPAT.md).
    public func addAction(_ action: UIAction, for controlEvents: Event) {
        let token = addTarget(for: controlEvents) { control, _ in
            action.performWithSender(control, target: nil)
        }
        _actions.append((action, controlEvents, token))
    }

    public func removeAction(_ action: UIAction, for controlEvents: Event) {
        for entry in _actions
        where entry.action === action && entry.events == controlEvents {
            removeTarget(entry.token)
        }
        _actions.removeAll { $0.action === action && $0.events == controlEvents }
    }

    /// Registered UIActions, in registration order (UIKit exposes
    /// `enumerateEventHandlers`; this is the honest small version).
    public var actions: [UIAction] { _actions.map(\.action) }
    var _actions: [(action: UIAction, events: Event, token: Int)] = []

    // MARK: Tracking overrides (subclass API, UIKit signatures)

    open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { true }
    open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { true }
    open func endTracking(_ touch: UITouch?, with event: UIEvent?) {}
    open func cancelTracking(with event: UIEvent?) {}

    // MARK: UIResponder plumbing (UIKit behavior)

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled, let touch = touches.first, !isTracking else { return }
        isTracking = beginTracking(touch, with: event)
        guard isTracking else { return }
        isTouchInside = true
        isHighlighted = true
        var events: Event = .touchDown
        if touch.tapCount > 1 { events.insert(.touchDownRepeat) }
        sendActions(for: events, with: event)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTracking, let touch = touches.first else { return }
        let wasInside = isTouchInside
        isTouchInside = point(inside: touch.location(in: self), with: event)
        isHighlighted = isTouchInside
        isTracking = continueTracking(touch, with: event)
        guard isTracking else {
            isHighlighted = false
            return
        }
        var events: Event = isTouchInside ? .touchDragInside : .touchDragOutside
        if isTouchInside != wasInside {
            events.insert(isTouchInside ? .touchDragEnter : .touchDragExit)
        }
        sendActions(for: events, with: event)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTracking, let touch = touches.first else { return }
        isTouchInside = point(inside: touch.location(in: self), with: event)
        endTracking(touch, with: event)
        let up: Event = isTouchInside ? .touchUpInside : .touchUpOutside
        isTracking = false
        isHighlighted = false
        sendActions(for: up, with: event)
        isTouchInside = false
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTracking else { return }
        cancelTracking(with: event)
        isTracking = false
        isHighlighted = false
        isTouchInside = false
        sendActions(for: .touchCancel, with: event)
    }
}
