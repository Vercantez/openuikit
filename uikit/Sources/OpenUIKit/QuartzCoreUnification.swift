// Core Animation on Apple toolchains is QuartzCore itself (cg-unify phase 3,
// docs/agent_reports/cg-unify.md).
//
// Where Apple's frameworks exist (the macOS host, route (b)'s iOS triple:
// `canImport(CoreGraphics)`), `CALayer`, `CAGradientLayer`, `CALayerDelegate`,
// `CAAnimation`, `CABasicAnimation`, `CATransaction`, `CATransform3D`, ... are
// QuartzCore's own classes and types, and `import UIKit` re-exports QuartzCore
// as Apple's UIKit does. An app's Swift and Objective-C code therefore see one
// Core Animation: no "'CALayer' has different definitions" between QuartzCore's
// headers and OpenUIKit-Swift.h, no ambiguous `CALayer` next to
// `import QuartzCore`, and CAShapeLayer / CASpringAnimation / CADisplayLink /
// CAMediaTimingFunction exist.
//
// The port keeps rendering. QuartzCore's layer is the MODEL: the renderer reads
// its properties; the port's own per-layer state (the backing view, animation
// records sampled on the port's clock, per-corner radii) hangs off it as an
// associated object. A handful of CALayer / CATransaction methods are
// interposed once per process to keep the semantics the port measured on
// iOS 26.1 and implemented before:
//
//   * a view's backing layer forwards geometry, opacity, visibility and
//     background colour to its view (the view stays the source of truth, as in
//     the port's own CALayer): the getters read the view, the setters write it;
//   * implicit animations are the port's (sampled on OpenUIKitRuntime's
//     deterministic clock), not QuartzCore's (which need a render server and
//     wall-clock begin times): `-actionForKey:` returns nil and the setters
//     record the port's implicit animation instead;
//   * `-addAnimation:forKey:` / `-removeAnimationForKey:` /
//     `-removeAllAnimations` also record into the port's animation model;
//   * `+[CATransaction begin/commit/…]` drive the port's transaction model
//     (durations, disableActions, completion blocks on the port's clock);
//   * `-renderInContext:` renders with the port's renderer (the layer's
//     content is the port's drawing, not QuartzCore contents).
//
// The interposers only act on layers the port has state for, or forward
// unchanged. Linux ELF and the Mach-O guest (no Apple frameworks) keep
// OpenUIKit's own CALayer family (UIView.swift, CoreAnimation.swift).
#if canImport(CoreGraphics)
import QuartzCore
import ObjectiveC
#if canImport(Foundation)
import class Foundation.NSNumber
import class Foundation.NSNull
#endif

// Re-exported, not re-declared (see OpenCoreGraphics/Geometry.swift on
// collection sugar: a typealias made `[CALayer]()` a literal of metatypes).
@_exported import class QuartzCore.CALayer
@_exported import class QuartzCore.CAGradientLayer
@_exported import protocol QuartzCore.CALayerDelegate
@_exported import struct QuartzCore.CACornerMask
@_exported import struct QuartzCore.CALayerCornerCurve
@_exported import struct QuartzCore.CAMediaTimingFillMode
@_exported import class QuartzCore.CAAnimation
@_exported import class QuartzCore.CAPropertyAnimation
@_exported import class QuartzCore.CABasicAnimation
@_exported import class QuartzCore.CATransaction
@_exported import struct QuartzCore.CATransform3D

extension CACornerMask {
    public static let _allKnown: CACornerMask = [
        .layerMinXMinYCorner, .layerMaxXMinYCorner,
        .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
    ]
}

/// The port's state for one QuartzCore layer.
final class _OUKLayerState {
    /// The view this layer backs (its geometry lives in the view).
    weak var owner: UIView?
    /// Explicit and implicit animation records on the port's clock.
    var explicitAnimations: [_CALayerAnimationRecord] = []
    /// Per-corner radii from `UIView.cornerConfiguration`.
    var cornerRadii: _CACornerRadii?
    /// Keeps the colour a forwarded `-backgroundColor` returned alive (+0).
    var ownerBackground: CGColor?
    /// Set while `-setFrame:` runs, so its nested bounds/position setters
    /// do not record a second implicit animation.
    var inFrameSetter = false
    /// The port's layout flags (its CALayer model, measured on iOS 26.1: a
    /// new layer does not need layout; a backing layer starts dirty;
    /// mutations made while the layer runs its own layout do not re-dirty
    /// it). QuartzCore's `-layoutIfNeeded` re-runs a layer's layout while it
    /// is dirty, which loops on views that touch their own geometry in
    /// layoutSubviews, so the port's pass drives layout instead.
    var needsLayout = false
    var isLayingOut = false

