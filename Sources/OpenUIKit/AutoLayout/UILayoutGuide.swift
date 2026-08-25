// UILayoutGuide + the safe area / layout margins / readable content model.
// Owner: autolayout module (app-compat cluster "controls2").
//
// docs/APP_COMPAT.md flags `safeAreaLayoutGuide` as the canonical example of
// "a missing MEMBER of a type we do export": every modern code-based screen
// pins to it, and until now `view.safeAreaLayoutGuide` did not compile.
//
// EVERY NUMBER AND EVERY RULE BELOW IS ORACLE-MEASURED (Mac Catalyst iOS
// 26.1, offscreen probe — the same oracle the fixtures use). The probe forces
// a root view's `safeAreaInsets` by overriding the getter and reads what real
// UIKit then computes for descendants, guides and margins.
//
// 1. SAFE-AREA PROPAGATION is PER EDGE and CLAMPED, not a rect intersection.
//    A child's inset on an edge is the parent's inset minus how far the child
//    starts inside it, floored at 0 and CAPPED AT THE PARENT'S OWN INSET:
//
//        child.top    = clamp(parent.top    - child.frame.minY, 0, parent.top)
//        child.left   = clamp(parent.left   - child.frame.minX, 0, parent.left)
//        child.bottom = clamp(child.frame.maxY - safeBottomEdge, 0, parent.bottom)
//        child.right  = clamp(child.frame.maxX - safeRightEdge,  0, parent.right)
//
//    where safeBottomEdge = parent.bounds.height - parent.bottom, and
//    likewise for the right. Nine probe frames — inside, overhanging every
//    edge, larger than the parent, entirely below the parent — all fit this
//    to the digit. Note what it is NOT: a child that lies ENTIRELY inside the
//    parent's unsafe bottom band still reports the parent's FULL bottom
//    inset (probe: child (0, 460, 320, 100) under insets (44,10,34,12) ->
//    (0, 10, 34, 12)), which a rect intersection could never produce because
//    the intersection is empty.
//
// 2. `safeAreaLayoutGuide.layoutFrame` == `bounds` inset by `safeAreaInsets`
//    (probe: 320x480 with (44,10,34,12) -> (10, 44, 298, 402)).
//
// 3. `layoutMargins` = the base margins PLUS the safe-area insets, edge by
//    edge, while `insetsLayoutMarginsFromSafeArea` is true (probe: base 8 all
//    round under safe (44,10,34,12) -> (52, 18, 42, 20)). It is a SUM, not a
//    max. With the flag off it is the base margins alone (probe: (8,8,8,8),
//    guide (8, 8, 304, 464)). UIKit's default base margin is 8 on every edge.
//
// 4. `preservesSuperviewLayoutMargins` uses the same per-edge geometry with
//    MAX instead of clamp: the superview's margin shows through where the
//    child overlaps it (probe: parent margins 20, child at (10,10,100,100)
//    in a 320x480 parent -> (10, 10, 8, 8)).
//
// 5. `readableContentGuide` IS the layout-margins guide unless TWO measured
//    conditions both hold, in which case it is a 920 pt band CENTRED in the
//    view's bounds:
//        bounds.width > 1008   AND   layoutMarginsGuide.width > 920
//    Both thresholds were bisected at 1 pt resolution. The bounds-width gate
//    is real and independent of the margins: at margins 0 the break is still
//    between 1008 and 1010 (width 1008 -> the full 1008, width 1010 -> 920
//    at x 45), and at margins 40 between 1008 and 1009 (1008 -> the margins'
//    928 at x 40, 1009 -> 920 at x 44.5). And the margins gate is real too:
//    a 1200 pt view with 200 pt margins keeps its 800 pt margins rect
//    untouched. (1008 == 920 + 2*44, i.e. the cap only engages once it can
//    leave 44 pt of gutter on each side — a plausible reading, not a
//    measured mechanism.) Vertically the guide always matches the margins
//    guide. The 920 is the value for the default body font; OpenUIKit has no
//    Dynamic Type (docs/KNOWN_GAPS.md), so it is a constant here.
//
// WHAT IS NOT MODELLED
//   * TRANSFORMS. Propagation reads `frame`, so a transformed child's safe
//     area is computed from its transformed frame rather than from UIKit's
//     untransformed layout rect. No fixture transforms a safe-area child.
//   * RTL. `leading`/`trailing` alias `left`/`right` everywhere in this
//     module, exactly as they already do in the rest of Auto Layout (M9).
//   * `UILayoutSupport` / `topLayoutGuide` / `bottomLayoutGuide` — the
//     pre-iOS-11 spelling. Deprecated in UIKit; not declared here.
//   * An UNREFERENCED user guide keeps `layoutFrame == .zero`, as in UIKit.
//     A SYSTEM guide, by contrast, always reports its frame here even if no
//     constraint mentions it (real UIKit leaves it zero until the guide
//     participates in a solve). The value we report is the one UIKit
//     converges to; only the "never asked" case differs.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


