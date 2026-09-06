// Interruptible-animation source surface backed by OpenUIKit's existing
// host-clock UIView transaction engine.
//
// MEASURED animprobe, iPhone SE 2x / iOS 26.1:
//   * Defaults: state inactive, isRunning false, isReversed false,
//     fractionComplete 0, isInterruptible true, isUserInteractionEnabled true,
//     isManualHitTestingEnabled false, scrubsLinearly true,
//     pausesOnCompletion false, delay 0.
//   * UICubicTimingParameters(animationCurve:): easeInOut (0.42,0,0.58,1),
//     easeIn (0.42,0,1,1), easeOut (0,0,0.58,1), linear (0,0,1,1);
//     timingCurveType builtIn (0). Custom points: type cubic (1), curve raw 6.
//     Default init: CSS ease (0.25, 0.1, 0.25, 1), curve raw 5.
//   * Running 1 s move 50→150: fractionComplete is linear time; pixels follow
//     the cubic (easeInOut t≈0.243 → x=62.14) or the duration-fit spring
//     (ζ=0.5 t≈0.297 → x=166.15, same family as UIView.animate).
//   * Normal completion releases the animator (inactive, not stopped).
//   * stopAnimation(true) from paused → inactive, completions skipped,
//     model restored to the FROM value (alpha 1 after 1→0).
//   * finishAnimation(at: .start) from stopped → inactive, model at start.

public enum UIViewAnimatingPosition: Int, Sendable {
    case end = 0
    case start = 1
    case current = 2
}

public enum UIViewAnimatingState: Int, Sendable {
    case inactive = 0
    case active = 1
    case stopped = 2
}

/// MEASURED animprobe, iPhone SE 2x / iOS 26.1: builtIn=0, cubic=1, spring=2.
public enum UITimingCurveType: Int, Sendable {
    case builtIn = 0
    case cubic = 1
    case spring = 2
    case composed = 3
}

@preconcurrency @MainActor
public protocol UITimingCurveProvider: AnyObject {
    var timingCurveType: UITimingCurveType { get }
    var cubicTimingParameters: UICubicTimingParameters? { get }
    var springTimingParameters: UISpringTimingParameters? { get }
}

@preconcurrency @MainActor
public protocol UIViewAnimating: AnyObject {
    var state: UIViewAnimatingState { get }
    var isRunning: Bool { get }
    var isReversed: Bool { get set }
    var fractionComplete: CGFloat { get set }
    func startAnimation()
    func startAnimation(afterDelay delay: TimeInterval)
    func pauseAnimation()
    func stopAnimation(_ withoutFinishing: Bool)
    func finishAnimation(at finalPosition: UIViewAnimatingPosition)
}

@preconcurrency @MainActor
public protocol UIViewImplicitlyAnimating: UIViewAnimating {
    func addAnimations(_ animation: @escaping () -> Void, delayFactor: CGFloat)
    func addAnimations(_ animation: @escaping () -> Void)
    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void)
    func continueAnimation(withTimingParameters parameters: UITimingCurveProvider?,
                           durationFactor: CGFloat)
}

@preconcurrency @MainActor
public final class UICubicTimingParameters: UITimingCurveProvider {
    public let controlPoint1: CGPoint
    public let controlPoint2: CGPoint
    public let animationCurve: UIView.AnimationCurve

    /// MEASURED animprobe: default init is CSS ease (0.25, 0.1, 0.25, 1),
    /// `animationCurve.rawValue == 5`.
    public init() {
        controlPoint1 = CGPoint(x: 0.25, y: 0.1)
        controlPoint2 = CGPoint(x: 0.25, y: 1)
        animationCurve = .cssEase
    }

