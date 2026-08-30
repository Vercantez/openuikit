// Interruptible-animation source surface backed by OpenUIKit's existing
// host-clock UIView transaction engine.

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

/// Public marker matching UIKit's timing-provider family.
public protocol UITimingCurveProvider: AnyObject {}

@preconcurrency @MainActor
public final class UISpringTimingParameters: UITimingCurveProvider {
    public let dampingRatio: CGFloat
    public let initialVelocity: CGVector

    public init(dampingRatio: CGFloat, initialVelocity: CGVector = .zero) {
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }

    var _openUIKitTiming: UIViewAnimation.Timing {
        let velocity = initialVelocity.dy.magnitude >= initialVelocity.dx.magnitude
            ? initialVelocity.dy : initialVelocity.dx
        return .spring(dampingRatio: dampingRatio, initialVelocity: velocity)
    }
}

@preconcurrency @MainActor
open class UIViewPropertyAnimator {
    public let duration: TimeInterval
    public private(set) var state: UIViewAnimatingState = .inactive
    public var isRunning: Bool { state == .active }

    private let timing: UIViewAnimation.Timing
    private var animationBlocks: [() -> Void] = []
    private var completionBlocks: [(UIViewAnimatingPosition) -> Void] = []

    public init(duration: TimeInterval,
                curve: UIView.AnimationCurve,
                animations: (() -> Void)? = nil) {
        self.duration = max(0, duration)
        switch curve {
        case .easeInOut:
            timing = .curve(c1x: 0.42, c1y: 0, c2x: 0.58, c2y: 1)
        case .easeIn:
            timing = .curve(c1x: 0.42, c1y: 0, c2x: 1, c2y: 1)
        case .easeOut:
            timing = .curve(c1x: 0, c1y: 0, c2x: 0.58, c2y: 1)
        case .linear:
            timing = .curve(c1x: 0, c1y: 0, c2x: 1, c2y: 1)
        }
        if let animations { animationBlocks.append(animations) }
    }

    public init(duration: TimeInterval, timingParameters parameters: UITimingCurveProvider) {
        self.duration = max(0, duration)
        timing = (parameters as? UISpringTimingParameters)?._openUIKitTiming
            ?? .curve(c1x: 0.42, c1y: 0, c2x: 0.58, c2y: 1)
    }

    /// Queue work for the transaction. Blocks added before start execute
    /// together, so their property changes share one timing curve and one
    /// completion boundary.
    open func addAnimations(_ animation: @escaping () -> Void) {
        guard state == .inactive else { return }
        animationBlocks.append(animation)
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
        guard state == .inactive else { return }
        state = .active
        let blocks = animationBlocks
        UIView.runAnimationBlock(
            UIViewAnimationContext.Params(duration: duration,
                                          delay: max(0, delay),
                                          timing: timing),
            animations: { for block in blocks { block() } },
            // The active transaction owns its animator until delivery. Focus
            // and other UIKit apps commonly keep an animator only in a local
            // variable; UIKit still guarantees that its completion fires.
            completion: { finished in
                self.state = .stopped
                let completions = self.completionBlocks
                self.completionBlocks.removeAll()
                let position: UIViewAnimatingPosition = finished ? .end : .current
                for completion in completions { completion(position) }
            },
            waitsForDurationWhenEmpty: true)
    }
}
