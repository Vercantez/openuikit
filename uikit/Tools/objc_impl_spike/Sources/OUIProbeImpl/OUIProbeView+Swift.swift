// Swift-only API on the same class, in a separate file: ordinary (non
// @implementation) extension. Measures whether Swift callers keep
// Swift-native conveniences (generics, closures, Swift value types).
import Foundation
import OUIProbeHeader

public extension OUIProbeView {
    /// Generic Swift-only method.
    func firstSubview<T: OUIProbeView>(of type: T.Type) -> T? {
        for view in subviews {
            if let match = view as? T { return match }
        }
        return nil
    }

    /// Swift-only closure-taking method over the Swift-only stored state.
    func animate(keyPath: String, from: Double, to: Double,
                 completion: (OUIProbeAnimation) -> Void) {
        let record = OUIProbeAnimation(keyPath: keyPath, from: from, to: to)
        animations.append(record)
        completion(record)
    }

    /// Swift-only computed property returning a tuple.
    var geometrySummary: (origin: CGPoint, size: CGSize) {
        (frame.origin, frame.size)
    }

    /// Enum-with-payload state, Swift-only.
    var tintDescription: String {
        switch tint {
        case .none: return "none"
        case let .color(r, g, b): return "rgb(\(r),\(g),\(b))"
        }
    }
}

/// A Swift subclass of the Swift-implemented, Objective-C-declared class.
/// Overrides an Objective-C-visible override point and calls super.
open class OUISwiftSubview: OUIProbeView {
    public var swiftSubviewLayouts = 0
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    open override func layoutSubviews() {
        OUIProbeTrace.record("OUISwiftSubview.layoutSubviews(before super)")
        super.layoutSubviews()
        swiftSubviewLayouts += 1
        OUIProbeTrace.record("OUISwiftSubview.layoutSubviews(after super)")
    }
}

/// A Swift subclass with NO Swift vtable entries beyond what the header
/// declares: every override is an Objective-C method and every Swift-only
/// member is `final`. The chain probe (OUIProbeLeaf.m) subclasses this from
/// Objective-C with the subclassing restriction lifted, to measure whether
/// a vtable-free Swift middle class is enough for an Objective-C leaf.
open class OUISwiftFinalMid: OUIProbeView {
    public final var finalMidLayouts = 0
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        finalMidLayouts += 1
        OUIProbeTrace.record("OUISwiftFinalMid.layoutSubviews")
    }
}

/// A Swift protocol whose requirement is satisfied by a header-declared
/// method (UIView's `CALayerDelegate.layoutSublayers(of:)` shape), adopted
/// by a plain extension of the @implementation class.
@MainActor
public protocol OUIProbeLayoutHost: AnyObject {
    func layoutSubviews()
    func setNeedsLayout()
}
extension OUIProbeView: OUIProbeLayoutHost {}

public extension OUIProbeLayoutHost {
    func relayout() { setNeedsLayout(); layoutSubviews() }
}
