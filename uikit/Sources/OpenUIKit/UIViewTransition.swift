// UIView content-transition entry point. Property animation and completion
// semantics are owned by UIViewAnimation.swift; keeping the public transition
// wrapper separate avoids coupling it to the view/layer implementation.

extension UIView {
    /// Run a UIKit-style transition transaction scoped to `view`.
    ///
    /// Animatable UIView properties changed by `animations` use the normal
    /// OpenUIKit animation engine, including `.beginFromCurrentState` source
    /// sampling and interruption completions. A content-only transition still
    /// keeps its completion pending for `duration`, as UIKit does. The current
    /// renderer does not retain old/new content snapshots, so
    /// `.transitionCrossDissolve` changes content at commit time rather than
    /// blending the two snapshots; the timing/source surface remains honest.
    public static func transition(with view: UIView,
                                  duration: Double,
                                  options: AnimationOptions = [],
                                  animations: (() -> Void)?,
                                  completion: ((Bool) -> Void)? = nil) {
        _ = view
        runAnimationBlock(UIViewAnimationContext.Params(
            duration: duration, delay: 0, timing: options.timingCurve,
            beginsFromCurrentState: options.contains(.beginFromCurrentState),
            allowsUserInteraction: options.contains(.allowUserInteraction)),
            animations: animations ?? {}, completion: completion,
            waitsForDurationWhenEmpty: true)
    }

    /// Replace one child with another in the same container while preserving
    /// the normal UIView animation clock and deferred completion semantics.
    public static func transition(from fromView: UIView,
                                  to toView: UIView,
                                  duration: Double,
                                  options: AnimationOptions = [],
                                  completion: ((Bool) -> Void)? = nil) {
        guard let container = fromView.superview,
              let oldIndex = container.subviews.firstIndex(where: { $0 === fromView }) else {
            completion?(false)
            return
        }
        let insertionIndex = container.subviews[..<oldIndex]
            .filter { $0 !== toView }.count
        runAnimationBlock(UIViewAnimationContext.Params(
            duration: duration, delay: 0, timing: options.timingCurve,
            beginsFromCurrentState: options.contains(.beginFromCurrentState),
            allowsUserInteraction: options.contains(.allowUserInteraction)),
            animations: {
                toView.removeFromSuperview()
                fromView.removeFromSuperview()
                container.insertSubview(toView,
                                        at: min(insertionIndex, container.subviews.count))
            }, completion: completion, waitsForDurationWhenEmpty: true)
    }
}