    public init(animationCurve curve: UIView.AnimationCurve) {
        animationCurve = curve
        switch curve {
        case .easeInOut, .navigationTransition:
            controlPoint1 = CGPoint(x: 0.42, y: 0)
            controlPoint2 = CGPoint(x: 0.58, y: 1)
        case .easeIn:
            controlPoint1 = CGPoint(x: 0.42, y: 0)
            controlPoint2 = CGPoint(x: 1, y: 1)
        case .easeOut:
            controlPoint1 = CGPoint(x: 0, y: 0)
            controlPoint2 = CGPoint(x: 0.58, y: 1)
        case .linear:
            controlPoint1 = CGPoint(x: 0, y: 0)
            controlPoint2 = CGPoint(x: 1, y: 1)
        case .cssEase:
            controlPoint1 = CGPoint(x: 0.25, y: 0.1)
            controlPoint2 = CGPoint(x: 0.25, y: 1)
        case .customCubic:
            controlPoint1 = CGPoint(x: 0.42, y: 0)
            controlPoint2 = CGPoint(x: 0.58, y: 1)
        }
    }

    public init(controlPoint1: CGPoint, controlPoint2: CGPoint) {
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
        animationCurve = .customCubic
    }

    public var timingCurveType: UITimingCurveType {
        switch animationCurve {
        case .easeInOut, .easeIn, .easeOut, .linear, .navigationTransition:
            return .builtIn
        case .cssEase, .customCubic:
            return animationCurve == .cssEase ? .builtIn : .cubic
        }
    }

    public var cubicTimingParameters: UICubicTimingParameters? { self }
    public var springTimingParameters: UISpringTimingParameters? { nil }

    var _openUIKitTiming: UIViewAnimation.Timing {
        .curve(
            c1x: controlPoint1.x,
            c1y: controlPoint1.y,
            c2x: controlPoint2.x,
            c2y: controlPoint2.y
        )
    }
}

@preconcurrency @MainActor
public final class UISpringTimingParameters: UITimingCurveProvider {
    public let dampingRatio: CGFloat
    public let initialVelocity: CGVector
    public let mass: CGFloat?
    public let stiffness: CGFloat?
    public let damping: CGFloat?

    public init() {
        dampingRatio = 1
        initialVelocity = .zero
        mass = nil
        stiffness = nil
        damping = nil
    }

    public init(dampingRatio: CGFloat) {
        self.dampingRatio = dampingRatio
        initialVelocity = .zero
        mass = nil
        stiffness = nil
        damping = nil
    }

    public init(dampingRatio: CGFloat, initialVelocity: CGVector) {
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
        mass = nil
        stiffness = nil
        damping = nil
    }

    public init(mass: CGFloat, stiffness: CGFloat, damping: CGFloat,
                initialVelocity: CGVector) {
        self.mass = mass
        self.stiffness = stiffness
        self.damping = damping
        self.initialVelocity = initialVelocity
            let wn = Double(stiffness) > 0 && Double(mass) > 0
                ? (Double(stiffness) / Double(mass)).squareRoot() : 1
            let zeta = wn > 0 ? Double(damping) / (2 * Double(mass) * wn) : 1
            dampingRatio = CGFloat(zeta)
    }

    public var timingCurveType: UITimingCurveType { .spring }
    public var cubicTimingParameters: UICubicTimingParameters? { nil }
    public var springTimingParameters: UISpringTimingParameters? { self }

    var _openUIKitTiming: UIViewAnimation.Timing {
        let velocity = initialVelocity.dy.magnitude >= initialVelocity.dx.magnitude
            ? initialVelocity.dy : initialVelocity.dx
        return .spring(dampingRatio: dampingRatio, initialVelocity: velocity)
    }
}

@preconcurrency @MainActor
open class UIViewPropertyAnimator: UIViewImplicitlyAnimating {
    public let duration: TimeInterval
    public private(set) var delay: TimeInterval = 0
    public private(set) var state: UIViewAnimatingState = .inactive
    public var isReversed = false
    public var isInterruptible = true
    public var isUserInteractionEnabled = true
    public var isManualHitTestingEnabled = false
    public var scrubsLinearly = true
    public var pausesOnCompletion = false
    public private(set) var timingParameters: UITimingCurveProvider?

    public var isRunning: Bool { state == .active && running }

    /// Internal framework bridge used by SwiftUI's `repeatForever`. UIKit's
    /// public property animator surface has no repeat toggle, but SwiftUI's
    /// renderer ultimately installs the same repeating Core Animation track.
    /// Keeping the knobs on the retained animator preserves an arbitrary
    /// cubic timing curve instead of degrading repeats to the four UIView
    /// convenience curves.
    public var _openUIKitRepeats = false
    public var _openUIKitAutoreverses = false

