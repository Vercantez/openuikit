// UIView + CALayer facade.
// VENDOR-EDIT (swift-macho-linux slice): trimmed from ~/uikit's UIView.swift.
// KEPT VERBATIM: every property and code path RenderPass.renderView reads to
// composite a static tree -- geometry (center/bounds/transform/frame),
// superview/subviews, CALayer (cornerRadius/border*/masksToBounds/shadow*),
// backgroundColor, alpha, isHidden, clipsToBounds, traitCollection, hierarchy
// mutators. REMOVED: Auto Layout constraints, safe area / layout guides /
// margins, trait-change registrations, gesture recognizers, interactions,
// managing view controller, window/first-responder, coordinate conversion,
// hit-testing, and the UIGraphics `draw(_:)` bridge -- none are on the
// boxes_basic / corner_radius render path. drawContent is the no-op it is for a
// plain UIView (custom drawing subclasses are out of this slice's scope).

public struct UIRectEdge: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}

public enum UIViewContentMode: Sendable {
    case scaleToFill, scaleAspectFit, scaleAspectFill, redraw, center
    case top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
}

/// Minimal CALayer facade: UIKit-visible layer properties live here.
public final class CALayer {
    public weak var owner: UIView?
    public var cornerRadius: CGFloat = 0 {
        didSet {
            if cornerRadius != oldValue {
                owner?.recordAnimation(.cornerRadius, from: .scalar(oldValue),
                                       to: .scalar(cornerRadius))
            }
        }
    }
    public var borderWidth: CGFloat = 0
    public var borderColor: CGColor? = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var masksToBounds: Bool = false
    public var shadowColor: CGColor? = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var shadowOpacity: Float = 0
    public var shadowOffset: CGSize = CGSize(width: 0, height: -3)
    public var shadowRadius: CGFloat = 3
    init(owner: UIView) { self.owner = owner }
}

open class UIView: UIResponder {
    // Geometry: center/bounds/transform are source of truth (like real UIKit).
    public var center: CGPoint = .zero {
        didSet {
            if center != oldValue {
                recordAnimation(.position, from: .point(oldValue), to: .point(center))
            }
        }
    }
    public var bounds: CGRect = .zero {
        didSet {
            if bounds != oldValue {
                recordAnimation(.bounds, from: .rect(oldValue), to: .rect(bounds))
            }
            if oldValue.size != bounds.size {
                setNeedsLayout()
                _autoresizeChildren(oldSize: oldValue.size)
            }
        }
    }
    public var transform: CGAffineTransform = .identity {
        didSet {
            if transform != oldValue {
                recordAnimation(.transform, from: .transform(oldValue),
                                to: .transform(transform))
            }
        }
    }

    /// Animations recorded by UIView.animate blocks. Unused by the static
    /// render pass (it draws MODEL values); kept as storage recordAnimation
    /// appends to.
    var animations: [UIViewAnimation] = []

    public func setNeedsDisplay() { }

    public var frame: CGRect {
        get {
            if transform.isIdentity {
                return CGRect(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2,
                              width: bounds.width, height: bounds.height)
            }
            let half = CGRect(x: -bounds.width / 2, y: -bounds.height / 2,
                              width: bounds.width, height: bounds.height)
            let bbox = half.applying(transform)
            return bbox.offsetBy(dx: center.x, dy: center.y)
        }
        set {
            bounds.size = newValue.size
            center = CGPoint(x: newValue.origin.x + newValue.width / 2,
                             y: newValue.origin.y + newValue.height / 2)
        }
    }

    public internal(set) var superview: UIView?
    public internal(set) var subviews: [UIView] = []
    public private(set) lazy var layer = CALayer(owner: self)

    public var backgroundColor: UIColor? {
        didSet {
            if backgroundColor != oldValue {
                recordAnimation(.backgroundColor, from: .color(oldValue),
                                to: .color(backgroundColor))
            }
        }
    }
    public var alpha: CGFloat = 1 {
        didSet {
            if alpha != oldValue {
                recordAnimation(.alpha, from: .scalar(oldValue), to: .scalar(alpha))
            }
        }
    }
    public var isHidden = false
    public var isOpaque = true
    public var isUserInteractionEnabled = true
    public var clipsToBounds: Bool {
        get { layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }
    public var contentMode: UIViewContentMode = .scaleToFill
    public var tag: Int = 0

    public struct AutoresizingMask: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let flexibleLeftMargin = AutoresizingMask(rawValue: 1 << 0)
        public static let flexibleWidth = AutoresizingMask(rawValue: 1 << 1)
        public static let flexibleRightMargin = AutoresizingMask(rawValue: 1 << 2)
        public static let flexibleTopMargin = AutoresizingMask(rawValue: 1 << 3)
        public static let flexibleHeight = AutoresizingMask(rawValue: 1 << 4)
        public static let flexibleBottomMargin = AutoresizingMask(rawValue: 1 << 5)
    }
    public var autoresizingMask: AutoresizingMask = []
    public var autoresizesSubviews = true

