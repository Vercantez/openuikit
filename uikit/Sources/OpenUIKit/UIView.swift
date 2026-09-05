// UIView + CALayer facade. Owner: view module.
// SKELETON — structure is in place; rendering (RenderPass.swift), autoresizing
// and layout behaviors must be completed and verified against goldens.

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

// A scoped Foundation declaration makes a conditional `@objc` member legal
// in ordinary Darwin builds without importing the umbrella (and its colliding
// geometry declarations) into this file. Foundation-hidden Mach-O cross
// builds instead use the production
// `-disable-objc-attr-requires-foundation-module` frontend setting.
#if canImport(ObjectiveC) && canImport(Foundation)
import struct Foundation.Data
#endif


public struct UIRectEdge: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}

/// The corners affected by `CALayer.cornerRadius`.
///
/// Core Animation names corners in the layer's local coordinate system.
/// UIView backing layers are not geometry-flipped, so minY is the visual top
/// in OpenUIKit's UIKit-style, top-left coordinate space.
public struct CACornerMask: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let layerMinXMinYCorner = CACornerMask(rawValue: 1 << 0)
    public static let layerMaxXMinYCorner = CACornerMask(rawValue: 1 << 1)
    public static let layerMinXMaxYCorner = CACornerMask(rawValue: 1 << 2)
    public static let layerMaxXMaxYCorner = CACornerMask(rawValue: 1 << 3)

    public static let _allKnown: CACornerMask = [
        .layerMinXMinYCorner, .layerMaxXMinYCorner,
        .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
    ]
}

public enum UIViewContentMode: Sendable {
    case scaleToFill, scaleAspectFit, scaleAspectFill, redraw, center
    case top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
}

/// Class-only subset of QuartzCore's layer delegate used for layout. Core
/// Animation makes this callback optional; a default implementation gives
/// portable Swift delegates the same adopt-only-what-you-use ergonomics.
@preconcurrency @MainActor
public protocol CALayerDelegate: AnyObject {
    func layoutSublayers(of layer: CALayer)
}

public extension CALayerDelegate {
    func layoutSublayers(of layer: CALayer) {}
}

/// Portable CALayer subset. A UIView's backing layer forwards its geometry
/// to the view; layers created directly keep independent geometry and can be
/// attached as an explicit layer tree.  Rendering lives in RenderPass.swift
/// (and LayerBridge.swift for the quartz compositor).
@preconcurrency @MainActor
open class CALayer {
    public weak var owner: UIView?
    public weak var delegate: CALayerDelegate?

    private var storedBounds: CGRect = .zero
    private var storedPosition: CGPoint = .zero
    private var storedAnchorPoint = CGPoint(x: 0.5, y: 0.5)
    private var storedSublayers: [CALayer] = []
    private var storedBackgroundColor: CGColor?
    private var storedOpacity: Float = 1
    private var storedHidden = false
    private var storedMask: CALayer?
    private weak var maskOwner: CALayer?
    private var storedCompatibilityValues: [String: Any] = [:]
    private var _needsLayout = true
    private var _isLayingOut = false
    /// Core Animation records live in `CoreAnimation.swift`. They are kept on
    /// the portable layer rather than the transient QZLayer built for one
    /// frame, so rebuilding the renderer tree does not restart animations.
    var _explicitAnimations: [_CALayerAnimationRecord] = []

    /// Geometry follows Core Animation's bounds/position/anchor model.
    /// A backing layer mirrors its UIView so existing view geometry remains
    /// the single source of truth.
    public var bounds: CGRect {
        get { owner?.bounds ?? storedBounds }
        set {
            if let owner { owner.bounds = newValue }
            else if storedBounds != newValue {
                _recordImplicitAnimation(keyPath: "bounds", from: storedBounds,
                                         to: newValue)
                storedBounds = newValue
                _setNeedsLayoutFromMutation()
                superlayer?._setNeedsLayoutFromMutation()
            }
        }
    }
    public var position: CGPoint {
        get { owner?.center ?? storedPosition }
        set {
            if let owner { owner.center = newValue }
            else if storedPosition != newValue {
                _recordImplicitAnimation(keyPath: "position", from: storedPosition,
                                         to: newValue)
                storedPosition = newValue
            }
        }
    }
    public var anchorPoint: CGPoint {
        get { storedAnchorPoint }
        set {
            if storedAnchorPoint != newValue {
                _recordImplicitAnimation(keyPath: "anchorPoint",
                                         from: storedAnchorPoint, to: newValue)
                storedAnchorPoint = newValue
            }
        }
    }
    public var frame: CGRect {
        get {
            if let owner { return owner.frame }
            return CGRect(x: position.x - anchorPoint.x * bounds.width,
                          y: position.y - anchorPoint.y * bounds.height,
                          width: bounds.width, height: bounds.height)
        }
        set {
            if let owner {
                owner.frame = newValue
                return
            }
            let oldBounds = storedBounds
            let oldPosition = storedPosition
            storedBounds.size = newValue.size
            storedPosition = CGPoint(x: newValue.minX + anchorPoint.x * newValue.width,
                                     y: newValue.minY + anchorPoint.y * newValue.height)
            if storedBounds != oldBounds || storedPosition != oldPosition {
                if storedBounds != oldBounds {
                    _recordImplicitAnimation(keyPath: "bounds", from: oldBounds,
                                             to: storedBounds)
                }
                if storedPosition != oldPosition {
                    _recordImplicitAnimation(keyPath: "position", from: oldPosition,
                                             to: storedPosition)
                }
                _setNeedsLayoutFromMutation()
                superlayer?._setNeedsLayoutFromMutation()
            }
        }
    }