    private var timing: UIViewAnimation.Timing
    private var animationBlocks: [() -> Void] = []
    private var delayedAnimationBlocks: [(factor: CGFloat, block: () -> Void)] = []
    private var completionBlocks: [(UIViewAnimatingPosition) -> Void] = []
    private var running = false
    private var committed = false
    private var startTime: Double = 0
    private var pausedFraction: CGFloat = 0
    private var transactionID = 0
    private var trackedViews: [UIView] = []
    private var heldCompletions: [UIViewAnimationCompletionQueue.Entry] = []

    public init(duration: TimeInterval,
                curve: UIView.AnimationCurve,
                animations: (() -> Void)? = nil) {
        self.duration = max(0, duration)
        let cubic = UICubicTimingParameters(animationCurve: curve)
        timingParameters = cubic
        timing = cubic._openUIKitTiming
        if let animations { animationBlocks.append(animations) }
    }

    public init(duration: TimeInterval, controlPoint1 point1: CGPoint,
                controlPoint2 point2: CGPoint, animations: (() -> Void)? = nil) {
        self.duration = max(0, duration)
        let cubic = UICubicTimingParameters(controlPoint1: point1, controlPoint2: point2)
        timingParameters = cubic
        timing = cubic._openUIKitTiming
        if let animations { animationBlocks.append(animations) }
    }

    public init(duration: TimeInterval, dampingRatio ratio: CGFloat,
                animations: (() -> Void)? = nil) {
        self.duration = max(0, duration)
        let spring = UISpringTimingParameters(dampingRatio: ratio)
        timingParameters = spring
        timing = spring._openUIKitTiming
        if let animations { animationBlocks.append(animations) }
    }

    public init(duration: TimeInterval, timingParameters parameters: UITimingCurveProvider) {
        self.duration = max(0, duration)
        timingParameters = parameters
        if let spring = parameters as? UISpringTimingParameters {
            timing = spring._openUIKitTiming
        } else if let cubic = parameters as? UICubicTimingParameters {
            timing = cubic._openUIKitTiming
        } else {
            timing = .curve(c1x: 0.42, c1y: 0, c2x: 0.58, c2y: 1)
        }
    }

    open func addAnimations(_ animation: @escaping () -> Void) {
        addAnimations(animation, delayFactor: 0)
    }

    open func addAnimations(_ animation: @escaping () -> Void, delayFactor: CGFloat) {
        guard state != .stopped else { return }
        let factor = min(max(delayFactor, 0), 1)
        if state == .inactive && factor == 0 {
            animationBlocks.append(animation)
        } else {
            delayedAnimationBlocks.append((factor, animation))
            if committed {
                runDelayedBlock(factor: factor, animation)
            }
        }
    }

