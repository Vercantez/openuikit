import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(HealthKit)
import HealthKit
#endif

/// A view that displays Move, Exercise, and Stand activity rings.
///
/// Linux stores the `HKActivitySummary` and the last `animated` flag. It
/// never renders rings, talks to HealthKit, or invents animation timing.
///
/// https://developer.apple.com/documentation/healthkitui/hkactivityringview
///
/// macios (`src/healthkitui.cs`) confirms `UIView` subclass,
/// designated `init(frame:)`, strong `activitySummary`, and
/// `setActivitySummary(_:animated:)`. Fresh-instance default is unobserved;
/// Linux uses `nil`.
open class HKActivityRingView: UIView {
    private var storedSummary: HKActivitySummary?
    private var lastAnimatedRequest = false
    private var didRenderActivityRings = false

    /// The activity summary currently represented by the view.
    ///
    /// Setting this property is treated as `setActivitySummary(_:animated:)`
    /// with `animated: false`. Apple's setter-vs-method relationship is
    /// unobserved (see `oracle-questions.tsv`).
    open var activitySummary: HKActivitySummary? {
        get { storedSummary }
        set { setActivitySummary(newValue, animated: false) }
    }

    public override init(frame: CGRect = .zero) {
        self.storedSummary = nil
        super.init(frame: frame)
    }

    /// Updates the rings from `activitySummary`.
    ///
    /// Darwin can animate the change. Linux stores the object identity and
    /// the `animated` flag, then leaves `didRenderActivityRings` false.
    open func setActivitySummary(_ activitySummary: HKActivitySummary?, animated: Bool) {
        storedSummary = activitySummary
        lastAnimatedRequest = animated
        didRenderActivityRings = false
    }

    var linuxLastAnimatedRequest: Bool { lastAnimatedRequest }
    var linuxDidRenderActivityRings: Bool { didRenderActivityRings }
}