    /// Explicit Core Animation children. UIKit exposes nil, rather than an
    /// empty array, when a layer has no children.
    public var sublayers: [CALayer]? {
        get { storedSublayers.isEmpty ? nil : storedSublayers }
        set {
            for child in storedSublayers where child.superlayer === self {
                child.superlayer = nil
            }
            storedSublayers.removeAll(keepingCapacity: true)
            for child in newValue ?? [] { _insertSublayer(child, at: storedSublayers.count) }
            _setNeedsLayoutFromMutation()
        }
    }
    public private(set) weak var superlayer: CALayer?

    /// The exact ordered storage used by the render pipelines (unlike the
    /// public UIKit-shaped optional, this never allocates an Optional array).
    var _orderedSublayers: [CALayer] { storedSublayers }

    public func addSublayer(_ layer: CALayer) {
        _insertSublayer(layer, at: storedSublayers.count)
    }

    public func insertSublayer(_ layer: CALayer, at index: UInt32) {
        _insertSublayer(layer, at: Swift.min(Int(index), storedSublayers.count))
    }

    private func _insertSublayer(_ layer: CALayer, at index: Int) {
        // Reject self and ancestor insertion. Without this guard a malformed
        // graph would recurse forever in both render pipelines.
        var ancestor: CALayer? = self
        while let candidate = ancestor {
            if candidate === layer { return }
            ancestor = candidate.superlayer
        }
        if let owner = layer.maskOwner {
            owner.storedMask = nil
            layer.maskOwner = nil
        }
        layer.removeFromSuperlayer()
        layer.superlayer = self
        storedSublayers.insert(layer, at: Swift.max(0, Swift.min(index, storedSublayers.count)))
        _setNeedsLayoutFromMutation()
    }

    public func removeFromSuperlayer() {
        guard let parent = superlayer else { return }
        parent.storedSublayers.removeAll { $0 === self }
        superlayer = nil
        parent._setNeedsLayoutFromMutation()
    }

    public var backgroundColor: CGColor? {
        get {
            if let owner {
                return owner.backgroundColor?.resolvedCGColor(with: owner.traitCollection)
            }
            return storedBackgroundColor
        }
        set {
            if let owner {
                owner.backgroundColor = newValue.map {
                    UIColor(red: $0.red, green: $0.green, blue: $0.blue, alpha: $0.alpha)
                }
            } else {
                storedBackgroundColor = newValue
            }
        }
    }
    public var opacity: Float {
        get { owner.map { Float($0.alpha) } ?? storedOpacity }
        set {
            if let owner { owner.alpha = CGFloat(newValue) }
            else { storedOpacity = newValue }
        }
    }
    public var isHidden: Bool {
        get { owner?.isHidden ?? storedHidden }
        set {
            if let owner { owner.isHidden = newValue }
            else { storedHidden = newValue }
        }
    }
    public var cornerRadius: CGFloat = 0 {
        didSet {
            if cornerRadius != oldValue {
                owner?.recordAnimation(.cornerRadius, from: .scalar(oldValue),
                                       to: .scalar(cornerRadius))
            }
        }
    }
    private var storedMaskedCorners: CACornerMask = ._allKnown
    /// Selects which corners receive `cornerRadius`. Unknown raw-value bits
    /// are discarded, matching iOS 26 Core Animation.
    public var maskedCorners: CACornerMask {
        get { storedMaskedCorners }
        set { storedMaskedCorners = newValue.intersection(._allKnown) }
    }
    public var borderWidth: CGFloat = 0 {
        didSet {
            if borderWidth != oldValue {
                _recordImplicitAnimation(keyPath: "borderWidth",
                                         from: oldValue, to: borderWidth)
            }
        }
    }
    public var borderColor: CGColor? = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var masksToBounds: Bool = false
    /// Core Animation's opaque-content optimization hint. It does not alter
    /// composited pixels by itself; renderers may use it to skip alpha work
    /// once they can prove the layer's contents are opaque.
    public var isOpaque: Bool = false
    /// Scale of the layer's backing contents. OpenUIKit's UIView renderer
    /// derives its raster scale from the host surface, but this public state
    /// is retained because app and framework code configures it directly.
    public var contentsScale: CGFloat = 1
    /// Filters attached to this exact layer identity. QuartzCore's portable
    /// module re-exports CALayer rather than wrapping it, so assignments made
    /// through either module spelling reach this single storage location.
    public var filters: [Any]?
    /// An alpha mask is retained by the receiving layer but is not a
    /// sublayer. The CQuartz compositor renders its full layer tree into an
    /// alpha surface, matching Core Animation's ownership and paint model.
    public var mask: CALayer? {
        get { storedMask }
        set {
            guard newValue !== self, storedMask !== newValue else { return }
            let oldMask = storedMask
            storedMask = nil
            oldMask?.maskOwner = nil

            if let previousOwner = newValue?.maskOwner {
                previousOwner.storedMask = nil
            }
            newValue?.removeFromSuperlayer()
            storedMask = newValue
            newValue?.maskOwner = self
        }
    }
    /// Core Animation treats this as a rendering-policy hint; it does not
    /// alter pixels or scheduling, which is also true for this deterministic
    /// software renderer.
    public var drawsAsynchronously: Bool = false
    // Shadow (spec v2) — CALayer defaults: opaque black, opacity 0 (off),
    // offset (0, -3) (up, in iOS's top-left geometry), radius 3.
    // Invisible while masksToBounds is true, like CoreAnimation.
    public var shadowColor: CGColor? = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var shadowOpacity: Float = 0 {
        didSet {
            if shadowOpacity != oldValue {
                _recordImplicitAnimation(keyPath: "shadowOpacity",
                                         from: oldValue, to: shadowOpacity)
            }
        }
    }
    public var shadowOffset: CGSize = CGSize(width: 0, height: -3) {
        didSet {
            if shadowOffset != oldValue {
                _recordImplicitAnimation(keyPath: "shadowOffset",
                                         from: oldValue, to: shadowOffset)
            }
        }
    }
    public var shadowRadius: CGFloat = 3 {
        didSet {
            if shadowRadius != oldValue {
                _recordImplicitAnimation(keyPath: "shadowRadius",
                                         from: oldValue, to: shadowRadius)
            }
        }
    }

