// UIView + CALayer facade. Owner: view module.
// SKELETON — structure is in place; rendering (RenderPass.swift), autoresizing
// and layout behaviors must be completed and verified against goldens.

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
    // Shadow (spec v2) — CALayer defaults: opaque black, opacity 0 (off),
    // offset (0, -3) (up, in iOS's top-left geometry), radius 3.
    // Invisible while masksToBounds is true, like CoreAnimation.
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

    /// Animations recorded by UIView.animate blocks (M6). LayerBridge
    /// samples these at OpenUIKitRuntime.animationTime to build the
    /// presentation layer tree; the stored properties above are the MODEL.
    var animations: [UIViewAnimation] = []

    // MARK: Layer-contents caching (M8 perf — see LayerBridge.swift)

    /// Monotone version of this view's CUSTOM drawn content (drawContent).
    /// OpenUIKit's own content views (UILabel, UISwitch, …) are fingerprinted
    /// property-by-property by LayerBridge; a custom view outside OpenUIKit
    /// that draws state in `drawContent` must call `setNeedsDisplay()` when
    /// that state changes (the same contract as real UIKit) or cached layer
    /// contents may go stale.
    var contentVersion: UInt64 = 0

    /// Mark this view's custom-drawn content as needing a redraw (UIKit
    /// semantics). Cheap: bumps a version consumed by the render caches.
    public func setNeedsDisplay() { contentVersion &+= 1 }

    /// LayerBridge's per-view cache storage (content image, subtree
    /// composite, fingerprint stability). Opaque here to keep the view
    /// model free of compositor types.
    var _layerCacheState: AnyObject?

    public var frame: CGRect {
        get {
            if transform.isIdentity {
                return CGRect(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2,
                              width: bounds.width, height: bounds.height)
            }
            // bbox of bounds transformed about center
            let half = CGRect(x: -bounds.width / 2, y: -bounds.height / 2,
                              width: bounds.width, height: bounds.height)
            let bbox = half.applying(transform)
            return bbox.offsetBy(dx: center.x, dy: center.y)
        }
        set {
            // Matches UIKit: setting frame with non-identity transform is
            // undefined-ish; we set bounds size and center from the rect.
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
    /// Hit-testing / touch delivery opt-out. UIKit defaults: true for
    /// UIView/controls, false for UILabel and UIImageView.
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

    // MARK: Auto Layout (M9 — autolayout module, AutoLayout/*.swift)

    /// UIKit semantics: while true, the view's frame is authoritative and
    /// enters the solver as required left/top/width/height constraints;
    /// constraint-positioned views set this to false.
    public var translatesAutoresizingMaskIntoConstraints = true
    /// Constraints installed on this view (nearest common ancestor of their
    /// items). Managed by NSLayoutConstraint.activate/deactivate.
    var _installedConstraints: [NSLayoutConstraint] = []
    var _huggingH: UILayoutPriority = .defaultLow
    var _huggingV: UILayoutPriority = .defaultLow
    var _compressionH: UILayoutPriority = .defaultHigh
    var _compressionV: UILayoutPriority = .defaultHigh

    // MARK: Layout guides / safe area (app-compat cluster; the measured
    // model lives in AutoLayout/UILayoutGuide.swift, which owns every rule
    // and every constant. Only the STORAGE is here — Swift extensions cannot
    // add stored properties.)

    var _customLayoutGuides: [UILayoutGuide] = []
    var _safeAreaGuide: UILayoutGuide?
    var _layoutMarginsGuide: UILayoutGuide?
    var _readableGuide: UILayoutGuide?
    /// Derived by propagation from the nearest ancestor that has its own.
    var _safeAreaInsets: UIEdgeInsets = .zero
    /// Set by `_setSafeAreaInsets(_:)` — this view is a propagation ROOT.
    var _ownSafeAreaInsets: UIEdgeInsets?
    /// `UIViewController.additionalSafeAreaInsets` of the controller managing
    /// this view, added on top of the inherited insets.
    var _additionalSafeAreaInsets: UIEdgeInsets = .zero
    /// UIKit's default base margins: 8 pt on every edge.
    var _baseLayoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    /// UIKit default true: `layoutMargins` = base + `safeAreaInsets`.
    public var insetsLayoutMarginsFromSafeArea = true {
        didSet { if insetsLayoutMarginsFromSafeArea != oldValue { _notifyLayoutMarginsChanged() } }
    }
    /// UIKit default false: inherit the superview's margins where they
    /// overlap this view.
    public var preservesSuperviewLayoutMargins = false {
        didSet { if preservesSuperviewLayoutMargins != oldValue { _notifyLayoutMarginsChanged() } }
    }

    /// Called after ``safeAreaInsets`` changes. Override to react; the
    /// default does nothing, like UIKit's. (Declared in the class body, not
    /// the guide extension: a non-@objc extension method cannot be
    /// overridden.)
    open func safeAreaInsetsDidChange() {}

    /// Called after ``layoutMargins`` changes.
    open func layoutMarginsDidChange() {}

    /// Baseline offsets for firstBaseline/lastBaseline constraint attributes:
    /// (first baseline from the view's top, last baseline from its bottom).
    /// nil (plain views): both baselines alias the bottom edge, like UIKit.
    /// UILabel overrides (text module hook).
    func _constraintBaselines() -> (firstFromTop: CGFloat, lastFromBottom: CGFloat)? {
        nil
    }

    /// Trait override; `.unspecified` inherits from superview / current.
    public var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified
    public var tintColor: UIColor! {
        get { _tintColor ?? superview?.tintColor ?? .systemBlue }
        set { _tintColor = newValue }
    }
    var _tintColor: UIColor?

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
        // Auto Layout (M9): solve constraints for the whole hierarchy first
        // (UIKit solves in the window/root space before layoutSubviews).
        // No-op (one integer compare) when no constraints are installed.
        var top: UIView = self
        while let sv = top.superview { top = sv }
        // Safe area is a layout INPUT (it is derived from frames) and also a
        // layout OUTPUT (guides move views). UIKit resolves that by treating
        // the previous pass's safe area as this pass's input; we iterate
        // twice, which converges for every hierarchy a fixture or an app
        // builds. See AutoLayout/UILayoutGuide.swift.
        top._propagateSafeArea()
        LayoutEngine.solveIfNeeded(root: top)
        if top._propagateSafeArea() {
            LayoutEngine.solveIfNeeded(root: top)
        }
        // Layout entire subtree (top-down), like a simplified layout pass.
        _layoutSubtree()
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
        // UIKit autoresizing-mask distribution. For each axis the frame is
        // split into three components (leading margin, size, trailing margin).
        // The size delta of the superview is distributed among the FLEXIBLE
        // components proportionally to their current magnitudes; fixed
        // components never change. If every flexible component is zero, the
        // delta is split equally between them. No flexible components => the
        // child's frame is left untouched.
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

    /// One-axis autoresizing distribution. Returns (newOrigin, newLength).
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
            // All flexible components are zero: split the delta equally.
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
    open var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    public static let noIntrinsicMetric: CGFloat = -1
    public func sizeToFit() {
        // Real UIKit passes the CURRENT bounds size to sizeThatFits (a
        // multiline label with frame width 200 wraps at 200 — verified
        // against golden label_multiline). Contract fix by the text module.
        let s = sizeThatFits(bounds.size)
        let origin = frame.origin
        frame = CGRect(origin: origin, size: s)
    }

    // MARK: Coordinate conversion (event module, M7)

    /// Transform mapping this view's bounds coordinates to its superview's
    /// bounds coordinates: p_super = center + transform · (p − boundsMid).
    /// (Anchor point (0.5, 0.5): the middle of the bounds rect maps to
    /// `center`; bounds.origin shifts the content, hence the mid offset.)
    var _toSuperview: CGAffineTransform {
        CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
            .concatenating(transform)
            .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
    }

    /// Accumulated transform from this view's coordinates to the coordinates
    /// of the hierarchy's root (the view with no superview), plus that root.
    func _transformToRoot() -> (CGAffineTransform, UIView) {
        var t = CGAffineTransform.identity
        var v: UIView = self
        while let sv = v.superview {
            t = t.concatenating(v._toSuperview)
            v = sv
        }
        return (t, v)
    }

    /// Convert a point from this view's coordinate system to `view`'s.
    /// nil = the root of this view's hierarchy (window/root coordinates),
    /// matching UIKit's nil-window behavior.
    public func convert(_ point: CGPoint, to view: UIView?) -> CGPoint {
        let (t, _) = _transformToRoot()
        let inRoot = point.applying(t)
        guard let view else { return inRoot }
        let (t2, _) = view._transformToRoot()
        return inRoot.applying(t2.inverted())
    }

    /// Convert a point from `view`'s coordinate system to this view's.
    public func convert(_ point: CGPoint, from view: UIView?) -> CGPoint {
        if let view { return view.convert(point, to: self) }
        let (t, _) = _transformToRoot()
        return point.applying(t.inverted())
    }

    // MARK: Hit testing (event module, M7 — exact UIKit semantics)

    /// CGRectContainsPoint(bounds, point): min-edge inclusive, max-edge
    /// exclusive.
    open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }

    /// UIKit recursion: a view is only reachable if EVERY ancestor on the
    /// path passes its own point(inside:) — subviews outside the parent's
    /// bounds are unreachable regardless of clipsToBounds (clipping is
    /// visual only, oracle-verified). Skips hidden views, alpha < 0.01 and
    /// disabled interaction (each prunes its whole subtree); subviews are
    /// tested front-to-back (reverse array order).
    open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else { return nil }
        guard self.point(inside: point, with: event) else { return nil }
        for sub in subviews.reversed() {
            if let hit = sub.hitTest(sub.convert(point, from: self), with: event) {
                return hit
            }
        }
        return self
    }

    // MARK: Touch handling (UIResponder subset — event module, M7)

    /// Gesture recognizers attached to this view (nil when none, like UIKit).
    public var gestureRecognizers: [UIGestureRecognizer]? {
        _gestureRecognizers.isEmpty ? nil : _gestureRecognizers
    }
    var _gestureRecognizers: [UIGestureRecognizer] = []

    /// Interactions attached to this view (M13 — `addInteraction(_:)` and
    /// the rest live in UIContextMenu.swift, which owns the protocol).
    var _interactions: [UIInteraction] = []

    public func addGestureRecognizer(_ recognizer: UIGestureRecognizer) {
        recognizer.view?.removeGestureRecognizer(recognizer)
        recognizer.view = self
        _gestureRecognizers.append(recognizer)
    }

    public func removeGestureRecognizer(_ recognizer: UIGestureRecognizer) {
        guard recognizer.view === self else { return }
        _gestureRecognizers.removeAll { $0 === recognizer }
        recognizer.view = nil
    }

    // (The UIResponder touch entry points — touchesBegan/Moved/Ended/
    // Cancelled — now live on UIResponder, where UIKit puts them, and their
    // default forwards up the responder chain. See UIResponder.swift.)

    // MARK: Responder chain (lifecycle module, M12)

    /// The view controller whose ROOT view this is, if any. Set by
    /// UIViewController when it takes ownership of a view; the one hop that
    /// makes the responder chain pass through view controllers.
    weak var _managingViewController: UIViewController?

    /// UIKit: a view's next responder is the view controller it is the root
    /// view of, otherwise its superview.
    open override var next: UIResponder? {
        if let vc = _managingViewController, vc.viewIfLoaded === self { return vc }
        return superview
    }

    // MARK: First responder (text-input module, M8; storage moved to
    // UIResponder in M12 — the become/resign behavior is unchanged)

    /// The UIWindow at the root of this view's superview chain, if any.
    public var window: UIWindow? {
        var v: UIView? = self
        while let cur = v {
            if let w = cur as? UIWindow { return w }
            v = cur.superview
        }
        return nil
    }

    /// A view can only hold focus while it is installed in a window — the
    /// rule that makes `becomeFirstResponder()` fail on a detached view.
    override var _firstResponderWindow: UIWindow? { window }

    // MARK: Rendering (view module: RenderPass.swift implements)
    /// Draw this view's own content (background is handled by the render
    /// pass; subclasses draw text/images/chrome here).
    ///
    /// The base implementation is the bridge to UIKit's app-facing drawing
    /// API: it makes `canvas` the current graphics context and calls
    /// `draw(_ rect:)`, so an app subclass that overrides `draw(_:)` — with
    /// `UIBezierPath`, `UIColor.setFill()`, `UIGraphicsGetCurrentContext()`
    /// — renders through the normal content path (and the layer-contents
    /// cache, invalidated by `setNeedsDisplay()`). OpenUIKit's own content
    /// views override `drawContent` directly and never pay for this.
    open func drawContent(in canvas: Canvas, bounds: CGRect) {
        UIGraphics.pushContext(canvas)
        draw(bounds)
        UIGraphics.popContext()
    }

    /// UIKit's app-side drawing hook. Override to draw the view's content
    /// with `UIBezierPath` / `UIGraphicsGetCurrentContext()`; call
    /// `setNeedsDisplay()` when the drawing inputs change. `rect` is the
    /// view's bounds (OpenUIKit always redraws the whole view).
    open func draw(_ rect: CGRect) {}
}
