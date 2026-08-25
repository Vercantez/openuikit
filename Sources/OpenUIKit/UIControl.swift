// UIControl. Owner: controls/event module (M7).
//
// UIKit's control base: state (enabled/highlighted/selected), target-action
// dispatch, and touch tracking (beginTracking/continueTracking/endTracking/
// cancelTracking) driven by the UIResponder touch entry points UIWindow
// delivers to the hit-test view.
//
// No ObjC runtime: targets are closures. `addTarget(for:_:)` returns a
// token for removal; `sendActions(for:)` invokes every handler whose
// registered event set intersects the sent events (UIKit semantics).

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

    // MARK: Target-action (closure based)

    public typealias ActionHandler = (UIControl, UIEvent?) -> Void

    struct Target {
        let token: Int
        let events: Event
        let handler: ActionHandler
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
                              handler: handler))
        return nextToken
    }

    public func removeTarget(_ token: Int) {
        targets.removeAll { $0.token == token }
    }

    public var allControlEvents: Event {
        targets.reduce(Event()) { $0.union($1.events) }
    }

    public func sendActions(for controlEvents: Event, with event: UIEvent? = nil) {
        for t in targets where !t.events.intersection(controlEvents).isEmpty {
            t.handler(self, event)
        }
    }

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
