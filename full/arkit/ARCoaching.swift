import Foundation

public protocol ARCoachingOverlayViewDelegate: AnyObject {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView)
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView)
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView)
}

public extension ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        _ = coachingOverlayView
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        _ = coachingOverlayView
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        _ = coachingOverlayView
    }
}

/// Linux has no UIKit view hierarchy. This type is an `NSObject` stand-in for
/// Apple's `UIView` subclass and never becomes visually active.
open class ARCoachingOverlayView: NSObject {
    public enum Goal: Int, Hashable, Sendable {
        case tracking = 0
        case horizontalPlane = 1
        case verticalPlane = 2
        case anyPlane = 3
        case geoTracking = 4
    }

    public var activatesAutomatically: Bool = true
    public weak var delegate: (any ARCoachingOverlayViewDelegate)?
    public var goal: Goal = .tracking
    public private(set) var isActive: Bool = false
    public var session: ARSession?
    public weak var sessionProvider: (any ARSessionProviding)?

    public override init() {
        super.init()
    }

    public func setActive(_ active: Bool, animated: Bool) {
        _ = animated
        // No camera, no coaching UI, and no fabricated "ready to place" state.
        isActive = false
        _ = active
    }
}
