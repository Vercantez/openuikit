// CADisplayLink on OpenUIKit's deterministic host clock.
//
// A display link is scheduled into the same turn driven by
// `UIWindow.tick(timestamp:)`; it never owns a wall-clock thread. This keeps
// renderer captures deterministic while production hosts still deliver one
// callback per paced frame.

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif

#if canImport(ObjectiveC)
import ObjectiveC
#endif

@preconcurrency @MainActor
open class CADisplayLink: NSObject, @unchecked Sendable {
    private static var scheduled: [CADisplayLink] = []
    private static var lastHostTimestamp: CFTimeInterval?

    private var target: AnyObject?
    private let selector: Selector
    private var modes: Set<RunLoop.Mode> = []
    private var isValid = true
    private var deliveredHostFrames = 0

    /// Timestamp of the display frame associated with the most recent call.
    public private(set) var timestamp: CFTimeInterval = 0

    /// Nominal duration of one host display frame. OpenUIKit's production
    /// frame loop is paced at 60 Hz.
    public private(set) var duration: CFTimeInterval = 1.0 / 60.0

    /// Timestamp applications should target for their next rendered frame.
    public private(set) var targetTimestamp: CFTimeInterval = 1.0 / 60.0

    /// Pausing suppresses callbacks without removing the link from its modes.
    open var isPaused = false

    /// Legacy frame divisor. Values below one are normalized to one.
    open var frameInterval: Int = 1 {
        didSet { if frameInterval < 1 { frameInterval = 1 } }
    }

    /// Desired callback rate. Zero follows the native 60 Hz host cadence.
    open var preferredFramesPerSecond: Int = 0 {
        didSet { if preferredFramesPerSecond < 0 { preferredFramesPerSecond = 0 } }
    }

    public init(target: Any, selector: Selector) {
        self.target = target as AnyObject
        self.selector = selector
        super.init()
    }

    /// Add the link to a run-loop mode. OpenUIKit has one host run loop; the
    /// mode is retained so removing the final registration unschedules it.
    open func add(to runloop: RunLoop, forMode mode: RunLoop.Mode) {
        _ = runloop
        guard isValid else { return }
        modes.insert(mode)
        if !Self.scheduled.contains(where: { $0 === self }) {
            Self.scheduled.append(self)
        }
    }

    open func remove(from runloop: RunLoop, forMode mode: RunLoop.Mode) {
        _ = runloop
        modes.remove(mode)
        if modes.isEmpty { Self.scheduled.removeAll { $0 === self } }
    }

    /// Unschedule permanently and release the retained target.
    open func invalidate() {
        guard isValid else { return }
        isValid = false
        modes.removeAll()
        Self.scheduled.removeAll { $0 === self }
        target = nil
    }

    /// Hosts use this redraw hint alongside their other animation sources.
    public static var _hasActiveDisplayLinks: Bool {
        scheduled.contains { $0.isValid && !$0.isPaused && !$0.modes.isEmpty }
    }

    static func _step(to hostTimestamp: CFTimeInterval) {
        guard hostTimestamp.isFinite, hostTimestamp >= 0 else { return }
        // One display clock services every UIWindow. Multiple windows ticked
        // at the same timestamp must not multiply callback delivery.
        guard lastHostTimestamp != hostTimestamp else { return }
        lastHostTimestamp = hostTimestamp

        let links = scheduled
        for link in links where link.isValid && !link.isPaused && !link.modes.isEmpty {
            link.deliveredHostFrames &+= 1
            let divisor: Int
            if link.preferredFramesPerSecond > 0 {
                divisor = Swift.max(1, Int((60.0 / Double(link.preferredFramesPerSecond)).rounded()))
            } else {
                divisor = Swift.max(1, link.frameInterval)
            }
            guard (link.deliveredHostFrames - 1) % divisor == 0 else { continue }

            link.duration = Double(divisor) / 60.0
            link.timestamp = hostTimestamp
            link.targetTimestamp = hostTimestamp + link.duration
            link._send()
        }
        scheduled.removeAll { !$0.isValid || $0.modes.isEmpty }
    }

    private func _send() {
        guard let target else { return }

#if canImport(ObjectiveC)
        // CADisplayLink accepts any Objective-C-visible target, including a
        // Swift root class which does not inherit NSObject (Gifu deliberately
        // uses that shape). Dispatch its one-argument selector through the
        // runtime IMP before falling back to OpenUIKit's portable table.
        if selector.actionArity == 1,
           let object = target as? any NSObjectProtocol,
           object.responds(to: selector),
           let method = class_getInstanceMethod(type(of: target), selector) {
            typealias Function = @convention(c) (
                AnyObject, Selector, AnyObject?
            ) -> Void
            let function = unsafeBitCast(
                method_getImplementation(method),
                to: Function.self
            )
            function(target, selector, self)
            return
        }
#endif

        SelectorDispatch.send(selector, to: target, sender: self)
    }

    /// Deterministic test/renderer reset. Existing links become invalid and
    /// release their targets so state cannot cross an application boundary.
    public static func _reset() {
        for link in scheduled {
            link.isValid = false
            link.modes.removeAll()
            link.target = nil
        }
        scheduled.removeAll()
        lastHostTimestamp = nil
    }
}