/// UIKit's directional (leading/trailing) insets. LTR only, like the rest of
/// this module, so `leading` == `left`.


public struct NSDirectionalEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat
    public init(top: CGFloat = 0, leading: CGFloat = 0,
                bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
    public static let zero = NSDirectionalEdgeInsets()
}

// MARK: - UILayoutGuide

/// A rectangle that participates in Auto Layout without being a view.
///
/// UIKit uses guides for the safe area, layout margins and readable content
/// width, and apps create their own to space views without a dummy view.
/// A guide's anchors make ordinary `NSLayoutConstraint`s, and the solver
/// gives it the same four variables a view gets — the only difference is
/// that a guide has no frame to write back to, so the solution lands in
/// ``layoutFrame`` instead.
public final class UILayoutGuide {
    /// The view whose coordinate space ``layoutFrame`` is expressed in. Set
    /// by `UIView.addLayoutGuide(_:)`.
    public internal(set) weak var owningView: UIView? {
        didSet { owningView?.setNeedsLayout() }
    }

    /// Debug name. UIKit gives its own guides names like
    /// "UIViewSafeAreaLayoutGuide"; so do we.
    public var identifier: String = ""

    /// The rectangle, in ``owningView``'s coordinate space.
    ///
    /// A SYSTEM guide computes it live from the owning view's bounds and
    /// insets, so it is correct the moment it is read (real UIKit leaves it
    /// `.zero` until the guide takes part in a solve — the documented
    /// divergence in the file header). A CUSTOM guide reports what the last
    /// solve gave it, `.zero` before that.
    public var layoutFrame: CGRect { systemFrame() ?? _solvedFrame }
    var _solvedFrame: CGRect = .zero

    /// Which system guide this is, or `.custom` for an app-created one. The
    /// solver anchors the system ones to their owning view; a custom guide is
    /// positioned entirely by the app's constraints.
    enum Kind {
        case custom
        case safeArea
        case layoutMargins
        case readableContent
        /// `UIScrollView.frameLayoutGuide` — the scroll view's own frame,
        /// expressed in its CONTENT coordinate space (so its origin is the
        /// content offset). System-anchored.
        case scrollFrame
        /// `UIScrollView.contentLayoutGuide` — origin pinned to the content
        /// origin, SIZE left free so the app's constraints determine it. The
        /// solved size is what `UIScrollView` then adopts as `contentSize`,
        /// which is the whole point of the guide.
        case scrollContent
    }
    let kind: Kind

    public init() { kind = .custom }
    init(kind: Kind, owningView: UIView) {
        self.kind = kind
        self.owningView = owningView
        switch kind {
        case .custom: identifier = ""
        case .safeArea: identifier = "UIViewSafeAreaLayoutGuide"
        case .layoutMargins: identifier = "UIViewLayoutMarginsGuide"
        case .readableContent: identifier = "UIViewReadableContentGuide"
        case .scrollFrame: identifier = "UIScrollViewFrameLayoutGuide"
        case .scrollContent: identifier = "UIScrollViewContentLayoutGuide"
        }
    }

    /// The rect a SYSTEM guide occupies in its owning view's bounds, from the
    /// measured rules in the file header. `nil` for a custom guide (its rect
    /// comes from the solver).
    func systemFrame() -> CGRect? {
        guard let v = owningView else { return nil }
        let b = v.bounds
        switch kind {
        case .custom, .scrollContent:
            return nil
        case .scrollFrame:
            return b
        case .safeArea:
            return b.inset(by: v.safeAreaInsets)
        case .layoutMargins:
            return b.inset(by: v.layoutMargins)
        case .readableContent:
            let m = b.inset(by: v.layoutMargins)
            let cap = UILayoutGuide.readableContentMaxWidth
            guard b.width > UILayoutGuide.readableContentMinBoundsWidth,
                  m.width > cap else { return m }
            return CGRect(x: b.minX + (b.width - cap) / 2,
                          y: m.minY, width: cap, height: m.height)
        }
    }

    /// Measured cap on the readable width, and the bounds width below which
    /// the cap does not apply at all (file header, rule 5).
    static let readableContentMaxWidth: CGFloat = 920
    static let readableContentMinBoundsWidth: CGFloat = 1008

    // MARK: Anchors

