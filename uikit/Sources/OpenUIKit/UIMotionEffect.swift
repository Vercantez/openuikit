// UIMotionEffect, UIInterpolatingMotionEffect, UIMotionEffectGroup and
// UIView's motion-effect list (UIMotionEffect.h). SVProgressHUD 2.2.3 tilts
// its HUD with an interpolating effect pair in a group
// (-updateMotionEffectForXMotionEffectType:yMotionEffectType:).
//
// MEASURED kioskrowsprobe `## motion` (iPad Pro 11-inch M4 simulator /
// iOS 26.1): an interpolating effect keeps its key path, type and relative
// values; adding a group to a view lists it in `motionEffects`, removing it
// empties the list. A simulator has no device-motion input, so no effect
// ever moves a view there; OpenUIKit has none either and applies nothing —
// the objects and the view's list are the observable behaviour.

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

@preconcurrency @MainActor
open class UIMotionEffect: NSObject {
    public override init() { super.init() }
}

@preconcurrency @MainActor
open class UIInterpolatingMotionEffect: UIMotionEffect {
    public enum EffectType: Int, Sendable {
        case tiltAlongHorizontalAxis = 0
        case tiltAlongVerticalAxis = 1
    }

    public let keyPath: String
    public let type: EffectType
    public var minimumRelativeValue: Any?
    public var maximumRelativeValue: Any?

    public init(keyPath: String, type: EffectType) {
        self.keyPath = keyPath
        self.type = type
        super.init()
    }
}

@preconcurrency @MainActor
open class UIMotionEffectGroup: UIMotionEffect {
    public var motionEffects: [UIMotionEffect]?
}

extension UIView {
    public final var motionEffects: [UIMotionEffect] {
        get { _motionEffects }
        set { _motionEffects = newValue }
    }

    public final func addMotionEffect(_ effect: UIMotionEffect) {
        if !_motionEffects.contains(where: { $0 === effect }) { _motionEffects.append(effect) }
    }

    public final func removeMotionEffect(_ effect: UIMotionEffect) {
        _motionEffects.removeAll { $0 === effect }
    }
}