    deinit {
        let ids = explicitAnimations.map(\.workID)
        guard !ids.isEmpty else { return }
        MainActor.assumeIsolated {
            for id in ids { _OUKTransaction._removeAnimation(workID: id) }
        }
    }
}

nonisolated(unsafe) private var _oukLayerStateKey: UInt8 = 0

// The associated-object read on every interposed getter: typed, no dynamic
// cast (only this file stores under the key, always an _OUKLayerState).
@_silgen_name("objc_getAssociatedObject")
private func _oukGetAssociatedObject(_ object: AnyObject, _ key: UnsafeRawPointer) -> Unmanaged<AnyObject>?

extension CALayer {
    /// The port's state, if the port has touched this layer.
    var _oukStateIfPresent: _OUKLayerState? {
        guard let object = withUnsafePointer(to: &_oukLayerStateKey, { _oukGetAssociatedObject(self, $0) })
        else { return nil }
        return unsafeDowncast(object.takeUnretainedValue(), to: _OUKLayerState.self)
    }

    /// The port's state, created on first use.
    var _ouk: _OUKLayerState {
        if let state = _oukStateIfPresent { return state }
        _OUKQuartzBridge.install()
        let state = _OUKLayerState()
        objc_setAssociatedObject(self, &_oukLayerStateKey, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }

    /// The view whose backing layer this is.
    var owner: UIView? { _oukStateIfPresent?.owner }

    /// A view's backing layer.
    convenience init(owner: UIView) {
        self.init()
        _adoptOwner(owner)
    }

    /// Makes the receiver `owner`'s backing layer. iOS: the view is the
    /// layer's delegate, and a new backing layer is dirty (the view's first
    /// layout pass runs through it).
    func _adoptOwner(_ owner: UIView) {
        let state = _ouk
        state.owner = owner
        delegate = owner
        state.needsLayout = true
    }

    /// Property-tree mutations dirty the layer, except while it runs its own
    /// layout (Core Animation's recursion guard, the port's model).
    func _oukSetNeedsLayoutFromMutation() {
        if _oukStateIfPresent?.isLayingOut == true { return }
        setNeedsLayout()
    }

    /// The port's layout pass for this layer's tree: the nearest dirty
    /// ancestor first, then every dirty descendant, each laid out once.
    func _oukLayoutIfNeeded() {
        var root = self
        var ancestor = superlayer
        while let candidate = ancestor, candidate._oukStateIfPresent?.needsLayout == true {
            root = candidate
            ancestor = candidate.superlayer
        }
        root._oukLayoutTreeIfNeeded()
    }

    private func _oukLayoutTreeIfNeeded() {
        if let state = _oukStateIfPresent, state.needsLayout {
            state.needsLayout = false
            state.isLayingOut = true
            layoutSublayers()
            state.isLayingOut = false
        }
        for sublayer in sublayers ?? [] { sublayer._oukLayoutTreeIfNeeded() }
    }

    /// The backing layer of a view whose `+layerClass` is `type`: an
    /// Objective-C `alloc`/`init` of that class (QuartzCore's or an app's).
    static func _makeBackingLayer(of type: CALayer.Type, owner: UIView) -> CALayer {
        _OUKQuartzBridge.install()
        let object = unsafeBitCast(type, to: NSObject.Type.self).init()
        let layer = (object as? CALayer) ?? CALayer()
        layer._adoptOwner(owner)
        return layer
    }

    var _explicitAnimations: [_CALayerAnimationRecord] {
        get { _oukStateIfPresent?.explicitAnimations ?? [] }
        set { _ouk.explicitAnimations = newValue }
    }

    var _cornerRadii: _CACornerRadii? {
        get { _oukStateIfPresent?.cornerRadii }
        set { _ouk.cornerRadii = newValue }
    }

    /// The exact ordered storage the render pipelines walk.
    var _orderedSublayers: [CALayer] { sublayers ?? [] }

    // The renderer's value colours (CoreGraphics' colours converted once per
    // read; the port's CanvasColor).
    var _backgroundColorValue: CanvasColor? {
        get {
            if let owner {
                return owner.backgroundColor?.resolvedCGColor(with: owner.traitCollection)
            }
            return backgroundColor.map(CanvasColor.init)
        }
        set { backgroundColor = newValue?.cgColor }
    }
    var _borderColorValue: CanvasColor? {
        get { borderColor.map(CanvasColor.init) }
        set { borderColor = newValue?.cgColor }
    }
    var _shadowColorValue: CanvasColor? {
        get { shadowColor.map(CanvasColor.init) }
        set { shadowColor = newValue?.cgColor }
    }

    /// OpenUIKit's bounded key-value compatibility (see the portable
    /// CALayer): QuartzCore's layer is a key-value container itself.
    func _openSetValue(_ value: Any?, forKey key: String) {
        setValue(value, forKey: key == "isOpaque" ? "opaque" : key)
    }
    func _openValue(forKey key: String) -> Any? {
        value(forKey: key == "isOpaque" ? "opaque" : key)
    }

    /// Paint the receiver and its descendants into a Canvas (the port's
    /// `render(in:)`): the root's own frame is not applied.
    public func render(in context: Canvas) {
        // iOS 26's legacy render(in:) path was measured to round all four
        // corners regardless of maskedCorners, unlike live compositing.
        if let owner {
            UIRenderer.renderView(owner, into: context, honorsMaskedCorners: false)
        } else {
            UIRenderer.renderLayer(self, into: context, honorsMaskedCorners: false)
        }
    }
}

extension CAGradientLayer {
    /// The renderer's gradient colours.
    var _colorValues: [CanvasColor]? {
        (colors as? [CGColor])?.map(CanvasColor.init)
    }
    /// The gradient's stop locations as CGFloat.
    var _locationValues: [CGFloat]? {
        locations?.map { CGFloat(truncating: $0) }
    }
}

extension CAAnimation {
    /// An independent copy (QuartzCore animations are NSCopying).
    func _copyAnimation() -> CAAnimation {
        (copy() as? CAAnimation) ?? self
    }
}

// MARK: - The interposers

private typealias _GetRect = @convention(c) (CALayer, Selector) -> CGRect
private typealias _SetRect = @convention(c) (CALayer, Selector, CGRect) -> Void
private typealias _GetPoint = @convention(c) (CALayer, Selector) -> CGPoint
private typealias _SetPoint = @convention(c) (CALayer, Selector, CGPoint) -> Void
private typealias _GetSize = @convention(c) (CALayer, Selector) -> CGSize
private typealias _SetSize = @convention(c) (CALayer, Selector, CGSize) -> Void
private typealias _GetFloat = @convention(c) (CALayer, Selector) -> Float
private typealias _SetFloat = @convention(c) (CALayer, Selector, Float) -> Void
private typealias _GetCGFloat = @convention(c) (CALayer, Selector) -> CGFloat
private typealias _SetCGFloat = @convention(c) (CALayer, Selector, CGFloat) -> Void
private typealias _GetBool = @convention(c) (CALayer, Selector) -> Bool
private typealias _SetBool = @convention(c) (CALayer, Selector, Bool) -> Void
private typealias _GetColor = @convention(c) (CALayer, Selector) -> Unmanaged<CGColor>?
private typealias _SetColor = @convention(c) (CALayer, Selector, CGColor?) -> Void
private typealias _GetTransform3D = @convention(c) (CALayer, Selector) -> CATransform3D
private typealias _SetTransform3D = @convention(c) (CALayer, Selector, CATransform3D) -> Void
private typealias _GetAffine = @convention(c) (CALayer, Selector) -> CGAffineTransform
private typealias _SetAffine = @convention(c) (CALayer, Selector, CGAffineTransform) -> Void
private typealias _Void = @convention(c) (CALayer, Selector) -> Void
private typealias _SetObject = @convention(c) (CALayer, Selector, AnyObject?) -> Void
private typealias _SetTwoObjects = @convention(c) (CALayer, Selector, AnyObject?, AnyObject?) -> Void
private typealias _InsertAtIndex = @convention(c) (CALayer, Selector, AnyObject?, UInt32) -> Void
private typealias _AddAnimation = @convention(c) (CALayer, Selector, CAAnimation, AnyObject?) -> Void
private typealias _RemoveAnimation = @convention(c) (CALayer, Selector, AnyObject) -> Void
private typealias _AnimationForKey = @convention(c) (CALayer, Selector, AnyObject) -> CAAnimation?
private typealias _AnimationKeys = @convention(c) (CALayer, Selector) -> AnyObject?
private typealias _RenderIn = @convention(c) (CALayer, Selector, CGContext) -> Void
private typealias _ClassVoid = @convention(c) (AnyClass, Selector) -> Void
private typealias _ClassSetDouble = @convention(c) (AnyClass, Selector, Double) -> Void
private typealias _ClassSetBool = @convention(c) (AnyClass, Selector, Bool) -> Void

/// Installs the interposers once per process (a C constructor calls
/// `_openuikit_install_quartzcore_bridge` at load; first use of the port's
/// layer state calls it too).
enum _OUKQuartzBridge {
    nonisolated(unsafe) private static var installed = false
    /// > 0 while one of QuartzCore's own mutators runs under an interposer.
    nonisolated(unsafe) static var quartzInternalDepth = 0