    public var leadingAnchor: NSLayoutXAxisAnchor { .init(guide: self, attribute: .leading) }
    public var trailingAnchor: NSLayoutXAxisAnchor { .init(guide: self, attribute: .trailing) }
    public var leftAnchor: NSLayoutXAxisAnchor { .init(guide: self, attribute: .left) }
    public var rightAnchor: NSLayoutXAxisAnchor { .init(guide: self, attribute: .right) }
    public var topAnchor: NSLayoutYAxisAnchor { .init(guide: self, attribute: .top) }
    public var bottomAnchor: NSLayoutYAxisAnchor { .init(guide: self, attribute: .bottom) }
    public var widthAnchor: NSLayoutDimension { .init(guide: self, attribute: .width) }
    public var heightAnchor: NSLayoutDimension { .init(guide: self, attribute: .height) }
    public var centerXAnchor: NSLayoutXAxisAnchor { .init(guide: self, attribute: .centerX) }
    public var centerYAnchor: NSLayoutYAxisAnchor { .init(guide: self, attribute: .centerY) }
}

extension CGRect {
    /// UIKit's `CGRect.inset(by:)`. Negative results are allowed to collapse
    /// (UIKit clamps to a zero-size rect at the inset origin).
    public func inset(by insets: UIEdgeInsets) -> CGRect {
        let w = width - insets.left - insets.right
        let h = height - insets.top - insets.bottom
        return CGRect(x: minX + insets.left, y: minY + insets.top,
                      width: max(0, w), height: max(0, h))
    }
}

// MARK: - UIView: guides, safe area, layout margins

extension UIView {
    /// The guides added with ``addLayoutGuide(_:)`` (system guides are not
    /// listed, matching UIKit).
    public var layoutGuides: [UILayoutGuide] { _customLayoutGuides }

    public func addLayoutGuide(_ guide: UILayoutGuide) {
        guide.owningView?.removeLayoutGuide(guide)
        _customLayoutGuides.append(guide)
        guide.owningView = self
        setNeedsLayout()
    }

    public func removeLayoutGuide(_ guide: UILayoutGuide) {
        _customLayoutGuides.removeAll { $0 === guide }
        guide.owningView = nil
        setNeedsLayout()
    }

    /// The area not covered by system chrome. See the file header for the
    /// measured propagation rule.
    public var safeAreaInsets: UIEdgeInsets { _safeAreaInsets }

    /// `bounds` inset by ``safeAreaInsets``.
    public var safeAreaLayoutGuide: UILayoutGuide {
        if let g = _safeAreaGuide { return g }
        let g = UILayoutGuide(kind: .safeArea, owningView: self)
        _safeAreaGuide = g
        return g
    }

    public var layoutMarginsGuide: UILayoutGuide {
        if let g = _layoutMarginsGuide { return g }
        let g = UILayoutGuide(kind: .layoutMargins, owningView: self)
        _layoutMarginsGuide = g
        return g
    }

    public var readableContentGuide: UILayoutGuide {
        if let g = _readableGuide { return g }
        let g = UILayoutGuide(kind: .readableContent, owningView: self)
        _readableGuide = g
        return g
    }

    /// UIKit's default is 8 pt on every edge, plus the safe-area insets while
    /// ``insetsLayoutMarginsFromSafeArea`` is true (file header, rule 3).
    public var layoutMargins: UIEdgeInsets {
        get {
            var m = _baseLayoutMargins
            if preservesSuperviewLayoutMargins, let sv = superview {
                let inherited = UIView._inheritedMargins(from: sv, childFrame: frame)
                m = UIEdgeInsets(top: max(m.top, inherited.top),
                                 left: max(m.left, inherited.left),
                                 bottom: max(m.bottom, inherited.bottom),
                                 right: max(m.right, inherited.right))
            }
            guard insetsLayoutMarginsFromSafeArea else { return m }
            let s = _safeAreaInsets
            return UIEdgeInsets(top: m.top + s.top, left: m.left + s.left,
                                bottom: m.bottom + s.bottom, right: m.right + s.right)
        }
        set {
            _baseLayoutMargins = newValue
            _notifyLayoutMarginsChanged()
        }
    }

    /// LTR alias of ``layoutMargins`` (no RTL — file header).
    public var directionalLayoutMargins: NSDirectionalEdgeInsets {
        get {
            let m = layoutMargins
            return NSDirectionalEdgeInsets(top: m.top, leading: m.left,
                                           bottom: m.bottom, trailing: m.right)
        }
        set {
            layoutMargins = UIEdgeInsets(top: newValue.top, left: newValue.leading,
                                         bottom: newValue.bottom, right: newValue.trailing)
        }
    }

