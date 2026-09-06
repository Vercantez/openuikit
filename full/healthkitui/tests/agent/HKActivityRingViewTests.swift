import Foundation
@_spi(OpenUIKitHost) import HealthKitUI

func testHKActivityRingViewClass() {
    let zero = HKActivityRingView()
    let asView: UIView = zero
    precondition(asView.frame == .zero)
    precondition(zero.activitySummary == nil)
    precondition(!HealthKitUIHostControl.lastAnimatedRequest(of: zero))
    precondition(!HealthKitUIHostControl.didRenderActivityRings(of: zero))

    let framed = HKActivityRingView(frame: CGRect(x: 1, y: 2, width: 44, height: 44))
    precondition(framed.frame.origin.x == 1)
    precondition(framed.frame.origin.y == 2)
    precondition(framed.frame.width == 44)
    precondition(framed.frame.height == 44)
    precondition(framed.activitySummary == nil)
}

func testActivitySummaryProperty() {
    let view = HKActivityRingView()
    precondition(view.activitySummary == nil)

    let summary = HKActivitySummary()
    view.activitySummary = summary
    precondition(view.activitySummary === summary)
    precondition(!HealthKitUIHostControl.lastAnimatedRequest(of: view))
    precondition(!HealthKitUIHostControl.didRenderActivityRings(of: view))

    view.activitySummary = nil
    precondition(view.activitySummary == nil)
    precondition(!HealthKitUIHostControl.lastAnimatedRequest(of: view))
}

func testSetActivitySummaryAnimated() {
    let view = HKActivityRingView()
    let first = HKActivitySummary()
    view.setActivitySummary(first, animated: true)
    precondition(view.activitySummary === first)
    precondition(HealthKitUIHostControl.lastAnimatedRequest(of: view))
    precondition(!HealthKitUIHostControl.didRenderActivityRings(of: view))

    let second = HKActivitySummary()
    view.setActivitySummary(second, animated: false)
    precondition(view.activitySummary === second)
    precondition(!HealthKitUIHostControl.lastAnimatedRequest(of: view))
    precondition(!HealthKitUIHostControl.didRenderActivityRings(of: view))
}