    public init() {}
    init(owner: UIView) {
        self.owner = owner
        self.delegate = owner
    }

    isolated deinit {
        for record in _explicitAnimations {
            CATransaction._removeAnimation(workID: record.workID)
        }
    }

    // MARK: Bounded key-value compatibility

    /// Retain dynamically addressed Core Animation properties used by
    /// open-source visual-effect implementations. This is deliberately a
    /// CALayer-owned compatibility surface rather than a pretend NSObject
    /// runtime: known public properties remain strongly typed above, while
    /// private filter inputs retain their exact values under their keys.
    open func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "isOpaque":
            if let value = value as? Bool { isOpaque = value }
        case "contentsScale":
            if let value = value as? CGFloat { contentsScale = value }
        default:
            if let value {
                storedCompatibilityValues[key] = value
            } else {
                storedCompatibilityValues.removeValue(forKey: key)
            }
        }
    }

    open func value(forKey key: String) -> Any? {
        switch key {
        case "isOpaque": return isOpaque
        case "contentsScale": return contentsScale
        default: return storedCompatibilityValues[key]
        }
    }

    /// Key-path variants preserve the complete path. They cover private
    /// paths such as `filters.gaussianBlur.inputRadius` without claiming a
    /// general Objective-C KVC implementation on non-Objective-C platforms.
    open func setValue(_ value: Any?, forKeyPath keyPath: String) {
        setValue(value, forKey: keyPath)
    }

    open func value(forKeyPath keyPath: String) -> Any? {
        value(forKey: keyPath)
    }

    /// Marks this layer's delegate/layout pass dirty.
    public func setNeedsLayout() {
        _needsLayout = true
        owner?.needsLayout = true
    }

    /// Property-tree mutations implicitly invalidate layout, except while
    /// the receiving layer is already running its callback (Core Animation's
    /// documented recursion guard). Explicit `setNeedsLayout()` calls remain
    /// able to schedule a subsequent pass.
    private func _setNeedsLayoutFromMutation() {
        guard !_isLayingOut else { return }
        setNeedsLayout()
    }

    public func needsLayout() -> Bool { _needsLayout }

    /// Runs the nearest dirty ancestor first, then every dirty descendant.
    /// This mirrors the observable Core Animation contract while remaining
    /// synchronous and deterministic for portable hosts.
    public func layoutIfNeeded() {
        var root = self
        var ancestor = superlayer
        while let candidate = ancestor, candidate._needsLayout {
            root = candidate
            ancestor = candidate.superlayer
        }
        root._layoutTreeIfNeeded()
    }

    private func _layoutTreeIfNeeded() {
        if _needsLayout {
            _needsLayout = false
            _isLayingOut = true
            layoutSublayers()
            _isLayingOut = false
        }
        for sublayer in storedSublayers {
            sublayer._layoutTreeIfNeeded()
        }
    }

    /// Subclass override point. The default Core Animation implementation
    /// consults its delegate before any layout manager; OpenUIKit currently
    /// models that delegate path and has no CALayoutManager surface.
    open func layoutSublayers() {
        delegate?.layoutSublayers(of: self)
    }

    /// Paint the receiver and its descendants into an existing graphics
    /// context. Like Core Animation, the root's own frame/position is not
    /// applied; only its bounds contents and descendant placement are drawn.
    public func render(in context: Canvas) {
        // iOS 26's legacy render(in:) path was measured to round all four
        // corners regardless of maskedCorners, unlike live compositing.
        if let owner {
            UIRenderer.renderView(owner, into: context,
                                  honorsMaskedCorners: false)
        } else {
            UIRenderer.renderLayer(self, into: context,
                                   honorsMaskedCorners: false)
        }
    }
}