    open func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        guard state != .stopped else {
            completion(.end)
            return
        }
        completionBlocks.append(completion)
    }

    open func startAnimation() { startAnimation(afterDelay: 0) }

    open func startAnimation(afterDelay delay: TimeInterval) {
        if state == .active && !running {
            continueAnimation(withTimingParameters: nil, durationFactor: 0)
            return
        }
        guard state == .inactive else { return }
        self.delay = max(0, delay)
        commitIfNeeded()
        running = true
        state = .active
        startTime = OpenUIKitRuntime.animationTime
        scheduleCompletion()
    }

    open func pauseAnimation() {
        guard state == .active, running else { return }
        pausedFraction = linearFraction(at: OpenUIKitRuntime.animationTime)
        running = false
        applyScrub(pausedFraction)
        heldCompletions = UIViewAnimationCompletionQueue.takeInterrupted(
            transactionID: transactionID)
    }

    public var fractionComplete: CGFloat {
        get {
            if state == .inactive { return pausedFraction }
            if running {
                return linearFraction(at: OpenUIKitRuntime.animationTime)
            }
            return pausedFraction
        }
        set {
            let f = min(max(newValue, 0), 1)
            if state == .inactive {
                commitIfNeeded()
                state = .active
                running = false
                startTime = OpenUIKitRuntime.animationTime
            }
            if running { pauseAnimation() }
            pausedFraction = f
            applyScrub(f)
        }
    }

    open func stopAnimation(_ withoutFinishing: Bool) {
        guard state == .active || state == .stopped else { return }
        if running { pauseAnimation() }
        if withoutFinishing {
            applyPosition(.start)
            clearTrackedAnimations()
            heldCompletions.removeAll()
            completionBlocks.removeAll()
            running = false
            state = .inactive
            committed = false
        } else {
            applyPosition(.current)
            running = false
            state = .stopped
            _ = UIViewAnimationCompletionQueue.takeInterrupted(transactionID: transactionID)
            heldCompletions.removeAll()
        }
    }

    open func finishAnimation(at finalPosition: UIViewAnimatingPosition) {
        guard state == .stopped else { return }
        applyPosition(finalPosition)
        clearTrackedAnimations()
        fireCompletions(finalPosition)
        running = false
        state = .inactive
        committed = false
    }

    open func continueAnimation(withTimingParameters parameters: UITimingCurveProvider?,
                                durationFactor: CGFloat) {
        guard state == .active, !running else { return }
        if let parameters {
            if let spring = parameters as? UISpringTimingParameters {
                timing = spring._openUIKitTiming
            } else if let cubic = parameters as? UICubicTimingParameters {
                timing = cubic._openUIKitTiming
            }
            timingParameters = parameters
        }
        let f = pausedFraction
        let remaining = isReversed ? Double(f) : Double(1 - f)
        let factor = durationFactor <= 0 ? remaining : Double(durationFactor)
        let speed = remaining <= 1e-12 || factor <= 1e-12
            ? 1
            : remaining / factor
        running = true
        startTime = OpenUIKitRuntime.animationTime
        let now = startTime
        for view in trackedViews {
            for i in view.animations.indices where view.animations[i].transactionID == transactionID {
                view.animations[i].begin = now - view.animations[i].delay
                view.animations[i].speed = isReversed ? -speed : speed
                view.animations[i].timeOffset = Double(f) * view.animations[i].duration
                view.animations[i].pacesLinearly = false
                if parameters != nil {
                    view.animations[i] = retimed(view.animations[i], timing: timing)
                }
            }
        }
        scheduleCompletion()
    }

    public static func runningPropertyAnimator(
        withDuration duration: TimeInterval,
        delay: TimeInterval,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void,
        completion: ((UIViewAnimatingPosition) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let curve: UIView.AnimationCurve
        switch (options.rawValue >> 16) & 0xF {
        case 1: curve = .easeIn
        case 2: curve = .easeOut
        case 3: curve = .linear
        default: curve = .easeInOut
        }
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve,
                                              animations: animations)
        animator.isUserInteractionEnabled = options.contains(.allowUserInteraction)
        if let completion { animator.addCompletion(completion) }
        animator.startAnimation(afterDelay: delay)
        return animator
    }

    // MARK: - Internals

    private func commitIfNeeded() {
        guard !committed else { return }
        committed = true
        let blocks = animationBlocks
        let params = UIViewAnimationContext.Params(
            duration: duration,
            delay: delay,
            timing: timing,
            allowsUserInteraction: isUserInteractionEnabled || isManualHitTestingEnabled,
            repeats: _openUIKitRepeats,
            autoreverses: _openUIKitAutoreverses)
        UIView.runAnimationBlock(
            params,
            animations: {
                for block in blocks { block() }
            },
            completion: nil,
            waitsForDurationWhenEmpty: false)
        transactionID = trackedTransactionID()
        trackedViews = UIViewAnimationContext.recordedViews
        for item in delayedAnimationBlocks {
            runDelayedBlock(factor: item.factor, item.block)
        }
    }

    private func trackedTransactionID() -> Int {
        for view in UIViewAnimationContext.recordedViews {
            if let id = view.animations.last?.transactionID, id != 0 { return id }
        }
        return UIViewAnimationContext.nextTransactionID &- 1
    }

    private func runDelayedBlock(factor: CGFloat, _ animation: @escaping () -> Void) {
        let remaining = max(0, 1 - Double(fractionComplete))
        let extraDelay = Double(factor) * remaining * duration
        UIView.runAnimationBlock(
            UIViewAnimationContext.Params(
                duration: duration,
                delay: extraDelay,
                timing: timing,
                allowsUserInteraction: isUserInteractionEnabled || isManualHitTestingEnabled),
            animations: animation,
            completion: nil)
        for view in UIViewAnimationContext.recordedViews {
            if !trackedViews.contains(where: { $0 === view }) {
                trackedViews.append(view)
            }
        }
    }

    private func scheduleCompletion() {
        _ = UIViewAnimationCompletionQueue.takeInterrupted(transactionID: transactionID)
        let remaining: Double
        if running {
            let t = OpenUIKitRuntime.animationTime
            if t < startTime + delay {
                remaining = (startTime + delay - t) + duration
            } else {
                let f = Double(linearFraction(at: t))
                remaining = (isReversed ? f : 1 - f) * duration
            }
        } else {
            remaining = (isReversed ? Double(pausedFraction) : 1 - Double(pausedFraction)) * duration
        }
        let end = OpenUIKitRuntime.animationTime + max(0, remaining)
        OpenUIKitRuntime.noteAnimationWork(until: end)
        UIViewAnimationCompletionQueue.schedule(
            end: end, transactionID: transactionID
        ) { finished in
            self.handleClockCompletion(finished: finished)
        }
    }

    private func pausedFractionIfRunning() -> CGFloat {
        running ? linearFraction(at: OpenUIKitRuntime.animationTime) : pausedFraction
    }

    private func handleClockCompletion(finished: Bool) {
        guard state == .active, running else { return }
        if pausesOnCompletion {
            pauseAnimation()
            pausedFraction = isReversed ? 0 : 1
            applyScrub(pausedFraction)
            return
        }
        running = false
        state = .inactive
        committed = false
        pausedFraction = isReversed ? 0 : 1
        clearTrackedAnimations()
        fireCompletions(finished ? (isReversed ? .start : .end) : .current)
    }

    private func fireCompletions(_ position: UIViewAnimatingPosition) {
        let completions = completionBlocks
        completionBlocks.removeAll()
        heldCompletions.removeAll()
        for completion in completions { completion(position) }
    }

    private func linearFraction(at time: Double) -> CGFloat {
        guard duration > 1e-12 else { return 1 }
        let elapsed = time - startTime - delay
        var f = elapsed / duration
        if isReversed { f = 1 - f }
        return CGFloat(min(max(f, 0), 1))
    }

    private func applyScrub(_ fraction: CGFloat) {
        let now = OpenUIKitRuntime.animationTime
        for view in trackedViews {
            for i in view.animations.indices where view.animations[i].transactionID == transactionID {
                view.animations[i].begin = now - view.animations[i].delay
                view.animations[i].speed = 0
                view.animations[i].timeOffset = Double(fraction) * view.animations[i].duration
                view.animations[i].pacesLinearly = scrubsLinearly
            }
        }
    }

    private func applyPosition(_ position: UIViewAnimatingPosition) {
        let now = OpenUIKitRuntime.animationTime
        for view in trackedViews {
            for anim in view.animations where anim.transactionID == transactionID {
                let value: UIViewAnimation.Value
                switch position {
                case .start: value = anim.from
                case .end: value = anim.to
                case .current: value = view.presentationValue(of: anim, at: now)
                }
                view._applyAnimationValue(value, for: anim.property)
            }
        }
    }

    private func clearTrackedAnimations() {
        for view in trackedViews {
            view.animations.removeAll { $0.transactionID == transactionID }
        }
        trackedViews.removeAll()
    }

    private func retimed(_ anim: UIViewAnimation, timing: UIViewAnimation.Timing) -> UIViewAnimation {
        var copy = anim
        switch timing {
        case .curve, .spring, .cosineEaseInOut:
            copy = UIViewAnimation(
                property: anim.property, from: anim.from, to: anim.to,
                begin: anim.begin, delay: anim.delay, duration: anim.duration,
                timing: timing,
                allowsUserInteraction: anim.allowsUserInteraction,
                repeats: anim.repeats, autoreverses: anim.autoreverses,
                transactionID: anim.transactionID,
                speed: anim.speed, timeOffset: anim.timeOffset,
                pacesLinearly: anim.pacesLinearly)
        }
        return copy
    }
}