    // MARK: Host / container hook

    /// Sets this view's OWN safe-area insets — the root of a propagation.
    /// UIKit gets them from the window server (the notch, the home indicator,
    /// the status bar); OpenUIKit has no window server, so a host, a
    /// `UIWindow` or a scene fixture supplies them. Descendants derive theirs
    /// from this by the measured rule in the file header.
    ///
    /// Underscored because it is NOT UIKit API: in UIKit `safeAreaInsets` is
    /// read-only and the only app-facing lever is
    /// `UIViewController.additionalSafeAreaInsets`, which is implemented on
    /// top of this.
    public func _setSafeAreaInsets(_ insets: UIEdgeInsets) {
        guard _ownSafeAreaInsets != insets else { return }
        _ownSafeAreaInsets = insets
        setNeedsLayout()
        _applySafeArea(insets)
    }

    /// This view's own insets, if it is a propagation root (a window, or a
    /// view a host/fixture set them on). `nil` means "inherit".
    var _safeAreaRootInsets: UIEdgeInsets? { _ownSafeAreaInsets }

    /// Recompute the safe area of this subtree, top-down. Called by
    /// `layoutIfNeeded` before and after the constraint solve (frames are an
    /// input to propagation, and the solve moves frames). Returns whether any
    /// view's insets changed, so the caller can re-solve.
    ///
    /// A view's insets are `own ?? inherited`, PLUS its managing view
    /// controller's `additionalSafeAreaInsets` — UIKit's rule, and the only
    /// app-facing way to widen a safe area.
    @discardableResult
    func _propagateSafeArea(inherited: UIEdgeInsets? = nil) -> Bool {
        let base = _ownSafeAreaInsets ?? inherited ?? .zero
        let a = _additionalSafeAreaInsets
        let mine = a == .zero ? base
            : UIEdgeInsets(top: base.top + a.top, left: base.left + a.left,
                           bottom: base.bottom + a.bottom, right: base.right + a.right)
        var changed = false
        if mine != _safeAreaInsets {
            _applySafeArea(mine)
            changed = true
        }
        let b = bounds
        for sub in subviews {
            let derived = UIView._derivedSafeArea(parentInsets: mine,
                                                  parentBounds: b,
                                                  childFrame: sub.frame)
            if sub._propagateSafeArea(inherited: derived) { changed = true }
        }
        return changed
    }

    private func _applySafeArea(_ insets: UIEdgeInsets) {
        guard insets != _safeAreaInsets else { return }
        let marginsMoved = insetsLayoutMarginsFromSafeArea
        _safeAreaInsets = insets
        setNeedsLayout()
        // Measured ordering: UIKit delivers layoutMarginsDidChange BEFORE
        // safeAreaInsetsDidChange when a safe-area change moves the margins.
        if marginsMoved { layoutMarginsDidChange() }
        safeAreaInsetsDidChange()
    }

    func _notifyLayoutMarginsChanged() {
        setNeedsLayout()
        layoutMarginsDidChange()
        for sub in subviews where sub.preservesSuperviewLayoutMargins {
            sub._notifyLayoutMarginsChanged()
        }
    }

    /// The measured per-edge clamp (file header, rule 1). `childFrame` is in
    /// the parent's BOUNDS space.
    static func _derivedSafeArea(parentInsets p: UIEdgeInsets,
                                 parentBounds b: CGRect,
                                 childFrame f: CGRect) -> UIEdgeInsets {
        func clamp(_ v: CGFloat, _ cap: CGFloat) -> CGFloat {
            min(max(v, 0), cap)
        }
        let safeBottomEdge = b.maxY - p.bottom
        let safeRightEdge = b.maxX - p.right
        return UIEdgeInsets(top: clamp(b.minY + p.top - f.minY, p.top),
                            left: clamp(b.minX + p.left - f.minX, p.left),
                            bottom: clamp(f.maxY - safeBottomEdge, p.bottom),
                            right: clamp(f.maxX - safeRightEdge, p.right))
    }

    /// The same geometry with MAX instead of clamp — what
    /// `preservesSuperviewLayoutMargins` inherits (file header, rule 4).
    static func _inheritedMargins(from sv: UIView, childFrame f: CGRect) -> UIEdgeInsets {
        let m = sv.layoutMargins
        let b = sv.bounds
        return UIEdgeInsets(top: max(0, b.minY + m.top - f.minY),
                            left: max(0, b.minX + m.left - f.minX),
                            bottom: max(0, f.maxY - (b.maxY - m.bottom)),
                            right: max(0, f.maxX - (b.maxX - m.right)))
    }

}