/// Axial Core Animation gradient layer. The render pipelines route these
/// stops through the same oracle-calibrated Generic-RGB interpolation used by
/// UIGradientView (or quartz's calibrated QZGradientLayer implementation).
@preconcurrency @MainActor
public final class CAGradientLayer: CALayer {
    public var colors: [CGColor]?
    public var locations: [CGFloat]?
    public var startPoint = CGPoint(x: 0.5, y: 0)
    public var endPoint = CGPoint(x: 0.5, y: 1)

    public override init() { super.init() }
}

/// Internal hierarchy policy for UIKit containers whose public contract does
/// not permit arbitrary direct children. UIView's public insertion methods
/// consult it; framework implementation paths can install private children
/// through the scoped bypasses below.
@MainActor
protocol _UIViewSubviewAdmission: AnyObject {
    func validateSubviewInsertion(_ view: UIView)
}

@preconcurrency @MainActor
open class UIView: UIResponder, CALayerDelegate {
    /// Process-wide base-view appearance proxy. New views inherit explicitly
    /// configured values; inherited defaults remain live through the normal
    /// superview chain. A construction guard prevents the proxy from trying
    /// to inherit from itself.
    private static var _appearanceProxy: UIView?
    private static var _constructingAppearanceProxy = false

    public class func appearance() -> Self {
        precondition(
            self == UIView.self,
            "UIView subclasses with appearance-customizable properties must provide their own proxy"
        )
        if let proxy = _appearanceProxy { return proxy as! Self }
        _constructingAppearanceProxy = true
        let proxy = UIView(frame: .zero)
        _constructingAppearanceProxy = false
        _appearanceProxy = proxy
        return proxy as! Self
    }
    // Geometry: center/bounds/transform are source of truth (like real UIKit).
    public var center: CGPoint = .zero {
        didSet {
            if center != oldValue {
                recordAnimation(.position, from: .point(oldValue), to: .point(center))
            }
        }
    }
    open var bounds: CGRect = .zero {
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
            // UIKit: under a pure (axis-aligned) scale the frame is still
            // meaningful and setting it sizes the BOUNDS so that the
            // transformed box equals the new frame — a sheet scaled by
            // 377/393 given frame width 377 keeps bounds width 393 (measured
            // 2026-09-04: iOS 26 floating sheet card, UIDropShadowView frame
            // [8, 482.349, 377, 361.651] with bounds 393x377). Any other
            // transform keeps the old "size as given" behaviour.
            var size = newValue.size
            if !transform.isIdentity, transform.b == 0, transform.c == 0,
               transform.a != 0, transform.d != 0 {
                size = CGSize(width: newValue.width / abs(transform.a),
                              height: newValue.height / abs(transform.d))
            }
            bounds.size = size
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
    /// Portable compositor hooks used by SwiftUI's brightness/saturation
    /// modifiers. They apply to the completed subtree as a single group,
    /// preserving descendant alpha and overlap exactly like a layer filter.
    public var _openUIKitBrightness: CGFloat = 0 {
        didSet { if _openUIKitBrightness != oldValue { setNeedsDisplay() } }
    }
    public var _openUIKitSaturation: CGFloat = 1 {
        didSet { if _openUIKitSaturation != oldValue { setNeedsDisplay() } }
    }
    public var isHidden = false
    public var isOpaque = true
    /// iOS 26 liquid-glass chrome (tab-bar / toolbar / bar-button platters,
    /// floating sheet). The Canvas backdrop-filter path applies
    /// `_UIGlassMaterial`; Catalyst ignores the flag.
    /// Public so the SwiftUI module can set it (`.glassEffect` on the iOS cut).
    public var _usesIOSGlass = false
    /// Dark floating sheet only. Bar platters keep the measured dark flats
    /// (19 / 25); the sheet's systemBackground fill tracks the dimmed
    /// backdrop (MEASURED /tmp/sheetfill_dark, SE 2x).
    var _usesIOSDarkGlass = false
    /// Clip path for `_UIGlassMaterial`. Bar platters are capsules; the
    /// floating sheet overrides with independent top/bottom radii.
    func _iosGlassPath(in bounds: CGRect) -> Path {
        UIRenderer.layerRoundedRect(bounds, cornerRadius: layer.cornerRadius,
                                    maskedCorners: layer.maskedCorners)
    }
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
    /// UIKit creates every view with a pending constraints update. The flag
    /// is cleared by `updateConstraints()` (whose overrides must call super)
    /// and is propagated to ancestors by `setNeedsUpdateConstraints()` so a
    /// root-driven pass can visit dirty descendants bottom-up.
    var _needsUpdateConstraints = true
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

    /// `registerForTraitChanges` bookings (UIViewCompat.swift).
    var _traitRegistrations: [UITraitChangeRegistration] = []
    /// Backing storage for UIView's semantic layout-direction contract.
    var _semanticContentAttribute: UISemanticContentAttribute = .unspecified

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
    /// An assignment to ``layoutMargins``, which wins over the class default.
    var _baseLayoutMarginsOverride: UIEdgeInsets?
    /// The base margins ``layoutMargins`` starts from: whatever was assigned,
    /// else the class's own default.
    var _baseLayoutMargins: UIEdgeInsets {
        get { _baseLayoutMarginsOverride ?? _defaultBaseLayoutMargins }
        set { _baseLayoutMarginsOverride = newValue }
    }
    /// UIKit's default base margins: 8 pt on every edge. Computed rather than
    /// stored so a subclass whose margins depend on its geometry can override
    /// it and stay live as that geometry changes — `UITableViewCell`'s do,
    /// they follow the window's system margin.
    var _defaultBaseLayoutMargins: UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
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

    /// Hierarchy lifecycle override points. OpenUIKit delivers window changes
    /// to the complete moved subtree, with `window` already reflecting the
    /// new hierarchy when `didMoveToWindow()` runs. Moving between two
    /// superviews in the same window does not manufacture a window change.
    open func willMove(toSuperview newSuperview: UIView?) {}
    open func didMoveToSuperview() {}
    open func willMove(toWindow newWindow: UIWindow?) {}
    open func didMoveToWindow() {}

    /// Legacy trait callback retained by UIKit for source compatibility.
    /// Host-driven trait changes call this once per view after matching modern
    /// registrations have fired. Subclasses may intentionally omit `super`.
    open func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {}

    /// Baseline offsets for firstBaseline/lastBaseline constraint attributes:
    /// (first baseline from the view's top, last baseline from its bottom).
    /// nil (plain views): both baselines alias the bottom edge, like UIKit.
    /// UILabel overrides (text module hook).
    func _constraintBaselines() -> (firstFromTop: CGFloat, lastFromBottom: CGFloat)? {
        nil
    }

    /// Trait override; `.unspecified` inherits from superview / current.
    public var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified
    /// `open`, as UIKit declares it: pocket-casts' TintableImageView overrides
    /// it to re-tint its image on assignment.
    open var tintColor: UIColor! {
        get { _tintColor ?? superview?.tintColor ?? .systemBlue }
        set { _tintColor = newValue }
    }
    var _tintColor: UIColor?

    public init(frame: CGRect) {
        super.init()
        if !UIView._constructingAppearanceProxy {
            _tintColor = UIView._appearanceProxy?._tintColor
            // MEASURED /tmp/rtlprobe, iPhone SE 2x / iOS 26.1:
            // `UIView.appearance().semanticContentAttribute = .forceRightToLeft`
            // stamps every subsequently constructed UIView (74/76 views
            // dump `uiDir=rtl`). Window-only assignment stamps the window
            // (1/76) and does not propagate — `effectiveUserInterfaceLayoutDirection`
            // of an unspecified child stays LTR (UIButtonTests).
            if let proxy = UIView._appearanceProxy,
               proxy._semanticContentAttribute != .unspecified {
                _semanticContentAttribute = proxy._semanticContentAttribute
            }
        }
        self.frame = frame
    }

    /// UIKit exposes a real zero-argument convenience initializer in addition
    /// to `init(frame:)`.  It cannot be modeled as a default argument on the
    /// designated frame initializer: default arguments are not inherited when
    /// a subclass overrides `init(frame:)`, while convenience initializers are.
    public convenience override init() {
        self.init(frame: .zero)
    }

    /// Source-compatible entry point for code-based UIKit views that carry
    /// the required `init?(coder: NSCoder)` boilerplate.  OpenUIKit does not
    /// decode Interface Builder archives; this initializer only preserves the
    /// framework initializer contract and starts with zero geometry.
    public required init?(coder: NSCoder) {
        _ = coder
        super.init()
        self.frame = .zero
    }

    /// UIKit's NSObject description is a live diagnostic of the concrete
    /// view identity and geometry. Keeping the dynamic class name first is
    /// important to unchanged code which distinguishes private visual-effect
    /// hierarchy nodes by their description. UIView is main-thread-only; the
    /// inherited NSObject requirement is nonisolated, so make that existing
    /// contract explicit at this single synchronous boundary.
    nonisolated private var _openDescription: String {
        let className = String(describing: type(of: self))
        let identity = Unmanaged.passUnretained(self).toOpaque()
        return MainActor.assumeIsolated {
            "<\(className): \(identity); frame = \(frame); bounds = \(bounds)>"
        }
    }

#if canImport(Foundation)
    /// Foundation's NSObject declares `description`, so the Darwin/host
    /// surface is a genuine override.
    nonisolated open override var description: String { _openDescription }
#else
    /// The guest ObjectiveC NSObject deliberately has no Foundation
    /// description property. Keep UIView's UIKit surface without claiming a
    /// nonexistent override; statically typed UIView callers (including
    /// unchanged applications) see the same public member.
    nonisolated open var description: String { _openDescription }
#endif

    // MARK: Hierarchy
    public func addSubview(_ view: UIView) {
        (self as? _UIViewSubviewAdmission)?.validateSubviewInsertion(view)
        _addSubviewWithoutAdmissionCheck(view)
    }

    /// Framework containers with a restricted public hierarchy use this
    /// path to install their own implementation views. It intentionally is
    /// not public: app calls still pass through the admission check above.
    func _addSubviewWithoutAdmissionCheck(_ view: UIView) {
        guard view !== self else { return }
        if view.superview === self {
            bringSubviewToFront(view)
            return
        }
        let oldWindow = view.window
        let newWindow = window
        view.willMove(toSuperview: self)
        if oldWindow !== newWindow {
            view._willMoveSubtree(toWindow: newWindow)
        }
        view._detachFromSuperviewWithoutCallbacks()
        view.superview = self
        subviews.append(view)
        // A newly attached view starts with a pending constraints update.
        // Re-issuing the invalidation after assigning `superview` propagates
        // that pending work to this hierarchy's root.
        view.setNeedsUpdateConstraints()
        setNeedsLayout()
        view.didMoveToSuperview()
        if oldWindow !== newWindow {
            view._didMoveSubtreeToWindow()
        }
    }

    public func insertSubview(_ view: UIView, at index: Int) {
        (self as? _UIViewSubviewAdmission)?.validateSubviewInsertion(view)
        _insertSubviewWithoutAdmissionCheck(view, at: index)
    }

    /// Insert `view` immediately below an existing child. UIKit requires the
    /// sibling to belong to this receiver; fail at the call site rather than
    /// silently inventing an ordering for an unrelated view.
    public func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        guard siblingSubview.superview === self else {
            preconditionFailure("belowSubview must be a subview of the receiver")
        }
        guard view !== siblingSubview else { return }
        let index = subviews.firstIndex(where: { $0 === siblingSubview })!
        insertSubview(view, at: index)
    }