    /// Trait override; `.unspecified` inherits from superview / current.
    public var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified

    public init(frame: CGRect = .zero) {
        super.init()
        self.frame = frame
    }

    // MARK: Hierarchy
    public func addSubview(_ view: UIView) {
        view.removeFromSuperview()
        view.superview = self
        subviews.append(view)
        setNeedsLayout()
    }
    public func insertSubview(_ view: UIView, at index: Int) {
        view.removeFromSuperview()
        view.superview = self
        subviews.insert(view, at: index)
        setNeedsLayout()
    }
    public func removeFromSuperview() {
        guard let sv = superview else { return }
        sv.subviews.removeAll { $0 === self }
        superview = nil
    }
    public func bringSubviewToFront(_ view: UIView) {
        guard let i = subviews.firstIndex(where: { $0 === view }) else { return }
        subviews.remove(at: i)
        subviews.append(view)
    }
    public func sendSubviewToBack(_ view: UIView) {
        guard let i = subviews.firstIndex(where: { $0 === view }) else { return }
        subviews.remove(at: i)
        subviews.insert(view, at: 0)
    }

    // MARK: Traits
    public var traitCollection: UITraitCollection {
        var t = superview?.traitCollection ?? UITraitCollection.current
        if overrideUserInterfaceStyle != .unspecified {
            t.userInterfaceStyle = overrideUserInterfaceStyle
        }
        return t
    }

    // MARK: Layout
    var needsLayout = true
    public func setNeedsLayout() { needsLayout = true }
    public func layoutIfNeeded() {
        var top: UIView = self
        while let sv = top.superview { top = sv }
        top._layoutSubtree()
    }
    func _layoutSubtree() {
        if needsLayout {
            layoutSubviews()
            needsLayout = false
        }
        for s in subviews { s._layoutSubtree() }
    }
    open func layoutSubviews() {}

    func _autoresizeChildren(oldSize: CGSize) {
        guard autoresizesSubviews else { return }
        let newSize = bounds.size
        let dw = newSize.width - oldSize.width
        let dh = newSize.height - oldSize.height
        if dw == 0 && dh == 0 { return }
        for sub in subviews {
            let mask = sub.autoresizingMask
            if mask.isEmpty { continue }
            var f = sub.frame
            (f.origin.x, f.size.width) = UIView._autoresizeAxis(
                origin: f.origin.x, length: f.size.width,
                oldParent: oldSize.width, delta: dw,
                flexLead: mask.contains(.flexibleLeftMargin),
                flexSize: mask.contains(.flexibleWidth),
                flexTrail: mask.contains(.flexibleRightMargin))
            (f.origin.y, f.size.height) = UIView._autoresizeAxis(
                origin: f.origin.y, length: f.size.height,
                oldParent: oldSize.height, delta: dh,
                flexLead: mask.contains(.flexibleTopMargin),
                flexSize: mask.contains(.flexibleHeight),
                flexTrail: mask.contains(.flexibleBottomMargin))
            sub.frame = f
        }
    }

    static func _autoresizeAxis(origin: CGFloat, length: CGFloat,
                                oldParent: CGFloat, delta: CGFloat,
                                flexLead: Bool, flexSize: Bool,
                                flexTrail: Bool) -> (CGFloat, CGFloat) {
        if delta == 0 { return (origin, length) }
        if !flexLead && !flexSize && !flexTrail { return (origin, length) }
        let lead = origin
        let trail = oldParent - origin - length
        var total: CGFloat = 0
        var count = 0
        if flexLead { total += lead; count += 1 }
        if flexSize { total += length; count += 1 }
        if flexTrail { total += trail; count += 1 }
        var dLead: CGFloat = 0
        var dSize: CGFloat = 0
        if total == 0 {
            let each = delta / CGFloat(count)
            if flexLead { dLead = each }
            if flexSize { dSize = each }
        } else {
            if flexLead { dLead = delta * lead / total }
            if flexSize { dSize = delta * length / total }
        }
        return (origin + dLead, length + dSize)
    }

    // MARK: Sizing
    open func sizeThatFits(_ size: CGSize) -> CGSize { bounds.size }
    public static let noIntrinsicMetric: CGFloat = -1
    public func sizeToFit() {
        let s = sizeThatFits(bounds.size)
        let origin = frame.origin
        frame = CGRect(origin: origin, size: s)
    }

    // MARK: Rendering
    /// Draw this view's own content. A plain UIView draws nothing; custom
    /// drawing subclasses are out of this render slice's scope.
    open func drawContent(in canvas: Canvas, bounds: CGRect) {}
}
