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
    public var cornerRadius: CGFloat = 0
    public var borderWidth: CGFloat = 0
    public var borderColor: CGColor? = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var masksToBounds: Bool = false
    init(owner: UIView) { self.owner = owner }
}

open class UIView {
    // Geometry: center/bounds/transform are source of truth (like real UIKit).
    public var center: CGPoint = .zero
    public var bounds: CGRect = .zero {
        didSet {
            if oldValue.size != bounds.size {
                setNeedsLayout()
                _autoresizeChildren(oldSize: oldValue.size)
            }
        }
    }
    public var transform: CGAffineTransform = .identity

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

    public var backgroundColor: UIColor?
    public var alpha: CGFloat = 1
    public var isHidden = false
    public var isOpaque = true
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
    public var tintColor: UIColor! {
        get { _tintColor ?? superview?.tintColor ?? .systemBlue }
        set { _tintColor = newValue }
    }
    var _tintColor: UIColor?

    public init(frame: CGRect = .zero) {
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
        // view module: implement UIKit autoresizing-mask distribution.
    }

    // MARK: Sizing
    open func sizeThatFits(_ size: CGSize) -> CGSize { bounds.size }
    open var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    public static let noIntrinsicMetric: CGFloat = -1
    public func sizeToFit() {
        let s = sizeThatFits(CGSize(width: .greatestFiniteMagnitude,
                                    height: .greatestFiniteMagnitude))
        let origin = frame.origin
        frame = CGRect(origin: origin, size: s)
    }

    // MARK: Rendering (view module: RenderPass.swift implements)
    /// Draw this view's own content (background is handled by the render
    /// pass; subclasses draw text/images/chrome here).
    open func drawContent(in canvas: Canvas, bounds: CGRect) {}
}