    /// Insert `view` immediately above an existing child.
    public func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        guard siblingSubview.superview === self else {
            preconditionFailure("aboveSubview must be a subview of the receiver")
        }
        guard view !== siblingSubview else { return }
        let index = subviews.firstIndex(where: { $0 === siblingSubview })!
        insertSubview(view, at: index + 1)
    }

    /// Internal twin of `_addSubviewWithoutAdmissionCheck(_:)` for ordered
    /// implementation children.
    func _insertSubviewWithoutAdmissionCheck(_ view: UIView, at index: Int) {
        guard view !== self else { return }
        if view.superview === self {
            guard let oldIndex = subviews.firstIndex(where: { $0 === view }) else { return }
            subviews.remove(at: oldIndex)
            let adjustedIndex = oldIndex < index ? index - 1 : index
            subviews.insert(view, at: Swift.max(0, Swift.min(adjustedIndex, subviews.count)))
            setNeedsLayout()
            return
        }
        let oldWindow = view.window
        let newWindow = window
        view.willMove(toSuperview: self)
        if oldWindow !== newWindow {
            view._willMoveSubtree(toWindow: newWindow)
        }
        view._detachFromSuperviewWithoutCallbacks()
        view.superview = self
        subviews.insert(view, at: Swift.max(0, Swift.min(index, subviews.count)))
        view.setNeedsUpdateConstraints()
        setNeedsLayout()
        view.didMoveToSuperview()
        if oldWindow !== newWindow {
            view._didMoveSubtreeToWindow()
        }
    }
    public func removeFromSuperview() {
        guard superview != nil else { return }
        let oldWindow = window
        willMove(toSuperview: nil)
        if oldWindow != nil { _willMoveSubtree(toWindow: nil) }
        let formerSuperview = superview
        _detachFromSuperviewWithoutCallbacks()
        formerSuperview?.setNeedsLayout()
        didMoveToSuperview()
        if oldWindow != nil { _didMoveSubtreeToWindow() }
    }

    private func _detachFromSuperviewWithoutCallbacks() {
        guard let currentSuperview = superview else { return }
        currentSuperview.subviews.removeAll { $0 === self }
        superview = nil
    }

    private func _willMoveSubtree(toWindow newWindow: UIWindow?) {
        willMove(toWindow: newWindow)
        for subview in subviews {
            subview._willMoveSubtree(toWindow: newWindow)
        }
    }

    private func _didMoveSubtreeToWindow() {
        didMoveToWindow()
        for subview in subviews {
            subview._didMoveSubtreeToWindow()
        }
    }

    /// Whether the receiver is the supplied view or lies below it in the
    /// view hierarchy (UIKit includes identity in this predicate).
    open func isDescendant(of view: UIView) -> Bool {
        var candidate: UIView? = self
        while let current = candidate {
            if current === view { return true }
            candidate = current.superview
        }
        return false
    }

    /// Ask the first responder in this view's subtree to resign.
    ///
    /// iOS 26.1's measured `force` behavior is subtler than the SDK header's
    /// “optionally force” shorthand: UIKit still gives the responder (and
    /// therefore its text delegate) the opportunity to refuse; `true` changes
    /// the RETURN VALUE to true but leaves focus/editing untouched and sends
    /// no did-end callback. An active responder outside the receiver's
    /// subtree returns false for either force value. With no active responder,
    /// the operation is already satisfied and returns true.