    /// Runs QuartzCore's original mutator; its internal `-setNeedsLayout`
    /// calls do not reach the port's layout model.
    @inline(__always)
    static func quartz(_ body: () -> Void) {
        quartzInternalDepth += 1
        body()
        quartzInternalDepth -= 1
    }
    /// Originals the port calls directly (bypassing its own interposers).
    nonisolated(unsafe) fileprivate static var removeAnimationOriginal: _RemoveAnimation?

    static func install() {
        guard !installed else { return }
        installed = true
        installLayer()
        installTransaction()
    }

    private static func replace<Original>(_ cls: AnyClass, _ name: String, as: Original.Type,
                                          _ make: (Original, Selector) -> Any) {
        let selector = NSSelectorFromString(name)
        guard let method = class_getInstanceMethod(cls, selector) else { return }
        let original = unsafeBitCast(method_getImplementation(method), to: Original.self)
        method_setImplementation(method, imp_implementationWithBlock(make(original, selector)))
    }

    // swiftlint:disable:next function_body_length
    private static func installLayer() {
        let c: AnyClass = CALayer.self

        // Geometry of a backing layer is its view's.
        replace(c, "bounds", as: _GetRect.self) { original, sel in
            { (layer: CALayer) -> CGRect in
                if let owner = layer.owner { return owner.bounds }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> CGRect
        }
        replace(c, "setBounds:", as: _SetRect.self) { original, sel in
            { (layer: CALayer, value: CGRect) in
                let state = layer._oukStateIfPresent
                if let owner = state?.owner {
                    MainActor.assumeIsolated { owner.bounds = value }
                    _OUKQuartzBridge.quartz { original(layer, sel, value) }; return
                }
                let old = layer.bounds
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                if !(state?.inFrameSetter ?? false), old != value {
                    MainActor.assumeIsolated {
                        layer._recordImplicitAnimation(keyPath: "bounds", from: old, to: value)
                        layer._oukSetNeedsLayoutFromMutation()
                        layer.superlayer?._oukSetNeedsLayoutFromMutation()
                    }
                }
            } as @convention(block) (CALayer, CGRect) -> Void
        }
        replace(c, "position", as: _GetPoint.self) { original, sel in
            { (layer: CALayer) -> CGPoint in
                if let owner = layer.owner { return owner.center }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> CGPoint
        }
        replace(c, "setPosition:", as: _SetPoint.self) { original, sel in
            { (layer: CALayer, value: CGPoint) in
                let state = layer._oukStateIfPresent
                if let owner = state?.owner {
                    MainActor.assumeIsolated { owner.center = value }
                    _OUKQuartzBridge.quartz { original(layer, sel, value) }; return
                }
                let old = layer.position
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                if !(state?.inFrameSetter ?? false), old != value {
                    MainActor.assumeIsolated {
                        layer._recordImplicitAnimation(keyPath: "position", from: old, to: value)
                    }
                }
            } as @convention(block) (CALayer, CGPoint) -> Void
        }
        replace(c, "frame", as: _GetRect.self) { original, sel in
            { (layer: CALayer) -> CGRect in
                if let owner = layer.owner { return owner.frame }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> CGRect
        }
        replace(c, "setFrame:", as: _SetRect.self) { original, sel in
            { (layer: CALayer, value: CGRect) in
                if let owner = layer.owner {
                    MainActor.assumeIsolated { owner.frame = value }
                    return
                }
                let state = layer._ouk
                let oldBounds = layer.bounds, oldPosition = layer.position
                state.inFrameSetter = true
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                state.inFrameSetter = false
                let newBounds = layer.bounds, newPosition = layer.position
                MainActor.assumeIsolated {
                    if newBounds != oldBounds {
                        layer._recordImplicitAnimation(keyPath: "bounds", from: oldBounds, to: newBounds)
                    }
                    if newPosition != oldPosition {
                        layer._recordImplicitAnimation(keyPath: "position", from: oldPosition, to: newPosition)
                    }
                    if newBounds != oldBounds || newPosition != oldPosition {
                        layer._oukSetNeedsLayoutFromMutation()
                        layer.superlayer?._oukSetNeedsLayoutFromMutation()
                    }
                }
            } as @convention(block) (CALayer, CGRect) -> Void
        }
        replace(c, "setAnchorPoint:", as: _SetPoint.self) { original, sel in
            { (layer: CALayer, value: CGPoint) in
                let old = layer.anchorPoint
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                if old != value {
                    MainActor.assumeIsolated {
                        layer._recordImplicitAnimation(keyPath: "anchorPoint", from: old, to: value)
                    }
                }
            } as @convention(block) (CALayer, CGPoint) -> Void
        }

        // Opacity, visibility and background colour of a backing layer are
        // its view's alpha, isHidden and backgroundColor.
        replace(c, "opacity", as: _GetFloat.self) { original, sel in
            { (layer: CALayer) -> Float in
                if let owner = layer.owner { return Float(owner.alpha) }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> Float
        }
        replace(c, "setOpacity:", as: _SetFloat.self) { original, sel in
            { (layer: CALayer, value: Float) in
                if let owner = layer.owner { MainActor.assumeIsolated { owner.alpha = CGFloat(value) } }
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
            } as @convention(block) (CALayer, Float) -> Void
        }
        replace(c, "isHidden", as: _GetBool.self) { original, sel in
            { (layer: CALayer) -> Bool in
                if let owner = layer.owner { return owner.isHidden }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> Bool
        }
        replace(c, "setHidden:", as: _SetBool.self) { original, sel in
            { (layer: CALayer, value: Bool) in
                if let owner = layer.owner { MainActor.assumeIsolated { owner.isHidden = value } }
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
            } as @convention(block) (CALayer, Bool) -> Void
        }
        replace(c, "backgroundColor", as: _GetColor.self) { original, sel in
            { (layer: CALayer) -> Unmanaged<CGColor>? in
                if let state = layer._oukStateIfPresent, let owner = state.owner {
                    let color = MainActor.assumeIsolated {
                        owner.backgroundColor?._cgColorObject(with: owner.traitCollection)
                    }
                    state.ownerBackground = color
                    return color.map { Unmanaged.passUnretained($0) }
                }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> Unmanaged<CGColor>?
        }
        replace(c, "setBackgroundColor:", as: _SetColor.self) { original, sel in
            { (layer: CALayer, value: CGColor?) in
                if let owner = layer.owner {
                    MainActor.assumeIsolated { owner.backgroundColor = value.map { UIColor(cgColor: $0) } }
                }
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
            } as @convention(block) (CALayer, CGColor?) -> Void
        }
        replace(c, "transform", as: _GetTransform3D.self) { original, sel in
            { (layer: CALayer) -> CATransform3D in
                if let owner = layer.owner {
                    return CATransform3DMakeAffineTransform(MainActor.assumeIsolated { owner.transform })
                }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> CATransform3D
        }
        replace(c, "setTransform:", as: _SetTransform3D.self) { original, sel in
            { (layer: CALayer, value: CATransform3D) in
                if let owner = layer.owner, CATransform3DIsAffine(value) {
                    MainActor.assumeIsolated { owner.transform = CATransform3DGetAffineTransform(value) }
                }
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
            } as @convention(block) (CALayer, CATransform3D) -> Void
        }
        replace(c, "affineTransform", as: _GetAffine.self) { original, sel in
            { (layer: CALayer) -> CGAffineTransform in
                if let owner = layer.owner { return MainActor.assumeIsolated { owner.transform } }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> CGAffineTransform
        }
        replace(c, "setAffineTransform:", as: _SetAffine.self) { original, sel in
            { (layer: CALayer, value: CGAffineTransform) in
                if let owner = layer.owner { MainActor.assumeIsolated { owner.transform = value } }
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
            } as @convention(block) (CALayer, CGAffineTransform) -> Void
        }

        // Animatable scalars the port animates implicitly on every layer.
        for (name, keyPath) in [("setBorderWidth:", "borderWidth"), ("setShadowRadius:", "shadowRadius")] {
            replace(c, name, as: _SetCGFloat.self) { original, sel in
                { (layer: CALayer, value: CGFloat) in
                        let old = (layer.value(forKey: keyPath) as? CGFloat) ?? 0
                    _OUKQuartzBridge.quartz { original(layer, sel, value) }
                    if old != value {
                        MainActor.assumeIsolated {
                            layer._recordImplicitAnimation(keyPath: keyPath, from: old, to: value)
                        }
                    }
                } as @convention(block) (CALayer, CGFloat) -> Void
            }
        }
        replace(c, "setShadowOpacity:", as: _SetFloat.self) { original, sel in
            { (layer: CALayer, value: Float) in
                let old = layer.shadowOpacity
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                if old != value {
                    MainActor.assumeIsolated {
                        layer._recordImplicitAnimation(keyPath: "shadowOpacity", from: old, to: value)
                    }
                }
            } as @convention(block) (CALayer, Float) -> Void
        }
        replace(c, "setShadowOffset:", as: _SetSize.self) { original, sel in
            { (layer: CALayer, value: CGSize) in
                let old = layer.shadowOffset
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                if old != value {
                    MainActor.assumeIsolated {
                        layer._recordImplicitAnimation(keyPath: "shadowOffset", from: old, to: value)
                    }
                }
            } as @convention(block) (CALayer, CGSize) -> Void
        }
        // A backing layer's corner radius animates with its view
        // (UIView.animate); a standalone layer's does not (the port's model).
        replace(c, "setCornerRadius:", as: _SetCGFloat.self) { original, sel in
            { (layer: CALayer, value: CGFloat) in
                guard let owner = layer.owner else { return original(layer, sel, value) }
                let old = layer.cornerRadius
                _OUKQuartzBridge.quartz { original(layer, sel, value) }
                if old != value {
                    MainActor.assumeIsolated {
                        owner.recordAnimation(.cornerRadius, from: .scalar(old), to: .scalar(value))
                    }
                }
            } as @convention(block) (CALayer, CGFloat) -> Void
        }

        // Layout runs on the port's flags (see _OUKLayerState.needsLayout);
        // a backing layer marks its view.
        replace(c, "setNeedsLayout", as: _Void.self) { _, _ in
            { (layer: CALayer) in
                guard _OUKQuartzBridge.quartzInternalDepth == 0 else { return }
                let state = layer._ouk
                state.needsLayout = true
                if let owner = state.owner { MainActor.assumeIsolated { owner.needsLayout = true } }
            } as @convention(block) (CALayer) -> Void
        }
        replace(c, "needsLayout", as: _GetBool.self) { _, _ in
            { (layer: CALayer) -> Bool in
                layer._oukStateIfPresent?.needsLayout ?? false
            } as @convention(block) (CALayer) -> Bool
        }
        replace(c, "layoutIfNeeded", as: _Void.self) { _, _ in
            { (layer: CALayer) in
                MainActor.assumeIsolated { layer._oukLayoutIfNeeded() }
            } as @convention(block) (CALayer) -> Void
        }
        // Tree mutations dirty the parent's layout (the port's model).
        for name in ["addSublayer:", "setSublayers:"] {
            replace(c, name, as: _SetObject.self) { original, sel in
                { (layer: CALayer, value: AnyObject?) in
                    _OUKQuartzBridge.quartz { original(layer, sel, value) }
                    MainActor.assumeIsolated { layer._oukSetNeedsLayoutFromMutation() }
                } as @convention(block) (CALayer, AnyObject?) -> Void
            }
        }
        replace(c, "insertSublayer:atIndex:", as: _InsertAtIndex.self) { original, sel in
            { (layer: CALayer, value: AnyObject?, index: UInt32) in
                _OUKQuartzBridge.quartz { original(layer, sel, value, index) }
                MainActor.assumeIsolated { layer._oukSetNeedsLayoutFromMutation() }
            } as @convention(block) (CALayer, AnyObject?, UInt32) -> Void
        }
        for name in ["insertSublayer:below:", "insertSublayer:above:", "replaceSublayer:with:"] {
            replace(c, name, as: _SetTwoObjects.self) { original, sel in
                { (layer: CALayer, a: AnyObject?, b: AnyObject?) in
                    _OUKQuartzBridge.quartz { original(layer, sel, a, b) }
                    MainActor.assumeIsolated { layer._oukSetNeedsLayoutFromMutation() }
                } as @convention(block) (CALayer, AnyObject?, AnyObject?) -> Void
            }
        }
        replace(c, "removeFromSuperlayer", as: _Void.self) { original, sel in
            { (layer: CALayer) in
                let parent = layer.superlayer
                _OUKQuartzBridge.quartz { original(layer, sel) }
                if let parent { MainActor.assumeIsolated { parent._oukSetNeedsLayoutFromMutation() } }
            } as @convention(block) (CALayer) -> Void
        }

        // No QuartzCore implicit actions: the port records its own.
        replace(c, "actionForKey:", as: _AnimationForKey.self) { _, _ in
            { (_: CALayer, _: AnyObject) -> AnyObject? in nil } as @convention(block) (CALayer, AnyObject) -> AnyObject?
        }

        // Explicit animations: QuartzCore keeps its copy; the port records
        // one sampled on its own clock.
        replace(c, "addAnimation:forKey:", as: _AddAnimation.self) { original, sel in
            { (layer: CALayer, animation: CAAnimation, key: AnyObject?) in
                _OUKQuartzBridge.quartz { original(layer, sel, animation, key) }
                MainActor.assumeIsolated {
                    layer._recordExplicitAnimation(animation, forKey: key as? String)
                }
            } as @convention(block) (CALayer, CAAnimation, AnyObject?) -> Void
        }
        replace(c, "removeAnimationForKey:", as: _RemoveAnimation.self) { original, sel in
            removeAnimationOriginal = original
            return { (layer: CALayer, key: AnyObject) in
                if layer._oukStateIfPresent != nil, let key = key as? String {
                    MainActor.assumeIsolated { layer._removeExplicitAnimations(forKey: key) }
                }
                _OUKQuartzBridge.quartz { original(layer, sel, key) }
            } as @convention(block) (CALayer, AnyObject) -> Void
        }
        replace(c, "removeAllAnimations", as: _Void.self) { original, sel in
            { (layer: CALayer) in
                if layer._oukStateIfPresent != nil {
                    MainActor.assumeIsolated { layer._removeExplicitAnimations(forKey: nil) }
                }
                _OUKQuartzBridge.quartz { original(layer, sel) }
            } as @convention(block) (CALayer) -> Void
        }
        replace(c, "animationForKey:", as: _AnimationForKey.self) { original, sel in
            { (layer: CALayer, key: AnyObject) -> CAAnimation? in
                if layer._oukStateIfPresent != nil {
                    MainActor.assumeIsolated {
                        layer._purgeFinishedAnimations(at: OpenUIKitRuntime.animationTime)
                    }
                }
                return original(layer, sel, key)
            } as @convention(block) (CALayer, AnyObject) -> CAAnimation?
        }
        replace(c, "animationKeys", as: _AnimationKeys.self) { original, sel in
            { (layer: CALayer) -> AnyObject? in
                if layer._oukStateIfPresent != nil {
                    MainActor.assumeIsolated {
                        layer._purgeFinishedAnimations(at: OpenUIKitRuntime.animationTime)
                    }
                }
                return original(layer, sel)
            } as @convention(block) (CALayer) -> AnyObject?
        }

        // render(in:) draws the port's rendering of the layer tree.
        replace(c, "renderInContext:", as: _RenderIn.self) { _, _ in
            { (layer: CALayer, context: CGContext) in
                MainActor.assumeIsolated {
                    UIGraphicsPushContext(context)
                    UIGraphics.draw { layer.render(in: $0) }
                    UIGraphicsPopContext()
                }
            } as @convention(block) (CALayer, CGContext) -> Void
        }
    }

    private static func installTransaction() {
        let meta: AnyClass = object_getClass(CATransaction.self)!
        replace(meta, "begin", as: _ClassVoid.self) { original, sel in
            { (cls: AnyClass) in
                original(cls, sel)
                MainActor.assumeIsolated { _OUKTransaction.begin() }
            } as @convention(block) (AnyClass) -> Void
        }
        replace(meta, "commit", as: _ClassVoid.self) { original, sel in
            { (cls: AnyClass) in
                MainActor.assumeIsolated { _OUKTransaction.commit() }
                original(cls, sel)
            } as @convention(block) (AnyClass) -> Void
        }
        replace(meta, "flush", as: _ClassVoid.self) { original, sel in
            { (cls: AnyClass) in
                MainActor.assumeIsolated { _OUKTransaction.flush() }
                original(cls, sel)
            } as @convention(block) (AnyClass) -> Void
        }
        replace(meta, "setAnimationDuration:", as: _ClassSetDouble.self) { original, sel in
            { (cls: AnyClass, value: Double) in
                MainActor.assumeIsolated { _OUKTransaction.setAnimationDuration(value) }
                original(cls, sel, value)
            } as @convention(block) (AnyClass, Double) -> Void
        }
        replace(meta, "animationDuration", as: _ClassVoid.self) { _, _ in
            { (_: AnyClass) -> Double in
                MainActor.assumeIsolated { _OUKTransaction.animationDuration() }
            } as @convention(block) (AnyClass) -> Double
        }
        replace(meta, "setDisableActions:", as: _ClassSetBool.self) { original, sel in
            { (cls: AnyClass, value: Bool) in
                MainActor.assumeIsolated { _OUKTransaction.setDisableActions(value) }
                original(cls, sel, value)
            } as @convention(block) (AnyClass, Bool) -> Void
        }
        replace(meta, "disableActions", as: _ClassVoid.self) { _, _ in
            { (_: AnyClass) -> Bool in
                MainActor.assumeIsolated { _OUKTransaction.disableActions() }
            } as @convention(block) (AnyClass) -> Bool
        }
        // Completion blocks run on the port's clock, after the port's
        // animations of the transaction; QuartzCore never sees them.
        replace(meta, "setCompletionBlock:", as: _ClassVoid.self) { _, _ in
            { (_: AnyClass, block: (@convention(block) () -> Void)?) in
                MainActor.assumeIsolated {
                    _OUKTransaction.setCompletionBlock(block.map { b in { b() } })
                }
            } as @convention(block) (AnyClass, (@convention(block) () -> Void)?) -> Void
        }
        // `+completionBlock` is not interposed: returning a Swift closure as
        // a block from here crashed Swift 6.2.1's IRGen (-O) in an unrelated
        // function's dispatch block (UIApplication.registerForRemoteNotifications,
        // emitBlockHeader, signal 11). QuartzCore's getter answers nil for
        // blocks the port holds.
    }
}

extension CALayer {
    /// Removes a finished animation from QuartzCore's own store without
    /// re-entering the port's interposer.
    func _removeFromQuartzStore(key: String) {
        guard let original = _OUKQuartzBridge.removeAnimationOriginal else { return }
        original(self, NSSelectorFromString("removeAnimationForKey:"), key as AnyObject)
    }
}

/// Called by the C constructor (OpenUIKitQuartzBootstrap) when the image
/// loads, so layers and transactions made before any view exists are covered.
@_cdecl("_openuikit_install_quartzcore_bridge")
public func _openuikit_install_quartzcore_bridge() {
    _OUKQuartzBridge.install()
}
#endif