#if canImport(ObjectiveC)
    @objc(endEditing:)
#endif
    @discardableResult
    open func endEditing(_ force: Bool) -> Bool {
        guard let window else { return true }
        guard let responder = window.firstResponder else { return true }
        guard let responderView = responder as? UIView,
              responderView.isDescendant(of: self) else { return false }
        if force {
            // Measured UIKit calls the responder once, then reports success
            // even when that call refuses to end editing.
            _ = responder.resignFirstResponder()
            return true
        }
        // The non-force path first checks eligibility, then performs the
        // resignation. A permissive text delegate is consequently asked
        // twice; a refusing one is asked once (iOS 26.1 behavior).
        guard responder.canResignFirstResponder else { return false }
        return responder.resignFirstResponder()
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

    /// Capture the receiver's current laid-out presentation as a static image
    /// view. The portable renderer has no private live snapshot layer, so the
    /// returned view intentionally remains unchanged when the source changes.
    public func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        _ = afterUpdates
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        layoutIfNeeded()
        let scale = max(1, window?.windowScene?.screen.scale ?? UIScreen.main.scale)
        let bitmap = UIRenderer.render(self, scale: scale)
        guard bitmap.width > 0, bitmap.height > 0 else { return nil }
        let snapshot = UIImageView(image: UIImage(bitmap: bitmap, scale: scale))
        snapshot.frame = CGRect(origin: .zero, size: bounds.size)
        return snapshot
    }

    // MARK: Traits
    /// The semantic direction of this view's immediate content. OpenUIKit's
    /// unspecified value resolves against its process-wide LTR fallback;
    /// playback and spatial controls deliberately remain left-to-right.
    open var semanticContentAttribute: UISemanticContentAttribute {
        get { _semanticContentAttribute }
        set {
            guard newValue != _semanticContentAttribute else { return }
            _semanticContentAttribute = newValue
            setNeedsLayout()
        }
    }

    open class func userInterfaceLayoutDirection(
        for semanticContentAttribute: UISemanticContentAttribute
    ) -> UIUserInterfaceLayoutDirection {
        userInterfaceLayoutDirection(for: semanticContentAttribute,
                                     relativeTo: .leftToRight)
    }

    open class func userInterfaceLayoutDirection(
        for semanticContentAttribute: UISemanticContentAttribute,
        relativeTo layoutDirection: UIUserInterfaceLayoutDirection
    ) -> UIUserInterfaceLayoutDirection {
        switch semanticContentAttribute {
        case .unspecified:
            return layoutDirection
        case .playback, .spatial, .forceLeftToRight:
            return .leftToRight
        case .forceRightToLeft:
            return .rightToLeft
        }
    }

    /// Direction appropriate for arranging this view's immediate content.
    /// UIKit does not propagate semantic content attributes through a view
    /// subtree. OpenUIKit has no process-wide UIApplication locale yet, so
    /// each unspecified view resolves against an LTR application fallback.
    open var effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        type(of: self).userInterfaceLayoutDirection(for: semanticContentAttribute)
    }

    /// Whether this view arranges its own content right-to-left.
    /// Unspecified still resolves LTR (UIButtonTests: a child of an RTL
    /// parent does not inherit).
    var _layoutIsRTL: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    open var traitCollection: UITraitCollection {
        // UIKit supplies a complete environment even before a view joins a
        // hierarchy. OpenUIKit's process-wide collection may intentionally
        // leave size axes unspecified for the host surface to resolve, so a
        // detached view completes just those axes from UIScreen's bounds
        // rather than exposing placeholders to initializers/viewDidLoad.
        var t = superview?.traitCollection ?? UIScreen.main._currentTraitsResolvingSizeClasses
        if overrideUserInterfaceStyle != .unspecified {
            t.userInterfaceStyle = overrideUserInterfaceStyle
        }
        return t
    }

    // MARK: Layout
    var needsLayout = true
    public func setNeedsLayout() {
        needsLayout = true
        layer.setNeedsLayout()
    }

    /// Schedule the receiver's update-constraints callback for the next
    /// layout pass. UIKit propagates this dirtiness to the hierarchy root:
    /// invalidating a child and laying out the root updates the child first,
    /// then the ancestors, and finally lays out the root.
    open func setNeedsUpdateConstraints() {
        _needsUpdateConstraints = true
        var top = self
        var ancestor = superview
        while let current = ancestor {
            current._needsUpdateConstraints = true
            top = current
            ancestor = current.superview
        }
        // Measured UIKit behavior: a constraints invalidation schedules the
        // root layout, not a standalone layoutSubviews call on the child.
        top.setNeedsLayout()
    }

    open func needsUpdateConstraints() -> Bool { _needsUpdateConstraints }

    /// Run a bottom-up constraints update for the hierarchy rooted here.
    /// A view-controller-managed root dispatches to the controller in lieu
    /// of calling the root view directly; UIViewController's base method then
    /// sends `updateConstraints()` to the view, matching UIKit's documented
    /// separation-of-concerns hook.
    open func updateConstraintsIfNeeded() {
        _updateConstraintsSubtreeIfNeeded()
    }

    func _updateConstraintsSubtreeIfNeeded() {
        for subview in subviews {
            subview._updateConstraintsSubtreeIfNeeded()
        }
        guard _needsUpdateConstraints else { return }
        if let controller = _managingViewController,
           controller.viewIfLoaded === self {
            controller.updateViewConstraints()
        } else {
            updateConstraints()
        }
    }

    /// Override point for constraint creation/adjustment. Overrides must call
    /// super; the base implementation clears the pending-update flag. This
    /// also gives direct calls the same state transition observed on UIKit.
    open func updateConstraints() {
        _needsUpdateConstraints = false
    }

    public func layoutIfNeeded() {
        // Auto Layout (M9): solve constraints for the whole hierarchy first
        // (UIKit solves in the window/root space before layoutSubviews).
        // No-op (one integer compare) when no constraints are installed.
        var top: UIView = self
        while let sv = top.superview { top = sv }
        // Constraints update bottom-up before solving and layout. A child
        // invalidation dirties its ancestors, so the controller-managed root
        // is reached after every dirty descendant.
        top._updateConstraintsSubtreeIfNeeded()
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
            // Clear before callbacks so setNeedsLayout() from inside an
            // override schedules a subsequent pass instead of being erased.
            needsLayout = false
            let controller = _managingViewController.flatMap {
                $0.viewIfLoaded === self ? $0 : nil
            }
            controller?.viewWillLayoutSubviews()
            layer.layoutIfNeeded()
            controller?.viewDidLayoutSubviews()
        }
        for s in subviews { s._layoutSubtree() }
    }
    open func layoutSubviews() {}

    /// CALayerDelegate entry point for this view's backing layer. UIKit routes
    /// `layoutSubviews()` through this callback; doing the same preserves the
    /// ordering seen by subclasses that override `layoutSublayers(of:)` and
    /// call `super`, including views that resize explicit gradient layers.
    open func layoutSublayers(of layer: CALayer) {
        guard layer === self.layer else { return }
        needsLayout = false
        layoutSubviews()
    }

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

    /// Converts all four corners and returns their axis-aligned bounding box,
    /// which is UIKit's CGRect behavior when either hierarchy contains a
    /// transform.
    public func convert(_ rect: CGRect, to view: UIView?) -> CGRect {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ].map { convert($0, to: view) }
        guard let first = corners.first else { return .zero }
        let minX = corners.dropFirst().reduce(first.x) { min($0, $1.x) }
        let maxX = corners.dropFirst().reduce(first.x) { max($0, $1.x) }
        let minY = corners.dropFirst().reduce(first.y) { min($0, $1.y) }
        let maxY = corners.dropFirst().reduce(first.y) { max($0, $1.y) }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public func convert(_ rect: CGRect, from view: UIView?) -> CGRect {
        if let view { return view.convert(rect, to: self) }
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ].map { convert($0, from: nil) }
        guard let first = corners.first else { return .zero }
        let minX = corners.dropFirst().reduce(first.x) { min($0, $1.x) }
        let maxX = corners.dropFirst().reduce(first.x) { max($0, $1.x) }
        let minY = corners.dropFirst().reduce(first.y) { min($0, $1.y) }
        let maxY = corners.dropFirst().reduce(first.y) { max($0, $1.y) }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
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
        guard !_hasInteractionBlockingAnimation(at: OpenUIKitRuntime.animationTime)
        else { return nil }
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
